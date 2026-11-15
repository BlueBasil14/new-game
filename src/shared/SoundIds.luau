--!strict
-- Roblox audio asset ids for every GDD G9.2 sound. 0 = not picked yet (FeedbackController skips it).
-- Sources: "Daily Sounds" free set (DailySoundsFX) and Pro Sound Effects on the Creator Store, and the
-- RBLX Essentials Sound System pack already installed in the place (assets/rblxessentials).
-- Each non-zero id was checked to load in Studio; none has been judged by ear yet.
local SoundIds: { [string]: number } = {
	trailStart = 133564751966469, -- Platformer Jump - Daily Sounds
	trailLoop = 0,
	heartbeat = 132163421525060, -- Fast Heartbeat - Daily Sounds
	claimPop = 106984966606682, -- Cartoon Pop - Daily Sounds
	bigClaim = 88130568524452, -- Reward_Rise_01 - RBLX Essentials Sound System pack
	stealCrunch = 9113959343, -- Crack Egg Crunchy 11 - Pro Sound Effects
	snip = 76771846843586, -- Movement_Swish_01 - RBLX Essentials pack (a swish, not scissors)
	deathPop = 96795857757261, -- Power Down - Daily Sounds
	respawnWhoosh = 80984744279155, -- Fast Whoosh - Daily Sounds
	crownFanfare = 4612378086, -- Roulette_Reward - RBLX Essentials pack
	coinTick = 130378474223829, -- Coin Pickup - Daily Sounds
	purchase = 138309872562566, -- Retro Coin Collect - Daily Sounds
	uiHover = 103003970474571, -- Hover - RBLX Essentials pack
	uiClick = 106623224876186, -- Tiny Click - Daily Sounds
	uiError = 91501650514390, -- Error Buzz - Daily Sounds
	rewardClaim = 130378474223829, -- Coin Pickup - Daily Sounds (same as coinTick)
	questComplete = 112485797063762, -- Level_Up - RBLX Essentials pack
	rebirthSwell = 94077390731779, -- Cinematic Riser - Daily Sounds
	lobbyMusic = 0, -- music comes from the RBLX Essentials music player; keep 0 so two tracks never overlap
	arenaMusic = 0, -- as above
}

return SoundIds
