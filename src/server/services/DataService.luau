--!strict
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Types = require(Shared.Types)
local ProfileTemplate = require(Shared.ProfileTemplate)

type Profile = Types.Profile

type Store = {
	update: (key: string, transform: (any) -> any) -> any,
}

type Session = {
	key: string,
	profile: Profile,
	dirty: boolean,
	released: boolean,
}

local LOCK_TIMEOUT = 120
local LOCK_RETRIES = 5
local LOCK_RETRY_WAIT = 6
local CALL_TRIES = 3
local CLOSE_CAP = 25

local DataService = {}

local listeners: { (Player, Profile) -> () } = {}
DataService.changed = {
	Connect = function(_self: any, fn: (Player, Profile) -> ())
		table.insert(listeners, fn)
		return {
			Disconnect = function()
				local i = table.find(listeners, fn)
				if i then
					table.remove(listeners, i)
				end
			end,
		}
	end,
}

local store: Store? = nil
local sessions: { [Player]: Session } = {}
local loading: { [Player]: boolean } = {}
local releasing = 0 -- release writes in flight
local started = false

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in value do
		out[k] = deepCopy(v)
	end
	return out
end

local function makeMockStore(): Store
	local data: { [string]: any } = {}
	return {
		update = function(key: string, transform: (any) -> any): any
			local result = transform(deepCopy(data[key]))
			if result ~= nil then
				data[key] = deepCopy(result)
			end
			return result
		end,
	}
end

local function makeRealStore(ds: DataStore): Store
	return {
		update = function(key: string, transform: (any) -> any): any
			return (ds:UpdateAsync(key, transform))
		end,
	}
end

local function initStore(): Store
	local ok, ds = pcall(function()
		return DataStoreService:GetDataStore(Config.Data.StoreName)
	end)
	if ok and ds and RunService:IsStudio() then
		-- Unpublished places / API access off only fail on the first real request.
		ok = pcall(function()
			local _ = (ds :: DataStore):GetAsync("__probe")
		end)
	end
	if ok and ds then
		return makeRealStore(ds :: DataStore)
	end
	if RunService:IsStudio() then
		warn("[DataService] DataStores unavailable in Studio; using an in-memory mock store. Progress will not persist.")
		return makeMockStore()
	end
	-- Live server without a store: every call fails, so players are kicked rather than given unsaved data.
	warn("[DataService] GetDataStore failed:", ds)
	return {
		update = function(_key: string, _transform: (any) -> any): any
			error("DataStore unavailable")
		end,
	}
end

local function getStore(): Store
	if not store then
		store = initStore()
	end
	return store :: Store
end

local function withRetry(fn: () -> any): (boolean, any)
	local lastErr: any = nil
	for attempt = 1, CALL_TRIES do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		if attempt < CALL_TRIES then
			task.wait(2 ^ (attempt - 1))
		end
	end
	warn("[DataService] DataStore call failed after retries:", lastErr)
	return false, lastErr
end

local function keyFor(player: Player): string
	return "u_" .. tostring(player.UserId)
end

local function stripLock(data: any): Profile
	data._lock = nil
	return data :: Profile
end

-- Returns "ok" | "locked" | "error", plus the profile on "ok".
local function tryLoad(key: string): (string, Profile?)
	local blocked = false
	local loaded: any = nil
	local ok = withRetry(function()
		return getStore().update(key, function(old: any): any
			blocked = false
			loaded = nil
			local now = os.time()
			if type(old) == "table" and type(old._lock) == "table" then
				local lock = old._lock
				local t = if type(lock.t) == "number" then lock.t else 0
				if lock.jobId ~= game.JobId and now - t < LOCK_TIMEOUT then
					blocked = true
					return nil
				end
			end
			local data: any = ProfileTemplate.reconcile(old, now)
			data.lastJoin = now
			data._lock = { jobId = game.JobId, t = now }
			loaded = data
			return data
		end)
	end)
	if not ok then
		return "error", nil
	end
	if blocked then
		return "locked", nil
	end
	if loaded == nil then
		return "error", nil
	end
	return "ok", stripLock(deepCopy(loaded))
end

