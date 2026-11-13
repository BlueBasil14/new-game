--!strict
-- All modal panels (G9.3). Each panel is built lazily and refreshed on profile changes while open.
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Types = require(Shared.Types)
local Catalog = require(Shared.Catalog)
local Formulas = require(Shared.Formulas)
local Remotes = require(Shared.Remotes)
local UiKit = require(script.Parent.Parent.ui.UiKit)
local ClientState = require(script.Parent.Parent.ClientState)

local S = {
	upgradesTitle = "Upgrades",
	shopTitle = "Shop",
	dailyTitle = "Daily Reward",
	questsTitle = "Daily Quests",
	rebirthTitle = "Rebirth",
	codesTitle = "Codes",
	settingsTitle = "Settings",
	deathTitle = "Eliminated",
	starterTitle = "Starter Pack",

	genericError = "Something went wrong",
	comingSoon = "Coming soon",
	notEnoughCoins = "Not enough coins",
	notEnoughGems = "Not enough gems",
	upgraded = "%s upgraded",
	upgradeMax = "MAX",
	upgradeLevel = "Lv %d / %d",
	upgradeArrow = "%s  >  %s",
	upgradeCoins = "%s coins",
	speedValue = "+%d%%",
	cellsValue = "%d cells",
	secondsValue = "%.1f s",
	passFooter = "Get the 2x Coins pass",
	passFooterOwned = "2x Coins pass active",
	upgradeNames = {
		coinBoost = "Coin Boost",
		speed = "Speed",
		shield = "Spawn Shield",
		startSize = "Start Size",
	},

	tabs = {
		featured = "Featured",
		skins = "Skins",
		trails = "Trails",
		effects = "Effects",
		gems = "Gems",
		passes = "Passes",
	},
	ownedToggle = "Owned",
	emptyTab = "Nothing here yet",
	owned = "Owned",
	equip = "Equip",
	equipped = "Equipped",
	equippedToast = "%s equipped",
	boughtToast = "Bought %s",
	claimItem = "Claim",
	needsCrowns = "Needs %d Crowns",
	notForSale = "Not for sale",
	unlockVia = "Unlock via: %s",
	discount = "-%d%%",
	priceCoins = "%s coins",
	priceGems = "%s gems",
	priceRobux = "R$ %d",
	sources = {
		vip = "VIP pass",
		neonPack = "Neon Pack",
		starterPack = "Starter Pack",
		group = "Group reward",
		daily7 = "7-day streak",
	},
	rarity = {
		common = "Common",
		rare = "Rare",
		epic = "Epic",
		legendary = "Legendary",
		crown = "Crown",
		exclusive = "Exclusive",
	},
	gemsName = "%s Gems",
	boostName = "2x Coins",
	boostSub = "%d min",
	starterName = "Starter Pack",
	starterSub = "%s gems + skin",
	passNames = { vip = "VIP", doubleCoins = "2x Coins", neonPack = "Neon Pack" },
	passDescs = {
		vip = "Gold name tag, VIP skin and trail, bonus coins",
		doubleCoins = "Double coins forever",
		neonPack = "5 neon skins and a neon trail",
	},

	dailyDay = "Day %d",
	dailyToday = "Today",
	dailyDone = "Claimed",
	dailyClaim = "Claim Day %d",
	dailyWait = "Come back tomorrow",
	dailySkin = "+ skin",
	dailyClaimed = "Day %d claimed: %s",
	currencyCoins = "coins",
	currencyGems = "gems",
	rewardText = "+%s %s",

	questKinds = {
		cells = "Claim %s cells",
		kills = "Eliminate %s runners",
		bigCapture = "Capture %s cells at once",
		mapPct = "Reach %s%% of the map",
		kingSeconds = "Be King for %s seconds",
		playMinutes = "Play for %s minutes",
	},
	questProgress = "%s / %s",
	questClaim = "Claim",
	questClaimed = "Claimed",
	questNone = "No quests today",

	rebirthRequirement = "Earn %s coins since your last rebirth",
	rebirthProgress = "%s / %s",
	rebirthResetsTitle = "Resets",
	rebirthResets = "Coins\nUpgrades",
	rebirthGainTitle = "You gain",
	rebirthGainCrown = "+1 Crown",
	rebirthGainBonus = "+%d%% coins per Crown",
	rebirthGainGems = "+%d gems",
	rebirthButton = "Rebirth",
	rebirthConfirm = "Tap again to confirm",
	rebirthDone = "Rebirth complete! Crowns: %d",

	codePlaceholder = "Enter code",
	codeRedeem = "Redeem",
	codeEmpty = "Type a code first",
	codeOk = "Code redeemed",

	settingNames = {
		music = "Music",
		sfx = "Sound effects",
		shake = "Screen shake",
		lowDetail = "Low detail",
	},
	on = "ON",
	off = "OFF",

	deathCells = "Cells held",
	deathCoins = "Coins earned",
	deathKills = "Eliminations",
	deathTime = "Time alive",
	deathKiller = "Cut by %s",
	respawn = "Respawn",
	secondChance = "Second Chance  R$ %d  (%d)",
	secondChanceWaiting = "Second Chance  R$ %d",

	starterHeadline = "One-time offer",
	starterGems = "%s Gems",
	starterCoins = "%s Coins",
	starterSkin = "Starter Spark skin",
	starterNo = "No thanks",

	neonBanner = "Neon Pack: 5 neon skins + trail  R$ %d",
	boostQuest = "%dx Coins %d min",
	awayTitle = "Welcome back",
	awayStreak = "Daily streak: %d",
	awayDailyReady = "Daily reward is ready",
	awayDailyDone = "Daily reward claimed",
	awayQuests = "Quests ready: %d",
	awayView = "View",
}

-- Server error key -> friendly text. Unknown keys fall back to S.genericError.
local ERRORS: { [string]: string } = {
	network = "Connection problem, try again",
	unknown_upgrade = "That upgrade does not exist",
	max_level = "Already at max level",
	insufficient_funds = "Not enough funds",
	not_enough_coins = "Not enough coins earned yet",
	unknown_item = "That item does not exist",
	already_owned = "You already own that",
	crowns_required = "You need more Crowns",
	not_for_sale = "That item is not for sale",
	not_owned = "You do not own that item",
	already_claimed = "Already claimed",
	too_early = "Not ready yet",
	bad_args = S.genericError,
	quests_refreshed = "Quests were refreshed, check again",
	not_complete = "Quest not complete yet",
	invalid_code = "Invalid code",
	already_used = "You already used that code",
	rate_limited = "Slow down a little",
}

-- Display-only Robux prices; they must match the Roblox dashboard.
local ROBUX = {
	products = { gemsS = 49, gemsM = 199, gemsL = 449, gemsXL = 999, boost15 = 29, starterPack = 79, secondChance = 15 },
	passes = { vip = 399, doubleCoins = 249, neonPack = 199 },
}

local RARITY_HEX: { [string]: string } = {
	common = "#B8C2D6",
	rare = "#4F8BFF",
	epic = "#C45CFF",
	legendary = "#FFC83D",
	crown = "#3DDCFF",
	exclusive = "#FF4F8B",
}

local GEM_PRODUCTS = { "gemsS", "gemsM", "gemsL", "gemsXL" }
local PASS_ORDER = { "vip", "doubleCoins", "neonPack" }
local TAB_ORDER = { "featured", "skins", "trails", "effects", "gems", "passes" }
local TAB_TYPES: { [string]: string } = { skins = "skin", trails = "trail", effects = "effect" }
local SETTING_ORDER = { "music", "sfx", "shake", "lowDetail" }

local CARD_WIDTH = 0.32
local CARD_HEIGHT_PER_WIDTH = 1.15
local CARDS_PER_ROW = 3
local PULSE_SECONDS = 1.5
local REBIRTH_CONFIRM_SECONDS = 3
local DEATH_GUARD_SECONDS = 0.5
local STARTER_DELAY = 0.6
local COUNTDOWN_STEP = 0.1
local COIN_COUNT = 6
local COIN_PX = 16
local COIN_TIME = 0.45
local COIN_STAGGER = 0.05
local AWAY_DELAY = 1.2

