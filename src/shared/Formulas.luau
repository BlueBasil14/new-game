--!strict
-- Pure economy and calendar formulas. Every number comes from Config.
local Config = require(script.Parent.Config)

local Formulas = {}

type UpgradeDef = { Max: number, Base: number, Growth: number, PerLevel: number }
local Upgrades = Config.Upgrades :: { [string]: UpgradeDef }

export type CoinContext = {
	coinBoostLevel: number,
	crowns: number,
	vip: boolean,
	doubleCoins: boolean,
	boostActive: boolean,
	inGroup: boolean,
	weekend: boolean,
}

local SECONDS_PER_DAY = 86400
local DAYS_PER_WEEK = 7
local EPOCH_WEEKDAY = 4 -- 1970-01-01 was a Thursday (0 = Sunday)
local SATURDAY, SUNDAY = 6, 0

local function round(x: number): number
	return math.floor(x + 0.5)
end

local function roundTo5(x: number): number
	return round(x / 5) * 5
end

-- nil at max level (or unknown upgrade)
function Formulas.upgradeCost(upgradeId: string, currentLevel: number): number?
	local def = Upgrades[upgradeId]
	if def == nil or currentLevel >= def.Max then
		return nil
	end
	return roundTo5(def.Base * def.Growth ^ currentLevel)
end

function Formulas.upgradeValue(upgradeId: string, level: number): number
	local def = Upgrades[upgradeId]
	if upgradeId == "startSize" then
		return Config.Arena.StartPatch + def.PerLevel * level
	elseif upgradeId == "shield" then
		return Config.Arena.SpawnShield + def.PerLevel * level
	end
	return 1 + def.PerLevel * level -- speed, coinBoost
end

function Formulas.coinMultiplier(ctx: CoinContext): number
	local inc = Config.Income
	local m = Formulas.upgradeValue("coinBoost", ctx.coinBoostLevel)
	m *= 1 + inc.RebirthBonusPerCrown * ctx.crowns
	if ctx.vip then
		m *= inc.VipMultiplier
	end
	if ctx.doubleCoins then
		m *= inc.DoubleCoinsMultiplier
	end
	if ctx.boostActive then
		m *= inc.BoostMultiplier
	end
	if ctx.inGroup then
		m *= 1 + inc.GroupBonus
	end
	if ctx.weekend then
		m *= inc.WeekendMultiplier
	end
	return m
end

-- Base coins for one capture; size bonus tier is chosen by the capture's total cell count.
function Formulas.captureCoins(neutralCells: number, stolenCells: number): number
	local inc = Config.Income
	local base = neutralCells * inc.CellNeutral + stolenCells * inc.CellStolen
	local total = neutralCells + stolenCells
	local bonus = 0
	for _, tier in inc.CaptureBonus do
		if total >= tier.MinCells then
			bonus = tier.Bonus
		end
	end
	return round(base * (1 + bonus))
end

function Formulas.killCoins(victimCells: number, victimWasKing: boolean): number
	local inc = Config.Income
	local coins = inc.KillBase + math.floor(victimCells * inc.KillVictimShare + 1e-9)
	if victimWasKing then
		coins *= inc.KingKillMultiplier
	end
	return coins
end

function Formulas.passiveCoins(ownCells: number): number
	return math.floor(ownCells / Config.Income.PassiveCellsPerCoin)
end

function Formulas.rebirthRequirement(crowns: number): number
	return Config.Rebirth.Base * 2 ^ crowns
end

function Formulas.dayNumber(unixSeconds: number): number
	return math.floor(unixSeconds / SECONDS_PER_DAY)
end

function Formulas.isWeekendUTC(unixSeconds: number): boolean
	local weekday = (Formulas.dayNumber(unixSeconds) + EPOCH_WEEKDAY) % DAYS_PER_WEEK
	return weekday == SATURDAY or weekday == SUNDAY
end

function Formulas.dailyClaimState(lastClaimDay: number, streak: number, today: number): { canClaim: boolean, nextStreak: number }
	local gap = today - lastClaimDay
	if gap <= 0 then
		return { canClaim = false, nextStreak = streak }
	elseif gap == 1 then
		return { canClaim = true, nextStreak = streak % DAYS_PER_WEEK + 1 }
	end
	return { canClaim = true, nextStreak = 1 }
end

-- nil when the rarity is not for sale (crown, exclusive, unknown)
function Formulas.itemPrice(rarity: string, featured: boolean): { currency: string, amount: number }?
	local def = (Config.Prices :: any)[rarity]
	if type(def) ~= "table" then
		return nil
	end
	local amount: number = def.Amount
	if featured then
		amount = round(amount * (1 - Config.Prices.FeaturedDiscount))
	end
	return { currency = def.Currency, amount = amount }
end

return Formulas
