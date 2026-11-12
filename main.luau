-- Services
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local TS         = game:GetService("TweenService")
local Lighting   = game:GetService("Lighting")
local CoreGui    = game:GetService("CoreGui")
local LP         = Players.LocalPlayer

-- ── Feature state ─────────────────────────────────────────────────────────
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
    Brightness = Lighting.Brightness, Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient, FogEnd = Lighting.FogEnd,
    FogColor = Lighting.FogColor, ClockTime = Lighting.ClockTime,
}

-- ── Helpers ───────────────────────────────────────────────────────────────
local function hasBomb()
    local c = LP.Character
    return c and (c:FindFirstChild("bomb") or c:FindFirstChild("Bomb")) ~= nil
end
local function isOnLadder(hum)
    return hum:GetState() == Enum.HumanoidStateType.Climbing
end

-- ── Lighting presets ──────────────────────────────────────────────────────
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
    Lighting.Brightness = p.brightness
    Lighting.Ambient        = Color3.fromRGB(unpack(p.ambient))
    Lighting.OutdoorAmbient = Color3.fromRGB(unpack(p.outdoor))
    Lighting.FogEnd  = p.fog
    Lighting.FogColor = Color3.fromRGB(unpack(p.fogcol))
    Lighting.ClockTime = p.clock
end
local function resetLighting()
    Lighting.Brightness = origLight.Brightness; Lighting.Ambient = origLight.Ambient
    Lighting.OutdoorAmbient = origLight.OutdoorAmbient; Lighting.FogEnd = origLight.FogEnd
    Lighting.FogColor = origLight.FogColor; Lighting.ClockTime = origLight.ClockTime
end

-- ── FPS funcs ─────────────────────────────────────────────────────────────
local function setNoParticles(v)
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Smoke")
        or o:IsA("Sparkles") or o:IsA("Fire") then o.Enabled = not v end
    end
end
local function setNoLights(v)
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("PointLight") or o:IsA("SpotLight") or o:IsA("SurfaceLight") then
            o.Enabled = not v
        end
    end
end
local function setNoPostFX(v)
    for _, o in ipairs(Lighting:GetDescendants()) do
        if o:IsA("PostEffect") then o.Enabled = not v end
    end
end
local function setLowGraphics(v)
    local c = LP.Character
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") and not (c and o:IsDescendantOf(c)) then
            if v then o.Material = Enum.Material.Plastic end
        end
    end
end

-- ── Keybind state (must be before UIS connection) ─────────────────────────
local keybindMap = {
    speed = Enum.KeyCode.Unknown, bombSpeed = Enum.KeyCode.Unknown,
    spinBot = Enum.KeyCode.Unknown, infiniteJump = Enum.KeyCode.Unknown,
    noclip = Enum.KeyCode.Unknown,
}
local keybindTogglers = {}
local kbListening = nil  -- {key, setLabel, reset}

-- ── HUD ───────────────────────────────────────────────────────────────────
local HudGui = Instance.new("ScreenGui")
HudGui.Name = "NocturnixHUD"; HudGui.ResetOnSpawn = false; HudGui.Parent = CoreGui

local HUDFrame = Instance.new("Frame")
HUDFrame.Size = UDim2.new(0,110,0,10); HUDFrame.Position = UDim2.new(0,5,0.5,-40)
HUDFrame.BackgroundTransparency = 1; HUDFrame.Parent = HudGui

do
    local l = Instance.new("UIListLayout")
    l.SortOrder = Enum.SortOrder.LayoutOrder; l.Padding = UDim.new(0,2); l.Parent = HUDFrame
end

local HUD_FEATS = {
    {k="regularSpeed",l="Speed"},{k="bombSpeed",l="Bomb Spd"},
    {k="spinBot",l="Spin Bot"},{k="infiniteJump",l="Inf Jump"},{k="noclip",l="Noclip"},
}
local hudLabels = {}
for i, f in ipairs(HUD_FEATS) do
    local lbl = Instance.new("TextLabel")
    lbl.Size=UDim2.new(0,110,0,14); lbl.BackgroundColor3=Color3.fromRGB(12,12,20)
    lbl.BackgroundTransparency=0.25; lbl.TextColor3=Color3.fromRGB(170,170,185)
    lbl.Font=Enum.Font.GothamMedium; lbl.TextSize=10; lbl.Text=f.l..": OFF"
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.LayoutOrder=i
    local p=Instance.new("UIPadding"); p.PaddingLeft=UDim.new(0,4); p.Parent=lbl
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,2); c.Parent=lbl
    lbl.Parent=HUDFrame; hudLabels[f.k]=lbl
