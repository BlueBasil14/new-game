--!strict
-- Always-on HUD: wallet, map %, boost/weekend/friend chips, invite button, leaderboard, kill feed, button rail, playtime bar.
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local SocialService = game:GetService("SocialService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Types = require(Shared.Types)
local Catalog = require(Shared.Catalog)
local Formulas = require(Shared.Formulas)
local Remotes = require(Shared.Remotes)
local UiKit = require(script.Parent.Parent.ui.UiKit)
local ClientState = require(script.Parent.Parent.ClientState)
local PanelController = require(script.Parent.PanelController)
local ArenaClient = require(script.Parent.ArenaClient)
local TurfRenderer = require(script.Parent.TurfRenderer)
local FeedbackController = require(script.Parent.FeedbackController)
local MusicController = require(script.Parent.MusicController)

local S = {
	coinsIcon = "economy_coin",
	gemsIcon = "economy_gem",
	crownsIcon = "economy_crown",
	mapLabel = "YOUR TERRITORY",
	percent = "%.1f%%",
	boost = "%dx %s",
	weekend = "%dx WEEKEND",
	crownRush = "CROWN RUSH: KING %dx",
	friend = "+%d%% FRIEND",
	inviteIcon = "core_friends",
	speedIcon = "economy_energy",
	speedLabel = "%dx",
	skipIcon = "gameplay_skip",
	kingMark = "K",
	starterBadge = "!",
	cutFeed = "%s cut %s",
	unknownRunner = "Someone",
	timeFormat = "%d:%02d",
	claimed = "OK",
	rewardClaimed = "Reward claimed",
	rail = {
		{ panel = "Shop", text = "Shop" },
		{ panel = "Upgrades", text = "Upgrades" },
		{ panel = "Quests", text = "Quests" },
		{ panel = "Daily", text = "Daily" },
		{ panel = "Rebirth", text = "Rebirth" },
		{ panel = "Codes", text = "Codes" },
		{ panel = "Settings", text = "Settings" },
	},
}

local BOARD_ROWS = 8
local MAX_FEED = 4
local FEED_SECONDS = 5
local FEED_FADE = 0.5
local ROLL_SECONDS = 0.5
local TICK_SECONDS = 0.5
local MINI_BLOCK = 8 -- cells per minimap block side
local MINI_HEIGHT = 0.16 -- fraction of screen height
local MINI_BLOCKS_PER_TICK = 100
local MINI_DOT = 7
local MINI_DOT_PERIOD = 0.1
local MINI_BLOCK_EVERY = 5 -- dot periods per block refresh (2 Hz)
local INVITE_SIZE = 0.55 -- invite button side as a fraction of the minimap side
local INVITE_GAP = 6 -- px between the invite button and the minimap

local theme = UiKit.theme
local PANEL_BG = Color3.fromHex("FFF9EE")
local INK = Color3.fromHex("202840")
local CYAN = Color3.fromHex("43D8E8")
local LILAC = Color3.fromHex("C9B7FF")

local started = false
local railButtons: { [string]: TextButton } = {}

local function formatTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return string.format(S.timeFormat, seconds // 60, seconds % 60)
end

local function escapeRich(text: string): string
	return (string.gsub(text, "[<>&]", ""))
end

local function playerColorHex(colorIndex: number): string
	return Config.Colors.Players[colorIndex] or Config.Colors.UiLight
end

local VIP_GOLD_HEX = Config.Colors.Yellow

-- RunnerInfo.vip is added by the server later; nil counts as false.
local function isVip(runner: Types.RunnerInfo): boolean
	return (runner :: any).vip == true
end

local function currencyColor(currency: string): Color3
	return if currency == "gems" then theme.Gem else theme.Yellow
end

-- Wallet ------------------------------------------------------------------------------------

local function walletRow(parent: Frame, order: number, icon: string, color: Color3): TextLabel
	local row = UiKit.frame({
		Name = "Row" .. order,
		BackgroundColor3 = PANEL_BG,
		Size = UDim2.fromScale(0.32, 1),
		LayoutOrder = order,
		parent = parent,
	})
	UiKit.corner(row, 14)
	UiKit.stroke(row, INK, 3)
	local badge = UiKit.frame({
		Name = "Badge",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.04, 0.5),
		Size = UDim2.fromScale(0.28, 0.85),
		BackgroundColor3 = color,
		BackgroundTransparency = 1,
		parent = row,
	})
	UiKit.corner(badge, 100)
	UiKit.aspect(badge, 1)
	local mark = UiKit.icon(icon, {
		Size = UDim2.fromScale(1, 1),
		parent = badge,
	})
	mark.Name = "Mark"
	UiKit.label({ Name = "Currency", Text = ({ "Coins", "Gems", "Crowns" })[order], TextColor3 = INK, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.35, 0.08), Size = UDim2.fromScale(0.61, 0.23), parent = row })
	return UiKit.label({
		Name = "Value",
		TextColor3 = INK,
		Text = "0",
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromScale(0.61, 0.55),
		Position = UDim2.fromScale(0.35, 0.33),
		parent = row,
	})
