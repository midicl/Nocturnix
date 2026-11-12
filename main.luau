-- Nocturnix | Speed GUI

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

local speedEnabled     = false
local bombPauseEnabled = true
local speedValue       = 1.0
local sliderMin        = 1.0
local sliderMax        = 5.0
local BASE_WALKSPEED   = 16

local keys           = {}
local dragging       = false
local sliderDragging = false
local dragStart      = Vector2.new()
local startOffset    = UDim2.new()

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

-- ── GUI ──────────────────────────────────────────────────────────────────────

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Enabled = true
ScreenGui.Parent  = CoreGui

local Frame = Instance.new("Frame")
Frame.Size                   = UDim2.new(0, 240, 0, 128)
Frame.Position               = UDim2.new(0.5, -120, 0.4, -64)
Frame.BackgroundColor3       = Color3.fromRGB(30, 30, 30)
Frame.BackgroundTransparency = 0
Frame.BorderSizePixel        = 0
Frame.ClipsDescendants       = false
Frame.Parent                 = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

-- helper: simple text label
local function mkLabel(parent, txt, y, h, size)
    local l = Instance.new("TextLabel")
    l.Text                   = txt
    l.TextColor3             = Color3.fromRGB(255, 255, 255)
    l.TextSize               = size or 14
    l.BackgroundTransparency = 1
    l.BorderSizePixel        = 0
    l.Size                   = UDim2.new(0.9, 0, 0, h)
    l.Position               = UDim2.new(0.05, 0, 0, y)
    l.Parent                 = parent
    return l
end

-- helper: button
local function mkBtn(txt, y)
    local b = Instance.new("TextButton")
    b.Text                   = txt
    b.TextColor3             = Color3.fromRGB(255, 255, 255)
    b.TextSize               = 14
    b.BackgroundColor3       = Color3.fromRGB(55, 55, 55)
    b.BackgroundTransparency = 0
    b.BorderSizePixel        = 0
    b.Size                   = UDim2.new(0.9, 0, 0, 22)
    b.Position               = UDim2.new(0.05, 0, 0, y)
    b.Parent                 = Frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

mkLabel(Frame, "Nocturnix | Speed", 7, 18, 14)

local ToggleButton = mkBtn("Speed: OFF", 29)
local BombButton   = mkBtn("Bomb Pause: ON", 55)
BombButton.TextColor3 = Color3.fromRGB(100, 255, 120)

local SpeedLabel = mkLabel(Frame, "Speed: 1.0x", 82, 16, 13)
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Slider track (tall enough to see, lighter color so it stands out)
local SliderTrack = Instance.new("Frame")
SliderTrack.Name             = "SliderTrack"
SliderTrack.Size             = UDim2.new(0.9, 0, 0, 10)
SliderTrack.Position         = UDim2.new(0.05, 0, 0, 102)
SliderTrack.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
SliderTrack.BorderSizePixel  = 0
SliderTrack.ClipsDescendants = false   -- allow knob to overflow track bounds
SliderTrack.Parent           = Frame
Instance.new("UICorner", SliderTrack).CornerRadius = UDim.new(0, 5)

-- Filled portion
local SliderFill = Instance.new("Frame")
SliderFill.Size             = UDim2.new(0, 0, 1, 0)   -- updated by updateSlider
SliderFill.BackgroundColor3 = Color3.fromRGB(90, 190, 90)
SliderFill.BorderSizePixel  = 0
SliderFill.ClipsDescendants = false
SliderFill.Parent           = SliderTrack
Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(0, 5)

-- Knob: child of Fill, always at Fill's right edge — no manual pixel math needed
local SliderKnob = Instance.new("Frame")
SliderKnob.Size             = UDim2.new(0, 16, 0, 16)
SliderKnob.Position         = UDim2.new(1, -8, 0.5, -8)   -- right edge, centered
SliderKnob.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
SliderKnob.BorderSizePixel  = 0
SliderKnob.ZIndex           = 4
SliderKnob.Parent           = SliderFill
Instance.new("UICorner", SliderKnob).CornerRadius = UDim.new(0.5, 0)

-- ── Slider logic ─────────────────────────────────────────────────────────────

local function updateSlider()
    local pct = math.clamp((speedValue - sliderMin) / (sliderMax - sliderMin), 0, 1)
    SliderFill.Size = UDim2.new(pct, 0, 1, 0)
    SpeedLabel.Text = string.format("Speed: %.1fx", speedValue)
end

