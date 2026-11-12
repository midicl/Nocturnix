-- Services
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local Lighting    = game:GetService("Lighting")
local CoreGui     = game:GetService("CoreGui")
local LP          = Players.LocalPlayer

-- State
local regularSpeedEnabled = false
local regularSpeed        = 20
local bombSpeedEnabled    = false
local bombSpeed           = 25
local spinEnabled         = false
local spinAngle           = 0
local ladderCheckEnabled  = true
local frozenCheckEnabled  = true
local infiniteJumpEnabled = false
local noclipEnabled       = false

-- Capture original lighting
local origLight = {
    Brightness     = Lighting.Brightness,
    Ambient        = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd         = Lighting.FogEnd,
    FogColor       = Lighting.FogColor,
    ClockTime      = Lighting.ClockTime,
}

-- Helpers
local function hasBomb()
    local char = LP.Character
    if not char then return false end
    return char:FindFirstChild("bomb") ~= nil or char:FindFirstChild("Bomb") ~= nil
end

local function isOnLadder(hum)
    return hum:GetState() == Enum.HumanoidStateType.Climbing
end

-- Lighting presets
local SCENE_PRESETS = {
    ["Ultra Realism"] = {brightness=3,   ambient={80,80,95},    outdoor={100,100,120}, fog=2000, fogcol={180,190,210}, clock=14},
    ["Golden Valley"] = {brightness=4,   ambient={180,150,80},  outdoor={200,170,90},  fog=3000, fogcol={255,230,150}, clock=17},
    ["Rainy Night"]   = {brightness=0.3, ambient={50,60,80},    outdoor={40,50,70},    fog=200,  fogcol={90,100,120},  clock=22},
    ["Neon City"]     = {brightness=0.5, ambient={0,80,160},    outdoor={20,60,120},   fog=5000, fogcol={20,30,80},    clock=0},
    ["Frostbite"]     = {brightness=1.5, ambient={180,210,230}, outdoor={200,220,240}, fog=500,  fogcol={200,220,240}, clock=10},
    ["Cinematic"]     = {brightness=1.8, ambient={80,70,70},    outdoor={90,80,80},    fog=5000, fogcol={150,140,140}, clock=14},
    ["Blood Moon"]    = {brightness=0.8, ambient={120,20,20},   outdoor={100,20,20},   fog=800,  fogcol={150,50,50},   clock=23},
    ["Silent Fog"]    = {brightness=1,   ambient={120,120,120}, outdoor={130,130,130}, fog=80,   fogcol={200,200,200}, clock=12},
}

local WEATHER_PRESETS = {
    ["Clear"]    = {brightness=2,   ambient={127,127,127}, outdoor={127,127,127}, fog=1e6,  fogcol={192,192,192}, clock=14},
    ["Cloudy"]   = {brightness=1.2, ambient={100,100,110}, outdoor={110,110,120}, fog=3000, fogcol={160,160,170}, clock=13},
    ["Foggy"]    = {brightness=1,   ambient={130,130,140}, outdoor={140,140,150}, fog=150,  fogcol={180,185,190}, clock=12},
    ["Rainy"]    = {brightness=0.4, ambient={60,65,75},    outdoor={50,55,65},    fog=400,  fogcol={80,85,95},    clock=11},
    ["Stormy"]   = {brightness=0.2, ambient={40,40,50},    outdoor={30,30,40},    fog=200,  fogcol={60,60,70},    clock=20},
    ["Sunrise"]  = {brightness=3,   ambient={180,120,80},  outdoor={200,140,90},  fog=4000, fogcol={255,200,150}, clock=7},
    ["Blizzard"] = {brightness=0.8, ambient={200,210,220}, outdoor={210,220,230}, fog=80,   fogcol={220,230,235}, clock=11},
    ["Firefly"]  = {brightness=0.3, ambient={30,50,20},    outdoor={20,40,15},    fog=2000, fogcol={40,60,30},    clock=22},
}

