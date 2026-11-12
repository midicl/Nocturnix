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

local origLight = {
    Brightness=Lighting.Brightness, Ambient=Lighting.Ambient,
    OutdoorAmbient=Lighting.OutdoorAmbient, FogEnd=Lighting.FogEnd,
    FogColor=Lighting.FogColor, ClockTime=Lighting.ClockTime,
}

local function hasBomb()
    local c=LP.Character; return c and (c:FindFirstChild("bomb") or c:FindFirstChild("Bomb")) ~= nil
end
local function isOnLadder(hum) return hum:GetState()==Enum.HumanoidStateType.Climbing end

local SCENE_PRESETS = {
    ["Ultra Realism"]={brightness=3,  ambient={80,80,95},   outdoor={100,100,120},fog=2000,fogcol={180,190,210},clock=14},
    ["Golden Valley"] ={brightness=4,  ambient={180,150,80}, outdoor={200,170,90}, fog=3000,fogcol={255,230,150},clock=17},
    ["Rainy Night"]   ={brightness=.3, ambient={50,60,80},   outdoor={40,50,70},   fog=200, fogcol={90,100,120}, clock=22},
    ["Neon City"]     ={brightness=.5, ambient={0,80,160},   outdoor={20,60,120},  fog=5000,fogcol={20,30,80},   clock=0},
    ["Frostbite"]     ={brightness=1.5,ambient={180,210,230},outdoor={200,220,240},fog=500, fogcol={200,220,240},clock=10},
    ["Cinematic"]     ={brightness=1.8,ambient={80,70,70},   outdoor={90,80,80},   fog=5000,fogcol={150,140,140},clock=14},
    ["Blood Moon"]    ={brightness=.8, ambient={120,20,20},  outdoor={100,20,20},  fog=800, fogcol={150,50,50},  clock=23},
    ["Silent Fog"]    ={brightness=1,  ambient={120,120,120},outdoor={130,130,130},fog=80,  fogcol={200,200,200},clock=12},
}
local WEATHER_PRESETS = {
    ["Clear"]   ={brightness=2,  ambient={127,127,127},outdoor={127,127,127},fog=1e6, fogcol={192,192,192},clock=14},
    ["Cloudy"]  ={brightness=1.2,ambient={100,100,110},outdoor={110,110,120},fog=3000,fogcol={160,160,170},clock=13},
    ["Foggy"]   ={brightness=1,  ambient={130,130,140},outdoor={140,140,150},fog=150, fogcol={180,185,190},clock=12},
    ["Rainy"]   ={brightness=.4, ambient={60,65,75},   outdoor={50,55,65},   fog=400, fogcol={80,85,95},   clock=11},
    ["Stormy"]  ={brightness=.2, ambient={40,40,50},   outdoor={30,30,40},   fog=200, fogcol={60,60,70},   clock=20},
    ["Sunrise"] ={brightness=3,  ambient={180,120,80}, outdoor={200,140,90}, fog=4000,fogcol={255,200,150},clock=7},
    ["Blizzard"]={brightness=.8, ambient={200,210,220},outdoor={210,220,230},fog=80,  fogcol={220,230,235},clock=11},
    ["Firefly"] ={brightness=.3, ambient={30,50,20},   outdoor={20,40,15},   fog=2000,fogcol={40,60,30},   clock=22},
}
local function applyLightingPreset(p)
    Lighting.Brightness=p.brightness; Lighting.Ambient=Color3.fromRGB(unpack(p.ambient))
    Lighting.OutdoorAmbient=Color3.fromRGB(unpack(p.outdoor)); Lighting.FogEnd=p.fog
    Lighting.FogColor=Color3.fromRGB(unpack(p.fogcol)); Lighting.ClockTime=p.clock
end
local function resetLighting()
    Lighting.Brightness=origLight.Brightness; Lighting.Ambient=origLight.Ambient
    Lighting.OutdoorAmbient=origLight.OutdoorAmbient; Lighting.FogEnd=origLight.FogEnd
    Lighting.FogColor=origLight.FogColor; Lighting.ClockTime=origLight.ClockTime
end

local function setNoParticles(v)
    for _,o in ipairs(workspace:GetDescendants()) do
        if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Smoke")
        or o:IsA("Sparkles") or o:IsA("Fire") then o.Enabled=not v end
    end
