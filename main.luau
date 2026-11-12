-- Nocturnix | Speed GUI

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

-- ── State ─────────────────────────────────────────────────────────────────────
local BASE_WALKSPEED      = 16

local regularSpeedEnabled = false
local regularSpeed        = 20

local bombSpeedEnabled    = false
local bombSpeed           = 10

local ladderCheckEnabled  = true
local frozenCheckEnabled  = true

local menuVisible         = true
local listeningForKey     = false
local toggleKey           = nil  -- nil = button only

local SLIDER_MIN = 1
local SLIDER_MAX = 100

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function hasBomb()
    local char = LocalPlayer.Character
    if not char then return false end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") and string.lower(v.Name):find("bomb") then
            return true
        end
    end
    return false
end

local function isOnLadder(hum)
    return hum:GetState() == Enum.HumanoidStateType.Climbing
end

-- ── GUI root ──────────────────────────────────────────────────────────────────
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Enabled = true
ScreenGui.Parent  = CoreGui

local Frame = Instance.new("Frame")
Frame.Size                   = UDim2.new(0, 240, 0, 190)
Frame.Position               = UDim2.new(0.5, -120, 0.4, -95)
Frame.BackgroundColor3       = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel        = 0
Frame.ClipsDescendants       = false
Frame.Parent                 = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

-- Title (also drag handle)
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text                   = "Nocturnix | Speed"
TitleLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize               = 13
TitleLabel.Font                   = Enum.Font.Gotham
TitleLabel.BackgroundTransparency = 1
TitleLabel.BorderSizePixel        = 0
TitleLabel.Size                   = UDim2.new(1, 0, 0, 24)
TitleLabel.Position               = UDim2.new(0, 0, 0, 0)
TitleLabel.Parent                 = Frame

-- ── Tabs ─────────────────────────────────────────────────────────────────────
local TAB_NAMES    = { "Regular", "Bomb", "Settings" }
local tabButtons   = {}
local contentFrames = {}

for i, name in ipairs(TAB_NAMES) do
    local b = Instance.new("TextButton")
    b.Text             = name
    b.TextColor3       = Color3.fromRGB(200, 200, 200)
    b.TextSize         = 12
    b.Font             = Enum.Font.Gotham
    b.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    b.BorderSizePixel  = 0
    b.Size             = UDim2.new(0, 72, 0, 20)
    b.Position         = UDim2.new(0, 4 + (i - 1) * 77, 0, 26)
    b.Parent           = Frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    tabButtons[name] = b

    local cf = Instance.new("Frame")
    cf.Size                   = UDim2.new(1, 0, 0, 140)
    cf.Position               = UDim2.new(0, 0, 0, 50)
    cf.BackgroundTransparency = 1
    cf.BorderSizePixel        = 0
    cf.ClipsDescendants       = false
    cf.Visible                = false
    cf.Parent                 = Frame
    contentFrames[name] = cf
end

-- Divider
local Divider = Instance.new("Frame")
Divider.Size             = UDim2.new(1, -16, 0, 1)
Divider.Position         = UDim2.new(0, 8, 0, 48)
Divider.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
Divider.BorderSizePixel  = 0
Divider.Parent           = Frame

local function switchTab(name)
    for tname, btn in pairs(tabButtons) do
        btn.BackgroundColor3 = tname == name
            and Color3.fromRGB(60, 60, 60)
            or  Color3.fromRGB(45, 45, 45)
        btn.TextColor3 = tname == name
            and Color3.fromRGB(255, 255, 255)
            or  Color3.fromRGB(200, 200, 200)
    end
    for cname, cf in pairs(contentFrames) do
        cf.Visible = cname == name
    end
end

for name, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
end

