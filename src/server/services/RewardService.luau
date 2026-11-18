--!strict
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local EconomyRules = require(Shared.EconomyRules)
local Formulas = require(Shared.Formulas)
local Types = require(Shared.Types)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local ShopService = require(script.Parent.ShopService)
local BattlePassService = require(script.Parent.BattlePassService)

type Profile = Types.Profile

local RewardService = {}

local PLAY_TICK = 60
local MINUTES_PER_TICK = PLAY_TICK / 60

local bankClock: { [Player]: number } = {} -- os.clock() of the last time play was banked into profile.playtime
local started = false

local questDefs: { [string]: EconomyRules.QuestDef } = {}
for _, quest in Catalog.quests do
	questDefs[quest.id] = { kind = quest.kind, target = quest.target }
end
local questRewards: { [string]: Catalog.Reward } = {}
for _, quest in Catalog.quests do
	questRewards[quest.id] = quest.reward
end

local function today(): number
	return Formulas.dayNumber(os.time())
end

-- Call inside an update: rolls profile.playtime over to today and banks the seconds since the last bank.
-- ponytail: seconds since the last 60 s bank are lost on leave; add a bank on release if that matters.
local function bankPlaytime(p: Profile, player: Player)
	local now = os.clock()
	local since = now - (bankClock[player] or now)
	bankClock[player] = now
	local day = today()
	if p.playtime.day ~= day then
		p.playtime.day = day
		p.playtime.seconds = 0
		p.playtime.claimed = 0
	end
	p.playtime.seconds += since
end

-- Call inside an update.
local function regenerateQuests(profile: Profile, userId: number)
	local day = today()
	if profile.quests.day == day then
		return
	end
	local list = {}
	for i, quest in Catalog.questsForDay(day, userId, BattlePassService.missionCount()) do
		list[i] = { id = quest.id, progress = 0, claimed = false }
	end
	profile.quests = { day = day, list = list }
end

local function grant(player: Player, reward: Catalog.Reward, reason: string)
	if reward.currency == "gems" then
		EconomyService.addGems(player, reward.amount, reason)
	else
		EconomyService.addCoins(player, reward.amount, reason, false)
	end
end

local function isIndex(value: any, max: number): boolean
	return type(value) == "number" and value == math.floor(value) and value >= 1 and value <= max
end

function RewardService.claimDaily(player: Player): (boolean, any)
	local profile = DataService.get(player)
	if profile == nil then
		return false, "no_profile"
	end
	local state = Formulas.dailyClaimState(profile.daily.lastClaimDay, profile.daily.streak, today())
	if not state.canClaim then
		return false, "already_claimed"
	end
	local reward = Catalog.daily[state.nextStreak]
	local vip = EconomyService.hasPass(player, "vip")
	local function dailyAmount(currency: string, base: number): number
		return if currency == "gems" and vip then base * Config.Vip.DailyGemMultiplier else base
	end
	local amount = dailyAmount(reward.currency, reward.amount)
	local firstLoop = profile.daily.loops == 0
	local run = Formulas.dailyNextRun(profile.daily.lastClaimDay, profile.daily.run, today())
	local m = Catalog.nextDailyMilestone(run, profile.daily.milestones)
	local hit = if m ~= nil and m.day == run then m else nil
	DataService.update(player, function(p)
		p.daily.streak = state.nextStreak
		p.daily.lastClaimDay = today()
		p.daily.run = run
		if state.nextStreak == #Catalog.daily then
			p.daily.loops += 1
		end
		if hit ~= nil then
			p.daily.milestones[tostring(hit.day)] = true
		end
	end)
	grant(player, { currency = reward.currency, amount = amount }, "daily")
	local skin: string? = nil
	if reward.skin ~= nil and firstLoop and ShopService.grantItem(player, reward.skin) then
		skin = reward.skin
	end
	local milestone = nil
	if hit ~= nil then
		local bonus = dailyAmount(hit.currency, hit.amount)
		grant(player, { currency = hit.currency, amount = bonus }, "daily_milestone")
		local mSkin: string? = nil
		if hit.skin ~= nil and ShopService.grantItem(player, hit.skin) then
			mSkin = hit.skin
		end
		milestone = { day = hit.day, currency = hit.currency, amount = bonus, skin = mSkin }
	end
	return true,
		{ streak = state.nextStreak, currency = reward.currency, amount = amount, skin = skin, run = run, milestone = milestone }
end

