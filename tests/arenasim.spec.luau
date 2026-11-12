--!strict
local ArenaSim = require(script.Parent.ArenaSim)
local Grid = require(script.Parent.Grid)
local Config = require(script.Parent.Config)

local function info(id: number): any
	return { id = id, userId = 0, name = "r" .. id, colorIndex = 1, skin = "", trail = "", effect = "", isBot = true }
end

local function zero(): number
	return 0
end

local function newSim(size: number?): ArenaSim.ArenaSim
	return ArenaSim.new({ size = size or 40, rng = zero })
end

-- Moves a runner's turf to a p x p patch centred on (cx, cy) and stands it there.
local function place(sim: ArenaSim.ArenaSim, id: number, cx: number, cy: number, p: number)
	local g = sim.grid
	for i = 0, g.total - 1 do
		if g:getIndex(i) == id then
			g:setIndex(i, 0)
		end
	end
	local h = (p - 1) // 2
	for y = cy - h, cy - h + p - 1 do
		for x = cx - h, cx - h + p - 1 do
			g:set(x, y, id)
		end
	end
	local r = assert(sim:runner(id))
	r.x, r.y = cx, cy
end

local function add(sim: ArenaSim.ArenaSim, cx: number, cy: number, p: number, shield: number?, now: number?): number
	local id = sim:addRunner(info(0), p, shield or 0, now or 0)
	place(sim, id, cx, cy, p)
	sim:drainEvents()
	sim:drainCellChanges()
	sim:drainTrailDeltas()
	return id
end

local function mv(sim: ArenaSim.ArenaSim, now: number, moves: { [number]: { number } })
	local pos = {}
	for id, p in moves do
		pos[id] = { x = p[1], y = p[2] }
	end
	sim:step(now, pos)
end

local function kinds(events: { any }): string
	local out = {}
	for _, e in events do
		table.insert(out, e.kind)
	end
	return table.concat(out, ",")
end

-- Grid: default arena size comes from Config
do
	local sim = ArenaSim.new()
	assert(sim.size == Config.Arena.GridSize and sim.grid:count(0) == sim.total)
end

