--!strict
-- Server entry point (GDD G11): builds the world, creates the remotes, starts services in
-- dependency order, loads players and routes client requests.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local Formulas = require(Shared.Formulas)
local Remotes = require(Shared.Remotes)

local Server = script.Parent
local Services = Server:WaitForChild("services")
local WorldBuilder = require(Server:WaitForChild("WorldBuilder") :: any)
local AnalyticsService = require(Services:WaitForChild("AnalyticsService") :: any)
local ArenaService = require(Services:WaitForChild("ArenaService") :: any)
local BadgeService = require(Services:WaitForChild("BadgeService") :: any)
local BotService = require(Services:WaitForChild("BotService") :: any)
local DataService = require(Services:WaitForChild("DataService") :: any)
local EconomyService = require(Services:WaitForChild("EconomyService") :: any)
local LeaderboardService = require(Services:WaitForChild("LeaderboardService") :: any)
local MonetizationService = require(Services:WaitForChild("MonetizationService") :: any)
local RewardService = require(Services:WaitForChild("RewardService") :: any)
local ShopService = require(Services:WaitForChild("ShopService") :: any)
local UpgradeService = require(Services:WaitForChild("UpgradeService") :: any)

local PROFILE_PERIOD = 0.25 -- 4 Hz ProfileUpdate throttle
local MAX_ARGS = 4
local MAX_STRING = 64
local RESPAWN_TIME = 0.5
local FUNNEL_MINUTE_10 = 600 -- seconds, GDD G12 funnel
local SETTINGS = { music = true, sfx = true, shake = true, lowDetail = true }

-- 1. world and remotes ---------------------------------------------------------------------------

WorldBuilder.build()

local remoteFolder = Instance.new("Folder")
remoteFolder.Name = Remotes.Folder
for key, value in Remotes :: any do
	if type(value) == "string" and key ~= "Folder" and key ~= "Request" then
		local ev = Instance.new("RemoteEvent")
		ev.Name = value
		ev.Parent = remoteFolder
	end
end
local requestFn = Instance.new("RemoteFunction")
requestFn.Name = Remotes.Request
requestFn.Parent = remoteFolder
remoteFolder.Parent = ReplicatedStorage

local profileRemote = remoteFolder:FindFirstChild(Remotes.ProfileUpdate) :: RemoteEvent

Players.RespawnTime = RESPAWN_TIME

-- 2. services --------------------------------------------------------------------------------------

DataService.start()
EconomyService.start()
ShopService.start()
MonetizationService.start()
RewardService.start()
LeaderboardService.start()
ArenaService.start()
BotService.start()

-- 3. profile replication ---------------------------------------------------------------------------

local joinedAt: { [Player]: number } = {}
local coinsEarned: { [Player]: number } = {}
local dirty: { [Player]: boolean } = {}

local function sessionInfo(player: Player): { [string]: any }
	local passes: { [string]: boolean } = {}
	for key in Config.Ids.Passes do
		passes[key] = EconomyService.hasPass(player, key)
	end
	return {
		multiplier = EconomyService.multiplier(player),
		passes = passes,
		featured = Catalog.featured(Formulas.dayNumber(os.time())),
		joinedAt = joinedAt[player] or os.time(),
		playtimeClaimed = RewardService.playtimeClaimed(player),
		starterOffer = MonetizationService.shouldOfferStarter(player),
		serverTime = os.time(),
	}
end

local function sendProfile(player: Player)
	local profile = DataService.get(player)
	if profile == nil or player.Parent == nil then
		return
	end
	local copy = table.clone(profile) :: any
	copy.receipts = nil
	profileRemote:FireClient(player, { profile = copy, session = sessionInfo(player) })
end

DataService.changed:Connect(function(player: Player)
	dirty[player] = true
end)

task.spawn(function()
	while true do
		task.wait(PROFILE_PERIOD)
		local list: { Player } = {}
		for player in dirty do
			table.insert(list, player)
		end
		table.clear(dirty)
		for _, player in list do
			local ok, err = pcall(sendProfile, player)
			if not ok then
				warn("[Main] ProfileUpdate failed:", err)
			end
		end
	end
end)

EconomyService.granted:Connect(function(player: Player, currency: string, amount: number)
	if currency == "coins" then
		coinsEarned[player] = (coinsEarned[player] or 0) + amount
	end
end)

