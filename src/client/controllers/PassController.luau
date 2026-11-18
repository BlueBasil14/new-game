--!strict
-- Turf Pass screen (docs/BATTLEPASS.md): a full-width horizontal track, free row below, premium row above,
-- tier nodes on a glowing rail, missions sheet, unlock and reward celebrations. Draws only; the server
-- (BattlePassService) owns XP, claims and purchases.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BattlePass = require(Shared.BattlePass)
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local Formulas = require(Shared.Formulas)
local Remotes = require(Shared.Remotes)
local TurfAnim = require(Shared.TurfAnim)
local ArcadeIcons = require(Shared.ArcadeIcons)
local SkyChest = require(Shared.SkyChest)
local UiKit = require(script.Parent.Parent.ui.UiKit)
local ClientState = require(script.Parent.Parent.ClientState)
local PanelController = require(script.Parent.PanelController)

local CFG = Config.BattlePass
local S = {
	title = "TURF PASS",
	season = "Season %d: %s",
	ends = "%dd %dh left",
	endsHours = "%dh %dm left",
	tier = "TIER",
	xp = "%s / %s XP",
	xpMax = "MAX TIER! Bonus key every %s XP",
	missions = "Missions",
	free = "FREE",
	premium = "PREMIUM",
	unlock = "UNLOCK",
	unlockPrice = "R$ %d",
	worth = "4 exclusive animated Legendaries",
	plus = "+10 TIERS\nR$ %d",
	tierSkip = "+1 TIER\nR$ %d",
	owner = "SEASON 1\nOWNER",
	unlockTwo = "UNLOCK\nR$ %d",
	unlockLate = "UNLOCK R$ %d\nends in %dh",
	waiting = "%d Legendary, %d Rare,\n%d gems waiting!",
	toGo = "%d tiers to go!",
	finaleDone = "Unlocked!",
	go = "GO!",
	unlockNamed = "GET %s\nR$ %d",
	plusJump = "+10 TIERS R$ %d\n%s now!",
	odds = "Sky Chest odds: ",
	firstTitle = "%s is waiting!",
	waitingWords = "%d Legendary · %d Rare · %s gems",
	plusOne = "+10 TIERS  R$ %d",
	jumpTag = "%s now!",
	waitingTile = "WAITING!",
	waitingShort = "waiting for you!",
	alsoWaiting = "Waiting: %d Legendary, %d Rare, %d gems",
	get = "GET",
	claimAll = "CLAIM ALL\n%d",
	finale = "TIER 30",
	finaleSub = "Season finale",
	comingSoon = "Coming soon",
	missionsTitle = "DAILY MISSIONS",
	missionsNew = "New missions in %dh %dm",
	missionXp = "+%s XP",
	catchUp = "2x CATCH-UP XP",
	playCapped = "Daily play XP maxed",
	claim = "Claim",
	claimed = "Done",
	close = "Back",
	xpFloat = "+%s Pass XP",
	tierUp = "TIER %d!",
	delivered = "Season rewards delivered: %d",
	premiumGot = "PREMIUM UNLOCKED!",
	legendary = "LEGENDARY!",
	equipNow = "Equip now",
	nice = "Awesome!",
	popupTitle = "You just passed %s!",
	popupBody = "Unlock Premium to claim it and everything you've reached:",
	popupLater = "Later",
	keyName = "Sky Chest Key",
	keysName = "Sky Chest Keys",
	boostName = "2x Coins",
	boostSub = "%d min",
	restrictedKey = "%s coins",
	notReady = "Reach tier %d first",
	needPremium = "Unlock Premium to claim this",
	questKinds = {
		cells = "Claim %s cells",
		kills = "Eliminate %s runners",
		bigCapture = "Capture %s cells at once",
		mapPct = "Reach %s%% of the map",
		kingSeconds = "Be King for %s seconds",
		playMinutes = "Play for %s minutes",
	},
}

local INK = Color3.fromHex("202840")
local CREAM = Color3.fromHex("FFF9EE")
local GOLD = Color3.fromHex("FFC83D")
local GOLD_DEEP = Color3.fromHex("F08A1C")
local GOLD_LIGHT = Color3.fromHex("FFF1B0")
local BLUE = Color3.fromHex("4F8BFF")
local BLUE_LIGHT = Color3.fromHex("BFE3FF")
local VIOLET = Color3.fromHex("6A4BD8")
local VIOLET_DEEP = Color3.fromHex("3A2A8C")
local MUTED = Color3.fromHex("626779")
local GREEN = Color3.fromHex("43D17A")
local WHITE = Color3.new(1, 1, 1)
local RARITY: { [string]: Color3 } = {
	legendary = GOLD,
	rare = BLUE,
	common = Color3.fromHex("B8C2D6"),
}

local COL_W = 132 -- px per tier column (before the track scale)
local TILE = 112 -- px reward tile (before the track scale)
local BASE_H = 340 -- track height the layout is drawn for; scaled to the real track height
local MAX_TRACK_SCALE = 1.3
local COMPACT_HEIGHT = 560 -- viewport px below which the pass goes full-screen (phones in landscape)
local QUEST_ICONS: { [string]: string } = {
	cells = "gameplay_territory",
	kills = "gameplay_trail_cut",
	bigCapture = "gameplay_capture_loop",
	mapPct = "gameplay_map_control",
	kingSeconds = "economy_crown",
	playMinutes = "core_timer",
} -- tall windows centre the track instead of growing tiles further
local ANIM_HZ = 20

local theme = UiKit.theme
local PassController = {}

local gui: ScreenGui? = nil
local root: Frame? = nil
local isOpen = false
local refreshFn: (() -> ())? = nil
local animated: { { img: ImageLabel, item: Catalog.Item, holder: Frame } } = {}
local lastTier = -1
local hudDot: ((number) -> ())? = nil
local popupShown: { [number]: boolean } = {} -- one-time tier 10 / 20 prompts already shown this session

local function tween(inst: Instance, t: number, goal: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?, repeats: number?, reverses: boolean?): Tween
	local tw = TweenService:Create(inst, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out, repeats or 0, reverses or false), goal)
	tw:Play()
	return tw
end

local function state(): BattlePass.State
	local p = ClientState.profile
	return (BattlePass.normalize(if p then (p :: any).pass else nil, CFG.Season))
end

local function sessionPass(): { [string]: any }
	local s = (ClientState.session :: any).pass
	return if type(s) == "table" then s else { open = false, endsAt = 0, behind = false, keysRestricted = false }
end

function PassController.isOpenSeason(): boolean
	return sessionPass().open == true
end

local function label(parent: Instance, text: string, props: { [string]: any }?): TextLabel
	local p = props or {}
	p.Text = text
	p.parent = parent
	local l = UiKit.label(p)
	return l
end

local function outlined(l: TextLabel, color: Color3?, thickness: number?)
	local s = Instance.new("UIStroke")
	s.Color = color or INK
	s.Thickness = thickness or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = l
end

local function gradient(inst: Instance, a: Color3, b: Color3, rotation: number?)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(a, b)
	g.Rotation = rotation or 90
	g.Parent = inst
	return g
end

