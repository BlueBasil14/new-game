--!strict
-- Always-on HUD: wallet, map %, boost/weekend chips, leaderboard, kill feed, button rail, playtime bar.
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

local S = {
	coinsIcon = "C",
	gemsIcon = "G",
	crownsIcon = "K",
	mapLabel = "MAP",
	percent = "%.1f%%",
	boost = "%dx %s",
	weekend = "%dx WEEKEND",
	kingMark = "K",
	cutFeed = "%s cut %s",
	unknownRunner = "Someone",
	timeFormat = "%d:%02d",
	claimed = "OK",
	rewardClaimed = "Reward claimed",
	rail = {
		{ panel = "Upgrades", text = "Upgrades" },
		{ panel = "Shop", text = "Shop" },
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

local theme = UiKit.theme
local PANEL_BG = Color3.fromHex(Config.Colors.UiDark)

local started = false

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

local function currencyColor(currency: string): Color3
	return if currency == "gems" then theme.Gem else theme.Yellow
end

-- Wallet ------------------------------------------------------------------------------------

local function walletRow(parent: Frame, order: number, icon: string, color: Color3): TextLabel
	local row = UiKit.frame({
		Name = "Row" .. order,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.3),
		LayoutOrder = order,
		parent = parent,
	})
	local badge = UiKit.frame({
		Name = "Badge",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromScale(0.16, 0.9),
		BackgroundColor3 = color,
		parent = row,
	})
	UiKit.corner(badge, 100)
	UiKit.aspect(badge, 1)
	local mark = UiKit.label({
		Text = icon,
		TextColor3 = theme.UiDark,
		Size = UDim2.fromScale(0.7, 0.7),
		Position = UDim2.fromScale(0.15, 0.15),
		parent = badge,
	})
	mark.Name = "Mark"
	return UiKit.label({
		Name = "Value",
		Text = "0",
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromScale(0.78, 0.8),
		Position = UDim2.fromScale(0.22, 0.1),
		parent = row,
	})
end

local function buildWallet(gui: ScreenGui)
	local wallet = UiKit.frame({
		Name = "Wallet",
		Position = UDim2.fromScale(0.012, 0.02),
		Size = UDim2.fromScale(0.17, 0.16),
		BackgroundColor3 = PANEL_BG,
		BackgroundTransparency = 0.25,
		parent = gui,
	})
	UiKit.corner(wallet, 12)
	UiKit.padding(wallet, 0.03)
	UiKit.list(wallet, { Padding = UDim.new(0.03, 0) })

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
		Size = UDim2.fromScale(0.34, 0.09),
		parent = gui,
	})
	UiKit.list(holder, {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0.02, 0),
	})

	local _, mapMain, mapSub = chip(holder, "Map", 0.34, PANEL_BG, 1)
	mapSub.Text = S.mapLabel
	mapMain.Text = string.format(S.percent, 0)

	local boostChip, boostMain, boostSub = chip(holder, "Boost", 0.3, theme.Pink, 2)
	boostChip.Visible = false
	boostSub.Text = ""

	local weekendChip, weekendMain, _ = chip(holder, "Weekend", 0.3, theme.Success, 3)
	weekendChip.Visible = false
	weekendMain.Text = string.format(S.weekend, Config.Income.WeekendMultiplier)
	weekendMain.TextColor3 = theme.UiDark
	weekendMain.Size = UDim2.fromScale(0.9, 0.7)
	weekendMain.Position = UDim2.fromScale(0.05, 0.15)

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
		weekendChip.Visible = Formulas.isWeekendUTC(now)
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
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.988, 0.02),
		Size = UDim2.fromScale(0.2, 0.33),
		parent = gui,
	})
	UiKit.list(board, { Padding = UDim.new(0.008, 0) })

	local rows: { BoardRow } = {}
	for i = 1, BOARD_ROWS do
		local root = UiKit.frame({
			Name = "Row" .. i,
			Size = UDim2.fromScale(1, 0.115),
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
		UiKit.label({
			Text = S.kingMark,
			TextColor3 = theme.UiDark,
			Size = UDim2.fromScale(0.7, 0.7),
			Position = UDim2.fromScale(0.15, 0.15),
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
				row.percent.Text = string.format(S.percent, entry.cells / arena.totalCells * 100)
				row.crown.Visible = entry.id == arena.kingId
				local mine = entry.id == arena.myId
				row.root.BackgroundColor3 = if mine then theme.Yellow else PANEL_BG
				row.root.BackgroundTransparency = if mine then 0.55 else 0.35
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
		return string.format('<font color="%s">%s</font>', playerColorHex(runner.colorIndex), escapeRich(runner.name))
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

local function buildRail(gui: ScreenGui): (() -> ())
	local rail = UiKit.frame({
		Name = "Rail",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.012, 0.2),
		Size = UDim2.fromScale(0.075, 0.42),
		parent = gui,
	})
	UiKit.list(rail, { Padding = UDim.new(0.014, 0) })

	local dots: { [string]: Frame } = {}
	for i, def in S.rail do
		local b = UiKit.button({
			text = def.text,
			color = theme.Yellow,
			size = UDim2.fromScale(1, 0.13),
			parent = rail,
			onClick = function()
				PanelController.sound("click")
				PanelController.open(def.panel)
			end,
		})
		b.Name = def.panel
		b.LayoutOrder = i
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

	return function()
		local daily = dots.Daily
		if daily then
			daily.Visible = ClientState.dailyState().canClaim
		end
		local quests = dots.Quests
		if quests then
			quests.Visible = ClientState.questClaimable()
		end
	end
end

-- Playtime reward bar -----------------------------------------------------------------------

type Node = { wrap: Frame, button: TextButton, stroke: UIStroke, time: TextLabel }

local function buildPlaytime(gui: ScreenGui): (() -> ())
	local count = #Catalog.playtime
	local function nodeX(i: number): number
		return (i - 0.5) / count
	end

	local bar = UiKit.frame({
		Name = "Playtime",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.985),
		Size = UDim2.fromScale(0.4, 0.12),
		parent = gui,
	})
	local track = UiKit.frame({
		Name = "Track",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.31),
		Size = UDim2.fromScale(1, 0.1),
		BackgroundColor3 = PANEL_BG,
		BackgroundTransparency = 0.2,
		parent = bar,
	})
	UiKit.corner(track, 100)
	local fill = UiKit.frame({
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = theme.Yellow,
		parent = track,
	})
	UiKit.corner(fill, 100)

	local nodes: { Node } = {}
	local busy = false
	for i, def in Catalog.playtime do
		local wrap = UiKit.frame({
			Name = "Node" .. i,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(nodeX(i), 0),
			Size = UDim2.fromScale(0.1, 0.62),
			BackgroundTransparency = 1,
			parent = bar,
		})
		UiKit.aspect(wrap, 1)
		local button = UiKit.button({
			text = "",
			color = PANEL_BG,
			size = UDim2.fromScale(1, 1),
			parent = wrap,
			onClick = function()
				local session = ClientState.session
				local sec = ClientState.serverNow() - session.joinedAt
				if busy or session.playtimeClaimed[i] == true or sec < def.seconds then
					return
				end
				busy = true
				local ok, result = ClientState.request(Remotes.Requests.ClaimPlaytime, i)
				busy = false
				if ok then
					PanelController.sound("reward")
					UiKit.toast(PanelController.rewardText(result, S.rewardClaimed), theme.Success)
				else
					PanelController.sound("error")
					UiKit.toast(PanelController.errorText(result), theme.Danger)
				end
			end,
		})
		local corner = button:FindFirstChildOfClass("UICorner")
		if corner then
			corner.CornerRadius = UDim.new(0.5, 0)
		end
		local stroke = UiKit.stroke(button, currencyColor(def.currency), 3)
		local time = UiKit.label({
			Name = "Time",
			Text = formatTime(def.seconds),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(nodeX(i), 0.7),
			Size = UDim2.fromScale(0.14, 0.28),
			TextTransparency = 0.2,
			parent = bar,
		})
		nodes[i] = { wrap = wrap, button = button, stroke = stroke, time = time }
	end

	local function fillFraction(sec: number): number
		local prevSec, prevX = 0, 0
		for i, def in Catalog.playtime do
			if sec < def.seconds then
				return prevX + (nodeX(i) - prevX) * (sec - prevSec) / (def.seconds - prevSec)
			end
			prevSec, prevX = def.seconds, nodeX(i)
		end
		return nodeX(count)
	end

	return function()
		local session = ClientState.session
		local sec = ClientState.serverNow() - session.joinedAt
		fill.Size = UDim2.fromScale(fillFraction(math.max(0, sec)), 1)
		for i, def in Catalog.playtime do
			local node = nodes[i]
			local claimed = session.playtimeClaimed[i] == true
			local ready = not claimed and sec >= def.seconds
			if claimed then
				node.button.Text = S.claimed
				node.button.BackgroundColor3 = theme.Success
				node.button.TextColor3 = theme.UiDark
				node.stroke.Enabled = false
			elseif ready then
				node.button.Text = UiKit.formatNumber(def.amount)
				node.button.BackgroundColor3 = currencyColor(def.currency)
				node.button.TextColor3 = theme.UiDark
				node.stroke.Enabled = true
				node.stroke.Color = theme.UiLight
			else
				node.button.Text = UiKit.formatNumber(def.amount)
				node.button.BackgroundColor3 = PANEL_BG
				node.button.TextColor3 = theme.UiLight
				node.stroke.Enabled = true
				node.stroke.Color = currencyColor(def.currency)
			end
			if ready then
				UiKit.pulse(node.wrap)
			else
				UiKit.stopPulse(node.wrap)
			end
			node.time.Text = formatTime(def.seconds)
		end
	end
end

local HudController = {}

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
	local updateDots = buildRail(gui)
	local updatePlaytime = buildPlaytime(gui)

	local function updateAll()
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
