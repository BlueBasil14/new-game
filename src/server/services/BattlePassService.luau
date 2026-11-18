--!strict
-- Turf Pass server: owns pass state in profile.pass, grants XP from server events only (missions, captures,
-- eliminations, receipts), validates claims and delivers rewards. Rules live in Shared/BattlePass.
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BattlePass = require(Shared.BattlePass)
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local Formulas = require(Shared.Formulas)
local Remotes = require(Shared.Remotes)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local CFG = Config.BattlePass
local BattlePassService = {}

local remote: RemoteEvent? = nil
local policies: { [Player]: { at: number, restricted: boolean } } = {}
local started = false

function BattlePassService.isOpen(): boolean
	return BattlePass.isOpen(os.time(), RunService:IsStudio())
end

-- Daily missions shown while a season is open (Catalog.questsForDay count).
function BattlePassService.missionCount(): number
	return if BattlePassService.isOpen() then CFG.Missions else 3
end

local function notify(player: Player, payload: { [string]: any })
	if remote and player.Parent ~= nil then
		remote:FireClient(player, payload)
	end
end

-- Keys are random (Sky Chest) and pass XP can be bought, so restricted players get fixed coins instead.
-- A failed policy lookup counts as restricted.
local function keysRestricted(player: Player): boolean
	local cached = policies[player]
	if cached and os.clock() - cached.at < 300 then
		return cached.restricted
	end
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	local restricted = not (ok and type(info) == "table" and info.ArePaidRandomItemsRestricted == false)
	policies[player] = { at = os.clock(), restricted = restricted }
	return restricted
end

-- Call inside DataService.update. Returns the normalized state stored on the profile.
local function stateIn(p: any): (BattlePass.State, { BattlePass.Reward })
	local st, leftovers = BattlePass.normalize(p.pass, CFG.Season)
	p.pass = st
	return st, leftovers
end

-- Applies one reward inside an update. `restricted` is resolved before the update (it may yield).
local function grantIn(player: Player, p: any, r: BattlePass.Reward, restricted: boolean, reason: string)
	local amount = r.amount or 0
	if r.kind == "coins" then
		EconomyService.creditInProfile(player, p, "coins", amount, reason)
	elseif r.kind == "gems" then
		EconomyService.creditInProfile(player, p, "gems", amount, reason)
	elseif r.kind == "keys" then
		if restricted then
			EconomyService.creditInProfile(player, p, "coins", amount * CFG.RestrictedKeyCoins, reason)
		else
			p.wheelFree += amount
		end
	elseif r.kind == "boost" then
		EconomyService.extendBoostInProfile(p, amount)
	elseif r.kind == "item" and r.id and Catalog.byId(r.id) then
		p.owned[r.id] = true
	end
end

-- Season roll on join: deliver last season's unclaimed rewards.
local function roll(player: Player)
	if DataService.get(player) == nil then
		return
	end
	local restricted = keysRestricted(player)
	local delivered = 0
	DataService.update(player, function(p)
		local _, leftovers = stateIn(p)
		for _, r in leftovers do
			grantIn(player, p, r, restricted, "passSeasonEnd")
		end
		delivered = #leftovers
	end)
	if delivered > 0 then
		DataService.save(player)
		notify(player, { kind = "delivered", count = delivered })
	end
end

-- The only way XP enters the pass. Bonus keys past the last tier are granted here.
function BattlePassService.addXp(player: Player, amount: number, reason: string, play: boolean?)
	if not BattlePassService.isOpen() or type(amount) ~= "number" or amount <= 0 or DataService.get(player) == nil then
		return
	end
	local restricted = keysRestricted(player)
	local granted, gained, bonus, tier, capped = 0, 0, 0, 0, false
	DataService.update(player, function(p)
		local st = stateIn(p)
		local xp = amount
		if play then
			xp = BattlePass.playXp(st, Formulas.dayNumber(os.time()), amount)
			capped = st.playXp >= CFG.PlayXpPerDay
		end
		if xp <= 0 then
			return
		end
		granted = xp
		gained, bonus = BattlePass.addXp(st, xp)
		if bonus > 0 then
			grantIn(player, p, { kind = "keys", amount = bonus }, restricted, "passBonus")
		end
		tier = BattlePass.tierOf(st.xp)
	end)
	if granted > 0 then
		notify(player, { kind = "xp", amount = granted, reason = reason, tier = tier, gained = gained, bonus = bonus, capped = capped })
	elseif play and capped then
		notify(player, { kind = "capped" })
	end
end

function BattlePassService.onMission(player: Player, slot: number)
	local p = DataService.get(player)
	if p == nil then
		return
	end
	local st = BattlePass.normalize((p :: any).pass, CFG.Season)
	local behind = BattlePass.isBehind(st, os.time())
	BattlePassService.addXp(player, BattlePass.missionXp(slot, behind), if behind then "catchup" else "mission")
end

