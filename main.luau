-- Services
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local TS         = game:GetService("TweenService")
local Lighting   = game:GetService("Lighting")
local CoreGui    = game:GetService("CoreGui")
local LP         = Players.LocalPlayer

-- Feature state
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
    local c=LP.Character; return c and (c:FindFirstChild("bomb") or c:FindFirstChild("Bomb"))~=nil
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

-- Keybind state  (menu = toggle GUI visible)
local keybindMap = {
    menu=Enum.KeyCode.Unknown, speed=Enum.KeyCode.Unknown,
    bombSpeed=Enum.KeyCode.Unknown, spinBot=Enum.KeyCode.Unknown,
    infiniteJump=Enum.KeyCode.Unknown, noclip=Enum.KeyCode.Unknown,
}
local keybindToggles = {}   -- fire(nil) = toggle, fire(bool) = set
local kbListening    = nil

-- Palette
local BK  = Color3.fromRGB(0,   0,   0  )
local S1  = Color3.fromRGB(11,  11,  11 )
local S2  = Color3.fromRGB(20,  20,  20 )
local PUR = Color3.fromRGB(165, 95,  255)
local WHT = Color3.fromRGB(228, 228, 232)
local DIM = Color3.fromRGB(90,  90,  100)
local TRK = Color3.fromRGB(28,  28,  28 )
local TI  = TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI2 = TweenInfo.new(0.07, Enum.EasingStyle.Linear)

-- ScreenGui
local SG = Instance.new("ScreenGui")
SG.Name = "TimeBomb_GUI"; SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; SG.DisplayOrder = 50
pcall(function() SG.Parent = CoreGui end)
if not SG.Parent then SG.Parent = LP.PlayerGui end

-- Window: 500 x 338
local WIN = Instance.new("Frame")
WIN.Name = "Win"; WIN.Size = UDim2.new(0,500,0,338)
WIN.Position = UDim2.new(0.5,-250,0.5,-169)
WIN.BackgroundColor3 = BK; WIN.BorderSizePixel = 0
WIN.Parent = SG
Instance.new("UICorner",WIN).CornerRadius = UDim.new(0,8)
local ws = Instance.new("UIStroke",WIN); ws.Color=Color3.fromRGB(38,38,38); ws.Thickness=1

-- Clip holder (clips body content without clipping dropdowns)
local CLIP = Instance.new("Frame")
CLIP.Size = UDim2.new(1,0,1,0); CLIP.BackgroundTransparency = 1
CLIP.ClipsDescendants = true; CLIP.ZIndex = 1; CLIP.Parent = WIN

-- Title bar: 44px
local TBAR = Instance.new("Frame")
TBAR.Size = UDim2.new(1,0,0,44); TBAR.BackgroundColor3 = BK
TBAR.BorderSizePixel = 0; TBAR.ZIndex = 5; TBAR.Parent = CLIP

local TACC = Instance.new("Frame")
TACC.Size = UDim2.new(1,0,0,2); TACC.Position = UDim2.new(0,0,1,-2)
TACC.BackgroundColor3 = PUR; TACC.BorderSizePixel = 0; TACC.ZIndex = 6; TACC.Parent = TBAR

local TTITLE = Instance.new("TextLabel")
TTITLE.Size = UDim2.new(0,120,1,0); TTITLE.Position = UDim2.new(0,14,0,0)
TTITLE.BackgroundTransparency = 1; TTITLE.Text = "TIMEBOMB"
TTITLE.TextColor3 = WHT; TTITLE.Font = Enum.Font.GothamBold
TTITLE.TextSize = 15; TTITLE.TextXAlignment = Enum.TextXAlignment.Left
TTITLE.ZIndex = 6; TTITLE.Parent = TBAR

