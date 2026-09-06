local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ScreenGui = Instance.new("ScreenGui")
local ToggleButton = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "FlyGui"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ToggleButton.Position = UDim2.new(0.05, 0, 0.2, 0)
ToggleButton.Size = UDim2.new(0, 100, 0, 50)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "FLY: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 18.000

UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = ToggleButton

local isFlying = false
local flySpeed = 50
local bodyVelocity = nil
local bodyGyro = nil
local renderConnection = nil

local function getControls()
	local PlayerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
	if PlayerScripts then
		local PlayerModule = PlayerScripts:FindFirstChild("PlayerModule")
		if PlayerModule then
			return require(PlayerModule):GetControls()
		end
	end
	return nil
end

local function stopFlying()
	isFlying = false
	ToggleButton.Text = "FLY: OFF"
	ToggleButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)

	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end

	if bodyGyro then
		bodyGyro:Destroy()
		bodyGyro = nil
	end

	local character = LocalPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.PlatformStand = false
		end
	end
end

local function startFlying()
	local character = LocalPlayer.Character
	if not character then return end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then return end

	local controls = getControls()

	isFlying = true
	ToggleButton.Text = "FLY: ON"
	ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)

	humanoid.PlatformStand = true

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = hrp

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	bodyGyro.P = 9e4
	bodyGyro.CFrame = Camera.CFrame
	bodyGyro.Parent = hrp

	renderConnection = RunService.RenderStepped:Connect(function()
		if not isFlying or not character or not hrp or not humanoid then
			stopFlying()
			return
		end

		humanoid.PlatformStand = true
		
		local moveVector = Vector3.zero
		if controls then
			moveVector = controls:GetMoveVector()
		end

		local camCFrame = Camera.CFrame
		local flyDir = (camCFrame.LookVector * -moveVector.Z) + (camCFrame.RightVector * moveVector.X)
		
		if flyDir.Magnitude > 0 then
			bodyVelocity.Velocity = flyDir.Unit * flySpeed
		else
			bodyVelocity.Velocity = Vector3.zero
		end

		bodyGyro.CFrame = camCFrame
	end)
end

ToggleButton.MouseButton1Click:Connect(function()
	if isFlying then
		stopFlying()
	else
		startFlying()
	end
end)

LocalPlayer.CharacterAdded:Connect(function()
	stopFlying()
end)
	ToggleButton.Text = "FLY: OFF"
	ToggleButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)

	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end

	if bodyGyro then
		bodyGyro:Destroy()
		bodyGyro = nil
	end

	local character = LocalPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.PlatformStand = false
		end
	end
end

local function startFlying()
	local character = LocalPlayer.Character
	if not character then return end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then return end

	isFlying = true
	ToggleButton.Text = "FLY: ON"
	ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)

	humanoid.PlatformStand = true

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = hrp

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	bodyGyro.P = 9e4
	bodyGyro.CFrame = hrp.CFrame
	bodyGyro.Parent = hrp

	renderConnection = RunService.RenderStepped:Connect(function()
		if not isFlying or not character or not hrp or not humanoid then
			stopFlying()
			return
		end

		humanoid.PlatformStand = true

		local moveVector = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			moveVector = moveVector + Camera.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			moveVector = moveVector - Camera.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			moveVector = moveVector - Camera.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			moveVector = moveVector + Camera.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			moveVector = moveVector + Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
			moveVector = moveVector - Vector3.new(0, 1, 0)
		end

		if moveVector.Magnitude > 0 then
			bodyVelocity.Velocity = moveVector.Unit * flySpeed
		else
			bodyVelocity.Velocity = Vector3.zero
		end

		bodyGyro.CFrame = Camera.CFrame
	end)
end

ToggleButton.MouseButton1Click:Connect(function()
	if isFlying then
		stopFlying()
	else
		startFlying()
	end
end)

LocalPlayer.CharacterAdded:Connect(function()
	stopFlying()
end