-- Leaderboard stand (WorldBuilder's LeaderboardStand): title + top 10 of the "cells" board. Rows are built
-- once; names resolve asynchronously, cached per userId ("Player" until known).
local STAND_BOARD = "cells"
local STAND_ROWS = 10
local standRows: { { rank: TextLabel, name: TextLabel, value: TextLabel } }? = nil
local nameCache: { [number]: string } = {}
local nameResolving: { [number]: boolean } = {}

local function standLabel(parent: Instance, pos: UDim2, size: UDim2, align: Enum.TextXAlignment, color: Color3): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position, l.Size = pos, size
	l.Font = Enum.Font.GothamBold
	l.TextScaled = true
	l.TextXAlignment = align
	l.TextColor3 = color
	l.Text = ""
	l.Parent = parent
	return l
end

local function buildStand(): { { rank: TextLabel, name: TextLabel, value: TextLabel } }?
	local node: Instance? = workspace
	for _, name in { "World", "Decor", "Props", "LeaderboardStand", "BoardPanel", "BoardGui", "Board" } do
		node = if node ~= nil then node:FindFirstChild(name) else nil
	end
	local board = node
	if board == nil or not board:IsA("Frame") then
		return nil
	end
	local white, yellow = Color3.fromHex(Config.Colors.UiLight), Color3.fromHex(Config.Colors.Yellow)
	local title = standLabel(board, UDim2.fromScale(0.05, 0.02), UDim2.fromScale(0.9, 0.1), Enum.TextXAlignment.Center, yellow)
	title.Text = "TOP PLAYERS - CELLS CAPTURED"
	local rows = {}
	local rowH = 0.8 / STAND_ROWS
	for i = 1, STAND_ROWS do
		local y = 0.15 + (i - 1) * rowH
		rows[i] = {
			rank = standLabel(board, UDim2.fromScale(0.05, y), UDim2.fromScale(0.1, rowH * 0.85), Enum.TextXAlignment.Left, yellow),
			name = standLabel(board, UDim2.fromScale(0.17, y), UDim2.fromScale(0.5, rowH * 0.85), Enum.TextXAlignment.Left, white),
			value = standLabel(board, UDim2.fromScale(0.68, y), UDim2.fromScale(0.27, rowH * 0.85), Enum.TextXAlignment.Right, white),
		}
	end
	return rows
end

local function renderStand()
	if standRows == nil then
		standRows = buildStand()
	end
	local rows = standRows
	if rows == nil then
		return
	end
	local entries = LeaderboardService.top(STAND_BOARD)
	for i, row in rows do
		local e = entries[i]
		if e == nil then
			row.rank.Text, row.name.Text, row.value.Text = "", "", ""
		else
			row.rank.Text = "#" .. i
			row.name.Text = nameCache[e.userId] or "Player"
			row.value.Text = tostring(e.value)
			if nameCache[e.userId] == nil and not nameResolving[e.userId] then
				nameResolving[e.userId] = true
				task.spawn(function()
					local ok, name = pcall(function()
						return Players:GetNameFromUserIdAsync(e.userId)
					end)
					nameResolving[e.userId] = nil
					if ok and type(name) == "string" then
						nameCache[e.userId] = name
						renderStand()
					end
				end)
			end
		end
	end
end

local function updateLeaderboardStand(board: string, _entries: { any })
	if board == STAND_BOARD then
		renderStand()
	end
end
LeaderboardService.changed:Connect(updateLeaderboardStand)
renderStand()

MonetizationService.onProductBought = function(player: Player, productKey: string, robux: number)
	AnalyticsService.log(player, "product_bought", { id = productKey, robux = robux })
	if productKey == "starterPack" then
		AnalyticsService.log(player, "offer_bought", { id = productKey })
	end
end

-- 4. request router ---------------------------------------------------------------------------------

type Handler = (Player, ...any) -> (boolean, any)

local handlers: { [string]: Handler } = {
	BuyUpgrade = function(player: Player, upgradeId: any): (boolean, any)
		local ok, result = UpgradeService.buy(player, upgradeId)
		if ok then
			ArenaService.refreshWalkSpeed(player)
			AnalyticsService.log(player, "upgrade_buy", { id = upgradeId, level = result.level })
			AnalyticsService.funnelOnce(player, 3, "first_upgrade")
		end
		return ok, result
	end,
	BuyItem = function(player: Player, itemId: any): (boolean, any)
		local ok, result = ShopService.buyItem(player, itemId)
		if ok then
			AnalyticsService.log(player, "item_buy", { id = itemId, currency = result.currency })
		end
		return ok, result
	end,
	Equip = function(player: Player, itemId: any): (boolean, any)
		return ShopService.equip(player, itemId)
	end,
	ClaimDaily = function(player: Player): (boolean, any)
		local ok, result = RewardService.claimDaily(player)
		if ok then
			AnalyticsService.log(player, "daily_claim", { day = result.streak })
			if result.streak >= #Catalog.daily then
				BadgeService.award(player, "streak7")
			end
		end
		return ok, result
	end,
	ClaimPlaytime = function(player: Player, index: any): (boolean, any)
		return RewardService.claimPlaytime(player, index)
	end,
	ClaimQuest = function(player: Player, index: any): (boolean, any)
		local ok, result = RewardService.claimQuest(player, index)
		if ok then
			AnalyticsService.log(player, "quest_claim", { id = result.id })
		end
		return ok, result
	end,
	RedeemCode = function(player: Player, code: any): (boolean, any)
		local ok, result = RewardService.redeemCode(player, code)
		if ok then
			AnalyticsService.log(player, "code_redeem", { code = code })
		end
		return ok, result
	end,
	Rebirth = function(player: Player): (boolean, any)
		local ok, result = UpgradeService.rebirth(player)
		if ok then
			ArenaService.refreshWalkSpeed(player)
			LeaderboardService.submit(player, "crowns", result.crowns)
			BadgeService.award(player, "firstRebirth")
			AnalyticsService.log(player, "rebirth", { count = result.crowns })
		end
		return ok, result
	end,
	Respawn = function(player: Player): (boolean, any)
		return ArenaService.respawn(player)
	end,
	DeclineSecondChance = function(player: Player): (boolean, any)
		return ArenaService.declineSecondChance(player)
	end,
	SetSetting = function(player: Player, key: any, value: any): (boolean, any)
		if type(key) ~= "string" or SETTINGS[key] == nil or type(value) ~= "boolean" then
			return false, "bad_args"
		end
		if DataService.get(player) == nil then
			return false, "no_profile"
		end
		DataService.update(player, function(p)
			(p.settings :: any)[key] = value
		end)
		return true, value
	end,
	TutorialDone = function(player: Player): (boolean, any)
		if DataService.get(player) == nil then
			return false, "no_profile"
		end
		DataService.update(player, function(p)
			p.tutorialDone = true
		end)
		AnalyticsService.log(player, "tutorial_step", { n = "done" })
		return true, nil
	end,
	-- Client startup ping: the router below already re-sends the snapshot on a player's first Request.
	Ready = function(_player: Player): (boolean, any)
		return true, nil
	end,
	StarterOfferSeen = function(player: Player): (boolean, any)
		MonetizationService.markStarterOfferSeen(player)
		AnalyticsService.log(player, "offer_shown", { id = "starterPack" })
		return true, nil
	end,
}

local buckets: { [Player]: { tokens: number, last: number } } = {}
local readySent: { [Player]: boolean } = {}

local function allowRequest(player: Player): boolean
	local now = os.clock()
	local rate = Config.Security.RequestsPerSecond
	local b = buckets[player]
	if b == nil then
		b = { tokens = rate, last = now }
		buckets[player] = b
	end
	local bucket = b :: { tokens: number, last: number }
	bucket.tokens = math.min(rate, bucket.tokens + (now - bucket.last) * rate)
	bucket.last = now
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

local function validArg(a: any): boolean
	local t = type(a)
	if t == "string" then
		return #a <= MAX_STRING
	end
	return t == "nil" or t == "boolean" or t == "number"
end

requestFn.OnServerInvoke = function(player: Player, name: any, ...: any): (boolean, any)
	if type(name) ~= "string" or (Remotes.Requests :: any)[name] ~= name or handlers[name] == nil then
		return false, "bad_request"
	end
	if not allowRequest(player) then
		return false, "rate_limited"
	end
	local n = select("#", ...)
	if n > MAX_ARGS then
		return false, "bad_args"
	end
	local args = { ... }
	for i = 1, n do
		if not validArg(args[i]) then
			return false, "bad_args"
		end
	end
	-- The first Request proves the client's listeners are connected: (re)send the arena snapshot.
	if not readySent[player] then
		readySent[player] = true
		ArenaService.clientReady(player)
	end
	local ok, result, extra = pcall(handlers[name], player, table.unpack(args, 1, n))
	if not ok then
		warn("[Main] request " .. name .. " failed:", result)
		return false, "server_error"
	end
	return result, extra
end

-- 5. players ---------------------------------------------------------------------------------------

local function onPlayerAdded(player: Player)
	joinedAt[player] = os.time()
	coinsEarned[player] = 0
	local profile = DataService.load(player)
	if profile == nil or player.Parent == nil then
		return
	end
	ShopService.reconcile(player)
	sendProfile(player)
	ArenaService.join(player)
	AnalyticsService.log(player, "session_start")
	AnalyticsService.funnelOnce(player, 1, "join")
	task.delay(FUNNEL_MINUTE_10, function()
		if player.Parent ~= nil then
			AnalyticsService.funnelOnce(player, 6, "minute_10")
		end
	end)
end

Players.PlayerAdded:Connect(function(player: Player)
	task.spawn(onPlayerAdded, player)
end)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player: Player)
	ArenaService.leave(player)
	local joined = joinedAt[player]
	if joined ~= nil then
		AnalyticsService.log(player, "session_end", { seconds = os.time() - joined, coinsEarned = coinsEarned[player] or 0 })
	end
	joinedAt[player] = nil
	coinsEarned[player] = nil
	dirty[player] = nil
	buckets[player] = nil
	readySent[player] = nil
	DataService.release(player)
end)