end

-- Roblox's own top-bar buttons sit top-left; the wallet and rail start below them.
local function belowTopbar(frame: Frame, xScale: number, yScale: number)
	local function place()
		frame.Position = UDim2.new(xScale, 0, yScale, GuiService.TopbarInset.Height)
	end
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(place)
	place()
end

local function buildWallet(gui: ScreenGui)
	local wallet = UiKit.frame({
		Name = "Wallet",
		Size = UDim2.fromScale(0.34, 0.075),
		BackgroundColor3 = PANEL_BG,
		BackgroundTransparency = 1,
		parent = gui,
	})
	belowTopbar(wallet, 0.012, 0.02)
	UiKit.corner(wallet, 12)
	UiKit.list(wallet, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.02, 0) })

	local labels = {
		coins = walletRow(wallet, 1, S.coinsIcon, theme.Yellow),
		gems = walletRow(wallet, 2, S.gemsIcon, theme.Gem),
		crowns = walletRow(wallet, 3, S.crownsIcon, theme.Pink),
	}
	local shown: { [string]: number } = {}

	local function update()
		local p = ClientState.profile
		if p == nil then
			return
		end
		local values = { coins = p.coins, gems = p.gems, crowns = p.crowns }
		for key, label in labels do
			local new = values[key]
			local old = shown[key]
			if old == nil then
				UiKit.rollNumber(label, new, new, 0)
			elseif old ~= new then
				UiKit.rollNumber(label, old, new, ROLL_SECONDS)
			end
			shown[key] = new
		end
	end
	ClientState.profileChanged:Connect(update)
	update()
	-- ponytail: coin drop on server-sent capture/kill rewards only; passive income (every 10 s) stays silent.
	ClientState.reward:Connect(function(payload: any)
		if type(payload) == "table" and type(payload.coins) == "number" and payload.coins > 0 then
			FeedbackController.play("coinDrop")
		end
	end)
end

-- Top centre: map %, boost chip, weekend chip -----------------------------------------------

local function chip(parent: Instance, name: string, width: number, color: Color3, order: number): (Frame, TextLabel, TextLabel)
	local f = UiKit.frame({
		Name = name,
		Size = UDim2.fromScale(width, 1),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.15,
		LayoutOrder = order,
		parent = parent,
	})
	UiKit.corner(f, 12)
	local top = UiKit.label({
		Name = "Main",
		Size = UDim2.fromScale(0.9, 0.55),
		Position = UDim2.fromScale(0.05, 0.05),
		parent = f,
	})
	local sub = UiKit.label({
		Name = "Sub",
		Size = UDim2.fromScale(0.9, 0.3),
		Position = UDim2.fromScale(0.05, 0.64),
		TextTransparency = 0.25,
		parent = f,
	})
	return f, top, sub
end

