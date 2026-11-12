--!strict
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local Formulas = require(Shared.Formulas)
local DataService = require(script.Parent.DataService)
local EconomyService = require(script.Parent.EconomyService)

local ShopService = {}

local listeners: { (Player, { skin: string, trail: string, effect: string }) -> () } = {}
ShopService.equippedChanged = {
	Connect = function(_self: any, fn: (Player, { skin: string, trail: string, effect: string }) -> ())
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

local started = false

function ShopService.owns(player: Player, itemId: string): boolean
	local profile = DataService.get(player)
	return profile ~= nil and profile.owned[itemId] == true
end

-- True only when the item was newly added.
function ShopService.grantItem(player: Player, itemId: string): boolean
	if type(itemId) ~= "string" or Catalog.byId(itemId) == nil then
		return false
	end
	local added = false
	DataService.update(player, function(profile)
		if profile.owned[itemId] ~= true then
			profile.owned[itemId] = true
			added = true
		end
	end)
	return added
end

-- Idempotent: defaults, crown-tier skins by crowns, and items tied to passes, group or the starter pack.
function ShopService.reconcile(player: Player)
	DataService.update(player, function(profile)
		for _, item in Catalog.items do
			local entitled = item.default == true
			if item.crownsRequired ~= nil and profile.crowns >= item.crownsRequired then
				entitled = true
			end
			local source = item.source
			if source ~= nil then
				if (Config.Ids.Passes :: any)[source] ~= nil then
					entitled = entitled or EconomyService.hasPass(player, source)
				elseif source == "group" then
					entitled = entitled or EconomyService.isInGroup(player)
				elseif source == "starterPack" then
					entitled = entitled or profile.starterPackBought
				end
			end
			if entitled and profile.owned[item.id] ~= true then
				profile.owned[item.id] = true
			end
		end
	end)
end

function ShopService.buyItem(player: Player, itemId: any): (boolean, any)
	if type(itemId) ~= "string" then
		return false, "bad_args"
	end
	local item = Catalog.byId(itemId)
	local profile = DataService.get(player)
	if item == nil then
		return false, "unknown_item"
	end
	if profile == nil then
		return false, "no_profile"
	end
	if profile.owned[itemId] == true then
		return false, "already_owned"
	end
	if item.crownsRequired ~= nil and profile.crowns < item.crownsRequired then
		return false, "crowns_required"
	end
	if not Catalog.isPurchasable(item) then
		return false, "not_for_sale"
	end
	local featured = table.find(Catalog.featured(Formulas.dayNumber(os.time())), itemId) ~= nil
	local price = Formulas.itemPrice(item.rarity, featured)
	if price == nil then
		return false, "not_for_sale"
	end
	if not EconomyService.spend(player, price.currency, price.amount) then
		return false, "insufficient_funds"
	end
	ShopService.grantItem(player, itemId)
	return true, { id = itemId, currency = price.currency, amount = price.amount }
end

function ShopService.equip(player: Player, itemId: any): (boolean, any)
	if type(itemId) ~= "string" then
		return false, "bad_args"
	end
	local item = Catalog.byId(itemId)
	if item == nil then
		return false, "unknown_item"
	end
	local equipped: { skin: string, trail: string, effect: string }? = nil
	local err = "not_owned"
	DataService.update(player, function(profile)
		if profile.owned[itemId] ~= true then
			return
		end
		if item.type == "skin" then
			profile.equipped.skin = itemId
		elseif item.type == "trail" then
			profile.equipped.trail = itemId
		elseif item.type == "effect" then
			profile.equipped.effect = itemId
		else
			err = "unknown_item"
			return
		end
		equipped = profile.equipped
	end)
	if equipped == nil then
		return false, err
	end
	for _, cb in table.clone(listeners) do
		task.spawn(cb, player, equipped)
	end
	return true, itemId
end

function ShopService.start()
	if started then
		return
	end
	started = true
	local function onPlayer(player: Player)
		if DataService.load(player) ~= nil then
			ShopService.reconcile(player)
		end
	end
	Players.PlayerAdded:Connect(function(player)
		task.spawn(onPlayer, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end
end

return ShopService
