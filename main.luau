-- Runtime: Roblox executor (Synapse X / KRNL / Fluxus etc.)
-- Lib: LinoriaLib (violin-suzutsuki)

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Lighting   = game:GetService("Lighting")
local CoreGui    = game:GetService("CoreGui")
local LP         = Players.LocalPlayer
local Camera     = workspace.CurrentCamera

local NR  = NumberRange.new
local NS  = NumberSequence.new
local NSK = NumberSequenceKeypoint.new
local CS  = ColorSequence.new
local CSK = ColorSequenceKeypoint.new
local V2  = Vector2.new
local V3  = Vector3.new
local C3  = Color3.fromRGB

-- ======== VISUALS FOLDER ========
-- Creates Timebomb_Visuals/ on first run, writes a source guide,
-- then auto-loadstrings any .lua files found inside it.
local VISUALS_FOLDER = "Timebomb_Visuals"
pcall(function()
    if not isfolder(VISUALS_FOLDER) then
        makefolder(VISUALS_FOLDER)
        writefile(VISUALS_FOLDER .. "/README.txt", [[
==================================================================
 Timebomb Duels  —  Free Visuals Drop Folder
==================================================================

Drop any .lua visual script here and it loads automatically
every time the script runs.

-- READY-TO-USE SNIPPETS --

[1] Universal Highlight Chams
    Save as "chams.lua" in this folder:

    for _, p in ipairs(game.Players:GetPlayers()) do
      if p ~= game.Players.LocalPlayer and p.Character then
        local h = Instance.new("Highlight", p.Character)
        h.FillColor    = Color3.fromRGB(255, 0, 0)
        h.OutlineColor = Color3.fromRGB(255, 255, 255)
        h.FillTransparency    = 0.3
        h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
      end
    end
    game.Players.PlayerAdded:Connect(function(p)
      p.CharacterAdded:Connect(function(c)
        local h = Instance.new("Highlight", c)
        h.FillColor = Color3.fromRGB(255,0,0)
        h.OutlineColor = Color3.fromRGB(255,255,255)
        h.FillTransparency = 0.3
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
      end)
    end)

[2] Infinite Yield (full hub):
    Save as "iy.lua":
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()

[3] SimpleSpy (remote spy):
    Save as "simplespy.lua":
    loadstring(game:HttpGet("https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua"))()

-- COMMUNITY --
  discord.gg/ojailbreaks
  discord.gg/enhancements

==================================================================
]])
    end
    for _, file in ipairs(listfiles(VISUALS_FOLDER)) do
        if file:sub(-4):lower() == ".lua" then
            pcall(function() loadstring(readfile(file))() end)
        end
    end
end)

-- ======== STATE ========
local regularSpeedEnabled = false; local regularSpeed = 20
local bombSpeedEnabled    = false; local bombSpeed    = 25
local spinEnabled         = false; local spinAngle    = 0
local ladderCheckEnabled  = true;  local frozenCheckEnabled = true
local infiniteJumpEnabled = false; local jumpHeld     = false
local noclipEnabled       = false
local followEnabled       = false; local followTarget = nil; local followDist = 3
local headlessEnabled     = false; local korbloxEnabled = false
local trailEnabled        = false; local trailColorKey  = "Purple"
local rainEnabled         = false; local thunderEnabled = false
local rainObj             = nil;   local rainConn      = nil; local thunderConn = nil
local fovEnabled          = false; local customFOV     = 70
local shaderActive        = "None"
local auraType            = "None"
local wingsStyle          = "None"
local haloEnabled         = false; local haloAngle = 0; local haloObj = nil
local instantRespawn      = false
local arFOVMult           = 1.0

-- ======== SILENT AIM STATE ========
local sa = {
    Enabled    = false,
    FovRadius  = 150,
    Prediction = 0.12,
    WallCheck  = true,
    TeamCheck  = false,
    HitPart    = "HumanoidRootPart",
}
local mb1Down = false
local saTarget   = nil   -- current locked target part (hookmetamethod SA)

local rb = {
    Enabled   = false,
    Delay     = 0.1,
    DoubleTap = false,
}
local rbLastFire = 0

-- cycle resolver: tries each Y-angle offset per shot until one registers a hit
local rbCycle = {
    Enabled  = false,
    offsets  = {0, 45, -45, 90, -90, 135, -135, 180},
    idx      = 1,
    prevHP   = nil,
    locked   = nil,    -- offset that last landed a hit
    lockedPl = nil,
}
local rbCycleOffset = 0  -- active offset (degrees) fed into hookmetamethod

local saTargetPlayer = nil

local plrHistory = {}   -- [player] = {positions={{pos=V3,t=number},...}}

local hvh = {
    -- Anti-aim
    AAEnabled = false,
    AAMode    = "Spin",
    AASpeed   = 20,
    aaAngle   = 0,
    aaFlip    = false,
    -- Fake lag
    FLEnabled = false,
    FLTicks   = 6,
    flCount   = 0,
    -- Void
    VoidSpam   = false,
    VoidHold   = false,
    VoidDelay  = 0.1,
    voidActive = false,
    voidOrigin = nil,
    voidTimer  = 0,
    -- Resolver / Backtrack
    ResEnabled = false,
    ResMode    = "Backtrack",
    BTTicks    = 3,
}

local FovCircle = Drawing.new("Circle")
FovCircle.Color    = Color3.fromRGB(165, 95, 255)
FovCircle.Thickness = 1
FovCircle.Filled   = false
FovCircle.Visible  = false

-- ======== ESP STATE ========
local esp = {
    Enabled     = false,
    Boxes       = true,
    FilledBoxes = false,
    FilledAlpha = 0.15,
    Names       = true,
    Health      = true,
    Tracers     = false,
    Distance    = true,
    Chams       = false,
    MaxDist     = 1000,
    TextSize    = 13,
    BoxThick    = 1.5,
    BoxColor    = C3(255, 243, 220),
    FilledColor = C3(255, 235, 200),
    NameColor   = C3(255, 250, 238),
    TracerColor = C3(190, 140, 255),
    ChamFill    = C3(220, 175, 255),
    ChamOutline = C3(255, 243, 220),
}

-- ======== LIGHTING SAVE ========
local origLight = {
    Brightness     = Lighting.Brightness,
    Ambient        = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd         = Lighting.FogEnd,
    FogColor       = Lighting.FogColor,
    ClockTime      = Lighting.ClockTime,
}

