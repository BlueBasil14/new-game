--!strict
-- Authoritative arena (GDD G2, G11.6): owns the ArenaSim, reads character positions on a fixed
-- tick, applies movement checks, pays out sim events and replicates state. See docs/API_arena.md.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ArenaSim = require(Shared.ArenaSim)
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local Types = require(Shared.Types)

local AnalyticsService = require(script.Parent.AnalyticsService)
local BadgeService = require(script.Parent.BadgeService)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local LeaderboardService = require(script.Parent.LeaderboardService)
local MonetizationService = require(script.Parent.MonetizationService)
local RewardService = require(script.Parent.RewardService)
local ShopService = require(script.Parent.ShopService)
local UpgradeService = require(script.Parent.UpgradeService)

type RunnerInfo = Types.RunnerInfo
type ArenaEvent = Types.ArenaEvent
type Runner = ArenaSim.Runner
type Cell = { x: number, y: number }

type PState = {
	player: Player,
	joinClock: number,
	id: number, -- 0 = no runner
	character: Model?,
	hrp: BasePart?,
	humanoid: Humanoid?,
	connections: { RBXScriptConnection },
	charConnections: { RBXScriptConnection },
	walkSpeed: number,
	prevWalkSpeed: number,
	speedGraceUntil: number,
	lastPos: Vector3?,
	lastTime: number,
	overTicks: number,
	strikes: { number },
	exemptUntil: number,
	settleTarget: Vector3?,
	settleTries: number,
	deathTime: number,
	lifeStart: number,
	lifeCoins: number,
	lifeKills: number,
	pendingUntil: number?,
	secondChanceUsed: boolean,
	respawning: boolean,
	kingAccum: number,
	ready: boolean,
}

local STEP = 1 / Config.Arena.TickRate
local DELTA_PERIOD = 1 / Config.Arena.DeltaRate
local CELL = Config.Arena.CellSize
local HALF = Config.Arena.GridSize * CELL / 2
local FLOOR_Y = Config.Arena.FloorY

local MAX_CATCHUP_STEPS = 5
-- After a server teleport the client keeps reporting its old position for a few frames.
local TELEPORT_EXEMPT = 0.5
local SETTLE_RADIUS = 2 * CELL
local SETTLE_RETRIES = 5
local SPEED_SLACK = 1 -- studs per check, absorbs replication jitter
local SPEED_DROP_GRACE = 1 -- seconds the old speed stays allowed after WalkSpeed drops (client lag)
local MAX_SPEED_WINDOW = 1 -- caps the allowance after a long stand-still
local BELOW_FLOOR = 6
local ABOVE_FLOOR = 20
-- Cut players wait anchored under the floor; the chase camera then still sits above the arena.
local HIDE_DEPTH = 20
local SECOND_CHANCE_GRACE = 20 -- purchase dialogs take time
local ZERO_TURF_RECYCLE = 2
local IDLE_RESPAWN = 30 -- server respawns a released player who never sent Respawn
local CHARACTER_WAIT = 10
local MAP_BADGES = { { pct = 10, key = "map10" }, { pct = 50, key = "map50" } }

local ArenaService = {}

local rng = Random.new()
local sim = ArenaSim.new({
	rng = function(): number
		return rng:NextNumber()
	end,
})

ArenaService.sim = sim
-- Bot target positions in cell units (floored by the sim), written by BotService in preStep.
ArenaService.botPositions = {} :: { [number]: Cell }
-- Single hook run at the start of every sim tick, before positions are read (BotService).
ArenaService.preStep = nil :: ((now: number, dt: number) -> ())?

local eventListeners: { (ArenaEvent) -> () } = {}
-- Callbacks run synchronously, in order, for every drained sim event (after ArenaService handled it).
ArenaService.onEvent = {
	Connect = function(_self: any, fn: (ArenaEvent) -> ())
		table.insert(eventListeners, fn)
		return {
			Disconnect = function()
				local i = table.find(eventListeners, fn)
				if i then
					table.remove(eventListeners, i)
				end
			end,
		}
	end,
}

