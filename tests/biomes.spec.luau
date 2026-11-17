--!strict
local Biomes = require(script.Parent.Biomes)
local Config = require(script.Parent.Config)

local function eq(a: any, b: any, msg: string)
	if a ~= b then
		error(msg .. ": got " .. tostring(a) .. " expected " .. tostring(b), 2)
	end
end

local wood = Biomes.bySkin.biome_woodland
local SIZE = 60
local B = Config.Biomes.BlockCells
local cells: { [number]: number } = {}
local function get(x: number, y: number): number
	return cells[y * SIZE + x] or 0
end
local function fill(x0: number, y0: number, x1: number, y1: number, o: number)
	for y = y0, y1 do
		for x = x0, x1 do
			cells[y * SIZE + x] = o
		end
	end
end
local function scan(owner: number): { [string]: string }
	local out = {}
	for by = 0, SIZE // B do
		for bx = 0, SIZE // B do
			local name, x, y = Biomes.blockProp(wood, get, SIZE, owner, bx, by)
			if name then
				out[bx .. "," .. by] = name .. "@" .. x .. "," .. y
			end
		end
	end
	return out
end

-- Empty land grows nothing.
eq(next(scan(1)), nil, "no land, no props")

-- A big square grows a mix with trees; every prop's reach is inside the owner's land.
fill(10, 10, 49, 49, 1)
local big = scan(1)
local n, trees = 0, 0
for _, v in big do
	n += 1
	if string.find(v, "tree") then
		trees += 1
	end
end
assert(n > 60 and n < 180, "density " .. n)
assert(trees > 10, "trees " .. trees)

-- Stable: capturing more land never moves or removes a prop; edge props may only upgrade in place.
fill(50, 10, 57, 49, 1)
local bigger = scan(1)
local upgraded = 0
for k, v in big do
	local was, now = string.match(v, "@.*"), bigger[k] and string.match(bigger[k], "@.*")
	eq(now, was, "stable " .. k)
	if bigger[k] ~= v then
		upgraded += 1
	end
end
assert(upgraded < 6, "upgrades " .. upgraded)

-- Another owner's cell next to a tree trunk demotes it (reach), never places on foreign land.
cells[30 * SIZE + 30] = 2
for _, v in scan(1) do
	local x, y = string.match(v, "@(%d+),(%d+)")
	assert(get(tonumber(x) :: number, tonumber(y) :: number) == 1, "on own land")
end

-- A thin strip (1 cell wide) only gets reach-0 props.
table.clear(cells)
fill(0, 20, SIZE - 1, 20, 3)
for _, v in scan(3) do
	assert(string.find(v, "wood_rock_c"), "strip prop " .. v)
end

print("biomes ok")
return nil
