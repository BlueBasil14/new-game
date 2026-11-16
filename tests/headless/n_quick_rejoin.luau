-- (n) leave and rejoin the same server while the old session's release write is still in flight
-- (security review findings 2 and 3). The release write is made slow so the new load would
-- otherwise read the store before it lands.
H.boot({ jobId = "job-A" })
H.run(1)
local Arena = H.svc("ArenaService")
local Econ = H.svc("EconomyService")
local Data = H.svc("DataService")
local p = H.addPlayer({ userId = 5151, name = "Bouncer" })
H.runUntil(function() return Arena.runnerIdOf(p) ~= 0 end, 10, "runner")
H.run(0.5)
Econ.addCoins(p, 1234, "test", false)
local finalCoins = Data.get(p).coins

-- Finding 3: a save cancelled by the release must not report success.
local saveResult = nil
H.S.spawn(function() saveResult = Data.save(p) end)
H.removePlayer(p) -- release waits for that save, then writes with the slow latency below
H.M.dsLatency = 2
H.run(0.2)
H.eq(saveResult, false, "save cancelled by release reported success")
H.M.dsLatency = 0.05

-- Finding 2: rejoin while the release write is still in flight.
local p2 = H.addPlayer({ userId = 5151, name = "Bouncer" })
H.runUntil(function() return Data.get(p2) ~= nil or #H.S.kicks > 0 end, 30, "rejoin loaded")
H.eq(#H.S.kicks, 0, "kicked on quick rejoin")
H.eq(Data.get(p2).coins, finalCoins, "rejoin loaded stale data")
Econ.addCoins(p2, 1, "test", false)
local ok = H.call(Data.save, p2)
H.eq(ok, true, "save after quick rejoin failed")
H.eq(#H.S.kicks, 0, "kicked after quick rejoin save")
local stored = H.M.dsBacking.stores["PlayerData_v1/global"]["u_5151"]
H.eq(stored.coins, finalCoins + 1, "stored coins after rejoin save")
H.eq(stored._lock and stored._lock.jobId, "job-A", "lock owner after rejoin")