local states: { [Player]: PState } = {}
local playerById: { [number]: PState } = {}
local orphans: { [number]: boolean } = {} -- runners of players who left, removed after LeaveNeutralDelay
local zeroSince: { [number]: number } = {}
local remotes: { [string]: RemoteEvent } = {}
local started = false

function ArenaService.now(): number
	return os.clock()
end

local function remote(name: string): RemoteEvent
	local r = remotes[name]
	if r == nil then
		local folder = ReplicatedStorage:WaitForChild(Remotes.Folder)
		r = folder:WaitForChild(name) :: RemoteEvent
		remotes[name] = r
	end
	return r :: RemoteEvent
end

-- Only clients that have received a snapshot get incremental updates.
local function broadcast(name: string, ...: any)
	local r = remote(name)
	for player, st in states do
		if st.ready and player.Parent ~= nil then
			r:FireClient(player, ...)
		end
	end
end

local function liveInfos(): { RunnerInfo }
	local out = {}
	for _, r in sim:runners() do
		if r.alive or r.pending then
			table.insert(out, r.info)
		end
	end
	return out
end

function ArenaService.freeColorIndex(): number
	local used: { [number]: boolean } = {}
	local runners = sim:runners()
	for _, r in runners do
		used[r.info.colorIndex] = true
	end
	local n = #Config.Colors.Players
	for i = 1, n do
		if not used[i] then
			return i
		end
	end
	return 1 + #runners % n
end

-- Player runner ids whose session is still inside the bots' gentle window (GDD G7.6).
function ArenaService.gentleRunnerIds(now: number): { number }
	local out = {}
	for id, st in playerById do
		if now - st.joinClock < Config.Bots.GentleSeconds then
			table.insert(out, id)
		end
	end
	return out
end

-- replication --------------------------------------------------------------------------------

local function flushDeltas()
	local changes = sim:drainCellChanges()
	local trails = sim:drainTrailDeltas()
	if #changes > 0 or #trails > 0 then
		broadcast(Remotes.ArenaDelta, sim.grid:encodeIndices(changes), trails)
	end
end

local function sendSnapshot(player: Player)
	local st = states[player]
	if st == nil then
		return
	end
	-- Flush first so deltas already queued are not re-applied on top of the snapshot's trails.
	flushDeltas()
	remote(Remotes.ArenaSnapshot):FireClient(player, sim.grid:encodeRLE(), liveInfos(), if st.id ~= 0 then st.id else nil)
	local trails = {}
	for _, r in sim:runners() do
		if r.alive or r.pending then
			table.insert(trails, { id = r.id, clear = true, append = table.clone(r.trail) })
		end
	end
	remote(Remotes.ArenaDelta):FireClient(player, sim.grid:encodeIndices({}), trails)
	st.ready = true
end

-- Called by the request router on a client's first Request (its UI is listening by then).
function ArenaService.clientReady(player: Player)
	if states[player] ~= nil then
		sendSnapshot(player)
	end
end

-- characters ---------------------------------------------------------------------------------

local function cellCFrame(st: PState, cx: number, cy: number): CFrame
	local wx, wz = sim.grid:cellToWorld(cx, cy)
	local lift = 3
	local hrp, humanoid = st.hrp, st.humanoid
	if hrp ~= nil and humanoid ~= nil then
		lift = math.max(humanoid.HipHeight, 2) + hrp.Size.Y / 2 + 0.5
	end
	return CFrame.new(wx, FLOOR_Y + lift, wz)
end

local function teleport(st: PState, target: CFrame, now: number)
	local char, hrp = st.character, st.hrp
	if char == nil or hrp == nil then
		return
	end
	char:PivotTo(target)
	hrp.AssemblyLinearVelocity = Vector3.zero
	st.exemptUntil = now + TELEPORT_EXEMPT
	st.settleTarget = target.Position
	st.lastPos = nil
	st.overTicks = 0
