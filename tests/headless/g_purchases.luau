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
		Config.Ids.Passes.doubleSpeed = 2001 -- skipMusic stays 0: granted through the Studio debug hook below
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
-- game passes: 2x Speed via PromptGamePassPurchaseFinished doubles the applied and allowed speed at once
local Econ = H.svc("EconomyService")
local base = H.humanoid(p).WalkSpeed
H.check(base > 0, "player walking")
H.firePassPurchase(p, 2001, false)
H.run(0.2)
H.check(not Econ.hasPass(p, "doubleSpeed"), "declined purchase granted the pass")
H.firePassPurchase(p, 2001, true)
H.run(0.5)
H.check(Econ.hasPass(p, "doubleSpeed"), "doubleSpeed not owned after purchase")
H.eq(H.humanoid(p).WalkSpeed, base * Config.Passes.doubleSpeed.SpeedMultiplier, "doubled WalkSpeed")
-- owner walks at the doubled speed without strikes or snap-backs
local cx0, cy0 = H.cellOf(p)
local dir = if cx0 < Config.Arena.GridSize / 2 then 1 else -1 -- walk toward the centre
H.walkCells(p, { { cx0 + 8 * dir, cy0 } })
H.run(2)
local cx1 = H.cellOf(p)
H.check((cx1 - cx0) * dir >= 6, "fast owner was snapped back")
H.check(H.inGame(p), "fast owner kicked")
-- Studio debug grant runs the same path; session.passes carries both new keys
local main = H.S.modules["ServerScriptService.Server.Main"]
local grant = main:FindFirstChild("DebugGrantPass")
H.check(grant ~= nil, "DebugGrantPass missing in Studio")
H.clearSent(p)
grant:Fire(p, "skipMusic")
H.run(0.5)
H.check(Econ.hasPass(p, "skipMusic"), "debug grant skipMusic")
local upd = H.last(p, "ProfileUpdate")
H.check(upd ~= nil, "no ProfileUpdate after pass grant")
local passes = upd.args[1].session.passes
H.eq(passes.skipMusic, true, "session.passes.skipMusic")
H.eq(passes.doubleSpeed, true, "session.passes.doubleSpeed")
