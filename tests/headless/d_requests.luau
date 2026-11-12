-- (d) every Request with valid args on a fresh profile, then hostile args and rate limiting.
H.boot()
H.run(1)
local Formulas = H.shared("Formulas")
local Catalog = H.shared("Catalog")
local Remotes = H.shared("Remotes")
local Arena = H.svc("ArenaService")
local Data = H.svc("DataService")
local Econ = H.svc("EconomyService")
local p = H.addPlayer({ userId = 777, name = "Req" })
H.runUntil(function() return Arena.runnerIdOf(p) ~= 0 end, 10, "runner")

local function req(...)
	H.run(0.15) -- stay under the rate limit
	return H.invoke(p, ...)
end
local function expect(want, ...)
	local ok, res = req(...)
	local name = tostring((...))
	if type(want) == "string" then
		H.check(ok == false and res == want, "%s: expected false,%s got %s,%s", name, want, tostring(ok), tostring(res))
	else
		H.check(ok == true, "%s: expected success, got %s,%s", name, tostring(ok), tostring(res))
	end
	return res
end
local common
for _, item in Catalog.items do
	if item.rarity == "common" and Catalog.isPurchasable(item) and not item.default then common = item.id break end
end

-- valid args, fresh profile
expect("insufficient_funds", "BuyUpgrade", "coinBoost")
expect("unknown_upgrade", "BuyUpgrade", "nope")
expect("unknown_item", "BuyItem", "nope")
if common then expect("insufficient_funds", "BuyItem", common) end
H.eq(expect(true, "Equip", "default"), "default", "Equip result")
expect("unknown_item", "Equip", "nope")
if common then expect("not_owned", "Equip", common) end
local daily = expect(true, "ClaimDaily")
H.eq(daily.streak, 1, "daily streak")
expect("already_claimed", "ClaimDaily")
expect("too_early", "ClaimPlaytime", 1)
expect("bad_args", "ClaimPlaytime", 99)
expect("not_complete", "ClaimQuest", 1)
expect("bad_args", "ClaimQuest", 9)
local code = expect(true, "RedeemCode", "release")
H.eq(code.amount, Catalog.codes.RELEASE.amount, "code amount")
expect("already_used", "RedeemCode", "RELEASE")
expect("invalid_code", "RedeemCode", "NOPE")
expect("not_enough_coins", "Rebirth")
expect("not_dead", "Respawn")
expect("not_pending", "DeclineSecondChance")
H.eq(expect(true, "SetSetting", "music", false), false, "SetSetting result")
expect(true, "TutorialDone")
expect(true, "StarterOfferSeen")
H.check(Data.get(p).settings.music == false and Data.get(p).tutorialDone, "settings/tutorial not stored")
H.check(H.last(p, "ArenaSnapshot") ~= nil, "first request did not (re)send the snapshot")
do -- Ready: being added concurrently by another programmer; report, do not fail
	local ok, r = req("Ready")
	H.say("Ready ->", ok, r)
end
-- every Request name was exercised
for name in Remotes.Requests do
	local seen = false
	for _, n in { "BuyUpgrade", "BuyItem", "Equip", "ClaimDaily", "ClaimPlaytime", "ClaimQuest", "RedeemCode", "Rebirth",
		"Respawn", "DeclineSecondChance", "SetSetting", "TutorialDone", "StarterOfferSeen", "Ready" } do
		if n == name then seen = true end
	end
	if not seen then H.say("WARNING: request not covered by this scenario:", name) end
end

-- hostile args
expect("bad_request", "Explode")
expect("bad_request", { "BuyUpgrade" })
expect("bad_request", nil)
expect("unknown_upgrade", "BuyUpgrade", 5)
expect("bad_args", "BuyUpgrade", string.rep("x", 100000))
expect("bad_args", "BuyUpgrade", { "coinBoost" })
expect("bad_args", "ClaimPlaytime", 0 / 0)
expect("bad_args", "ClaimPlaytime", math.huge)
expect("bad_args", "ClaimQuest", 1.5)
expect("bad_args", "SetSetting", "music", "yes")
expect("bad_args", "SetSetting", "__index", true)
expect("bad_args", "RedeemCode", string.rep("A", 30))
expect("bad_args", "Equip", 1, 2, 3, 4, 5)
expect("unknown_item", "Equip", "default\0")
H.check(Data.get(p) ~= nil, "profile lost")

-- buy the first Coin Boost with coins granted through the economy service
H.run(1.2)
local before = Data.get(p).coins
local cost = Formulas.upgradeCost("coinBoost", 0)
Econ.addCoins(p, cost, "test", false)
local res = expect(true, "BuyUpgrade", "coinBoost")
H.eq(res.level, 1, "coinBoost level")
H.eq(res.cost, cost, "cost")
H.eq(Data.get(p).coins, before, "coins deducted by upgradeCost")
H.eq(Data.get(p).upgrades.coinBoost, 1, "profile upgrade")
H.run(0.5)
H.eq(H.last(p, "ProfileUpdate").args[1].profile.upgrades.coinBoost, 1, "ProfileUpdate shows upgrade")

-- 100 rapid calls
H.run(1.5)
local limited = 0
for _ = 1, 100 do
	local ok, r = H.invoke(p, "TutorialDone")
	if ok == false and r == "rate_limited" then limited += 1 end
end
H.check(limited >= 85, "only %d of 100 rapid calls were rate limited", limited)
H.say("rate limited", limited, "of 100; coinBoost cost", cost)
H.eq(#H.S.kicks, 0, "kicks")
