--!strict
-- Names of every remote and every client request (GDD G11.4). Instances are created by the
-- server in ReplicatedStorage.Remotes; clients WaitForChild them.
local Remotes = {}

Remotes.Folder = "Remotes"

-- server -> client RemoteEvents
Remotes.ArenaSnapshot = "ArenaSnapshot" -- (rle: buffer, runners: {RunnerInfo}, yourRunnerId: number?)
Remotes.ArenaDelta = "ArenaDelta" -- (cells: buffer, trails: {TrailDelta})   see Types
Remotes.ArenaEvent = "ArenaEvent" -- (event: ArenaEvent)
-- (payload: { coins: number, cells: number, lifeSeconds: number, kills: number, canSecondChance: boolean, killerName: string? })
Remotes.Death = "Death" -- sent to the eliminated player only
Remotes.Reward = "Reward" -- (payload: { coins: number?, gems: number?, reason: string, cx: number?, cy: number? }) popup feedback
-- (payload: { profile: Profile (receipts stripped), session: SessionInfo })
-- SessionInfo = { multiplier: number, passes: { [string]: boolean }, featured: { string },
--   joinedAt: number (os.time), playtimeClaimed: { [number]: boolean }, starterOffer: boolean, serverTime: number }
-- Sent in full on load and after every profile change (throttled to 4 Hz per player).
Remotes.ProfileUpdate = "ProfileUpdate"
Remotes.Toast = "Toast" -- (text: string, kind: "info" | "good" | "bad")

-- client -> server RemoteFunction; server returns (ok: boolean, resultOrErrorKey: any)
Remotes.Request = "Request"

Remotes.Requests = {
	BuyUpgrade = "BuyUpgrade", -- (upgradeId: string)
	BuyItem = "BuyItem", -- (itemId: string)
	Equip = "Equip", -- (itemId: string)
	ClaimDaily = "ClaimDaily", -- ()
	ClaimPlaytime = "ClaimPlaytime", -- (index: number)
	ClaimQuest = "ClaimQuest", -- (index: number)
	RedeemCode = "RedeemCode", -- (code: string)
	Rebirth = "Rebirth", -- ()
	Respawn = "Respawn", -- ()
	SetSetting = "SetSetting", -- (key: string, value: boolean)
	TutorialDone = "TutorialDone", -- ()
	StarterOfferSeen = "StarterOfferSeen", -- ()
	DeclineSecondChance = "DeclineSecondChance", -- ()
}

return Remotes
