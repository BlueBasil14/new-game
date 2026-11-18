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
local BattlePass = require(Shared.BattlePass)
local TurfAnim = require(Shared.TurfAnim)
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
		daily28 = "28-day streak",
		crownRush = "Crown Rush event",
		pass = "Turf Pass",
	},
	rarity = {
		common = "Common",
		rare = "Rare",
		legendary = "Legendary",
		crown = "Crown",
		exclusive = "Exclusive",
	},
	tierHeader = "%s  %d",
	tierHints = {
		legendary = "Animated and 3D",
		rare = "Patterned",
		common = "Solid colours",
		crown = "Earned with Crowns",
		exclusive = "Packs and rewards",
	},
	subs = {
		biome = "3D trees grow on your land",
		effect = "Animated capture effect",
		pattern = "Patterned",
		solid = "Solid colour",
		anim = "Animated turf",
	},
	gemsName = "%s Gems",
	boostName = "2x Coins",
	boostSub = "%d min",
	starterName = "Starter Pack",
	starterSub = "%s gems + skin",
	passNames = { vip = "VIP", doubleCoins = "2x Coins", neonPack = "Neon Pack", skipMusic = "Skip Music", doubleSpeed = "2x Speed" },
	passDescs = {
		vip = "Gold name tag, VIP skin and trail, bonus coins",
		doubleCoins = "Double coins forever",
		neonPack = "5 neon skins and a neon trail",
		skipMusic = "Skip any song you don't like",
		doubleSpeed = "Run %dx faster, forever",
	},

	dailyDay = "Day %d",
	dailyToday = "Today",
	dailyDone = "Claimed",
	dailyClaim = "Claim Day %d",
	dailyWait = "Come back tomorrow",
	dailySkin = "+ skin",
	dailyClaimed = "Day %d claimed: %s",
	dailyRun = "Login streak: %d. Day %d bonus: %s", -- no "days" so 1 needs no singular form
	dailyRunDone = "All streak bonuses earned",
	dailyMilestone = "Day %d streak bonus: %s",
	dailyMilestoneSkin = "%s + %s",
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
	deathPass = "+%s Pass XP",
	deathPassNext = "%d tier%s to %s!",
	deathPassTier = "Tier %d",
	deathPassBtn = "%s in Turf Pass  >",
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
	passBanner = "TURF PASS Premium: 4 animated Legendaries + 4 Rares, R$ %d  >",
	getInPass = "Get in Pass",
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
}

local RARITY_HEX: { [string]: string } = {
	common = "#B8C2D6",
	rare = "#4F8BFF",
	legendary = "#FFC83D",
	crown = "#3DDCFF",
	exclusive = "#FF4F8B",
}

local GEM_PRODUCTS = { "gemsS", "gemsM", "gemsL", "gemsXL" }
local PASS_ORDER = { "vip", "doubleCoins", "neonPack", "skipMusic", "doubleSpeed" }
local PASS_ICONS: { [string]: string } = {
	vip = "economy_crown",
	doubleCoins = "economy_coin_stack",
	neonPack = "gameplay_cosmetics",
	skipMusic = "gameplay_skip",
	doubleSpeed = "economy_energy",
}
local PASS_COLORS: { [string]: Color3 } = {
	vip = UiKit.theme.Yellow,
	doubleCoins = UiKit.theme.Success,
	neonPack = UiKit.theme.Pink,
	skipMusic = UiKit.theme.Gem,
	doubleSpeed = UiKit.theme.Yellow,
}
local TIER_ORDER = { "legendary", "rare", "common", "crown", "exclusive" }
local LEGENDARY_EDGE = "#F08A1C"
local LEGENDARY_SHINE = 1.6 -- seconds for the shine to cross a Legendary ribbon
local TAB_ORDER = { "featured", "skins", "trails", "effects", "gems", "passes" }
local TAB_TYPES: { [string]: string } = { skins = "skin", trails = "trail", effects = "effect" }
local SETTING_ORDER = { "music", "sfx", "shake", "lowDetail" }

local CARD_HEIGHT_PER_WIDTH = 1.42
local CARD_GAP_PX = 10
local SECTION_GAP_PX = 10
local HEADER_PX = 30
local BANNER_PX = 44
local SCROLLBAR_PX = 8
local MIN_CARD_PX = 150 -- cards per row = as many as fit at this width, at least 3 (phones)
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
local PANEL_BG = Color3.fromHex("FFF9EE")
local CARD_BG = Color3.fromRGB(255, 255, 255)
local DIM = Color3.fromHex("DAD8D2")
local TRACK = Color3.fromHex("E1DACA")
local INK = Color3.fromHex("202840")
local MUTED = Color3.fromHex("626779")

local PanelController = {}
PanelController.onSound = nil :: ((name: string) -> ())?
-- Opens the Turf Pass screen (set by Main; PassController requires this module, so no direct require).
PanelController.onOpenPass = nil :: (() -> ())?
PanelController.holdDeath = false -- Studio test hook only (Main "death"): keep the death panel open while alive

local function passOpen(): boolean
	local sp = (ClientState.session :: any).pass
	return type(sp) == "table" and sp.open == true
end