local TSUB = Instance.new("TextLabel")
TSUB.Size = UDim2.new(0,60,1,0); TSUB.Position = UDim2.new(0,112,0,0)
TSUB.BackgroundTransparency = 1; TSUB.Text = "DUELS"
TSUB.TextColor3 = PUR; TSUB.Font = Enum.Font.Gotham
TSUB.TextSize = 11; TSUB.TextXAlignment = Enum.TextXAlignment.Left
TSUB.ZIndex = 6; TSUB.Parent = TBAR

local TMIN = Instance.new("TextButton")
TMIN.Size = UDim2.new(0,24,0,24); TMIN.Position = UDim2.new(1,-38,0.5,-12)
TMIN.BackgroundColor3 = Color3.fromRGB(28,28,28); TMIN.Text = "−"
TMIN.TextColor3 = DIM; TMIN.Font = Enum.Font.GothamBold
TMIN.TextSize = 14; TMIN.BorderSizePixel = 0; TMIN.ZIndex = 6; TMIN.Parent = TBAR
Instance.new("UICorner",TMIN).CornerRadius = UDim.new(0,5)

-- Drag
local dragActive,dragStart,dragOrigin = false,nil,nil
TBAR.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 then
        dragActive=true; dragStart=inp.Position; dragOrigin=WIN.Position
    end
end)
TBAR.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragActive=false end
end)
UIS.InputChanged:Connect(function(inp)
    if dragActive and inp.UserInputType==Enum.UserInputType.MouseMovement then
        local d=inp.Position-dragStart
        WIN.Position=UDim2.new(dragOrigin.X.Scale,dragOrigin.X.Offset+d.X,
                                dragOrigin.Y.Scale,dragOrigin.Y.Offset+d.Y)
    end
end)

-- Body
local BODY = Instance.new("Frame")
BODY.Size = UDim2.new(1,0,1,-44); BODY.Position = UDim2.new(0,0,0,44)
BODY.BackgroundTransparency = 1; BODY.Parent = CLIP

-- Sidebar: 95px
local SIDE = Instance.new("Frame")
SIDE.Size = UDim2.new(0,95,1,0)
SIDE.BackgroundColor3 = Color3.fromRGB(5,5,5)
SIDE.BorderSizePixel = 0; SIDE.Parent = BODY

local SBR = Instance.new("Frame")
SBR.Size = UDim2.new(0,1,1,0); SBR.Position = UDim2.new(1,-1,0,0)
SBR.BackgroundColor3 = Color3.fromRGB(32,32,32); SBR.BorderSizePixel = 0; SBR.Parent = SIDE

-- Content panel (no ClipsDescendants — CLIP handles that)
local CONTENT = Instance.new("Frame")
CONTENT.Size = UDim2.new(1,-96,1,0); CONTENT.Position = UDim2.new(0,96,0,0)
CONTENT.BackgroundColor3 = BK; CONTENT.BorderSizePixel = 0; CONTENT.Parent = BODY

-- Dropdown overlay layer (above CLIP, never clipped)
local OVERLAY = Instance.new("Frame")
OVERLAY.Size = UDim2.new(1,0,1,0); OVERLAY.BackgroundTransparency = 1
OVERLAY.ZIndex = 50; OVERLAY.Parent = WIN

-- HUD
local HUD = Instance.new("ScreenGui")
HUD.Name = "TimeBomb_HUD"; HUD.ResetOnSpawn = false; HUD.DisplayOrder = 49
pcall(function() HUD.Parent = CoreGui end)
if not HUD.Parent then HUD.Parent = LP.PlayerGui end

local hudFrame = Instance.new("Frame")
hudFrame.Size = UDim2.new(0,118,0,88); hudFrame.Position = UDim2.new(0,5,0.5,-44)
hudFrame.BackgroundColor3 = BK; hudFrame.BackgroundTransparency = 0.3
hudFrame.BorderSizePixel = 0; hudFrame.Parent = HUD
Instance.new("UICorner",hudFrame).CornerRadius = UDim.new(0,6)

