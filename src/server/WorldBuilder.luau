--!strict
local Lighting = game:GetService("Lighting")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)

local WorldBuilder = {}

local HALF = Config.Arena.GridSize * Config.Arena.CellSize / 2
local FLOOR_Y = Config.Arena.FloorY
local WALL_H, WALL_T = 12, 4

function WorldBuilder.hex(str: string): Color3
	return Color3.fromHex(str)
end

local function makePart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, props: { [string]: any }?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props then
		for k, v in props do
			(p :: any)[k] = v
		end
	end
	p.Parent = parent
	return p
end

local function ball(parent: Instance, name: string, diameter: number, pos: Vector3, color: Color3, props: { [string]: any }?): Part
	local p = makePart(parent, name, Vector3.new(diameter, diameter, diameter), CFrame.new(pos), color, props)
	p.Shape = Enum.PartType.Ball
	return p
end

-- Cylinders extend along X, so rotate to stand them upright.
local function pillar(parent: Instance, name: string, height: number, diameter: number, pos: Vector3, color: Color3): Part
	local p = makePart(parent, name, Vector3.new(height, diameter, diameter), CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2), color)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function buildFloor(root: Folder)
	local f = folder(root, "Arena")
	local size = Config.Arena.GridSize * Config.Arena.CellSize
	local floor = makePart(f, "Floor", Vector3.new(size, 2, size), CFrame.new(0, FLOOR_Y - 1, 0), WorldBuilder.hex(Config.Colors.Ground))
	floor.TopSurface = Enum.SurfaceType.Smooth
	local lineColor = WorldBuilder.hex(Config.Colors.GridLine)
	local step = 8 * Config.Arena.CellSize
	local lines = folder(f, "GridLines")
	for i = 0, Config.Arena.GridSize / 8 do
		local offset = -HALF + i * step
		local common = { CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false }
		makePart(lines, "LineX", Vector3.new(size, 0.05, 0.4), CFrame.new(0, FLOOR_Y + 0.025, offset), lineColor, common)
		makePart(lines, "LineZ", Vector3.new(0.4, 0.05, size), CFrame.new(offset, FLOOR_Y + 0.025, 0), lineColor, common)
	end
end

local function buildWalls(root: Folder)
	local f = folder(root, "Walls")
	local color = WorldBuilder.hex(Config.Colors.Wall)
	local len = HALF * 2 + WALL_T * 2
	local c = HALF + WALL_T / 2
	local specs = {
		{ "North", Vector3.new(len, WALL_H, WALL_T), Vector3.new(0, 0, -c) },
		{ "South", Vector3.new(len, WALL_H, WALL_T), Vector3.new(0, 0, c) },
		{ "East", Vector3.new(WALL_T, WALL_H, len), Vector3.new(c, 0, 0) },
		{ "West", Vector3.new(WALL_T, WALL_H, len), Vector3.new(-c, 0, 0) },
	}
	for _, s in specs do
		local size = s[2] :: Vector3
		local pos = s[3] :: Vector3
		makePart(f, (s[1] :: string) .. "Wall", size, CFrame.new(pos + Vector3.new(0, FLOOR_Y + WALL_H / 2, 0)), color)
		local cs = Vector3.new(size.X, 60, size.Z)
		makePart(f, (s[1] :: string) .. "Collider", cs, CFrame.new(pos + Vector3.new(0, FLOOR_Y + WALL_H + 30, 0)), color, {
			Transparency = 1,
			CanQuery = false,
			CastShadow = false,
		})
	end

	local towers = folder(f, "Towers")
	local accent = WorldBuilder.hex(Config.Colors.Yellow)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local model = Instance.new("Model")
			model.Name = "CornerTower"
			model:SetAttribute("Placeholder", "M2")
			local bx, bz = sx * (HALF + WALL_T), sz * (HALF + WALL_T)
			makePart(model, "Base", Vector3.new(14, 6, 14), CFrame.new(bx, FLOOR_Y + 3, bz), color)
			pillar(model, "Shaft", 14, 9, Vector3.new(bx, FLOOR_Y + 13, bz), color)
			makePart(model, "Cap", Vector3.new(12, 3, 12), CFrame.new(bx, FLOOR_Y + 21.5, bz), color)
			ball(model, "Beacon", 5, Vector3.new(bx, FLOOR_Y + 25.5, bz), accent)
			model.Parent = towers
		end
	end
end

local function ringPos(rng: Random, minR: number, maxR: number): Vector3
	-- Sample outside the walls (square ring) by rejection.
	local limit = HALF + WALL_T + 14
	for _ = 1, 50 do
		local x = rng:NextNumber(-maxR, maxR)
		local z = rng:NextNumber(-maxR, maxR)
		if math.max(math.abs(x), math.abs(z)) > limit and math.max(math.abs(x), math.abs(z)) > minR then
			return Vector3.new(x, FLOOR_Y, z)
		end
	end
	return Vector3.new(maxR, FLOOR_Y, maxR)
end

