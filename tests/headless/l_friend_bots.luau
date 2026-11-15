-- (l) bots wear joining players' friends' avatars (DisplayName as runner name), fallback avatars
-- otherwise; a joining player removes the bot wearing them, and its turf goes neutral.
H.M.friends[81] = { [901] = true, [902] = true }
H.boot()
H.run(1)
local Config = H.shared("Config")
local Arena = H.svc("ArenaService")
local sim = Arena.sim
local A = H.addPlayer({ userId = 81, name = "Host" })
local function botNamed(name: string): any
	for _, r in sim:runners() do
		if r.info.isBot and r.info.name == name then
			return r
		end
	end
	return nil
end
-- Bots spawned before A joined wear fallbacks; let one be recycled by having B join and leave.
local B = H.addPlayer({ userId = 82, name = "Other" })
H.run(3)
H.removePlayer(B)
H.runUntil(function()
	return botNamed("Friend901") ~= nil or botNamed("Friend902") ~= nil
end, 10, "a friend bot spawns")
H.run(2) -- avatar build
local bots = H.S.workspace:FindFirstChild("Bots")
local withHum = 0
for _, rig in bots:GetChildren() do
	local hum = rig:FindFirstChildOfClass("Humanoid")
	if hum ~= nil then
		withHum += 1
		H.check(rig:FindFirstChildWhichIsA("LuaSourceContainer", true) == nil, "script left in avatar rig")
		H.check(rig.PrimaryPart:GetNetworkOwner() == nil, "rig not server-owned")
		local r = sim:runner(tonumber(rig.Name))
		H.eq(hum.DisplayName, r.info.name, "humanoid DisplayName")
		H.eq(r.info.userId, 0, "bot userId")
	end
end
H.check(withHum >= Config.Arena.MinRunners - 2, "only %d avatar rigs", withHum)
-- The friend joins: the bot wearing them is removed first and its cells are neutral.
local worn = botNamed("Friend901") or botNamed("Friend902")
local uid = if worn.info.name == "Friend901" then 901 else 902
H.addPlayer({ userId = uid, name = "RealFriend" })
H.runUntil(function()
	return sim:runner(worn.id) == nil or sim:runner(worn.id).info ~= worn.info
end, 5, "worn bot removed")
H.check(sim:runner(worn.id) ~= nil or sim:cellsOf(worn.id) == 0, "removed bot kept turf")
H.run(2)
H.eq(#sim:runners(), Config.Arena.MinRunners, "runner count")
H.removePlayer(A)
H.run(Config.Arena.LeaveNeutralDelay + 3) -- the leaver's runner lingers this long
H.eq(#sim:runners(), Config.Arena.MinRunners, "runner count after leave")
H.assertClean()