-- A sweeping white shine across a frame (Legendary tiles, premium ticket, unlock button).
local function shine(frame: GuiObject, period: number)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(WHITE)
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.42, 1),
		NumberSequenceKeypoint.new(0.5, 0.35),
		NumberSequenceKeypoint.new(0.58, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Rotation = 20
	g.Offset = Vector2.new(-1, 0)
	local overlay = Instance.new("Frame")
	overlay.Name = "Shine"
	overlay.BackgroundColor3 = WHITE
	overlay.BorderSizePixel = 0
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.ZIndex = frame.ZIndex + 4
	overlay.Parent = frame
	local c = frame:FindFirstChildOfClass("UICorner")
	if c then
		c:Clone().Parent = overlay
	end
	g.Parent = overlay
	tween(g, period, { Offset = Vector2.new(1, 0) }, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false)
end

local function bob(inst: GuiObject, amount: number, period: number)
	local s = Instance.new("UIScale")
	s.Parent = inst
	tween(s, period, { Scale = 1 + amount }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	return s
end

local function punch(inst: GuiObject)
	local s = inst:FindFirstChild("Punch") :: UIScale?
	if not s then
		local n = Instance.new("UIScale")
		n.Name = "Punch"
		n.Parent = inst
		s = n
	end
	local sc = s :: UIScale
	sc.Scale = 1.25
	tween(sc, 0.35, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

local function confetti(parent: GuiObject, at: Vector2?)
	local holder = gui
	if not holder then
		return
	end
	local origin = at or (parent.AbsolutePosition + parent.AbsoluteSize / 2)
	local colors = { GOLD, BLUE, theme.Pink, GREEN, Color3.fromHex("C45CFF") }
	for i = 1, 22 do
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.BackgroundColor3 = colors[(i % #colors) + 1]
		f.Size = UDim2.fromOffset(math.random(7, 12), math.random(7, 12))
		f.Position = UDim2.fromOffset(origin.X, origin.Y)
		f.Rotation = math.random(0, 360)
		f.ZIndex = 80
		f.Parent = holder
		local ang = math.random() * math.pi * 2
		local dist = math.random(70, 190)
		local dest = origin + Vector2.new(math.cos(ang) * dist, math.sin(ang) * dist - 40)
		tween(f, 0.55, { Position = UDim2.fromOffset(dest.X, dest.Y), Rotation = f.Rotation + math.random(-200, 200) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.delay(0.45, function()
			tween(f, 0.35, { Position = UDim2.fromOffset(dest.X, dest.Y + 60), BackgroundTransparency = 1 })
			task.wait(0.4)
			f:Destroy()
		end)
	end
end

-- Reward art -------------------------------------------------------------------------------------

local function artId(id: number?): string?
	return if id and id ~= 0 then "rbxassetid://" .. id else nil
end

local function image(parent: Instance, id: string, color: Color3?, z: number): ImageLabel
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromScale(1, 1)
	img.ScaleType = Enum.ScaleType.Fit
	img.Image = id
	img.ImageColor3 = color or WHITE
	img.ZIndex = z
	img.Parent = parent
	return img
end

-- Skin preview: the real turf look (colour + pattern tile), animated for animated skins.
local function skinPreview(parent: Frame, item: Catalog.Item)
	parent.BackgroundColor3 = Color3.fromHex(item.colorA)
	parent.ClipsDescendants = true
	local tileImg = artId(Config.ShopArt.Patterns[item.pattern])
	if not (item.colorB and tileImg) then
		return
	end
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.ZIndex = parent.ZIndex + 1
	holder.Parent = parent
	local img = image(holder, tileImg :: string, Color3.fromHex(item.colorB :: string), parent.ZIndex + 1)
	img.ScaleType = Enum.ScaleType.Tile
	img.TileSize = UDim2.fromOffset(TILE * 0.45, TILE * 0.45)
	if item.anim then
		-- Oversized by one tile so the shifted image never shows an edge.
		img.Size = UDim2.new(1, TILE * 0.45, 1, TILE * 0.45)
		table.insert(animated, { img = img, item = item, holder = holder })
	end
end

local function trailPreview(parent: Frame, item: Catalog.Item)
	local a = Color3.fromHex(item.colorA)
	parent.BackgroundColor3 = a:Lerp(CREAM, 0.8)
	local band, core, line = artId(Config.ShopArt.Trail.band), artId(Config.ShopArt.Trail.core), artId(Config.ShopArt.Trail.line)
	if not (band and core and line) then
		UiKit.icon("gameplay_capture_loop", { Size = UDim2.fromScale(1, 1), parent = parent })
		return
	end
	local z = parent.ZIndex
	image(parent, band :: string, a, z + 1)
	image(parent, core :: string, if item.colorB then Color3.fromHex(item.colorB) else a:Lerp(WHITE, 0.45), z + 2)
	image(parent, line :: string, nil, z + 3)
end

local function rewardName(r: BattlePass.Reward, restricted: boolean): (string, string?)
	local n = r.amount or 0
	if r.kind == "coins" then
		return UiKit.formatNumber(n), nil
	elseif r.kind == "gems" then
		return UiKit.formatNumber(n), nil
	elseif r.kind == "keys" then
		if restricted then
			return string.format(S.restrictedKey, UiKit.formatNumber(n * CFG.RestrictedKeyCoins)), nil
		end
		return "x" .. n, if n == 1 then S.keyName else S.keysName
	elseif r.kind == "boost" then
		return S.boostName, string.format(S.boostSub, n // 60)
	elseif r.kind == "item" then
		local it = Catalog.byId(r.id :: string)
		return if it then it.name else "?", nil
	end
	return "", nil
end

-- Draws one reward into `art` (a square frame).
local function rewardArt(art: Frame, r: BattlePass.Reward, restricted: boolean)
	local icon = if r.kind == "coins" then "economy_coin_stack"
		elseif r.kind == "gems" then "economy_gem_cluster"
		elseif r.kind == "keys" then (if restricted then "economy_coin_stack" else "economy_reward_chest")
		elseif r.kind == "boost" then "economy_energy"
		else nil
	if icon then
		UiKit.icon(icon, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromScale(0.86, 0.86), parent = art })
		if r.kind == "boost" then
			local x = label(art, "2x", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(0.98, 0.98), Size = UDim2.fromScale(0.5, 0.36), TextColor3 = WHITE })
			outlined(x, INK, 2)
			x.ZIndex = art.ZIndex + 3
		end
		return
	end
	local it = Catalog.byId(r.id :: string)
	if not it then
		return
	end
	local inner = UiKit.frame({ Size = UDim2.fromScale(1, 1), parent = art })
	inner.ZIndex = art.ZIndex + 1
	UiKit.corner(inner, 10)
	if it.type == "trail" then
		trailPreview(inner, it)
	else
		skinPreview(inner, it)
	end
end

local function stepAnimated(now: number)
	for i = #animated, 1, -1 do
		local a = animated[i]
		if a.img.Parent == nil then
			table.remove(animated, i)
			continue
		end
		local color, u, v, transparency = TurfAnim.frame(a.item.anim :: string, Color3.fromHex(a.item.colorB or "#FFFFFF"), now)
		local tile = a.img.TileSize.X.Offset
		a.img.ImageColor3 = color
		a.img.ImageTransparency = transparency
		a.img.Position = UDim2.fromOffset(-u * tile, -v * tile)
	end
end

-- Screen ------------------------------------------------------------------------------------------

type TileUi = { frame: Frame, get: TextButton, lock: GuiObject?, check: GuiObject, glow: Frame, track: string, tier: number, names: { TextLabel }, dim: Frame }

local function build()
	local g = UiKit.screenGui("TurfPass", 60)
	gui = g
	local dim = UiKit.frame({ Name = "Dim", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.4, Active = true, Visible = false, parent = g })
	local win = UiKit.frame({
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.53),
		Size = UDim2.fromScale(0.94, 0.86),
		BackgroundColor3 = CREAM,
		parent = dim,
	})
	root = dim
	UiKit.corner(win, 22)
	UiKit.stroke(win, INK, 4)
	local winScale = Instance.new("UIScale")
	winScale.Parent = win
	local edge = UiKit.frame({ Name = "RaisedEdge", Size = UDim2.fromScale(1, 1), Position = UDim2.fromOffset(0, 8), BackgroundColor3 = INK, ZIndex = 0, parent = win })
	UiKit.corner(edge, 22)
	local surface = UiKit.frame({ Name = "Surface", Size = UDim2.fromScale(1, 1), BackgroundColor3 = CREAM, ClipsDescendants = true, parent = win })
	UiKit.corner(surface, 22)

	-- Header: gold ribbon, season, countdown, tier badge, XP bar, missions -----------------------
	local header = UiKit.frame({ Name = "Header", Size = UDim2.new(1, 0, 0.2, 0), BackgroundColor3 = WHITE, parent = surface })
	gradient(header, VIOLET, VIOLET_DEEP, 0)
	local title = label(header, S.title, { Position = UDim2.fromScale(0.02, 0.08), Size = UDim2.fromScale(0.26, 0.42), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD })
	outlined(title, INK, 3)
	local seasonL = label(header, string.format(S.season, CFG.Season, CFG.Name), { Position = UDim2.fromScale(0.02, 0.52), Size = UDim2.fromScale(0.26, 0.26), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = WHITE })
	outlined(seasonL, INK, 2)
	local timeChip = UiKit.frame({ Name = "Countdown", Position = UDim2.fromScale(0.02, 0.8), Size = UDim2.fromScale(0.13, 0.16), BackgroundColor3 = INK, parent = header })
	UiKit.corner(timeChip, 8)
	local timeL = label(timeChip, "", { Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1), TextColor3 = GOLD_LIGHT })

	local badge = UiKit.frame({ Name = "TierBadge", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.34, 0.5), Size = UDim2.fromScale(0.085, 0.84), BackgroundColor3 = GOLD, parent = header })
	UiKit.aspect(badge, 1)
	UiKit.corner(badge, 18)
	UiKit.stroke(badge, INK, 3)
	gradient(badge, GOLD_LIGHT, GOLD_DEEP, 90)
	badge.Rotation = 45
	local badgeInner = UiKit.frame({ BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Rotation = -45, parent = badge })
	label(badgeInner, S.tier, { Position = UDim2.fromScale(0.15, 0.12), Size = UDim2.fromScale(0.7, 0.24), TextColor3 = INK })
	local tierL = label(badgeInner, "0", { Position = UDim2.fromScale(0.1, 0.32), Size = UDim2.fromScale(0.8, 0.55), TextColor3 = WHITE })
	outlined(tierL, INK, 3)

	local barBack = UiKit.frame({ Name = "XpBar", Position = UDim2.fromScale(0.4, 0.3), Size = UDim2.fromScale(0.3, 0.34), BackgroundColor3 = VIOLET_DEEP, parent = header })
	UiKit.corner(barBack, 100)
	UiKit.stroke(barBack, INK, 3)
	local barFill = UiKit.frame({ Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, parent = barBack })
	UiKit.corner(barFill, 100)
	gradient(barFill, GOLD_LIGHT, GOLD, 90)
	shine(barFill, 2.2)
	local xpL = label(barBack, "", { Size = UDim2.fromScale(0.92, 0.7), Position = UDim2.fromScale(0.04, 0.15), TextColor3 = WHITE })
	xpL.ZIndex = barFill.ZIndex + 6
	outlined(xpL, INK, 2)
	local chips = UiKit.frame({ Name = "Chips", BackgroundTransparency = 1, Position = UDim2.fromScale(0.4, 0.7), Size = UDim2.fromScale(0.3, 0.22), parent = header })
	UiKit.list(chips, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.02, 0) })
	local function chip(text: string, color: Color3): Frame
		local c = UiKit.frame({ Size = UDim2.fromScale(0.48, 1), BackgroundColor3 = color, Visible = false, parent = chips })
		UiKit.corner(c, 8)
		UiKit.stroke(c, INK, 2)
		label(c, text, { Size = UDim2.fromScale(0.92, 0.8), Position = UDim2.fromScale(0.04, 0.1), TextColor3 = INK })
		return c
	end
	local catchChip = chip(S.catchUp, GREEN)
	local capChip = chip(S.playCapped, Color3.fromHex("FFB59A"))

	local missionsBtn = UiKit.button({ text = "", color = Color3.fromHex("C9B7FF"), size = UDim2.fromScale(0.11, 0.5), position = UDim2.fromScale(0.715, 0.25), parent = header })
	UiKit.icon("core_quests", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.05, 0.5), Size = UDim2.fromScale(0.3, 0.8), parent = missionsBtn })
	label(missionsBtn, S.missions, { Position = UDim2.fromScale(0.34, 0.15), Size = UDim2.fromScale(0.62, 0.7), TextColor3 = INK })
	local missionDot = UiKit.frame({ Name = "Dot", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.97, 0.05), Size = UDim2.fromScale(0.26, 0.5), BackgroundColor3 = theme.Danger, Visible = false, parent = missionsBtn })
	UiKit.aspect(missionDot, 1)
	UiKit.corner(missionDot, 100)
	UiKit.stroke(missionDot, WHITE, 2)
	local missionCount = label(missionDot, "", { Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1), TextColor3 = WHITE })
	missionCount.ZIndex = missionDot.ZIndex + 1

	local claimAllBtn = UiKit.button({ text = "", color = GREEN, size = UDim2.fromScale(0.095, 0.5), position = UDim2.fromScale(0.835, 0.25), parent = header })
	claimAllBtn.TextColor3 = WHITE
	local cas = Instance.new("UIStroke")
	cas.Color = INK
	cas.Thickness = 2
	cas.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	cas.Parent = claimAllBtn
	bob(claimAllBtn, 0.07, 0.45)
	claimAllBtn.Visible = false

	local closeBtn = UiKit.button({ text = "", color = theme.Danger, size = UDim2.fromScale(0.055, 0.5), position = UDim2.fromScale(0.94, 0.25), parent = header })
	closeBtn.BackgroundTransparency = 1
	local cs = closeBtn:FindFirstChildOfClass("UIStroke")
	if cs then
		cs.Enabled = false
	end
	UiKit.icon("core_close", { Size = UDim2.fromScale(1, 1), parent = closeBtn })
	UiKit.aspect(closeBtn, 1)

	-- Lane labels (left) ------------------------------------------------------------------------
	local rail = UiKit.frame({ Name = "Lanes", BackgroundTransparency = 1, Position = UDim2.fromScale(0.012, 0.22), Size = UDim2.fromScale(0.1, 0.76), parent = surface })
	local function ticket(text: string, icon: string, top: number, h: number, color: Color3, color2: Color3): Frame
		local t = UiKit.frame({ Position = UDim2.fromScale(0, top), Size = UDim2.fromScale(1, h), BackgroundColor3 = WHITE, parent = rail })
		UiKit.corner(t, 14)
		UiKit.stroke(t, INK, 3)
		gradient(t, color, color2, 90)
		UiKit.icon(icon, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromScale(0.78, 0.36), parent = t })
		local l = label(t, text, { Position = UDim2.fromScale(0.03, 0.6), Size = UDim2.fromScale(0.94, 0.24), TextColor3 = WHITE })
		outlined(l, INK, 2)
		return t
	end
	local premTicket = ticket(S.premium, "economy_crown", 0, 0.45, GOLD_LIGHT, GOLD_DEEP)
	shine(premTicket, 2.6)
	ticket(S.free, "core_gift", 0.55, 0.45, BLUE_LIGHT, BLUE)

	-- Buy zone (right): finale chase card, the one big UNLOCK, value line, tier offer -------------
	local buy = UiKit.frame({ Name = "BuyZone", BackgroundTransparency = 1, Position = UDim2.fromScale(0.838, 0.22), Size = UDim2.fromScale(0.15, 0.76), parent = surface })
	local unlockBtn = UiKit.button({ text = "", color = GREEN, size = UDim2.fromScale(1, 0.17), position = UDim2.fromScale(0, 0.53), parent = buy })
	local hookItem = Catalog.byId(BattlePass.tiers[1].prem[1].id :: string) :: Catalog.Item
	local thumb = UiKit.frame({ Name = "Thumb", Position = UDim2.fromScale(0.03, 0.14), Size = UDim2.fromScale(0.22, 0.72), parent = unlockBtn })
	UiKit.corner(thumb, 8)
	UiKit.stroke(thumb, INK, 2)
	thumb.ZIndex = unlockBtn.ZIndex + 2
	skinPreview(thumb, hookItem)
	local unlockL = label(unlockBtn, "", { Size = UDim2.fromScale(0.72, 0.84), Position = UDim2.fromScale(0.27, 0.08), TextColor3 = WHITE })
	outlined(unlockL, INK, 2)
	unlockL.ZIndex = unlockBtn.ZIndex + 6
	shine(unlockBtn, 1.8)
	local unlockPulse = bob(unlockBtn, 0.06, 0.55)
	local ownerCrown = UiKit.icon("economy_crown", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.1, 0.1), Size = UDim2.fromScale(0.36, 0.6), Rotation = -18, Visible = false, parent = unlockBtn })
	ownerCrown.ZIndex = unlockBtn.ZIndex + 7
	local valuePill = UiKit.frame({ Name = "Value", Position = UDim2.fromScale(0, 0.71), Size = UDim2.fromScale(1, 0.14), BackgroundColor3 = WHITE, parent = buy })
	UiKit.corner(valuePill, 10)
	UiKit.stroke(valuePill, GOLD_DEEP, 2)
	local valueRow = label(valuePill, "", { Position = UDim2.fromScale(0.04, 0.06), Size = UDim2.fromScale(0.92, 0.5), TextColor3 = INK })
	local valueL = label(valuePill, "", { Position = UDim2.fromScale(0.04, 0.56), Size = UDim2.fromScale(0.92, 0.38), TextColor3 = GOLD_DEEP })
	local plusBtn = UiKit.button({ text = "", color = GOLD, size = UDim2.fromScale(1, 0.12), position = UDim2.fromScale(0, 0.88), parent = buy })
	local jumpTag = UiKit.frame({ Name = "JumpTag", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(0.8, 0.34), BackgroundColor3 = theme.Pink, Visible = false, parent = plusBtn })
	UiKit.corner(jumpTag, 6)
	UiKit.stroke(jumpTag, INK, 2)
	jumpTag.ZIndex = plusBtn.ZIndex + 4
	local jumpL = label(jumpTag, "", { Size = UDim2.fromScale(0.92, 0.8), Position = UDim2.fromScale(0.04, 0.1), TextColor3 = WHITE })
	jumpL.ZIndex = jumpTag.ZIndex + 1
	local tierBtn = UiKit.button({ text = "", color = Color3.fromHex("C9B7FF"), size = UDim2.fromScale(1, 0.12), position = UDim2.fromScale(0, 0.88), parent = buy })
	tierBtn.Visible = false

	-- Track ---------------------------------------------------------------------------------------
	local trackBack = UiKit.frame({ Name = "TrackBack", Position = UDim2.fromScale(0.12, 0.22), Size = UDim2.fromScale(0.71, 0.76), BackgroundColor3 = WHITE, ClipsDescendants = true, parent = surface })
	UiKit.corner(trackBack, 16)
	UiKit.stroke(trackBack, INK, 3)
	gradient(trackBack, Color3.fromHex("EDE6FF"), Color3.fromHex("D9CCFF"), 90)
	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "Track"
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Size = UDim2.fromScale(1, 1)
	scroller.ScrollingDirection = Enum.ScrollingDirection.X
	scroller.ScrollBarThickness = 8
	scroller.ScrollBarImageColor3 = INK
	scroller.HorizontalScrollBarInset = Enum.ScrollBarInset.None
	scroller.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	scroller.Parent = trackBack
	-- Everything on the track is laid out in px for a BASE_H-tall track, then scaled to the real height so
	-- tiles grow on big screens and shrink on phones; the canvas width follows the scale.
	local content = UiKit.frame({ Name = "Content", BackgroundTransparency = 1, Size = UDim2.fromOffset(CFG.Tiers * COL_W + 24, BASE_H), parent = scroller })
	local contentScale = Instance.new("UIScale")
	contentScale.Parent = content
	local function fitTrack()
		local h = scroller.AbsoluteWindowSize.Y
		if h <= 0 then
			return
		end
		local k = math.min((h - 10) / BASE_H, MAX_TRACK_SCALE)
		contentScale.Scale = k
		content.Position = UDim2.fromOffset(0, math.max(0, (h - BASE_H * k) / 2))
		scroller.CanvasSize = UDim2.fromOffset(math.ceil((CFG.Tiers * COL_W + 24) * k), 0)
	end
	scroller:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(fitTrack)
	task.defer(fitTrack)

	-- lane backgrounds: premium is a purple-to-gold band, free a soft blue band
	local premLane = UiKit.frame({ Name = "PremiumLane", Size = UDim2.fromScale(1, 0.5), BackgroundColor3 = WHITE, ZIndex = 0, parent = trackBack })
	gradient(premLane, Color3.fromHex("B9A2FF"), Color3.fromHex("FFD66B"), 0)
	premLane.BackgroundTransparency = 0.45
	local freeLane = UiKit.frame({ Name = "FreeLane", Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromScale(1, 0.5), BackgroundColor3 = Color3.fromHex("CFE6FF"), BackgroundTransparency = 0.15, ZIndex = 0, parent = trackBack })
	local _ = freeLane
	for i = 1, 30 do
		local dot = UiKit.frame({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(math.random(), math.random() * 0.9), Size = UDim2.fromOffset(5, 5), BackgroundColor3 = WHITE, BackgroundTransparency = 0.3, ZIndex = 0, parent = premLane })
		dot.Rotation = 45
		tween(dot, 0.8 + (i % 5) * 0.3, { BackgroundTransparency = 0.95 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	end

	-- scroll arrows on both track edges (the track scrolls sideways)
	local function chevron(left: boolean)
		local b = UiKit.button({ text = "", color = WHITE, size = UDim2.fromScale(0.46, 0.08), position = UDim2.fromScale(if left then 0 else 0.54, 0.46), parent = rail })
		b.ZIndex = 30
		local a = UiKit.icon("gameplay_arrow_right", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.75, 0.75), Rotation = if left then 180 else 0, parent = b })
		a.ZIndex = 31
		UiKit.aspect(b, 1)
		b.Activated:Connect(function()
			local step = COL_W * 3 * contentScale.Scale
			local x = math.clamp(scroller.CanvasPosition.X + (if left then -step else step), 0, math.max(0, scroller.AbsoluteCanvasSize.X - scroller.AbsoluteWindowSize.X))
			tween(scroller, 0.35, { CanvasPosition = Vector2.new(x, 0) }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		end)
	end
	chevron(true)
	chevron(false)

	-- rail line behind the nodes
	local lineBack = UiKit.frame({ Name = "Rail", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12 + COL_W / 2, 0.5, 0), Size = UDim2.new(0, (CFG.Tiers - 1) * COL_W, 0, 14), BackgroundColor3 = VIOLET_DEEP, parent = content })
	UiKit.corner(lineBack, 100)
	UiKit.stroke(lineBack, INK, 2)
	local lineFill = UiKit.frame({ Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, parent = lineBack })
	UiKit.corner(lineFill, 100)
	gradient(lineFill, GOLD_LIGHT, GOLD, 90)

	local tiles: { TileUi } = {}
	local nodes: { Frame } = {}
	local busy = false
	-- pulsing ring behind the current tier's node
	local ring = UiKit.frame({ Name = "CurrentRing", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(74, 74), BackgroundColor3 = GOLD, BackgroundTransparency = 0.35, parent = content })
	UiKit.corner(ring, 100)
	ring.ZIndex = lineBack.ZIndex + 1
	bob(ring, 0.25, 0.6)

	local function makeTile(tier: number, track: string): TileUi
		local col = 12 + (tier - 1) * COL_W + (COL_W - TILE) / 2
		local isPrem = track == "prem"
		local rewards = BattlePass.rewards(track, tier)
		local main = rewards[1]
		local item = if main.kind == "item" then Catalog.byId(main.id :: string) else nil
		local rarity = if item then item.rarity else nil
		local f = UiKit.frame({
			Name = track .. tier,
			Position = UDim2.fromOffset(col, if isPrem then 8 else BASE_H - TILE - 18 - 8),
			Size = UDim2.fromOffset(TILE, TILE + 18),
			BackgroundColor3 = WHITE,
			parent = content,
		})
		UiKit.corner(f, 14)
		local strokeColor = if rarity == "legendary" then GOLD_DEEP elseif rarity == "rare" then BLUE else INK
		UiKit.stroke(f, strokeColor, if rarity == "legendary" then 4 else 3)
		if isPrem then
			gradient(f, Color3.fromHex("FFE9A6"), Color3.fromHex("FFC24A"), 90)
		else
			gradient(f, Color3.fromHex("E3F2FF"), Color3.fromHex("9DD3FF"), 90)
		end
		local glow = UiKit.frame({ Name = "Glow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 16, 1, 16), BackgroundColor3 = GREEN, BackgroundTransparency = 1, ZIndex = 0, parent = f })
		UiKit.corner(glow, 18)
		local art = UiKit.frame({ Name = "Art", BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 8), Size = UDim2.fromOffset(TILE - 20, TILE - 20), parent = f })
		art.ZIndex = f.ZIndex + 1
		local restricted = sessionPass().keysRestricted == true
		rewardArt(art, main, restricted)
		if rarity == "legendary" then
			shine(f, 2.4)
			local halo = UiKit.frame({ Name = "Halo", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 22, 1, 22), BackgroundColor3 = GOLD, BackgroundTransparency = 0.45, ZIndex = 0, parent = f })
			UiKit.corner(halo, 20)
			tween(halo, 0.9, { BackgroundTransparency = 0.8, Size = UDim2.new(1, 30, 1, 30) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		end
		local name, sub = rewardName(main, restricted)
		if #rewards > 1 then
			local extras = {}
			for k = 2, #rewards do
				local r = rewards[k]
				if r.kind == "item" then
					local it = Catalog.byId(r.id :: string)
					table.insert(extras, if it and it.type == "trail" then "Trail" else "Skin")
				elseif r.kind == "gems" then
					table.insert(extras, UiKit.formatNumber(r.amount or 0) .. " gems")
				elseif r.kind == "keys" then
					table.insert(extras, (r.amount or 0) .. " keys")
				end
			end
			sub = "+ " .. table.concat(extras, " + ")
		end
		local names: { TextLabel } = {}
		local nameL = label(f, name, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, if sub then -18 else -4), Size = UDim2.new(1, -8, 0, 22), TextColor3 = WHITE })
		outlined(nameL, INK, 2)
		nameL.ZIndex = f.ZIndex + 5
		table.insert(names, nameL)
		if sub then
			local subL = label(f, sub, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -3), Size = UDim2.new(1, -8, 0, 15), TextColor3 = INK })
			subL.ZIndex = f.ZIndex + 5
			table.insert(names, subL)
		end
		if rarity == "legendary" or rarity == "rare" then
			local tag = UiKit.frame({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(84, 20), BackgroundColor3 = RARITY[rarity], parent = f })
			UiKit.corner(tag, 6)
			UiKit.stroke(tag, INK, 2)
			tag.ZIndex = f.ZIndex + 6
			local tl = label(tag, string.upper(rarity), { Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1), TextColor3 = if rarity == "rare" then WHITE else INK })
			tl.ZIndex = tag.ZIndex + 1
		end
		local lock: GuiObject? = nil
		if isPrem then
			-- dark scrim + big padlock until Premium; lifting it is the unlock payoff
			local scrim = UiKit.frame({ Name = "Locked", Size = UDim2.fromScale(1, 1), BackgroundColor3 = INK, BackgroundTransparency = 0.8, parent = f })
			UiKit.corner(scrim, 14)
			scrim.ZIndex = f.ZIndex + 8
			local l = UiKit.icon("gameplay_lock", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -3, 0, 3), Size = UDim2.fromOffset(34, 34), parent = scrim })
			l.ZIndex = scrim.ZIndex + 2
			local waiting = UiKit.frame({ Name = "Waiting", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -10), Size = UDim2.fromOffset(TILE - 30, 22), BackgroundColor3 = GOLD, Visible = false, parent = scrim })
			UiKit.corner(waiting, 8)
			UiKit.stroke(waiting, INK, 2)
			waiting.ZIndex = scrim.ZIndex + 3
			local wl = label(waiting, S.waitingTile, { Size = UDim2.fromScale(0.92, 0.8), Position = UDim2.fromScale(0.04, 0.1), TextColor3 = INK })
			wl.ZIndex = waiting.ZIndex + 1
			lock = scrim
		end
		local dim = UiKit.frame({ Name = "NotYet", Size = UDim2.fromScale(1, 1), BackgroundColor3 = INK, BackgroundTransparency = 0.86, Visible = false, parent = f })
		UiKit.corner(dim, 14)
		dim.ZIndex = f.ZIndex + 7
		local check = UiKit.frame({ Name = "Done", Size = UDim2.fromScale(1, 1), BackgroundColor3 = INK, BackgroundTransparency = 0.45, Visible = false, parent = f })
		UiKit.corner(check, 14)
		check.ZIndex = f.ZIndex + 9
		local ci = UiKit.icon("core_confirm", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.55, 0.55), parent = check })
		ci.ZIndex = check.ZIndex + 1
		local get = UiKit.button({ text = S.get, color = GREEN, size = UDim2.fromOffset(TILE - 20, 32), position = UDim2.new(0, 10, 1, -38), parent = f })
		get.ZIndex = f.ZIndex + 10
		get.Visible = false
		local getL = get :: TextButton
		getL.TextColor3 = WHITE
		local gs = Instance.new("UIStroke")
		gs.Color = INK
		gs.Thickness = 2
		gs.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		gs.Parent = getL
		bob(get, 0.1, 0.4)
		local tile: TileUi = { frame = f, get = get, lock = lock, check = check, glow = glow, track = track, tier = tier, names = names, dim = dim }
		return tile
	end

	for tier = 1, CFG.Tiers do
		table.insert(tiles, makeTile(tier, "prem"))
		table.insert(tiles, makeTile(tier, "free"))
		local node = UiKit.frame({ Name = "Node" .. tier, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 12 + (tier - 0.5) * COL_W, 0.5, 0), Size = UDim2.fromOffset(40, 40), BackgroundColor3 = WHITE, parent = content })
		UiKit.corner(node, 10)
		UiKit.stroke(node, INK, 3)
		node.Rotation = 45
		node.ZIndex = lineBack.ZIndex + 3
		local nl = label(node, tostring(tier), { Size = UDim2.fromScale(0.9, 0.9), Position = UDim2.fromScale(0.05, 0.05), Rotation = -45, TextColor3 = INK })
		nl.ZIndex = node.ZIndex + 1
		nodes[tier] = node
	end

	-- Finale card (top of the buy zone) ---------------------------------------------------------
	local finale = UiKit.frame({ Name = "Finale", Size = UDim2.fromScale(1, 0.5), BackgroundColor3 = WHITE, parent = buy })
	UiKit.corner(finale, 16)
	UiKit.stroke(finale, GOLD_DEEP, 4)
	gradient(finale, Color3.fromHex("FFE9A6"), Color3.fromHex("F7A31F"), 90)
	shine(finale, 3)
	local ft = label(finale, S.finale, { Position = UDim2.fromScale(0.05, 0.03), Size = UDim2.fromScale(0.78, 0.13), TextColor3 = WHITE })
	outlined(ft, INK, 2)
	local fCrown = UiKit.icon("economy_crown", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.94, 0.03), Size = UDim2.fromScale(0.3, 0.17), Rotation = 20, parent = finale })
	fCrown.ZIndex = finale.ZIndex + 6
	local finaleItem = Catalog.byId(BattlePass.tiers[CFG.Tiers].prem[1].id :: string) :: Catalog.Item
	local fArt = UiKit.frame({ Position = UDim2.fromScale(0.08, 0.18), Size = UDim2.fromScale(0.84, 0.5), parent = finale })
	UiKit.corner(fArt, 12)
	UiKit.stroke(fArt, INK, 3)
	fArt.ZIndex = finale.ZIndex + 1
	skinPreview(fArt, finaleItem)
	local fn = label(finale, finaleItem.name, { Position = UDim2.fromScale(0.04, 0.7), Size = UDim2.fromScale(0.92, 0.14), TextColor3 = WHITE })
	outlined(fn, INK, 2)
	local toGo = label(finale, "", { Position = UDim2.fromScale(0.04, 0.85), Size = UDim2.fromScale(0.92, 0.12), TextColor3 = INK })

	-- Missions sheet ------------------------------------------------------------------------------
	local sheet = UiKit.frame({ Name = "Missions", Position = UDim2.fromScale(0.12, 1.05), Size = UDim2.fromScale(0.71, 0.76), BackgroundColor3 = CREAM, ZIndex = 50, parent = surface })
	UiKit.corner(sheet, 16)
	UiKit.stroke(sheet, INK, 3)
	local sheetTitle = label(sheet, S.missionsTitle, { Position = UDim2.fromScale(0.03, 0.03), Size = UDim2.fromScale(0.4, 0.1), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = VIOLET })
	sheetTitle.ZIndex = 51
	local sheetTime = label(sheet, "", { Position = UDim2.fromScale(0.45, 0.045), Size = UDim2.fromScale(0.39, 0.07), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = INK })
	sheetTime.ZIndex = 51
	local sheetClose = UiKit.button({ text = S.close, color = Color3.fromHex("C9B7FF"), size = UDim2.fromScale(0.12, 0.1), position = UDim2.fromScale(0.86, 0.03), parent = sheet })
	sheetClose.ZIndex = 52
	type Row = { frame: Frame, icon: ImageLabel, text: TextLabel, fill: Frame, prog: TextLabel, xp: TextLabel, reward: TextLabel, btn: TextButton, bob: UIScale }
	local rows: { Row } = {}
	for i = 1, CFG.Missions do
		local r = UiKit.frame({ Position = UDim2.fromScale(0.03, 0.16 + (i - 1) * 0.165), Size = UDim2.fromScale(0.94, 0.145), BackgroundColor3 = WHITE, parent = sheet })
		r.ZIndex = 51
		UiKit.corner(r, 12)
		UiKit.stroke(r, INK, 2)
		local diff = if i <= 3 then BLUE elseif i == 4 then GOLD else theme.Pink
		local pill = UiKit.frame({ Position = UDim2.fromScale(0.01, 0.15), Size = UDim2.fromScale(0.012, 0.7), BackgroundColor3 = diff, parent = r })
		pill.ZIndex = 52
		UiKit.corner(pill, 100)
		local ic = UiKit.icon("gameplay_territory", { Position = UDim2.fromScale(0.03, 0.1), Size = UDim2.fromScale(0.08, 0.8), parent = r })
		ic.ZIndex = 52
		local t = label(r, "", { Position = UDim2.fromScale(0.12, 0.08), Size = UDim2.fromScale(0.42, 0.45), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = INK })
		t.ZIndex = 52
		t.TextScaled = false -- one size for every row (long texts used to shrink on their own)
		local function fitText()
			t.TextSize = math.max(12, math.floor(r.AbsoluteSize.Y * 0.29))
		end
		r:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitText)
		fitText()
		local track = UiKit.frame({ Position = UDim2.fromScale(0.12, 0.6), Size = UDim2.fromScale(0.42, 0.28), BackgroundColor3 = Color3.fromHex("E1DACA"), parent = r })
		track.ZIndex = 52
		UiKit.corner(track, 100)
		UiKit.stroke(track, INK, 2)
		local fill = UiKit.frame({ Size = UDim2.fromScale(0, 1), BackgroundColor3 = GREEN, parent = track })
		fill.ZIndex = 53
		UiKit.corner(fill, 100)
		local prog = label(track, "", { Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1), TextColor3 = INK })
		prog.ZIndex = 54
		local xpPill = UiKit.frame({ Position = UDim2.fromScale(0.56, 0.1), Size = UDim2.fromScale(0.22, 0.42), BackgroundColor3 = WHITE, parent = r })
		xpPill.ZIndex = 52
		UiKit.corner(xpPill, 100)
		UiKit.stroke(xpPill, INK, 2)
		gradient(xpPill, GOLD_LIGHT, GOLD, 90)
		local xp = label(xpPill, "", { Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1), TextColor3 = INK })
		xp.ZIndex = 53
		local reward = label(r, "", { Position = UDim2.fromScale(0.56, 0.56), Size = UDim2.fromScale(0.22, 0.34), TextColor3 = INK })
		reward.ZIndex = 52
		local btn = UiKit.button({ text = S.claim, color = GREEN, size = UDim2.fromScale(0.17, 0.7), position = UDim2.fromScale(0.805, 0.15), parent = r })
		btn.ZIndex = 53
		local bs = Instance.new("UIScale")
		bs.Parent = btn
		rows[i] = { frame = r, icon = ic, text = t, fill = fill, prog = prog, xp = xp, reward = reward, btn = btn, bob = bs }
	end
	local sheetOpen = false
	local function showSheet(on: boolean)
		sheetOpen = on
		tween(sheet, 0.3, { Position = UDim2.fromScale(0.12, if on then 0.22 else 1.05) }, Enum.EasingStyle.Back, if on then Enum.EasingDirection.Out else Enum.EasingDirection.In)
	end
	missionsBtn.Activated:Connect(function()
		showSheet(not sheetOpen)
	end)
	sheetClose.Activated:Connect(function()
		showSheet(false)
	end)

	-- Behaviour -----------------------------------------------------------------------------------

	local function premiumPrompt(key: string)
		local id = (Config.Ids.Products :: any)[key]
		if type(id) ~= "number" or id == 0 then
			UiKit.toast(S.comingSoon)
			return
		end
		MarketplaceService:PromptProductPurchase(Players.LocalPlayer, id)
	end
	unlockBtn.Activated:Connect(function()
		if not state().premium then
			premiumPrompt("battlePass")
		end
	end)
	plusBtn.Activated:Connect(function()
		premiumPrompt(if state().premium then "battlePassTiers10" else "battlePassPlus")
	end)
	tierBtn.Activated:Connect(function()
		premiumPrompt("battlePassTier")
	end)

	local function claim(track: string?, tier: number?, from: GuiObject?)
		if busy then
			return
		end
		busy = true
		local ok, result
		if track then
			ok, result = ClientState.request(Remotes.Requests.BattlePass, "claim", track, tier)
		else
			ok, result = ClientState.request(Remotes.Requests.BattlePass, "claimAll")
		end
		busy = false
		if not ok then
			PanelController.sound("error")
			UiKit.toast(PanelController.errorText(result), theme.Danger)
			return
		end
		PanelController.sound("reward")
		local legendary: Catalog.Item? = nil
		for _, c in result.claimed do
			for _, t in tiles do
				if t.track == c.track and t.tier == c.tier then
					punch(t.frame)
					confetti(t.frame)
				end
			end
			for _, r in BattlePass.rewards(c.track, c.tier) do
				local it = if r.kind == "item" then Catalog.byId(r.id :: string) else nil
				if it and it.type == "skin" and it.rarity == "legendary" then
					legendary = it
				end
			end
		end
		if legendary then
			PassController.reveal(legendary)
		end
		local _ = from
	end
	claimAllBtn.Activated:Connect(function()
		claim(nil, nil, claimAllBtn)
	end)
	for _, t in tiles do
		t.get.Activated:Connect(function()
			claim(t.track, t.tier, t.get)
		end)
		local hit = Instance.new("TextButton")
		hit.BackgroundTransparency = 1
		hit.Text = ""
		hit.Size = UDim2.fromScale(1, 1)
		hit.ZIndex = t.frame.ZIndex + 7
		hit.Parent = t.frame
		hit.Activated:Connect(function()
			local st = state()
			local ok, why = BattlePass.canClaim(st, t.track, t.tier)
			if ok then
				claim(t.track, t.tier, t.frame)
			elseif why == "premium_required" then
				punch(unlockBtn)
				UiKit.toast(S.needPremium)
			elseif why == "too_early" then
				UiKit.toast(string.format(S.notReady, t.tier))
			end
			local first = BattlePass.rewards(t.track, t.tier)[1]
			if first and first.kind == "keys" and sessionPass().keysRestricted ~= true then
				local parts = {}
				for _, prize in SkyChest.Prizes do
					table.insert(parts, prize.name .. " " .. prize.weight .. "%")
				end
				UiKit.toast(S.odds .. table.concat(parts, ", "))
			end
		end)
	end

	for i, row in rows do
		row.btn.Activated:Connect(function()
			if row.btn.Text == S.go then
				PassController.close() -- back to the match to finish it
				return
			end
			if row.btn.Text ~= S.claim then
				return
			end
			local ok, result = ClientState.request(Remotes.Requests.ClaimQuest, i)
			if ok then
				PanelController.sound("reward")
				punch(row.frame)
				confetti(row.btn)
			else
				PanelController.sound("error")
				UiKit.toast(PanelController.errorText(result), theme.Danger)
			end
		end)
	end

	local function refresh()
		local st = state()
		local sp = sessionPass()
		local tier = BattlePass.tierOf(st.xp)
		local inTier = st.xp - tier * CFG.XpPerTier
		tierL.Text = tostring(tier)
		if tier >= CFG.Tiers then
			barFill.Size = UDim2.fromScale(1, 1)
			xpL.Text = string.format(S.xpMax, UiKit.formatNumber(CFG.BonusKeyXp))
		else
			tween(barFill, 0.5, { Size = UDim2.fromScale(math.clamp(inTier / CFG.XpPerTier, 0.04, 1), 1) })
			xpL.Text = string.format(S.xp, UiKit.formatNumber(inTier), UiKit.formatNumber(CFG.XpPerTier))
		end
		local left = math.max(0, (sp.endsAt or 0) - ClientState.serverNow())
		timeL.Text = if left >= 86400 then string.format(S.ends, left // 86400, (left % 86400) // 3600) else string.format(S.endsHours, left // 3600, (left % 3600) // 60)
		catchChip.Visible = sp.behind == true
		local today = Formulas.dayNumber(ClientState.serverNow())
		capChip.Visible = st.playDay == today and st.playXp >= CFG.PlayXpPerDay

		-- rail fill reaches the current node plus progress toward the next one
		local frac = if tier >= CFG.Tiers then 1 else math.clamp((tier - 1 + inTier / CFG.XpPerTier) / (CFG.Tiers - 1), 0, 1)
		tween(lineFill, 0.5, { Size = UDim2.fromScale(frac, 1) })
		for i, node in nodes do
			local reached = i <= tier
			node.BackgroundColor3 = if reached then GOLD else WHITE
			node.Size = if i == math.max(tier, 1) then UDim2.fromOffset(54, 54) else UDim2.fromOffset(40, 40)
		end
		local cur = nodes[math.max(tier, 1)]
		ring.Position = cur.Position
		toGo.Text = if tier >= CFG.Tiers then S.finaleDone else string.format(S.toGo, CFG.Tiers - tier)

		local claimable = 0
		for _, t in tiles do
			local isPrem = t.track == "prem"
			local claimed = BattlePass.isClaimed(st, t.track, t.tier)
			local reached = t.tier <= tier
			local can = reached and not claimed and (not isPrem or st.premium)
			t.check.Visible = claimed
			t.get.Visible = can
			for _, n in t.names do
				n.Visible = not can -- GET takes the name's place
			end
			t.glow.BackgroundTransparency = if can then 0.35 else 1
			t.dim.Visible = not reached
			local lockedHere = isPrem and not st.premium and not claimed
			if lockedHere and reached then
				t.glow.BackgroundColor3 = GOLD
				t.glow.BackgroundTransparency = 0.3
			else
				t.glow.BackgroundColor3 = GREEN
			end
			if t.lock then
				local w = (t.lock :: GuiObject):FindFirstChild("Waiting")
				if w and w:IsA("GuiObject") then
					w.Visible = lockedHere and reached
				end
				-- reached-but-locked tiles read brighter than tiers not reached yet
				(t.lock :: Frame).BackgroundTransparency = if reached then 0.92 else 0.78
			end
			if t.lock then
				(t.lock :: GuiObject).Visible = not st.premium
			end
			if can then
				claimable += 1
			end
		end
		claimAllBtn.Visible = claimable >= 2
		claimAllBtn.Text = string.format(S.claimAll, claimable)

		local plusHidden = sp.endsAt and (sp.endsAt - ClientState.serverNow()) < CFG.PlusHideSeconds
		if st.premium then
			unlockL.Text = S.owner
			unlockL.Size = UDim2.fromScale(0.92, 0.84)
			unlockL.Position = UDim2.fromScale(0.04, 0.08)
			thumb.Visible = false
			unlockBtn.BackgroundColor3 = GOLD
			unlockPulse.Scale = 1
			ownerCrown.Visible = true
			valuePill.Visible = false
			-- owners: a fair +10 (not Premium+ again) and the single tier, filling the space under the badge
			plusBtn.Text = string.format(S.plusOne, CFG.Robux.tiers10)
			plusBtn.Visible = tier < CFG.Tiers
			plusBtn.Position = UDim2.fromScale(0, 0.72)
			jumpTag.Visible = false
			tierBtn.Text = string.format(S.tierSkip, CFG.Robux.tier)
			tierBtn.Visible = tier < CFG.Tiers
		else
			local secsLeft = math.max(0, (sp.endsAt or 0) - ClientState.serverNow())
			unlockL.Text = if plusHidden then string.format(S.unlockLate, CFG.Robux.premium, secsLeft // 3600) else string.format(S.unlockNamed, string.upper(hookItem.name), CFG.Robux.premium)
			unlockL.Size = UDim2.fromScale(0.72, 0.84)
			unlockL.Position = UDim2.fromScale(0.27, 0.08)
			thumb.Visible = true
			tierBtn.Visible = false
			unlockBtn.BackgroundColor3 = GREEN
			ownerCrown.Visible = false
			valuePill.Visible = true
			plusBtn.Position = UDim2.fromScale(0, 0.88)
			local got = BattlePass.premiumReached(st, function(id)
				local it = Catalog.byId(id)
				return if it and it.type == "skin" then it.rarity else nil
			end)
			local any = got.legendary + got.rare + got.gems > 0
			valueRow.Visible = any
			valueRow.Text = string.format(S.waitingWords, got.legendary, got.rare, UiKit.formatNumber(got.gems))
			valueL.Text = if any then S.waitingShort else S.worth
			valueL.Position = if any then UDim2.fromScale(0.04, 0.56) else UDim2.fromScale(0.04, 0.2)
			valueL.Size = if any then UDim2.fromScale(0.92, 0.38) else UDim2.fromScale(0.92, 0.6)
			-- +10 tiers that would pass a Legendary right away says so
			local jump: Catalog.Item? = nil
			for _, lt in BattlePass.legendaryTiers do
				if lt > tier and lt <= tier + 10 and lt > 1 then
					jump = Catalog.byId(BattlePass.tiers[lt].prem[1].id :: string)
					break
				end
			end
			plusBtn.Text = string.format(S.plusOne, CFG.Robux.plus)
			plusBtn.Visible = not plusHidden
			jumpTag.Visible = jump ~= nil
			if jump then
				jumpL.Text = string.format(S.jumpTag, jump.name)
			end
		end

		-- missions
		local p = ClientState.profile
		local list = if p then p.quests.list else {}
		local open = 0
		for i, row in rows do
			local entry = list[i]
			local q = if entry then ClientState.quest(entry.id) else nil
			row.frame.Visible = q ~= nil
			if entry and q then
				local fmt = S.questKinds[q.kind] or "%s"
				row.text.Text = string.format(fmt, UiKit.formatNumber(q.target))
				row.icon.Image = ArcadeIcons[QUEST_ICONS[q.kind] or "gameplay_territory"] or row.icon.Image
				local pr = math.min(entry.progress, q.target)
				row.fill.Size = UDim2.fromScale(math.clamp(pr / q.target, 0, 1), 1)
				row.prog.Text = UiKit.formatNumber(math.floor(pr)) .. " / " .. UiKit.formatNumber(q.target)
				local xp = BattlePass.missionXp(i, sp.behind == true)
				row.xp.Text = string.format(S.missionXp, UiKit.formatNumber(xp))
				row.reward.Text = "+" .. UiKit.formatNumber(q.reward.amount) .. " " .. q.reward.currency
				local done = entry.progress >= q.target
				row.btn.Text = if entry.claimed then S.claimed elseif done then S.claim else S.go
				row.btn.BackgroundColor3 = if entry.claimed then Color3.fromHex("DAD8D2") elseif done then GREEN else Color3.fromHex("43D8E8")
				if done and not entry.claimed then
					punch(row.btn)
				end
				if done and not entry.claimed then
					open += 1
				end
			end
		end
		missionDot.Visible = open > 0
		missionCount.Text = tostring(open)
		local secs = 86400 - (ClientState.serverNow() % 86400)
		sheetTime.Text = string.format(S.missionsNew, secs // 3600, (secs % 3600) // 60)

		if hudDot then
			(hudDot :: (number) -> ())(claimable + open)
		end

		-- one-time "you just passed a Legendary" prompt for free players: first open (tier 1), tiers 10 and 20
		if not st.premium and isOpen then
			for _, pair in { { 4, 1 }, { 1, 10 }, { 2, 20 } } do
				local bitN, at = pair[1], pair[2]
				if tier >= at and not bit32.btest(st.seen, bitN) and not popupShown[bitN] then
					popupShown[bitN] = true
					task.spawn(ClientState.request, Remotes.Requests.BattlePass, "seen", nil, bitN)
					local it = Catalog.byId(BattlePass.tiers[at].prem[1].id :: string)
					if it then
						PassController.passedPopup(it, if at == 1 then S.firstTitle else nil)
					end
					break
				end
			end
		end
	end
	refreshFn = refresh

	closeBtn.Activated:Connect(function()
		PassController.close()
	end)

	-- Short screens (phones in landscape): the pass takes the whole screen and the lane labels drop
	-- their text, so tiles and text stay big enough to read.
	function PassController._fitScreen()
		local cam = workspace.CurrentCamera
		local compact = cam ~= nil and cam.ViewportSize.Y < COMPACT_HEIGHT
		win.Size = if compact then UDim2.fromScale(1, 1) else UDim2.fromScale(0.94, 0.86)
		win.Position = if compact then UDim2.fromScale(0.5, 0.5) else UDim2.fromScale(0.5, 0.53)
		for _, t in rail:GetChildren() do
			if t:IsA("Frame") then
				for _, l in t:GetChildren() do
					if l:IsA("TextLabel") then
						l.Visible = not compact
					end
				end
			end
		end
	end

	-- open: scroll so the next tier is in view; animate in
	function PassController._afterOpen()
		winScale.Scale = 0.85
		tween(winScale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local tier = BattlePass.tierOf(state().xp)
		local target = math.max(0, (12 + (tier - 1) * COL_W) * contentScale.Scale - scroller.AbsoluteWindowSize.X * 0.3)
		scroller.CanvasPosition = Vector2.new(0, 0)
		tween(scroller, 0.6, { CanvasPosition = Vector2.new(target, 0) }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		showSheet(false)
	end

	-- premium unlock celebration: locks pop off left to right
	function PassController._unlockShow()
		for _, t in tiles do
			local scrim = t.lock
			if scrim then
				scrim.Visible = true
				task.delay(t.tier * 0.05, function()
					tween(scrim, 0.3, { BackgroundTransparency = 1 } :: any)
					for _, d in scrim:GetDescendants() do
						if d:IsA("ImageLabel") then
							tween(d, 0.3, { ImageTransparency = 1, Size = UDim2.fromOffset(84, 84) } :: any)
						end
					end
					punch(t.frame)
					task.wait(0.35)
					scrim.Visible = false
				end)
			end
		end
		confetti(unlockBtn)
	end

	RunService.Heartbeat:Connect(function()
		if isOpen or #animated > 0 then
			local now = os.clock()
			if now - (PassController._lastAnim or 0) >= 1 / ANIM_HZ then
				PassController._lastAnim = now
				stepAnimated(now)
			end
		end
	end)
end
PassController._lastAnim = 0 :: number
PassController._fitScreen = nil :: (() -> ())?
PassController._afterOpen = nil :: (() -> ())?
PassController._unlockShow = nil :: (() -> ())?

-- Popups -------------------------------------------------------------------------------------------

local function popup(build: (card: Frame, close: () -> ()) -> ())
	local g = gui
	if not g then
		return
	end
	local shade = UiKit.frame({ Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, Active = true, ZIndex = 90, parent = g })
	local rays = UiKit.icon("economy_star", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.7, 0.9), ImageTransparency = 0.75, ZIndex = 91, parent = shade })
	UiKit.aspect(rays, 1)
	tween(rays, 6, { Rotation = 360 }, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1)
	local card = UiKit.frame({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.34, 0.62), BackgroundColor3 = CREAM, ZIndex = 92, parent = shade })
	UiKit.corner(card, 20)
	UiKit.stroke(card, INK, 4)
	local sc = Instance.new("UIScale")
	sc.Scale = 0.3
	sc.Parent = card
	tween(sc, 0.4, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local function close()
		shade:Destroy()
	end
	build(card, close)
end

function PassController.reveal(item: Catalog.Item)
	popup(function(card, close)
		local banner = UiKit.frame({ Position = UDim2.fromScale(0.05, 0.04), Size = UDim2.fromScale(0.9, 0.13), BackgroundColor3 = WHITE, ZIndex = 93, parent = card })
		UiKit.corner(banner, 10)
		UiKit.stroke(banner, INK, 3)
		gradient(banner, GOLD_LIGHT, GOLD_DEEP, 90)
		local bl = label(banner, S.legendary, { Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1), TextColor3 = WHITE, ZIndex = 94 })
		outlined(bl, INK, 3)
		shine(banner, 1.5)
		local art = UiKit.frame({ Position = UDim2.fromScale(0.12, 0.2), Size = UDim2.fromScale(0.76, 0.5), ZIndex = 93, parent = card })
		UiKit.corner(art, 14)
		UiKit.stroke(art, INK, 3)
		skinPreview(art, item)
		label(card, item.name, { Position = UDim2.fromScale(0.05, 0.72), Size = UDim2.fromScale(0.9, 0.1), TextColor3 = INK, ZIndex = 93 })
		local equip = UiKit.button({ text = S.equipNow, color = GREEN, size = UDim2.fromScale(0.42, 0.11), position = UDim2.fromScale(0.05, 0.85), parent = card })
		equip.ZIndex = 94
		local ok = UiKit.button({ text = S.nice, color = GOLD, size = UDim2.fromScale(0.42, 0.11), position = UDim2.fromScale(0.53, 0.85), parent = card })
		ok.ZIndex = 94
		equip.Activated:Connect(function()
			ClientState.request(Remotes.Requests.Equip, item.id)
			close()
		end)
		ok.Activated:Connect(close)
		confetti(card)
	end)
end

function PassController.passedPopup(item: Catalog.Item, title: string?)
	popup(function(card, close)
		local t = label(card, if title then string.format(title, item.name) else string.format(S.popupTitle, item.name), { Position = UDim2.fromScale(0.05, 0.035), Size = UDim2.fromScale(0.9, 0.1), TextColor3 = VIOLET, ZIndex = 93 })
		local _ = t
		local art = UiKit.frame({ Position = UDim2.fromScale(0.15, 0.18), Size = UDim2.fromScale(0.7, 0.42), ZIndex = 93, parent = card })
		UiKit.corner(art, 14)
		UiKit.stroke(art, GOLD_DEEP, 4)
		skinPreview(art, item)
		label(card, S.popupBody, { Position = UDim2.fromScale(0.07, 0.615), Size = UDim2.fromScale(0.86, 0.095), TextColor3 = INK, ZIndex = 93 })
		local got = BattlePass.premiumReached(state(), function(id)
			local it = Catalog.byId(id)
			return if it and it.type == "skin" then it.rarity else nil
		end)
		local strip = UiKit.frame({ Position = UDim2.fromScale(0.06, 0.705), Size = UDim2.fromScale(0.88, 0.075), BackgroundColor3 = GOLD_LIGHT, ZIndex = 93, parent = card })
		UiKit.corner(strip, 8)
		UiKit.stroke(strip, GOLD_DEEP, 2)
		label(strip, string.format(S.waitingWords, got.legendary, got.rare, UiKit.formatNumber(got.gems)), { Size = UDim2.fromScale(0.94, 0.8), Position = UDim2.fromScale(0.03, 0.1), TextColor3 = INK, ZIndex = 94 })
		local tag = UiKit.frame({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.18), Size = UDim2.fromScale(0.42, 0.06), BackgroundColor3 = GOLD, ZIndex = 95, parent = card })
		UiKit.corner(tag, 6)
		UiKit.stroke(tag, INK, 2)
		label(tag, "LEGENDARY", { Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1), TextColor3 = INK, ZIndex = 96 })
		shine(art, 2)
		local hook = Catalog.byId(BattlePass.tiers[1].prem[1].id :: string)
		local buy = UiKit.button({ text = string.format(S.unlockNamed, string.upper(if hook then hook.name else ""), CFG.Robux.premium), color = GREEN, size = UDim2.fromScale(0.6, 0.13), position = UDim2.fromScale(0.2, 0.79), parent = card })
		buy.ZIndex = 94
		buy.TextColor3 = WHITE
		bob(buy, 0.06, 0.5)
		local later = Instance.new("TextButton")
		later.BackgroundTransparency = 1
		later.Text = S.popupLater
		later.Font = Enum.Font.GothamBold
		later.TextColor3 = MUTED
		later.TextScaled = true
		later.Size = UDim2.fromScale(0.3, 0.05)
		later.Position = UDim2.fromScale(0.35, 0.935)
		later.ZIndex = 94
		later.Parent = card
		buy.Activated:Connect(function()
			close()
			local id = Config.Ids.Products.battlePass
			if id == 0 then
				UiKit.toast(S.comingSoon)
			else
				MarketplaceService:PromptProductPurchase(Players.LocalPlayer, id)
			end
		end)
		later.Activated:Connect(close)
	end)