end
local HUD_NAMES={regularSpeed="Speed",bombSpeed="Bomb Spd",spinBot="Spin Bot",infiniteJump="Inf Jump",noclip="Noclip"}
local function updateHUD()
    local st={regularSpeed=regularSpeedEnabled,bombSpeed=bombSpeedEnabled,spinBot=spinEnabled,
              infiniteJump=infiniteJumpEnabled,noclip=noclipEnabled}
    for k,lbl in pairs(hudLabels) do
        local on=st[k]
        lbl.Text=HUD_NAMES[k]..": "..(on and "ON" or "OFF")
        lbl.TextColor3=on and Color3.fromRGB(90,210,90) or Color3.fromRGB(170,170,185)
    end
end

-- ── UI palette ────────────────────────────────────────────────────────────
local BG      = Color3.fromRGB(13, 13, 20)
local SURF    = Color3.fromRGB(21, 21, 32)
local SURF2   = Color3.fromRGB(28, 28, 44)
local SIDE    = Color3.fromRGB(17, 17, 27)
local ACCENT  = Color3.fromRGB(88, 128, 245)
local ACCENT2 = Color3.fromRGB(60, 100, 220)
local GREEN   = Color3.fromRGB(68, 168, 84)
local TEXT    = Color3.fromRGB(212, 216, 232)
local DIM     = Color3.fromRGB(120, 125, 150)
local TRACK   = Color3.fromRGB(38, 38, 60)
local BORDER  = Color3.fromRGB(38, 38, 60)

local TI  = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI2 = TweenInfo.new(0.08, Enum.EasingStyle.Linear)

-- ── Window ────────────────────────────────────────────────────────────────
local WIN_W, WIN_H, SIDE_W, TBAR_H = 540, 310, 110, 44

local GUI = Instance.new("ScreenGui")
GUI.Name="NocturnixGUI"; GUI.ResetOnSpawn=false
GUI.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; GUI.Parent=CoreGui

local Window = Instance.new("Frame")
Window.Name="Window"; Window.Size=UDim2.new(0,WIN_W,0,WIN_H)
Window.Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2)
Window.BackgroundColor3=BG; Window.BorderSizePixel=0; Window.Parent=GUI

do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=Window end
do
    local s=Instance.new("UIStroke"); s.Color=BORDER; s.Thickness=1
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=Window
end

-- Titlebar
local TBar = Instance.new("Frame")
TBar.Size=UDim2.new(1,0,0,TBAR_H); TBar.BackgroundColor3=SURF
TBar.BorderSizePixel=0; TBar.Parent=Window
do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=TBar end
do
    local p=Instance.new("Frame"); p.Size=UDim2.new(1,0,0,8)
    p.Position=UDim2.new(0,0,1,-8); p.BackgroundColor3=SURF; p.BorderSizePixel=0; p.Parent=TBar
end

-- Accent stripe at very top
local Stripe = Instance.new("Frame")
Stripe.Size=UDim2.new(1,0,0,2); Stripe.BackgroundColor3=ACCENT
Stripe.BorderSizePixel=0; Stripe.Parent=TBar
do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=Stripe end

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size=UDim2.new(1,-50,1,0); TitleLbl.Position=UDim2.new(0,14,0,0)
TitleLbl.BackgroundTransparency=1; TitleLbl.Text="Nocturnix"
TitleLbl.TextColor3=TEXT; TitleLbl.Font=Enum.Font.GothamBold; TitleLbl.TextSize=15
TitleLbl.TextXAlignment=Enum.TextXAlignment.Left; TitleLbl.Parent=TBar

