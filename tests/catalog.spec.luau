--!strict
local Catalog = require(script.Parent.Catalog)
local Formulas = require(script.Parent.Formulas)
local Config = require(script.Parent.Config)

local function eq(a: any, b: any, msg: string)
	if a ~= b then
		error(msg .. ": got " .. tostring(a) .. " expected " .. tostring(b), 2)
	end
end

local seen: { [string]: boolean } = {}
local counts: { [string]: number } = {}
for _, item in Catalog.items do
	eq(seen[item.id], nil, "duplicate " .. item.id)
	seen[item.id] = true
	eq(item.id:match("^[a-z0-9_]+$") ~= nil, true, "snake_case " .. item.id)
	eq(Catalog.byId(item.id), item, "byId " .. item.id)
	if item.default ~= true then
		local k = item.type .. ":" .. item.rarity
		counts[k] = (counts[k] or 0) + 1
	end
end
local expect = {
	["skin:common"] = 12, ["skin:rare"] = 9, ["skin:epic"] = 7, ["skin:legendary"] = 3, ["skin:crown"] = 4,
	["trail:common"] = 2, ["trail:rare"] = 3, ["trail:epic"] = 3, ["trail:legendary"] = 1,
	["effect:rare"] = 2, ["effect:epic"] = 1, ["effect:legendary"] = 1,
	["skin:exclusive"] = 10, ["trail:exclusive"] = 3, -- skin +streak_month (T-RET-02, departs from GDD G3.6)
}
for k, v in expect do
	eq(counts[k], v, "count " .. k)
end
for k, v in counts do
	eq(expect[k], v, "unexpected bucket " .. k)
