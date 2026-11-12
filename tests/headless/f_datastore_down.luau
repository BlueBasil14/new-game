-- (f) every DataStore request errors: Studio falls back to the in-memory store; play works.
H.M.dsDown = "requests"
H.boot()
H.run(1)
H.allow = { allowWarn = { "LeaderboardService: DataStore error", "DataStores unavailable in Studio", "DataStore call failed after retries" } }
local Arena = H.svc("ArenaService")
local Data = H.svc("DataService")
local p = H.addPlayer({ userId = 31, name = "Offline" })
H.runUntil(function() return Arena.runnerIdOf(p) ~= 0 or #H.S.kicks > 0 end, 30, "join")
H.eq(#H.S.kicks, 0, "kicked")
H.check(Data.get(p) ~= nil, "no profile")
local ok, res = H.invoke(p, "ClaimDaily")
H.eq(ok, true, "ClaimDaily on mock store")
H.run(150) -- leaderboard refresh, autosave
H.check(Data.get(p).coins > 0, "no coins")
H.removePlayer(p)
H.run(2)
H.assertClean(H.allow)
