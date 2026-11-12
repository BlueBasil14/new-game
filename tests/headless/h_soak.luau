-- (h) soak: 4 random-walking players + bots for SOAK_SECONDS virtual seconds.
local SOAK_SECONDS = 180
H.boot()
H.run(1)
local Config = H.shared("Config")
local Arena = H.svc("ArenaService")
local sim = Arena.sim
local rng = H.S.env.Random.new(4242)
local players = {}
for i = 1, 4 do
	table.insert(players, H.addPlayer({ userId = 9000 + i, name = "Soak" .. i }))
end
H.runUntil(function()
	for _, p in players do
		if Arena.runnerIdOf(p) == 0 then return false end
	end
	return true
end, 10, "runners")
H.run(1.5) -- BotService.maintain trims bots once a second

-- teleport detector: any per-frame HRP jump larger than walking allows
local jumps, lastPos = {}, {}
table.insert(H.S.frameHooks, function(dt)
	for _, p in players do
		local pos = H.pos(p)
		local hum = H.humanoid(p)
		if pos and lastPos[p] and hum then
			local d = (pos - lastPos[p]).Magnitude
			if d > math.max(hum.WalkSpeed, Config.Arena.BaseWalkSpeed) * dt * 1.01 + 1e-3 then
				jumps[p] = (jumps[p] or 0) + 1
			end
		end
		lastPos[p] = pos
	end
end)

local bots = 0
for _, r in sim:runners() do
	if r.info.isBot then bots += 1 end
end
H.say("bots", bots, "runners", #sim:runners())
H.eq(bots, Config.Arena.MinRunners - #players, "bot count")

local half = Config.Arena.GridSize
local respawns, recounts = 0, 0
local frames0, real0 = H.S.heartbeatFrames, H.S.heartbeatReal
local t = 0
while t < SOAK_SECONDS do
	H.run(1)
	t += 1
	for _, p in players do
		local id = Arena.runnerIdOf(p)
		local r = id ~= 0 and sim:runner(id)
		if r and not r.alive then
			H.stopWalking(p)
			local ok, res = H.invoke(p, "Respawn")
			if ok == true then
				respawns += 1
			elseif res ~= "not_dead" and res ~= "busy" then
				error("Respawn failed: " .. tostring(res))
			end
		elseif r and not H.walking(p) then
			local cx, cy = r.x, r.y
			local tx = math.clamp(cx + rng:NextInteger(-12, 12), 1, half - 2)
			local ty = math.clamp(cy + rng:NextInteger(-12, 12), 1, half - 2)
			H.walkCells(p, { { tx, cy }, { tx, ty } })
		end
	end
	if t % 10 == 0 then
		local rc = sim.grid:recount()
		for k = 1, 256 do
			if rc[k] ~= sim.grid.counts[k] then
				error(string.format("grid count mismatch for owner %d: counts=%d recount=%d", k - 1, sim.grid.counts[k], rc[k]))
			end
		end
		recounts += 1
	end
end
local frames = H.S.heartbeatFrames - frames0
local real = H.S.heartbeatReal - real0
local ticks = frames / 60 * Config.Arena.TickRate
H.eq(#H.S.kicks, 0, "kicks")
local jumpText = {}
for _, p in players do
	table.insert(jumpText, tostring(jumps[p] or 0))
end
local kills, deaths = 0, 0
for _, p in players do
	local prof = H.svc("DataService").get(p)
	kills += prof.stats.kills
	deaths += prof.stats.deaths
end
H.say(string.format("%ds virtual: heartbeat avg %.3f ms/frame, %.3f ms per 20 Hz tick (incl. bots, replication); respawns=%d player kills=%d deaths=%d recounts=%d teleports per player=%s",
	SOAK_SECONDS, real / frames * 1000, real / ticks * 1000, respawns, kills, deaths, recounts, table.concat(jumpText, ",")))
for _, p in players do
	-- each death hides (1 jump) and each respawn places (1 jump) + the initial placement
	local prof = H.svc("DataService").get(p)
	local allowed = 2 * prof.stats.deaths + 4
	H.check((jumps[p] or 0) <= allowed, "%s teleported %d times (allowed %d): anti-cheat snap-backs against an honest walker?", p.Name, jumps[p] or 0, allowed)
end