local function buildTopCentre(gui: ScreenGui)
	local holder = UiKit.frame({
		Name = "TopCentre",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.02),
		Size = UDim2.fromScale(0.30, 0.10),
		parent = gui,
	})
	

	local mapChip, mapMain, mapSub = chip(holder, "Map", 0.48, PANEL_BG, 1)
	mapChip.Position = UDim2.fromScale(0.26, 0)
	mapChip.BackgroundTransparency = 1
	mapMain.TextColor3 = Color3.new(1, 1, 1)
	mapMain.TextStrokeColor3 = INK
	mapMain.TextStrokeTransparency = 0
	mapSub.TextColor3 = INK
	mapSub.TextTransparency = 0
	mapSub.Text = S.mapLabel
	mapMain.Text = string.format(S.percent, 0)

	local boostChip, boostMain, boostSub = chip(holder, "Boost", 0.3, theme.Pink, 2)
	boostChip.Position = UDim2.fromScale(0, 1.1)
	boostChip.Size = UDim2.fromScale(0.31, 0.55)
	boostChip.Visible = false
	boostSub.Text = ""

	local weekendChip, weekendMain, weekendSub = chip(holder, "Weekend", 0.3, theme.Success, 3)
	weekendSub.Text = ""
	weekendChip.Position = UDim2.fromScale(0.345, 1.1)
	weekendChip.Size = UDim2.fromScale(0.31, 0.55)
	weekendChip.Visible = false
	weekendMain.Text = string.format(S.weekend, Config.Income.WeekendMultiplier)
	weekendMain.TextColor3 = theme.UiDark
	weekendMain.Size = UDim2.fromScale(0.9, 0.7)
	weekendMain.Position = UDim2.fromScale(0.05, 0.15)

	local friendChip, friendMain, friendSub = chip(holder, "Friend", 0.3, theme.Gem, 4)
	friendSub.Text = ""
	friendChip.Position = UDim2.fromScale(0.69, 1.1)
	friendChip.Size = UDim2.fromScale(0.31, 0.55)
	friendChip.Visible = false
	friendMain.Text = string.format(S.friend, math.floor(Config.Income.FriendBonus * 100 + 0.5))
	friendMain.TextColor3 = theme.UiDark
	friendMain.Size = UDim2.fromScale(0.9, 0.7)
	friendMain.Position = UDim2.fromScale(0.05, 0.15)

	local lastPct = -1
	local function updateMap()
		local pct = math.floor(ClientState.myShare() * 1000 + 0.5) / 10
		if pct ~= lastPct then
			lastPct = pct
			mapMain.Text = string.format(S.percent, pct)
		end
	end
	ClientState.arenaChanged:Connect(updateMap)

	local function updateTimers()
		local now = ClientState.serverNow()
		local p = ClientState.profile
		local left = if p then p.boostUntil - now else 0
		if left > 0 then
			boostChip.Visible = true
			boostMain.Text = string.format(S.boost, Config.Income.BoostMultiplier, formatTime(left))
		else
			boostChip.Visible = false
		end
		-- The weekend chip doubles as the Crown Rush chip while that event runs.
		local rush = Formulas.isCrownRush(now)
		weekendChip.Visible = rush or Formulas.isWeekendUTC(now)
		weekendMain.Text = if rush
			then string.format(S.crownRush, Config.CrownRush.KingMultiplier)
			else string.format(S.weekend, Config.Income.WeekendMultiplier)
		friendChip.Visible = ClientState.session.withFriend == true
	end
	return updateTimers, updateMap
end

-- Leaderboard -------------------------------------------------------------------------------

type BoardRow = {
	root: Frame,
	crown: Frame,
	swatch: Frame,
	name: TextLabel,
	percent: TextLabel,
}

type BoardEntry = { id: number, runner: Types.RunnerInfo, cells: number }

