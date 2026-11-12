--!strict
local Grid = require(script.Parent.Grid)
local GreedyMesh = require(script.Parent.GreedyMesh)

type Rect = GreedyMesh.Rect

-- Asserts rects cover exactly owner's cells in the region with no overlap.
local function checkCover(g: Grid.Grid, owner: number, rects: { Rect }, x0: number, y0: number, x1: number, y1: number)
	local hit = buffer.create(g.size * g.size)
	for _, r in rects do
		assert(r.w >= 1 and r.h >= 1, "non-empty rect")
		for y = r.y, r.y + r.h - 1 do
			for x = r.x, r.x + r.w - 1 do
				assert(x >= x0 and x <= x1 and y >= y0 and y <= y1, "rect inside region")
				local i = g:index(x, y)
				assert(buffer.readu8(hit, i) == 0, "overlap")
				buffer.writeu8(hit, i, 1)
				assert(g:getIndex(i) == owner, "rect covers foreign cell")
			end
		end
	end
	for y = y0, y1 do
		for x = x0, x1 do
			local i = g:index(x, y)
			if g:getIndex(i) == owner then
				assert(buffer.readu8(hit, i) == 1, "owner cell not covered")
			end
		end
	end
end

-- random blobs
local g = Grid.new(64)
local seed = 99
local function rnd(n: number): number
	seed = (seed * 1103515245 + 12345) % 2147483648
	return seed % n
end
for _ = 1, 200 do
	local x0, y0, o = rnd(64), rnd(64), rnd(5)
	for y = y0, math.min(63, y0 + rnd(8)) do
		for x = x0, math.min(63, x0 + rnd(8)) do
			g:set(x, y, o)
		end
	end
end
for o = 1, 4 do
	checkCover(g, o, GreedyMesh.build(g, o, 0, 0, 63, 63), 0, 0, 63, 63)
	checkCover(g, o, GreedyMesh.build(g, o, 10, 5, 40, 33), 10, 5, 40, 33)
end
local all = GreedyMesh.buildAll(g)
local total = 0
for o = 1, 4 do
	local rects = all[o] or {}
	checkCover(g, o, rects, 0, 0, 63, 63)
	for _, r in rects do
		total += r.w * r.h
	end
end
assert(total == 64 * 64 - g:count(0), "buildAll area")
assert(all[0] == nil, "neutral not meshed")

-- whole map single owner = 1 rect
local f = Grid.new(160)
for i = 0, 160 * 160 - 1 do
	f:setIndex(i, 9)
end
local one = GreedyMesh.build(f, 9, 0, 0, 159, 159)
assert(#one == 1 and one[1].w == 160 and one[1].h == 160)
assert(#(GreedyMesh.buildAll(f)[9]) == 1)

-- checkerboard worst case: every cell its own rect
local c = Grid.new(160)
for y = 0, 159 do
	for x = 0, 159 do
		c:set(x, y, if (x + y) % 2 == 0 then 1 else 2)
	end
end
local t0 = os.clock()
local cb = GreedyMesh.buildAll(c)
local ms = (os.clock() - t0) * 1000
assert(#cb[1] == 12800 and #cb[2] == 12800, "checkerboard rect count")
local cb1 = GreedyMesh.build(c, 1, 0, 0, 159, 159)
assert(#cb1 == 12800)
checkCover(c, 1, cb1, 0, 0, 159, 159)
print(string.format("greedymesh checkerboard buildAll: %.2f ms", ms))

return "greedymesh ok"