local function sliderSetFromAbsX(absX)
    local tl = SliderTrack.AbsolutePosition.X
    local tw = SliderTrack.AbsoluteSize.X
    if tw <= 0 then return end
    local pct = math.clamp((absX - tl) / tw, 0, 1)
    local raw = sliderMin + pct * (sliderMax - sliderMin)
    speedValue = math.floor(raw * 10 + 0.5) / 10
    updateSlider()
end

SliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = true
        sliderSetFromAbsX(input.Position.X)
    end
end)

SliderKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = true
    end
end)

-- ── Frame dragging ────────────────────────────────────────────────────────────

Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not sliderDragging then
        dragging    = true
        dragStart   = Vector2.new(input.Position.X, input.Position.Y)
        startOffset = Frame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    if sliderDragging then
        sliderSetFromAbsX(input.Position.X)
    elseif dragging then
        local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
        Frame.Position = UDim2.new(
            startOffset.X.Scale, startOffset.X.Offset + delta.X,
            startOffset.Y.Scale, startOffset.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = false
        dragging       = false
    end
    for i, k in ipairs(keys) do
        if k == input.KeyCode then table.remove(keys, i) break end
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed then table.insert(keys, input.KeyCode) end
end)

-- ── Button toggles ────────────────────────────────────────────────────────────

ToggleButton.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled
    ToggleButton.Text             = speedEnabled and "Speed: ON"  or "Speed: OFF"
    ToggleButton.BackgroundColor3 = speedEnabled
        and Color3.fromRGB(40, 110, 40)
        or  Color3.fromRGB(55, 55, 55)
end)

BombButton.MouseButton1Click:Connect(function()
    bombPauseEnabled = not bombPauseEnabled
    BombButton.Text       = bombPauseEnabled and "Bomb Pause: ON"  or "Bomb Pause: OFF"
    BombButton.TextColor3 = bombPauseEnabled
        and Color3.fromRGB(100, 255, 120)
        or  Color3.fromRGB(200, 200, 200)
end)

-- ── Heartbeat — WalkSpeed multiplier ─────────────────────────────────────────
-- speedValue is a multiplier (1.0 = normal, 2.0 = double, etc.)
-- WalkSpeed is set every frame so it survives character respawn and game resets.

updateSlider()

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return end

    if speedEnabled and not (bombPauseEnabled and hasBomb()) then
        hum.WalkSpeed = BASE_WALKSPEED * speedValue
    else
        hum.WalkSpeed = BASE_WALKSPEED
    end
end)
-- Nocturnix | Speed GUI

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

local speedEnabled     = false
local bombPauseEnabled = true
local speedValue       = 1.0
local sliderMin        = 0.1
local sliderMax        = 10.0

local keys           = {}
local dragging       = false
local sliderDragging = false
local dragStart      = Vector2.new()
local startOffset    = UDim2.new()

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

-- ── GUI ──────────────────────────────────────────────────────────────────────

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Enabled = true
ScreenGui.Parent  = CoreGui

local Frame = Instance.new("Frame")
Frame.Size                   = UDim2.new(0, 240, 0, 128)
Frame.Position               = UDim2.new(0.5, -120, 0.4, -64)
Frame.BackgroundColor3       = Color3.fromRGB(30, 30, 30)
Frame.BackgroundTransparency = 0
Frame.BorderSizePixel        = 0
Frame.ClipsDescendants       = false
Frame.Parent                 = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

-- helper: simple text label
local function mkLabel(parent, txt, y, h, size)
    local l = Instance.new("TextLabel")
    l.Text                   = txt
    l.TextColor3             = Color3.fromRGB(255, 255, 255)
    l.TextSize               = size or 14
    l.BackgroundTransparency = 1
    l.BorderSizePixel        = 0
    l.Size                   = UDim2.new(0.9, 0, 0, h)
    l.Position               = UDim2.new(0.05, 0, 0, y)
    l.Parent                 = parent
    return l
end

-- helper: button
local function mkBtn(txt, y)
    local b = Instance.new("TextButton")
    b.Text                   = txt
    b.TextColor3             = Color3.fromRGB(255, 255, 255)
    b.TextSize               = 14
    b.BackgroundColor3       = Color3.fromRGB(55, 55, 55)
    b.BackgroundTransparency = 0
    b.BorderSizePixel        = 0
    b.Size                   = UDim2.new(0.9, 0, 0, 22)
    b.Position               = UDim2.new(0.05, 0, 0, y)
    b.Parent                 = Frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

mkLabel(Frame, "Nocturnix | Speed", 7, 18, 14)

local ToggleButton = mkBtn("Speed: OFF", 29)
local BombButton   = mkBtn("Bomb Pause: ON", 55)
BombButton.TextColor3 = Color3.fromRGB(100, 255, 120)