-- ── Reusable helpers ──────────────────────────────────────────────────────────
local function mkBtn(parent, txt, y, active)
    local b = Instance.new("TextButton")
    b.Text             = txt
    b.TextColor3       = Color3.fromRGB(255, 255, 255)
    b.TextSize         = 13
    b.Font             = Enum.Font.Gotham
    b.BackgroundColor3 = active
        and Color3.fromRGB(40, 110, 40)
        or  Color3.fromRGB(55, 55, 55)
    b.BorderSizePixel  = 0
    b.Size             = UDim2.new(0.9, 0, 0, 22)
    b.Position         = UDim2.new(0.05, 0, 0, y)
    b.Parent           = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local function mkSlider(parent, y, initVal, onChange)
    local lbl = Instance.new("TextLabel")
    lbl.Text                   = string.format("Speed: %d", initVal)
    lbl.TextColor3             = Color3.fromRGB(255, 255, 255)
    lbl.TextSize               = 12
    lbl.Font                   = Enum.Font.Gotham
    lbl.BackgroundTransparency = 1
    lbl.BorderSizePixel        = 0
    lbl.Size                   = UDim2.new(0.9, 0, 0, 14)
    lbl.Position               = UDim2.new(0.05, 0, 0, y)
    lbl.TextXAlignment         = Enum.TextXAlignment.Center
    lbl.Parent                 = parent

    local track = Instance.new("Frame")
    track.Size             = UDim2.new(0.9, 0, 0, 10)
    track.Position         = UDim2.new(0.05, 0, 0, y + 18)
    track.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    track.BorderSizePixel  = 0
    track.ClipsDescendants = false
    track.Parent           = parent
    Instance.new("UICorner", track).CornerRadius = UDim.new(0, 5)

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Color3.fromRGB(90, 190, 90)
    fill.BorderSizePixel  = 0
    fill.ClipsDescendants = false
    fill.Parent           = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 5)

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 16, 0, 16)
    knob.Position         = UDim2.new(1, -8, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 4
    knob.Parent           = fill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(0.5, 0)

    local sd = false  -- slider dragging

    local function update(v)
        v = math.floor(math.clamp(v, SLIDER_MIN, SLIDER_MAX) + 0.5)
        local pct = (v - SLIDER_MIN) / (SLIDER_MAX - SLIDER_MIN)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        lbl.Text  = string.format("Speed: %d", v)
        onChange(v)
    end

    local function fromX(x)
        local tl = track.AbsolutePosition.X
        local tw = track.AbsoluteSize.X
        if tw <= 0 then return end
        update(SLIDER_MIN + math.clamp((x - tl) / tw, 0, 1) * (SLIDER_MAX - SLIDER_MIN))
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            sd = true; fromX(i.Position.X)
        end
    end)
    knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sd = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sd = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sd and i.UserInputType == Enum.UserInputType.MouseMovement then
            fromX(i.Position.X)
        end
    end)

    update(initVal)
end

-- ── Regular tab ───────────────────────────────────────────────────────────────
local RC = contentFrames["Regular"]

local RegularToggle = mkBtn(RC, "Speed: OFF", 5, false)
mkSlider(RC, 35, regularSpeed, function(v) regularSpeed = v end)

RegularToggle.MouseButton1Click:Connect(function()
    regularSpeedEnabled = not regularSpeedEnabled
    RegularToggle.Text             = regularSpeedEnabled and "Speed: ON" or "Speed: OFF"
    RegularToggle.BackgroundColor3 = regularSpeedEnabled
        and Color3.fromRGB(40, 110, 40) or Color3.fromRGB(55, 55, 55)
end)

-- ── Bomb tab ──────────────────────────────────────────────────────────────────
local BC = contentFrames["Bomb"]

local BombToggle = mkBtn(BC, "Bomb Speed: OFF", 5, false)
mkSlider(BC, 35, bombSpeed, function(v) bombSpeed = v end)

BombToggle.MouseButton1Click:Connect(function()
    bombSpeedEnabled = not bombSpeedEnabled
    BombToggle.Text             = bombSpeedEnabled and "Bomb Speed: ON" or "Bomb Speed: OFF"
    BombToggle.BackgroundColor3 = bombSpeedEnabled
        and Color3.fromRGB(40, 110, 40) or Color3.fromRGB(55, 55, 55)
end)

