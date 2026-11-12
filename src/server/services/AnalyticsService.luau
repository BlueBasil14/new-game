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

return Analytics