local SpeedLabel = mkLabel(Frame, "Speed: 1.0", 82, 16, 13)
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Slider track (tall enough to see, lighter color so it stands out)
local SliderTrack = Instance.new("Frame")
SliderTrack.Name             = "SliderTrack"
SliderTrack.Size             = UDim2.new(0.9, 0, 0, 10)
SliderTrack.Position         = UDim2.new(0.05, 0, 0, 102)
SliderTrack.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
SliderTrack.BorderSizePixel  = 0
SliderTrack.ClipsDescendants = false   -- allow knob to overflow track bounds
SliderTrack.Parent           = Frame
Instance.new("UICorner", SliderTrack).CornerRadius = UDim.new(0, 5)

-- Filled portion
local SliderFill = Instance.new("Frame")
SliderFill.Size             = UDim2.new(0, 0, 1, 0)   -- updated by updateSlider
SliderFill.BackgroundColor3 = Color3.fromRGB(90, 190, 90)
SliderFill.BorderSizePixel  = 0
SliderFill.ClipsDescendants = false
SliderFill.Parent           = SliderTrack
Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(0, 5)

-- Knob: child of Fill, always at Fill's right edge — no manual pixel math needed
local SliderKnob = Instance.new("Frame")
SliderKnob.Size             = UDim2.new(0, 16, 0, 16)
SliderKnob.Position         = UDim2.new(1, -8, 0.5, -8)   -- right edge, centered
SliderKnob.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
SliderKnob.BorderSizePixel  = 0
SliderKnob.ZIndex           = 4
SliderKnob.Parent           = SliderFill
Instance.new("UICorner", SliderKnob).CornerRadius = UDim.new(0.5, 0)

-- ── Slider logic ─────────────────────────────────────────────────────────────

local function updateSlider()
    local pct = math.clamp((speedValue - sliderMin) / (sliderMax - sliderMin), 0, 1)
    SliderFill.Size = UDim2.new(pct, 0, 1, 0)
    SpeedLabel.Text = string.format("Speed: %.1f", speedValue)
end

local function sliderSetFromAbsX(absX)
    local tl = SliderTrack.AbsolutePosition.X
    local tw = SliderTrack.AbsoluteSize.X
    if tw <= 0 then return end
    local pct = math.clamp((absX - tl) / tw, 0, 1)
    local raw = sliderMin + pct * (sliderMax - sliderMin)
    speedValue = math.floor(raw * 10 + 0.5) / 10
    updateSlider()
end

SliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = true
        sliderSetFromAbsX(input.Position.X)
    end
end)

SliderKnob.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = true
    end
end)

-- ── Frame dragging ────────────────────────────────────────────────────────────

Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not sliderDragging then
        dragging    = true
        dragStart   = Vector2.new(input.Position.X, input.Position.Y)
        startOffset = Frame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    if sliderDragging then
        sliderSetFromAbsX(input.Position.X)
    elseif dragging then
        local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
        Frame.Position = UDim2.new(
            startOffset.X.Scale, startOffset.X.Offset + delta.X,
            startOffset.Y.Scale, startOffset.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        sliderDragging = false
        dragging       = false
    end
    for i, k in ipairs(keys) do
        if k == input.KeyCode then table.remove(keys, i) break end
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed then table.insert(keys, input.KeyCode) end
end)

-- ── Button toggles ────────────────────────────────────────────────────────────

ToggleButton.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled
    ToggleButton.Text             = speedEnabled and "Speed: ON"  or "Speed: OFF"
    ToggleButton.BackgroundColor3 = speedEnabled
        and Color3.fromRGB(40, 110, 40)
        or  Color3.fromRGB(55, 55, 55)
end)

BombButton.MouseButton1Click:Connect(function()
    bombPauseEnabled = not bombPauseEnabled
    BombButton.Text       = bombPauseEnabled and "Bomb Pause: ON"  or "Bomb Pause: OFF"
    BombButton.TextColor3 = bombPauseEnabled
        and Color3.fromRGB(100, 255, 120)
        or  Color3.fromRGB(200, 200, 200)
end)

-- ── RenderStepped ─────────────────────────────────────────────────────────────

updateSlider()   -- set initial fill/label (no AbsoluteSize needed with this approach)

RunService.RenderStepped:Connect(function(dt)
    if not speedEnabled then return end
    if bombPauseEnabled and hasBomb() then return end

    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end
    if hum.Health <= 0 then return end

    local dir = hum.MoveDirection
    if dir.Magnitude > 0 then
        hrp.CFrame = hrp.CFrame + dir * speedValue * dt
    end
end)
