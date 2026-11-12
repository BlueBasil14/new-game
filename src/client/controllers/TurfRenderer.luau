--!strict
-- Client-only turf and trail drawing with pooled anchored Parts.
-- Turf: the grid is split into CHUNK x CHUNK cell chunks; changed cells mark chunks dirty and a
-- per-frame budget of dirty chunks is re-meshed (GreedyMesh per owner present in the chunk).
-- Trails: one Part per straight run of trail cells (TrailRuns). Unused Parts are parked with
-- Parent = nil and never destroyed.
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local Grid = require(Shared.Grid)
local GreedyMesh = require(Shared.GreedyMesh)
local TrailRuns = require(Shared.TrailRuns)
local Types = require(Shared.Types)
local ClientState = require(script.Parent.Parent.ClientState)

local TurfRenderer = {}

-- pattern name -> image asset id; empty until pattern textures exist.
TurfRenderer.patternImages = {} :: { [string]: number }

local CHUNK = 16
local BUDGET = 6
local BUDGET_LOW = 3
local TURF_H = 0.2
local TRAIL_H = 0.6
local TRAIL_WIDTH = 0.6 -- fraction of a cell
local TRAIL_BRIGHTEN = 0.35
local FLASH_TIME = 0.25
local FLASH_LIGHTEN = 0.6
local FLASH_MAX = 40
local STOLEN_TINT = 0.7 -- stolen-claim flash starts this far from the owner colour toward Danger
local FLASH_WINDOW = 0.6 -- seconds a claim event and its cell delta may arrive apart
local BLINK_HZ = 4
local TEXTURE_TILE_CELLS = 2

local CS = Config.Arena.CellSize
local FLOOR = Config.Arena.FloorY
local WHITE = Color3.new(1, 1, 1)
local FALLBACK = Color3.fromHex(Config.Colors.GridLine)
local STOLEN_COLOR = Color3.fromHex(Config.Colors.Danger)

type Style = {
	a: Color3,
	b: Color3?,
	pattern: string,
	trail: Color3,
	image: number?,
}

local started = false
local folder: Folder? = nil
local grid: Grid.Grid? = nil
local size = Config.Arena.GridSize
local half = size * CS / 2
local cps = TrailRuns.chunksPerSide(size, CHUNK)
local lowDetail = false

local chunkParts: { { BasePart } } = {}
local chunkOwners: { { number } } = {}
local dirty: { boolean } = {}
local dirtyList: { number } = {}
local dirtyHead = 1
local gainOwner: { number } = {} -- chunk -> last owner that gained cells there
local gainTime: { number } = {}

local turfPool: { BasePart } = {}
local trailPool: { BasePart } = {}
local partTexture: { [BasePart]: Texture } = {}

local styles: { [number]: Style } = {}
local trailParts: { [number]: { BasePart } } = {}
local trailRuns: { [number]: TrailRuns.Runs } = {}
local danger: { [number]: boolean } = {}
local blinkOn = false

local claimAt: { [number]: number } = {}
local flashLeft: { [number]: number } = {}
local claimStolen: { [number]: boolean } = {} -- owner -> latest claim took cells from others
local flashStart: { [BasePart]: number } = {}
local flashFrom: { [BasePart]: Color3 } = {}
local flashTo: { [BasePart]: Color3 } = {}

-- Owner-presence scratch for one chunk pass.
local seen: { number } = table.create(256, 0)
local stamp = 0
local owners: { number } = table.create(256, 0)

local function newPart(): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Locked = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	return p
end

local function acquireTurf(): BasePart
	local n = #turfPool
	local p = turfPool[n]
	if p then
		turfPool[n] = nil
	else
		p = newPart()
		p.Name = "Turf"
	end
	p.Parent = folder
	return p
end

local function acquireTrail(): BasePart
	local n = #trailPool
	local p = trailPool[n]
	if p then
		trailPool[n] = nil
	else
		p = newPart()
		p.Name = "Trail"
	end
	p.Material = if lowDetail then Enum.Material.SmoothPlastic else Enum.Material.Neon
	p.Parent = folder
	return p
end

local function stopFlash(p: BasePart)
	if flashStart[p] then
		flashStart[p] = nil
		flashFrom[p] = nil
		flashTo[p] = nil
	end
end

local function releaseTurf(p: BasePart)
	stopFlash(p)
	p.Parent = nil
	table.insert(turfPool, p)
end

local function releaseTrail(p: BasePart)
	p.Parent = nil
	table.insert(trailPool, p)
end