local theme = UiKit.theme
local PANEL_BG = Color3.fromHex(Config.Colors.UiDark)
local CARD_BG = PANEL_BG:Lerp(theme.UiLight, 0.1)
local DIM = Color3.fromRGB(95, 104, 128)
local TRACK = PANEL_BG:Lerp(Color3.new(0, 0, 0), 0.4)

local PanelController = {}
PanelController.onSound = nil :: ((name: string) -> ())?

function PanelController.sound(name: string)
	local hook = PanelController.onSound
	if hook then
		hook(name)
	end
end
local sound = PanelController.sound

function PanelController.errorText(key: any): string
	if type(key) == "string" then
		local text = ERRORS[key]
		if text then
			return text
		end
	end
	return S.genericError
end
local errorText = PanelController.errorText

local function currencyWord(currency: string): string
	return if currency == "gems" then S.currencyGems else S.currencyCoins
end

function PanelController.rewardText(result: any, fallback: string): string
	if type(result) == "table" and type(result.amount) == "number" and type(result.currency) == "string" then
		return string.format(S.rewardText, UiKit.formatNumber(result.amount), currencyWord(result.currency))
	end
	return fallback
end

-- Helpers -----------------------------------------------------------------------------------

local function toastGood(text: string)
	UiKit.toast(text, theme.Success)
end

local function toastBad(text: string)
	UiKit.toast(text, theme.Danger)
end

local function round(x: number): number
	return math.floor(x + 0.5)
end

local function formatClock(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function squash(btn: GuiObject)
	local s = btn:FindFirstChild("ButtonScale")
	if s and s:IsA("UIScale") then
		s.Scale = 0.82
		TweenService:Create(s, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
end

local function pulseFor(inst: GuiObject, seconds: number)
	UiKit.pulse(inst)
	task.delay(seconds, function()
		UiKit.stopPulse(inst)
	end)
end

-- Coin shower: a few pooled Frames fly from the HUD wallet to the pressed button.
local coinFrames: { Frame } = {}

local function coinShower(target: GuiObject, currency: string?)
	local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
	local hud = playerGui and playerGui:FindFirstChild("Hud")
	local wallet = hud and hud:FindFirstChild("Wallet")
	if wallet == nil or not wallet:IsA("GuiObject") then
		return
	end
	local walletGui = wallet :: GuiObject
	if #coinFrames == 0 then
		local gui = UiKit.screenGui("CoinShower", 90)
		for i = 1, COIN_COUNT do
			local f = UiKit.frame({
				Name = "Coin" .. i,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(COIN_PX, COIN_PX),
				Visible = false,
				parent = gui,
			})
			UiKit.corner(f, 100)
			UiKit.stroke(f, theme.UiDark, 2)
			coinFrames[i] = f
		end
	end
	local from = walletGui.AbsolutePosition + walletGui.AbsoluteSize * Vector2.new(0.1, 0.17)
	local to = target.AbsolutePosition + target.AbsoluteSize * 0.5
	local color = if currency == "gems" then theme.Gem else theme.Yellow
	for i, f in coinFrames do
		local delay = (i - 1) * COIN_STAGGER
		task.delay(delay, function()
			f.BackgroundColor3 = color
			f.Position = UDim2.fromOffset(from.X, from.Y)
			f.Visible = true
			TweenService:Create(f, TweenInfo.new(COIN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
				Position = UDim2.fromOffset(to.X, to.Y),
			}):Play()
		end)
		task.delay(delay + COIN_TIME, function()
			f.Visible = false
		end)
	end
end

local function button(props: {
	text: string?,
	color: Color3?,
	size: UDim2?,
	position: UDim2?,
	parent: Instance?,
	onClick: (() -> ())?,
}): TextButton
	local onClick = props.onClick
	props.onClick = function()
		sound("click")
		if onClick then
			onClick()
		end
	end
	return UiKit.button(props)
end

local function styleButton(btn: TextButton, text: string, color: Color3, dim: boolean)
	btn.Text = text
	btn.BackgroundColor3 = if dim then DIM else color
	btn.TextColor3 = if dim then theme.UiLight else theme.UiDark
end

local function currencyColor(currency: string): Color3
	return if currency == "gems" then theme.Gem else theme.Yellow
end

local function plainLabel(parent: Instance, text: string, pos: UDim2, size: UDim2, align: Enum.TextXAlignment?): TextLabel
	return UiKit.label({
		Text = text,
		Position = pos,
		Size = size,
		TextXAlignment = align or Enum.TextXAlignment.Left,
		parent = parent,
	})
end

local function bar(parent: Instance, pos: UDim2, size: UDim2): (Frame, Frame, TextLabel)
	local track = UiKit.frame({ Name = "Track", Position = pos, Size = size, BackgroundColor3 = TRACK, parent = parent })
	UiKit.corner(track, 100)
	local fill = UiKit.frame({ Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = theme.Success, parent = track })
	UiKit.corner(fill, 100)
	local text = UiKit.label({
		Name = "Text",
		Size = UDim2.fromScale(0.9, 0.8),
		Position = UDim2.fromScale(0.05, 0.1),
		ZIndex = 2,
		parent = track,
	})
	return track, fill, text
end

local function promptProduct(key: string)
	local id = (Config.Ids.Products :: any)[key]
	if type(id) ~= "number" or id == 0 then
		UiKit.toast(S.comingSoon)
		return
	end
	MarketplaceService:PromptProductPurchase(Players.LocalPlayer, id)
end

local function promptPass(key: string)
	local id = (Config.Ids.Passes :: any)[key]
	if type(id) ~= "number" or id == 0 then
		UiKit.toast(S.comingSoon)
		return
	end
	MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, id)
end

-- Registry ----------------------------------------------------------------------------------

type PanelEntry = { panel: UiKit.Panel, refresh: () -> () }

local built: { [string]: PanelEntry } = {}
local builders: { [string]: () -> PanelEntry } = {}
local started = false

local function ensure(name: string): PanelEntry?
	local entry = built[name]
	if entry then
		return entry
	end
	local builder = builders[name]
	if builder == nil then
		return nil
	end
	entry = builder()
	built[name] = entry
	return entry
end

local setShopTab: ((tab: string) -> ())? = nil

-- Upgrades ----------------------------------------------------------------------------------

local function upgradeLevel(p: Types.Profile, id: string): number
	return (p.upgrades :: any)[id] or 0
end

local function upgradeValueText(id: string, value: number): string
	if id == "startSize" then
		return string.format(S.cellsValue, value)
	elseif id == "shield" then
		return string.format(S.secondsValue, value)
	end
	return string.format(S.speedValue, round((value - 1) * 100))
end

local function buildUpgrades(): PanelEntry
	local panel = UiKit.panel({ title = S.upgradesTitle })
	local body = panel.body
	local list = UiKit.frame({
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.03, 0.03),
		Size = UDim2.fromScale(0.94, 0.75),
		parent = body,
	})
	UiKit.list(list, { Padding = UDim.new(0.02, 0) })

	local footWrap = UiKit.frame({
		Name = "FooterWrap",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.03, 0.82),
		Size = UDim2.fromScale(0.94, 0.14),
		parent = body,
	})
	local footer = button({
		text = S.passFooter,
		color = theme.Pink,
		size = UDim2.fromScale(1, 1),
		parent = footWrap,
		onClick = function()
			promptPass("doubleCoins")
		end,
	})
	footer.TextColor3 = theme.UiLight

	type Row = { id: string, level: TextLabel, value: TextLabel, cost: TextButton }
	local rows: { Row } = {}
	local busy = false

	for i, id in Config.UpgradeOrder do
		local row = UiKit.frame({
			Name = id,
			Size = UDim2.fromScale(1, 0.235),
			BackgroundColor3 = CARD_BG,
			LayoutOrder = i,
			parent = list,
		})
		UiKit.corner(row, 12)
		plainLabel(row, S.upgradeNames[id], UDim2.fromScale(0.03, 0.08), UDim2.fromScale(0.33, 0.45))
		local level = plainLabel(row, "", UDim2.fromScale(0.03, 0.56), UDim2.fromScale(0.33, 0.32))
		level.TextTransparency = 0.25
		local value = plainLabel(row, "", UDim2.fromScale(0.38, 0.2), UDim2.fromScale(0.3, 0.6), Enum.TextXAlignment.Center)
		local cost: TextButton = nil :: any
		cost = button({
			text = "",
			size = UDim2.fromScale(0.27, 0.72),
			position = UDim2.fromScale(0.7, 0.14),
			parent = row,
			onClick = function()
				local p = ClientState.profile
				if busy or p == nil then
					return
				end
				local price = Formulas.upgradeCost(id, upgradeLevel(p, id))
				if price == nil then
					return
				end
				if p.coins < price then
					sound("error")
					toastBad(S.notEnoughCoins)
					pulseFor(footWrap, PULSE_SECONDS)
					return
				end
				busy = true
				local ok, result = ClientState.request(Remotes.Requests.BuyUpgrade, id)
				busy = false
				if ok then
					squash(cost)
					coinShower(cost, "coins")
					sound("buy")
					toastGood(string.format(S.upgraded, S.upgradeNames[id]))
				else
					sound("error")
					toastBad(errorText(result))
					if result == "insufficient_funds" then
						pulseFor(footWrap, PULSE_SECONDS)
					end
				end
			end,
		})
		rows[i] = { id = id, level = level, value = value, cost = cost }
	end

	local function refresh()
		local p = ClientState.profile
		if p == nil then
			return
		end
		for _, row in rows do
			local lvl = upgradeLevel(p, row.id)
			local max = (Config.Upgrades :: any)[row.id].Max
			row.level.Text = string.format(S.upgradeLevel, lvl, max)
			local current = upgradeValueText(row.id, Formulas.upgradeValue(row.id, lvl))
			local price = Formulas.upgradeCost(row.id, lvl)
			if price == nil then
				row.value.Text = current
				styleButton(row.cost, S.upgradeMax, theme.Success, true)
			else
				local nextText = upgradeValueText(row.id, Formulas.upgradeValue(row.id, lvl + 1))
				row.value.Text = string.format(S.upgradeArrow, current, nextText)
				styleButton(row.cost, string.format(S.upgradeCoins, UiKit.formatNumber(price)), theme.Yellow, p.coins < price)
			end
		end
		local owned = ClientState.session.passes.doubleCoins == true
		footer.Text = if owned then S.passFooterOwned else S.passFooter
		footer.BackgroundColor3 = if owned then DIM else theme.Pink
	end
	return { panel = panel, refresh = refresh }
