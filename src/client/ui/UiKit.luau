--!strict
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local ArcadeIcons = require(Shared.ArcadeIcons)

local UiKit = {}

UiKit.onClickSound = nil :: (() -> ())?
UiKit.onHoverSound = nil :: (() -> ())?

function UiKit.color(hex: string): Color3
	return Color3.fromHex(hex)
end

local theme: { [string]: any } = {}
for k, v in Config.Colors do
	if type(v) == "string" then
		theme[k] = Color3.fromHex(v)
	end
end
UiKit.theme = theme

local FONT = Enum.Font.GothamBold
local PANEL_ICONS: { [string]: string } = {
	Upgrades = "core_upgrades",
	Shop = "core_shop",
	["Daily Reward"] = "core_daily",
	["Daily Quests"] = "core_quests",
	Rebirth = "core_rebirth",
	Codes = "core_codes",
	Settings = "core_settings",
	Eliminated = "economy_heart",
	["Starter Pack"] = "economy_reward_chest",
}

function UiKit.screenGui(name: string, displayOrder: number?): ScreenGui
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local existing = pg:FindFirstChild(name)
	if existing and existing:IsA("ScreenGui") then
		return existing
	end
	local g = Instance.new("ScreenGui")
	g.Name = name
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.DisplayOrder = displayOrder or 0
	g.Parent = pg
	return g
end

local function applyProps(inst: Instance, props: { [string]: any }?)
	if props then
		for k, v in props do
			if k ~= "parent" then
				(inst :: any)[k] = v
			end
		end
		if props.parent then
			inst.Parent = props.parent
		end
	end
end

-- One registry for the original icon pack; decorative images never intercept input.
function UiKit.icon(key: string, props: { [string]: any }?): ImageLabel
	local image = Instance.new("ImageLabel")
	image.Name = key
	image.BackgroundTransparency = 1
	image.BorderSizePixel = 0
	image.ScaleType = Enum.ScaleType.Fit
	image.Image = assert(ArcadeIcons[key], "Unknown Arcade Commons icon: " .. key)
	if props and props.parent and props.parent:IsA("GuiObject") then
		image.ZIndex = props.parent.ZIndex + 1
	end
	applyProps(image, props)
	return image
end

function UiKit.frame(props: { [string]: any }?): Frame
	local f = Instance.new("Frame")
	f.BackgroundColor3 = theme.UiDark
	f.BorderSizePixel = 0
	applyProps(f, props)
	return f
end

