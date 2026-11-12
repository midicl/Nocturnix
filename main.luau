-- Services
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Lighting   = game:GetService("Lighting")
local TweenS     = game:GetService("TweenService")
local CoreGui    = game:GetService("CoreGui")
local LP         = Players.LocalPlayer

-- Shorthand
local NR  = NumberRange.new
local NS  = NumberSequence.new
local NSK = NumberSequenceKeypoint.new
local CS  = ColorSequence.new
local CSK = ColorSequenceKeypoint.new
local V2  = Vector2.new
local V3  = Vector3.new
local C3  = Color3.fromRGB

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

local origLight = {
    Brightness=Lighting.Brightness, Ambient=Lighting.Ambient,
    OutdoorAmbient=Lighting.OutdoorAmbient, FogEnd=Lighting.FogEnd,
    FogColor=Lighting.FogColor, ClockTime=Lighting.ClockTime,
}

-- ======== HELPERS ========
local function hasBomb()
    local c=LP.Character; return c and (c:FindFirstChild("bomb") or c:FindFirstChild("Bomb"))~=nil
end
local function isOnLadder(hum) return hum:GetState()==Enum.HumanoidStateType.Climbing end

-- ======== PRESETS ========
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

-- ======== ASPECT RATIO ========
local arGui=Instance.new("ScreenGui"); arGui.Name="TB_AR"; arGui.ResetOnSpawn=false
arGui.DisplayOrder=60; arGui.IgnoreGuiInset=true
pcall(function() arGui.Parent=CoreGui end)
if not arGui.Parent then arGui.Parent=LP.PlayerGui end
local function mkBar(n) local f=Instance.new("Frame",arGui); f.Name=n; f.BackgroundColor3=Color3.new(0,0,0); f.BorderSizePixel=0; f.Size=UDim2.new(0,0,0,0); return f end
local arT=mkBar("T"); local arB=mkBar("B"); local arL=mkBar("L"); local arR=mkBar("R")
local function setAspectRatio(r)
    for _,b in ipairs({arT,arB,arL,arR}) do b.Size=UDim2.new(0,0,0,0) end
    if r=="21:9" then
        arT.Size=UDim2.new(1,0,0.119,0); arT.Position=UDim2.new(0,0,0,0)
        arB.Size=UDim2.new(1,0,0.119,0); arB.Position=UDim2.new(0,0,0.881,0)
    elseif r=="4:3" then
        arL.Size=UDim2.new(0.125,0,1,0); arL.Position=UDim2.new(0,0,0,0)
        arR.Size=UDim2.new(0.125,0,1,0); arR.Position=UDim2.new(0.875,0,0,0)
    elseif r=="2.35:1" then
        arT.Size=UDim2.new(1,0,0.121,0); arT.Position=UDim2.new(0,0,0,0)
        arB.Size=UDim2.new(1,0,0.121,0); arB.Position=UDim2.new(0,0,0.879,0)
    elseif r=="1:1" then
        arL.Size=UDim2.new(0.219,0,1,0); arL.Position=UDim2.new(0,0,0,0)
        arR.Size=UDim2.new(0.219,0,1,0); arR.Position=UDim2.new(0.781,0,0,0)
    end
end

-- ======== SHADER ========
local function clearShaders()
    for _,c in ipairs(Lighting:GetChildren()) do
        if c:IsA("PostEffect") and c:GetAttribute("_TB") then c:Destroy() end
    end
end
local function applyShader(name)
    clearShaders(); local p=SHADER_PRESETS[name]; if not p then return end
    if p.cc then local cc=Instance.new("ColorCorrectionEffect",Lighting); cc:SetAttribute("_TB",true); cc.Brightness=p.cc[1]; cc.Contrast=p.cc[2]; cc.Saturation=p.cc[3]; cc.TintColor=C3(unpack(p.cc[4])) end
    if p.bloom then local b=Instance.new("BloomEffect",Lighting); b:SetAttribute("_TB",true); b.Intensity=p.bloom[1]; b.Size=p.bloom[2]; b.Threshold=p.bloom[3] end
    if p.sun   then local s=Instance.new("SunRaysEffect",Lighting); s:SetAttribute("_TB",true); s.Intensity=p.sun[1]; s.Spread=p.sun[2] end
    if p.blur  then local bl=Instance.new("BlurEffect",Lighting); bl:SetAttribute("_TB",true); bl.Size=p.blur end
    if p.dof   then local d=Instance.new("DepthOfFieldEffect",Lighting); d:SetAttribute("_TB",true); d.FarIntensity=p.dof[1]; d.FocusDistance=p.dof[2]; d.InFocusRadius=p.dof[3]; d.NearIntensity=p.dof[4] end
end

-- ======== RAIN ========
local function setRain(on, rate)
    if rainConn then rainConn:Disconnect(); rainConn=nil end
    if rainObj  then rainObj:Destroy(); rainObj=nil end
    if not on   then return end
    local part=Instance.new("Part"); part.Name="_RainPart"; part.Size=V3(600,1,600); part.Anchored=true; part.CanCollide=false; part.CastShadow=false; part.Transparency=1; part.Parent=workspace
    rainObj=part
    local em=Instance.new("ParticleEmitter",part); em.Name="_RainFX"
    em.Color=CS{CSK.new(0,C3(180,205,235)), CSK.new(1,C3(150,180,215))}
    em.Transparency=NS{NSK.new(0,0.15), NSK.new(0.85,0.15), NSK.new(1,1)}
    em.Size=NS(0.025); em.Speed=NR(100,130); em.Rate=rate or 1500; em.Lifetime=NR(0.6,1)
    em.Rotation=NR(10,14); em.RotSpeed=NR(0,0); em.SpreadAngle=V2(4,0)
    em.EmissionDirection=Enum.NormalId.Bottom; em.LockedToPart=false
    em.LightEmission=0; em.LightInfluence=1
    rainConn=RunService.Heartbeat:Connect(function()
        if rainObj and rainObj.Parent then
            rainObj.CFrame=CFrame.new(workspace.CurrentCamera.CFrame.Position+V3(0,70,0))
        end
    end)
end
local function updateRainRate(rate)
    if rainObj then local em=rainObj:FindFirstChild("_RainFX"); if em then em.Rate=rate end end
end

