--!strict
-- Every tunable number in the game. Source of truth is docs/GDD.md; section ids are noted.
local Config = {}

-- G2 arena
Config.Arena = {
	GridSize = 160, -- cells per side
	CellSize = 4, -- studs
	FloorY = 0, -- world Y of the walkable surface
	MaxPlayers = 16,
	MinRunners = 10, -- bots fill up to this
	TickRate = 20, -- Hz, server simulation
	DeltaRate = 10, -- Hz, replication batches
	BaseWalkSpeed = 22,
	StartPatch = 5, -- cells per side before upgrades
	SpawnShield = 3, -- seconds before upgrades
	RespawnDelay = 3,
	LeaveNeutralDelay = 5,
	KillerShare = 0.25, -- share of victim cells handed to the killer
	KingMinShare = 0.03, -- share of map needed to be King
	FullMapBonus = 5000,
	TrailDangerRadius = 6, -- cells, client warning
}

-- G6 claim feel (client): flash start is delayed by up to WaveTime, trail edge first, centroid last
Config.ClaimFx = { WaveTime = 0.25 }
-- G6 cutting: client-only pause when the local player cuts someone.
Config.CutFx = { HitStop = 0.08, PopTime = 0.6, PopSpeed = 60 } -- Pop*: eliminated runner flies apart (seconds, studs/s)

-- WallFade: local transparency of the south wall when it hides the runner; WallFadeMargin: studs over which it fades in.
Config.Camera = { Pitch = 55, MinDistance = 45, MaxDistance = 70, FieldOfView = 70, WallFade = 0.85, WallFadeMargin = 6 }

-- G3.2 income
Config.Income = {
	CellNeutral = 1,
	CellStolen = 2,
	KillBase = 25,
	KillVictimShare = 0.10,
	KingKillMultiplier = 2,
	PassiveInterval = 10, -- seconds
	PassiveCellsPerCoin = 20,
	CaptureBonus = { -- sorted ascending by MinCells
		{ MinCells = 100, Bonus = 0.10 },
		{ MinCells = 400, Bonus = 0.25 },
		{ MinCells = 1000, Bonus = 0.50 },
	},
	RebirthBonusPerCrown = 0.25,
	VipMultiplier = 1.2,
	DoubleCoinsMultiplier = 2,
	BoostMultiplier = 2,
	GroupBonus = 0.10,
	WeekendMultiplier = 2,
}

-- G3.3 upgrades: cost(level) = Base * Growth^level rounded to nearest 5 (level = current level, 0-based)
Config.Upgrades = {
	speed = { Max = 10, Base = 150, Growth = 1.75, PerLevel = 0.015 },
	startSize = { Max = 3, Base = 1000, Growth = 5.0, PerLevel = 2 },
	coinBoost = { Max = 20, Base = 100, Growth = 1.45, PerLevel = 0.10 },
	shield = { Max = 5, Base = 300, Growth = 2.0, PerLevel = 0.5 },
}
Config.UpgradeOrder = { "coinBoost", "speed", "shield", "startSize" }

-- G3.4 rebirth: requirement = Base * 2^crowns lifetime coins since last rebirth
Config.Rebirth = { Base = 150000, GemReward = 50 }

-- G3.6 cosmetic prices
Config.Prices = {
	common = { Currency = "coins", Amount = 500 },
	rare = { Currency = "coins", Amount = 5000 },
	epic = { Currency = "gems", Amount = 150 },
	legendary = { Currency = "gems", Amount = 400 },
	FeaturedDiscount = 0.20,
	FeaturedCount = 6,
}

-- G4 monetization. Ids are 0 until the owner creates them on Roblox (T-LCH-01).
Config.Ids = {
	GroupId = 0,
	Passes = { vip = 0, doubleCoins = 0, neonPack = 0 },
	Products = {
		starterPack = 0,
		secondChance = 0,
		boost15 = 0,
		gemsS = 0,
		gemsM = 0,
		gemsL = 0,
		gemsXL = 0,
	},
	Badges = {
		firstLoop = 0,
		firstCut = 0,
		king = 0,
		map10 = 0,
		map50 = 0,
		map100 = 0,
		firstRebirth = 0,
		streak7 = 0,
	},
}
Config.Products = {
	starterPack = { Gems = 300, Coins = 2500, Skin = "starter_spark", OfferAfterSeconds = 240, OfferWindowHours = 48 },
	secondChance = { MinMapShare = 0.03, PromptSeconds = 4, Shield = 3 },
	boost15 = { Seconds = 900 },
	gemsS = { Gems = 80 },
	gemsM = { Gems = 400 },
	gemsL = { Gems = 1000 },
	gemsXL = { Gems = 2600 },
}
Config.Vip = { DailyGemMultiplier = 2, Skin = "vip_gold", Trail = "vip_gold_trail" }

-- G10 bots
Config.Bots = {
	Tiers = {
		{ LoopMin = 4, LoopMax = 7, Reaction = 0.6 },
		{ LoopMin = 5, LoopMax = 10, Reaction = 0.35 },
		{ LoopMin = 6, LoopMax = 12, Reaction = 0.15 },
	},
	ThreatRadius = 8,
	HuntRadius = 6,
	GentleSeconds = 120, -- bots near a new player stay slow and never cut them
	GentleSpeedScale = 0.8,
}

-- G11.6 anti-exploit
Config.Security = {
	SpeedTolerance = 1.5,
	SpeedStrikeTicks = 3,
	KickStrikes = 5,
	StrikeWindow = 60,
	RequestsPerSecond = 10,
	MaxCodeLength = 24,
}

Config.Data = { StoreName = "PlayerData_v1", AutosaveSeconds = 60, ReceiptHistory = 50, Version = 1 }
Config.Leaderboards = { RefreshSeconds = 120, Size = 50, Boards = { "cells", "kills", "bestPct", "crowns" } }

-- G8 palette
Config.Colors = {
	Ground = "#EEF1F5",
	GridLine = "#DDE2EA",
	Wall = "#2B2F3A",
	UiDark = "#1E2230",
	UiLight = "#FFFFFF",
	Yellow = "#FFC83D",
	Pink = "#FF4F8B",
	Gem = "#3DDCFF",
	Success = "#4ADE80",
	Danger = "#FF4D4D",
	Players = {
		"#FF4D4D", "#FF8A3D", "#FFC83D", "#B6E33B", "#4ADE80", "#2DD4BF", "#3DDCFF", "#4F8BFF",
		"#7C5CFF", "#C45CFF", "#FF5CD6", "#FF4F8B", "#A0704A", "#6B7A99", "#F5F5F5", "#2B2F3A",
	},
}

return Config