local hudLabels = {}
local hudNames  = {"Speed","Bomb Spd","Spin Bot","Inf Jump","Noclip"}
for i,n in ipairs(hudNames) do
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,14); lbl.Position = UDim2.new(0,7,0,4+(i-1)*16)
    lbl.BackgroundTransparency = 1; lbl.Text = n..": OFF"
    lbl.TextColor3 = DIM; lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = hudFrame
    hudLabels[n] = lbl
end

local function updateHUD()
    local s={["Speed"]=regularSpeedEnabled,["Bomb Spd"]=bombSpeedEnabled,
             ["Spin Bot"]=spinEnabled,["Inf Jump"]=infiniteJumpEnabled,["Noclip"]=noclipEnabled}
    for n,lbl in pairs(hudLabels) do
        lbl.Text = n..": "..(s[n] and "ON" or "OFF")
        lbl.TextColor3 = s[n] and PUR or DIM
    end
end

-- ======== TAB SYSTEM ========
local tabButtons = {}
local tabPages   = {}
local activeTab  = nil

local function switchTab(name)
    if activeTab==name then return end
    activeTab = name
    for n,t in pairs(tabButtons) do
        local a = (n==name)
        t.bar.BackgroundColor3 = a and PUR or BK
        t.lbl.TextColor3       = a and WHT or DIM
        t.btn.BackgroundColor3 = a and S1  or BK
    end
    for n,pg in pairs(tabPages) do pg.Visible=(n==name) end
end

local tabOrder = {"Speed","Combat","Settings","Visuals","Keys"}
local sideY    = 10

for _,tname in ipairs(tabOrder) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,-1,0,34); btn.Position = UDim2.new(0,0,0,sideY)
    btn.BackgroundColor3 = BK; btn.BorderSizePixel = 0
    btn.Text = ""; btn.AutoButtonColor = false; btn.Parent = SIDE

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0,3,1,0)
    bar.BackgroundColor3 = BK; bar.BorderSizePixel = 0; bar.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-3,1,0); lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = tname
    lbl.TextColor3 = DIM; lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12; lbl.Parent = btn

    tabButtons[tname] = {btn=btn,bar=bar,lbl=lbl}
    sideY = sideY + 36

    local pg = Instance.new("ScrollingFrame")
    pg.Size = UDim2.new(1,0,1,0); pg.BackgroundTransparency = 1
    pg.BorderSizePixel = 0; pg.ScrollBarThickness = 3
    pg.ScrollBarImageColor3 = PUR; pg.CanvasSize = UDim2.new(0,0,0,0)
    pg.AutomaticCanvasSize = Enum.AutomaticSize.Y
    pg.Visible = false; pg.Parent = CONTENT

    local uil = Instance.new("UIListLayout",pg)
    uil.SortOrder = Enum.SortOrder.LayoutOrder; uil.Padding = UDim.new(0,0)

    tabPages[tname] = pg

    btn.MouseButton1Click:Connect(function() switchTab(tname) end)
    btn.MouseEnter:Connect(function()
        if activeTab~=tname then TS:Create(btn,TI2,{BackgroundColor3=S1}):Play() end
    end)
    btn.MouseLeave:Connect(function()
        if activeTab~=tname then TS:Create(btn,TI2,{BackgroundColor3=BK}):Play() end
    end)
end

switchTab("Speed")