-- ======== THUNDER ========
local function setThunder(on)
    if thunderConn then thunderConn:Disconnect(); thunderConn=nil end
    if not on then return end
    thunderConn=RunService.Heartbeat:Connect(function()
        if math.random(1,500)==1 then
            local orig=Lighting.Brightness
            Lighting.Brightness=math.clamp(orig*8,5,15)
            task.delay(0.05,function()
                Lighting.Brightness=orig
                if math.random(1,2)==1 then
                    task.delay(0.04,function() Lighting.Brightness=math.clamp(orig*4,3,10); task.delay(0.04,function() Lighting.Brightness=orig end) end)
                end
            end)
        end
    end)
end

-- ======== HEADLESS ========
local function applyHeadless(on)
    local char=LP.Character; if not char then return end
    local head=char:FindFirstChild("Head"); if not head then return end
    head.Transparency=on and 1 or 0
    for _,d in ipairs(head:GetDescendants()) do if d:IsA("Decal") then d.Transparency=on and 1 or 0 end end
    for _,acc in ipairs(char:GetChildren()) do
        if acc:IsA("Accessory") then
            local h=acc:FindFirstChild("Handle"); if not h then continue end
            for _,w in ipairs(h:GetChildren()) do
                if w:IsA("Weld") or w:IsA("WeldConstraint") then
                    local other=w.Part0==h and w.Part1 or w.Part0
                    if other and other.Name=="Head" then h.Transparency=on and 1 or 0 end
                end
            end
        end
    end
end

-- ======== KORBLOX ========
local function applyKorblox(on)
    local char=LP.Character; if not char then return end
    local old=char:FindFirstChild("_KorbloxPart"); if old then old:Destroy() end
    local isR15=char:FindFirstChild("RightLowerLeg")~=nil
    if isR15 then
        for _,n in ipairs({"RightLowerLeg","RightFoot"}) do local p=char:FindFirstChild(n); if p then p.Transparency=on and 1 or 0 end end
        if not on then return end
        local rup=char:FindFirstChild("RightUpperLeg"); if not rup then return end
        local part=Instance.new("Part"); part.Name="_KorbloxPart"; part.Size=V3(0.5,2.6,0.5); part.Anchored=false; part.CanCollide=false
        local mesh=Instance.new("SpecialMesh",part); mesh.MeshType=Enum.MeshType.FileMesh; mesh.MeshId="rbxassetid://6340101562"; mesh.TextureId="rbxassetid://6340101616"; mesh.Scale=V3(1,1,1)
        part.CFrame=rup.CFrame*CFrame.new(0,-1.3,0); part.Parent=char
        local wc=Instance.new("WeldConstraint",part); wc.Part0=rup; wc.Part1=part
    else
        local rl=char:FindFirstChild("Right Leg"); if rl then rl.Transparency=on and 1 or 0 end
        if not on then return end
        local torso=char:FindFirstChild("Torso"); if not torso then return end
        local part=Instance.new("Part"); part.Name="_KorbloxPart"; part.Size=V3(1,2,1); part.Anchored=false; part.CanCollide=false
        local mesh=Instance.new("SpecialMesh",part); mesh.MeshType=Enum.MeshType.FileMesh; mesh.MeshId="rbxassetid://48474629"; mesh.Scale=V3(1,1,1)
        part.CFrame=torso.CFrame*CFrame.new(0.5,-1.5,0); part.Parent=char
        local wc=Instance.new("WeldConstraint",part); wc.Part0=torso; wc.Part1=part
    end
end

