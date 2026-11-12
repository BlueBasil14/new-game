--!strict
local R = require(script.Parent.EconomyRules)
local Config = require(script.Parent.Config)

local function eq(a: any, b: any, msg: string)
	if a ~= b then
		error(msg .. ": got " .. tostring(a) .. " expected " .. tostring(b), 2)
	end
end

local cfg = Config.Products.starterPack
local hour = 3600
eq(R.shouldOfferStarter(false, cfg.OfferAfterSeconds - 1, 0, 1000), false, "too early")
eq(R.shouldOfferStarter(false, cfg.OfferAfterSeconds, 0, 1000), true, "first offer")
eq(R.shouldOfferStarter(true, cfg.OfferAfterSeconds, 0, 1000), false, "bought")
eq(R.shouldOfferStarter(false, cfg.OfferAfterSeconds, 1000, 1000 + cfg.OfferWindowHours * hour), true, "window edge")
eq(R.shouldOfferStarter(false, cfg.OfferAfterSeconds, 1000, 1001 + cfg.OfferWindowHours * hour), false, "window over")

local defs = { a = { kind = "cells", target = 500 }, b = { kind = "mapPct", target = 10 }, c = { kind = "cells", target = 50 } }
local function list()
	return { { id = "a", progress = 0, claimed = false }, { id = "b", progress = 0, claimed = false }, { id = "c", progress = 0, claimed = true } }
end

local l = list()
eq(R.applyQuestProgress(l, defs, "cells", 300, "add"), true, "add changed")
eq(l[1].progress, 300, "add a")
eq(l[2].progress, 0, "other kind")
eq(l[3].progress, 0, "claimed frozen")
R.applyQuestProgress(l, defs, "cells", 300, "add")
eq(l[1].progress, 500, "capped")
eq(R.applyQuestProgress(l, defs, "cells", 5, "add"), false, "no change at cap")
R.applyQuestProgress(l, defs, "mapPct", 7, "max")
R.applyQuestProgress(l, defs, "mapPct", 3, "max")
eq(l[2].progress, 7, "max keeps highest")
eq(R.applyQuestProgress(l, defs, "mapPct", -1, "max"), false, "negative ignored")
eq(R.applyQuestProgress(l, defs, "mapPct", 0 / 0, "max"), false, "nan ignored")