end

local function placeAtCell(st: PState, cx: number, cy: number, now: number)
	local hrp, humanoid = st.hrp, st.humanoid
	if hrp == nil or humanoid == nil then
		return
	end
	hrp.Anchored = false
	humanoid.WalkSpeed = st.walkSpeed
	st.settleTries = 0
	teleport(st, cellCFrame(st, cx, cy), now)
	-- Anchoring (hideCharacter) drops network ownership; hand control back to the player.
	pcall(function()
		hrp:SetNetworkOwner(st.player)
	end)
end

local function hideCharacter(st: PState)
	local char, hrp, humanoid = st.character, st.hrp, st.humanoid
	if char == nil or hrp == nil or humanoid == nil then
		return
	end
	humanoid.WalkSpeed = 0
	hrp.Anchored = true
	local p = hrp.Position
	char:PivotTo(CFrame.new(p.X, FLOOR_Y - HIDE_DEPTH, p.Z))
	st.settleTarget = nil
	st.lastPos = nil
end

local function resetLife(st: PState, now: number)
	st.lifeStart = now
	st.lifeCoins = 0
	st.lifeKills = 0
	st.secondChanceUsed = false
	st.pendingUntil = nil
	st.respawning = false
	st.kingAccum = 0
	st.overTicks = 0
end

local function removePlayerRunner(st: PState, now: number)
	local id = st.id
	if id == 0 then
		return
	end
	st.id = 0
	st.pendingUntil = nil
	playerById[id] = nil
	zeroSince[id] = nil
	sim:removeRunner(id, now)
end

local function addPlayerRunner(st: PState, now: number)
	local player = st.player
	local profile = DataService.get(player)
	if profile == nil or st.character == nil or st.id ~= 0 then
		return
	end
	local info: RunnerInfo = {
		id = 0,
		userId = player.UserId,
		name = player.DisplayName,
		colorIndex = ArenaService.freeColorIndex(),
		skin = profile.equipped.skin,
		trail = profile.equipped.trail,
		effect = profile.equipped.effect,
		isBot = false,
	}
	local id = sim:addRunner(info, UpgradeService.startPatch(player), UpgradeService.shieldSeconds(player), now)
	st.id = id
	playerById[id] = st
	st.walkSpeed = UpgradeService.walkSpeed(player)
	resetLife(st, now)
	local r = sim:runner(id)
	if r ~= nil then
		placeAtCell(st, r.x, r.y, now)
	end
	sendSnapshot(player)
end

local function onDied(st: PState)
	removePlayerRunner(st, os.clock())
	st.character, st.hrp, st.humanoid = nil, nil, nil
end

local function onCharacter(st: PState, char: Model)
	for _, c in st.charConnections do
		c:Disconnect()
	end
	table.clear(st.charConnections)
	st.character, st.hrp, st.humanoid = nil, nil, nil
	local player = st.player
	local humanoid = char:WaitForChild("Humanoid", CHARACTER_WAIT)
	local hrp = char:WaitForChild("HumanoidRootPart", CHARACTER_WAIT)
	if humanoid == nil or hrp == nil or not humanoid:IsA("Humanoid") or not hrp:IsA("BasePart") then
		return
	end
	local deadline = os.clock() + CHARACTER_WAIT
	while char.Parent == nil and os.clock() < deadline do
		task.wait()
		if player.Character ~= char or states[player] ~= st then
			return
		end
	end
	-- One frame so the engine's own spawn placement does not override our teleport.
	task.wait()
	if player.Character ~= char or states[player] ~= st or char.Parent == nil then
		return
	end
	local hum = humanoid :: Humanoid
	hum.JumpPower = 0
	hum.JumpHeight = 0
	st.character, st.hrp, st.humanoid = char, hrp :: BasePart, hum
	table.insert(
		st.charConnections,
		hum.Died:Connect(function()
			if st.character == char then
				onDied(st)
			end
		end)
	)
	local now = os.clock()
	removePlayerRunner(st, now) -- stale runner from a previous character, if any
	addPlayerRunner(st, now)
