--!strict
-- Animated turf skins (Turf Pass Legendaries). One function drives both the in-game turf Texture
-- (TurfRenderer) and the shop/pass card previews, so they always move the same way.
-- Returns the pattern colour, the pattern offset in tiles (u, v, each wrapped to [0, 1)) and its transparency.
local TurfAnim = {}

local WHITE = Color3.new(1, 1, 1)
local TAU = 2 * math.pi

function TurfAnim.frame(anim: string, b: Color3, t: number): (Color3, number, number, number)
	if anim == "pulse" then
		-- Neon Pulse: stripes slide sideways while the stripe colour throbs to white once a second.
		local k = 0.5 + 0.5 * math.sin(t * TAU)
		return b:Lerp(WHITE, 0.6 * k), (t * 0.35) % 1, 0, 0
	elseif anim == "flow" then
		-- Magma Surge: molten waves roll along and glow brighter in slow surges.
		local k = 0.5 + 0.5 * math.sin(t * TAU / 1.6)
		return b:Lerp(WHITE, 0.45 * k), (t * 0.22) % 1, (t * 0.05) % 1, 0
	elseif anim == "drift" then
		-- Starfall: stars fall diagonally and twinkle.
		local twinkle = 0.5 + 0.5 * math.sin(t * TAU * 1.3)
		return b:Lerp(WHITE, 0.3 * twinkle), (t * 0.12) % 1, (t * 0.2) % 1, 0.35 * (1 - twinkle)
	elseif anim == "rainbow" then
		-- Prism Storm: hexes cycle through the rainbow while drifting.
		return Color3.fromHSV((t / 4) % 1, 0.6, 1), (t * 0.1) % 1, (t * 0.1) % 1, 0
	end
	return b, 0, 0, 0
end

return TurfAnim
