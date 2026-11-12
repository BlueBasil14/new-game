--!strict
-- Server bots (GDD G10): keeps the arena at Config.Arena.MinRunners with BotBrain-driven runners
-- shown as simple anchored rigs. Rigs live in workspace.Bots, named tostring(runnerId).
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local BotBrain = require(Shared.BotBrain)
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local Types = require(Shared.Types)
local ArenaService = require(script.Parent.ArenaService)

type RunnerInfo = Types.RunnerInfo
type Bot = {
	id: number,
	info: RunnerInfo,
	brain: BotBrain.State,
	px: number, -- continuous position in cell units; the sim floors it
	py: number,
	model: Model,
	body: Part,
	head: Part,
	respawnAt: number?,
}

local NAMES = {
	"PixelPanda", "TurboTaco", "SunnySprout", "ZippyZebra", "MangoMoose", "CosmoCub", "BubbleBolt", "NovaNugget",
	"JellyJet", "MapleMarble", "RocketRadish", "PeppyPenguin", "WaffleWizard", "BreezyBean", "LunaLlama", "CometCookie",
	"DizzyDolphin", "FizzyFox", "GummyGecko", "HappyHedgehog", "IcyIguana", "JollyJaguar", "KiwiKite", "LemonLynx",
	"MintyMole", "NoodleNewt", "OtterOrbit", "PuddlePuffin", "QuirkyQuail", "RaspberryRay", "SnappySquid", "TofuTiger",
	"UmbrellaUnicorn", "VelvetVole", "WobblyWalrus", "YoyoYak", "ZestyZinnia", "BlueberryBlitz", "CloudyCamel", "DoodleDuck",
}

local GENTLE_RADIUS = 20 -- cells
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

local function placeRig(b: Bot)
	local wx, wz = ArenaService.sim.grid:cellToWorld(b.px - 0.5, b.py - 0.5)
	b.body.CFrame = CFrame.new(wx, FLOOR_Y + BODY_HEIGHT / 2, wz) * CFrame.Angles(0, 0, math.pi / 2)
	b.head.CFrame = CFrame.new(wx, FLOOR_Y + BODY_HEIGHT + HEAD_SIZE / 2, wz)
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
	placeRig(b)
	b.model.Parent = folder
end

local function spawnBot(now: number)
	local tiers = Config.Bots.Tiers
	local tier = tiers[rng:NextInteger(1, #tiers)]
	local info: RunnerInfo = {
		id = 0,
		userId = 0,
		name = pickName(),
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
	}
	bots[id] = b
	resetBot(b)
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
		local sim = ArenaService.sim
		local pick: Bot? = nil
		local best = math.huge
		for id, b in bots do
			local score = if sim:isAlive(id) then sim:cellsOf(id) else -1
			if score < best then
				pick, best = b, score
			end
		end
		if pick ~= nil then
			removeBot(pick, now)
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
	placeRig(b)
end

local function preStep(now: number, dt: number)
	maintainAcc += dt
	if maintainAcc >= MAINTAIN_PERIOD then
		maintainAcc = 0
		maintain(now)
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
	ArenaService.preStep = preStep
	ArenaService.onEvent:Connect(onEvent)
end

return BotService