-- ======== TRAILS ========
local function applyTrails(on)
    local char=LP.Character; if not char then return end
    for _,d in ipairs(char:GetDescendants()) do if d.Name=="_TrailAtt" or d.Name=="_FootTrail" then d:Destroy() end end
    if not on then return end
    local cols=TRAIL_COLORS[trailColorKey] or TRAIL_COLORS["Purple"]
    local feet={}
    for _,n in ipairs({"LeftFoot","RightFoot"}) do local p=char:FindFirstChild(n); if p then feet[#feet+1]=p end end
    if #feet==0 then for _,n in ipairs({"Left Leg","Right Leg"}) do local p=char:FindFirstChild(n); if p then feet[#feet+1]=p end end end
    for _,foot in ipairs(feet) do
        local a0=Instance.new("Attachment",foot); a0.Name="_TrailAtt"; a0.Position=V3(0,-0.4,0.3)
        local a1=Instance.new("Attachment",foot); a1.Name="_TrailAtt"; a1.Position=V3(0,-0.4,-0.3)
        local t=Instance.new("Trail",foot); t.Name="_FootTrail"; t.Attachment0=a0; t.Attachment1=a1
        t.Lifetime=0.45; t.MinLength=0; t.FaceCamera=true; t.LightEmission=0.4; t.LightInfluence=0.5
        t.Color=CS{CSK.new(0,cols[1]), CSK.new(1,cols[2])}
        t.Transparency=NS{NSK.new(0,0), NSK.new(0.5,0.25), NSK.new(1,1)}
        t.WidthScale=NS{NSK.new(0,1), NSK.new(1,0)}
    end
end

-- ======== AURA SYSTEM ========
local function mkFX(parent, t)
    local em=Instance.new("ParticleEmitter",parent); em:SetAttribute("_AuraFX",true)
    if t.color then em.Color=t.color end
    if t.size  then em.Size=t.size   end
    if t.trans then em.Transparency=t.trans end
    em.LightEmission=t.le or 0.8; em.LightInfluence=t.li or 0
    em.Speed=t.spd or NR(5,10); em.Rate=t.rate or 50; em.Lifetime=t.life or NR(1,2)
    em.SpreadAngle=t.spread or V2(30,30); em.EmissionDirection=t.dir or Enum.NormalId.Top
    em.RotSpeed=t.rotspd or NR(-30,30); em.Rotation=t.rot or NR(0,360)
    return em
end
local function mkAtt(p,pos) local a=Instance.new("Attachment",p); a.Position=pos or V3(0,0,0); a:SetAttribute("_AuraFX",true); return a end
local function mkHL(char,fc,fo,ft,ot)
    local h=Instance.new("Highlight",char); h.Name="_AuraHL"; h:SetAttribute("_AuraFX",true)
    h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    h.FillColor=fc; h.FillTransparency=ft or 0.85; h.OutlineColor=fo; h.OutlineTransparency=ot or 0.3; return h
end
local function clearAura(char)
    if not char then return end
    for _,d in ipairs(char:GetDescendants()) do if d:GetAttribute("_AuraFX") then d:Destroy() end end
    for _,c in ipairs(char:GetChildren()) do if c:IsA("Highlight") and c.Name=="_AuraHL" then c:Destroy() end end
end

local AURAS = {}

AURAS["Purple Storm"] = function(char,hrp)
    mkHL(char, C3(165,95,255), C3(220,180,255), 0.85, 0.25)
    local att=mkAtt(hrp,V3(0,-2,0))
    mkFX(att,{color=CS{CSK.new(0,C3(165,95,255)),CSK.new(0.5,C3(120,20,220)),CSK.new(1,C3(60,0,140))},
        size=NS{NSK.new(0,0.4),NSK.new(0.5,0.65),NSK.new(1,0)},
        trans=NS{NSK.new(0,0.3),NSK.new(0.7,0.4),NSK.new(1,1)},
        spd=NR(5,12),rate=65,life=NR(1.5,2.8),spread=V2(22,22),rotspd=NR(-60,60)})
    mkFX(att,{color=CS{CSK.new(0,C3(240,210,255)),CSK.new(1,C3(200,150,255))},
        size=NS{NSK.new(0,0.08),NSK.new(1,0)},trans=NS{NSK.new(0,0),NSK.new(1,1)},
        spd=NR(12,25),rate=35,life=NR(0.15,0.5),spread=V2(100,100),le=1})
    mkFX(mkAtt(hrp,V3(0,-2.5,0)),{color=CS{CSK.new(0,C3(80,0,200)),CSK.new(1,C3(140,50,255))},
        size=NS{NSK.new(0,0.3),NSK.new(1,0)},trans=NS{NSK.new(0,0.5),NSK.new(1,1)},
        spd=NR(1,4),rate=40,life=NR(0.8,1.5),spread=V2(80,10),dir=Enum.NormalId.Front})
end

AURAS["Blue Flames"] = function(char,hrp)
    mkHL(char, C3(0,160,255), C3(100,220,255), 0.85, 0.2)
    local att=mkAtt(hrp,V3(0,-2,0))
    mkFX(att,{color=CS{CSK.new(0,C3(0,80,255)),CSK.new(0.4,C3(0,180,255)),CSK.new(1,C3(200,240,255))},
        size=NS{NSK.new(0,0.5),NSK.new(0.4,0.3),NSK.new(1,0)},
        trans=NS{NSK.new(0,0.2),NSK.new(0.6,0.4),NSK.new(1,1)},
        spd=NR(6,14),rate=70,life=NR(1,2),spread=V2(18,18),rotspd=NR(-40,40)})
    mkFX(att,{color=CS(C3(180,230,255)),size=NS{NSK.new(0,0.12),NSK.new(1,0)},
        trans=NS{NSK.new(0,0),NSK.new(1,1)},spd=NR(8,16),rate=20,life=NR(0.2,0.6),spread=V2(30,30),le=1})
end

AURAS["Galaxy"] = function(char,hrp)
    mkHL(char, C3(10,10,60), C3(80,100,255), 0.9, 0.2)
    local att=mkAtt(hrp,V3(0,-1,0))
    mkFX(att,{color=CS{CSK.new(0,C3(255,255,255)),CSK.new(0.5,C3(180,200,255)),CSK.new(1,C3(100,120,255))},
        size=NS{NSK.new(0,0.08),NSK.new(0.5,0.12),NSK.new(1,0)},
        trans=NS{NSK.new(0,0),NSK.new(0.8,0.3),NSK.new(1,1)},
        spd=NR(1,5),rate=45,life=NR(2,4),spread=V2(180,180),rotspd=NR(-15,15),le=0.9})
    mkFX(att,{color=CS{CSK.new(0,C3(80,80,180)),CSK.new(1,C3(40,40,120))},
        size=NS{NSK.new(0,0.8),NSK.new(1,0)},trans=NS{NSK.new(0,0.7),NSK.new(1,1)},
        spd=NR(0.5,2),rate=20,life=NR(2,4),spread=V2(180,180),le=0.3})
end

AURAS["Ice Crystals"] = function(char,hrp)
    mkHL(char, C3(140,220,255), C3(220,245,255), 0.82, 0.2)
    local att=mkAtt(hrp,V3(0,1,0))
    mkFX(att,{color=CS{CSK.new(0,C3(220,245,255)),CSK.new(0.6,C3(140,210,255)),CSK.new(1,C3(80,160,220))},
        size=NS{NSK.new(0,0.08),NSK.new(0.3,0.15),NSK.new(1,0)},
        trans=NS{NSK.new(0,0.1),NSK.new(0.8,0.3),NSK.new(1,1)},
        spd=NR(1,4),rate=40,life=NR(2,3.5),spread=V2(50,50),
        dir=Enum.NormalId.Bottom,rotspd=NR(-90,90),le=0.6})
    mkFX(mkAtt(hrp,V3(0,-2,0)),{color=CS(C3(255,255,255)),
        size=NS{NSK.new(0,0.3),NSK.new(1,0)},trans=NS{NSK.new(0,0.6),NSK.new(1,1)},
        spd=NR(0.5,2),rate=25,life=NR(1.5,2.5),spread=V2(100,10),le=0.4})
end

AURAS["Shadow"] = function(char,hrp)
    mkHL(char, C3(0,0,0), C3(60,0,80), 0.8, 0.0)
    local att=mkAtt(hrp,V3(0,-2.5,0))
    mkFX(att,{color=CS{CSK.new(0,C3(0,0,0)),CSK.new(0.5,C3(30,0,50)),CSK.new(1,C3(0,0,0))},
        size=NS{NSK.new(0,0.6),NSK.new(0.4,1.0),NSK.new(1,0)},
        trans=NS{NSK.new(0,0.3),NSK.new(0.5,0.5),NSK.new(1,1)},
        spd=NR(2,6),rate=55,life=NR(1.5,2.5),spread=V2(60,30),rotspd=NR(-20,20),le=0.0,li=1})
    mkFX(mkAtt(hrp,V3(0,0,0)),{color=CS{CSK.new(0,C3(80,0,120)),CSK.new(1,C3(0,0,0))},
        size=NS{NSK.new(0,0.08),NSK.new(1,0)},trans=NS{NSK.new(0,0),NSK.new(1,1)},
        spd=NR(5,12),rate=20,life=NR(0.3,0.8),spread=V2(90,90),le=0.4})
end

AURAS["Golden Divine"] = function(char,hrp)
    mkHL(char, C3(255,200,0), C3(255,230,100), 0.85, 0.2)
    local att=mkAtt(hrp,V3(0,-2,0))
    mkFX(att,{color=CS{CSK.new(0,C3(255,200,0)),CSK.new(0.6,C3(255,160,0)),CSK.new(1,C3(255,220,100))},
        size=NS{NSK.new(0,0.3),NSK.new(0.4,0.5),NSK.new(1,0)},
        trans=NS{NSK.new(0,0.2),NSK.new(0.7,0.4),NSK.new(1,1)},
        spd=NR(6,14),rate=55,life=NR(1,2),spread=V2(20,20),rotspd=NR(-30,30)})
    mkFX(att,{color=CS(C3(255,255,180)),size=NS{NSK.new(0,0.15),NSK.new(1,0)},
        trans=NS{NSK.new(0,0),NSK.new(1,1)},spd=NR(3,8),rate=30,life=NR(0.5,1.2),spread=V2(60,60),le=1})
end

AURAS["Lightning"] = function(char,hrp)
    mkHL(char, C3(200,230,255), C3(255,255,255), 0.9, 0.0)
    local att=mkAtt(hrp,V3(0,0,0))
    mkFX(att,{color=CS{CSK.new(0,C3(255,255,255)),CSK.new(0.5,C3(180,220,255)),CSK.new(1,C3(100,180,255))},
        size=NS{NSK.new(0,0.06),NSK.new(0.2,0.1),NSK.new(1,0)},
        trans=NS{NSK.new(0,0),NSK.new(0.5,0.3),NSK.new(1,1)},
        spd=NR(15,30),rate=80,life=NR(0.08,0.3),spread=V2(180,180),le=1})
    mkFX(mkAtt(hrp,V3(0,-1,0)),{color=CS{CSK.new(0,C3(100,180,255)),CSK.new(1,C3(0,120,255))},
        size=NS{NSK.new(0,0.3),NSK.new(0.3,0.4),NSK.new(1,0)},
        trans=NS{NSK.new(0,0.4),NSK.new(1,1)},spd=NR(4,10),rate=40,
        life=NR(0.5,1.2),spread=V2(30,30),le=0.8})
end

AURAS["Crimson"] = function(char,hrp)
    mkHL(char, C3(180,0,0), C3(255,80,80), 0.85, 0.2)
    local att=mkAtt(hrp,V3(0,-2,0))
    mkFX(att,{color=CS{CSK.new(0,C3(80,0,0)),CSK.new(0.4,C3(200,20,0)),CSK.new(1,C3(255,100,0))},
        size=NS{NSK.new(0,0.5),NSK.new(0.4,0.35),NSK.new(1,0)},
        trans=NS{NSK.new(0,0.2),NSK.new(0.6,0.4),NSK.new(1,1)},
        spd=NR(5,12),rate=65,life=NR(1,2),spread=V2(20,20),rotspd=NR(-40,40)})
    mkFX(att,{color=CS{CSK.new(0,C3(255,50,0)),CSK.new(1,C3(180,0,0))},
        size=NS{NSK.new(0,0.08),NSK.new(1,0)},trans=NS{NSK.new(0,0),NSK.new(1,1)},
        spd=NR(8,18),rate=25,life=NR(0.2,0.5),spread=V2(70,70),le=1})
end

AURAS["Sakura"] = function(char,hrp)
    mkHL(char, C3(255,160,200), C3(255,210,230), 0.85, 0.2)
    local att=mkAtt(hrp,V3(0,1,0))
    mkFX(att,{color=CS{CSK.new(0,C3(255,180,210)),CSK.new(0.5,C3(255,140,180)),CSK.new(1,C3(255,200,230))},
        size=NS{NSK.new(0,0.2),NSK.new(0.5,0.3),NSK.new(1,0)},
        trans=NS{NSK.new(0,0.2),NSK.new(0.8,0.4),NSK.new(1,1)},
        spd=NR(1,4),rate=35,life=NR(2.5,4),spread=V2(70,70),
        dir=Enum.NormalId.Bottom,rotspd=NR(-90,90),le=0.4})
    mkFX(mkAtt(hrp,V3(0,-1,0)),{color=CS(C3(255,220,235)),
        size=NS{NSK.new(0,0.4),NSK.new(1,0)},trans=NS{NSK.new(0,0.5),NSK.new(1,1)},
        spd=NR(0.5,2),rate=20,life=NR(2,3),spread=V2(80,10),le=0.3})
end

AURAS["Neon Rainbow"] = function(char,hrp)
    mkHL(char, C3(255,255,255), C3(255,255,255), 0.9, 0.0)
    local att=mkAtt(hrp,V3(0,-1,0))
    mkFX(att,{color=CS{CSK.new(0,C3(255,0,100)),CSK.new(0.25,C3(255,200,0)),
        CSK.new(0.5,C3(0,255,100)),CSK.new(0.75,C3(0,100,255)),CSK.new(1,C3(200,0,255))},
        size=NS{NSK.new(0,0.2),NSK.new(0.5,0.3),NSK.new(1,0)},
        trans=NS{NSK.new(0,0),NSK.new(0.8,0.3),NSK.new(1,1)},
        spd=NR(4,10),rate=70,life=NR(1,2),spread=V2(60,60),le=1})
    mkFX(att,{color=CS(C3(255,255,255)),size=NS{NSK.new(0,0.08),NSK.new(1,0)},
        trans=NS{NSK.new(0,0),NSK.new(1,1)},spd=NR(10,20),rate=40,life=NR(0.1,0.3),
        spread=V2(180,180),le=1})
end

local function applyAura(char, name)
    if not char then return end
    clearAura(char)
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    if AURAS[name] then AURAS[name](char, hrp) end
end

-- ======== WINGS ========
local function clearWings(char)
    if not char then return end
    for _,d in ipairs(char:GetDescendants()) do if d:GetAttribute("_AuraWing") then d:Destroy() end end
end

local WING_STYLES = {
    Angel    = {c1=C3(255,255,255), c2=C3(255,230,120), t=0.22, mat=Enum.Material.Neon},
    Demon    = {c1=C3(180,0,0),     c2=C3(60,0,0),      t=0.18, mat=Enum.Material.Neon, big=1.2},
    Butterfly= {c1=C3(0,200,255),   c2=C3(160,0,255),   t=0.2,  mat=Enum.Material.Neon, wide=1.3},
}

local function applyWings(char, style)
    if not char then return end
    clearWings(char)
    if style=="None" then return end
    local cfg=WING_STYLES[style]; if not cfg then return end
    local torso=char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"); if not torso then return end
    local sc=cfg.big or 1; local wr=cfg.wide or 1

    local function mkWing(sy, sz, color, cf)
        local p=Instance.new("Part"); p:SetAttribute("_AuraWing",true)
        p.Size=V3(0.08, sy, sz); p.Color=color; p.Material=cfg.mat
        p.Transparency=cfg.t; p.CanCollide=false; p.CastShadow=false; p.Anchored=false
        p.Parent=char
        p.CFrame=torso.CFrame*cf
        local wc=Instance.new("WeldConstraint",p); wc:SetAttribute("_AuraWing",true); wc.Part0=torso; wc.Part1=p
    end

    for _,s in ipairs({-1,1}) do
        mkWing(2.0*sc, 3.2*wr*sc, cfg.c1,
            CFrame.new(s*2.0*sc, 0.6, -0.25)*CFrame.Angles(math.rad(14),math.rad(s*(-28)),math.rad(s*42)))
        mkWing(1.5*sc, 2.2*wr*sc, cfg.c2,
            CFrame.new(s*1.9*sc, -0.5, -0.15)*CFrame.Angles(math.rad(-12),math.rad(s*(-18)),math.rad(s*54)))
        mkWing(0.8*sc, 1.1*sc,    cfg.c1,
            CFrame.new(s*2.9*sc, 1.3, -0.4)*CFrame.Angles(math.rad(5),math.rad(s*(-38)),math.rad(s*20)))
    end
end

-- ======== HALO ========
local function makeHalo(char)
    if not char then return nil end
    local head=char:FindFirstChild("Head"); if not head then return nil end
    local part=Instance.new("Part")
    part.Name="_HaloPart"; part.Size=V3(2.4,0.18,2.4)
    part.Shape=Enum.PartType.Cylinder; part.Material=Enum.Material.Neon; part.Color=C3(255,215,0)
    part.CanCollide=false; part.CastShadow=false; part.Anchored=true; part.Transparency=0.1; part.Parent=char
    return part
end
local function clearHalo()
    if haloObj then haloObj:Destroy(); haloObj=nil end
    local char=LP.Character; if not char then return end
    for _,d in ipairs(char:GetDescendants()) do if d.Name=="_HaloPart" then d:Destroy() end end
end

-- ======== LIGHT PRESET ========
local function applyLightPreset(p)
    Lighting.Brightness=p.brightness; Lighting.Ambient=C3(unpack(p.ambient))
    Lighting.OutdoorAmbient=C3(unpack(p.outdoor)); Lighting.FogEnd=p.fog
    Lighting.FogColor=C3(unpack(p.fogcol)); Lighting.ClockTime=p.clock
end

-- ======== CHARACTER ADDED ========
local function setupChar(char)
    task.wait(1)
    if headlessEnabled  then applyHeadless(true)              end
    if korbloxEnabled   then applyKorblox(true)               end
    if trailEnabled     then applyTrails(true)                end
    if auraType~="None" then applyAura(char, auraType)        end
    if wingsStyle~="None" then applyWings(char, wingsStyle)   end
    if haloEnabled      then haloObj=makeHalo(char)           end
    if instantRespawn   then
        local hum=char:FindFirstChildOfClass("Humanoid")
        if hum then hum.Died:Connect(function() task.wait(0.1); LP:LoadCharacter() end) end
    end
end
LP.CharacterAdded:Connect(setupChar)
if LP.Character then task.spawn(setupChar, LP.Character) end

-- ======== HUD ========
local HUD=Instance.new("ScreenGui"); HUD.Name="TimeBomb_HUD"; HUD.ResetOnSpawn=false; HUD.DisplayOrder=49
pcall(function() HUD.Parent=CoreGui end)
if not HUD.Parent then HUD.Parent=LP.PlayerGui end
local hudF=Instance.new("Frame"); hudF.Size=UDim2.new(0,118,0,100); hudF.Position=UDim2.new(0,5,0.5,-50)
hudF.BackgroundColor3=Color3.new(0,0,0); hudF.BackgroundTransparency=0.3; hudF.BorderSizePixel=0; hudF.Parent=HUD
Instance.new("UICorner",hudF).CornerRadius=UDim.new(0,6)
local DIM=C3(90,90,100); local PUR=C3(165,95,255)
local hudLabels={}
local hudNames={"Speed","Bomb Spd","Spin Bot","Inf Jump","Noclip","Follow"}
for i,n in ipairs(hudNames) do
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,0,14); lbl.Position=UDim2.new(0,7,0,4+(i-1)*16)
    lbl.BackgroundTransparency=1; lbl.Text=n..": OFF"; lbl.TextColor3=DIM
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=11; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=hudF
    hudLabels[n]=lbl
