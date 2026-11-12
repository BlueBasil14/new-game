--!strict
-- Pure helpers for the client turf renderer: merging trail cells into straight runs and
-- marking 16x16 render chunks dirty. No Instances, so they can be unit tested.
local TrailRuns = {}

-- Current (last) straight run of one trail: start (sx, sy), end (ex, ey), direction (dx, dy).
export type Runs = {
	has: boolean,
	sx: number,
	sy: number,
	ex: number,
	ey: number,
	dx: number,
	dy: number,
}

TrailRuns.NONE = 0 -- cell ignored (same as the last one)
TrailRuns.EXTEND = 1 -- current run grew; reshape its Part
TrailRuns.NEW = 2 -- a new run started; needs a new Part

function TrailRuns.new(): Runs
	return { has = false, sx = 0, sy = 0, ex = 0, ey = 0, dx = 0, dy = 0 }
end

function TrailRuns.reset(r: Runs)
	r.has = false
	r.dx, r.dy = 0, 0
end

-- Adds trail cell (x, y). A collinear neighbour extends the run; a turn starts a new run that
-- shares the corner cell so the strips meet without a gap; a jump starts a detached run.
function TrailRuns.push(r: Runs, x: number, y: number): number
	if not r.has then
		r.has = true
		r.sx, r.sy, r.ex, r.ey = x, y, x, y
		r.dx, r.dy = 0, 0
		return TrailRuns.NEW
	end
	local ddx, ddy = x - r.ex, y - r.ey
	if ddx == 0 and ddy == 0 then
		return TrailRuns.NONE
	end
	local adjacent = math.abs(ddx) + math.abs(ddy) == 1
	if adjacent and ((r.dx == 0 and r.dy == 0) or (r.dx == ddx and r.dy == ddy)) then
		r.ex, r.ey = x, y
		r.dx, r.dy = ddx, ddy
		return TrailRuns.EXTEND
	end
	if adjacent then
		r.sx, r.sy = r.ex, r.ey
		r.dx, r.dy = ddx, ddy
	else
		r.sx, r.sy = x, y
		r.dx, r.dy = 0, 0
	end
	r.ex, r.ey = x, y
	return TrailRuns.NEW
end

function TrailRuns.chunksPerSide(size: number, chunk: number): number
	return (size + chunk - 1) // chunk
end

-- 1-based chunk id of a 0-based cell index.
function TrailRuns.chunkOf(i: number, size: number, chunk: number, cps: number): number
	local x, y = i % size, i // size
	return (y // chunk) * cps + (x // chunk) + 1
end

-- Marks the chunks touched by indices dirty (flags[c] = true) and appends newly dirty ids to
-- list. Returns how many were newly marked.
function TrailRuns.markCells(
	indices: { number },
	size: number,
	chunk: number,
	cps: number,
	flags: { boolean },
	list: { number }
): number
	local added = 0
	for _, i in indices do
		local c = (i // size // chunk) * cps + (i % size) // chunk + 1
		if not flags[c] then
			flags[c] = true
			table.insert(list, c)
			added += 1
		end
	end
	return added
end

-- Marks every chunk overlapping the inclusive cell box.
function TrailRuns.markBox(
	x0: number,
	y0: number,
	x1: number,
	y1: number,
	chunk: number,
	cps: number,
	flags: { boolean },
	list: { number }
): number
	local added = 0
	for cy = y0 // chunk, y1 // chunk do
		for cx = x0 // chunk, x1 // chunk do
			local c = cy * cps + cx + 1
			if not flags[c] then
				flags[c] = true
				table.insert(list, c)
				added += 1
			end
		end
	end
	return added
end

return TrailRuns