local function buildLeaderboard(gui: ScreenGui)
	local board = UiKit.frame({
		Name = "Leaderboard",
		BackgroundColor3 = PANEL_BG,
		BackgroundTransparency = 0,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.988, 0.02),
		Size = UDim2.fromScale(0.2, 0.33),
		parent = gui,
	})
	UiKit.corner(board, 16)
	UiKit.stroke(board, INK, 3)
	UiKit.padding(board, 0.04)
	UiKit.list(board, { Padding = UDim.new(0.008, 0) })
	local heading = UiKit.frame({ Name = "Heading", Size = UDim2.fromScale(1, 0.13), BackgroundTransparency = 1, LayoutOrder = 0, parent = board })
	UiKit.icon("core_leaderboard", { Size = UDim2.fromScale(0.18, 1), parent = heading })
	UiKit.label({ Text = "Top runners", TextColor3 = INK, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.22, 0), Size = UDim2.fromScale(0.77, 1), parent = heading })

	local rows: { BoardRow } = {}
	for i = 1, BOARD_ROWS do
		local root = UiKit.frame({
			Name = "Row" .. i,
			Size = UDim2.fromScale(1, 0.098),
			BackgroundColor3 = PANEL_BG,
			BackgroundTransparency = 0.35,
			LayoutOrder = i,
			Visible = false,
			parent = board,
		})
		UiKit.corner(root, 8)
		local crown = UiKit.frame({
			Name = "Crown",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.015, 0.5),
			Size = UDim2.fromScale(0.09, 0.7),
			BackgroundColor3 = theme.Yellow,
			Visible = false,
			parent = root,
		})
		UiKit.corner(crown, 100)
		UiKit.aspect(crown, 1)
		crown.BackgroundTransparency = 1
		UiKit.icon("economy_crown", {
			Size = UDim2.fromScale(1, 1),
			parent = crown,
		})
		local swatch = UiKit.frame({
			Name = "Swatch",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.125, 0.5),
			Size = UDim2.fromScale(0.09, 0.62),
			parent = root,
		})
		UiKit.corner(swatch, 4)
		UiKit.aspect(swatch, 1)
		local name = UiKit.label({
			Name = "Name",
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromScale(0.45, 0.7),
			Position = UDim2.fromScale(0.24, 0.15),
			parent = root,
		})
		local percent = UiKit.label({
			Name = "Percent",
			TextXAlignment = Enum.TextXAlignment.Right,
			Size = UDim2.fromScale(0.26, 0.7),
			Position = UDim2.fromScale(0.72, 0.15),
			parent = root,
		})
		rows[i] = { root = root, crown = crown, swatch = swatch, name = name, percent = percent }
	end

	local function update()
		local arena = ClientState.arena
		local list: { BoardEntry } = {}
		for id, runner in arena.runners do
			table.insert(list, { id = id, runner = runner, cells = arena.cells[id] or 0 })
		end
		table.sort(list, function(a: BoardEntry, b: BoardEntry)
			if a.cells ~= b.cells then
				return a.cells > b.cells
			end
			return a.id < b.id
		end)
		for i, row in rows do
			local entry = list[i]
			if entry == nil then
				row.root.Visible = false
			else
				row.root.Visible = true
				row.swatch.BackgroundColor3 = Color3.fromHex(playerColorHex(entry.runner.colorIndex))
				row.name.Text = entry.runner.name
				row.name.TextColor3 = if isVip(entry.runner) then Color3.fromHex("8A5900") else INK
				row.percent.TextColor3 = INK
				row.percent.Text = string.format(S.percent, entry.cells / arena.totalCells * 100)
				row.crown.Visible = entry.id == arena.kingId
				local mine = entry.id == arena.myId
				row.root.BackgroundColor3 = if mine then Color3.fromHex("C7F3ED") else PANEL_BG
				row.root.BackgroundTransparency = 0
			end
		end
	end
	ClientState.arenaChanged:Connect(update)
end

-- Kill feed ---------------------------------------------------------------------------------

