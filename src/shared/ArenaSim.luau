--!strict
-- Engine-free arena rules (GDD G2). The server feeds it target cells each tick and forwards the
-- drained events, cell changes and trail deltas to clients. See docs/API_arena.md.
local Config = require(script.Parent.Config)
local Types = require(script.Parent.Types)
local Grid = require(script.Parent.Grid)
local FloodFill = require(script.Parent.FloodFill)

type RunnerInfo = Types.RunnerInfo
type ArenaEvent = Types.ArenaEvent
type TrailDelta = Types.TrailDelta

export type Runner = {
	id: number,
	info: RunnerInfo,
	alive: boolean,
	-- Dead and waiting for releaseVictim/revive; turf still belongs to the runner meanwhile.
	pending: boolean,
	killer: number, -- killer of a pending victim, 0 if none
	x: number,
	y: number,
	trail: { number }, -- cell indices in walk order, never contains own turf
	shieldUntil: number,
	startPatch: number,
}

export type Options = { size: number?, rng: (() -> number)? }

local ArenaSim = {}
ArenaSim.__index = ArenaSim

export type ArenaSim = typeof(setmetatable(
	{} :: {
		grid: Grid.Grid,
		size: number,
		total: number,
		rng: () -> number,
		runnersById: { [number]: Runner },
		order: { number }, -- runner ids ascending
		-- Trail overlay: primary trail owner per cell; rare second owners (only possible when a
		-- shield stopped a cut) live in `extra`.
		trailOwner: buffer,
		extra: { [number]: { number } },
		king: number,
		events: { ArenaEvent },
		dirty: buffer,
		dirtyList: { number },
		deltas: { [number]: TrailDelta },
		cutBy: { [number]: number }, -- victim -> killer, during one step
		cutOrder: { number },
	},
	ArenaSim
))

function ArenaSim.new(opts: Options?): ArenaSim
	local o = opts or {}
	local grid = Grid.new(o.size)
	local n = grid.size
	return setmetatable({
		grid = grid,
		size = n,
		total = n * n,
		rng = o.rng or math.random,
		runnersById = {},
		order = {},
		trailOwner = buffer.create(n * n),
		extra = {},
		king = 0,
		events = {},
		dirty = buffer.create(n * n),
		dirtyList = {},
		deltas = {},
		cutBy = {},
		cutOrder = {},
	}, ArenaSim)
end

-- cell / trail primitives ------------------------------------------------------------------

local function setCell(self: ArenaSim, i: number, owner: number)
	if self.grid:setIndex(i, owner) ~= owner and buffer.readu8(self.dirty, i) == 0 then
		buffer.writeu8(self.dirty, i, 1)
		table.insert(self.dirtyList, i)
	end
end

local function markDirty(self: ArenaSim, i: number)
	if buffer.readu8(self.dirty, i) == 0 then
		buffer.writeu8(self.dirty, i, 1)
		table.insert(self.dirtyList, i)
	end
end

local function deltaFor(self: ArenaSim, id: number): TrailDelta
	local d = self.deltas[id]
	if not d then
		d = { id = id, clear = false, append = {} }
		self.deltas[id] = d
	end
	return d
end

local function trailHas(self: ArenaSim, i: number, id: number): boolean
	if buffer.readu8(self.trailOwner, i) == id then
		return true
	end
	local ex = self.extra[i]
	return ex ~= nil and table.find(ex, id) ~= nil
end

local function appendTrail(self: ArenaSim, r: Runner, i: number)
	table.insert(r.trail, i)
	if buffer.readu8(self.trailOwner, i) == 0 then
		buffer.writeu8(self.trailOwner, i, r.id)
	else
		local ex = self.extra[i]
		if ex then
			table.insert(ex, r.id)
		else
			self.extra[i] = { r.id }
		end
	end
	table.insert(deltaFor(self, r.id).append, i)
end

local function clearTrail(self: ArenaSim, r: Runner)
	local id = r.id
	for _, i in r.trail do
		local ex = self.extra[i]
		if buffer.readu8(self.trailOwner, i) == id then
			if ex then
				buffer.writeu8(self.trailOwner, i, table.remove(ex, 1) :: number)
				if #ex == 0 then
					self.extra[i] = nil
				end
			else
				buffer.writeu8(self.trailOwner, i, 0)
			end
		elseif ex then
			local k = table.find(ex, id)
			if k then
				table.remove(ex, k)
				if #ex == 0 then
					self.extra[i] = nil
				end
			end
		end
	end
	if #r.trail > 0 then
		table.clear(r.trail)
		local d = deltaFor(self, id)
		d.clear = true
		table.clear(d.append)
	end
end

