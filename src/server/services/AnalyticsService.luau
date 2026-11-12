--!strict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)

local Analytics = {}

local CUSTOM_KEYS = { "CustomField01", "CustomField02", "CustomField03" }

function Analytics.log(player: Player?, event: string, fields: { [string]: any }?)
	if player == nil then
		return
	end
	local target: Player = player
	local payload: { [string]: string }? = nil
	if fields ~= nil then
		-- Roblox only accepts Enum.AnalyticsCustomFieldKeys names (CustomField01..03) as keys;
		-- field names are sorted so each event maps them to the same slot every time.
		local names: { string } = {}
		for key in pairs(fields) do
			table.insert(names, key)
		end
		table.sort(names)
		local out: { [string]: string } = {}
		for i = 1, math.min(#names, #CUSTOM_KEYS) do
			out[CUSTOM_KEYS[i]] = tostring(fields[names[i]])
		end
		payload = out
	end
	local ok = pcall(function()
		game:GetService("AnalyticsService"):LogCustomEvent(target, event, 1, payload)
	end)
	if not ok and payload ~= nil then
		pcall(function()
			game:GetService("AnalyticsService"):LogCustomEvent(target, event, 1)
		end)
	end
end

function Analytics.funnel(player: Player, step: number, name: string)
	pcall(function()
		game:GetService("AnalyticsService"):LogOnboardingFunnelStepEvent(player, step, name)
	end)
end

-- Funnel step logged at most once per player per session (GDD G12: join, first capture, first upgrade,
-- first death, respawn, minute 10).
local funnelSeen: { [Player]: { [number]: boolean } } = {}

function Analytics.funnelOnce(player: Player, step: number, name: string)
	local seen = funnelSeen[player]
	if seen == nil then
		seen = {}
		funnelSeen[player] = seen
	end
	local set = seen :: { [number]: boolean }
	if set[step] then
		return
	end
	set[step] = true
	Analytics.funnel(player, step, name)
end

game:GetService("Players").PlayerRemoving:Connect(function(player: Player)
	funnelSeen[player] = nil
end)

return Analytics
