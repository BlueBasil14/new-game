--!strict
local Config = require(script.Parent.Config)
local Types = require(script.Parent.Types)

type Profile = Types.Profile

local ProfileTemplate = {}

function ProfileTemplate.default(now: number): Profile
	return {
		v = Config.Data.Version,
		coins = 0,
		gems = 0,
		crowns = 0,
		lifetimeCoinsSinceRebirth = 0,
		upgrades = { speed = 0, startSize = 0, coinBoost = 0, shield = 0 },
		owned = { default = true, sparkle = true },
		equipped = { skin = "default", trail = "default", effect = "sparkle" },
		stats = {
			cells = 0,
			kills = 0,
			deaths = 0,
			bestPct = 0,
			captures = 0,
			playSeconds = 0,
			kingSeconds = 0,
		},
		daily = { streak = 0, lastClaimDay = 0, loops = 0 },
		quests = { day = 0, list = {} },
		codes = {},
		starterPackBought = false,
		starterOfferSeenAt = 0,
		tutorialDone = false,
		receipts = {},
		boostUntil = 0,
		settings = { music = true, sfx = true, shake = true, lowDetail = false },
		firstJoin = now,
		lastJoin = now,
	}
end

local function isFiniteNumber(x: any): boolean
	return type(x) == "number" and x == x and x ~= math.huge and x ~= -math.huge
end

-- Map fields hold arbitrary string keys; only `true` entries are meaningful.
local MAP_FIELDS = { owned = true, codes = true }

local function reconcileValue(value: any, template: any): any
	local tt = type(template)
	if tt == "number" then
		if isFiniteNumber(value) then
			return math.max(0, value)
		end
		return template
	elseif tt == "table" then
		local out = {}
		local src = if type(value) == "table" then value else {}
		for k, tv in template do
			out[k] = reconcileValue(src[k], tv)
		end
		return out
	elseif type(value) == tt then
		return value
	end
	return template
end

local function reconcileMap(value: any, template: { [string]: boolean }): { [string]: boolean }
	local out: { [string]: boolean } = {}
	if type(value) == "table" then
		for k, v in value do
			if type(k) == "string" and v == true then
				out[k] = true
			end
		end
	end
	for k, v in template do
		if out[k] == nil then
			out[k] = v
		end
	end
	return out
end

local function reconcileQuestList(value: any): { { id: string, progress: number, claimed: boolean } }
	local out = {}
	if type(value) ~= "table" then
		return out
	end
	for _, q in ipairs(value) do
		if type(q) == "table" and type(q.id) == "string" then
			table.insert(out, {
				id = q.id,
				progress = if isFiniteNumber(q.progress) then math.max(0, q.progress) else 0,
				claimed = q.claimed == true,
			})
		end
	end
	return out
end

local function reconcileReceipts(value: any): { string }
	local all: { string } = {}
	if type(value) == "table" then
		for _, r in ipairs(value) do
			if type(r) == "string" then
				table.insert(all, r)
			end
		end
	end
	local limit = Config.Data.ReceiptHistory
	if #all <= limit then
		return all
	end
	local out: { string } = {}
	for i = #all - limit + 1, #all do
		table.insert(out, all[i])
	end
	return out
end

function ProfileTemplate.reconcile(data: any, now: number): Profile
	local template: any = ProfileTemplate.default(now)
	local src: { [any]: any } = if type(data) == "table" then data else {}
	local out: { [any]: any } = {}

	-- Unknown top-level keys are preserved so newer-schema fields survive an older server.
	for k, v in src do
		if template[k] == nil then
			out[k] = v
		end
	end

	for k, tv in template do
		if MAP_FIELDS[k] then
			out[k] = reconcileMap(src[k], tv)
		elseif k == "receipts" then
			out[k] = reconcileReceipts(src[k])
		elseif k == "quests" then
			local q = if type(src.quests) == "table" then src.quests else {}
			out[k] = {
				day = if isFiniteNumber(q.day) then math.max(0, q.day) else 0,
				list = reconcileQuestList(q.list),
			}
		else
			out[k] = reconcileValue(src[k], tv)
		end
	end

	out.v = Config.Data.Version
	return (out :: any) :: Profile
end

return ProfileTemplate