-- ======== PRESETS ========
local SCENE_PRESETS = {
    ["Ultra Realism"] ={brightness=3,  ambient={80,80,95},   outdoor={100,100,120},fog=2000,fogcol={180,190,210},clock=14},
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
local SHADER_PRESETS = {
    ["None"]        = {},
    ["Cinematic"]   = {cc={0,0.35,0.3,{255,235,210}}, bloom={0.4,24,0.95}, sun={0.15,0.5}},
    ["Vibrant"]     = {cc={0.05,0.2,0.8,{255,255,255}}, bloom={0.8,24,0.9}},
    ["Dark Film"]   = {cc={-0.05,0.55,-0.4,{200,200,235}}, blur=4},
    ["Neon Glow"]   = {cc={0,0,1.3,{255,255,255}}, bloom={2,56,0.75}},
    ["Warm Sunset"] = {cc={0.1,0.2,0.5,{255,210,170}}, sun={0.3,0.9}, bloom={0.5,24,0.9}},
    ["Cold Blue"]   = {cc={0,0.3,0.4,{190,210,255}}, bloom={0.3,20,0.95}},
    ["Depth"]       = {cc={0,0.4,0.5,{255,255,255}}, dof={1,60,15,0}},
}
local TRAIL_COLORS = {
    ["Purple"] = {C3(165,95,255),  C3(100,30,200)},
    ["Cyan"]   = {C3(0,230,255),   C3(0,140,200)},
    ["Fire"]   = {C3(255,120,0),   C3(255,0,0)},
    ["Ice"]    = {C3(180,235,255), C3(255,255,255)},
    ["Gold"]   = {C3(255,200,0),   C3(220,130,0)},
    ["White"]  = {C3(255,255,255), C3(180,180,180)},
}

-- ======== HELPERS ========
local function hasBomb()
    local c = LP.Character
    return c and (c:FindFirstChild("bomb") or c:FindFirstChild("Bomb")) ~= nil
end
local function isOnLadder(hum) return hum:GetState() == Enum.HumanoidStateType.Climbing end

-- ======== ASPECT RATIO BARS ========
local arGui = Instance.new("ScreenGui")
arGui.Name = "TB_AR"; arGui.ResetOnSpawn = false
arGui.DisplayOrder = 60; arGui.IgnoreGuiInset = true
pcall(function() arGui.Parent = CoreGui end)
if not arGui.Parent then arGui.Parent = LP.PlayerGui end
local function mkBar(n)
    local f = Instance.new("Frame", arGui)
    f.Name = n; f.BackgroundColor3 = Color3.new(0,0,0); f.BorderSizePixel = 0; f.Size = UDim2.new(0,0,0,0)
    return f
end
local arT = mkBar("T"); local arB = mkBar("B"); local arL = mkBar("L"); local arR = mkBar("R")

local function setAspectRatio(r)
    for _, b in ipairs({arT, arB, arL, arR}) do b.Size = UDim2.new(0,0,0,0) end
    arFOVMult = 1.0
    if r == "21:9" then
        arT.Size = UDim2.new(1,0,0.119,0); arT.Position = UDim2.new(0,0,0,0)
        arB.Size = UDim2.new(1,0,0.119,0); arB.Position = UDim2.new(0,0,0.881,0)
        arFOVMult = 0.762
    elseif r == "4:3" then
        arL.Size = UDim2.new(0.125,0,1,0); arL.Position = UDim2.new(0,0,0,0)
        arR.Size = UDim2.new(0.125,0,1,0); arR.Position = UDim2.new(0.875,0,0,0)
    elseif r == "2.35:1" then
        arT.Size = UDim2.new(1,0,0.121,0); arT.Position = UDim2.new(0,0,0,0)
        arB.Size = UDim2.new(1,0,0.121,0); arB.Position = UDim2.new(0,0,0.879,0)
        arFOVMult = 0.758
    elseif r == "1:1" then
        arL.Size = UDim2.new(0.219,0,1,0); arL.Position = UDim2.new(0,0,0,0)
        arR.Size = UDim2.new(0.219,0,1,0); arR.Position = UDim2.new(0.781,0,0,0)
    else
        if not fovEnabled then workspace.CurrentCamera.FieldOfView = 70 end
    end
end

-- ======== SHADER ========
local function clearShaders()
    for _, c in ipairs(Lighting:GetChildren()) do
        if c:IsA("PostEffect") and c:GetAttribute("_TB") then c:Destroy() end
    end
end
local function applyShader(name)
    clearShaders()
    local p = SHADER_PRESETS[name]; if not p then return end
    local function mk(cls, props)
        local obj = Instance.new(cls, Lighting); obj:SetAttribute("_TB", true)
        for k, v in pairs(props) do obj[k] = v end
    end
    if p.cc    then mk("ColorCorrectionEffect", {Brightness=p.cc[1],Contrast=p.cc[2],Saturation=p.cc[3],TintColor=C3(unpack(p.cc[4]))}) end
    if p.bloom then mk("BloomEffect",           {Intensity=p.bloom[1],Size=p.bloom[2],Threshold=p.bloom[3]}) end
    if p.sun   then mk("SunRaysEffect",         {Intensity=p.sun[1],Spread=p.sun[2]}) end
    if p.blur  then mk("BlurEffect",            {Size=p.blur}) end
    if p.dof   then mk("DepthOfFieldEffect",    {FarIntensity=p.dof[1],FocusDistance=p.dof[2],InFocusRadius=p.dof[3],NearIntensity=p.dof[4]}) end
end

-- ======== RAIN / THUNDER ========
local function setRain(on, rate)
    if rainConn then rainConn:Disconnect(); rainConn = nil end
    if rainObj  then rainObj:Destroy(); rainObj = nil end
    if not on then return end
    local part = Instance.new("Part"); part.Name = "_RainPart"
    part.Size = V3(600,1,600); part.Anchored = true; part.CanCollide = false
    part.CastShadow = false; part.Transparency = 1; part.Parent = workspace
    rainObj = part
    local em = Instance.new("ParticleEmitter", part); em.Name = "_RainFX"
    em.Color = CS{CSK.new(0,C3(180,205,235)), CSK.new(1,C3(150,180,215))}
    em.Transparency = NS{NSK.new(0,0.15), NSK.new(0.85,0.15), NSK.new(1,1)}
    em.Size = NS(0.025); em.Speed = NR(100,130); em.Rate = rate or 1500; em.Lifetime = NR(0.6,1)
    em.Rotation = NR(10,14); em.RotSpeed = NR(0,0); em.SpreadAngle = V2(4,0)
    em.EmissionDirection = Enum.NormalId.Bottom; em.LockedToPart = false
    em.LightEmission = 0; em.LightInfluence = 1
    rainConn = RunService.Heartbeat:Connect(function()
        if rainObj and rainObj.Parent then
            rainObj.CFrame = CFrame.new(Camera.CFrame.Position + V3(0,70,0))
        end
    end)
end
local function updateRainRate(rate)
    if rainObj then local em = rainObj:FindFirstChild("_RainFX"); if em then em.Rate = rate end end
end
local function setThunder(on)
    if thunderConn then thunderConn:Disconnect(); thunderConn = nil end
    if not on then return end
    thunderConn = RunService.Heartbeat:Connect(function()
        if math.random(1,500) == 1 then
            local orig = Lighting.Brightness
            Lighting.Brightness = math.clamp(orig*8, 5, 15)
            task.delay(0.05, function()
                Lighting.Brightness = orig
                if math.random(1,2) == 1 then
                    task.delay(0.04, function()
                        Lighting.Brightness = math.clamp(orig*4, 3, 10)
                        task.delay(0.04, function() Lighting.Brightness = orig end)
                    end)
                end
            end)
        end
    end)
end

-- ======== HEADLESS / KORBLOX ========
local function applyHeadless(on)
    local char = LP.Character; if not char then return end
    local head = char:FindFirstChild("Head"); if not head then return end
    head.Transparency = on and 1 or 0
    for _, d in ipairs(head:GetDescendants()) do if d:IsA("Decal") then d.Transparency = on and 1 or 0 end end
    for _, acc in ipairs(char:GetChildren()) do
        if acc:IsA("Accessory") then
            local h = acc:FindFirstChild("Handle"); if not h then continue end
            for _, w in ipairs(h:GetChildren()) do
                if w:IsA("Weld") or w:IsA("WeldConstraint") then
                    local other = w.Part0 == h and w.Part1 or w.Part0
                    if other and other.Name == "Head" then h.Transparency = on and 1 or 0 end
                end
            end
        end
    end
end
local function applyKorblox(on)
    local char = LP.Character; if not char then return end
    local old = char:FindFirstChild("_KorbloxPart"); if old then old:Destroy() end
    local isR15 = char:FindFirstChild("RightLowerLeg") ~= nil
    if isR15 then
        for _, n in ipairs({"RightLowerLeg","RightFoot"}) do local p = char:FindFirstChild(n); if p then p.Transparency = on and 1 or 0 end end
        if not on then return end
        local rup = char:FindFirstChild("RightUpperLeg"); if not rup then return end
        local part = Instance.new("Part"); part.Name = "_KorbloxPart"; part.Size = V3(0.5,2.6,0.5)
        part.Anchored = false; part.CanCollide = false
        local mesh = Instance.new("SpecialMesh", part); mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = "rbxassetid://6340101562"; mesh.TextureId = "rbxassetid://6340101616"; mesh.Scale = V3(1,1,1)
        part.CFrame = rup.CFrame * CFrame.new(0,-1.3,0); part.Parent = char
        local wc = Instance.new("WeldConstraint", part); wc.Part0 = rup; wc.Part1 = part
    else
        local rl = char:FindFirstChild("Right Leg"); if rl then rl.Transparency = on and 1 or 0 end
        if not on then return end
        local torso = char:FindFirstChild("Torso"); if not torso then return end
        local part = Instance.new("Part"); part.Name = "_KorbloxPart"; part.Size = V3(1,2,1)
        part.Anchored = false; part.CanCollide = false
        local mesh = Instance.new("SpecialMesh", part); mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = "rbxassetid://48474629"; mesh.Scale = V3(1,1,1)
        part.CFrame = torso.CFrame * CFrame.new(0.5,-1.5,0); part.Parent = char
        local wc = Instance.new("WeldConstraint", part); wc.Part0 = torso; wc.Part1 = part
    end
end

-- ======== TRAILS ========
local function applyTrails(on)
    local char = LP.Character; if not char or not char.Parent then return end
    for _, d in ipairs(char:GetDescendants()) do if d.Name == "_TrailAtt" or d.Name == "_FootTrail" then d:Destroy() end end
    if not on then return end
    local cols = TRAIL_COLORS[trailColorKey] or TRAIL_COLORS["Purple"]
    local feet = {}
    for _, n in ipairs({"LeftFoot","RightFoot"}) do local p = char:FindFirstChild(n); if p then feet[#feet+1] = p end end
    if #feet == 0 then for _, n in ipairs({"Left Leg","Right Leg"}) do local p = char:FindFirstChild(n); if p then feet[#feet+1] = p end end end
    for _, foot in ipairs(feet) do
        local a0 = Instance.new("Attachment", foot); a0.Name = "_TrailAtt"; a0.Position = V3(0,-0.4,0.3)
        local a1 = Instance.new("Attachment", foot); a1.Name = "_TrailAtt"; a1.Position = V3(0,-0.4,-0.3)
        local t = Instance.new("Trail", foot); t.Name = "_FootTrail"
        t.Attachment0 = a0; t.Attachment1 = a1; t.Lifetime = 0.45; t.MinLength = 0
        t.FaceCamera = true; t.LightEmission = 0.4; t.LightInfluence = 0.5
        t.Color = CS{CSK.new(0,cols[1]), CSK.new(1,cols[2])}
        t.Transparency = NS{NSK.new(0,0), NSK.new(0.5,0.25), NSK.new(1,1)}
        t.WidthScale = NS{NSK.new(0,1), NSK.new(1,0)}
    end
end

-- ======== AURA SYSTEM ========
local function mkFX(parent, t)
    local em = Instance.new("ParticleEmitter", parent); em:SetAttribute("_AuraFX", true)
    if t.color  then em.Color      = t.color  end
    if t.size   then em.Size       = t.size   end
    if t.trans  then em.Transparency = t.trans end
    em.LightEmission  = t.le     or 0.8
    em.LightInfluence = t.li     or 0
    em.Speed          = t.spd    or NR(5,10)
    em.Rate           = t.rate   or 50
    em.Lifetime       = t.life   or NR(1,2)
    em.SpreadAngle    = t.spread or V2(30,30)
    em.EmissionDirection = t.dir or Enum.NormalId.Top
    em.RotSpeed       = t.rotspd or NR(-30,30)
    em.Rotation       = t.rot    or NR(0,360)
    return em
end
local function mkAtt(p, pos)
    local a = Instance.new("Attachment", p); a.Position = pos or V3(0,0,0)
    a:SetAttribute("_AuraFX", true); return a
end
local function mkHL(char, fc, fo, ft, ot)
    local h = Instance.new("Highlight", char); h.Name = "_AuraHL"; h:SetAttribute("_AuraFX", true)
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.FillColor = fc; h.FillTransparency = ft or 0.85
    h.OutlineColor = fo; h.OutlineTransparency = ot or 0.3
    return h
end
local function clearAura(char)
    if not char then return end
    for _, d in ipairs(char:GetDescendants()) do if d:GetAttribute("_AuraFX") then d:Destroy() end end
    for _, c in ipairs(char:GetChildren()) do if c:IsA("Highlight") and c.Name == "_AuraHL" then c:Destroy() end end
end

local AURAS = {}
AURAS["Purple Storm"] = function(char, hrp)
    mkHL(char, C3(165,95,255), C3(220,180,255), 0.85, 0.25)
    local att = mkAtt(hrp, V3(0,-2,0))
    mkFX(att, {color=CS{CSK.new(0,C3(165,95,255)),CSK.new(0.5,C3(120,20,220)),CSK.new(1,C3(60,0,140))},
        size=NS{NSK.new(0,0.4),NSK.new(0.5,0.65),NSK.new(1,0)},
        trans=NS{NSK.new(0,0.3),NSK.new(0.7,0.4),NSK.new(1,1)},
        spd=NR(5,12),rate=65,life=NR(1.5,2.8),spread=V2(22,22),rotspd=NR(-60,60)})
    mkFX(att, {color=CS{CSK.new(0,C3(240,210,255)),CSK.new(1,C3(200,150,255))},
        size=NS{NSK.new(0,0.08),NSK.new(1,0)},trans=NS{NSK.new(0,0),NSK.new(1,1)},
        spd=NR(12,25),rate=35,life=NR(0.15,0.5),spread=V2(100,100),le=1})
    mkFX(mkAtt(hrp,V3(0,-2.5,0)), {color=CS{CSK.new(0,C3(80,0,200)),CSK.new(1,C3(140,50,255))},
        size=NS{NSK.new(0,0.3),NSK.new(1,0)},trans=NS{NSK.new(0,0.5),NSK.new(1,1)},
        spd=NR(1,4),rate=40,life=NR(0.8,1.5),spread=V2(80,10),dir=Enum.NormalId.Front})
end
AURAS["Blue Flames"] = function(char, hrp)
    mkHL(char, C3(0,160,255), C3(100,220,255), 0.85, 0.2)
    local att = mkAtt(hrp, V3(0,-2,0))
    mkFX(att, {color=CS{CSK.new(0,C3(0,80,255)),CSK.new(0.4,C3(0,180,255)),CSK.new(1,C3(200,240,255))},
        size=NS{NSK.new(0,0.5),NSK.new(0.4,0.3),NSK.new(1,0)},
        trans=NS{NSK.new(0,0.2),NSK.new(0.6,0.4),NSK.new(1,1)},
        spd=NR(6,14),rate=70,life=NR(1,2),spread=V2(18,18),rotspd=NR(-40,40)})
    mkFX(att, {color=CS(C3(180,230,255)),size=NS{NSK.new(0,0.12),NSK.new(1,0)},
        trans=NS{NSK.new(0,0),NSK.new(1,1)},spd=NR(8,16),rate=20,life=NR(0.2,0.6),spread=V2(30,30),le=1})
end
AURAS["Galaxy"] = function(char, hrp)
    mkHL(char, C3(10,10,60), C3(80,100,255), 0.9, 0.2)
    local att = mkAtt(hrp, V3(0,-1,0))
    mkFX(att, {color=CS{CSK.new(0,C3(255,255,255)),CSK.new(0.5,C3(180,200,255)),CSK.new(1,C3(100,120,255))},
        size=NS{NSK.new(0,0.08),NSK.new(0.5,0.12),NSK.new(1,0)},
        trans=NS{NSK.new(0,0),NSK.new(0.8,0.3),NSK.new(1,1)},
        spd=NR(1,5),rate=45,life=NR(2,4),spread=V2(180,180),rotspd=NR(-15,15),le=0.9})
    mkFX(att, {color=CS{CSK.new(0,C3(80,80,180)),CSK.new(1,C3(40,40,120))},
        size=NS{NSK.new(0,0.8),NSK.new(1,0)},trans=NS{NSK.new(0,0.7),NSK.new(1,1)},
        spd=NR(0.5,2),rate=20,life=NR(2,4),spread=V2(180,180),le=0.3})
end
AURAS["Ice Crystals"] = function(char, hrp)
    mkHL(char, C3(140,220,255), C3(220,245,255), 0.82, 0.2)
    local att = mkAtt(hrp, V3(0,1,0))
    mkFX(att, {color=CS{CSK.new(0,C3(220,245,255)),CSK.new(0.6,C3(140,210,255)),CSK.new(1,C3(80,160,220))},
        size=NS{NSK.new(0,0.08),NSK.new(0.3,0.15),NSK.new(1,0)},
        trans=NS{NSK.new(0,0.1),NSK.new(0.8,0.3),NSK.new(1,1)},
        spd=NR(1,4),rate=40,life=NR(2,3.5),spread=V2(50,50),
        dir=Enum.NormalId.Bottom,rotspd=NR(-90,90),le=0.6})
    mkFX(mkAtt(hrp,V3(0,-2,0)), {color=CS(C3(255,255,255)),
        size=NS{NSK.new(0,0.3),NSK.new(1,0)},trans=NS{NSK.new(0,0.6),NSK.new(1,1)},
        spd=NR(0.5,2),rate=25,life=NR(1.5,2.5),spread=V2(100,10),le=0.4})
end
AURAS["Shadow"] = function(char, hrp)
    mkHL(char, C3(0,0,0), C3(60,0,80), 0.8, 0.0)
    local att = mkAtt(hrp, V3(0,-2.5,0))
    mkFX(att, {color=CS{CSK.new(0,C3(0,0,0)),CSK.new(0.5,C3(30,0,50)),CSK.new(1,C3(0,0,0))},
        size=NS{NSK.new(0,0.6),NSK.new(0.4,1.0),NSK.new(1,0)},
        trans=NS{NSK.new(0,0.3),NSK.new(0.5,0.5),NSK.new(1,1)},
        spd=NR(2,6),rate=55,life=NR(1.5,2.5),spread=V2(60,30),rotspd=NR(-20,20),le=0.0,li=1})
    mkFX(mkAtt(hrp,V3(0,0,0)), {color=CS{CSK.new(0,C3(80,0,120)),CSK.new(1,C3(0,0,0))},
        size=NS{NSK.new(0,0.08),NSK.new(1,0)},trans=NS{NSK.new(0,0),NSK.new(1,1)},
        spd=NR(5,12),rate=20,life=NR(0.3,0.8),spread=V2(90,90),le=0.4})
end
AURAS["Golden Divine"] = function(char, hrp)
    mkHL(char, C3(255,200,0), C3(255,230,100), 0.85, 0.2)
    local att = mkAtt(hrp, V3(0,-2,0))
    mkFX(att, {color=CS{CSK.new(0,C3(255,200,0)),CSK.new(0.6,C3(255,160,0)),CSK.new(1,C3(255,220,100))},
        size=NS{NSK.new(0,0.3),NSK.new(0.4,0.5),NSK.new(1,0)},
        trans=NS{NSK.new(0,0.2),NSK.new(0.7,0.4),NSK.new(1,1)},
        spd=NR(6,14),rate=55,life=NR(1,2),spread=V2(20,20),rotspd=NR(-30,30)})
    mkFX(att, {color=CS(C3(255,255,180)),size=NS{NSK.new(0,0.15),NSK.new(1,0)},
        trans=NS{NSK.new(0,0),NSK.new(1,1)},spd=NR(3,8),rate=30,life=NR(0.5,1.2),spread=V2(60,60),le=1})
end
AURAS["Lightning"] = function(char, hrp)
    mkHL(char, C3(200,230,255), C3(255,255,255), 0.9, 0.0)
    local att = mkAtt(hrp, V3(0,0,0))
    mkFX(att, {color=CS{CSK.new(0,C3(255,255,255)),CSK.new(0.5,C3(180,220,255)),CSK.new(1,C3(100,180,255))},
        size=NS{NSK.new(0,0.06),NSK.new(0.2,0.1),NSK.new(1,0)},
        trans=NS{NSK.new(0,0),NSK.new(0.5,0.3),NSK.new(1,1)},
        spd=NR(15,30),rate=80,life=NR(0.08,0.3),spread=V2(180,180),le=1})
    mkFX(mkAtt(hrp,V3(0,-1,0)), {color=CS{CSK.new(0,C3(100,180,255)),CSK.new(1,C3(0,120,255))},
        size=NS{NSK.new(0,0.3),NSK.new(0.3,0.4),NSK.new(1,0)},
        trans=NS{NSK.new(0,0.4),NSK.new(1,1)},spd=NR(4,10),rate=40,
        life=NR(0.5,1.2),spread=V2(30,30),le=0.8})
end
AURAS["Crimson"] = function(char, hrp)
    mkHL(char, C3(180,0,0), C3(255,80,80), 0.85, 0.2)
    local att = mkAtt(hrp, V3(0,-2,0))
    mkFX(att, {color=CS{CSK.new(0,C3(80,0,0)),CSK.new(0.4,C3(200,20,0)),CSK.new(1,C3(255,100,0))},
        size=NS{NSK.new(0,0.5),NSK.new(0.4,0.35),NSK.new(1,0)},
        trans=NS{NSK.new(0,0.2),NSK.new(0.6,0.4),NSK.new(1,1)},
        spd=NR(5,12),rate=65,life=NR(1,2),spread=V2(20,20),rotspd=NR(-40,40)})
    mkFX(att, {color=CS{CSK.new(0,C3(255,50,0)),CSK.new(1,C3(180,0,0))},
        size=NS{NSK.new(0,0.08),NSK.new(1,0)},trans=NS{NSK.new(0,0),NSK.new(1,1)},
        spd=NR(8,18),rate=25,life=NR(0.2,0.5),spread=V2(70,70),le=1})
end
AURAS["Sakura"] = function(char, hrp)
    mkHL(char, C3(255,160,200), C3(255,210,230), 0.85, 0.2)
    local att = mkAtt(hrp, V3(0,1,0))
    mkFX(att, {color=CS{CSK.new(0,C3(255,180,210)),CSK.new(0.5,C3(255,140,180)),CSK.new(1,C3(255,200,230))},
        size=NS{NSK.new(0,0.2),NSK.new(0.5,0.3),NSK.new(1,0)},
        trans=NS{NSK.new(0,0.2),NSK.new(0.8,0.4),NSK.new(1,1)},
        spd=NR(1,4),rate=35,life=NR(2.5,4),spread=V2(70,70),
        dir=Enum.NormalId.Bottom,rotspd=NR(-90,90),le=0.4})
    mkFX(mkAtt(hrp,V3(0,-1,0)), {color=CS(C3(255,220,235)),
        size=NS{NSK.new(0,0.4),NSK.new(1,0)},trans=NS{NSK.new(0,0.5),NSK.new(1,1)},
        spd=NR(0.5,2),rate=20,life=NR(2,3),spread=V2(80,10),le=0.3})
end
AURAS["Neon Rainbow"] = function(char, hrp)
    mkHL(char, C3(255,255,255), C3(255,255,255), 0.9, 0.0)
    local att = mkAtt(hrp, V3(0,-1,0))
    mkFX(att, {color=CS{CSK.new(0,C3(255,0,100)),CSK.new(0.25,C3(255,200,0)),
        CSK.new(0.5,C3(0,255,100)),CSK.new(0.75,C3(0,100,255)),CSK.new(1,C3(200,0,255))},
        size=NS{NSK.new(0,0.2),NSK.new(0.5,0.3),NSK.new(1,0)},
        trans=NS{NSK.new(0,0),NSK.new(0.8,0.3),NSK.new(1,1)},
        spd=NR(4,10),rate=70,life=NR(1,2),spread=V2(60,60),le=1})
    mkFX(att, {color=CS(C3(255,255,255)),size=NS{NSK.new(0,0.08),NSK.new(1,0)},
        trans=NS{NSK.new(0,0),NSK.new(1,1)},spd=NR(10,20),rate=40,life=NR(0.1,0.3),
        spread=V2(180,180),le=1})
end

local function applyAura(char, name)
    if not char or not char.Parent then return end
    clearAura(char)
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    if AURAS[name] then pcall(AURAS[name], char, hrp) end
end

-- ======== WINGS ========
local function clearWings(char)
    if not char then return end
    for _, d in ipairs(char:GetDescendants()) do if d:GetAttribute("_AuraWing") then d:Destroy() end end
end
local WING_CONFIGS = {
    Angel     = {c1=C3(255,255,255), c2=C3(255,230,120), angles={68,45,15,-18,-45}, lens={2.4,3.1,3.8,3.1,2.4}, w={0.28,0.36,0.44,0.36,0.28}},
    Demon     = {c1=C3(220,30,30),   c2=C3(80,0,0),      angles={62,22,-15,-52},    lens={2.4,3.6,3.6,1.8},     w={0.28,0.44,0.44,0.22}},
    Butterfly = {c1=C3(0,210,255),   c2=C3(190,0,255),   angles={82,55,-38,-68},    lens={2.0,3.6,3.6,2.0},     w={0.4,0.5,0.5,0.4}},
}
local function applyWings(char, style)
    if not char or not char.Parent then return end
    clearWings(char)
    if style == "None" then return end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
    local cfg = WING_CONFIGS[style]; if not cfg then return end
    for _, sx in ipairs({-1,1}) do
        local base = Instance.new("Attachment", root); base:SetAttribute("_AuraWing", true)
        base.Position = V3(sx*0.5, 0.3, -0.1)
        for i, deg in ipairs(cfg.angles) do
            local ar = math.rad(deg); local len = cfg.lens[i]
            local tip = Instance.new("Attachment", root); tip:SetAttribute("_AuraWing", true)
            tip.Position = V3(sx*0.5+sx*math.cos(ar)*len, 0.3+math.sin(ar)*len, -0.1-math.abs(math.sin(ar))*0.25)
            local b = Instance.new("Beam", root); b:SetAttribute("_AuraWing", true)
            b.Attachment0 = base; b.Attachment1 = tip
            b.Color = CS{CSK.new(0,cfg.c1), CSK.new(1,cfg.c2)}
            b.Width0 = cfg.w[i]; b.Width1 = 0
            b.FaceCamera = true; b.LightEmission = 1; b.LightInfluence = 0
            b.Segments = 20; b.TextureLength = 2
            b.Transparency = NS{NSK.new(0,0), NSK.new(0.85,0.3), NSK.new(1,1)}
        end
    end
end

-- ======== HALO ========
local function makeHalo(char)
    if not char then return nil end
    local head = char:FindFirstChild("Head"); if not head then return nil end
    local part = Instance.new("Part"); part.Name = "_HaloPart"; part.Size = V3(2.4,0.18,2.4)
    part.Shape = Enum.PartType.Cylinder; part.Material = Enum.Material.Neon; part.Color = C3(255,215,0)
    part.CanCollide = false; part.CastShadow = false; part.Anchored = true; part.Transparency = 0.1; part.Parent = char
    return part
end
local function clearHalo()
    if haloObj then haloObj:Destroy(); haloObj = nil end
    local char = LP.Character; if not char then return end
    for _, d in ipairs(char:GetDescendants()) do if d.Name == "_HaloPart" then d:Destroy() end end
end

-- ======== LIGHT PRESET ========
local function applyLightPreset(p)
    Lighting.Brightness = p.brightness; Lighting.Ambient = C3(unpack(p.ambient))
    Lighting.OutdoorAmbient = C3(unpack(p.outdoor)); Lighting.FogEnd = p.fog
    Lighting.FogColor = C3(unpack(p.fogcol)); Lighting.ClockTime = p.clock
end

-- ======== CHARACTER ADDED ========
local function setupChar(char)
    task.wait(1)
    if headlessEnabled  then applyHeadless(true)             end
    if korbloxEnabled   then applyKorblox(true)              end
    if trailEnabled     then applyTrails(true)               end
    if auraType ~= "None" then applyAura(char, auraType)     end
    if wingsStyle ~= "None" then applyWings(char, wingsStyle) end
    if haloEnabled      then haloObj = makeHalo(char)        end
    if instantRespawn   then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Died:Connect(function() task.wait(0.1); LP:LoadCharacter() end) end
    end
end
LP.CharacterAdded:Connect(setupChar)
if LP.Character then task.spawn(setupChar, LP.Character) end

-- ======== HUD ========
local HUD = Instance.new("ScreenGui"); HUD.Name = "TimeBomb_HUD"; HUD.ResetOnSpawn = false; HUD.DisplayOrder = 49
pcall(function() HUD.Parent = CoreGui end)
if not HUD.Parent then HUD.Parent = LP.PlayerGui end
local hudF = Instance.new("Frame")
hudF.Size = UDim2.new(0,122,0,104); hudF.Position = UDim2.new(0,4,0.5,-52)
hudF.BackgroundColor3 = Color3.new(0,0,0); hudF.BackgroundTransparency = 0.25; hudF.BorderSizePixel = 0; hudF.Parent = HUD
Instance.new("UICorner", hudF).CornerRadius = UDim.new(0,4)
-- top accent line
local accentBar = Instance.new("Frame", hudF)
accentBar.Size = UDim2.new(1,0,0,2); accentBar.Position = UDim2.new(0,0,0,0)
accentBar.BackgroundColor3 = C3(165,95,255); accentBar.BorderSizePixel = 0
Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0,2)

local DIM = C3(70,70,80); local PUR = C3(165,95,255)
local hudLabels = {}
local hudNames = {"Speed","Bomb Spd","Spin Bot","Inf Jump","Noclip","Follow"}
for i, n in ipairs(hudNames) do
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,-8,0,14); lbl.Position = UDim2.new(0,7,0,6+(i-1)*16)
    lbl.BackgroundTransparency = 1; lbl.Text = n .. ": OFF"; lbl.TextColor3 = DIM
    lbl.Font = Enum.Font.Code; lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = hudF
    hudLabels[n] = lbl