end
local function setNoLights(v)
    for _,o in ipairs(workspace:GetDescendants()) do
        if o:IsA("PointLight") or o:IsA("SpotLight") or o:IsA("SurfaceLight") then o.Enabled=not v end
    end
end
local function setNoPostFX(v)
    for _,o in ipairs(Lighting:GetDescendants()) do
        if o:IsA("PostEffect") then o.Enabled=not v end
    end
end
local function setLowGraphics(v)
    local c=LP.Character
    for _,o in ipairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") and not(c and o:IsDescendantOf(c)) then
            if v then o.Material=Enum.Material.Plastic end
        end
    end
end

-- ── Keybind state ─────────────────────────────────────────────────────────
local keybindMap={speed=Enum.KeyCode.Unknown,bombSpeed=Enum.KeyCode.Unknown,
    spinBot=Enum.KeyCode.Unknown,infiniteJump=Enum.KeyCode.Unknown,noclip=Enum.KeyCode.Unknown}
local keybindTogglers={}
local kbListening=nil

-- ── HUD ───────────────────────────────────────────────────────────────────
local HudGui=Instance.new("ScreenGui")
HudGui.Name="NocturnixHUD"; HudGui.ResetOnSpawn=false; HudGui.Parent=CoreGui
local HUDFrame=Instance.new("Frame")
HUDFrame.Size=UDim2.new(0,110,0,10); HUDFrame.Position=UDim2.new(0,5,0.5,-40)
HUDFrame.BackgroundTransparency=1; HUDFrame.Parent=HudGui
do local l=Instance.new("UIListLayout"); l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,2); l.Parent=HUDFrame end
local HUD_FEATS={{k="regularSpeed",l="Speed"},{k="bombSpeed",l="Bomb Spd"},
    {k="spinBot",l="Spin Bot"},{k="infiniteJump",l="Inf Jump"},{k="noclip",l="Noclip"}}
local hudLabels={}
for i,f in ipairs(HUD_FEATS) do
    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(0,110,0,14); lbl.BackgroundColor3=Color3.fromRGB(0,0,0)
    lbl.BackgroundTransparency=0.2; lbl.TextColor3=Color3.fromRGB(160,160,170)
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
        lbl.TextColor3=on and Color3.fromRGB(180,100,255) or Color3.fromRGB(160,160,170)
    end
end

-- ── Palette ───────────────────────────────────────────────────────────────
local BK  = Color3.fromRGB(0,   0,   0  )   -- pure black
local S1  = Color3.fromRGB(11,  11,  11 )   -- row bg
local S2  = Color3.fromRGB(20,  20,  20 )   -- hover
local PUR = Color3.fromRGB(165, 95,  255)   -- main purple
local PU2 = Color3.fromRGB(115, 55,  215)   -- darker purple
local WHT = Color3.fromRGB(228, 228, 232)   -- text
local DIM = Color3.fromRGB(90,  90,  100)   -- dim
local TRK = Color3.fromRGB(28,  28,  28 )   -- toggle off track
local TI  = TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI2 = TweenInfo.new(0.07, Enum.EasingStyle.Linear)

-- ── Window ────────────────────────────────────────────────────────────────
local WIN_W, WIN_H, TBAR_H = 360, 490, 46

local GUI=Instance.new("ScreenGui")
GUI.Name="NocturnixGUI"; GUI.ResetOnSpawn=false
GUI.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; GUI.Parent=CoreGui

local Window=Instance.new("Frame")
Window.Name="Window"; Window.Size=UDim2.new(0,WIN_W,0,WIN_H)
Window.Position=UDim2.new(0.5,-WIN_W/2,0.5,-WIN_H/2)
Window.BackgroundColor3=BK; Window.BorderSizePixel=0; Window.Parent=GUI
do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,10); c.Parent=Window end
do
    local s=Instance.new("UIStroke"); s.Color=Color3.fromRGB(30,30,30)
    s.Thickness=1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=Window
end

-- Title bar
local TBar=Instance.new("Frame")
TBar.Size=UDim2.new(1,0,0,TBAR_H); TBar.BackgroundColor3=BK
TBar.BorderSizePixel=0; TBar.Parent=Window
do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,10); c.Parent=TBar end
do
    local p=Instance.new("Frame"); p.Size=UDim2.new(1,0,0,10)
    p.Position=UDim2.new(0,0,1,-10); p.BackgroundColor3=BK; p.BorderSizePixel=0; p.Parent=TBar
end