end
eq(#Catalog.ofType("effect"), 5, "effects incl default") -- sparkle + 4
eq(#Catalog.ofType("trail"), 8 + 1 + 2, "trails")
eq(#Catalog.ofType("skin"), 1 + 33 + 10, "skins")
eq((Catalog.byId("default") :: any).default, true, "default flag")
eq(Catalog.byId("nope"), nil, "missing")
eq((Catalog.byId("sparkle") :: any).type, "effect", "sparkle")

local crowns = { 1, 3, 5, 10 }
local ci = 0
for _, item in Catalog.ofType("skin") do
	if item.rarity == "crown" then
		ci += 1
		eq(item.crownsRequired, crowns[ci], "crown req")
	end
end
eq(ci, 4, "crown skins")
eq((Catalog.byId("vip_gold") :: any).source, "vip", "vip src")
eq((Catalog.byId("streak_week") :: any).source, "daily7", "daily7 src")
eq((Catalog.byId("team") :: any).source, "group", "group src")
eq((Catalog.byId("starter_spark") :: any).source, "starterPack", "starter src")

for _, item in Catalog.items do
	if item.default ~= true then
		local price = Formulas.itemPrice(item.rarity, false)
		if item.rarity == "crown" or item.rarity == "exclusive" then
			eq(price, nil, "no price " .. item.id)
		else
			eq(price ~= nil, true, "price " .. item.id)
			eq(Catalog.isPurchasable(item), item.release == nil, "purchasable " .. item.id)
		end
	end
end

for day = 19000, 19040 do
	local f = Catalog.featured(day)
	eq(#f, Config.Prices.FeaturedCount, "featured size")
	local u: { [string]: boolean } = {}
	for _, id in f do
		eq(u[id], nil, "featured dup")
		u[id] = true
		local item = Catalog.byId(id) :: Catalog.Item
		eq(Catalog.isPurchasable(item), true, "featured purchasable " .. id)
	end
	local g = Catalog.featured(day)
	for i = 1, #f do
		eq(f[i], g[i], "featured stable")
	end
end
local differs = false
local a, b = Catalog.featured(19000), Catalog.featured(19001)
for i = 1, 6 do
	if a[i] ~= b[i] then differs = true end
end
eq(differs, true, "featured rotates")

for day = 19000, 19060 do
	for _, uid in { 1, 12345, 987654321 } do
		local qs = Catalog.questsForDay(day, uid)
		eq(#qs, 3, "quest count")
		eq(qs[1].kind ~= qs[2].kind and qs[1].kind ~= qs[3].kind and qs[2].kind ~= qs[3].kind, true, "distinct kinds")
		local qs2 = Catalog.questsForDay(day, uid)
		for i = 1, 3 do
			eq(qs[i].id, qs2[i].id, "quest stable")
		end
	end
end

eq(#Catalog.daily, 7, "daily")
eq(Catalog.daily[7].skin, "streak_week", "daily7 skin")
eq(#Catalog.dailyMilestones, 3, "milestones")
eq(Catalog.dailyMilestones[1].day, 14, "milestone 14")
eq(Catalog.dailyMilestones[2].amount, 250, "milestone 21 amount")
eq(Catalog.dailyMilestones[3].skin, "streak_month", "milestone 28 skin")
eq((Catalog.byId("streak_month") :: any).source, "daily28", "daily28 src")
eq((Catalog.byId("streak_month") :: any).rarity, "exclusive", "streak_month exclusive")
eq(Catalog.isPurchasable(Catalog.byId("streak_month") :: any), false, "streak_month not for sale")
for _, m in Catalog.dailyMilestones do
	eq(m.skin == nil or Catalog.byId(m.skin) ~= nil, true, "milestone skin exists")
end
eq((Catalog.nextDailyMilestone(1, {}) :: any).day, 14, "next from 1")
eq((Catalog.nextDailyMilestone(14, {}) :: any).day, 14, "next at 14")
eq((Catalog.nextDailyMilestone(15, {}) :: any).day, 21, "next from 15")
eq((Catalog.nextDailyMilestone(1, { ["14"] = true }) :: any).day, 21, "skip claimed")
eq(Catalog.nextDailyMilestone(29, {}), nil, "none above 28")
eq(Catalog.nextDailyMilestone(1, { ["14"] = true, ["21"] = true, ["28"] = true }), nil, "all claimed")
eq(#Catalog.playtime, 5, "playtime")
eq(Catalog.playtime[1].seconds, 120, "playtime first")
eq(Catalog.playtime[5].seconds, 1800, "playtime last")
eq(Catalog.codes.RELEASE.amount, 1000, "code release")
eq(Catalog.codes.TURF.currency, "gems", "code turf")
eq(#Catalog.badges, 8, "badges")
for _, bd in Catalog.badges do
	eq((Config.Ids.Badges :: any)[bd.key] ~= nil, true, "badge key " .. bd.key)
end

-- Week-two update: hidden while Config.WeekTwo.Start = 0, sold and featured from Start.
do
	local tide = Catalog.byId("tide_pool") :: Catalog.Item
	local NOW = 1800000000 -- a Friday, 00:00 UTC is not required for this check
	eq(Catalog.isPurchasable(tide, NOW), false, "week-two item for sale before Start")
	for _, item in Catalog.ofType("skin") do
		eq(item.release, nil, "unreleased item listed")
	end
	eq(Catalog.isReleaseOpen(Catalog.codeRelease.CROWNRUSH, NOW), false, "CROWNRUSH open before Start")
	local day = NOW // 86400
	Config.WeekTwo.Start = day * 86400
	eq(Catalog.isPurchasable(tide, NOW), true, "week-two item not for sale after Start")
	local f = Catalog.featured(day)
	eq(#f, Config.Prices.FeaturedCount, "featured count in week two")
	eq(table.find(f, "tide_pool") ~= nil and table.find(f, "trail_comet") ~= nil, true, "week-two items not featured")
	eq(table.find(f, "crown_rush_trail"), nil, "won trail featured")
	eq(table.find(Catalog.featured(day + Config.WeekTwo.FeaturedDays), "tide_pool") == 1, false, "still forced after FeaturedDays")
	eq(Catalog.isPurchasable(Catalog.byId("crown_rush_trail") :: Catalog.Item, NOW), false, "won trail for sale")
	Config.WeekTwo.Start = 0
	-- Crown Rush window and King multiplier
	eq(Formulas.isCrownRush(NOW), false, "rush with Start 0")
	Config.CrownRush.Start, Config.CrownRush.End = NOW, NOW + 3600
	eq(Formulas.isCrownRush(NOW + 10), true, "rush inside window")
	eq(Formulas.isCrownRush(NOW + 3600), false, "rush at End")
	local base = { coinBoostLevel = 0, crowns = 0, vip = false, doubleCoins = false, boostActive = false, inGroup = false, weekend = false }
	local king = table.clone(base) :: any
	king.crownRushKing = true
	eq(Formulas.coinMultiplier(king), Formulas.coinMultiplier(base) * Config.CrownRush.KingMultiplier, "king multiplier")
	Config.CrownRush.Start, Config.CrownRush.End = 0, 0
end
return "catalog ok (incl. week two)"
