--!strict
-- Wordless first-run tutorial: loop guide, cut hint, then the first upgrade pointer.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local ClientState = require(script.Parent.Parent.ClientState)
local UiKit = require(script.Parent.Parent.ui.UiKit)
local ArenaClient = require(script.Parent.ArenaClient)

local TutorialController = {}

local DOT_COUNT = 12
local DOT_STEP = 0.15
local DOT_SIZE = 1.2
local DOT_SIZE_ACTIVE = 2
local REPLACE_EVERY = 4
local CUT_TIMEOUT = 60
local CUT_POLL = 0.25
local UPGRADE_TIMEOUT = 45
local POLL = 0.2
-- Three legs in cells: +X 5, +Z 4, -X 5; four dots per leg.
local LEGS = { Vector2.new(5, 0), Vector2.new(0, 4), Vector2.new(-5, 0) }

local function getRoot(): BasePart?
	local character = Players.LocalPlayer.Character
	if character == nil then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function guidePath(origin: Vector3): { Vector3 }
	local cellSize = Config.Arena.CellSize
	local points: { Vector3 } = {}
	local cursor = Vector3.new(origin.X, 1, origin.Z)
	for _, leg in LEGS do
		local step = Vector3.new(leg.X * cellSize, 0, leg.Y * cellSize)
		for j = 0, 3 do
			table.insert(points, cursor + step * (j / 4))
		end
		cursor += step
	end
	return points
end

local function runGuide()
	local folder = Instance.new("Folder")
	folder.Name = "TutorialGuide"
	local dots: { BasePart } = {}
	for _ = 1, DOT_COUNT do
		local dot = Instance.new("Part")
		dot.Shape = Enum.PartType.Ball
		dot.Size = Vector3.new(DOT_SIZE, DOT_SIZE, DOT_SIZE)
		dot.Material = Enum.Material.Neon
		dot.Color = Color3.new(1, 1, 1)
		dot.Anchored = true
		dot.CanCollide = false
		dot.CanQuery = false
		dot.CanTouch = false
		dot.CastShadow = false
		dot.Parent = folder
		table.insert(dots, dot)
	end
	-- Parented on first placement so the dots do not sit stacked at the origin before a character exists.

	local claimed = false
	local claimConn = ClientState.arenaEvent:Connect(function(event: any)
		if event.kind == "claim" and event.id == ClientState.arena.myId then
			claimed = true
		end
	end)

	local current = 0
	local lastPlaced = -math.huge
	while not claimed do
		local root = getRoot()
		local myId = ClientState.arena.myId
		local trail = if myId then ArenaClient.trails[myId] else nil
		local hasTrail = trail ~= nil and #trail > 0
		if root ~= nil and not hasTrail and os.clock() - lastPlaced >= REPLACE_EVERY then
			lastPlaced = os.clock()
			local points = guidePath(root.Position)
			for i, dot in dots do
				dot.Position = points[i]
			end
			if folder.Parent == nil then
				folder.Parent = workspace
			end
		end

		local prev = current
		current = current % DOT_COUNT + 1
		if prev > 0 then
			dots[prev].Size = Vector3.new(DOT_SIZE, DOT_SIZE, DOT_SIZE)
		end
		dots[current].Size = Vector3.new(DOT_SIZE_ACTIVE, DOT_SIZE_ACTIVE, DOT_SIZE_ACTIVE)
		task.wait(DOT_STEP)
	end

	claimConn:Disconnect()
	folder:Destroy()
end

local function nearestEnemyCell(grid: any, origin: Vector3, myId: number?): Vector3?
	local best: Vector3? = nil
	local bestDist = math.huge
	for id, trail in ArenaClient.trails do
		if id ~= myId and #trail > 0 then
			local x, y = grid:fromIndex(trail[#trail])
			local wx, wz = grid:cellToWorld(x, y)
			local d = Vector3.new(wx - origin.X, 0, wz - origin.Z).Magnitude
			if d < bestDist then
				bestDist = d
				best = Vector3.new(wx, 1, wz)
			end
		end
	end
	return best
end

local function runCutHint()
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.new(1, 1, 1)
	part.Position = Vector3.new(0, 1, 0)

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(60, 60)
	billboard.AlwaysOnTop = true
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.Enabled = false
	billboard.Parent = part
	UiKit.label({
		Text = "✂",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		Parent = billboard,
	})
	part.Parent = workspace

	local cut = false
	local cutConn = ClientState.arenaEvent:Connect(function(event: any)
		if event.kind == "cut" and event.killer == ClientState.arena.myId then
			cut = true
		end
	end)

	local deadline = os.clock() + CUT_TIMEOUT
	while not cut and os.clock() < deadline do
		local root = getRoot()
		local grid = ArenaClient.getGrid()
		if root ~= nil and grid ~= nil then
			local target = nearestEnemyCell(grid, root.Position, ClientState.arena.myId)
			if target then
				part.Position = target
				billboard.Enabled = true
			else
				billboard.Enabled = false
			end
		end
		task.wait(CUT_POLL)
	end

	cutConn:Disconnect()
	part:Destroy()
end

local function canBuyCoinBoost(): boolean
	local profile = ClientState.profile
	if profile == nil then
		return false
	end
	return profile.coins >= Config.Upgrades.coinBoost.Base or profile.upgrades.coinBoost > 0
end

local function coinBoostLevel(): number
	local profile = ClientState.profile
	return if profile then profile.upgrades.coinBoost else 0
end

local function runUpgradeHint()
	while not canBuyCoinBoost() do
		task.wait(POLL)
	end

	local gui = UiKit.screenGui("Tutorial", 50)
	local arrow = UiKit.label({
		Text = "👆",
		Size = UDim2.fromScale(0.06, 0.1),
		Position = UDim2.fromScale(0.09, 0.3),
		BackgroundTransparency = 1,
		TextScaled = true,
		Parent = gui,
	})
	UiKit.pulse(arrow)

	local deadline = os.clock() + UPGRADE_TIMEOUT
	while coinBoostLevel() <= 0 and os.clock() < deadline do
		task.wait(POLL)
	end

	UiKit.stopPulse(arrow)
	gui:Destroy()
end

function TutorialController.start()
	task.spawn(function()
		local profile = ClientState.profile
		while profile == nil do
			task.wait(POLL)
			profile = ClientState.profile
		end
		if profile.tutorialDone then
			return
		end

		runGuide()
		runCutHint()
		runUpgradeHint()

		task.spawn(function()
			ClientState.request("TutorialDone")
		end)
	end)
end

return TutorialController
