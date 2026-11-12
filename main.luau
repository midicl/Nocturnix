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
Frame.Size                   = UDim2.new(0, 240, 0, 118)
Frame.Position               = UDim2.new(0.5, -120, 0.4, -59)
Frame.BackgroundColor3       = Color3.fromRGB(30, 30, 30)
Frame.BackgroundTransparency = 0
Frame.BorderSizePixel        = 0
Frame.Parent                 = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

local function label(text, y, h)
    local l = Instance.new("TextLabel")
    l.Text                   = text
    l.TextColor3             = Color3.fromRGB(255, 255, 255)
    l.BackgroundTransparency = 1
    l.BorderSizePixel        = 0
    l.Size                   = UDim2.new(0.9, 0, 0, h)
    l.Position               = UDim2.new(0.05, 0, 0, y)
    l.Parent                 = Frame
    return l
end

local function button(text, y)
    local b = Instance.new("TextButton")
    b.Text                   = text
    b.TextColor3             = Color3.fromRGB(255, 255, 255)
    b.BackgroundColor3       = Color3.fromRGB(50, 50, 50)
    b.BackgroundTransparency = 0
    b.BorderSizePixel        = 0
    b.Size                   = UDim2.new(0.9, 0, 0, 20)
    b.Position               = UDim2.new(0.05, 0, 0, y)
    b.Parent                 = Frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

label("Nocturnix | Speed", 6, 16)

local ToggleButton = button("Speed: OFF", 26)
local BombButton   = button("Bomb Pause: ON", 50)
BombButton.TextColor3 = Color3.fromRGB(100, 255, 120)

local SpeedLabel = label("Speed: 1.0", 78, 14)
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Slider track
local SliderTrack = Instance.new("Frame")
SliderTrack.Size             = UDim2.new(0.9, 0, 0, 8)
SliderTrack.Position         = UDim2.new(0.05, 0, 0, 97)
SliderTrack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
SliderTrack.BorderSizePixel  = 0
SliderTrack.ClipsDescendants = true
SliderTrack.Parent           = Frame
Instance.new("UICorner", SliderTrack).CornerRadius = UDim.new(0, 4)

local SliderFill = Instance.new("Frame")
SliderFill.Size             = UDim2.new(0, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
SliderFill.BorderSizePixel  = 0
SliderFill.Parent           = SliderTrack
Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(0, 4)

-- Knob sits outside track so it's not clipped
local SliderKnob = Instance.new("Frame")
SliderKnob.Size             = UDim2.new(0, 14, 0, 14)
SliderKnob.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
SliderKnob.BorderSizePixel  = 0
SliderKnob.ZIndex           = 3
SliderKnob.Parent           = Frame
Instance.new("UICorner", SliderKnob).CornerRadius = UDim.new(0.5, 0)

local function updateSlider()
    local pct = math.clamp((speedValue - sliderMin) / (sliderMax - sliderMin), 0, 1)
    SliderFill.Size = UDim2.new(pct, 0, 1, 0)
    -- position knob relative to frame, tracking the track's left edge
    local trackX  = SliderTrack.Position.X.Offset          -- 0.05 * 240 = 12
    local trackW  = SliderTrack.AbsoluteSize.X
    if trackW <= 0 then
        -- fallback before first layout: estimate from parent width
        trackW = 240 * 0.9
    end
    local kx = trackX + pct * trackW - 7
    SliderKnob.Position = UDim2.new(0, kx, 0, 94)
    SpeedLabel.Text = string.format("Speed: %.1f", speedValue)
end

local function sliderSetFromAbsX(absX)
    local tl = SliderTrack.AbsolutePosition.X
    local tw = SliderTrack.AbsoluteSize.X
    if tw <= 0 then return end
    local pct = math.clamp((absX - tl) / tw, 0, 1)
    -- round to nearest 0.1
    local raw = sliderMin + pct * (sliderMax - sliderMin)
    speedValue = math.floor(raw * 10 + 0.5) / 10
    updateSlider()
end

-- ── Toggles ───────────────────────────────────────────────────────────────────

ToggleButton.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled
    ToggleButton.Text             = speedEnabled and "Speed: ON"  or "Speed: OFF"
    ToggleButton.BackgroundColor3 = speedEnabled
        and Color3.fromRGB(40, 100, 40)
        or  Color3.fromRGB(50, 50, 50)
end)

BombButton.MouseButton1Click:Connect(function()
    bombPauseEnabled = not bombPauseEnabled
    BombButton.Text       = bombPauseEnabled and "Bomb Pause: ON"  or "Bomb Pause: OFF"
    BombButton.TextColor3 = bombPauseEnabled
        and Color3.fromRGB(100, 255, 120)
        or  Color3.fromRGB(255, 255, 255)
end)

-- ── Slider input ─────────────────────────────────────────────────────────────

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

-- Single InputChanged / InputEnded on UserInputService handles both
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
    -- key tracking
    for i, k in ipairs(keys) do
        if k == input.KeyCode then
            table.remove(keys, i)
            break
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed then
        table.insert(keys, input.KeyCode)
    end
end)

-- ── RenderStepped ─────────────────────────────────────────────────────────────

task.defer(updateSlider)   -- lay out slider after first frame

RunService.RenderStepped:Connect(function()
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
        hrp.CFrame = hrp.CFrame + dir * speedValue
    end
end)
