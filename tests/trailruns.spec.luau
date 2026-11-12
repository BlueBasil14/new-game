--!strict
local TrailRuns = require(script.Parent.TrailRuns)

local NEW, EXTEND, NONE = TrailRuns.NEW, TrailRuns.EXTEND, TrailRuns.NONE

-- straight line is one run
local r = TrailRuns.new()
assert(TrailRuns.push(r, 5, 5) == NEW)
for x = 6, 15 do
	assert(TrailRuns.push(r, x, 5) == EXTEND, "collinear extends")
end
assert(r.sx == 5 and r.ex == 15 and r.sy == 5 and r.ey == 5)

-- duplicate cell ignored
assert(TrailRuns.push(r, 15, 5) == NONE)

-- turn: new run starts at the corner
assert(TrailRuns.push(r, 15, 6) == NEW)
assert(r.sx == 15 and r.sy == 5 and r.ex == 15 and r.ey == 6, "corner shared")
assert(TrailRuns.push(r, 15, 7) == EXTEND)
assert(r.dy == 1 and r.dx == 0)

-- reversing direction is a turn, not an extension
assert(TrailRuns.push(r, 15, 6) == NEW)

-- jump starts a detached single-cell run that extends in any direction afterwards
assert(TrailRuns.push(r, 40, 40) == NEW)
assert(r.sx == 40 and r.sy == 40 and r.dx == 0 and r.dy == 0)
assert(TrailRuns.push(r, 40, 39) == EXTEND)

-- staircase: every step is a new run
TrailRuns.reset(r)
local runs = 0
local x, y = 0, 0
for k = 1, 20 do
	if TrailRuns.push(r, x, y) == NEW then
		runs += 1
	end
	if k % 2 == 0 then
		x += 1
	else
		y += 1
	end
end
-- the second cell extends the initial single-cell run; every later step is a turn
assert(runs == 19, "staircase runs " .. runs)

-- rectangle loop: 4 runs
TrailRuns.reset(r)
runs = 0
local path = {}
for i = 0, 9 do
	table.insert(path, { i, 0 })
end
for i = 1, 9 do
	table.insert(path, { 9, i })
end
for i = 8, 0, -1 do
	table.insert(path, { i, 9 })
end
for _, p in path do
	if TrailRuns.push(r, p[1], p[2]) == NEW then
		runs += 1
	end
end
assert(runs == 3, "U loop runs " .. runs)

-- chunks
local size, chunk = 160, 16
local cps = TrailRuns.chunksPerSide(size, chunk)
assert(cps == 10)
assert(TrailRuns.chunksPerSide(150, 16) == 10)
assert(TrailRuns.chunkOf(0, size, chunk, cps) == 1)
assert(TrailRuns.chunkOf(15, size, chunk, cps) == 1)
assert(TrailRuns.chunkOf(16, size, chunk, cps) == 2)
assert(TrailRuns.chunkOf(16 * size, size, chunk, cps) == 11)
assert(TrailRuns.chunkOf(size * size - 1, size, chunk, cps) == 100)

local flags: { boolean } = {}
local list: { number } = {}
local added = TrailRuns.markCells({ 0, 1, 15, 16, 16 * size + 17, size * size - 1 }, size, chunk, cps, flags, list)
assert(added == 4, "added " .. added)
assert(#list == 4 and list[1] == 1 and list[2] == 2 and list[3] == 12 and list[4] == 100)
assert(TrailRuns.markCells({ 2, 3 }, size, chunk, cps, flags, list) == 0, "already dirty")

local flags2: { boolean } = {}
local list2: { number } = {}
assert(TrailRuns.markBox(10, 10, 40, 20, chunk, cps, flags2, list2) == 6)
assert(flags2[1] and flags2[3] and flags2[11] and flags2[13] and not flags2[4])

return "ok"
