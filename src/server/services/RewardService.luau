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

type Profile = Types.Profile

local RewardService = {}

local PLAY_TICK = 60
local MINUTES_PER_TICK = PLAY_TICK / 60

local joinClock: { [Player]: number } = {}
local claimedPlaytime: { [Player]: { [number]: boolean } } = {}
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

-- Call inside an update.
local function regenerateQuests(profile: Profile, userId: number)
	local day = today()
	if profile.quests.day == day then
		return
	end
	local list = {}
	for i, quest in Catalog.questsForDay(day, userId) do
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
	local amount = reward.amount
	if reward.currency == "gems" and EconomyService.hasPass(player, "vip") then
		amount *= Config.Vip.DailyGemMultiplier
	end
	local firstLoop = profile.daily.loops == 0
	DataService.update(player, function(p)
		p.daily.streak = state.nextStreak
		p.daily.lastClaimDay = today()
		if state.nextStreak == #Catalog.daily then
			p.daily.loops += 1
		end
	end)
	grant(player, { currency = reward.currency, amount = amount }, "daily")
	local skin: string? = nil
	if reward.skin ~= nil and firstLoop and ShopService.grantItem(player, reward.skin) then
		skin = reward.skin
	end
	return true, { streak = state.nextStreak, currency = reward.currency, amount = amount, skin = skin }
end

function RewardService.claimPlaytime(player: Player, index: any): (boolean, any)
	if not isIndex(index, #Catalog.playtime) then
		return false, "bad_args"
	end
	local joined = joinClock[player]
	if joined == nil or DataService.get(player) == nil then
		return false, "no_profile"
	end
	local reward = Catalog.playtime[index]
	local claimed = claimedPlaytime[player]
	if claimed == nil then
		claimed = {}
		claimedPlaytime[player] = claimed
	end
	if (claimed :: { [number]: boolean })[index] then
		return false, "already_claimed"
	end
	if os.clock() - joined < reward.seconds then
		return false, "too_early"
	end
	(claimed :: { [number]: boolean })[index] = true
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
	return true, { id = entry.id, currency = reward.currency, amount = reward.amount }
end

function RewardService.redeemCode(player: Player, code: any): (boolean, any)
	if type(code) ~= "string" or #code == 0 or #code > Config.Security.MaxCodeLength then
		return false, "bad_args"
	end
	local key = string.upper(code)
	local reward = (Catalog.codes :: { [string]: Catalog.Reward })[key]
	if reward == nil then
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

-- Playtime rewards claimed this session as a dense array (sparse tables do not survive remotes).
function RewardService.playtimeClaimed(player: Player): { boolean }
	local out = table.create(#Catalog.playtime, false)
	local claimed = claimedPlaytime[player]
	if claimed ~= nil then
		for i in claimed do
			if out[i] ~= nil then
				out[i] = true
			end
		end
	end
	return out
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
end

local function playLoop()
	while true do
		task.wait(PLAY_TICK)
		for _, player in Players:GetPlayers() do
			DataService.update(player, function(p)
				p.stats.playSeconds += PLAY_TICK
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
		joinClock[player] = os.clock()
		if DataService.load(player) ~= nil then
			DataService.update(player, function(p)
				regenerateQuests(p, player.UserId)
			end)
		end
	end
	Players.PlayerAdded:Connect(function(player)
		task.spawn(onPlayer, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		joinClock[player] = nil
		claimedPlaytime[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end
	task.spawn(playLoop)
end

return RewardService
