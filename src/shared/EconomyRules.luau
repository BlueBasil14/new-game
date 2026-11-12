--!strict
-- Pure decision logic shared by the economy services so it can be unit tested.
local Config = require(script.Parent.Config)

local EconomyRules = {}

export type QuestDef = { kind: string, target: number }
export type QuestEntry = { id: string, progress: number, claimed: boolean }

local SECONDS_PER_HOUR = 3600

-- GDD G4.2: shown once the session is old enough, then only inside the offer window.
function EconomyRules.shouldOfferStarter(bought: boolean, sessionSeconds: number, seenAt: number, now: number): boolean
	local cfg = Config.Products.starterPack
	if bought or sessionSeconds < cfg.OfferAfterSeconds then
		return false
	end
	if seenAt == 0 then
		return true
	end
	return now - seenAt <= cfg.OfferWindowHours * SECONDS_PER_HOUR
end

-- Returns true when any entry changed. Claimed quests are frozen; progress is capped at target.
function EconomyRules.applyQuestProgress(
	list: { QuestEntry },
	defs: { [string]: QuestDef },
	kind: string,
	amount: number,
	mode: string
): boolean
	if amount ~= amount or amount <= 0 or amount == math.huge then
		return false
	end
	local changed = false
	for _, entry in list do
		local def = defs[entry.id]
		if def ~= nil and def.kind == kind and not entry.claimed then
			local nextValue = if mode == "add" then entry.progress + amount else math.max(entry.progress, amount)
			nextValue = math.min(nextValue, def.target)
			if nextValue ~= entry.progress then
				entry.progress = nextValue
				changed = true
			end
		end
	end
	return changed
end

return EconomyRules
