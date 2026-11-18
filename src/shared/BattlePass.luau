--!strict
-- Turf Pass (battle pass) rules: season clock, the tier table, XP and claim bookkeeping. Pure and unit-tested;
-- the server applies rewards (BattlePassService), the client only draws. Design: docs/BATTLEPASS.md.
local Config = require(script.Parent.Config)

export type Reward = { kind: string, amount: number?, id: string? } -- kind: coins | gems | keys | boost (seconds) | item
export type Tier = { free: { Reward }, prem: { Reward } }
export type State = {
	season: number,
	xp: number,
	premium: boolean,
	free: number, -- bitmask of claimed free tiers (bit tier-1)
	prem: number, -- bitmask of claimed premium tiers
	playDay: number, -- day number playXp counts for
	playXp: number, -- play XP granted on playDay (capped)
	bonus: number, -- bonus keys granted after the last tier
	seen: number, -- bitmask of one-time prompts shown (1 = tier 10 popup, 2 = tier 20 popup)
}

local CFG = Config.BattlePass
local BattlePass = {}

local function coins(n: number): Reward
	return { kind = "coins", amount = n }
end
local function gems(n: number): Reward
	return { kind = "gems", amount = n }
end
local function keys(n: number): Reward
	return { kind = "keys", amount = n }
end
local function boost(minutes: number): Reward
	return { kind = "boost", amount = minutes * 60 }
end
local function item(id: string): Reward
	return { kind = "item", id = id }
end

-- Season 1 "Neon Rush". Each row: { free rewards }, { premium rewards }.
local ROWS: { { { Reward } } } = {
	{ { coins(2500) }, { item("pass_neon_pulse"), item("pass_neon_pulse_trail"), gems(100) } },
	{ { coins(3000) }, { coins(6000) } },
	{ { keys(1) }, { keys(2) } },
	{ { boost(15) }, { boost(30) } },
	{ { item("pass_zigzag_rookie") }, { item("pass_sour_blast") } },
	{ { coins(3500) }, { coins(8000) } },
	{ { gems(10) }, { keys(2) } },
	{ { keys(1) }, { gems(20) } },
	{ { coins(4000) }, { coins(10000) } },
	{ { boost(15) }, { item("pass_magma_surge"), item("pass_magma_trail") } },
	{ { coins(4500) }, { boost(60) } },
	{ { gems(15) }, { item("pass_frost_bite") } },
	{ { keys(1) }, { keys(2) } },
	{ { item("pass_pebble_dash") }, { coins(12000) } },
	{ { boost(30) }, { keys(3) } },
	{ { coins(5500) }, { gems(20) } },
	{ { gems(20) }, { coins(14000) } },
	{ { keys(1) }, { item("pass_bubble_pop") } },
	{ { coins(6000) }, { boost(60) } },
	{ { boost(30) }, { item("pass_starfall"), item("pass_starfall_trail") } },
	{ { coins(7000) }, { coins(16000) } },
	{ { item("pass_turbo_tide") }, { keys(3) } },
	{ { keys(1) }, { gems(20) } },
	{ { coins(8000) }, { coins(18000) } },
	{ { gems(25) }, { keys(3) } },
	{ { coins(9000) }, { item("pass_sunset_riot") } },
	{ { keys(1) }, { boost(60) } },
	{ { coins(10000) }, { coins(20000) } },
	{ { gems(30) }, { gems(40) } },
	{ { item("pass_neon_streak"), keys(2) }, { item("pass_prism_storm"), item("pass_prism_trail"), gems(100) } },
}

BattlePass.tiers = {} :: { Tier }
for i, row in ROWS do
	BattlePass.tiers[i] = { free = row[1], prem = row[2] }
