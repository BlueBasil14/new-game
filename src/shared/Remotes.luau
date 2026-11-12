--!strict
-- Names of every remote and every client request (GDD G11.4). Instances are created by the
-- server in ReplicatedStorage.Remotes; clients WaitForChild them.
local Remotes = {}

Remotes.Folder = "Remotes"

-- server -> client RemoteEvents
Remotes.ArenaSnapshot = "ArenaSnapshot" -- (rle: buffer, runners: {RunnerInfo}, yourRunnerId: number?)
Remotes.ArenaDelta = "ArenaDelta" -- (cells: buffer, trails: {TrailDelta})   see Types
Remotes.ArenaEvent = "ArenaEvent" -- (event: ArenaEvent)
Remotes.ProfileUpdate = "ProfileUpdate" -- (partial profile table)
Remotes.Toast = "Toast" -- (key: string, args: {any}?)

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
}

return Remotes
