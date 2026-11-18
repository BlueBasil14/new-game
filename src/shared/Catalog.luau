--!strict
-- Static cosmetics, quests and reward tables, plus deterministic lookup helpers.
local Config = require(script.Parent.Config)

export type Item = {
	id: string,
	name: string,
	type: string, -- "skin" | "trail" | "effect"
	rarity: string, -- "common" | "rare" | "legendary" | "crown" | "exclusive"
	colorA: string,
	colorB: string?,
	pattern: string, -- "solid" | "stripes" | "dots" | "checker" | "waves" | "stars" | "hex"
	crownsRequired: number?,
	source: string?, -- "vip" | "neonPack" | "starterPack" | "group" | "daily7" | "daily28" | "crownRush" | "pass"
	default: boolean?,
	release: string?, -- "weekTwo": hidden until Config.WeekTwo.Start
	priceTier: string?, -- Config.Prices key when it differs from rarity (biome skins)
	anim: string?, -- animated turf: "pulse" | "flow" | "drift" | "rainbow" (TurfRenderer)
	biome: boolean?, -- 3D biome skin (scenery from Biomes.bySkin)
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
	extra: { crownsRequired: number?, source: string?, default: boolean?, release: string?, priceTier: string?, biome: boolean?, anim: string? }?
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
		item.release = extra.release
		item.priceTier = extra.priceTier
		item.biome = extra.biome
		item.anim = extra.anim
	end
	table.insert(items, item)
	itemsById[id] = item
end

-- Defaults owned by everyone
add("skin", "common", "default", "Runner Colour", "#FFFFFF", nil, "solid", { default = true })
add("trail", "common", "default_trail", "Plain Trail", "#FFFFFF", nil, "solid", { default = true })
add("effect", "common", "sparkle", "Sparkle", "#FFE88A", "#FFFFFF", "stars", { default = true })

-- Shop tiers (owner 2026-11-17): plain colours are Common, patterned (two-colour) items are Rare,
-- animated (capture effects) and 3D (biome skins) are Legendary.
local function tierOf(itemType: string, pattern: string, colorB: string?): string
	if itemType == "effect" then
		return "legendary"
	end
	return if pattern == "solid" or colorB == nil then "common" else "rare"
end

local shopSkins = {
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
	{ "candy_stripe", "Candy Stripe", "#FF4F8B", "#FFFFFF", "stripes" },
	{ "ocean_waves", "Ocean Waves", "#3D8BFF", "#9DD3FF", "waves" },
	{ "forest_hex", "Forest Hex", "#2E9E5B", "#8FE3A8", "hex" },
	{ "sunny_dots", "Sunny Dots", "#FFC83D", "#FF8A3D", "dots" },
	{ "berry_checker", "Berry Checker", "#7C5CFF", "#C9B8FF", "checker" },
	{ "starry_night", "Starry Night", "#2B3A8C", "#FFE88A", "stars" },
	{ "tangerine_wave", "Tangerine Wave", "#FF8A3D", "#FFD2A8", "waves" },
	{ "frosty_hex", "Frosty Hex", "#BDEBFF", "#FFFFFF", "hex" },
	{ "aurora", "Aurora", "#4ADE80", "#7C5CFF", "waves" },
	{ "lava_lamp", "Lava Lamp", "#FF4D4D", "#FFC83D", "waves" },
	{ "galaxy_swirl", "Galaxy Swirl", "#2B1F6B", "#C45CFF", "stars" },
	{ "disco_floor", "Disco Floor", "#FF5CD6", "#3DDCFF", "checker" },
	{ "jungle_gems", "Jungle Gems", "#1F8A4C", "#B6E33B", "hex" },
	{ "cotton_clouds", "Cotton Clouds", "#FFB8E0", "#B8E6FF", "dots" },
	{ "rainbow_road", "Rainbow Road", "#FF4D4D", "#4F8BFF", "stripes" },
	{ "cosmic_crystal", "Cosmic Crystal", "#3DDCFF", "#C45CFF", "hex" },
	{ "golden_sunrise", "Golden Sunrise", "#FFC83D", "#FF4F8B", "stars" },
}
for _, r in shopSkins do
	add("skin", tierOf("skin", r[5], r[4]), r[1], r[2], r[3], r[4], r[5])
end

-- 3D biome skins: grow scenery on owned turf (Biomes.luau). Legendary, priced as Config.Prices.biome.
add("skin", "legendary", "biome_woodland", "Living Woodland", "#A3CF62", nil, "solid", { priceTier = "biome", biome = true })

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
add("trail", tierOf("trail", "dots", nil), "trail_pebble", "Pebble Path", "#B8C2D6", nil, "dots")
add("trail", tierOf("trail", "stripes", nil), "trail_ribbon", "Ribbon", "#FF9ACB", nil, "stripes")
add("trail", tierOf("trail", "dots", "#FFFFFF"), "trail_bubble", "Bubble Trail", "#7CC4FF", "#FFFFFF", "dots")
add("trail", tierOf("trail", "waves", "#B6E33B"), "trail_leaf", "Leaf Trail", "#4ADE80", "#B6E33B", "waves")
add("trail", tierOf("trail", "dots", "#FFC83D"), "trail_ember", "Ember Trail", "#FF8A3D", "#FFC83D", "dots")
add("trail", tierOf("trail", "stars", "#C45CFF"), "trail_stardust", "Stardust", "#FFE88A", "#C45CFF", "stars")
add("trail", tierOf("trail", "hex", "#3DDCFF"), "trail_ice", "Ice Streak", "#BDEBFF", "#3DDCFF", "hex")
add("trail", tierOf("trail", "stripes", "#4F8BFF"), "trail_rainbow", "Rainbow Streak", "#FF4D4D", "#4F8BFF", "stripes")

-- Capture effects
add("effect", tierOf("effect", "stars", "#FFC83D"), "fireworks", "Fireworks", "#FF4F8B", "#FFC83D", "stars")
add("effect", tierOf("effect", "dots", "#FFFFFF"), "bubbles", "Bubbles", "#7CC4FF", "#FFFFFF", "dots")
add("effect", tierOf("effect", "stripes", "#4F8BFF"), "lightning", "Lightning", "#FFE88A", "#4F8BFF", "stripes")
add("effect", tierOf("effect", "dots", "#FFB8E0"), "hearts", "Hearts", "#FF4F8B", "#FFB8E0", "dots")

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
add("skin", "exclusive", "streak_month", "Month Streak", "#3DDCFF", "#FFC83D", "hex", { source = "daily28" })

-- Week-two update: hidden until Config.WeekTwo.Start (Crown Rush trail is won, never sold)
local WEEK_TWO = { release = "weekTwo" }
add("skin", "rare", "tide_pool", "Tide Pool", "#2DD4BF", "#3DDCFF", "waves", WEEK_TWO)
add("skin", "rare", "sunset_grid", "Sunset Grid", "#FF8A3D", "#FF4F8B", "checker", WEEK_TWO)
add("trail", tierOf("trail", "stars", "#7C5CFF"), "trail_comet", "Comet Tail", "#FFFFFF", "#7C5CFF", "stars", WEEK_TWO)
add("trail", "exclusive", "crown_rush_trail", "Crown Rush Trail", "#FFC83D", "#2B2F3A", "stars", { source = "crownRush", release = "weekTwo" })

-- Turf Pass season 1 "Neon Rush" (BattlePass.luau): earned on the pass, never sold. Hidden from the shop until
-- the season opens (release "pass").
local PASS = { source = "pass", release = "pass" }
local function passAnim(anim: string)
	return { source = "pass", release = "pass", anim = anim }
end
add("skin", "legendary", "pass_neon_pulse", "Neon Pulse", "#FF2E9A", "#00F0FF", "stripes", passAnim("pulse"))
add("trail", "legendary", "pass_neon_pulse_trail", "Neon Pulse Trail", "#00F0FF", "#FF2E9A", "stripes", PASS)
add("skin", "legendary", "pass_magma_surge", "Magma Surge", "#E8361A", "#FFC83D", "waves", passAnim("flow"))
add("trail", "legendary", "pass_magma_trail", "Magma Trail", "#FF6A1A", "#FFC83D", "waves", PASS)
add("skin", "legendary", "pass_starfall", "Starfall", "#1B1F5E", "#FFE88A", "stars", passAnim("drift"))
add("trail", "legendary", "pass_starfall_trail", "Starfall Trail", "#FFE88A", "#3A3FA0", "stars", PASS)
add("skin", "legendary", "pass_prism_storm", "Prism Storm", "#7C5CFF", "#FFFFFF", "hex", passAnim("rainbow"))
add("trail", "legendary", "pass_prism_trail", "Prism Trail", "#C45CFF", "#3DDCFF", "hex", PASS)
add("skin", "rare", "pass_sour_blast", "Sour Blast", "#B6FF3B", "#FFE14D", "checker", PASS)
add("skin", "rare", "pass_frost_bite", "Frost Bite", "#9FE8FF", "#FFFFFF", "hex", PASS)
add("skin", "rare", "pass_bubble_pop", "Bubble Pop", "#FF8AD8", "#FFFFFF", "dots", PASS)
add("skin", "rare", "pass_sunset_riot", "Sunset Riot", "#FF6A3D", "#7C2BD9", "stripes", PASS)
add("skin", "rare", "pass_zigzag_rookie", "Zigzag Rookie", "#4F8BFF", "#FFC83D", "waves", PASS)
add("skin", "rare", "pass_turbo_tide", "Turbo Tide", "#00C2B8", "#E6FFF9", "waves", PASS)
add("trail", "rare", "pass_neon_streak", "Neon Streak", "#00F0FF", "#FF2E9A", "stripes", PASS)
add("trail", "common", "pass_pebble_dash", "Pebble Dash", "#C9B8FF", nil, "dots", PASS)

Catalog.items = items

-- True when a release tag (nil = always out) is open at unix time `now`.
function Catalog.isReleaseOpen(release: string?, now: number): boolean
	if release == nil then
		return true
	end
	if release == "pass" then
		local bp = Config.BattlePass
		return bp.Start > 0 and now >= bp.Start
	end
	local start = Config.WeekTwo.Start
	return start > 0 and now >= start
end

function Catalog.byId(id: string): Item?
	return itemsById[id]
end

-- Released items of one type (shop lists, bot outfits). Catalog.byId still finds unreleased ones.
function Catalog.ofType(itemType: string): { Item }
	local now = os.time()
	local out = {}
	for _, item in items do
		if item.type == itemType and Catalog.isReleaseOpen(item.release, now) then
			table.insert(out, item)
		end
	end
	return out
end

-- Config.Prices key for an item (biome skins share Legendary rarity but have their own price).
function Catalog.priceTier(item: Item): string
	return item.priceTier or item.rarity
end

local function sellable(item: Item): boolean
	return item.default ~= true and item.source == nil and item.crownsRequired == nil and Config.Prices[Catalog.priceTier(item) :: any] ~= nil
end

local function isPurchasable(item: Item, now: number?): boolean
	return sellable(item) and Catalog.isReleaseOpen(item.release, now or os.time())
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
	local dayStart = dayNumber * 86400
	local ids = {}
	local out = {}
	-- The week-two items lead the row for their first FeaturedDays.
	local start = Config.WeekTwo.Start
	local fresh = start > 0 and dayStart + 86399 >= start and dayNumber < start // 86400 + Config.WeekTwo.FeaturedDays
	for _, item in items do
		if isPurchasable(item, dayStart + 86399) then
			if fresh and item.release == "weekTwo" and #out < Config.Prices.FeaturedCount then
				table.insert(out, item.id)
			else
				table.insert(ids, item.id)
			end
		end
	end
	local rng = makeRng(dayNumber * 7919 + 13)
	local shuffled = shuffle(ids, rng)
	for i = 1, Config.Prices.FeaturedCount - #out do
		table.insert(out, shuffled[i])
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

-- count 3: the classic daily quests (random difficulty). count 5: Turf Pass missions while a season is open,
-- slots 1-3 easy, 4 medium, 5 hard (pools are ordered easy -> hard); mission XP is by slot (Config.BattlePass).
function Catalog.questsForDay(dayNumber: number, userId: number, count: number?): { Quest }
	local n = count or 3
	local rng = makeRng(dayNumber * 104729 + userId * 31 + 7)
	local kinds = shuffle(Catalog.questKinds, rng)
	local out = {}
	for i = 1, n do
		local pool = {}
		for _, quest in Catalog.quests do
			if quest.kind == kinds[i] then
				table.insert(pool, quest)
			end
		end
		local pick = rng(#pool)
		if n > 3 then
			pick = if i <= 3 then 1 elseif i == 4 then math.min(2, #pool) else #pool
		end
		out[i] = pool[pick]
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

-- One-time bonuses for consecutive daily claims (profile.daily.run), each granted once per profile ever.
export type DailyMilestone = { day: number, currency: string, amount: number, skin: string? }
Catalog.dailyMilestones = {
	{ day = 14, currency = "gems", amount = 150 },
	{ day = 21, currency = "gems", amount = 250 },
	{ day = 28, currency = "gems", amount = 500, skin = "streak_month" },
} :: { DailyMilestone }

-- First milestone with day >= fromDay that is not in `claimed` (keys are tostring(day)), or nil.
function Catalog.nextDailyMilestone(fromDay: number, claimed: { [string]: boolean }): DailyMilestone?
	for _, m in Catalog.dailyMilestones do
		if m.day >= fromDay and not claimed[tostring(m.day)] then
			return m
		end
	end
	return nil
end

-- Playtime rewards, once per UTC day (seconds played that day, across sessions)
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
	CROWNRUSH = { currency = "gems", amount = 50 }, -- week-two code, works from Config.WeekTwo.Start
}
-- Codes that only work once their release is open (Catalog.isReleaseOpen).
Catalog.codeRelease = { CROWNRUSH = "weekTwo" } :: { [string]: string }

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