end

-- anti-exploit (G11.6) --------------------------------------------------------------------------

local function addStrike(st: PState, now: number)
	local strikes = st.strikes
	local i = 1
	while i <= #strikes do
		if now - strikes[i] > Config.Security.StrikeWindow then
			table.remove(strikes, i)
		else
			i += 1
		end
	end
	table.insert(strikes, now)
	if #strikes >= Config.Security.KickStrikes then
		st.player:Kick("Movement check failed. Please rejoin.")
	end
end

local function snapBack(st: PState, r: Runner, now: number)
	st.settleTries = 0
	teleport(st, cellCFrame(st, r.x, r.y), now)
end

local function speedAllowance(st: PState, now: number): number
	if now < st.speedGraceUntil then
		return math.max(st.walkSpeed, st.prevWalkSpeed)
	end
	return st.walkSpeed
end

-- Writes the runner's target cell into positions only when the movement is accepted.
local function readPlayer(st: PState, r: Runner, now: number, positions: { [number]: Cell })
	local hrp = st.hrp
	if hrp == nil or hrp.Parent == nil or hrp.Anchored then
		return
	end
	local pos = hrp.Position
	if now < st.exemptUntil then
		-- Once the client has been seen at the target the teleport has landed; the player may
		-- then walk away from it during the window without being pulled back.
		local t = st.settleTarget
		if t ~= nil then
			local tdx, tdz = pos.X - t.X, pos.Z - t.Z
			if tdx * tdx + tdz * tdz <= SETTLE_RADIUS * SETTLE_RADIUS then
				st.settleTarget = nil
			end
		end
		st.lastPos, st.lastTime = pos, now
		return
	end
	local target = st.settleTarget
	if target ~= nil then
		local dx, dz = pos.X - target.X, pos.Z - target.Z
		if dx * dx + dz * dz > SETTLE_RADIUS * SETTLE_RADIUS and st.settleTries < SETTLE_RETRIES then
			st.settleTries += 1
			teleport(st, CFrame.new(target), now)
			return
		end
		st.settleTarget = nil
		st.lastPos, st.lastTime = pos, now
	end
	if
		math.abs(pos.X) > HALF + CELL
		or math.abs(pos.Z) > HALF + CELL
		or pos.Y < FLOOR_Y - BELOW_FLOOR
		or pos.Y > FLOOR_Y + ABOVE_FLOOR
	then
		snapBack(st, r, now)
		return
	end
	local last = st.lastPos
	if last == nil then
		st.lastPos, st.lastTime = pos, now
		return
	end
	-- Compared against the last ACCEPTED position, so held ticks widen the allowance (lag-safe).
	local dx, dz = pos.X - last.X, pos.Z - last.Z
	local distSq = dx * dx + dz * dz
	if distSq < 1e-4 then
		-- No new replicated position (or standing still): keep lastTime so a replication stall
		-- followed by a catch-up burst is measured over the real elapsed time.
		st.overTicks = 0
		local cx, cy = sim.grid:worldToCell(pos.X, pos.Z)
		positions[r.id] = { x = cx, y = cy }
		return
	end
	local elapsed = math.min(now - st.lastTime, MAX_SPEED_WINDOW)
	local allowed = Config.Security.SpeedTolerance * speedAllowance(st, now) * elapsed + SPEED_SLACK
	if distSq > allowed * allowed then
		st.overTicks += 1
		if st.overTicks >= Config.Security.SpeedStrikeTicks then
			snapBack(st, r, now)
			addStrike(st, now)
		end
		return
	end
	st.overTicks = 0
	st.lastPos, st.lastTime = pos, now
	local cx, cy = sim.grid:worldToCell(pos.X, pos.Z)
	positions[r.id] = { x = cx, y = cy }