-- ── Settings tab ──────────────────────────────────────────────────────────────
local SC = contentFrames["Settings"]

local KeybindBtn = mkBtn(SC, "Toggle Key: NONE", 5, false)
local LadderBtn  = mkBtn(SC, "Ladder Check: ON", 35, true)
local FrozenBtn  = mkBtn(SC, "Frozen Check: ON", 62, true)

local function updateToggleState()
    RegularToggle.Text             = regularSpeedEnabled and "Speed: ON" or "Speed: OFF"
    RegularToggle.BackgroundColor3 = regularSpeedEnabled
        and Color3.fromRGB(40, 110, 40) or Color3.fromRGB(55, 55, 55)
end

KeybindBtn.MouseButton1Click:Connect(function()
    if listeningForKey then return end
    listeningForKey = true
    KeybindBtn.Text             = "Press a key..."
    KeybindBtn.BackgroundColor3 = Color3.fromRGB(100, 90, 20)
end)

LadderBtn.MouseButton1Click:Connect(function()
    ladderCheckEnabled = not ladderCheckEnabled
    LadderBtn.Text             = ladderCheckEnabled and "Ladder Check: ON" or "Ladder Check: OFF"
    LadderBtn.BackgroundColor3 = ladderCheckEnabled
        and Color3.fromRGB(40, 110, 40) or Color3.fromRGB(55, 55, 55)
end)

FrozenBtn.MouseButton1Click:Connect(function()
    frozenCheckEnabled = not frozenCheckEnabled
    FrozenBtn.Text             = frozenCheckEnabled and "Frozen Check: ON" or "Frozen Check: OFF"
    FrozenBtn.BackgroundColor3 = frozenCheckEnabled
        and Color3.fromRGB(40, 110, 40) or Color3.fromRGB(55, 55, 55)
end)

-- ── Input handling ────────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, processed)
    -- Rebind capture (eats the key regardless of processed)
    if listeningForKey then
        listeningForKey = false
        if input.UserInputType == Enum.UserInputType.Keyboard then
            toggleKey = input.KeyCode
            KeybindBtn.Text = "Toggle Key: " .. input.KeyCode.Name
        else
            KeybindBtn.Text = "Toggle Key: " .. (toggleKey and toggleKey.Name or "NONE")
        end
        KeybindBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
        return
    end

    -- Insert = hide / show menu
    if input.KeyCode == Enum.KeyCode.Insert then
        menuVisible = not menuVisible
        Frame.Visible = menuVisible
        return
    end

    -- Toggle key fires speed toggle
    if not processed and toggleKey and input.KeyCode == toggleKey then
        regularSpeedEnabled = not regularSpeedEnabled
        updateToggleState()
    end
end)

-- ── Frame drag (title bar only) ───────────────────────────────────────────────
local dragging    = false
local dragStart   = Vector2.new()
local startOffset = UDim2.new()

TitleLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging    = true
        dragStart   = Vector2.new(input.Position.X, input.Position.Y)
        startOffset = Frame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local d = Vector2.new(input.Position.X, input.Position.Y) - dragStart
        Frame.Position = UDim2.new(
            startOffset.X.Scale, startOffset.X.Offset + d.X,
            startOffset.Y.Scale, startOffset.Y.Offset + d.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ── RenderStepped — CFrame speed ─────────────────────────────────────────────
RunService.RenderStepped:Connect(function(dt)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    local dir = hum.MoveDirection
    if frozenCheckEnabled and dir.Magnitude == 0 then return end
    if ladderCheckEnabled and isOnLadder(hum) then return end

    local speed = 0
    if hasBomb() then
        if bombSpeedEnabled then speed = bombSpeed end
    elseif regularSpeedEnabled then
        speed = regularSpeed
    end

    if speed > 0 and dir.Magnitude > 0 then
        hrp.CFrame = hrp.CFrame + dir * speed * dt
    end
end)

switchTab("Regular")
