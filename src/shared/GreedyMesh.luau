--!strict
-- Covers an owner's cells with few rectangles: each row is split into runs, and a run extends the
-- rectangle directly above it when that rectangle has the same x, width and owner.
local Grid = require(script.Parent.Grid)

local GreedyMesh = {}

export type Rect = { x: number, y: number, w: number, h: number }

-- Active rectangles keyed by run start x + 1, swapped between rows.
local activeA: { [number]: Rect } = {}
local activeB: { [number]: Rect } = {}
local ownerA: { [number]: number } = {}
local ownerB: { [number]: number } = {}

-- Rectangles covering exactly owner's cells inside the inclusive region (x0,y0)-(x1,y1).
function GreedyMesh.build(grid: Grid.Grid, owner: number, x0: number, y0: number, x1: number, y1: number): { Rect }
	local size, cells = grid.size, grid.cells
	x0, y0 = math.max(x0, 0), math.max(y0, 0)
	x1, y1 = math.min(x1, size - 1), math.min(y1, size - 1)
	local out: { Rect } = {}
	local prev, cur = activeA, activeB
	table.clear(prev)
	for y = y0, y1 do
		table.clear(cur)
		local row = y * size
		local x = x0
		while x <= x1 do
			if buffer.readu8(cells, row + x) == owner then
				local s = x
				x += 1
				while x <= x1 and buffer.readu8(cells, row + x) == owner do
					x += 1
				end
				local w = x - s
				local r = prev[s + 1]
				if r and r.w == w then
					r.h += 1
				else
					r = { x = s, y = y, w = w, h = 1 }
					table.insert(out, r)
				end
				cur[s + 1] = r
			else
				x += 1
			end
		end
		prev, cur = cur, prev
	end
	table.clear(activeA)
	table.clear(activeB)
	return out
end

-- One pass over the whole grid; returns rectangles for every non-neutral owner.
function GreedyMesh.buildAll(grid: Grid.Grid): { [number]: { Rect } }
	local size, cells = grid.size, grid.cells
	local out: { [number]: { Rect } } = {}
	local prev, cur, prevO, curO = activeA, activeB, ownerA, ownerB
	table.clear(prev)
	table.clear(prevO)
	for y = 0, size - 1 do
		table.clear(cur)
		table.clear(curO)
		local row = y * size
		local x = 0
		while x < size do
			local o = buffer.readu8(cells, row + x)
			local s = x
			x += 1
			while x < size and buffer.readu8(cells, row + x) == o do
				x += 1
			end
			if o ~= 0 then
				local w = x - s
				local r = prev[s + 1]
				if r and r.w == w and prevO[s + 1] == o then
					r.h += 1
				else
					r = { x = s, y = y, w = w, h = 1 }
					local list = out[o]
					if not list then
						list = {}
						out[o] = list
					end
					table.insert(list, r)
				end
				cur[s + 1] = r
				curO[s + 1] = o
			end
		end
		prev, cur, prevO, curO = cur, prev, curO, prevO
	end
	table.clear(activeA)
	table.clear(activeB)
	table.clear(ownerA)
	table.clear(ownerB)
	return out
end

return GreedyMesh
