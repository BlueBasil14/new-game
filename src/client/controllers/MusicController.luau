--!strict
-- Background music: shuffles the RBLX Essentials tracks (SoundService.RBLXEssentials.SoundSystem.Music) with no UI.
-- Respects profile.settings.music. Skipping is a game pass perk (session.passes.skipMusic): keybind here,
-- the HUD button calls MusicController.canSkip() / MusicController.skip().
local ContextActionService = game:GetService("ContextActionService")
local SoundService = game:GetService("SoundService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local ClientState = require(script.Parent.Parent.ClientState)

local MusicController = {}

local ACTION = "MusicSkip"
local tracks: { Sound } = {}
local current: Sound? = nil
local lastIndex = 0
local generation = 0 -- bumps on every track change so a stale Ended/timeout does nothing
local bound = false

local function musicOn(): boolean
	local profile = ClientState.profile
	return profile ~= nil and profile.settings.music
end

function MusicController.canSkip(): boolean
	return ClientState.session.passes.skipMusic == true and musicOn() and #tracks > 1
end

local function playNext()
	local snd = current
	if snd then
		snd:Stop()
	end
	current = nil
	generation += 1
	if #tracks == 0 or not musicOn() then
		return
	end
	local i = math.random(#tracks)
	if i == lastIndex and #tracks > 1 then
		i = i % #tracks + 1 -- never the same track twice in a row
	end
	lastIndex = i
	local nextSound = tracks[i]
	current = nextSound
	nextSound.TimePosition = 0
	nextSound:Play()
	-- A track that never loads (moderated or permission-blocked asset) would stall the playlist.
	local gen = generation
	task.delay(Config.Music.LoadTimeout, function()
		if gen == generation and not nextSound.IsLoaded then
			warn(`[Music] "{nextSound.Name}" did not load; skipping`)
			playNext()
		end
	end)
end

function MusicController.skip()
	if MusicController.canSkip() then
		playNext()
	end
end

local function onSkipAction(_name: string, state: Enum.UserInputState, _input: InputObject): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		MusicController.skip()
	end
	return Enum.ContextActionResult.Pass
end

local function refresh()
	local snd = current
	if musicOn() then
		if snd == nil then
			playNext()
		end
	elseif snd then
		snd:Stop()
		current = nil
		generation += 1
	end
	local owner = ClientState.session.passes.skipMusic == true
	if owner ~= bound then
		bound = owner
		if owner then
			ContextActionService:BindAction(ACTION, onSkipAction, false, (Enum.KeyCode :: any)[Config.Music.SkipKey])
		else
			ContextActionService:UnbindAction(ACTION)
		end
	end
end

local function setup()
	local root = SoundService:WaitForChild("RBLXEssentials", 10)
	local system = root and root:WaitForChild("SoundSystem", 10)
	local group = system and system:WaitForChild("Music", 10)
	if group == nil then
		warn("[Music] SoundService.RBLXEssentials.SoundSystem.Music not found; no background music")
		return
	end
	for _, child in group:GetChildren() do
		if child:IsA("Sound") then
			table.insert(tracks, child)
		end
	end
	for _, snd in tracks do
		snd.Looped = false
		snd.Volume *= Config.Music.Volume
		-- The pack's Kernel assigned SoundGroups at runtime; it is no longer installed.
		if group:IsA("SoundGroup") then
			snd.SoundGroup = group
		end
		snd.Ended:Connect(function()
			if snd == current then
				playNext()
			end
		end)
	end
	ClientState.profileChanged:Connect(refresh)
	refresh()
end

function MusicController.start()
	task.spawn(setup) -- waits for the SoundService pack folder without holding up the other controllers
end

return MusicController
