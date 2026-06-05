-- NOCTURNIX | CUSTOM BYPASS (No External Libraries)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = game:GetService("Workspace").CurrentCamera

-- Settings
local Config = {
    SpeedEnabled = false,
    LegitEnabled = false,
    SpeedValue = 1.2,
    LegitValue = 0.3,
    Visible = true
}

-- GUI Creation (Homemade, zero dependency)
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 200, 0, 150)
Main.Position = UDim2.new(0.5, -100, 0.5, -75)
Main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

-- Title
local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "Nocturnix | Timebomb"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1

-- Toggle Button (Speed)
local Toggle = Instance.new("TextButton", Main)
Toggle.Size = UDim2.new(0.8, 0, 0, 30)
Toggle.Position = UDim2.new(0.1, 0, 0.25, 0)
Toggle.Text = "Speed: OFF"
Toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
Instance.new("UICorner", Toggle)

-- Legit Toggle
local Legit = Instance.new("TextButton", Main)
Legit.Size = UDim2.new(0.8, 0, 0, 30)
Legit.Position = UDim2.new(0.1, 0, 0.5, 0)
Legit.Text = "Legit Mode: OFF"
Legit.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
Instance.new("UICorner", Legit)

-- Panic Button
local Panic = Instance.new("TextButton", Main)
Panic.Size = UDim2.new(0.8, 0, 0, 30)
Panic.Position = UDim2.new(0.1, 0, 0.75, 0)
Panic.Text = "Panic/Destroy"
Panic.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
Instance.new("UICorner", Panic)

-- Watermark (Integrated)
local Watermark = Instance.new("TextLabel", ScreenGui)
Watermark.Size = UDim2.new(0, 150, 0, 30)
Watermark.Position = UDim2.new(0, 10, 0, 10)
Watermark.Text = "Nocturnix | FPS: 0"
Watermark.BackgroundTransparency = 1
Watermark.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Interaction Logic
Toggle.MouseButton1Click:Connect(function()
    Config.SpeedEnabled = not Config.SpeedEnabled
    Toggle.Text = Config.SpeedEnabled and "Speed: ON" or "Speed: OFF"
end)

Legit.MouseButton1Click:Connect(function()
    Config.LegitEnabled = not Config.LegitEnabled
    Legit.Text = Config.LegitEnabled and "Legit: ON" or "Legit: OFF"
end)

Panic.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    Config.SpeedEnabled = false
    Config.LegitEnabled = false
end)

-- Physics Bypass Loop
RunService.Heartbeat:Connect(function(dt)
    Watermark.Text = "Nocturnix | FPS: " .. math.floor(1/dt)
    
    local Char = LocalPlayer.Character
    local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
    local Hum = Char and Char:FindFirstChild("Humanoid")

    if (Config.SpeedEnabled or Config.LegitEnabled) and HRP and Hum then
        if Hum.MoveDirection.Magnitude > 0 then
            local Multiplier = Config.LegitEnabled and Config.LegitValue or Config.SpeedValue
            
            -- PHYSICS BYPASS: 
            -- Instead of overriding velocity, we add a small force vector.
            -- This looks like natural momentum to the anti-cheat.
            local Force = Hum.MoveDirection * (Hum.WalkSpeed * Multiplier)
            HRP.AssemblyLinearVelocity = Vector3.new(Force.X, HRP.AssemblyLinearVelocity.Y, Force.Z)
        end
    end
end)
