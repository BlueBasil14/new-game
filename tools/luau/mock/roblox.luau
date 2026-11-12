--!nocheck
-- Headless Roblox SERVER mock for tools/luau/headless.mjs (see docs/HEADLESS.md).
-- Everything here is strict on purpose: an unknown class, property, method, enum or a
-- wrongly-typed property assignment errors with the class and member name, and is also
-- recorded in S.misuse so that misuse hidden behind a pcall still fails the scenario.
-- The chunk returns the table M; M.runScenario(mods, scenarioFn, name) runs one scenario.

local M = {}

local rawtypeof = typeof
local rawprint = print
local realClock = os.clock
local realTime = os.time
local realDate = os.date
local fmt = string.format
local REAL_G = getfenv(0)

M.clock = 0 -- virtual seconds since the run started
M.TIME0 = 1767787200 -- os.time() at clock 0: Wed 2026-01-07 12:00 UTC (no weekend bonus, no day rollover)
M.CLOCK0 = 50 -- os.clock() at clock 0
M.verbose = false
M.current = nil -- current server S
M.dsBacking = { stores = {}, ordered = {} } -- persists across server restarts within one run
M.dsDown = false -- false | "requests" | "all"
M.dsLatency = 0.05
M.passes = {} -- [userId] = { [passId] = true }
M.groups = {} -- [userId] = { [groupId] = true }
M.badges = {} -- list of { userId, badgeId }

local TYPE = setmetatable({}, { __mode = "k" })
local DATA = setmetatable({}, { __mode = "k" })
M.TYPE, M.DATA = TYPE, DATA

local function typeofm(v)
	local t = TYPE[v]
	if t ~= nil then
		return t
	end
	return rawtypeof(v)
end
M.typeof = typeofm

local function misuse(msg, level)
	local S = M.current
	if S ~= nil then
		table.insert(S.misuse, msg .. "\n" .. debug.traceback("", (level or 1) + 1))
	end
	error(msg, (level or 1) + 1)
end
M.misuse = misuse

local function proxy(tname, data, meta)
	local p = newproxy(true)
	local mt = getmetatable(p)
	for k, f in meta do
		mt[k] = f
	end
	TYPE[p] = tname
	DATA[p] = data
	return p
end

-- A global library table (Vector3, CFrame, ...): unknown members error.
local function lib(name, t)
	return setmetatable(t, {
		__index = function(_, k)
			misuse(fmt("%s is not a valid member of %s", tostring(k), name), 2)
		end,
		__newindex = function(_, k)
			misuse(fmt("cannot assign %s.%s", name, tostring(k)), 2)
		end,
	})
end

local function needNum(v, what, level)
	if type(v) ~= "number" then
		misuse(fmt("%s: number expected, got %s", what, typeofm(v)), (level or 1) + 1)
	end
	return v
end

local function arith(op, a, b)
	misuse(fmt("attempt to perform arithmetic (%s) on %s and %s", op, typeofm(a), typeofm(b)), 3)
end

---------------------------------------------------------------------------------------------
-- datatypes
---------------------------------------------------------------------------------------------

local V3, V3m = {}, {}
local function v3(x, y, z)
	return proxy("Vector3", { X = x, Y = y, Z = z }, V3)
end
local function isV3(v)
	return TYPE[v] == "Vector3"
end
V3.__index = function(self, k)
	local d = DATA[self]
	if k == "X" or k == "Y" or k == "Z" then
		return d[k]
	elseif k == "Magnitude" then
		return math.sqrt(d.X * d.X + d.Y * d.Y + d.Z * d.Z)
	elseif k == "Unit" then
		local m = math.sqrt(d.X * d.X + d.Y * d.Y + d.Z * d.Z)
		return v3(d.X / m, d.Y / m, d.Z / m)
	end
	local f = V3m[k]
	if f then
		return f
	end
	misuse(fmt("%s is not a valid member of Vector3", tostring(k)), 2)
end
V3.__newindex = function(_, k)
	misuse(fmt("%s cannot be assigned to (Vector3 is immutable)", tostring(k)), 2)
end
V3.__add = function(a, b)
	if not (isV3(a) and isV3(b)) then
		arith("add", a, b)
	end
	local A, B = DATA[a], DATA[b]
	return v3(A.X + B.X, A.Y + B.Y, A.Z + B.Z)
end
V3.__sub = function(a, b)
	if not (isV3(a) and isV3(b)) then
		arith("sub", a, b)
	end
	local A, B = DATA[a], DATA[b]
	return v3(A.X - B.X, A.Y - B.Y, A.Z - B.Z)
end
V3.__mul = function(a, b)
	if type(a) == "number" and isV3(b) then
		local B = DATA[b]
		return v3(a * B.X, a * B.Y, a * B.Z)
	elseif isV3(a) and type(b) == "number" then
		local A = DATA[a]
		return v3(A.X * b, A.Y * b, A.Z * b)
	elseif isV3(a) and isV3(b) then
		local A, B = DATA[a], DATA[b]
		return v3(A.X * B.X, A.Y * B.Y, A.Z * B.Z)
	end
	arith("mul", a, b)
end
V3.__div = function(a, b)
	if isV3(a) and type(b) == "number" then
		local A = DATA[a]
		return v3(A.X / b, A.Y / b, A.Z / b)
	elseif isV3(a) and isV3(b) then
		local A, B = DATA[a], DATA[b]
		return v3(A.X / B.X, A.Y / B.Y, A.Z / B.Z)
	end
	arith("div", a, b)
end
V3.__unm = function(a)
	local A = DATA[a]
	return v3(-A.X, -A.Y, -A.Z)
end
V3.__eq = function(a, b)
	local A, B = DATA[a], DATA[b]
	return A.X == B.X and A.Y == B.Y and A.Z == B.Z
end
V3.__tostring = function(a)
	local A = DATA[a]
	return fmt("%g, %g, %g", A.X, A.Y, A.Z)
end
function V3m.Dot(a, b)
	local A, B = DATA[a], DATA[b]
	return A.X * B.X + A.Y * B.Y + A.Z * B.Z
end
function V3m.Cross(a, b)
	local A, B = DATA[a], DATA[b]
	return v3(A.Y * B.Z - A.Z * B.Y, A.Z * B.X - A.X * B.Z, A.X * B.Y - A.Y * B.X)
end
function V3m.Lerp(a, b, t)
	return a + (b - a) * t
end
function V3m.FuzzyEq(a, b, eps)
	return (a - b).Magnitude <= (eps or 1e-5)
end
function V3m.Abs(a)
	local A = DATA[a]
	return v3(math.abs(A.X), math.abs(A.Y), math.abs(A.Z))
end
function V3m.Floor(a)
	local A = DATA[a]
	return v3(math.floor(A.X), math.floor(A.Y), math.floor(A.Z))
end
function V3m.Min(a, b)
	local A, B = DATA[a], DATA[b]
	return v3(math.min(A.X, B.X), math.min(A.Y, B.Y), math.min(A.Z, B.Z))
end
function V3m.Max(a, b)
	local A, B = DATA[a], DATA[b]
	return v3(math.max(A.X, B.X), math.max(A.Y, B.Y), math.max(A.Z, B.Z))
end

local Vector3 = lib("Vector3", {
	new = function(x, y, z)
		if x ~= nil then needNum(x, "Vector3.new", 2) end
		if y ~= nil then needNum(y, "Vector3.new", 2) end
		if z ~= nil then needNum(z, "Vector3.new", 2) end
		return v3(x or 0, y or 0, z or 0)
	end,
	zero = v3(0, 0, 0),
	one = v3(1, 1, 1),
	xAxis = v3(1, 0, 0),
	yAxis = v3(0, 1, 0),
	zAxis = v3(0, 0, 1),
})

local V2 = {}
local function v2(x, y)
	return proxy("Vector2", { X = x, Y = y }, V2)
end
V2.__index = function(self, k)
	local d = DATA[self]
	if k == "X" or k == "Y" then
		return d[k]
	elseif k == "Magnitude" then
		return math.sqrt(d.X * d.X + d.Y * d.Y)
	end
	misuse(fmt("%s is not a valid member of Vector2", tostring(k)), 2)
end
V2.__newindex = function(_, k)
	misuse(fmt("%s cannot be assigned to (Vector2 is immutable)", tostring(k)), 2)
end
V2.__eq = function(a, b)
	return DATA[a].X == DATA[b].X and DATA[a].Y == DATA[b].Y
end
V2.__add = function(a, b)
	if TYPE[a] ~= "Vector2" or TYPE[b] ~= "Vector2" then
		arith("add", a, b)
	end
	return v2(DATA[a].X + DATA[b].X, DATA[a].Y + DATA[b].Y)
end
V2.__tostring = function(a)
	return fmt("%g, %g", DATA[a].X, DATA[a].Y)
end
local Vector2 = lib("Vector2", {
	new = function(x, y)
		return v2(x or 0, y or 0)
	end,
	zero = v2(0, 0),
	one = v2(1, 1),
})

-- CFrame: position + row-major 3x3 rotation
local CF, CFm = {}, {}
local function cf(x, y, z, a, b, c, d, e, f, g, h, i)
	return proxy("CFrame", { x, y, z, a, b, c, d, e, f, g, h, i }, CF)
end
local function isCF(v)
	return TYPE[v] == "CFrame"
end
local function cfMul(A, B)
	local x, y, z, a, b, c, d, e, f, g, h, i = table.unpack(A)
	local X, Y, Z, A2, B2, C2, D2, E2, F2, G2, H2, I2 = table.unpack(B)
	return cf(
		a * X + b * Y + c * Z + x,
		d * X + e * Y + f * Z + y,
		g * X + h * Y + i * Z + z,
		a * A2 + b * D2 + c * G2,
		a * B2 + b * E2 + c * H2,
		a * C2 + b * F2 + c * I2,
		d * A2 + e * D2 + f * G2,
		d * B2 + e * E2 + f * H2,
		d * C2 + e * F2 + f * I2,
		g * A2 + h * D2 + i * G2,
		g * B2 + h * E2 + i * H2,
		g * C2 + h * F2 + i * I2
	)
end
local function cfInv(A)
	local x, y, z, a, b, c, d, e, f, g, h, i = table.unpack(A)
	-- R^T, -R^T p
	return cf(-(a * x + d * y + g * z), -(b * x + e * y + h * z), -(c * x + f * y + i * z), a, d, g, b, e, h, c, f, i)
end
CF.__index = function(self, k)
	local D = DATA[self]
	if k == "Position" or k == "p" then
		return v3(D[1], D[2], D[3])
	elseif k == "X" then
		return D[1]
	elseif k == "Y" then
		return D[2]
	elseif k == "Z" then
		return D[3]
	elseif k == "LookVector" then
		return v3(-D[6], -D[9], -D[12])
	elseif k == "RightVector" or k == "XVector" then
		return v3(D[4], D[7], D[10])
	elseif k == "UpVector" or k == "YVector" then
		return v3(D[5], D[8], D[11])
	elseif k == "ZVector" then
		return v3(D[6], D[9], D[12])
	elseif k == "Rotation" then
		return cf(0, 0, 0, table.unpack(D, 4, 12))
	end
	local f = CFm[k]
	if f then
		return f
	end
	misuse(fmt("%s is not a valid member of CFrame", tostring(k)), 2)
end
CF.__newindex = function(_, k)
	misuse(fmt("%s cannot be assigned to (CFrame is immutable)", tostring(k)), 2)
end
CF.__mul = function(a, b)
	if isCF(a) and isCF(b) then
		return cfMul(DATA[a], DATA[b])
	elseif isCF(a) and isV3(b) then
		local x, y, z, A, B, C, D, E, F, G, H, I = table.unpack(DATA[a])
		local V = DATA[b]
		return v3(A * V.X + B * V.Y + C * V.Z + x, D * V.X + E * V.Y + F * V.Z + y, G * V.X + H * V.Y + I * V.Z + z)
	end
	arith("mul", a, b)
end
CF.__add = function(a, b)
	if isCF(a) and isV3(b) then
		local D, V = DATA[a], DATA[b]
		return cf(D[1] + V.X, D[2] + V.Y, D[3] + V.Z, table.unpack(D, 4, 12))
	end
	arith("add", a, b)
end
CF.__sub = function(a, b)
	if isCF(a) and isV3(b) then
		local D, V = DATA[a], DATA[b]
		return cf(D[1] - V.X, D[2] - V.Y, D[3] - V.Z, table.unpack(D, 4, 12))
	end
	arith("sub", a, b)
end
CF.__eq = function(a, b)
	local A, B = DATA[a], DATA[b]
	for k = 1, 12 do
		if A[k] ~= B[k] then
			return false
		end
	end
	return true
end
CF.__tostring = function(a)
	return table.concat(DATA[a], ", ")
end
function CFm.Inverse(a)
	return cfInv(DATA[a])
end
function CFm.ToWorldSpace(a, b)
	return cfMul(DATA[a], DATA[b])
end
function CFm.ToObjectSpace(a, b)
	return cfMul(DATA[cfInv(DATA[a])], DATA[b])
end
function CFm.PointToWorldSpace(a, v)
	return a * v
end
function CFm.PointToObjectSpace(a, v)
	return cfInv(DATA[a]) * v
end
function CFm.VectorToWorldSpace(a, v)
	return CF.__index(a, "Rotation") * v
end
function CFm.VectorToObjectSpace(a, v)
	return CF.__index(cfInv(DATA[a]), "Rotation") * v
end
function CFm.GetComponents(a)
	return table.unpack(DATA[a])
end
CFm.components = CFm.GetComponents
function CFm.Lerp(a, b, t)
	-- position lerp only; rotation snaps at t >= 0.5 (not modelled precisely)
	local A, B = DATA[a], DATA[b]
	local src = if t >= 0.5 then B else A
	return cf(A[1] + (B[1] - A[1]) * t, A[2] + (B[2] - A[2]) * t, A[3] + (B[3] - A[3]) * t, table.unpack(src, 4, 12))
end
function CFm.ToEulerAnglesXYZ(a)
	local D = DATA[a]
	local r02, r12, r22, r01, r00 = D[6], D[9], D[12], D[5], D[4]
	local ry = math.asin(math.clamp(r02, -1, 1))
	local rx = math.atan2(-r12, r22)
	local rz = math.atan2(-r01, r00)
	return rx, ry, rz
end
local function angles(rx, ry, rz)
	local cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
	-- Rx * Ry * Rz
	local Rx = { 0, 0, 0, 1, 0, 0, 0, cx, -sx, 0, sx, cx }
	local Ry = { 0, 0, 0, cy, 0, sy, 0, 1, 0, -sy, 0, cy }
	local Rz = { 0, 0, 0, cz, -sz, 0, sz, cz, 0, 0, 0, 1 }
	return cfMul(DATA[cfMul(Rx, Ry)], Rz)
