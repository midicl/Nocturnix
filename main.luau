-- Services
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Lighting   = game:GetService("Lighting")
local CoreGui    = game:GetService("CoreGui")
local LP         = Players.LocalPlayer

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

-- Original lighting
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

-- ── HUD ───────────────────────────────────────────────────────────────────────
local HudGui = Instance.new("ScreenGui")
HudGui.Name = "NocturnixHUD"
HudGui.ResetOnSpawn = false
HudGui.Parent = CoreGui

local HUDFrame = Instance.new("Frame")
HUDFrame.Size     = UDim2.new(0, 110, 0, 10)
HUDFrame.Position = UDim2.new(0, 5, 0.5, -40)
HUDFrame.BackgroundTransparency = 1
HUDFrame.Parent = HudGui

do
    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding   = UDim.new(0, 2)
    list.Parent    = HUDFrame
end

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
    lbl.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
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
        lbl.TextColor3 = on and Color3.fromRGB(100, 220, 100) or Color3.fromRGB(180, 180, 180)
    end
end

-- ── Main GUI ──────────────────────────────────────────────────────────────────
local GUI = Instance.new("ScreenGui")
GUI.Name = "NocturnixGUI"
GUI.ResetOnSpawn = false
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Parent = CoreGui

local WIN_W, WIN_H = 500, 290

local Window = Instance.new("Frame")
Window.Name     = "Window"
Window.Size     = UDim2.new(0, WIN_W, 0, WIN_H)
Window.Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
Window.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Window.BorderSizePixel  = 0
Window.ClipsDescendants = false
Window.Parent = GUI

local WCorner = Instance.new("UICorner")
WCorner.CornerRadius = UDim.new(0, 7)
WCorner.Parent = Window

-- Title bar
local TBar = Instance.new("Frame")
TBar.Size            = UDim2.new(1, 0, 0, 36)
TBar.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
TBar.BorderSizePixel  = 0
TBar.Parent = Window

local TBCorner = Instance.new("UICorner")
TBCorner.CornerRadius = UDim.new(0, 7)
TBCorner.Parent = TBar

-- Patch rounded corners on bottom of titlebar
local TBPatch = Instance.new("Frame")
TBPatch.Size            = UDim2.new(1, 0, 0, 7)
TBPatch.Position        = UDim2.new(0, 0, 1, -7)
TBPatch.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
TBPatch.BorderSizePixel  = 0
TBPatch.Parent = TBar

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size            = UDim2.new(1, -50, 1, 0)
TitleLbl.Position        = UDim2.new(0, 12, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text            = "Nocturnix"
TitleLbl.TextColor3      = Color3.fromRGB(220, 220, 230)
TitleLbl.Font            = Enum.Font.GothamBold
TitleLbl.TextSize        = 14
TitleLbl.TextXAlignment  = Enum.TextXAlignment.Left
TitleLbl.Parent = TBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size            = UDim2.new(0, 24, 0, 24)
MinBtn.Position        = UDim2.new(1, -32, 0.5, -12)
MinBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
MinBtn.Text            = "-"
MinBtn.TextColor3      = Color3.fromRGB(180, 180, 200)
MinBtn.Font            = Enum.Font.GothamBold
MinBtn.TextSize        = 16
MinBtn.BorderSizePixel  = 0
MinBtn.AutoButtonColor  = false
MinBtn.Parent = TBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 5)
MinCorner.Parent = MinBtn

-- Drag
local _drag, _dragStart, _winStart = false
TBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        _drag = true
        _dragStart = inp.Position
        _winStart  = Window.Position
    end
end)
UIS.InputChanged:Connect(function(inp)
    if _drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local d = inp.Position - _dragStart
        Window.Position = UDim2.new(
            _winStart.X.Scale, _winStart.X.Offset + d.X,
            _winStart.Y.Scale, _winStart.Y.Offset + d.Y
        )
    end
end)
UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then _drag = false end
end)

-- Minimize
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Window.Size = UDim2.new(0, WIN_W, 0, minimized and 36 or WIN_H)
    MinBtn.Text = minimized and "+" or "-"
end)

-- Tab sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Name            = "Sidebar"
Sidebar.Size            = UDim2.new(0, 92, 0, WIN_H - 36)
Sidebar.Position        = UDim2.new(0, 0, 0, 36)
Sidebar.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
Sidebar.BorderSizePixel  = 0
Sidebar.ClipsDescendants = true
Sidebar.Parent = Window