local function applyLightingPreset(p)
    Lighting.Brightness     = p.brightness
    Lighting.Ambient        = Color3.fromRGB(unpack(p.ambient))
    Lighting.OutdoorAmbient = Color3.fromRGB(unpack(p.outdoor))
    Lighting.FogEnd         = p.fog
    Lighting.FogColor       = Color3.fromRGB(unpack(p.fogcol))
    Lighting.ClockTime      = p.clock
end

local function resetLighting()
    Lighting.Brightness     = origLight.Brightness
    Lighting.Ambient        = origLight.Ambient
    Lighting.OutdoorAmbient = origLight.OutdoorAmbient
    Lighting.FogEnd         = origLight.FogEnd
    Lighting.FogColor       = origLight.FogColor
    Lighting.ClockTime      = origLight.ClockTime
end

-- FPS funcs
local function setNoParticles(v)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail")
        or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Fire") then
            obj.Enabled = not v
        end
    end
end

local function setNoLights(v)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            obj.Enabled = not v
        end
    end
end

local function setNoPostFX(v)
    for _, obj in ipairs(Lighting:GetDescendants()) do
        if obj:IsA("PostEffect") then
            obj.Enabled = not v
        end
    end
end

local function setLowGraphics(v)
    local char = LP.Character
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not (char and obj:IsDescendantOf(char)) then
            if v then obj.Material = Enum.Material.Plastic end
        end
    end
end

-- HUD
local HudGui = Instance.new("ScreenGui")
HudGui.Name = "NocturnixHUD"
HudGui.ResetOnSpawn = false
HudGui.Parent = CoreGui

local HUDFrame = Instance.new("Frame")
HUDFrame.Size = UDim2.new(0, 110, 0, 10)
HUDFrame.Position = UDim2.new(0, 5, 0.5, -40)
HUDFrame.BackgroundTransparency = 1
HUDFrame.Parent = HudGui

local HUDList = Instance.new("UIListLayout")
HUDList.SortOrder = Enum.SortOrder.LayoutOrder
HUDList.Padding = UDim.new(0, 2)
HUDList.Parent = HUDFrame

local HUD_FEATURES = {
    {k="regularSpeed", l="Speed"},
    {k="bombSpeed",    l="Bomb Spd"},
    {k="spinBot",      l="Spin Bot"},
    {k="infiniteJump", l="Inf Jump"},
    {k="noclip",       l="Noclip"},
}

local hudLabels = {}
for i, feat in ipairs(HUD_FEATURES) do
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 110, 0, 14)
    lbl.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    lbl.BackgroundTransparency = 0.3
    lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 10
    lbl.Text = feat.l .. ": OFF"
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = i
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 4)
    pad.Parent = lbl
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 2)
    corner.Parent = lbl
    lbl.Parent = HUDFrame
    hudLabels[feat.k] = lbl
end

local HUD_LABEL_MAP = {
    regularSpeed = "Speed",
    bombSpeed    = "Bomb Spd",
    spinBot      = "Spin Bot",
    infiniteJump = "Inf Jump",
    noclip       = "Noclip",
}

local function updateHUD()
    local states = {
        regularSpeed = regularSpeedEnabled,
        bombSpeed    = bombSpeedEnabled,
        spinBot      = spinEnabled,
        infiniteJump = infiniteJumpEnabled,
        noclip       = noclipEnabled,
    }
    for k, lbl in pairs(hudLabels) do
        local on = states[k]
        lbl.Text = HUD_LABEL_MAP[k] .. ": " .. (on and "ON" or "OFF")
        lbl.TextColor3 = on
            and Color3.fromRGB(100, 220, 100)
            or  Color3.fromRGB(180, 180, 180)
    end
end

-- Load Orion
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/OrionLibrary/Orion/main/source"))()
local Window = OrionLib:CreateOrion("Nocturnix")

-- Speed tab
local SpeedTab = Window:CreateSection("Speed")

