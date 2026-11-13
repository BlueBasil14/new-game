--!strict
-- Client boot. Order matters: state first, then world rendering, then UI on top.
-- Modules index ReplicatedStorage.Shared children directly; make sure initial replication is done.
if not game:IsLoaded() then
	game.Loaded:Wait()
end
local client = script.Parent
local controllers = client:WaitForChild("controllers")

local ClientState = require(client:WaitForChild("ClientState"))
local UiKit = require(client:WaitForChild("ui"):WaitForChild("UiKit"))
local CameraController = require(controllers:WaitForChild("CameraController"))
local InputController = require(controllers:WaitForChild("InputController"))
local ArenaClient = require(controllers:WaitForChild("ArenaClient"))
local TurfRenderer = require(controllers:WaitForChild("TurfRenderer"))
local FeedbackController = require(controllers:WaitForChild("FeedbackController"))
local HudController = require(controllers:WaitForChild("HudController"))
local PanelController = require(controllers:WaitForChild("PanelController"))
local TutorialController = require(controllers:WaitForChild("TutorialController"))

local PANEL_SOUNDS: { [string]: string } = {
	click = "uiClick",
	buy = "purchase",
	error = "uiError",
	reward = "rewardClaim",
}

local function boot(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if not ok then
		warn(`[Client] {name} failed to start: {err}`)
	end
end

UiKit.onClickSound = function()
	FeedbackController.play("uiClick")
end
UiKit.onHoverSound = function()
	FeedbackController.play("uiHover")
end
PanelController.onSound = function(name: string)
	if name == "click" then
		return -- every UiKit.button already plays uiClick via UiKit.onClickSound
	end
	FeedbackController.play(PANEL_SOUNDS[name] or name)
end
FeedbackController.onToast = function(text: string, kind: string)
	local color: Color3? = if kind == "good"
		then UiKit.theme.Success
		elseif kind == "bad" then UiKit.theme.Danger
		else nil
	UiKit.toast(text, color)
end

local lastLowDetail: boolean? = nil
ClientState.profileChanged:Connect(function(profile)
	if profile == nil then
		return
	end
	local low = profile.settings.lowDetail
	if low ~= lastLowDetail then
		lastLowDetail = low
		TurfRenderer.setLowDetail(low)
	end
end)

boot("ClientState", ClientState.start)
boot("Camera", CameraController.start)
boot("Input", InputController.start)
boot("Arena", ArenaClient.start)
boot("Feedback", FeedbackController.start)
boot("Hud", HudController.start)
boot("Panels", PanelController.start)
boot("Tutorial", TutorialController.start)

-- Studio-only test hook: automated playtests cannot click UI reliably under the device emulator.
-- script.Debug:Fire("open", "Shop") / ("close") / ("cut") / ("waveTime", "4")
if game:GetService("RunService"):IsStudio() then
	local debugEvent = Instance.new("BindableEvent")
	debugEvent.Name = "Debug"
	debugEvent.Event:Connect(function(action: string, arg: string?)
		if action == "open" and arg then
			PanelController.open(arg)
		elseif action == "close" then
			PanelController.close()
		elseif action == "cut" then
			-- Replays the local "I cut someone" feedback (hit-stop, punch, cubes); nothing reaches the server.
			local myId = ClientState.arena.myId
			for id in ClientState.arena.runners do
				if myId and id ~= myId then
					ClientState.arenaEvent:Fire({ kind = "cut", killer = myId, victim = id, victimCells = 0, victimWasKing = false })
					break
				end
			end
		elseif action == "waveTime" and arg then
			-- Slows the claim wave so a screenshot can catch it.
			local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config")) :: any
			Config.ClaimFx.WaveTime = tonumber(arg) or Config.ClaimFx.WaveTime
		end
	end)
	debugEvent.Parent = script
end
