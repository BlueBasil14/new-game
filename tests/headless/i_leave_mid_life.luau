-- (i) a player with turf and a trail leaves; turf goes neutral after LeaveNeutralDelay.
H.boot()
H.run(1)
local Config = H.shared("Config")
local Arena = H.svc("ArenaService")
local sim = Arena.sim
local A = H.addPlayer({ userId = 61, name = "Leaver" })
local W = H.addPlayer({ userId = 62, name = "Watcher" })
H.runUntil(function() return Arena.runnerIdOf(A) ~= 0 and Arena.runnerIdOf(W) ~= 0 end, 10, "runners")
local id = Arena.runnerIdOf(A)
local r = sim:runner(id)
local x0, y0 = r.x, r.y
H.walkCells(A, { { x0 + (if x0 < 80 then 6 else -6), y0 } })
H.runUntil(function() return not H.walking(A) end, 10, "trail")
H.check(#r.trail > 0 and sim:cellsOf(id) > 0, "no turf/trail")
H.removePlayer(A)
H.run(1)
H.check(sim:runner(id) ~= nil, "runner removed before LeaveNeutralDelay")
H.run(Config.Arena.LeaveNeutralDelay)
H.check(sim:runner(id) == nil or sim:runner(id).info.userId ~= 61, "runner still present")
H.eq(sim.grid:count(id) == 0 or (sim:runner(id) ~= nil), true, "turf not neutral")
local despawn = false
for _, e in H.sent(W, "ArenaEvent") do
	if e.args[1].kind == "despawn" and e.args[1].id == id then despawn = true end
end
H.check(despawn, "no despawn broadcast")
H.run(10)
H.eq(#H.S.kicks, 0, "kicks")
