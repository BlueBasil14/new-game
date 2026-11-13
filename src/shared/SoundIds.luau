--!strict
-- Roblox audio asset ids for every GDD G9.2 sound. 0 = not picked yet (FeedbackController skips it).
-- Sources: "Daily Sounds" free set (DailySoundsFX) and Pro Sound Effects, both on the Creator Store.
-- Each non-zero id was checked to load in Studio; none has been judged by ear yet.
local SoundIds: { [string]: number } = {
	trailStart = 133564751966469, -- Platformer Jump - Daily Sounds
	trailLoop = 0,
	heartbeat = 132163421525060, -- Fast Heartbeat - Daily Sounds
	claimPop = 106984966606682, -- Cartoon Pop - Daily Sounds
	bigClaim = 0,
	stealCrunch = 9113959343, -- Crack Egg Crunchy 11 - Pro Sound Effects
	snip = 0,
	deathPop = 96795857757261, -- Power Down - Daily Sounds
	respawnWhoosh = 80984744279155, -- Fast Whoosh - Daily Sounds
	crownFanfare = 0,
	coinTick = 130378474223829, -- Coin Pickup - Daily Sounds
	purchase = 138309872562566, -- Retro Coin Collect - Daily Sounds
	uiHover = 0,
	uiClick = 106623224876186, -- Tiny Click - Daily Sounds
	uiError = 91501650514390, -- Error Buzz - Daily Sounds
	rewardClaim = 130378474223829, -- Coin Pickup - Daily Sounds (same as coinTick)
	questComplete = 0,
	rebirthSwell = 94077390731779, -- Cinematic Riser - Daily Sounds
	lobbyMusic = 0,
	arenaMusic = 0,
}

return SoundIds