local function openPass()
	local hook = PanelController.onOpenPass
	if hook then
		PanelController.close()
		hook()
	end
end

local shopSetTab: ((string) -> ())? = nil

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

-- ClaimDaily result may carry a one-time streak milestone; RewardService already granted it.
local function toastDailyMilestone(result: any)
	local m = if type(result) == "table" then result.milestone else nil
	if type(m) ~= "table" or type(m.day) ~= "number" then
		return
	end
	local text = PanelController.rewardText(m, "")
	local item = if type(m.skin) == "string" then Catalog.byId(m.skin) else nil
	if item then
		text = string.format(S.dailyMilestoneSkin, text, item.name)
	end
	toastGood(string.format(S.dailyMilestone, m.day, text))
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
	btn.TextColor3 = if dim then INK else theme.UiDark
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
	UiKit.stroke(track, INK, 2)
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
	-- Starter Pack is once per account (owner decision 4): a still-open offer panel must not sell it twice.
	if key == "starterPack" and ClientState.profile ~= nil and ClientState.profile.starterPackBought then
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

function PanelController.promptPass(key: string)
	promptPass(key)
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
	footer.TextColor3 = INK

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
		UiKit.stroke(row, INK, 2)
		local icons = { coinBoost = "economy_coin_stack", speed = "gameplay_speed", shield = "gameplay_shield", startSize = "gameplay_territory" }
		UiKit.icon(icons[id], { Name = "UpgradeIcon", Position = UDim2.fromScale(0.02, 0.1), Size = UDim2.fromScale(0.11, 0.8), parent = row })
		plainLabel(row, S.upgradeNames[id], UDim2.fromScale(0.15, 0.08), UDim2.fromScale(0.22, 0.45))
		local level = plainLabel(row, "", UDim2.fromScale(0.15, 0.56), UDim2.fromScale(0.22, 0.32))
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
-- Cards are built once per tab and updated in place (price/equip state), so a coin change while
-- the shop is open never rebuilds the list or moves the scroll position.

type CardSpec = {
	key: string, -- identity: item id, product or pass key
	name: string,
	tier: string?, -- rarity key -> ribbon, tint and border; nil for products and passes
	sub: string?,
	art: (art: Frame) -> (),
	badge: string?,
	action: string,
	actionColor: Color3,
	dim: boolean,
	pulse: boolean?,
	onAction: (btn: TextButton) -> (),
}

type Card = { frame: Frame, button: TextButton, badge: TextLabel, spec: CardSpec }
type Section = { tier: string?, specs: { CardSpec } }

local function artId(id: number?): string?
	return if id and id ~= 0 then "rbxassetid://" .. id else nil
end

local function image(parent: Instance, id: string, color: Color3?, z: number): ImageLabel
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromScale(1, 1)
	img.ScaleType = Enum.ScaleType.Fit
	img.Image = id
	img.ImageColor3 = color or Color3.new(1, 1, 1)
	img.ZIndex = z
	img.Parent = parent
	return img
end

local function iconArt(key: string)
	return function(art: Frame)
		UiKit.icon(key, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.8, 0.8),
			parent = art,
		})
	end
end

-- Turf preview: colorA ground with the pattern tile tinted colorB, exactly as the turf draws it.
-- Animated (Turf Pass) skin previews in the shop move like the turf does (Shared/TurfAnim).
local animatedArt: { { img: ImageLabel, item: Catalog.Item } } = {}
local animClock = 0
game:GetService("RunService").Heartbeat:Connect(function()
	local now = os.clock()
	if #animatedArt == 0 or now - animClock < 0.05 then
		return
	end
	animClock = now
	for i = #animatedArt, 1, -1 do
		local a = animatedArt[i]
		if a.img.Parent == nil then
			table.remove(animatedArt, i)
		elseif a.img.Visible then
			local color, u, v, transparency = TurfAnim.frame(a.item.anim :: string, Color3.fromHex(a.item.colorB or "#FFFFFF"), now)
			local tile = a.img.TileSize.X.Offset
			a.img.ImageColor3 = color
			a.img.ImageTransparency = transparency
			a.img.Position = UDim2.fromOffset(-u * tile, -v * tile)
		end
	end
end)

local function skinArt(item: Catalog.Item)
	return function(art: Frame)
		local a = Color3.fromHex(item.colorA)
		art.BackgroundColor3 = a
		local biomeImg = artId(Config.ShopArt.Biomes[item.id])
		if item.biome then
			art.BackgroundColor3 = a:Lerp(Color3.new(1, 1, 1), 0.55)
			if biomeImg then
				image(art, biomeImg, nil, art.ZIndex + 1)
			else
				iconArt("gameplay_territory")(art)
			end
			return
		end
		local tileImg = artId(Config.ShopArt.Patterns[item.pattern])
		if item.colorB and item.pattern ~= "solid" then
			local b = Color3.fromHex(item.colorB)
			if tileImg then
				local img = image(art, tileImg, b, art.ZIndex + 1)
				img.ScaleType = Enum.ScaleType.Tile
				local function fit()
					local px = math.max(8, art.AbsoluteSize.Y * 0.62)
					img.TileSize = UDim2.fromOffset(px, px)
					if item.anim then
						img.Size = UDim2.new(1, px, 1, px) -- one tile of slack so the shifted pattern never shows an edge
					end
				end
				if item.anim then
					table.insert(animatedArt, { img = img, item = item })
				end
				art:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
				fit()
			else
				art.BackgroundColor3 = Color3.new(1, 1, 1) -- UIGradient multiplies the background colour
				local g = Instance.new("UIGradient")
				g.Color = ColorSequence.new(a, b)
				g.Rotation = 45
				g.Parent = art
			end
		end
		if item.default then
			iconArt("gameplay_cosmetics")(art)
		elseif item.crownsRequired then
			UiKit.icon("economy_crown", { Position = UDim2.fromScale(0.62, 0.05), Size = UDim2.fromScale(0.34, 0.5), parent = art })
		end
	end