-- Purple accent line under title
local TLine=Instance.new("Frame")
TLine.Size=UDim2.new(1,-24,0,1); TLine.Position=UDim2.new(0,12,1,-1)
TLine.BackgroundColor3=PUR; TLine.BackgroundTransparency=0.4
TLine.BorderSizePixel=0; TLine.Parent=TBar

-- Purple glow dot + title
local GlowDot=Instance.new("Frame")
GlowDot.Size=UDim2.new(0,7,0,7); GlowDot.Position=UDim2.new(0,14,0.5,-3.5)
GlowDot.BackgroundColor3=PUR; GlowDot.BorderSizePixel=0; GlowDot.Parent=TBar
do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=GlowDot end

local TitleLbl=Instance.new("TextLabel")
TitleLbl.Size=UDim2.new(1,-55,1,0); TitleLbl.Position=UDim2.new(0,28,0,0)
TitleLbl.BackgroundTransparency=1; TitleLbl.Text="Nocturnix"
TitleLbl.TextColor3=WHT; TitleLbl.Font=Enum.Font.GothamBold; TitleLbl.TextSize=15
TitleLbl.TextXAlignment=Enum.TextXAlignment.Left; TitleLbl.Parent=TBar

local MinBtn=Instance.new("TextButton")
MinBtn.Size=UDim2.new(0,26,0,26); MinBtn.Position=UDim2.new(1,-36,0.5,-13)
MinBtn.BackgroundColor3=PU2; MinBtn.Text="–"; MinBtn.TextColor3=WHT
MinBtn.Font=Enum.Font.GothamBold; MinBtn.TextSize=16; MinBtn.BorderSizePixel=0
MinBtn.AutoButtonColor=false; MinBtn.Parent=TBar
do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,6); c.Parent=MinBtn end
MinBtn.MouseEnter:Connect(function() TS:Create(MinBtn,TI2,{BackgroundColor3=PUR}):Play() end)
MinBtn.MouseLeave:Connect(function() TS:Create(MinBtn,TI2,{BackgroundColor3=PU2}):Play() end)

-- Drag
local _drag,_ds,_ws=false
TBar.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 then
        _drag=true; _ds=inp.Position; _ws=Window.Position
    end
end)
UIS.InputChanged:Connect(function(inp)
    if _drag and inp.UserInputType==Enum.UserInputType.MouseMovement then
        local d=inp.Position-_ds
        Window.Position=UDim2.new(_ws.X.Scale,_ws.X.Offset+d.X,_ws.Y.Scale,_ws.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 then _drag=false end
end)

local minimized=false
MinBtn.MouseButton1Click:Connect(function()
    minimized=not minimized
    TS:Create(Window,TI,{Size=UDim2.new(0,WIN_W,0,minimized and TBAR_H or WIN_H)}):Play()
    MinBtn.Text=minimized and "+" or "–"
end)

-- ── Scrollable content ────────────────────────────────────────────────────
local Page=Instance.new("ScrollingFrame")
Page.Name="Page"; Page.Size=UDim2.new(1,0,0,WIN_H-TBAR_H)
Page.Position=UDim2.new(0,0,0,TBAR_H); Page.BackgroundColor3=BK
Page.BorderSizePixel=0; Page.ScrollBarThickness=3
Page.ScrollBarImageColor3=PUR; Page.CanvasSize=UDim2.new(0,0,0,0)
Page.AutomaticCanvasSize=Enum.AutomaticSize.Y; Page.Parent=Window
do
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,10); c.Parent=Page
    local p=Instance.new("Frame"); p.Size=UDim2.new(1,0,0,10)
    p.BackgroundColor3=BK; p.BorderSizePixel=0; p.Parent=Page
end
do
    local l=Instance.new("UIListLayout"); l.SortOrder=Enum.SortOrder.LayoutOrder
    l.Padding=UDim.new(0,4); l.Parent=Page
    local p=Instance.new("UIPadding"); p.PaddingTop=UDim.new(0,10); p.PaddingBottom=UDim.new(0,14)
    p.PaddingLeft=UDim.new(0,12); p.PaddingRight=UDim.new(0,14); p.Parent=Page
end

