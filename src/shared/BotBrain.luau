--!strict
-- Engine-free bot decision module (GDD G10). One brain state per bot; `step` is called every
-- simulation tick and returns a 4-direction unit step. Decisions are planned per cell, so repeated
-- calls while the bot's cell is unchanged return the same step (unless a threat flips the mode).
local Config = require(script.Parent.Config)
local Grid = require(script.Parent.Grid)
local ArenaSim = require(script.Parent.ArenaSim)

local BotBrain = {}

export type TierConfig = { LoopMin: number, LoopMax: number, Reaction: number }

type Cell = { x: number, y: number }

export type State = {
	tier: TierConfig,
	rng: () -> number,
	plan: { Cell }?,
	planIdx: number,
	threatSince: number?,
	returning: boolean,
	-- decision cache, keyed by cell + trail length + mode
	cx: number,
	cy: number,
	ctrail: number,
	cmode: string,
	cdx: number,
	cdy: number,
}

local SHORT_TRAIL = 6 -- GDD G10: hunting allowed with a trail this short
local TRAIL_LIMIT_FACTOR = 4 -- trail longer than this many LoopMax forces Return
local EDGE_SEARCH_RADIUS = 10 -- cells searched around the bot for a turf edge
local MAX_EDGE_CANDIDATES = 6

local DIRS: { Cell } = { { x = 1, y = 0 }, { x = -1, y = 0 }, { x = 0, y = 1 }, { x = 0, y = -1 } }

function BotBrain.new(tierConfig: TierConfig, rng: () -> number): State
	return {
		tier = tierConfig,
		rng = rng,
		plan = nil,
		planIdx = 1,
		threatSince = nil,
		returning = false,
		cx = -1,
		cy = -1,
		ctrail = -1,
		cmode = "",
		cdx = 0,
		cdy = 0,
	}
end

function BotBrain.reset(state: State)
	state.plan = nil
	state.planIdx = 1
	state.threatSince = nil
	state.returning = false
	state.cx = -1
	state.cy = -1
	state.ctrail = -1
	state.cmode = ""
	state.cdx = 0
	state.cdy = 0
end

local function stepToward(x: number, y: number, tx: number, ty: number): (number, number)
	local ddx, ddy = tx - x, ty - y
	if ddx ~= 0 and math.abs(ddx) >= math.abs(ddy) then
		return (ddx > 0 and 1 or -1), 0
	end
	if ddy ~= 0 then
		return 0, (ddy > 0 and 1 or -1)
	end
	return 0, 0
end

local function consider(
	grid: Grid.Grid,
	id: number,
	x: number,
	y: number,
	cx: number,
	cy: number,
	bestD: number,
	bx: number,
	by: number
): (number, number, number)
	if cx >= 0 and cy >= 0 and cx < grid.size and cy < grid.size and grid:get(cx, cy) == id then
		local d = math.abs(cx - x) + math.abs(cy - y)
		if d < bestD then
			return d, cx, cy
		end
	end
	return bestD, bx, by
end

-- Nearest own cell by bounded ring search around (x, y), limited by the owner's bounding box.
local function nearestOwn(grid: Grid.Grid, id: number, x: number, y: number): (number?, number?)
	if grid:get(x, y) == id then
		return x, y
	end
	local x0, y0, x1, y1 = grid:bounds(id)
	if x0 == nil or y0 == nil or x1 == nil or y1 == nil then
		return nil, nil
	end
	local dmin = math.max(0, x0 - x, x - x1, y0 - y, y - y1)
	local rMax = math.min(grid.size, dmin + math.max(x1 - x0, y1 - y0) + 1)
	for r = math.max(1, dmin), rMax do
		local bestD, bx, by = math.huge, -1, -1
		for ox = -r, r do
			bestD, bx, by = consider(grid, id, x, y, x + ox, y - r, bestD, bx, by)
			bestD, bx, by = consider(grid, id, x, y, x + ox, y + r, bestD, bx, by)
		end
		for oy = -r + 1, r - 1 do
			bestD, bx, by = consider(grid, id, x, y, x - r, y + oy, bestD, bx, by)
			bestD, bx, by = consider(grid, id, x, y, x + r, y + oy, bestD, bx, by)
		end
		if bx >= 0 then
			return bx, by
		end
	end
	return nil, nil
end

local function isEdge(grid: Grid.Grid, id: number, x: number, y: number): boolean
	if grid:get(x, y) ~= id then
		return false
	end
	for _, d in DIRS do
		local nx, ny = x + d.x, y + d.y
		if grid:inBounds(nx, ny) and grid:get(nx, ny) ~= id then
			return true
		end
	end
	return false
end

