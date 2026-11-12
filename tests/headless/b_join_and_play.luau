-- (b) one player joins, gets profile + snapshot, walks a loop out of their patch and back.
H.boot()
H.run(2)
local Config = H.shared("Config")
local Catalog = H.shared("Catalog")
local Formulas = H.shared("Formulas")
local Grid = H.shared("Grid")
local Arena = H.svc("ArenaService")
local Econ = H.svc("EconomyService")
local sim = Arena.sim

-- a user id whose quests today include a claim-driven kind
local day = Formulas.dayNumber(H.S.env.os.time())
local uid = 1000
while true do
	local hit = false
	for _, q in Catalog.questsForDay(day, uid) do
		if q.kind == "cells" or q.kind == "bigCapture" or q.kind == "mapPct" then hit = true end
	end
	if hit then break end
	uid += 1
end
local grants = {}
Econ.granted:Connect(function(player, currency, amount, reason)
	table.insert(grants, { currency = currency, amount = amount, reason = reason, t = H.M.clock })
end)

local p = H.addPlayer({ userId = uid, name = "Walker" })
H.runUntil(function() return Arena.runnerIdOf(p) ~= 0 and H.last(p, "ArenaSnapshot") ~= nil end, 10, "runner + snapshot")
local id = Arena.runnerIdOf(p)
local prof = H.last(p, "ProfileUpdate")
H.check(prof ~= nil, "no ProfileUpdate")
H.check(type(prof.args[1].profile) == "table" and type(prof.args[1].session) == "table", "ProfileUpdate shape")
H.check(prof.args[1].profile.receipts == nil, "receipts not stripped")
local snap = H.last(p, "ArenaSnapshot")
H.eq(snap.args[3], id, "snapshot yourRunnerId")
local g = Grid.decodeRLE(snap.args[1])
H.run(0.6) -- let the teleport settle
local cx, cy = H.cellOf(p)
local r = sim:runner(id)
H.eq(g:get(cx, cy), id, "snapshot owner at HRP cell")
H.check(math.abs(cx - r.x) <= 1 and math.abs(cy - r.y) <= 1, "HRP cell %d,%d vs runner %d,%d", cx, cy, r.x, r.y)
H.check(not H.anchored(p), "HRP anchored after spawn")
H.say("spawned runner", id, "at", r.x, r.y)

-- rectangle out of the patch and back, heading toward the map centre
local half = Config.Arena.GridSize / 2
local sx = if r.x < half then 1 else -1
local sy = if r.y < half then 1 else -1
local x0, y0 = r.x, r.y
H.clearSent(p)
local profBefore = prof.args[1].profile
local questBefore = {}
for i, q in profBefore.quests.list do questBefore[i] = q.progress end
H.walkCells(p, { { x0 + 5 * sx, y0 }, { x0 + 5 * sx, y0 + 4 * sy }, { x0, y0 + 4 * sy }, { x0, y0 } })
local claim
H.runUntil(function()
	for _, e in H.sent(p, "ArenaEvent") do
		local ev = e.args[1]
		if ev.kind == "claim" and ev.id == id then claim = ev return true end
	end
	return false
end, 20, "claim event")
H.run(1)
local mult = Econ.multiplier(p)
local expected = math.floor(Formulas.captureCoins(claim.neutral, claim.stolen) * mult + 0.5)
local reward
for _, e in H.sent(p, "Reward") do
	if e.args[1].reason == "capture" then reward = e.args[1] end
end
H.check(reward ~= nil, "no capture Reward")
H.eq(reward.coins, expected, "Reward coins = captureCoins x multiplier")
local after = H.last(p, "ProfileUpdate").args[1].profile
local granted = 0
for _, gr in grants do
	if gr.currency == "coins" then granted += gr.amount end
end
H.eq(after.coins - profBefore.coins, granted, "profile coins delta = granted coins")
H.check(after.coins - profBefore.coins >= expected, "coins grew by at least the capture")
local moved = false
for i, q in after.quests.list do
	if q.progress > (questBefore[i] or 0) then moved = true end
end
H.check(moved, "no quest progress")
H.eq(after.stats.captures, 1, "stats.captures")
H.say(string.format("claim cells=%d neutral=%d stolen=%d coins=%d mult=%.2f", claim.cells, claim.neutral, claim.stolen, reward.coins, mult))
H.eq(#H.S.kicks, 0, "kicks")
