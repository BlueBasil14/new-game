--!strict
-- Loads the biome prop Models (Config.Biomes.Assets, uploaded by the lead) into
-- ReplicatedStorage.BiomeProps for the client BiomeRenderer. Off the join path; a failed or
-- missing asset only means that prop is not drawn.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local BiomeService = {}

function BiomeService.start()
	local folder = Instance.new("Folder")
	folder.Name = "BiomeProps"
	folder.Parent = ReplicatedStorage
	if next(Config.Biomes.Assets) == nil then
		return
	end
	task.spawn(function()
		local InsertService = game:GetService("InsertService")
		for name, id in Config.Biomes.Assets do
			if id ~= 0 then
				local ok, res = pcall(InsertService.LoadAsset, InsertService, id)
				if ok then
					local model = res:FindFirstChildWhichIsA("Model") or res
					model.Name = name
					model.Parent = folder
				else
					warn("BiomeService: prop " .. name .. " failed to load: " .. tostring(res))
				end
			end
		end
	end)
end

return BiomeService