end

-- Shop --------------------------------------------------------------------------------------

type CardSpec = {
	key: string,
	name: string,
	sub: string,
	subColor: Color3,
	colorA: Color3,
	colorB: Color3?,
	big: string?,
	badge: string?,
	borderColor: Color3,
	action: string,
	actionColor: Color3,
	dim: boolean,
	pulse: boolean?,
	onAction: (btn: TextButton) -> (),
}

local function makeCard(parent: Instance, spec: CardSpec, order: number)
	local card = UiKit.frame({
		Name = "Card" .. order,
		Size = UDim2.fromScale(CARD_WIDTH, 1),
		BackgroundColor3 = CARD_BG,
		LayoutOrder = order,
		parent = parent,
	})
	UiKit.corner(card, 12)
	UiKit.stroke(card, spec.borderColor, 2)
	local swatch = UiKit.frame({
		Name = "Swatch",
		Position = UDim2.fromScale(0.06, 0.04),
		Size = UDim2.fromScale(0.88, 0.42),
		BackgroundColor3 = spec.colorA,
		parent = card,
	})
	UiKit.corner(swatch, 8)
	if spec.colorB then
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(spec.colorA, spec.colorB)
		g.Rotation = 45
		g.Parent = swatch
	end
	if spec.big then
		UiKit.label({
			Text = spec.big,
			TextColor3 = theme.UiDark,
			Size = UDim2.fromScale(0.8, 0.5),
			Position = UDim2.fromScale(0.1, 0.25),
			parent = swatch,
		})
	end
	if spec.badge then
		local badge = UiKit.frame({
			Name = "Badge",
			Position = UDim2.fromScale(0.04, 0.06),
			Size = UDim2.fromScale(0.36, 0.26),
			BackgroundColor3 = theme.Pink,
			parent = swatch,
		})
		UiKit.corner(badge, 6)
		UiKit.label({
			Text = spec.badge,
			Size = UDim2.fromScale(0.9, 0.8),
			Position = UDim2.fromScale(0.05, 0.1),
			parent = badge,
		})
	end
	plainLabel(card, spec.name, UDim2.fromScale(0.06, 0.48), UDim2.fromScale(0.88, 0.14), Enum.TextXAlignment.Center)
	if spec.pulse then
		pulseFor(card, PULSE_SECONDS)
	end
	local sub = plainLabel(card, spec.sub, UDim2.fromScale(0.06, 0.62), UDim2.fromScale(0.88, 0.11), Enum.TextXAlignment.Center)
	sub.TextColor3 = spec.subColor
	local btn: TextButton = nil :: any
	btn = button({
		text = spec.action,
		color = spec.actionColor,
		size = UDim2.fromScale(0.88, 0.2),
		position = UDim2.fromScale(0.06, 0.76),
		parent = card,
		onClick = function()
			spec.onAction(btn)
		end,
	})
	styleButton(btn, spec.action, spec.actionColor, spec.dim)
end

local function specKey(parts: { string }): string
	return table.concat(parts, "|")
end