local SubLbl = Instance.new("TextLabel")
SubLbl.Size=UDim2.new(0,120,1,0); SubLbl.Position=UDim2.new(0,100,0,0)
SubLbl.BackgroundTransparency=1; SubLbl.Text="Timebomb Duels"
SubLbl.TextColor3=DIM; SubLbl.Font=Enum.Font.GothamMedium; SubLbl.TextSize=11
SubLbl.TextXAlignment=Enum.TextXAlignment.Left; SubLbl.Parent=TBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size=UDim2.new(0,26,0,26); MinBtn.Position=UDim2.new(1,-36,0.5,-13)
MinBtn.BackgroundColor3=SURF2; MinBtn.Text="–"; MinBtn.TextColor3=DIM
MinBtn.Font=Enum.Font.GothamBold; MinBtn.TextSize=16; MinBtn.BorderSizePixel=0
MinBtn.AutoButtonColor=false; MinBtn.Parent=TBar
do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,6); c.Parent=MinBtn end
MinBtn.MouseEnter:Connect(function() MinBtn.BackgroundColor3=ACCENT end)
MinBtn.MouseLeave:Connect(function() MinBtn.BackgroundColor3=SURF2 end)

-- Drag
local _drag,_dragStart,_winStart=false
TBar.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 then
        _drag=true; _dragStart=inp.Position; _winStart=Window.Position
    end