end

local function trailArt(item: Catalog.Item)
	return function(art: Frame)
		local a = Color3.fromHex(item.colorA)
		art.BackgroundColor3 = a:Lerp(PANEL_BG, 0.8)
		local band, core, line = artId(Config.ShopArt.Trail.band), artId(Config.ShopArt.Trail.core), artId(Config.ShopArt.Trail.line)
		if not (band and core and line) then
			iconArt("gameplay_capture_loop")(art)
			return
		end
		local z = art.ZIndex
		image(art, band, a, z + 1)
		local b = if item.colorB then Color3.fromHex(item.colorB) else a:Lerp(Color3.new(1, 1, 1), 0.45)
		image(art, core, b, z + 2)
		image(art, line, nil, z + 3)
	end
end

local function effectArt(item: Catalog.Item)
	return function(art: Frame)
		art.BackgroundColor3 = Color3.fromHex(item.colorA):Lerp(PANEL_BG, 0.78)
		local img = artId(Config.ShopArt.Effects[item.id])
		if img then
			image(art, img, nil, art.ZIndex + 1)
		else
			iconArt("economy_star")(art)
		end
	end
end

local function itemArt(item: Catalog.Item): (Frame) -> ()
	if item.type == "trail" then
		return trailArt(item)
	elseif item.type == "effect" then
		return effectArt(item)
	end
	return skinArt(item)
end

local function itemSub(item: Catalog.Item): string
	if item.biome then
		return S.subs.biome
	elseif item.type == "effect" then
		return S.subs.effect
	elseif item.anim then
		return S.subs.anim
	elseif item.pattern ~= "solid" and item.colorB then
		return S.subs.pattern
	end
	return S.subs.solid
end

local function makeCard(parent: Instance, spec: CardSpec, order: number): Card
	local tier = spec.tier
	local tierHex = tier and RARITY_HEX[tier]
	local tierColor = if tierHex then Color3.fromHex(tierHex) else nil
	local legendary = tier == "legendary"
	local card = UiKit.frame({
		Name = "Card_" .. spec.key,
		BackgroundColor3 = if tierColor then tierColor:Lerp(CARD_BG, if legendary then 0.8 else 0.9) else CARD_BG,
		LayoutOrder = order,
		parent = parent,
	})
	UiKit.corner(card, 12)
	UiKit.stroke(card, if legendary and tierColor then Color3.fromHex(LEGENDARY_EDGE) else INK, if legendary then 4 else 3)

	local artTop = 0.04
	if tier and tierColor then
		local ribbon = UiKit.frame({
			Name = "Tier",
			Position = UDim2.fromScale(0.05, 0.03),
			Size = UDim2.fromScale(0.9, 0.09),
			BackgroundColor3 = if legendary then Color3.new(1, 1, 1) else tierColor, -- gradient supplies the gold
			parent = card,
		})
		UiKit.corner(ribbon, 6)
		UiKit.stroke(ribbon, INK, 2)
		local text = UiKit.label({
			Text = string.upper(S.rarity[tier] or tier),
			Size = UDim2.fromScale(0.92, 0.78),
			Position = UDim2.fromScale(0.04, 0.11),
			TextColor3 = if tier == "rare" or tier == "exclusive" then Color3.new(1, 1, 1) else INK,
			parent = ribbon,
		})
		text.ZIndex = ribbon.ZIndex + 2
		if legendary then
			local g = Instance.new("UIGradient")
			g.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHex(RARITY_HEX.legendary)),
				ColorSequenceKeypoint.new(0.45, Color3.fromHex(RARITY_HEX.legendary)),
				ColorSequenceKeypoint.new(0.5, Color3.fromHex("FFF6CC")),
				ColorSequenceKeypoint.new(0.55, Color3.fromHex(RARITY_HEX.legendary)),
				ColorSequenceKeypoint.new(1, Color3.fromHex(LEGENDARY_EDGE)),
			})
			g.Offset = Vector2.new(-1, 0)
			g.Parent = ribbon
			TweenService:Create(g, TweenInfo.new(LEGENDARY_SHINE, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false, 0.8), { Offset = Vector2.new(1, 0) }):Play()
		end
		artTop = 0.15
	end

	local art = UiKit.frame({
		Name = "Art",
		Position = UDim2.fromScale(0.05, artTop),
		Size = UDim2.fromScale(0.9, 0.6 - artTop),
		BackgroundColor3 = CARD_BG,
		ClipsDescendants = true,
		parent = card,
	})
	UiKit.corner(art, 8)
	UiKit.stroke(art, INK, 2)
	spec.art(art)

	local badge = UiKit.label({
		Name = "Badge",
		Text = "",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.97, artTop - 0.02),
		Size = UDim2.fromScale(0.36, 0.1),
		BackgroundColor3 = theme.Pink,
		BackgroundTransparency = 0,
		TextColor3 = INK,
		Visible = false,
		parent = card,
	})
	badge.ZIndex = art.ZIndex + 5
	UiKit.corner(badge, 6)
	UiKit.stroke(badge, INK, 2)

	plainLabel(card, spec.name, UDim2.fromScale(0.05, 0.62), UDim2.fromScale(0.9, 0.1), Enum.TextXAlignment.Center)
	if spec.sub and spec.sub ~= "" then
		local sub = plainLabel(card, spec.sub, UDim2.fromScale(0.05, 0.72), UDim2.fromScale(0.9, 0.07), Enum.TextXAlignment.Center)
		sub.TextColor3 = MUTED
	end
	local self: Card = { frame = card, button = nil :: any, badge = badge, spec = spec }
	self.button = button({
		text = spec.action,
		color = spec.actionColor,
		size = UDim2.fromScale(0.9, 0.15),
		position = UDim2.fromScale(0.05, 0.81),
		parent = card,
		onClick = function()
			self.spec.onAction(self.button)
		end,
	})
	return self
