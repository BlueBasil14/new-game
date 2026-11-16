-- (p) playtime rewards and the bots' gentle window survive a rejoin (BALANCE.md item 5):
-- rewards are once per day from the profile, and gentle time counts lifetime play.
H.boot()
H.run(1)
local Arena = H.svc("ArenaService")
local Data = H.svc("DataService")
local p = H.addPlayer({ userId = 6262, name = "Idler" })
H.runUntil(function() return Arena.runnerIdOf(p) ~= 0 end, 10, "runner")
H.check(table.find(Arena.gentleRunnerIds(Arena.now()), Arena.runnerIdOf(p)) ~= nil, "new player not gentle")

local function claim(pl, i)
	H.run(0.2)
	return H.invoke(pl, "ClaimPlaytime", i)
end
H.run(125)
local ok, res = claim(p, 1)
H.check(ok == true, "claim 1 after 125 s: %s", tostring(res))
ok, res = claim(p, 1)
H.check(ok == false and res == "already_claimed", "claim 1 twice: %s", tostring(res))
ok, res = claim(p, 2)
H.check(ok == false and res == "too_early", "claim 2 early: %s", tostring(res))
local played = Data.get(p).playtime.seconds
H.check(played >= 60, "playtime not banked: %s", tostring(played))

H.removePlayer(p)
H.run(3)
local p2 = H.addPlayer({ userId = 6262, name = "Idler" })
H.runUntil(function() return Arena.runnerIdOf(p2) ~= 0 end, 40, "runner after rejoin")
ok, res = claim(p2, 1)
H.check(ok == false and res == "already_claimed", "claim 1 again after rejoin: %s", tostring(res))
H.check(table.find(Arena.gentleRunnerIds(Arena.now()), Arena.runnerIdOf(p2)) == nil, "gentle window restarted on rejoin")
H.run(300 - played)
ok, res = claim(p2, 2)
H.check(ok == true, "claim 2 after a total of 300 s across sessions: %s", tostring(res))