end

-- HUD feedback: "+120 Pass XP" floats and tier-up toasts, even with the pass closed.
local function xpFloat(amount: number)
	local g = gui
	if not g then
		return
	end
	local f = label(g, string.format(S.xpFloat, UiKit.formatNumber(amount)), {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.2),
		Size = UDim2.fromScale(0.22, 0.05),
		TextColor3 = GOLD,
		ZIndex = 70,
	})
	outlined(f, INK, 3)
	tween(f, 1.2, { Position = UDim2.fromScale(0.5, 0.15), TextTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(1.3, function()
		f:Destroy()
	end)
end

local function tierToast(tier: number)
	local g = gui
	if not g then
		return
	end
	local card = UiKit.frame({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromScale(0.2, 0.09), BackgroundColor3 = WHITE, ZIndex = 72, parent = g })
	UiKit.corner(card, 14)
	UiKit.stroke(card, INK, 3)
	gradient(card, GOLD_LIGHT, GOLD_DEEP, 90)
	local l = label(card, string.format(S.tierUp, tier), { Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1), TextColor3 = WHITE, ZIndex = 73 })
	outlined(l, INK, 3)
	local sc = Instance.new("UIScale")
	sc.Scale = 0.2
	sc.Parent = card
	tween(sc, 0.35, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	confetti(card)
	PanelController.sound("reward")
	task.delay(1.8, function()
		tween(sc, 0.2, { Scale = 0 })
		task.wait(0.25)
		card:Destroy()
	end)
end

-- API ----------------------------------------------------------------------------------------------

function PassController.open()
	if not PassController.isOpenSeason() then
		return
	end
	if not gui then
		build()
	end
	local fit = PassController._fitScreen
	if fit then
		fit()
	end
	PanelController.close()
	local r = root :: Frame
	r.Visible = true
	isOpen = true
	if refreshFn then
		(refreshFn :: () -> ())()
	end
	local after = PassController._afterOpen
	if after then
		after()
	end
end

function PassController.close()
	if root then
		(root :: Frame).Visible = false
	end
	isOpen = false
end

-- True while missions give double XP (shown on the HUD Pass button).
function PassController.isBehind(): boolean
	return PassController.isOpenSeason() and sessionPass().behind == true
end

function PassController.isOpen(): boolean
	return isOpen
end

-- HUD rail button hook: called with the number of things to claim (rewards + finished missions).
function PassController.onDot(fn: (number) -> ())
	hudDot = fn
end

function PassController.start()
	if not gui then
		build()
		PassController.close()
	end
	ClientState.profileChanged:Connect(function()
		local st = state()
		local tier = BattlePass.tierOf(st.xp)
		if lastTier >= 0 and tier > lastTier and PassController.isOpenSeason() then
			tierToast(tier)
		end
		lastTier = tier
		if refreshFn then
			(refreshFn :: () -> ())()
		end
	end)
	local ev = ReplicatedStorage:WaitForChild(Remotes.Folder):WaitForChild(Remotes.PassEvent) :: RemoteEvent
	ev.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then
			return
		end
		if payload.kind == "xp" and type(payload.amount) == "number" then
			xpFloat(payload.amount)
		elseif payload.kind == "delivered" then
			UiKit.toast(string.format(S.delivered, payload.count or 0), theme.Success)
		elseif payload.kind == "product" then
			UiKit.toast(S.premiumGot, theme.Success)
			local show = PassController._unlockShow
			if show and isOpen then
				show()
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(30)
			if isOpen and refreshFn then
				(refreshFn :: () -> ())()
			end
		end
	end)
end

return PassController