local function buildShop(): PanelEntry
	local panel = UiKit.panel({ title = S.shopTitle, size = UDim2.fromScale(0.66, 0.82) })
	local body = panel.body

	local tabBar = UiKit.frame({
		Name = "Tabs",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.02, 0.015),
		Size = UDim2.fromScale(0.96, 0.095),
		parent = body,
	})
	UiKit.list(tabBar, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.008, 0) })

	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "Cards"
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Position = UDim2.fromScale(0.02, 0.125)
	scroller.Size = UDim2.fromScale(0.96, 0.86)
	scroller.CanvasSize = UDim2.new()
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroller.ScrollingDirection = Enum.ScrollingDirection.Y
	scroller.ScrollBarThickness = 6
	scroller.Parent = body
	-- Offset padding: a scale padding inside an AutomaticCanvasSize canvas feeds back into the canvas height.
	local rowsLayout = UiKit.list(scroller, { Padding = UDim.new(0, 8) })
	rowsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local tab = "featured"
	local ownedOnly = false
	local lastSig = ""
	local busy = false
	local passPulse = false
	local tabButtons: { [string]: TextButton } = {}
	local toggleButton: TextButton
	local refresh: () -> ()

	local function setTab(newTab: string)
		tab = newTab
		lastSig = ""
		refresh()
	end

	local tabWidth = (1 - 0.008 * #TAB_ORDER) / (#TAB_ORDER + 1)
	for i, id in TAB_ORDER do
		tabButtons[id] = button({
			text = S.tabs[id],
			size = UDim2.fromScale(tabWidth, 1),
			parent = tabBar,
			onClick = function()
				setTab(id)
			end,
		})
		tabButtons[id].LayoutOrder = i
	end
	-- TextScaled gave each tab its own size ("Skins" huge, "Featured" small); one size for the row,
	-- small enough for the longest caption.
	local function sizeTabText()
		local abs = tabBar.AbsoluteSize
		local size = math.max(8, math.floor(math.min(abs.Y * 0.5, abs.X * tabWidth / 5.5)))
		for _, child in tabBar:GetChildren() do
			if child:IsA("TextButton") then
				child.TextScaled = false
				child.TextSize = size
			end
		end
	end
	tabBar:GetPropertyChangedSignal("AbsoluteSize"):Connect(sizeTabText)
	tabBar.ChildAdded:Connect(sizeTabText)
	toggleButton = button({
		text = S.ownedToggle,
		size = UDim2.fromScale(tabWidth, 1),
		parent = tabBar,
		onClick = function()
			ownedOnly = not ownedOnly
			if tab == "gems" or tab == "passes" then
				tab = "skins"
			end
			lastSig = ""
			refresh()
		end,
	})
	toggleButton.LayoutOrder = #TAB_ORDER + 1

	local function guarded(fn: () -> ())
		if busy then
			return
		end
		busy = true
		fn()
		busy = false
	end

	-- Insufficient coins: bring the 2x Coins pass forward (Passes tab, pulsing card) unless owned.
	local function offerCoinsPass()
		if ClientState.session.passes.doubleCoins == true then
			return
		end
		passPulse = true
		setTab("passes")
	end

	local function neonOffered(): boolean
		return Config.Ids.Passes.neonPack ~= 0 and ClientState.session.passes.neonPack ~= true
	end

	local function itemSpec(item: Catalog.Item, p: Types.Profile, featuredSet: { [string]: boolean }): CardSpec
		local owned = ClientState.owns(item.id)
		local featured = featuredSet[item.id] == true
		local rarityColor = Color3.fromHex(RARITY_HEX[item.rarity] or RARITY_HEX.common)
		local spec: CardSpec = {
			key = "",
			name = item.name,
			sub = S.rarity[item.rarity] or item.rarity,
			subColor = rarityColor,
			colorA = Color3.fromHex(item.colorA),
			colorB = if item.colorB then Color3.fromHex(item.colorB) else nil,
			big = nil,
			badge = nil,
			borderColor = rarityColor,
			action = "",
			actionColor = theme.Yellow,
			dim = true,
			onAction = function() end,
		}
		if owned then
			local isEquipped = (p.equipped :: any)[item.type] == item.id
			spec.action = if isEquipped then S.equipped else S.equip
			spec.actionColor = theme.Success
			spec.dim = isEquipped
			spec.onAction = function(btn: TextButton)
				if isEquipped then
					return
				end
				guarded(function()
					local ok, result = ClientState.request(Remotes.Requests.Equip, item.id)
					if ok then
						squash(btn)
						toastGood(string.format(S.equippedToast, item.name))
					else
						sound("error")
						toastBad(errorText(result))
					end
				end)
			end
		elseif item.crownsRequired then
			local need = item.crownsRequired
			local enough = p.crowns >= need
			spec.action = if enough then S.claimItem else string.format(S.needsCrowns, need)
			spec.actionColor = theme.Success
			spec.dim = not enough
			spec.onAction = function(btn: TextButton)
				if not enough then
					sound("error")
					toastBad(string.format(S.needsCrowns, need))
					return
				end
				guarded(function()
					local ok, result = ClientState.request(Remotes.Requests.BuyItem, item.id)
					if ok then
						squash(btn)
						sound("buy")
						toastGood(string.format(S.boughtToast, item.name))
					else
						sound("error")
						toastBad(errorText(result))
					end
				end)
			end
		elseif item.source then
			local source = item.source
			local label = S.sources[source] or source
			spec.action = label
			spec.dim = true
			spec.onAction = function()
				if source == "vip" or source == "neonPack" then
					promptPass(source)
				else
					UiKit.toast(string.format(S.unlockVia, label))
				end
			end
		else
			local price = Formulas.itemPrice(item.rarity, featured)
			if price == nil then
				spec.action = S.notForSale
			else
				local balance = if price.currency == "gems" then p.gems else p.coins
				local fmt = if price.currency == "gems" then S.priceGems else S.priceCoins
				spec.action = string.format(fmt, UiKit.formatNumber(price.amount))
				spec.actionColor = currencyColor(price.currency)
				spec.dim = balance < price.amount
				if featured then
					spec.badge = string.format(S.discount, round(Config.Prices.FeaturedDiscount * 100))
				end
				spec.onAction = function(btn: TextButton)
					local fresh = ClientState.profile
					if fresh == nil then
						return
					end
					local have = if price.currency == "gems" then fresh.gems else fresh.coins
					if have < price.amount then
						sound("error")
						toastBad(if price.currency == "gems" then S.notEnoughGems else S.notEnoughCoins)
						if price.currency == "gems" then
							setTab("gems")
						else
							offerCoinsPass()
						end
						return
					end
					guarded(function()
						local ok, result = ClientState.request(Remotes.Requests.BuyItem, item.id)
						if ok then
							squash(btn)
							coinShower(btn, price.currency)
							sound("buy")
							toastGood(string.format(S.boughtToast, item.name))
						else
							sound("error")
							toastBad(errorText(result))
							if result == "insufficient_funds" and price.currency == "coins" then
								offerCoinsPass()
							end
						end
					end)
				end
			end
		end
		spec.key = specKey({
			item.id,
			spec.action,
			if spec.dim then "d" else "a",
			spec.badge or "",
		})
		return spec
	end

	local function productSpec(key: string, name: string, sub: string, big: string, colorA: Color3, colorB: Color3?): CardSpec
		local robux = (ROBUX.products :: any)[key]
		local action = string.format(S.priceRobux, robux)
		return {
			key = specKey({ key, action }),
			name = name,
			sub = sub,
			subColor = theme.UiLight,
			colorA = colorA,
			colorB = colorB,
			big = big,
			badge = nil,
			borderColor = colorA,
			action = action,
			actionColor = theme.Yellow,
			dim = false,
			onAction = function()
				promptProduct(key)
			end,
		}
	end

	local function passSpec(key: string): CardSpec
		local owned = ClientState.session.passes[key] == true
		local robux = (ROBUX.passes :: any)[key]
		local colorA = if key == "vip" then theme.Yellow elseif key == "doubleCoins" then theme.Success else theme.Pink
		return {
			key = specKey({ key, if owned then "o" else "b" }),
			name = S.passNames[key],
			sub = S.passDescs[key],
			subColor = theme.UiLight,
			colorA = colorA,
			colorB = theme.UiLight,
			big = nil,
			badge = nil,
			borderColor = colorA,
			action = if owned then S.owned else string.format(S.priceRobux, robux),
			actionColor = theme.Yellow,
			dim = owned,
			pulse = key == "doubleCoins" and passPulse and not owned,
			onAction = function()
				if not owned then
					promptPass(key)
				end
			end,
		}
	end

	local function buildSpecs(p: Types.Profile): { CardSpec }
		local specs: { CardSpec } = {}
		if tab == "gems" then
			for _, key in GEM_PRODUCTS do
				local gems = (Config.Products :: any)[key].Gems
				local text = UiKit.formatNumber(gems)
				table.insert(specs, productSpec(key, string.format(S.gemsName, text), "", text, theme.Gem, theme.UiLight))
			end
			local minutes = round(Config.Products.boost15.Seconds / 60)
			table.insert(
				specs,
				productSpec("boost15", S.boostName, string.format(S.boostSub, minutes), Config.Income.BoostMultiplier .. "x", theme.Pink, theme.Yellow)
			)
			if not p.starterPackBought then
				local gems = UiKit.formatNumber(Config.Products.starterPack.Gems)
				table.insert(
					specs,
					productSpec("starterPack", S.starterName, string.format(S.starterSub, gems), gems, theme.Yellow, Color3.fromHex(Config.Colors.Players[2]))
				)
			end
		elseif tab == "passes" then
			for _, key in PASS_ORDER do
				table.insert(specs, passSpec(key))
			end
		else
			local featuredSet: { [string]: boolean } = {}
			for _, id in ClientState.session.featured do
				featuredSet[id] = true
			end
			local items: { Catalog.Item } = {}
			if tab == "featured" then
				for _, id in ClientState.session.featured do
					local item = Catalog.byId(id)
					if item then
						table.insert(items, item)
					end
				end
			else
				items = Catalog.ofType(TAB_TYPES[tab])
			end
			-- VIP is the top slot of Featured until owned.
			if tab == "featured" and not ownedOnly and ClientState.session.passes.vip ~= true then
				table.insert(specs, passSpec("vip"))
			end
			for _, item in items do
				if not ownedOnly or ClientState.owns(item.id) then
					table.insert(specs, itemSpec(item, p, featuredSet))
				end
			end
		end
		return specs
	end

	refresh = function()
		local p = ClientState.profile
		if p == nil then
			return
		end
		for id, btn in tabButtons do
			btn.BackgroundColor3 = if id == tab then theme.Yellow else DIM
			btn.TextColor3 = if id == tab then theme.UiDark else theme.UiLight
		end
		toggleButton.BackgroundColor3 = if ownedOnly then theme.Success else DIM
		toggleButton.TextColor3 = if ownedOnly then theme.UiDark else theme.UiLight

		local specs = buildSpecs(p)
		passPulse = false
		local keys = { tab, if ownedOnly then "own" else "all" }
		local showNeon = tab == "skins" and neonOffered()
		if showNeon then
			table.insert(keys, "neon")
		end
		for _, spec in specs do
			table.insert(keys, spec.key)
		end
		local sig = specKey(keys)
		if sig == lastSig then
			return
		end
		lastSig = sig
		local canvasPos = scroller.CanvasPosition
		for _, child in scroller:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		if showNeon then
			local banner = button({
				text = string.format(S.neonBanner, ROBUX.passes.neonPack),
				color = theme.Pink,
				size = UDim2.new(0.98, 0, 0, 44),
				parent = scroller,
				onClick = function()
					promptPass("neonPack")
				end,
			})
			banner.Name = "NeonBanner"
			banner.TextColor3 = theme.UiLight
			banner.LayoutOrder = 0
		end
		if #specs == 0 then
			local empty = UiKit.label({
				Name = "Empty",
				Text = S.emptyTab,
				Size = UDim2.fromScale(0.8, 0.12),
				TextTransparency = 0.3,
				parent = scroller,
			})
			empty.LayoutOrder = 1
			return
		end
		local rowCount = math.ceil(#specs / CARDS_PER_ROW)
		for r = 1, rowCount do
			local row = UiKit.frame({
				Name = "Row" .. r,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0),
				LayoutOrder = r,
				parent = scroller,
			})
			-- Default FitWithinMaxSize would clamp the zero-height row to 0x0; size from the canvas width instead.
			local rowAspect = UiKit.aspect(row, 1 / (CARD_WIDTH * CARD_HEIGHT_PER_WIDTH))
			rowAspect.AspectType = Enum.AspectType.ScaleWithParentSize
			rowAspect.DominantAxis = Enum.DominantAxis.Width
			UiKit.list(row, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new((1 - CARD_WIDTH * CARDS_PER_ROW) / (CARDS_PER_ROW - 1), 0) })
			for c = 1, CARDS_PER_ROW do
				local spec = specs[(r - 1) * CARDS_PER_ROW + c]
				if spec then
					makeCard(row, spec, c)
				end
			end
		end
		task.defer(function()
			scroller.CanvasPosition = canvasPos
		end)
	end

	setShopTab = setTab
	return { panel = panel, refresh = refresh }