end
local function updateHUD()
    local s = {["Speed"]=regularSpeedEnabled,["Bomb Spd"]=bombSpeedEnabled,["Spin Bot"]=spinEnabled,
               ["Inf Jump"]=infiniteJumpEnabled,["Noclip"]=noclipEnabled,["Follow"]=followEnabled}
    for n, lbl in pairs(hudLabels) do
        lbl.Text = n .. ": " .. (s[n] and "ON" or "OFF")
        lbl.TextColor3 = s[n] and PUR or DIM
    end
    if followEnabled and followTarget then
        hudLabels["Follow"].Text = "-> " .. followTarget.Name
        hudLabels["Follow"].TextColor3 = PUR
    end
end

-- ======== ESP OBJECTS ========
local espObjects = {}

local function newDraw(dtype, props)
    local d = Drawing.new(dtype)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function createESP(player)
    if player == LP then return end
    local co = esp.BoxColor
    local function L(t) return newDraw("Line", t) end
    espObjects[player] = {
        -- corner lines (C++ style, 8 lines)
        TLH = L({Visible=false,Color=co,Thickness=esp.BoxThick,ZIndex=5}),
        TLV = L({Visible=false,Color=co,Thickness=esp.BoxThick,ZIndex=5}),
        TRH = L({Visible=false,Color=co,Thickness=esp.BoxThick,ZIndex=5}),
        TRV = L({Visible=false,Color=co,Thickness=esp.BoxThick,ZIndex=5}),
        BLH = L({Visible=false,Color=co,Thickness=esp.BoxThick,ZIndex=5}),
        BLV = L({Visible=false,Color=co,Thickness=esp.BoxThick,ZIndex=5}),
        BRH = L({Visible=false,Color=co,Thickness=esp.BoxThick,ZIndex=5}),
        BRV = L({Visible=false,Color=co,Thickness=esp.BoxThick,ZIndex=5}),
        -- fill
        BoxFill   = newDraw("Square", {Visible=false,Filled=true,Color=esp.FilledColor,Thickness=1,Transparency=1-esp.FilledAlpha,ZIndex=3}),
        -- name tag: black panel + text
        NameBG    = newDraw("Square", {Visible=false,Filled=true,Color=Color3.new(0,0,0),Transparency=0.3,Thickness=0,ZIndex=5}),
        Name      = newDraw("Text",   {Visible=false,Color=esp.NameColor,Size=esp.TextSize,Center=true,Outline=false,Font=Drawing.Fonts.Plex,ZIndex=6}),
        Dist      = newDraw("Text",   {Visible=false,Color=C3(185,170,150),Size=esp.TextSize-3,Center=true,Outline=false,Font=Drawing.Fonts.Plex,ZIndex=6}),
        -- health bar
        HpOutline = newDraw("Square", {Visible=false,Filled=true,Color=Color3.new(0,0,0),Transparency=0,Thickness=0,ZIndex=4}),
        HpBG      = newDraw("Square", {Visible=false,Filled=true,Color=C3(25,10,10),Transparency=0,Thickness=0,ZIndex=5}),
        HpBar     = newDraw("Square", {Visible=false,Filled=true,Color=C3(0,200,60),Transparency=0,Thickness=0,ZIndex=6}),
        Tracer    = newDraw("Line",   {Visible=false,Color=esp.TracerColor,Thickness=1,ZIndex=4}),
        HL        = nil,
    }
