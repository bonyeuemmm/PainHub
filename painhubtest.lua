"local SCRIPT_NAME = "Pain Hub"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

getgenv().Config = {
    AutoFarmFruit = false,
    AutoFarmMob = false,
    AutoFarmBoss = false,
    AutoUpV4 = false,
    AutoLeviathan = false,
    AutoAttack = false,
    SelectedBoss = "Gorilla King",
    SelectedIsland = "Dragon Island",
    FarmDistance = 5,
    AttackSpeed = 0.15,
    TweenSpeed = 100
}

local Bosses = {
    ["Gorilla King"] = {CFrame = CFrame.new(-1223, 6, -502)},
    ["The Saw"] = {CFrame = CFrame.new(-677, 8, 316)},
    ["Diamond"] = {CFrame = CFrame.new(-424, 73, 183)},
    ["Jeremy"] = {CFrame = CFrame.new(2154, 449, -1924)},
    ["Fajita"] = {CFrame = CFrame.new(-2101, 73, -3321)},
    ["Don Swan"] = {CFrame = CFrame.new(2288, 15, 731)},
    ["Tide Keeper"] = {CFrame = CFrame.new(-3570, 123, -11555)},
    ["Rip Indra"] = {CFrame = CFrame.new(5230, 602, 195)}
}

local Islands = {
    ["Dragon Island"] = {CFrame = CFrame.new(5230, 602, 195)},
    ["Kitsune Island"] = {Dynamic = true},
    ["Mirage Island"] = {Dynamic = true},
    ["Great Tree"] = {CFrame = CFrame.new(-5078, 315, -3150)},
    ["Temple of Time"] = {CFrame = CFrame.new(28575, 1500, -3500)}
}

local function GetClosestFruit()
    local closest, dist = nil, math.huge
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Tool") and obj.Name:find("Fruit") and obj:FindFirstChild("Handle") then
            local d = (HumanoidRootPart.Position - obj.Handle.Position).Magnitude
            if d < dist then closest, dist = obj, d end
        end
    end
    return closest
end
local function GetBoss(name)
    for _, enemy in pairs(workspace.Enemies:GetChildren()) do
        if enemy.Name == name and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
            return enemy
        end
    end
    return nil
end

local function GetDynamicModel(name)
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name == name and obj:IsA("Model") then return obj end
    end
    return nil
end

local function TeleportTo(cframe)
    local dist = (HumanoidRootPart.Position - cframe.Position).Magnitude
    local tween = TweenService:Create(HumanoidRootPart, TweenInfo.new(dist / getgenv().Config.TweenSpeed), {CFrame = cframe})
    tween:Play()
    tween.Completed:Wait()
end

local function AutoAttack(target)
    if target and target:FindFirstChild("HumanoidRootPart") and getgenv().Config.AutoAttack then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new())
    end
end

local function StoreFruit(fruit)
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("StoreFruit", fruit.Name, fruit)
    end)
end

local function AutoUpV4()
    local mirror = Player.Backpack:FindFirstChild("Mirror Fractal")
    if not mirror then return end
    
    local mirage = GetDynamicModel("Mirage Island")
    if mirage then
        TeleportTo(mirage:FindFirstChild("HumanoidRootPart").CFrame * CFrame.new(0, 50, 0))
        Humanoid:EquipTool(mirror)
        wait(2)
        local gear = mirage:FindFirstChild("Blue Gear")
        if gear then TeleportTo(gear.CFrame) end
    else
        TeleportTo(CFrame.new(math.random(-10000,10000), 100, math.random(-10000,10000)))
    end
    if Player.Backpack:FindFirstChild("Blue Gear") then
        TeleportTo(Islands["Temple of Time"].CFrame)
    end
end

local function AutoLeviathan()
    TeleportTo(Islands["Great Tree"].CFrame * CFrame.new(0, 50, 0))
    local levi = GetDynamicModel("Leviathan")
    if levi then
        TeleportTo(levi.HumanoidRootPart.CFrame * CFrame.new(0, getgenv().Config.FarmDistance, 0))
        AutoAttack(levi)
    end
end

local function TeleportIsland(name)
    local data = Islands[name]
    if data.Dynamic then
        local model = GetDynamicModel(name)
        if model then
            TeleportTo(model.HumanoidRootPart.CFrame * CFrame.new(0, 50, 0))
        else
            TeleportTo(CFrame.new(math.random(-10000,10000), 100, math.random(-10000,10000)))
        end
    else
        TeleportTo(data.CFrame)
    end
end

