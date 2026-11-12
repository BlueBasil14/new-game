--!strict
-- Shared type contracts. Cell indices are 0-based: index = y * GridSize + x, x and y in [0, GridSize).
-- Owner ids: 0 = neutral, 1..255 = runner id (players and bots share the id space).

export type RunnerInfo = {
	id: number, -- 1..255
	userId: number, -- 0 for bots
	name: string,
	colorIndex: number, -- 1..16 into Config.Colors.Players
	skin: string, -- Catalog item id
	trail: string, -- Catalog item id
	effect: string, -- Catalog item id
	isBot: boolean,
}

-- Events emitted by ArenaSim.step and forwarded to clients on Remotes.ArenaEvent.
export type ArenaEvent =
	{ kind: "spawn", runner: RunnerInfo, x: number, y: number, shieldUntil: number }
	| { kind: "despawn", id: number }
	| { kind: "claim", id: number, cells: number, neutral: number, stolen: number, cx: number, cy: number }
	| { kind: "cut", killer: number, victim: number, victimCells: number, victimWasKing: boolean }
	| { kind: "king", id: number } -- id 0 = nobody
	| { kind: "fullMap", id: number }

-- One entry per runner whose trail changed in a replication batch.
export type TrailDelta = { id: number, clear: boolean, append: { number } } -- append = cell indices in order

export type Profile = {
	v: number,
	coins: number,
	gems: number,
	crowns: number,
	lifetimeCoinsSinceRebirth: number,
	upgrades: { speed: number, startSize: number, coinBoost: number, shield: number },
	owned: { [string]: boolean }, -- Catalog item ids of every type
	equipped: { skin: string, trail: string, effect: string },
	stats: {
		cells: number,
		kills: number,
		deaths: number,
		bestPct: number,
		captures: number,
		playSeconds: number,
		kingSeconds: number,
	},
	daily: { streak: number, lastClaimDay: number, loops: number }, -- day = floor(unix / 86400)
	quests: { day: number, list: { { id: string, progress: number, claimed: boolean } } },
	codes: { [string]: boolean },
	starterPackBought: boolean,
	starterOfferSeenAt: number,
	tutorialDone: boolean,
	receipts: { string },
	boostUntil: number, -- unix seconds
	settings: { music: boolean, sfx: boolean, shake: boolean, lowDetail: boolean },
	firstJoin: number,
	lastJoin: number,
}

return {}
