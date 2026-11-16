--!strict
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Def = require(Shared.SkyChest)
local Data = require(script.Parent.DataService)
local Economy = require(script.Parent.EconomyService)
local Arena = require(script.Parent.ArenaService)
local Service = {}
local remote: RemoteEvent
local active: Model? = nil
local busy: {[Player]: boolean} = {}
local rng = Random.new()
local started = false
local policies: {[Player]: any} = {}

local function paidAllowed(player: Player): boolean
	local cached=policies[player]
	if cached and os.clock()-cached.at<60 then return cached.allowed end
	local ok, policy = pcall(function() return PolicyService:GetPolicyInfoForPlayerAsync(player) end)
	local allowed=ok and policy.ArePaidRandomItemsRestricted == false
	policies[player]={at=os.clock(),allowed=allowed}
	return allowed
end

function Service.request(player: Player, action: any): (boolean, any)
	if busy[player] then return false, "Please wait for your spin." end
	busy[player] = true
	local function done(ok: boolean, result: any): (boolean, any)
		busy[player] = nil
		return ok, result
	end
	local p = Data.get(player)
	if not p then return done(false, "Profile not ready.") end
	if action == "status" then
		return done(true, {free = p.wheelFree, paid = p.wheelPaid, allowed = paidAllowed(player), productId = Def.ProductId})
	elseif action == "purchase" then
		if Def.ProductId == 0 or not paidAllowed(player) then return done(false, "Paid spins are unavailable for this account.") end
		return done(true, Def.ProductId)
	elseif action ~= "spin" then return done(false, "Invalid action.") end
	if p.wheelFree <= 0 and (p.wheelPaid <= 0 or not paidAllowed(player)) then return done(false, "No eligible spins available.") end
	local draw = rng:NextInteger(1, 100)
	local index = 1
	for i, prize in Def.Prizes do draw -= prize.weight; if draw <= 0 then index = i; break end end
	local prize = Def.Prizes[index]
	local duplicate = false
	Data.update(player, function(profile)
		if profile.wheelFree > 0 then profile.wheelFree -= 1 else profile.wheelPaid -= 1 end
		if prize.kind == "coins" or prize.kind == "gems" then Economy.creditInProfile(player, profile, prize.kind, prize.amount, "skyChest")
		elseif prize.kind == "skin" then
			duplicate = profile.owned[prize.skin] == true
			if duplicate then Economy.creditInProfile(player, profile, "gems", 100, "skyChestDuplicate") else profile.owned[prize.skin] = true end
		elseif prize.kind == "speed" then profile.speedBoostUntil = math.max(os.time(), profile.speedBoostUntil) + Def.SpeedSeconds end
	end)
	Arena.refreshWalkSpeed(player)
	Data.save(player)
	return done(true, {index = index, duplicate = duplicate, free = p.wheelFree, paid = p.wheelPaid})
end

local function chest(position: Vector3): Model
	local model = Instance.new("Model"); model.Name = "SkyChest"
	local root = Instance.new("Part"); root.Name = "Body"; root.Size = Vector3.new(7,4,5); root.Color = Color3.fromHex("9C7DFF"); root.Anchored = true; root.CanCollide = false; root.Material = Enum.Material.SmoothPlastic; root.CFrame = CFrame.new(position); root.Parent = model
	model.PrimaryPart = root
	local function part(name: string, size: Vector3, offset: Vector3, color: string)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Color = Color3.fromHex(color); p.Material = Enum.Material.SmoothPlastic; p.CanCollide = false; p.Massless = true; p.CFrame = root.CFrame + offset; p.Parent = model
		local weld = Instance.new("WeldConstraint"); weld.Part0 = root; weld.Part1 = p; weld.Parent = p
	end
	part("Lid",Vector3.new(7.4,1.5,5.4),Vector3.new(0,2.6,0),"C9B7FF")
	for _,x in {-2.4,2.4} do part("GoldBand",Vector3.new(0.6,5.2,5.6),Vector3.new(x,0.65,0),"FFC94A") end
	part("BaseTrim",Vector3.new(7.5,0.5,5.5),Vector3.new(0,-2,0),"202840")
	part("Latch",Vector3.new(1.1,1.6,0.6),Vector3.new(0,1,-2.9),"FFC94A")
	local light = Instance.new("PointLight"); light.Color = Color3.fromHex("FFC94A"); light.Brightness = 3; light.Range = 25; light.Parent = root
	local gui=Instance.new("BillboardGui"); gui.Size=UDim2.fromOffset(230,65);gui.StudsOffset=Vector3.new(0,6,0);gui.AlwaysOnTop=true;gui.Parent=root
	local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text="SKY CHEST\nRun into it for a free spin!";label.Font=Enum.Font.GothamBold;label.TextScaled=true;label.TextColor3=Color3.fromHex("FFC94A");label.TextStrokeTransparency=0;label.Parent=gui
	return model
end

function Service.drop(at: Vector3?)
	local TweenService = game:GetService("TweenService")
	if active then return end
	local half = Config.Arena.GridSize * Config.Arena.CellSize * 0.36
	local landing = at or Vector3.new(rng:NextNumber(-half,half), Config.Arena.FloorY+3, rng:NextNumber(-half,half))
	local model=chest(landing+Vector3.new(0,110,0));active=model;model.Parent=workspace
	remote:FireAllClients({kind="fall",position=landing})
	local root=model.PrimaryPart :: BasePart
	local fall=TweenService:Create(root,TweenInfo.new(Def.FallSeconds,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{CFrame=CFrame.new(landing)});fall:Play();fall.Completed:Wait()
	remote:FireAllClients({kind="land",position=landing})
	local expires=os.clock()+Def.Lifetime
	while active==model and os.clock()<expires do
		for _,player in Players:GetPlayers() do
			local char=player.Character;local hrp=char and char:FindFirstChild("HumanoidRootPart");local hum=char and char:FindFirstChildOfClass("Humanoid")
			if hrp and hrp:IsA("BasePart") and hum and hum.Health>0 and (hrp.Position-landing).Magnitude<8 and Data.get(player) then
				active=nil;model:Destroy()
				Data.update(player,function(p) p.wheelFree+=1 end);Data.save(player)
				remote:FireClient(player,{kind="claimed"});return
			end
		end
		task.wait(0.15)
	end
	if active==model then active=nil end;model:Destroy()
end

function Service.start()
	if started then return end;started=true
	remote=Instance.new("RemoteEvent");remote.Name="SkyChestEvent";remote.Parent=ReplicatedStorage:WaitForChild("Remotes")
	Players.PlayerRemoving:Connect(function(player) busy[player]=nil;policies[player]=nil end)
	task.spawn(function() task.wait(Def.Interval);while true do task.spawn(Service.drop);task.wait(Def.Interval) end end)
	if game:GetService("RunService"):IsStudio() then
		local debugDrop=Instance.new("BindableEvent");debugDrop.Name="DebugDrop";debugDrop.Parent=script
		debugDrop.Event:Connect(function(position: Vector3?) task.spawn(Service.drop,position) end)
	end
	-- One refresh per second expires temporary speed without multiplying the permanent pass.
	task.spawn(function() while true do task.wait(1);for _,player in Players:GetPlayers() do if Data.get(player) then Arena.refreshWalkSpeed(player) end end end end)
end
return Service
