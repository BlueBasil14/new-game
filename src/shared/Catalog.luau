--!strict
-- Static cosmetics, quests and reward tables, plus deterministic lookup helpers.
local Config = require(script.Parent.Config)

export type Item = {
	id: string,
	name: string,
	type: string, -- "skin" | "trail" | "effect"
	rarity: string, -- "common" | "rare" | "epic" | "legendary" | "crown" | "exclusive"
	colorA: string,
	colorB: string?,
	pattern: string, -- "solid" | "stripes" | "dots" | "checker" | "waves" | "stars" | "hex"
	crownsRequired: number?,
	source: string?, -- "vip" | "neonPack" | "starterPack" | "group" | "daily7"
	default: boolean?,
}

export type Reward = { currency: string, amount: number }
export type Quest = { id: string, kind: string, target: number, reward: Reward }

local Catalog = {}

local items: { Item } = {}
local itemsById: { [string]: Item } = {}

local function add(
	itemType: string,
	rarity: string,
	id: string,
	name: string,
	colorA: string,
	colorB: string?,
	pattern: string?,
	extra: { crownsRequired: number?, source: string?, default: boolean? }?
)
	assert(itemsById[id] == nil, "duplicate item id " .. id)
	local item: Item = {
		id = id,
		name = name,
		type = itemType,
		rarity = rarity,
		colorA = colorA,
		colorB = colorB,
		pattern = pattern or "solid",
	}
	if extra then
		item.crownsRequired = extra.crownsRequired
		item.source = extra.source
		item.default = extra.default
	end
	table.insert(items, item)
	itemsById[id] = item
end

-- Defaults owned by everyone
add("skin", "common", "default", "Runner Colour", "#FFFFFF", nil, "solid", { default = true })
add("trail", "common", "default_trail", "Plain Trail", "#FFFFFF", nil, "solid", { default = true })
add("effect", "common", "sparkle", "Sparkle", "#FFE88A", "#FFFFFF", "stars", { default = true })

-- Turf skins: common
local commonSkins = {
	{ "sky_blue", "Sky Blue", "#7CC4FF", nil, "solid" },
	{ "mint_fresh", "Mint Fresh", "#8FF0C8", nil, "solid" },
	{ "lemon_pop", "Lemon Pop", "#FFF07A", nil, "solid" },
	{ "peach_fuzz", "Peach Fuzz", "#FFB59A", nil, "solid" },
	{ "grape_soda", "Grape Soda", "#B58CFF", nil, "solid" },
	{ "bubblegum", "Bubblegum", "#FF9ACB", nil, "solid" },
	{ "lime_zest", "Lime Zest", "#B6E33B", nil, "solid" },
	{ "coral_reef", "Coral Reef", "#FF7A6B", nil, "solid" },
	{ "sandy_beach", "Sandy Beach", "#F2D9A0", "#E8C37A", "stripes" },
	{ "teal_tide", "Teal Tide", "#2DD4BF", "#7CE8DA", "waves" },
	{ "cherry_dots", "Cherry Dots", "#FF4D4D", "#FFFFFF", "dots" },
	{ "slate_check", "Slate Check", "#6B7A99", "#9AA7C2", "checker" },
}
for _, r in commonSkins do
	add("skin", "common", r[1], r[2], r[3], r[4], r[5])
end

local rareSkins = {
	{ "candy_stripe", "Candy Stripe", "#FF4F8B", "#FFFFFF", "stripes" },
	{ "ocean_waves", "Ocean Waves", "#3D8BFF", "#9DD3FF", "waves" },
	{ "forest_hex", "Forest Hex", "#2E9E5B", "#8FE3A8", "hex" },
	{ "sunny_dots", "Sunny Dots", "#FFC83D", "#FF8A3D", "dots" },
	{ "berry_checker", "Berry Checker", "#7C5CFF", "#C9B8FF", "checker" },
	{ "starry_night", "Starry Night", "#2B3A8C", "#FFE88A", "stars" },
	{ "tangerine_wave", "Tangerine Wave", "#FF8A3D", "#FFD2A8", "waves" },
	{ "frosty_hex", "Frosty Hex", "#BDEBFF", "#FFFFFF", "hex" },
}
for _, r in rareSkins do
	add("skin", "rare", r[1], r[2], r[3], r[4], r[5])
end