end)
UIS.InputChanged:Connect(function(inp)
    if _drag and inp.UserInputType==Enum.UserInputType.MouseMovement then
        local d=inp.Position-_dragStart
        Window.Position=UDim2.new(_winStart.X.Scale,_winStart.X.Offset+d.X,_winStart.Y.Scale,_winStart.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 then _drag=false end
end)

-- Minimize
local minimized=false
MinBtn.MouseButton1Click:Connect(function()
    minimized=not minimized
    TS:Create(Window,TI,{Size=UDim2.new(0,WIN_W,0,minimized and TBAR_H or WIN_H)}):Play()
    MinBtn.Text=minimized and "+" or "–"
end)

-- ── Sidebar ───────────────────────────────────────────────────────────────
local Sidebar = Instance.new("Frame")
Sidebar.Name="Sidebar"; Sidebar.Size=UDim2.new(0,SIDE_W,0,WIN_H-TBAR_H)
Sidebar.Position=UDim2.new(0,0,0,TBAR_H); Sidebar.BackgroundColor3=SIDE
Sidebar.BorderSizePixel=0; Sidebar.ClipsDescendants=true; Sidebar.Parent=Window
do
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=Sidebar
    local p=Instance.new("Frame"); p.Size=UDim2.new(0,8,1,0); p.Position=UDim2.new(1,-8,0,0)
    p.BackgroundColor3=SIDE; p.BorderSizePixel=0; p.Parent=Sidebar
    local p2=Instance.new("Frame"); p2.Size=UDim2.new(1,0,0,8)
    p2.BackgroundColor3=SIDE; p2.BorderSizePixel=0; p2.Parent=Sidebar
end
do
    local l=Instance.new("UIListLayout"); l.SortOrder=Enum.SortOrder.LayoutOrder
    l.Padding=UDim.new(0,3); l.Parent=Sidebar
    local p=Instance.new("UIPadding"); p.PaddingTop=UDim.new(0,10)
    p.PaddingLeft=UDim.new(0,7); p.PaddingRight=UDim.new(0,7); p.Parent=Sidebar
end

-- ── Content panel ─────────────────────────────────────────────────────────
local Content = Instance.new("Frame")
Content.Name="Content"; Content.Size=UDim2.new(0,WIN_W-SIDE_W,0,WIN_H-TBAR_H)
Content.Position=UDim2.new(0,SIDE_W,0,TBAR_H); Content.BackgroundColor3=BG
Content.BorderSizePixel=0; Content.ClipsDescendants=true; Content.Parent=Window
do
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=Content
    local p=Instance.new("Frame"); p.Size=UDim2.new(0,8,1,0)
    p.BackgroundColor3=BG; p.BorderSizePixel=0; p.Parent=Content
    local p2=Instance.new("Frame"); p2.Size=UDim2.new(1,0,0,8)
    p2.BackgroundColor3=BG; p2.BorderSizePixel=0; p2.Parent=Content
end

-- ── Tab system ────────────────────────────────────────────────────────────
local pages   = {}
local tabBtns = {}
local tabInds = {}
local activeTab = nil

local function switchTab(name)
    for n,pg in pairs(pages) do pg.Visible=(n==name) end
    for n,btn in pairs(tabBtns) do
        local act=(n==name)
        TS:Create(btn,TI,{BackgroundColor3=act and SURF2 or SIDE}):Play()
        btn.TextColor3 = act and TEXT or DIM
        if tabInds[n] then tabInds[n].Visible=act end
    end
    activeTab=name
end

local function makeTab(name)
    local btn = Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,0,32); btn.BackgroundColor3=SIDE; btn.Text=name
    btn.TextColor3=DIM; btn.Font=Enum.Font.GothamSemibold; btn.TextSize=12
    btn.BorderSizePixel=0; btn.AutoButtonColor=false; btn.Parent=Sidebar
    do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,5); c.Parent=btn end
    tabBtns[name]=btn

    -- Left accent indicator
    local ind = Instance.new("Frame")
    ind.Size=UDim2.new(0,3,0.6,0); ind.AnchorPoint=Vector2.new(0,0.5)
    ind.Position=UDim2.new(0,0,0.5,0); ind.BackgroundColor3=ACCENT
    ind.BorderSizePixel=0; ind.Visible=false; ind.Parent=btn
    do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=ind end
    tabInds[name]=ind

    btn.MouseEnter:Connect(function()
        if activeTab~=name then TS:Create(btn,TI2,{BackgroundColor3=SURF}):Play() end
    end)
    btn.MouseLeave:Connect(function()
        if activeTab~=name then TS:Create(btn,TI2,{BackgroundColor3=SIDE}):Play() end
    end)

    local page = Instance.new("ScrollingFrame")
    page.Size=UDim2.new(1,0,1,0); page.BackgroundTransparency=1
    page.BorderSizePixel=0; page.ScrollBarThickness=3
    page.ScrollBarImageColor3=Color3.fromRGB(60,80,160)
    page.CanvasSize=UDim2.new(0,0,0,0); page.AutomaticCanvasSize=Enum.AutomaticSize.Y
    page.Visible=false; page.Parent=Content
    pages[name]=page

    do
        local l=Instance.new("UIListLayout"); l.SortOrder=Enum.SortOrder.LayoutOrder
        l.Padding=UDim.new(0,5); l.Parent=page
        local p=Instance.new("UIPadding"); p.PaddingTop=UDim.new(0,10)
        p.PaddingLeft=UDim.new(0,10); p.PaddingRight=UDim.new(0,10)
        p.PaddingBottom=UDim.new(0,10); p.Parent=page
    end

    btn.MouseButton1Click:Connect(function() switchTab(name) end)
    if not activeTab then switchTab(name) end

    local tab = {}

    -- Toggle — returns a fire() so keybinds can toggle programmatically
    function tab:Toggle(label, default, callback)
        local on = default or false
        local ON_POS  = UDim2.new(1,-17,0.5,-7)
        local OFF_POS = UDim2.new(0,3,0.5,-7)

        local row = Instance.new("Frame")
        row.Size=UDim2.new(1,0,0,36); row.BackgroundColor3=SURF; row.BorderSizePixel=0; row.Parent=page
        do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,6); c.Parent=row end

        local dot = Instance.new("Frame")
        dot.Size=UDim2.new(0,4,0,4); dot.Position=UDim2.new(0,8,0.5,-2)
        dot.BackgroundColor3=on and GREEN or Color3.fromRGB(55,55,70)
        dot.BorderSizePixel=0; dot.Parent=row
        do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=dot end

        local lbl = Instance.new("TextLabel")
        lbl.Size=UDim2.new(1,-68,1,0); lbl.Position=UDim2.new(0,20,0,0)
        lbl.BackgroundTransparency=1; lbl.Text=label
        lbl.TextColor3=TEXT; lbl.Font=Enum.Font.GothamMedium; lbl.TextSize=13
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row

        local track = Instance.new("Frame")
        track.Size=UDim2.new(0,38,0,20); track.Position=UDim2.new(1,-50,0.5,-10)
        track.BackgroundColor3=on and GREEN or TRACK; track.BorderSizePixel=0; track.Parent=row
        do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=track end

        local knob = Instance.new("Frame")
        knob.Size=UDim2.new(0,14,0,14); knob.Position=on and ON_POS or OFF_POS
        knob.BackgroundColor3=Color3.fromRGB(228,230,240); knob.BorderSizePixel=0; knob.Parent=track
        do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=knob end

        local hitbox = Instance.new("TextButton")
        hitbox.Size=UDim2.new(1,0,1,0); hitbox.BackgroundTransparency=1; hitbox.Text=""; hitbox.Parent=row

        row.MouseEnter:Connect(function() TS:Create(row,TI2,{BackgroundColor3=SURF2}):Play() end)
        row.MouseLeave:Connect(function() TS:Create(row,TI2,{BackgroundColor3=SURF}):Play() end)

        local function fire(val)
            if val == nil then val = not on end
            on = val
            TS:Create(track,TI,{BackgroundColor3=on and GREEN or TRACK}):Play()
            TS:Create(knob,TI,{Position=on and ON_POS or OFF_POS}):Play()
            TS:Create(dot,TI,{BackgroundColor3=on and GREEN or Color3.fromRGB(55,55,70)}):Play()
            callback(on)
        end

        hitbox.MouseButton1Click:Connect(function() fire() end)
        return fire
    end

    function tab:Slider(label, min, max, default, callback)
        local value = default or min

        local row = Instance.new("Frame")
        row.Size=UDim2.new(1,0,0,48); row.BackgroundColor3=SURF; row.BorderSizePixel=0; row.Parent=page
        do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,6); c.Parent=row end

        local lbl = Instance.new("TextLabel")
        lbl.Size=UDim2.new(1,-70,0,22); lbl.Position=UDim2.new(0,12,0,5)
        lbl.BackgroundTransparency=1; lbl.Text=label
        lbl.TextColor3=TEXT; lbl.Font=Enum.Font.GothamMedium; lbl.TextSize=13
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row

        local valLbl = Instance.new("TextLabel")
        valLbl.Size=UDim2.new(0,58,0,22); valLbl.Position=UDim2.new(1,-68,0,5)
        valLbl.BackgroundTransparency=1; valLbl.Text=tostring(value)
        valLbl.TextColor3=ACCENT; valLbl.Font=Enum.Font.GothamBold; valLbl.TextSize=13
        valLbl.TextXAlignment=Enum.TextXAlignment.Right; valLbl.Parent=row

        local trackBG = Instance.new("Frame")
        trackBG.Size=UDim2.new(1,-24,0,6); trackBG.Position=UDim2.new(0,12,1,-17)
        trackBG.BackgroundColor3=TRACK; trackBG.BorderSizePixel=0; trackBG.Parent=row
        do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=trackBG end

        local fill = Instance.new("Frame")
        fill.Size=UDim2.new((value-min)/(max-min),0,1,0); fill.BackgroundColor3=ACCENT
        fill.BorderSizePixel=0; fill.Parent=trackBG
        do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=fill end

        local handle = Instance.new("Frame")
        handle.Size=UDim2.new(0,12,0,12); handle.AnchorPoint=Vector2.new(0.5,0.5)
        handle.Position=UDim2.new((value-min)/(max-min),0,0.5,0)
        handle.BackgroundColor3=Color3.fromRGB(180,205,255); handle.BorderSizePixel=0; handle.Parent=trackBG
        do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=handle end

        row.MouseEnter:Connect(function() TS:Create(row,TI2,{BackgroundColor3=SURF2}):Play() end)
        row.MouseLeave:Connect(function() TS:Create(row,TI2,{BackgroundColor3=SURF}):Play() end)

        local slideDrag=false
        local hitbox=Instance.new("TextButton")
        hitbox.Size=UDim2.new(1,0,0,22); hitbox.Position=UDim2.new(0,0,1,-22)
        hitbox.BackgroundTransparency=1; hitbox.Text=""; hitbox.Parent=row

        local function update(x)
            local ap=trackBG.AbsolutePosition; local sz=trackBG.AbsoluteSize
            local t=math.clamp((x-ap.X)/sz.X,0,1)
            value=math.floor(min+t*(max-min)+0.5)
            fill.Size=UDim2.new(t,0,1,0); handle.Position=UDim2.new(t,0,0.5,0)
            valLbl.Text=tostring(value); callback(value)
        end
        hitbox.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 then
                slideDrag=true; update(inp.Position.X)
            end
        end)
        UIS.InputChanged:Connect(function(inp)
            if slideDrag and inp.UserInputType==Enum.UserInputType.MouseMovement then update(inp.Position.X) end
        end)
        UIS.InputEnded:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 then slideDrag=false end
        end)
    end

    function tab:Dropdown(label, options, callback)
        local selected = options[1] or "None"
        local open = false
        local OPT_H = 28
        local totalH = #options * OPT_H

        local wrapper = Instance.new("Frame")
        wrapper.Size=UDim2.new(1,0,0,36); wrapper.BackgroundTransparency=1
        wrapper.ClipsDescendants=false; wrapper.Parent=page

        local row = Instance.new("Frame")
        row.Size=UDim2.new(1,0,0,36); row.BackgroundColor3=SURF; row.BorderSizePixel=0
        row.ZIndex=2; row.Parent=wrapper
        do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,6); c.Parent=row end

        local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(0.42,0,1,0)
        lbl.Position=UDim2.new(0,12,0,0); lbl.BackgroundTransparency=1; lbl.Text=label
        lbl.TextColor3=TEXT; lbl.Font=Enum.Font.GothamMedium; lbl.TextSize=13
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=2; lbl.Parent=row

        local selLbl=Instance.new("TextLabel"); selLbl.Size=UDim2.new(0.52,-28,1,0)
        selLbl.Position=UDim2.new(0.44,0,0,0); selLbl.BackgroundTransparency=1; selLbl.Text=selected
        selLbl.TextColor3=ACCENT; selLbl.Font=Enum.Font.GothamMedium; selLbl.TextSize=12
        selLbl.TextXAlignment=Enum.TextXAlignment.Right; selLbl.ZIndex=2; selLbl.Parent=row

        local arrow=Instance.new("TextLabel"); arrow.Size=UDim2.new(0,22,1,0)
        arrow.Position=UDim2.new(1,-24,0,0); arrow.BackgroundTransparency=1; arrow.Text="▾"
        arrow.TextColor3=DIM; arrow.Font=Enum.Font.GothamBold; arrow.TextSize=13
        arrow.ZIndex=2; arrow.Parent=row

        local dropFrame=Instance.new("Frame")
        dropFrame.Size=UDim2.new(1,0,0,math.min(totalH,112)); dropFrame.Position=UDim2.new(0,0,1,3)
        dropFrame.BackgroundColor3=SURF2; dropFrame.BorderSizePixel=0
        dropFrame.ClipsDescendants=true; dropFrame.ZIndex=10; dropFrame.Visible=false; dropFrame.Parent=row
        do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,6); c.Parent=dropFrame end
        do local s=Instance.new("UIStroke"); s.Color=BORDER; s.Thickness=1; s.Parent=dropFrame end

        local dfScroll=Instance.new("ScrollingFrame")
        dfScroll.Size=UDim2.new(1,0,1,0); dfScroll.BackgroundTransparency=1
        dfScroll.BorderSizePixel=0; dfScroll.ScrollBarThickness=3
        dfScroll.ScrollBarImageColor3=Color3.fromRGB(60,80,160)
        dfScroll.CanvasSize=UDim2.new(0,0,0,totalH); dfScroll.ZIndex=10; dfScroll.Parent=dropFrame
        do local l=Instance.new("UIListLayout"); l.SortOrder=Enum.SortOrder.LayoutOrder; l.Parent=dfScroll end

        for _, opt in ipairs(options) do
            local ob=Instance.new("TextButton"); ob.Size=UDim2.new(1,0,0,OPT_H)
            ob.BackgroundColor3=SURF2; ob.Text="  "..opt; ob.TextColor3=DIM
            ob.Font=Enum.Font.GothamMedium; ob.TextSize=12; ob.BorderSizePixel=0
            ob.AutoButtonColor=false; ob.TextXAlignment=Enum.TextXAlignment.Left
            ob.ZIndex=11; ob.Parent=dfScroll
            ob.MouseEnter:Connect(function() ob.BackgroundColor3=Color3.fromRGB(38,38,58) end)
            ob.MouseLeave:Connect(function() ob.BackgroundColor3=SURF2 end)
            ob.MouseButton1Click:Connect(function()
                selected=opt; selLbl.Text=opt; open=false
                dropFrame.Visible=false; arrow.Text="▾"; callback(opt)
            end)
        end

        row.MouseEnter:Connect(function() if not open then TS:Create(row,TI2,{BackgroundColor3=SURF2}):Play() end end)
        row.MouseLeave:Connect(function() if not open then TS:Create(row,TI2,{BackgroundColor3=SURF}):Play() end end)

        local hitbox=Instance.new("TextButton"); hitbox.Size=UDim2.new(1,0,1,0)
        hitbox.BackgroundTransparency=1; hitbox.Text=""; hitbox.ZIndex=3; hitbox.Parent=row
        hitbox.MouseButton1Click:Connect(function()
            open=not open; dropFrame.Visible=open; arrow.Text=open and "▴" or "▾"
            if open then TS:Create(row,TI2,{BackgroundColor3=SURF2}):Play()
            else TS:Create(row,TI2,{BackgroundColor3=SURF}):Play() end
        end)
    end

    function tab:KeybindRow(label, featureKey)
        local row=Instance.new("Frame")
        row.Size=UDim2.new(1,0,0,36); row.BackgroundColor3=SURF; row.BorderSizePixel=0; row.Parent=page
        do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,6); c.Parent=row end

        local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-110,1,0)
        lbl.Position=UDim2.new(0,12,0,0); lbl.BackgroundTransparency=1; lbl.Text=label
        lbl.TextColor3=TEXT; lbl.Font=Enum.Font.GothamMedium; lbl.TextSize=13
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row

        local kc0=keybindMap[featureKey]
        local initName = kc0~=Enum.KeyCode.Unknown and kc0.Name or "None"

        local keyBtn=Instance.new("TextButton"); keyBtn.Size=UDim2.new(0,88,0,24)
        keyBtn.Position=UDim2.new(1,-98,0.5,-12)
        keyBtn.BackgroundColor3=initName=="None" and TRACK or ACCENT2
        keyBtn.Text=initName; keyBtn.TextColor3=initName=="None" and DIM or TEXT
        keyBtn.Font=Enum.Font.GothamSemibold; keyBtn.TextSize=11
        keyBtn.BorderSizePixel=0; keyBtn.AutoButtonColor=false; keyBtn.Parent=row
        do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,5); c.Parent=keyBtn end
        do local s=Instance.new("UIStroke"); s.Color=BORDER; s.Thickness=1; s.Parent=keyBtn end

        row.MouseEnter:Connect(function() TS:Create(row,TI2,{BackgroundColor3=SURF2}):Play() end)
        row.MouseLeave:Connect(function() TS:Create(row,TI2,{BackgroundColor3=SURF}):Play() end)

        local function setLabel(text)
            keyBtn.Text=text
            keyBtn.BackgroundColor3=text=="None" and TRACK or ACCENT2
            keyBtn.TextColor3=text=="None" and DIM or TEXT
        end
        local function resetBtn()
            local k=keybindMap[featureKey]
            setLabel(k~=Enum.KeyCode.Unknown and k.Name or "None")
        end

        keyBtn.MouseButton1Click:Connect(function()
            if kbListening then kbListening.reset(); kbListening=nil end
            keyBtn.Text="Press key..."; keyBtn.BackgroundColor3=Color3.fromRGB(50,70,130)
            keyBtn.TextColor3=Color3.fromRGB(180,210,255)
            kbListening={key=featureKey, setLabel=setLabel, reset=resetBtn}
        end)
    end

    return tab
