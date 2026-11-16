-- (o) server movement authority (docs/SECURITY_REVIEW.md part 2): C1 exempt window, C2 ignored
-- snap-back, H1 speed slack, H2 out of bounds, H3 NaN position, M3 re-equip.
H.boot()
H.run(1)
local env = H.S.env
local Config = H.shared("Config")
local Arena = H.svc("ArenaService")
local sim = Arena.sim
local GRID = Config.Arena.GridSize
local CELL = Config.Arena.CellSize

local function join(uid: number): any
	local p = H.addPlayer({ userId = uid, name = "Mover" .. uid })
	H.runUntil(function()
		return Arena.runnerIdOf(p) ~= 0
	end, 10, "runner " .. uid)
	return p
end
local function kicked(p: any): boolean
	for _, k in H.S.kicks do
		if k.userId == p.UserId then
			return true
		end
	end
	return false
end
local function moveTo(p: any, x: number, z: number)
	H.character(p):PivotTo(env.CFrame.new(x, H.pos(p).Y, z))
end
local function moveToCell(p: any, cx: number, cy: number)
	local x, z = H.cellToWorld(cx, cy)
	moveTo(p, x, z)
end
local function towardCentre(c: number): number
	return if c < GRID / 2 then 1 else -1
end
local function near(r: any, cx: number, cy: number, d: number): boolean
	return math.abs(r.x - cx) <= d and math.abs(r.y - cy) <= d
end