end

-- Daily -------------------------------------------------------------------------------------

local function buildDaily(): PanelEntry
	local panel = UiKit.panel({ title = S.dailyTitle, size = UDim2.fromScale(0.7, 0.68) })
	local body = panel.body
	local days = UiKit.frame({
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.02, 0.04),
		Size = UDim2.fromScale(0.96, 0.62),
		parent = body,
	})
	local count = #Catalog.daily
	local gap = 0.012
	UiKit.list(days, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(gap, 0) })

	type Cell = { card: Frame, stroke: UIStroke, status: TextLabel }
	local cells: { Cell } = {}
	for i, reward in Catalog.daily do
		local card = UiKit.frame({
			Name = "Day" .. i,
			Size = UDim2.fromScale((1 - gap * (count - 1)) / count, 1),
			BackgroundColor3 = CARD_BG,
			LayoutOrder = i,
			parent = days,
		})
		UiKit.corner(card, 10)
		local stroke = UiKit.stroke(card, theme.UiLight, 3)
		stroke.Enabled = false
		plainLabel(card, string.format(S.dailyDay, i), UDim2.fromScale(0.05, 0.04), UDim2.fromScale(0.9, 0.12), Enum.TextXAlignment.Center)
		local coin = UiKit.frame({
			Name = "Icon",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.22),
			Size = UDim2.fromScale(0.78, 0.2),
			BackgroundColor3 = currencyColor(reward.currency),
			parent = card,
		})
		UiKit.corner(coin, 100)
		UiKit.aspect(coin, 1)
		UiKit.label({
			Text = UiKit.formatNumber(reward.amount),
			TextColor3 = theme.UiDark,
			Size = UDim2.fromScale(0.8, 0.4),
			Position = UDim2.fromScale(0.1, 0.3),
			parent = coin,
		})
		local word = plainLabel(card, currencyWord(reward.currency), UDim2.fromScale(0.05, 0.62), UDim2.fromScale(0.9, 0.1), Enum.TextXAlignment.Center)
		word.TextTransparency = 0.25
		local status = plainLabel(card, "", UDim2.fromScale(0.05, 0.78), UDim2.fromScale(0.9, 0.12), Enum.TextXAlignment.Center)
		cells[i] = { card = card, stroke = stroke, status = status }
	end

	local busy = false
	local claimBtn: TextButton = nil :: any
	claimBtn = button({
		text = "",
		size = UDim2.fromScale(0.5, 0.18),
		position = UDim2.fromScale(0.25, 0.74),
		parent = body,
		onClick = function()
			local state = ClientState.dailyState()
			if busy or not state.canClaim then
				return
			end
			busy = true
			local ok, result = ClientState.request(Remotes.Requests.ClaimDaily)
			busy = false
			if ok then
				squash(claimBtn)
				sound("reward")
				local day = if type(result) == "table" and type(result.streak) == "number" then result.streak else state.nextStreak
				toastGood(string.format(S.dailyClaimed, day, PanelController.rewardText(result, "")))
			else
				sound("error")
				toastBad(errorText(result))
			end
		end,
	})

	local function refresh()
		local p = ClientState.profile
		if p == nil then
			return
		end
		local state = ClientState.dailyState()
		local claimedThrough = if state.canClaim then state.nextStreak - 1 else p.daily.streak
		local today = if state.canClaim then state.nextStreak else p.daily.streak
		for i, cell in cells do
			local done = i <= claimedThrough
			cell.stroke.Enabled = i == today
			cell.stroke.Color = if state.canClaim then theme.Yellow else theme.Success
			cell.card.BackgroundColor3 = if done then PANEL_BG:Lerp(theme.Success, 0.3) else CARD_BG
			local skinNote = Catalog.daily[i].skin ~= nil and p.daily.loops == 0
			if done then
				cell.status.Text = S.dailyDone
			elseif i == today and state.canClaim then
				cell.status.Text = S.dailyToday
			elseif skinNote then
				cell.status.Text = S.dailySkin
			else
				cell.status.Text = ""
			end
		end
		if state.canClaim then
			styleButton(claimBtn, string.format(S.dailyClaim, state.nextStreak), theme.Yellow, false)
			UiKit.pulse(claimBtn)
		else
			styleButton(claimBtn, S.dailyWait, theme.Yellow, true)
			UiKit.stopPulse(claimBtn)
		end
	end
	return { panel = panel, refresh = refresh }
end

-- Quests ------------------------------------------------------------------------------------