local function buildKillFeed(gui: ScreenGui)
	local feed = UiKit.frame({
		Name = "KillFeed",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.988, 0.36),
		Size = UDim2.fromScale(0.2, 0.2),
		parent = gui,
	})
	UiKit.list(feed, { Padding = UDim.new(0.02, 0), HorizontalAlignment = Enum.HorizontalAlignment.Right })

	local entries: { Frame } = {}
	local counter = 0

	local function tag(id: number): string
		local runner = ClientState.arena.runners[id]
		if runner == nil then
			return S.unknownRunner
		end
		local hex = if isVip(runner) then VIP_GOLD_HEX else playerColorHex(runner.colorIndex)
		return string.format('<font color="%s">%s</font>', hex, escapeRich(runner.name))
	end

	local function remove(entry: Frame)
		local i = table.find(entries, entry)
		if i then
			table.remove(entries, i)
		end
		entry:Destroy()
	end

	ClientState.arenaEvent:Connect(function(event: Types.ArenaEvent)
		if event.kind ~= "cut" then
			return
		end
		counter += 1
		local mine = event.killer == ClientState.arena.myId or event.victim == ClientState.arena.myId
		local entry = UiKit.frame({
			Name = "Entry",
			Size = UDim2.fromScale(1, 0.2),
			BackgroundColor3 = if mine then theme.Pink else PANEL_BG,
			BackgroundTransparency = 0.3,
			LayoutOrder = counter,
			parent = feed,
		})
		UiKit.corner(entry, 8)
		local label = UiKit.label({
			Text = string.format(S.cutFeed, tag(event.killer), tag(event.victim)),
			RichText = true,
			Size = UDim2.fromScale(0.94, 0.7),
			Position = UDim2.fromScale(0.03, 0.15),
			parent = entry,
		})
		table.insert(entries, entry)
		while #entries > MAX_FEED do
			remove(entries[1])
		end
		task.delay(FEED_SECONDS - FEED_FADE, function()
			if entry.Parent == nil then
				return
			end
			TweenService:Create(entry, TweenInfo.new(FEED_FADE), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(label, TweenInfo.new(FEED_FADE), { TextTransparency = 1 }):Play()
			task.wait(FEED_FADE)
			if entry.Parent then
				remove(entry)
			end
		end)
	end)
end

-- Button rail -------------------------------------------------------------------------------

local RAIL_BUTTON_HEIGHT = 0.115
local RAIL_TEXT_WIDTH_DIVISOR = 5.2 -- widest label ("Upgrades") fits when TextSize <= width / this

local function buildRail(gui: ScreenGui): (() -> ())
	local rail = UiKit.frame({
		Name = "Rail",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.13, 0.48),
		parent = gui,
	})
	belowTopbar(rail, 0.012, 0.13)
	UiKit.list(rail, { Padding = UDim.new(0.032, 0) })

	local dots: { [string]: Frame } = {}
	for i, def in S.rail do
		local b = UiKit.button({
			text = def.text,
			color = if def.panel == "Shop" then theme.Yellow elseif def.panel == "Upgrades" then CYAN elseif def.panel == "Daily" then LILAC else PANEL_BG,
			size = UDim2.fromScale(1, RAIL_BUTTON_HEIGHT),
			parent = rail,
			onClick = function()
				PanelController.sound("click")
				PanelController.open(def.panel)
			end,
		})
		b.Name = def.panel
		b.LayoutOrder = i
		railButtons[def.panel] = b
		UiKit.icon("core_" .. string.lower(def.panel), {
			Name = "MenuIcon",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.04, 0.5),
			Size = UDim2.fromScale(0.22, 0.8),
			parent = b,
		})
		-- A separate caption keeps text padding from shifting the decorative icon.
		b.TextTransparency = 1
		UiKit.label({
			Name = "Caption",
			Text = def.text,
			TextColor3 = theme.UiDark,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextScaled = false,
			Position = UDim2.fromScale(0.32, 0),
			Size = UDim2.fromScale(0.64, 1),
			parent = b,
		})
		b.TextScaled = false -- TextScaled gave each label its own size; one size for the whole rail
		if def.panel == "Shop" then
			local badge = UiKit.frame({
				Name = "StarterBadge",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.94, 0.08),
				Size = UDim2.fromScale(0.24, 0.24),
				BackgroundColor3 = theme.Pink,
				Visible = false,
				parent = b,
			})
			UiKit.corner(badge, 100)
			UiKit.aspect(badge, 1)
			UiKit.stroke(badge, theme.UiLight, 2)
			UiKit.label({
				Text = S.starterBadge,
				Size = UDim2.fromScale(0.7, 0.7),
				Position = UDim2.fromScale(0.15, 0.15),
				parent = badge,
			})
			dots.Shop = badge
		end
		if def.panel == "Daily" or def.panel == "Quests" then
			local dot = UiKit.frame({
				Name = "Dot",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.94, 0.08),
				Size = UDim2.fromScale(0.2, 0.2),
				BackgroundColor3 = theme.Danger,
				Visible = false,
				parent = b,
			})
			UiKit.corner(dot, 100)
			UiKit.aspect(dot, 1)
			UiKit.stroke(dot, theme.UiLight, 2)
			dots[def.panel] = dot
		end
	end

	local function fitRailText()
		local width = rail.AbsoluteSize.X
		local height = rail.AbsoluteSize.Y * RAIL_BUTTON_HEIGHT
		local size = math.max(math.floor(math.min(height * 0.55, width * 0.64 / RAIL_TEXT_WIDTH_DIVISOR)), 8)
		for _, b in railButtons do
			b.TextSize = size
			local caption = b:FindFirstChild("Caption")
			if caption and caption:IsA("TextLabel") then
				caption.TextSize = size
			end
		end
	end
	rail:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitRailText)
	fitRailText()

	return function()
		local daily = dots.Daily
		if daily then
			daily.Visible = ClientState.dailyState().canClaim
		end
		local quests = dots.Quests
		if quests then
			quests.Visible = ClientState.questClaimable()
		end
		local shop = dots.Shop
		if shop then
			shop.Visible = ClientState.starterOfferOpen()
		end
	end
