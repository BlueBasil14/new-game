--!strict
-- Single source of client truth: profile, session, arena mirror and the signals other client code listens to.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Types = require(Shared.Types)
local Remotes = require(Shared.Remotes)
local Catalog = require(Shared.Catalog)
local Formulas = require(Shared.Formulas)
local UiKit = require(script.Parent.ui.UiKit)

export type Connection = { Disconnect: (self: Connection) -> () }
export type Signal = {
	Connect: (self: Signal, fn: (...any) -> ()) -> Connection,
	Fire: (self: Signal, ...any) -> (),
}

export type SessionInfo = {
	multiplier: number,
	passes: { [string]: boolean },
	featured: { string },
	joinedAt: number,
	playtimeClaimed: { [number]: boolean },
	starterOffer: boolean,
	serverTime: number,
}

local function newSignal(): Signal
	local handlers: { { fn: (...any) -> () } } = {}
	local signal = {} :: Signal
	function signal.Connect(_self: Signal, fn: (...any) -> ()): Connection
		local entry = { fn = fn }
		table.insert(handlers, entry)
		local conn = {} :: Connection
		function conn.Disconnect(_c: Connection)
			local i = table.find(handlers, entry)
			if i then
				table.remove(handlers, i)
			end
		end
		return conn
	end
	function signal.Fire(_self: Signal, ...: any)
		for _, entry in table.clone(handlers) do
			task.spawn(entry.fn, ...)
		end
	end
	return signal
end

local ClientState = {}

ClientState.signal = newSignal

ClientState.profile = nil :: Types.Profile?
ClientState.session = {
	multiplier = 1,
	passes = {},
	featured = {},
	joinedAt = os.time(),
	playtimeClaimed = {},
	starterOffer = false,
	serverTime = os.time(),
} :: SessionInfo

ClientState.profileChanged = newSignal()
ClientState.arenaChanged = newSignal()
ClientState.arenaEvent = newSignal()
ClientState.death = newSignal()
ClientState.reward = newSignal()

ClientState.arena = {
	myId = nil :: number?,
	runners = {} :: { [number]: Types.RunnerInfo },
	cells = {} :: { [number]: number }, -- runner id -> owned cell count
	kingId = 0,
	totalCells = Config.Arena.GridSize ^ 2,
	alive = false,
}

local started = false
local requestRemote: RemoteFunction? = nil
local receivedClock = os.clock()

-- Server unix time, advanced locally between profile updates.
function ClientState.serverNow(): number
	return ClientState.session.serverTime + (os.clock() - receivedClock)
end

function ClientState.request(name: string, ...: any): (boolean, any)
	local remote = requestRemote
	if remote == nil then
		local folder = ReplicatedStorage:FindFirstChild(Remotes.Folder)
		local found = folder and folder:FindFirstChild(Remotes.Request)
		if found and found:IsA("RemoteFunction") then
			remote = found
			requestRemote = found
		end
	end
	if remote == nil then
		return false, "network"
	end
	local args = table.pack(...)
	local callOk, ok, result = pcall(function()
		return (remote :: RemoteFunction):InvokeServer(name, table.unpack(args, 1, args.n))
	end)
	if not callOk then
		return false, "network"
	end
	return ok == true, result
end

function ClientState.start()
	if started then
		return
	end
	started = true
	local folder = ReplicatedStorage:WaitForChild(Remotes.Folder)
	local rf = folder:WaitForChild(Remotes.Request)
	if rf:IsA("RemoteFunction") then
		requestRemote = rf
	end

	local profileUpdate = folder:WaitForChild(Remotes.ProfileUpdate) :: RemoteEvent
	profileUpdate.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" or payload.profile == nil then
			return
		end
		local previous = ClientState.profile
		ClientState.profile = payload.profile
		if payload.session then
			ClientState.session = payload.session
			receivedClock = os.clock()
		end
		ClientState.profileChanged:Fire(ClientState.profile, ClientState.session, previous)
	end)

	local death = folder:WaitForChild(Remotes.Death) :: RemoteEvent
	death.OnClientEvent:Connect(function(payload: any)
		ClientState.death:Fire(payload)
	end)

	local reward = folder:WaitForChild(Remotes.Reward) :: RemoteEvent
	reward.OnClientEvent:Connect(function(payload: any)
		ClientState.reward:Fire(payload)
	end)

	local toast = folder:WaitForChild(Remotes.Toast) :: RemoteEvent
	toast.OnClientEvent:Connect(function(text: any, kind: any)
		local color: Color3 = UiKit.theme.UiDark
		if kind == "good" then
			color = UiKit.theme.Success
		elseif kind == "bad" then
			color = UiKit.theme.Danger
		end
		UiKit.toast(tostring(text), color)
	end)
end

function ClientState.myShare(): number
	local arena = ClientState.arena
	local id = arena.myId
	if id == nil or arena.totalCells <= 0 then
		return 0
	end
	local count = arena.cells[id]
	if count == nil then
		return 0
	end
	return count / arena.totalCells
end

function ClientState.owns(itemId: string): boolean
	local item = Catalog.byId(itemId)
	if item and item.default then
		return true
	end
	local p = ClientState.profile
	return p ~= nil and p.owned[itemId] == true
end

function ClientState.coins(): number
	local p = ClientState.profile
	return if p then p.coins else 0
end

function ClientState.gems(): number
	local p = ClientState.profile
	return if p then p.gems else 0
end

-- Extras used by the HUD and panels.
local questsById: { [string]: Catalog.Quest } = {}
for _, q in Catalog.quests do
	questsById[q.id] = q
end

function ClientState.quest(id: string): Catalog.Quest?
	return questsById[id]
end

function ClientState.dailyState(): { canClaim: boolean, nextStreak: number }
	local p = ClientState.profile
	if p == nil then
		return { canClaim = false, nextStreak = 1 }
	end
	return Formulas.dailyClaimState(p.daily.lastClaimDay, p.daily.streak, Formulas.dayNumber(ClientState.serverNow()))
end

function ClientState.questClaimable(): boolean
	local p = ClientState.profile
	if p == nil then
		return false
	end
	for _, entry in p.quests.list do
		local def = questsById[entry.id]
		if def and not entry.claimed and entry.progress >= def.target then
			return true
		end
	end
	return false
end

return ClientState