-- ── UI builders ───────────────────────────────────────────────────────────
local function addSection(label)
    local h=Instance.new("Frame"); h.Size=UDim2.new(1,0,0,22)
    h.BackgroundTransparency=1; h.Parent=Page

    local line=Instance.new("Frame"); line.Size=UDim2.new(1,0,0,1)
    line.Position=UDim2.new(0,0,0.5,0); line.BackgroundColor3=Color3.fromRGB(22,22,22)
    line.BorderSizePixel=0; line.Parent=h

    local pill=Instance.new("Frame"); pill.Size=UDim2.new(0,4,0,14)
    pill.Position=UDim2.new(0,0,0.5,-7); pill.BackgroundColor3=PUR; pill.BorderSizePixel=0; pill.Parent=h
    do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=pill end

    local bg=Instance.new("Frame"); bg.Size=UDim2.new(0,#label*8+16,1,0)
    bg.Position=UDim2.new(0,0,0,0); bg.BackgroundColor3=BK; bg.BorderSizePixel=0; bg.Parent=h

    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(0,#label*8+10,1,0)
    lbl.Position=UDim2.new(0,10,0,0); lbl.BackgroundTransparency=1
    lbl.Text=label:upper(); lbl.TextColor3=PUR; lbl.Font=Enum.Font.GothamBold
    lbl.TextSize=10; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=h
end

local function addToggle(label, default, callback)
    local on=default or false
    local ON_POS=UDim2.new(1,-17,0.5,-7); local OFF_POS=UDim2.new(0,3,0.5,-7)

    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,38)
    row.BackgroundColor3=S1; row.BorderSizePixel=0; row.Parent=Page
    do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,7); c.Parent=row end

    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-68,1,0)
    lbl.Position=UDim2.new(0,12,0,0); lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.TextColor3=WHT; lbl.Font=Enum.Font.GothamMedium; lbl.TextSize=13
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row

    local track=Instance.new("Frame"); track.Size=UDim2.new(0,38,0,20)
    track.Position=UDim2.new(1,-50,0.5,-10); track.BackgroundColor3=on and PUR or TRK
    track.BorderSizePixel=0; track.Parent=row
    do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=track end

    local knob=Instance.new("Frame"); knob.Size=UDim2.new(0,14,0,14)
    knob.Position=on and ON_POS or OFF_POS; knob.BackgroundColor3=Color3.fromRGB(220,220,228)
    knob.BorderSizePixel=0; knob.Parent=track
    do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=knob end

    local hit=Instance.new("TextButton"); hit.Size=UDim2.new(1,0,1,0)
    hit.BackgroundTransparency=1; hit.Text=""; hit.Parent=row

    row.MouseEnter:Connect(function() TS:Create(row,TI2,{BackgroundColor3=S2}):Play() end)
    row.MouseLeave:Connect(function() TS:Create(row,TI2,{BackgroundColor3=S1}):Play() end)

    local function fire(val)
        if val==nil then val=not on end; on=val
        TS:Create(track,TI,{BackgroundColor3=on and PUR or TRK}):Play()
        TS:Create(knob,TI,{Position=on and ON_POS or OFF_POS}):Play()
        callback(on)
    end
    hit.MouseButton1Click:Connect(function() fire() end)
    return fire
end

