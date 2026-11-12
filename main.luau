-- Nocturnix | Speed GUI
-- Deobfuscated from LuaObfuscator.com (Alpha 0.10.9)

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

local speedEnabled     = false
local speedValue       = 40
local bombPauseEnabled = true   -- auto-kill speed while bomb is in hand
local keys             = {}

-- Returns true if the character is currently holding a bomb tool
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
Frame.Size                   = UDim2.new(0, 240, 0, 110)
Frame.Position               = UDim2.new(0.5, -120, 0.4, -55)
Frame.BackgroundColor3       = Color3.fromRGB(30, 30, 30)
Frame.BackgroundTransparency = 0
Frame.BorderSizePixel        = 0
Frame.Parent                 = ScreenGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 8)
FrameCorner.Parent = Frame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text                   = "Nocturnix | Speed"
TitleLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
TitleLabel.BackgroundTransparency = 1
TitleLabel.BorderSizePixel        = 0
TitleLabel.Size                   = UDim2.new(0.9, 0, 0, 18)
TitleLabel.Position               = UDim2.new(0.05, 0, 0, 8)
TitleLabel.Parent                 = Frame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Text                   = "Speed: OFF"
ToggleButton.TextColor3             = Color3.fromRGB(255, 255, 255)
ToggleButton.BackgroundColor3       = Color3.fromRGB(30, 30, 30)
ToggleButton.BackgroundTransparency = 0.8
ToggleButton.BorderSizePixel        = 0
ToggleButton.Size                   = UDim2.new(0.9, 0, 0, 20)
ToggleButton.Position               = UDim2.new(0.05, 0, 0, 30)
ToggleButton.Parent                 = Frame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = ToggleButton

-- Bomb pause toggle
local BombButton = Instance.new("TextButton")
BombButton.Text                   = "Bomb Pause: ON"
BombButton.TextColor3             = Color3.fromRGB(100, 255, 120)   -- green = active
BombButton.BackgroundColor3       = Color3.fromRGB(30, 30, 30)
BombButton.BackgroundTransparency = 0.8
BombButton.BorderSizePixel        = 0
BombButton.Size                   = UDim2.new(0.9, 0, 0, 20)
BombButton.Position               = UDim2.new(0.05, 0, 0, 54)
BombButton.Parent                 = Frame

local BombCorner = Instance.new("UICorner")
BombCorner.CornerRadius = UDim.new(0, 6)
BombCorner.Parent = BombButton

local SpeedBox = Instance.new("TextBox")
SpeedBox.Text                   = tostring(speedValue)
SpeedBox.TextColor3             = Color3.fromRGB(255, 255, 255)
SpeedBox.BackgroundColor3       = Color3.fromRGB(30, 30, 30)
SpeedBox.BackgroundTransparency = 0.9
SpeedBox.BorderSizePixel        = 0
SpeedBox.Size                   = UDim2.new(0.9, 0, 0, 20)
SpeedBox.Position               = UDim2.new(0.05, 0, 0, 78)
SpeedBox.Parent                 = Frame

local BoxCorner = Instance.new("UICorner")
BoxCorner.CornerRadius = UDim.new(0, 6)
BoxCorner.Parent = SpeedBox

-- ── Dragging ─────────────────────────────────────────────────────────────────

local dragging    = false
local dragStart   = Vector2.new()
local startOffset = UDim2.new()

Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging    = true
        dragStart   = Vector2.new(input.Position.X, input.Position.Y)
        startOffset = Frame.Position
    end
end)

Frame.InputChanged:Connect(function(input)
    if dragging then
        local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
        Frame.Position = UDim2.new(
            startOffset.X.Scale,  startOffset.X.Offset + delta.X,
            startOffset.Y.Scale,  startOffset.Y.Offset + delta.Y
        )
    end
end)

Frame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ── Toggles ───────────────────────────────────────────────────────────────────

ToggleButton.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled
    ToggleButton.Text = speedEnabled and "Speed: ON" or "Speed: OFF"
end)

BombButton.MouseButton1Click:Connect(function()
    bombPauseEnabled = not bombPauseEnabled
    if bombPauseEnabled then
        BombButton.Text       = "Bomb Pause: ON"
        BombButton.TextColor3 = Color3.fromRGB(100, 255, 120)
    else
        BombButton.Text       = "Bomb Pause: OFF"
        BombButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end)

-- ── Speed textbox ─────────────────────────────────────────────────────────────

SpeedBox.FocusLost:Connect(function()
    local v = tonumber(SpeedBox.Text)
    if v then
        speedValue = math.clamp(v, 1, 1000)
        SpeedBox.Text = string.format("%.1f", speedValue)
    end
end)

-- ── Key tracking ─────────────────────────────────────────────────────────────

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed then
        table.insert(keys, input.KeyCode)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    for i, k in ipairs(keys) do
        if k == input.KeyCode then
            table.remove(keys, i)
            break
        end
    end
end)

-- ── RenderStepped speed application ──────────────────────────────────────────

RunService.RenderStepped:Connect(function()
    if not speedEnabled then return end
    if bombPauseEnabled and hasBomb() then return end   -- don't speed with bomb

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
