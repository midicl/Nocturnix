-- Nocturnix | Speed GUI

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer
local HttpService      = game:GetService("HttpService")

-- ── State ─────────────────────────────────────────────────────────────────────
local BASE_WALKSPEED      = 16

local regularSpeedEnabled = false
local regularSpeed        = 20

local bombSpeedEnabled    = false
local bombSpeed           = 10

local hbEnabled           = false
local hbSize              = 6
local originalSizes       = {}

local spinEnabled         = false
local spinAngle           = 0

local jumpGlitchEnabled   = false

local ladderCheckEnabled  = true
local frozenCheckEnabled  = true
local jumpUnlockEnabled   = false
local infiniteJumpEnabled = false
local noclipEnabled       = false

local menuVisible         = true
local listeningForFeature = nil
local keybinds            = {}
local kbButtons           = {}

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

-- ── GUI root ──────────────────────────────────────────────────────────────────
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Enabled = true
ScreenGui.Parent  = CoreGui

local Frame = Instance.new("Frame")
Frame.Size                   = UDim2.new(0, 240, 0, 245)
Frame.Position               = UDim2.new(0.5, -120, 0.4, -122)
Frame.BackgroundColor3       = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel        = 0
Frame.ClipsDescendants       = false
Frame.Parent                 = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

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

-- ── Tabs (4 × 55 px) ─────────────────────────────────────────────────────────
local TAB_NAMES     = {"Regular", "Bomb", "Settings", "Keys"}
local tabButtons    = {}
local contentFrames = {}

for i, name in ipairs(TAB_NAMES) do
    local b = Instance.new("TextButton")
    b.Text             = name
    b.TextColor3       = Color3.fromRGB(200, 200, 200)
    b.TextSize         = 11
    b.Font             = Enum.Font.Gotham
    b.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    b.BorderSizePixel  = 0
    b.Size             = UDim2.new(0, 55, 0, 20)
    b.Position         = UDim2.new(0, 5 + (i-1)*59, 0, 26)
    b.Parent           = Frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    tabButtons[name] = b

    local cf = Instance.new("Frame")
    cf.Size                   = UDim2.new(1, 0, 0, 195)
    cf.Position               = UDim2.new(0, 0, 0, 50)
    cf.BackgroundTransparency = 1
    cf.BorderSizePixel        = 0
    cf.ClipsDescendants       = false
    cf.Visible                = false
    cf.Parent                 = Frame
    contentFrames[name] = cf
end

local Divider = Instance.new("Frame")
Divider.Size             = UDim2.new(1, -16, 0, 1)
Divider.Position         = UDim2.new(0, 8, 0, 48)
Divider.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
Divider.BorderSizePixel  = 0
Divider.Parent           = Frame

local function switchTab(name)
    for tname, btn in pairs(tabButtons) do
        btn.BackgroundColor3 = tname == name and Color3.fromRGB(60,60,60) or Color3.fromRGB(45,45,45)
        btn.TextColor3       = tname == name and Color3.fromRGB(255,255,255) or Color3.fromRGB(200,200,200)
    end
    for cname, cf in pairs(contentFrames) do cf.Visible = cname == name end
end

for name, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
end

-- ── Widget helpers ────────────────────────────────────────────────────────────
local function mkBtn(parent, txt, y, active)
    local b = Instance.new("TextButton")
    b.Text             = txt
    b.TextColor3       = Color3.fromRGB(255, 255, 255)
    b.TextSize         = 13
    b.Font             = Enum.Font.Gotham
    b.BackgroundColor3 = active and Color3.fromRGB(40,110,40) or Color3.fromRGB(55,55,55)
    b.BorderSizePixel  = 0
    b.Size             = UDim2.new(0.9, 0, 0, 22)
    b.Position         = UDim2.new(0.05, 0, 0, y)
    b.Parent           = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local function mkSlider(parent, y, initVal, minV, maxV, prefix, onChange)
    local lbl = Instance.new("TextLabel")
    lbl.Text                   = string.format("%s: %d", prefix, initVal)
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

    local sd = false

    local function update(v)
        v = math.floor(math.clamp(v, minV, maxV) + 0.5)
        fill.Size = UDim2.new((v - minV) / (maxV - minV), 0, 1, 0)
        lbl.Text  = string.format("%s: %d", prefix, v)
        onChange(v)
    end

    local function fromX(x)
        local tl, tw = track.AbsolutePosition.X, track.AbsoluteSize.X
        if tw <= 0 then return end
        update(minV + math.clamp((x - tl) / tw, 0, 1) * (maxV - minV))
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sd = true; fromX(i.Position.X) end
    end)
    knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sd = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sd = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sd and i.UserInputType == Enum.UserInputType.MouseMovement then fromX(i.Position.X) end
    end)

    update(initVal)
    return update