local function addSlider(label, min, max, default, callback)
    local value=default or min

    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,50)
    row.BackgroundColor3=S1; row.BorderSizePixel=0; row.Parent=Page
    do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,7); c.Parent=row end

    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-70,0,22)
    lbl.Position=UDim2.new(0,12,0,6); lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.TextColor3=WHT; lbl.Font=Enum.Font.GothamMedium; lbl.TextSize=13
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row

    local valLbl=Instance.new("TextLabel"); valLbl.Size=UDim2.new(0,56,0,22)
    valLbl.Position=UDim2.new(1,-66,0,6); valLbl.BackgroundTransparency=1
    valLbl.Text=tostring(value); valLbl.TextColor3=PUR
    valLbl.Font=Enum.Font.GothamBold; valLbl.TextSize=13
    valLbl.TextXAlignment=Enum.TextXAlignment.Right; valLbl.Parent=row

    local bg=Instance.new("Frame"); bg.Size=UDim2.new(1,-24,0,5)
    bg.Position=UDim2.new(0,12,1,-15); bg.BackgroundColor3=TRK
    bg.BorderSizePixel=0; bg.Parent=row
    do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=bg end

    local fill=Instance.new("Frame"); fill.Size=UDim2.new((value-min)/(max-min),0,1,0)
    fill.BackgroundColor3=PUR; fill.BorderSizePixel=0; fill.Parent=bg
    do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=fill end

    local handle=Instance.new("Frame"); handle.Size=UDim2.new(0,13,0,13)
    handle.AnchorPoint=Vector2.new(0.5,0.5); handle.Position=UDim2.new((value-min)/(max-min),0,0.5,0)
    handle.BackgroundColor3=Color3.fromRGB(210,180,255); handle.BorderSizePixel=0; handle.Parent=bg
    do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(1,0); c.Parent=handle end

    row.MouseEnter:Connect(function() TS:Create(row,TI2,{BackgroundColor3=S2}):Play() end)
    row.MouseLeave:Connect(function() TS:Create(row,TI2,{BackgroundColor3=S1}):Play() end)

    local sd=false
    local hit=Instance.new("TextButton"); hit.Size=UDim2.new(1,0,0,22)
    hit.Position=UDim2.new(0,0,1,-22); hit.BackgroundTransparency=1; hit.Text=""; hit.Parent=row

    local function update(x)
        local ap=bg.AbsolutePosition; local sz=bg.AbsoluteSize
        local t=math.clamp((x-ap.X)/sz.X,0,1)
        value=math.floor(min+t*(max-min)+0.5)
        fill.Size=UDim2.new(t,0,1,0); handle.Position=UDim2.new(t,0,0.5,0)
        valLbl.Text=tostring(value); callback(value)
    end
    hit.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then sd=true; update(inp.Position.X) end
    end)
    UIS.InputChanged:Connect(function(inp)
        if sd and inp.UserInputType==Enum.UserInputType.MouseMovement then update(inp.Position.X) end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then sd=false end
    end)
end

local function addDropdown(label, options, callback)
    local selected=options[1] or "None"
    local open=false; local OPT_H=28; local totalH=#options*OPT_H

    local wrapper=Instance.new("Frame"); wrapper.Size=UDim2.new(1,0,0,38)
    wrapper.BackgroundTransparency=1; wrapper.ClipsDescendants=false; wrapper.Parent=Page

    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,38)
    row.BackgroundColor3=S1; row.BorderSizePixel=0; row.ZIndex=2; row.Parent=wrapper
    do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,7); c.Parent=row end

    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(0.42,0,1,0)
    lbl.Position=UDim2.new(0,12,0,0); lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.TextColor3=WHT; lbl.Font=Enum.Font.GothamMedium; lbl.TextSize=13
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=2; lbl.Parent=row

    local selLbl=Instance.new("TextLabel"); selLbl.Size=UDim2.new(0.52,-28,1,0)
    selLbl.Position=UDim2.new(0.44,0,0,0); selLbl.BackgroundTransparency=1; selLbl.Text=selected
    selLbl.TextColor3=PUR; selLbl.Font=Enum.Font.GothamMedium; selLbl.TextSize=12
    selLbl.TextXAlignment=Enum.TextXAlignment.Right; selLbl.ZIndex=2; selLbl.Parent=row

    local arrow=Instance.new("TextLabel"); arrow.Size=UDim2.new(0,22,1,0)
    arrow.Position=UDim2.new(1,-24,0,0); arrow.BackgroundTransparency=1; arrow.Text="▾"
    arrow.TextColor3=DIM; arrow.Font=Enum.Font.GothamBold; arrow.TextSize=13
    arrow.ZIndex=2; arrow.Parent=row

    local drop=Instance.new("Frame"); drop.Size=UDim2.new(1,0,0,math.min(totalH,112))
    drop.Position=UDim2.new(0,0,1,3); drop.BackgroundColor3=Color3.fromRGB(8,8,8)
    drop.BorderSizePixel=0; drop.ClipsDescendants=true; drop.ZIndex=10
    drop.Visible=false; drop.Parent=row
    do
        local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,7); c.Parent=drop
        local s=Instance.new("UIStroke"); s.Color=Color3.fromRGB(35,35,35); s.Thickness=1; s.Parent=drop
    end

    local ds=Instance.new("ScrollingFrame"); ds.Size=UDim2.new(1,0,1,0)
    ds.BackgroundTransparency=1; ds.BorderSizePixel=0; ds.ScrollBarThickness=2
    ds.ScrollBarImageColor3=PUR; ds.CanvasSize=UDim2.new(0,0,0,totalH); ds.ZIndex=10; ds.Parent=drop
    do local l=Instance.new("UIListLayout"); l.SortOrder=Enum.SortOrder.LayoutOrder; l.Parent=ds end

    for _,opt in ipairs(options) do
        local ob=Instance.new("TextButton"); ob.Size=UDim2.new(1,0,0,OPT_H)
        ob.BackgroundColor3=Color3.fromRGB(8,8,8); ob.Text="   "..opt; ob.TextColor3=DIM
        ob.Font=Enum.Font.GothamMedium; ob.TextSize=12; ob.BorderSizePixel=0
        ob.AutoButtonColor=false; ob.TextXAlignment=Enum.TextXAlignment.Left; ob.ZIndex=11; ob.Parent=ds
        ob.MouseEnter:Connect(function() ob.TextColor3=WHT; ob.BackgroundColor3=Color3.fromRGB(18,18,18) end)
        ob.MouseLeave:Connect(function() ob.TextColor3=DIM; ob.BackgroundColor3=Color3.fromRGB(8,8,8) end)
        ob.MouseButton1Click:Connect(function()
            selected=opt; selLbl.Text=opt; open=false
            drop.Visible=false; arrow.Text="▾"; callback(opt)
        end)
    end

    row.MouseEnter:Connect(function() if not open then TS:Create(row,TI2,{BackgroundColor3=S2}):Play() end end)
    row.MouseLeave:Connect(function() if not open then TS:Create(row,TI2,{BackgroundColor3=S1}):Play() end end)

    local hit=Instance.new("TextButton"); hit.Size=UDim2.new(1,0,1,0)
    hit.BackgroundTransparency=1; hit.Text=""; hit.ZIndex=3; hit.Parent=row
    hit.MouseButton1Click:Connect(function()
        open=not open; drop.Visible=open; arrow.Text=open and "▴" or "▾"
        TS:Create(row,TI2,{BackgroundColor3=open and S2 or S1}):Play()
    end)
