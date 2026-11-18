--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local EconomyRules = require(Shared.EconomyRules)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local ShopService = require(script.Parent.ShopService)
local BattlePassService = require(script.Parent.BattlePassService)

local MonetizationService = {}

-- Pluggable: return true when the respawn was applied.
MonetizationService.onSecondChance = nil :: ((Player) -> boolean)?
-- Pluggable: called after a game pass is marked owned (ArenaService refreshes the VIP tag).
MonetizationService.onPassOwned = nil :: ((Player) -> ())?
-- Pluggable: called after a receipt is granted (productKey, Robux price or 0); Main logs analytics.
MonetizationService.onProductBought = nil :: ((Player, string, number) -> ())?

local SECOND_CHANCE_REFUND_GEMS = 20

local joinClock: { [Player]: number } = {}
local passKeyById: { [number]: string } = {}
local productKeyById: { [number]: string } = {}
local started = false

for key, id in Config.Ids.Passes do
	if id ~= 0 then
		passKeyById[id] = key
	end
end
for key, id in Config.Ids.Products do
	if id ~= 0 then
		productKeyById[id] = key
	end
end

local function markPassOwned(player: Player, passKey: string)
	EconomyService.setPassOwned(player, passKey, true)
	if DataService.get(player) ~= nil then
		ShopService.reconcile(player)
	end
	local hook = MonetizationService.onPassOwned
	if hook ~= nil then
		pcall(hook, player)
	end
end

-- Studio-only: same path as a finished pass purchase, for testing with placeholder ids. No-op in live servers.
function MonetizationService.debugGrantPass(player: Player, passKey: string): boolean
	if not RunService:IsStudio() or (Config.Ids.Passes :: any)[passKey] == nil then
		return false
	end
	markPassOwned(player, passKey)
	return true
end

-- Grants a pass only when Roblox confirms ownership. Errors always retry; a clean false retries only
-- after a purchase prompt (retryFalse), where the API can return a cached false. Run off the caller's thread.
local verifying: { [Player]: { [string]: boolean } } = {} -- purchase checks in flight, so a spammed signal starts one loop
local function verifyPass(player: Player, key: string, id: number, retryFalse: boolean)
	if EconomyService.hasPass(player, key) then
		return
	end
	if retryFalse then
		local set: { [string]: boolean } = verifying[player] or {}
		if set[key] or player.Parent == nil then
			return
		end
		set[key] = true
		verifying[player] = set
	end
	local cfg = Config.PassCheck
	for attempt = 1, cfg.Attempts do
		if player.Parent == nil then
			break
		end
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
		end)
		if ok and owns == true then
			if player.Parent ~= nil then
				markPassOwned(player, key)
			end
			break
		end
		if (ok and not retryFalse) or attempt == cfg.Attempts then
			break
		end
		task.wait(if retryFalse then cfg.RetrySeconds else cfg.RetrySeconds * 2 ^ (attempt - 1))
	end
	local set = verifying[player]
	if retryFalse and set ~= nil then
		set[key] = nil
	end
end

local function checkPasses(player: Player)
	for key, id in Config.Ids.Passes do
		if id ~= 0 then
			task.spawn(verifyPass, player, key, id, false)
		end
	end
end

local function checkGroup(player: Player)
	if Config.Ids.GroupId == 0 then
		return
	end
	local ok, member = pcall(function()
		return player:IsInGroup(Config.Ids.GroupId)
	end)
	if ok and member == true then
		EconomyService.setInGroup(player, true)
		if DataService.get(player) ~= nil then
			ShopService.reconcile(player)
		end
	end
end

local function onPlayerAdded(player: Player)
	joinClock[player] = os.clock()
	DataService.load(player)
	if player.Parent == nil then
		return
	end
	task.spawn(checkPasses, player)
	task.spawn(checkGroup, player)
end

