--!strict
local Grid = require(script.Parent.Grid)
local FloodFill = require(script.Parent.FloodFill)

local function fillRect(g: Grid.Grid, x0: number, y0: number, x1: number, y1: number, o: number)
	for y = y0, y1 do
		for x = x0, x1 do
			g:set(x, y, o)
		end
	end
end

-- trail from a list of waypoints, walked with Grid.line, excluding the start cell
local function path(g: Grid.Grid, pts: { { number } }): { number }
	local out = {}
	for k = 2, #pts do
		for _, i in g:line(pts[k - 1][1], pts[k - 1][2], pts[k][1], pts[k][2]) do
			table.insert(out, i)
		end
	end
	return out
end

local function trailOnly(g: Grid.Grid, owner: number, pts: { { number } }): { number }
	local out = {}
	for _, i in path(g, pts) do
		if g:getIndex(i) ~= owner then
			table.insert(out, i)
		end
	end
	return out
end

local function checkCounts(g: Grid.Grid)
	local rc = g:recount()
	for o = 0, 255 do
		assert(rc[o + 1] == g:count(o), "count mismatch for owner " .. o)
	end
end

-- 1. square loop out of a 3x3 home patch: home (10..12, 10..12), trail around (13..18, 10..15)
do
	local g = Grid.new(40)
	fillRect(g, 10, 10, 12, 12, 1)
	local trail = trailOnly(g, 1, { { 12, 11 }, { 18, 11 }, { 18, 15 }, { 12, 15 }, { 12, 12 } })
	local r = FloodFill.claim(g, 1, trail)
	-- owner now holds 10..12 x 10..12 plus 13..18 x 11..15 plus 12 x 13..15
	local expected = 9 + 6 * 5 + 3
	assert(g:count(1) == expected, "square loop count " .. g:count(1))
	assert(r.neutral == expected - 9 and r.stolen == 0 and #r.changed == expected - 9)
	assert(g:get(15, 13) == 1 and g:get(19, 13) == 0 and g:get(15, 16) == 0)
	assert(r.cx > 12 and r.cx < 19 and r.cy > 10 and r.cy < 16, "centroid inside loop")
	checkCounts(g)
end

-- 2. loop closed against the arena corner: home at (0..2, 0..2), trail goes along x=6 and y=6 lines
do
	local g = Grid.new(40)
	fillRect(g, 0, 0, 2, 2, 2)
	local trail = trailOnly(g, 2, { { 2, 0 }, { 6, 0 }, { 6, 6 }, { 0, 6 }, { 0, 2 } })
	FloodFill.claim(g, 2, trail)
	assert(g:count(2) == 49, "corner loop fills 7x7, got " .. g:count(2))
	checkCounts(g)
	-- along a wall: home (20..22, 0..1), loop down to y=5 and back to the wall at x=28
	fillRect(g, 20, 0, 22, 1, 3)
	local t2 = trailOnly(g, 3, { { 22, 1 }, { 22, 5 }, { 28, 5 }, { 28, 0 }, { 23, 0 } })
	t2[#t2 + 1] = g:index(22, 0) -- re-entry cell is home, already filtered; keep trail as is
	table.remove(t2)
	FloodFill.claim(g, 3, t2)
	assert(g:get(25, 3) == 3 and g:get(29, 3) == 0 and g:get(25, 6) == 0, "wall loop interior")
	checkCounts(g)
end

-- 3. loop enclosing enemy turf counts stolen
do
	local g = Grid.new(40)
	fillRect(g, 5, 5, 7, 7, 1)
	fillRect(g, 12, 7, 14, 9, 4) -- enemy block inside the loop
	g:set(16, 12, 5) -- a cell of a third runner inside
	local trail = trailOnly(g, 1, { { 7, 6 }, { 20, 6 }, { 20, 15 }, { 6, 15 }, { 6, 7 } })
	local r = FloodFill.claim(g, 1, trail)
	assert(g:count(4) == 0 and g:count(5) == 0, "enemy turf stolen")
	assert(r.stolen == 10, "stolen count " .. r.stolen)
	assert(r.neutral + r.stolen == #r.changed)
	checkCounts(g)
end

-- 4. concave turf (U shape): a trail closing the mouth of the U claims the pocket
do
	local g = Grid.new(40)
	fillRect(g, 10, 10, 11, 20, 6)
	fillRect(g, 18, 10, 19, 20, 6)
	fillRect(g, 10, 19, 19, 20, 6)
	-- pocket is 12..17 x 10..18; close the top with a trail on row 9
	local trail = trailOnly(g, 6, { { 10, 10 }, { 10, 9 }, { 19, 9 }, { 19, 10 } })
	assert(#trail == 10)
	local r = FloodFill.claim(g, 6, trail)
	assert(g:get(14, 14) == 6 and g:get(12, 10) == 6 and g:get(17, 18) == 6, "pocket claimed")
	assert(g:get(14, 8) == 0 and g:get(9, 14) == 0, "outside untouched")
	assert(#r.changed == 10 + 6 * 9)
	checkCounts(g)
end

-- 5. trail that returns without enclosing anything: only trail cells change
do
	local g = Grid.new(40)
	fillRect(g, 10, 10, 12, 12, 7)
	local trail = trailOnly(g, 7, { { 12, 11 }, { 17, 11 }, { 17, 12 }, { 13, 12 } })
	local before = g:count(0)
	local r = FloodFill.claim(g, 7, trail)
	assert(#r.changed == #trail and #trail == 10, "only trail changed")
	assert(g:count(0) == before - #trail)
	checkCounts(g)
	-- claim with an empty trail is a no-op
	local r2 = FloodFill.claim(g, 7, {})
	assert(#r2.changed == 0)
end

-- 6. 160x160 near-worst case: thin home in a corner, trail runs the whole arena perimeter
-- one cell in, with enemy turf scattered inside; the flood region is the entire map.
do
	local g = Grid.new(160)
	g:set(1, 1, 1)
	local seed = 7
	for _ = 1, 400 do
		seed = (seed * 1103515245 + 12345) % 2147483648
		local i = seed % (160 * 160)
		local x, y = g:fromIndex(i)
		if x > 2 and y > 2 and x < 157 and y < 157 then
			g:setIndex(i, 2 + seed % 10)
		end
	end
	local trail = trailOnly(g, 1, { { 1, 1 }, { 158, 1 }, { 158, 158 }, { 1, 158 }, { 1, 2 } })
	local t0 = os.clock()
	local r = FloodFill.claim(g, 1, trail)
	local ms = (os.clock() - t0) * 1000
	print(string.format("floodfill 160x160 near-worst: %.2f ms, %d cells changed", ms, #r.changed))
	assert(g:count(1) == 158 * 158, "perimeter loop claims interior")
	assert(ms < 30, "flood too slow: " .. ms)
	checkCounts(g)
	-- second call reuses scratch (generation stamp) and still behaves
	local g2 = Grid.new(160)
	fillRect(g2, 50, 50, 52, 52, 3)
	local t2 = trailOnly(g2, 3, { { 52, 51 }, { 60, 51 }, { 60, 60 }, { 51, 60 }, { 51, 52 } })
	FloodFill.claim(g2, 3, t2)
	assert(g2:get(55, 55) == 3 and g2:get(61, 55) == 0)
	checkCounts(g2)
	return string.format("floodfill ok (%.2f ms)", ms)
end
