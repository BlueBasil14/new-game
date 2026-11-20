--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)

local CameraController = {}
CameraController.shakeEnabled = true

local BIND_NAME = "TurfLoopCamera"
local SMOOTH = 8 -- exponential follow rate
local FULL_SHARE = 0.25

local started = false
local share = 0
local distance: number = Config.Camera.MaxDistance
local focus: Vector3? = nil
local fovPunch = 0
local shakeStrength = 0
local shakeTime = 0
local shakeTotal = 0
local holdUntil = 0
local recMode = "game" -- "game" | "map" | "sky"; only changed by the Studio-only recording key

-- Studio-only recording cameras (Main.client binds the key). Hides every ScreenGui while not "game".
local hiddenGuis: { ScreenGui } = {}
function CameraController.setRecMode(mode: string)
	if mode ~= "map" and mode ~= "sky" then
		mode = "game"
	end
	recMode = mode
	-- Decorative clouds float over the arena and block the overhead shots; hide them on this client only.
	local world = workspace:FindFirstChild("World")
	local decor = world and world:FindFirstChild("Decor")
	local clouds = decor and decor:FindFirstChild("Clouds")
	if clouds then
		for _, p in clouds:GetDescendants() do
			if p:IsA("BasePart") then
				p.LocalTransparencyModifier = if mode == "game" then 0 else 1
			end
		end
	end
	local gui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if mode == "game" then
		for _, g in hiddenGuis do
			g.Enabled = true
		end
		table.clear(hiddenGuis)
	elseif gui and #hiddenGuis == 0 then
		for _, g in gui:GetChildren() do
			if g:IsA("ScreenGui") and g.Enabled then
				g.Enabled = false
				table.insert(hiddenGuis, g)
			end
		end
	end
end

function CameraController.getRecMode(): string
	return recMode
end

function CameraController.setTurfShare(s: number)
	share = math.clamp(s, 0, 1)
end

-- Smoothed world point the camera looks at (nil before the character exists).
function CameraController.getFocus(): Vector3?
	return focus
end

function CameraController.punch(amount: number)
	fovPunch = math.max(fovPunch, amount)
end

-- Hit-stop: the camera holds its last frame for a moment. Client-only, no gameplay effect.
function CameraController.hold(seconds: number)
	holdUntil = math.max(holdUntil, os.clock() + seconds)
end

function CameraController.shake(strength: number, seconds: number)
	if not CameraController.shakeEnabled or seconds <= 0 then
		return
	end
	shakeStrength = math.max(shakeStrength * (shakeTime / math.max(shakeTotal, 0.001)), strength)
	shakeTime = seconds
	shakeTotal = seconds
end

local function getRoot(): BasePart?
	local char = Players.LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local southWall: BasePart? = nil

-- GAP-28: near the south wall the camera sits outside the arena, so the wall is faded
-- on this client only while it stands between the camera and the runner.
local function fadeSouthWall(camPos: Vector3, f: Vector3, pitch: number)
	local wall = southWall
	if not wall or not wall:IsDescendantOf(workspace) then
		local world = workspace:FindFirstChild("World")
		local walls = world and world:FindFirstChild("Walls")
		wall = walls and walls:FindFirstChild("SouthWall") :: BasePart?
		southWall = wall
	end
	if not wall then
		return
	end
	local nearZ = wall.Position.Z - wall.Size.Z / 2
	local fade = 0
	if camPos.Z > nearZ then
		-- Height at which the camera-to-runner line passes the wall's inner face.
		local crossY = f.Y + (nearZ - f.Z) * math.tan(pitch)
		local top = wall.Position.Y + wall.Size.Y / 2
		fade = math.clamp((top + Config.Camera.WallFadeMargin - crossY) / Config.Camera.WallFadeMargin, 0, 1)
	end
	wall.LocalTransparencyModifier = fade * Config.Camera.WallFade
end

local function step(dt: number)
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	cam.CameraType = Enum.CameraType.Scriptable
	if os.clock() < holdUntil then
		return
	end

	if recMode == "map" then
		-- Fit the whole arena (centred on the origin) in the shorter screen side, north at the top.
		local rc = Config.RecCamera
		local half = Config.Arena.GridSize * Config.Arena.CellSize / 2 + rc.MapMargin
		local view = cam.ViewportSize
		local aspect = if view.Y > 0 then view.X / view.Y else 1
		local tanV = math.tan(math.rad(rc.MapFov) / 2)
		local height = half / (tanV * math.min(1, aspect))
		cam.FieldOfView = rc.MapFov
		cam.CFrame = CFrame.lookAt(Vector3.new(0, height, 0), Vector3.zero, Vector3.new(0, 0, -1))
		return
	end

	local root = getRoot()
	if root then
		local target = root.Position
		local alpha = 1 - math.exp(-SMOOTH * dt)
		focus = if focus then (focus :: Vector3):Lerp(target, alpha) else target
	end
	local f = focus
	if not f then
		return
	end

	local sky = recMode == "sky"
	local wanted = if sky
		then Config.RecCamera.SkyDistance
		else Config.Camera.MinDistance + (Config.Camera.MaxDistance - Config.Camera.MinDistance) * math.clamp(share / FULL_SHARE, 0, 1)
	distance += (wanted - distance) * (1 - math.exp(-2 * dt))

	local pitch = math.rad(if sky then Config.RecCamera.SkyPitch else Config.Camera.Pitch)
	-- Camera sits south (+Z) of the focus looking north (-Z), so +X is screen-right.
	local pos = f + Vector3.new(0, math.sin(pitch), math.cos(pitch)) * distance
	local cf = CFrame.lookAt(pos, f)
	fadeSouthWall(pos, f, pitch)

	if shakeTime > 0 then
		shakeTime = math.max(0, shakeTime - dt)
		local k = shakeStrength * (shakeTime / math.max(shakeTotal, 0.001))
		cf += Vector3.new((math.random() - 0.5) * 2 * k, (math.random() - 0.5) * 2 * k, (math.random() - 0.5) * 2 * k)
	end
	cam.CFrame = cf

	fovPunch -= fovPunch * (1 - math.exp(-10 * dt))
	cam.FieldOfView = (if sky then Config.RecCamera.SkyFov else Config.Camera.FieldOfView) - fovPunch
end

function CameraController.start()
	if started then
		return
	end
	started = true
	RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Camera.Value + 1, step)
end

return CameraController