-- Server size / ids: lowest free id 1..255
do
	local sim = newSim(80)
	for k = 1, 16 do
		assert(sim:addRunner(info(0), 3, 0, 0) == k)
	end
	sim:removeRunner(3, 0)
	sim:removeRunner(7, 0)
	assert(sim:allocateId() == 3)
	assert(sim:addRunner(info(0), 3, 0, 0) == 3 and sim:addRunner(info(0), 3, 0, 0) == 7)
	assert(sim:addRunner(info(40), 3, 0, 0) == 40, "explicit id kept")
	assert(#sim:runners() == 17)
end

-- Tick: one tick walks every crossed cell (4-connected, no gaps)
do
	local sim = newSim()
	local a = add(sim, 5, 5, 3)
	local own = 0
	for _, i in sim.grid:line(5, 5, 15, 12) do
		if sim.grid:getIndex(i) == a then
			own += 1
		end
	end
	mv(sim, 0.05, { [a] = { 15, 12 } })
	local r = assert(sim:runner(a))
	assert(r.x == 15 and r.y == 12)
	local trail = r.trail
	assert(own > 0 and #trail == 10 + 7 - own, "trail excludes own-turf cells crossed, got " .. #trail)
	for k = 2, #trail do
		local x0, y0 = sim.grid:fromIndex(trail[k - 1])
		local x1, y1 = sim.grid:fromIndex(trail[k])
		assert(math.abs(x1 - x0) + math.abs(y1 - y0) == 1, "gap in trail")
	end
end

-- Spawn: patch size, farthest spot, spawn event, shield blocks cutting both ways
do
	local sim = newSim(60)
	local a = sim:addRunner(info(0), 5, 0, 0)
	assert(sim:cellsOf(a) == 25)
	local ev = sim:drainEvents()
	assert(ev[1].kind == "spawn" and (ev[1] :: any).runner.id == a)
	local ra = assert(sim:runner(a))
	local b = sim:addRunner(info(0), 5, 3, 10)
	local rb = assert(sim:runner(b))
	local d2 = (ra.x - rb.x) ^ 2 + (ra.y - rb.y) ^ 2
	assert(d2 >= 40 * 40, "second spawn far from the first: " .. d2)
	local spawnEv = sim:drainEvents()[1] :: any
	assert(spawnEv.kind == "spawn" and spawnEv.shieldUntil == 13)

	-- shielded runner can neither be cut nor cut
	local s2 = newSim()
	local s = add(s2, 5, 5, 3, 3, 0) -- shield until 3
	local e = add(s2, 30, 5, 3, 0, 0)
	mv(s2, 0.1, { [s] = { 5, 15 }, [e] = { 30, 15 } }) -- both grow vertical trails
	mv(s2, 0.2, { [e] = { 5, 12 } }) -- e crosses s's trail at (5,12) and others
	assert(s2:isAlive(s), "shielded runner cut")
	mv(s2, 0.3, { [s] = { 30, 11 } }) -- shielded s crosses e's trail
	assert(s2:isAlive(e), "shielded runner cut someone")
	assert(#s2:trailOwnersAt(s2.grid:index(5, 12)) == 2, "overlapping trails tracked")
	mv(s2, 4, { [e] = { 5, 14 } }) -- shield expired: e enters s's trail again
	assert(not s2:isAlive(s) and s2:isAlive(e), "cut after shield expiry")
end

-- Trail: non-own cells join the trail in order; own turf never does; deltas mirror it
do
	local sim = newSim()
	local a = add(sim, 10, 10, 3)
	mv(sim, 0.05, { [a] = { 11, 10 } })
	assert(#assert(sim:runner(a)).trail == 0, "own turf is not trail")
	mv(sim, 0.1, { [a] = { 14, 10 } })
	local t = assert(sim:runner(a)).trail
	assert(#t == 3 and t[1] == sim.grid:index(12, 10) and t[3] == sim.grid:index(14, 10))
	assert(sim:trailOwnerAt(13, 10) == a and sim:trailOwnerAt(11, 10) == 0)
	local d = sim:drainTrailDeltas()
	assert(#d == 1 and d[1].id == a and not d[1].clear and #d[1].append == 3)
	assert(#sim:drainCellChanges() == 0, "trail is not a cell change")
end

-- Claim: re-entering own turf converts trail and enclosed cells, steals enemy turf
do
	local sim = newSim()
	local a = add(sim, 10, 10, 3)
	local b = add(sim, 30, 30, 3)
	sim.grid:set(14, 13, b) -- enemy cell inside the coming loop
	mv(sim, 0.05, { [a] = { 17, 11 } })
	mv(sim, 0.10, { [a] = { 17, 15 } })
	mv(sim, 0.15, { [a] = { 11, 15 } })
	sim:drainEvents()
	sim:drainCellChanges()
	mv(sim, 0.20, { [a] = { 11, 11 } }) -- re-enters at (11,11)
	local ev = sim:drainEvents()
	local c = ev[1] :: any
	assert(c.kind == "claim" and c.id == a and c.stolen == 1, kinds(ev))
	assert(c.cells == c.neutral + c.stolen)
	assert(sim:cellsOf(a) == 9 + c.cells)
	assert(sim.grid:get(14, 13) == a and sim:cellsOf(b) == 9)
	assert(#assert(sim:runner(a)).trail == 0 and sim:trailOwnerAt(17, 13) == 0)
	assert(#sim:drainCellChanges() == c.cells, "cell changes match claim")
	local deltas = sim:drainTrailDeltas()
	assert(deltas[1].clear and #deltas[1].append == 0, "claim clears the trail")
end

-- Cut: entering another runner's trail eliminates its owner; turf held until released
do
	local sim = newSim()
	local a = add(sim, 5, 5, 3)
	local b = add(sim, 30, 5, 3)
	mv(sim, 0.05, { [a] = { 5, 15 } })
	mv(sim, 0.10, { [b] = { 2, 12 } }) -- crosses a's trail column
	local ev = sim:drainEvents()
	local cut = ev[1] :: any
	assert(cut.kind == "cut" and cut.killer == b and cut.victim == a and cut.victimCells == 9, kinds(ev))
	assert(not sim:isAlive(a) and sim:isAlive(b))
	assert(#assert(sim:runner(a)).trail == 0 and sim:trailOwnerAt(5, 12) == 0)
	assert(sim:cellsOf(a) == 9, "turf held while pending")
	mv(sim, 0.15, { [a] = { 20, 20 } })
	assert(assert(sim:runner(a)).x == 5, "dead runners do not move")

	-- head-on: both enter each other's trail in the same tick
	local h = newSim()
	local p = add(h, 5, 5, 3)
	local q = add(h, 30, 5, 3)
	mv(h, 0.05, { [p] = { 5, 15 }, [q] = { 30, 15 } })
	mv(h, 0.10, { [p] = { 30, 14 }, [q] = { 5, 15 } })
	assert(not h:isAlive(p) and not h:isAlive(q), "head-on kills both")
	local hev = h:drainEvents()
	assert(kinds(hev) == "cut,cut")
	assert((hev[1] :: any).victim == p and (hev[1] :: any).killer == q)
	assert((hev[2] :: any).victim == q and (hev[2] :: any).killer == p)
	-- both killers dead: release gives nothing to anyone
	local given = h:releaseVictim(p)
	assert(given == 0 and h:cellsOf(p) == 0)
end

-- Own trail: crossing your own trail is harmless and adds no duplicate
do
	local sim = newSim()
	local a = add(sim, 5, 5, 3)
	mv(sim, 0.05, { [a] = { 5, 15 } })
	mv(sim, 0.10, { [a] = { 10, 15 } })
	mv(sim, 0.15, { [a] = { 10, 10 } })
	local n = #assert(sim:runner(a)).trail
	mv(sim, 0.20, { [a] = { 2, 10 } }) -- crosses column 5 at (5,10)
	assert(sim:isAlive(a))
	assert(#assert(sim:runner(a)).trail == n + 8 - 1, "own trail cell not duplicated")
end

-- Wall: targets outside the arena clamp to the edge; nobody dies
do
	local sim = newSim()
	local a = add(sim, 2, 2, 3)
	mv(sim, 0.05, { [a] = { -50, 2 } })
	mv(sim, 0.10, { [a] = { 2, 999 } })
	local r = assert(sim:runner(a))
	assert(sim:isAlive(a) and r.x == 2 and r.y == 39)
end

-- Enclosed: a runner inside someone else's claim survives on enemy turf
do
	local sim = newSim()
	local a = add(sim, 5, 5, 3)
	local b = add(sim, 30, 30, 3)
	local rb = assert(sim:runner(b))
	rb.x, rb.y = 12, 12
	mv(sim, 0.05, { [a] = { 20, 5 } })
	mv(sim, 0.10, { [a] = { 20, 20 } })
	mv(sim, 0.15, { [a] = { 5, 20 } })
	mv(sim, 0.20, { [a] = { 5, 6 } })
	assert(sim.grid:get(12, 12) == a, "area claimed")
	assert(sim:isAlive(b), "enclosed runner survives")
	local ev = sim:drainEvents()
	assert(kinds(ev) == "claim,king", kinds(ev)) -- no cut event: b survives; a is now big enough to be King
end

-- Elimination: killer gets the 25% of victim cells nearest it, the rest goes neutral
do
	local sim = newSim()
	local v = add(sim, 25, 25, 3)
	for y = 20, 29 do
		for x = 20, 29 do
			sim.grid:set(x, y, v)
		end
	end
	local k = add(sim, 5, 33, 3)
	mv(sim, 0.05, { [v] = { 25, 35 } })
	mv(sim, 0.10, { [k] = { 30, 33 } })
	assert(not sim:isAlive(v) and sim:cellsOf(v) == 100)
	local snapshot = {}
	for y = 20, 29 do
		for x = 20, 29 do
			table.insert(snapshot, sim.grid:index(x, y))
		end
	end
	local given, neutral = sim:releaseVictim(v)
	assert(given == 25 and neutral == 75 and sim:cellsOf(v) == 0)
	assert(sim:cellsOf(k) == 9 + 25)
	local maxGiven, minNeutral = -1, math.huge
	for _, i in snapshot do
		local x, y = sim.grid:fromIndex(i)
		local d = (x - 30) ^ 2 + (y - 33) ^ 2
		if sim.grid:getIndex(i) == k then
			maxGiven = math.max(maxGiven, d)
		else
			assert(sim.grid:getIndex(i) == 0)
			minNeutral = math.min(minNeutral, d)
		end
	end
	assert(maxGiven <= minNeutral, "killer got the nearest cells")
	assert(sim:releaseVictim(v) == 0, "release is one-shot")
	sim:respawn(v, 5, 3, 1)
	assert(sim:isAlive(v) and sim:cellsOf(v) == 25)

	-- Second Chance: revive cancels the release and keeps the turf
	local s = newSim()
	local a = add(s, 5, 5, 3)
	local b = add(s, 30, 5, 3)
	mv(s, 0.05, { [a] = { 5, 15 } })
	mv(s, 0.10, { [b] = { 2, 12 } })
	s:drainEvents()
	assert(s:revive(a, 3, 0.2))
	assert(s:isAlive(a) and s:cellsOf(a) == 9)
	local rev = s:drainEvents()[1] :: any
	assert(rev.kind == "spawn" and rev.shieldUntil == 3.2)
	assert(s:releaseVictim(a) == 0 and s:cellsOf(a) == 9, "release after revive is a no-op")
	assert(not s:revive(b, 3, 0.3), "only pending victims revive")
end

-- Leaving: removeRunner makes the turf neutral and frees the id
do
	local sim = newSim()
	local a = add(sim, 5, 5, 3)
	mv(sim, 0.05, { [a] = { 5, 15 } })
	sim:removeRunner(a, 1)
	assert(sim:cellsOf(a) == 0 and sim:runner(a) == nil and sim:trailOwnerAt(5, 12) == 0)
	assert(kinds(sim:drainEvents()) == "despawn")
	assert(#sim:drainCellChanges() == 9)
	assert(sim:allocateId() == a)
end

-- King: most cells with at least KingMinShare; event on change; victimWasKing on cut
do
	local sim = newSim() -- 1600 cells, king needs 48
	local a = add(sim, 5, 5, 3)
	local b = add(sim, 30, 30, 5)
	assert(sim:kingId() == 0, "25 cells is below the minimum share")
	mv(sim, 0.05, { [a] = { 15, 5 } })
	mv(sim, 0.10, { [a] = { 15, 15 } })
	mv(sim, 0.15, { [a] = { 5, 15 } })
	mv(sim, 0.20, { [a] = { 5, 6 } })
	local ev = sim:drainEvents()
	assert(kinds(ev) == "claim,king" and (ev[2] :: any).id == a, kinds(ev))
	assert(sim:kingId() == a and sim:share(a) >= Config.Arena.KingMinShare)
	mv(sim, 0.25, { [a] = { 5, 25 } })
	mv(sim, 0.30, { [b] = { 2, 20 } })
	ev = sim:drainEvents()
	assert(kinds(ev) == "cut,king", kinds(ev))
	assert((ev[1] :: any).victimWasKing == true and (ev[2] :: any).id == 0)
end

-- Win state: a 100% capture emits fullMap after the claim and resets to a start patch
do
	local sim = newSim(10)
	local a = add(sim, 1, 1, 3)
	mv(sim, 0.04, { [a] = { 2, 0 } }) -- still on own patch
	mv(sim, 0.05, { [a] = { 9, 0 } })
	mv(sim, 0.10, { [a] = { 9, 9 } })
	mv(sim, 0.15, { [a] = { 0, 9 } })
	mv(sim, 0.20, { [a] = { 0, 2 } })
	local ev = sim:drainEvents()
	assert(kinds(ev) == "claim,fullMap", kinds(ev))
	assert(sim:isAlive(a) and sim:cellsOf(a) > 0 and sim:cellsOf(a) <= 9)
	assert(sim:cellsOf(0) == 100 - sim:cellsOf(a))
end

-- Soak: 12 runners random-walking for 5,000 ticks; client mirror replays the replication stream
do
	local seed = 20261112
	local function rand(): number
		seed = (seed * 1103515245 + 12345) % 2147483648
		return seed / 2147483648
	end
	local sim = ArenaSim.new({ rng = rand })
	local size = sim.size
	local client = Grid.new(size)
	local clientTrails: { [number]: { number } } = {}
	local home: { [number]: { number } } = {}
	local heading: { [number]: { number } } = {}
	local respawnAt: { [number]: number } = {}
	local dirs = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 } }
	local claims, cuts, revives = 0, 0, 0

	local function handleEvents(tick: number, now: number)
		for _, e in sim:drainEvents() do
			local ev = e :: any
			if ev.kind == "spawn" then
				home[ev.runner.id] = { ev.x, ev.y }
			elseif ev.kind == "claim" then
				claims += 1
			elseif ev.kind == "cut" then
				cuts += 1
				if rand() < 0.2 then
					assert(sim:revive(ev.victim, 1, now))
					revives += 1
				else
					sim:releaseVictim(ev.victim)
					respawnAt[ev.victim] = tick + 60
				end
			end
		end
	end

	local function sync()
		client:applyDelta(sim.grid:encodeIndices(sim:drainCellChanges()))
		for _, d in sim:drainTrailDeltas() do
			local t = clientTrails[d.id] or {}
			clientTrails[d.id] = t
			if d.clear then
				table.clear(t)
			end
			for _, i in d.append do
				table.insert(t, i)
			end
		end
	end

	local function checkInvariants()
		local rc = sim.grid:recount()
		for o = 0, 255 do
			assert(rc[o + 1] == sim.grid:count(o), "grid count drift")
		end
		local overlay = 0
		for i = 0, sim.total - 1 do
			assert(client:getIndex(i) == sim.grid:getIndex(i), "client grid diverged")
			overlay += #sim:trailOwnersAt(i)
		end
		local trailCells = 0
		for _, r in sim:runners() do
			if not r.alive then
				assert(#r.trail == 0, "dead runner has a trail")
			end
			local seen = {}
			for _, i in r.trail do
				assert(sim.grid:getIndex(i) ~= r.id, "trail on own turf")
				assert(table.find(sim:trailOwnersAt(i), r.id), "overlay missing trail cell")
				assert(not seen[i], "duplicate trail cell")
				seen[i] = true
			end
			trailCells += #r.trail
			local ct = clientTrails[r.id] or {}
			assert(#ct == #r.trail, "client trail diverged")
			for k, i in r.trail do
				assert(ct[k] == i, "client trail order")
			end
		end
		assert(overlay == trailCells, "overlay has stale entries")
	end

	for k = 1, 12 do
		sim:addRunner(info(0), Config.Arena.StartPatch, Config.Arena.SpawnShield, 0)
		heading[k] = dirs[1 + math.floor(rand() * 4)]
	end
	handleEvents(0, 0)
	sync()

	local t0 = os.clock()
	for tick = 1, 5000 do
		local now = tick / Config.Arena.TickRate
		local positions = {}
		for _, r in sim:runners() do
			local id = r.id
			if r.alive then
				local h = heading[id]
				local hm = home[id]
				if #r.trail > 18 and hm and rand() < 0.7 then
					local dx, dy = hm[1] - r.x, hm[2] - r.y
					if math.abs(dx) > math.abs(dy) then
						h = { if dx > 0 then 1 else -1, 0 }
					else
						h = { 0, if dy > 0 then 1 else -1 }
					end
				elseif rand() < 0.15 then
					h = dirs[1 + math.floor(rand() * 4)]
				end
				local speed = if rand() < 0.2 then 2 else 1
				local nx, ny = r.x + h[1] * speed, r.y + h[2] * speed
				if nx < 0 or ny < 0 or nx >= size or ny >= size then
					h = { -h[1], -h[2] }
					nx, ny = r.x + h[1], r.y + h[2]
				end
				heading[id] = h
				positions[id] = { x = nx, y = ny }
			elseif not r.pending and respawnAt[id] and tick >= respawnAt[id] then
				respawnAt[id] = nil
				sim:respawn(id, Config.Arena.StartPatch, Config.Arena.SpawnShield, now)
			end
		end
		sim:step(now, positions)
		handleEvents(tick, now)
		sync()
		if tick % 100 == 0 then
			checkInvariants()
		end
	end
	local secs = os.clock() - t0
	print(string.format("arenasim soak: 5000 ticks in %.2f s, %d claims, %d cuts, %d revives", secs, claims, cuts, revives))
	assert(claims > 50 and cuts > 5, "soak exercised the rules")
	return string.format("arenasim ok (soak %.2fs, %d claims, %d cuts)", secs, claims, cuts)
end
