--!strict
-- Client boot. Order matters: state first, then world rendering, then UI on top.
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
PanelController.onSound = function(name: string)
	FeedbackController.play(PANEL_SOUNDS[name] or name)
end
FeedbackController.onToast = function(text: string, kind: string)
	local color = if kind == "good"
		then UiKit.theme.Success
		elseif kind == "bad" then UiKit.theme.Danger
		else nil
	UiKit.toast(text, if color then UiKit.color(color) else nil)
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