-- ======== ELEMENT BUILDERS ========
local function newSection(pg, label)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,28); row.BackgroundTransparency = 1
    row.LayoutOrder = 0; row.Parent = pg

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0,3,0,12); pill.Position = UDim2.new(0,10,0.5,-6)
    pill.BackgroundColor3 = PUR; pill.BorderSizePixel = 0; pill.Parent = row
    Instance.new("UICorner",pill).CornerRadius = UDim.new(1,0)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-20,1,0); lbl.Position = UDim2.new(0,20,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = label:upper()
    lbl.TextColor3 = Color3.fromRGB(75,75,88); lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
end

-- fire(nil) = toggle, fire(bool) = set
local function newToggle(pg, label, default, onChange, lo)
    local enabled = default or false

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,36); row.BackgroundColor3 = S1
    row.BorderSizePixel = 0; row.LayoutOrder = lo or 1; row.Parent = pg

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-58,1,0); lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = label
    lbl.TextColor3 = WHT; lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0,36,0,18); track.Position = UDim2.new(1,-46,0.5,-9)
    track.BackgroundColor3 = enabled and PUR or TRK
    track.BorderSizePixel = 0; track.Parent = row
    Instance.new("UICorner",track).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0,12,0,12)
    knob.Position = enabled and UDim2.new(1,-15,0.5,-6) or UDim2.new(0,3,0.5,-6)
    knob.BackgroundColor3 = Color3.fromRGB(220,220,220)
    knob.BorderSizePixel = 0; knob.Parent = track
    Instance.new("UICorner",knob).CornerRadius = UDim.new(1,0)

    local function fire(val)
        if val==nil then val = not enabled end
        enabled = val
        TS:Create(track,TI,{BackgroundColor3=enabled and PUR or TRK}):Play()
        TS:Create(knob,TI,{Position=enabled and UDim2.new(1,-15,0.5,-6) or UDim2.new(0,3,0.5,-6)}):Play()
        if onChange then onChange(enabled) end
    end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""; btn.Parent = row
    btn.MouseButton1Click:Connect(function() fire(nil) end)
    btn.MouseEnter:Connect(function() TS:Create(row,TI2,{BackgroundColor3=S2}):Play() end)
    btn.MouseLeave:Connect(function() TS:Create(row,TI2,{BackgroundColor3=S1}):Play() end)

    fire(default or false)
    return fire
end

