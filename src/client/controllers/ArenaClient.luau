--!strict
-- Receives arena replication (snapshot, 10 Hz deltas, events), owns the client Grid and trail
-- lists, fills ClientState.arena and drives TurfRenderer.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Grid = require(Shared.Grid)
local Remotes = require(Shared.Remotes)
local Types = require(Shared.Types)
local ClientState = require(script.Parent.Parent.ClientState)
local TurfRenderer = require(script.Parent.TurfRenderer)
local CameraController = require(script.Parent.CameraController)

local ArenaClient = {}

local CHANGED_INTERVAL = 0.25 -- arenaChanged at most 4 Hz
local RUNNER_INFO_REMOTE = "RunnerInfo"
local RUNNER_INFO_TIMEOUT = 5

local started = false
local grid: Grid.Grid? = nil
local trails: { [number]: { number } } = {}
local alive: { [number]: boolean } = {}
-- Client os.clock() at which each runner's spawn shield ends (see spawn handling).
local shieldEnds: { [number]: number } = {}

local pendingDeltas: { { cells: buffer, trails: { Types.TrailDelta } } } = {}
local pendingEvents: { Types.ArenaEvent } = {}

local changedScheduled = false
local lastChanged = -math.huge
local lastShare = -1

ArenaClient.trails = trails
ArenaClient.alive = alive
ArenaClient.shieldEnds = shieldEnds

function ArenaClient.getGrid(): Grid.Grid?
	return grid
end

local function refreshCounts()
	local arena = ClientState.arena
	local g = grid
	if not g then
		return
	end
	arena.totalCells = g.total
	table.clear(arena.cells)
	for id in arena.runners do
		arena.cells[id] = g:count(id)
	end
	local myId = arena.myId
	local share = if myId then g:count(myId) / g.total else 0
	if share ~= lastShare then
		lastShare = share
		CameraController.setTurfShare(share)
	end
end

local function flushChanged()
	changedScheduled = false
	lastChanged = os.clock()
	refreshCounts()
	ClientState.arenaChanged:Fire()
end

local function markChanged()
	if changedScheduled then
		return
	end
	changedScheduled = true
	local wait = math.max(0, lastChanged + CHANGED_INTERVAL - os.clock())
	task.delay(wait, flushChanged)
end

-- Server shield times use the server's clock, whose base the client cannot know for certain:
-- epoch-like values are compared with GetServerTimeNow, anything else falls back to the base shield.
local function shieldEndFor(shieldUntil: number): number
	local now = os.clock()
	if shieldUntil > 1e9 then
		return now + math.max(0, shieldUntil - workspace:GetServerTimeNow())
	end
	return now + Config.Arena.SpawnShield
end

local function applyTrailDelta(d: Types.TrailDelta)
	local id = d.id
	local list = trails[id]
	if d.clear and list then
		table.clear(list)
	end
	local append = d.append
	if #append > 0 then
		local target = list or {}
		trails[id] = target
		table.move(append, 1, #append, #target + 1, target)
	end
	TurfRenderer.trailDelta(d)
end

local function applyDelta(cells: buffer, trailDeltas: { Types.TrailDelta })
	local g = grid
	if not g then
		table.insert(pendingDeltas, { cells = cells, trails = trailDeltas })
		return
	end
	if buffer.len(cells) >= 2 then
		local changed = g:applyDelta(cells)
		if #changed > 0 then
			TurfRenderer.cellsChanged(changed)
			markChanged()
		end
	end
	for _, d in trailDeltas do
		applyTrailDelta(d)
	end
end

local function isLocal(info: Types.RunnerInfo): boolean
	return info.userId ~= 0 and info.userId == Players.LocalPlayer.UserId
end

local function handleEvent(ev: Types.ArenaEvent)
	if not grid then
		table.insert(pendingEvents, ev)
		return
	end
	local arena = ClientState.arena
	if ev.kind == "spawn" then
		local info = ev.runner
		local id = info.id
		arena.runners[id] = info
		alive[id] = true
		shieldEnds[id] = shieldEndFor(ev.shieldUntil)
		if isLocal(info) then
			arena.myId = id
		end
		if id == arena.myId then
			arena.alive = true
		end
		TurfRenderer.runnerChanged(id)
	elseif ev.kind == "despawn" then
		local id = ev.id
		arena.runners[id] = nil
		arena.cells[id] = nil
		alive[id] = nil
		shieldEnds[id] = nil
		trails[id] = nil
		TurfRenderer.removeRunner(id)
		if id == arena.myId then
			arena.alive = false
		end
	elseif ev.kind == "cut" then
		alive[ev.victim] = false
		if ev.victim == arena.myId then
			arena.alive = false
		end
	elseif ev.kind == "king" then
		arena.kingId = ev.id
	elseif ev.kind == "claim" then
		TurfRenderer.claimFlash(ev.id)
	end
	markChanged()
	ClientState.arenaEvent:Fire(ev)
end

local function applySnapshot(rle: buffer, runners: { Types.RunnerInfo }, yourRunnerId: number?)
	local g = Grid.decodeRLE(rle)
	grid = g
	local arena = ClientState.arena
	table.clear(arena.runners)
	table.clear(arena.cells)
	table.clear(alive)
	table.clear(trails)
	for _, info in runners do
		arena.runners[info.id] = info
		alive[info.id] = true
		if yourRunnerId == nil and isLocal(info) then
			yourRunnerId = info.id
		end
	end
	arena.myId = yourRunnerId
	arena.alive = yourRunnerId ~= nil and arena.runners[yourRunnerId :: number] ~= nil
	arena.totalCells = g.total
	TurfRenderer.applySnapshot(g)

	-- Deltas/events that overtook the snapshot. Delta owners are final values, so replaying is safe.
	local deltas = table.clone(pendingDeltas)
	table.clear(pendingDeltas)
	for _, d in deltas do
		applyDelta(d.cells, d.trails)
	end
	local events = table.clone(pendingEvents)
	table.clear(pendingEvents)
	for _, ev in events do
		handleEvent(ev)
	end
	markChanged()
end

local function applyRunnerInfo(list: { Types.RunnerInfo })
	local arena = ClientState.arena
	for _, info in list do
		arena.runners[info.id] = info
		if isLocal(info) then
			arena.myId = info.id
		end
		TurfRenderer.runnerChanged(info.id)
	end
	markChanged()
end

function ArenaClient.start()
	if started then
		return
	end
	started = true
	TurfRenderer.start()

	local folder = ReplicatedStorage:WaitForChild(Remotes.Folder)
	local snapshotRemote = folder:WaitForChild(Remotes.ArenaSnapshot) :: RemoteEvent
	local deltaRemote = folder:WaitForChild(Remotes.ArenaDelta) :: RemoteEvent
	local eventRemote = folder:WaitForChild(Remotes.ArenaEvent) :: RemoteEvent

	snapshotRemote.OnClientEvent:Connect(applySnapshot)
	deltaRemote.OnClientEvent:Connect(applyDelta)
	eventRemote.OnClientEvent:Connect(handleEvent)

	task.spawn(function()
		local remote = folder:WaitForChild(RUNNER_INFO_REMOTE, RUNNER_INFO_TIMEOUT)
		if remote and remote:IsA("RemoteEvent") then
			remote.OnClientEvent:Connect(applyRunnerInfo)
		end
	end)
end

return ArenaClient