-- Indices of every cell owned by id (scans the owner's conservative bounding box).
local function cellsOwned(self: ArenaSim, id: number): { number }
	local out = {}
	local x0, y0, x1, y1 = self.grid:bounds(id)
	if not (x0 and y0 and x1 and y1) then
		return out
	end
	local cells, size = self.grid.cells, self.size
	for y = y0, y1 do
		for i = y * size + x0, y * size + x1 do
			if buffer.readu8(cells, i) == id then
				table.insert(out, i)
			end
		end
	end
	return out
end

local function releaseCells(self: ArenaSim, id: number)
	for _, i in cellsOwned(self, id) do
		setCell(self, i, 0)
	end
end

local function updateKing(self: ArenaSim)
	local best, bestN = 0, 0
	for _, id in self.order do
		local r = self.runnersById[id]
		if r.alive then
			local n = self.grid:count(id)
			-- order is ascending, so ties go to the lowest id unless the current king is tied
			if n > bestN or (n == bestN and n > 0 and id == self.king) then
				best, bestN = id, n
			end
		end
	end
	if bestN < Config.Arena.KingMinShare * self.total then
		best = 0
	end
	if best ~= self.king then
		self.king = best
		table.insert(self.events, { kind = "king", id = best } :: ArenaEvent)
	end
end

-- spawning ---------------------------------------------------------------------------------

local function patchOrigin(self: ArenaSim, cx: number, cy: number, p: number): (number, number)
	local half = (p - 1) // 2
	return cx - half, cy - half
end

local function stampPatch(self: ArenaSim, id: number, cx: number, cy: number, p: number)
	local ox, oy = patchOrigin(self, cx, cy, p)
	local size = self.size
	for y = math.max(oy, 0), math.min(oy + p - 1, size - 1) do
		for x = math.max(ox, 0), math.min(ox + p - 1, size - 1) do
			setCell(self, y * size + x, id)
		end
	end
end

-- Centre cell of the free patch farthest from every other present runner. Candidates are
-- sampled every 4 cells; a patch is free if all its cells are neutral and trail-free. Falls back
-- to occupied candidates when nothing is free. rng breaks ties only.
local function chooseSpawn(self: ArenaSim, selfId: number, p: number): (number, number)
	local size = self.size
	local half = (p - 1) // 2
	local lo = math.min(half, size - 1)
	local hi = math.max(size - 1 - (p - 1 - half), lo)
	local others = {}
	for _, id in self.order do
		local r = self.runnersById[id]
		if id ~= selfId and (r.alive or r.pending) then
			table.insert(others, r)
		end
	end
	local cells, trail = self.grid.cells, self.trailOwner
	local bestX, bestY, bestScore = (lo + hi) // 2, (lo + hi) // 2, -math.huge
	local step = 4
	local y = lo
	while true do
		local x = lo
		while true do
			local free = true
			for py = math.max(y - half, 0), math.min(y - half + p - 1, size - 1) do
				for px = math.max(x - half, 0), math.min(x - half + p - 1, size - 1) do
					local i = py * size + px
					if buffer.readu8(cells, i) ~= 0 or buffer.readu8(trail, i) ~= 0 then
						free = false
						break
					end
				end
				if not free then
					break
				end
			end
			local d = if #others == 0 then 0 else math.huge
			for _, r in others do
				local dx, dy = r.x - x, r.y - y
				local dd = dx * dx + dy * dy
				if dd < d then
					d = dd
				end
			end
			local score = (if free then 1e9 else 0) + d + self.rng()
			if score > bestScore then
				bestX, bestY, bestScore = x, y, score
			end
			if x >= hi then
				break
			end
			x = math.min(x + step, hi)
		end
		if y >= hi then
			break
		end
		y = math.min(y + step, hi)
	end
	return bestX, bestY
end

local function spawnRunner(self: ArenaSim, r: Runner, startPatch: number, shieldSeconds: number, now: number)
	local cx, cy = chooseSpawn(self, r.id, startPatch)
	stampPatch(self, r.id, cx, cy, startPatch)
	r.x, r.y = cx, cy
	r.alive, r.pending, r.killer = true, false, 0
	r.shieldUntil = now + shieldSeconds
	r.startPatch = startPatch
	table.insert(
		self.events,
		{ kind = "spawn", runner = r.info, x = cx, y = cy, shieldUntil = r.shieldUntil } :: ArenaEvent
	)
end

-- public API -------------------------------------------------------------------------------

function ArenaSim.allocateId(self: ArenaSim): number
	for id = 1, 255 do
		if self.runnersById[id] == nil then
			return id
		end
	end
	error("ArenaSim: no free runner id")
end

-- info.id == 0 allocates the lowest free id and writes it back into info. Returns the id.
function ArenaSim.addRunner(self: ArenaSim, info: RunnerInfo, startPatch: number, shieldSeconds: number, now: number): number
	if info.id == 0 then
		info.id = self:allocateId()
	end
	local id = info.id
	assert(id >= 1 and id <= 255 and self.runnersById[id] == nil, "runner id in use or invalid")
	local r: Runner = {
		id = id,
		info = info,
		alive = false,
		pending = false,
		killer = 0,
		x = 0,
		y = 0,
		trail = {},
		shieldUntil = 0,
		startPatch = startPatch,
	}
	self.runnersById[id] = r
	table.insert(self.order, id)
	table.sort(self.order)
	spawnRunner(self, r, startPatch, shieldSeconds, now)
	updateKing(self)
	return id
end

function ArenaSim.removeRunner(self: ArenaSim, id: number, _now: number)
	local r = self.runnersById[id]
	if not r then
		return
	end
	clearTrail(self, r)
	releaseCells(self, id)
	self.runnersById[id] = nil
	table.remove(self.order, table.find(self.order, id) :: number)
	table.insert(self.events, { kind = "despawn", id = id } :: ArenaEvent)
	updateKing(self)
end

-- Splits a pending victim's turf: the KillerShare of cells nearest the killer's current cell go
-- to the killer (if still alive; never cells under the killer's own trail), the rest neutral.
-- Returns (cells given to killer, cells made neutral).
function ArenaSim.releaseVictim(self: ArenaSim, id: number): (number, number)
	local r = self.runnersById[id]
	if not r or not r.pending then
		return 0, 0
	end
	r.pending = false
	local owned = cellsOwned(self, id)
	local n = #owned
	local given = 0
	local killer = self.runnersById[r.killer]
	r.killer = 0
	local k = math.floor(n * Config.Arena.KillerShare)
	if killer and killer.alive and k > 0 then
		local size, kx, ky = self.size, killer.x, killer.y
		local cand, dist = table.create(n), table.create(n)
		for _, i in owned do
			if not trailHas(self, i, killer.id) then
				local dx, dy = i % size - kx, i // size - ky
				table.insert(cand, i)
				table.insert(dist, dx * dx + dy * dy)
			end
		end
		k = math.min(k, #cand)
		-- Quickselect: afterwards cand[1..k] are the k nearest cells (unordered).
		local lo, hi = 1, #cand
		while lo < hi do
			local p = dist[(lo + hi) // 2]
			local a, b = lo, hi
			while a <= b do
				while dist[a] < p do
					a += 1
				end
				while dist[b] > p do
					b -= 1
				end
				if a <= b then
					dist[a], dist[b] = dist[b], dist[a]
					cand[a], cand[b] = cand[b], cand[a]
					a += 1
					b -= 1
				end
			end
			if k <= b then
				hi = b
			elseif k >= a then
				lo = a
			else
				break
			end
		end
		for j = 1, k do
			setCell(self, cand[j], killer.id)
		end
		given = k
	end
	for _, i in owned do
		if self.grid:getIndex(i) == id then
			setCell(self, i, 0)
		end
	end
	updateKing(self)
	return given, n - given
end

-- Second Chance: cancels a pending release; the runner keeps its turf and stays where it died.
function ArenaSim.revive(self: ArenaSim, id: number, shieldSeconds: number, now: number): boolean
	local r = self.runnersById[id]
	if not r or not r.pending then
		return false
	end
	r.pending, r.killer, r.alive = false, 0, true
	r.shieldUntil = now + shieldSeconds
	table.insert(self.events, { kind = "spawn", runner = r.info, x = r.x, y = r.y, shieldUntil = r.shieldUntil } :: ArenaEvent)
	updateKing(self)
	return true
end

-- New patch at a fresh spot. A still-pending victim is released first.
function ArenaSim.respawn(self: ArenaSim, id: number, startPatch: number, shieldSeconds: number, now: number)
	local r = self.runnersById[id]
	assert(r and not r.alive, "respawn needs a dead runner")
	if r.pending then
		self:releaseVictim(id)
	end
	spawnRunner(self, r, startPatch, shieldSeconds, now)
	updateKing(self)
end

-- step -------------------------------------------------------------------------------------

local function tryCut(self: ArenaSim, killer: Runner, victimId: number, now: number)
	local v = self.runnersById[victimId]
	if v and v.alive and self.cutBy[victimId] == nil and now >= killer.shieldUntil and now >= v.shieldUntil then
		self.cutBy[victimId] = killer.id
		table.insert(self.cutOrder, victimId)
	end
end

local function claim(self: ArenaSim, r: Runner)
	local res = FloodFill.claim(self.grid, r.id, r.trail)
	for _, i in res.changed do
		markDirty(self, i)
	end
	clearTrail(self, r)
	table.insert(self.events, {
		kind = "claim",
		id = r.id,
		cells = #res.changed,
		neutral = res.neutral,
		stolen = res.stolen,
		cx = res.cx,
		cy = res.cy,
	} :: ArenaEvent)
	if self.grid:count(r.id) >= self.total then
		table.insert(self.events, { kind = "fullMap", id = r.id } :: ArenaEvent)
		releaseCells(self, r.id)
		stampPatch(self, r.id, r.x, r.y, r.startPatch)
	end
end

local function enter(self: ArenaSim, r: Runner, i: number, now: number)
	local id = r.id
	local p = buffer.readu8(self.trailOwner, i)
	if p ~= 0 then
		if p ~= id then
			tryCut(self, r, p, now)
		end
		local ex = self.extra[i]
		if ex then
			for _, o in ex do
				if o ~= id then
					tryCut(self, r, o, now)
				end
			end
		end
	end
	-- A runner cut earlier this tick still moves (so head-on cuts resolve) but cannot claim.
	if self.cutBy[id] ~= nil then
		return
	end
	if self.grid:getIndex(i) == id then
		if #r.trail > 0 then
			claim(self, r)
		end
	elseif not trailHas(self, i, id) then
		appendTrail(self, r, i)
	end
end

-- positions: target cell per runner id for this tick. Absent or dead runners do not move.
function ArenaSim.step(self: ArenaSim, now: number, positions: { [number]: { x: number, y: number } })
	local size = self.size
	for _, id in self.order do
		local r = self.runnersById[id]
		local pos = positions[id]
		if r and r.alive and pos then
			local tx = math.clamp(math.floor(pos.x), 0, size - 1)
			local ty = math.clamp(math.floor(pos.y), 0, size - 1)
			if tx ~= r.x or ty ~= r.y then
				for _, i in self.grid:line(r.x, r.y, tx, ty) do
					r.x, r.y = i % size, i // size
					enter(self, r, i, now)
				end
			end
		end
	end
	if #self.cutOrder > 0 then
		table.sort(self.cutOrder)
		local wasKing = self.king
		for _, vid in self.cutOrder do
			local v = self.runnersById[vid]
			v.alive, v.pending, v.killer = false, true, self.cutBy[vid]
			clearTrail(self, v)
			table.insert(self.events, {
				kind = "cut",
				killer = v.killer,
				victim = vid,
				victimCells = self.grid:count(vid),
				victimWasKing = vid == wasKing,
			} :: ArenaEvent)
		end
		table.clear(self.cutOrder)
		table.clear(self.cutBy)
	end
	updateKing(self)
end

-- draining ---------------------------------------------------------------------------------

function ArenaSim.drainEvents(self: ArenaSim): { ArenaEvent }
	local e = self.events
	self.events = {}
	return e
end

function ArenaSim.drainCellChanges(self: ArenaSim): { number }
	local list = self.dirtyList
	for _, i in list do
		buffer.writeu8(self.dirty, i, 0)
	end
	self.dirtyList = {}
	return list
end

function ArenaSim.drainTrailDeltas(self: ArenaSim): { TrailDelta }
	local out = {}
	for _, d in self.deltas do
		table.insert(out, d)
	end
	table.sort(out, function(a, b)
		return a.id < b.id
	end)
	self.deltas = {}
	return out
end

-- getters ----------------------------------------------------------------------------------

function ArenaSim.cellsOf(self: ArenaSim, id: number): number
	return self.grid:count(id)
end

function ArenaSim.share(self: ArenaSim, id: number): number
	return self.grid:count(id) / self.total
end

function ArenaSim.kingId(self: ArenaSim): number
	return self.king
end

function ArenaSim.runner(self: ArenaSim, id: number): Runner?
	return self.runnersById[id]
end

function ArenaSim.runners(self: ArenaSim): { Runner }
	local out = table.create(#self.order)
	for k, id in self.order do
		out[k] = self.runnersById[id]
	end
	return out
end

function ArenaSim.isAlive(self: ArenaSim, id: number): boolean
	local r = self.runnersById[id]
	return r ~= nil and r.alive
end

-- Primary trail owner of a cell (0 = none).
function ArenaSim.trailOwnerAt(self: ArenaSim, x: number, y: number): number
	return buffer.readu8(self.trailOwner, y * self.size + x)
end

-- Every trail owner of a cell (normally 0 or 1 entries).
function ArenaSim.trailOwnersAt(self: ArenaSim, i: number): { number }
	local out = {}
	local p = buffer.readu8(self.trailOwner, i)
	if p ~= 0 then
		table.insert(out, p)
	end
	local ex = self.extra[i]
	if ex then
		for _, o in ex do
			table.insert(out, o)
		end
	end
	return out
end

return ArenaSim