local function buildQuests(): PanelEntry
	local panel = UiKit.panel({ title = S.questsTitle, size = UDim2.fromScale(0.66, 0.7) })
	local body = panel.body
	local hasBoost = Config.Ids.Products.boost15 ~= 0
	local list = UiKit.frame({
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.03, 0.04),
		Size = UDim2.fromScale(0.94, if hasBoost then 0.82 else 0.92),
		parent = body,
	})
	UiKit.list(list, { Padding = UDim.new(0.03, 0) })
	if hasBoost then
		local boost = button({
			text = string.format(S.boostQuest, Config.Income.BoostMultiplier, round(Config.Products.boost15.Seconds / 60)),
			color = theme.Pink,
			size = UDim2.fromScale(0.4, 0.09),
			position = UDim2.fromScale(0.57, 0.89),
			parent = body,
			onClick = function()
				promptProduct("boost15")
			end,
		})
		boost.TextColor3 = theme.UiLight
	end

	type Row = { root: Frame, desc: TextLabel, fill: Frame, progress: TextLabel, reward: TextLabel, claim: TextButton }
	local rows: { Row } = {}
	local busy = false
	for i = 1, 3 do
		local root = UiKit.frame({
			Name = "Quest" .. i,
			Size = UDim2.fromScale(1, 0.3),
			BackgroundColor3 = CARD_BG,
			LayoutOrder = i,
			parent = list,
		})
		UiKit.corner(root, 12)
		local desc = plainLabel(root, "", UDim2.fromScale(0.03, 0.08), UDim2.fromScale(0.64, 0.28))
		local _, fill, progress = bar(root, UDim2.fromScale(0.03, 0.42), UDim2.fromScale(0.64, 0.22))
		local reward = plainLabel(root, "", UDim2.fromScale(0.03, 0.7), UDim2.fromScale(0.64, 0.22))
		local claim: TextButton = nil :: any
		claim = button({
			text = S.questClaim,
			size = UDim2.fromScale(0.27, 0.6),
			position = UDim2.fromScale(0.7, 0.2),
			parent = root,
			onClick = function()
				if busy then
					return
				end
				busy = true
				local ok, result = ClientState.request(Remotes.Requests.ClaimQuest, i)
				busy = false
				if ok then
					squash(claim)
					sound("reward")
					toastGood(PanelController.rewardText(result, S.questClaimed))
				else
					sound("error")
					toastBad(errorText(result))
				end
			end,
		})
		rows[i] = { root = root, desc = desc, fill = fill, progress = progress, reward = reward, claim = claim }
	end

	local function refresh()
		local p = ClientState.profile
		if p == nil then
			return
		end
		for i, row in rows do
			local entry = p.quests.list[i]
			local def = if entry then ClientState.quest(entry.id) else nil
			if entry == nil or def == nil then
				row.root.Visible = false
			else
				row.root.Visible = true
				local progress = math.min(entry.progress, def.target)
				local template = S.questKinds[def.kind] or "%s"
				row.desc.Text = string.format(template, UiKit.formatNumber(def.target))
				row.fill.Size = UDim2.fromScale(math.clamp(entry.progress / def.target, 0, 1), 1)
				row.progress.Text = string.format(S.questProgress, UiKit.formatNumber(math.floor(progress)), UiKit.formatNumber(def.target))
				row.reward.Text = string.format(S.rewardText, UiKit.formatNumber(def.reward.amount), currencyWord(def.reward.currency))
				row.reward.TextColor3 = currencyColor(def.reward.currency)
				local complete = entry.progress >= def.target
				if entry.claimed then
					styleButton(row.claim, S.questClaimed, theme.Success, true)
				else
					styleButton(row.claim, S.questClaim, theme.Yellow, not complete)
				end
			end
		end
	end
	return { panel = panel, refresh = refresh }
end

-- Rebirth -----------------------------------------------------------------------------------

local function buildRebirth(): PanelEntry
	local panel = UiKit.panel({ title = S.rebirthTitle, size = UDim2.fromScale(0.62, 0.72) })
	local body = panel.body
	local reqLabel = plainLabel(body, "", UDim2.fromScale(0.06, 0.04), UDim2.fromScale(0.88, 0.08), Enum.TextXAlignment.Center)
	local _, fill, progress = bar(body, UDim2.fromScale(0.06, 0.15), UDim2.fromScale(0.88, 0.1))

	local function column(x: number, title: string, text: string, color: Color3): TextLabel
		local box = UiKit.frame({
			Position = UDim2.fromScale(x, 0.32),
			Size = UDim2.fromScale(0.42, 0.34),
			BackgroundColor3 = CARD_BG,
			parent = body,
		})
		UiKit.corner(box, 12)
		local t = plainLabel(box, title, UDim2.fromScale(0.06, 0.06), UDim2.fromScale(0.88, 0.22), Enum.TextXAlignment.Center)
		t.TextColor3 = color
		return plainLabel(box, text, UDim2.fromScale(0.06, 0.32), UDim2.fromScale(0.88, 0.6), Enum.TextXAlignment.Center)
	end
	column(0.06, S.rebirthResetsTitle, S.rebirthResets, theme.Danger)
	local gainText = table.concat({
		S.rebirthGainCrown,
		string.format(S.rebirthGainBonus, round(Config.Income.RebirthBonusPerCrown * 100)),
		string.format(S.rebirthGainGems, Config.Rebirth.GemReward),
	}, "\n")
	column(0.52, S.rebirthGainTitle, gainText, theme.Success)

	local armed = false
	local armToken = 0
	local busy = false
	local confirm: TextButton = nil :: any

	local function eligible(): boolean
		local p = ClientState.profile
		return p ~= nil and p.lifetimeCoinsSinceRebirth >= Formulas.rebirthRequirement(p.crowns)
	end

	local function refresh()
		local p = ClientState.profile
		if p == nil then
			return
		end
		local need = Formulas.rebirthRequirement(p.crowns)
		reqLabel.Text = string.format(S.rebirthRequirement, UiKit.formatNumber(need))
		fill.Size = UDim2.fromScale(math.clamp(p.lifetimeCoinsSinceRebirth / need, 0, 1), 1)
		progress.Text = string.format(S.rebirthProgress, UiKit.formatNumber(math.floor(p.lifetimeCoinsSinceRebirth)), UiKit.formatNumber(need))
		if armed and eligible() then
			styleButton(confirm, S.rebirthConfirm, theme.Danger, false)
			confirm.TextColor3 = theme.UiLight
		else
			armed = false
			styleButton(confirm, S.rebirthButton, theme.Pink, not eligible())
		end
	end

	confirm = button({
		text = S.rebirthButton,
		size = UDim2.fromScale(0.6, 0.18),
		position = UDim2.fromScale(0.2, 0.74),
		parent = body,
		onClick = function()
			if busy then
				return
			end
			if not eligible() then
				sound("error")
				toastBad(errorText("not_enough_coins"))
				return
			end
			if not armed then
				armed = true
				armToken += 1
				local token = armToken
				refresh()
				task.delay(REBIRTH_CONFIRM_SECONDS, function()
					if armToken == token and armed then
						armed = false
						refresh()
					end
				end)
				return
			end
			armed = false
			armToken += 1
			busy = true
			local ok, result = ClientState.request(Remotes.Requests.Rebirth)
			busy = false
			if ok then
				squash(confirm)
				sound("reward")
				sound("rebirthSwell")
				local crowns = if type(result) == "table" and type(result.crowns) == "number" then result.crowns else ClientState.profile and ClientState.profile.crowns or 0
				toastGood(string.format(S.rebirthDone, crowns))
			else
				sound("error")
				toastBad(errorText(result))
			end
			refresh()
		end,
	})
	return { panel = panel, refresh = refresh }
end

-- Codes -------------------------------------------------------------------------------------

