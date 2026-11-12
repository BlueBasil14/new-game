--!strict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Formulas = require(Shared.Formulas)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)
local ShopService = require(script.Parent.ShopService)

local UpgradeService = {}

local listeners: { (Player, number) -> () } = {}
UpgradeService.rebirthed = {
	Connect = function(_self: any, fn: (Player, number) -> ())
		table.insert(listeners, fn)
		return {
			Disconnect = function()
				local i = table.find(listeners, fn)
				if i then
					table.remove(listeners, i)
				end
			end,
		}
	end,
}

local UPGRADE_IDS = Config.Upgrades :: { [string]: any }

local function level(player: Player, upgradeId: string): number
	local profile = DataService.get(player)
	if profile == nil then
		return 0
	end
	return (profile.upgrades :: any)[upgradeId]
end

function UpgradeService.walkSpeed(player: Player): number
	return Config.Arena.BaseWalkSpeed * Formulas.upgradeValue("speed", level(player, "speed"))
end

function UpgradeService.startPatch(player: Player): number
	return Formulas.upgradeValue("startSize", level(player, "startSize"))
end

function UpgradeService.shieldSeconds(player: Player): number
	return Formulas.upgradeValue("shield", level(player, "shield"))
end

function UpgradeService.buy(player: Player, upgradeId: any): (boolean, any)
	if type(upgradeId) ~= "string" or UPGRADE_IDS[upgradeId] == nil then
		return false, "unknown_upgrade"
	end
	local profile = DataService.get(player)
	if profile == nil then
		return false, "no_profile"
	end
	local current: number = (profile.upgrades :: any)[upgradeId]
	local cost = Formulas.upgradeCost(upgradeId, current)
	if cost == nil then
		return false, "max_level"
	end
	if not EconomyService.spend(player, "coins", cost) then
		return false, "insufficient_funds"
	end
	local newLevel = current + 1
	DataService.update(player, function(p)
		(p.upgrades :: any)[upgradeId] = newLevel
	end)
	return true, { id = upgradeId, level = newLevel, cost = cost }
end

function UpgradeService.rebirth(player: Player): (boolean, any)
	local profile = DataService.get(player)
	if profile == nil then
		return false, "no_profile"
	end
	if profile.lifetimeCoinsSinceRebirth < Formulas.rebirthRequirement(profile.crowns) then
		return false, "not_enough_coins"
	end
	-- No yields between the check above and the writes below.
	EconomyService.resetCoins(player)
	EconomyService.addGems(player, Config.Rebirth.GemReward, "rebirth")
	local crowns = 0
	DataService.update(player, function(p)
		for id in UPGRADE_IDS do
			(p.upgrades :: any)[id] = 0
		end
		p.crowns += 1
		crowns = p.crowns
	end)
	ShopService.reconcile(player)
	for _, cb in table.clone(listeners) do
		task.spawn(cb, player, crowns)
	end
	return true, { crowns = crowns }
end

return UpgradeService