end

local function removeESP(player)
    local obj = espObjects[player]; if not obj then return end
    for _, v in pairs(obj) do
        if type(v) == "userdata" and v.Remove then v:Remove() end
    end
    if obj.HL and obj.HL.Parent then obj.HL:Destroy() end
    espObjects[player] = nil
end

local function updateESPChams(player, on)
    local obj = espObjects[player]; if not obj then return end
    if on then
        local char = player.Character
        if char and not obj.HL then
            obj.HL = Instance.new("Highlight")
            obj.HL.Name = "_TBCesP"
            obj.HL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            obj.HL.FillColor = esp.ChamFill; obj.HL.OutlineColor = esp.ChamOutline
            obj.HL.FillTransparency = 0.45; obj.HL.OutlineTransparency = 0
            obj.HL.Parent = char
        end
    else
        if obj.HL then obj.HL:Destroy(); obj.HL = nil end
    end
end

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(function(p) task.wait(1); createESP(p) end)
Players.PlayerRemoving:Connect(removeESP)

-- re-attach chams after respawn
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(char)
        task.wait(1)
        local obj = espObjects[p]
        if obj and esp.Chams then
            if obj.HL then obj.HL:Destroy(); obj.HL = nil end
            updateESPChams(p, true)
        end
    end)
end)

-- ======== LIBRARY LOAD ========
-- universal http getter — pcall-based so nil globals don't crash the chain
-- covers: Synapse X, KRNL, Fluxus, Solara, Wave, Hydrogen, Comet, Delta
local function httpGet(url)
    local attempts = {
        function() return syn.request({ Url = url, Method = "GET" }).Body end,
        function() return http.request({ Url = url, Method = "GET" }).Body end,
        function() return http_request({ Url = url, Method = "GET" }).Body end,
        function() return request({ Url = url, Method = "GET" }).Body end,
        function() return (fluxus or fluxus_request)({ Url = url, Method = "GET" }).Body end,
        function() return game:HttpGet(url) end,
        function() return HttpGet(url) end,
    }
    for _, fn in ipairs(attempts) do
        local ok, result = pcall(fn)
        if ok and type(result) == "string" and #result > 10 then
            return result
        end
    end
    error("[TB] No working HTTP method — executor may not support web requests")
