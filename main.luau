-- Nocturnix | Speed GUI

-- ── Services ──────────────────────────────────────────────────────────────────
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer
local Lighting         = game:GetService("Lighting")

-- ── State ─────────────────────────────────────────────────────────────────────
local regularSpeedEnabled = false
local regularSpeed        = 20
local bombSpeedEnabled    = false
local bombSpeed           = 10
local spinEnabled         = false
local spinAngle           = 0
local ladderCheckEnabled  = true
local frozenCheckEnabled  = true
local infiniteJumpEnabled = false
local noclipEnabled       = false

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function hasBomb()
    local char = LocalPlayer.Character
    if not char then return false end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") and string.lower(v.Name):find("bomb") then return true end
    end
    return false
end

local function isOnLadder(hum)
    return hum:GetState() == Enum.HumanoidStateType.Climbing
end

-- ── Lighting data ─────────────────────────────────────────────────────────────
local origLight = {}
pcall(function()
    origLight = {
        Brightness     = Lighting.Brightness,
        Ambient        = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        FogEnd         = Lighting.FogEnd,
        FogStart       = Lighting.FogStart,
        FogColor       = Lighting.FogColor,
        ClockTime      = Lighting.ClockTime,
    }
end)
for _, v in ipairs(Lighting:GetChildren()) do
    if v:IsA("PostEffect") then origLight["fx_"..v.Name] = v.Enabled end
end

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

local function applyLightingPreset(preset)
    if not preset then return end
    pcall(function() Lighting.Brightness     = preset.brightness end)
    pcall(function() Lighting.Ambient        = Color3.fromRGB(table.unpack(preset.ambient)) end)
    pcall(function() Lighting.OutdoorAmbient = Color3.fromRGB(table.unpack(preset.outdoor)) end)
    pcall(function() Lighting.FogEnd         = preset.fog end)
    pcall(function() Lighting.FogColor       = Color3.fromRGB(table.unpack(preset.fogcol)) end)
    pcall(function() Lighting.ClockTime      = preset.clock end)
end

local function resetLighting()
    if not origLight.Brightness then return end
    pcall(function() Lighting.Brightness     = origLight.Brightness     end)
    pcall(function() Lighting.Ambient        = origLight.Ambient        end)
    pcall(function() Lighting.OutdoorAmbient = origLight.OutdoorAmbient end)
    pcall(function() Lighting.FogEnd         = origLight.FogEnd         end)
    pcall(function() Lighting.FogStart       = origLight.FogStart       end)
    pcall(function() Lighting.FogColor       = origLight.FogColor       end)
    pcall(function() Lighting.ClockTime      = origLight.ClockTime      end)
    for _, v in ipairs(Lighting:GetChildren()) do
        local key = "fx_"..v.Name
        if v:IsA("PostEffect") and origLight[key] ~= nil then
            pcall(function() v.Enabled = origLight[key] end)
        end
    end
end

-- ── FPS improvements ──────────────────────────────────────────────────────────
local storedParticles = {}
local storedLights    = {}
local storedPostFX    = {}
local storedMaterials = {}

