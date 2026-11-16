--!strict
-- Server bots (GDD G10): keeps the arena at Config.Arena.MinRunners with BotBrain-driven runners.
-- Rigs live in workspace.Bots, named tostring(runnerId). A bot starts as a simple anchored stand-in
-- rig; its R15 avatar (a joining player's friend, else a Config fallback) is built asynchronously
-- and swapped in. The arena sim stays authoritative: the avatar walks after it with Humanoid:MoveTo.
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local BotBrain = require(Shared.BotBrain)
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local Types = require(Shared.Types)
local ArenaService = require(script.Parent.ArenaService)
local DataService = require(script.Parent.DataService)

type RunnerInfo = Types.RunnerInfo
type Bot = {
	id: number,
	info: RunnerInfo,
	brain: BotBrain.State,
	px: number, -- continuous position in cell units; the sim floors it
	py: number,
	model: Model,
	body: Part?, -- stand-in rig parts; nil once the avatar is swapped in
	head: Part?,
	respawnAt: number?,
	avatarUserId: number?,
	hum: Humanoid?, -- set once the avatar is swapped in
	root: BasePart?,
	lift: number, -- avatar root height above the floor
	run: AnimationTrack?,
	idle: AnimationTrack?,
	moving: boolean?,
}
type PoolEntry = { userId: number, displayName: string, owner: Player }

local NAMES = {
	"PixelPanda", "TurboTaco", "SunnySprout", "ZippyZebra", "MangoMoose", "CosmoCub", "BubbleBolt", "NovaNugget",
	"JellyJet", "MapleMarble", "RocketRadish", "PeppyPenguin", "WaffleWizard", "BreezyBean", "LunaLlama", "CometCookie",
	"DizzyDolphin", "FizzyFox", "GummyGecko", "HappyHedgehog", "IcyIguana", "JollyJaguar", "KiwiKite", "LemonLynx",
	"MintyMole", "NoodleNewt", "OtterOrbit", "PuddlePuffin", "QuirkyQuail", "RaspberryRay", "SnappySquid", "TofuTiger",
	"UmbrellaUnicorn", "VelvetVole", "WobblyWalrus", "YoyoYak", "ZestyZinnia", "BlueberryBlitz", "CloudyCamel", "DoodleDuck",
}

local GENTLE_RADIUS = 20 -- cells
local TUTORIAL_NEAR_CELLS = 25 -- a new player should have a bot this close (GDD G7.4)
local TUTORIAL_RELEASE_CELLS = 15 -- a steered bot is released once this close
local BODY_HEIGHT = 4
local BODY_WIDTH = 3
local HEAD_SIZE = 2
local RESPAWN_JITTER_MIN, RESPAWN_JITTER_MAX = 1, 3
local MAINTAIN_PERIOD = 1
local FLOOR_Y = Config.Arena.FloorY
local CELLS_PER_SECOND = Config.Arena.BaseWalkSpeed / Config.Arena.CellSize

local BotService = {}

local bots: { [number]: Bot } = {}
local rng = Random.new()
local folder: Folder? = nil
local maintainAcc = 0
local warnedBrain = false
local started = false
-- One bot at a time is steered toward a tutorial player who has no bot nearby (GAP-07).
local steer: { botId: number, targetId: number }? = nil
local BOT_GROUP = "TurfBots" -- avatar rigs: collide with the floor (Default), not with players or each other
local PLAYER_GROUP = "TurfPlayers" -- player characters: same as Default except they pass through bots
local pool: { PoolEntry } = {} -- friends of players in the server, tagged with that player
local templates: { [number]: Model } = {} -- built avatars by userId, kept in ServerStorage
local templateOrder: { number } = {}
local building: { [number]: boolean } = {}
local failed: { [number]: boolean } = {} -- userIds whose avatar could not be built (not retried)
local store: Folder? = nil

local function pickName(): string
	local used: { [string]: boolean } = {}
	for _, b in bots do
		used[b.info.name] = true
	end
	local start = rng:NextInteger(1, #NAMES)
	for k = 0, #NAMES - 1 do
		local name = NAMES[(start + k - 1) % #NAMES + 1]
		if not used[name] then
			return name
		end
	end
	return NAMES[start]
end

-- A default or common cosmetic of the given type, so bots look varied but never premium.
local function pickCosmetic(itemType: string): string
	local list: { string } = {}
	local fallback = ""
	for _, item in Catalog.ofType(itemType) do
		if item.default == true then
			fallback = item.id
		end
		if item.default == true or item.rarity == "common" then
			table.insert(list, item.id)
		end
	end
	if #list == 0 then
		return fallback
	end
	return list[rng:NextInteger(1, #list)]
end

local function makeRig(info: RunnerInfo): (Model, Part, Part)
	local color = Color3.fromHex(Config.Colors.Players[info.colorIndex] or Config.Colors.Players[1])
	local model = Instance.new("Model")
	model.Name = tostring(info.id)

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Cylinder -- cylinders run along X; placeRig turns it upright
	body.Size = Vector3.new(BODY_HEIGHT, BODY_WIDTH, BODY_WIDTH)
	body.Color = color
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.CanQuery = false
	body.CanTouch = false
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(HEAD_SIZE, HEAD_SIZE, HEAD_SIZE)
	head.Color = color
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.CanQuery = false
	head.CanTouch = false
	head.Parent = model

	local gui = Instance.new("BillboardGui")
	gui.Name = "NameTag"
	gui.Size = UDim2.fromOffset(160, 30)
	gui.StudsOffset = Vector3.new(0, HEAD_SIZE, 0)
	gui.MaxDistance = 150
	gui.Adornee = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = info.name
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	gui.Parent = head

	model.PrimaryPart = body
	return model, body, head
end

local function animate(b: Bot, moving: boolean, walkSpeed: number)
	local run, idle = b.run, b.idle
	if run == nil or idle == nil then
		return
	end
	if b.moving ~= moving then
		b.moving = moving
		if moving then
			idle:Stop(0.2)
			run:Play(0.2)
		else
			run:Stop(0.2)
			idle:Play(0.2)
		end
	end
	if moving then
		run:AdjustSpeed(walkSpeed / Config.Bots.RunAnimationSpeed)
	end
end

-- Stand-in: anchored parts placed on the simulated position. Avatar: walks with Humanoid:MoveTo
-- toward a point a little ahead of the simulated position along (dx, dy) at the simulated speed
-- (cells/s); PivotTo only when `snap` or when it drifted further than RigSnapDistance.
local function placeRig(b: Bot, snap: boolean, dx: number, dy: number, speed: number)
	local grid = ArenaService.sim.grid
	local wx, wz = grid:cellToWorld(b.px - 0.5, b.py - 0.5)
	local hum, root = b.hum, b.root
	if hum == nil or root == nil then
		local body, head = b.body, b.head
		if body ~= nil and head ~= nil then
			body.CFrame = CFrame.new(wx, FLOOR_Y + BODY_HEIGHT / 2, wz) * CFrame.Angles(0, 0, math.pi / 2)
			head.CFrame = CFrame.new(wx, FLOOR_Y + BODY_HEIGHT + HEAD_SIZE / 2, wz)
		end
		return
	end
	local ahead = Config.Bots.RigLookAheadCells
	local tx, tz = grid:cellToWorld(b.px - 0.5 + dx * ahead, b.py - 0.5 + dy * ahead)
	local rp = root.Position
	if
		snap
		or Vector3.new(rp.X - wx, 0, rp.Z - wz).Magnitude > Config.Bots.RigSnapDistance
		or math.abs(rp.Y - (FLOOR_Y + b.lift)) > Config.Bots.RigSnapHeight
	then
		local pos = Vector3.new(wx, FLOOR_Y + b.lift, wz)
		local look = if dx ~= 0 or dy ~= 0 then Vector3.new(tx - wx, 0, tz - wz) else root.CFrame.LookVector * Vector3.new(1, 0, 1)
		b.model:PivotTo(if look.Magnitude > 1e-3 then CFrame.new(pos, pos + look) else CFrame.new(pos))
		root.AssemblyLinearVelocity = Vector3.zero
	end
	local walkSpeed = math.max(speed * Config.Arena.CellSize * Config.Bots.RigSpeedScale, 1)
	hum.WalkSpeed = walkSpeed
	hum:MoveTo(Vector3.new(tx, FLOOR_Y, tz))
	animate(b, dx ~= 0 or dy ~= 0, walkSpeed)
end

-- Parents the rig into workspace.Bots on the simulated position; avatar roots stay server-owned.
local function showRig(b: Bot)
	placeRig(b, true, 0, 0, 0)
	b.model.Parent = folder
	local root = b.root
	if root ~= nil then
		pcall(root.SetNetworkOwner, root, nil)
	end
end

-- Swaps the stand-in rig for a clone of a built avatar template (keeps the simulated state).
local function applyAvatar(b: Bot, template: Model)
	local m = template:Clone()
	local hum = m:FindFirstChildOfClass("Humanoid")
	local root = m.PrimaryPart or m:FindFirstChild("HumanoidRootPart")
	if hum == nil or root == nil or not root:IsA("BasePart") then
		m:Destroy()
		return
	end
	m.Name = tostring(b.id)
	m.PrimaryPart = root
	hum.DisplayName = b.info.name
	hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CollisionGroup = BOT_GROUP
		end
	end
	local animator = hum:FindFirstChildOfClass("Animator")
	if animator == nil then
		local a = Instance.new("Animator")
		a.Parent = hum
		animator = a
	end
	local function load(id: string): AnimationTrack?
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		local ok, track = pcall((animator :: Animator).LoadAnimation, animator :: Animator, anim)
		if ok and track ~= nil then
			track.Looped = true
			return track
		end
		return nil
	end
	local visible = b.model.Parent ~= nil
	b.model:Destroy()
	b.model, b.body, b.head = m, nil, nil
	b.hum, b.root = hum, root
	b.lift = hum.HipHeight + root.Size.Y / 2
	b.run, b.idle, b.moving = load(Config.Bots.RunAnimationId), load(Config.Bots.IdleAnimationId), nil
	if visible then
		showRig(b)
	end
end

-- Builds (once per userId, off the caller's thread) and caches the avatar, then applies it to every
-- bot still waiting for it. On failure the bot keeps its stand-in rig.
local function requestAvatar(userId: number)
	local cached = templates[userId]
	if cached ~= nil then
		for _, b in bots do
			if b.avatarUserId == userId and b.hum == nil then
				applyAvatar(b, cached)
			end
		end
		return
	end
	if building[userId] or failed[userId] then
		return
	end
	building[userId] = true
	task.spawn(function()
		-- Always R15, whatever the friend's own rig type (R6 sinks into the floor and does not animate).
		local ok, model = pcall(function()
			local desc = Players:GetHumanoidDescriptionFromUserId(userId)
			return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
		end)
		building[userId] = nil
		if not ok or typeof(model) ~= "Instance" or not (model :: Instance):IsA("Model") then
			failed[userId] = true
			return
		end
		local m = model :: Model
		for _, d in m:GetDescendants() do
			if d:IsA("LuaSourceContainer") then
				d:Destroy()
			end
		end
		m.Name = tostring(userId)
		m.Parent = store
		templates[userId] = m
		table.insert(templateOrder, userId)
		while #templateOrder > Config.Bots.AvatarCacheMax do
			local old = table.remove(templateOrder, 1) :: number
			local t = templates[old]
			templates[old] = nil
			if t ~= nil then
				t:Destroy()
			end
		end
		requestAvatar(userId)
	end)
end

-- A friend from the pool not worn by another bot and not in the server, else a fallback avatar
-- with a generated name. Returns (avatar userId or nil, runner name).
local function pickAvatar(): (number?, string)
	local inUse: { [number]: boolean } = {}
	for _, b in bots do
		local uid = b.avatarUserId
		if uid ~= nil then
			inUse[uid] = true
		end
	end
	local function free(uid: number): boolean
		return not inUse[uid] and not failed[uid] and Players:GetPlayerByUserId(uid) == nil
	end
	if #pool > 0 then
		local start = rng:NextInteger(1, #pool)
		for k = 0, #pool - 1 do
			local e = pool[(start + k - 1) % #pool + 1]
			if free(e.userId) then
				return e.userId, e.displayName
			end
		end
	end
	for _, uid in Config.Bots.FallbackUserIds do
		if free(uid) then
			return uid, pickName()
		end
	end
	return nil, pickName()
end

-- Adds up to FriendsPerPlayer of the player's friends to the pool (yields; run off the join path).
local function fetchFriends(player: Player)
	local ok, pages = pcall(Players.GetFriendsAsync, Players, player.UserId)
	if not ok then
		return
	end
	local got: { PoolEntry } = {}
	local cap = Config.Bots.FriendsPerPlayer
	while #got < cap do
		local okPage, page = pcall(function()
			return (pages :: any):GetCurrentPage()
		end)
		if not okPage or type(page) ~= "table" then
			break
		end
		for _, f in page do
			if #got >= cap then
				break
			end
			local id, name = f.Id, f.DisplayName or f.Username
			if type(id) == "number" and id > 0 and type(name) == "string" then
				table.insert(got, { userId = id, displayName = name, owner = player })
			end
		end
		if (pages :: any).IsFinished then
			break
		end
		if not pcall(function()
			(pages :: any):AdvanceToNextPageAsync()
		end) then
			break
		end
	end
	if player.Parent ~= Players then
		return
	end
	local have: { [number]: boolean } = {}
	for _, e in pool do
		have[e.userId] = true
	end
	for _, e in got do
		if not have[e.userId] then
			have[e.userId] = true
			table.insert(pool, e)
		end
	end
end

local function dropFriends(player: Player)
	for i = #pool, 1, -1 do
		if pool[i].owner == player then
			table.remove(pool, i)
		end
	end
end

local function setPlayerGroup(char: Model)
	local function set(d: Instance)
		if d:IsA("BasePart") then
			d.CollisionGroup = PLAYER_GROUP
		end
	end
	for _, d in char:GetDescendants() do
		set(d)
	end
	char.DescendantAdded:Connect(set)
end

local function watchPlayer(player: Player)
	task.spawn(fetchFriends, player)
	if player.Character ~= nil then
		setPlayerGroup(player.Character)
	end
	player.CharacterAdded:Connect(setPlayerGroup)
end

local function hideBot(b: Bot)
	b.model.Parent = nil
	ArenaService.botPositions[b.id] = nil
end

-- Snap to the runner's current cell (after spawn, respawn or a server-side recycle).
local function resetBot(b: Bot)
	local r = ArenaService.sim:runner(b.id)
	if r == nil then
		return
	end
	b.px, b.py = r.x + 0.5, r.y + 0.5
	b.respawnAt = nil
	BotBrain.reset(b.brain)
	ArenaService.botPositions[b.id] = { x = b.px, y = b.py }
	b.model.Name = tostring(b.id)
	showRig(b)
end

local function spawnBot(now: number)
	local tiers = Config.Bots.Tiers
	local tier = tiers[rng:NextInteger(1, #tiers)]
	local avatarUserId, name = pickAvatar()
	local info: RunnerInfo = {
		id = 0,
		userId = 0, -- stays 0: bots are off the leaderboards and never matched to a Player
		name = name,
		colorIndex = ArenaService.freeColorIndex(),
		skin = pickCosmetic("skin"),
		trail = pickCosmetic("trail"),
		effect = pickCosmetic("effect"),
		isBot = true,
	}
	local id = ArenaService.sim:addRunner(info, Config.Arena.StartPatch, Config.Arena.SpawnShield, now)
	local model, body, head = makeRig(info)
	local b: Bot = {
		id = id,
		info = info,
		brain = BotBrain.new(tier, function(): number
			return rng:NextNumber()
		end),
		px = 0,
		py = 0,
		model = model,
		body = body,
		head = head,
		respawnAt = nil,
		avatarUserId = avatarUserId,
		lift = 0,
	}
	bots[id] = b
	resetBot(b)
	if avatarUserId ~= nil then
		requestAvatar(avatarUserId)
	end
end

local function removeBot(b: Bot, now: number)
	bots[b.id] = nil
	ArenaService.botPositions[b.id] = nil
	b.model:Destroy()
	local r = ArenaService.sim:runner(b.id)
	if r ~= nil and r.info == b.info then
		ArenaService.sim:removeRunner(b.id, now)
	end
end

-- Bot count follows the number of players in the server (not live player runners), so a player's
-- character respawn does not make bots churn.
local function maintain(now: number)
	local target = math.max(0, Config.Arena.MinRunners - #Players:GetPlayers())
	local count = 0
	for _ in bots do
		count += 1
	end
	if count < target then
		for _ = 1, target - count do
			spawnBot(now)
		end
	elseif count > target then
		-- A player joined: drop the bot with the fewest cells (one wearing a player now in the server
		-- goes first). removeRunner clears its trail and makes all its cells neutral (no killer share).
		local sim = ArenaService.sim
		local pick: Bot? = nil
		local best = math.huge
		for id, b in bots do
			local uid = b.avatarUserId
			local score = if uid ~= nil and Players:GetPlayerByUserId(uid) ~= nil then -1 else sim:cellsOf(id)
			if score < best then
				pick, best = b, score
			end
		end
		if pick ~= nil then
			removeBot(pick, now)
		end
	end
end

local function cellDist2(a: any, b: any): number
	return (a.x - b.x) ^ 2 + (a.y - b.y) ^ 2
end

-- Runs once per maintain period: keeps or ends the current steer, or starts one.
local function updateSteer()
	local sim = ArenaService.sim
	local cur = steer
	if cur ~= nil then
		local br, tr = sim:runner(cur.botId), sim:runner(cur.targetId)
		if br == nil or tr == nil or not br.alive or not tr.alive or bots[cur.botId] == nil
			or cellDist2(br, tr) <= TUTORIAL_RELEASE_CELLS ^ 2 then
			steer = nil
		end
		return
	end
	local now = ArenaService.now()
	local gentleSet: { [number]: boolean } = {}
	for _, id in ArenaService.gentleRunnerIds(now) do
		gentleSet[id] = true
	end
	for _, player in Players:GetPlayers() do
		local id = ArenaService.runnerIdOf(player)
		local profile = DataService.get(player)
		local t = sim:runner(id)
		if gentleSet[id] and profile ~= nil and not profile.tutorialDone and t ~= nil and t.alive then
			local nearest, farthest, farD = math.huge, nil :: any, -1
			for botId, b in bots do
				local r = sim:runner(botId)
				if r ~= nil and r.alive and r.info == b.info then
					local d = cellDist2(r, t)
					nearest = math.min(nearest, d)
					if d > farD and #r.trail == 0 then
						farthest, farD = botId, d
					end
				end
			end
			if nearest > TUTORIAL_NEAR_CELLS ^ 2 and farthest ~= nil then
				steer = { botId = farthest :: number, targetId = id }
				return
			end
		end
	end
end

local function approach(value: number, target: number, maxDelta: number): number
	if math.abs(target - value) <= maxDelta then
		return target
	end
	return value + math.sign(target - value) * maxDelta
end

local function moveBot(b: Bot, r: any, now: number, dt: number, gentle: { number }, gentleSet: { [number]: boolean })
	local sim = ArenaService.sim
	local grid = sim.grid
	local size = grid.size
	if math.abs(math.floor(b.px) - r.x) > 1 or math.abs(math.floor(b.py) - r.y) > 1 then
		resetBot(b)
	end

	local dx, dy = 0, 0
	local ok, a, c = pcall(BotBrain.step, b.brain, sim, b.id, now)
	if ok then
		dx, dy = math.sign(a or 0), math.sign(c or 0)
	elseif not warnedBrain then
		warnedBrain = true
		warn("[BotService] BotBrain.step failed:", a)
	end
	if dx ~= 0 and dy ~= 0 then
		dy = 0
	end
	local sv = steer
	if sv ~= nil and sv.botId == b.id then
		local t = sim:runner(sv.targetId)
		if t ~= nil then
			local tx, ty = t.x - r.x, t.y - r.y
			if math.abs(tx) >= math.abs(ty) then
				dx, dy = math.sign(tx), 0
			else
				dx, dy = 0, math.sign(ty)
			end
		end
	end

	-- Never cut a player in their gentle window: stop before entering their trail.
	if dx ~= 0 or dy ~= 0 then
		local nx, ny = math.floor(b.px) + dx, math.floor(b.py) + dy
		if grid:inBounds(nx, ny) then
			for _, owner in sim:trailOwnersAt(grid:index(nx, ny)) do
				if gentleSet[owner] then
					dx, dy = 0, 0
					break
				end
			end
		end
	end

	local speed = CELLS_PER_SECOND
	for _, id in gentle do
		local g = sim:runner(id)
		if g ~= nil and g.alive then
			local ddx, ddy = g.x - r.x, g.y - r.y
			if ddx * ddx + ddy * ddy <= GENTLE_RADIUS * GENTLE_RADIUS then
				speed *= Config.Bots.GentleSpeedScale
				break
			end
		end
	end
	local step = speed * dt
	-- Moving along one axis re-centres the other so the bot stays in its row/column.
	if dx ~= 0 then
		b.px += dx * step
		b.py = approach(b.py, math.floor(b.py) + 0.5, step)
	elseif dy ~= 0 then
		b.py += dy * step
		b.px = approach(b.px, math.floor(b.px) + 0.5, step)
	end
	b.px = math.clamp(b.px, 0.5, size - 0.5)
	b.py = math.clamp(b.py, 0.5, size - 0.5)
	ArenaService.botPositions[b.id] = { x = b.px, y = b.py }
	placeRig(b, false, dx, dy, speed)
end

local function preStep(now: number, dt: number)
	maintainAcc += dt
	if maintainAcc >= MAINTAIN_PERIOD then
		maintainAcc = 0
		maintain(now)
		updateSteer()
	end
	local sim = ArenaService.sim
	local gentle = ArenaService.gentleRunnerIds(now)
	local gentleSet: { [number]: boolean } = {}
	for _, id in gentle do
		gentleSet[id] = true
	end
	for id, b in table.clone(bots) do
		local r = sim:runner(id)
		if r == nil or r.info ~= b.info then
			removeBot(b, now)
		elseif not r.alive then
			local at = b.respawnAt
			if at == nil then
				sim:releaseVictim(id)
				b.respawnAt = now + Config.Arena.RespawnDelay + rng:NextNumber(RESPAWN_JITTER_MIN, RESPAWN_JITTER_MAX)
				hideBot(b)
			elseif now >= at then
				sim:respawn(id, Config.Arena.StartPatch, Config.Arena.SpawnShield, now)
				resetBot(b)
			end
		else
			moveBot(b, r, now, dt, gentle, gentleSet)
		end
	end
end

local function onEvent(ev: Types.ArenaEvent)
	local e = ev :: any
	if e.kind == "cut" then
		local b = bots[e.victim]
		if b ~= nil then
			ArenaService.sim:releaseVictim(b.id)
			b.respawnAt = ArenaService.now()
				+ Config.Arena.RespawnDelay
				+ rng:NextNumber(RESPAWN_JITTER_MIN, RESPAWN_JITTER_MAX)
			hideBot(b)
		end
	elseif e.kind == "spawn" then
		local b = bots[e.runner.id]
		if b ~= nil and e.runner == b.info then
			resetBot(b)
		end
	elseif e.kind == "despawn" then
		local b = bots[e.id]
		if b ~= nil then
			hideBot(b)
		end
	end
end

function BotService.start()
	if started then
		return
	end
	started = true
	local existing = workspace:FindFirstChild("Bots")
	if existing ~= nil then
		existing:Destroy()
	end
	local f = Instance.new("Folder")
	f.Name = "Bots"
	f.Parent = workspace
	folder = f
	local s = Instance.new("Folder")
	s.Name = "BotAvatars"
	s.Parent = ServerStorage
	store = s
	pcall(function()
		for _, g in { BOT_GROUP, PLAYER_GROUP } do
			if not PhysicsService:IsCollisionGroupRegistered(g) then
				PhysicsService:RegisterCollisionGroup(g)
			end
		end
		PhysicsService:CollisionGroupSetCollidable(BOT_GROUP, BOT_GROUP, false)
		PhysicsService:CollisionGroupSetCollidable(BOT_GROUP, PLAYER_GROUP, false)
		-- Players never touch each other (no flinging); both groups still collide with Default (floor, walls).
		PhysicsService:CollisionGroupSetCollidable(PLAYER_GROUP, PLAYER_GROUP, false)
	end)
	for _, p in Players:GetPlayers() do
		watchPlayer(p)
	end
	Players.PlayerAdded:Connect(watchPlayer)
	Players.PlayerRemoving:Connect(dropFriends)
	ArenaService.preStep = preStep
	ArenaService.onEvent:Connect(onEvent)
end

return BotService
