--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local InputController = {}

local function setupCharacter(char: Model)
	local humanoid = char:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then
		return
	end
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
end

function InputController.start()
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	local player = Players.LocalPlayer
	player.CharacterAdded:Connect(setupCharacter)
	if player.Character then
		task.spawn(setupCharacter, player.Character)
	end
end

return InputController