end

local function addKeybindRow(label, featureKey)
    local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,38)
    row.BackgroundColor3=S1; row.BorderSizePixel=0; row.Parent=Page
    do local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,7); c.Parent=row end

    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-112,1,0)
    lbl.Position=UDim2.new(0,12,0,0); lbl.BackgroundTransparency=1; lbl.Text=label
    lbl.TextColor3=WHT; lbl.Font=Enum.Font.GothamMedium; lbl.TextSize=13
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row

    local kc0=keybindMap[featureKey]
    local initName=kc0~=Enum.KeyCode.Unknown and kc0.Name or "None"

    local kBtn=Instance.new("TextButton"); kBtn.Size=UDim2.new(0,90,0,26)
    kBtn.Position=UDim2.new(1,-102,0.5,-13)
    kBtn.BackgroundColor3=initName=="None" and TRK or PU2
    kBtn.Text=initName; kBtn.TextColor3=initName=="None" and DIM or WHT
    kBtn.Font=Enum.Font.GothamSemibold; kBtn.TextSize=11; kBtn.BorderSizePixel=0
    kBtn.AutoButtonColor=false; kBtn.Parent=row
    do
        local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,5); c.Parent=kBtn
        local s=Instance.new("UIStroke"); s.Color=Color3.fromRGB(35,35,35); s.Thickness=1; s.Parent=kBtn
    end

    row.MouseEnter:Connect(function() TS:Create(row,TI2,{BackgroundColor3=S2}):Play() end)
    row.MouseLeave:Connect(function() TS:Create(row,TI2,{BackgroundColor3=S1}):Play() end)

    local function setLabel(text)
        kBtn.Text=text; kBtn.BackgroundColor3=text=="None" and TRK or PU2
        kBtn.TextColor3=text=="None" and DIM or WHT
    end
    local function resetBtn()
        local k=keybindMap[featureKey]; setLabel(k~=Enum.KeyCode.Unknown and k.Name or "None")
    end

    kBtn.MouseButton1Click:Connect(function()
        if kbListening then kbListening.reset(); kbListening=nil end
        kBtn.Text="Press key..."; kBtn.BackgroundColor3=PUR; kBtn.TextColor3=WHT
        kbListening={key=featureKey,setLabel=setLabel,reset=resetBtn}
    end)
    kBtn.MouseEnter:Connect(function()
        if kbListening and kbListening.key==featureKey then return end
        TS:Create(kBtn,TI2,{BackgroundColor3=kBtn.BackgroundColor3==TRK and S2 or PUR}):Play()
    end)
    kBtn.MouseLeave:Connect(function()
        if kbListening and kbListening.key==featureKey then return end
        TS:Create(kBtn,TI2,{BackgroundColor3=keybindMap[featureKey]~=Enum.KeyCode.Unknown and PU2 or TRK}):Play()
    end)