function UiKit.label(props: { [string]: any }?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.TextColor3 = theme.UiLight
	l.TextScaled = true
	l.BorderSizePixel = 0
	applyProps(l, props)
	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = 48
	c.MinTextSize = 8
	c.Parent = l
	return l
end

function UiKit.corner(inst: Instance, radius: number?): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = inst
	return c
end

function UiKit.stroke(inst: Instance, color: Color3?, thickness: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color or theme.UiLight
	s.Thickness = thickness or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

function UiKit.padding(inst: Instance, scale: number?): UIPadding
	local p = Instance.new("UIPadding")
	local u = UDim.new(scale or 0.04, 0)
	p.PaddingTop, p.PaddingBottom, p.PaddingLeft, p.PaddingRight = u, u, u, u
	p.Parent = inst
	return p
end

function UiKit.list(inst: Instance, props: { [string]: any }?): UIListLayout
	local l = Instance.new("UIListLayout")
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Padding = UDim.new(0.02, 0)
	applyProps(l, props)
	l.Parent = inst
	return l
end

function UiKit.grid(inst: Instance, props: { [string]: any }?): UIGridLayout
	local g = Instance.new("UIGridLayout")
	g.SortOrder = Enum.SortOrder.LayoutOrder
	applyProps(g, props)
	g.Parent = inst
	return g
end

function UiKit.aspect(inst: Instance, ratio: number): UIAspectRatioConstraint
	local a = Instance.new("UIAspectRatioConstraint")
	a.AspectRatio = ratio
	a.Parent = inst
	return a
end

local function tween(inst: Instance, time: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween
	local t = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), goal)
	t:Play()
	return t
end

function UiKit.button(props: {
	text: string?,
	color: Color3?,
	size: UDim2?,
	position: UDim2?,
	parent: Instance?,
	onClick: (() -> ())?,
}): TextButton
	local b = Instance.new("TextButton")
	b.Name = "Button"
	b.AutoButtonColor = false
	b.BackgroundColor3 = props.color or theme.Yellow
	b.BorderSizePixel = 0
	b.Font = FONT
	b.Text = props.text or ""
	b.TextColor3 = theme.UiDark
	b.TextScaled = true
	b.Size = props.size or UDim2.fromScale(0.3, 0.1)
	b.Position = props.position or UDim2.new()
	UiKit.corner(b, 12)
	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = 36
	c.MinTextSize = 8
	c.Parent = b
	local scale = Instance.new("UIScale")
	scale.Name = "ButtonScale"
	scale.Parent = b
	b.Parent = props.parent

	local hover, down = false, false
	local function refresh()
		local target = if down then 0.95 elseif hover then 1.05 else 1
		tween(scale, 0.1, { Scale = target })
	end
	b.MouseEnter:Connect(function()
		hover = true
		local hoverSnd = UiKit.onHoverSound
		if hoverSnd then
			hoverSnd()
		end
		refresh()
	end)
	b.MouseLeave:Connect(function()
		hover = false
		down = false
		refresh()
	end)
	b.MouseButton1Down:Connect(function()
		down = true
		refresh()
	end)
	b.MouseButton1Up:Connect(function()
		down = false
		refresh()
	end)
	b.Activated:Connect(function()
		local snd = UiKit.onClickSound
		if snd then
			snd()
		end
		if props.onClick then
			props.onClick()
		end
	end)
	return b
end

export type Panel = {
	root: Frame,
	body: Frame,
	closeButton: TextButton,
	dimmer: Frame,
	show: () -> (),
	hide: () -> (),
	isOpen: () -> boolean,
}

local panelGui: ScreenGui? = nil
local currentPanel: Panel? = nil

function UiKit.panel(props: { title: string?, size: UDim2?, parent: Instance? }): Panel
	if not panelGui then
		panelGui = UiKit.screenGui("Panels", 50)
	end
	local dimmer = UiKit.frame({
		Name = "Dimmer",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Active = true,
		Visible = false,
		parent = props.parent or panelGui,
	})
	local root = UiKit.frame({
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = props.size or UDim2.fromScale(0.6, 0.7),
		parent = dimmer,
	})
	UiKit.corner(root, 18)
	UiKit.stroke(root, theme.UiLight, 2)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(720, 560)
	limit.Parent = root
	local scale = Instance.new("UIScale")
	scale.Parent = root

	local bar = UiKit.frame({
		Name = "TitleBar",
		Size = UDim2.fromScale(1, 0.12),
		BackgroundColor3 = theme.Pink,
		parent = root,
	})
	UiKit.corner(bar, 18)
	UiKit.icon(PANEL_ICONS[props.title or ""] or "core_gift", {
		Name = "PanelIcon",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.025, 0.5),
		Size = UDim2.fromScale(0.09, 0.85),
		parent = bar,
	})
	UiKit.label({
		Name = "Title",
		Text = props.title or "",
		Size = UDim2.fromScale(0.66, 0.7),
		Position = UDim2.fromScale(0.15, 0.15),
		TextXAlignment = Enum.TextXAlignment.Left,
		parent = bar,
	})
	local closeBtn = UiKit.button({
		text = "X",
		color = theme.Danger,
		size = UDim2.fromScale(0.09, 0.7),
		position = UDim2.fromScale(0.89, 0.15),
		parent = bar,
	})
	closeBtn.Text = ""
	closeBtn.BackgroundTransparency = 1
	UiKit.icon("core_close", { Name = "CloseIcon", Size = UDim2.fromScale(1, 1), parent = closeBtn })
	UiKit.aspect(closeBtn, 1)

	local body = UiKit.frame({
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, 0.12),
		Size = UDim2.fromScale(1, 0.88),
		parent = root,
	})

	local open = false
	local panel: Panel
	local function hide()
		if not open then
			return
		end
		open = false
		dimmer.Visible = false
		if currentPanel == panel then
			currentPanel = nil
		end
	end
	local function show()
		if currentPanel and currentPanel ~= panel then
			currentPanel.hide()
		end
		currentPanel = panel
		open = true
		scale.Scale = 0.8
		dimmer.Visible = true
		tween(scale, 0.18, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end
	panel = {
		root = root,
		body = body,
		closeButton = closeBtn,
		dimmer = dimmer,
		show = show,
		hide = hide,
		isOpen = function()
			return open
		end,
	}
	closeBtn.Activated:Connect(hide)
	return panel
end

function UiKit.isPanelOpen(): boolean
	return currentPanel ~= nil
end

function UiKit.showPanel(panel: Panel)
	panel.show()
end

function UiKit.formatNumber(n: number): string
	local sign = if n < 0 then "-" else ""
	local a = math.abs(n)
	local function short(v: number, suffix: string): string
		local s = string.format("%.1f", v)
		s = string.gsub(s, "%.0$", "")
		return sign .. s .. suffix
	end
	if a >= 1e9 then
		return short(a / 1e9, "B")
	elseif a >= 1e6 then
		return short(a / 1e6, "M")
	elseif a >= 1e4 then
		return short(a / 1e3, "K")
	end
	local s = tostring(math.floor(a + 0.5))
	while true do
		local r, count = string.gsub(s, "^(%d+)(%d%d%d)", "%1,%2")
		s = r
		if count == 0 then
			break
		end
	end
	return sign .. s
end

local rollTokens: { [Instance]: number } = setmetatable({}, { __mode = "k" }) :: any

function UiKit.rollNumber(label: TextLabel, fromValue: number, toValue: number, seconds: number, formatFn: ((number) -> string)?)
	local fmt = formatFn or UiKit.formatNumber
	local token = (rollTokens[label] or 0) + 1
	rollTokens[label] = token
	if seconds <= 0 then
		label.Text = fmt(toValue)
		return
	end
	task.spawn(function()
		local t0 = os.clock()
		while rollTokens[label] == token and label.Parent do
			local a = math.min((os.clock() - t0) / seconds, 1)
			local eased = 1 - (1 - a) ^ 3
			label.Text = fmt(math.floor(fromValue + (toValue - fromValue) * eased + 0.5))
			if a >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end
		if rollTokens[label] == token then
			label.Text = fmt(toValue)
		end
	end)
end

local pulses: { [Instance]: Tween } = {}

function UiKit.pulse(inst: GuiObject)
	if pulses[inst] then
		return
	end
	local found = inst:FindFirstChild("PulseScale") :: UIScale?
	local scale: UIScale
	if found then
		scale = found
	else
		scale = Instance.new("UIScale")
		scale.Name = "PulseScale"
		scale.Parent = inst
	end
	local t = TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.08 })
	pulses[inst] = t
	t:Play()