local function buildCodes(): PanelEntry
	local panel = UiKit.panel({ title = S.codesTitle, size = UDim2.fromScale(0.5, 0.5) })
	local body = panel.body
	local box = Instance.new("TextBox")
	box.Name = "CodeBox"
	box.BackgroundColor3 = TRACK
	box.BorderSizePixel = 0
	box.Font = Enum.Font.GothamBold
	box.TextScaled = true
	box.TextColor3 = theme.UiLight
	box.PlaceholderText = S.codePlaceholder
	box.PlaceholderColor3 = DIM
	box.Text = ""
	box.ClearTextOnFocus = false
	box.Position = UDim2.fromScale(0.1, 0.18)
	box.Size = UDim2.fromScale(0.8, 0.22)
	box.Parent = body
	UiKit.corner(box, 12)
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 32
	limit.MinTextSize = 8
	limit.Parent = box

	local busy = false
	local redeem: TextButton = nil :: any
	redeem = button({
		text = S.codeRedeem,
		size = UDim2.fromScale(0.5, 0.22),
		position = UDim2.fromScale(0.25, 0.55),
		parent = body,
		onClick = function()
			if busy then
				return
			end
			local code = string.match(box.Text, "^%s*(.-)%s*$") or ""
			code = string.sub(code, 1, Config.Security.MaxCodeLength)
			if code == "" then
				sound("error")
				toastBad(S.codeEmpty)
				return
			end
			busy = true
			local ok, result = ClientState.request(Remotes.Requests.RedeemCode, code)
			busy = false
			if ok then
				squash(redeem)
				sound("reward")
				box.Text = ""
				toastGood(PanelController.rewardText(result, S.codeOk))
			else
				sound("error")
				toastBad(errorText(result))
			end
		end,
	})
	return { panel = panel, refresh = function() end }
end

-- Settings ----------------------------------------------------------------------------------

local function buildSettings(): PanelEntry
	local panel = UiKit.panel({ title = S.settingsTitle, size = UDim2.fromScale(0.5, 0.62) })
	local body = panel.body
	local list = UiKit.frame({
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.05, 0.05),
		Size = UDim2.fromScale(0.9, 0.9),
		parent = body,
	})
	UiKit.list(list, { Padding = UDim.new(0.03, 0) })

	local toggles: { [string]: TextButton } = {}
	local busy = false
	local function paint(btn: TextButton, on: boolean)
		styleButton(btn, if on then S.on else S.off, theme.Success, not on)
	end

	for i, key in SETTING_ORDER do
		local row = UiKit.frame({ Name = key, Size = UDim2.fromScale(1, 0.2), BackgroundColor3 = CARD_BG, LayoutOrder = i, parent = list })
		UiKit.corner(row, 12)
		plainLabel(row, S.settingNames[key], UDim2.fromScale(0.04, 0.15), UDim2.fromScale(0.6, 0.7))
		local btn: TextButton = nil :: any
		btn = button({
			text = "",
			size = UDim2.fromScale(0.28, 0.6),
			position = UDim2.fromScale(0.68, 0.2),
			parent = row,
			onClick = function()
				local p = ClientState.profile
				if busy or p == nil then
					return
				end
				local new = not ((p.settings :: any)[key] == true)
				paint(btn, new)
				busy = true
				local ok, result = ClientState.request(Remotes.Requests.SetSetting, key, new)
				busy = false
				if not ok then
					sound("error")
					toastBad(errorText(result))
					paint(btn, not new)
				end
			end,
		})
		toggles[key] = btn
	end

	local function refresh()
		local p = ClientState.profile
		if p == nil then
			return
		end
		for key, btn in toggles do
			paint(btn, (p.settings :: any)[key] == true)
		end
	end
	return { panel = panel, refresh = refresh }
end

-- Death -------------------------------------------------------------------------------------

type DeathUi = {
	stats: { [string]: TextLabel },
	killer: TextLabel,
	respawn: TextButton,
	second: TextButton,
}

local death = {
	payload = nil :: any,
	ui = nil :: DeathUi?,
	busy = false,
	frozen = false,
	token = 0,
	shownAt = 0,
	justClosed = false,
}
local starterShown = false

local function finishDeath()
	local ui = death.ui
	if ui == nil or death.busy then
		return
	end
	death.busy = true
	death.token += 1
	ui.second.Visible = false
	local payload = death.payload
	if type(payload) == "table" and payload.canSecondChance then
		ClientState.request(Remotes.Requests.DeclineSecondChance)
	end
	local ok, result = ClientState.request(Remotes.Requests.Respawn)
	if not ok then
		sound("error")
		toastBad(errorText(result))
		death.busy = false
	end
end

local function buildDeath(): PanelEntry
	local panel = UiKit.panel({ title = S.deathTitle, size = UDim2.fromScale(0.5, 0.72) })
	panel.closeButton.Visible = false
	local body = panel.body

	local stats: { [string]: TextLabel } = {}
	local statDefs = {
		{ "cells", S.deathCells },
		{ "coins", S.deathCoins },
		{ "kills", S.deathKills },
		{ "time", S.deathTime },
	}
	for i, def in statDefs do
		local row = UiKit.frame({
			Name = def[1],
			Position = UDim2.fromScale(0.08, 0.03 + (i - 1) * 0.11),
			Size = UDim2.fromScale(0.84, 0.1),
			BackgroundColor3 = CARD_BG,
			parent = body,
		})
		UiKit.corner(row, 10)
		plainLabel(row, def[2], UDim2.fromScale(0.04, 0.15), UDim2.fromScale(0.55, 0.7))
		stats[def[1]] = plainLabel(row, "", UDim2.fromScale(0.6, 0.15), UDim2.fromScale(0.36, 0.7), Enum.TextXAlignment.Right)
	end
	local killer = plainLabel(body, "", UDim2.fromScale(0.08, 0.47), UDim2.fromScale(0.84, 0.07), Enum.TextXAlignment.Center)
	killer.TextTransparency = 0.2

	local respawn = button({
		text = S.respawn,
		color = theme.Success,
		size = UDim2.fromScale(0.8, 0.2),
		position = UDim2.fromScale(0.1, 0.57),
		parent = body,
		onClick = finishDeath,
	})
	local second = button({
		text = "",
		color = theme.Pink,
		size = UDim2.fromScale(0.8, 0.15),
		position = UDim2.fromScale(0.1, 0.8),
		parent = body,
		onClick = function()
			death.frozen = true
			second.Text = string.format(S.secondChanceWaiting, ROBUX.products.secondChance)
			promptProduct("secondChance")
		end,
	})
	second.TextColor3 = theme.UiLight
	death.ui = { stats = stats, killer = killer, respawn = respawn, second = second }
	return { panel = panel, refresh = function() end }
end

local function showDeath(payload: any)
	if type(payload) ~= "table" then
		return
	end
	local entry = ensure("Death")
	local ui = death.ui
	if entry == nil or ui == nil then
		return
	end
	death.payload = payload
	death.busy = false
	death.frozen = false
	death.token += 1
	death.shownAt = os.clock()
	local token = death.token

	ui.stats.cells.Text = UiKit.formatNumber(payload.cells or 0)
	ui.stats.coins.Text = UiKit.formatNumber(payload.coins or 0)
	ui.stats.kills.Text = UiKit.formatNumber(payload.kills or 0)
	ui.stats.time.Text = formatClock(payload.lifeSeconds or 0)
	ui.killer.Text = if payload.killerName then string.format(S.deathKiller, payload.killerName) else ""
	local eligible = payload.canSecondChance == true
	ui.second.Visible = eligible
	local remaining = Config.Products.secondChance.PromptSeconds
	ui.second.Text = string.format(S.secondChance, ROBUX.products.secondChance, math.ceil(remaining))
	entry.panel.show()

	if eligible then
		task.spawn(function()
			while death.token == token do
				task.wait(COUNTDOWN_STEP)
				if death.token ~= token then
					return
				end
				if not death.frozen then
					remaining -= COUNTDOWN_STEP
					if remaining <= 0 then
						finishDeath()
						return
					end
					ui.second.Text = string.format(S.secondChance, ROBUX.products.secondChance, math.ceil(remaining))
				end
			end
		end)
	end