end

-- Minimap -----------------------------------------------------------------------------------

local function runnerPosition(id: number): Vector3?
	local info = ClientState.arena.runners[id]
	if not info then
		return nil
	end
	local inst: Instance? = nil
	if info.isBot then
		local bots = workspace:FindFirstChild("Bots")
		inst = bots and bots:FindFirstChild(tostring(id))
	else
		local player = Players:GetPlayerByUserId(info.userId)
		local char = player and player.Character
		inst = char and char:FindFirstChild("HumanoidRootPart")
	end
	if inst and inst:IsA("PVInstance") then
		return inst:GetPivot().Position
	end
	return nil
end

-- Square overview of the arena: one Frame per MINI_BLOCK x MINI_BLOCK cells (built once), coloured by
-- the majority owner of the block's 4 centre cells. Blocks refresh round-robin at 2 Hz.
local function buildMinimap(gui: ScreenGui)
	local blocks = Config.Arena.GridSize // MINI_BLOCK
	local neutral = PANEL_BG:Lerp(theme.UiLight, 0.12)
	local root = UiKit.frame({
		Name = "Minimap",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(0.988, 0.78),
		Size = UDim2.fromScale(MINI_HEIGHT, MINI_HEIGHT),
		BackgroundColor3 = PANEL_BG,
		BackgroundTransparency = 0.2,
		ClipsDescendants = true,
		parent = gui,
	})
	UiKit.corner(root, 8)
	UiKit.aspect(root, 1)

	local frames: { Frame } = {}
	local shown: { Color3 } = {}
	local step = 1 / blocks
	for by = 0, blocks - 1 do
		for bx = 0, blocks - 1 do
			local i = by * blocks + bx + 1
			frames[i] = UiKit.frame({
				Name = "B" .. i,
				Position = UDim2.fromScale(bx * step, by * step),
				Size = UDim2.fromScale(step, step),
				BackgroundColor3 = neutral,
				parent = root,
			})
			shown[i] = neutral
		end
	end

	local function makeDot(name: string, color: Color3, z: number): Frame
		local d = UiKit.frame({
			Name = name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(MINI_DOT, MINI_DOT),
			BackgroundColor3 = color,
			ZIndex = z,
			Visible = false,
			parent = root,
		})
		UiKit.corner(d, 100)
		return d
	end
	local kingDot = makeDot("King", theme.Yellow, 2)
	local meDot = makeDot("Me", theme.UiLight, 3)

	local samples: { number } = { 0, 0, 0, 0 }
	local half = MINI_BLOCK // 2
	local cursor = 0
	local lastGrid: any = nil

	local function refreshBlock(g: any, i: number)
		local bx, by = (i - 1) % blocks, (i - 1) // blocks
		local x0, y0 = bx * MINI_BLOCK + half - 1, by * MINI_BLOCK + half - 1
		samples[1], samples[2] = g:get(x0, y0), g:get(x0 + 1, y0)
		samples[3], samples[4] = g:get(x0, y0 + 1), g:get(x0 + 1, y0 + 1)
		local best, bestN = 0, 0
		for k = 1, 4 do
			local o = samples[k]
			if o ~= 0 then
				local n = 0
				for j = 1, 4 do
					if samples[j] == o then
						n += 1
					end
				end
				if n > bestN then
					best, bestN = o, n
				end
			end
		end
		local color = if best == 0 then neutral else TurfRenderer.colorOf(best)
		if shown[i] ~= color then
			shown[i] = color
			frames[i].BackgroundColor3 = color
		end
	end

	local function placeDot(dot: Frame, g: any, pos: Vector3?)
		if pos == nil then
			dot.Visible = false
			return
		end
		local cx, cy = g:worldToCell(pos.X, pos.Z)
		dot.Position = UDim2.fromScale((cx + 0.5) / g.size, (cy + 0.5) / g.size)
		dot.Visible = true
	end

	task.spawn(function()
		local periods = 0
		while true do
			task.wait(MINI_DOT_PERIOD)
			local profile = ClientState.profile
			local low = profile ~= nil and profile.settings.lowDetail
			root.Visible = not low
			local g: any = ArenaClient.getGrid()
			if low or g == nil then
				continue
			end
			periods += 1
			if g ~= lastGrid then
				lastGrid = g
				for i = 1, #frames do
					refreshBlock(g, i)
				end
			elseif periods % MINI_BLOCK_EVERY == 0 then
				for _ = 1, MINI_BLOCKS_PER_TICK do
					cursor = cursor % #frames + 1
					refreshBlock(g, cursor)
				end
			end
			local arena = ClientState.arena
			local myId = arena.myId
			placeDot(meDot, g, if myId and arena.alive then runnerPosition(myId) else nil)
			placeDot(kingDot, g, if arena.kingId ~= 0 then runnerPosition(arena.kingId) else nil)
		end
	end)
