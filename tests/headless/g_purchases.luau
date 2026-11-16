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
		Config.Ids.Passes.doubleCoins = 2002
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
-- Failed persistence must stay pending, including repeat delivery in this server.
local realSave = Data.save
local failMode = "false"
Data.save = function(player)
	if failMode == "error" then error("injected receipt save failure") end
	if failMode == "false" then return false end
	return realSave(player)
end
local beforeFailure = Data.get(p).gems
H.eq(buy("gemsS", "RETRY_SAVE"), NP, "failed save acknowledged")
H.eq(buy("gemsS", "RETRY_SAVE"), NP, "unsaved in-memory receipt acknowledged")
failMode = "error"
H.eq(buy("gemsS", "RETRY_SAVE"), NP, "throwing save acknowledged")
H.eq(Data.get(p).gems - beforeFailure, Config.Products.gemsS.Gems, "retry granted twice")
failMode = "ok"
H.eq(buy("gemsS", "RETRY_SAVE"), G, "successful retry not acknowledged")
H.eq(Data.get(p).gems - beforeFailure, Config.Products.gemsS.Gems, "successful retry granted twice")
Data.save = realSave
stored = H.M.dsBacking.stores["PlayerData_v1/global"]["u_88"]
H.check(table.find(stored.receipts, "RETRY_SAVE") ~= nil, "retry receipt not persisted")
-- game passes: 2x Speed via PromptGamePassPurchaseFinished doubles the applied and allowed speed at once
local Econ = H.svc("EconomyService")
local base = H.humanoid(p).WalkSpeed
H.check(base > 0, "player walking")
H.firePassPurchase(p, 2001, false)
H.run(0.2)
H.check(not Econ.hasPass(p, "doubleSpeed"), "declined purchase granted the pass")
-- Spoofed signal (finding 1): wasPurchased=true but Roblox says not owned -> nothing, through every retry.
local function countOwned()
	local n = 0
	for _ in Data.get(p).owned do n += 1 end
	return n
end
local owned0 = countOwned()
H.clearSent(p)
for _ = 1, 3 do H.firePassPurchase(p, 2001, true) end -- spam starts one check loop
H.firePassPurchase(p, 999999, true) -- unknown id ignored
H.run(Config.PassCheck.Attempts * Config.PassCheck.RetrySeconds + 2)
H.check(not Econ.hasPass(p, "doubleSpeed"), "spoofed purchase granted the pass")
H.eq(H.humanoid(p).WalkSpeed, base, "spoofed purchase changed speed")
H.eq(countOwned(), owned0, "spoofed purchase granted items")
for _, m in H.sent(p, "ProfileUpdate") do
	local sp = m.args[1].session
	H.check(sp == nil or sp.passes == nil or sp.passes.doubleSpeed ~= true, "spoofed purchase in session.passes")
end
-- Ownership already visible: granted on the first check.
H.M.passes[88] = { [2001] = true }
H.firePassPurchase(p, 2001, true)
H.run(0.5)
H.check(Econ.hasPass(p, "doubleSpeed"), "doubleSpeed not owned after purchase")
-- Cached false right after a real purchase: granted on a later attempt; an errored attempt never grants.
H.M.passErrors[2002] = 1
H.firePassPurchase(p, 2002, true)
H.run(Config.PassCheck.RetrySeconds + 1)
H.check(not Econ.hasPass(p, "doubleCoins"), "doubleCoins granted before ownership was confirmed")
H.M.passes[88][2002] = true
H.run(Config.PassCheck.RetrySeconds + 1)
H.check(Econ.hasPass(p, "doubleCoins"), "doubleCoins not granted when ownership turned true")
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
-- Join check (finding 4): two errored UserOwnsGamePassAsync calls, then success -> pass applied by retry.
H.M.passes[90] = { [2001] = true }
H.M.passErrors[2001] = 2
local owner = H.addPlayer({ userId = 90, name = "Owner" })
H.runUntil(function() return Data.get(owner) ~= nil end, 10, "owner loaded")
H.run(1)
H.check(not Econ.hasPass(owner, "doubleSpeed"), "pass applied despite errored check")
H.runUntil(function() return Econ.hasPass(owner, "doubleSpeed") end, Config.PassCheck.RetrySeconds * 3 + 2, "join retry applied the pass")