local epicSkins = {
	{ "aurora", "Aurora", "#4ADE80", "#7C5CFF", "waves" },
	{ "lava_lamp", "Lava Lamp", "#FF4D4D", "#FFC83D", "waves" },
	{ "galaxy_swirl", "Galaxy Swirl", "#2B1F6B", "#C45CFF", "stars" },
	{ "disco_floor", "Disco Floor", "#FF5CD6", "#3DDCFF", "checker" },
	{ "jungle_gems", "Jungle Gems", "#1F8A4C", "#B6E33B", "hex" },
	{ "cotton_clouds", "Cotton Clouds", "#FFB8E0", "#B8E6FF", "dots" },
}
for _, r in epicSkins do
	add("skin", "epic", r[1], r[2], r[3], r[4], r[5])
end

local legendarySkins = {
	{ "rainbow_road", "Rainbow Road", "#FF4D4D", "#4F8BFF", "stripes" },
	{ "cosmic_crystal", "Cosmic Crystal", "#3DDCFF", "#C45CFF", "hex" },
	{ "golden_sunrise", "Golden Sunrise", "#FFC83D", "#FF4F8B", "stars" },
}
for _, r in legendarySkins do
	add("skin", "legendary", r[1], r[2], r[3], r[4], r[5])
end

local crownSkins = {
	{ "crown_bronze", "Bronze Crown", "#C98A4B", "#F0C08A", "stars", 1 },
	{ "crown_silver", "Silver Crown", "#C8D0DC", "#FFFFFF", "stars", 3 },
	{ "crown_gold", "Gold Crown", "#FFC83D", "#FFF1B0", "stars", 5 },
	{ "crown_diamond", "Diamond Crown", "#3DDCFF", "#FFFFFF", "hex", 10 },
}
for _, r in crownSkins do
	add("skin", "crown", r[1], r[2], r[3], r[4], r[5], { crownsRequired = r[6] })
end

-- Trails
add("trail", "common", "trail_pebble", "Pebble Path", "#B8C2D6", nil, "dots")
add("trail", "common", "trail_ribbon", "Ribbon", "#FF9ACB", nil, "stripes")
add("trail", "rare", "trail_bubble", "Bubble Trail", "#7CC4FF", "#FFFFFF", "dots")
add("trail", "rare", "trail_leaf", "Leaf Trail", "#4ADE80", "#B6E33B", "waves")
add("trail", "rare", "trail_ember", "Ember Trail", "#FF8A3D", "#FFC83D", "dots")
add("trail", "epic", "trail_stardust", "Stardust", "#FFE88A", "#C45CFF", "stars")
add("trail", "epic", "trail_ice", "Ice Streak", "#BDEBFF", "#3DDCFF", "hex")
add("trail", "legendary", "trail_rainbow", "Rainbow Streak", "#FF4D4D", "#4F8BFF", "stripes")

-- Capture effects
add("effect", "rare", "fireworks", "Fireworks", "#FF4F8B", "#FFC83D", "stars")
add("effect", "rare", "bubbles", "Bubbles", "#7CC4FF", "#FFFFFF", "dots")
add("effect", "epic", "lightning", "Lightning", "#FFE88A", "#4F8BFF", "stripes")
add("effect", "legendary", "hearts", "Hearts", "#FF4F8B", "#FFB8E0", "dots")

-- Exclusives (not for sale)
add("skin", "exclusive", "starter_spark", "Starter Spark", "#FFC83D", "#FF8A3D", "stars", { source = "starterPack" })
add("skin", "exclusive", "vip_gold", "VIP Gold", "#FFC83D", "#FFF1B0", "hex", { source = "vip" })
add("trail", "exclusive", "vip_gold_trail", "VIP Gold Trail", "#FFC83D", "#FFF1B0", "stars", { source = "vip" })
add("skin", "exclusive", "neon_pink", "Neon Pink", "#FF2E9A", "#FFB3E0", "stripes", { source = "neonPack" })
add("skin", "exclusive", "neon_cyan", "Neon Cyan", "#00F0FF", "#B3FBFF", "waves", { source = "neonPack" })
add("skin", "exclusive", "neon_lime", "Neon Lime", "#B6FF00", "#E6FF99", "checker", { source = "neonPack" })
add("skin", "exclusive", "neon_purple", "Neon Purple", "#B026FF", "#E0B3FF", "hex", { source = "neonPack" })
add("skin", "exclusive", "neon_orange", "Neon Orange", "#FF7A00", "#FFD1A3", "dots", { source = "neonPack" })
add("trail", "exclusive", "neon_trail", "Neon Trail", "#00F0FF", "#FF2E9A", "stripes", { source = "neonPack" })
add("skin", "exclusive", "team", "Team Colours", "#4F8BFF", "#FFFFFF", "stripes", { source = "group" })
add("skin", "exclusive", "streak_week", "Week Streak", "#FF5CD6", "#FFE88A", "stars", { source = "daily7" })