local SBPatch = Instance.new("Frame")
SBPatch.Size            = UDim2.new(1, 0, 0, 7)
SBPatch.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
SBPatch.BorderSizePixel  = 0
SBPatch.Parent = Sidebar

local SBCorner = Instance.new("UICorner")
SBCorner.CornerRadius = UDim.new(0, 7)
SBCorner.Parent = Sidebar

local SBList = Instance.new("UIListLayout")
SBList.SortOrder = Enum.SortOrder.LayoutOrder
SBList.Padding   = UDim.new(0, 3)
SBList.Parent    = Sidebar

local SBPad = Instance.new("UIPadding")
SBPad.PaddingTop   = UDim.new(0, 10)
SBPad.PaddingLeft  = UDim.new(0, 6)
SBPad.PaddingRight = UDim.new(0, 6)
SBPad.Parent = Sidebar

-- Content panel
local ContentPanel = Instance.new("Frame")
ContentPanel.Name            = "Content"
ContentPanel.Size            = UDim2.new(0, WIN_W - 92, 0, WIN_H - 36)
ContentPanel.Position        = UDim2.new(0, 92, 0, 36)
ContentPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
ContentPanel.BorderSizePixel  = 0
ContentPanel.ClipsDescendants = true
ContentPanel.Parent = Window

local CPCorner = Instance.new("UICorner")
CPCorner.CornerRadius = UDim.new(0, 7)
CPCorner.Parent = ContentPanel

local CPPatch = Instance.new("Frame")
CPPatch.Size            = UDim2.new(0, 7, 1, 0)
CPPatch.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
CPPatch.BorderSizePixel  = 0
CPPatch.Parent = ContentPanel

-- Active tab state
local pages   = {}
local tabBtns = {}
local activeTab = nil