end

-- Starter pack offer ------------------------------------------------------------------------

local function buildStarter(): PanelEntry
	local panel = UiKit.panel({ title = S.starterTitle, size = UDim2.fromScale(0.6, 0.66) })
	local body = panel.body
	local head = plainLabel(body, S.starterHeadline, UDim2.fromScale(0.1, 0.04), UDim2.fromScale(0.8, 0.1), Enum.TextXAlignment.Center)
	head.TextColor3 = theme.Yellow

	local starter = Config.Products.starterPack
	local offers = {
		{ string.format(S.starterGems, UiKit.formatNumber(starter.Gems)), theme.Gem },
		{ string.format(S.starterCoins, UiKit.formatNumber(starter.Coins)), theme.Yellow },
		{ S.starterSkin, theme.Pink },
	}
	local width = 0.29
	local gap = (1 - width * #offers) / (#offers + 1)
	for i, offer in offers do
		local card = UiKit.frame({
			Position = UDim2.fromScale(gap + (i - 1) * (width + gap), 0.18),
			Size = UDim2.fromScale(width, 0.34),
			BackgroundColor3 = offer[2],
			parent = body,
		})
		UiKit.corner(card, 12)
		UiKit.label({
			Text = offer[1],
			TextColor3 = theme.UiDark,
			TextWrapped = true,
			Size = UDim2.fromScale(0.86, 0.6),
			Position = UDim2.fromScale(0.07, 0.2),
			parent = card,
		})
	end

	local buy = button({
		text = string.format(S.priceRobux, ROBUX.products.starterPack),
		size = UDim2.fromScale(0.6, 0.18),
		position = UDim2.fromScale(0.2, 0.58),
		parent = body,
		onClick = function()
			promptProduct("starterPack")
		end,
	})
	UiKit.pulse(buy)
	button({
		text = S.starterNo,
		color = DIM,
		size = UDim2.fromScale(0.36, 0.12),
		position = UDim2.fromScale(0.32, 0.82),
		parent = body,
		onClick = function()
			panel.hide()
		end,
	}).TextColor3 = theme.UiLight

	local function refresh()
		local p = ClientState.profile
		if p and p.starterPackBought and panel.isOpen() then
			panel.hide()
		end
	end
	return { panel = panel, refresh = refresh }
end

local function tryStarter()
	if not death.justClosed then
		return
	end
	death.justClosed = false
	local profile = ClientState.profile
	if starterShown or not ClientState.session.starterOffer or profile == nil or profile.starterOfferSeenAt ~= 0 then
		return
	end
	starterShown = true
	task.delay(STARTER_DELAY, function()
		if not ClientState.arena.alive then
			starterShown = false
			return
		end
		PanelController.open("Starter")
		ClientState.request(Remotes.Requests.StarterOfferSeen)
	end)
end

local function closeDeath()
	local entry = built.Death
	if entry == nil or not entry.panel.isOpen() then
		return
	end
	if os.clock() - death.shownAt < DEATH_GUARD_SECONDS then
		return
	end
	death.token += 1
	entry.panel.hide()
	death.justClosed = true
	tryStarter()
end

-- "While you were away" return panel ---------------------------------------------------------

local function claimableQuests(): number
	local p = ClientState.profile
	local n = 0
	if p then
		for _, entry in p.quests.list do
			local def = ClientState.quest(entry.id)
			if def and not entry.claimed and entry.progress >= def.target then
				n += 1
			end
		end
	end
	return n
end

local function buildAway(): PanelEntry
	local panel = UiKit.panel({ title = S.awayTitle, size = UDim2.fromScale(0.5, 0.5) })
	local body = panel.body
	local streak = plainLabel(body, "", UDim2.fromScale(0.08, 0.06), UDim2.fromScale(0.84, 0.16), Enum.TextXAlignment.Center)
	streak.TextColor3 = theme.Yellow

	local function row(y: number): (TextLabel, TextButton, Frame)
		local box = UiKit.frame({
			Position = UDim2.fromScale(0.08, y),
			Size = UDim2.fromScale(0.84, 0.24),
			BackgroundColor3 = CARD_BG,
			parent = body,
		})
		UiKit.corner(box, 12)
		local label = plainLabel(box, "", UDim2.fromScale(0.04, 0.15), UDim2.fromScale(0.56, 0.7))
		local btn = button({
			text = "",
			size = UDim2.fromScale(0.32, 0.6),
			position = UDim2.fromScale(0.64, 0.2),
			parent = box,
		})
		return label, btn, box
	end

	local dailyLabel, dailyBtn = row(0.28)
	local questLabel, questBtn = row(0.6)

	local busy = false
	dailyBtn.Activated:Connect(function()
		local state = ClientState.dailyState()
		if busy or not state.canClaim then
			return
		end
		busy = true
		local ok, result = ClientState.request(Remotes.Requests.ClaimDaily)
		busy = false
		if ok then
			squash(dailyBtn)
			coinShower(dailyBtn, "coins")
			sound("reward")
			local day = if type(result) == "table" and type(result.streak) == "number" then result.streak else state.nextStreak
			toastGood(string.format(S.dailyClaimed, day, PanelController.rewardText(result, "")))
		else
			sound("error")
			toastBad(errorText(result))
		end
	end)
	questBtn.Activated:Connect(function()
		panel.hide()
		PanelController.open("Quests")
	end)

	local function refresh()
		local p = ClientState.profile
		if p == nil then
			return
		end
		streak.Text = string.format(S.awayStreak, p.daily.streak)
		local state = ClientState.dailyState()
		dailyLabel.Text = if state.canClaim then S.awayDailyReady else S.awayDailyDone
		dailyBtn.Visible = state.canClaim
		styleButton(dailyBtn, string.format(S.dailyClaim, state.nextStreak), theme.Yellow, false)
		local n = claimableQuests()
		questLabel.Text = string.format(S.awayQuests, n)
		questBtn.Visible = n > 0
		styleButton(questBtn, S.awayView, theme.Success, false)
	end
	return { panel = panel, refresh = refresh }
end

builders.Away = buildAway
builders.Upgrades = buildUpgrades
builders.Shop = buildShop
builders.Daily = buildDaily
builders.Quests = buildQuests
builders.Rebirth = buildRebirth
builders.Codes = buildCodes
builders.Settings = buildSettings
builders.Death = buildDeath
builders.Starter = buildStarter

-- Public API --------------------------------------------------------------------------------

function PanelController.open(name: string)
	local deathEntry = built.Death
	if name ~= "Death" and deathEntry and deathEntry.panel.isOpen() then
		return
	end
	local entry = ensure(name)
	if entry == nil then
		return
	end
	entry.refresh()
	entry.panel.show()
end

function PanelController.close()
	for name, entry in built do
		if name ~= "Death" and entry.panel.isOpen() then
			entry.panel.hide()
		end
	end
end

function PanelController.start()
	if started then
		return
	end
	started = true
	ClientState.start()

	ClientState.profileChanged:Connect(function()
		for _, entry in built do
			if entry.panel.isOpen() then
				entry.refresh()
			end
		end
	end)
	-- First profile of the session: welcome returning players who have something to claim.
	local awayChecked = false
	ClientState.profileChanged:Connect(function(profile: Types.Profile?)
		if awayChecked or profile == nil then
			return
		end
		awayChecked = true
		if profile.firstJoin == profile.lastJoin or not profile.tutorialDone then
			return
		end
		if not (ClientState.dailyState().canClaim or ClientState.questClaimable()) then
			return
		end
		task.delay(AWAY_DELAY, function()
			PanelController.open("Away")
		end)
	end)
	ClientState.death:Connect(showDeath)
	ClientState.arenaChanged:Connect(function()
		if ClientState.arena.alive then
			closeDeath()
		end
	end)
	ClientState.reward:Connect(function()
		sound("reward")
	end)
end

return PanelController
