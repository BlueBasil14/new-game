-- (g) ProcessReceipt for every product with test ids injected into Config.Ids before boot.
local ids = {}
H.boot({
	beforeMain = function(S)
		local Config = S.require(S.modules["ReplicatedStorage.Shared.Config"])
		local n = 0
		for key in Config.Ids.Products do
			n += 1
			Config.Ids.Products[key] = 1000 + n
			ids[key] = 1000 + n
		end
	end,
})
H.run(1)
local Config = H.shared("Config")
local Arena = H.svc("ArenaService")
local Data = H.svc("DataService")
local Enum = H.Enum
local p = H.addPlayer({ userId = 88, name = "Buyer" })
H.runUntil(function() return Arena.runnerIdOf(p) ~= 0 end, 10, "runner")
local purchase = 0
local function buy(key, pid)
	purchase += 1
	return H.processReceipt({ PlayerId = 88, ProductId = ids[key], PurchaseId = pid or ("P" .. purchase), PlaceIdWherePurchased = 0, CurrencySpent = 10 })
end
local G = Enum.ProductPurchaseDecision.PurchaseGranted
local NP = Enum.ProductPurchaseDecision.NotProcessedYet
for _, key in { "gemsS", "gemsM", "gemsL", "gemsXL" } do
	local g0 = Data.get(p).gems
	H.eq(buy(key), G, key)
	H.eq(Data.get(p).gems - g0, Config.Products[key].Gems, key .. " gems")
end
-- idempotency
local g0 = Data.get(p).gems
H.eq(buy("gemsS", "SAME"), G, "first")
H.eq(buy("gemsS", "SAME"), G, "repeat")
H.eq(Data.get(p).gems - g0, Config.Products.gemsS.Gems, "repeat PurchaseId granted twice")
-- starter pack once
local c0, gm0 = Data.get(p).coins, Data.get(p).gems
H.eq(buy("starterPack"), G, "starter 1")
H.eq(Data.get(p).coins - c0, Config.Products.starterPack.Coins, "starter coins")
H.check(Data.get(p).owned[Config.Products.starterPack.Skin], "starter skin")
H.check(Data.get(p).starterPackBought, "starter flag")
H.eq(buy("starterPack"), G, "starter 2")
H.eq(Data.get(p).coins - c0, Config.Products.starterPack.Coins, "starter coins granted twice")
H.say("starter pack second purchase gems delta", Data.get(p).gems - gm0)
-- boost
local b0 = os.time and nil
H.eq(buy("boost15"), G, "boost")
H.check(Data.get(p).boostUntil >= H.S.env.os.time() + Config.Products.boost15.Seconds - 1, "boost not active")
H.check(H.svc("EconomyService").multiplier(p) >= 2, "boost multiplier")
-- second chance while alive: refund
local g1 = Data.get(p).gems
H.eq(buy("secondChance"), G, "secondChance")
H.eq(Data.get(p).gems - g1, 20, "secondChance refund when not pending")
-- unknown player / unknown product
H.eq(H.processReceipt({ PlayerId = 99999, ProductId = ids.gemsS, PurchaseId = "X1" }), NP, "unknown player")
H.eq(H.processReceipt({ PlayerId = 88, ProductId = 5, PurchaseId = "X2" }), NP, "unknown product")
-- receipt persisted before PurchaseGranted
local stored = H.M.dsBacking.stores["PlayerData_v1/global"]["u_88"]
H.check(stored and table.find(stored.receipts, "SAME"), "receipt not saved before granting")