end

-- ── Build tabs ────────────────────────────────────────────────────────────
local SpeedTab    = makeTab("Speed")
local CombatTab   = makeTab("Combat")
local SettingsTab = makeTab("Settings")
local VisualsTab  = makeTab("Visuals")
local KeysTab     = makeTab("Keys")

-- Speed
local speedFire = SpeedTab:Toggle("Speed", false, function(v)
    regularSpeedEnabled=v; updateHUD()
end)
keybindTogglers.speed = speedFire

SpeedTab:Slider("Speed Value", 10, 200, 20, function(v) regularSpeed=v end)

local bombSpeedFire = SpeedTab:Toggle("Bomb Speed", false, function(v)
    bombSpeedEnabled=v; updateHUD()
end)
keybindTogglers.bombSpeed = bombSpeedFire

SpeedTab:Slider("Bomb Speed Value", 10, 200, 25, function(v) bombSpeed=v end)

local spinFire = SpeedTab:Toggle("Spin Bot", false, function(v)
    spinEnabled=v; if not v then spinAngle=0 end; updateHUD()
end)
keybindTogglers.spinBot = spinFire

-- Combat
local infJumpFire = CombatTab:Toggle("Infinite Jump", false, function(v)
    infiniteJumpEnabled=v; updateHUD()
end)
keybindTogglers.infiniteJump = infJumpFire