function BattlePassService.onCells(player: Player, cells: number)
	BattlePassService.addXp(player, math.floor(cells / CFG.CellsPerXp), "play", true)
end

function BattlePassService.onKill(player: Player)
	BattlePassService.addXp(player, CFG.KillXp, "play", true)
end

-- Receipt effects; called inside the receipt's DataService.update (MonetizationService).
function BattlePassService.applyProductIn(player: Player, p: any, key: string, restricted: boolean)
	local st = stateIn(p)
	local gems, bonus = BattlePass.applyProduct(st, key)
	if gems > 0 then
		EconomyService.creditInProfile(player, p, "gems", gems, key)
	end
	if bonus > 0 then
		grantIn(player, p, { kind = "keys", amount = bonus }, restricted, "passBonus")
	end
end

function BattlePassService.keysRestricted(player: Player): boolean
	return keysRestricted(player)
end

function BattlePassService.afterProduct(player: Player, key: string)
	notify(player, { kind = "product", key = key })
end

local function claimList(player: Player, list: { { track: string, tier: number } }): (boolean, any)
	local restricted = keysRestricted(player)
	local claimed = {}
	local err: string? = nil
	DataService.update(player, function(p)
		local st = stateIn(p)
		for _, c in list do
			local ok, why = BattlePass.canClaim(st, c.track, c.tier)
			if ok then
				BattlePass.markClaimed(st, c.track, c.tier)
				for _, r in BattlePass.rewards(c.track, c.tier) do
					grantIn(player, p, r, restricted, "pass")
				end
				table.insert(claimed, { track = c.track, tier = c.tier })
			elseif #list == 1 then
				err = why
			end
		end
	end)
	if err then
		return false, err
	end
	if #claimed == 0 then
		return false, "nothing_to_claim"
	end
	return true, { claimed = claimed, restricted = restricted }
end

-- Request router: ("claim", track, tier) | ("claimAll") | ("seen", n)
function BattlePassService.request(player: Player, action: any, track: any, tier: any): (boolean, any)
	if not BattlePassService.isOpen() then
		return false, "pass_closed"
	end
	local p = DataService.get(player)
	if p == nil then
		return false, "no_profile"
	end
	if action == "claim" then
		local ok, why = BattlePass.canClaim(BattlePass.normalize((p :: any).pass, CFG.Season), track, tier)
		if not ok then
			return false, why
		end
		return claimList(player, { { track = track, tier = tier } })
	elseif action == "claimAll" then
		return claimList(player, BattlePass.unclaimed(BattlePass.normalize((p :: any).pass, CFG.Season)))
	elseif action == "seen" then
		if tier ~= 1 and tier ~= 2 then
			return false, "bad_args"
		end
		DataService.update(player, function(pp)
			local st = stateIn(pp)
			st.seen = bit32.bor(st.seen, tier)
		end)
		return true, nil
	end
	return false, "bad_args"
end

-- Session info for the client (who is restricted, whether the season is open, when it ends).
function BattlePassService.session(player: Player): { [string]: any }
	local p = DataService.get(player)
	local behind = false
	if p ~= nil then
		behind = BattlePass.isBehind(BattlePass.normalize((p :: any).pass, CFG.Season), os.time())
	end
	local cached = policies[player]
	return {
		open = BattlePassService.isOpen(),
		endsAt = if CFG.Start > 0 then BattlePass.endsAt() else os.time() + CFG.Days * 86400,
		behind = behind,
		keysRestricted = if cached then cached.restricted else false,
	}
end

function BattlePassService.start()
	if started then
		return
	end
	started = true
	local folder = ReplicatedStorage:WaitForChild(Remotes.Folder)
	remote = folder:WaitForChild(Remotes.PassEvent) :: RemoteEvent
	local function onPlayer(player: Player)
		if DataService.load(player) ~= nil and player.Parent ~= nil and BattlePassService.isOpen() then
			roll(player)
		end
	end
	Players.PlayerAdded:Connect(function(player)
		task.spawn(onPlayer, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		policies[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end
	if RunService:IsStudio() then
		-- Studio-only test hook: DebugPass:Fire(player, "premium" | "plus" | "tier", nil) runs the receipt path;
		-- ("xp", amount) adds XP; ("reset") wipes the pass state.
		local ev = Instance.new("BindableEvent")
		ev.Name = "DebugPass"
		ev.Event:Connect(function(player: Player, what: string, amount: number?)
			if what == "xp" then
				BattlePassService.addXp(player, amount or 1000, "debug")
			elseif what == "reset" then
				DataService.update(player, function(p)
					(p :: any).pass = BattlePass.fresh(CFG.Season)
				end)
			else
				local key = if what == "plus" then "battlePassPlus" elseif what == "tier" then "battlePassTier" else "battlePass"
				DataService.update(player, function(p)
					BattlePassService.applyProductIn(player, p, key, false)
				end)
				BattlePassService.afterProduct(player, key)
			end
		end)
		ev.Parent = script
	end
end

return BattlePassService