local function switchTab(name)
    for n, pg in pairs(pages) do pg.Visible = (n == name) end
    for n, btn in pairs(tabBtns) do
        if n == name then
            btn.BackgroundColor3 = Color3.fromRGB(50, 90, 160)
            btn.TextColor3       = Color3.fromRGB(220, 230, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
            btn.TextColor3       = Color3.fromRGB(130, 130, 150)
        end
    end
    activeTab = name
end

-- Tab builder
local function makeTab(name)
    local btn = Instance.new("TextButton")
    btn.Size            = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
    btn.Text            = name
    btn.TextColor3      = Color3.fromRGB(130, 130, 150)
    btn.Font            = Enum.Font.GothamMedium
    btn.TextSize        = 12
    btn.BorderSizePixel  = 0
    btn.AutoButtonColor  = false
    btn.Parent = Sidebar
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 5)
    bc.Parent = btn
    tabBtns[name] = btn

    local page = Instance.new("ScrollingFrame")
    page.Size               = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel    = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(70, 100, 180)
    page.CanvasSize         = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible            = false
    page.Parent             = ContentPanel
    pages[name] = page

    local pgList = Instance.new("UIListLayout")
    pgList.SortOrder = Enum.SortOrder.LayoutOrder
    pgList.Padding   = UDim.new(0, 4)
    pgList.Parent    = page

    local pgPad = Instance.new("UIPadding")
    pgPad.PaddingTop   = UDim.new(0, 8)
    pgPad.PaddingLeft  = UDim.new(0, 8)
    pgPad.PaddingRight = UDim.new(0, 8)
    pgPad.PaddingBottom = UDim.new(0, 8)
    pgPad.Parent = page

    btn.MouseButton1Click:Connect(function() switchTab(name) end)
    if not activeTab then switchTab(name) end

    -- Element functions
    local tab = {}

    function tab:Toggle(label, default, callback)
        local on = default or false

        local row = Instance.new("Frame")
        row.Size            = UDim2.new(1, 0, 0, 34)
        row.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
        row.BorderSizePixel  = 0
        row.Parent = page
        local rc = Instance.new("UICorner")
        rc.CornerRadius = UDim.new(0, 5)
        rc.Parent = row

        local lbl = Instance.new("TextLabel")
        lbl.Size            = UDim2.new(1, -58, 1, 0)
        lbl.Position        = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text            = label
        lbl.TextColor3      = Color3.fromRGB(200, 200, 215)
        lbl.Font            = Enum.Font.GothamMedium
        lbl.TextSize        = 12
        lbl.TextXAlignment  = Enum.TextXAlignment.Left
        lbl.Parent = row

        local track = Instance.new("Frame")
        track.Size            = UDim2.new(0, 36, 0, 18)
        track.Position        = UDim2.new(1, -46, 0.5, -9)
        track.BackgroundColor3 = on and Color3.fromRGB(70, 150, 70) or Color3.fromRGB(50, 50, 65)
        track.BorderSizePixel  = 0
        track.Parent = row
        local tc = Instance.new("UICorner")
        tc.CornerRadius = UDim.new(1, 0)
        tc.Parent = track

        local knob = Instance.new("Frame")
        knob.Size      = UDim2.new(0, 14, 0, 14)
        knob.Position  = on and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        knob.BackgroundColor3 = Color3.fromRGB(220, 225, 235)
        knob.BorderSizePixel  = 0
        knob.Parent = track
        local kc = Instance.new("UICorner")
        kc.CornerRadius = UDim.new(1, 0)
        kc.Parent = knob

        local hitbox = Instance.new("TextButton")
        hitbox.Size            = UDim2.new(1, 0, 1, 0)
        hitbox.BackgroundTransparency = 1
        hitbox.Text            = ""
        hitbox.Parent = row

        hitbox.MouseButton1Click:Connect(function()
            on = not on
            track.BackgroundColor3 = on and Color3.fromRGB(70, 150, 70) or Color3.fromRGB(50, 50, 65)
            knob.Position = on and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
            callback(on)
        end)
    end

    function tab:Slider(label, min, max, default, callback)
        local value = default or min

        local row = Instance.new("Frame")
        row.Size            = UDim2.new(1, 0, 0, 46)
        row.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
        row.BorderSizePixel  = 0
        row.Parent = page
        local rc = Instance.new("UICorner")
        rc.CornerRadius = UDim.new(0, 5)
        rc.Parent = row

        local lbl = Instance.new("TextLabel")
        lbl.Size           = UDim2.new(1, -60, 0, 20)
        lbl.Position       = UDim2.new(0, 10, 0, 6)
        lbl.BackgroundTransparency = 1
        lbl.Text           = label
        lbl.TextColor3     = Color3.fromRGB(200, 200, 215)
        lbl.Font           = Enum.Font.GothamMedium
        lbl.TextSize       = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local valLbl = Instance.new("TextLabel")
        valLbl.Size           = UDim2.new(0, 50, 0, 20)
        valLbl.Position       = UDim2.new(1, -58, 0, 6)
        valLbl.BackgroundTransparency = 1
        valLbl.Text           = tostring(value)
        valLbl.TextColor3     = Color3.fromRGB(100, 150, 230)
        valLbl.Font           = Enum.Font.GothamMedium
        valLbl.TextSize       = 12
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.Parent = row

        local trackBG = Instance.new("Frame")
        trackBG.Size            = UDim2.new(1, -20, 0, 4)
        trackBG.Position        = UDim2.new(0, 10, 1, -14)
        trackBG.BackgroundColor3 = Color3.fromRGB(44, 44, 58)
        trackBG.BorderSizePixel  = 0
        trackBG.Parent = row
        local tbc = Instance.new("UICorner")
        tbc.CornerRadius = UDim.new(1, 0)
        tbc.Parent = trackBG

        local fill = Instance.new("Frame")
        fill.Size            = UDim2.new((value - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(70, 120, 210)
        fill.BorderSizePixel  = 0
        fill.Parent = trackBG
        local fc = Instance.new("UICorner")
        fc.CornerRadius = UDim.new(1, 0)
        fc.Parent = fill

        local handle = Instance.new("Frame")
        handle.Size       = UDim2.new(0, 10, 0, 10)
        handle.AnchorPoint = Vector2.new(0.5, 0.5)
        handle.Position   = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
        handle.BackgroundColor3 = Color3.fromRGB(160, 195, 255)
        handle.BorderSizePixel  = 0
        handle.Parent = trackBG
        local hc = Instance.new("UICorner")
        hc.CornerRadius = UDim.new(1, 0)
        hc.Parent = handle

        local slideDragging = false
        local hitbox = Instance.new("TextButton")
        hitbox.Size            = UDim2.new(1, 0, 0, 20)
        hitbox.Position        = UDim2.new(0, 0, 1, -20)
        hitbox.BackgroundTransparency = 1
        hitbox.Text            = ""
        hitbox.Parent = row

        local function updateSlider(x)
            local ap  = trackBG.AbsolutePosition
            local sz  = trackBG.AbsoluteSize
            local t   = math.clamp((x - ap.X) / sz.X, 0, 1)
            value     = math.floor(min + t * (max - min) + 0.5)
            fill.Size = UDim2.new(t, 0, 1, 0)
            handle.Position = UDim2.new(t, 0, 0.5, 0)
            valLbl.Text = tostring(value)
            callback(value)
        end

        hitbox.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                slideDragging = true
                updateSlider(inp.Position.X)
            end
        end)
        UIS.InputChanged:Connect(function(inp)
            if slideDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider(inp.Position.X)
            end
        end)
        UIS.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                slideDragging = false
            end
        end)
    end

    function tab:Dropdown(label, options, callback)
        local selected = options[1] or "None"
        local open     = false
        local OPT_H    = 26
        local totalH   = #options * OPT_H

        local wrapper = Instance.new("Frame")
        wrapper.Size            = UDim2.new(1, 0, 0, 34)
        wrapper.BackgroundTransparency = 1
        wrapper.ClipsDescendants = false
        wrapper.Parent = page

        local row = Instance.new("Frame")
        row.Size            = UDim2.new(1, 0, 0, 34)
        row.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
        row.BorderSizePixel  = 0
        row.ZIndex           = 2
        row.Parent = wrapper
        local rc = Instance.new("UICorner")
        rc.CornerRadius = UDim.new(0, 5)
        rc.Parent = row

        local lbl = Instance.new("TextLabel")
        lbl.Size           = UDim2.new(0.45, 0, 1, 0)
        lbl.Position       = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text           = label
        lbl.TextColor3     = Color3.fromRGB(200, 200, 215)
        lbl.Font           = Enum.Font.GothamMedium
        lbl.TextSize       = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex         = 2
        lbl.Parent = row

        local selLbl = Instance.new("TextLabel")
        selLbl.Size           = UDim2.new(0.5, -26, 1, 0)
        selLbl.Position       = UDim2.new(0.47, 0, 0, 0)
        selLbl.BackgroundTransparency = 1
        selLbl.Text           = selected
        selLbl.TextColor3     = Color3.fromRGB(100, 150, 230)
        selLbl.Font           = Enum.Font.GothamMedium
        selLbl.TextSize       = 12
        selLbl.TextXAlignment = Enum.TextXAlignment.Right
        selLbl.ZIndex         = 2
        selLbl.Parent = row

        local arrow = Instance.new("TextLabel")
        arrow.Size           = UDim2.new(0, 20, 1, 0)
        arrow.Position       = UDim2.new(1, -22, 0, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text           = "▾"
        arrow.TextColor3     = Color3.fromRGB(130, 130, 155)
        arrow.Font           = Enum.Font.GothamBold
        arrow.TextSize       = 13
        arrow.ZIndex         = 2
        arrow.Parent = row

        local dropFrame = Instance.new("Frame")
        dropFrame.Size            = UDim2.new(1, 0, 0, math.min(totalH, 104))
        dropFrame.Position        = UDim2.new(0, 0, 1, 2)
        dropFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
        dropFrame.BorderSizePixel  = 0
        dropFrame.ClipsDescendants = true
        dropFrame.ZIndex           = 10
        dropFrame.Visible          = false
        dropFrame.Parent = row
        local dfc = Instance.new("UICorner")
        dfc.CornerRadius = UDim.new(0, 5)
        dfc.Parent = dropFrame

        local dfScroll = Instance.new("ScrollingFrame")
        dfScroll.Size               = UDim2.new(1, 0, 1, 0)
        dfScroll.BackgroundTransparency = 1
        dfScroll.BorderSizePixel    = 0
        dfScroll.ScrollBarThickness = 3
        dfScroll.ScrollBarImageColor3 = Color3.fromRGB(70, 100, 180)
        dfScroll.CanvasSize         = UDim2.new(0, 0, 0, totalH)
        dfScroll.ZIndex             = 10
        dfScroll.Parent = dropFrame

        local dfList = Instance.new("UIListLayout")
        dfList.SortOrder = Enum.SortOrder.LayoutOrder
        dfList.Parent    = dfScroll

        for _, opt in ipairs(options) do
            local ob = Instance.new("TextButton")
            ob.Size            = UDim2.new(1, 0, 0, OPT_H)
            ob.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
            ob.Text            = opt
            ob.TextColor3      = Color3.fromRGB(175, 175, 195)
            ob.Font            = Enum.Font.GothamMedium
            ob.TextSize        = 12
            ob.BorderSizePixel  = 0
            ob.AutoButtonColor  = false
            ob.ZIndex           = 11
            ob.Parent = dfScroll

            ob.MouseEnter:Connect(function()
                ob.BackgroundColor3 = Color3.fromRGB(44, 44, 60)
            end)
            ob.MouseLeave:Connect(function()
                ob.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
            end)
            ob.MouseButton1Click:Connect(function()
                selected = opt
                selLbl.Text = opt
                open = false
                dropFrame.Visible = false
                arrow.Text = "▾"
                callback(opt)
            end)
        end

        local hitbox = Instance.new("TextButton")
        hitbox.Size            = UDim2.new(1, 0, 1, 0)
        hitbox.BackgroundTransparency = 1
        hitbox.Text            = ""
        hitbox.ZIndex          = 3
        hitbox.Parent = row

        hitbox.MouseButton1Click:Connect(function()
            open = not open
            dropFrame.Visible = open
            arrow.Text = open and "▴" or "▾"
        end)
    end

    return tab
end

-- ── Build tabs ────────────────────────────────────────────────────────────────
local SpeedTab    = makeTab("Speed")
local CombatTab   = makeTab("Combat")
local SettingsTab = makeTab("Settings")
local VisualsTab  = makeTab("Visuals")

-- Speed
SpeedTab:Toggle("Speed", false, function(v)
    regularSpeedEnabled = v
    updateHUD()
end)

SpeedTab:Slider("Speed Value", 10, 200, 20, function(v)
    regularSpeed = v
end)

SpeedTab:Toggle("Bomb Speed", false, function(v)
    bombSpeedEnabled = v
    updateHUD()
end)

SpeedTab:Slider("Bomb Speed Value", 10, 200, 25, function(v)
    bombSpeed = v
end)

SpeedTab:Toggle("Spin Bot", false, function(v)
    spinEnabled = v
    if not v then spinAngle = 0 end
    updateHUD()
end)

-- Combat
CombatTab:Toggle("Infinite Jump", false, function(v)
    infiniteJumpEnabled = v
    updateHUD()
end)

CombatTab:Toggle("Noclip", false, function(v)
    noclipEnabled = v
    updateHUD()
end)

-- Settings
SettingsTab:Toggle("Frozen Check", true, function(v)
    frozenCheckEnabled = v
end)

SettingsTab:Toggle("Ladder Check", true, function(v)
    ladderCheckEnabled = v
end)

-- Visuals
VisualsTab:Dropdown("Scene", {
    "None","Ultra Realism","Golden Valley","Rainy Night",
    "Neon City","Frostbite","Cinematic","Blood Moon","Silent Fog"
}, function(v)
    if v == "None" then resetLighting()
    else local p = SCENE_PRESETS[v]; if p then applyLightingPreset(p) end end
end)

VisualsTab:Dropdown("Weather", {
    "None","Clear","Cloudy","Foggy","Rainy","Stormy","Sunrise","Blizzard","Firefly"
}, function(v)
    if v == "None" then resetLighting()
    else local p = WEATHER_PRESETS[v]; if p then applyLightingPreset(p) end end
end)

VisualsTab:Toggle("No Particles", false, function(v) setNoParticles(v) end)
VisualsTab:Toggle("No Lights",    false, function(v) setNoLights(v)    end)
VisualsTab:Toggle("No PostFX",    false, function(v) setNoPostFX(v)    end)
VisualsTab:Toggle("Low Graphics", false, function(v) setLowGraphics(v) end)

-- ── Connections ───────────────────────────────────────────────────────────────
UIS.JumpRequest:Connect(function()
    if not infiniteJumpEnabled then return end
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

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
