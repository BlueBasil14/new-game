--!strict
-- Territory claim: trail becomes turf, then everything the owner encloses becomes turf.
local Grid = require(script.Parent.Grid)

local FloodFill = {}

export type ClaimResult = {
	changed: { number }, -- indices whose owner changed, trail cells first
	neutral: number,
	stolen: number,
	cx: number, -- centroid of changed cells (cell coords); trail end cell if nothing changed
	cy: number,
}

type Scratch = { mark: buffer, queue: buffer, gen: number }
local scratchBySize: { [number]: Scratch } = {}
local scratchLost: { number } = table.create(256, 0) -- cells lost per previous owner + 1

local function scratchFor(size: number): Scratch
	local s = scratchBySize[size]
	if not s then
		-- mark holds a u32 generation stamp per cell so it never needs clearing.
		s = { mark = buffer.create(size * size * 4), queue = buffer.create(size * size * 2), gen = 0 }
		scratchBySize[size] = s
	end
	s.gen += 1
	if s.gen >= 4294967295 then
		buffer.fill(s.mark, 0, 0)
		s.gen = 1
	end
	return s
end

function FloodFill.claim(grid: Grid.Grid, owner: number, trailCells: { number }): ClaimResult
	local size = grid.size
	local cells = grid.cells
	local changed = {}
	local neutral, stolen = 0, 0
	local sumX, sumY = 0, 0

	local function take(i: number)
		local prev = grid:setIndex(i, owner)
		if prev ~= owner then
			table.insert(changed, i)
			if prev == 0 then
				neutral += 1
			else
				stolen += 1
			end
			sumX += i % size
			sumY += i // size
		end
	end

	for _, i in trailCells do
		take(i)
	end

	local bx0, by0, bx1, by1 = grid:bounds(owner)
	if bx0 and by0 and bx1 and by1 then
		-- Cells outside the owner's box reach the border trivially, so flood only inside box+1.
		local x0, y0 = math.max(bx0 - 1, 0), math.max(by0 - 1, 0)
		local x1, y1 = math.min(bx1 + 1, size - 1), math.min(by1 + 1, size - 1)
		local s = scratchFor(size)
		local mark, queue, gen = s.mark, s.queue, s.gen
		local head, tail = 0, 0

		local function seed(i: number)
			if buffer.readu8(cells, i) ~= owner and buffer.readu32(mark, i * 4) ~= gen then
				buffer.writeu32(mark, i * 4, gen)
				buffer.writeu16(queue, tail * 2, i)
				tail += 1
			end
		end
		for x = x0, x1 do
			seed(y0 * size + x)
			seed(y1 * size + x)
		end
		for y = y0 + 1, y1 - 1 do
			seed(y * size + x0)
			seed(y * size + x1)
		end

		while head < tail do
			local i = buffer.readu16(queue, head * 2)
			head += 1
			local x, y = i % size, i // size
			if x > x0 then
				local j = i - 1
				if buffer.readu32(mark, j * 4) ~= gen and buffer.readu8(cells, j) ~= owner then
					buffer.writeu32(mark, j * 4, gen)
					buffer.writeu16(queue, tail * 2, j)
					tail += 1
				end
			end
			if x < x1 then
				local j = i + 1
				if buffer.readu32(mark, j * 4) ~= gen and buffer.readu8(cells, j) ~= owner then
					buffer.writeu32(mark, j * 4, gen)
					buffer.writeu16(queue, tail * 2, j)
					tail += 1
				end
			end
			if y > y0 then
				local j = i - size
				if buffer.readu32(mark, j * 4) ~= gen and buffer.readu8(cells, j) ~= owner then
					buffer.writeu32(mark, j * 4, gen)
					buffer.writeu16(queue, tail * 2, j)
					tail += 1
				end
			end
			if y < y1 then
				local j = i + size
				if buffer.readu32(mark, j * 4) ~= gen and buffer.readu8(cells, j) ~= owner then
					buffer.writeu32(mark, j * 4, gen)
					buffer.writeu16(queue, tail * 2, j)
					tail += 1
				end
			end
		end

		-- Hot loop writes the buffer directly; every filled cell lies inside the owner's box, so
		-- only counts (and emptied owners' boxes) need fixing up.
		local counts = grid.counts
		local lost = scratchLost
		local filled = 0
		for y = y0 + 1, y1 - 1 do
			local row = y * size
			for x = x0 + 1, x1 - 1 do
				local i = row + x
				if buffer.readu32(mark, i * 4) ~= gen then
					local prev = buffer.readu8(cells, i)
					if prev ~= owner then
						buffer.writeu8(cells, i, owner)
						lost[prev + 1] += 1
						filled += 1
						table.insert(changed, i)
						sumX += x
						sumY += y
					end
				end
			end
		end
		if filled > 0 then
			counts[owner + 1] += filled
			for k = 1, 256 do
				local c = lost[k]
				if c > 0 then
					counts[k] -= c
					lost[k] = 0
					if k == 1 then
						neutral += c
					else
						stolen += c
						grid:refreshBounds(k - 1)
					end
				end
			end
		end
	end

	local n = #changed
	local cx, cy
	if n > 0 then
		cx, cy = sumX / n, sumY / n
	else
		local last = trailCells[#trailCells] or 0
		cx, cy = last % size, last // size
	end
	return { changed = changed, neutral = neutral, stolen = stolen, cx = cx, cy = cy }
end

return FloodFill
