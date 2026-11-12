--!strict
-- Buffer-backed owner grid: one u8 per cell (0 = neutral, 1..255 = runner id).
-- Cell index = y * size + x, 0-based (see Types). World X maps to grid x, world Z to grid y.
local Config = require(script.Parent.Config)

local Grid = {}
Grid.__index = Grid

export type Grid = typeof(setmetatable(
	{} :: {
		size: number,
		total: number,
		cells: buffer,
		counts: { number }, -- counts[owner + 1]
		-- Conservative per-owner bounding boxes: they grow on every set and reset only when the
		-- owner's count reaches 0, so they always contain the owner's cells (possibly loosely).
		minX: { number },
		minY: { number },
		maxX: { number },
		maxY: { number },
	},
	Grid
))

export type CellDelta = { index: number, owner: number }

function Grid.new(size: number?): Grid
	local n = size or Config.Arena.GridSize
	-- Indices must fit the u16 used by the delta encoding.
	assert(n >= 1 and n <= 255, "grid size must be 1..255")
	local self = setmetatable({
		size = n,
		total = n * n,
		cells = buffer.create(n * n),
		counts = table.create(256, 0),
		minX = table.create(256, math.huge),
		minY = table.create(256, math.huge),
		maxX = table.create(256, -1),
		maxY = table.create(256, -1),
	}, Grid)
	self.counts[1] = n * n
	return self
end

function Grid.inBounds(self: Grid, x: number, y: number): boolean
	return x >= 0 and y >= 0 and x < self.size and y < self.size
end

function Grid.index(self: Grid, x: number, y: number): number
	return y * self.size + x
end

function Grid.fromIndex(self: Grid, i: number): (number, number)
	return i % self.size, i // self.size
end

function Grid.getIndex(self: Grid, i: number): number
	return buffer.readu8(self.cells, i)
end

-- Returns the previous owner.
function Grid.setIndex(self: Grid, i: number, owner: number): number
	local cells = self.cells
	local prev = buffer.readu8(cells, i)
	if prev == owner then
		return prev
	end
	buffer.writeu8(cells, i, owner)
	local counts = self.counts
	local pc = counts[prev + 1] - 1
	counts[prev + 1] = pc
	if pc == 0 and prev ~= 0 then
		self.minX[prev + 1] = math.huge
		self.minY[prev + 1] = math.huge
		self.maxX[prev + 1] = -1
		self.maxY[prev + 1] = -1
	end
	counts[owner + 1] += 1
	if owner ~= 0 then
		local k = owner + 1
		local size = self.size
		local x, y = i % size, i // size
		if x < self.minX[k] then
			self.minX[k] = x
		end
		if x > self.maxX[k] then
			self.maxX[k] = x
		end
		if y < self.minY[k] then
			self.minY[k] = y
		end
		if y > self.maxY[k] then
			self.maxY[k] = y
		end
	end
	return prev
end

-- For bulk writers (FloodFill) that adjust counts themselves: resets owner's box if it is empty.
function Grid.refreshBounds(self: Grid, owner: number)
	local k = owner + 1
	if owner ~= 0 and self.counts[k] == 0 then
		self.minX[k] = math.huge
		self.minY[k] = math.huge
		self.maxX[k] = -1
		self.maxY[k] = -1
	end
end

function Grid.get(self: Grid, x: number, y: number): number
	return buffer.readu8(self.cells, y * self.size + x)
end

function Grid.set(self: Grid, x: number, y: number, owner: number): number
	return self:setIndex(y * self.size + x, owner)
end

function Grid.count(self: Grid, owner: number): number
	return self.counts[owner + 1]
end

-- Conservative bounding box (inclusive) containing every cell of owner, or nil if it has none.
function Grid.bounds(self: Grid, owner: number): (number?, number?, number?, number?)
	if owner == 0 then
		return 0, 0, self.size - 1, self.size - 1
	end
	local k = owner + 1
	if self.counts[k] == 0 then
		return nil, nil, nil, nil
	end
	return self.minX[k], self.minY[k], self.maxX[k], self.maxY[k]
end

-- Recounts from scratch (tests / invariant checks).
function Grid.recount(self: Grid): { number }
	local out = table.create(256, 0)
	for i = 0, self.total - 1 do
		local o = buffer.readu8(self.cells, i) + 1
		out[o] += 1
	end
	return out
end

