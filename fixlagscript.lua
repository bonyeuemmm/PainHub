local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level04

pcall(function()
    settings().Rendering.EnableFRM = false
    if sethiddenproperty then
        sethiddenproperty(Lighting, "Technology", Enum.Technology.Compatibility)
        sethiddenproperty(Lighting, "GlobalShadows", false)
    end
end)

Lighting.GlobalShadows = false
Lighting.FogEnd = 9e9
Lighting.Brightness = 1

for _, effect in pairs(Lighting:GetDescendants()) do
    if effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("BloomEffect") or effect:IsA("DepthOfFieldEffect") then
        effect:Destroy()
    end
end

local function NukeVisuals(obj)
    if obj:IsA("BasePart") and not obj:IsA("MeshPart") then
        obj.Material = Enum.Material.SmoothPlastic
        obj.Reflectance = 0
        obj.CastShadow = false
    elseif obj:IsA("MeshPart") then
        obj.Material = Enum.Material.SmoothPlastic
        obj.Reflectance = 0
        obj.CastShadow = false
        obj.TextureID = ""
    elseif obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("Trail") or obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
        obj:Destroy()
    elseif obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") or obj:IsA("CharacterMesh") then
        obj:Destroy()
    end
end

for _, obj in pairs(game:GetDescendants()) do
    pcall(function() NukeVisuals(obj) end)
end

game.DescendantAdded:Connect(function(obj)
    pcall(function() NukeVisuals(obj) end)
end)

Workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Animator") then
        pcall(function() obj:Destroy() end)
    end
end)
