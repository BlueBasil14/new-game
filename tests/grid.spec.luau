--!strict
local Grid = require(script.Parent.Grid)
local Config = require(script.Parent.Config)

local g = Grid.new()
local N = Config.Arena.GridSize
assert(g.size == N and g:count(0) == N * N, "default size and neutral count")

-- index round trip and bounds
assert(g:index(3, 7) == 7 * N + 3)
local fx, fy = g:fromIndex(g:index(159, 12))
assert(fx == 159 and fy == 12)
assert(g:inBounds(0, 0) and g:inBounds(N - 1, N - 1))
assert(not g:inBounds(-1, 0) and not g:inBounds(0, N) and not g:inBounds(N, 5))

-- get/set and incremental counts
assert(g:set(5, 5, 3) == 0)
g:set(6, 5, 3)
g:set(6, 5, 4)
assert(g:get(5, 5) == 3 and g:get(6, 5) == 4)
assert(g:count(3) == 1 and g:count(4) == 1 and g:count(0) == N * N - 2)
g:set(5, 5, 0)
assert(g:count(3) == 0 and g:bounds(3) == nil)
local rc = g:recount()
for o = 0, 255 do
	assert(rc[o + 1] == g:count(o), "recount matches")
end
local bx0, by0, bx1, by1 = g:bounds(4)
assert(bx0 == 6 and by0 == 5 and bx1 == 6 and by1 == 5)

-- world <-> cell
local cs = Config.Arena.CellSize
local wx, wz = g:cellToWorld(0, 0)
assert(wx == -N * cs / 2 + cs / 2 and wz == wx)
local cx, cy = g:worldToCell(wx, wz)
assert(cx == 0 and cy == 0)
cx, cy = g:worldToCell(0.1, -0.1)
assert(cx == N // 2 and cy == N // 2 - 1)
cx, cy = g:worldToCell(1e6, -1e6)
assert(cx == N - 1 and cy == 0, "clamped")
for _, p in { { 10, 20 }, { 159, 0 }, { 80, 80 } } do
	local ax, az = g:cellToWorld(p[1], p[2])
	local rx, ry = g:worldToCell(ax, az)
	assert(rx == p[1] and ry == p[2])
end

-- line: excludes start, ends at target, 4-connected, length = manhattan distance
local function checkLine(x0: number, y0: number, x1: number, y1: number)
	local l = g:line(x0, y0, x1, y1)
	assert(#l == math.abs(x1 - x0) + math.abs(y1 - y0), "line length")
	local px, py = x0, y0
	for _, i in l do
		local x, y = g:fromIndex(i)
		assert(math.abs(x - px) + math.abs(y - py) == 1, "4-connected step")
		px, py = x, y
	end
	assert(px == x1 and py == y1, "ends at target")
end
checkLine(0, 0, 0, 0)
checkLine(0, 0, 5, 0)
checkLine(5, 0, 0, 0)
checkLine(0, 0, 0, 7)
checkLine(10, 10, 3, 14)
checkLine(1, 1, 9, 9)
checkLine(20, 3, 2, 30)
assert(#g:line(4, 4, 4, 4) == 0)
-- diagonal stays close to the ideal line
for _, i in g:line(0, 0, 6, 6) do
	local x, y = g:fromIndex(i)
	assert(math.abs(x - y) <= 1)
end

-- RLE round trip
local r = Grid.new(40)
local seed = 12345
local function rnd(n: number): number
	seed = (seed * 1103515245 + 12345) % 2147483648
	return seed % n
end
for _ = 1, 300 do
	local x0, y0 = rnd(40), rnd(40)
	local o = rnd(6)
	for y = y0, math.min(39, y0 + rnd(6)) do
		for x = x0, math.min(39, x0 + rnd(6)) do
			r:set(x, y, o)
		end
	end
end
local enc = r:encodeRLE()
local d = Grid.decodeRLE(enc)
assert(d.size == 40)
for i = 0, 40 * 40 - 1 do
	assert(d:getIndex(i) == r:getIndex(i), "rle cell")
end
for o = 0, 6 do
	assert(d:count(o) == r:count(o), "rle counts")
end
local full = Grid.new()
assert(buffer.len(full:encodeRLE()) == 4, "uniform grid is one run")
assert(Grid.decodeRLE(full:encodeRLE()):count(0) == N * N)

-- delta round trip
local deltas = { { index = 0, owner = 1 }, { index = N * N - 1, owner = 255 }, { index = 777, owner = 0 } }
local back = Grid.decodeDelta(Grid.encodeDelta(deltas))
assert(#back == 3)
for k, v in deltas do
	assert(back[k].index == v.index and back[k].owner == v.owner)
end
local tgt = Grid.new()
tgt:set(1, 0, 9)
local changed = tgt:applyDelta(g:encodeIndices({ g:index(6, 5), 1 }))
assert(#changed == 2 and tgt:get(6, 5) == 4 and tgt:get(1, 0) == 0 and tgt:count(9) == 0)

return "grid ok"
