--!strict
-- The only module that changes coins or gems.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Formulas = require(Shared.Formulas)
local Types = require(Shared.Types)
local DataService = require(script.Parent.DataService)

type Profile = Types.Profile

local EconomyService = {}

local listeners: { (Player, string, number, string) -> () } = {}
EconomyService.granted = {
	Connect = function(_self: any, fn: (Player, string, number, string) -> ())
		table.insert(listeners, fn)
		return {
			Disconnect = function()
				local i = table.find(listeners, fn)
				if i then
					table.remove(listeners, i)
				end
			end,
		}
	end,
}

EconomyService.cellsProvider = nil :: ((Player) -> number)?

local passOwned: { [Player]: { [string]: boolean } } = {}
local inGroup: { [Player]: boolean } = {}
local started = false

local function fire(player: Player, currency: string, amount: number, reason: string)
	for _, cb in table.clone(listeners) do
		task.spawn(cb, player, currency, amount, reason)
	end
end

local function validAmount(amount: any): boolean
	return type(amount) == "number" and amount == amount and amount > 0 and amount < math.huge
end

function EconomyService.setPassOwned(player: Player, passKey: string, owned: boolean)
	local set = passOwned[player]
	if set == nil then
		set = {}
		passOwned[player] = set
	end
	(set :: { [string]: boolean })[passKey] = owned
end

function EconomyService.hasPass(player: Player, passKey: string): boolean
	local set = passOwned[player]
	return set ~= nil and set[passKey] == true
end

function EconomyService.setInGroup(player: Player, value: boolean)
	inGroup[player] = value
end

function EconomyService.isInGroup(player: Player): boolean
	return inGroup[player] == true
end

function EconomyService.multiplier(player: Player): number
	local profile = DataService.get(player)
	if profile == nil then
		return 1
	end
	local now = os.time()
	return Formulas.coinMultiplier({
		coinBoostLevel = profile.upgrades.coinBoost,
		crowns = profile.crowns,
		vip = EconomyService.hasPass(player, "vip"),
		doubleCoins = EconomyService.hasPass(player, "doubleCoins"),
		boostActive = profile.boostUntil > now,
		inGroup = inGroup[player] == true,
		weekend = Formulas.isWeekendUTC(now),
	})
end

-- Returns coins actually added (after multiplier, rounded). 0 when the profile is not loaded.
function EconomyService.addCoins(player: Player, baseAmount: number, reason: string, applyMultiplier: boolean): number
	if not validAmount(baseAmount) then
		return 0
	end
	local amount = baseAmount
	if applyMultiplier then
		amount = baseAmount * EconomyService.multiplier(player)
	end
	amount = math.floor(amount + 0.5)
	if amount <= 0 then
		return 0
	end
	local applied = false
	DataService.update(player, function(profile)
		profile.coins += amount
		profile.lifetimeCoinsSinceRebirth += amount
		applied = true
	end)
	if not applied then
		return 0
	end
	fire(player, "coins", amount, reason)
	return amount
end

function EconomyService.addGems(player: Player, amount: number, reason: string)
	if not validAmount(amount) then
		return
	end
	amount = math.floor(amount)
	local applied = false
	DataService.update(player, function(profile)
		profile.gems += amount
		applied = true
	end)
	if applied then
		fire(player, "gems", amount, reason)
	end
end

-- For use INSIDE a DataService.update callback (e.g. a receipt grant that must be atomic).
-- Adds a flat amount with no multiplier and does not count toward rebirth progress.
function EconomyService.creditInProfile(player: Player, profile: Profile, currency: string, amount: number, reason: string)
	if not validAmount(amount) then
		return
	end
	amount = math.floor(amount)
	if currency == "coins" then
		profile.coins += amount
	elseif currency == "gems" then
		profile.gems += amount
	else
		return
	end
	fire(player, currency, amount, reason)
end

-- Atomic check-and-deduct.
function EconomyService.spend(player: Player, currency: string, amount: number): boolean
	if (currency ~= "coins" and currency ~= "gems") or not validAmount(amount) then
		return false
	end
	local ok = false
	DataService.update(player, function(profile)
		if currency == "coins" then
			if profile.coins >= amount then
				profile.coins -= amount
				ok = true
			end
		elseif profile.gems >= amount then
			profile.gems -= amount
			ok = true
		end
	end)
	return ok
end

-- Rebirth reset: coins and rebirth progress back to zero.
function EconomyService.resetCoins(player: Player)
	DataService.update(player, function(profile)
		profile.coins = 0
		profile.lifetimeCoinsSinceRebirth = 0
	end)
end

function EconomyService.onCapture(player: Player, neutral: number, stolen: number): number
	if type(neutral) ~= "number" or type(stolen) ~= "number" then
		return 0
	end
	return EconomyService.addCoins(player, Formulas.captureCoins(neutral, stolen), "capture", true)
end

function EconomyService.onKill(player: Player, victimCells: number, victimWasKing: boolean): number
	return EconomyService.addCoins(player, Formulas.killCoins(victimCells, victimWasKing), "kill", true)
end

function EconomyService.onFullMap(player: Player)
	EconomyService.addCoins(player, Config.Arena.FullMapBonus, "fullMap", true)
end

-- For use INSIDE a DataService.update callback.
function EconomyService.extendBoostInProfile(profile: Profile, seconds: number)
	profile.boostUntil = math.max(os.time(), profile.boostUntil) + seconds
end

function EconomyService.activateBoost(player: Player, seconds: number)
	if not validAmount(seconds) then
		return
	end
	DataService.update(player, function(profile)
		EconomyService.extendBoostInProfile(profile, seconds)
	end)
end

local function passiveLoop()
	while true do
		task.wait(Config.Income.PassiveInterval)
		local provider = EconomyService.cellsProvider
		if provider ~= nil then
			for _, player in Players:GetPlayers() do
				local ok, cells = pcall(provider, player)
				if ok and type(cells) == "number" then
					local coins = Formulas.passiveCoins(cells)
					if coins > 0 then
						EconomyService.addCoins(player, coins, "passive", true)
					end
				end
			end
		end
	end
end

function EconomyService.start()
	if started then
		return
	end
	started = true
	Players.PlayerRemoving:Connect(function(player)
		passOwned[player] = nil
		inGroup[player] = nil
	end)
	task.spawn(passiveLoop)
end

return EconomyService