SpeedTab:Toggle("Speed", function(v)
    regularSpeedEnabled = v
    updateHUD()
end)

SpeedTab:Slider("Speed Value", 10, 200, function(v)
    regularSpeed = v
end)

SpeedTab:Toggle("Bomb Speed", function(v)
    bombSpeedEnabled = v
    updateHUD()
end)

SpeedTab:Slider("Bomb Speed Value", 10, 200, function(v)
    bombSpeed = v
end)

SpeedTab:Toggle("Spin Bot", function(v)
    spinEnabled = v
    if not v then spinAngle = 0 end
    updateHUD()
end)

-- Combat tab
local CombatTab = Window:CreateSection("Combat")

CombatTab:Toggle("Infinite Jump", function(v)
    infiniteJumpEnabled = v
    updateHUD()
end)

CombatTab:Toggle("Noclip", function(v)
    noclipEnabled = v
    updateHUD()
end)

-- Settings tab
local SettingsTab = Window:CreateSection("Settings")

SettingsTab:Toggle("Frozen Check", function(v)
    frozenCheckEnabled = v
end)

SettingsTab:Toggle("Ladder Check", function(v)
    ladderCheckEnabled = v
end)

-- Visuals tab
local VisualsTab = Window:CreateSection("Visuals")

VisualsTab:Dropdown("Scene", {
    "None","Ultra Realism","Golden Valley","Rainy Night",
    "Neon City","Frostbite","Cinematic","Blood Moon","Silent Fog"
}, function(v)
    if v == "None" then resetLighting() else
        local p = SCENE_PRESETS[v]
        if p then applyLightingPreset(p) end
    end
end)

VisualsTab:Dropdown("Weather", {
    "None","Clear","Cloudy","Foggy","Rainy","Stormy","Sunrise","Blizzard","Firefly"
}, function(v)
    if v == "None" then resetLighting() else
        local p = WEATHER_PRESETS[v]
        if p then applyLightingPreset(p) end
    end
end)

VisualsTab:Toggle("No Particles", function(v) setNoParticles(v) end)
VisualsTab:Toggle("No Lights",    function(v) setNoLights(v)    end)
VisualsTab:Toggle("No PostFX",    function(v) setNoPostFX(v)    end)
VisualsTab:Toggle("Low Graphics", function(v) setLowGraphics(v) end)

-- Auto-select first tab
task.defer(function()
    for _, desc in ipairs(CoreGui:GetDescendants()) do
        if desc:IsA("TextButton") and desc.Name:sub(1, 6) == "tabBtn" then
            desc.MouseButton1Click:Fire()
            return
        end
    end
end)

-- Infinite jump
UIS.JumpRequest:Connect(function()
    if not infiniteJumpEnabled then return end
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Noclip
RunService.Heartbeat:Connect(function()
    if not noclipEnabled then return end
    local char = LP.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.CanCollide = false
        end
    end
end)

-- Speed / spin
RunService.RenderStepped:Connect(function(dt)
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    if frozenCheckEnabled then
        if hrp.Anchored then return end
        if hum.PlatformStand then return end
        for _, v in ipairs(hrp:GetChildren()) do
            if v:IsA("BodyPosition") or v:IsA("BodyVelocity") then return end
        end
    end

    if ladderCheckEnabled and isOnLadder(hum) then return end

    local dir   = hum.MoveDirection
    local speed = 0
    if hasBomb() then
        if bombSpeedEnabled then speed = bombSpeed end
    elseif regularSpeedEnabled then
        speed = regularSpeed
    end

    local newCF = hrp.CFrame
    if speed > 0 and dir.Magnitude > 0 then
        newCF = newCF + dir * speed * dt
    end
    if spinEnabled then
        spinAngle = (spinAngle + 20 * dt) % (2 * math.pi)
        newCF = CFrame.new(newCF.Position) * CFrame.Angles(0, spinAngle, 0)
    end
    if newCF ~= hrp.CFrame then hrp.CFrame = newCF end
end)