end

-- event handling -------------------------------------------------------------------------------

local function onClaim(e: any, now: number)
	local st = playerById[e.id]
	if st == nil then
		return
	end
	local player = st.player
	local coins = EconomyService.onCapture(player, e.neutral, e.stolen)
	st.lifeCoins += coins
	local pct = sim:share(e.id) * 100
	RewardService.progress(player, "cells", e.cells, "add")
	RewardService.progress(player, "bigCapture", e.cells, "max")
	RewardService.progress(player, "mapPct", pct, "max")
	local applied, firstCapture, totalCells, best = false, false, 0, 0
	DataService.update(player, function(p)
		applied = true
		firstCapture = p.stats.captures == 0
		p.stats.cells += e.cells
		p.stats.captures += 1
		if pct > p.stats.bestPct then
			p.stats.bestPct = pct
		end
		totalCells, best = p.stats.cells, p.stats.bestPct
	end)
	if applied then
		LeaderboardService.submit(player, "cells", totalCells)
		LeaderboardService.submit(player, "bestPct", best)
	end
	BadgeService.award(player, "firstLoop")
	for _, b in MAP_BADGES do
		if pct >= b.pct then
			BadgeService.award(player, b.key)
		end
	end
	remote(Remotes.Reward):FireClient(player, { coins = coins, reason = "capture", cx = e.cx, cy = e.cy })
	AnalyticsService.log(player, "capture", { cells = e.cells, stolen = e.stolen })
	if firstCapture then
		AnalyticsService.log(player, "first_capture", { seconds = math.floor(now - st.joinClock) })
	end
end

local function onCut(e: any, now: number)
	local victimRunner = sim:runner(e.victim)
	local killerRunner = sim:runner(e.killer)
	local victimWasBot = victimRunner ~= nil and victimRunner.info.isBot
	local killerWasBot = killerRunner ~= nil and killerRunner.info.isBot

	local ks = playerById[e.killer]
	if ks ~= nil then
		local player = ks.player
		local coins = EconomyService.onKill(player, e.victimCells, e.victimWasKing)
		ks.lifeCoins += coins
		ks.lifeKills += 1
		RewardService.progress(player, "kills", 1, "add")
		local kills: number? = nil
		DataService.update(player, function(p)
			p.stats.kills += 1
			kills = p.stats.kills
		end)
		if kills ~= nil then
			LeaderboardService.submit(player, "kills", kills)
		end
		BadgeService.award(player, "firstCut")
		remote(Remotes.Reward):FireClient(player, { coins = coins, reason = "kill" })
		AnalyticsService.log(player, "cut", { victimWasBot = victimWasBot })
	end

	local vs = playerById[e.victim]
	if vs == nil then
		-- Bots and runners of players who left: split their turf now (BotService also does this for bots).
		sim:releaseVictim(e.victim)
		return
	end
	local player = vs.player
	vs.deathTime = now
	DataService.update(player, function(p)
		p.stats.deaths += 1
	end)
	hideCharacter(vs)
	local canSecondChance = Config.Ids.Products.secondChance ~= 0
		and sim:share(e.victim) >= Config.Products.secondChance.MinMapShare
		and not vs.secondChanceUsed
	local lifeSeconds = math.floor(now - vs.lifeStart)
	remote(Remotes.Death):FireClient(player, {
		coins = vs.lifeCoins,
		cells = e.victimCells,
		lifeSeconds = lifeSeconds,
		kills = vs.lifeKills,
		canSecondChance = canSecondChance,
		killerName = if killerRunner ~= nil then killerRunner.info.name else nil,
	})
	AnalyticsService.log(player, "death", { cells = e.victimCells, lifeSeconds = lifeSeconds, killerWasBot = killerWasBot })
	if canSecondChance then
		vs.pendingUntil = now + Config.Products.secondChance.PromptSeconds + SECOND_CHANCE_GRACE
	else
		sim:releaseVictim(e.victim)
	end