spawn(function()
    while true do
        wait(getgenv().Config.AttackSpeed)
        pcall(function()
            local tool = Player.Backpack:FindFirstChildOfClass("Tool")
            if tool then Humanoid:EquipTool(tool) end
        end)
        
        if getgenv().Config.AutoUpV4 then AutoUpV4()
        elseif getgenv().Config.AutoLeviathan then AutoLeviathan()
        elseif getgenv().Config.AutoFarmFruit then
            local fruit = GetClosestFruit()
            if fruit then
                TeleportTo(fruit.Handle.CFrame * CFrame.new(0, getgenv().Config.FarmDistance, 0))
                StoreFruit(fruit)
            end
        elseif getgenv().Config.AutoFarmBoss then
            local bossData = Bosses[getgenv().Config.SelectedBoss]
            local boss = GetBoss(getgenv().Config.SelectedBoss)
            if boss then
                TeleportTo(boss.HumanoidRootPart.CFrame * CFrame.new(0, getgenv().Config.FarmDistance, 0))
                AutoAttack(boss)
            else
                TeleportTo(bossData.CFrame * CFrame.new(0, getgenv().Config.FarmDistance, 0))
            end
        elseif getgenv().Config.AutoFarmMob then
            local mob = GetClosestMob()
            if mob then
                TeleportTo(mob.HumanoidRootPart.CFrame * CFrame.new(0, getgenv().Config.FarmDistance, 0))
                AutoAttack(mob)
            end
        end
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = SCRIPT_NAME .. " GUI"
ScreenGui.Parent = Player.PlayerGui
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 450, 0, 400)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
MainFrame.BorderSizePixel = 3
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.Text = Pain Hub
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local TabFrame = Instance.new("Frame")
TabFrame.Size = UDim2.new(0, 120, 1, -50)
TabFrame.Position = UDim2.new(0, 0, 0, 50)
TabFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TabFrame.Parent = MainFrame

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(0, 330, 1, -50)
ContentFrame.Position = UDim2.new(0, 120, 0, 50)
ContentFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ContentFrame.Parent = MainFrame

local function CreateTabButton(name, posY, tabFrame)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Position = UDim2.new(0, 0, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 16
    btn.Font = Enum.Font.Gotham
    btn.Parent = TabFrame
    btn.MouseButton1Click:Connect(function()
        for _, frame in pairs(ContentFrame:GetChildren()) do
            if frame:IsA("Frame") then frame.Visible = (frame == tabFrame) end
        end
    end)
end

local FarmTab = Instance.new("Frame")
FarmTab.Name = "FarmTab"
FarmTab.Size = UDim2.new(1, 0, 1, 0)
FarmTab.BackgroundTransparency = 1
FarmTab.Visible = true
FarmTab.Parent = ContentFrame

local EventsTab = Instance.new("Frame")
EventsTab.Name = "EventsTab"
EventsTab.Size = UDim2.new(1, 0, 1, 0)
EventsTab.BackgroundTransparency = 1
EventsTab.Visible = false
EventsTab.Parent = ContentFrame

local V4Toggle = Instance.new("TextButton")
V4Toggle.Size = UDim2.new(0, 250, 0, 40)
V4Toggle.Position = UDim2.new(0, 40, 0, 20)
V4Toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
V4Toggle.Text = "Auto Up V4: OFF"
V4Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
V4Toggle.TextSize = 16
V4Toggle.Font = Enum.Font.Gotham
V4Toggle.Parent = EventsTab
V4Toggle.MouseButton1Click:Connect(function()
    getgenv().Config.AutoUpV4 = not getgenv().Config.AutoUpV4
    V4Toggle.Text = "Auto Up V4: " .. (getgenv().Config.AutoUpV4 and "ON" or "OFF")
end)

local LeviToggle = Instance.new("TextButton")
LeviToggle.Size = UDim2.new(0, 250, 0, 40)
LeviToggle.Position = UDim2.new(0, 40, 0, 70)
LeviToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
LeviToggle.Text = "Auto Leviathan: OFF"
LeviToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
LeviToggle.TextSize = 16
LeviToggle.Font = Enum.Font.Gotham
LeviToggle.Parent = EventsTab
LeviToggle.MouseButton1Click:Connect(function()
    getgenv().Config.AutoLeviathan = not getgenv().Config.AutoLeviathan
    LeviToggle.Text = "Auto Leviathan: " .. (getgenv().Config.AutoLeviathan and "ON" or "OFF")
end)

local TeleportTab = Instance.new("Frame")
TeleportTab.Name = "TeleportTab"
TeleportTab.Size = UDim2.new(1, 0, 1, 0)
TeleportTab.BackgroundTransparency = 1
TeleportTab.Visible = false
TeleportTab.Parent = ContentFrame

local IslandBtn = Instance.new("TextButton")
IslandBtn.Size = UDim2.new(0, 250, 0, 40)
IslandBtn.Position = UDim2.new(0, 40, 0, 20)
IslandBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
IslandBtn.Text = "Teleport Dragon Island"
IslandBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
IslandBtn.TextSize = 16
IslandBtn.Font = Enum.Font.Gotham
IslandBtn.Parent = TeleportTab
IslandBtn.MouseButton1Click:Connect(function()
    TeleportIsland("Dragon Island")
end)

CreateTabButton("Farm", 0, FarmTab)
CreateTabButton("Events", 40, EventsTab)
CreateTabButton("Teleport", 80, TeleportTab)

local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)

RunService.RenderStepped:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

print(SCRIPT_NAME .. " Loaded Successfully!")
print("Full functions: V4, Leviathan, Dragon/Kitsune Islands ready.")"