end
assert(#BattlePass.tiers == CFG.Tiers, "tier table must have Config.BattlePass.Tiers rows")

-- Tiers whose premium track holds an animated Legendary (popups, finale card).
BattlePass.legendaryTiers = { 1, 10, 20, 30 }

function BattlePass.endsAt(): number
	return CFG.Start + CFG.Days * 86400
end

-- Open in live servers from Start to the end; Start = 0 keeps it hidden live and previewable in Studio.
function BattlePass.isOpen(now: number, studio: boolean): boolean
	if CFG.Start == 0 then
		return studio
	end
	return now >= CFG.Start and now < BattlePass.endsAt()
end

function BattlePass.tierOf(xp: number): number
	return math.clamp(xp // CFG.XpPerTier, 0, CFG.Tiers)
end

function BattlePass.fresh(season: number): State
	return { season = season, xp = 0, premium = false, free = 0, prem = 0, playDay = 0, playXp = 0, bonus = 0, seen = 0 }
end

local function num(v: any): number
	return if type(v) == "number" and v == v and v >= 0 and v < math.huge then math.floor(v) else 0
end

-- Any saved value -> a valid State for `season`. When the saved season is older, also returns the rewards that
-- were reached but never claimed, so the server can deliver them (nothing earned is lost at season end).
function BattlePass.normalize(raw: any, season: number): (State, { Reward })
	local src = if type(raw) == "table" then raw else {}
	local st: State = {
		season = num(src.season),
		xp = num(src.xp),
		premium = src.premium == true,
		free = num(src.free),
		prem = num(src.prem),
		playDay = num(src.playDay),
		playXp = num(src.playXp),
		bonus = num(src.bonus),
		seen = num(src.seen),
	}
	if st.season == season then
		return st, {}
	end
	local leftovers: { Reward } = {}
	if st.season ~= 0 then
		for _, entry in BattlePass.unclaimed(st) do
			for _, r in BattlePass.rewards(entry.track, entry.tier) do
				table.insert(leftovers, r)
			end
		end
	end
	return BattlePass.fresh(season), leftovers
end

local function bit(tier: number): number
	return bit32.lshift(1, tier - 1)
end

function BattlePass.isClaimed(st: State, track: string, tier: number): boolean
	local mask = if track == "prem" then st.prem else st.free
	return bit32.btest(mask, bit(tier))
end

function BattlePass.rewards(track: string, tier: number): { Reward }
	local t = BattlePass.tiers[tier]
	if t == nil then
		return {}
	end
	return if track == "prem" then t.prem else t.free
end

-- Validates a claim request (untrusted track/tier).
function BattlePass.canClaim(st: State, track: any, tier: any): (boolean, string?)
	if (track ~= "free" and track ~= "prem") or type(tier) ~= "number" or tier ~= math.floor(tier) then
		return false, "bad_args"
	end
	if tier < 1 or tier > CFG.Tiers then
		return false, "bad_args"
	end
	if BattlePass.tierOf(st.xp) < tier then
		return false, "too_early"
	end
	if track == "prem" and not st.premium then
		return false, "premium_required"
	end
	if BattlePass.isClaimed(st, track, tier) then
		return false, "already_claimed"
	end
	return true, nil
end

function BattlePass.markClaimed(st: State, track: string, tier: number)
	if track == "prem" then
		st.prem = bit32.bor(st.prem, bit(tier))
	else
		st.free = bit32.bor(st.free, bit(tier))
	end
end

-- Every reached, unclaimed (track, tier), free first then premium, in tier order.
function BattlePass.unclaimed(st: State): { { track: string, tier: number } }
	local out = {}
	local reached = BattlePass.tierOf(st.xp)
	for tier = 1, reached do
		if not BattlePass.isClaimed(st, "free", tier) then
			table.insert(out, { track = "free", tier = tier })
		end
		if st.premium and not BattlePass.isClaimed(st, "prem", tier) then
			table.insert(out, { track = "prem", tier = tier })
		end
	end
	return out
end

-- Adds XP. Returns tiers gained and bonus keys newly earned past the last tier (also recorded in st.bonus).
function BattlePass.addXp(st: State, amount: number): (number, number)
	if type(amount) ~= "number" or amount <= 0 then
		return 0, 0
	end
	local before = BattlePass.tierOf(st.xp)
	st.xp += math.floor(amount)
	local gained = BattlePass.tierOf(st.xp) - before
	local over = st.xp - CFG.Tiers * CFG.XpPerTier
	local keysNow = if over > 0 then over // CFG.BonusKeyXp else 0
	local newKeys = math.max(0, keysNow - st.bonus)
	st.bonus = math.max(st.bonus, keysNow)
	return gained, newKeys
end

-- Play XP (captures, eliminations), capped per day. Returns XP actually granted.
function BattlePass.playXp(st: State, day: number, amount: number): number
	if st.playDay ~= day then
		st.playDay = day
		st.playXp = 0
	end
	local grant = math.clamp(math.floor(amount), 0, CFG.PlayXpPerDay - st.playXp)
	st.playXp += grant
	return grant
end

-- Catch-up: missions give double XP while 3+ tiers behind a schedule that reaches the last tier on FinishDay.
function BattlePass.isBehind(st: State, now: number): boolean
	if CFG.Start == 0 then
		return false
	end
	local days = math.max(0, (now - CFG.Start) / 86400)
	local expected = math.min(CFG.Tiers, CFG.Tiers * days / CFG.FinishDay)
	return BattlePass.tierOf(st.xp) <= expected - CFG.CatchUpBehind
end

function BattlePass.missionXp(slot: number, behind: boolean): number
	local base = CFG.MissionXp[slot] or 0
	return if behind then base * 2 else base
end

-- Premium rewards a non-premium player has reached so far (the "earned so far" counter).
function BattlePass.premiumReached(st: State, rarityOf: (string) -> string?): { legendary: number, rare: number, gems: number }
	local out = { legendary = 0, rare = 0, gems = 0 }
	for tier = 1, BattlePass.tierOf(st.xp) do
		for _, r in BattlePass.tiers[tier].prem do
			if r.kind == "gems" then
				out.gems += r.amount or 0
			elseif r.kind == "item" and r.id then
				local rarity = rarityOf(r.id)
				if rarity == "legendary" then
					out.legendary += 1
				elseif rarity == "rare" then
					out.rare += 1
				end
			end
		end
	end
	return out
end

-- Purchase effects on the state (receipts). Returns gems to grant instead (duplicate Premium) and bonus keys
-- earned by the bought XP past the last tier.
function BattlePass.applyProduct(st: State, key: string): (number, number)
	if key == "battlePass" then
		if st.premium then
			return CFG.DuplicatePremiumGems, 0
		end
		st.premium = true
		return 0, 0
	elseif key == "battlePassPlus" then
		st.premium = true
		local _, bonus = BattlePass.addXp(st, CFG.PlusXp)
		return 0, bonus
	elseif key == "battlePassTier" then
		local _, bonus = BattlePass.addXp(st, CFG.TierXp)
		return 0, bonus
	end
	return 0, 0
end

return BattlePass