local noclipFire = CombatTab:Toggle("Noclip", false, function(v)
    noclipEnabled=v; updateHUD()
end)
keybindTogglers.noclip = noclipFire

-- Settings
SettingsTab:Toggle("Frozen Check", true, function(v) frozenCheckEnabled=v end)
SettingsTab:Toggle("Ladder Check", true, function(v) ladderCheckEnabled=v end)

-- Visuals
VisualsTab:Dropdown("Scene", {
    "None","Ultra Realism","Golden Valley","Rainy Night",
    "Neon City","Frostbite","Cinematic","Blood Moon","Silent Fog"
}, function(v)
    if v=="None" then resetLighting() else local p=SCENE_PRESETS[v]; if p then applyLightingPreset(p) end end
end)
VisualsTab:Dropdown("Weather", {
    "None","Clear","Cloudy","Foggy","Rainy","Stormy","Sunrise","Blizzard","Firefly"
}, function(v)
    if v=="None" then resetLighting() else local p=WEATHER_PRESETS[v]; if p then applyLightingPreset(p) end end
end)
VisualsTab:Toggle("No Particles", false, function(v) setNoParticles(v) end)
VisualsTab:Toggle("No Lights",    false, function(v) setNoLights(v) end)
VisualsTab:Toggle("No PostFX",    false, function(v) setNoPostFX(v) end)
VisualsTab:Toggle("Low Graphics", false, function(v) setLowGraphics(v) end)