local function hex(s: string?): Color3?
	if not s then
		return nil
	end
	local ok, c = pcall(Color3.fromHex, s)
	return if ok then c else nil
end

local function styleOf(owner: number): Style
	local s = styles[owner]
	if s then
		return s
	end
	local a, b, pattern = FALLBACK, nil :: Color3?, "solid"
	local trailBase = FALLBACK
	local info: Types.RunnerInfo? = ClientState.arena.runners[owner]
	if info then
		local item = Catalog.byId(info.skin)
		if item and item.type == "skin" and not item.default then
			a = hex(item.colorA) or FALLBACK
			b = hex(item.colorB)
			pattern = item.pattern
		else
			a = hex(Config.Colors.Players[info.colorIndex]) or FALLBACK
		end
		trailBase = a
		local trailItem = Catalog.byId(info.trail)
		if trailItem and trailItem.type == "trail" and not trailItem.default then
			trailBase = hex(trailItem.colorA) or a
		end
	end
	s = {
		a = a,
		b = b,
		pattern = pattern,
		trail = trailBase:Lerp(WHITE, TRAIL_BRIGHTEN),
		image = TurfRenderer.patternImages[pattern],
	}
	styles[owner] = s
	return s
end

-- Cheap pattern stand-in until textures exist: alternate colorA/colorB per chunk.
local function chunkColor(s: Style, cx: number, cy: number): Color3
	local b = s.b
	if b and s.pattern ~= "solid" and not s.image then
		local parity = if s.pattern == "stripes" then cx % 2 else (cx + cy) % 2
		return if parity == 0 then s.a else b
	end
	return s.a
end

local function applyTexture(p: BasePart, s: Style)
	local tex = partTexture[p]
	local image = s.image
	if image then
		if not tex then
			local t = Instance.new("Texture")
			t.Face = Enum.NormalId.Top
			t.StudsPerTileU = CS * TEXTURE_TILE_CELLS
			t.StudsPerTileV = CS * TEXTURE_TILE_CELLS
			t.Parent = p
			partTexture[p] = t
			tex = t
		end
		local t = tex :: Texture
		t.Texture = "rbxassetid://" .. image
		t.Color3 = s.b or WHITE
		t.Transparency = 0
	elseif tex then
		tex.Transparency = 1
	end
end

local function startFlash(p: BasePart, owner: number, color: Color3, now: number)
	local left = flashLeft[owner] or 0
	if lowDetail or left <= 0 then
		return
	end
	flashLeft[owner] = left - 1
	local from = if claimStolen[owner] then color:Lerp(STOLEN_COLOR, STOLEN_TINT) else color:Lerp(WHITE, FLASH_LIGHTEN)
	p.Color = from
	flashStart[p] = now
	flashFrom[p] = from
	flashTo[p] = color
end

local function markDirty(c: number)
	if not dirty[c] then
		dirty[c] = true
		table.insert(dirtyList, c)
	end
end

local function rebuildChunk(c: number, now: number)
	local g = grid :: Grid.Grid
	local cells = g.cells
	local cx, cy = (c - 1) % cps, (c - 1) // cps
	local x0, y0 = cx * CHUNK, cy * CHUNK
	local x1, y1 = math.min(x0 + CHUNK - 1, size - 1), math.min(y0 + CHUNK - 1, size - 1)

	stamp += 1
	local n = 0
	for y = y0, y1 do
		local row = y * size
		for x = x0, x1 do
			local o = buffer.readu8(cells, row + x)
			if o ~= 0 and seen[o] ~= stamp then
				seen[o] = stamp
				n += 1
				owners[n] = o
			end
		end
	end

	local flashOwner = 0
	local go = gainOwner[c]
	if go ~= 0 then
		local t = claimAt[go]
		if t and now - t < FLASH_WINDOW then
			flashOwner = go
			gainOwner[c] = 0
		elseif now - gainTime[c] > FLASH_WINDOW then
			gainOwner[c] = 0
		end
	end

	local parts, pOwner = chunkParts[c], chunkOwners[c]
	local used = 0
	for k = 1, n do
		local o = owners[k]
		local s = styleOf(o)
		local color = chunkColor(s, cx, cy)
		local rects = GreedyMesh.build(g, o, x0, y0, x1, y1)
		for _, r in rects do
			used += 1
			local p = parts[used]
			if not p then
				p = acquireTurf()
				parts[used] = p
			end
			pOwner[used] = o
			stopFlash(p)
			p.Size = Vector3.new(r.w * CS, TURF_H, r.h * CS)
			p.CFrame = CFrame.new((r.x + r.w * 0.5) * CS - half, FLOOR + 0.1 - TURF_H * 0.5, (r.y + r.h * 0.5) * CS - half)
			p.Color = color
			applyTexture(p, s)
			if o == flashOwner then
				startFlash(p, o, color, now)
			end
		end
	end
	for k = #parts, used + 1, -1 do
		releaseTurf(parts[k])
		parts[k] = nil
		pOwner[k] = nil
	end
