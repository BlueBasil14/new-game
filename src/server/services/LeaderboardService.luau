--!strict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

type Entry = { userId: number, value: number }

local LeaderboardService = {}

local boardSet: { [string]: boolean } = {}
for _, board in ipairs(Config.Leaderboards.Boards) do
	boardSet[board] = true
end

local stores: { [string]: any } = {}
local cache: { [string]: { Entry } } = {}
local pending: { [string]: { [number]: number } } = {}
local listeners: { (string, { Entry }) -> () } = {}
local available = true
local warned = false
local started = false

for _, board in ipairs(Config.Leaderboards.Boards) do
	cache[board] = {}
	pending[board] = {}
end

local function warnOnce(err: any)
	if warned then
		return
	end
	warned = true
	warn("LeaderboardService: DataStore error, leaderboards degraded: " .. tostring(err))
end

local function getStore(board: string): any?
	if not available then
		return nil
	end
	local existing = stores[board]
	if existing ~= nil then
		return existing
	end
	local ok, result = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, "LB_" .. board .. "_v1")
	if not ok then
		available = false
		warnOnce(result)
		return nil
	end
	stores[board] = result
	return result
end

local function fire(board: string, entries: { Entry })
	for _, fn in ipairs(listeners) do
		task.spawn(fn, board, entries)
	end
end

local function refresh()
	for _, player in ipairs(Players:GetPlayers()) do
		for _, board in ipairs(Config.Leaderboards.Boards) do
			local byUser = pending[board]
			local store = getStore(board)
			if byUser ~= nil and store ~= nil then
				local value = byUser[player.UserId]
				if value ~= nil then
					byUser[player.UserId] = nil
					local ok, err = pcall(store.SetAsync, store, "u_" .. player.UserId, math.floor(value))
					if not ok then
						if byUser[player.UserId] == nil then
							byUser[player.UserId] = value
						end
						warnOnce(err)
					end
				end
			end
		end
	end

	for _, board in ipairs(Config.Leaderboards.Boards) do
		local store = getStore(board)
		if store ~= nil then
			local ok, result = pcall(function()
				local pages = store:GetSortedAsync(false, Config.Leaderboards.Size)
				return pages:GetCurrentPage()
			end)
			if ok then
				local entries: { Entry } = {}
				for _, row in ipairs(result) do
					local userId = tonumber(string.sub(row.key, 3))
					if userId ~= nil then
						table.insert(entries, { userId = userId, value = row.value })
					end
				end
				cache[board] = entries
				fire(board, entries)
			else
				warnOnce(result)
			end
		end
	end
end

local function onRemoving(player: Player)
	for _, board in ipairs(Config.Leaderboards.Boards) do
		local byUser = pending[board]
		if byUser ~= nil then
			local value = byUser[player.UserId]
			if value ~= nil then
				local store = getStore(board)
				if store ~= nil then
					local ok, err = pcall(store.SetAsync, store, "u_" .. player.UserId, math.floor(value))
					if not ok then
						warnOnce(err)
					end
				end
				byUser[player.UserId] = nil
			end
		end
	end
end

function LeaderboardService.start()
	if started then
		return
	end
	started = true
	Players.PlayerRemoving:Connect(onRemoving)
	task.spawn(function()
		while true do
			refresh()
			task.wait(Config.Leaderboards.RefreshSeconds)
		end
	end)
end

function LeaderboardService.submit(player: Player, board: string, value: number)
	if not boardSet[board] then
		return
	end
	pending[board][player.UserId] = value
end

function LeaderboardService.top(board: string): { Entry }
	return cache[board] or {}
end

LeaderboardService.changed = {
	Connect = function(_self: any, fn: (string, { Entry }) -> ())
		table.insert(listeners, fn)
	end,
}

return LeaderboardService
