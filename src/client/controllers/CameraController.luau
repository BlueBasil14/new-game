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

local function step(dt: number)
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	cam.CameraType = Enum.CameraType.Scriptable
	if os.clock() < holdUntil then
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

	local wanted = Config.Camera.MinDistance + (Config.Camera.MaxDistance - Config.Camera.MinDistance) * math.clamp(share / FULL_SHARE, 0, 1)
	distance += (wanted - distance) * (1 - math.exp(-2 * dt))

	local pitch = math.rad(Config.Camera.Pitch)
	-- Camera sits south (+Z) of the focus looking north (-Z), so +X is screen-right.
	local pos = f + Vector3.new(0, math.sin(pitch), math.cos(pitch)) * distance
	local cf = CFrame.lookAt(pos, f)

	if shakeTime > 0 then
		shakeTime = math.max(0, shakeTime - dt)
		local k = shakeStrength * (shakeTime / math.max(shakeTotal, 0.001))
		cf += Vector3.new((math.random() - 0.5) * 2 * k, (math.random() - 0.5) * 2 * k, (math.random() - 0.5) * 2 * k)
	end
	cam.CFrame = cf

	fovPunch -= fovPunch * (1 - math.exp(-10 * dt))
	cam.FieldOfView = Config.Camera.FieldOfView - fovPunch
end

function CameraController.start()
	if started then
		return
	end
	started = true
	RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Camera.Value + 1, step)
end

return CameraController