function MonetizationService.shouldOfferStarter(player: Player): boolean
	local profile = DataService.get(player)
	local joined = joinClock[player]
	if profile == nil or joined == nil then
		return false
	end
	return EconomyRules.shouldOfferStarter(profile.starterPackBought, os.clock() - joined, profile.starterOfferSeenAt, os.time())
end

function MonetizationService.markStarterOfferSeen(player: Player)
	DataService.update(player, function(profile)
		if profile.starterOfferSeenAt == 0 then
			profile.starterOfferSeenAt = os.time()
		end
	end)
end

local function processReceipt(info: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if player == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local profile = DataService.get(player)
	if profile == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local productKey = productKeyById[info.ProductId]
	if productKey == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local purchaseId = tostring(info.PurchaseId)
	if DataService.hasReceipt(profile, purchaseId) then
		-- This may be an in-memory receipt from a failed save, not a durable one.
		-- Retry persistence without granting the reward again.
		local ok, saved = pcall(DataService.save, player)
		return if ok and saved == true then Enum.ProductPurchaseDecision.PurchaseGranted else Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local cfg = (Config.Products :: any)[productKey]
	local isPass = string.sub(productKey, 1, 10) == "battlePass"
	-- Policy lookup can yield, so it runs before the profile update (pass keys become coins when restricted).
	local passRestricted = isPass and BattlePassService.keysRestricted(player)
	local secondChanceApplied = true
	if productKey == "secondChance" then
		local handler = MonetizationService.onSecondChance
		secondChanceApplied = false
		if handler ~= nil then
			local ok, result = pcall(handler, player)
			secondChanceApplied = ok and result == true
		end
	end

	local ran = false
	DataService.update(player, function(p)
		if DataService.hasReceipt(p, purchaseId) then
			ran = true
			return
		end
		DataService.addReceipt(p, purchaseId)
		if isPass then
			BattlePassService.applyProductIn(player, p, productKey, passRestricted)
		elseif productKey == "wheelSpin" then
			p.wheelPaid += 1
		elseif productKey == "boost15" then
			EconomyService.extendBoostInProfile(p, cfg.Seconds)
		elseif productKey == "starterPack" then
			-- Once per account (owner decision 4): the client never offers it again. A repeat can only come
			-- from a stale or forced prompt; the player has paid, so they still get the gems.
			EconomyService.creditInProfile(player, p, "gems", cfg.Gems, productKey)
			if not p.starterPackBought then
				p.starterPackBought = true
				EconomyService.creditInProfile(player, p, "coins", cfg.Coins, productKey)
				p.owned[cfg.Skin] = true
			end
		elseif productKey == "secondChance" then
			if not secondChanceApplied then
				EconomyService.creditInProfile(player, p, "gems", SECOND_CHANCE_REFUND_GEMS, "secondChanceRefund")
			end
		elseif cfg.Gems ~= nil then
			EconomyService.creditInProfile(player, p, "gems", cfg.Gems, productKey)
		end
		ran = true
	end)
	if not ran then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- Persist the receipt before telling Roblox the purchase is granted.
	local saveOk, saved = pcall(DataService.save, player)
	if not saveOk or saved ~= true then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if isPass then
		BattlePassService.afterProduct(player, productKey)
	end
	local bought = MonetizationService.onProductBought
	if bought ~= nil then
		pcall(bought, player, productKey, tonumber(info.CurrencySpent) or 0)
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService.start()
	if started then
		return
	end
	started = true
	MarketplaceService.ProcessReceipt = processReceipt :: any
	-- The client can fire this signal itself, so it only triggers a server-side ownership check.
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Instance, gamePassId: number, wasPurchased: boolean)
		local key = if type(gamePassId) == "number" then passKeyById[gamePassId] else nil
		if wasPurchased == true and key ~= nil and typeof(player) == "Instance" and player:IsA("Player") then
			task.spawn(verifyPass, player :: Player, key, gamePassId, true)
		end
	end)
	Players.PlayerAdded:Connect(function(player)
		task.spawn(onPlayerAdded, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		joinClock[player] = nil
		verifying[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return MonetizationService