end

-- ── HUD (left side, persists through Insert hide) ─────────────────────────────
local HUDFrame = Instance.new("Frame")
HUDFrame.Size                   = UDim2.new(0, 185, 0, 10)
HUDFrame.Position               = UDim2.new(0, 5, 0.5, -60)
HUDFrame.BackgroundColor3       = Color3.fromRGB(15, 15, 15)
HUDFrame.BackgroundTransparency = 0.35
HUDFrame.BorderSizePixel        = 0
HUDFrame.Parent                 = ScreenGui  -- separate Frame — Insert only hides main Frame
Instance.new("UICorner", HUDFrame).CornerRadius = UDim.new(0, 6)

local hudLabels = {}

local HUD_FEATURES = {
    {k="regularSpeed", l="Speed"},
    {k="bombSpeed",    l="Bomb Spd"},
    {k="hbExpand",     l="HB Expand"},
    {k="spinBot",      l="Spin Bot"},
    {k="jumpGlitch",   l="Jump Glitch"},
    {k="jumpUnlock",   l="Jump Unlock"},
    {k="infiniteJump", l="Inf Jump"},
    {k="noclip",       l="Noclip"},
}

local function getEnabled(k)
    if k=="regularSpeed"  then return regularSpeedEnabled  end
    if k=="bombSpeed"     then return bombSpeedEnabled     end
    if k=="hbExpand"      then return hbEnabled            end
    if k=="spinBot"       then return spinEnabled          end
    if k=="jumpGlitch"    then return jumpGlitchEnabled    end
    if k=="jumpUnlock"    then return jumpUnlockEnabled    end
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
        local kc      = keybinds[feat.k]
        local enabled = getEnabled(feat.k)
        hudLabels[i].Text       = string.format("[%s] %s: %s",
            kc and kc.Name or "NONE", feat.l, enabled and "ON" or "OFF")
        hudLabels[i].TextColor3 = enabled
            and Color3.fromRGB(100, 255, 120)
            or  Color3.fromRGB(160, 160, 160)
    end
    HUDFrame.Size = UDim2.new(0, 185, 0, 8 + #HUD_FEATURES * 16)
end

-- ── Regular tab ───────────────────────────────────────────────────────────────
local RC = contentFrames["Regular"]

local RegularToggle     = mkBtn(RC, "Speed: OFF", 5, false)
local updateSpeedSlider = mkSlider(RC, 32, regularSpeed, 1, 100, "Speed", function(v) regularSpeed = v end)

local HBToggle       = mkBtn(RC, "HB Expand: OFF", 65, false)
local updateHBSlider = mkSlider(RC, 92, hbSize, 1, 20, "Size", function(v) hbSize = v end)

local SpinToggle   = mkBtn(RC, "Spin Bot: OFF",    125, false)
local GlitchToggle = mkBtn(RC, "Jump Glitch: OFF", 152, false)

RegularToggle.MouseButton1Click:Connect(function()
    regularSpeedEnabled = not regularSpeedEnabled
    RegularToggle.Text             = regularSpeedEnabled and "Speed: ON" or "Speed: OFF"
    RegularToggle.BackgroundColor3 = regularSpeedEnabled and Color3.fromRGB(40,110,40) or Color3.fromRGB(55,55,55)
    updateHUD()
end)

HBToggle.MouseButton1Click:Connect(function()
    hbEnabled = not hbEnabled
    HBToggle.Text             = hbEnabled and "HB Expand: ON" or "HB Expand: OFF"
    HBToggle.BackgroundColor3 = hbEnabled and Color3.fromRGB(40,110,40) or Color3.fromRGB(55,55,55)
    if not hbEnabled then
        for part, orig in pairs(originalSizes) do
            if part and part.Parent then part.Size = orig.size; part.CanCollide = orig.canCollide end
        end
        originalSizes = {}
    end
    updateHUD()
end)

SpinToggle.MouseButton1Click:Connect(function()
    spinEnabled = not spinEnabled
    SpinToggle.Text             = spinEnabled and "Spin Bot: ON" or "Spin Bot: OFF"
    SpinToggle.BackgroundColor3 = spinEnabled and Color3.fromRGB(40,110,40) or Color3.fromRGB(55,55,55)
    if not spinEnabled then spinAngle = 0 end
    updateHUD()
end)

GlitchToggle.MouseButton1Click:Connect(function()
    jumpGlitchEnabled = not jumpGlitchEnabled
    GlitchToggle.Text             = jumpGlitchEnabled and "Jump Glitch: ON" or "Jump Glitch: OFF"
    GlitchToggle.BackgroundColor3 = jumpGlitchEnabled and Color3.fromRGB(40,110,40) or Color3.fromRGB(55,55,55)
    updateHUD()
end)

-- ── Bomb tab ──────────────────────────────────────────────────────────────────
local BC = contentFrames["Bomb"]

local BombToggle       = mkBtn(BC, "Bomb Speed: OFF", 5, false)
local updateBombSlider = mkSlider(BC, 32, bombSpeed, 1, 100, "Speed", function(v) bombSpeed = v end)

BombToggle.MouseButton1Click:Connect(function()
    bombSpeedEnabled = not bombSpeedEnabled
    BombToggle.Text             = bombSpeedEnabled and "Bomb Speed: ON" or "Bomb Speed: OFF"
    BombToggle.BackgroundColor3 = bombSpeedEnabled and Color3.fromRGB(40,110,40) or Color3.fromRGB(55,55,55)
    updateHUD()
end)

-- ── Settings tab ──────────────────────────────────────────────────────────────
local SC = contentFrames["Settings"]

local LadderBtn     = mkBtn(SC, "Ladder Check: ON",   5,   true)
local FrozenBtn     = mkBtn(SC, "Frozen Check: ON",   32,  true)
local JumpUnlockBtn = mkBtn(SC, "Jump Unlock: OFF",   59,  false)
local InfJumpBtn    = mkBtn(SC, "Infinite Jump: OFF", 86,  false)
local NoclipBtn     = mkBtn(SC, "Noclip: OFF",        113, false)

local SaveBtn = Instance.new("TextButton")
SaveBtn.Text             = "Save Config"
SaveBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
SaveBtn.TextSize         = 13
SaveBtn.Font             = Enum.Font.Gotham
SaveBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 130)
SaveBtn.BorderSizePixel  = 0
SaveBtn.Size             = UDim2.new(0.9, 0, 0, 22)
SaveBtn.Position         = UDim2.new(0.05, 0, 0, 140)
SaveBtn.Parent           = SC
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 6)

