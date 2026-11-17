--!strict
-- Biome skins: grows low-poly scenery on turf owned by runners wearing a biome skin. Client only.
-- Placement is Biomes.blockProp (stable per block); this file only clones, animates and pools.
-- Prop templates are Models in ReplicatedStorage.BiomeProps (loaded by the server's BiomeService);
-- a missing template just means that prop is skipped.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Biomes = require(Shared.Biomes)
local Config = require(Shared.Config)
local Grid = require(Shared.Grid)
local ClientState = require(script.Parent.Parent.ClientState)

local BiomeRenderer = {}

local CFG = Config.Biomes
local B = CFG.BlockCells
local CS = Config.Arena.CellSize
local FLOOR = Config.Arena.FloorY + 0.1 -- turf top
local C1 = 1.70158

type PartInfo = { part: BasePart, rel: Vector3, size: Vector3, stage: number }
type Prop = { name: string, model: Model, parts: { PartInfo }, root: CFrame, scale: number, t0: number, out: boolean }

local grid: Grid.Grid? = nil
local size = 0
local nb = 0
local half = 0
local folder: Folder? = nil
local started = false

local shown: { [number]: Prop } = {} -- block index -> prop
local animating: { [Prop]: boolean } = {}
local dirty: { [number]: boolean } = {}
local dirtyList: { number } = {}
local live = 0
local pool: { [string]: { Prop } } = {}
local templates: { [string]: { model: Model, parts: { PartInfo } } } = {}

local debugSkin: string? = nil -- Studio-only override (see start)

local function biomeOf(owner: number): Biomes.Biome?
	if debugSkin then
		return Biomes.bySkin[debugSkin]
	end
	local info = ClientState.arena.runners[owner]
	return if info then Biomes.bySkin[info.skin] else nil
end

-- Template: part offsets from the model's base centre (min Y), colours and growth stage by part key.
local function template(name: string)
	local t = templates[name]
	if t then
		return t
	end
	local lib = ReplicatedStorage:FindFirstChild("BiomeProps")
	local src = lib and lib:FindFirstChild(name)
	if not (src and src:IsA("Model")) then
		return nil
	end
	local cf, ext = src:GetBoundingBox()
	local base = cf.Position - Vector3.new(0, ext.Y / 2, 0)
	local parts = {}
	for _, d in src:GetDescendants() do
		if d:IsA("BasePart") then
			local key = string.match(d.Name, "__(.+)$") or d.Name
			local spec = Biomes.parts[key]
			table.insert(parts, { part = d, rel = d.Position - base, size = d.Size, stage = if spec then spec[2] else 1 })
		end
	end
	t = { model = src, parts = parts }
	templates[name] = t
	return t
end

local function make(name: string): Prop?
	local list = pool[name]
	local p = list and table.remove(list)
	if p then
		return p
	end
	local t = template(name)
	if not t then
		return nil
	end
	local model = t.model:Clone()
	local parts = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Material = Enum.Material.SmoothPlastic
			local key = string.match(d.Name, "__(.+)$") or d.Name
			local spec = Biomes.parts[key]
			if spec then
				d.Color = Color3.fromHex(spec[1])
			end
		end
	end
	-- match clone parts to template info by order (Clone keeps descendant order)
	local k = 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			k += 1
			local info = t.parts[k]
			table.insert(parts, { part = d, rel = info.rel, size = info.size, stage = info.stage })
		end
	end
	return { name = name, model = model, parts = parts, root = CFrame.identity, scale = 1, t0 = 0, out = false }
end

local function release(p: Prop)
	p.model.Parent = nil
	animating[p] = nil
	live -= 1
	local list = pool[p.name]
	if not list then
		list = {}
		pool[p.name] = list
	end
	table.insert(list, p)
end

local function backOut(t: number): number
	local u = t - 1
	return 1 + (C1 + 1) * u * u * u + C1 * u * u
end

-- Grow: each stage starts StageDelay after the previous; positions follow stage 0 (the trunk),
-- so canopies ride up as the trunk grows and then inflate. Shrink: everything at once.
local function pose(p: Prop, now: number): boolean
	local t = now - p.t0
	local done = true
	local trunk = 1
	if p.out then
		trunk = 1 - math.clamp(t / CFG.ShrinkTime, 0, 1)
		done = trunk <= 0
	else
		trunk = backOut(math.clamp(t / CFG.GrowTime, 0, 1))
	end
	for _, info in p.parts do
		local s = trunk
		if not p.out then
			local lt = math.clamp((t - info.stage * CFG.StageDelay) / CFG.GrowTime, 0, 1)
			s = backOut(lt)
			if lt < 1 then
				done = false
			end
		end
		s = math.max(s, 0.02)
		info.part.Size = info.size * (p.scale * s)
		info.part.CFrame = p.root * CFrame.new(info.rel * (p.scale * math.max(trunk, 0.02)))
	end
	return done
end

local function show(bi: number, name: string, x: number, y: number, yaw: number, scale: number, now: number)
	local p = make(name)
	if not p then
		return
	end
	p.root = CFrame.new((x + 0.5) * CS - half, FLOOR, (y + 0.5) * CS - half) * CFrame.Angles(0, yaw, 0)
	p.scale = scale
	-- small per-block jitter so a capture pops in as a ripple, not all at once
	p.t0 = now + (Biomes.hash(x, y, 5) % 30) / 100
	p.out = false
	pose(p, now)
	p.model.Parent = folder
	shown[bi] = p
	animating[p] = true
	live += 1
end

local function hide(bi: number, now: number)
	local p = shown[bi]
	if p then
		shown[bi] = nil
		p.out = true
		p.t0 = now
		animating[p] = true
	end
end

local function evaluate(bi: number, now: number)
	local g = grid :: Grid.Grid
	local bx, by = bi % nb, bi // nb
	local ax, ay = Biomes.anchor(bx, by)
	local name, x, y, yaw, scale = nil :: string?, 0, 0, 0, 1
	if ax < size and ay < size then
		local owner = g:get(ax, ay)
		local biome = if owner ~= 0 then biomeOf(owner) else nil
		if biome then
			name, x, y, yaw, scale = Biomes.blockProp(biome, function(cx, cy)
				return g:get(cx, cy)
			end, size, owner, bx, by)
		end
	end
	local cur = shown[bi]
	if cur and cur.name == name and not cur.out then
		return
	end
	hide(bi, now)
	if name and live < CFG.MaxProps then
		show(bi, name, x, y, yaw, scale, now)
	end
end

local function markBlock(bx: number, by: number)
	if bx < 0 or by < 0 or bx >= nb or by >= nb then
		return
	end
	local bi = by * nb + bx
	if not dirty[bi] then
		dirty[bi] = true
		table.insert(dirtyList, bi)
	end
end

-- A changed cell can affect its own block and (via reach <= 2 < B) the 8 around it.
local function markCell(x: number, y: number)
	local bx, by = x // B, y // B
	for dy = -1, 1 do
		for dx = -1, 1 do
			markBlock(bx + dx, by + dy)
		end
	end
end

local function markBox(x0: number, y0: number, x1: number, y1: number)
	for by = y0 // B - 1, y1 // B + 1 do
		for bx = x0 // B - 1, x1 // B + 1 do
			markBlock(bx, by)
		end
	end
end

local function step()
	local now = os.clock()
	if grid then
		local budget = CFG.RebuildBudget
		while budget > 0 and #dirtyList > 0 do
			local bi = table.remove(dirtyList) :: number
			dirty[bi] = nil
			evaluate(bi, now)
			budget -= 1
		end
	end
	for p in animating do
		if now >= p.t0 or p.out then
			if pose(p, now) then
				if p.out then
					release(p)
				else
					animating[p] = nil
				end
			end
		end
	end
end

local function start()
	if started then
		return
	end
	started = true
	local f = Instance.new("Folder")
	f.Name = "BiomeProps"
	f.Parent = workspace
	folder = f
	RunService.Heartbeat:Connect(step)
	if RunService:IsStudio() then
		-- Studio-only test hook: workspace.BiomeProps.Debug:Fire("biome_woodland") paints every runner's turf.
		local ev = Instance.new("BindableEvent")
		ev.Name = "Debug"
		ev.Event:Connect(function(skin: string?)
			debugSkin = skin
			if grid then
				markBox(0, 0, size - 1, size - 1)
			end
		end)
		ev.Parent = f
	end
end

function BiomeRenderer.applySnapshot(g: Grid.Grid)
	start()
	local now = os.clock()
	for bi in shown do
		hide(bi, now)
	end
	grid = g
	size = g.size
	half = size * CS / 2
	nb = (size + B - 1) // B
	table.clear(dirty)
	table.clear(dirtyList)
	markBox(0, 0, size - 1, size - 1)
end

function BiomeRenderer.cellsChanged(indices: { number })
	if not grid then
		return
	end
	for _, i in indices do
		markCell(i % size, i // size)
	end
end

-- Skin change, spawn or despawn: re-evaluate everything the runner owns.
function BiomeRenderer.runnerChanged(id: number)
	local g = grid
	if not g then
		return
	end
	local x0, y0, x1, y1 = g:bounds(id)
	if x0 and y0 and x1 and y1 then
		markBox(x0, y0, x1, y1)
	end
end

return BiomeRenderer
