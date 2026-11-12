--!strict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)

local Analytics = {}

function Analytics.log(player: Player?, event: string, fields: { [string]: any }?)
	if player == nil then
		return
	end
	local target: Player = player
	local payload: { [string]: string }? = nil
	if fields ~= nil then
		local out: { [string]: string } = {}
		local count = 0
		for key, value in pairs(fields) do
			if count >= 3 then
				break
			end
			out[key] = tostring(value)
			count += 1
		end
		payload = out
	end
	pcall(function()
		game:GetService("AnalyticsService"):LogCustomEvent(target, event, 1, payload)
	end)
end

function Analytics.funnel(player: Player, step: number, name: string)
	pcall(function()
		game:GetService("AnalyticsService"):LogOnboardingFunnelStepEvent(player, step, name)
	end)
end

return Analytics