local function newSlider(pg, label, min, max, default, onChange, lo)
    local val = default or min

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,46); row.BackgroundColor3 = S1
    row.BorderSizePixel = 0; row.LayoutOrder = lo or 1; row.Parent = pg

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.65,0,0,20); lbl.Position = UDim2.new(0,12,0,5)
    lbl.BackgroundTransparency = 1; lbl.Text = label
    lbl.TextColor3 = WHT; lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0.35,-12,0,20); valLbl.Position = UDim2.new(0.65,0,0,5)
    valLbl.BackgroundTransparency = 1; valLbl.Text = tostring(val)
    valLbl.TextColor3 = PUR; valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 13; valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1,-24,0,4); track.Position = UDim2.new(0,12,1,-14)
    track.BackgroundColor3 = TRK; track.BorderSizePixel = 0; track.Parent = row
    Instance.new("UICorner",track).CornerRadius = UDim.new(1,0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((val-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = PUR; fill.BorderSizePixel = 0; fill.Parent = track
    Instance.new("UICorner",fill).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0,12,0,12)
    knob.Position = UDim2.new((val-min)/(max-min),-6,0.5,-6)
    knob.BackgroundColor3 = WHT; knob.BorderSizePixel = 0
    knob.Text = ""; knob.AutoButtonColor = false; knob.Parent = track
    Instance.new("UICorner",knob).CornerRadius = UDim.new(1,0)

    local sliding = false
    local function update(mx)
        local t=math.clamp((mx-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        val=math.floor(min+t*(max-min)+0.5)
        fill.Size=UDim2.new(t,0,1,0); knob.Position=UDim2.new(t,-6,0.5,-6)
        valLbl.Text=tostring(val); if onChange then onChange(val) end
    end
    knob.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then sliding=true end
    end)
    UIS.InputChanged:Connect(function(inp)
        if sliding and inp.UserInputType==Enum.UserInputType.MouseMovement then update(inp.Position.X) end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end
    end)
end

-- Dropdown: popup is parented to OVERLAY so it's never clipped by scroll frames
local function newDropdown(pg, label, choices, onChange, lo)
    local open  = false
    local popup = nil   -- created lazily on first open

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,36); row.BackgroundColor3 = S1
    row.BorderSizePixel = 0; row.LayoutOrder = lo or 1; row.Parent = pg

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-50,1,0); lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = label
    lbl.TextColor3 = WHT; lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0,30,1,0); arrow.Position = UDim2.new(1,-40,0,0)
    arrow.BackgroundTransparency = 1; arrow.Text = "▾"
    arrow.TextColor3 = PUR; arrow.Font = Enum.Font.Gotham
    arrow.TextSize = 14; arrow.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1
    btn.Text = ""; btn.ZIndex = 2; btn.Parent = row

    local function closePopup()
        open = false; arrow.Text = "▾"
        if popup then popup.Visible = false end
    end

    local function openPopup()
        -- Build popup on first use
        if not popup then
            popup = Instance.new("Frame")
            popup.BackgroundColor3 = Color3.fromRGB(14,14,14)
            popup.BorderSizePixel = 0; popup.ZIndex = 51; popup.Parent = OVERLAY
            Instance.new("UIStroke",popup).Color = Color3.fromRGB(50,50,50)

            local uil = Instance.new("UIListLayout",popup)
            uil.SortOrder = Enum.SortOrder.LayoutOrder

            for i,ch in ipairs(choices) do
                local item = Instance.new("TextButton")
                item.Size = UDim2.new(1,0,0,28); item.LayoutOrder = i
                item.BackgroundColor3 = Color3.fromRGB(14,14,14); item.BorderSizePixel = 0
                item.Text = ch; item.TextColor3 = DIM; item.Font = Enum.Font.Gotham
                item.TextSize = 12; item.AutoButtonColor = false; item.ZIndex = 52; item.Parent = popup

                item.MouseEnter:Connect(function() item.BackgroundColor3=S2; item.TextColor3=WHT end)
                item.MouseLeave:Connect(function() item.BackgroundColor3=Color3.fromRGB(14,14,14); item.TextColor3=DIM end)
                item.MouseButton1Click:Connect(function()
                    lbl.Text = label..": "..ch
                    closePopup()
                    if onChange then onChange(ch) end
                end)
            end
        end

        -- Position relative to WIN using AbsolutePosition
        local abs  = row.AbsolutePosition
        local wAbs = WIN.AbsolutePosition
        local rx   = abs.X - wAbs.X
        local ry   = abs.Y - wAbs.Y + 36
        local w    = row.AbsoluteSize.X
        local h    = #choices * 28

        -- Clamp so it doesn't go below WIN
        local winH = WIN.AbsoluteSize.Y
        if ry + h > winH then ry = ry - h - 36 end

        popup.Position = UDim2.new(0,rx,0,ry)
        popup.Size     = UDim2.new(0,w,0,h)
        popup.Visible  = true
    end

    btn.MouseButton1Click:Connect(function()
        open = not open
        if open then openPopup() else closePopup() end
        arrow.Text = open and "▴" or "▾"
    end)
    btn.MouseEnter:Connect(function() TS:Create(row,TI2,{BackgroundColor3=S2}):Play() end)
    btn.MouseLeave:Connect(function() TS:Create(row,TI2,{BackgroundColor3=S1}):Play() end)
end