-- Writes only while we still own the lock, so a lost lock can never clobber another server's data.
local function write(session: Session, releaseLock: boolean): boolean
	local snapshot: any = deepCopy(session.profile)
	local lockLost = false
	local ok = withRetry(function()
		return getStore().update(session.key, function(old: any): any
			lockLost = false
			if not releaseLock and session.released then
				-- An autosave still in flight when the session was released must not re-take the lock.
				return nil
			end
			if type(old) ~= "table" or type(old._lock) ~= "table" or old._lock.jobId ~= game.JobId then
				lockLost = true
				return nil
			end
			local out = deepCopy(snapshot)
			if not releaseLock then
				out._lock = { jobId = game.JobId, t = os.time() }
			end
			return out
		end)
	end)
	if ok and lockLost then
		warn("[DataService] Session lock lost for " .. session.key .. "; save skipped.")
		return false
	end
	if ok then
		session.dirty = false
	end
	return ok
end

function DataService.load(player: Player): Profile?
	local existing = sessions[player]
	if existing and not existing.released then
		return existing.profile
	end
	while loading[player] do
		task.wait(0.1)
	end
	if sessions[player] then
		return DataService.get(player)
	end

	loading[player] = true
	local key = keyFor(player)
	local status, profile = "error", nil
	for attempt = 0, LOCK_RETRIES do
		if attempt > 0 then
			task.wait(LOCK_RETRY_WAIT)
		end
		if player.Parent == nil then
			loading[player] = nil
			return nil
		end
		status, profile = tryLoad(key)
		if status ~= "locked" then
			break
		end
	end
	loading[player] = nil

	if status ~= "ok" or profile == nil then
		if player.Parent ~= nil then
			if status == "locked" then
				player:Kick("Your data is still being saved by another server. Please rejoin in a minute.")
			else
				player:Kick("We couldn't load your data safely. Please rejoin in a moment.")
			end
		end
		return nil
	end

	local session: Session = { key = key, profile = profile, dirty = false, released = false }
	sessions[player] = session
	if player.Parent == nil then
		-- Left mid-load: drop the lock we just took.
		DataService.release(player)
		return nil
	end
	return profile
end

function DataService.get(player: Player): Profile?
	local session = sessions[player]
	if session and not session.released then
		return session.profile
	end
	return nil
end

function DataService.update(player: Player, fn: (Profile) -> ())
	local session = sessions[player]
	if not session or session.released then
		return
	end
	fn(session.profile)
	session.dirty = true
	for _, cb in table.clone(listeners) do
		task.spawn(cb, player, session.profile)
	end
end

function DataService.save(player: Player): boolean
	local session = sessions[player]
	if not session or session.released then
		return false
	end
	return write(session, false)
end

function DataService.release(player: Player)
	local session = sessions[player]
	if not session or session.released then
		return
	end
	session.released = true
	releasing += 1
	write(session, true)
	releasing -= 1
	if sessions[player] == session then
		sessions[player] = nil
	end
end

function DataService.hasReceipt(profile: Profile, purchaseId: string): boolean
	return table.find(profile.receipts, purchaseId) ~= nil
end

function DataService.addReceipt(profile: Profile, purchaseId: string)
	if DataService.hasReceipt(profile, purchaseId) then
		return
	end
	table.insert(profile.receipts, purchaseId)
	while #profile.receipts > Config.Data.ReceiptHistory do
		table.remove(profile.receipts, 1)
	end
end

local function autosaveLoop()
	while true do
		local period = Config.Data.AutosaveSeconds
		local list: { Player } = {}
		for player, session in sessions do
			if not session.released then
				table.insert(list, player)
			end
		end
		if #list == 0 then
			task.wait(period)
		else
			local gap = period / #list
			for _, player in list do
				task.wait(gap)
				-- Always written, even when clean, because the write also refreshes the session lock.
				if sessions[player] and not sessions[player].released then
					task.spawn(DataService.save, player)
				end
			end
		end
	end
end

local function onClose()
	for player, session in sessions do
		if not session.released then
			task.spawn(DataService.release, player)
		end
	end
	-- Also waits for releases PlayerRemoving started during shutdown: the server stops as soon as
	-- BindToClose returns, which would drop those in-flight saves.
	local deadline = os.clock() + CLOSE_CAP
	while releasing > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end

function DataService.start()
	if started then
		return
	end
	started = true
	getStore()
	Players.PlayerRemoving:Connect(function(player: Player)
		DataService.release(player)
	end)
	game:BindToClose(onClose)
	task.spawn(autosaveLoop)
end

return DataService
