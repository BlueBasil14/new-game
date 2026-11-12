--!strict
-- Non-UI game feel from GDD G6: trail danger, claim/cut/death/king/spawn feedback and SFX.
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local SoundIds = require(Shared.SoundIds)
local Types = require(Shared.Types)
local ClientState = require(script.Parent.Parent.ClientState)
local ArenaClient = require(script.Parent.ArenaClient)
local CameraController = require(script.Parent.CameraController)
local TurfRenderer = require(script.Parent.TurfRenderer)

local FeedbackController = {}

-- UI layers set this to show announcements (text, kind "info" | "good" | "bad").
FeedbackController.onToast = nil :: ((text: string, kind: string) -> ())?

local DANGER_INTERVAL = 0.2 -- 5 Hz
local HEARTBEAT_INTERVAL = 0.8
local VIGNETTE_WIDTH = 0.18
local VIGNETTE_MIN = 0.25
local VIGNETTE_MAX = 0.65
local VIGNETTE_HZ = 1.5
local POPUP_TIME = 0.9
local POPUP_RISE = 6
local POPUP_HEIGHT = 3
local REWARD_MATCH_WINDOW = 1.5
local SHAKE_MAX = 0.6
local SHAKE_TIME = 0.35
local PUNCH_FOV = 8 -- G6: FOV 70 -> 62 -> 70
local DESAT_HOLD = 0.3
local DESAT_RECOVER = 0.2
local POP_CELLS = 20
local POP_MAX = 12
local POP_STEP = 0.06
local POP_GAP = 0.05
local CONFETTI_COUNT = 60
local BEAM_HEIGHT = 40
local BEAM_WIDTH = 1.5
local BEAM_RESOLVE = 0.5
local SHIELD_SIZE = 7
local SOUND_POOL = 4