end
local function updateHUD()
    local s={["Speed"]=regularSpeedEnabled,["Bomb Spd"]=bombSpeedEnabled,["Spin Bot"]=spinEnabled,
             ["Inf Jump"]=infiniteJumpEnabled,["Noclip"]=noclipEnabled,["Follow"]=followEnabled}
    for n,lbl in pairs(hudLabels) do lbl.Text=n..": "..(s[n] and "ON" or "OFF"); lbl.TextColor3=s[n] and PUR or DIM end
    if followEnabled and followTarget then hudLabels["Follow"].Text="→ "..followTarget.Name; hudLabels["Follow"].TextColor3=PUR end
end
local function syncToggle(flag,val)
    if Rayfield and Rayfield.Flags and Rayfield.Flags[flag] then pcall(function() Rayfield.Flags[flag]:Set(val) end) end
end

-- ======== RAYFIELD ========
local Rayfield=loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window=Rayfield:CreateWindow({Name="Timebomb Duels",Icon=0,LoadingTitle="Timebomb Duels",LoadingSubtitle="based.gg",Theme="Purple",DisableRayfieldPrompts=false,DisableBuildWarnings=false})

local SpeedTab   = Window:CreateTab("Speed",     "zap")
local CombatTab  = Window:CreateTab("Combat",    "sword")
local CharTab    = Window:CreateTab("Character", "user")
local VisualsTab = Window:CreateTab("Visuals",   "eye")
local FXTab      = Window:CreateTab("FX",        "sparkles")
local KeysTab    = Window:CreateTab("Keys",      "keyboard")