local function newKeybindRow(pg, featureKey, featureLabel, lo)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,36); row.BackgroundColor3 = S1
    row.BorderSizePixel = 0; row.LayoutOrder = lo or 1; row.Parent = pg

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-90,1,0); lbl.Position = UDim2.new(0,12,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = featureLabel
    lbl.TextColor3 = WHT; lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row

    local kbBtn = Instance.new("TextButton")
    kbBtn.Size = UDim2.new(0,72,0,22); kbBtn.Position = UDim2.new(1,-82,0.5,-11)
    kbBtn.BackgroundColor3 = TRK; kbBtn.Text = "NONE"
    kbBtn.TextColor3 = DIM; kbBtn.Font = Enum.Font.GothamBold
    kbBtn.TextSize = 11; kbBtn.BorderSizePixel = 0; kbBtn.Parent = row
    Instance.new("UICorner",kbBtn).CornerRadius = UDim.new(0,4)

    local function setLabel(kc)
        if kc==Enum.KeyCode.Unknown then kbBtn.Text="NONE"; kbBtn.TextColor3=DIM
        else kbBtn.Text=kc.Name; kbBtn.TextColor3=PUR end
    end

    kbBtn.MouseButton1Click:Connect(function()
        if kbListening and kbListening.key==featureKey then
            kbListening.reset(); kbListening=nil; return
        end
        if kbListening then kbListening.reset() end
        kbBtn.Text="..."; kbBtn.TextColor3=PUR
        kbListening={key=featureKey,setLabel=setLabel,
            reset=function() setLabel(keybindMap[featureKey]) end}
    end)

    setLabel(keybindMap[featureKey])
    row.MouseEnter:Connect(function() TS:Create(row,TI2,{BackgroundColor3=S2}):Play() end)
    row.MouseLeave:Connect(function() TS:Create(row,TI2,{BackgroundColor3=S1}):Play() end)
end

-- ======== POPULATE TABS ========

-- SPEED  (sliders now go down to 1)
do
    local pg = tabPages["Speed"]
    newSection(pg,"Regular Movement")
    keybindToggles["speed"] = newToggle(pg,"Speed Boost",false,function(v)
        regularSpeedEnabled=v; updateHUD() end, 2)
    newSlider(pg,"Speed Value",1,100,20,function(v) regularSpeed=v end, 3)
    newSection(pg,"Bomb Movement")
    keybindToggles["bombSpeed"] = newToggle(pg,"Bomb Speed",false,function(v)
        bombSpeedEnabled=v; updateHUD() end, 5)
    newSlider(pg,"Bomb Speed Value",1,100,25,function(v) bombSpeed=v end, 6)
    newSection(pg,"Checks")
    newToggle(pg,"Ladder Check",true,function(v) ladderCheckEnabled=v end, 8)
    newToggle(pg,"Frozen Check",true,function(v) frozenCheckEnabled=v end, 9)
end

-- COMBAT
do
    local pg = tabPages["Combat"]
    newSection(pg,"Bot")
    keybindToggles["spinBot"] = newToggle(pg,"Spin Bot",false,function(v)
        spinEnabled=v; updateHUD() end, 2)
    newSection(pg,"Movement")
    keybindToggles["infiniteJump"] = newToggle(pg,"Infinite Jump",false,function(v)
        infiniteJumpEnabled=v; updateHUD() end, 4)
    keybindToggles["noclip"] = newToggle(pg,"Noclip",false,function(v)
        noclipEnabled=v; updateHUD() end, 5)
end

-- SETTINGS
do
    local pg = tabPages["Settings"]
    newSection(pg,"Performance")
    newToggle(pg,"Disable Particles",false,function(v)
        for _,d in ipairs(game.Workspace:GetDescendants()) do
            if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then d.Enabled=not v end
        end end, 2)
    newToggle(pg,"Disable Lights",false,function(v)
        for _,d in ipairs(game.Workspace:GetDescendants()) do
            if d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then d.Enabled=not v end
        end end, 3)
    newToggle(pg,"Disable Post FX",false,function(v)
        for _,d in ipairs(Lighting:GetDescendants()) do
            if d:IsA("PostEffect") then d.Enabled=not v end
        end end, 4)
    newToggle(pg,"Disable Textures",false,function(v)
        for _,d in ipairs(game.Workspace:GetDescendants()) do
            if d:IsA("Texture") or d:IsA("Decal") then d.Transparency=v and 1 or 0 end
        end end, 5)
    newSection(pg,"GUI")
    newToggle(pg,"Show HUD",true,function(v) hudFrame.Visible=v end, 7)
end

-- VISUALS
do
    local pg = tabPages["Visuals"]
    local function applyPreset(p)
        Lighting.Brightness=p.brightness
        Lighting.Ambient=Color3.fromRGB(unpack(p.ambient))
        Lighting.OutdoorAmbient=Color3.fromRGB(unpack(p.outdoor))
        Lighting.FogEnd=p.fog
        Lighting.FogColor=Color3.fromRGB(unpack(p.fogcol))
        Lighting.ClockTime=p.clock
    end
    newSection(pg,"Scene")
    local sn={}; for n in pairs(SCENE_PRESETS) do sn[#sn+1]=n end; table.sort(sn)
    newDropdown(pg,"Scene Preset",sn,function(v) applyPreset(SCENE_PRESETS[v]) end, 2)
    newSection(pg,"Weather")
    local wn={}; for n in pairs(WEATHER_PRESETS) do wn[#wn+1]=n end; table.sort(wn)
    newDropdown(pg,"Weather Preset",wn,function(v) applyPreset(WEATHER_PRESETS[v]) end, 4)
    newSection(pg,"Reset")
    newToggle(pg,"Reset Lighting",false,function(v)
        if v then
            Lighting.Brightness=origLight.Brightness; Lighting.Ambient=origLight.Ambient
            Lighting.OutdoorAmbient=origLight.OutdoorAmbient; Lighting.FogEnd=origLight.FogEnd
            Lighting.FogColor=origLight.FogColor; Lighting.ClockTime=origLight.ClockTime
        end end, 6)
end

-- KEYS  (menu toggle at top)
do
    local pg = tabPages["Keys"]
    newSection(pg,"Keybinds")
    newKeybindRow(pg,"menu",        "Menu Toggle",   2)
    newKeybindRow(pg,"speed",       "Speed Boost",   3)
    newKeybindRow(pg,"bombSpeed",   "Bomb Speed",    4)
    newKeybindRow(pg,"spinBot",     "Spin Bot",      5)
    newKeybindRow(pg,"infiniteJump","Infinite Jump", 6)
    newKeybindRow(pg,"noclip",      "Noclip",        7)
end

-- ======== MINIMIZE ========
TMIN.MouseButton1Click:Connect(function()
    local mini = BODY.Visible
    BODY.Visible = not mini
    WIN.Size = mini and UDim2.new(0,500,0,44) or UDim2.new(0,500,0,338)
    TMIN.Text = mini and "+" or "−"
end)

-- ======== INPUT ========
UIS.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    if inp.UserInputType~=Enum.UserInputType.Keyboard then return end

    if kbListening then
        local kc=inp.KeyCode
        if kc==Enum.KeyCode.Escape then kbListening.reset(); kbListening=nil; return end
        keybindMap[kbListening.key]=kc; kbListening.setLabel(kc); kbListening=nil; return
    end

    -- Menu toggle
    local mk = keybindMap["menu"]
    if mk~=Enum.KeyCode.Unknown and inp.KeyCode==mk then
        WIN.Visible = not WIN.Visible; return
    end

    -- Feature toggles
    for feat,kc in pairs(keybindMap) do
        if feat~="menu" and kc~=Enum.KeyCode.Unknown and inp.KeyCode==kc then
            local fn=keybindToggles[feat]; if fn then fn(nil) end
        end
    end
end)

-- ======== INFINITE JUMP ========
UIS.JumpRequest:Connect(function()
    if not infiniteJumpEnabled then return end
    local c=LP.Character; if not c then return end
    local hum=c:FindFirstChild("Humanoid"); if not hum then return end
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
end)

-- ======== NOCLIP ========
RunService.Heartbeat:Connect(function()
    if not noclipEnabled then return end
    local c=LP.Character; if not c then return end
    for _,p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then p.CanCollide=false end
    end
end)

-- ======== RENDER STEPPED ========
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