local function setNoParticles(on)
    if on then
        for _, v in ipairs(workspace:GetDescendants()) do
            if (v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles")) and v.Enabled then
                storedParticles[v] = true; v.Enabled = false
            end
        end
    else
        for v in pairs(storedParticles) do pcall(function() v.Enabled = true end) end
        storedParticles = {}
    end
end

local function setNoLights(on)
    if on then
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then
                storedLights[v] = v.Brightness; v.Brightness = 0
            end
        end
    else
        for v, b in pairs(storedLights) do pcall(function() v.Brightness = b end) end
        storedLights = {}
    end
end

local function setNoPostFX(on)
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") then
            if on then storedPostFX[v] = v.Enabled; v.Enabled = false
            elseif storedPostFX[v] ~= nil then pcall(function() v.Enabled = storedPostFX[v] end) end
        end
    end
    if not on then storedPostFX = {} end
end

local function setPlasticMats(on)
    if on then
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and v.Material ~= Enum.Material.SmoothPlastic then
                storedMaterials[v] = v.Material; v.Material = Enum.Material.SmoothPlastic
            end
        end
    else
        for v, m in pairs(storedMaterials) do pcall(function() v.Material = m end) end
        storedMaterials = {}
    end
end

local function setLowGraphics(on)
    setNoParticles(on); setNoLights(on); setNoPostFX(on); setPlasticMats(on)
end

-- ── HUD (always visible, not hidden by Insert) ────────────────────────────────
local HudGui = Instance.new("ScreenGui")
HudGui.Enabled = true
HudGui.Parent  = CoreGui

local HUDFrame = Instance.new("Frame")
HUDFrame.Size                   = UDim2.new(0, 110, 0, 10)
HUDFrame.Position               = UDim2.new(0, 5, 0.5, -40)
HUDFrame.BackgroundColor3       = Color3.fromRGB(15, 15, 15)
HUDFrame.BackgroundTransparency = 0.35
HUDFrame.BorderSizePixel        = 0
HUDFrame.Parent                 = HudGui
Instance.new("UICorner", HUDFrame).CornerRadius = UDim.new(0, 6)

local hudLabels = {}

local HUD_FEATURES = {
    {k="regularSpeed", l="Speed"},
    {k="bombSpeed",    l="Bomb Spd"},
    {k="spinBot",      l="Spin Bot"},
    {k="infiniteJump", l="Inf Jump"},
    {k="noclip",       l="Noclip"},
}

local function getEnabled(k)
    if k=="regularSpeed"  then return regularSpeedEnabled  end
    if k=="bombSpeed"     then return bombSpeedEnabled     end
    if k=="spinBot"       then return spinEnabled          end
    if k=="infiniteJump"  then return infiniteJumpEnabled  end
    if k=="noclip"        then return noclipEnabled        end
    return false
end

local function updateHUD()
    for i, feat in ipairs(HUD_FEATURES) do
        if not hudLabels[i] then
            local l = Instance.new("TextLabel")
            l.TextSize               = 11
            l.Font                   = Enum.Font.Gotham
            l.BackgroundTransparency = 1
            l.BorderSizePixel        = 0
            l.Size                   = UDim2.new(1, -8, 0, 15)
            l.Position               = UDim2.new(0, 4, 0, 4 + (i-1)*16)
            l.TextXAlignment         = Enum.TextXAlignment.Left
            l.Parent                 = HUDFrame
            hudLabels[i] = l
        end
        local enabled = getEnabled(feat.k)
        hudLabels[i].Text       = feat.l .. ": " .. (enabled and "ON" or "OFF")
        hudLabels[i].TextColor3 = enabled and Color3.fromRGB(100, 255, 120) or Color3.fromRGB(160, 160, 160)
    end
    HUDFrame.Size = UDim2.new(0, 110, 0, 8 + #HUD_FEATURES * 16)
end

updateHUD()

-- ── Load UI Library ───────────────────────────────────────────────────────────
local function safeloadstring(url)
    local ok, code = pcall(game.HttpGet, game, url)
    if not ok then warn("HttpGet failed: " .. tostring(code)); return nil end
    local fn, err = loadstring(code)
    if not fn then warn("loadstring failed: " .. tostring(err)); return nil end
    return fn()
end

local UILibrary = safeloadstring("https://raw.githubusercontent.com/SugaBlaz/UI-Library/refs/heads/main/Orbital%20UI.lua")
if not UILibrary then return end

local ui = UILibrary.Main.new({
    TitleText         = "Nocturnix",
    Size              = UDim2.new(0, 220, 0, 420),
    Position          = UDim2.new(0.5, -110, 0.4, -210),
    SettingSize       = UDim2.new(0, 220, 0, 250),
    TitleHeight       = 30,
    CornerRadius      = 6,
    ElementPadding    = 5,
    Font              = Enum.Font.GothamBold,
    TextSize          = 12,
    SectionHeight     = 20,
    UIStrokeThickness = 1,
    SliderColor       = Color3.fromRGB(54, 54, 54),
    NotifcationSound  = "rbxassetid://80833448337193",
    ResetOnSpawn      = false,
    Addons            = {},
    KeySystemEnabled  = false,
    TabPadding        = 10,
    UseOwnTheme       = false,
    Theme             = "Midnight",
    SaveOnExit        = true,
})

ui:CreateUI()

-- ── Speed ─────────────────────────────────────────────────────────────────────
ui:AddSection("Speed")

local speedToggle = ui:AddToggle({
    Text          = "Speed",
    Default       = false,
    Flag          = "SpeedEnabled",
    SavingEnabled = true,
    Callback      = function(state)
        regularSpeedEnabled = state
        updateHUD()
    end,
})

ui:AddSlider({
    Text          = "Speed Value",
    Default       = 20,
    Min           = 1,
    Max           = 100,
    Flag          = "SpeedVal",
    SavingEnabled = true,
    Callback      = function(v) regularSpeed = v end,
})

local spinToggle = ui:AddToggle({
    Text          = "Spin Bot",
    Default       = false,
    Flag          = "SpinEnabled",
    SavingEnabled = true,
    Callback      = function(state)
        spinEnabled = state
        if not state then spinAngle = 0 end
        updateHUD()
    end,
})

ui:AddSeparator()

-- ── Bomb ──────────────────────────────────────────────────────────────────────
ui:AddSection("Bomb")

local bombToggle = ui:AddToggle({
    Text          = "Bomb Speed",
    Default       = false,
    Flag          = "BombEnabled",
    SavingEnabled = true,
    Callback      = function(state)
        bombSpeedEnabled = state
        updateHUD()
    end,
})

ui:AddSlider({
    Text          = "Bomb Speed Value",
    Default       = 10,
    Min           = 1,
    Max           = 100,
    Flag          = "BombVal",
    SavingEnabled = true,
    Callback      = function(v) bombSpeed = v end,
})

ui:AddSeparator()

-- ── Settings ──────────────────────────────────────────────────────────────────
ui:AddSection("Settings")

ui:AddToggle({
    Text          = "Ladder Check",
    Default       = true,
    Flag          = "LadderCheck",
    SavingEnabled = true,
    Callback      = function(state) ladderCheckEnabled = state end,
})

ui:AddToggle({
    Text          = "Frozen Check",
    Default       = true,
    Flag          = "FrozenCheck",
    SavingEnabled = true,
    Callback      = function(state) frozenCheckEnabled = state end,
})

local infJumpToggle = ui:AddToggle({
    Text          = "Infinite Jump",
    Default       = false,
    Flag          = "InfJump",
    SavingEnabled = true,
    Callback      = function(state)
        infiniteJumpEnabled = state
        updateHUD()
    end,
})

local noclipToggle = ui:AddToggle({
    Text          = "Noclip",
    Default       = false,
    Flag          = "NoclipEnabled",
    SavingEnabled = true,
    Callback      = function(state)
        noclipEnabled = state
        if not state then
            local char = LocalPlayer.Character
            if char then
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then v.CanCollide = true end
                end
            end
        end
        updateHUD()
    end,
})

ui:AddSeparator()

-- ── Keybinds ──────────────────────────────────────────────────────────────────
ui:AddSection("Keybinds")

ui:AddKeybind({
    Text            = "Speed",
    Default         = Enum.KeyCode.Unknown,
    Flag            = "SpeedKey",
    SavingEnabled   = true,
    Callback        = function() speedToggle:Set(not regularSpeedEnabled) end,
    ChangedCallback = function() end,
})

ui:AddKeybind({
    Text            = "Bomb Speed",
    Default         = Enum.KeyCode.Unknown,
    Flag            = "BombKey",
    SavingEnabled   = true,
    Callback        = function() bombToggle:Set(not bombSpeedEnabled) end,
    ChangedCallback = function() end,
})

ui:AddKeybind({
    Text            = "Spin Bot",
    Default         = Enum.KeyCode.Unknown,
    Flag            = "SpinKey",
    SavingEnabled   = true,
    Callback        = function() spinToggle:Set(not spinEnabled) end,
    ChangedCallback = function() end,
})

ui:AddKeybind({
    Text            = "Infinite Jump",
    Default         = Enum.KeyCode.Unknown,
    Flag            = "InfJumpKey",
    SavingEnabled   = true,
    Callback        = function() infJumpToggle:Set(not infiniteJumpEnabled) end,
    ChangedCallback = function() end,
})

ui:AddKeybind({
    Text            = "Noclip",
    Default         = Enum.KeyCode.Unknown,
    Flag            = "NoclipKey",
    SavingEnabled   = true,
    Callback        = function() noclipToggle:Set(not noclipEnabled) end,
    ChangedCallback = function() end,
})

ui:AddSeparator()

-- ── Visuals: Scenes ───────────────────────────────────────────────────────────
ui:AddSection("Visuals: Scenes")

ui:AddDropdown({
    Text          = "Scene",
    Default       = "None",
    Options       = {"None","Ultra Realism","Golden Valley","Rainy Night","Neon City","Frostbite","Cinematic","Blood Moon","Silent Fog"},
    Flag          = "ScenePreset",
    SavingEnabled = false,
    Callback      = function(opt)
        if opt == "None" then resetLighting()
        else applyLightingPreset(SCENE_PRESETS[opt]) end
    end,
})

-- ── Visuals: Weather ──────────────────────────────────────────────────────────
ui:AddSection("Visuals: Weather")

ui:AddDropdown({
    Text          = "Weather",
    Default       = "None",
    Options       = {"None","Clear","Cloudy","Foggy","Rainy","Stormy","Sunrise","Blizzard","Firefly"},
    Flag          = "WeatherPreset",
    SavingEnabled = false,
    Callback      = function(opt)
        if opt == "None" then resetLighting()
        else applyLightingPreset(WEATHER_PRESETS[opt]) end
    end,
})

-- ── FPS ───────────────────────────────────────────────────────────────────────
ui:AddSection("FPS")

ui:AddToggle({ Text="No Particles",  Default=false, Flag="NoParticles",  SavingEnabled=false, Callback=function(s) setNoParticles(s)  end })
ui:AddToggle({ Text="No Map Lights", Default=false, Flag="NoLights",     SavingEnabled=false, Callback=function(s) setNoLights(s)     end })
ui:AddToggle({ Text="No Post FX",    Default=false, Flag="NoPostFX",     SavingEnabled=false, Callback=function(s) setNoPostFX(s)     end })
ui:AddToggle({ Text="Plastic Mats",  Default=false, Flag="PlasticMats",  SavingEnabled=false, Callback=function(s) setPlasticMats(s)  end })
ui:AddToggle({ Text="Low Graphics",  Default=false, Flag="LowGraphics",  SavingEnabled=false, Callback=function(s) setLowGraphics(s)  end })

-- ── Insert toggles GUI ────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Insert then
        ui:ToggleGuiVisibility()
    end
end)

-- ── Infinite jump ─────────────────────────────────────────────────────────────
UserInputService.JumpRequest:Connect(function()
    if not infiniteJumpEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- ── RenderStepped — speed / spin ──────────────────────────────────────────────
RunService.RenderStepped:Connect(function(dt)
    local char = LocalPlayer.Character
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

-- ── Heartbeat — noclip ───────────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not noclipEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            v.CanCollide = false
        end
    end
end)