-- C1: once the spawn teleport has landed, a jump inside the 0.5 s window is speed-checked.
local p1 = join(701)
local id1 = Arena.runnerIdOf(p1)
H.run(0.15) -- landed; still inside the exempt window
local r1 = sim:runner(id1)
local sx, sy = r1.x, r1.y
moveToCell(p1, sx + 25 * towardCentre(sx), sy)
H.run(0.1)
H.check(near(r1, sx, sy, 1), "C1: jump inside the exempt window accepted (runner at %d,%d, spawn %d,%d)", r1.x, r1.y, sx, sy)
H.eq(#r1.trail, 0, "C1: trail line drawn to the jump target")
H.run(0.3)
local c1x, c1y = H.cellOf(p1)
H.check(math.abs(c1x - sx) <= 1 and math.abs(c1y - sy) <= 1, "C1: not snapped back (%d,%d)", c1x, c1y)

-- C2: a client that never leaves its far position is eliminated and reloaded, never accepted.
local p2 = join(702)
local id2 = Arena.runnerIdOf(p2)
H.run(0.15)
local r2 = sim:runner(id2)
local fx, fy = r2.x + 25 * towardCentre(r2.x), r2.y
local fwx, fwz = H.cellToWorld(fx, fy)
local char2 = H.character(p2)
local hold = env.CFrame.new(fwx, H.pos(p2).Y, fwz)
local reachedFar = false
table.insert(H.S.frameHooks, function()
	if H.character(p2) == char2 and not H.anchored(p2) then
		char2:PivotTo(hold) -- ignores every server teleport
	end
	local r = sim:runner(id2)
	if r ~= nil and r.info.userId == 702 and near(r, fx, fy, 3) then
		reachedFar = true
	end
end)
H.runUntil(function()
	return H.character(p2) ~= char2
end, 10, "C2: ignored snap-backs end in a character reload")
local reloadAt = H.M.clock
H.check(not reachedFar, "C2: server accepted the refused far position")
H.check(sim:runner(id2) == nil or sim:runner(id2).info.userId ~= 702, "C2: old runner still in the sim")
H.runUntil(function()
	return Arena.runnerIdOf(p2) ~= 0
end, 10, "C2: new runner after reload")
H.check(H.M.clock - reloadAt >= Config.Arena.RespawnDelay - 0.6, "C2: new runner before RespawnDelay (%.2fs)", H.M.clock - reloadAt)
H.check(not kicked(p2), "C2: kicked")

-- H2a: out of bounds without a trail: sent home with a strike; five strikes kick.
local p3 = join(703)
local id3 = Arena.runnerIdOf(p3)
local outside = Config.Arena.GridSize * CELL / 2 + 3 * CELL
for i = 1, Config.Security.KickStrikes do
	H.check(not kicked(p3), "H2: kicked after %d out-of-bounds strikes", i - 1)
	H.run(0.2) -- previous teleport landed
	moveTo(p3, outside, H.pos(p3).Z)
	H.run(0.1)
	if i == 1 then
		local r3 = sim:runner(id3)
		H.check(r3 ~= nil and r3.alive, "H2: runner without trail died out of bounds")
		local cx, cy = H.cellOf(p3)
		H.eq(sim.grid:get(cx, cy), id3, "H2: not sent home onto own turf")
	end
end
H.run(0.1)
H.check(kicked(p3), "H2: out of bounds gave no strikes (no kick after %d)", Config.Security.KickStrikes)

-- H2b: out of bounds with an open trail is an elimination with no killer (turf goes neutral).
local p4 = join(704)
local id4 = Arena.runnerIdOf(p4)
H.run(0.15)
local r4 = sim:runner(id4)
H.walkCells(p4, { { r4.x + 6 * towardCentre(r4.x), r4.y } })
H.runUntil(function()
	return not H.walking(p4)
end, 5, "H2: lay a trail")
H.check(#r4.trail >= 2, "H2: no trail (%d)", #r4.trail)
moveTo(p4, outside, H.pos(p4).Z)
H.run(0.1)
local cur4 = sim:runner(id4)
H.check(cur4 == nil or cur4.info.userId ~= 704, "H2: runner with a trail escaped out of bounds")
H.eq(Arena.runnerIdOf(p4), 0, "H2: player still has a runner")
local elimAt = H.M.clock
H.runUntil(function()
	return Arena.runnerIdOf(p4) ~= 0
end, 10, "H2: new runner after elimination")
H.check(H.M.clock - elimAt >= Config.Arena.RespawnDelay - 0.15, "H2: respawned before RespawnDelay (%.2fs)", H.M.clock - elimAt)
H.check(not kicked(p4), "H2: one strike kicked")

-- H3: a NaN position is dropped every tick with a strike, never reaches the sim.
local p5 = join(705)
local id5 = Arena.runnerIdOf(p5)
H.run(0.15)
local r5 = sim:runner(id5)
local x5, y5 = r5.x, r5.y
local nan = 0 / 0
H.character(p5):PivotTo(env.CFrame.new(nan, H.pos(p5).Y, nan))
H.run(0.1)
H.check(r5.x == x5 and r5.y == y5, "H3: NaN moved the runner")
H.run(0.3)
H.check(kicked(p5), "H3: NaN positions gave no strikes")

-- H1: the speed slack does not grow per tick. 1.9x speed is snapped back, 1.3x walks freely.
local function jumpsWhileWalking(uid: number, factor: number): number
	local p = join(uid)
	H.run(0.15)
	local r = sim:runner(Arena.runnerIdOf(p))
	local id = r.id
	local jumps, last = 0, H.pos(p)
	local hook = function(dt: number)
		local pos, hum = H.pos(p), H.humanoid(p)
		local rr = sim:runner(id)
		if pos and last and hum and rr and rr.alive then
			if (pos - last).Magnitude > hum.WalkSpeed * factor * dt * 1.01 + 1e-3 then
				jumps += 1
			end
		end
		last = pos
	end
	table.insert(H.S.frameHooks, hook)
	H.walkCells(p, { { r.x + 14 * towardCentre(r.x), r.y } }, { speedFactor = factor })
	H.run(2.5)
	table.remove(H.S.frameHooks, table.find(H.S.frameHooks, hook))
	H.stopWalking(p)
	return jumps
end
local fast = jumpsWhileWalking(706, 1.9)
H.check(fast >= 1, "H1: 1.9x speed never snapped back")
local ok13 = jumpsWhileWalking(707, 1.3)
H.eq(ok13, 0, "H1: snap-backs at 1.3x speed (inside tolerance)")

-- M3: re-equipping the equipped item succeeds without a RunnerInfo broadcast.
-- M2: Reset while alive: the reloaded character gets its runner only after RespawnDelay.
local p9 = join(709)
H.run(0.2)
H.humanoid(p9).Health = 0
local resetAt = H.M.clock
H.run(0.1)
H.eq(Arena.runnerIdOf(p9), 0, "M2: runner kept after reset")
H.runUntil(function()
	return Arena.runnerIdOf(p9) ~= 0
end, 10, "M2: runner after reset")
H.check(H.M.clock - resetAt >= Config.Arena.RespawnDelay - 0.05, "M2: reset skipped RespawnDelay (%.2fs)", H.M.clock - resetAt)

local p8 = join(708)
H.run(0.2)
H.eq(H.invoke(p8, "Equip", "default"), true, "M3: Equip default")
H.check(H.last(p8, "ArenaSnapshot") ~= nil, "M3: client not ready")
H.run(0.2)
H.clearSent(p8)
local okEq, res = H.invoke(p8, "Equip", "default")
H.run(0.2)
H.eq(okEq, true, "M3: re-equip ok")
H.eq(res, "default", "M3: re-equip result")
H.eq(#H.sent(p8, "RunnerInfo"), 0, "M3: re-equip broadcast RunnerInfo")
H.say(string.format("C2 reload, H1 jumps at 1.9x=%d", fast))
H.assertClean()
