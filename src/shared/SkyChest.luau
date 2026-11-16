--!strict
-- Exact server odds; UI presents these before any paid spin.
local SkyChest= {
	Interval = 300,
	Lifetime = 120,
	FallSeconds = 3,
	SpeedSeconds = 180,
	ProductId = 3732125306,
	Prizes = {
		{ name = "500 coins", kind = "coins", amount = 500, weight = 35, icon = "economy_coin_stack" },
		{ name = "25 gems", kind = "gems", amount = 25, weight = 25, icon = "economy_gem" },
		{ name = "1,500 coins", kind = "coins", amount = 1500, weight = 20, icon = "economy_coin_stack" },
		{ name = "75 gems", kind = "gems", amount = 75, weight = 10, icon = "economy_gem_cluster" },
		{ name = "2x speed · 3 min", kind = "speed", amount = 180, weight = 8, icon = "gameplay_speed" },
		{ name = "Sky Blue skin", kind = "skin", skin = "sky_blue", amount = 100, weight = 2, icon = "gameplay_cosmetics" },
	},
}
return SkyChest