Catalog.items = items

function Catalog.byId(id: string): Item?
	return itemsById[id]
end

function Catalog.ofType(itemType: string): { Item }
	local out = {}
	for _, item in items do
		if item.type == itemType then
			table.insert(out, item)
		end
	end
	return out
end

local function isPurchasable(item: Item): boolean
	return item.default ~= true and item.source == nil and item.crownsRequired == nil and Config.Prices[item.rarity :: any] ~= nil
end
Catalog.isPurchasable = isPurchasable

-- Seeded deterministic PRNG (Park-Miller); no global random state.
local function makeRng(seed: number)
	local state = seed % 2147483646 + 1
	return function(n: number): number -- uniform integer in [1, n]
		state = state * 48271 % 2147483647
		return state % n + 1
	end
end

local function shuffle<T>(list: { T }, rng: (number) -> number): { T }
	local out = table.clone(list)
	for i = #out, 2, -1 do
		local j = rng(i)
		out[i], out[j] = out[j], out[i]
	end
	return out
end

function Catalog.featured(dayNumber: number): { string }
	local ids = {}
	for _, item in items do
		if isPurchasable(item) then
			table.insert(ids, item.id)
		end
	end
	local rng = makeRng(dayNumber * 7919 + 13)
	local shuffled = shuffle(ids, rng)
	local out = {}
	for i = 1, Config.Prices.FeaturedCount do
		out[i] = shuffled[i]
	end
	return out
end

-- Daily quest pool (G5)
local function q(id: string, kind: string, target: number, currency: string, amount: number): Quest
	return { id = id, kind = kind, target = target, reward = { currency = currency, amount = amount } }
end
Catalog.quests = {
	q("cells_500", "cells", 500, "coins", 300),
	q("cells_1500", "cells", 1500, "coins", 700),
	q("cells_4000", "cells", 4000, "coins", 1500),
	q("kills_3", "kills", 3, "coins", 500),
	q("kills_8", "kills", 8, "gems", 20),
	q("bigcap_100", "bigCapture", 100, "coins", 400),
	q("bigcap_300", "bigCapture", 300, "gems", 15),
	q("map_5", "mapPct", 5, "coins", 600),
	q("map_10", "mapPct", 10, "gems", 25),
	q("king_30", "kingSeconds", 30, "coins", 500),
	q("king_120", "kingSeconds", 120, "gems", 20),
	q("play_10", "playMinutes", 10, "coins", 300),
	q("play_20", "playMinutes", 20, "gems", 10),
}

Catalog.questKinds = { "cells", "kills", "bigCapture", "mapPct", "kingSeconds", "playMinutes" }

function Catalog.questsForDay(dayNumber: number, userId: number): { Quest }
	local rng = makeRng(dayNumber * 104729 + userId * 31 + 7)
	local kinds = shuffle(Catalog.questKinds, rng)
	local out = {}
	for i = 1, 3 do
		local pool = {}
		for _, quest in Catalog.quests do
			if quest.kind == kinds[i] then
				table.insert(pool, quest)
			end
		end
		out[i] = pool[rng(#pool)]
	end
	return out
end

-- Daily streak rewards, day 1..7. Day 7 also grants a rare skin on the first loop only.
Catalog.daily = {
	{ currency = "coins", amount = 250 },
	{ currency = "coins", amount = 500 },
	{ currency = "gems", amount = 20 },
	{ currency = "coins", amount = 1000 },
	{ currency = "gems", amount = 40 },
	{ currency = "coins", amount = 2500 },
	{ currency = "gems", amount = 100, skin = "streak_week" },
}

-- Per-session playtime rewards
Catalog.playtime = {
	{ seconds = 120, currency = "coins", amount = 100 },
	{ seconds = 300, currency = "coins", amount = 250 },
	{ seconds = 600, currency = "gems", amount = 10 },
	{ seconds = 1200, currency = "coins", amount = 1000 },
	{ seconds = 1800, currency = "gems", amount = 30 },
}

-- Keys are upper-case; compare against string.upper(input)
Catalog.codes = {
	RELEASE = { currency = "coins", amount = 1000 },
	TURF = { currency = "gems", amount = 25 },
}

Catalog.badges = {
	{ key = "firstLoop", name = "First Loop" },
	{ key = "firstCut", name = "First Cut" },
	{ key = "king", name = "King" },
	{ key = "map10", name = "10% Map" },
	{ key = "map50", name = "50% Map" },
	{ key = "map100", name = "100% Map" },
	{ key = "firstRebirth", name = "First Rebirth" },
	{ key = "streak7", name = "7-Day Streak" },
}

return Catalog