-- Keys tab
KeysTab:KeybindRow("Speed",         "speed")
KeysTab:KeybindRow("Bomb Speed",    "bombSpeed")
KeysTab:KeybindRow("Spin Bot",      "spinBot")
KeysTab:KeybindRow("Infinite Jump", "infiniteJump")
KeysTab:KeybindRow("Noclip",        "noclip")

-- ── Keybind dispatch ──────────────────────────────────────────────────────
UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if kbListening then
        if inp.KeyCode == Enum.KeyCode.Escape then
            keybindMap[kbListening.key] = Enum.KeyCode.Unknown
            kbListening.setLabel("None")
        elseif inp.KeyCode ~= Enum.KeyCode.Unknown then
            keybindMap[kbListening.key] = inp.KeyCode
            kbListening.setLabel(inp.KeyCode.Name)
        end
        kbListening.reset(); kbListening = nil
        return
    end
    for featureKey, kc in pairs(keybindMap) do
        if kc ~= Enum.KeyCode.Unknown and inp.KeyCode == kc then
            if keybindTogglers[featureKey] then keybindTogglers[featureKey]() end
        end
    end
end)

-- ── Connections ───────────────────────────────────────────────────────────
UIS.JumpRequest:Connect(function()
    if not infiniteJumpEnabled then return end
    local char=LP.Character; if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health>0 then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

RunService.Heartbeat:Connect(function()
    if not noclipEnabled then return end
    local char=LP.Character; if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then
            part.CanCollide=false
        end
    end
end)

RunService.RenderStepped:Connect(function(dt)
    local char=LP.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart")
    local hum=char:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health<=0 then return end
    if frozenCheckEnabled then
        if hrp.Anchored then return end
        if hum.PlatformStand then return end
        for _, v in ipairs(hrp:GetChildren()) do
            if v:IsA("BodyPosition") or v:IsA("BodyVelocity") then return end
        end
    end
    if ladderCheckEnabled and isOnLadder(hum) then return end
    local dir=hum.MoveDirection
    local speed=0
    if hasBomb() then
        if bombSpeedEnabled then speed=bombSpeed end
    elseif regularSpeedEnabled then
        speed=regularSpeed
    end
    local newCF=hrp.CFrame
    if speed>0 and dir.Magnitude>0 then newCF=newCF+dir*speed*dt end
    if spinEnabled then
        spinAngle=(spinAngle+20*dt)%(2*math.pi)
        newCF=CFrame.new(newCF.Position)*CFrame.Angles(0,spinAngle,0)
    end
    if newCF~=hrp.CFrame then hrp.CFrame=newCF end
end)
