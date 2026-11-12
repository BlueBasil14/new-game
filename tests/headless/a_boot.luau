-- (a) boot: Main.server runs to steady state with zero players; bots fill and claim turf.
H.boot()
H.run(1)
local Remotes = H.shared("Remotes")
local Config = H.shared("Config")
local rs = H.S.services.ReplicatedStorage
local folder = rs:FindFirstChild(Remotes.Folder)
H.check(folder ~= nil, "Remotes folder missing")
for key, value in Remotes do
	if type(value) == "string" and key ~= "Folder" then
		H.check(folder:FindFirstChild(value) ~= nil, "remote %s missing", value)
	end
end
H.check(H.S.workspace:FindFirstChild("World") ~= nil, "world not built")
H.check(H.S.workspace:FindFirstChild("Bots") ~= nil, "Bots folder missing")
local Arena = H.svc("ArenaService")
local sim = Arena.sim
H.runUntil(function()
	return #sim:runners() >= Config.Arena.MinRunners
end, 5, "bots fill to MinRunners")
local function owned()
	local n = 0
	for _, r in sim:runners() do
		n += sim:cellsOf(r.id)
	end
	return n
end
local start = owned()
H.run(120)
local after = owned()
H.say(string.format("runners=%d owned cells %d -> %d, instances=%d", #sim:runners(), start, after, H.S.instanceCount))
H.check(after > start, "bots claimed no turf (%d -> %d)", start, after)
H.check(#sim:runners() == Config.Arena.MinRunners, "runner count %d", #sim:runners())
H.assertClean()