local CONFETTI_MIN_CELLS = Config.Income.CaptureBonus[1].MinCells
local SHAKE_FULL_CELLS = Config.Income.CaptureBonus[#Config.Income.CaptureBonus].MinCells
local FLOOR = Config.Arena.FloorY
local DANGER_COLOR = Color3.fromHex(Config.Colors.Danger)
local COIN_COLOR = Color3.fromHex(Config.Colors.Yellow)
local GEM_COLOR = Color3.fromHex(Config.Colors.Gem)
local STROKE_COLOR = Color3.fromHex(Config.Colors.UiDark)

type Preset = {
	count: number,
	speed: NumberRange,
	lifetime: NumberRange,
	size: NumberSequence,
	transparency: NumberSequence,
	spread: Vector2,
	accel: Vector3,
	drag: number,
	light: number,
	rot: NumberRange,
	shape: Enum.ParticleEmitterShape,
}

-- Capture-effect cosmetics keyed by Catalog effect id; shapes differ by motion, not texture.
local PRESETS: { [string]: Preset } = {
	sparkle = {
		count = 30,
		speed = NumberRange.new(4, 10),
		lifetime = NumberRange.new(0.4, 0.8),
		size = NumberSequence.new(0.6, 0),
		transparency = NumberSequence.new(0, 0.6),
		spread = Vector2.new(180, 180),
		accel = Vector3.new(0, 2, 0),
		drag = 3,
		light = 1,
		rot = NumberRange.new(-180, 180),
		shape = Enum.ParticleEmitterShape.Sphere,
	},
	fireworks = {
		count = 50,
		speed = NumberRange.new(25, 35),
		lifetime = NumberRange.new(0.8, 1.2),
		size = NumberSequence.new(0.5, 0.1),
		transparency = NumberSequence.new(0, 1),
		spread = Vector2.new(60, 60),
		accel = Vector3.new(0, -30, 0),
		drag = 2,
		light = 1,
		rot = NumberRange.new(0, 0),
		shape = Enum.ParticleEmitterShape.Box,
	},
	bubbles = {
		count = 20,
		speed = NumberRange.new(2, 5),
		lifetime = NumberRange.new(1.5, 2.5),
		size = NumberSequence.new(0.8, 1.6),
		transparency = NumberSequence.new(0.3, 1),
		spread = Vector2.new(180, 180),
		accel = Vector3.new(0, 6, 0),
		drag = 1,
		light = 0.2,
		rot = NumberRange.new(0, 0),
		shape = Enum.ParticleEmitterShape.Sphere,
	},
	lightning = {
		count = 40,
		speed = NumberRange.new(40, 60),
		lifetime = NumberRange.new(0.15, 0.3),
		size = NumberSequence.new(0.4, 0),
		transparency = NumberSequence.new(0, 0.2),
		spread = Vector2.new(180, 180),
		accel = Vector3.zero,
		drag = 0,
		light = 1,
		rot = NumberRange.new(0, 0),
		shape = Enum.ParticleEmitterShape.Box,
	},
	hearts = {
		count = 24,
		speed = NumberRange.new(6, 10),
		lifetime = NumberRange.new(1, 1.6),
		size = NumberSequence.new(1.2, 0.4),
		transparency = NumberSequence.new(0, 1),
		spread = Vector2.new(35, 35),
		accel = Vector3.new(0, 4, 0),
		drag = 2,
		light = 0.5,
		rot = NumberRange.new(-30, 30),
		shape = Enum.ParticleEmitterShape.Box,
	},
}

local CONFETTI_COLORS = { 1, 3, 7, 11 } -- indices into Config.Colors.Players

local started = false
local effectsFolder: Folder? = nil
local vignetteEdges: { Frame } = {}
local colorCorrection: ColorCorrectionEffect? = nil
local beam: BasePart? = nil

local soundPools: { [string]: { Sound } } = {}
local soundNext: { [string]: number } = {}

local dangerAcc = 0
local dangerOn = false
local dangerId: number? = nil
local nextBeat = 0
local lastTrailLen = 0
local lastCutAt = -math.huge
local lastDesatAt = -math.huge

local kingTarget: PVInstance? = nil
local kingResolveAt = 0
type Shield = { part: BasePart, ends: number }
local shields: { [number]: Shield } = {}

local function settings(): { music: boolean, sfx: boolean, shake: boolean, lowDetail: boolean }?
	local profile = ClientState.profile
	return if profile then profile.settings else nil
end

function FeedbackController.play(name: string, pitch: number?)
	local id = SoundIds[name]
	if not id or id == 0 then
		return
	end
	local s = settings()
	if s and not s.sfx then
		return
	end
	local pool = soundPools[name]
	if not pool then
		pool = {}
		soundPools[name] = pool
	end
	local k = (soundNext[name] or 0) % SOUND_POOL + 1
	soundNext[name] = k
	local list = pool :: { Sound }
	local snd = list[k]
	if not snd then
		local created = Instance.new("Sound")
		created.Name = name
		created.SoundId = "rbxassetid://" .. id
		created.Parent = SoundService
		list[k] = created
		snd = created
	end
	snd.PlaybackSpeed = pitch or 1
	snd.TimePosition = 0
	snd:Play()
end

local function runnerInstance(id: number): PVInstance?
	local info = ClientState.arena.runners[id]
	if not info then
		return nil
	end
	if info.isBot then
		local bots = workspace:FindFirstChild("Bots")
		local rig = bots and bots:FindFirstChild(tostring(id))
		if rig and rig:IsA("PVInstance") then
			return rig
		end
		return nil
	end
	local player = Players:GetPlayerByUserId(info.userId)
	local char = player and player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function cellWorld(cx: number, cy: number, height: number): Vector3?
	local g = ArenaClient.getGrid()
	if not g then
		return nil
	end
	local wx, wz = g:cellToWorld(cx, cy)
	return Vector3.new(wx, FLOOR + height, wz)
end

local function tempAnchor(pos: Vector3, lifetime: number): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.CFrame = CFrame.new(pos)
	p.Parent = effectsFolder
	Debris:AddItem(p, lifetime)
	return p
end

local function popup(pos: Vector3, text: string, color: Color3)
	local anchor = tempAnchor(pos, POPUP_TIME + 0.1)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(160, 56)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Adornee = anchor
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeColor3 = STROKE_COLOR
	label.TextStrokeTransparency = 0
	label.Parent = bb
	bb.Parent = anchor
	TweenService:Create(anchor, TweenInfo.new(POPUP_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = anchor.CFrame + Vector3.new(0, POPUP_RISE, 0),
	}):Play()
	TweenService:Create(label, TweenInfo.new(POPUP_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
end

local function configureEmitter(pe: ParticleEmitter, preset: Preset, color: ColorSequence)
	pe.Enabled = false
	pe.Rate = 0
	pe.Color = color
	pe.Speed = preset.speed
	pe.Lifetime = preset.lifetime
	pe.Size = preset.size
	pe.Transparency = preset.transparency
	pe.SpreadAngle = preset.spread
	pe.Acceleration = preset.accel
	pe.Drag = preset.drag
	pe.LightEmission = preset.light
	pe.Rotation = preset.rot
	pe.RotSpeed = preset.rot
	pe.Shape = preset.shape
	pe.EmissionDirection = Enum.NormalId.Top
end

local function lowDetail(): boolean
	local s = settings()
	return s ~= nil and s.lowDetail
end

local function burst(pos: Vector3, effectId: string)
	local preset = PRESETS[effectId] or PRESETS.sparkle
	local item = Catalog.byId(effectId)
	local a = if item then Color3.fromHex(item.colorA) else COIN_COLOR
	local b = if item and item.colorB then Color3.fromHex(item.colorB) else a
	local anchor = tempAnchor(pos, preset.lifetime.Max + 0.5)
	local pe = Instance.new("ParticleEmitter")
	configureEmitter(pe, preset, ColorSequence.new(a, b))
	pe.Parent = anchor
	local n = if lowDetail() then preset.count // 2 else preset.count
	pe:Emit(n)
end

local confettiPreset: Preset = {
	count = CONFETTI_COUNT,
	speed = NumberRange.new(20, 30),
	lifetime = NumberRange.new(1.2, 1.8),
	size = NumberSequence.new(0.5, 0.4),
	transparency = NumberSequence.new(0, 0.8),
	spread = Vector2.new(50, 50),
	accel = Vector3.new(0, -25, 0),
	drag = 1.5,
	light = 0,
	rot = NumberRange.new(-360, 360),
	shape = Enum.ParticleEmitterShape.Box,
}

local function confetti(pos: Vector3)
	local anchor = tempAnchor(pos, confettiPreset.lifetime.Max + 0.5)
	local per = (if lowDetail() then CONFETTI_COUNT // 2 else CONFETTI_COUNT) // #CONFETTI_COLORS
	for _, idx in CONFETTI_COLORS do
		local pe = Instance.new("ParticleEmitter")
		configureEmitter(pe, confettiPreset, ColorSequence.new(Color3.fromHex(Config.Colors.Players[idx])))
		pe.Parent = anchor
		pe:Emit(per)
	end
end

local function myRootPosition(): Vector3?
	local char = Players.LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return nil
end

local function desaturate()
	local cc = colorCorrection
	local now = os.clock()
	if not cc or now - lastDesatAt < DESAT_HOLD + DESAT_RECOVER then
		return
	end
	lastDesatAt = now
	cc.Saturation = -1
	cc.Enabled = true
	task.delay(DESAT_HOLD, function()
		local tween = TweenService:Create(cc, TweenInfo.new(DESAT_RECOVER), { Saturation = 0 })
		tween.Completed:Connect(function(state)
			if state == Enum.PlaybackState.Completed and cc.Saturation > -0.01 then
				cc.Enabled = false
			end
		end)
		tween:Play()
	end)
end

local function setDanger(on: boolean, id: number?)
	if on == dangerOn and id == dangerId then
		return
	end
	if dangerId then
		TurfRenderer.setTrailDanger(dangerId, false)
	end
	dangerOn = on and id ~= nil
	dangerId = if dangerOn then id else nil
	if dangerOn then
		TurfRenderer.setTrailDanger(id :: number, true)
		nextBeat = 0
	end
	for _, f in vignetteEdges do
		f.Visible = dangerOn
	end
end

local function checkDanger()
	local arena = ClientState.arena
	local myId = arena.myId
	local g = ArenaClient.getGrid()
	local trail = if myId then ArenaClient.trails[myId] else nil
	local n = if trail then #trail else 0
	if n > 0 and lastTrailLen == 0 and arena.alive then
		FeedbackController.play("trailStart")
	end
	lastTrailLen = n
	if not (g and myId and trail and arena.alive and n > 0) then
		setDanger(false, nil)
		return
	end
	local size = g.size
	local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
	for _, i in trail do
		local x, y = i % size, i // size
		minX, maxX = math.min(minX, x), math.max(maxX, x)
		minY, maxY = math.min(minY, y), math.max(maxY, y)
	end
	local r = Config.Arena.TrailDangerRadius
	local r2 = r * r
	local now = os.clock()
	local found = false
	for id in arena.runners do
		if id ~= myId and ArenaClient.alive[id] and (ArenaClient.shieldEnds[id] or 0) <= now then
			local inst = runnerInstance(id)
			if inst then
				local pos = inst:GetPivot().Position
				local px, py = g:worldToCell(pos.X, pos.Z)
				if px >= minX - r and px <= maxX + r and py >= minY - r and py <= maxY + r then
					for _, i in trail do
						local dx, dy = i % size - px, i // size - py
						if dx * dx + dy * dy <= r2 then
							found = true
							break
						end
					end
				end
			end
		end
		if found then
			break
		end
	end
	setDanger(found, myId)
end

local function onClaim(ev: { id: number, cells: number, neutral: number, stolen: number, cx: number, cy: number })
	local cells = ev.cells
	local steps = math.clamp(math.ceil(cells / POP_CELLS), 1, POP_MAX)
	for k = 0, steps - 1 do
		task.delay(k * POP_GAP, FeedbackController.play, "claimPop", 1 + POP_STEP * k)
	end
	if ev.stolen > 0 then
		FeedbackController.play("stealCrunch")
	end
	local s = settings()
	if s and s.shake then
		CameraController.shake(SHAKE_MAX * math.clamp(cells / SHAKE_FULL_CELLS, 0, 1), SHAKE_TIME)
	end
	local pos = cellWorld(ev.cx, ev.cy, 1)
	if not pos then
		return
	end
	if cells >= CONFETTI_MIN_CELLS then
		FeedbackController.play("bigClaim")
		confetti(pos)
	end
	local info = ClientState.arena.runners[ev.id]
	burst(pos, if info then info.effect else "sparkle")
end

local function runnerName(id: number): string
	local info = ClientState.arena.runners[id]
	return if info then info.name else "?"
end

local function onSpawn(info: Types.RunnerInfo)
	local id = info.id
	if id == ClientState.arena.myId then
		FeedbackController.play("respawnWhoosh")
	end
	local old = shields[id]
	if old then
		old.part:Destroy()
		shields[id] = nil
	end
	if info.isBot then
		return
	end
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(SHIELD_SIZE, SHIELD_SIZE, SHIELD_SIZE)
	p.Material = Enum.Material.ForceField
	p.Color = GEM_COLOR
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	shields[id] = { part = p, ends = ArenaClient.shieldEnds[id] or os.clock() }
end

local function onEvent(ev: Types.ArenaEvent)
	local arena = ClientState.arena
	local myId = arena.myId
	if ev.kind == "claim" then
		if ev.id == myId then
			onClaim(ev)
		end
	elseif ev.kind == "cut" then
		if ev.killer == myId then
			lastCutAt = os.clock()
			CameraController.punch(PUNCH_FOV)
			FeedbackController.play("snip")
		end
		if ev.victim == myId then
			FeedbackController.play("deathPop")
			desaturate()
		end
	elseif ev.kind == "king" then
		kingTarget = nil
		kingResolveAt = 0
		if ev.id ~= 0 then
			FeedbackController.play("crownFanfare")
			local toast = FeedbackController.onToast
			if toast then
				toast(if ev.id == myId then "You are the King!" else runnerName(ev.id) .. " is the King!", "good")
			end
		end
	elseif ev.kind == "fullMap" then
		local toast = FeedbackController.onToast
		if toast then
			toast(runnerName(ev.id) .. " captured the whole map!", "good")
		end
	elseif ev.kind == "spawn" then
		onSpawn(ev.runner)
	elseif ev.kind == "despawn" then
		local sh = shields[ev.id]
		if sh then
			sh.part:Destroy()
			shields[ev.id] = nil
		end
	end
end

local function onReward(payload: { coins: number?, gems: number?, reason: string, cx: number?, cy: number? })
	local coins, gems = payload.coins, payload.gems
	local text: string, color: Color3
	if coins and coins > 0 then
		text, color = "+" .. math.floor(coins), COIN_COLOR
	elseif gems and gems > 0 then
		text, color = "+" .. math.floor(gems) .. " gems", GEM_COLOR
	else
		return
	end
	local pos: Vector3? = nil
	local cx, cy = payload.cx, payload.cy
	if cx and cy then
		pos = cellWorld(cx, cy, POPUP_HEIGHT)
	elseif os.clock() - lastCutAt < REWARD_MATCH_WINDOW then
		local root = myRootPosition()
		pos = if root then root + Vector3.new(0, POPUP_HEIGHT, 0) else nil
	end
	if pos then
		popup(pos, text, color)
	end
end

local function step(dt: number)
	local now = os.clock()
	dangerAcc += dt
	if dangerAcc >= DANGER_INTERVAL then
		dangerAcc = 0
		checkDanger()
	end

	if dangerOn then
		local t = 0.5 + 0.5 * math.sin(now * VIGNETTE_HZ * 2 * math.pi)
		local transparency = VIGNETTE_MIN + (VIGNETTE_MAX - VIGNETTE_MIN) * t
		for _, f in vignetteEdges do
			f.BackgroundTransparency = transparency
		end
		if now >= nextBeat then
			nextBeat = now + HEARTBEAT_INTERVAL
			FeedbackController.play("heartbeat")
		end
	end

	local b = beam
	if b then
		local kingId = ClientState.arena.kingId
		if kingId ~= 0 and now >= kingResolveAt then
			kingResolveAt = now + BEAM_RESOLVE
			kingTarget = runnerInstance(kingId)
		end
		local target = if kingId ~= 0 then kingTarget else nil
		if target and target.Parent then
			b.CFrame = CFrame.new(target:GetPivot().Position + Vector3.new(0, BEAM_HEIGHT * 0.5 + 3, 0))
			if b.Parent ~= effectsFolder then
				b.Parent = effectsFolder
			end
		elseif b.Parent then
			b.Parent = nil
		end
	end

	for id, sh in shields do
		local inst = if now < sh.ends then runnerInstance(id) else nil
		if now >= sh.ends then
			sh.part:Destroy()
			shields[id] = nil
		elseif inst then
			sh.part.CFrame = inst:GetPivot()
			if sh.part.Parent ~= effectsFolder then
				sh.part.Parent = effectsFolder
			end
		end
	end
end

local function buildVignette()
	local gui = Instance.new("ScreenGui")
	gui.Name = "FeedbackVignette"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = -10
	local w = VIGNETTE_WIDTH
	-- UIGradient rotation picks which edge is opaque: 0 left, 180 right, 90 top, -90 bottom.
	local edges = {
		{ UDim2.fromScale(0, 0), UDim2.fromScale(w, 1), 0 },
		{ UDim2.fromScale(1 - w, 0), UDim2.fromScale(w, 1), 180 },
		{ UDim2.fromScale(0, 0), UDim2.fromScale(1, w), 90 },
		{ UDim2.fromScale(0, 1 - w), UDim2.fromScale(1, w), -90 },
	}
	for _, e in edges do
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = DANGER_COLOR
		f.BackgroundTransparency = VIGNETTE_MIN
		f.Position = e[1] :: UDim2
		f.Size = e[2] :: UDim2
		f.Visible = false
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = e[3] :: number
		gradient.Transparency = NumberSequence.new(0, 1)
		gradient.Parent = f
		f.Parent = gui
		table.insert(vignetteEdges, f)
	end
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

function FeedbackController.start()
	if started then
		return
	end
	started = true

	local folder = Instance.new("Folder")
	folder.Name = "Feedback"
	folder.Parent = workspace
	effectsFolder = folder

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "DeathDesaturate"
	cc.Enabled = false
	cc.Parent = Lighting
	colorCorrection = cc

	local b = Instance.new("Part")
	b.Name = "KingBeam"
	b.Anchored = true
	b.CanCollide = false
	b.CanTouch = false
	b.CanQuery = false
	b.CastShadow = false
	b.Material = Enum.Material.Neon
	b.Color = COIN_COLOR
	b.Transparency = 0.35
	b.Size = Vector3.new(BEAM_WIDTH, BEAM_HEIGHT, BEAM_WIDTH)
	beam = b

	task.spawn(buildVignette)

	local function readSettings()
		local s = settings()
		if s then
			CameraController.shakeEnabled = s.shake
		end
	end
	ClientState.profileChanged:Connect(readSettings)
	readSettings()

	ClientState.arenaEvent:Connect(onEvent)
	ClientState.reward:Connect(onReward)
	ClientState.death:Connect(desaturate)
	RunService.Heartbeat:Connect(step)
end

return FeedbackController