end

local function trailColor(id: number): Color3
	if danger[id] and blinkOn then
		return WHITE
	end
	return styleOf(id).trail
end

local function placeRun(p: BasePart, r: TrailRuns.Runs)
	local x0, x1 = math.min(r.sx, r.ex), math.max(r.sx, r.ex)
	local y0, y1 = math.min(r.sy, r.ey), math.max(r.sy, r.ey)
	local thin = CS * TRAIL_WIDTH
	p.Size = Vector3.new((x1 - x0) * CS + thin, TRAIL_H, (y1 - y0) * CS + thin)
	p.CFrame = CFrame.new((x0 + x1 + 1) * 0.5 * CS - half, FLOOR + TRAIL_H * 0.5, (y0 + y1 + 1) * 0.5 * CS - half)
end

local function clearTrail(id: number)
	local list = trailParts[id]
	if list then
		for k = #list, 1, -1 do
			releaseTrail(list[k])
			list[k] = nil
		end
	end
	local r = trailRuns[id]
	if r then
		TrailRuns.reset(r)
	end
end

local function recolorTrail(id: number)
	local list = trailParts[id]
	if not list then
		return
	end
	local c = trailColor(id)
	for _, p in list do
		p.Color = c
	end
end

local function resetAll()
	for c = 1, #chunkParts do
		local parts = chunkParts[c]
		for k = #parts, 1, -1 do
			releaseTurf(parts[k])
			parts[k] = nil
		end
	end
	for id in trailParts do
		clearTrail(id)
	end
	table.clear(chunkParts)
	table.clear(chunkOwners)
	table.clear(dirty)
	table.clear(dirtyList)
	table.clear(gainOwner)
	table.clear(gainTime)
	table.clear(styles)
	table.clear(claimAt)
	table.clear(flashLeft)
	table.clear(claimStolen)
	dirtyHead = 1
	half = size * CS / 2
	cps = TrailRuns.chunksPerSide(size, CHUNK)
	for c = 1, cps * cps do
		chunkParts[c] = {}
		chunkOwners[c] = {}
		dirty[c] = false
		gainOwner[c] = 0
		gainTime[c] = 0
	end
end

local function step()
	local now = os.clock()
	if grid then
		local budget = if lowDetail then BUDGET_LOW else BUDGET
		while budget > 0 and dirtyHead <= #dirtyList do
			local c = dirtyList[dirtyHead]
			dirtyHead += 1
			if dirty[c] then
				dirty[c] = false
				rebuildChunk(c, now)
				budget -= 1
			end
		end
		if dirtyHead > #dirtyList then
			table.clear(dirtyList)
			dirtyHead = 1
		end
	end

	if next(flashStart) ~= nil then
		for p, t0 in flashStart do
			local a = (now - t0) / FLASH_TIME
			if a >= 1 then
				p.Color = flashTo[p]
				flashStart[p] = nil
				flashFrom[p] = nil
				flashTo[p] = nil
			else
				p.Color = flashFrom[p]:Lerp(flashTo[p], a)
			end
		end
	end

	if next(danger) ~= nil then
		local on = math.floor(now * BLINK_HZ * 2) % 2 == 0
		if on ~= blinkOn then
			blinkOn = on
			for id in danger do
				recolorTrail(id)
			end
		end
	end
end

function TurfRenderer.start()
	if started then
		return
	end
	started = true
	local existing = workspace:FindFirstChild("Turf")
	if existing and existing:IsA("Folder") then
		folder = existing
	else
		local f = Instance.new("Folder")
		f.Name = "Turf"
		f.Parent = workspace
		folder = f
	end
	resetAll()

	local function readSettings()
		local profile = ClientState.profile
		if profile then
			TurfRenderer.setLowDetail(profile.settings.lowDetail)
		end
	end
	ClientState.profileChanged:Connect(readSettings)
	readSettings()

	RunService.Heartbeat:Connect(step)
end