LadderBtn.MouseButton1Click:Connect(function()
    ladderCheckEnabled = not ladderCheckEnabled
    LadderBtn.Text             = ladderCheckEnabled and "Ladder Check: ON" or "Ladder Check: OFF"
    LadderBtn.BackgroundColor3 = ladderCheckEnabled and Color3.fromRGB(40,110,40) or Color3.fromRGB(55,55,55)
end)

FrozenBtn.MouseButton1Click:Connect(function()
    frozenCheckEnabled = not frozenCheckEnabled
    FrozenBtn.Text             = frozenCheckEnabled and "Frozen Check: ON" or "Frozen Check: OFF"
    FrozenBtn.BackgroundColor3 = frozenCheckEnabled and Color3.fromRGB(40,110,40) or Color3.fromRGB(55,55,55)
end)

JumpUnlockBtn.MouseButton1Click:Connect(function()
    jumpUnlockEnabled = not jumpUnlockEnabled
    JumpUnlockBtn.Text             = jumpUnlockEnabled and "Jump Unlock: ON" or "Jump Unlock: OFF"
    JumpUnlockBtn.BackgroundColor3 = jumpUnlockEnabled and Color3.fromRGB(40,110,40) or Color3.fromRGB(55,55,55)
    updateHUD()
end)

