--!strict
local BotBrain = require(script.Parent.BotBrain)
local ArenaSim = require(script.Parent.ArenaSim)
local Config = require(script.Parent.Config)

local function lcg(seed: number): () -> number
	local s = seed
	return function()
		s = (s * 16807) % 2147483647
		return s / 2147483647
	end
end

local function info(id: number): any
	return { id = id, userId = 0, name = "b" .. id, colorIndex = 1, skin = "", trail = "", effect = "", isBot = true }
end

-- seconds a bot needs per cell at base speed
local CELL_TIME = Config.Arena.CellSize / Config.Arena.BaseWalkSpeed

local function addBot(sim: ArenaSim.ArenaSim, now: number): number
	local id = sim:addRunner(info(0), Config.Arena.StartPatch, 0, now)
	sim:drainEvents()
	return id
end

-- brute-force distance to the nearest own cell (test oracle)
local function homeDist(sim: ArenaSim.ArenaSim, id: number, x: number, y: number): number
	local best = math.huge
	local g = sim.grid
	for i = 0, g.total - 1 do
		if g:getIndex(i) == id then
			local cx, cy = g:fromIndex(i)
			best = math.min(best, math.abs(cx - x) + math.abs(cy - y))
		end
	end
	return best
end

-- Drives all bots one cell per brain step; respawns the dead. Returns claims, cuts.
local function drive(sim: ArenaSim.ArenaSim, brains: { [number]: any }, ids: { number }, steps: number, now0: number)
	local claims, cuts = 0, 0
	local now = now0
	for _ = 1, steps do
		now += CELL_TIME
		local pos = {}
		for _, id in ids do
			local r = assert(sim:runner(id))
			if not r.alive then
				sim:respawn(id, Config.Arena.StartPatch, 0, now)
				BotBrain.reset(brains[id])
				r = assert(sim:runner(id))
			end
			local dx, dy = BotBrain.step(brains[id], sim, id, now)
			assert(math.abs(dx) + math.abs(dy) <= 1, "unit step")
			assert(sim.grid:inBounds(r.x + dx, r.y + dy), "step stays in grid")
			pos[id] = { x = r.x + dx, y = r.y + dy }
		end
		sim:step(now, pos)
		for _, e in sim:drainEvents() do
			if e.kind == "claim" then
				claims += 1
			elseif e.kind == "cut" then
				cuts += 1
			end
		end
		sim:drainCellChanges()
		sim:drainTrailDeltas()
		-- bots are never left pending: release victims straight away
		for _, id in ids do
			local r = assert(sim:runner(id))
			if r.pending then
				sim:releaseVictim(id)
			end
		end
	end
	return claims, cuts, now
end

-- 1. lone bot gains turf
do
	local sim = ArenaSim.new({ size = 60, rng = lcg(7) })
	local id = addBot(sim, 0)
	local start = sim:cellsOf(id)
	local brains = { [id] = BotBrain.new(Config.Bots.Tiers[2], lcg(11)) }
	local claims = drive(sim, brains, { id }, 400, 0)
	assert(sim:cellsOf(id) > start, "lone bot grew")
	assert(claims >= 2, "at least two claims, got " .. claims)
end

-- 2. never leaves the grid (drive asserts every step), 3 tiers, 3000 steps, small grid
do
	local sim = ArenaSim.new({ size = 40, rng = lcg(3) })
	local ids, brains = {}, {}
	for t = 1, 3 do
		local id = addBot(sim, 0)
		table.insert(ids, id)
		brains[id] = BotBrain.new(Config.Bots.Tiers[t], lcg(100 + t))
	end
	drive(sim, brains, ids, 3000, 0)
end

-- 3. returns home when threatened
local function threatTest(tierIdx: number)
	local tier = Config.Bots.Tiers[tierIdx]
	local sim = ArenaSim.new({ size = 60, rng = lcg(5) })
	local id = addBot(sim, 0)
	local other = addBot(sim, 0)
	local brain = BotBrain.new(tier, lcg(21))
	local now = 0
	local r = assert(sim:runner(id))
	local o = assert(sim:runner(other))
	-- walk until the bot is mid-loop with a few trail cells
	local guard = 0
	while #r.trail < 3 do
		guard += 1
		assert(guard < 200, "bot never left turf")
		now += CELL_TIME
		local dx, dy = BotBrain.step(brain, sim, id, now)
		sim:step(now, { [id] = { x = r.x + dx, y = r.y + dy } })
	end
	-- hold the other runner right next to the trail's last cell
	local last = r.trail[#r.trail]
	local lx, ly = sim.grid:fromIndex(last)
	local ox, oy = lx, ly
	for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
		local nx, ny = lx + d[1], ly + d[2]
		if sim.grid:inBounds(nx, ny) and sim.grid:get(nx, ny) == 0 and sim:trailOwnerAt(nx, ny) == 0 then
			ox, oy = nx, ny
			break
		end
	end
	o.x, o.y = ox, oy
	local tStart = now
	local reactSteps = math.ceil(tier.Reaction / CELL_TIME) + 3
	local returned = false
	for n = 1, 60 do
		now += CELL_TIME
		local before = homeDist(sim, id, r.x, r.y)
		local dx, dy = BotBrain.step(brain, sim, id, now)
		sim:step(now, { [id] = { x = r.x + dx, y = r.y + dy }, [other] = { x = ox, y = oy } })
		if #r.trail == 0 then
			returned = true
			break
		end
		if now - tStart > tier.Reaction + 3 * CELL_TIME and n > reactSteps then
			local after = homeDist(sim, id, r.x, r.y)
			assert(after < before, "returning step must reduce distance home")
		end
	end
	assert(returned, "bot got home while threatened")
	assert(r.alive, "bot survived")
end
threatTest(3)
threatTest(2)

-- 4. dead bot returns (0, 0)
do
	local sim = ArenaSim.new({ size = 40, rng = lcg(9) })
	local id = addBot(sim, 0)
	local brain = BotBrain.new(Config.Bots.Tiers[1], lcg(2))
	local r = assert(sim:runner(id))
	r.alive = false
	local dx, dy = BotBrain.step(brain, sim, id, 1)
	assert(dx == 0 and dy == 0, "dead bot idles")
	r.alive = true
	r.pending = true
	dx, dy = BotBrain.step(brain, sim, id, 1)
	assert(dx == 0 and dy == 0, "pending bot idles")
end

-- 5. 16 bots on the default grid
local ms: number
do
	local sim = ArenaSim.new({ rng = lcg(13) })
	local ids, brains = {}, {}
	for k = 1, Config.Arena.MaxPlayers do
		local id = addBot(sim, 0)
		table.insert(ids, id)
		brains[id] = BotBrain.new(Config.Bots.Tiers[(k - 1) % #Config.Bots.Tiers + 1], lcg(1000 + k))
	end
	local initial = 0
	for _, id in ids do
		initial += sim:cellsOf(id)
	end
	local t0 = os.clock()
	local claims, cuts = drive(sim, brains, ids, 2000, 0)
	ms = (os.clock() - t0) * 1000
	local total = 0
	for _, id in ids do
		total += sim:cellsOf(id)
	end
	print(string.format("botbrain 16 bots x 2000 steps: %.0f ms, %d claims, %d cuts", ms, claims, cuts))
	assert(total > initial, "total claimed cells grew")
end

return string.format("botbrain ok (16 bots x 2000 steps %.0f ms)", ms)