end

local function onFullMap(e: any)
	local r = sim:runner(e.id)
	local st = playerById[e.id]
	if st ~= nil then
		EconomyService.onFullMap(st.player)
		BadgeService.award(st.player, "map100")
	end
	local name = if r ~= nil then r.info.name else "Someone"
	remote(Remotes.Toast):FireAllClients(name .. " captured the WHOLE map!", "good")
end

local function handleEvent(ev: ArenaEvent, now: number)
	local e = ev :: any
	if e.kind == "claim" then
		onClaim(e, now)
	elseif e.kind == "cut" then
		onCut(e, now)
	elseif e.kind == "king" then
		local st = playerById[e.id]
		if st ~= nil then
			BadgeService.award(st.player, "king")
		end
	elseif e.kind == "fullMap" then
		onFullMap(e)
	end
end

-- life cycle -----------------------------------------------------------------------------------

local function doRespawn(st: PState, now: number)
	local player = st.player
	st.pendingUntil = nil
	sim:respawn(st.id, UpgradeService.startPatch(player), UpgradeService.shieldSeconds(player), now)
	st.walkSpeed = UpgradeService.walkSpeed(player)
	resetLife(st, now)
	local r = sim:runner(st.id)
	if r ~= nil then
		placeAtCell(st, r.x, r.y, now)
	end
end

-- Alive runners left with no turf and no trail can never claim again: give them a fresh patch.
-- The runner keeps its id and info (removeRunner then addRunner), so clients see despawn + spawn.
local function recycle(r: Runner, now: number)
	local id = r.id
	if orphans[id] then
		orphans[id] = nil
		sim:removeRunner(id, now)
		return
	end
	local st = playerById[id]
	local patch, shield = r.startPatch, Config.Arena.SpawnShield
	if st ~= nil then
		patch, shield = UpgradeService.startPatch(st.player), UpgradeService.shieldSeconds(st.player)
	end
	local info = r.info
	sim:removeRunner(id, now)
	info.id = id
	sim:addRunner(info, patch, shield, now)
	local nr = sim:runner(id)
	if st ~= nil and nr ~= nil then
		placeAtCell(st, nr.x, nr.y, now)
	end
end

local function housekeeping(now: number)
	local kingSt = playerById[sim:kingId()]
	if kingSt ~= nil then
		kingSt.kingAccum += STEP
		if kingSt.kingAccum >= 1 then
			kingSt.kingAccum -= 1
			RewardService.progress(kingSt.player, "kingSeconds", 1, "add")
			DataService.update(kingSt.player, function(p)
				p.stats.kingSeconds += 1
			end)
		end
	end

	for _, st in table.clone(playerById) do
		local r = sim:runner(st.id)
		if r ~= nil and not r.alive then
			local pendingUntil = st.pendingUntil
			if r.pending and pendingUntil ~= nil and now >= pendingUntil then
				st.pendingUntil = nil
				sim:releaseVictim(st.id)
			elseif not r.pending and not st.respawning and now - st.deathTime > IDLE_RESPAWN then
				doRespawn(st, now)
			end
		end
	end

	for _, r in sim:runners() do
		if r.alive and #r.trail == 0 and sim:cellsOf(r.id) == 0 then
			local since = zeroSince[r.id]
			if since == nil then
				zeroSince[r.id] = now
			elseif now - since > ZERO_TURF_RECYCLE then
				zeroSince[r.id] = nil
				recycle(r, now)
			end
		else
			zeroSince[r.id] = nil
		end
	end
end