InfJumpBtn.MouseButton1Click:Connect(function()
    infiniteJumpEnabled = not infiniteJumpEnabled
    InfJumpBtn.Text             = infiniteJumpEnabled and "Infinite Jump: ON" or "Infinite Jump: OFF"
    InfJumpBtn.BackgroundColor3 = infiniteJumpEnabled and Color3.fromRGB(40,110,40) or Color3.fromRGB(55,55,55)
    updateHUD()
end)

NoclipBtn.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    NoclipBtn.Text             = noclipEnabled and "Noclip: ON" or "Noclip: OFF"
    NoclipBtn.BackgroundColor3 = noclipEnabled and Color3.fromRGB(40,110,40) or Color3.fromRGB(55,55,55)
    if not noclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then v.CanCollide = true end
            end
        end
    end
    updateHUD()
end)

-- ── Keys tab ──────────────────────────────────────────────────────────────────
local KT = contentFrames["Keys"]

local KEYBIND_FEATURES = {
    {key="regularSpeed", label="Speed"},
    {key="bombSpeed",    label="Bomb Speed"},
    {key="hbExpand",     label="HB Expand"},
    {key="spinBot",      label="Spin Bot"},
    {key="jumpGlitch",   label="Jump Glitch"},
    {key="jumpUnlock",   label="Jump Unlock"},
    {key="infiniteJump", label="Inf Jump"},
    {key="noclip",       label="Noclip"},
}

for i, feat in ipairs(KEYBIND_FEATURES) do
    local y = 5 + (i-1) * 23

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Text                   = feat.label
    nameLbl.TextColor3             = Color3.fromRGB(210, 210, 210)
    nameLbl.TextSize               = 12
    nameLbl.Font                   = Enum.Font.Gotham
    nameLbl.BackgroundTransparency = 1
    nameLbl.BorderSizePixel        = 0
    nameLbl.Size                   = UDim2.new(0, 95, 0, 22)
    nameLbl.Position               = UDim2.new(0, 10, 0, y)
    nameLbl.TextXAlignment         = Enum.TextXAlignment.Left
    nameLbl.Parent                 = KT

    local kbBtn = Instance.new("TextButton")
    kbBtn.Text             = "[NONE]"
    kbBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
    kbBtn.TextSize         = 11
    kbBtn.Font             = Enum.Font.Gotham
    kbBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    kbBtn.BorderSizePixel  = 0
    kbBtn.Size             = UDim2.new(0, 95, 0, 22)
    kbBtn.Position         = UDim2.new(0, 112, 0, y)
    kbBtn.Parent           = KT
    Instance.new("UICorner", kbBtn).CornerRadius = UDim.new(0, 5)

    kbButtons[feat.key] = kbBtn

    local fkey = feat.key
    kbBtn.MouseButton1Click:Connect(function()
        if listeningForFeature and listeningForFeature ~= fkey then
            local prev = kbButtons[listeningForFeature]
            if prev then
                local prevKc = keybinds[listeningForFeature]
                prev.Text             = prevKc and ("[" .. prevKc.Name .. "]") or "[NONE]"
                prev.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
            end
        end
        listeningForFeature     = fkey
        kbBtn.Text             = "Press key..."
        kbBtn.BackgroundColor3 = Color3.fromRGB(100, 90, 20)
    end)