end

local function safeLoad(url)
    local body = httpGet(url)
    assert(type(body) == "string" and #body > 0, "Empty response from: " .. url)
    local fn, err = loadstring(body)
    assert(fn, "loadstring failed for: " .. url .. " — " .. tostring(err))
    return fn()
end

if not ProtectGui then ProtectGui = function() end end
if not gethui    then gethui    = function() return game:GetService("CoreGui") end end

local repo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
local Library      = safeLoad(repo .. "Library.lua")
local ThemeManager = safeLoad(repo .. "addons/ThemeManager.lua")
local SaveManager  = safeLoad(repo .. "addons/SaveManager.lua")

local Window = Library:CreateWindow({
    Title       = "Timebomb Duels",
    Center      = true,
    AutoShow    = true,
    TabPadding  = 8,
    MenuFadeTime = 0.2,
})
Library.AccentColor = C3(165, 95, 255)

local Tabs = {
    Speed    = Window:AddTab("Speed"),
    Combat   = Window:AddTab("Combat"),
    Char     = Window:AddTab("Character"),
    Visuals  = Window:AddTab("Visuals"),
    ESP      = Window:AddTab("ESP"),
    FX       = Window:AddTab("FX"),
    HvH      = Window:AddTab("HvH"),
    Settings = Window:AddTab("Settings"),
}

-- ======== SPEED TAB ========
local SpdLeft  = Tabs.Speed:AddLeftTabbox()
local SpdRight = Tabs.Speed:AddRightTabbox()

local SpdReg = SpdLeft:AddTab("Regular")
SpdReg:AddToggle("SpeedEnabled", {
    Text = "Speed Boost", Default = false,
    Callback = function(v) regularSpeedEnabled = v; updateHUD() end
})
SpdReg:AddSlider("SpeedValue", {
    Text = "Speed", Default = 20, Min = 1, Max = 100, Rounding = 1,
    Callback = function(v) regularSpeed = v end
})
SpdReg:AddToggle("LadderCheck", {
    Text = "Ladder Check", Default = true,
    Callback = function(v) ladderCheckEnabled = v end
})
SpdReg:AddToggle("FrozenCheck", {
    Text = "Frozen Check", Default = true,
    Callback = function(v) frozenCheckEnabled = v end
})

local SpdBomb = SpdLeft:AddTab("Bomb")
SpdBomb:AddToggle("BombSpeedEnabled", {
    Text = "Bomb Speed", Default = false,
    Callback = function(v) bombSpeedEnabled = v; updateHUD() end
})
SpdBomb:AddSlider("BombSpeedValue", {
    Text = "Bomb Speed", Default = 25, Min = 1, Max = 100, Rounding = 1,
    Callback = function(v) bombSpeed = v end
})

-- ======== COMBAT TAB ========
local CombatLeft  = Tabs.Combat:AddLeftTabbox()
local CombatRight = Tabs.Combat:AddRightTabbox()

local CombatBot = CombatLeft:AddTab("Movement")
CombatBot:AddToggle("SpinEnabled", {
    Text = "Spin Bot", Default = false,
    Callback = function(v) spinEnabled = v; updateHUD() end
})
CombatBot:AddToggle("InfJump", {
    Text = "Infinite Jump", Default = false,
    Callback = function(v) infiniteJumpEnabled = v; updateHUD() end
})
CombatBot:AddToggle("NoclipEnabled", {
    Text = "Noclip", Default = false,
    Callback = function(v) noclipEnabled = v; updateHUD() end
})
CombatBot:AddToggle("InstantRespawn", {
    Text = "Instant Respawn", Default = false,
    Callback = function(v)
        instantRespawn = v
        if v then
            local char = LP.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.Died:Connect(function() task.wait(0.1); LP:LoadCharacter() end) end
            end
        end
    end
})

local CombatRage = CombatLeft:AddTab("Rage")
CombatRage:AddToggle("RBEnabled", {
    Text = "Rage Bot", Default = false,
    Tooltip = "Auto-fires at Silent Aim target. Requires Silent Aim to be on.",
    Callback = function(v) rb.Enabled = v end
})
CombatRage:AddSlider("RBDelay", {
    Text = "Fire Rate", Default = 10, Min = 1, Max = 20, Rounding = 1,
    Suffix = "×/s",
    Callback = function(v) rb.Delay = 1 / v end
})
CombatRage:AddToggle("RBDoubleTap", {
    Text = "Double Tap", Default = false,
    Tooltip = "Fires twice per activation — bypasses some server-side cooldowns",
    Callback = function(v) rb.DoubleTap = v end
})
CombatRage:AddToggle("RBCycleEnabled", {
    Text = "Cycle Resolver", Default = false,
    Tooltip = "Rotates aim offset each shot (0°→45°→-45°→90°…) until a hit registers, then locks that angle",
    Callback = function(v)
        rbCycle.Enabled = v
        if not v then rbCycleOffset = 0; rbCycle.locked = nil end
    end
})

local CombatSA = CombatRight:AddTab("Silent Aim")
CombatSA:AddToggle("SAEnabled", {
    Text = "Silent Aim", Default = false,
    Tooltip = "Hooks Mouse.Hit — bullets fly to nearest target in FOV automatically",
    Callback = function(v)
        sa.Enabled = v
        FovCircle.Visible = v
    end
})
CombatSA:AddSlider("SAFov", {
    Text = "FOV Radius", Default = 150, Min = 10, Max = 500, Rounding = 5,
    Suffix = "px",
    Callback = function(v) sa.FovRadius = v end
})
CombatSA:AddSlider("SAPrediction", {
    Text = "Prediction", Default = 12, Min = 0, Max = 50, Rounding = 1,
    Suffix = "%",
    Callback = function(v) sa.Prediction = v / 100 end
})
CombatSA:AddToggle("SAWallCheck", {
    Text = "Wall Check", Default = true,
    Tooltip = "Skip targets behind walls",
    Callback = function(v) sa.WallCheck = v end
})
CombatSA:AddToggle("SATeamCheck", {
    Text = "Team Check", Default = false,
    Tooltip = "Skip teammates",
    Callback = function(v) sa.TeamCheck = v end
})
CombatSA:AddDropdown("SAHitPart", {
    Text = "Target Part", Default = "HumanoidRootPart",
    Values = {"HumanoidRootPart", "Head", "UpperTorso", "Torso"},
    Multi = false,
    Callback = function(v) sa.HitPart = v end
})
CombatSA:AddLabel("FOV Circle Color"):AddColorPicker("SAFovColor", {
    Default = Color3.fromRGB(165, 95, 255),
    Callback = function(v) FovCircle.Color = v end
})

local CombatFollow = CombatRight:AddTab("Follow")
local playerOpts = {}
for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then playerOpts[#playerOpts+1] = p.Name end end
if #playerOpts == 0 then playerOpts = {"(no players)"} end

CombatFollow:AddDropdown("FollowTarget", {
    Text = "Target", Default = playerOpts[1], Values = playerOpts, Multi = false,
    Callback = function(v) followTarget = Players:FindFirstChild(v) end
})
CombatFollow:AddToggle("FollowEnabled", {
    Text = "Follow When Bomb", Default = false,
    Callback = function(v) followEnabled = v; updateHUD() end
})
CombatFollow:AddSlider("FollowDist", {
    Text = "Follow Distance", Default = 3, Min = 0, Max = 15, Rounding = 1,
    Suffix = " studs",
    Callback = function(v) followDist = v end
})
CombatFollow:AddButton({
    Text = "Set Nearest Target",
    Func = function()
        local char = LP.Character; if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local best, bd = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local ph = p.Character:FindFirstChild("HumanoidRootPart")
                if ph then local d = (ph.Position - hrp.Position).Magnitude; if d < bd then bd = d; best = p end end
            end
        end
        if best then followTarget = best; Library:Notify("Follow: " .. best.Name, 2) end
    end
})

-- ======== CHARACTER TAB ========
local CharLeft  = Tabs.Char:AddLeftTabbox()
local CharRight = Tabs.Char:AddRightTabbox()

local CharApp = CharLeft:AddTab("Look")
CharApp:AddToggle("HeadlessEnabled", {
    Text = "Client Headless", Default = false,
    Callback = function(v) headlessEnabled = v; applyHeadless(v) end
})
CharApp:AddToggle("KorbloxEnabled", {
    Text = "Client Korblox", Default = false,
    Callback = function(v) korbloxEnabled = v; applyKorblox(v) end
})
CharApp:AddToggle("HaloEnabled", {
    Text = "Halo", Default = false,
    Callback = function(v)
        haloEnabled = v
        if v then haloObj = makeHalo(LP.Character) else clearHalo() end
    end
})
CharApp:AddToggle("TrailEnabled", {
    Text = "Foot Trails", Default = false,
    Callback = function(v) trailEnabled = v; applyTrails(v) end
})
CharApp:AddDropdown("TrailColor", {
    Text = "Trail Color", Default = "Purple",
    Values = {"Purple","Cyan","Fire","Ice","Gold","White"}, Multi = false,
    Callback = function(v) trailColorKey = v; if trailEnabled then applyTrails(true) end end
})

local CharAura = CharRight:AddTab("Aura")
CharAura:AddDropdown("AuraStyle", {
    Text = "Aura Style", Default = "None",
    Values = {"None","Purple Storm","Blue Flames","Galaxy","Ice Crystals","Shadow","Golden Divine","Lightning","Crimson","Sakura","Neon Rainbow"},
    Multi = false,
    Callback = function(v) auraType = v; applyAura(LP.Character, auraType) end
})
CharAura:AddDropdown("WingsStyle", {
    Text = "Wings Style", Default = "None",
    Values = {"None","Angel","Demon","Butterfly"}, Multi = false,
    Callback = function(v) wingsStyle = v; applyWings(LP.Character, wingsStyle) end
})

-- ======== VISUALS TAB ========
local VisLeft  = Tabs.Visuals:AddLeftTabbox()
local VisRight = Tabs.Visuals:AddRightTabbox()

local VisCam = VisLeft:AddTab("Camera")
VisCam:AddToggle("FOVEnabled", {
    Text = "Custom FOV", Default = false,
    Callback = function(v) fovEnabled = v; if not v then workspace.CurrentCamera.FieldOfView = 70 end end
})
VisCam:AddSlider("FOVValue", {
    Text = "Field of View", Default = 70, Min = 30, Max = 120, Rounding = 1,
    Suffix = "°",
    Callback = function(v) customFOV = v; if fovEnabled then workspace.CurrentCamera.FieldOfView = v end end
})
VisCam:AddDropdown("AspectRatio", {
    Text = "Aspect Ratio", Default = "16:9",
    Values = {"16:9","21:9","4:3","2.35:1","1:1"}, Multi = false,
    Callback = function(v) setAspectRatio(v) end
})
VisCam:AddDropdown("ShaderPreset", {
    Text = "Shader", Default = "None",
    Values = {"None","Cinematic","Vibrant","Dark Film","Neon Glow","Warm Sunset","Cold Blue","Depth"}, Multi = false,
    Callback = function(v) shaderActive = v; applyShader(v) end
})

local sceneList = {}; for n in pairs(SCENE_PRESETS) do sceneList[#sceneList+1] = n end; table.sort(sceneList)
local weatherList = {}; for n in pairs(WEATHER_PRESETS) do weatherList[#weatherList+1] = n end; table.sort(weatherList)

local VisWorld = VisRight:AddTab("World")
VisWorld:AddDropdown("ScenePreset", {
    Text = "Scene Preset", Default = sceneList[1], Values = sceneList, Multi = false,
    Callback = function(v) if SCENE_PRESETS[v] then applyLightPreset(SCENE_PRESETS[v]) end end
})
VisWorld:AddDropdown("WeatherPreset", {
    Text = "Weather Preset", Default = weatherList[1], Values = weatherList, Multi = false,
    Callback = function(v) if WEATHER_PRESETS[v] then applyLightPreset(WEATHER_PRESETS[v]) end end
})
VisWorld:AddButton({
    Text = "Reset Lighting",
    Func = function()
        Lighting.Brightness = origLight.Brightness; Lighting.Ambient = origLight.Ambient
        Lighting.OutdoorAmbient = origLight.OutdoorAmbient; Lighting.FogEnd = origLight.FogEnd
        Lighting.FogColor = origLight.FogColor; Lighting.ClockTime = origLight.ClockTime
        clearShaders()
        Library:Notify("Lighting reset", 2)
    end
})

-- ======== ESP TAB ========
-- C++ style player ESP via Drawing API
local ESPLeft  = Tabs.ESP:AddLeftTabbox()
local ESPRight = Tabs.ESP:AddRightTabbox()

local ESPMain = ESPLeft:AddTab("Players")
ESPMain:AddToggle("ESPEnabled", {
    Text = "Enable ESP", Default = false,
    Tooltip = "Master toggle — all ESP drawing",
    Callback = function(v) esp.Enabled = v end
})
ESPMain:AddToggle("ESPBoxes", {
    Text = "Boxes", Default = true,
    Callback = function(v) esp.Boxes = v end
})
ESPMain:AddToggle("ESPFilledBoxes", {
    Text = "Filled Boxes", Default = false,
    Callback = function(v) esp.FilledBoxes = v end
})
ESPMain:AddToggle("ESPNames", {
    Text = "Names", Default = true,
    Callback = function(v) esp.Names = v end
})
ESPMain:AddToggle("ESPHealth", {
    Text = "Health Bar", Default = true,
    Callback = function(v) esp.Health = v end
})
ESPMain:AddToggle("ESPTracers", {
    Text = "Tracers", Default = false,
    Callback = function(v) esp.Tracers = v end
})
ESPMain:AddToggle("ESPDistance", {
    Text = "Distance", Default = true,
    Callback = function(v) esp.Distance = v end
})
ESPMain:AddToggle("ESPChams", {
    Text = "Chams", Default = false,
    Callback = function(v)
        esp.Chams = v
        for player in pairs(espObjects) do updateESPChams(player, v) end
    end
})

local ESPCfg = ESPLeft:AddTab("Config")
ESPCfg:AddSlider("ESPMaxDist", {
    Text = "Max Distance", Default = 1000, Min = 100, Max = 2000, Rounding = 50,
    Suffix = " studs",
    Callback = function(v) esp.MaxDist = v end
})
ESPCfg:AddSlider("ESPTextSize", {
    Text = "Text Size", Default = 13, Min = 8, Max = 24, Rounding = 1,
    Callback = function(v) esp.TextSize = v end
})
ESPCfg:AddSlider("ESPBoxThick", {
    Text = "Box Thickness", Default = 1, Min = 1, Max = 5, Rounding = 1,
    Callback = function(v) esp.BoxThick = v end
})
ESPCfg:AddSlider("ESPFilledAlpha", {
    Text = "Fill Opacity", Default = 15, Min = 1, Max = 100, Rounding = 1,
    Suffix = "%",
    Callback = function(v) esp.FilledAlpha = v / 100 end
})

local ESPCol = ESPRight:AddTab("Colors")
ESPCol:AddLabel("Box Color"):AddColorPicker("ESPBoxColor", {
    Default = C3(255,255,255),
    Callback = function(v) esp.BoxColor = v end
})
ESPCol:AddLabel("Fill Color"):AddColorPicker("ESPFilledColor", {
    Default = C3(255,255,255),
    Callback = function(v) esp.FilledColor = v end
})
ESPCol:AddLabel("Name Color"):AddColorPicker("ESPNameColor", {
    Default = C3(255,255,255),
    Callback = function(v) esp.NameColor = v end
})
ESPCol:AddLabel("Tracer Color"):AddColorPicker("ESPTracerColor", {
    Default = C3(255,0,100),
    Callback = function(v) esp.TracerColor = v end
})
ESPCol:AddLabel("Cham Fill"):AddColorPicker("ESPChamFill", {
    Default = C3(255,0,0),
    Callback = function(v)
        esp.ChamFill = v
        for _, obj in pairs(espObjects) do if obj.HL then obj.HL.FillColor = v end end
    end
})
ESPCol:AddLabel("Cham Outline"):AddColorPicker("ESPChamOutline", {
    Default = C3(255,255,255),
    Callback = function(v)
        esp.ChamOutline = v
        for _, obj in pairs(espObjects) do if obj.HL then obj.HL.OutlineColor = v end end
    end
})

-- ======== FX TAB ========
local FXLeft  = Tabs.FX:AddLeftTabbox()
local FXRight = Tabs.FX:AddRightTabbox()

local FXWeather = FXLeft:AddTab("Weather")
FXWeather:AddToggle("RainEnabled", {
    Text = "Rain", Default = false,
    Callback = function(v)
        rainEnabled = v
        local rate = Toggles.RainEnabled and Options.RainRate and Options.RainRate.Value or 1500
        setRain(v, rate)
    end
})
FXWeather:AddSlider("RainRate", {
    Text = "Rain Intensity", Default = 1500, Min = 200, Max = 3000, Rounding = 100,
    Callback = function(v) if rainEnabled then updateRainRate(v) end end
})
FXWeather:AddToggle("ThunderEnabled", {
    Text = "Thunder", Default = false,
    Callback = function(v) thunderEnabled = v; setThunder(v) end
})

local FXPerf = FXRight:AddTab("Performance")
FXPerf:AddToggle("NoParticles", {
    Text = "Disable Particles", Default = false,
    Callback = function(v)
        for _, d in ipairs(workspace:GetDescendants()) do
            if (d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam"))
               and d.Name ~= "_RainFX" and d.Name ~= "_FootTrail"
               and not d:GetAttribute("_AuraFX") then d.Enabled = not v end
        end
    end
})
FXPerf:AddToggle("NoLights", {
    Text = "Disable Lights", Default = false,
    Callback = function(v)
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then d.Enabled = not v end
        end
    end
})
FXPerf:AddToggle("NoPostFX", {
    Text = "Disable Post FX", Default = false,
    Callback = function(v)
        for _, d in ipairs(Lighting:GetChildren()) do
            if d:IsA("PostEffect") and not d:GetAttribute("_TB") then d.Enabled = not v end
        end
    end
})
FXPerf:AddToggle("NoTextures", {
    Text = "Disable Textures", Default = false,
    Callback = function(v)
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("Texture") or d:IsA("Decal") then d.Transparency = v and 1 or 0 end
        end
    end
})
FXPerf:AddToggle("ShowHUD", {
    Text = "Show Status HUD", Default = true,
    Callback = function(v) hudF.Visible = v end
})

-- ======== SETTINGS TAB ========
local SettLeft  = Tabs.Settings:AddLeftTabbox()
local SettRight = Tabs.Settings:AddRightTabbox()

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("TimebombDuels")
ThemeManager:ApplyToTab(SettLeft:AddTab("Theme"))
SaveManager:AddToTab(SettRight:AddTab("Config"))
SaveManager:SetIgnoreIndexes({})

-- Keys box in settings
local KeyBox = SettLeft:AddTab("Keys")
KeyBox:AddKeybind("SpeedKeybind", {
    Text = "Speed Boost", Default = "None", Mode = "Toggle",
    Callback = function()
        regularSpeedEnabled = not regularSpeedEnabled
        Toggles.SpeedEnabled:SetValue(regularSpeedEnabled)
        updateHUD()
    end
})
KeyBox:AddKeybind("BombSpeedKeybind", {
    Text = "Bomb Speed", Default = "None", Mode = "Toggle",
    Callback = function()
        bombSpeedEnabled = not bombSpeedEnabled
        Toggles.BombSpeedEnabled:SetValue(bombSpeedEnabled)
        updateHUD()
    end
})
KeyBox:AddKeybind("SpinKeybind", {
    Text = "Spin Bot", Default = "None", Mode = "Toggle",
    Callback = function()
        spinEnabled = not spinEnabled
        Toggles.SpinEnabled:SetValue(spinEnabled)
        updateHUD()
    end
})
KeyBox:AddKeybind("InfJumpKeybind", {
    Text = "Infinite Jump", Default = "None", Mode = "Toggle",
    Callback = function()
        infiniteJumpEnabled = not infiniteJumpEnabled
        Toggles.InfJump:SetValue(infiniteJumpEnabled)
        updateHUD()
    end
})
KeyBox:AddKeybind("NoclipKeybind", {
    Text = "Noclip", Default = "None", Mode = "Toggle",
    Callback = function()
        noclipEnabled = not noclipEnabled
        Toggles.NoclipEnabled:SetValue(noclipEnabled)
        updateHUD()
    end
})
KeyBox:AddKeybind("FollowKeybind", {
    Text = "Follow Target", Default = "None", Mode = "Toggle",
    Callback = function()
        followEnabled = not followEnabled
        Toggles.FollowEnabled:SetValue(followEnabled)
        updateHUD()
    end
})
KeyBox:AddKeybind("ESPKeybind", {
    Text = "Toggle ESP", Default = "None", Mode = "Toggle",
    Callback = function()
        esp.Enabled = not esp.Enabled
        Toggles.ESPEnabled:SetValue(esp.Enabled)
    end
})

-- ======== HvH TAB ========
local HvHLeft  = Tabs.HvH:AddLeftTabbox()
local HvHRight = Tabs.HvH:AddRightTabbox()

local HvHAA = HvHLeft:AddTab("Anti-Aim")
HvHAA:AddToggle("AAEnabled", {
    Text = "Anti-Aim", Default = false,
    Tooltip = "Manipulates your body angles to confuse enemy resolvers",
    Callback = function(v) hvh.AAEnabled = v end
})
HvHAA:AddDropdown("AAMode", {
    Text = "Mode", Default = "Spin",
    Values = {"Spin", "Jitter", "FakeDown", "Desync"},
    Multi = false,
    Callback = function(v) hvh.AAMode = v end
})
HvHAA:AddSlider("AASpeed", {
    Text = "Spin Speed", Default = 20, Min = 5, Max = 60, Rounding = 1,
    Suffix = "°/f",
    Callback = function(v) hvh.AASpeed = v end
})

local HvHFL = HvHLeft:AddTab("Fake Lag")
HvHFL:AddToggle("FLEnabled", {
    Text = "Fake Lag", Default = false,
    Tooltip = "Desync your position by periodically anchoring the character",
    Callback = function(v)
        hvh.FLEnabled = v
        hvh.flCount = 0
        if not v then
            local c2 = LP.Character
            local h2 = c2 and c2:FindFirstChild("HumanoidRootPart")
            if h2 then h2.Anchored = false end
        end
    end
})
HvHFL:AddSlider("FLTicks", {
    Text = "Lag Ticks", Default = 6, Min = 1, Max = 15, Rounding = 1,
    Suffix = " ticks",
    Callback = function(v) hvh.FLTicks = v end
})

local HvHRes = HvHRight:AddTab("Resolver")
HvHRes:AddToggle("ResEnabled", {
    Text = "Resolver", Default = false,
    Tooltip = "Shoots at a corrected position to counter enemy fake-lag or anti-aim",
    Callback = function(v) hvh.ResEnabled = v end
})
HvHRes:AddDropdown("ResMode", {
    Text = "Mode", Default = "Backtrack",
    Values = {"Backtrack", "Velocity"},
    Multi = false,
    Tooltip = "Backtrack: aim at a past position | Velocity: aim behind movement direction",
    Callback = function(v) hvh.ResMode = v end
})
HvHRes:AddSlider("BTTicks", {
    Text = "Backtrack Ticks", Default = 3, Min = 1, Max = 15, Rounding = 1,
    Suffix = " ticks",
    Callback = function(v) hvh.BTTicks = v end
})

local HvHVoid = HvHRight:AddTab("Void")
HvHVoid:AddToggle("VoidSpam", {
    Text = "Void Spam", Default = false,
    Tooltip = "Rapidly flickers between void and your position — extremely hard to register",
    Callback = function(v)
        hvh.VoidSpam = v; hvh.voidTimer = 0
        if not v and hvh.voidActive then
            local c2 = LP.Character
            local h2 = c2 and c2:FindFirstChild("HumanoidRootPart")
            if h2 then h2.Anchored = false; if hvh.voidOrigin then h2.CFrame = hvh.voidOrigin end end
            hvh.voidActive = false
        end
    end
})
HvHVoid:AddToggle("VoidHold", {
    Text = "Void Hold", Default = false,
    Tooltip = "Stay in void while toggled — toggle off to return to your position",
    Callback = function(v)
        hvh.VoidHold = v
        if not v and hvh.voidActive then
            local c2 = LP.Character
            local h2 = c2 and c2:FindFirstChild("HumanoidRootPart")
            if h2 then h2.Anchored = false; if hvh.voidOrigin then h2.CFrame = hvh.voidOrigin end end
            hvh.voidActive = false
        end
    end
})
HvHVoid:AddSlider("VoidSpeed", {
    Text = "Void Speed", Default = 10, Min = 3, Max = 30, Rounding = 1,
    Suffix = "×/s",
    Callback = function(v) hvh.VoidDelay = 1 / v end
})

-- ======== INFINITE JUMP + MB1 TRACKING ========
UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.Space then jumpHeld = true end
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then mb1Down = true end
end)
UIS.InputEnded:Connect(function(inp)
    if inp.KeyCode == Enum.KeyCode.Space then jumpHeld = false end
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then mb1Down = false end
end)
UIS.JumpRequest:Connect(function()
    if not infiniteJumpEnabled then return end
    local c = LP.Character; if not c then return end
    local hum = c:FindFirstChild("Humanoid"); if not hum then return end
    if hum.JumpPower == 0  then hum.JumpPower = 50  end
    if hum.JumpHeight == 0 then hum.JumpHeight = 7.2 end
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
end)

-- ======== HEARTBEAT ========
RunService.Heartbeat:Connect(function()
    if infiniteJumpEnabled and jumpHeld then
        local c = LP.Character; if c then
            local hum = c:FindFirstChild("Humanoid")
            if hum and hum:GetState() == Enum.HumanoidStateType.Freefall then
                if hum.JumpPower == 0  then hum.JumpPower = 50  end
                if hum.JumpHeight == 0 then hum.JumpHeight = 7.2 end
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
    if noclipEnabled then
        local c = LP.Character; if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.CanCollide = false end
            end
        end
    end
end)

-- ======== RENDER STEPPED ========
RunService.RenderStepped:Connect(function(dt)
    -- FOV
    if fovEnabled or arFOVMult ~= 1.0 then
        local base = fovEnabled and customFOV or 70
        if arFOVMult == 1.0 then
            workspace.CurrentCamera.FieldOfView = base
        else
            workspace.CurrentCamera.FieldOfView = math.deg(2 * math.atan(math.tan(math.rad(base / 2)) * arFOVMult))
        end
    end

    -- Halo spin
    if haloEnabled and haloObj and haloObj.Parent then
        local char = LP.Character
        if char then
            local head = char:FindFirstChild("Head")
            if head then
                haloAngle = (haloAngle + 80 * dt) % 360
                haloObj.CFrame = head.CFrame * CFrame.new(0,1.6,0) * CFrame.Angles(0.15, math.rad(haloAngle), math.rad(90))
            end
        end
    end

    -- Movement
    local char = LP.Character; if not char then goto esp_render end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then goto esp_render end

    if followEnabled and followTarget and hasBomb() then
        if not Players:FindFirstChild(followTarget.Name) then
            followTarget = nil; followEnabled = false
            Toggles.FollowEnabled:SetValue(false); updateHUD()
        else
            local tc = followTarget.Character
            if tc then
                local tHRP = tc:FindFirstChild("HumanoidRootPart")
                if tHRP and (tHRP.Position - hrp.Position).Magnitude <= 300 then
                    hrp.CFrame = tHRP.CFrame * CFrame.new(0, 0, followDist)
                    goto esp_render
                end
            end
        end
    end

    if frozenCheckEnabled then
        if hrp.Anchored then goto esp_render end
        if hum.PlatformStand then goto esp_render end
        for _, v in ipairs(hrp:GetChildren()) do
            if v:IsA("BodyPosition") or v:IsA("BodyVelocity") then goto esp_render end
        end
    end
    if ladderCheckEnabled and isOnLadder(hum) then goto esp_render end

    local dir = hum.MoveDirection; local speed = 0
    if hasBomb() then if bombSpeedEnabled then speed = bombSpeed end
    elseif regularSpeedEnabled then speed = regularSpeed end

    local newCF = hrp.CFrame
    if speed > 0 and dir.Magnitude > 0 then newCF = newCF + dir * speed * dt end
    if spinEnabled then spinAngle = (spinAngle + 20 * dt) % (2 * math.pi); newCF = CFrame.new(newCF.Position) * CFrame.Angles(0, spinAngle, 0) end
    if newCF ~= hrp.CFrame then hrp.CFrame = newCF end

    -- ======== ESP RENDER ========
    ::esp_render::

    -- ======== POSITION HISTORY (resolver / backtrack) ========
    for _, pl2 in ipairs(Players:GetPlayers()) do
        if pl2 == LP then continue end
        local pc2 = pl2.Character
        if not pc2 then plrHistory[pl2] = nil; continue end
        local hrp3 = pc2:FindFirstChild("HumanoidRootPart")
        if not hrp3 then plrHistory[pl2] = nil; continue end
        if not plrHistory[pl2] then plrHistory[pl2] = {positions={}} end
        local ph = plrHistory[pl2]
        table.insert(ph.positions, 1, {pos=hrp3.Position, t=tick()})
        if #ph.positions > 20 then table.remove(ph.positions) end
    end

    -- ======== HvH: ANTI-AIM ========
    if hvh.AAEnabled and hrp then
        if hvh.AAMode == "Spin" then
            hvh.aaAngle = (hvh.aaAngle + hvh.AASpeed) % 360
            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(hvh.aaAngle), 0)
        elseif hvh.AAMode == "Jitter" then
            hvh.aaFlip = not hvh.aaFlip
            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, hvh.aaFlip and math.rad(90) or math.rad(-90), 0)
        elseif hvh.AAMode == "FakeDown" then
            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(math.rad(-85), 0, 0)
        elseif hvh.AAMode == "Desync" then
            hvh.aaFlip = not hvh.aaFlip
            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, hvh.aaFlip and math.rad(180) or 0, 0)
        end
    end

    -- ======== HvH: FAKE LAG ========
    if hrp then
        if hvh.FLEnabled then
            hvh.flCount = hvh.flCount + 1
            local cycle = hvh.FLTicks * 2
            hrp.Anchored = (hvh.flCount % cycle) < hvh.FLTicks
        elseif hrp.Anchored and not noclipEnabled and not hvh.voidActive then
            hrp.Anchored = false
        end
    end

    -- ======== HvH: VOID SPAM / VOID HOLD ========
    if hrp then
        local wantVoid = hvh.VoidSpam or hvh.VoidHold
        if wantVoid then
            if hvh.VoidSpam then
                hvh.voidTimer = hvh.voidTimer + dt
                if hvh.voidTimer >= hvh.VoidDelay then
                    hvh.voidTimer = 0
                    hvh.voidActive = not hvh.voidActive
                    if hvh.voidActive then
                        hvh.voidOrigin = hrp.CFrame
                        hrp.Anchored = true
                        hrp.CFrame = CFrame.new(0, -5000, 0)
                    else
                        hrp.Anchored = false
                        if hvh.voidOrigin then hrp.CFrame = hvh.voidOrigin end
                    end
                end
            else
                if not hvh.voidActive then
                    hvh.voidActive = true
                    hvh.voidOrigin = hrp.CFrame
                    hrp.Anchored = true
                    hrp.CFrame = CFrame.new(0, -5000, 0)
                end
            end
        elseif hvh.voidActive then
            hvh.voidActive = false
            hrp.Anchored = false
            if hvh.voidOrigin then hrp.CFrame = hvh.voidOrigin end
            hvh.voidOrigin = nil
        end
    end

    -- target selection for hookmetamethod silent aim + ragebot
    do
        local vp2 = Camera.ViewportSize
        local sc2 = Vector2.new(vp2.X / 2, vp2.Y / 2)
        FovCircle.Position = sc2
        FovCircle.Radius   = sa.FovRadius
        FovCircle.Visible  = sa.Enabled
        if sa.Enabled then
            local char2 = LP.Character
            local saP   = RaycastParams.new()
            saP.FilterType = Enum.RaycastFilterType.Exclude
            if char2 then saP.FilterDescendantsInstances = { char2 } end
            local best, bestPl, bestD = nil, nil, math.huge
            for _, pl in ipairs(Players:GetPlayers()) do
                if pl == LP then continue end
                if sa.TeamCheck and pl.Team == LP.Team then continue end
                local pc = pl.Character; if not pc then continue end
                local tgt = pc:FindFirstChild(sa.HitPart) or pc:FindFirstChild("HumanoidRootPart")
                if not tgt then continue end
                local h2 = pc:FindFirstChildOfClass("Humanoid")
                if not h2 or h2.Health <= 0 then continue end
                local sp, dp = Camera:WorldToViewportPoint(tgt.Position)
                if dp <= 0 then continue end
                local sd = (sc2 - Vector2.new(sp.X, sp.Y)).Magnitude
                if sd > sa.FovRadius then continue end
                if sa.WallCheck then
                    local res = workspace:Raycast(Camera.CFrame.Position, tgt.Position - Camera.CFrame.Position, saP)
                    if not res or not res.Instance:IsDescendantOf(pc) then continue end
                end
                if sd < bestD then bestD = sd; best = tgt; bestPl = pl end
            end
            saTarget = best; saTargetPlayer = bestPl
            -- ragebot: auto-fire at locked target with cycle resolver
            if rb.Enabled and saTarget then
                local now = tick()
                if now - rbLastFire >= rb.Delay then
                    -- cycle resolver: detect hit and rotate offset
                    if rbCycle.Enabled then
                        local hum3 = saTargetPlayer and saTargetPlayer.Character and saTargetPlayer.Character:FindFirstChildOfClass("Humanoid")
                        local curHP = hum3 and hum3.Health
                        if rbCycle.lockedPl ~= saTargetPlayer then
                            -- new target — reset cycle
                            rbCycle.lockedPl = saTargetPlayer
                            rbCycle.locked   = nil
                            rbCycle.idx      = 1
                            rbCycle.prevHP   = curHP
                        else
                            if rbCycle.prevHP and curHP and curHP < rbCycle.prevHP then
                                rbCycle.locked = rbCycle.offsets[rbCycle.idx]  -- hit, lock it
                            elseif not rbCycle.locked then
                                rbCycle.idx = (rbCycle.idx % #rbCycle.offsets) + 1  -- miss, next angle
                            end
                            rbCycle.prevHP = curHP
                        end
                        rbCycleOffset = rbCycle.locked or rbCycle.offsets[rbCycle.idx]
                    else
                        rbCycleOffset = 0
                    end
                    -- Use Da Hood's native shoot handler via simulated mouse click
                    -- mouse1click() triggers MouseButton1Down which reads our hooked Mouse.Hit
                    local function doFire()
                        local ok = pcall(mouse1click)
                        if not ok then
                            -- some executors split press/release
                            pcall(mouse1press)
                            task.defer(function() pcall(mouse1release) end)
                        end
                    end
                    doFire()
                    if rb.DoubleTap then task.defer(doFire) end
                    rbLastFire = now
                end
            end
        else
            saTarget = nil; saTargetPlayer = nil
        end
    end

    for player, obj in pairs(espObjects) do
        local pchar = player.Character
        local phum  = pchar and pchar:FindFirstChildOfClass("Humanoid")
        local alive = phum and phum.Health > 0

        local function hideAll()
            for _, k in ipairs({"TLH","TLV","TRH","TRV","BLH","BLV","BRH","BRV","BoxFill","NameBG","Name","Dist","HpOutline","HpBG","HpBar","Tracer"}) do
                if obj[k] then obj[k].Visible = false end
            end
        end

        if not esp.Enabled or not alive then hideAll(); continue end

        local phrp = pchar:FindFirstChild("HumanoidRootPart")
        if not phrp then hideAll(); continue end

        local myHRP = char and char:FindFirstChild("HumanoidRootPart")
        local dist  = myHRP and (phrp.Position - myHRP.Position).Magnitude or 0
        if dist > esp.MaxDist then hideAll(); continue end

        local hipH   = phum.HipHeight * 2 + 0.5
        local topSP, _, topOn = Camera:WorldToViewportPoint(phrp.Position + V3(0, hipH * 0.5, 0))
        local botSP, botZ     = Camera:WorldToViewportPoint(phrp.Position - V3(0, hipH * 0.5, 0))
        local topV2  = V2(topSP.X, topSP.Y)
        local botV2  = V2(botSP.X, botSP.Y)

        if not topOn or botZ <= 0 then hideAll(); continue end

        local boxH = math.abs(topV2.Y - botV2.Y)
        local boxW = boxH * 0.55
        local bx   = topV2.X - boxW * 0.5
        local by   = topV2.Y
        local hpct = phum.Health / math.max(phum.MaxHealth, 1)
        local cLen = math.min(boxW, boxH) * 0.22

        -- Corner box (C++ style)
        if esp.Boxes then
            local co = esp.BoxColor; local ct = esp.BoxThick
            local function setLine(ln, x1, y1, x2, y2)
                ln.Visible=true; ln.From=V2(x1,y1); ln.To=V2(x2,y2); ln.Color=co; ln.Thickness=ct
            end
            setLine(obj.TLH, bx,      by,      bx+cLen,      by)
            setLine(obj.TLV, bx,      by,      bx,           by+cLen)
            setLine(obj.TRH, bx+boxW, by,      bx+boxW-cLen, by)
            setLine(obj.TRV, bx+boxW, by,      bx+boxW,      by+cLen)
            setLine(obj.BLH, bx,      by+boxH, bx+cLen,      by+boxH)
            setLine(obj.BLV, bx,      by+boxH, bx,           by+boxH-cLen)
            setLine(obj.BRH, bx+boxW, by+boxH, bx+boxW-cLen, by+boxH)
            setLine(obj.BRV, bx+boxW, by+boxH, bx+boxW,      by+boxH-cLen)
        else
            for _, k in ipairs({"TLH","TLV","TRH","TRV","BLH","BLV","BRH","BRV"}) do obj[k].Visible=false end
        end

        -- Filled box
        if esp.FilledBoxes then
            obj.BoxFill.Visible=true; obj.BoxFill.Position=V2(bx,by)
            obj.BoxFill.Size=V2(boxW,boxH); obj.BoxFill.Color=esp.FilledColor
            obj.BoxFill.Transparency=1-esp.FilledAlpha
        else obj.BoxFill.Visible=false end

        -- Name tag with black panel
        if esp.Names then
            local nameY = by - esp.TextSize - 4
            obj.NameBG.Visible=true; obj.NameBG.Position=V2(bx, nameY-2)
            obj.NameBG.Size=V2(boxW, esp.TextSize+4); obj.NameBG.Color=Color3.new(0,0,0); obj.NameBG.Transparency=0.3
            obj.Name.Visible=true; obj.Name.Position=V2(topV2.X, nameY)
            obj.Name.Text=player.DisplayName; obj.Name.Color=esp.NameColor
            obj.Name.Size=esp.TextSize; obj.Name.Font=Drawing.Fonts.Plex
        else obj.NameBG.Visible=false; obj.Name.Visible=false end

        -- Distance
        if esp.Distance then
            obj.Dist.Visible=true; obj.Dist.Position=V2(topV2.X, by+boxH+3)
            obj.Dist.Text=string.format("%.0f m", dist); obj.Dist.Color=C3(185,170,150)
            obj.Dist.Size=esp.TextSize-3; obj.Dist.Font=Drawing.Fonts.Plex
        else obj.Dist.Visible=false end

        -- Health bar with outline
        if esp.Health then
            local barW=3; local barX=bx-barW-3; local filledH=boxH*hpct
            obj.HpOutline.Visible=true; obj.HpOutline.Position=V2(barX-1,by-1); obj.HpOutline.Size=V2(barW+2,boxH+2); obj.HpOutline.Color=Color3.new(0,0,0)
            obj.HpBG.Visible=true; obj.HpBG.Position=V2(barX,by); obj.HpBG.Size=V2(barW,boxH); obj.HpBG.Color=C3(25,10,10)
            obj.HpBar.Visible=true; obj.HpBar.Position=V2(barX,by+boxH-filledH); obj.HpBar.Size=V2(barW,filledH)
            obj.HpBar.Color=C3(math.floor((1-hpct)*220), math.floor(hpct*200+55), 40)
        else obj.HpOutline.Visible=false; obj.HpBG.Visible=false; obj.HpBar.Visible=false end

        -- Tracer
        if esp.Tracers then
            local vp2 = Camera.ViewportSize
            obj.Tracer.Visible=true; obj.Tracer.From=V2(vp2.X*0.5, vp2.Y)
            obj.Tracer.To=botV2; obj.Tracer.Color=esp.TracerColor; obj.Tracer.Thickness=1
        else obj.Tracer.Visible=false end
    end
end)

-- ======== SILENT AIM (hookmetamethod Mouse.Hit/Target intercept) ========
-- Intercepts Mouse.Hit/Target so bullets fly to saTarget regardless of aim
local __indexHook
pcall(function()
    __indexHook = hookmetamethod(game, "__index", function(t, k)
        if t:IsA("Mouse") and sa.Enabled and saTarget then
            if k == "Hit" then
                local pos
                if hvh.ResEnabled and saTargetPlayer then
                    local h = plrHistory[saTargetPlayer]
                    if h and #h.positions > 0 then
                        if hvh.ResMode == "Backtrack" then
                            local bt = math.min(hvh.BTTicks, #h.positions)
                            pos = h.positions[bt].pos
                        elseif hvh.ResMode == "Velocity" and #h.positions >= 3 then
                            local vel = (h.positions[1].pos - h.positions[3].pos) * 30
                            pos = saTarget.Position + vel * 0.05
                        end
                    end
                end
                if not pos then
                    pos = saTarget.Position + (saTarget.Velocity * sa.Prediction)
                end
                -- apply cycle resolver angular offset
                if rb.Enabled and rbCycle.Enabled and rbCycleOffset ~= 0 then
                    local r = 0.5
                    pos = pos + Vector3.new(math.cos(math.rad(rbCycleOffset)) * r, 0, math.sin(math.rad(rbCycleOffset)) * r)
                end
                return CFrame.new(pos)
            elseif k == "Target" then
                return saTarget
            end
        end
        return __indexHook(t, k)
    end)
end)
