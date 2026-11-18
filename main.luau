-- Runtime: Roblox executor (Synapse X / KRNL / Fluxus etc.)
-- Lib: NextUI (diser.me/nextui)

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
local infiniteJumpEnabled = false
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
local arMode = "Off"


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

-- ======== VFX PACK ========
local _packLoaded = false
local _packTexIds = {}
local _packCallbacks = {}

task.spawn(function()
    local ok, m = pcall(function()
        return game:GetService("InsertService"):LoadAsset(18221073047)
    end)
    if not (ok and m) then return end
    for _, v in ipairs(m:GetDescendants()) do
        local id
        if     v:IsA("ParticleEmitter") then id = v.Texture
        elseif v:IsA("Decal")           then id = v.Texture
        elseif v:IsA("Texture")         then id = v.Texture
        end
        if id and id ~= "" and id ~= "rbxassetid://0" then
            local dup = false
            for _, x in ipairs(_packTexIds) do if x == id then dup = true; break end end
            if not dup then _packTexIds[#_packTexIds+1] = id end
        end
    end
    _packLoaded = #_packTexIds > 0
    m:Destroy()
    if _packLoaded then
        for _, cb in ipairs(_packCallbacks) do pcall(cb) end
        pcall(function() NextUI:Success("VFX Pack", "Loaded " .. #_packTexIds .. " textures", 3) end)
    end
end)

-- cycles through pack textures by offset index
local function packTex(i)
    if not _packLoaded or #_packTexIds == 0 then return nil end
    return _packTexIds[((i or 1) - 1) % #_packTexIds + 1]
end

-- ======== HELPERS ========
local function hasBomb()
    local c = LP.Character
    if not c then return false end
    for _, v in ipairs(c:GetChildren()) do
        if v:IsA("Tool") then
            local low = v.Name:lower()
            if low:find("bomb") or low:find("timer") or low:find("time") then return true end
        end
    end
    return false
end
local function isOnLadder(hum) return hum:GetState() == Enum.HumanoidStateType.Climbing end

-- ======== ASPECT RATIO ========
local AR_RATIOS = { ["4:3"]=4/3, ["16:9"]=16/9, ["16:10"]=16/10, ["21:9"]=21/9, ["1:1"]=1 }
local _arOrigVP = workspace.CurrentCamera.ViewportSize
local _setres = rawget(_G, "setresolution")
    or (rawget(_G,"syn") and type(rawget(_G,"syn"))=="table" and rawget(rawget(_G,"syn"),"setresolution"))
    or rawget(_G, "set_resolution") or rawget(_G, "setwindowsize") or rawget(_G, "set_window_size")
local function setAspectRatio(r)
    arMode = r
    local origW = math.floor(_arOrigVP.X)
    local origH = math.floor(_arOrigVP.Y)
    if r == "Off" then
        if _setres then pcall(_setres, origW, origH) end
        return
    end
    local ratio = AR_RATIOS[r]; if not ratio then return end
    if not _setres then return end
    local newW = math.floor(origH * ratio)
    pcall(_setres, newW, origH)
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
    local rTex = packTex(4); if rTex then em.Texture = rTex end
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
            local h = acc:FindFirstChild("Handle")
            if h then
                for _, w in ipairs(h:GetChildren()) do
                    if w:IsA("Weld") or w:IsA("WeldConstraint") then
                        local other = w.Part0 == h and w.Part1 or w.Part0
                        if other and other.Name == "Head" then h.Transparency = on and 1 or 0 end
                    end
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
        local tex = packTex(1)
        if tex then t.Texture = tex; t.TextureLength = 1; t.TextureMode = Enum.TextureMode.Stretch end
    end
end

-- ======== AURA SYSTEM ========
local _mkFXCount = 0
local function mkFX(parent, t)
    _mkFXCount = _mkFXCount + 1
    local em = Instance.new("ParticleEmitter", parent); em:SetAttribute("_AuraFX", true)
    -- Use pack texture by offset, or explicit override, or default sparkle
    em.Texture = t.tex or packTex(_mkFXCount) or "rbxassetid://6880950593"
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

-- Register pack callback: adds "VFX 1", "VFX 2", ... aura entries once pack loads
_packCallbacks[#_packCallbacks+1] = function()
    for i, texId in ipairs(_packTexIds) do
        local n = "VFX " .. i; local tid = texId
        AURAS[n] = function(char, hrp)
            mkHL(char, C3(255,255,255), C3(220,220,255), 0.85, 0.2)
            local att = mkAtt(hrp, V3(0,-1,0))
            mkFX(att, {tex=tid, size=NS{NSK.new(0,V2(0,0)),NSK.new(0.2,V2(1.5,1.5)),NSK.new(1,V2(0,0))},
                le=1,li=0,spd=NR(2,6),rate=35,life=NR(1,2.5),spread=V2(60,60)})
            mkFX(att, {tex=tid, size=NS{NSK.new(0,V2(0,0)),NSK.new(0.3,V2(2,2)),NSK.new(1,V2(0,0))},
                le=0.8,li=0,spd=NR(5,12),rate=20,life=NR(0.8,1.5),spread=V2(45,45)})
        end
    end
    pcall(function()
        local vals = {"None"}
        for n in next, AURAS do vals[#vals+1] = n end
        table.sort(vals)
        local opt = NextUI.Options and NextUI.Options.AuraStyle
        if opt then
            if type(opt.SetValues)   == "function" then opt:SetValues(vals)
            elseif type(opt.SetOptions) == "function" then opt:SetOptions(vals) end
        end
    end)
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
            local wTex = packTex(2)
            if wTex then b.Texture = wTex; b.TextureMode = Enum.TextureMode.Wrap end
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


-- ======== LIBRARY LOAD ========
local NextUI = loadstring(game:HttpGet("https://diser.me/nextui/source.lua"))()
NextUI.ConfigFolder = "TimebombDuels"

local Window = NextUI:CreateWindow({
    Title    = "Timebomb",
    SubTitle = "Duels",
    Theme    = "Amethyst",
    Size     = Vector2.new(820, 520),
    Stars    = true,
})

-- ======== SPEED TAB ========
local SpeedTab = Window:AddTab("Speed", "zap")

local RegCard = SpeedTab:AddSection({Title = "Regular Speed", Icon = "zap"})
RegCard:AddToggle({Title = "Speed Boost", Flag = "SpeedEnabled", Default = false,
    Callback = function(v) regularSpeedEnabled = v; updateHUD() end})
RegCard:AddSlider({Title = "Speed", Flag = "SpeedValue", Default = 20, Min = 1, Max = 100,
    Callback = function(v) regularSpeed = v end})
RegCard:AddToggle({Title = "Ladder Check", Flag = "LadderCheck", Default = true,
    Callback = function(v) ladderCheckEnabled = v end})
RegCard:AddToggle({Title = "Frozen Check", Flag = "FrozenCheck", Default = true,
    Callback = function(v) frozenCheckEnabled = v end})

local BombSub = SpeedTab:AddSubTab("Bomb", "bomb")
local BombCard = BombSub:AddSection({Title = "Bomb Speed", Icon = "bomb"})
BombCard:AddToggle({Title = "Bomb Speed", Flag = "BombSpeedEnabled", Default = false,
    Callback = function(v) bombSpeedEnabled = v; updateHUD() end})
BombCard:AddSlider({Title = "Bomb Speed", Flag = "BombSpeedValue", Default = 25, Min = 1, Max = 100,
    Callback = function(v) bombSpeed = v end})

-- ======== COMBAT TAB ========
local CombatTab = Window:AddTab("Combat", "swords")

local MovCard = CombatTab:AddSection({Title = "Movement", Icon = "move"})
MovCard:AddToggle({Title = "Spin Bot", Flag = "SpinEnabled", Default = false,
    Callback = function(v) spinEnabled = v; updateHUD() end})
MovCard:AddToggle({Title = "Infinite Jump", Flag = "InfJump", Default = false,
    Callback = function(v) infiniteJumpEnabled = v; updateHUD() end})
MovCard:AddToggle({Title = "Noclip", Flag = "NoclipEnabled", Default = false,
    Callback = function(v) noclipEnabled = v; updateHUD() end})
MovCard:AddToggle({Title = "Instant Respawn", Flag = "InstantRespawn", Default = false,
    Callback = function(v)
        instantRespawn = v
        if v then
            local char = LP.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.Died:Connect(function() task.wait(0.1); LP:LoadCharacter() end) end
            end
        end
    end})

local FollowSub = CombatTab:AddSubTab("Follow", "user")
local playerOpts = {}
for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then playerOpts[#playerOpts+1] = p.Name end end
if #playerOpts == 0 then playerOpts = {"(no players)"} end

local FollowCard = FollowSub:AddSection({Title = "Follow", Icon = "user"})
FollowCard:AddDropdown({Title = "Target", Flag = "FollowTarget", Default = playerOpts[1], Values = playerOpts,
    Callback = function(v) followTarget = Players:FindFirstChild(v) end})
FollowCard:AddToggle({Title = "Follow When Bomb", Flag = "FollowEnabled", Default = false,
    Callback = function(v) followEnabled = v; updateHUD() end})
FollowCard:AddSlider({Title = "Follow Distance", Flag = "FollowDist", Default = 3, Min = 0, Max = 15,
    Suffix = " studs", Callback = function(v) followDist = v end})
FollowCard:AddButton({Title = "Set Nearest Target",
    Callback = function()
        local char = LP.Character; if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        local best, bd = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local ph = p.Character:FindFirstChild("HumanoidRootPart")
                if ph then local d = (ph.Position - hrp.Position).Magnitude; if d < bd then bd = d; best = p end end
            end
        end
        if best then followTarget = best; NextUI:Info("Follow", best.Name, 2) end
    end})

-- ======== CHARACTER TAB ========
local CharTab = Window:AddTab("Character", "user")

local LookCard = CharTab:AddSection({Title = "Appearance", Icon = "user"})
LookCard:AddToggle({Title = "Client Headless", Flag = "HeadlessEnabled", Default = false,
    Callback = function(v) headlessEnabled = v; applyHeadless(v) end})
LookCard:AddToggle({Title = "Client Korblox", Flag = "KorbloxEnabled", Default = false,
    Callback = function(v) korbloxEnabled = v; applyKorblox(v) end})
LookCard:AddToggle({Title = "Halo", Flag = "HaloEnabled", Default = false,
    Callback = function(v) haloEnabled = v; if v then haloObj = makeHalo(LP.Character) else clearHalo() end end})
LookCard:AddToggle({Title = "Foot Trails", Flag = "TrailEnabled", Default = false,
    Callback = function(v) trailEnabled = v; applyTrails(v) end})
LookCard:AddDropdown({Title = "Trail Color", Flag = "TrailColor", Default = "Purple",
    Values = {"Purple","Cyan","Fire","Ice","Gold","White"},
    Callback = function(v) trailColorKey = v; if trailEnabled then applyTrails(true) end end})

local AuraSub = CharTab:AddSubTab("Aura", "sparkles")
local AuraCard = AuraSub:AddSection({Title = "Aura", Icon = "sparkles"})
AuraCard:AddDropdown({Title = "Aura Style", Flag = "AuraStyle", Default = "None",
    Values = {"None","Purple Storm","Blue Flames","Galaxy","Ice Crystals","Shadow","Golden Divine","Lightning","Crimson","Sakura","Neon Rainbow"},
    Callback = function(v) auraType = v; applyAura(LP.Character, auraType) end})
AuraCard:AddDropdown({Title = "Wings Style", Flag = "WingsStyle", Default = "None",
    Values = {"None","Angel","Demon","Butterfly"},
    Callback = function(v) wingsStyle = v; applyWings(LP.Character, wingsStyle) end})

-- ======== VISUALS TAB ========
local VisTab = Window:AddTab("Visuals", "eye")

local CamCard = VisTab:AddSection({Title = "Camera", Icon = "camera"})
CamCard:AddToggle({Title = "Custom FOV", Flag = "FOVEnabled", Default = false,
    Callback = function(v) fovEnabled = v; if not v then workspace.CurrentCamera.FieldOfView = 70 end end})
CamCard:AddSlider({Title = "Field of View", Flag = "FOVValue", Default = 70, Min = 30, Max = 120, Suffix = "°",
    Callback = function(v) customFOV = v; if fovEnabled then workspace.CurrentCamera.FieldOfView = v end end})
CamCard:AddDropdown({Title = "Aspect Ratio", Flag = "AspectRatio", Default = "Off",
    Values = {"Off","4:3","16:9","16:10","21:9","1:1"},
    Callback = function(v) setAspectRatio(v) end})
CamCard:AddDropdown({Title = "Shader", Flag = "ShaderPreset", Default = "None",
    Values = {"None","Cinematic","Vibrant","Dark Film","Neon Glow","Warm Sunset","Cold Blue","Depth"},
    Callback = function(v) shaderActive = v; applyShader(v) end})

local sceneList = {}; for n in pairs(SCENE_PRESETS) do sceneList[#sceneList+1] = n end; table.sort(sceneList)
local weatherList = {}; for n in pairs(WEATHER_PRESETS) do weatherList[#weatherList+1] = n end; table.sort(weatherList)

local WorldSub = VisTab:AddSubTab("World", "sun")
local WorldCard = WorldSub:AddSection({Title = "World", Icon = "sun"})
WorldCard:AddDropdown({Title = "Scene Preset", Flag = "ScenePreset", Default = sceneList[1], Values = sceneList,
    Callback = function(v) if SCENE_PRESETS[v] then applyLightPreset(SCENE_PRESETS[v]) end end})
WorldCard:AddDropdown({Title = "Weather Preset", Flag = "WeatherPreset", Default = weatherList[1], Values = weatherList,
    Callback = function(v) if WEATHER_PRESETS[v] then applyLightPreset(WEATHER_PRESETS[v]) end end})
WorldCard:AddButton({Title = "Reset Lighting",
    Callback = function()
        Lighting.Brightness = origLight.Brightness; Lighting.Ambient = origLight.Ambient
        Lighting.OutdoorAmbient = origLight.OutdoorAmbient; Lighting.FogEnd = origLight.FogEnd
        Lighting.FogColor = origLight.FogColor; Lighting.ClockTime = origLight.ClockTime
        clearShaders(); NextUI:Info("Lighting", "Reset to default", 2)
    end})

-- ======== FX TAB ========
local FXTab = Window:AddTab("FX", "sparkles")

local WeatherCard = FXTab:AddSection({Title = "Weather", Icon = "cloud-rain"})
WeatherCard:AddToggle({Title = "Rain", Flag = "RainEnabled", Default = false,
    Callback = function(v) rainEnabled = v; setRain(v, NextUI.Flags.RainRate or 1500) end})
WeatherCard:AddSlider({Title = "Rain Intensity", Flag = "RainRate", Default = 1500, Min = 200, Max = 3000, Increment = 100,
    Callback = function(v) if rainEnabled then updateRainRate(v) end end})
WeatherCard:AddToggle({Title = "Thunder", Flag = "ThunderEnabled", Default = false,
    Callback = function(v) thunderEnabled = v; setThunder(v) end})

local PerfSub = FXTab:AddSubTab("Performance", "cpu")
local PerfCard = PerfSub:AddSection({Title = "Performance", Icon = "cpu"})
PerfCard:AddToggle({Title = "Disable Particles", Flag = "NoParticles", Default = false,
    Callback = function(v)
        for _, d in ipairs(workspace:GetDescendants()) do
            if (d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam"))
               and d.Name ~= "_RainFX" and d.Name ~= "_FootTrail"
               and not d:GetAttribute("_AuraFX") then d.Enabled = not v end
        end
    end})
PerfCard:AddToggle({Title = "Disable Lights", Flag = "NoLights", Default = false,
    Callback = function(v)
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then d.Enabled = not v end
        end
    end})
PerfCard:AddToggle({Title = "Disable Post FX", Flag = "NoPostFX", Default = false,
    Callback = function(v)
        for _, d in ipairs(Lighting:GetChildren()) do
            if d:IsA("PostEffect") and not d:GetAttribute("_TB") then d.Enabled = not v end
        end
    end})
PerfCard:AddToggle({Title = "Disable Textures", Flag = "NoTextures", Default = false,
    Callback = function(v)
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("Texture") or d:IsA("Decal") then d.Transparency = v and 1 or 0 end
        end
    end})
PerfCard:AddToggle({Title = "Show Status HUD", Flag = "ShowHUD", Default = true,
    Callback = function(v) hudF.Visible = v end})

-- ======== SETTINGS TAB ========
local SettTab = Window:AddTab("Settings", "settings")

local ConfCard = SettTab:AddSection({Title = "Config", Icon = "save"})
ConfCard:AddConfigManager()

local KeysSub = SettTab:AddSubTab("Keys", "keyboard")
local KeysCard = KeysSub:AddSection({Title = "Keybinds", Icon = "keyboard"})
KeysCard:AddKeybind({Title = "Speed Boost",   Flag = "SpeedKeybind",     Mode = "Toggle", Callback = function() end})
KeysCard:AddKeybind({Title = "Bomb Speed",    Flag = "BombSpeedKeybind", Mode = "Toggle", Callback = function() end})
KeysCard:AddKeybind({Title = "Spin Bot",      Flag = "SpinKeybind",      Mode = "Toggle", Callback = function() end})
KeysCard:AddKeybind({Title = "Infinite Jump", Flag = "InfJumpKeybind",   Mode = "Toggle", Callback = function() end})
KeysCard:AddKeybind({Title = "Noclip",        Flag = "NoclipKeybind",    Mode = "Toggle", Callback = function() end})
KeysCard:AddKeybind({Title = "Follow Target", Flag = "FollowKeybind",    Mode = "Toggle", Callback = function() end})

-- ======== KEYBIND HANDLER ========
-- Checks every keybind flag on each keypress so multiple features
-- bound to the same key both fire correctly.
local _KB_ACTIONS = {
    {flag="SpeedKeybind",     fn=function() regularSpeedEnabled=not regularSpeedEnabled; NextUI.Options.SpeedEnabled:Set(regularSpeedEnabled); updateHUD() end},
    {flag="BombSpeedKeybind", fn=function() bombSpeedEnabled=not bombSpeedEnabled; NextUI.Options.BombSpeedEnabled:Set(bombSpeedEnabled); updateHUD() end},
    {flag="SpinKeybind",      fn=function() spinEnabled=not spinEnabled; NextUI.Options.SpinEnabled:Set(spinEnabled); updateHUD() end},
    {flag="InfJumpKeybind",   fn=function() infiniteJumpEnabled=not infiniteJumpEnabled; NextUI.Options.InfJump:Set(infiniteJumpEnabled); updateHUD() end},
    {flag="NoclipKeybind",    fn=function() noclipEnabled=not noclipEnabled; NextUI.Options.NoclipEnabled:Set(noclipEnabled); updateHUD() end},
    {flag="FollowKeybind",    fn=function() followEnabled=not followEnabled; NextUI.Options.FollowEnabled:Set(followEnabled); updateHUD() end},
}
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local kn = input.KeyCode.Name
    for _, kb in ipairs(_KB_ACTIONS) do
        local bound = NextUI.Flags[kb.flag]
        if bound then
            local bs = tostring(bound)
            if bs == kn or bs == "Enum.KeyCode."..kn then kb.fn() end
        end
    end
end)


-- ======== INFINITE JUMP ========
UIS.JumpRequest:Connect(function()
    if not infiniteJumpEnabled then return end
    local c = LP.Character; if not c then return end
    local hum = c:FindFirstChild("Humanoid"); if not hum then return end
    if hum.JumpPower == 0  then hum.JumpPower = 50  end
    if hum.JumpHeight == 0 then hum.JumpHeight = 7.2 end
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
end)

-- ======== HEARTBEAT ========
RunService.Heartbeat:Connect(function(dt)
    local c = LP.Character
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    local hum = c and c:FindFirstChildOfClass("Humanoid")

    if hum and hrp then
        local frozen = frozenCheckEnabled and (hrp.Anchored or hum.PlatformStand)
        if not frozen then
            local spd = 0
            if regularSpeedEnabled then spd = regularSpeed end
            if bombSpeedEnabled and hasBomb() then spd = bombSpeed end
            if spd > 0 then
                local dir = hum.MoveDirection
                if dir.Magnitude > 0 then
                    hrp.CFrame = hrp.CFrame + dir * spd * dt
                end
            end
        end
    end

    if infiniteJumpEnabled and hum and UIS:IsKeyDown(Enum.KeyCode.Space) then
        if hum:GetState() == Enum.HumanoidStateType.Freefall then
            if hum.JumpPower == 0  then hum.JumpPower = 50  end
            if hum.JumpHeight == 0 then hum.JumpHeight = 7.2 end
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end

    if noclipEnabled and c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)


-- ======== RENDER STEPPED ========
RunService.RenderStepped:Connect(function(dt)
    -- FOV
    if fovEnabled then
        workspace.CurrentCamera.FieldOfView = customFOV
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

    -- Spinbot
    if spinEnabled then
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            spinAngle = (spinAngle + 20 * dt) % (2 * math.pi)
            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, spinAngle, 0)
        end
    end

    -- Follow
    if followEnabled and followTarget then
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        if char and hrp and hum and hum.Health > 0 and hasBomb() then
            if not Players:FindFirstChild(followTarget.Name) then
                followTarget = nil; followEnabled = false
                NextUI.Options.FollowEnabled:Set(false); updateHUD()
            else
                local tc = followTarget.Character
                if tc then
                    local tHRP = tc:FindFirstChild("HumanoidRootPart")
                    if tHRP and (tHRP.Position - hrp.Position).Magnitude <= 300 then
                        hrp.CFrame = tHRP.CFrame * CFrame.new(0, 0, followDist)
                    end
                end
            end
        end
    end
end)