end

-- ── Toggle dispatch (used by keybinds) ───────────────────────────────────────
local function fireToggle(fname)
    if fname == "regularSpeed" then
        regularSpeedEnabled = not regularSpeedEnabled
        RegularToggle.Text             = regularSpeedEnabled and "Speed: ON" or "Speed: OFF"
        RegularToggle.BackgroundColor3 = regularSpeedEnabled and Color3.fromRGB(40,110,40) or Color3.fromRGB(55,55,55)
    elseif fname == "bombSpeed" then
        bombSpeedEnabled = not bombSpeedEnabled
        BombToggle.Text             = bombSpeedEnabled and "Bomb Speed: ON" or "Bomb Speed: OFF"
        BombToggle.BackgroundColor3 = bombSpeedEnabled and Color3.fromRGB(40,110,40) or Color3.fromRGB(55,55,55)
    elseif fname == "hbExpand" then
        hbEnabled = not hbEnabled
        HBToggle.Text             = hbEnabled and "HB Expand: ON" or "HB Expand: OFF"
        HBToggle.BackgroundColor3 = hbEnabled and Color3.fromRGB(40,110,40) or Color3.fromRGB(55,55,55)
        if not hbEnabled then
            for part, orig in pairs(originalSizes) do
                if part and part.Parent then part.Size = orig.size; part.CanCollide = orig.canCollide end
            end
            originalSizes = {}
        end
    elseif fname == "spinBot" then
        spinEnabled = not spinEnabled
        SpinToggle.Text             = spinEnabled and "Spin Bot: ON" or "Spin Bot: OFF"
        SpinToggle.BackgroundColor3 = spinEnabled and Color3.fromRGB(40,110,40) or Color3.fromRGB(55,55,55)
        if not spinEnabled then spinAngle = 0 end
    elseif fname == "jumpGlitch" then
        jumpGlitchEnabled = not jumpGlitchEnabled
        GlitchToggle.Text             = jumpGlitchEnabled and "Jump Glitch: ON" or "Jump Glitch: OFF"
        GlitchToggle.BackgroundColor3 = jumpGlitchEnabled and Color3.fromRGB(40,110,40) or Color3.fromRGB(55,55,55)
    elseif fname == "jumpUnlock" then
        jumpUnlockEnabled = not jumpUnlockEnabled
        JumpUnlockBtn.Text             = jumpUnlockEnabled and "Jump Unlock: ON" or "Jump Unlock: OFF"
        JumpUnlockBtn.BackgroundColor3 = jumpUnlockEnabled and Color3.fromRGB(40,110,40) or Color3.fromRGB(55,55,55)
    elseif fname == "infiniteJump" then
        infiniteJumpEnabled = not infiniteJumpEnabled
        InfJumpBtn.Text             = infiniteJumpEnabled and "Infinite Jump: ON" or "Infinite Jump: OFF"
        InfJumpBtn.BackgroundColor3 = infiniteJumpEnabled and Color3.fromRGB(40,110,40) or Color3.fromRGB(55,55,55)
    elseif fname == "noclip" then
        noclipEnabled = not noclipEnabled
        NoclipBtn.Text             = noclipEnabled and "Noclip: ON" or "Noclip: OFF"
        NoclipBtn.BackgroundColor3 = noclipEnabled and Color3.fromRGB(40,110,40) or Color3.fromRGB(55,55,55)
        if not noclipEnabled then
            local char = LocalPlayer.Character
            if char then
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then v.CanCollide = true end
                end
            end
        end
    end
    updateHUD()
end