local function tick(now: number)
	local pre = ArenaService.preStep
	if pre ~= nil then
		local ok, err = pcall(pre, now, STEP)
		if not ok then
			warn("[ArenaService] preStep failed:", err)
		end
	end

	local positions: { [number]: Cell } = {}
	for id, p in ArenaService.botPositions do
		local r = sim:runner(id)
		if r ~= nil and r.info.isBot then
			positions[id] = p
		end
	end
	local list: { PState } = {}
	for _, st in states do
		table.insert(list, st)
	end
	for _, st in list do
		if st.id ~= 0 then
			local r = sim:runner(st.id)
			if r ~= nil and r.alive then
				readPlayer(st, r, now, positions)
			end
		end
	end

	sim:step(now, positions)

	for _, ev in sim:drainEvents() do
		local e = ev :: any
		if e.kind == "spawn" then
			-- Clients cannot read os.clock; give them shieldUntil on the synchronized server clock.
			local copy = table.clone(e)
			copy.shieldUntil = workspace:GetServerTimeNow() + (e.shieldUntil - now)
			broadcast(Remotes.ArenaEvent, copy)
		else
			broadcast(Remotes.ArenaEvent, ev)
		end
		local ok, err = pcall(handleEvent, ev, now)
		if not ok then
			warn("[ArenaService] event handler failed:", (ev :: any).kind, err)
		end
		for _, fn in table.clone(eventListeners) do
			local ok2, err2 = pcall(fn, ev)
			if not ok2 then
				warn("[ArenaService] onEvent listener failed:", err2)
			end
		end
	end

	housekeeping(now)
end

-- public API -----------------------------------------------------------------------------------

-- Called once the player's profile is loaded; the runner is added when the character exists.
function ArenaService.join(player: Player)
	if states[player] ~= nil or player.Parent == nil then
		return
	end
	local now = os.clock()
	local st: PState = {
		player = player,
		joinClock = now,
		id = 0,
		character = nil,
		hrp = nil,
		humanoid = nil,
		connections = {},
		charConnections = {},
		walkSpeed = UpgradeService.walkSpeed(player),
		prevWalkSpeed = 0,
		speedGraceUntil = 0,
		lastPos = nil,
		lastTime = now,
		overTicks = 0,
		strikes = {},
		exemptUntil = 0,
		settleTarget = nil,
		settleTries = 0,
		deathTime = now,
		lifeStart = now,
		lifeCoins = 0,
		lifeKills = 0,
		pendingUntil = nil,
		secondChanceUsed = false,
		respawning = false,
		kingAccum = 0,
		ready = false,
	}
	states[player] = st
	table.insert(
		st.connections,
		player.CharacterAdded:Connect(function(char: Model)
			onCharacter(st, char)
		end)
	)
	local char = player.Character
	if char ~= nil then
		task.spawn(onCharacter, st, char)
	end
end

-- The runner (and its turf) stays for LeaveNeutralDelay seconds, then is removed.
function ArenaService.leave(player: Player)
	local st = states[player]
	if st == nil then
		return
	end
	states[player] = nil
	for _, c in st.connections do
		c:Disconnect()
	end
	for _, c in st.charConnections do
		c:Disconnect()
	end
	local id = st.id
	if id == 0 then
		return
	end
	st.id = 0
	playerById[id] = nil
	local r = sim:runner(id)
	if r == nil then
		return
	end
	if r.pending then
		sim:releaseVictim(id)
	end
	orphans[id] = true
	local info = r.info
	task.delay(Config.Arena.LeaveNeutralDelay, function()
		if orphans[id] then
			orphans[id] = nil
			local cur = sim:runner(id)
			if cur ~= nil and cur.info == info then
				sim:removeRunner(id, os.clock())
			end
		end
	end)
end

-- Request handler. Waits out the rest of RespawnDelay if needed.
function ArenaService.respawn(player: Player): (boolean, any)
	local st = states[player]
	if st == nil or st.id == 0 then
		return false, "not_in_arena"
	end
	local id = st.id
	local r = sim:runner(id)
	if r == nil or r.alive then
		return false, "not_dead"
	end
	if st.respawning then
		return false, "busy"
	end
	if r.pending then
		st.pendingUntil = nil
		sim:releaseVictim(id)
	end
	local remaining = st.deathTime + Config.Arena.RespawnDelay - os.clock()
	if remaining > 0 then
		st.respawning = true
		task.wait(remaining)
		st.respawning = false
		local again = sim:runner(id)
		if states[player] ~= st or st.id ~= id or again == nil or again.alive then
			return false, "not_dead"
		end
	end
	doRespawn(st, os.clock())
	return true, id
