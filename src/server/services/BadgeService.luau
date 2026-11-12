--!strict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)

local Players = game:GetService("Players")

local Badges = {}

local awarded: { [number]: { [string]: boolean } } = {}

function Badges.award(player: Player, key: string)
	local id = Config.Ids.Badges[key]
	if id == nil or id == 0 then
		return
	end
	local set = awarded[player.UserId]
	if set == nil then
		set = {}
		awarded[player.UserId] = set
	end
	if set[key] then
		return
	end
	set[key] = true
	local userId = player.UserId
	task.spawn(function()
		local ok = pcall(function()
			game:GetService("BadgeService"):AwardBadge(userId, id)
		end)
		if not ok and awarded[userId] ~= nil then
			awarded[userId][key] = nil
		end
	end)
end

Players.PlayerRemoving:Connect(function(player: Player)
	awarded[player.UserId] = nil
end)

return Badges