local function buildDecor(root: Folder)
	local rng = Random.new(20240601)
	local greens = { Color3.fromHex("#4ADE80"), Color3.fromHex("#2DB86A"), Color3.fromHex("#B6E33B") }
	local rockColors = { Color3.fromHex("#9AA3B5"), Color3.fromHex("#6B7A99"), Color3.fromHex("#B8C0D0") }

	local trees = folder(root, "Trees")
	for _ = 1, 40 do
		local pos = ringPos(rng, 0, 560)
		local h = rng:NextNumber(10, 18)
		local model = Instance.new("Model")
		model.Name = "Tree"
		model:SetAttribute("Placeholder", "M4")
		pillar(model, "Trunk", h, 3, pos + Vector3.new(0, h / 2, 0), Color3.fromHex("#A0704A"))
		local g = greens[rng:NextInteger(1, #greens)]
		local d = h * 0.9
		ball(model, "LeavesLow", d, pos + Vector3.new(0, h + d * 0.2, 0), g)
		ball(model, "LeavesHigh", d * 0.65, pos + Vector3.new(0, h + d * 0.75, 0), g)
		model.Parent = trees
	end

	local rocks = folder(root, "Rocks")
	for _ = 1, 25 do
		local pos = ringPos(rng, 0, 560)
		local s = rng:NextNumber(3, 8)
		local r = makePart(rocks, "Rock", Vector3.new(s, s * 0.7, s * rng:NextNumber(0.8, 1.3)),
			CFrame.new(pos + Vector3.new(0, s * 0.25, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0),
			rockColors[rng:NextInteger(1, #rockColors)], { Material = Enum.Material.Slate })
		r:SetAttribute("Placeholder", "M5")
	end

	local clouds = folder(root, "Clouds")
	local white = Color3.new(1, 1, 1)
	for _ = 1, 12 do
		local model = Instance.new("Model")
		model.Name = "Cloud"
		model:SetAttribute("Placeholder", "M6")
		local c = Vector3.new(rng:NextNumber(-600, 600), rng:NextNumber(90, 140), rng:NextNumber(-600, 600))
		for _ = 1, rng:NextInteger(4, 5) do
			ball(model, "Puff", rng:NextNumber(18, 34), c + Vector3.new(rng:NextNumber(-22, 22), rng:NextNumber(-3, 3), rng:NextNumber(-10, 10)), white, {
				CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
			})
		end
		model.Parent = clouds
	end
end

local function buildProps(root: Folder)
	local f = folder(root, "Props")
	local dark = WorldBuilder.hex(Config.Colors.UiDark)
	local yellow = WorldBuilder.hex(Config.Colors.Yellow)
	local pink = WorldBuilder.hex(Config.Colors.Pink)
	local out = HALF + 50

	local kiosk = Instance.new("Model")
	kiosk.Name = "ShopKiosk"
	kiosk:SetAttribute("Placeholder", "M7")
	makePart(kiosk, "Counter", Vector3.new(12, 6, 8), CFrame.new(-30, FLOOR_Y + 3, out), pink)
	makePart(kiosk, "Roof", Vector3.new(15, 1.5, 11), CFrame.new(-30, FLOOR_Y + 12, out), yellow)
	for _, dx in { -6, 6 } do
		makePart(kiosk, "Post", Vector3.new(1, 6, 1), CFrame.new(-30 + dx, FLOOR_Y + 9, out + 4), dark)
	end
	kiosk.Parent = f

	local stand = Instance.new("Model")
	stand.Name = "LeaderboardStand"
	stand:SetAttribute("Placeholder", "M8")
	makePart(stand, "Post", Vector3.new(2, 8, 2), CFrame.new(30, FLOOR_Y + 4, out), dark)
	local panel = makePart(stand, "BoardPanel", Vector3.new(16, 10, 1), CFrame.new(30, FLOOR_Y + 13, out), dark)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "BoardGui"
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.Parent = panel
	local board = Instance.new("Frame")
	board.Name = "Board"
	board.Size = UDim2.fromScale(1, 1)
	board.BackgroundColor3 = dark
	board.BorderSizePixel = 0
	board.Parent = gui
	stand.Parent = f

	local chest = Instance.new("Model")
	chest.Name = "RewardChest"
	chest:SetAttribute("Placeholder", "M11")
	makePart(chest, "Box", Vector3.new(6, 4, 4), CFrame.new(0, FLOOR_Y + 2, out), yellow)
	makePart(chest, "Lid", Vector3.new(6.4, 1.5, 4.4), CFrame.new(0, FLOOR_Y + 4.75, out), pink)
	makePart(chest, "Lock", Vector3.new(1, 1.5, 0.5), CFrame.new(0, FLOOR_Y + 3.5, out - 2.2), dark)
	chest.Parent = f
end

local function buildLighting()
	-- Lighting.Technology (Future) is not scriptable; set it in Studio.
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.5
	Lighting.Ambient = Color3.fromHex("#8A93A8")
	Lighting.OutdoorAmbient = Color3.fromHex("#B8C0D0")
	Lighting.GlobalShadows = true

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "TurfColorCorrection"
	cc.Saturation = 0.15
	cc.Contrast = 0.05
	cc.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "TurfBloom"
	bloom.Intensity = 0.4
	bloom.Threshold = 1.2
	bloom.Size = 24
	bloom.Parent = Lighting

	local atmo = Instance.new("Atmosphere")
	atmo.Name = "TurfAtmosphere"
	atmo.Density = 0.25
	atmo.Color = Color3.fromHex("#CFE3FF")
	atmo.Decay = Color3.fromHex("#B8D0F0")
	atmo.Glare = 0
	atmo.Haze = 1
	atmo.Parent = Lighting
end

function WorldBuilder.build()
	local old = workspace:FindFirstChild("World")
	if old then
		old:Destroy()
	end
	local root = Instance.new("Folder")
	root.Name = "World"
	buildFloor(root)
	buildWalls(root)
	local decor = folder(root, "Decor")
	buildDecor(decor)
	buildProps(decor)
	root.Parent = workspace
	buildLighting()
end

return WorldBuilder
