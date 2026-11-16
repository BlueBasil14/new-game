--!strict
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Remotes = require(Shared.Remotes)
local UiKit = require(script.Parent.UiKit)
local ClientState = require(script.Parent.Parent.ClientState)
local PanelController = require(script.Parent.Parent.controllers.PanelController)
local Rewards = {}
local INK = Color3.fromHex("202840")
local PAPER = Color3.fromHex("FFF9EE")
local GOLD = Color3.fromHex("FFC94A")
local MINT = Color3.fromHex("6DE0A5")
local CYAN = Color3.fromHex("43D8E8")
local function timeText(n: number): string
	n = math.max(0, math.ceil(n))
	return string.format("%d:%02d", n // 60, n % 60)
end
local function animate(object: Instance, duration: number, goal: any, style: Enum.EasingStyle?)
	TweenService:Create(object, TweenInfo.new(duration, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

function Rewards.celebrate(source: GuiObject, amount: number, currency: string, title: string?)
	local gui = UiKit.screenGui("RewardCelebration", 90)
	local origin = source.AbsolutePosition + source.AbsoluteSize / 2
	local icon = if currency == "gems" then "economy_gem" elseif currency == "speed" then "gameplay_speed" elseif currency == "skin" then "gameplay_cosmetics" else "economy_coin"
	local low = ClientState.profile ~= nil and ClientState.profile.settings.lowDetail
	local layer = UiKit.frame({Name = "ClaimBurst", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, parent = gui})
	Debris:AddItem(layer, 3)
	local card = UiKit.frame({Name = "RewardPopup", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.68), Size = UDim2.fromOffset(280, 88), BackgroundColor3 = PAPER, parent = layer})
	UiKit.corner(card, 20); UiKit.stroke(card, INK, 3)
	UiKit.icon(icon, {Position = UDim2.fromOffset(12, 10), Size = UDim2.fromOffset(64, 64), parent = card})
	UiKit.label({Text = title or ("+" .. UiKit.formatNumber(amount) .. " " .. currency), Position = UDim2.fromScale(0.29, 0.12), Size = UDim2.fromScale(0.67, 0.45), parent = card})
	UiKit.label({Text = "Reward collected!", TextColor3 = Color3.fromHex("55746B"), Position = UDim2.fromScale(0.29, 0.58), Size = UDim2.fromScale(0.67, 0.23), parent = card})
	local scale = Instance.new("UIScale"); scale.Scale = 0.3; scale.Parent = card
	animate(scale, 0.4, {Scale = 1}, Enum.EasingStyle.Back)
	if not low then
		local ring = UiKit.frame({Name = "RewardRipple", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(origin.X, origin.Y), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, parent = layer})
		UiKit.corner(ring, 100); local stroke = UiKit.stroke(ring, GOLD, 5)
		animate(ring, 0.65, {Size = UDim2.fromOffset(240, 240)}); animate(stroke, 0.65, {Transparency = 1})
	end
	for i = 1, if low then 6 else 28 do
		local angle = i * 2.399
		local distance = if low then 45 else 65 + (i % 5) * 24
		local particle = UiKit.icon(if i % 4 == 0 then "economy_star" else icon, {Name = "RewardParticle", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(origin.X, origin.Y), Size = UDim2.fromOffset(24 + i % 3 * 6, 24 + i % 3 * 6), parent = layer})
		animate(particle, 0.3, {Position = UDim2.fromOffset(origin.X + math.cos(angle) * distance, origin.Y + math.sin(angle) * distance - 70), Rotation = (i % 2 * 2 - 1) * 70}, Enum.EasingStyle.Back)
		task.delay(0.32 + i * 0.012, function()
			if not particle.Parent then return end
			-- Fly currency into the wallet, rather than leaving screen-wide debris.
			local wallet = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Hud")
			local row = wallet and wallet:FindFirstChild("Wallet")
			local target = if row and row:IsA("GuiObject") then row.AbsolutePosition + Vector2.new(55, 25) else Vector2.new(80, 70)
			animate(particle, 0.55, {Position = UDim2.fromOffset(target.X, target.Y), Size = UDim2.fromOffset(8, 8), ImageTransparency = 1})
		end)
	end
	task.delay(1.7, function()
		if card.Parent then animate(card, 0.3, {Position = UDim2.fromScale(0.5, 0.63), BackgroundTransparency = 1}); animate(scale, 0.3, {Scale = 0}) end
	end)
end

function Rewards.build(gui: ScreenGui): () -> ()
	local bar = UiKit.frame({Name = "Playtime", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.fromScale(0.53, 0.19), BackgroundColor3 = PAPER, parent = gui})
	UiKit.corner(bar, 20); UiKit.stroke(bar, INK, 3)
	local limit = Instance.new("UISizeConstraint"); limit.MaxSize = Vector2.new(780, 150); limit.Parent = bar
	UiKit.icon("core_gift", {Position = UDim2.fromScale(0.025, 0.045), Size = UDim2.fromScale(0.065, 0.2), parent = bar})
	UiKit.label({Text = "Play & collect", TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromScale(0.1, 0.04), Size = UDim2.fromScale(0.37, 0.18), parent = bar})
	local nextLabel = UiKit.label({Name = "NextReward", Text = "", TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.fromScale(0.48, 0.04), Size = UDim2.fromScale(0.49, 0.18), parent = bar})
	local track = UiKit.frame({Name = "ProgressTrack", Position = UDim2.fromScale(0.035, 0.265), Size = UDim2.fromScale(0.93, 0.045), BackgroundColor3 = Color3.fromHex("DDD8CD"), parent = bar})
	UiKit.corner(track, 20)
	local fill = UiKit.frame({Name = "Progress", Size = UDim2.fromScale(0, 1), BackgroundColor3 = CYAN, parent = track}); UiKit.corner(fill, 20)
	local nodes: {any} = {}
	local busy = false
	for i, def in Catalog.playtime do
		local b: TextButton
		b = UiKit.button({text = "", color = PAPER, position = UDim2.fromScale(0.025 + (i - 1) * 0.193, 0.37), size = UDim2.fromScale(0.18, 0.56), parent = bar, onClick = function()
			local session = ClientState.session
			if busy or session.playtimeClaimed[i] or ClientState.serverNow() - session.joinedAt < def.seconds then return end
			busy = true
			local ok, result = ClientState.request(Remotes.Requests.ClaimPlaytime, i)
			busy = false
			if ok then
				PanelController.sound("reward")
				Rewards.celebrate(b, def.amount, def.currency)
			else PanelController.sound("error"); UiKit.toast(PanelController.errorText(result), UiKit.theme.Danger) end
		end})
		b.Name = "Reward" .. i
		local art = UiKit.icon(if def.currency == "gems" then "economy_gem" else "economy_coin_stack", {Position = UDim2.fromScale(0.04, 0.08), Size = UDim2.fromScale(0.36, 0.5), parent = b})
		UiKit.label({Text = UiKit.formatNumber(def.amount), Position = UDim2.fromScale(0.4, 0.1), Size = UDim2.fromScale(0.55, 0.38), parent = b})
		local state = UiKit.label({Name = "State", Text = timeText(def.seconds), Position = UDim2.fromScale(0.05, 0.64), Size = UDim2.fromScale(0.9, 0.23), parent = b})
		nodes[i] = {button = b, state = state, art = art, last = ""}
	end
	return function()
		local session = ClientState.session
		local sec = math.max(0, ClientState.serverNow() - session.joinedAt)
		local nextTime: number? = nil
		local readyCount = 0
		for i, def in Catalog.playtime do
			local node = nodes[i]
			local claimed = session.playtimeClaimed[i] == true
			local ready = not claimed and sec >= def.seconds
			local state = if claimed then "claimed" elseif ready then "ready" else "locked"
			if ready then readyCount += 1 elseif not claimed and nextTime == nil then nextTime = math.max(0, def.seconds - sec) end
			node.state.Text = if claimed then "Collected!" elseif ready then "CLAIM!" else timeText(def.seconds - sec)
			if state ~= node.last then
				node.last = state
				node.button.BackgroundColor3 = if claimed then MINT elseif ready then GOLD else PAPER
				node.art.ImageTransparency = if claimed then 0.35 else 0
				if ready and not (ClientState.profile and ClientState.profile.settings.lowDetail) then UiKit.pulse(node.button) else UiKit.stopPulse(node.button) end
			end
		end
		nextLabel.Text = if readyCount > 0 then tostring(readyCount) .. " ready to claim!" elseif nextTime then "Next in " .. timeText(nextTime) else "All rewards collected!"
		animate(fill, 0.45, {Size = UDim2.fromScale(math.clamp(sec / Catalog.playtime[#Catalog.playtime].seconds, 0, 1), 1)})
	end
end
return Rewards