end

-- Playtime reward bar -----------------------------------------------------------------------

type Node = { wrap: Frame, button: TextButton, stroke: UIStroke, time: TextLabel }

-- Invite button: left of the minimap, top-aligned with it (clear of the mobile jump button). Hidden when invites are unavailable.
local function buildInvite(gui: ScreenGui)
	local minimap = gui:FindFirstChild("Minimap") :: Frame
	local player = Players.LocalPlayer
	local b = UiKit.button({
		color = theme.Yellow,
		parent = gui,
		onClick = function()
			PanelController.sound("click")
			pcall(SocialService.PromptGameInvite, SocialService, player)
		end,
	})
	b.Name = "Invite"
	b.AnchorPoint = Vector2.new(1, 0)
	b.Visible = false
	UiKit.stroke(b, theme.UiDark, 2)
	UiKit.icon(S.inviteIcon, {
		Size = UDim2.fromScale(0.8, 0.8),
		Position = UDim2.fromScale(0.1, 0.1),
		parent = b,
	})
	local function place()
		local side = minimap.AbsoluteSize.Y
		local size = math.floor(side * INVITE_SIZE)
		b.Size = UDim2.fromOffset(size, size)
		b.Position = UDim2.new(minimap.Position.X.Scale, -minimap.AbsoluteSize.X - INVITE_GAP, minimap.Position.Y.Scale, -side)
	end
	minimap:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
	place()
	task.spawn(function()
		local ok, can = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
		b.Visible = ok and can == true
	end)
end

