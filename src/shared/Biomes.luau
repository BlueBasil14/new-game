--!strict
-- Biome skins (owner direction 2026-11-16): the captured turf grows low-poly scenery.
-- Pure placement logic, shared so it is unit-tested. The grid is split into Block x Block cell
-- blocks; each block holds at most one prop at a hash-chosen anchor cell, so the same land
-- always shows the same scenery (stable when more land is captured) and density grows with area.
-- A prop only appears when every cell within its `reach` of the anchor belongs to the owner,
-- so big props sit away from edges and trails. A spot that cannot fit its prop falls back down
-- the `fallback` chain (tree -> bush -> pebble), so a growing area upgrades bushes into trees.
local Config = require(script.Parent.Config)

export type Prop = { name: string, weight: number, reach: number, fallback: string? }
export type Biome = { seed: number, fill: number, props: { Prop } }

local Biomes = {}

-- skin id -> biome. Prop names match the Blender kit (docs/art/WOODLAND_KIT.md).
Biomes.bySkin = {
	biome_woodland = {
		seed = 11,
		fill = 70, -- percent of blocks that hold a prop at all
		props = {
			{ name = "wood_tree_round", weight = 14, reach = 2, fallback = "wood_bush_a" },
			{ name = "wood_tree_pine", weight = 12, reach = 2, fallback = "wood_bush_b" },
			{ name = "wood_tree_tall", weight = 8, reach = 2, fallback = "wood_bush_a" },
			{ name = "wood_bush_a", weight = 10, reach = 1, fallback = "wood_rock_c" },
			{ name = "wood_bush_b", weight = 10, reach = 1, fallback = "wood_rock_c" },
			{ name = "wood_log_a", weight = 6, reach = 1, fallback = "wood_rock_c" },
			{ name = "wood_log_b", weight = 6, reach = 1, fallback = "wood_rock_c" },
			{ name = "wood_mushrooms", weight = 8, reach = 1, fallback = "wood_rock_c" },
			{ name = "wood_rock_a", weight = 8, reach = 1, fallback = "wood_rock_c" },
			{ name = "wood_rock_b", weight = 6, reach = 1, fallback = "wood_rock_c" },
			{ name = "wood_rock_c", weight = 12, reach = 0 },
		},
	},
} :: { [string]: Biome }

-- Part key (after "<prop>__") -> colour and growth stage. Colours are applied in Roblox so the look
-- never depends on how the importer read FBX materials. Stage 0 grows first (trunks), 3 last (tops).
Biomes.parts = {
	bark = { "#7A5236", 0 }, bark_dark = { "#5C3D27", 0 }, wood_end = { "#C9A57A", 0 },
	rock = { "#8E949A", 0 }, rock_dark = { "#6B7178", 0 }, stem = { "#F2E6CF", 0 },
	leaf_dark = { "#2F7A3B", 1 }, moss = { "#6BAA4A", 1 },
	leaf = { "#4FA34A", 2 }, cap_red = { "#E2533F", 2 },
	leaf_light = { "#7CC35A", 3 }, spot = { "#FFFFFF", 3 },
} :: { [string]: { any } }

local byName: { [Biome]: { [string]: Prop } } = {}
local totals: { [Biome]: number } = {}
for _, b in Biomes.bySkin do
	local m, t = {}, 0
	for _, p in b.props do
		m[p.name] = p
		t += p.weight
	end
	byName[b], totals[b] = m, t
end

-- Integer hash, stable across client and server.
local function hash(a: number, b: number, c: number): number
	local h = bit32.bxor(a * 374761393, b * 668265263, c * 2246822519)
	h = bit32.bxor(h, bit32.rshift(h, 13)) * 1274126177
	return bit32.bxor(h % 4294967296, bit32.rshift(h % 4294967296, 16))
end
Biomes.hash = hash

type CellGetter = (x: number, y: number) -> number

local function owns(get: CellGetter, size: number, owner: number, x: number, y: number, reach: number): boolean
	if x - reach < 0 or y - reach < 0 or x + reach >= size or y + reach >= size then
		return false
	end
	for yy = y - reach, y + reach do
		for xx = x - reach, x + reach do
			if get(xx, yy) ~= owner then
				return false
			end
		end
	end
	return true
end

-- A block's anchor cell; the same for every biome, so the anchor's owner picks the biome.
function Biomes.anchor(bx: number, by: number): (number, number)
	local B = Config.Biomes.BlockCells
	local h = hash(bx, by, 0)
	return bx * B + h % B, by * B + (h // 7) % B
end

-- The prop a block shows for `owner`, or nil. Returns name, anchor cell, yaw (radians), scale.
function Biomes.blockProp(biome: Biome, get: CellGetter, size: number, owner: number, bx: number, by: number): (string?, number, number, number, number)
	if hash(bx, by, biome.seed) % 100 >= biome.fill then
		return nil, 0, 0, 0, 1
	end
	local x, y = Biomes.anchor(bx, by)
	if x >= size or y >= size or get(x, y) ~= owner then
		return nil, 0, 0, 0, 1
	end
	local h2 = hash(x, y, biome.seed + 1)
	local pick = h2 % totals[biome]
	local prop: Prop? = nil
	for _, p in biome.props do
		pick -= p.weight
		if pick < 0 then
			prop = p
			break
		end
	end
	while prop and not owns(get, size, owner, x, y, prop.reach) do
		prop = if prop.fallback then byName[biome][prop.fallback] else nil
	end
	if not prop then
		return nil, 0, 0, 0, 1
	end
	local yaw = (h2 // 997 % 360) * math.pi / 180
	local scale = 0.85 + (h2 // 7 % 31) / 100
	return prop.name, x, y, yaw, scale
end

return Biomes