end
local function lookAt(at, target, up)
	up = up or v3(0, 1, 0)
	local look = (target - at).Unit
	local right = look:Cross(up).Unit
	local upv = right:Cross(look)
	local P, R, U, L = DATA[at], DATA[right], DATA[upv], DATA[look]
	return cf(P.X, P.Y, P.Z, R.X, U.X, -L.X, R.Y, U.Y, -L.Y, R.Z, U.Z, -L.Z)
end
local CFrame = lib("CFrame", {
	new = function(...)
		local n = select("#", ...)
		local a, b, c = ...
		if n == 0 then
			return cf(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
		elseif n == 1 then
			if not isV3(a) then
				misuse("CFrame.new: Vector3 expected, got " .. typeofm(a), 2)
			end
			local P = DATA[a]
			return cf(P.X, P.Y, P.Z, 1, 0, 0, 0, 1, 0, 0, 0, 1)
		elseif n == 2 then
			if not (isV3(a) and isV3(b)) then
				misuse("CFrame.new(pos, lookAt): Vector3 expected", 2)
			end
			return lookAt(a, b)
		elseif n == 3 then
			needNum(a, "CFrame.new", 2)
			needNum(b, "CFrame.new", 2)
			needNum(c, "CFrame.new", 2)
			return cf(a, b, c, 1, 0, 0, 0, 1, 0, 0, 0, 1)
		elseif n == 12 then
			for k = 1, 12 do
				needNum((select(k, ...)), "CFrame.new", 2)
			end
			return cf(...)
		end
		misuse("CFrame.new: unsupported argument count " .. n, 2)
	end,
	Angles = function(rx, ry, rz)
		return angles(needNum(rx or 0, "CFrame.Angles", 2), needNum(ry or 0, "CFrame.Angles", 2), needNum(rz or 0, "CFrame.Angles", 2))
	end,
	fromEulerAnglesXYZ = function(rx, ry, rz)
		return angles(rx or 0, ry or 0, rz or 0)
	end,
	fromOrientation = function(rx, ry, rz)
		-- YXZ order
		local Y = DATA[angles(0, ry, 0)]
		local X = DATA[angles(rx, 0, 0)]
		local Z = DATA[angles(0, 0, rz)]
		return cfMul(DATA[cfMul(Y, X)], Z)
	end,
	lookAt = function(at, target, up)
		return lookAt(at, target, up)
	end,
	identity = cf(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
})

local C3, C3m = {}, {}
local function c3(r, g, b)
	return proxy("Color3", { R = r, G = g, B = b }, C3)
end
C3.__index = function(self, k)
	local d = DATA[self]
	if k == "R" or k == "G" or k == "B" then
		return d[k]
	end
	local f = C3m[k]
	if f then
		return f
	end
	misuse(fmt("%s is not a valid member of Color3", tostring(k)), 2)
end
C3.__newindex = function(_, k)
	misuse(fmt("%s cannot be assigned to (Color3 is immutable)", tostring(k)), 2)
end
C3.__eq = function(a, b)
	local A, B = DATA[a], DATA[b]
	return A.R == B.R and A.G == B.G and A.B == B.B
end
C3.__tostring = function(a)
	local A = DATA[a]
	return fmt("%g, %g, %g", A.R, A.G, A.B)
end
function C3m.Lerp(a, b, t)
	if TYPE[b] ~= "Color3" then
		misuse("Color3:Lerp expects a Color3", 2)
	end
	local A, B = DATA[a], DATA[b]
	needNum(t, "Color3:Lerp", 2)
	return c3(A.R + (B.R - A.R) * t, A.G + (B.G - A.G) * t, A.B + (B.B - A.B) * t)
end
function C3m.ToHex(a)
	local A = DATA[a]
	return fmt("%02X%02X%02X", math.floor(A.R * 255 + 0.5), math.floor(A.G * 255 + 0.5), math.floor(A.B * 255 + 0.5))
end
function C3m.ToHSV(a)
	local A = DATA[a]
	local r, g, b = A.R, A.G, A.B
	local mx, mn = math.max(r, g, b), math.min(r, g, b)
	local d = mx - mn
	local h = 0
	if d > 0 then
		if mx == r then
			h = ((g - b) / d) % 6
		elseif mx == g then
			h = (b - r) / d + 2
		else
			h = (r - g) / d + 4
		end
		h /= 6
	end
	return h, if mx == 0 then 0 else d / mx, mx
end
local Color3 = lib("Color3", {
	new = function(r, g, b)
		return c3(needNum(r or 0, "Color3.new", 2), needNum(g or 0, "Color3.new", 2), needNum(b or 0, "Color3.new", 2))
	end,
	fromRGB = function(r, g, b)
		return c3(needNum(r or 0, "Color3.fromRGB", 2) / 255, needNum(g or 0, "Color3.fromRGB", 2) / 255, needNum(b or 0, "Color3.fromRGB", 2) / 255)
	end,
	fromHex = function(s)
		if type(s) ~= "string" then
			misuse("Color3.fromHex: string expected, got " .. typeofm(s), 2)
		end
		local h = string.gsub(s, "^#", "")
		if #h == 3 then
			h = string.gsub(h, ".", "%0%0")
		end
		if #h ~= 6 or string.find(h, "[^%x]") then
			misuse("Color3.fromHex: Unable to convert characters to hex value: " .. s, 2)
		end
		return c3(tonumber(h:sub(1, 2), 16) / 255, tonumber(h:sub(3, 4), 16) / 255, tonumber(h:sub(5, 6), 16) / 255)
	end,
	fromHSV = function(h, s, v)
		local i = math.floor(h * 6)
		local f = h * 6 - i
		local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
		i %= 6
		if i == 0 then return c3(v, t, p) elseif i == 1 then return c3(q, v, p) elseif i == 2 then return c3(p, v, t)
		elseif i == 3 then return c3(p, q, v) elseif i == 4 then return c3(t, p, v) end
		return c3(v, p, q)
	end,
})

local UD = {}
local function udim(s, o)
	return proxy("UDim", { Scale = s, Offset = o }, UD)
end
UD.__index = function(self, k)
	local d = DATA[self]
	if k == "Scale" or k == "Offset" then
		return d[k]
	end
	misuse(fmt("%s is not a valid member of UDim", tostring(k)), 2)
end
UD.__newindex = function(_, k)
	misuse(fmt("%s cannot be assigned to (UDim is immutable)", tostring(k)), 2)
end
UD.__eq = function(a, b)
	return DATA[a].Scale == DATA[b].Scale and DATA[a].Offset == DATA[b].Offset
end
local UDim = lib("UDim", {
	new = function(s, o)
		return udim(needNum(s or 0, "UDim.new", 2), needNum(o or 0, "UDim.new", 2))
	end,
})
local UD2 = {}
local function udim2(xs, xo, ys, yo)
	return proxy("UDim2", { X = udim(xs, xo), Y = udim(ys, yo) }, UD2)
end
UD2.__index = function(self, k)
	local d = DATA[self]
	if k == "X" or k == "Width" then
		return d.X
	elseif k == "Y" or k == "Height" then
		return d.Y
	end
	misuse(fmt("%s is not a valid member of UDim2", tostring(k)), 2)
end
UD2.__newindex = function(_, k)
	misuse(fmt("%s cannot be assigned to (UDim2 is immutable)", tostring(k)), 2)
end
UD2.__eq = function(a, b)
	return DATA[a].X == DATA[b].X and DATA[a].Y == DATA[b].Y
end
local UDim2 = lib("UDim2", {
	new = function(a, b, c, d)
		if TYPE[a] == "UDim" and TYPE[b] == "UDim" then
			return udim2(a.Scale, a.Offset, b.Scale, b.Offset)
		end
		return udim2(needNum(a or 0, "UDim2.new", 2), needNum(b or 0, "UDim2.new", 2), needNum(c or 0, "UDim2.new", 2), needNum(d or 0, "UDim2.new", 2))
	end,
	fromScale = function(x, y)
		return udim2(needNum(x or 0, "UDim2.fromScale", 2), 0, needNum(y or 0, "UDim2.fromScale", 2), 0)
	end,
	fromOffset = function(x, y)
		return udim2(0, needNum(x or 0, "UDim2.fromOffset", 2), 0, needNum(y or 0, "UDim2.fromOffset", 2))
	end,
})

-- Enum ----------------------------------------------------------------------------------------
local ENUM_DEFS = {
	Material = { "Plastic", "SmoothPlastic", "Neon", "Wood", "WoodPlanks", "Marble", "Slate", "Concrete", "Granite", "Brick",
		"Pebble", "Cobblestone", "CorrodedMetal", "DiamondPlate", "Foil", "Metal", "Grass", "LeafyGrass", "Sand", "Fabric",
		"Ice", "Glass", "ForceField", "Rock", "Asphalt", "Basalt", "Ground", "Mud", "Snow", "Sandstone", "Limestone", "Pavement",
		"Salt", "CrackedLava", "Glacier", "Air", "Water", "Cardboard", "Carpet", "CeramicTiles", "ClayRoofTiles", "Leather",
		"Plaster", "Rubber", "RoofShingles" },
	SurfaceType = { "Smooth", "Glue", "Weld", "Studs", "Inlet", "Universal", "Hinge", "Motor", "SteppingMotor", "SmoothNoOutlines" },
	PartType = { "Ball", "Block", "Cylinder", "Wedge", "CornerWedge" },
	NormalId = { "Right", "Top", "Back", "Left", "Bottom", "Front" },
	SurfaceGuiSizingMode = { "FixedSize", "PixelsPerStud" },
	Font = { "Legacy", "Arial", "ArialBold", "SourceSans", "SourceSansBold", "SourceSansLight", "SourceSansItalic", "Bodoni",
		"Garamond", "Cartoon", "Code", "Highway", "SciFi", "Arcade", "Fantasy", "Antique", "SourceSansSemibold", "Gotham",
		"GothamMedium", "GothamBold", "GothamBlack", "AmaticSC", "Bangers", "Creepster", "DenkOne", "Fondamento", "FredokaOne",
		"GrenzeGotisch", "IndieFlower", "JosefinSans", "Jura", "Kalam", "LuckiestGuy", "Merriweather", "Michroma", "Nunito",
		"Oswald", "PatrickHand", "PermanentMarker", "Roboto", "RobotoCondensed", "RobotoMono", "Sarpanch", "SpecialElite",
		"TitilliumWeb", "Ubuntu", "BuilderSans", "BuilderSansMedium", "BuilderSansBold", "BuilderSansExtraBold", "Arimo", "ArimoBold", "Unknown" },
	ProductPurchaseDecision = { "NotProcessedYet", "PurchaseGranted" },
	HumanoidStateType = { "FallingDown", "Running", "RunningNoPhysics", "Climbing", "StrafingNoPhysics", "Ragdoll", "GettingUp",
		"Jumping", "Landed", "Flying", "Freefall", "Seated", "PlatformStanding", "Dead", "Swimming", "Physics", "None" },
	HumanoidRigType = { "R6", "R15" },
	AnalyticsCustomFieldKeys = { "CustomField01", "CustomField02", "CustomField03" },
	AnalyticsEconomyFlowType = { "Sink", "Source" },
	AnalyticsProgressionType = { "Custom", "Start", "Fail", "Complete" },
	TextXAlignment = { "Left", "Right", "Center" },
	TextYAlignment = { "Top", "Center", "Bottom" },
	ZIndexBehavior = { "Global", "Sibling" },
	Technology = { "Legacy", "Voxel", "Compatibility", "ShadowMap", "Future", "Unified" },
	SortOrder = { "Name", "Custom", "LayoutOrder" },
	FillDirection = { "Horizontal", "Vertical" },
	KeyCode = { "Unknown" },
}
local ENUM_ITEM, ENUM_TYPE = {}, {}
local enumTypes = {}
ENUM_ITEM.__index = function(self, k)
	local d = DATA[self]
	if k == "Name" or k == "Value" or k == "EnumType" then
		return d[k]
	elseif k == "IsA" then
		return function(_, n)
			return n == d.enumName
		end
	end
	misuse(fmt("%s is not a valid member of EnumItem %s", tostring(k), d.full), 2)
end
ENUM_ITEM.__newindex = function(_, k)
	misuse("EnumItem is read-only: " .. tostring(k), 2)
end
ENUM_ITEM.__tostring = function(self)
	return DATA[self].full
end
ENUM_TYPE.__index = function(self, k)
	local d = DATA[self]
	local it = d.items[k]
	if it then
		return it
	elseif k == "GetEnumItems" then
		return function()
			local out = {}
			for _, n in d.order do
				table.insert(out, d.items[n])
			end
			return out
		end
	elseif k == "FromName" then
		return function(_, n)
			return d.items[n]
		end
	elseif k == "FromValue" then
		return function(_, v)
			return d.byValue[v]
		end
	end
	misuse(fmt("%s is not a valid member of \"Enum.%s\"", tostring(k), d.name), 2)
end
ENUM_TYPE.__newindex = function(_, k)
	misuse("Enum is read-only: " .. tostring(k), 2)
end
ENUM_TYPE.__tostring = function(self)
	return DATA[self].name
end
for name, items in ENUM_DEFS do
	local et = proxy("Enum", { name = name, items = {}, order = items, byValue = {} }, ENUM_TYPE)
	local d = DATA[et]
	for i, itemName in items do
		local it = proxy("EnumItem", { Name = itemName, Value = i - 1, EnumType = et, enumName = name, full = "Enum." .. name .. "." .. itemName }, ENUM_ITEM)
		d.items[itemName] = it
		d.byValue[i - 1] = it
	end
	enumTypes[name] = et
end
local Enum = proxy("Enums", {}, {
	__index = function(_, k)
		local e = enumTypes[k]
		if e then
			return e
		end
		misuse(fmt("%s is not a valid member of \"Enum\" (or not modelled by the mock)", tostring(k)), 2)
	end,
	__newindex = function()
		misuse("Enum is read-only", 2)
	end,
})
M.Enum = Enum
local function isEnumOf(v, enumName)
	return TYPE[v] == "EnumItem" and DATA[v].enumName == enumName
end

-- Random: Park-Miller minimal standard generator (deterministic) ----------------------------------
local RND = {}
local seedCounter = 0
local function rndNext(d)
	d.s = (d.s * 48271) % 2147483647
	return d.s
end
local function rndUnit(d)
	-- 2 draws for ~53 bits
	local a = (rndNext(d) - 1) / 2147483646
	local b = (rndNext(d) - 1) / 2147483646
	return (math.floor(a * 2 ^ 26) + b) / 2 ^ 26
end
RND.__index = function(self, k)
	if k == "NextNumber" then
		return function(me, lo, hi)
			local d = DATA[me]
			lo, hi = lo or 0, hi or 1
			needNum(lo, "Random:NextNumber", 2)
			needNum(hi, "Random:NextNumber", 2)
			return lo + (hi - lo) * rndUnit(d)
		end
	elseif k == "NextInteger" then
		return function(me, lo, hi)
			local d = DATA[me]
			needNum(lo, "Random:NextInteger", 2)
			needNum(hi, "Random:NextInteger", 2)
			lo, hi = math.floor(lo), math.floor(hi)
			if lo > hi then
				misuse("invalid argument #2 to 'NextInteger' (interval is empty)", 2)
			end
			return lo + math.floor(rndUnit(d) * (hi - lo + 1))
		end
	elseif k == "Clone" then
		return function(me)
			return proxy("Random", { s = DATA[me].s }, RND)
		end
	end
	misuse(fmt("%s is not a valid member of Random", tostring(k)), 2)
end
RND.__newindex = function(_, k)
	misuse("Random is read-only: " .. tostring(k), 2)
end
local Random = lib("Random", {
	new = function(seed)
		if seed == nil then
			seedCounter += 1
			seed = 1234567 + seedCounter * 7919
		end
		needNum(seed, "Random.new", 2)
		return proxy("Random", { s = (math.floor(math.abs(seed)) % 2147483646) + 1 }, RND)
	end,
})

---------------------------------------------------------------------------------------------
-- serialization checks (remotes, DataStores)
---------------------------------------------------------------------------------------------

local IMMUTABLE_OK = { Vector3 = true, Vector2 = true, CFrame = true, Color3 = true, UDim = true, UDim2 = true, EnumItem = true }

-- Returns a deep copy of v as the receiver would see it; problems are appended to errs.
local function wireCopy(v, path, seen, errs, forStore)
	local t = type(v)
	if t == "nil" or t == "boolean" then
		return v
	elseif t == "number" then
		if forStore and (v ~= v or v == math.huge or v == -math.huge) then
			table.insert(errs, fmt("%s: NaN/inf cannot be stored", path))
		end
		return v
	elseif t == "string" then
		if forStore and utf8.len(v) == nil then
			table.insert(errs, fmt("%s: string is not valid UTF-8", path))
		end
		return v
	elseif t == "buffer" then
		local b = buffer.create(buffer.len(v))
		buffer.copy(b, 0, v)
		return b
	elseif t == "function" or t == "thread" then
		table.insert(errs, fmt("%s: a %s cannot be sent", path, t))
		return nil
	elseif t == "userdata" then
		local tn = TYPE[v]
		if forStore then
			table.insert(errs, fmt("%s: %s cannot be stored in a DataStore", path, tostring(tn or "userdata")))
			return nil
		end
		if tn == "Instance" or (tn and IMMUTABLE_OK[tn]) then
			return v
		end
		table.insert(errs, fmt("%s: %s cannot be sent", path, tostring(tn or "userdata")))
		return nil
	elseif t == "table" then
		if seen[v] then
			table.insert(errs, path .. ": cyclic table")
			return nil
		end
		seen[v] = true
		local nNum, nStr, maxN = 0, 0, 0
		for k in v do
			if type(k) == "number" and k >= 1 and k == math.floor(k) then
				nNum += 1
				if k > maxN then
					maxN = k
				end
			elseif type(k) == "string" then
				nStr += 1
			else
				table.insert(errs, fmt("%s: key %s of type %s (only string keys or a 1..n array survive)", path, tostring(k), typeofm(k)))
			end
		end
		if nNum > 0 and nStr > 0 then
			table.insert(errs, fmt("%s: mixed table (%d array keys, %d string keys)", path, nNum, nStr))
		end
		if nNum > 0 and maxN ~= nNum then
			table.insert(errs, fmt("%s: array with gaps (%d entries, max index %d)", path, nNum, maxN))
		end
		local out = {}
		for k, x in v do
			out[k] = wireCopy(x, path .. "." .. tostring(k), seen, errs, forStore)
		end
		seen[v] = nil
		return out
	end
	table.insert(errs, path .. ": unsupported type " .. t)
	return nil
end
M.wireCopy = wireCopy

local function deepCopy(v)
	if type(v) ~= "table" then
		if type(v) == "buffer" then
			local b = buffer.create(buffer.len(v))
			buffer.copy(b, 0, v)
			return b
		end
		return v
	end
	local out = {}
	for k, x in v do
		out[k] = deepCopy(x)
	end
	return out
end
M.deepCopy = deepCopy

---------------------------------------------------------------------------------------------
-- signals
---------------------------------------------------------------------------------------------

local SIG, CONN = {}, {}
local function newSignal(S, name)
	return proxy("RBXScriptSignal", { S = S, name = name, conns = {}, waiters = {} }, SIG)
end
local function sigConnect(self, fn, once)
	local d = DATA[self]
	if TYPE[self] ~= "RBXScriptSignal" then
		misuse("Expected ':' not '.' calling member function Connect", 3)
	end
	if type(fn) ~= "function" then
		misuse("Attempt to connect failed: Passed value is not a function", 3)
	end
	local c = proxy("RBXScriptConnection", { sig = d, fn = fn, connected = true, once = once }, CONN)
	table.insert(d.conns, c)
	return c
end
local function disconnect(c)
	local cd = DATA[c]
	if not cd.connected then
		return
	end
	cd.connected = false
	local list = cd.sig.conns
	local i = table.find(list, c)
	if i then
		table.remove(list, i)
	end
end
SIG.__index = function(self, k)
	if k == "Connect" then
		return function(me, fn)
			return sigConnect(me, fn, false)
		end
	elseif k == "Once" then
		return function(me, fn)
			return sigConnect(me, fn, true)
		end
	elseif k == "Wait" then
		return function(me)
			if not coroutine.isyieldable() then
				misuse("Signal:Wait() called from a non-yieldable context", 2)
			end
			table.insert(DATA[me].waiters, coroutine.running())
			return coroutine.yield()
		end
	end
	misuse(fmt("%s is not a valid member of RBXScriptSignal (%s)", tostring(k), DATA[self].name), 2)
end
SIG.__newindex = function(self, k)
	misuse(fmt("cannot assign %s on RBXScriptSignal %s", tostring(k), DATA[self].name), 2)
end
SIG.__tostring = function(self)
	return "Signal " .. DATA[self].name
end
CONN.__index = function(self, k)
	if k == "Disconnect" then
		return disconnect
	elseif k == "Connected" then
		return DATA[self].connected
	end
	misuse(fmt("%s is not a valid member of RBXScriptConnection", tostring(k)), 2)
end
CONN.__newindex = function(_, k)
	misuse("cannot assign " .. tostring(k) .. " on RBXScriptConnection", 2)
end

local function fire(sig, ...)
	local d = DATA[sig]
	local S = d.S
	if S.dead then
		return
	end
	if #d.conns > 0 then
		for _, c in table.clone(d.conns) do
			local cd = DATA[c]
			if cd.connected then
				if cd.once then
					disconnect(c)
				end
				S.spawn(cd.fn, ...)
			end
		end
	end
	if #d.waiters > 0 then
		local w = d.waiters
		d.waiters = {}
		for _, co in w do
			S.resume(co, ...)
		end
	end
end
M.fire = fire

---------------------------------------------------------------------------------------------
-- classes
---------------------------------------------------------------------------------------------

local Classes = {}
local function defclass(name, super, spec)
	spec.name = name
	spec.super = super
	spec.props = spec.props or {}
	spec.methods = spec.methods or {}
	spec.events = spec.events or {}
	spec.callbacks = spec.callbacks or {}
	Classes[name] = spec
end
local function P(t, default, extra)
	local p = extra or {}
	p.t = t
	p.d = default
	return p
end
local function RO(t, default)
	return { t = t, d = default, ro = true }
end

local GREY = c3(0.639, 0.635, 0.647)
local WHITE = c3(1, 1, 1)
local BLACK = c3(0, 0, 0)
local ID_CF = cf(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1)
local ZERO3 = v3(0, 0, 0)

-- forward
local Inst = {}

defclass("Instance", nil, {
	abstract = true,
	props = {
		Name = P("string", nil),
		Parent = { t = "Instance" }, -- handled specially
		ClassName = RO("string", nil),
		Archivable = P("boolean", true),
	},
	events = { "ChildAdded", "ChildRemoved", "DescendantAdded", "DescendantRemoving", "AncestryChanged", "Destroying", "Changed", "AttributeChanged" },
})
defclass("PVInstance", "Instance", { abstract = true })
defclass("BasePart", "PVInstance", {
	abstract = true,
	props = {
		Anchored = P("boolean", false),
		Size = P("Vector3", v3(4, 1, 2)),
		CFrame = P("CFrame", ID_CF),
		Position = P("Vector3", nil, { virtual = true }),
		Orientation = P("Vector3", nil, { virtual = true }),
		Color = P("Color3", GREY),
		Material = P("Enum.Material", Enum.Material.Plastic),
		Transparency = P("number", 0),
		Reflectance = P("number", 0),
		CanCollide = P("boolean", true),
		CanQuery = P("boolean", true),
		CanTouch = P("boolean", true),
		CastShadow = P("boolean", true),
		Massless = P("boolean", false),
		Locked = P("boolean", false),
		TopSurface = P("Enum.SurfaceType", Enum.SurfaceType.Smooth),
		BottomSurface = P("Enum.SurfaceType", Enum.SurfaceType.Smooth),
		FrontSurface = P("Enum.SurfaceType", Enum.SurfaceType.Smooth),
		BackSurface = P("Enum.SurfaceType", Enum.SurfaceType.Smooth),
		LeftSurface = P("Enum.SurfaceType", Enum.SurfaceType.Smooth),
		RightSurface = P("Enum.SurfaceType", Enum.SurfaceType.Smooth),
		AssemblyLinearVelocity = P("Vector3", ZERO3),
		AssemblyAngularVelocity = P("Vector3", ZERO3),
		CollisionGroup = P("string", "Default"),
	},
	events = { "Touched", "TouchEnded" },
})
defclass("Part", "BasePart", { props = { Shape = P("Enum.PartType", Enum.PartType.Block) } })
defclass("Model", "PVInstance", {
	props = { PrimaryPart = P("Instance:BasePart", nil), WorldPivot = P("CFrame", nil, { virtual = true }) },
})
defclass("Folder", "Instance", {})
defclass("Configuration", "Instance", {})
defclass("RemoteEvent", "Instance", { events = { "OnServerEvent", "OnClientEvent" } })
defclass("UnreliableRemoteEvent", "Instance", { events = { "OnServerEvent", "OnClientEvent" } })
defclass("RemoteFunction", "Instance", { callbacks = { OnServerInvoke = true, OnClientInvoke = true } })
defclass("BindableEvent", "Instance", { events = { "Event" } })
defclass("BindableFunction", "Instance", { callbacks = { OnInvoke = true } })
defclass("GuiBase2d", "Instance", { abstract = true })
defclass("GuiObject", "GuiBase2d", {
	abstract = true,
	props = {
		Size = P("UDim2", udim2(0, 100, 0, 100)),
		Position = P("UDim2", udim2(0, 0, 0, 0)),
		AnchorPoint = P("Vector2", v2(0, 0)),
		BackgroundColor3 = P("Color3", WHITE),
		BackgroundTransparency = P("number", 0),
		BorderColor3 = P("Color3", BLACK),
		BorderSizePixel = P("number", 1),
		Visible = P("boolean", true),
		ZIndex = P("number", 1),
		LayoutOrder = P("number", 0),
		Rotation = P("number", 0),
		ClipsDescendants = P("boolean", false),
	},
})
defclass("Frame", "GuiObject", {})
defclass("TextLabel", "GuiObject", {
	props = {
		Text = P("string", "Label"),
		TextColor3 = P("Color3", BLACK),
		TextTransparency = P("number", 0),
		TextStrokeTransparency = P("number", 1),
		TextStrokeColor3 = P("Color3", BLACK),
		TextScaled = P("boolean", false),
		TextSize = P("number", 14),
		TextWrapped = P("boolean", false),
		RichText = P("boolean", false),
		Font = P("Enum.Font", Enum.Font.Legacy),
		TextXAlignment = P("Enum.TextXAlignment", Enum.TextXAlignment.Center),
		TextYAlignment = P("Enum.TextYAlignment", Enum.TextYAlignment.Center),
	},
})
defclass("LayerCollector", "GuiBase2d", {
	abstract = true,
	props = { Enabled = P("boolean", true), ResetOnSpawn = P("boolean", true), ZIndexBehavior = P("Enum.ZIndexBehavior", Enum.ZIndexBehavior.Sibling) },
})
defclass("BillboardGui", "LayerCollector", {
	props = {
		Size = P("UDim2", udim2(0, 0, 0, 0)),
		StudsOffset = P("Vector3", ZERO3),
		StudsOffsetWorldSpace = P("Vector3", ZERO3),
		ExtentsOffset = P("Vector3", ZERO3),
		MaxDistance = P("number", math.huge),
		Adornee = P("Instance", nil),
		AlwaysOnTop = P("boolean", false),
		LightInfluence = P("number", 1),
	},
})
defclass("SurfaceGui", "LayerCollector", {
	props = {
		Face = P("Enum.NormalId", Enum.NormalId.Front),
		SizingMode = P("Enum.SurfaceGuiSizingMode", Enum.SurfaceGuiSizingMode.FixedSize),
		PixelsPerStud = P("number", 50),
		CanvasSize = P("Vector2", v2(800, 600)),
		Adornee = P("Instance", nil),
		AlwaysOnTop = P("boolean", false),
		LightInfluence = P("number", 1),
		Brightness = P("number", 1),
	},
})
defclass("Humanoid", "Instance", {
	props = {
		WalkSpeed = P("number", 16),
		JumpPower = P("number", 50),
		JumpHeight = P("number", 7.2),
		UseJumpPower = P("boolean", false),
		Health = P("number", 100),
		MaxHealth = P("number", 100),
		HipHeight = P("number", 2),
		AutoRotate = P("boolean", true),
		DisplayName = P("string", ""),
		RigType = P("Enum.HumanoidRigType", Enum.HumanoidRigType.R15),
		MoveDirection = RO("Vector3", ZERO3),
		PlatformStand = P("boolean", false),
		Sit = P("boolean", false),
		BreakJointsOnDeath = P("boolean", true),
		RequiresNeck = P("boolean", true),
	},
	events = { "Died", "HealthChanged", "StateChanged", "Running", "Jumping", "MoveToFinished" },
})
defclass("PostEffect", "Instance", { abstract = true, props = { Enabled = P("boolean", true) } })
defclass("BloomEffect", "PostEffect", { props = { Intensity = P("number", 0.4), Size = P("number", 24), Threshold = P("number", 0.95) } })
defclass("ColorCorrectionEffect", "PostEffect", {
	props = { Brightness = P("number", 0), Contrast = P("number", 0), Saturation = P("number", 0), TintColor = P("Color3", WHITE) },
})
defclass("SunRaysEffect", "PostEffect", { props = { Intensity = P("number", 0.25), Spread = P("number", 1) } })
defclass("Atmosphere", "Instance", {
	props = {
		Density = P("number", 0.395),
		Offset = P("number", 0),
		Color = P("Color3", c3(0.78, 0.78, 0.78)),
		Decay = P("Color3", c3(0.42, 0.44, 0.49)),
		Glare = P("number", 0),
		Haze = P("number", 0),
	},
})
defclass("LuaSourceContainer", "Instance", { abstract = true })
defclass("Script", "LuaSourceContainer", { props = { Disabled = P("boolean", false), Enabled = P("boolean", true) } })
defclass("ModuleScript", "LuaSourceContainer", {})
defclass("Player", "Instance", {
	notCreatable = true,
	props = {
		UserId = RO("number", 0),
		DisplayName = RO("string", ""),
		Character = P("Instance:Model", nil),
		AccountAge = RO("number", 100),
		CanLoadCharacterAppearance = P("boolean", true),
	},
	events = { "CharacterAdded", "CharacterRemoving", "CharacterAppearanceLoaded", "Chatted" },
})
-- services
defclass("DataModel", "Instance", {
	notCreatable = true,
	props = { JobId = RO("string", ""), PlaceId = RO("number", 0), GameId = RO("number", 0), PlaceVersion = RO("number", 0), CreatorId = RO("number", 0) },
})
local function service(name, spec)
	spec.service = true
	spec.notCreatable = true
	defclass(name, spec.super or "Instance", spec)
end
service("Workspace", {
	props = {
		Gravity = P("number", 196.2),
		FallenPartsDestroyHeight = P("number", -500),
		StreamingEnabled = RO("boolean", false),
		FilteringEnabled = RO("boolean", true),
		DistributedGameTime = RO("number", 0),
	},
})
service("Players", {
	props = { RespawnTime = P("number", 5), CharacterAutoLoads = P("boolean", true), MaxPlayers = RO("number", 16) },
	events = { "PlayerAdded", "PlayerRemoving" },
})
service("Lighting", {
	props = {
		ClockTime = P("number", 14),
		Brightness = P("number", 2),
		Ambient = P("Color3", BLACK),
		OutdoorAmbient = P("Color3", c3(0.5, 0.5, 0.5)),
		GlobalShadows = P("boolean", true),
		FogEnd = P("number", 100000),
		FogStart = P("number", 0),
		FogColor = P("Color3", c3(0.75, 0.75, 0.75)),
		ExposureCompensation = P("number", 0),
		EnvironmentDiffuseScale = P("number", 0),
		EnvironmentSpecularScale = P("number", 0),
		ShadowSoftness = P("number", 0.2),
		GeographicLatitude = P("number", 0),
		TimeOfDay = P("string", "14:00:00"),
		ColorShift_Top = P("Color3", BLACK),
		ColorShift_Bottom = P("Color3", BLACK),
		Technology = { t = "Enum.Technology", ro = true, roMsg = "The current thread cannot write 'Technology' (lacking capability Plugin)" },
	},
})
for _, n in { "ReplicatedStorage", "ServerScriptService", "ServerStorage", "StarterGui", "StarterPack", "StarterPlayer", "SoundService", "Teams" } do
	service(n, {})
end
defclass("StarterPlayerScripts", "Instance", { notCreatable = true })
defclass("StarterCharacterScripts", "Instance", { notCreatable = true })
service("RunService", { events = { "Heartbeat", "Stepped", "PostSimulation", "PreSimulation", "PreAnimation", "PreRender" } })
service("DataStoreService", {})
service("MarketplaceService", { callbacks = { ProcessReceipt = true }, events = { "PromptGamePassPurchaseFinished", "PromptProductPurchaseFinished", "PromptPurchaseFinished" } })
service("BadgeService", {})
service("AnalyticsService", {})
service("HttpService", { props = { HttpEnabled = RO("boolean", false) } })
defclass("GlobalDataStore", "Instance", { notCreatable = true })
defclass("DataStore", "GlobalDataStore", { notCreatable = true })
defclass("OrderedDataStore", "GlobalDataStore", { notCreatable = true })
defclass("DataStorePages", "Instance", { notCreatable = true, props = { IsFinished = RO("boolean", true) } })

---------------------------------------------------------------------------------------------
-- instance core
---------------------------------------------------------------------------------------------

local INST = {}

local function instData(self, member, level)
	local d = TYPE[self] == "Instance" and DATA[self]
	if not d then
		misuse(fmt("Expected ':' not '.' calling member function %s", member), (level or 1) + 1)
	end
	return d
end

local function fullName(self)
	local parts = {}
	local cur = self
	while cur ~= nil do
		local d = DATA[cur]
		if d.className == "DataModel" then
			break
		end
		table.insert(parts, 1, d.props.Name)
		cur = d.parent
	end
	return table.concat(parts, ".")
end
Inst.fullName = fullName

local function getSignal(d, name)
	local s = d.sigs[name]
	if s == nil then
		s = newSignal(d.S, d.className .. "." .. name)
		d.sigs[name] = s
	end
	return s
end
local function fireEv(d, name, ...)
	local s = d.sigs[name]
	if s ~= nil then
		fire(s, ...)
	end
end
Inst.fireEv = fireEv
Inst.getSignal = getSignal

local function findChild(d, name)
	for _, c in d.children do
		if DATA[c].props.Name == name then
			return c
		end
	end
	return nil
end

local function isDescendantOf(self, anc)
	local cur = DATA[self].parent
	while cur ~= nil do
		if cur == anc then
			return true
		end
		cur = DATA[cur].parent
	end
	return false
end

local function checkType(t, v, cls, prop, level)
	local function bad()
		misuse(fmt("Unable to assign property %s.%s. %s expected, got %s", cls, prop, t, typeofm(v)), level + 2)
	end
	if t == "any" then
		return v
	elseif t == "number" then
		if type(v) ~= "number" then
			bad()
		end
		return v
	elseif t == "boolean" then
		if type(v) ~= "boolean" then
			bad()
		end
		return v
	elseif t == "string" then
		if type(v) == "number" then
			return tostring(v)
		end
		if type(v) ~= "string" then
			bad()
		end
		return v
	elseif string.sub(t, 1, 8) == "Instance" then
		if v == nil then
			return nil
		end
		if TYPE[v] ~= "Instance" then
			bad()
		end
		local want = string.match(t, "^Instance:(%w+)$")
		if want and not DATA[v].cls.isa[want] then
			misuse(fmt("Unable to assign property %s.%s. %s expected, got %s", cls, prop, want, DATA[v].className), level + 1)
		end
		return v
	elseif string.sub(t, 1, 5) == "Enum." then
		local en = string.sub(t, 6)
		if isEnumOf(v, en) then
			return v
		end
		-- Roblox coerces enum names and values
		local et = DATA[enumTypes[en]]
		if type(v) == "string" and et.items[v] then
			return et.items[v]
		elseif type(v) == "number" and et.byValue[v] then
			return et.byValue[v]
		end
		bad()
	else
		if TYPE[v] ~= t then
			bad()
		end
		return v
	end
end

local function newInstance(S, className, internal)
	local cls = Classes[className]
	if cls == nil or cls.abstract or (not internal and cls.notCreatable) then
		misuse(fmt("Unable to create an Instance of type \"%s\"", tostring(className)), 3)
	end
	local props = {}
	for k, p in cls.allProps do
		if not p.virtual and k ~= "Parent" then
			props[k] = p.d
		end
	end
	props.Name = className
	props.ClassName = className
	local d = {
		S = S,
		cls = cls,
		className = className,
		props = props,
		children = {},
		parent = nil,
		attrs = {},
		sigs = {},
		propSigs = {},
		attrSigs = {},
		callbacks = {},
		waitFor = {},
		destroyed = false,
		parentLocked = false,
	}
	local p = newproxy(true)
	local mt = getmetatable(p)
	mt.__index = INST.__index
	mt.__newindex = INST.__newindex
	mt.__tostring = INST.__tostring
	TYPE[p] = "Instance"
	DATA[p] = d
	S.instanceCount += 1
	return p
end
Inst.new = newInstance

local function fireChanged(self, d, prop)
	fireEv(d, "Changed", prop)
	local s = d.propSigs[prop]
	if s then
		fire(s)
	end
end

local function resolveWaiters(parent, pd, child, name)
	local list = pd.waitFor[name]
	if list == nil or #list == 0 then
		return
	end
	pd.waitFor[name] = nil
	for _, e in list do
		if not e.done then
			e.done = true
			pd.S.childWaits[e] = nil
			pd.S.resume(e.co, child)
		end
	end
end

local function setParent(self, d, newParent, force)
	if newParent ~= nil and TYPE[newParent] ~= "Instance" then
		misuse(fmt("Unable to assign property %s.Parent. Instance expected, got %s", d.className, typeofm(newParent)), 4)
	end
	if d.parentLocked and not force then
		misuse(fmt("The Parent property of %s is locked, current parent: NULL, new parent %s", d.props.Name, tostring(newParent and DATA[newParent].props.Name)), 4)
	end
	if newParent == d.parent then
		return
	end
	if newParent ~= nil then
		local a = newParent
		while a ~= nil do
			if a == self then
				misuse(fmt("Attempt to set parent of %s to %s would result in circular reference", d.props.Name, DATA[newParent].props.Name), 4)
			end
			a = DATA[a].parent
		end
	end
	local old = d.parent
	if old ~= nil then
		local od = DATA[old]
		local i = table.find(od.children, self)
		if i then
			table.remove(od.children, i)
		end
	end
	d.parent = newParent
	if newParent ~= nil then
		table.insert(DATA[newParent].children, self)
	end
	if old ~= nil then
		fireEv(DATA[old], "ChildRemoved", self)
	end
	if newParent ~= nil then
		local nd = DATA[newParent]
		fireEv(nd, "ChildAdded", self)
		local a = newParent
		while a ~= nil do
			fireEv(DATA[a], "DescendantAdded", self)
			a = DATA[a].parent
		end
		resolveWaiters(newParent, nd, self, d.props.Name)
	end
	-- AncestryChanged on self and descendants
	local function anc(x)
		fireEv(DATA[x], "AncestryChanged", self, newParent)
		for _, c in DATA[x].children do
			anc(c)
		end
	end
	anc(self)
	fireChanged(self, d, "Parent")
end
Inst.setParent = setParent

-- Model pivot helpers
local function partsOf(self, out)
	for _, c in DATA[self].children do
		if DATA[c].cls.isa.BasePart then
			table.insert(out, c)
		end
		partsOf(c, out)
	end
	return out
end
local function getPivot(self, d)
	if d.cls.isa.BasePart then
		return d.props.CFrame
	end
	local pp = d.props.PrimaryPart
	if pp ~= nil and isDescendantOf(pp, self) then
		return DATA[pp].props.CFrame
	end
	if d.worldPivot then
		return d.worldPivot
	end
	local parts = partsOf(self, {})
	if #parts > 0 then
		return DATA[parts[1]].props.CFrame
	end
	return ID_CF
end
local function setPartCFrame(part, value)
	local pd = DATA[part]
	if pd.props.CFrame ~= value then
		pd.props.CFrame = value
		fireChanged(part, pd, "CFrame")
		fireChanged(part, pd, "Position")
	end
end
local function pivotTo(self, d, target)
	if TYPE[target] ~= "CFrame" then
		misuse("PivotTo: CFrame expected, got " .. typeofm(target), 3)
	end
	if d.cls.isa.BasePart then
		setPartCFrame(self, target)
		return
	end
	local offset = target * getPivot(self, d):Inverse()
	for _, part in partsOf(self, {}) do
		setPartCFrame(part, offset * DATA[part].props.CFrame)
	end
	if d.props.PrimaryPart == nil then
		d.worldPivot = target
	end
end
Inst.pivotTo = pivotTo

local function destroy(self, d)
	if d.destroyed then
		return
	end
	fireEv(d, "Destroying")
	for _, c in table.clone(d.children) do
		destroy(c, DATA[c])
	end
	if d.parent ~= nil then
		setParent(self, d, nil, true)
	end
	d.parentLocked = true
	d.destroyed = true
	for _, s in d.sigs do
		for _, c in table.clone(DATA[s].conns) do
			disconnect(c)
		end
	end
	for _, s in d.propSigs do
		for _, c in table.clone(DATA[s].conns) do
			disconnect(c)
		end
	end
end
Inst.destroy = destroy

local ATTR_OK = { boolean = true, number = true, string = true, UDim = true, UDim2 = true, Color3 = true, Vector2 = true, Vector3 = true, CFrame = true, EnumItem = true }

local BaseMethods = {}
function BaseMethods.Destroy(self)
	destroy(self, instData(self, "Destroy", 2))
end
function BaseMethods.ClearAllChildren(self)
	local d = instData(self, "ClearAllChildren", 2)
	for _, c in table.clone(d.children) do
		destroy(c, DATA[c])
	end
end
function BaseMethods.GetFullName(self)
	instData(self, "GetFullName", 2)
	return fullName(self)
end
function BaseMethods.FindFirstChild(self, name, recursive)
	local d = instData(self, "FindFirstChild", 2)
	if type(name) ~= "string" then
		misuse("FindFirstChild: Argument 1 missing or nil (string expected, got " .. typeofm(name) .. ")", 2)
	end
	local c = findChild(d, name)
	if c or not recursive then
		return c
	end
	for _, ch in d.children do
		local r = BaseMethods.FindFirstChild(ch, name, true)
		if r then
			return r
		end
	end
	return nil
end
function BaseMethods.FindFirstChildOfClass(self, cn)
	local d = instData(self, "FindFirstChildOfClass", 2)
	for _, c in d.children do
		if DATA[c].className == cn then
			return c
		end
	end
	return nil
end
function BaseMethods.FindFirstChildWhichIsA(self, cn, recursive)
	local d = instData(self, "FindFirstChildWhichIsA", 2)
	for _, c in d.children do
		if DATA[c].cls.isa[cn] then
			return c
		end
	end
	if recursive then
		for _, c in d.children do
			local r = BaseMethods.FindFirstChildWhichIsA(c, cn, true)
			if r then
				return r
			end
		end
	end
	return nil
end
function BaseMethods.FindFirstAncestor(self, name)
	local cur = instData(self, "FindFirstAncestor", 2).parent
	while cur do
		if DATA[cur].props.Name == name then
			return cur
		end
		cur = DATA[cur].parent
	end
	return nil
end
function BaseMethods.FindFirstAncestorOfClass(self, cn)
	local cur = instData(self, "FindFirstAncestorOfClass", 2).parent
	while cur do
		if DATA[cur].className == cn then
			return cur
		end
		cur = DATA[cur].parent
	end
	return nil
end
function BaseMethods.FindFirstAncestorWhichIsA(self, cn)
	local cur = instData(self, "FindFirstAncestorWhichIsA", 2).parent
	while cur do
		if DATA[cur].cls.isa[cn] then
			return cur
		end
		cur = DATA[cur].parent
	end
	return nil
end
function BaseMethods.WaitForChild(self, name, timeout)
	local d = instData(self, "WaitForChild", 2)
	if type(name) ~= "string" then
		misuse("WaitForChild: string expected, got " .. typeofm(name), 2)
	end
	if timeout ~= nil and type(timeout) ~= "number" then
		misuse("WaitForChild: timeout must be a number", 2)
	end
	local c = findChild(d, name)
	if c then
		return c
	end
	if not coroutine.isyieldable() then
		misuse("WaitForChild would yield from a non-yieldable context", 2)
	end
	local S = d.S
	local e = { co = coroutine.running(), name = name, parent = self, infinite = timeout == nil, since = M.clock, trace = debug.traceback("", 2) }
	d.waitFor[name] = d.waitFor[name] or {}
	table.insert(d.waitFor[name], e)
	S.childWaits[e] = true
	if timeout ~= nil then
		S.after(timeout, function()
			if not e.done then
				e.done = true
				S.childWaits[e] = nil
				local list = d.waitFor[name]
				if list then
					local i = table.find(list, e)
					if i then
						table.remove(list, i)
					end
				end
				S.resume(e.co, nil)
			end
		end)
	end
	return coroutine.yield()
end
function BaseMethods.GetChildren(self)
	return table.clone(instData(self, "GetChildren", 2).children)
end
function BaseMethods.GetDescendants(self)
	local out = {}
	local function walk(x)
		for _, c in DATA[x].children do
			table.insert(out, c)
			walk(c)
		end
	end
	instData(self, "GetDescendants", 2)
	walk(self)
	return out
end
function BaseMethods.IsA(self, cn)
	local d = instData(self, "IsA", 2)
	if type(cn) ~= "string" then
		misuse("IsA: string expected", 2)
	end
	return d.cls.isa[cn] == true
end
function BaseMethods.IsDescendantOf(self, anc)
	instData(self, "IsDescendantOf", 2)
	if anc == nil then
		return false
	end
	return isDescendantOf(self, anc)
end
function BaseMethods.IsAncestorOf(self, desc)
	instData(self, "IsAncestorOf", 2)
	return desc ~= nil and isDescendantOf(desc, self)
end
function BaseMethods.SetAttribute(self, name, value)
	local d = instData(self, "SetAttribute", 2)
	if type(name) ~= "string" or #name == 0 or #name > 100 or string.find(name, "[^%w_]") or string.sub(name, 1, 3) == "RBX" then
		misuse("SetAttribute: invalid attribute name " .. tostring(name), 2)
	end
	if value ~= nil and not ATTR_OK[typeofm(value)] then
		misuse(fmt("SetAttribute: %s is not a supported attribute type", typeofm(value)), 2)
	end
	if d.attrs[name] ~= value then
		d.attrs[name] = value
		fireEv(d, "AttributeChanged", name)
		local s = d.attrSigs[name]
		if s then
			fire(s)
		end
	end
end
function BaseMethods.GetAttribute(self, name)
	local d = instData(self, "GetAttribute", 2)
	if type(name) ~= "string" then
		misuse("GetAttribute: string expected", 2)
	end
	return d.attrs[name]
end
function BaseMethods.GetAttributes(self)
	return table.clone(instData(self, "GetAttributes", 2).attrs)
end
function BaseMethods.GetAttributeChangedSignal(self, name)
	local d = instData(self, "GetAttributeChangedSignal", 2)
	local s = d.attrSigs[name]
	if s == nil then
		s = newSignal(d.S, "AttributeChanged:" .. tostring(name))
		d.attrSigs[name] = s
	end
	return s
end
function BaseMethods.GetPropertyChangedSignal(self, prop)
	local d = instData(self, "GetPropertyChangedSignal", 2)
	if type(prop) ~= "string" or d.cls.allProps[prop] == nil then
		misuse(fmt("%s is not a valid property name of %s", tostring(prop), d.className), 2)
	end
	local s = d.propSigs[prop]
	if s == nil then
		s = newSignal(d.S, d.className .. ":GetPropertyChangedSignal(" .. prop .. ")")
		d.propSigs[prop] = s
	end
	return s
end
function BaseMethods.Clone(self)
	local d = instData(self, "Clone", 2)
	if not d.props.Archivable then
		return nil
	end
	local n = newInstance(d.S, d.className, true)
	local nd = DATA[n]
	for k, v in d.props do
		nd.props[k] = v
	end
	nd.attrs = table.clone(d.attrs)
	for _, c in d.children do
		local cc = BaseMethods.Clone(c)
		if cc then
			setParent(cc, DATA[cc], n)
		end
	end
	return n
end
Classes.Instance.methods = BaseMethods

Classes.PVInstance.methods = {
	GetPivot = function(self)
		return getPivot(self, instData(self, "GetPivot", 2))
	end,
	PivotTo = function(self, target)
		pivotTo(self, instData(self, "PivotTo", 2), target)
	end,
}
Classes.Model.methods = {
	MoveTo = function(self, pos)
		local d = instData(self, "MoveTo", 2)
		local p = getPivot(self, d)
		pivotTo(self, d, p.Rotation + pos)
	end,
}
Classes.BasePart.methods = {
	SetNetworkOwner = function(self, player)
		local d = instData(self, "SetNetworkOwner", 2)
		if player ~= nil and (TYPE[player] ~= "Instance" or DATA[player].className ~= "Player") then
			misuse("SetNetworkOwner: Player or nil expected", 2)
		end
		if d.props.Anchored then
			error("Network Ownership API cannot be called on Anchored parts or parts welded to Anchored parts.", 2)
		end
		if not isDescendantOf(self, d.S.workspace) then
			error("Can only call Network Ownership API on a part that is descendent of Workspace", 2)
		end
		d.networkOwner = player or "server"
	end,
	GetNetworkOwner = function(self)
		local d = instData(self, "GetNetworkOwner", 2)
		if d.networkOwner == "server" then
			return nil
		end
		return d.networkOwner
	end,
	SetNetworkOwnershipAuto = function(self)
		instData(self, "SetNetworkOwnershipAuto", 2).networkOwner = nil
	end,
	GetMass = function(self)
		local s = instData(self, "GetMass", 2).props.Size
		return s.X * s.Y * s.Z * 0.7
	end,
}
Classes.BasePart.props.Position.get = function(self, d)
	return d.props.CFrame.Position
end
Classes.BasePart.props.Position.set = function(self, d, v)
	setPartCFrame(self, d.props.CFrame.Rotation + v)
end
Classes.BasePart.props.Orientation.get = function(self, d)
	local rx, ry, rz = d.props.CFrame:ToEulerAnglesXYZ()
	return v3(math.deg(rx), math.deg(ry), math.deg(rz))
end
Classes.BasePart.props.Orientation.set = function(self, d, v)
	setPartCFrame(self, CFrame.new(d.props.CFrame.Position) * CFrame.fromOrientation(math.rad(v.X), math.rad(v.Y), math.rad(v.Z)))
end
Classes.BasePart.props.CFrame.set = function(self, d, v)
	setPartCFrame(self, v)
end
Classes.BasePart.props.Anchored.set = function(self, d, v)
	if d.props.Anchored ~= v then
		d.props.Anchored = v
		if v then
			d.networkOwner = "server"
		elseif d.networkOwner == "server" then
			d.networkOwner = nil -- automatic again
		end
		fireChanged(self, d, "Anchored")
	end
end
Classes.Model.props.WorldPivot.get = function(self, d)
	return getPivot(self, d)
end
Classes.Model.props.WorldPivot.set = function(self, d, v)
	d.worldPivot = v
end

Classes.Humanoid.props.Health.set = function(self, d, v)
	local old = d.props.Health
	v = math.clamp(v, 0, d.props.MaxHealth)
	d.props.Health = v
	if v ~= old then
		fireEv(d, "HealthChanged", v)
		fireChanged(self, d, "Health")
	end
	if v <= 0 and not d.dead then
		d.dead = true
		fireEv(d, "Died")
		d.S.onHumanoidDied(self)
	end
end
Classes.Humanoid.methods = {
	SetStateEnabled = function(self, state, enabled)
		local d = instData(self, "SetStateEnabled", 2)
		if not isEnumOf(state, "HumanoidStateType") then
			misuse("SetStateEnabled: Enum.HumanoidStateType expected, got " .. typeofm(state), 2)
		end
		if type(enabled) ~= "boolean" then
			misuse("SetStateEnabled: boolean expected", 2)
		end
		d.states = d.states or {}
		d.states[state] = enabled
	end,
	GetStateEnabled = function(self, state)
		local d = instData(self, "GetStateEnabled", 2)
		return d.states == nil or d.states[state] ~= false
	end,
	ChangeState = function(self, state)
		local d = instData(self, "ChangeState", 2)
		if not isEnumOf(state, "HumanoidStateType") then
			misuse("ChangeState: Enum.HumanoidStateType expected", 2)
		end
		d.state = state
		if state == Enum.HumanoidStateType.Dead then
			self.Health = 0
		end
	end,
	GetState = function(self)
		return instData(self, "GetState", 2).state or Enum.HumanoidStateType.Running
	end,
	TakeDamage = function(self, amount)
		local d = instData(self, "TakeDamage", 2)
		self.Health = d.props.Health - needNum(amount, "TakeDamage", 2)
	end,
	MoveTo = function(self, pos)
		local d = instData(self, "MoveTo", 2)
		if not isV3(pos) then
			misuse("MoveTo: Vector3 expected", 2)
		end
		d.moveTo = pos
	end,
}

-- remotes -----------------------------------------------------------------------------------
local function isPlayer(v)
	return TYPE[v] == "Instance" and DATA[v].className == "Player"
end
local function recordSend(S, remote, player, args, n)
	local errs = {}
	local copy = { n = n }
	for i = 1, n do
		copy[i] = wireCopy(args[i], fmt("%s arg#%d", DATA[remote].props.Name, i), {}, errs, false)
	end
	if #errs > 0 then
		misuse(fmt("%s:FireClient: argument cannot be serialized: %s", DATA[remote].props.Name, table.concat(errs, "; ")), 4)
	end
	if DATA[player].parent ~= S.players then
		return -- left the game: dropped
	end
	S.seq += 1
	local entry = { name = DATA[remote].props.Name, args = copy, t = M.clock, seq = S.seq }
	local uid = DATA[player].props.UserId
	S.sent[uid] = S.sent[uid] or {}
	table.insert(S.sent[uid], entry)
end
Classes.RemoteEvent.methods = {
	FireClient = function(self, player, ...)
		local d = instData(self, "FireClient", 2)
		if not isPlayer(player) then
			misuse("FireClient: player argument must be a Player object, got " .. typeofm(player), 2)
		end
		recordSend(d.S, self, player, { ... }, select("#", ...))
	end,
	FireAllClients = function(self, ...)
		local d = instData(self, "FireAllClients", 2)
		for _, p in DATA[d.S.players].children do
			if isPlayer(p) then
				recordSend(d.S, self, p, { ... }, select("#", ...))
			end
		end
	end,
	FireServer = function()
		misuse("FireServer can only be called from the client", 2)
	end,
}
Classes.UnreliableRemoteEvent.methods = Classes.RemoteEvent.methods
Classes.RemoteFunction.methods = {
	InvokeClient = function()
		misuse("InvokeClient is not modelled (and is unsafe on the server)", 2)
	end,
	InvokeServer = function()
		misuse("InvokeServer can only be called from the client", 2)
	end,
}
Classes.BindableEvent.methods = {
	Fire = function(self, ...)
		local d = instData(self, "Fire", 2)
		fire(getSignal(d, "Event"), ...)
	end,
}

-- players -----------------------------------------------------------------------------------
Classes.Player.methods = {
	Kick = function(self, msg)
		local d = instData(self, "Kick", 2)
		if msg ~= nil and type(msg) ~= "string" then
			misuse("Kick: string expected", 2)
		end
		d.S.kick(self, msg or "")
	end,
	IsInGroup = function(self, groupId)
		local d = instData(self, "IsInGroup", 2)
		needNum(groupId, "IsInGroup", 2)
		d.S.sleep(0.05)
		local g = M.groups[d.props.UserId]
		return g ~= nil and g[groupId] == true
	end,
	GetRankInGroup = function(self, groupId)
		local d = instData(self, "GetRankInGroup", 2)
		local g = M.groups[d.props.UserId]
		return if g ~= nil and g[groupId] then 1 else 0
	end,
	LoadCharacter = function(self)
		local d = instData(self, "LoadCharacter", 2)
		if d.parent ~= d.S.players then
			error("LoadCharacter can only be called when Player is in the world", 2)
		end
		d.S.loadCharacter(self)
	end,
	GetNetworkPing = function()
		return 0.05
	end,
}
Classes.Players.methods = {
	GetPlayers = function(self)
		local d = instData(self, "GetPlayers", 2)
		local out = {}
		for _, c in d.children do
			if isPlayer(c) then
				table.insert(out, c)
			end
		end
		return out
	end,
	GetPlayerByUserId = function(self, uid)
		local d = instData(self, "GetPlayerByUserId", 2)
		needNum(uid, "GetPlayerByUserId", 2)
		for _, c in d.children do
			if isPlayer(c) and DATA[c].props.UserId == uid then
				return c
			end
		end
		return nil
	end,
	GetPlayerFromCharacter = function(self, char)
		local d = instData(self, "GetPlayerFromCharacter", 2)
		for _, c in d.children do
			if isPlayer(c) and char ~= nil and DATA[c].props.Character == char then
				return c
			end
		end
		return nil
	end,
}

-- game / workspace / run service ----------------------------------------------------------
Classes.DataModel.methods = {
	GetService = function(self, name)
		local d = instData(self, "GetService", 2)
		return d.S.getService(name, 2)
	end,
	FindService = function(self, name)
		local d = instData(self, "FindService", 2)
		return d.S.services[name]
	end,
	BindToClose = function(self, fn)
		local d = instData(self, "BindToClose", 2)
		if type(fn) ~= "function" then
			misuse("BindToClose: function expected", 2)
		end
		table.insert(d.S.closeHandlers, fn)
	end,
	IsLoaded = function()
		return true
	end,
}
Classes.Workspace.methods = {
	GetServerTimeNow = function(self)
		instData(self, "GetServerTimeNow", 2)
		return M.TIME0 + M.clock
	end,
	Raycast = function()
		error("workspace:Raycast is not modelled by the headless mock (no physics)", 2)
	end,
}
Classes.RunService.methods = {
	IsStudio = function(self)
		return instData(self, "IsStudio", 2).S.opts.isStudio ~= false
	end,
	IsServer = function()
		return true
	end,
	IsClient = function()
		return false
	end,
	IsRunning = function()
		return true
	end,
	IsEdit = function()
		return false
	end,
	IsRunMode = function()
		return false
	end,
	BindToRenderStep = function()
		misuse("BindToRenderStep can only be used on the client", 2)
	end,
}

-- DataStores ----------------------------------------------------------------------------------
local function dsCheck(S, what, level)
	S.sleep(M.dsLatency)
	if M.dsDown then
		error("502: API Services rejected request with error. HTTP 403 (Forbidden) [Studio access to API services is not enabled]", level + 1)
	end
end
local function dsKey(key, level)
	if type(key) ~= "string" or #key == 0 or #key > 50 then
		misuse("DataStore key must be a non-empty string of at most 50 characters, got " .. tostring(key), level + 1)
	end
end
local function dsStoreValue(value, level)
	local errs = {}
	local copy = wireCopy(value, "value", {}, errs, true)
	if #errs > 0 then
		misuse("104: Cannot store value in data store: " .. table.concat(errs, "; "), level + 1)
	end
	return copy
end
local function storeTable(d)
	local backing = if d.className == "OrderedDataStore" then M.dsBacking.ordered else M.dsBacking.stores
	local t = backing[d.storeName]
	if t == nil then
		t = {}
		backing[d.storeName] = t
	end
	return t
end
local dsMethods = {
	GetAsync = function(self, key)
		local d = instData(self, "GetAsync", 2)
		dsKey(key, 2)
		dsCheck(d.S, "GetAsync", 2)
		return deepCopy(storeTable(d)[key]), nil
	end,
	SetAsync = function(self, key, value)
		local d = instData(self, "SetAsync", 2)
		dsKey(key, 2)
		local copy = dsStoreValue(value, 2)
		if d.className == "OrderedDataStore" and (type(value) ~= "number" or value ~= math.floor(value)) then
			misuse("OrderedDataStore:SetAsync value must be an integer, got " .. tostring(value), 2)
		end
		dsCheck(d.S, "SetAsync", 2)
		storeTable(d)[key] = copy
		M.dsWrites = (M.dsWrites or 0) + 1
	end,
	RemoveAsync = function(self, key)
		local d = instData(self, "RemoveAsync", 2)
		dsKey(key, 2)
		dsCheck(d.S, "RemoveAsync", 2)
		local t = storeTable(d)
		local old = t[key]
		t[key] = nil
		return deepCopy(old)
	end,
	IncrementAsync = function(self, key, delta)
		local d = instData(self, "IncrementAsync", 2)
		dsKey(key, 2)
		dsCheck(d.S, "IncrementAsync", 2)
		local t = storeTable(d)
		t[key] = (t[key] or 0) + math.floor(delta or 1)
		return t[key]
	end,
	UpdateAsync = function(self, key, transform)
		local d = instData(self, "UpdateAsync", 2)
		dsKey(key, 2)
		if type(transform) ~= "function" then
			misuse("UpdateAsync: transform function expected", 2)
		end
		dsCheck(d.S, "UpdateAsync", 2)
		local t = storeTable(d)
		local co = coroutine.create(transform)
		local ok, res = coroutine.resume(co, deepCopy(t[key]), nil)
		if coroutine.status(co) ~= "dead" then
			misuse("UpdateAsync: the transform function yielded (it must not)", 2)
		end
		if not ok then
			error(res, 2)
		end
		if res == nil then
			return nil
		end
		local copy = dsStoreValue(res, 2)
		t[key] = copy
		M.dsWrites = (M.dsWrites or 0) + 1
		return deepCopy(copy), nil
	end,
}
Classes.GlobalDataStore.methods = dsMethods
Classes.OrderedDataStore.methods = {
	GetSortedAsync = function(self, ascending, pageSize, minValue, maxValue)
		local d = instData(self, "GetSortedAsync", 2)
		if type(ascending) ~= "boolean" then
			misuse("GetSortedAsync: ascending must be a boolean", 2)
		end
		if type(pageSize) ~= "number" or pageSize < 1 or pageSize > 100 or pageSize ~= math.floor(pageSize) then
			misuse("GetSortedAsync: pageSize must be an integer in 1..100", 2)
		end
		dsCheck(d.S, "GetSortedAsync", 2)
		local rows = {}
		for k, v in storeTable(d) do
			if (minValue == nil or v >= minValue) and (maxValue == nil or v <= maxValue) then
				table.insert(rows, { key = k, value = v })
			end
		end
		table.sort(rows, function(a, b)
			if a.value ~= b.value then
				return if ascending then a.value < b.value else a.value > b.value
			end
			return a.key < b.key
		end)
		local page = {}
		for i = 1, math.min(pageSize, #rows) do
			page[i] = rows[i]
		end
		local pages = newInstance(d.S, "DataStorePages", true)
		DATA[pages].page = page
		return pages
	end,
}
Classes.DataStorePages.methods = {
	GetCurrentPage = function(self)
		return deepCopy(instData(self, "GetCurrentPage", 2).page)
	end,
	AdvanceToNextPageAsync = function(self)
		instData(self, "AdvanceToNextPageAsync", 2).page = {}
	end,
}
Classes.DataStoreService.methods = {
	GetDataStore = function(self, name, scope)
		local d = instData(self, "GetDataStore", 2)
		if type(name) ~= "string" or #name == 0 or #name > 50 then
			misuse("GetDataStore: name must be a non-empty string of at most 50 characters", 2)
		end
		if M.dsDown == "all" then
			error("You must publish this place to the web to access DataStore.", 2)
		end
		local full = name .. "/" .. tostring(scope or "global")
		d.cache = d.cache or {}
		local ds = d.cache[full]
		if ds == nil then
			ds = newInstance(d.S, "DataStore", true)
			DATA[ds].props.Name = name
			DATA[ds].storeName = full
			d.cache[full] = ds
		end
		return ds
	end,
	GetOrderedDataStore = function(self, name, scope)
		local d = instData(self, "GetOrderedDataStore", 2)
		if type(name) ~= "string" or #name == 0 or #name > 50 then
			misuse("GetOrderedDataStore: name must be a non-empty string of at most 50 characters", 2)
		end
		if M.dsDown == "all" then
			error("You must publish this place to the web to access DataStore.", 2)
		end
		local full = "ordered:" .. name .. "/" .. tostring(scope or "global")
		d.cache = d.cache or {}
		local ds = d.cache[full]
		if ds == nil then
			ds = newInstance(d.S, "OrderedDataStore", true)
			DATA[ds].props.Name = name
			DATA[ds].storeName = full
			d.cache[full] = ds
		end
		return ds
	end,
	GetGlobalDataStore = function(self)
		return Classes.DataStoreService.methods.GetDataStore(self, "__global")
	end,
}

-- marketplace / badges / analytics ----------------------------------------------------------------
Classes.MarketplaceService.methods = {
	UserOwnsGamePassAsync = function(self, userId, passId)
		local d = instData(self, "UserOwnsGamePassAsync", 2)
		needNum(userId, "UserOwnsGamePassAsync userId", 2)
		needNum(passId, "UserOwnsGamePassAsync gamePassId", 2)
		if passId <= 0 then
			error("UserOwnsGamePassAsync: invalid game pass id " .. passId, 2)
		end
		d.S.sleep(0.05)
		local owned = M.passes[userId]
		return owned ~= nil and owned[passId] == true
	end,
	PromptGamePassPurchase = function(self, player, passId)
		local d = instData(self, "PromptGamePassPurchase", 2)
		if not isPlayer(player) then
			misuse("PromptGamePassPurchase: Player expected", 2)
		end
		table.insert(d.S.prompts, { kind = "pass", player = player, id = passId })
	end,
	PromptProductPurchase = function(self, player, productId)
		local d = instData(self, "PromptProductPurchase", 2)
		if not isPlayer(player) then
			misuse("PromptProductPurchase: Player expected", 2)
		end
		table.insert(d.S.prompts, { kind = "product", player = player, id = productId })
	end,
	GetProductInfo = function(self, id)
		instData(self, "GetProductInfo", 2)
		return { Name = "Product " .. tostring(id), PriceInRobux = 0 }
	end,
}
Classes.BadgeService.methods = {
	AwardBadge = function(self, userId, badgeId)
		local d = instData(self, "AwardBadge", 2)
		needNum(userId, "AwardBadge userId", 2)
		needNum(badgeId, "AwardBadge badgeId", 2)
		d.S.sleep(0.05)
		if badgeId <= 0 then
			error("AwardBadge: badge " .. badgeId .. " does not exist", 2)
		end
		table.insert(M.badges, { userId = userId, badgeId = badgeId })
		return true
	end,
	UserHasBadgeAsync = function(self, userId, badgeId)
		instData(self, "UserHasBadgeAsync", 2)
		for _, b in M.badges do
			if b.userId == userId and b.badgeId == badgeId then
				return true
			end
		end
		return false
	end,
}
local CUSTOM_FIELD_OK = { CustomField01 = true, CustomField02 = true, CustomField03 = true }
local function checkCustomFields(fields, level)
	if fields == nil then
		return
	end
	if type(fields) ~= "table" then
		misuse("Analytics customFields must be a dictionary", level + 1)
	end
	for k, v in fields do
		if not CUSTOM_FIELD_OK[k] then
			misuse("Analytics customFields key must be an Enum.AnalyticsCustomFieldKeys name (CustomField01..03), got " .. tostring(k), level + 1)
		end
		if type(v) ~= "string" then
			misuse("Analytics customFields values must be strings, got " .. typeofm(v), level + 1)
		end
	end
end
Classes.AnalyticsService.methods = {
	LogCustomEvent = function(self, player, eventName, value, fields)
		local d = instData(self, "LogCustomEvent", 2)
		if not isPlayer(player) then
			misuse("LogCustomEvent: Player expected, got " .. typeofm(player), 2)
		end
		if type(eventName) ~= "string" or #eventName == 0 or #eventName > 50 then
			misuse("LogCustomEvent: eventName must be a non-empty string (<= 50 chars), got " .. tostring(eventName), 2)
		end
		if value ~= nil and type(value) ~= "number" then
			misuse("LogCustomEvent: value must be a number", 2)
		end
		checkCustomFields(fields, 2)
		table.insert(d.S.analytics, { kind = "custom", userId = DATA[player].props.UserId, event = eventName, value = value or 1, fields = fields and table.clone(fields) })
	end,
	LogOnboardingFunnelStepEvent = function(self, player, step, stepName, fields)
		local d = instData(self, "LogOnboardingFunnelStepEvent", 2)
		if not isPlayer(player) then
			misuse("LogOnboardingFunnelStepEvent: Player expected", 2)
		end
		if type(step) ~= "number" or step < 1 or step ~= math.floor(step) then
			misuse("LogOnboardingFunnelStepEvent: step must be a positive integer", 2)
		end
		if stepName ~= nil and type(stepName) ~= "string" then
			misuse("LogOnboardingFunnelStepEvent: stepName must be a string", 2)
		end
		checkCustomFields(fields, 2)
		table.insert(d.S.analytics, { kind = "funnel", userId = DATA[player].props.UserId, step = step, name = stepName })
	end,
	LogEconomyEvent = function(self, player, flowType, currency, amount, endingBalance, transactionType, itemSku, fields)
		local d = instData(self, "LogEconomyEvent", 2)
		if not isPlayer(player) or not isEnumOf(flowType, "AnalyticsEconomyFlowType") or type(currency) ~= "string" or type(amount) ~= "number" or type(endingBalance) ~= "number" or type(transactionType) ~= "string" then
			misuse("LogEconomyEvent: bad arguments", 2)
		end
		checkCustomFields(fields, 2)
		table.insert(d.S.analytics, { kind = "economy", userId = DATA[player].props.UserId })
	end,
}

-- flatten class chains
for _, c in Classes do
	local chain = {}
	local cur = c
	while cur do
		table.insert(chain, 1, cur)
		cur = cur.super and Classes[cur.super]
	end
	c.allProps, c.allMethods, c.allEvents, c.allCallbacks, c.isa = {}, {}, {}, {}, {}
	for _, k in chain do
		c.isa[k.name] = true
		for n, p in k.props do
			c.allProps[n] = p
		end
		for n, f in k.methods do
			c.allMethods[n] = f
		end
		for _, n in k.events do
			c.allEvents[n] = true
		end
		for n in k.callbacks do
			c.allCallbacks[n] = true
		end
	end
end
M.Classes = Classes

INST.__index = function(self, k)
	local d = DATA[self]
	local cls = d.cls
	local p = cls.allProps[k]
	if p ~= nil then
		if k == "Parent" then
			return d.parent
		end
		if p.get then
			return p.get(self, d)
		end
		if p.wo then
			misuse(fmt("%s.%s cannot be read", d.className, k), 2)
		end
		return d.props[k]
	end
	local m = cls.allMethods[k]
	if m ~= nil then
		return m
	end
	if cls.allEvents[k] then
		return getSignal(d, k)
	end
	if cls.allCallbacks[k] then
		misuse(fmt("%s is a callback member of %s; you can only set the callback value, get is not available", k, d.className), 2)
	end
	if type(k) == "string" then
		local c = findChild(d, k)
		if c ~= nil then
			return c
		end
	end
	misuse(fmt("%s is not a valid member of %s \"%s\"", tostring(k), d.className, fullName(self)), 2)
end
INST.__newindex = function(self, k, v)
	local d = DATA[self]
	local cls = d.cls
	local p = cls.allProps[k]
	if p ~= nil then
		if k == "Parent" then
			setParent(self, d, v)
			return
		end
		if p.ro then
			misuse(p.roMsg or fmt("Unable to assign property %s. Property is read only (%s)", k, d.className), 2)
		end
		v = checkType(p.t, v, d.className, k, 1)
		if k == "Name" and d.destroyed == false and d.parent ~= nil and d.props.Name ~= v then
			d.props.Name = v
			resolveWaiters(d.parent, DATA[d.parent], self, v)
			fireChanged(self, d, k)
			return
		end
		if p.set then
			p.set(self, d, v)
			return
		end
		if d.props[k] ~= v then
			d.props[k] = v
			fireChanged(self, d, k)
		end
		return
	end
	if cls.allCallbacks[k] then
		if v ~= nil and type(v) ~= "function" then
			misuse(fmt("%s.%s must be a function or nil", d.className, k), 2)
		end
		d.callbacks[k] = v
		return
	end
	if cls.allMethods[k] or cls.allEvents[k] then
		misuse(fmt("%s is a method/event of %s and cannot be assigned", tostring(k), d.className), 2)
	end
	misuse(fmt("%s is not a valid member of %s \"%s\"", tostring(k), d.className, fullName(self)), 2)
end
INST.__tostring = function(self)
	return DATA[self].props.Name
end

---------------------------------------------------------------------------------------------
-- server (scheduler, world, players, harness hooks)
---------------------------------------------------------------------------------------------

local FRAME = 1 / 60

function M.newServer(opts)
	opts = opts or {}
	local S = {
		opts = opts,
		dead = false,
		frameNo = 0,
		waiting = {},
		deferred = {},
		waitIndex = {},
		wseq = 0,
		seq = 0,
		errors = {},
		misuse = {},
		warns = {},
		prints = {},
		sent = {},
		kicks = {},
		analytics = {},
		prompts = {},
		closeHandlers = {},
		childWaits = {},
		reportedWaits = {},
		services = {},
		walkers = {},
		instanceCount = 0,
		modules = {}, -- path -> { inst, fn, kind }
		moduleCache = {},
		moduleLoading = {},
		heartbeatReal = 0,
		heartbeatFrames = 0,
		frameHooks = {},
	}
	M.current = S

	-- scheduler -----------------------------------------------------------------------------
	function S.threadError(co, err)
		local msg = debug.traceback(co, tostring(err))
		table.insert(S.errors, msg)
		if M.verbose then
			rawprint("[thread error] " .. msg)
		end
	end
	function S.resume(co, ...)
		if S.dead or coroutine.status(co) ~= "suspended" then
			return
		end
		local ok, err = coroutine.resume(co, ...)
		if not ok then
			S.threadError(co, err)
		end
	end
	function S.spawn(fn, ...)
		local co = if type(fn) == "thread" then fn else coroutine.create(fn)
		S.resume(co, ...)
		return co
	end
	local function enqueue(entry)
		S.wseq += 1
		entry.seq = S.wseq
		entry.frame = S.frameNo
		table.insert(S.waiting, entry)
		if entry.co then
			S.waitIndex[entry.co] = entry
		end
		return entry
	end
	function S.sleep(t)
		if not coroutine.isyieldable() then
			misuse("task.wait/yielding call from a non-yieldable context (e.g. inside a metamethod or the harness main thread)", 3)
		end
		local co = coroutine.running()
		enqueue({ co = co, at = M.clock + math.max(t or 0, 0), start = M.clock })
		return coroutine.yield()
	end
	function S.after(t, fn)
		return enqueue({ fn = fn, at = M.clock + math.max(t or 0, 0) })
	end
	local function cancel(co)
		local e = S.waitIndex[co]
		if e then
			e.cancelled = true
			S.waitIndex[co] = nil
		end
		for _, x in S.deferred do
			if x.co == co then
				x.cancelled = true
			end
		end
		if coroutine.status(co) == "suspended" then
			coroutine.close(co)
		end
	end
	function S.runDeferred()
		local guard = 0
		while #S.deferred > 0 do
			guard += 1
			if guard > 1000 then
				misuse("task.defer re-entrancy limit exceeded", 2)
			end
			local list = S.deferred
			S.deferred = {}
			for _, x in list do
				if not x.cancelled then
					S.resume(x.co, table.unpack(x.args, 1, x.args.n))
				end
			end
		end
	end

	local task = lib("task", {
		wait = function(t)
			if t ~= nil and type(t) ~= "number" then
				misuse("task.wait: number expected", 2)
			end
			return S.sleep(t)
		end,
		spawn = function(fn, ...)
			if type(fn) ~= "function" and type(fn) ~= "thread" then
				misuse("task.spawn: function or thread expected, got " .. typeofm(fn), 2)
			end
			return S.spawn(fn, ...)
		end,
		defer = function(fn, ...)
			if type(fn) ~= "function" and type(fn) ~= "thread" then
				misuse("task.defer: function or thread expected", 2)
			end
			local co = if type(fn) == "thread" then fn else coroutine.create(fn)
			table.insert(S.deferred, { co = co, args = table.pack(...) })
			return co
		end,
		delay = function(t, fn, ...)
			if type(t) ~= "number" then
				misuse("task.delay: number expected", 2)
			end
			if type(fn) ~= "function" and type(fn) ~= "thread" then
				misuse("task.delay: function or thread expected", 2)
			end
			local co = if type(fn) == "thread" then fn else coroutine.create(fn)
			enqueue({ co = co, at = M.clock + math.max(t, 0), args = table.pack(...) })
			return co
		end,
		cancel = function(co)
			if type(co) ~= "thread" then
				misuse("task.cancel: thread expected", 2)
			end
			cancel(co)
		end,
		synchronize = function() end,
		desynchronize = function() end,
	})
	S.task = task

	-- world -----------------------------------------------------------------------------------
	local game = newInstance(S, "DataModel", true)
	DATA[game].props.Name = "Game"
	DATA[game].props.JobId = opts.jobId or ""
	DATA[game].props.PlaceId = opts.placeId or 0
	S.game = game
	local function mkService(name)
		local s = newInstance(S, name, true)
		DATA[s].props.Name = name
		setParent(s, DATA[s], game)
		DATA[s].parentLocked = true
		S.services[name] = s
		return s
	end
	for _, n in { "Workspace", "Lighting", "ReplicatedStorage", "ServerScriptService", "ServerStorage", "StarterGui", "StarterPack",
		"StarterPlayer", "SoundService", "Players", "RunService" } do
		mkService(n)
	end
	S.workspace = S.services.Workspace
	S.players = S.services.Players
	S.runService = S.services.RunService
	local sp = S.services.StarterPlayer
	local sps = newInstance(S, "StarterPlayerScripts", true)
	DATA[sps].props.Name = "StarterPlayerScripts"
	setParent(sps, DATA[sps], sp)
	local scs = newInstance(S, "StarterCharacterScripts", true)
	DATA[scs].props.Name = "StarterCharacterScripts"
	setParent(scs, DATA[scs], sp)

	function S.getService(name, level)
		if type(name) ~= "string" then
			misuse("GetService: string expected", level + 1)
		end
		local s = S.services[name]
		if s then
			return s
		end
		local cls = Classes[name]
		if cls == nil or not cls.service then
			misuse(fmt("'%s' is not a valid Service name (or not modelled by the mock)", name), level + 1)
		end
		return mkService(name)
	end

	-- players -----------------------------------------------------------------------------------
	local function hum(char)
		return char and BaseMethods.FindFirstChildOfClass(char, "Humanoid")
	end
	function S.buildCharacter(player)
		local pd = DATA[player]
		local m = newInstance(S, "Model", true)
		m.Name = pd.props.Name
		local hrp = newInstance(S, "Part", true)
		hrp.Name = "HumanoidRootPart"
		hrp.Size = v3(2, 2, 1)
		hrp.Transparency = 1
		hrp.CanCollide = false
		hrp.Parent = m
		local head = newInstance(S, "Part", true)
		head.Name = "Head"
		head.Size = v3(2, 1, 1)
		head.Parent = m
		local h = newInstance(S, "Humanoid", true)
		h.DisplayName = pd.props.DisplayName
		h.Parent = m
		m.PrimaryPart = hrp
		local spawn = opts.spawnPoint or v3(0, 5, 0)
		pivotTo(m, DATA[m], CFrame.new(spawn))
		head.CFrame = CFrame.new(spawn + v3(0, 1.5, 0))
		return m
	end
	function S.loadCharacter(player)
		local pd = DATA[player]
		local old = pd.props.Character
		if old ~= nil then
			fireEv(pd, "CharacterRemoving", old)
			destroy(old, DATA[old])
		end
		local m = S.buildCharacter(player)
		pd.props.Character = m
		fireChanged(player, pd, "Character")
		fireEv(pd, "CharacterAdded", m)
		-- the engine parents the character right after CharacterAdded handlers start
		if DATA[m].parent == nil and not DATA[m].destroyed then
			setParent(m, DATA[m], S.workspace)
		end
		fireEv(pd, "CharacterAppearanceLoaded", m)
		return m
	end
	function S.onHumanoidDied(h)
		local char = DATA[h].parent
		for _, p in DATA[S.players].children do
			if isPlayer(p) and DATA[p].props.Character == char then
				local respawn = DATA[S.players].props.RespawnTime
				S.after(respawn, function()
					if DATA[p].parent == S.players and DATA[p].props.Character == char and DATA[S.players].props.CharacterAutoLoads then
						S.spawn(S.loadCharacter, p)
					end
				end)
			end
		end
	end
	function S.addPlayer(o)
		o = o or {}
		local p = newInstance(S, "Player", true)
		local pd = DATA[p]
		pd.props.Name = o.name or ("Player" .. tostring(o.userId))
		pd.props.UserId = o.userId or 1
		pd.props.DisplayName = o.displayName or pd.props.Name
		setParent(p, pd, S.players)
		fireEv(DATA[S.players], "PlayerAdded", p)
		if DATA[S.players].props.CharacterAutoLoads and o.noCharacter ~= true then
			S.after(o.characterDelay or 0.1, function()
				if pd.parent == S.players then
					S.spawn(S.loadCharacter, p)
				end
			end)
		end
		return p
	end
	function S.removePlayer(p)
		local pd = DATA[p]
		if pd.parent ~= S.players then
			return
		end
		fireEv(DATA[S.players], "PlayerRemoving", p)
		local char = pd.props.Character
		if char ~= nil then
			fireEv(pd, "CharacterRemoving", char)
			destroy(char, DATA[char])
		end
		setParent(p, pd, nil)
		S.walkers[p] = nil
	end
	function S.kick(p, msg)
		local uid = DATA[p].props.UserId
		table.insert(S.kicks, { userId = uid, reason = msg, t = M.clock })
		S.after(0, function()
			S.removePlayer(p)
		end)
	end

	-- frames ------------------------------------------------------------------------------------
	function S.moveWalkers(dt)
		for p, w in S.walkers do
			local pd = DATA[p]
			local char = pd.props.Character
			local hrp = char and findChild(DATA[char], "HumanoidRootPart")
			local h = hum(char)
			if hrp and h and not DATA[hrp].props.Anchored and DATA[h].props.Health > 0 and isDescendantOf(hrp, S.workspace) then
				local budget = DATA[h].props.WalkSpeed * dt * (w.speedFactor or 1)
				while budget > 1e-9 and #w.path > 0 do
					local target = w.path[1]
					local pos = DATA[hrp].props.CFrame.Position
					local dx, dz = target.X - pos.X, target.Z - pos.Z
					local dist = math.sqrt(dx * dx + dz * dz)
					if dist <= budget then
						pivotTo(char, DATA[char], CFrame.new(target.X, pos.Y, target.Z))
						budget -= dist
						table.remove(w.path, 1)
						if w.onPoint then
							w.onPoint(#w.path)
						end
					else
						local f = budget / dist
						pivotTo(char, DATA[char], CFrame.new(pos.X + dx * f, pos.Y, pos.Z + dz * f))
						budget = 0
					end
				end
				if #w.path == 0 and w.onEmpty then
					w.onEmpty()
				end
			end
		end
	end
	function S.frame(dt)
		if S.dead then
			return
		end
		dt = dt or FRAME
		S.frameNo += 1
		M.clock += dt
		local due, keep = {}, {}
		for _, w in S.waiting do
			if w.cancelled then
				-- drop
			elseif w.frame < S.frameNo and w.at <= M.clock + 1e-9 then
				table.insert(due, w)
			else
				table.insert(keep, w)
			end
		end
		S.waiting = keep
		table.sort(due, function(a, b)
			if a.at ~= b.at then
				return a.at < b.at
			end
			return a.seq < b.seq
		end)
		for _, w in due do
			if not w.cancelled then
				if w.co then
					S.waitIndex[w.co] = nil
				end
				if w.fn then
					local ok, err = xpcall(w.fn, debug.traceback)
					if not ok then
						table.insert(S.errors, "[mock timer] " .. tostring(err))
					end
				elseif w.args then
					S.resume(w.co, table.unpack(w.args, 1, w.args.n))
				else
					S.resume(w.co, M.clock - w.start)
				end
			end
		end
		S.runDeferred()
		S.moveWalkers(dt)
		for _, h in S.frameHooks do
			h(dt)
		end
		local t0 = realClock()
		local hb = DATA[S.runService].sigs.Heartbeat
		if hb then
			fire(hb, dt)
		end
		S.runDeferred()
		S.heartbeatReal += realClock() - t0
		S.heartbeatFrames += 1
	end
	function S.checkInfiniteWaits()
		for e in S.childWaits do
			if e.infinite and not e.done and M.clock - e.since >= 5 and not S.reportedWaits[e] then
				S.reportedWaits[e] = true
				table.insert(S.errors, fmt("Infinite yield: %s:WaitForChild(\"%s\") never resolved (waited %.1fs)%s", fullName(e.parent), e.name, M.clock - e.since, e.trace))
			end
		end
	end
	function S.kill()
		S.dead = true
		S.waiting = {}
		S.deferred = {}
	end

	-- module system -------------------------------------------------------------------------------
	local function requireMod(mod)
		if TYPE[mod] ~= "Instance" then
			misuse("Attempted to call require with invalid argument(s): " .. typeofm(mod), 3)
		end
		local md = DATA[mod]
		if md.className ~= "ModuleScript" then
			misuse("Attempted to call require with a " .. md.className .. " (" .. fullName(mod) .. ")", 3)
		end
		local cached = S.moduleCache[mod]
		if cached ~= nil then
			return cached.value
		end
		if S.moduleLoading[mod] then
			misuse("Requested module was required recursively: " .. fullName(mod), 3)
		end
		local loader = md.loader
		if loader == nil then
			error("Module has no source in the headless bundle: " .. fullName(mod), 3)
		end
		S.moduleLoading[mod] = true
		setfenv(loader, S.env)
		local res = table.pack(xpcall(loader, debug.traceback, mod))
		S.moduleLoading[mod] = nil
		if not res[1] then
			error("Requested module experienced an error while loading: " .. fullName(mod) .. "\n" .. tostring(res[2]), 3)
		end
		if res.n ~= 2 or res[2] == nil then
			misuse("Module code did not return exactly one value: " .. fullName(mod), 3)
		end
		S.moduleCache[mod] = { value = res[2] }
		return res[2]
	end
	S.require = requireMod

	-- globals -------------------------------------------------------------------------------------
	local vos = setmetatable({
		clock = function()
			return M.CLOCK0 + M.clock
		end,
		time = function(t)
			if t ~= nil then
				return realTime(t)
			end
			return math.floor(M.TIME0 + M.clock)
		end,
		date = function(f, t)
			return realDate(f, t or math.floor(M.TIME0 + M.clock))
		end,
		difftime = function(a, b)
			return a - (b or 0)
		end,
	}, {
		__index = function(_, k)
			misuse("os." .. tostring(k) .. " is not available in Roblox", 2)
		end,
	})
	local function out(list, prefix, ...)
		local n = select("#", ...)
		local parts = {}
		for i = 1, n do
			parts[i] = tostring((select(i, ...)))
		end
		local s = table.concat(parts, " ")
		table.insert(list, s)
		if M.verbose then
			rawprint(prefix .. s)
		end
	end
	local G = {}
	S.G = G
	S.env = setmetatable({
		game = game,
		workspace = S.workspace,
		Workspace = S.workspace,
		Instance = lib("Instance", {
			new = function(className, parent)
				if type(className) ~= "string" then
					misuse("Instance.new: string expected", 2)
				end
				local i = newInstance(S, className, false)
				if parent ~= nil then
					i.Parent = parent
				end
				return i
			end,
		}),
		Vector3 = Vector3,
		Vector2 = Vector2,
		CFrame = CFrame,
		Color3 = Color3,
		UDim = UDim,
		UDim2 = UDim2,
		Enum = Enum,
		Random = Random,
		task = task,
		os = vos,
		typeof = typeofm,
		require = requireMod,
		print = function(...)
			out(S.prints, "[print] ", ...)
		end,
		warn = function(...)
			out(S.warns, "[warn] ", ...)
		end,
		wait = function(t)
			return S.sleep(t), M.clock
		end,
		spawn = function(fn)
			S.after(0, function()
				S.spawn(fn)
			end)
		end,
		delay = function(t, fn)
			task.delay(t, fn)
		end,
		tick = function()
			return M.TIME0 + M.clock
		end,
		time = function()
			return M.clock
		end,
		shared = {},
		_G = G,
	}, { __index = REAL_G })

	return S
end

---------------------------------------------------------------------------------------------
-- harness
---------------------------------------------------------------------------------------------

-- mods: { [path] = { kind = "ModuleScript" | "Script", fn = loader } }
function M.makeHarness(mods)
	local H = {}
	H.M = M
	H.Enum = Enum
	H.Vector3 = Vector3
	H.CFrame = CFrame
	H.log = {}
	H.boots = 0

	local function say(...)
		local parts = {}
		for i = 1, select("#", ...) do
			parts[i] = tostring((select(i, ...)))
		end
		table.insert(H.log, table.concat(parts, " "))
	end
	H.say = say

	function H.boot(opts)
		opts = opts or {}
		if H.S and not H.S.dead then
			H.S.kill()
		end
		H.boots += 1
		local S = M.newServer(opts)
		H.S = S
		-- script tree, laid out like tools/build_place.py
		local main = nil
		local paths = {}
		for path in mods do
			table.insert(paths, path)
		end
		table.sort(paths)
		for _, path in paths do
			local info = mods[path]
			local parts = string.split(path, ".")
			local parent = S.services[parts[1]]
			for i = 2, #parts - 1 do
				local c = findChild(DATA[parent], parts[i])
				if c == nil then
					c = newInstance(S, "Folder", true)
					c.Name = parts[i]
					setParent(c, DATA[c], parent)
				end
				parent = c
			end
			local inst = newInstance(S, info.kind, true)
			DATA[inst].props.Name = parts[#parts]
			DATA[inst].loader = info.fn
			setParent(inst, DATA[inst], parent)
			S.modules[path] = inst
			if info.kind == "Script" then
				main = inst
			end
		end
		if opts.beforeMain then
			H.call(opts.beforeMain, S)
		end
		-- the Script runs in its own thread, like the engine does
		local md = DATA[main]
		S.mainThread = S.spawn(function()
			setfenv(md.loader, S.env)
			md.loader(main)
		end)
		return S
	end

	function H.requirePath(path)
		local S = H.S
		local inst = S.modules[path]
		assert(inst, "no module at " .. path)
		local v
		H.call(function()
			v = S.require(inst)
		end)
		return v
	end
	function H.svc(name)
		return H.requirePath("ServerScriptService.Server.services." .. name)
	end
	function H.shared(name)
		return H.requirePath("ReplicatedStorage.Shared." .. name)
	end

	-- Runs fn in a server thread and steps virtual frames until it finishes (max timeout s).
	function H.call(fn, ...)
		local S = H.S
		local done, res = false, nil
		local args = table.pack(...)
		S.spawn(function()
			res = table.pack(xpcall(fn, debug.traceback, table.unpack(args, 1, args.n)))
			done = true
		end)
		local frames = 0
		while not done and frames < 60 * 120 do
			S.frame(FRAME)
			frames += 1
		end
		if not done then
			error("H.call: function did not finish within 120 virtual seconds", 2)
		end
		if not res[1] then
			error(res[2], 0)
		end
		return table.unpack(res, 2, res.n)
	end

	function H.run(seconds)
		local S = H.S
		local n = math.floor(seconds * 60 + 0.5)
		for _ = 1, n do
			S.frame(FRAME)
		end
		S.checkInfiniteWaits()
	end
	function H.runUntil(pred, timeout, what)
		local S = H.S
		local frames = 0
		local limit = math.floor((timeout or 30) * 60)
		while not pred() do
			if frames >= limit then
				S.checkInfiniteWaits()
				error(fmt("H.runUntil timed out after %gs: %s", timeout or 30, what or "?"), 2)
			end
			S.frame(FRAME)
			frames += 1
		end
		S.checkInfiniteWaits()
		return frames / 60
	end

	function H.addPlayer(o)
		local p = H.S.addPlayer(o)
		return p
	end
	function H.removePlayer(p)
		H.S.removePlayer(p)
	end
	function H.inGame(p)
		return DATA[p].parent == H.S.players
	end

	function H.character(p)
		return DATA[p].props.Character
	end
	function H.hrp(p)
		local c = DATA[p].props.Character
		return c and findChild(DATA[c], "HumanoidRootPart")
	end
	function H.humanoid(p)
		local c = DATA[p].props.Character
		return c and BaseMethods.FindFirstChildOfClass(c, "Humanoid")
	end
	function H.pos(p)
		local hrp = H.hrp(p)
		return hrp and DATA[hrp].props.CFrame.Position
	end
	function H.anchored(p)
		local hrp = H.hrp(p)
		return hrp ~= nil and DATA[hrp].props.Anchored
	end
	function H.networkOwner(part)
		return DATA[part].networkOwner
	end

	-- grid helpers (cell units use Config)
	function H.cellToWorld(cx, cy)
		local Config = H.shared("Config")
		local cs = Config.Arena.CellSize
		local half = Config.Arena.GridSize * cs / 2
		return (cx + 0.5) * cs - half, (cy + 0.5) * cs - half
	end
	function H.worldToCell(x, z)
		local Config = H.shared("Config")
		local cs = Config.Arena.CellSize
		local half = Config.Arena.GridSize * cs / 2
		return math.floor((x + half) / cs), math.floor((z + half) / cs)
	end
	function H.cellOf(p)
		local pos = H.pos(p)
		return H.worldToCell(pos.X, pos.Z)
	end

	-- walking: list of {cx, cy} cell targets (centres); replaces the current path
	function H.walkCells(p, cells, o)
		local path = {}
		for _, c in cells do
			local x, z = H.cellToWorld(c[1], c[2])
			table.insert(path, v3(x, 0, z))
		end
		H.S.walkers[p] = { path = path, speedFactor = o and o.speedFactor, onPoint = o and o.onPoint, onEmpty = o and o.onEmpty }
	end
	function H.walkWorld(p, points, o)
		H.S.walkers[p] = { path = table.clone(points), speedFactor = o and o.speedFactor, onEmpty = o and o.onEmpty }
	end
	function H.stopWalking(p)
		H.S.walkers[p] = nil
	end
	function H.walking(p)
		local w = H.S.walkers[p]
		return w ~= nil and #w.path > 0
	end

	-- remotes
	function H.sent(p, name)
		local out = {}
		for _, e in H.S.sent[DATA[p].props.UserId] or {} do
			if name == nil or e.name == name then
				table.insert(out, e)
			end
		end
		return out
	end
	function H.last(p, name)
		local list = H.sent(p, name)
		return list[#list]
	end
	function H.clearSent(p)
		H.S.sent[DATA[p].props.UserId] = {}
	end
	function H.remote(name)
		local folder = findChild(DATA[H.S.services.ReplicatedStorage], "Remotes")
		return folder and findChild(DATA[folder], name)
	end
	-- Fake client InvokeServer on Remotes.Request. Args go through the wire (functions dropped).
	function H.invoke(p, ...)
		local S = H.S
		local rf = H.remote("Request")
		assert(rf, "no Request RemoteFunction")
		local cb = DATA[rf].callbacks.OnServerInvoke
		assert(cb, "OnServerInvoke not set")
		local n = select("#", ...)
		local raw = { ... }
		local args = { n = n }
		for i = 1, n do
			local v = raw[i]
			if type(v) == "table" then
				v = deepCopy(v)
			elseif type(v) == "function" then
				v = nil
			end
			args[i] = v
		end
		local done, res = false, nil
		S.spawn(function()
			res = table.pack(xpcall(cb, debug.traceback, p, table.unpack(args, 1, n)))
			done = true
		end)
		local frames = 0
		while not done and frames < 60 * 60 do
			S.frame(FRAME)
			frames += 1
		end
		if not done then
			error("Request did not return within 60 virtual seconds", 2)
		end
		if not res[1] then
			table.insert(S.errors, "OnServerInvoke errored: " .. tostring(res[2]))
			return "__error", res[2]
		end
		local errs = {}
		local outv = {}
		for i = 2, res.n do
			outv[i - 1] = wireCopy(res[i], "Request return #" .. (i - 1), {}, errs, false)
		end
		if #errs > 0 then
			misuse("Request return value cannot be serialized: " .. table.concat(errs, "; "))
		end
		return table.unpack(outv, 1, res.n - 1)
	end
	function H.fireServer(p, name, ...)
		local r = H.remote(name)
		assert(r, "no remote " .. name)
		fire(getSignal(DATA[r], "OnServerEvent"), p, ...)
	end

	function H.processReceipt(info)
		local S = H.S
		local ms = S.services.MarketplaceService
		assert(ms, "MarketplaceService never requested")
		local cb = DATA[ms].callbacks.ProcessReceipt
		assert(cb, "ProcessReceipt not set")
		local done, res = false, nil
		S.spawn(function()
			res = table.pack(xpcall(cb, debug.traceback, info))
			done = true
		end)
		local frames = 0
		while not done and frames < 60 * 60 do
			S.frame(FRAME)
			frames += 1
		end
		assert(done, "ProcessReceipt did not return")
		if not res[1] then
			error("ProcessReceipt errored: " .. tostring(res[2]), 2)
		end
		local d = res[2]
		if not isEnumOf(d, "ProductPurchaseDecision") then
			misuse("ProcessReceipt must return an Enum.ProductPurchaseDecision, got " .. typeofm(d))
		end
		return d
	end
	function H.firePassPurchase(p, passId, purchased)
		local ms = H.S.getService("MarketplaceService", 1)
		fire(getSignal(DATA[ms], "PromptGamePassPurchaseFinished"), p, passId, purchased)
	end

	-- Server shutdown: players leave, BindToClose handlers run (max 30 s), then the server dies.
	function H.shutdown()
		local S = H.S
		for _, p in table.clone(DATA[S.players].children) do
			if isPlayer(p) then
				S.removePlayer(p)
			end
		end
		local threads = {}
		for _, fn in S.closeHandlers do
			table.insert(threads, S.spawn(fn))
		end
		local frames = 0
		local function busy()
			for _, co in threads do
				if coroutine.status(co) ~= "dead" then
					return true
				end
			end
			return false
		end
		while busy() and frames < 30 * 60 do
			S.frame(FRAME)
			frames += 1
		end
		local ok = not busy()
		S.checkInfiniteWaits()
		S.kill()
		return ok, frames / 60
	end

	-- problems collected so far: thread errors, misuse, infinite waits, error-looking warns
	function H.problems(o)
		local S = H.S
		o = o or {}
		local out = {}
		for _, e in S.errors do
			table.insert(out, "ERROR: " .. e)
		end
		for _, e in S.misuse do
			table.insert(out, "MISUSE: " .. e)
		end
		for _, w in S.warns do
			local lw = string.lower(w)
			if string.find(lw, "fail") or string.find(lw, "error") or string.find(lw, "invalid") or string.find(lw, "exception") then
				local allowed = false
				for _, pat in o.allowWarn or {} do
					if string.find(w, pat) then
						allowed = true
					end
				end
				if not allowed then
					table.insert(out, "WARN: " .. w)
				end
			end
		end
		return out
	end
	function H.assertClean(o)
		local probs = H.problems(o)
		if #probs > 0 then
			error(fmt("%d problem(s):\n%s", #probs, table.concat(probs, "\n---\n", 1, math.min(#probs, 8))), 2)
		end
	end
	function H.check(cond, msg, ...)
		if not cond then
			error("check failed: " .. fmt(msg, ...), 2)
		end
	end
	function H.eq(a, b, msg)
		if a ~= b then
			error(fmt("check failed: %s (expected %s, got %s)", msg or "", tostring(b), tostring(a)), 2)
		end
	end
	function H.realClock()
		return realClock()
	end
	return H
end

-- Runs one scenario; returns "PASS\n<log>" or "FAIL\n<error>\n<log>".
function M.runScenario(mods, scenario, name)
	local H = M.makeHarness(mods)
	local ok, err = xpcall(scenario, debug.traceback, H)
	local logText = table.concat(H.log, "\n")
	if ok and H.S then
		local probs = H.problems(H.allow)
		if #probs > 0 then
			ok = false
			err = fmt("%d unexpected problem(s) at end of scenario:\n%s", #probs, table.concat(probs, "\n---\n", 1, math.min(#probs, 8)))
		end
	end
	if ok then
		return "PASS\n" .. logText
	end
	local warns = ""
	if H.S then
		local w = H.S.warns
		if #w > 0 then
			warns = "\nlast warns:\n  " .. table.concat(w, "\n  ", math.max(1, #w - 9), #w)
		end
	end
	return "FAIL\n" .. tostring(err) .. warns .. "\n" .. logText
end

return M