-- 2x Speed (always shown: glows for owners, grey + opens the purchase prompt for others) and Skip Music (owners only),
-- both left of the minimap next to the Invite button: speed beside Invite, skip below Invite.
local function buildPassButtons(gui: ScreenGui): (() -> ())
	local minimap = gui:FindFirstChild("Minimap") :: Frame
	local grey = PANEL_BG:Lerp(INK, 0.25)
	local glow = UiKit.frame({ Name = "SpeedGlow", BackgroundColor3 = theme.Yellow, BackgroundTransparency = 0.75, parent = gui })
	UiKit.corner(glow, 16)
	TweenService:Create(glow, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.2 }):Play()

	local speed = UiKit.button({
		color = theme.Yellow,
		parent = gui,
		onClick = function()
			if ClientState.session.passes.doubleSpeed ~= true then
				PanelController.sound("click")
				PanelController.promptPass("doubleSpeed")
			end
		end,
	})
	speed.Name = "Speed"
	speed.AnchorPoint = Vector2.new(1, 0)
	local speedIcon = UiKit.icon(S.speedIcon, {
		Size = UDim2.fromScale(0.6, 0.6),
		Position = UDim2.fromScale(0.2, 0.04),
		parent = speed,
	})
	local speedText = UiKit.label({
		Text = string.format(S.speedLabel, Config.Passes.doubleSpeed.SpeedMultiplier),
		Size = UDim2.fromScale(0.8, 0.28),
		Position = UDim2.fromScale(0.1, 0.66),
		parent = speed,
	})

	local skip = UiKit.button({
		color = theme.Yellow,
		parent = gui,
		onClick = function()
			PanelController.sound("click")
			MusicController.skip()
		end,
	})
	skip.Name = "SkipMusic"
	skip.AnchorPoint = Vector2.new(1, 0)
	skip.Visible = false
	UiKit.icon(S.skipIcon, {
		Size = UDim2.fromScale(0.7, 0.7),
		Position = UDim2.fromScale(0.15, 0.15),
		parent = skip,
	})

	local function place()
		local side = minimap.AbsoluteSize.Y
		local size = math.floor(side * INVITE_SIZE)
		local small = math.floor(side * INVITE_SIZE * 0.75)
		local x = minimap.Position.X.Scale
		local y = minimap.Position.Y.Scale
		local left = -minimap.AbsoluteSize.X - INVITE_GAP
		speed.Size = UDim2.fromOffset(size, size)
		speed.Position = UDim2.new(x, left - size - INVITE_GAP, y, -side)
		glow.Size = UDim2.fromOffset(size + 10, size + 10)
		glow.AnchorPoint = Vector2.new(1, 0)
		glow.Position = UDim2.new(x, left - size - INVITE_GAP + 5, y, -side - 5)
		skip.Size = UDim2.fromOffset(small, small)
		skip.Position = UDim2.new(x, left, y, -side + size + INVITE_GAP)
	end
	minimap:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
	place()

	return function()
		local owned = ClientState.session.passes.doubleSpeed == true
		speed.BackgroundColor3 = if owned then theme.Yellow else grey
		speedIcon.ImageColor3 = if owned then Color3.new(1, 1, 1) else grey:Lerp(Color3.new(0, 0, 0), 0.3)
		speedIcon.ImageTransparency = if owned then 0 else 0.35
		speedText.TextTransparency = if owned then 0 else 0.4
		glow.Visible = owned
		skip.Visible = MusicController.canSkip()
	end
end

local function buildPlaytime(gui: ScreenGui): (() -> ())
return require(script.Parent.Parent.ui.PlaytimeRewards).build(gui)
end

local HudController = {}

-- Rail button by panel name ("Upgrades", "Shop", ...); nil until the HUD is built.
function HudController.getRailButton(name: string): TextButton?
	return railButtons[name]
end

function HudController.start()
	if started then
		return
	end
	started = true
	ClientState.start()

	local gui = UiKit.screenGui("Hud", 10)
	buildWallet(gui)
	local updateTimers, updateMap = buildTopCentre(gui)
	buildLeaderboard(gui)
	buildKillFeed(gui)
	buildMinimap(gui)
	buildInvite(gui)
	local updatePasses = buildPassButtons(gui)
	local updateDots = buildRail(gui)
	local updatePlaytime = buildPlaytime(gui)

	local function updateAll()
		updatePasses()
		updateTimers()
		updateDots()
		updatePlaytime()
	end
	ClientState.profileChanged:Connect(updateAll)
	updateMap()
	updateAll()

	task.spawn(function()
		while true do
			task.wait(TICK_SECONDS)
			updateAll()
		end
	end)
end

return HudController