end

function UiKit.stopPulse(inst: GuiObject)
	local t = pulses[inst]
	if t then
		t:Cancel()
		pulses[inst] = nil
	end
	local scale = inst:FindFirstChild("PulseScale") :: UIScale?
	if scale then
		scale.Scale = 1
	end
end

local toastHolder: Frame? = nil

function UiKit.toast(text: string, color: Color3?)
	if not toastHolder or not toastHolder.Parent then
		local gui = UiKit.screenGui("Toasts", 100)
		local holder = UiKit.frame({
			Name = "ToastHolder",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.12),
			Size = UDim2.fromScale(0.5, 0.3),
			parent = gui,
		})
		UiKit.list(holder, { HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0.02, 0) })
		local limit = Instance.new("UISizeConstraint")
		limit.MaxSize = Vector2.new(480, 10000)
		limit.Parent = holder
		toastHolder = holder
	end
	local t = UiKit.frame({
		Name = "Toast",
		Size = UDim2.fromScale(1, 0.14),
		BackgroundColor3 = color or theme.UiDark,
		parent = toastHolder,
	})
	UiKit.corner(t, 12)
	local l = UiKit.label({
		Text = text,
		Size = UDim2.fromScale(0.92, 0.7),
		Position = UDim2.fromScale(0.04, 0.15),
		parent = t,
	})
	task.delay(2.5, function()
		tween(t, 0.3, { BackgroundTransparency = 1 })
		tween(l, 0.3, { TextTransparency = 1 })
		task.wait(0.3)
		t:Destroy()
	end)
end

return UiKit