-- Full (re)build from a freshly decoded grid. Trails are dropped; the server follows a snapshot
-- with a delta carrying every trail in full.
function TurfRenderer.applySnapshot(g: Grid.Grid)
	grid = g
	size = g.size
	resetAll()
	for c = 1, cps * cps do
		markDirty(c)
	end
end

function TurfRenderer.cellsChanged(indices: { number })
	local g = grid
	if not g then
		return
	end
	local now = os.clock()
	local cells = g.cells
	for _, i in indices do
		local c = (i // size // CHUNK) * cps + (i % size) // CHUNK + 1
		markDirty(c)
		local o = buffer.readu8(cells, i)
		if o ~= 0 then
			gainOwner[c] = o
			gainTime[c] = now
		end
	end
end

-- Claim wave trigger (GDD G6). Chunks whose delta already arrived and were rebuilt flash now;
-- the rest flash when rebuilt within FLASH_WINDOW.
function TurfRenderer.claimFlash(owner: number, stolen: boolean?)
	if lowDetail or owner == 0 then
		return
	end
	claimStolen[owner] = stolen == true
	local now = os.clock()
	local estimate = 0
	for c = 1, cps * cps do
		if gainOwner[c] == owner and now - gainTime[c] < FLASH_WINDOW then
			local pOwner = chunkOwners[c]
			local found = 0
			for k = 1, #pOwner do
				if pOwner[k] == owner then
					found += 1
				end
			end
			estimate += math.max(found, 1)
		end
	end
	if estimate > FLASH_MAX then
		flashLeft[owner] = 0
		claimAt[owner] = nil
		return
	end
	claimAt[owner] = now
	flashLeft[owner] = FLASH_MAX
	for c = 1, cps * cps do
		if gainOwner[c] == owner and not dirty[c] and now - gainTime[c] < FLASH_WINDOW then
			gainOwner[c] = 0
			local parts, pOwner = chunkParts[c], chunkOwners[c]
			for k = 1, #parts do
				if pOwner[k] == owner then
					local p = parts[k]
					startFlash(p, owner, flashTo[p] or p.Color, now)
				end
			end
		end
	end
end

function TurfRenderer.trailDelta(delta: Types.TrailDelta)
	local id = delta.id
	if delta.clear then
		clearTrail(id)
	end
	local append = delta.append
	if #append == 0 then
		return
	end
	local r = trailRuns[id]
	if not r then
		r = TrailRuns.new()
		trailRuns[id] = r
	end
	local list = trailParts[id]
	if not list then
		list = {}
		trailParts[id] = list
	end
	local runs = r :: TrailRuns.Runs
	local parts = list :: { BasePart }
	local color = trailColor(id)
	for _, i in append do
		local res = TrailRuns.push(runs, i % size, i // size)
		if res == TrailRuns.NEW then
			local p = acquireTrail()
			p.Color = color
			table.insert(parts, p)
			placeRun(p, runs)
		elseif res == TrailRuns.EXTEND then
			placeRun(parts[#parts], runs)
		end
	end
end

-- Despawned runner: drop its trail state entirely.
function TurfRenderer.removeRunner(id: number)
	clearTrail(id)
	trailParts[id] = nil
	trailRuns[id] = nil
	danger[id] = nil
end

-- Base turf colour of a runner (same lookup the renderer uses); neutral grey for unknown ids.
function TurfRenderer.colorOf(runnerId: number): Color3
	if runnerId == 0 then
		return FALLBACK
	end
	return styleOf(runnerId).a
end

function TurfRenderer.runnerChanged(id: number)
	styles[id] = nil
	local g = grid
	if g then
		local x0, y0, x1, y1 = g:bounds(id)
		if x0 and y0 and x1 and y1 then
			TrailRuns.markBox(x0, y0, x1, y1, CHUNK, cps, dirty, dirtyList)
		end
	end
	recolorTrail(id)
end

function TurfRenderer.setTrailDanger(id: number, on: boolean)
	if on then
		danger[id] = true
	elseif danger[id] then
		danger[id] = nil
		recolorTrail(id)
	end
end

function TurfRenderer.setLowDetail(on: boolean)
	if on == lowDetail then
		return
	end
	lowDetail = on
	local material = if on then Enum.Material.SmoothPlastic else Enum.Material.Neon
	for _, list in trailParts do
		for _, p in list do
			p.Material = material
		end
	end
	if on then
		for p in flashStart do
			p.Color = flashTo[p]
		end
		table.clear(flashStart)
		table.clear(flashFrom)
		table.clear(flashTo)
	end
end

return TurfRenderer