-- ======== SPEED TAB ========
SpeedTab:CreateSection("Regular Movement")
SpeedTab:CreateToggle({Name="Speed Boost",CurrentValue=false,Flag="SpeedEnabled",Callback=function(v) regularSpeedEnabled=v; updateHUD() end})
SpeedTab:CreateSlider({Name="Speed Value",Range={1,100},Increment=1,Suffix="",CurrentValue=20,Flag="SpeedValue",Callback=function(v) regularSpeed=v end})
SpeedTab:CreateSection("Bomb Movement")
SpeedTab:CreateToggle({Name="Bomb Speed",CurrentValue=false,Flag="BombSpeedEnabled",Callback=function(v) bombSpeedEnabled=v; updateHUD() end})
SpeedTab:CreateSlider({Name="Bomb Speed Value",Range={1,100},Increment=1,Suffix="",CurrentValue=25,Flag="BombSpeedValue",Callback=function(v) bombSpeed=v end})
SpeedTab:CreateSection("Checks")
SpeedTab:CreateToggle({Name="Ladder Check",CurrentValue=true,Flag="LadderCheck",Callback=function(v) ladderCheckEnabled=v end})
SpeedTab:CreateToggle({Name="Frozen Check",CurrentValue=true,Flag="FrozenCheck",Callback=function(v) frozenCheckEnabled=v end})

