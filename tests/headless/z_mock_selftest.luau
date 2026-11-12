-- Self-test of the mock's strictness (not a game scenario).
H.boot()
H.run(0.5)
local function expectError(what, fn)
	local ok = pcall(H.call, fn)
	H.check(not ok, "mock accepted: %s", what)
end
local env = H.S.env
expectError("unknown property", function() local p = env.Instance.new("Part"); p.Colour = env.Color3.new() end)
expectError("unknown method", function() local p = env.Instance.new("Part"); p:Explode() end)
expectError("wrong type", function() local p = env.Instance.new("Part"); p.Size = 5 end)
expectError("unknown class", function() env.Instance.new("Partt") end)
expectError("unknown enum", function() return env.Enum.Material.Lava end)
expectError("read-only", function() env.game.JobId = "x" end)
expectError("callback read", function() return env.game:GetService("MarketplaceService").ProcessReceipt end)
expectError("vector immutable", function() local v = env.Vector3.new(); v.X = 1 end)
expectError("remote mixed table", function()
	local r = env.Instance.new("RemoteEvent")
	local p = H.addPlayer({ userId = 9, name = "T" })
	r:FireClient(p, { 1, 2, x = 3 })
end)
expectError("remote gap", function()
	local r = env.Instance.new("RemoteEvent")
	r:FireClient(env.game:GetService("Players"):GetPlayers()[1], { [1] = 1, [3] = 3 })
end)
expectError("remote function", function()
	local r = env.Instance.new("RemoteEvent")
	r:FireClient(env.game:GetService("Players"):GetPlayers()[1], print)
end)
H.check(#H.S.misuse >= 10, "misuse not recorded (%d)", #H.S.misuse)
H.say("misuse recorded:", #H.S.misuse, "warns:", #H.S.warns)
-- infinite WaitForChild is reported
H.S.spawn(function() env.workspace:WaitForChild("Nope") end)
H.run(6)
local found = false
for _, e in H.S.errors do
	if string.find(e, "Infinite yield") then found = true end
end
H.check(found, "infinite WaitForChild not reported")
H.S.misuse = {}
H.S.errors = {}