end

local function updateCard(card: Card, spec: CardSpec)
	card.spec = spec
	styleButton(card.button, spec.action, spec.actionColor, spec.dim)
	card.badge.Text = spec.badge or ""
	card.badge.Visible = spec.badge ~= nil
	if spec.pulse then
		pulseFor(card.frame, PULSE_SECONDS)
	end
end

local function specKey(parts: { string }): string
	return table.concat(parts, "|")
end

local function buildShop(): PanelEntry
	local panel = UiKit.panel({ title = S.shopTitle, size = UDim2.fromScale(0.7, 0.86) })
	local body = panel.body

	local tabBar = UiKit.frame({
		Name = "Tabs",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.02, 0.015),
		Size = UDim2.fromScale(0.96, 0.085),
		parent = body,
	})
	UiKit.list(tabBar, { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.008, 0) })

	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "Cards"
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Position = UDim2.fromScale(0.02, 0.115)
	scroller.Size = UDim2.fromScale(0.96, 0.87)
	-- Canvas height is set from the layout below; AutomaticCanvasSize lagged a frame behind rebuilds.
	scroller.CanvasSize = UDim2.new()
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.None
	scroller.ScrollingDirection = Enum.ScrollingDirection.Y
	-- No inset: the bar's room is reserved below, so the card width never depends on whether the bar shows
	-- (that dependency looped: bar appears -> narrower cards -> new height -> bar toggles).
	scroller.VerticalScrollBarInset = Enum.ScrollBarInset.None
	scroller.ScrollBarThickness = SCROLLBAR_PX
	scroller.ScrollBarImageColor3 = INK
	scroller.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	scroller.Parent = body
	local rowsLayout = UiKit.list(scroller, { Padding = UDim.new(0, SECTION_GAP_PX) })
	rowsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	rowsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		local h = math.ceil(rowsLayout.AbsoluteContentSize.Y) + SECTION_GAP_PX
		if scroller.CanvasSize.Y.Offset ~= h then
			scroller.CanvasSize = UDim2.fromOffset(0, h)
		end
	end)

	local tab = "featured"
	local ownedOnly = false
	local lastLayout = ""
	local busy = false
	local passPulse = false
	local tabButtons: { [string]: TextButton } = {}
	local toggleButton: TextButton
	local refresh: () -> ()
	local cards: { [string]: Card } = {}
	local grids: { { frame: Frame, layout: UIGridLayout, count: number } } = {}

	-- Pixel cell sizes from the visible width: 3 columns on phones, 4 on wide screens.
	local function layoutGrids()
		local w = scroller.AbsoluteSize.X - SCROLLBAR_PX - 4
		if w <= 0 then
			return
		end
		local cols = math.max(3, math.floor((w + CARD_GAP_PX) / (MIN_CARD_PX + CARD_GAP_PX)))
		local cellW = math.floor((w - CARD_GAP_PX * (cols - 1)) / cols)
		local cellH = math.floor(cellW * CARD_HEIGHT_PER_WIDTH)
		for _, g in grids do
			g.frame.Size = UDim2.new(0, w, 0, g.frame.Size.Y.Offset)
			g.layout.CellSize = UDim2.fromOffset(cellW, cellH)
			local rows = math.ceil(g.count / cols)
			g.frame.Size = UDim2.new(0, w, 0, rows * cellH + math.max(0, rows - 1) * CARD_GAP_PX)
		end
	end
	scroller:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutGrids)

	local function setTab(newTab: string)
		if newTab ~= tab then
			scroller.CanvasPosition = Vector2.zero
		end
		tab = newTab
		lastLayout = ""
		refresh()
	end
	shopSetTab = setTab

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
			scroller.CanvasPosition = Vector2.zero
			lastLayout = ""
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
		local spec: CardSpec = {
			key = item.id,
			name = item.name,
			tier = item.rarity,
			sub = itemSub(item),
			art = itemArt(item),
			badge = nil,
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
			spec.action = if source == "pass" then S.getInPass else label
			spec.dim = source ~= "pass"
			if source == "pass" then
				spec.actionColor = theme.Success
			end
			spec.onAction = function()
				if source == "vip" or source == "neonPack" then
					promptPass(source)
				elseif source == "pass" then
					openPass()
				else
					UiKit.toast(string.format(S.unlockVia, label))
				end
			end
		else
			local price = Formulas.itemPrice(Catalog.priceTier(item), featured)
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
		return spec
	end

	local function productSpec(key: string, name: string, sub: string, colorA: Color3): CardSpec
		local robux = (ROBUX.products :: any)[key]
		local icon = if key == "boost15" then "economy_coin_stack" elseif key == "starterPack" then "economy_reward_chest" else "economy_gem_cluster"
		return {
			key = key,
			name = name,
			sub = sub,
			art = function(art: Frame)
				art.BackgroundColor3 = colorA:Lerp(CARD_BG, 0.6)
				iconArt(icon)(art)
			end,
			action = string.format(S.priceRobux, robux),
			actionColor = theme.Yellow,
			dim = false,
			onAction = function()
				promptProduct(key)
			end,
		}
	end

	local function passSpec(key: string): CardSpec
		local owned = ClientState.session.passes[key] == true
		local robux = (Config.Passes :: any)[key].Robux
		local colorA = PASS_COLORS[key]
		local desc = S.passDescs[key]
		if key == "doubleSpeed" then
			desc = string.format(desc, Config.Passes.doubleSpeed.SpeedMultiplier)
		end
		return {
			key = "pass_" .. key,
			name = S.passNames[key],
			sub = desc,
			art = function(art: Frame)
				art.BackgroundColor3 = colorA:Lerp(CARD_BG, 0.55)
				iconArt(PASS_ICONS[key])(art)
			end,
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

	local function buildSections(p: Types.Profile): { Section }
		if tab == "gems" then
			local specs: { CardSpec } = {}
			for _, key in GEM_PRODUCTS do
				local text = UiKit.formatNumber((Config.Products :: any)[key].Gems)
				table.insert(specs, productSpec(key, string.format(S.gemsName, text), "", theme.Gem))
			end
			local minutes = round(Config.Products.boost15.Seconds / 60)
			table.insert(specs, productSpec("boost15", S.boostName, string.format(S.boostSub, minutes), theme.Pink))
			if not p.starterPackBought then
				local gems = UiKit.formatNumber(Config.Products.starterPack.Gems)
				table.insert(specs, productSpec("starterPack", S.starterName, string.format(S.starterSub, gems), theme.Yellow))
			end
			return { { tier = nil, specs = specs } }
		elseif tab == "passes" then
			local specs: { CardSpec } = {}
			for _, key in PASS_ORDER do
				table.insert(specs, passSpec(key))
			end
			return { { tier = nil, specs = specs } }
		end
		local featuredSet: { [string]: boolean } = {}
		for _, id in ClientState.session.featured do
			featuredSet[id] = true
		end
		if tab == "featured" then
			local specs: { CardSpec } = {}
			-- VIP is the top slot of Featured until owned.
			if not ownedOnly and ClientState.session.passes.vip ~= true then
				table.insert(specs, passSpec("vip"))
			end
			for _, id in ClientState.session.featured do
				local item = Catalog.byId(id)
				if item and (not ownedOnly or ClientState.owns(id)) then
					table.insert(specs, itemSpec(item, p, featuredSet))
				end
			end
			return { { tier = nil, specs = specs } }
		end
		-- Item tabs: one section per tier, best first, so the tier is obvious at a glance.
		local byTier: { [string]: { CardSpec } } = {}
		local tabItems = Catalog.ofType(TAB_TYPES[tab])
		if passOpen() and Config.BattlePass.Start == 0 then
			for _, item in Catalog.items do
				if item.type == TAB_TYPES[tab] and item.source == "pass" then
					table.insert(tabItems, item)
				end
			end
		end
		for _, item in tabItems do
			if not ownedOnly or ClientState.owns(item.id) then
				local list = byTier[item.rarity]
				if not list then
					list = {}
					byTier[item.rarity] = list
				end
				table.insert(list, itemSpec(item, p, featuredSet))
			end
		end
		local sections: { Section } = {}
		for _, t in TIER_ORDER do
			if byTier[t] then
				table.insert(sections, { tier = t, specs = byTier[t] })
			end
		end
		return sections
	end

	local function sectionHeader(tier: string, count: number, order: number)
		local hex = RARITY_HEX[tier] or RARITY_HEX.common
		local head = UiKit.frame({
			Name = "Header_" .. tier,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, HEADER_PX),
			LayoutOrder = order,
			parent = scroller,
		})
		local pill = UiKit.frame({
			Name = "Pill",
			Size = UDim2.new(0, HEADER_PX * 5.5, 1, 0),
			BackgroundColor3 = Color3.fromHex(hex),
			parent = head,
		})
		UiKit.corner(pill, 8)
		UiKit.stroke(pill, INK, 2)
		UiKit.label({
			Text = string.format(S.tierHeader, string.upper(S.rarity[tier] or tier), count),
			Size = UDim2.fromScale(0.9, 0.72),
			Position = UDim2.fromScale(0.05, 0.14),
			TextColor3 = if tier == "rare" or tier == "exclusive" then Color3.new(1, 1, 1) else INK,
			parent = pill,
		})
		local hint = if tab == "effects" then nil else S.tierHints[tier] -- effects: only the free Sparkle is Common
		if hint then
			local l = plainLabel(head, hint, UDim2.new(0, HEADER_PX * 5.5 + 10, 0.2, 0), UDim2.new(1, -(HEADER_PX * 5.5 + 10), 0.6, 0))
			l.TextColor3 = MUTED
		end
	end

	refresh = function()
		local p = ClientState.profile
		if p == nil then
			return
		end
		for id, btn in tabButtons do
			btn.BackgroundColor3 = if id == tab then theme.Yellow else CARD_BG
			btn.TextColor3 = if id == tab then theme.UiDark else INK
		end
		toggleButton.BackgroundColor3 = if ownedOnly then theme.Success else CARD_BG
		toggleButton.TextColor3 = if ownedOnly then theme.UiDark else INK

		local sections = buildSections(p)
		passPulse = false
		local showNeon = tab == "skins" and not ownedOnly and neonOffered()
		local showPass = (tab == "featured" or tab == "skins" or tab == "trails" or tab == "passes") and not ownedOnly and passOpen()
		local keys = { tab, if ownedOnly then "own" else "all", if showNeon then "neon" else "", if showPass then "pass" else "" }
		for _, sec in sections do
			table.insert(keys, "#" .. (sec.tier or ""))
			for _, spec in sec.specs do
				table.insert(keys, spec.key)
			end
		end
		local layout = specKey(keys)
		if layout == lastLayout then
			-- Same cards: update prices, equip state and badges in place.
			for _, sec in sections do
				for _, spec in sec.specs do
					local card = cards[spec.key]
					if card then
						updateCard(card, spec)
					end
				end
			end
			return
		end
		lastLayout = layout
		local keep = scroller.CanvasPosition
		for _, child in scroller:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		table.clear(cards)
		table.clear(grids)
		local order = 0
		if showPass then
			order += 1
			local banner = button({
				text = string.format(S.passBanner, Config.BattlePass.Robux.premium),
				color = Color3.fromHex("9C7DFF"),
				size = UDim2.new(1, -(SCROLLBAR_PX + 4), 0, BANNER_PX),
				parent = scroller,
				onClick = openPass,
			})
			banner.Name = "PassBanner"
			banner.TextColor3 = Color3.new(1, 1, 1)
			banner.LayoutOrder = order
			local st = Instance.new("UIStroke")
			st.Color = INK
			st.Thickness = 2
			st.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
			st.Parent = banner
		end
		if showNeon then
			order += 1
			local banner = button({
				text = string.format(S.neonBanner, Config.Passes.neonPack.Robux),
				color = theme.Pink,
				size = UDim2.new(1, -(SCROLLBAR_PX + 4), 0, BANNER_PX),
				parent = scroller,
				onClick = function()
					promptPass("neonPack")
				end,
			})
			banner.Name = "NeonBanner"
			banner.TextColor3 = INK
			banner.LayoutOrder = order
		end
		local total = 0
		for _, sec in sections do
			total += #sec.specs
		end
		if total == 0 then
			local empty = UiKit.label({
				Name = "Empty",
				Text = S.emptyTab,
				Size = UDim2.new(0.8, 0, 0, BANNER_PX),
				TextTransparency = 0.3,
				LayoutOrder = order + 1,
				parent = scroller,
			})
			empty.TextScaled = true
			return
		end
		for _, sec in sections do
			if #sec.specs == 0 then
				continue
			end
			if sec.tier then
				order += 1
				sectionHeader(sec.tier, #sec.specs, order)
			end
			order += 1
			local gridFrame = UiKit.frame({
				Name = "Grid_" .. (sec.tier or tab),
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				LayoutOrder = order,
				parent = scroller,
			})
			local layoutObj = UiKit.grid(gridFrame, { CellPadding = UDim2.fromOffset(CARD_GAP_PX, CARD_GAP_PX) })
			table.insert(grids, { frame = gridFrame, layout = layoutObj, count = #sec.specs })
			for i, spec in sec.specs do
				local card = makeCard(gridFrame, spec, i)
				cards[spec.key] = card
				updateCard(card, spec)
			end
		end
		layoutGrids()
		-- Same tab rebuilt (an item bought under Owned, the starter pack gone): keep the place.
		task.defer(function()
			local maxY = math.max(0, scroller.AbsoluteCanvasSize.Y - scroller.AbsoluteWindowSize.Y)
			scroller.CanvasPosition = Vector2.new(0, math.min(keep.Y, maxY))
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
		Size = UDim2.fromScale(0.96, 0.54),
		parent = body,
	})
	local runLabel = plainLabel(body, "", UDim2.fromScale(0.05, 0.61), UDim2.fromScale(0.9, 0.09), Enum.TextXAlignment.Center)
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
		local stroke = UiKit.stroke(card, INK, 3)
		stroke.Enabled = true
		plainLabel(card, string.format(S.dailyDay, i), UDim2.fromScale(0.05, 0.04), UDim2.fromScale(0.9, 0.12), Enum.TextXAlignment.Center)
		UiKit.icon(if reward.skin then "economy_reward_chest" elseif reward.currency == "gems" then "economy_gem_cluster" else "economy_coin_stack", {
			Name = "RewardIcon", Position = UDim2.fromScale(0.08, 0.2), Size = UDim2.fromScale(0.84, 0.39), parent = card,
		})
		local word = plainLabel(card, UiKit.formatNumber(reward.amount) .. " " .. currencyWord(reward.currency), UDim2.fromScale(0.05, 0.62), UDim2.fromScale(0.9, 0.1), Enum.TextXAlignment.Center)
		word.TextColor3 = INK
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
				toastDailyMilestone(result)
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
			cell.stroke.Enabled = true
			cell.stroke.Color = INK
			cell.stroke.Thickness = if i == today then 3 else 2
			cell.card.BackgroundColor3 = if done then Color3.fromHex("D6F5E2") elseif i == today then Color3.fromHex("FFF0B3") elseif i == count then Color3.fromHex("E6DBFF") else Color3.fromHex("EAE7DF")
			local skinNote = Catalog.daily[i].skin ~= nil and p.daily.loops == 0
			if done then
				cell.status.Text = S.dailyDone
			elseif i == today and state.canClaim then
				cell.status.Text = S.dailyToday
			elseif skinNote then
				cell.status.Text = S.dailySkin
			else
				cell.status.Text = "Locked"
			end
		end
		-- Run as it stands before today's claim (a missed day shows 0).
		local run = if state.canClaim
			then Formulas.dailyNextRun(p.daily.lastClaimDay, p.daily.run, Formulas.dayNumber(ClientState.serverNow())) - 1
			else p.daily.run
		local nextM = Catalog.nextDailyMilestone(run + 1, p.daily.milestones)
		runLabel.Text = if nextM
			then string.format(S.dailyRun, run, nextM.day, PanelController.rewardText(nextM, ""))
			else S.dailyRunDone
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
		boost.TextColor3 = INK
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
				row.reward.TextColor3 = MUTED
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
			confirm.TextColor3 = INK
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
	box.TextColor3 = INK
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
		styleButton(btn, "", theme.Success, not on)
		local knob = btn:FindFirstChild("Knob")
		if knob and knob:IsA("Frame") then
			knob.Position = UDim2.fromScale(if on then 0.56 else 0.06, 0.12)
		end
	end

	for i, key in SETTING_ORDER do
		local row = UiKit.frame({ Name = key, Size = UDim2.fromScale(1, 0.2), BackgroundColor3 = CARD_BG, LayoutOrder = i, parent = list })
		UiKit.corner(row, 12)
		local icons = { music = "gameplay_music", sfx = "gameplay_sound_on", shake = "economy_star", lowDetail = "gameplay_shield" }
		UiKit.icon(icons[key], { Name = "SettingIcon", Position = UDim2.fromScale(0.02, 0.17), Size = UDim2.fromScale(0.12, 0.66), parent = row })
		plainLabel(row, S.settingNames[key], UDim2.fromScale(0.17, 0.15), UDim2.fromScale(0.57, 0.7))
		local btn: TextButton = nil :: any
		btn = button({
			text = "",
			size = UDim2.fromScale(0.14, 0.44),
			position = UDim2.fromScale(0.81, 0.28),
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
		UiKit.corner(btn, 100)
		local knob = UiKit.frame({ Name = "Knob", BackgroundColor3 = CARD_BG, Position = UDim2.fromScale(0.56, 0.12), Size = UDim2.fromScale(0.38, 0.76), parent = btn })
		UiKit.corner(knob, 100)
		UiKit.stroke(knob, INK, 2)
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
	passRow: Frame,
	passFill: Frame,
	passText: TextLabel,
	passBtn: TextButton,
}

local death = {
	payload = nil :: any,
	ui = nil :: DeathUi?,
	busy = false,
	frozen = false,
	token = 0,
	shownAt = 0,
	justClosed = false,
	passXpAtSpawn = nil :: number?,
	wasAlive = false,
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
			Position = UDim2.fromScale(0.08, 0.02 + (i - 1) * 0.1),
			Size = UDim2.fromScale(0.84, 0.09),
			BackgroundColor3 = CARD_BG,
			parent = body,
		})
		UiKit.corner(row, 10)
		plainLabel(row, def[2], UDim2.fromScale(0.04, 0.15), UDim2.fromScale(0.55, 0.7))
		stats[def[1]] = plainLabel(row, "", UDim2.fromScale(0.6, 0.15), UDim2.fromScale(0.36, 0.7), Enum.TextXAlignment.Right)
	end
	-- Turf Pass row: XP earned this life, the bar filling, and the next Legendary to chase.
	local passRow = UiKit.frame({ Name = "PassXp", Position = UDim2.fromScale(0.08, 0.42), Size = UDim2.fromScale(0.84, 0.11), BackgroundColor3 = Color3.fromHex("3A2A8C"), Visible = false, parent = body })
	UiKit.corner(passRow, 10)
	UiKit.stroke(passRow, INK, 2)
	local passTrack = UiKit.frame({ Position = UDim2.fromScale(0.03, 0.55), Size = UDim2.fromScale(0.94, 0.3), BackgroundColor3 = Color3.fromHex("6A4BD8"), parent = passRow })
	UiKit.corner(passTrack, 100)
	local passFill = UiKit.frame({ Size = UDim2.fromScale(0, 1), BackgroundColor3 = theme.Yellow, parent = passTrack })
	UiKit.corner(passFill, 100)
	local passText = plainLabel(passRow, "", UDim2.fromScale(0.03, 0.06), UDim2.fromScale(0.94, 0.44), Enum.TextXAlignment.Left)
	passText.TextColor3 = Color3.new(1, 1, 1)
	local killer = plainLabel(body, "", UDim2.fromScale(0.08, 0.54), UDim2.fromScale(0.84, 0.06), Enum.TextXAlignment.Center)
	killer.TextTransparency = 0.2

	local respawn = button({
		text = S.respawn,
		color = theme.Success,
		size = UDim2.fromScale(0.8, 0.18),
		position = UDim2.fromScale(0.1, 0.61),
		parent = body,
		onClick = finishDeath,
	})
	local second = button({
		text = "",
		color = theme.Pink,
		size = UDim2.fromScale(0.8, 0.14),
		position = UDim2.fromScale(0.1, 0.81),
		parent = body,
		onClick = function()
			death.frozen = true
			second.Text = string.format(S.secondChanceWaiting, ROBUX.products.secondChance)
			promptProduct("secondChance")
		end,
	})
	second.TextColor3 = INK
	-- Free players close to a Legendary get a way into the pass from the most frequent screen in the game.
	local passBtn = button({
		text = "",
		color = Color3.fromHex("9C7DFF"),
		size = UDim2.fromScale(0.64, 0.1),
		position = UDim2.fromScale(0.18, 0.83),
		parent = body,
		onClick = function()
			finishDeath()
			openPass()
		end,
	})
	passBtn.TextColor3 = Color3.new(1, 1, 1)
	passBtn.Visible = false
	death.ui = { stats = stats, killer = killer, respawn = respawn, second = second, passRow = passRow, passFill = passFill, passText = passText, passBtn = passBtn }
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
	-- Turf Pass XP this life (pass XP at spawn -> now), with the bar filling toward the next tier
	local sp = (ClientState.session :: any).pass
	local prof = ClientState.profile
	if type(sp) == "table" and sp.open and prof then
		local st = BattlePass.normalize((prof :: any).pass, Config.BattlePass.Season)
		local tier = BattlePass.tierOf(st.xp)
		local gained = math.max(0, st.xp - (death.passXpAtSpawn or st.xp))
		local nextName: string? = nil
		local away = 0
		for _, t in BattlePass.legendaryTiers do
			if t > tier then
				local it = Catalog.byId(BattlePass.tiers[t].prem[1].id :: string)
				nextName = if it then it.name else nil
				away = t - tier
				break
			end
		end
		local head = string.format(S.deathPass, UiKit.formatNumber(gained))
		if nextName then
			head ..= "   " .. string.format(S.deathPassNext, away, if away == 1 then "" else "s", nextName)
		else
			head ..= "   " .. string.format(S.deathPassTier, tier)
		end
		ui.passText.Text = head
		local frac = if tier >= Config.BattlePass.Tiers then 1 else (st.xp % Config.BattlePass.XpPerTier) / Config.BattlePass.XpPerTier
		local before = if tier >= Config.BattlePass.Tiers then 1 else math.max(0, frac - gained / Config.BattlePass.XpPerTier)
		ui.passFill.Size = UDim2.fromScale(before, 1)
		TweenService:Create(ui.passFill, TweenInfo.new(0.9, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.fromScale(frac, 1) }):Play()
		ui.passRow.Visible = true
		ui.passBtn.Visible = not st.premium and nextName ~= nil and away <= 3 and payload.canSecondChance ~= true
		ui.passBtn.Text = string.format(S.deathPassBtn, nextName or "")
	else
		ui.passRow.Visible = false
		ui.passBtn.Visible = false
	end
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
	head.TextColor3 = INK

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
	}).TextColor3 = INK

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
	if entry == nil or not entry.panel.isOpen() or PanelController.holdDeath then
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
	streak.TextColor3 = INK

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
			toastDailyMilestone(result)
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

-- Opens the Shop on a given tab id ("passes", "skins", ...). Used by the Studio test hook.
function PanelController.openShopTab(id: string)
	PanelController.open("Shop")
	if shopSetTab then
		shopSetTab(id)
	end
end

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
			if not death.wasAlive then
				local prof = ClientState.profile
				death.passXpAtSpawn = if prof then BattlePass.normalize((prof :: any).pass, Config.BattlePass.Season).xp else nil
			end
		end
		death.wasAlive = ClientState.arena.alive
	end)
	ClientState.reward:Connect(function()
		sound("reward")
	end)
end

return PanelController
