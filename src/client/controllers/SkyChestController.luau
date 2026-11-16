--!strict
local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local MarketplaceService=game:GetService("MarketplaceService")
local Debris=game:GetService("Debris")
local Shared=game:GetService("ReplicatedStorage").Shared
local Def=require(Shared.SkyChest)
local UiKit=require(script.Parent.Parent.ui.UiKit)
local State=require(script.Parent.Parent.ClientState)
local Feedback=require(script.Parent.FeedbackController)
local Celebration=require(script.Parent.Parent.ui.PlaytimeRewards)
local Controller={}
local started=false
function Controller.start()
	if started then return end;started=true
	local panel=UiKit.panel({title="Sky Chest",size=UDim2.fromScale(0.78,0.8)})
	local body=panel.body
	local disk=UiKit.frame({Name="PrizeWheel",Position=UDim2.fromScale(0.04,0.07),Size=UDim2.fromScale(0.53,0.78),BackgroundColor3=Color3.fromHex("C9B7FF"),parent=body})
	UiKit.aspect(disk,1);UiKit.corner(disk,1000);UiKit.stroke(disk,UiKit.theme.UiDark,4)
	for i,p in Def.Prizes do
		local angle=math.rad((i-1)*60-90)
		local slot=UiKit.frame({Name="Prize"..i,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5+math.cos(angle)*0.32,0.5+math.sin(angle)*0.32),Size=UDim2.fromScale(0.3,0.24),BackgroundColor3=if i%2==0 then UiKit.theme.Paper else Color3.fromHex("FFF0B3"),parent=disk})
		UiKit.corner(slot,12)
		UiKit.icon(p.icon,{Position=UDim2.fromScale(0.27,0),Size=UDim2.fromScale(0.46,0.64),parent=slot})
		UiKit.label({Text=p.name,Position=UDim2.fromScale(0.02,0.68),Size=UDim2.fromScale(0.96,0.25),parent=slot})
	end
	local hub=UiKit.frame({AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromScale(0.2,0.2),BackgroundColor3=UiKit.theme.Yellow,parent=disk});UiKit.corner(hub,100);UiKit.stroke(hub)
	UiKit.icon("economy_star",{Size=UDim2.fromScale(1,1),parent=hub})
	UiKit.label({Name="Pointer",Text="▼",Position=UDim2.fromScale(0.24,0),Size=UDim2.fromScale(0.12,0.13),TextColor3=UiKit.theme.Pink,ZIndex=5,parent=body})
	local result=UiKit.label({Text="Your sky-high surprise",Position=UDim2.fromScale(0.6,0.02),Size=UDim2.fromScale(0.37,0.1),parent=body})
	local odds={}
	for _,p in Def.Prizes do table.insert(odds,p.name.." — "..p.weight.."%") end
	UiKit.label({Text=table.concat(odds,"\n").."\n\nOwned skin → 100 gems.\nSpeed lasts 3 min; does not stack\nwith the permanent 2x pass.",TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,Position=UDim2.fromScale(0.61,0.15),Size=UDim2.fromScale(0.36,0.48),parent=body})
	local spins={free=0,paid=0,allowed=false,productId=0}
	local rolling=false
	local purchase:TextButton
	local spin:TextButton
	local function refresh()
		local ok,status=State.request("SkyChest","status")
		if ok then spins=status end
		spin.Text="Spin ("..tostring(spins.free+spins.paid)..")"
		purchase.Visible=spins.allowed and spins.productId>0 and spins.free==0 and not rolling
	end
	spin=UiKit.button({text="Spin",color=UiKit.theme.Yellow,position=UDim2.fromScale(0.61,0.66),size=UDim2.fromScale(0.35,0.12),parent=body,onClick=function()
		if rolling then return end;rolling=true;purchase.Visible=false;spin.Text="Spinning…"
		local ok,reward=State.request("SkyChest","spin")
		if not ok then rolling=false;result.Text=tostring(reward);refresh();return end
		local rotation=disk.Rotation
		local final=rotation+(360-rotation%360)%360+360*5-(reward.index-1)*60
		local t=TweenService:Create(disk,TweenInfo.new(4.4,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Rotation=final});t:Play()
		task.spawn(function() for i=1,20 do if not rolling then break end;Feedback.play("uiClick");task.wait(0.07+i*0.012) end end)
		t.Completed:Wait()
		local prize=Def.Prizes[reward.index]
		result.Text=if reward.duplicate then "Duplicate → 100 gems!" else "You won "..prize.name.."!"
		Feedback.play("questComplete")
		Celebration.celebrate(spin,if reward.duplicate then 100 else prize.amount,if reward.duplicate then "gems" else prize.kind,if prize.kind=="skin" and not reward.duplicate then "Sky Blue unlocked!" elseif prize.kind=="speed" then "2x speed · 3 min!" else nil)
		rolling=false;refresh()
	end})
	purchase=UiKit.button({text="Another spin · 39 Robux",color=UiKit.theme.Gem,position=UDim2.fromScale(0.61,0.82),size=UDim2.fromScale(0.35,0.1),parent=body,onClick=function()
		if rolling then return end
		local ok,id=State.request("SkyChest","purchase")
		if ok then MarketplaceService:PromptProductPurchase(Players.LocalPlayer,id) else result.Text=tostring(id) end
	end});purchase.Visible=false
	local gui=UiKit.screenGui("SkyChestShortcut",11)
	UiKit.button({text="Sky Chest",color=UiKit.theme.Yellow,position=UDim2.fromScale(0.015,0.7),size=UDim2.fromScale(0.12,0.065),parent=gui,onClick=function() panel.show();refresh() end})
	local remote=game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SkyChestEvent") :: RemoteEvent
	remote.OnClientEvent:Connect(function(event)
		if event.kind=="claimed" then Feedback.play("rewardClaim");panel.show();result.Text="You found a free spin!";refresh()
		elseif event.kind=="fall" then UiKit.toast("A sky chest is falling!",UiKit.theme.Yellow)
		elseif event.kind=="land" then
			Feedback.play("bigClaim")
			local low=State.profile and State.profile.settings.lowDetail
			for i=1,if low then 6 else 22 do
				local spark=Instance.new("Part");spark.Shape=Enum.PartType.Ball;spark.Material=Enum.Material.Neon;spark.Color=if i%2==0 then UiKit.theme.Yellow else UiKit.theme.Gem;spark.Size=Vector3.new(0.5,0.5,0.5);spark.Anchored=true;spark.CanCollide=false;spark.CanTouch=false;spark.Position=event.position;spark.Parent=workspace
				local a=i*2.399;TweenService:Create(spark,TweenInfo.new(0.8,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=event.position+Vector3.new(math.cos(a)*14,3+i%5,math.sin(a)*14),Transparency=1,Size=Vector3.new(0.1,0.1,0.1)}):Play();Debris:AddItem(spark,1)
			end
		end
	end)
	State.profileChanged:Connect(function() if panel.isOpen() and not rolling then refresh() end end)
end
return Controller