function RewardService.claimPlaytime(player: Player, index: any): (boolean, any)
	if not isIndex(index, #Catalog.playtime) then
		return false, "bad_args"
	end
	if bankClock[player] == nil or DataService.get(player) == nil then
		return false, "no_profile"
	end
	local reward = Catalog.playtime[index]
	local bit = 2 ^ (index - 1)
	local err: string? = nil
	DataService.update(player, function(p)
		bankPlaytime(p, player)
		if bit32.btest(p.playtime.claimed, bit) then
			err = "already_claimed"
		elseif p.playtime.seconds < reward.seconds then
			err = "too_early"
		else
			p.playtime.claimed = bit32.bor(p.playtime.claimed, bit)
		end
	end)
	if err ~= nil then
		return false, err
	end
	grant(player, reward, "playtime")
	return true, { currency = reward.currency, amount = reward.amount }
end

function RewardService.claimQuest(player: Player, index: any): (boolean, any)
	local profile = DataService.get(player)
	if profile == nil then
		return false, "no_profile"
	end
	if profile.quests.day ~= today() then
		DataService.update(player, function(p)
			regenerateQuests(p, player.UserId)
		end)
		return false, "quests_refreshed"
	end
	if not isIndex(index, #profile.quests.list) then
		return false, "bad_args"
	end
	local entry = profile.quests.list[index]
	local def = questDefs[entry.id]
	local reward = questRewards[entry.id]
	if def == nil or reward == nil then
		return false, "unknown_quest"
	end
	if entry.claimed then
		return false, "already_claimed"
	end
	if entry.progress < def.target then
		return false, "not_complete"
	end
	DataService.update(player, function(p)
		p.quests.list[index].claimed = true
	end)
	grant(player, reward, "quest")
	if #profile.quests.list > 3 then
		BattlePassService.onMission(player, index) -- Turf Pass mission XP by slot
	end
	return true, { id = entry.id, currency = reward.currency, amount = reward.amount }
end

function RewardService.redeemCode(player: Player, code: any): (boolean, any)
	if type(code) ~= "string" or #code == 0 or #code > Config.Security.MaxCodeLength then
		return false, "bad_args"
	end
	local key = string.upper(code)
	local reward = (Catalog.codes :: { [string]: Catalog.Reward })[key]
	if reward == nil or not Catalog.isReleaseOpen(Catalog.codeRelease[key], os.time()) then
		return false, "invalid_code"
	end
	local profile = DataService.get(player)
	if profile == nil then
		return false, "no_profile"
	end
	if profile.codes[key] then
		return false, "already_used"
	end
	DataService.update(player, function(p)
		p.codes[key] = true
	end)
	grant(player, reward, "code")
	return true, { currency = reward.currency, amount = reward.amount }
end

-- Playtime rewards claimed today as a dense array (sparse tables do not survive remotes).
function RewardService.playtimeClaimed(player: Player): { boolean }
	local out = table.create(#Catalog.playtime, false)
	local p = DataService.get(player)
	if p ~= nil and p.playtime.day == today() then
		for i in out do
			out[i] = bit32.btest(p.playtime.claimed, 2 ^ (i - 1))
		end
	end
	return out
end

-- Unix time at which today's play would have started if it were one session; the client counts
-- playtime rewards from here, so it keeps working unchanged.
function RewardService.playtimeStart(player: Player): number
	local p = DataService.get(player)
	local played = if p ~= nil and p.playtime.day == today() then p.playtime.seconds else 0
	local clock = bankClock[player]
	if clock ~= nil then
		played += os.clock() - clock
	end
	return os.time() - math.floor(played)
end

-- One DataService update per call, however many quests match.
function RewardService.progress(player: Player, kind: string, amount: number, mode: string)
	if type(kind) ~= "string" or type(amount) ~= "number" then
		return
	end
	DataService.update(player, function(p)
		regenerateQuests(p, player.UserId)
		EconomyRules.applyQuestProgress(p.quests.list, questDefs, kind, amount, if mode == "max" then "max" else "add")
	end)
	if kind == "cells" then
		BattlePassService.onCells(player, amount)
	elseif kind == "kills" then
		BattlePassService.onKill(player)
	end
end

local function playLoop()
	while true do
		task.wait(PLAY_TICK)
		for _, player in Players:GetPlayers() do
			DataService.update(player, function(p)
				p.stats.playSeconds += PLAY_TICK
				bankPlaytime(p, player)
				regenerateQuests(p, player.UserId)
				EconomyRules.applyQuestProgress(p.quests.list, questDefs, "playMinutes", MINUTES_PER_TICK, "add")
			end)
		end
	end
end

function RewardService.start()
	if started then
		return
	end
	started = true
	local function onPlayer(player: Player)
		if DataService.load(player) ~= nil then
			bankClock[player] = os.clock()
			DataService.update(player, function(p)
				bankPlaytime(p, player) -- rolls the day over; banks nothing on join
				regenerateQuests(p, player.UserId)
			end)
		end
	end
	Players.PlayerAdded:Connect(function(player)
		task.spawn(onPlayer, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		bankClock[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end
	task.spawn(playLoop)
end

return RewardService