-- ── Input handling ────────────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, processed)
    -- Rebind capture eats the key entirely
    if listeningForFeature then
        local fname = listeningForFeature
        listeningForFeature = nil
        local btn = kbButtons[fname]
        if input.UserInputType == Enum.UserInputType.Keyboard
                and input.KeyCode ~= Enum.KeyCode.Escape then
            keybinds[fname] = input.KeyCode
            if btn then btn.Text = "[" .. input.KeyCode.Name .. "]" end
        else
            if btn then
                local kc = keybinds[fname]
                btn.Text = kc and ("[" .. kc.Name .. "]") or "[NONE]"
            end
        end
        if btn then btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55) end
        updateHUD()
        return
    end

    -- Insert hides main Frame only — HUD stays visible
    if input.KeyCode == Enum.KeyCode.Insert then
        menuVisible = not menuVisible
        Frame.Visible = menuVisible
        return
    end

    if processed then return end

    for fname, kc in pairs(keybinds) do
        if kc and input.KeyCode == kc then
            fireToggle(fname)
            break
        end
    end
end)

-- Infinite jump
UserInputService.JumpRequest:Connect(function()
    if not infiniteJumpEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- ── Frame drag (title bar) ────────────────────────────────────────────────────
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
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- ── RenderStepped — speed / spin / jump unlock ────────────────────────────────
RunService.RenderStepped:Connect(function(dt)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    if jumpUnlockEnabled then
        if hum.JumpPower  <= 0 then hum.JumpPower  = 50  end
        if hum.JumpHeight <= 0 then hum.JumpHeight = 7.2 end
    end

    if frozenCheckEnabled then
        if hrp.Anchored then return end
        if hum.PlatformStand then return end
        for _, v in ipairs(hrp:GetChildren()) do
            if v:IsA("BodyPosition") or v:IsA("BodyVelocity") then return end
        end
    end

    if ladderCheckEnabled and isOnLadder(hum) then return end

    local dir = hum.MoveDirection
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

-- ── Heartbeat — HB expander ───────────────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not hbEnabled then return end
    local bombInHand = hasBomb()
    local sz = Vector3.new(hbSize, hbSize, hbSize)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            for _, part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    if bombInHand then
                        if not originalSizes[part] then
                            originalSizes[part] = {size = part.Size, canCollide = part.CanCollide}
                        end
                        part.Size = sz; part.CanCollide = false
                    else
                        local orig = originalSizes[part]
                        if orig and part.Parent then
                            part.Size = orig.size; part.CanCollide = orig.canCollide
                        end
                    end
                end
            end
        end
    end
    if not bombInHand then originalSizes = {} end
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

-- ── Jump glitch — forward burst on jump ──────────────────────────────────────
local function setupJumpGlitch(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    hum.StateChanged:Connect(function(_, new)
        if jumpGlitchEnabled and new == Enum.HumanoidStateType.Jumping then
            local dir = hum.MoveDirection
            if dir.Magnitude > 0 then
                hrp.AssemblyLinearVelocity = Vector3.new(
                    dir.X * 60,
                    hrp.AssemblyLinearVelocity.Y,
                    dir.Z * 60
                )
            end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(setupJumpGlitch)
if LocalPlayer.Character then setupJumpGlitch(LocalPlayer.Character) end

-- ── Config save / load ────────────────────────────────────────────────────────
local function saveConfig()
    local cfg = {
        regularSpeedEnabled = regularSpeedEnabled,
        regularSpeed        = regularSpeed,
        bombSpeedEnabled    = bombSpeedEnabled,
        bombSpeed           = bombSpeed,
        hbEnabled           = hbEnabled,
        hbSize              = hbSize,
        spinEnabled         = spinEnabled,
        jumpGlitchEnabled   = jumpGlitchEnabled,
        noclipEnabled       = noclipEnabled,
        ladderCheckEnabled  = ladderCheckEnabled,
        frozenCheckEnabled  = frozenCheckEnabled,
        jumpUnlockEnabled   = jumpUnlockEnabled,
        infiniteJumpEnabled = infiniteJumpEnabled,
        keybinds            = {}
    }
    for k, kc in pairs(keybinds) do cfg.keybinds[k] = kc.Name end
    local ok = pcall(writefile, "nocturnix_config.json",
        HttpService:JSONEncode(cfg))
    SaveBtn.Text = ok and "Saved!" or "Save Failed"
    task.delay(1.5, function()
        if SaveBtn and SaveBtn.Parent then SaveBtn.Text = "Save Config" end
    end)
end

local function loadConfig()
    if not (isfile and isfile("nocturnix_config.json")) then return end
    local ok, raw = pcall(readfile, "nocturnix_config.json")
    if not ok or type(raw) ~= "string" then return end
    local ok2, cfg = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(cfg) ~= "table" then return end

    local function rb(v, btn, on, off)
        btn.Text             = v and on or off
        btn.BackgroundColor3 = v and Color3.fromRGB(40,110,40) or Color3.fromRGB(55,55,55)
    end

    if cfg.regularSpeedEnabled ~= nil then regularSpeedEnabled = cfg.regularSpeedEnabled; rb(regularSpeedEnabled, RegularToggle, "Speed: ON",         "Speed: OFF")         end
    if cfg.bombSpeedEnabled    ~= nil then bombSpeedEnabled    = cfg.bombSpeedEnabled;    rb(bombSpeedEnabled,    BombToggle,    "Bomb Speed: ON",    "Bomb Speed: OFF")    end
    if cfg.hbEnabled           ~= nil then hbEnabled           = cfg.hbEnabled;           rb(hbEnabled,           HBToggle,      "HB Expand: ON",     "HB Expand: OFF")     end
    if cfg.spinEnabled         ~= nil then spinEnabled         = cfg.spinEnabled;         rb(spinEnabled,         SpinToggle,    "Spin Bot: ON",      "Spin Bot: OFF")      end
    if cfg.jumpGlitchEnabled   ~= nil then jumpGlitchEnabled   = cfg.jumpGlitchEnabled;   rb(jumpGlitchEnabled,   GlitchToggle,  "Jump Glitch: ON",   "Jump Glitch: OFF")   end
    if cfg.noclipEnabled       ~= nil then noclipEnabled       = cfg.noclipEnabled;       rb(noclipEnabled,       NoclipBtn,     "Noclip: ON",        "Noclip: OFF")        end
    if cfg.ladderCheckEnabled  ~= nil then ladderCheckEnabled  = cfg.ladderCheckEnabled;  rb(ladderCheckEnabled,  LadderBtn,     "Ladder Check: ON",  "Ladder Check: OFF")  end
    if cfg.frozenCheckEnabled  ~= nil then frozenCheckEnabled  = cfg.frozenCheckEnabled;  rb(frozenCheckEnabled,  FrozenBtn,     "Frozen Check: ON",  "Frozen Check: OFF")  end
    if cfg.jumpUnlockEnabled   ~= nil then jumpUnlockEnabled   = cfg.jumpUnlockEnabled;   rb(jumpUnlockEnabled,   JumpUnlockBtn, "Jump Unlock: ON",   "Jump Unlock: OFF")   end
    if cfg.infiniteJumpEnabled ~= nil then infiniteJumpEnabled = cfg.infiniteJumpEnabled; rb(infiniteJumpEnabled, InfJumpBtn,    "Infinite Jump: ON", "Infinite Jump: OFF") end

    if type(cfg.regularSpeed) == "number" then regularSpeed = cfg.regularSpeed; updateSpeedSlider(regularSpeed) end
    if type(cfg.bombSpeed)    == "number" then bombSpeed    = cfg.bombSpeed;    updateBombSlider(bombSpeed)     end
    if type(cfg.hbSize)       == "number" then hbSize       = cfg.hbSize;       updateHBSlider(hbSize)          end

    if type(cfg.keybinds) == "table" then
        for k, name in pairs(cfg.keybinds) do
            local kok, kc = pcall(function() return Enum.KeyCode[name] end)
            if kok and kc and kbButtons[k] then
                keybinds[k] = kc
                kbButtons[k].Text = "[" .. name .. "]"
            end
        end
    end
end

SaveBtn.MouseButton1Click:Connect(saveConfig)

-- ── Init ──────────────────────────────────────────────────────────────────────
loadConfig()
updateHUD()
switchTab("Regular")
