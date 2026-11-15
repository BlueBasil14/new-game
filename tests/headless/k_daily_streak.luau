-- (k) daily run counter and one-time streak milestones (T-RET-02). Days are advanced by moving H.M.TIME0.
H.boot()
H.run(1)
local Catalog = H.shared("Catalog")
local Formulas = H.shared("Formulas")
local Arena = H.svc("ArenaService")
local Data = H.svc("DataService")
local p = H.addPlayer({ userId = 881, name = "Streaker" })
H.runUntil(function() return Arena.runnerIdOf(p) ~= 0 end, 10, "runner")

local DAY = 86400
local function nextDay(n)
	H.M.TIME0 += DAY * (n or 1)
	H.run(1.2)
end
local function claim()
	H.run(0.2)
	local ok, res = H.invoke(p, "ClaimDaily")
	H.check(ok == true, "ClaimDaily failed: %s", tostring(res))
	return res
end
local function today() return Formulas.dayNumber(H.M.TIME0 + H.M.clock) end -- server virtual clock
local function setRun(run) -- pretend `run` days were claimed through yesterday
	Data.update(p, function(pr) pr.daily.run = run; pr.daily.lastClaimDay = today() - 1 end)
end
local m14, m28 = Catalog.dailyMilestones[1], Catalog.dailyMilestones[3]

local r = claim()
H.eq(r.run, 1, "first run")
H.eq(r.milestone, nil, "no milestone day 1")
nextDay()
H.eq(claim().run, 2, "run 2")
nextDay(2)
H.eq(claim().run, 1, "missed day resets run")

nextDay()
setRun(m14.day - 1)
local gems = Data.get(p).gems
r = claim()
H.eq(r.run, m14.day, "run hits 14")
H.check(r.milestone ~= nil and r.milestone.day == m14.day and r.milestone.amount == m14.amount, "milestone 14 granted")
H.eq(Data.get(p).gems - gems, m14.amount + (if r.currency == "gems" then r.amount else 0), "milestone gems credited")
H.eq(Data.get(p).daily.milestones[tostring(m14.day)], true, "milestone recorded")

nextDay()
H.eq(claim().milestone, nil, "day 15 no milestone")
nextDay()
setRun(m14.day - 1)
r = claim()
H.eq(r.run, m14.day, "rebuilt run 14")
H.eq(r.milestone, nil, "milestone 14 only once")

nextDay()
setRun(m28.day - 1)
r = claim()
H.check(r.milestone ~= nil and r.milestone.day == m28.day and r.milestone.skin == m28.skin, "milestone 28 with skin")
H.eq(Data.get(p).owned[m28.skin], true, "streak_month owned")
H.eq(Data.get(p).daily.milestones["21"], nil, "skipped 21 not recorded")
H.say("daily run ok; run", Data.get(p).daily.run)