-- ======== COMBAT TAB ========
CombatTab:CreateSection("Bot")
CombatTab:CreateToggle({Name="Spin Bot",CurrentValue=false,Flag="SpinEnabled",Callback=function(v) spinEnabled=v; updateHUD() end})
CombatTab:CreateSection("Movement")
CombatTab:CreateToggle({Name="Infinite Jump",CurrentValue=false,Flag="InfJump",Callback=function(v) infiniteJumpEnabled=v; updateHUD() end})
CombatTab:CreateToggle({Name="Noclip",CurrentValue=false,Flag="NoclipEnabled",Callback=function(v) noclipEnabled=v; updateHUD() end})
CombatTab:CreateSection("Respawn")
CombatTab:CreateToggle({Name="Instant Respawn",CurrentValue=false,Flag="InstantRespawn",
    Callback=function(v)
        instantRespawn=v
        if v then
            local char=LP.Character
            if char then
                local hum=char:FindFirstChildOfClass("Humanoid")
                if hum then hum.Died:Connect(function() task.wait(0.1); LP:LoadCharacter() end) end
            end
        end
        Rayfield:Notify({Title="Instant Respawn",Content=v and "ON" or "OFF",Duration=2,Image=4483362458})
    end})
CombatTab:CreateSection("Follow Target (Bomb Only)")
local playerOptions={}
for _,p in ipairs(Players:GetPlayers()) do if p~=LP then playerOptions[#playerOptions+1]=p.Name end end
if #playerOptions==0 then playerOptions={"(no players)"} end
CombatTab:CreateDropdown({Name="Select Target",Options=playerOptions,CurrentOption={playerOptions[1]},MultipleOptions=false,Flag="FollowTarget",
    Callback=function(opt) local name=type(opt)=="table" and opt[1] or opt; followTarget=Players:FindFirstChild(name)
        if followTarget then Rayfield:Notify({Title="Follow",Content="Target: "..name,Duration=2,Image=4483362458}) end end})
CombatTab:CreateToggle({Name="Follow When Bomb",CurrentValue=false,Flag="FollowEnabled",Callback=function(v) followEnabled=v; updateHUD() end})
CombatTab:CreateSlider({Name="Follow Distance",Range={0,15},Increment=1,Suffix=" studs",CurrentValue=3,Flag="FollowDist",Callback=function(v) followDist=v end})
CombatTab:CreateButton({Name="Set Target = Nearest",Callback=function()
    local char=LP.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local best,bd=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then local ph=p.Character:FindFirstChild("HumanoidRootPart")
            if ph then local d=(ph.Position-hrp.Position).Magnitude; if d<bd then bd=d; best=p end end
        end
    end
    if best then followTarget=best; Rayfield:Notify({Title="Follow",Content="Target: "..best.Name,Duration=2,Image=4483362458}) end
end})

-- ======== CHARACTER TAB ========
CharTab:CreateSection("Appearance")
CharTab:CreateToggle({Name="Client Headless",CurrentValue=false,Flag="HeadlessEnabled",Callback=function(v) headlessEnabled=v; applyHeadless(v) end})
CharTab:CreateToggle({Name="Client Korblox",CurrentValue=false,Flag="KorbloxEnabled",Callback=function(v) korbloxEnabled=v; applyKorblox(v) end})
CharTab:CreateSection("Foot Trails")
CharTab:CreateToggle({Name="Enable Trails",CurrentValue=false,Flag="TrailEnabled",Callback=function(v) trailEnabled=v; applyTrails(v) end})
CharTab:CreateDropdown({Name="Trail Color",Options={"Purple","Cyan","Fire","Ice","Gold","White"},CurrentOption={"Purple"},MultipleOptions=false,Flag="TrailColor",
    Callback=function(opt) trailColorKey=type(opt)=="table" and opt[1] or opt; if trailEnabled then applyTrails(true) end end})
CharTab:CreateSection("Aura")
CharTab:CreateDropdown({Name="Aura Style",
    Options={"None","Purple Storm","Blue Flames","Galaxy","Ice Crystals","Shadow","Golden Divine","Lightning","Crimson","Sakura","Neon Rainbow"},
    CurrentOption={"None"},MultipleOptions=false,Flag="AuraStyle",
    Callback=function(opt)
        auraType=type(opt)=="table" and opt[1] or opt
        applyAura(LP.Character, auraType)
        Rayfield:Notify({Title="Aura",Content=auraType=="None" and "Removed" or auraType.." applied",Duration=2,Image=4483362458})
    end})
CharTab:CreateSection("Wings")
CharTab:CreateDropdown({Name="Wings Style",Options={"None","Angel","Demon","Butterfly"},CurrentOption={"None"},MultipleOptions=false,Flag="WingsStyle",
    Callback=function(opt)
        wingsStyle=type(opt)=="table" and opt[1] or opt
        applyWings(LP.Character, wingsStyle)
        Rayfield:Notify({Title="Wings",Content=wingsStyle=="None" and "Removed" or wingsStyle.." applied",Duration=2,Image=4483362458})
    end})
CharTab:CreateSection("Halo")
CharTab:CreateToggle({Name="Halo",CurrentValue=false,Flag="HaloEnabled",
    Callback=function(v)
        haloEnabled=v
        if v then haloObj=makeHalo(LP.Character)
        else clearHalo() end
    end})

-- ======== VISUALS TAB ========
VisualsTab:CreateSection("Camera")
VisualsTab:CreateToggle({Name="Custom FOV",CurrentValue=false,Flag="FOVEnabled",
    Callback=function(v) fovEnabled=v; if not v then workspace.CurrentCamera.FieldOfView=70 end end})
VisualsTab:CreateSlider({Name="Field of View",Range={30,120},Increment=1,Suffix="°",CurrentValue=70,Flag="FOVValue",
    Callback=function(v) customFOV=v; if fovEnabled then workspace.CurrentCamera.FieldOfView=v end end})
VisualsTab:CreateDropdown({Name="Aspect Ratio",Options={"16:9","21:9","4:3","2.35:1","1:1"},CurrentOption={"16:9"},MultipleOptions=false,Flag="AspectRatio",
    Callback=function(opt) setAspectRatio(type(opt)=="table" and opt[1] or opt) end})
VisualsTab:CreateSection("Shader")
VisualsTab:CreateDropdown({Name="Shader Preset",Options={"None","Cinematic","Vibrant","Dark Film","Neon Glow","Warm Sunset","Cold Blue","Depth"},CurrentOption={"None"},MultipleOptions=false,Flag="ShaderPreset",
    Callback=function(opt) shaderActive=type(opt)=="table" and opt[1] or opt; applyShader(shaderActive) end})
VisualsTab:CreateSection("Scene")
local sceneList={}; for n in pairs(SCENE_PRESETS) do sceneList[#sceneList+1]=n end; table.sort(sceneList)
VisualsTab:CreateDropdown({Name="Scene Preset",Options=sceneList,CurrentOption={sceneList[1]},MultipleOptions=false,Flag="ScenePreset",
    Callback=function(opt) local n=type(opt)=="table" and opt[1] or opt; if SCENE_PRESETS[n] then applyLightPreset(SCENE_PRESETS[n]) end end})
VisualsTab:CreateSection("Weather")
local weatherList={}; for n in pairs(WEATHER_PRESETS) do weatherList[#weatherList+1]=n end; table.sort(weatherList)
VisualsTab:CreateDropdown({Name="Weather Preset",Options=weatherList,CurrentOption={weatherList[1]},MultipleOptions=false,Flag="WeatherPreset",
    Callback=function(opt) local n=type(opt)=="table" and opt[1] or opt; if WEATHER_PRESETS[n] then applyLightPreset(WEATHER_PRESETS[n]) end end})
VisualsTab:CreateSection("Reset")
VisualsTab:CreateButton({Name="Reset Lighting",Callback=function()
    Lighting.Brightness=origLight.Brightness; Lighting.Ambient=origLight.Ambient
    Lighting.OutdoorAmbient=origLight.OutdoorAmbient; Lighting.FogEnd=origLight.FogEnd
    Lighting.FogColor=origLight.FogColor; Lighting.ClockTime=origLight.ClockTime
    clearShaders()
    Rayfield:Notify({Title="Visuals",Content="Lighting reset",Duration=2,Image=4483362458})
end})

-- ======== FX TAB ========
FXTab:CreateSection("Rain")
FXTab:CreateToggle({Name="Enable Rain",CurrentValue=false,Flag="RainEnabled",
    Callback=function(v) rainEnabled=v
        local rate=tonumber(Rayfield.Flags and Rayfield.Flags["RainRate"] and Rayfield.Flags["RainRate"].Value) or 1500
        setRain(v,rate)
        if v then Rayfield:Notify({Title="FX",Content="Rain started",Duration=2,Image=4483362458}) end
    end})
FXTab:CreateSlider({Name="Rain Intensity",Range={200,3000},Increment=100,Suffix="",CurrentValue=1500,Flag="RainRate",
    Callback=function(v) updateRainRate(v) end})
FXTab:CreateToggle({Name="Thunder",CurrentValue=false,Flag="ThunderEnabled",Callback=function(v) thunderEnabled=v; setThunder(v) end})
FXTab:CreateSection("Performance")
FXTab:CreateToggle({Name="Disable Particles",CurrentValue=false,Flag="NoParticles",
    Callback=function(v)
        for _,d in ipairs(game.Workspace:GetDescendants()) do
            if (d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam"))
               and d.Name~="_RainFX" and d.Name~="_FootTrail" and not d:GetAttribute("_AuraFX") then d.Enabled=not v end
        end end})
FXTab:CreateToggle({Name="Disable Lights",CurrentValue=false,Flag="NoLights",
    Callback=function(v) for _,d in ipairs(game.Workspace:GetDescendants()) do if d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then d.Enabled=not v end end end})
FXTab:CreateToggle({Name="Disable Post FX",CurrentValue=false,Flag="NoPostFX",
    Callback=function(v) for _,d in ipairs(Lighting:GetChildren()) do if d:IsA("PostEffect") and not d:GetAttribute("_TB") then d.Enabled=not v end end end})
FXTab:CreateToggle({Name="Disable Textures",CurrentValue=false,Flag="NoTextures",
    Callback=function(v) for _,d in ipairs(game.Workspace:GetDescendants()) do if d:IsA("Texture") or d:IsA("Decal") then d.Transparency=v and 1 or 0 end end end})
FXTab:CreateSection("HUD")
FXTab:CreateToggle({Name="Show HUD",CurrentValue=true,Flag="ShowHUD",Callback=function(v) hudF.Visible=v end})

-- ======== KEYS TAB ========
KeysTab:CreateSection("Keybinds")
KeysTab:CreateKeybind({Name="Menu Toggle",CurrentKeybind="",HoldToInteract=false,Flag="MenuKeybind",
    Callback=function()
        local rg=CoreGui:FindFirstChild("Rayfield") or LP.PlayerGui:FindFirstChild("Rayfield")
        if rg then rg.Enabled=not rg.Enabled end
    end})
KeysTab:CreateKeybind({Name="Speed Boost",CurrentKeybind="",HoldToInteract=false,Flag="SpeedKeybind",
    Callback=function() regularSpeedEnabled=not regularSpeedEnabled; syncToggle("SpeedEnabled",regularSpeedEnabled); updateHUD(); Rayfield:Notify({Title="Speed Boost",Content=regularSpeedEnabled and "ON" or "OFF",Duration=1.5,Image=4483362458}) end})
KeysTab:CreateKeybind({Name="Bomb Speed",CurrentKeybind="",HoldToInteract=false,Flag="BombSpeedKeybind",
    Callback=function() bombSpeedEnabled=not bombSpeedEnabled; syncToggle("BombSpeedEnabled",bombSpeedEnabled); updateHUD(); Rayfield:Notify({Title="Bomb Speed",Content=bombSpeedEnabled and "ON" or "OFF",Duration=1.5,Image=4483362458}) end})
KeysTab:CreateKeybind({Name="Spin Bot",CurrentKeybind="",HoldToInteract=false,Flag="SpinKeybind",
    Callback=function() spinEnabled=not spinEnabled; syncToggle("SpinEnabled",spinEnabled); updateHUD(); Rayfield:Notify({Title="Spin Bot",Content=spinEnabled and "ON" or "OFF",Duration=1.5,Image=4483362458}) end})
KeysTab:CreateKeybind({Name="Infinite Jump",CurrentKeybind="",HoldToInteract=false,Flag="InfJumpKeybind",
    Callback=function() infiniteJumpEnabled=not infiniteJumpEnabled; syncToggle("InfJump",infiniteJumpEnabled); updateHUD(); Rayfield:Notify({Title="Infinite Jump",Content=infiniteJumpEnabled and "ON" or "OFF",Duration=1.5,Image=4483362458}) end})
KeysTab:CreateKeybind({Name="Noclip",CurrentKeybind="",HoldToInteract=false,Flag="NoclipKeybind",
    Callback=function() noclipEnabled=not noclipEnabled; syncToggle("NoclipEnabled",noclipEnabled); updateHUD(); Rayfield:Notify({Title="Noclip",Content=noclipEnabled and "ON" or "OFF",Duration=1.5,Image=4483362458}) end})
KeysTab:CreateKeybind({Name="Follow Target",CurrentKeybind="",HoldToInteract=false,Flag="FollowKeybind",
    Callback=function() followEnabled=not followEnabled; syncToggle("FollowEnabled",followEnabled); updateHUD(); Rayfield:Notify({Title="Follow",Content=followEnabled and "ON" or "OFF",Duration=1.5,Image=4483362458}) end})

-- ======== INFINITE JUMP ========
UIS.InputBegan:Connect(function(inp,gpe) if gpe then return end; if inp.KeyCode==Enum.KeyCode.Space then jumpHeld=true end end)
UIS.InputEnded:Connect(function(inp) if inp.KeyCode==Enum.KeyCode.Space then jumpHeld=false end end)
UIS.JumpRequest:Connect(function()
    if not infiniteJumpEnabled then return end
    local c=LP.Character; if not c then return end
    local hum=c:FindFirstChild("Humanoid"); if not hum then return end
    if hum.JumpPower==0  then hum.JumpPower=50  end
    if hum.JumpHeight==0 then hum.JumpHeight=7.2 end
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
end)

-- ======== HEARTBEAT ========
RunService.Heartbeat:Connect(function()
    if infiniteJumpEnabled and jumpHeld then
        local c=LP.Character; if c then
            local hum=c:FindFirstChild("Humanoid")
            if hum and hum:GetState()==Enum.HumanoidStateType.Freefall then
                if hum.JumpPower==0  then hum.JumpPower=50  end
                if hum.JumpHeight==0 then hum.JumpHeight=7.2 end
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
    if noclipEnabled then
        local c=LP.Character; if c then
            for _,p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then p.CanCollide=false end
            end
        end
    end
end)

-- ======== RENDER STEPPED ========
RunService.RenderStepped:Connect(function(dt)
    if fovEnabled then workspace.CurrentCamera.FieldOfView=customFOV end

    if haloEnabled and haloObj and haloObj.Parent then
        local char=LP.Character
        if char then
            local head=char:FindFirstChild("Head")
            if head then
                haloAngle=(haloAngle+80*dt)%360
                haloObj.CFrame=head.CFrame*CFrame.new(0,1.6,0)*CFrame.Angles(0.15,math.rad(haloAngle),math.rad(90))
            end
        end
    end

    local char=LP.Character; if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart")
    local hum=char:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health<=0 then return end

    if followEnabled and followTarget and hasBomb() then
        if not Players:FindFirstChild(followTarget.Name) then
            followTarget=nil; followEnabled=false
            syncToggle("FollowEnabled",false); updateHUD()
            Rayfield:Notify({Title="Follow",Content="Target left the server",Duration=3,Image=4483362458})
        else
            local tc=followTarget.Character
            if tc then
                local tHRP=tc:FindFirstChild("HumanoidRootPart")
                if tHRP and (tHRP.Position-hrp.Position).Magnitude<=300 then
                    hrp.CFrame=tHRP.CFrame*CFrame.new(0,0,followDist); return
                end
            end
        end
    end

    if frozenCheckEnabled then
        if hrp.Anchored then return end
        if hum.PlatformStand then return end
        for _,v in ipairs(hrp:GetChildren()) do if v:IsA("BodyPosition") or v:IsA("BodyVelocity") then return end end
    end
    if ladderCheckEnabled and isOnLadder(hum) then return end

    local dir=hum.MoveDirection; local speed=0
    if hasBomb() then if bombSpeedEnabled then speed=bombSpeed end
    elseif regularSpeedEnabled then speed=regularSpeed end

    local newCF=hrp.CFrame
    if speed>0 and dir.Magnitude>0 then newCF=newCF+dir*speed*dt end
    if spinEnabled then spinAngle=(spinAngle+20*dt)%(2*math.pi); newCF=CFrame.new(newCF.Position)*CFrame.Angles(0,spinAngle,0) end
    if newCF~=hrp.CFrame then hrp.CFrame=newCF end
end)