-- Arena is centred on the world origin.
function Grid.worldToCell(self: Grid, wx: number, wz: number): (number, number)
	local cs = Config.Arena.CellSize
	local half = self.size * cs / 2
	local x = math.clamp(math.floor((wx + half) / cs), 0, self.size - 1)
	local y = math.clamp(math.floor((wz + half) / cs), 0, self.size - 1)
	return x, y
end

function Grid.cellToWorld(self: Grid, x: number, y: number): (number, number)
	local cs = Config.Arena.CellSize
	local half = self.size * cs / 2
	return (x + 0.5) * cs - half, (y + 0.5) * cs - half
end

-- Every cell crossed going from (x0,y0) to (x1,y1), excluding the start, 4-connected so a
-- trail drawn from consecutive results has no diagonal gaps. Returns a flat list of indices.
function Grid.line(self: Grid, x0: number, y0: number, x1: number, y1: number): { number }
	local dx, dy = math.abs(x1 - x0), math.abs(y1 - y0)
	local sx = if x1 > x0 then 1 else -1
	local sy = if y1 > y0 then 1 else -1
	local out = table.create(dx + dy)
	local size = self.size
	local x, y, ix, iy = x0, y0, 0, 0
	while ix < dx or iy < dy do
		-- Step along whichever axis the ideal line crosses a cell boundary on first.
		if (1 + 2 * ix) * dy < (1 + 2 * iy) * dx then
			x += sx
			ix += 1
		else
			y += sy
			iy += 1
		end
		table.insert(out, y * size + x)
	end
	return out
end

-- RLE snapshot: u8 size, then runs of [u8 owner, u16 length].
function Grid.encodeRLE(self: Grid): buffer
	local cells, total = self.cells, self.total
	local runs = 0
	local i = 0
	while i < total do
		local o = buffer.readu8(cells, i)
		local j = i + 1
		while j < total and j - i < 65535 and buffer.readu8(cells, j) == o do
			j += 1
		end
		runs += 1
		i = j
	end
	local out = buffer.create(1 + runs * 3)
	buffer.writeu8(out, 0, self.size)
	local p = 1
	i = 0
	while i < total do
		local o = buffer.readu8(cells, i)
		local j = i + 1
		while j < total and j - i < 65535 and buffer.readu8(cells, j) == o do
			j += 1
		end
		buffer.writeu8(out, p, o)
		buffer.writeu16(out, p + 1, j - i)
		p += 3
		i = j
	end
	return out
end

function Grid.decodeRLE(data: buffer): Grid
	local g = Grid.new(buffer.readu8(data, 0))
	local len = buffer.len(data)
	local p, i = 1, 0
	while p < len do
		local o = buffer.readu8(data, p)
		local n = buffer.readu16(data, p + 1)
		for k = i, i + n - 1 do
			g:setIndex(k, o)
		end
		i += n
		p += 3
	end
	return g
end

-- Cell delta: u16 count, then per entry [u16 index, u8 owner].
function Grid.encodeDelta(deltas: { CellDelta }): buffer
	local n = #deltas
	local out = buffer.create(2 + n * 3)
	buffer.writeu16(out, 0, n)
	for k = 1, n do
		local d = deltas[k]
		buffer.writeu16(out, 2 + (k - 1) * 3, d.index)
		buffer.writeu8(out, 4 + (k - 1) * 3, d.owner)
	end
	return out
end

-- Same format, owners read from the grid; avoids building CellDelta tables on the server.
function Grid.encodeIndices(self: Grid, indices: { number }): buffer
	local n = #indices
	local out = buffer.create(2 + n * 3)
	buffer.writeu16(out, 0, n)
	for k = 1, n do
		local i = indices[k]
		buffer.writeu16(out, 2 + (k - 1) * 3, i)
		buffer.writeu8(out, 4 + (k - 1) * 3, buffer.readu8(self.cells, i))
	end
	return out
end

function Grid.decodeDelta(data: buffer): { CellDelta }
	local n = buffer.readu16(data, 0)
	local out = table.create(n)
	for k = 1, n do
		out[k] = { index = buffer.readu16(data, 2 + (k - 1) * 3), owner = buffer.readu8(data, 4 + (k - 1) * 3) }
	end
	return out
end

-- Applies an encoded delta in place; returns the changed indices.
function Grid.applyDelta(self: Grid, data: buffer): { number }
	local n = buffer.readu16(data, 0)
	local out = table.create(n)
	for k = 1, n do
		local i = buffer.readu16(data, 2 + (k - 1) * 3)
		self:setIndex(i, buffer.readu8(data, 4 + (k - 1) * 3))
		out[k] = i
	end
	return out
end

return Grid
