-- (c) player B walks across player A's trail: cut, Death payload, respawn flow.
H.boot()
H.run(2)
local Config = H.shared("Config")
local Grid = H.shared("Grid")
local Arena = H.svc("ArenaService")
local sim = Arena.sim

local A = H.addPlayer({ userId = 501, name = "Alice" })
local B = H.addPlayer({ userId = 502, name = "Bob" })
H.runUntil(function()
	return Arena.runnerIdOf(A) ~= 0 and Arena.runnerIdOf(B) ~= 0
end, 10, "both runners")
local ida, idb = Arena.runnerIdOf(A), Arena.runnerIdOf(B)
H.run(Config.Arena.SpawnShield + 0.5) -- shields expire
local ra = sim:runner(ida)
local half = Config.Arena.GridSize / 2
local sx = if ra.x < half then 1 else -1
local ax, ay = ra.x, ra.y -- ra is live; copy the spawn cell
local trailEnd = { ax + 7 * sx, ay }
H.walkCells(A, { trailEnd })
H.runUntil(function() return not H.walking(A) end, 10, "A lays a trail")
H.check(#sim:runner(ida).trail >= 4, "A has no trail (%d)", #sim:runner(ida).trail)
local target = { ax + 5 * sx, ay } -- a trail cell
local rb = sim:runner(idb)
H.say("A", ida, "at", ra.x, ra.y, "B", idb, "at", rb.x, rb.y, "target", target[1], target[2])
-- B approaches perpendicular to the trail: first along x to the target column (offset row), then along y
local offRow = target[2] + (if rb.y < target[2] then -3 else 3)
H.walkCells(B, { { rb.x, offRow }, { target[1], offRow }, target })
local cut, cutAt
H.runUntil(function()
	for _, e in H.sent(A, "ArenaEvent") do
		local ev = e.args[1]
		if ev.kind == "cut" and ev.victim == ida then cut = ev cutAt = e.t return true end
	end
	return false
end, 60, "cut event")
H.eq(cut.killer, idb, "killer")
H.run(0.2)
local death = H.last(A, "Death")
H.check(death ~= nil, "no Death remote")
local payload = death.args[1]
local keys = {}
for k in payload do table.insert(keys, k) end
table.sort(keys)
H.eq(table.concat(keys, ","), "canSecondChance,cells,coins,killerName,kills,lifeSeconds", "Death payload keys")
H.eq(payload.killerName, "Bob", "killerName")
H.eq(payload.canSecondChance, false, "canSecondChance (product id 0)")
H.eq(payload.cells, cut.victimCells, "cells")
H.check(type(payload.lifeSeconds) == "number" and type(payload.kills) == "number" and type(payload.coins) == "number", "payload types")
local killReward
for _, e in H.sent(B, "Reward") do
	if e.args[1].reason == "kill" then killReward = e.args[1] end
end
H.check(killReward ~= nil and killReward.coins > 0, "killer got no kill coins")
local Formulas = H.shared("Formulas")
H.eq(killReward.coins, math.floor(Formulas.killCoins(cut.victimCells, cut.victimWasKing) * H.svc("EconomyService").multiplier(B) + 0.5), "kill coins")

-- victim is frozen
local deathClock = cutAt
H.check(H.anchored(A), "victim HRP not anchored")
H.eq(H.humanoid(A).WalkSpeed, 0, "victim WalkSpeed")
local p0 = H.pos(A)
H.walkCells(A, { { ax, ay } })
H.run(1)
H.check((H.pos(A) - p0).Magnitude < 1e-6, "victim moved while dead")
H.stopWalking(A)
H.clearSent(A)
local ok, res = H.invoke(A, "Respawn")
local waited = H.M.clock - deathClock
H.eq(ok, true, "Respawn ok (" .. tostring(res) .. ")")
H.eq(res, ida, "Respawn returns runner id")
H.check(waited >= Config.Arena.RespawnDelay - 0.05, "respawned too early (%.2fs)", waited)
H.run(0.6)
local spawnEv
for _, e in H.sent(A, "ArenaEvent") do
	local ev = e.args[1]
	if ev.kind == "spawn" and ev.runner.id == ida then spawnEv = ev end
end
H.check(spawnEv ~= nil, "no spawn event after respawn")
local cx, cy = H.cellOf(A)
local nr = sim:runner(ida)
H.check(nr.alive, "runner not alive")
H.eq(sim.grid:get(cx, cy), ida, "HRP on new patch")
H.check(not H.anchored(A), "HRP still anchored")
H.check(H.humanoid(A).WalkSpeed > 0, "WalkSpeed still 0")
H.eq(H.networkOwner(H.hrp(A)), A, "network owner back to player")
H.say(string.format("death->respawn %.2fs, new patch %d,%d, kill coins %d", waited, nr.x, nr.y, killReward.coins))
-- can move again
local p1 = H.pos(A)
H.walkCells(A, { { nr.x + 1, nr.y } })
H.run(1)
H.check((H.pos(A) - p1).Magnitude > 1, "cannot move after respawn")
H.eq(#H.S.kicks, 0, "kicks")
