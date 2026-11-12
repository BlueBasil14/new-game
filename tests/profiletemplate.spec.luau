--!strict
local Config = require(script.Parent.Config)
local ProfileTemplate = require(script.Parent.ProfileTemplate)

local NOW = 1_700_000_000

local function deepEqual(a: any, b: any): boolean
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return a == b
	end
	for k, v in a do
		if not deepEqual(v, b[k]) then
			return false
		end
	end
	for k in b do
		if a[k] == nil then
			return false
		end
	end
	return true
end

-- default is valid
local d = ProfileTemplate.default(NOW)
assert(d.v == Config.Data.Version, "default v")
assert(d.coins == 0 and d.gems == 0 and d.crowns == 0, "default currencies")
assert(d.owned.default == true and d.owned.default_trail == true and d.owned.sparkle == true, "default owned")
assert(d.equipped.skin == "default" and d.equipped.trail == "default_trail" and d.equipped.effect == "sparkle", "default equipped")
assert(d.settings.music and d.settings.sfx and d.settings.shake and not d.settings.lowDetail, "default settings")
assert(d.firstJoin == NOW and d.lastJoin == NOW, "default join times")
assert(#d.receipts == 0 and #d.quests.list == 0, "default lists empty")

-- reconcile(nil) equals default
assert(deepEqual(ProfileTemplate.reconcile(nil, NOW), d), "reconcile(nil) == default")
assert(deepEqual(ProfileTemplate.reconcile(d, NOW), d), "reconcile(default) idempotent")

-- repair a damaged profile
local receipts = {}
for i = 1, 80 do
	receipts[i] = "r" .. i
end
local broken: any = {
	v = 0,
	coins = -50,
	gems = "lots",
	crowns = 3,
	upgrades = { speed = 2 },
	owned = { neon = true, junk = "yes" },
	equipped = { skin = 5 },
	stats = "nope",
	quests = { day = 4, list = { { id = "q1", progress = -3, claimed = true }, { progress = 1 } } },
	receipts = receipts,
	settings = { music = false },
	firstJoin = 123,
	futureField = { keep = true },
}
local p = ProfileTemplate.reconcile(broken, NOW)
assert(p.v == Config.Data.Version, "v set")
assert(p.coins == 0, "negative coins clamped")
assert(p.gems == 0, "string gems coerced")
assert(p.crowns == 3, "valid crowns kept")
assert(p.upgrades.speed == 2 and p.upgrades.shield == 0 and p.upgrades.coinBoost == 0, "upgrades filled")
assert(p.owned.neon == true and p.owned.default == true and p.owned.default_trail == true and p.owned.sparkle == true, "owned merged")
assert((p.owned :: any).junk == nil, "non-boolean owned dropped")
assert(p.equipped.skin == "default" and p.equipped.trail == "default_trail" and p.equipped.effect == "sparkle", "equipped repaired")
assert(p.stats.kills == 0 and p.stats.kingSeconds == 0, "stats rebuilt")
assert(p.daily.streak == 0 and p.daily.loops == 0, "daily filled")
assert(p.quests.day == 4 and #p.quests.list == 1, "quests repaired")
assert(p.quests.list[1].progress == 0 and p.quests.list[1].claimed == true, "quest entry clamped")
assert(#p.receipts == Config.Data.ReceiptHistory, "receipts trimmed")
assert(p.receipts[#p.receipts] == "r80", "newest receipt kept")
assert(p.receipts[1] == "r" .. (80 - Config.Data.ReceiptHistory + 1), "oldest receipts dropped")
assert(p.settings.music == false and p.settings.sfx == true and p.settings.lowDetail == false, "settings filled")
assert(p.firstJoin == 123 and p.lastJoin == NOW, "join times")
assert((p :: any).futureField and (p :: any).futureField.keep == true, "unknown top-level kept")
assert(type(p.codes) == "table" and p.starterPackBought == false, "misc defaults")

return "profiletemplate ok"