end

-- ── Build UI ──────────────────────────────────────────────────────────────
addSection("Speed")
local speedFire = addToggle("Speed", false, function(v) regularSpeedEnabled=v; updateHUD() end)
keybindTogglers.speed = speedFire
addSlider("Speed Value", 10, 200, 20, function(v) regularSpeed=v end)

local bombSpeedFire = addToggle("Bomb Speed", false, function(v) bombSpeedEnabled=v; updateHUD() end)
keybindTogglers.bombSpeed = bombSpeedFire
addSlider("Bomb Speed Value", 10, 200, 25, function(v) bombSpeed=v end)

local spinFire = addToggle("Spin Bot", false, function(v) spinEnabled=v; if not v then spinAngle=0 end; updateHUD() end)
keybindTogglers.spinBot = spinFire

addSection("Combat")
local infJumpFire = addToggle("Infinite Jump", false, function(v) infiniteJumpEnabled=v; updateHUD() end)
keybindTogglers.infiniteJump = infJumpFire
local noclipFire = addToggle("Noclip", false, function(v) noclipEnabled=v; updateHUD() end)
keybindTogglers.noclip = noclipFire

addSection("Settings")
addToggle("Frozen Check", true,  function(v) frozenCheckEnabled=v end)
addToggle("Ladder Check", true,  function(v) ladderCheckEnabled=v end)

addSection("Visuals")
addDropdown("Scene", {"None","Ultra Realism","Golden Valley","Rainy Night","Neon City","Frostbite","Cinematic","Blood Moon","Silent Fog"}, function(v)
    if v=="None" then resetLighting() else local p=SCENE_PRESETS[v]; if p then applyLightingPreset(p) end end
end)
addDropdown("Weather", {"None","Clear","Cloudy","Foggy","Rainy","Stormy","Sunrise","Blizzard","Firefly"}, function(v)
    if v=="None" then resetLighting() else local p=WEATHER_PRESETS[v]; if p then applyLightingPreset(p) end end
end)
addToggle("No Particles", false, function(v) setNoParticles(v) end)
addToggle("No Lights",    false, function(v) setNoLights(v) end)
addToggle("No PostFX",    false, function(v) setNoPostFX(v) end)
addToggle("Low Graphics", false, function(v) setLowGraphics(v) end)

addSection("Keybinds")
addKeybindRow("Speed",         "speed")
addKeybindRow("Bomb Speed",    "bombSpeed")
addKeybindRow("Spin Bot",      "spinBot")
addKeybindRow("Infinite Jump", "infiniteJump")
addKeybindRow("Noclip",        "noclip")

-- ── Keybind dispatch ──────────────────────────────────────────────────────
UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if kbListening then
        if inp.KeyCode==Enum.KeyCode.Escape then
            keybindMap[kbListening.key]=Enum.KeyCode.Unknown; kbListening.setLabel("None")
        elseif inp.KeyCode~=Enum.KeyCode.Unknown then
            keybindMap[kbListening.key]=inp.KeyCode; kbListening.setLabel(inp.KeyCode.Name)
        end
        kbListening.reset(); kbListening=nil; return
    end
    for featureKey,kc in pairs(keybindMap) do
        if kc~=Enum.KeyCode.Unknown and inp.KeyCode==kc then
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
    for _,part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then part.CanCollide=false end
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
        for _,v in ipairs(hrp:GetChildren()) do
            if v:IsA("BodyPosition") or v:IsA("BodyVelocity") then return end
        end
    end
    if ladderCheckEnabled and isOnLadder(hum) then return end
    local dir=hum.MoveDirection; local speed=0
    if hasBomb() then
        if bombSpeedEnabled then speed=bombSpeed end
    elseif regularSpeedEnabled then speed=regularSpeed end
    local newCF=hrp.CFrame
    if speed>0 and dir.Magnitude>0 then newCF=newCF+dir*speed*dt end
    if spinEnabled then
        spinAngle=(spinAngle+20*dt)%(2*math.pi)
        newCF=CFrame.new(newCF.Position)*CFrame.Angles(0,spinAngle,0)
    end
    if newCF~=hrp.CFrame then hrp.CFrame=newCF end
end)