end

function ArenaService.declineSecondChance(player: Player): (boolean, any)
	local st = states[player]
	if st == nil or st.id == 0 then
		return false, "not_in_arena"
	end
	local r = sim:runner(st.id)
	if r == nil or not r.pending then
		return false, "not_pending"
	end
	st.pendingUntil = nil
	sim:releaseVictim(st.id)
	return true, nil
end

-- MonetizationService.onSecondChance: true only when the player was still a pending victim.
function ArenaService.secondChance(player: Player): boolean
	local st = states[player]
	if st == nil or st.id == 0 then
		return false
	end
	local r = sim:runner(st.id)
	if r == nil or not r.pending then
		return false
	end
	local now = os.clock()
	if not sim:revive(st.id, Config.Products.secondChance.Shield, now) then
		return false
	end
	st.pendingUntil = nil
	st.secondChanceUsed = true
	placeAtCell(st, r.x, r.y, now)
	return true
end

-- After a speed upgrade or a rebirth.
function ArenaService.refreshWalkSpeed(player: Player)
	local st = states[player]
	if st == nil then
		return
	end
	local speed = UpgradeService.walkSpeed(player)
	if speed < st.walkSpeed then
		st.prevWalkSpeed = st.walkSpeed
		st.speedGraceUntil = os.clock() + SPEED_DROP_GRACE
	end
	st.walkSpeed = speed
	local humanoid = st.humanoid
	if humanoid ~= nil and st.id ~= 0 and sim:isAlive(st.id) then
		humanoid.WalkSpeed = speed
	end
end

function ArenaService.runnerIdOf(player: Player): number
	local st = states[player]
	return if st ~= nil then st.id else 0
end

function ArenaService.start()
	if started then
		return
	end
	started = true
	for _, name in
		{ Remotes.ArenaSnapshot, Remotes.ArenaDelta, Remotes.ArenaEvent, Remotes.Death, Remotes.Reward, Remotes.Toast, Remotes.RunnerInfo }
	do
		remote(name)
	end

	MonetizationService.onSecondChance = ArenaService.secondChance
	EconomyService.cellsProvider = function(player: Player): number
		local st = states[player]
		if st == nil or st.id == 0 or not sim:isAlive(st.id) then
			return 0
		end
		return sim:cellsOf(st.id)
	end

	ShopService.equippedChanged:Connect(function(player: Player, equipped: { skin: string, trail: string, effect: string })
		local st = states[player]
		if st == nil or st.id == 0 then
			return
		end
		local r = sim:runner(st.id)
		if r == nil then
			return
		end
		r.info.skin, r.info.trail, r.info.effect = equipped.skin, equipped.trail, equipped.effect
		broadcast(Remotes.RunnerInfo, liveInfos())
	end)

	Players.PlayerRemoving:Connect(ArenaService.leave)

	local acc, deltaAcc = 0, 0
	RunService.Heartbeat:Connect(function(dt: number)
		acc += dt
		local steps = 0
		while acc >= STEP do
			steps += 1
			if steps > MAX_CATCHUP_STEPS then
				acc = 0
				break
			end
			acc -= STEP
			local ok, err = pcall(tick, os.clock())
			if not ok then
				warn("[ArenaService] tick failed:", err)
			end
		end
		deltaAcc += dt
		if deltaAcc >= DELTA_PERIOD then
			deltaAcc = math.min(deltaAcc - DELTA_PERIOD, DELTA_PERIOD)
			flushDeltas()
		end
	end)
end

return ArenaService
