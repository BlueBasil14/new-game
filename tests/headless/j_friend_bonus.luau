-- (j) two Roblox friends in one server both get Config.Income.FriendBonus; it ends when one leaves.
H.boot()
H.run(1)
local Config = H.shared("Config")
local Econ = H.svc("EconomyService")
H.M.friends[71] = { [72] = true } -- one direction only: IsFriendsWith must be symmetric
local A = H.addPlayer({ userId = 71, name = "FriendA" })
local B = H.addPlayer({ userId = 72, name = "FriendB" })
local C = H.addPlayer({ userId = 73, name = "Stranger" })
H.runUntil(function()
	return Econ.hasFriendHere(A) and Econ.hasFriendHere(B) and H.last(C, "ProfileUpdate") ~= nil
end, 10, "friend link")
H.check(not Econ.hasFriendHere(C), "stranger got the friend bonus")
H.run(1) -- ProfileUpdate throttle
local base = Econ.multiplier(C)
H.check(math.abs(Econ.multiplier(A) - base * (1 + Config.Income.FriendBonus)) < 1e-9, "A multiplier")
H.check(math.abs(Econ.multiplier(B) - base * (1 + Config.Income.FriendBonus)) < 1e-9, "B multiplier")
H.eq(H.last(A, "ProfileUpdate").args[1].session.withFriend, true, "A session withFriend")
H.eq(H.last(C, "ProfileUpdate").args[1].session.withFriend, false, "C session withFriend")
H.removePlayer(B)
H.run(1)
H.check(not Econ.hasFriendHere(A), "A kept bonus after friend left")
H.check(math.abs(Econ.multiplier(A) - base) < 1e-9, "A multiplier after leave")
local s = H.last(A, "ProfileUpdate").args[1].session
H.eq(s.withFriend, false, "A session after leave")
H.check(math.abs(s.multiplier - base) < 1e-9, "A pushed multiplier after leave")
