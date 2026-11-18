--!strict
local BattlePass = require(script.Parent.BattlePass)
local Catalog = require(script.Parent.Catalog)
local Config = require(script.Parent.Config)

local function eq(a: any, b: any, msg: string)
	if a ~= b then
		error(msg .. ": got " .. tostring(a) .. " expected " .. tostring(b), 2)
	end
end

local CFG = Config.BattlePass
eq(#BattlePass.tiers, CFG.Tiers, "tier count")

-- Every item reward exists, is a pass item, and appears exactly once.
local seen: { [string]: boolean } = {}
local premGems = 0
for tier, t in BattlePass.tiers do
	eq(#t.free > 0 and #t.prem > 0, true, "both tracks filled " .. tier)
	for _, track in { t.free, t.prem } do
		for _, r in track do
			if r.kind == "item" then
				local it = Catalog.byId(r.id :: string)
				eq(it ~= nil, true, "item exists " .. tostring(r.id))
				eq((it :: Catalog.Item).source, "pass", "pass source " .. tostring(r.id))
				eq(seen[r.id :: string], nil, "item once " .. tostring(r.id))
				seen[r.id :: string] = true
			else
				eq(type(r.amount) == "number" and (r.amount :: number) > 0, true, "amount " .. tier)
			end
		end
	end
	for _, r in t.prem do
		if r.kind == "gems" then
			premGems += r.amount :: number
		end
	end
end
eq(premGems, 300, "premium gems kept at 300 (gem packs)")
for _, tier in BattlePass.legendaryTiers do
	local id = BattlePass.tiers[tier].prem[1].id :: string
	local it = Catalog.byId(id) :: Catalog.Item
	eq(it.rarity, "legendary", "legendary at " .. tier)
	eq(it.anim ~= nil, true, "animated at " .. tier)
end

-- Tiers and XP
eq(BattlePass.tierOf(0), 0, "tier 0")
eq(BattlePass.tierOf(999), 0, "tier 0 at 999")
eq(BattlePass.tierOf(1000), 1, "tier 1")
eq(BattlePass.tierOf(10 ^ 9), CFG.Tiers, "tier capped")

local st = BattlePass.fresh(1)
local gained, keys = BattlePass.addXp(st, 2500)
eq(gained, 2, "gained 2")
eq(keys, 0, "no bonus yet")
eq(BattlePass.addXp(st, -5), 0, "negative ignored")

-- Claims
eq(select(2, BattlePass.canClaim(st, "free", 3)), "too_early", "not reached")
eq(select(2, BattlePass.canClaim(st, "prem", 1)), "premium_required", "premium gate")
eq(select(2, BattlePass.canClaim(st, "free", 1.5)), "bad_args", "fractional tier")
eq(select(2, BattlePass.canClaim(st, "gold", 1)), "bad_args", "bad track")
eq(select(2, BattlePass.canClaim(st, "free", 0)), "bad_args", "tier 0")
eq((BattlePass.canClaim(st, "free", 1)), true, "claimable")
BattlePass.markClaimed(st, "free", 1)
eq(select(2, BattlePass.canClaim(st, "free", 1)), "already_claimed", "double claim")
eq(#BattlePass.unclaimed(st), 1, "one free left")
st.premium = true
eq(#BattlePass.unclaimed(st), 3, "premium adds two")

-- Bonus keys past the last tier
local full = BattlePass.fresh(1)
BattlePass.addXp(full, CFG.Tiers * CFG.XpPerTier + 2500)
eq(full.bonus, 2, "two bonus keys")
local _, more = BattlePass.addXp(full, 600)
eq(more, 1, "third bonus key")
local _, none = BattlePass.addXp(full, 100)
eq(none, 0, "no extra key")

-- Play XP cap
local p = BattlePass.fresh(1)
eq(BattlePass.playXp(p, 10, 300), 300, "play 300")
eq(BattlePass.playXp(p, 10, 300), CFG.PlayXpPerDay - 300, "capped")
eq(BattlePass.playXp(p, 10, 50), 0, "cap reached")
eq(BattlePass.playXp(p, 11, 50), 50, "new day resets")

-- Season roll: unclaimed reached rewards come back as leftovers
local old = BattlePass.fresh(1)
BattlePass.addXp(old, 2000)
old.premium = true
BattlePass.markClaimed(old, "free", 1)
local raw = table.clone(old) :: any
local nxt, leftovers = BattlePass.normalize(raw, 2)
eq(nxt.season, 2, "new season")
eq(nxt.xp, 0, "xp reset")
eq(nxt.premium, false, "premium reset")
local n = 0
for _ in BattlePass.unclaimed(old) do
	n += 1
end
eq(n, 3, "3 unclaimed (free 2, prem 1, prem 2)")
local expect = #BattlePass.rewards("free", 2) + #BattlePass.rewards("prem", 1) + #BattlePass.rewards("prem", 2)
eq(#leftovers, expect, "leftovers delivered")
local same, none2 = BattlePass.normalize(raw, 1)
eq(same.xp, 2000, "same season kept")
eq(#none2, 0, "no leftovers same season")
local junk = BattlePass.normalize({ xp = -5, premium = "yes", free = 0 / 0 }, 1)
eq(junk.xp, 0, "junk xp")
eq(junk.premium, false, "junk premium")
local brandNew, nothing = BattlePass.normalize(nil, 1)
eq(brandNew.season, 1, "nil -> fresh")
eq(#nothing, 0, "fresh has no leftovers")

-- Products
local buy = BattlePass.fresh(1)
eq(BattlePass.applyProduct(buy, "battlePass"), 0, "premium bought")
eq(buy.premium, true, "premium on")
eq(BattlePass.applyProduct(buy, "battlePass"), CFG.DuplicatePremiumGems, "duplicate premium refunds gems")
local plus = BattlePass.fresh(1)
BattlePass.applyProduct(plus, "battlePassPlus")
eq(plus.premium and BattlePass.tierOf(plus.xp) == 10, true, "plus = premium + 10 tiers")
BattlePass.applyProduct(plus, "battlePassTier")
eq(BattlePass.tierOf(plus.xp), 11, "tier skip")
BattlePass.applyProduct(plus, "battlePassTiers10")
eq(BattlePass.tierOf(plus.xp), 21, "owners +10 tiers")

-- Missions
eq(BattlePass.missionXp(5, false), 800, "hard mission")
eq(BattlePass.missionXp(1, true), 600, "catch-up doubles")

-- Premium earned counter counts skins only
local counter = BattlePass.fresh(1)
BattlePass.addXp(counter, 12000)
local got = BattlePass.premiumReached(counter, function(id)
	local it = Catalog.byId(id)
	return if it and it.type == "skin" then it.rarity else nil
end)
eq(got.legendary, 2, "neon pulse + magma surge")
eq(got.rare, 2, "sour blast + frost bite")
eq(got.gems, 120, "100 + 20 gems by tier 12")

return "battlepass ok"