-- Cells from (ex, ey) to the grid border going in direction (dx, dy).
local function room(size: number, ex: number, ey: number, dx: number, dy: number): number
	if dx == 1 then
		return size - 1 - ex
	elseif dx == -1 then
		return ex
	elseif dy == 1 then
		return size - 1 - ey
	end
	return ey
end

-- Rectangular loop: edge cell, out `a`, sideways `b`, back `a`. Never leaves the grid.
local function makePlan(state: State, grid: Grid.Grid, id: number, x: number, y: number): { Cell }?
	local tier, rng, size = state.tier, state.rng, grid.size
	local span = tier.LoopMax - tier.LoopMin + 1
	local a0 = math.min(tier.LoopMax, tier.LoopMin + math.floor(rng() * span))
	local b0 = math.min(tier.LoopMax, tier.LoopMin + math.floor(rng() * span))

	local cands: { { x: number, y: number, d: number } } = {}
	for ey = math.max(0, y - EDGE_SEARCH_RADIUS), math.min(size - 1, y + EDGE_SEARCH_RADIUS) do
		for ex = math.max(0, x - EDGE_SEARCH_RADIUS), math.min(size - 1, x + EDGE_SEARCH_RADIUS) do
			if isEdge(grid, id, ex, ey) then
				table.insert(cands, { x = ex, y = ey, d = math.abs(ex - x) + math.abs(ey - y) })
			end
		end
	end
	table.sort(cands, function(p, q)
		return p.d < q.d
	end)

	local best: { Cell }? = nil
	local bestScore = -math.huge
	for ci = 1, math.min(#cands, MAX_EDGE_CANDIDATES) do
		local c = cands[ci]
		for _, d in DIRS do
			local nx, ny = c.x + d.x, c.y + d.y
			if grid:inBounds(nx, ny) and grid:get(nx, ny) ~= id then
				local a = math.min(a0, room(size, c.x, c.y, d.x, d.y))
				if a >= 2 then
					-- pick the sideways direction: prefer ending back on own turf, then more room
					local bestSide: Cell? = nil
					local bestB = 0
					local bestSideScore = -math.huge
					for sgn = -1, 1, 2 do
						local sx, sy = d.y * sgn, d.x * sgn
						local rb = room(size, c.x, c.y, sx, sy)
						local b = math.min(b0, rb)
						if b >= 1 then
							local own = grid:get(c.x + sx * b, c.y + sy * b) == id
							local s = (own and 1000 or 0) + rb + rng() * 0.5
							if s > bestSideScore then
								bestSideScore = s
								bestSide = { x = sx, y = sy }
								bestB = b
							end
						end
					end
					if bestSide ~= nil then
						local sx, sy = bestSide.x, bestSide.y
						local free = 0
						for i = 1, a do
							for j = 0, bestB do
								if grid:get(c.x + d.x * i + sx * j, c.y + d.y * i + sy * j) ~= id then
									free += 1
								end
							end
						end
						local score = free + rng() * 1.5
						if score > bestScore then
							bestScore = score
							local w1x, w1y = c.x + d.x * a, c.y + d.y * a
							local w2x, w2y = w1x + sx * bestB, w1y + sy * bestB
							best = {
								{ x = c.x, y = c.y },
								{ x = w1x, y = w1y },
								{ x = w2x, y = w2y },
								{ x = c.x + sx * bestB, y = c.y + sy * bestB },
							}
						end
					end
				end
			end
		end
	end
	return best
end

-- Is another alive runner within `radius` (Chebyshev) of the bot or any cell of its trail?
local function threatened(sim: ArenaSim.ArenaSim, id: number, x: number, y: number, trail: { number }, radius: number): boolean
	local size = sim.grid.size
	local minX, maxX, minY, maxY = x, x, y, y
	for _, i in trail do
		local cx, cy = i % size, i // size
		minX, maxX = math.min(minX, cx), math.max(maxX, cx)
		minY, maxY = math.min(minY, cy), math.max(maxY, cy)
	end
	for _, o in sim:runners() do
		if o.id ~= id and o.alive then
			local ox, oy = o.x, o.y
			if ox >= minX - radius and ox <= maxX + radius and oy >= minY - radius and oy <= maxY + radius then
				if math.max(math.abs(ox - x), math.abs(oy - y)) <= radius then
					return true
				end
				for _, i in trail do
					if math.max(math.abs(ox - i % size), math.abs(oy - i // size)) <= radius then
						return true
					end
				end
			end
		end
	end
	return false
end

-- Nearest cut-able enemy trail cell within HuntRadius that beats the bot's own way home.
local function findHunt(sim: ArenaSim.ArenaSim, id: number, x: number, y: number, tlen: number, now: number): (number?, number?)
	local grid = sim.grid
	local size = grid.size
	local radius = Config.Bots.HuntRadius
	local homeDist = math.huge
	if tlen > 0 then
		local hx, hy = nearestOwn(grid, id, x, y)
		if hx ~= nil and hy ~= nil then
			homeDist = math.abs(hx - x) + math.abs(hy - y)
		end
	end
	local best, bx, by = math.huge, nil, nil
	for _, o in sim:runners() do
		if o.id ~= id and o.alive and now >= o.shieldUntil then
			for _, i in o.trail do
				local cx, cy = i % size, i // size
				if math.max(math.abs(cx - x), math.abs(cy - y)) <= radius then
					local d = math.abs(cx - x) + math.abs(cy - y)
					if d > 0 and d < best then
						best, bx, by = d, cx, cy
					end
				end
			end
		end
	end
	if bx ~= nil and (tlen == 0 or best < homeDist) then
		return bx, by
	end
	return nil, nil
end

local function wander(state: State, size: number, x: number, y: number): (number, number)
	local c = size // 2
	if x ~= c or y ~= c then
		return stepToward(x, y, c, c)
	end
	local d = DIRS[1 + math.floor(state.rng() * #DIRS) % #DIRS]
	return d.x, d.y
end

local function goHome(state: State, grid: Grid.Grid, id: number, x: number, y: number): (number, number)
	local tx, ty = nearestOwn(grid, id, x, y)
	if tx == nil or ty == nil then
		return wander(state, grid.size, x, y)
	end
	return stepToward(x, y, tx, ty)
end

function BotBrain.step(state: State, sim: ArenaSim.ArenaSim, id: number, now: number): (number, number)
	local r = sim:runner(id)
	if r == nil or not r.alive or r.pending then
		BotBrain.reset(state)
		return 0, 0
	end
	local grid = sim.grid
	local size = grid.size
	local x = math.clamp(math.floor(r.x), 0, size - 1)
	local y = math.clamp(math.floor(r.y), 0, size - 1)
	local tlen = #r.trail
	local tier = state.tier

	-- threat tracking (only meaningful while carrying a trail)
	if tlen == 0 then
		state.returning = false
		state.threatSince = nil
	elseif threatened(sim, id, x, y, r.trail, Config.Bots.ThreatRadius) then
		local since = state.threatSince
		if since == nil then
			since = now
			state.threatSince = now
		end
		if now - since >= tier.Reaction then
			state.returning = true
		end
	else
		state.threatSince = nil
	end

	local mode = "free"
	if grid:count(id) == 0 then
		mode = "wander"
	elseif state.returning or tlen > tier.LoopMax * TRAIL_LIMIT_FACTOR then
		mode = "return"
	end

	if state.cx == x and state.cy == y and state.ctrail == tlen and state.cmode == mode then
		return state.cdx, state.cdy
	end

	local dx, dy = 0, 0
	if mode == "wander" then
		state.plan = nil
		dx, dy = wander(state, size, x, y)
	elseif mode == "return" then
		state.plan = nil
		dx, dy = goHome(state, grid, id, x, y)
	else
		local hx, hy = nil, nil
		if tlen <= SHORT_TRAIL then
			hx, hy = findHunt(sim, id, x, y, tlen, now)
		end
		if hx ~= nil and hy ~= nil then
			state.plan = nil
			dx, dy = stepToward(x, y, hx, hy)
		else
			-- advance along the loop waypoints
			local plan = state.plan
			if plan ~= nil then
				local idx = state.planIdx
				while idx <= #plan and plan[idx].x == x and plan[idx].y == y do
					idx += 1
				end
				state.planIdx = idx
				if idx > #plan then
					state.plan = nil
					plan = nil
				else
					dx, dy = stepToward(x, y, plan[idx].x, plan[idx].y)
				end
			end
			if plan == nil then
				if tlen > 0 or grid:get(x, y) ~= id then
					dx, dy = goHome(state, grid, id, x, y)
				else
					local newPlan = makePlan(state, grid, id, x, y)
					if newPlan ~= nil then
						state.plan = newPlan
						state.planIdx = 1
						local idx = 1
						while idx <= #newPlan and newPlan[idx].x == x and newPlan[idx].y == y do
							idx += 1
						end
						state.planIdx = idx
						dx, dy = stepToward(x, y, newPlan[idx].x, newPlan[idx].y)
					else
						dx, dy = wander(state, size, x, y)
					end
				end
			end
		end
	end

	-- safety: never leave the grid
	if not grid:inBounds(x + dx, y + dy) then
		state.plan = nil
		dx, dy = wander(state, size, x, y)
		if not grid:inBounds(x + dx, y + dy) then
			dx, dy = 0, 0
			for _, d in DIRS do
				if grid:inBounds(x + d.x, y + d.y) then
					dx, dy = d.x, d.y
					break
				end
			end
		end
	end

	state.cx, state.cy, state.ctrail, state.cmode = x, y, tlen, mode
	state.cdx, state.cdy = dx, dy
	return dx, dy
end

return BotBrain
