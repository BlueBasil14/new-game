--!strict
local F = require(script.Parent.Formulas)

local function eq(a: any, b: any, msg: string)
	if a ~= b then
		error(msg .. ": got " .. tostring(a) .. " expected " .. tostring(b), 2)
	end
end
local function near(a: number, b: number, msg: string)
	if math.abs(a - b) > 1e-9 then
		error(msg .. ": got " .. tostring(a) .. " expected " .. tostring(b), 2)
	end
end

eq(F.upgradeCost("coinBoost", 0), 100, "coinBoost 0")
eq(F.upgradeCost("coinBoost", 1), 145, "coinBoost 1")
eq(F.upgradeCost("speed", 0), 150, "speed 0")
eq(F.upgradeCost("speed", 1), 265, "speed 1") -- 262.5 rounds to 265
eq(F.upgradeCost("startSize", 1), 5000, "startSize 1")
eq(F.upgradeCost("shield", 2), 1200, "shield 2")
eq(F.upgradeCost("speed", 10), nil, "speed max")
eq(F.upgradeCost("coinBoost", 19) ~= nil, true, "coinBoost 19")
eq(F.upgradeCost("coinBoost", 20), nil, "coinBoost max")
eq(F.upgradeCost("bogus", 0), nil, "unknown")

near(F.upgradeValue("speed", 10), 1.15, "speed value")
eq(F.upgradeValue("startSize", 0), 5, "start 0")
eq(F.upgradeValue("startSize", 3), 11, "start 3")
near(F.upgradeValue("coinBoost", 20), 3, "boost 20")
near(F.upgradeValue("shield", 0), 3, "shield 0")
near(F.upgradeValue("shield", 5), 5.5, "shield 5")

local base = { coinBoostLevel = 0, crowns = 0, vip = false, doubleCoins = false, boostActive = false, inGroup = false, weekend = false }
near(F.coinMultiplier(base), 1, "mult base")
near(F.coinMultiplier({ coinBoostLevel = 5, crowns = 2, vip = true, doubleCoins = true, boostActive = true, inGroup = true, weekend = true }),
	1.5 * 1.5 * 1.2 * 2 * 2 * 1.1 * 2, "mult all")
near(F.coinMultiplier({ coinBoostLevel = 0, crowns = 4, vip = false, doubleCoins = false, boostActive = false, inGroup = true, weekend = false }), 2.2, "mult crowns+group")

eq(F.captureCoins(10, 0), 10, "capture small")
eq(F.captureCoins(100, 0), 110, "capture 100")
eq(F.captureCoins(50, 50), 150 * 1.1, "capture mixed 100 cells") -- 50 + 100 = 150, +10%
eq(F.captureCoins(400, 0), 500, "capture 400")
eq(F.captureCoins(1000, 0), 1500, "capture 1000")
eq(F.captureCoins(0, 0), 0, "capture none")

eq(F.killCoins(200, true), 90, "king kill")
eq(F.killCoins(200, false), 45, "kill")
eq(F.killCoins(0, false), 25, "kill zero")
eq(F.passiveCoins(399), 19, "passive")
eq(F.passiveCoins(19), 0, "passive none")

eq(F.rebirthRequirement(0), 150000, "rebirth 0")
eq(F.rebirthRequirement(2), 600000, "rebirth 2")

-- 2024-01-06 00:00:00 UTC was a Saturday: 1704499200
eq(F.dayNumber(1704499200), 19728, "day number")
eq(F.dayNumber(1704499200 + 86399), 19728, "day end")
eq(F.isWeekendUTC(1704499200), true, "sat")
eq(F.isWeekendUTC(1704499200 + 86400 + 100), true, "sun")
eq(F.isWeekendUTC(1704499200 + 2 * 86400), false, "mon")
eq(F.isWeekendUTC(1704499200 - 1), false, "fri")
eq(F.isWeekendUTC(0), false, "thursday epoch")

local s = F.dailyClaimState(100, 3, 100)
eq(s.canClaim, false, "same day")
eq(s.nextStreak, 3, "same day streak")
s = F.dailyClaimState(100, 3, 101)
eq(s.canClaim, true, "next day")
eq(s.nextStreak, 4, "next streak")
s = F.dailyClaimState(100, 7, 101)
eq(s.nextStreak, 1, "wrap")
s = F.dailyClaimState(100, 3, 102)
eq(s.canClaim, true, "gap")
eq(s.nextStreak, 1, "gap reset")
s = F.dailyClaimState(0, 0, 19000)
eq(s.nextStreak, 1, "first ever")

local p = F.itemPrice("common", false) :: { currency: string, amount: number }
eq(p.currency, "coins", "common cur")
eq(p.amount, 500, "common amt")
p = F.itemPrice("rare", true) :: { currency: string, amount: number }
eq(p.amount, 4000, "rare featured")
p = F.itemPrice("epic", false) :: { currency: string, amount: number }
eq(p.currency, "gems", "epic cur")
eq(p.amount, 150, "epic amt")
p = F.itemPrice("legendary", true) :: { currency: string, amount: number }
eq(p.amount, 320, "legendary featured")
eq(F.itemPrice("crown", false), nil, "crown")
eq(F.itemPrice("exclusive", true), nil, "exclusive")

return "formulas ok"
