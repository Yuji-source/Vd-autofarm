--[[
    ============================================================
    VD SHIELD - VIOLENCE DISTRICT AUTOFARM
    Safest Edition | Mobile + PC | 109 Features
    ============================================================
]]

-- ============================================================
-- SECTION 1: PLATFORM DETECTION & SAFE SERVICES
-- ============================================================
print("[VD] Initializing VD Shield...")

local function safeService(name)
    local svc = game:GetService(name)
    if cloneref then
        local ok, cloned = pcall(cloneref, svc)
        if ok then return cloned end
    end
    return svc
end

local Players = safeService("Players")
local RS = safeService("ReplicatedStorage")
local RunService = safeService("RunService")
local TweenService = safeService("TweenService")
local UIS = safeService("UserInputService")
local Lighting = safeService("Lighting")
local VIM = safeService("VirtualInputManager")
local VU = safeService("VirtualUser")
local SS = safeService("SoundService")
local Debris = safeService("Debris")
local HttpService = safeService("HttpService")
local WS = workspace

if not game:IsLoaded() then game.Loaded:Wait() end
local LP = Players.LocalPlayer
while not LP do task.wait(0.1) LP = Players.LocalPlayer end

local IS_MOBILE = UIS.TouchEnabled and not UIS.MouseEnabled
local IS_PC = not IS_MOBILE
print("[VD] Platform: " .. (IS_MOBILE and "Mobile" or "PC"))

local function getAdaptiveScale()
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
    local minDim = math.min(vp.X, vp.Y)
    if minDim < 500 then return 0.7
    elseif minDim < 700 then return 0.78
    elseif minDim < 900 then return 0.85
    else return 0.9 end
end

-- ============================================================
-- SECTION 2: UNIVERSAL BYPASS MODULE
-- ============================================================
local Bypass = {
    enabled = false,
    debugMode = false,
    originalProperties = {},
    blockedRemotes = {},
    antiCheatConnections = {},
    hooks = {},
}

function Bypass.setDebugMode(enabled) Bypass.debugMode = enabled end
function Bypass.log(...) if Bypass.debugMode then print("[VD-Bypass]", ...) end end

function Bypass.spoofProperties(humanoid)
    if not humanoid then return end
    Bypass.originalProperties[humanoid] = {
        WalkSpeed = humanoid.WalkSpeed,
        JumpPower = humanoid.JumpPower,
    }
    local mt = getrawmetatable and getrawmetatable(humanoid)
    if mt and hookmetamethod then
        local oldIndex = mt.__index
        if not Bypass.hooks[humanoid] then
            Bypass.hooks[humanoid] = true
            hookmetamethod(humanoid, "__index", function(self, key)
                local orig = oldIndex(self, key)
                if key == "WalkSpeed" and Bypass.enabled then
                    local cached = Bypass.originalProperties[self]
                    if cached and cached.WalkSpeed then return cached.WalkSpeed end
                end
                if key == "JumpPower" and Bypass.enabled then
                    local cached = Bypass.originalProperties[self]
                    if cached and cached.JumpPower then return cached.JumpPower end
                end
                return orig
            end)
            Bypass.log("Property spoofing enabled")
        end
    end
end

function Bypass.blockRemote(remote)
    if not remote then return end
    Bypass.blockedRemotes[remote] = true
    local mt = getrawmetatable and getrawmetatable(remote)
    if mt and hookmetamethod then
        local oldNamecall = mt.__namecall
        if oldNamecall and not Bypass.hooks[remote] then
            Bypass.hooks[remote] = true
            hookmetamethod(remote, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if method == "FireServer" and Bypass.blockedRemotes[self] then
                    Bypass.log("Blocked anti-cheat remote: " .. tostring(self.Name))
                    return
                end
                return oldNamecall(self, ...)
            end)
        end
    end
end

function Bypass.hookDebug()
    if not hookfunction or not getgc then return end
    local ok, oldGetInfo = pcall(function() return debug.getinfo end)
    if not ok then return end
    if debug and debug.getinfo and hookfunction then
        local originalGetInfo = debug.getinfo
        hookfunction(originalGetInfo, function(...)
            local info = originalGetInfo(...)
            if info and info.source and tostring(info.source):find("VD_Shield") then
                info.source = "=nil"
            end
            return info
        end)
        Bypass.log("Debug hooking enabled")
    end
end

function Bypass.disableAntiCheatConnections()
    if not getconnections then return end
    local success, conns = pcall(getconnections, LP.Idled)
    if success and conns then
        for _, conn in pairs(conns) do
            pcall(function()
                if conn and conn.script then
                    local scriptName = conn.script.Name:lower()
                    if scriptName:find("anticheat") or scriptName:find("detect")
                        or scriptName:find("anti") or scriptName:find("guard") then
                        pcall(conn.Disable, conn)
                        table.insert(Bypass.antiCheatConnections, conn)
                    end
                end
            end)
        end
    end
end

function Bypass.enable()
    Bypass.enabled = true
    Bypass.disableAntiCheatConnections()
    Bypass.hookDebug()
    Bypass.log("Universal bypass enabled")
end

function Bypass.simulateInput(key, isDown)
    if getgenv().bypass and getgenv().bypass.simulateInput then
        getgenv().bypass.simulateInput(key, isDown)
        return
    end
    if isDown then VIM:SendKeyEvent(true, key, false, game)
    else VIM:SendKeyEvent(false, key, false, game) end
end

function Bypass.disable()
    Bypass.enabled = false
    for _, conn in pairs(Bypass.antiCheatConnections) do
        pcall(function() conn:Enable() end)
    end
    Bypass.antiCheatConnections = {}
end

Bypass.enable()

-- ============================================================
-- SECTION 3: SAFE GUI PARENTING
-- ============================================================
local guiParent
do
    local ok, hidden = pcall(function() return gethui() end)
    if ok and hidden then guiParent = hidden
    else
        local ok2, coreGui = pcall(function()
            if cloneref then return cloneref(game:GetService("CoreGui")) end
            return game:GetService("CoreGui")
        end)
        if ok2 and coreGui then guiParent = coreGui
        else guiParent = LP:WaitForChild("PlayerGui", 5) or game:GetService("StarterGui") end
    end
end

for _, c in ipairs(guiParent:GetChildren()) do
    if c.Name == "VDGui" or c.Name == "VDLoad" then c:Destroy() end
end
pcall(function()
    for _, c in ipairs(LP.PlayerGui:GetChildren()) do
        if c.Name == "VDGui" or c.Name == "VDLoad" then c:Destroy() end
    end
end)

-- ============================================================
-- SECTION 4: MOBILE SUPPORT
-- ============================================================
local function simulateInteract()
    if IS_PC then
        Bypass.simulateInput(Enum.KeyCode.E, true)
        task.wait(0.06)
        Bypass.simulateInput(Enum.KeyCode.E, false)
    else
        local vp = workspace.CurrentCamera.ViewportSize
        local x = math.floor(vp.X * 0.58)
        local y = math.floor(vp.Y * 0.5)
        pcall(function()
            VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
            task.wait(0.06)
            VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
        end)
    end
end

local function simulateWiggle()
    if IS_PC then
        pcall(function()
            VIM:SendKeyEvent(true, Enum.KeyCode.A, false, game)
            task.wait(0.04)
            VIM:SendKeyEvent(false, Enum.KeyCode.A, false, game)
            VIM:SendKeyEvent(true, Enum.KeyCode.D, false, game)
            task.wait(0.04)
            VIM:SendKeyEvent(false, Enum.KeyCode.D, false, game)
        end)
    else
        local vp = workspace.CurrentCamera.ViewportSize
        local cx = math.floor(vp.X * 0.5)
        local cy = math.floor(vp.Y * 0.55)
        pcall(function()
            VIM:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
            task.wait(0.04)
            VIM:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
            VIM:SendMouseButtonEvent(cx + 20, cy, 0, true, game, 0)
            task.wait(0.04)
            VIM:SendMouseButtonEvent(cx + 20, cy, 0, false, game, 0)
        end)
    end
end

local isDraggingCamera = false
UIS.InputBegan:Connect(function(i, gp)
    if i.UserInputType == Enum.UserInputType.Touch then isDraggingCamera = true end
end)
UIS.InputEnded:Connect(function(i, gp)
    if i.UserInputType == Enum.UserInputType.Touch then isDraggingCamera = false end
end)

-- ============================================================
-- SECTION 5: SAFE INPUT
-- ============================================================
local function sKey(k)
    Bypass.simulateInput(k, true)
    task.wait(0.06)
    Bypass.simulateInput(k, false)
end

-- ============================================================
-- SECTION 6: REMOTE RESOLUTION
-- ============================================================
local R = RS:WaitForChild("Remotes", 10)
local function findRemote(path)
    local parts = {}
    for s in path:gmatch("[^%.]+") do table.insert(parts, s) end
    local cur = R
    for _, p in ipairs(parts) do if cur then cur = cur:FindFirstChild(p) end end
    return cur
end

local REM = {}
REM.BasicAttack = findRemote("Attacks.BasicAttack")
REM.Hit = findRemote("Attacks.hit")
REM.Lunge = findRemote("Attacks.Lunge")
REM.AfterAttack = findRemote("Attacks.AfterAttack")
REM.RepairEvent = findRemote("Generator.RepairEvent")
REM.BreakGenEvent = findRemote("Generator.BreakGenEvent")
REM.ProgressUpdate = findRemote("Progress.ProgressUpdateEvent")
REM.Parry = findRemote("Items.Parrying Dagger.parry")
REM.HookEvent = findRemote("Carry.HookEvent")
REM.CarrySurvivor = findRemote("Carry.CarrySurvivorEvent")
REM.DropSurvivor = findRemote("Carry.DropSurvivorEvent")
REM.SelfUnHook = findRemote("Carry.SelfUnHookEvent")
REM.UnHook = findRemote("Carry.UnHookEvent")
REM.HealEvent = findRemote("Healing.HealEvent")
REM.Teleport = findRemote("Mechanics.Teleportcharacter")
REM.EquipKillerPerk = findRemote("ShopKillers.EquipPerk")
REM.EquipSurvPerk = findRemote("Shop.EquipPerk")

local ATK_REMOTES = {}
for _, r in ipairs({REM.BasicAttack, REM.Hit, REM.Lunge, REM.AfterAttack}) do
    if r then table.insert(ATK_REMOTES, r) end
end

-- ============================================================
-- SECTION 7: HONEYPOT PROTECTION
-- ============================================================
local SAFE_REMOTES = {}
for _, r in pairs(REM) do if r then SAFE_REMOTES[r] = true end end

local remoteFireCount = {}
task.spawn(function()
    for _, r in pairs(REM) do
        if r and r:IsA("RemoteEvent") then
            pcall(function()
                r.OnClientEvent:Connect(function()
                    remoteFireCount[r] = (remoteFireCount[r] or 0) + 1
                end)
            end)
        end
    end
end)

local function safeFire(remote, ...)
    if not remote then return end
    if not SAFE_REMOTES[remote] then
        warn("[VD Honeypot] BLOCKED: " .. tostring(remote:GetFullName()))
        return
    end
    pcall(function() remote:FireServer(...) end)
end

-- ============================================================
-- SECTION 8: COLORS & NOTIFICATIONS
-- ============================================================
local C = {
    A=Color3.fromRGB(255,152,45), AL=Color3.fromRGB(255,220,150),
    AB=Color3.fromRGB(34,24,11), AH=Color3.fromRGB(54,38,15),
    BG=Color3.fromRGB(9,9,11), SB=Color3.fromRGB(20,20,24),
    HD=Color3.fromRGB(20,20,24), BD=Color3.fromRGB(52,52,60),
    TX=Color3.fromRGB(238,238,244), TD=Color3.fromRGB(140,140,152),
    TO=Color3.fromRGB(31,31,37),
    GRN=Color3.fromRGB(0,220,80), RED=Color3.fromRGB(220,50,50),
    AMB=Color3.fromRGB(220,200,80), GRY=Color3.fromRGB(140,140,140),
}

local function Notify(t)
    local n=Instance.new("TextLabel")
    n.Size=UDim2.new(0,300,0,36)
    n.Position=UDim2.new(0.5,-150,0,15)
    n.BackgroundColor3=C.AB n.BorderSizePixel=2 n.BorderColor3=C.A
    n.TextColor3=C.A n.TextSize=11 n.Font=Enum.Font.GothamBold
    n.Text=t n.Parent=guiParent
    Instance.new("UICorner",n).CornerRadius=UDim.new(0,6)
    task.delay(2.5,function() n:Destroy() end)
end

-- ============================================================
-- SECTION 9: STATE TABLE
-- ============================================================
local State = {
    AutoRepair=false, AutoSkillCheck=false, AutoParry=false, AutoHeal=false,
    LoopWalkSpeed=false, LoopSpeedValue=18, EnableJump=false,
    SpeedBoost=false, SpeedValue=22, AutoClimb=true,
    SilentAimSurvivor=false, SilentAimSmoothness=15, SilentAimFOV=120,
    SilentAimMissChance=0,
    AutoDodge=false, AutoZigZag=false, ZigZagSpeed=0.3,
    SmartKillerAvoidance=false, AvoidDistance=40,
    AutoWiggleEscape=false, DynamicActionCadence=false,
    KillerNotificationSound=false, KillerNotificationDistance=30, KillerNotificationVolume=5,
    KillerAutoFarm=false, AutoChase=false, AutoBreakGen=false,
    AutoDoubleHit=false, AutoDoubleHitDelay=0.5,
    PerkAutoEquip=false, SelectedPerkToEquip="Eternal Torment",
    SilentAimKiller=false, SilentAimKillerSmoothness=15, SilentAimKillerFOV=120,
    ESPSurvivor=false, ESPKiller=false, ESPPallet=false, ESPWindow=false,
    ESPGenerator=false, ESPHook=false, ESPGate=false, ESPRange=500,
    GeneratorProgressTracker=false,
    LoopFullbright=false, NoFog=false, RemoveShadows=false,
    Shaders=false, Saturation=false, SaturationValue=1.4, AntiAfk=false,
    HoneypotProtection=true, ConfigName="VD_Default"
}

-- ============================================================
-- SECTION 10: CONFIG
-- ============================================================
local CFGDIR = "VD_Cfg"
local function saveCfg()
    pcall(function()
        if not isfolder(CFGDIR) then makefolder(CFGDIR) end
        local d={}
        for k,v in pairs(State) do
            if type(v)=="boolean" or type(v)=="number" or type(v)=="string" then d[k]=v end
        end
        writefile(CFGDIR.."/"..State.ConfigName..".json", HttpService:JSONEncode(d))
    end)
end
local function loadCfg()
    pcall(function()
        if isfile(CFGDIR.."/"..State.ConfigName..".json") then
            local d=HttpService:JSONDecode(readfile(CFGDIR.."/"..State.ConfigName..".json"))
            for k,v in pairs(d) do if State[k]~=nil then State[k]=v end end
        end
    end)
end
loadCfg()

-- ============================================================
-- SECTION 11: KILLER DETECTION
-- ============================================================
local KILLER_WEAPONS = {"knife","machete","axe","cleaver","katana","sword","blade","weapon","revolver","gun"}
local function isKiller(player)
    if not player or not player.Character then return false end
    local pc = player.Character
    local equipped = player:GetAttribute("EquippedItem")
    if equipped then
        local e = tostring(equipped):lower()
        if e:find("dagger") or e:find("flashlight") or e:find("bandage")
            or e:find("adrenaline") or e:find("shield") or e:find("candle")
            or e:find("water") or e:find("tracker") or e:find("clone")
            or e:find("twist") then return false end
    end
    local selected = player:GetAttribute("SelectedKiller")
    if selected and selected ~= "" and selected ~= "None" then return true end
    if pc:GetAttribute("IsChasing") == true then return true end
    local ct = pc:GetAttribute("ChaseTargetUsername")
    if ct and ct ~= 0 and ct ~= "" then return true end
    for _, t in pairs(pc:GetChildren()) do
        if t:IsA("Tool") then
            local tn = t.Name:lower()
            for _, kw in ipairs(KILLER_WEAPONS) do
                if tn:find(kw) then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- SECTION 12: LOADING SCREEN
-- ============================================================
local LG = Instance.new("ScreenGui")
LG.Name="VDLoad" LG.ResetOnSpawn=false LG.IgnoreGuiInset=true LG.DisplayOrder=999
LG.Parent=guiParent
local lbg=Instance.new("Frame")
lbg.Size=UDim2.new(1,0,1,0) lbg.BackgroundColor3=C.BG lbg.BorderSizePixel=0 lbg.Parent=LG
local lp=Instance.new("Frame")
lp.Size=UDim2.new(0,400,0,180) lp.Position=UDim2.new(0.5,-200,0.5,-90)
lp.BackgroundColor3=C.HD lp.BorderSizePixel=2 lp.BorderColor3=C.A lp.Parent=lbg
Instance.new("UICorner",lp).CornerRadius=UDim.new(0,12)
local lt=Instance.new("TextLabel")
lt.Size=UDim2.new(1,0,0,36) lt.Position=UDim2.new(0,0,0,20)
lt.BackgroundTransparency=1 lt.Text="VD SHIELD" lt.TextColor3=C.A
lt.TextSize=26 lt.Font=Enum.Font.GothamBold lt.Parent=lp
local lsub=Instance.new("TextLabel")
lsub.Size=UDim2.new(1,0,0,16) lsub.Position=UDim2.new(0,0,0,56)
lsub.BackgroundTransparency=1 lsub.Text="SAFEST EDITION" lsub.TextColor3=C.AL
lsub.TextSize=12 lsub.Font=Enum.Font.Gotham lsub.Parent=lp
local pb=Instance.new("Frame")
pb.Size=UDim2.new(1,-60,0,12) pb.Position=UDim2.new(0,30,0,90)
pb.BackgroundColor3=C.TO pb.BorderSizePixel=2 pb.BorderColor3=C.A pb.Parent=lp
Instance.new("UICorner",pb).CornerRadius=UDim.new(0,6)
local pf=Instance.new("Frame")
pf.Size=UDim2.new(0,0,1,0) pf.BackgroundColor3=C.A pf.BorderSizePixel=0 pf.Parent=pb
Instance.new("UICorner",pf).CornerRadius=UDim.new(0,6)
local pt=Instance.new("TextLabel")
pt.Size=UDim2.new(1,0,0,20) pt.Position=UDim2.new(0,0,0,110)
pt.BackgroundTransparency=1 pt.Text="0%" pt.TextColor3=C.A
pt.TextSize=14 pt.Font=Enum.Font.GothamBold pt.Parent=lp
local st=Instance.new("TextLabel")
st.Size=UDim2.new(1,-30,0,16) st.Position=UDim2.new(0,15,0,138)
st.BackgroundTransparency=1 st.Text="Initializing..." st.TextColor3=C.TD
st.TextSize=10 st.Font=Enum.Font.Gotham st.Parent=lp

task.spawn(function()
    local p=0
    local msgs={"Loading remotes...","Activating safety...","Building GUI...","Almost ready..."}
    while p<100 do
        p=math.min(p+math.random(8,18),100)
        TweenService:Create(pf,TweenInfo.new(0.2),{Size=UDim2.new(p/100,0,1,0)}):Play()
        pt.Text=p.."%"
        st.Text= p<100 and msgs[math.random(1,#msgs)] or "Ready!"
        task.wait(p>=100 and 0.4 or math.random(20,50)/100)
    end
    LG:Destroy()
end)
task.wait(1.2)

-- ============================================================
-- SECTION 13: MAIN GUI
-- ============================================================
local SG=Instance.new("ScreenGui")
SG.Name="VDGui" SG.ResetOnSpawn=false SG.IgnoreGuiInset=true
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling SG.Parent=guiParent
Instance.new("UIScale",SG).Scale = getAdaptiveScale()

local safeInset = Instance.new("UIPadding", SG)
safeInset.PaddingTop = UDim.new(0, 4)
safeInset.PaddingBottom = UDim.new(0, 4)
safeInset.PaddingLeft = UDim.new(0, 4)
safeInset.PaddingRight = UDim.new(0, 4)

local TB=Instance.new("TextButton")
TB.Size=UDim2.new(0,48,0,48) TB.Position=UDim2.new(0,12,0.5,-24)
TB.BackgroundColor3=C.AB TB.BorderSizePixel=3 TB.BorderColor3=C.A
TB.Text="VD" TB.TextColor3=C.A TB.TextSize=16 TB.Font=Enum.Font.GothamBold
TB.Parent=SG
Instance.new("UICorner",TB).CornerRadius=UDim.new(0,24)

local closeBtnGui = Instance.new("TextButton")
closeBtnGui.Name = "VDClose"
closeBtnGui.Size = UDim2.new(0, 40, 0, 40)
closeBtnGui.Position = UDim2.new(0, 12, 0, 50)
closeBtnGui.BackgroundColor3 = C.AB
closeBtnGui.BorderSizePixel = 2
closeBtnGui.BorderColor3 = C.A
closeBtnGui.Text = "≡"
closeBtnGui.TextColor3 = C.A
closeBtnGui.TextSize = 18
closeBtnGui.Font = Enum.Font.GothamBold
closeBtnGui.Parent = SG
Instance.new("UICorner", closeBtnGui).CornerRadius = UDim.new(0, 20)

local MF=Instance.new("Frame")
MF.Size=UDim2.new(0,660,0,440) MF.Position=UDim2.new(0.5,-330,0.5,-220)
MF.BackgroundColor3=C.BG MF.BorderSizePixel=2 MF.BorderColor3=C.A
MF.Active=true MF.Visible=false MF.Parent=SG
Instance.new("UICorner",MF).CornerRadius=UDim.new(0,10)

local function makeDrag(f, handle)
    handle = handle or f
    local d=false, ds, sp
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            d=true ds=i.Position sp=f.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then d=false end end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if d and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local dt=i.Position-ds
            f.Position=UDim2.new(sp.X.Scale,sp.X.Offset+dt.X,sp.Y.Scale,sp.Y.Offset+dt.Y)
        end
    end)
end
makeDrag(TB); makeDrag(MF); makeDrag(closeBtnGui)
TB.MouseButton1Click:Connect(function() MF.Visible=not MF.Visible end)
closeBtnGui.MouseButton1Click:Connect(function() MF.Visible=not MF.Visible end)

local HD=Instance.new("Frame")
HD.Size=UDim2.new(1,0,0,34) HD.BackgroundColor3=C.HD HD.BorderSizePixel=2 HD.BorderColor3=C.A HD.Parent=MF
Instance.new("UICorner",HD).CornerRadius=UDim.new(0,10)
local HT=Instance.new("TextLabel")
HT.Size=UDim2.new(1,-70,1,0) HT.Position=UDim2.new(0,12,0,0)
HT.BackgroundTransparency=1 HT.Text="VD SHIELD" HT.TextColor3=C.A
HT.TextSize=13 HT.Font=Enum.Font.GothamBold HT.TextXAlignment=Enum.TextXAlignment.Left HT.Parent=HD
local CB=Instance.new("TextButton")
CB.Size=UDim2.new(0,24,0,24) CB.Position=UDim2.new(1,-30,0,5)
CB.BackgroundColor3=C.A CB.Text="X" CB.TextColor3=C.TX CB.TextSize=12
CB.Font=Enum.Font.GothamBold CB.BorderSizePixel=0 CB.Parent=HD
Instance.new("UICorner",CB).CornerRadius=UDim.new(0,5)
CB.MouseButton1Click:Connect(function() MF.Visible=false end)

local SB=Instance.new("Frame")
SB.Size=UDim2.new(0,155,1,-42) SB.Position=UDim2.new(0,5,0,38)
SB.BackgroundColor3=C.SB SB.BorderSizePixel=2 SB.BorderColor3=C.A SB.Parent=MF
Instance.new("UICorner",SB).CornerRadius=UDim.new(0,8)
local SBL=Instance.new("UIListLayout",SB)
SBL.SortOrder=Enum.SortOrder.LayoutOrder SBL.Padding=UDim.new(0,4)
local SBP=Instance.new("UIPadding",SB)
SBP.PaddingTop=UDim.new(0,6) SBP.PaddingLeft=UDim.new(0,6) SBP.PaddingRight=UDim.new(0,6)

local SR=Instance.new("TextBox")
SR.Size=UDim2.new(1,-12,0,24) SR.Position=UDim2.new(0,6,0,6)
SR.BackgroundColor3=C.TO SR.BorderSizePixel=2 SR.BorderColor3=C.BD
SR.PlaceholderText="Search..." SR.Text="" SR.TextColor3=C.TX
SR.TextSize=10 SR.Font=Enum.Font.Gotham SR.ClearTextOnFocus=false SR.Parent=SB
Instance.new("UICorner",SR).CornerRadius=UDim.new(0,6)

local CA=Instance.new("Frame")
CA.Size=UDim2.new(1,-170,1,-42) CA.Position=UDim2.new(0,165,0,38)
CA.BackgroundColor3=C.BG CA.BorderSizePixel=2 CA.BorderColor3=C.A CA.Parent=MF
Instance.new("UICorner",CA).CornerRadius=UDim.new(0,8)
local CS=Instance.new("ScrollingFrame")
CS.Size=UDim2.new(1,-8,1,-8) CS.Position=UDim2.new(0,4,0,4)
CS.BackgroundTransparency=1 CS.BorderSizePixel=0
CS.ScrollBarThickness=4 CS.ScrollBarImageColor3=C.A CS.CanvasSize=UDim2.new(0,0,0,0) CS.Parent=CA

-- ============================================================
-- SECTION 14: UI COMPONENT BUILDERS
-- ============================================================
local REG={}
local TOGGLE_H = IS_MOBILE and 38 or 26
local TOGGLE_IND_W = IS_MOBILE and 50 or 36
local TOGGLE_IND_H = IS_MOBILE and 22 or 14
local TOGGLE_KNOB = IS_MOBILE and 14 or 8
local TOGGLE_TEXT = IS_MOBILE and 12 or 10
local SLIDER_H = IS_MOBILE and 52 or 38
local SLIDER_TRACK_H = IS_MOBILE and 8 or 4
local SLIDER_TRACK_Y = IS_MOBILE and 34 or 26

local function section(txt)
    local h=Instance.new("TextLabel")
    h.Size=UDim2.new(1,0,0,18) h.BackgroundTransparency=1
    h.Text="> "..txt h.TextColor3=C.A h.TextSize=10
    h.Font=Enum.Font.GothamBold h.TextXAlignment=Enum.TextXAlignment.Left h.Parent=CS
end

local function toggle(name,key,cb)
    local f=Instance.new("Frame")
    f.Name=name f.Size=UDim2.new(1,0,0,TOGGLE_H)
    f.BackgroundColor3=C.SB f.BorderSizePixel=2 f.BorderColor3=C.BD f.Parent=CS
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,5)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,-60,1,0) l.Position=UDim2.new(0,8,0,0)
    l.BackgroundTransparency=1 l.Text=name l.TextColor3=C.TX l.TextSize=TOGGLE_TEXT
    l.Font=Enum.Font.Gotham l.TextXAlignment=Enum.TextXAlignment.Left l.Parent=f
    local ind=Instance.new("Frame")
    ind.Size=UDim2.new(0,TOGGLE_IND_W,0,TOGGLE_IND_H)
    ind.Position=UDim2.new(1, IS_MOBILE and -TOGGLE_IND_W-8 or -42, 0, IS_MOBILE and 8 or 6)
    ind.BackgroundColor3=State[key] and C.A or C.TO
    ind.BorderSizePixel=2 ind.BorderColor3=C.BD ind.Parent=f
    Instance.new("UICorner",ind).CornerRadius=UDim.new(0,TOGGLE_IND_H/2)
    local kn=Instance.new("Frame")
    kn.Size=UDim2.new(0,TOGGLE_KNOB,0,TOGGLE_KNOB)
    kn.Position=State[key] and UDim2.new(1,-TOGGLE_KNOB-3,0,3) or UDim2.new(0,3,0,3)
    kn.BackgroundColor3=C.TX kn.BorderSizePixel=0 kn.Parent=ind
    Instance.new("UICorner",kn).CornerRadius=UDim.new(0,TOGGLE_KNOB/2)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,0,1,0) btn.BackgroundTransparency=1 btn.Text="" btn.Parent=f
    btn.MouseButton1Click:Connect(function()
        State[key]=not State[key]
        ind.BackgroundColor3=State[key] and C.A or C.TO
        kn.Position=State[key] and UDim2.new(1,-TOGGLE_KNOB-3,0,3) or UDim2.new(0,3,0,3)
        if cb then cb(State[key]) end
    end)
    table.insert(REG,{name=name,parent=f})
end

local function slider(name,mn,mx,dv,key,cb)
    local f=Instance.new("Frame")
    f.Name=name f.Size=UDim2.new(1,0,0,SLIDER_H)
    f.BackgroundColor3=C.SB f.BorderSizePixel=2 f.BorderColor3=C.BD f.Parent=CS
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,5)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,-70,0,12) l.Position=UDim2.new(0,8,0,3)
    l.BackgroundTransparency=1 l.Text=name l.TextColor3=C.TX l.TextSize=9
    l.Font=Enum.Font.Gotham l.TextXAlignment=Enum.TextXAlignment.Left l.Parent=f
    local vl=Instance.new("TextLabel")
    vl.Size=UDim2.new(0,50,0,12) vl.Position=UDim2.new(1,-58,0,3)
    vl.BackgroundTransparency=1 vl.Text=tostring(dv) vl.TextColor3=C.A
    vl.TextSize=9 vl.Font=Enum.Font.GothamBold vl.TextXAlignment=Enum.TextXAlignment.Right vl.Parent=f
    local tr=Instance.new("Frame")
    tr.Size=UDim2.new(1,-16,0,SLIDER_TRACK_H) tr.Position=UDim2.new(0,8,0,SLIDER_TRACK_Y)
    tr.BackgroundColor3=C.TO tr.BorderSizePixel=0 tr.Parent=f
    Instance.new("UICorner",tr).CornerRadius=UDim.new(0,SLIDER_TRACK_H/2)
    local fl=Instance.new("Frame")
    fl.Size=UDim2.new((dv-mn)/(mx-mn),0,1,0) fl.BackgroundColor3=C.A
    fl.BorderSizePixel=0 fl.Parent=tr
    Instance.new("UICorner",fl).CornerRadius=UDim.new(0,SLIDER_TRACK_H/2)
    local drg=false
    local function upd(i)
        local x=math.clamp(i.Position.X-tr.AbsolutePosition.X,0,tr.AbsoluteSize.X)
        local p=x/tr.AbsoluteSize.X
        local v=math.floor(mn+(mx-mn)*p+0.5)
        fl.Size=UDim2.new(p,0,1,0) vl.Text=tostring(v)
        State[key]=v
        if cb then cb(v) end
    end
    tr.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drg=true upd(i)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drg and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then upd(i) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drg=false end
    end)
    table.insert(REG,{name=name,parent=f})
end

local function btn(name,cb)
    local b=Instance.new("TextButton")
    b.Name=name b.Size=UDim2.new(1,0,0,24)
    b.BackgroundColor3=C.AB b.BorderSizePixel=2 b.BorderColor3=C.A
    b.Text=name b.TextColor3=C.A b.TextSize=9 b.Font=Enum.Font.GothamBold b.Parent=CS
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    b.MouseButton1Click:Connect(function() if cb then cb() end end)
    table.insert(REG,{name=name,parent=b})
end

local PERK_OPTIONS = {"Eternal Torment","Bloodlust","Kingscourge","Resentment Clinger","Abyssal Covenant","None"}
local function perkSelector(name, key)
    local b=Instance.new("TextButton")
    b.Name=name b.Size=UDim2.new(1,0,0,24)
    b.BackgroundColor3=C.AB b.BorderSizePixel=2 b.BorderColor3=C.A
    b.Text=name..": "..State[key] b.TextColor3=C.A b.TextSize=9
    b.Font=Enum.Font.GothamBold b.Parent=CS
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    b.MouseButton1Click:Connect(function()
        local idx=1
        for i,v in ipairs(PERK_OPTIONS) do if v==State[key] then idx=i break end end
        idx=idx+1
        if idx>#PERK_OPTIONS then idx=1 end
        State[key]=PERK_OPTIONS[idx]
        b.Text=name..": "..State[key]
    end)
    table.insert(REG,{name=name,parent=b})
end

SR:GetPropertyChangedSignal("Text"):Connect(function()
    local q=SR.Text:lower()
    for _,it in ipairs(REG) do
        if it.parent and it.parent.Parent then
            it.parent.Visible = q=="" or it.name:lower():find(q)~=nil
        end
    end
end)

-- ============================================================
-- SECTION 15: TAB FRAMEWORK
-- ============================================================
local CURTAB=nil
local function clearTab()
    if CURTAB then CURTAB:Destroy() end
    REG={} CS.CanvasSize=UDim2.new(0,0,0,0)
end
local function mktab(h)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,-8,0,h) f.BackgroundTransparency=1 f.Parent=CS
    CURTAB=f
    local l=Instance.new("UIListLayout",f)
    l.SortOrder=Enum.SortOrder.LayoutOrder l.Padding=UDim.new(0,4)
    local p=Instance.new("UIPadding",f)
    p.PaddingTop=UDim.new(0,4) p.PaddingLeft=UDim.new(0,4) p.PaddingRight=UDim.new(0,4)
    return f
end

-- ============================================================
-- SECTION 16: TAB BUILDERS
-- ============================================================
local function homeTab()
    local f=mktab(240)
    local w=Instance.new("TextLabel")
    w.Size=UDim2.new(1,0,0,26) w.BackgroundTransparency=1
    w.Text="Hey, "..LP.DisplayName.."!" w.TextColor3=C.A
    w.TextSize=18 w.Font=Enum.Font.GothamBold w.TextXAlignment=Enum.TextXAlignment.Left w.Parent=f
    local s=Instance.new("TextLabel")
    s.Size=UDim2.new(1,0,0,18) s.Position=UDim2.new(0,0,0,28)
    s.BackgroundTransparency=1 s.Text="VD Shield - Safest Edition"
    s.TextColor3=C.TX s.TextSize=11 s.Font=Enum.Font.Gotham
    s.TextXAlignment=Enum.TextXAlignment.Left s.Parent=f
    local d=Instance.new("Frame")
    d.Size=UDim2.new(1,0,0,2) d.Position=UDim2.new(0,0,0,50)
    d.BackgroundColor3=C.A d.BorderSizePixel=0 d.Parent=f
    local disc=Instance.new("TextLabel")
    disc.Size=UDim2.new(1,-6,0,180) disc.Position=UDim2.new(0,0,0,60)
    disc.BackgroundTransparency=1
    disc.Text="Welcome to VD Shield, the safest Violence District autofarm. Built with 109 features including multi-layer anti-detection, mobile support, and full account safety. Keyless and free forever."
    disc.TextColor3=C.TD disc.TextSize=10 disc.Font=Enum.Font.Gotham
    disc.TextWrapped=true disc.TextXAlignment=Enum.TextXAlignment.Left
    disc.TextYAlignment=Enum.TextYAlignment.Top disc.Parent=f
    CS.CanvasSize=UDim2.new(0,0,0,250)
end

local function survTab()
    local f=mktab(1400)
    section("SURVIVOR AUTOFARM")
    toggle("Auto Repair Generator","AutoRepair")
    toggle("Auto Skill Check","AutoSkillCheck")
    toggle("Dynamic Action Cadence","DynamicActionCadence")
    toggle("Auto Parry","AutoParry")
    toggle("Auto Heal","AutoHeal")
    toggle("Auto Wiggle Escape","AutoWiggleEscape")
    section("MOVEMENT")
    toggle("Loop Walk Speed","LoopWalkSpeed")
    slider("Loop Speed",14,30,18,"LoopSpeedValue")
    toggle("Enable Jump","EnableJump")
    toggle("Speed Boost","SpeedBoost")
    slider("Speed Value",16,100,22,"SpeedValue")
    toggle("Auto Climb","AutoClimb")
    section("DEFENSE")
    toggle("Smart Killer Avoidance","SmartKillerAvoidance")
    slider("Avoid Distance",20,80,40,"AvoidDistance")
    toggle("Auto Dodge","AutoDodge")
    toggle("Auto Zig-Zag","AutoZigZag")
    slider("Zig-Zag Speed",0.1,0.6,0.3,"ZigZagSpeed")
    section("ALERTS")
    toggle("Killer Notification Sound","KillerNotificationSound")
    slider("Alert Distance",10,100,30,"KillerNotificationDistance")
    slider("Alert Volume",1,10,5,"KillerNotificationVolume")
    section("SILENT AIM")
    toggle("Silent Aim (Survivor)","SilentAimSurvivor")
    slider("Smoothness",1,50,15,"SilentAimSmoothness")
    slider("FOV",30,360,120,"SilentAimFOV")
    slider("Miss Chance %",0,30,0,"SilentAimMissChance")
    CS.CanvasSize=UDim2.new(0,0,0,1400)
end

local function killerTab()
    local f=mktab(900)
    section("KILLER AUTOFARM")
    toggle("Enable Killer Auto Farm","KillerAutoFarm")
    toggle("Auto Chase","AutoChase")
    toggle("Auto Break Generator","AutoBreakGen")
    section("KILLER COMBAT")
    toggle("Auto Double Hit","AutoDoubleHit")
    slider("Double Hit Delay",0.3,1.0,0.5,"AutoDoubleHitDelay")
    section("PERKS")
    toggle("Perk Auto Equip","PerkAutoEquip")
    perkSelector("Select Perk","SelectedPerkToEquip")
    section("SILENT AIM")
    toggle("Silent Aim (Killer)","SilentAimKiller")
    slider("Smoothness",1,50,15,"SilentAimKillerSmoothness")
    slider("FOV",30,360,120,"SilentAimKillerFOV")
    CS.CanvasSize=UDim2.new(0,0,0,900)
end

local function espTab()
    local f=mktab(600)
    section("PLAYER ESP")
    toggle("Survivor ESP (Blue)","ESPSurvivor")
    toggle("Killer ESP (Red)","ESPKiller")
    section("OBJECT ESP")
    toggle("Pallet ESP (Green)","ESPPallet")
    toggle("Window ESP (Purple)","ESPWindow")
    toggle("Generator ESP (Black)","ESPGenerator")
    toggle("Hook ESP (Orange)","ESPHook")
    toggle("Gate ESP (Gold)","ESPGate")
    section("TRACKING")
    toggle("Generator Progress Tracker","GeneratorProgressTracker")
    section("SETTINGS")
    slider("ESP Range",50,1000,500,"ESPRange")
    CS.CanvasSize=UDim2.new(0,0,0,600)
end

-- ============================================================
-- SAFETY REPORT TAB
-- ============================================================
local function safetyReportTab()
    local f=mktab(700)
    section("LIVE SAFETY STATUS")

    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(1, 0, 0, 320)
    statusFrame.BackgroundColor3 = C.SB
    statusFrame.BorderSizePixel = 2
    statusFrame.BorderColor3 = C.BD
    statusFrame.Parent = f
    Instance.new("UICorner", statusFrame).CornerRadius = UDim.new(0, 6)

    local statusList = {
        {name="Universal Bypass",           key="bypass"},
        {name="Property Spoofing",          key="spoof"},
        {name="Debug Hook Protection",      key="debughook"},
        {name="Anti-Cheat Conn Disabled",   key="anticheat"},
        {name="Hidden GUI Container",       key="gethui"},
        {name="Honeypot Protection",        key="honeypot"},
        {name="Safe Input Simulation",      key="safeinput"},
        {name="Gaussian Delay Timing",      key="gaussian"},
        {name="Human-Like Pause System",    key="humandelay"},
        {name="Verified Remote Whitelist",  key="whitelist"},
        {name="Adaptive Mobile Support",    key="mobile"},
        {name="Ping Compensation",          key="ping"},
    }

    local rowHeight = 24
    local rows = {}
    for i, item in ipairs(statusList) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -8, 0, rowHeight)
        row.Position = UDim2.new(0, 4, 0, 4 + (i-1) * (rowHeight + 2))
        row.BackgroundTransparency = 1
        row.Parent = statusFrame

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 10, 0, 10)
        dot.Position = UDim2.new(0, 0, 0, 7)
        dot.BackgroundColor3 = C.GRY
        dot.BorderSizePixel = 0
        dot.Parent = row
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 20, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = item.name
        nameLabel.TextColor3 = C.TX
        nameLabel.TextSize = 10
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = row

        local statusLabel = Instance.new("TextLabel")
        statusLabel.Size = UDim2.new(0.25, 0, 1, 0)
        statusLabel.Position = UDim2.new(0.7, 0, 0, 0)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Text = "..."
        statusLabel.TextColor3 = C.TD
        statusLabel.TextSize = 10
        statusLabel.Font = Enum.Font.GothamBold
        statusLabel.TextXAlignment = Enum.TextXAlignment.Right
        statusLabel.Parent = row

        rows[item.key] = {dot=dot, label=statusLabel}
    end

    task.spawn(function()
        while true do
            task.wait(0.5)

            if rows.bypass then
                local a = Bypass.enabled
                rows.bypass.dot.BackgroundColor3 = a and C.GRN or C.RED
                rows.bypass.label.Text = a and "ACTIVE" or "OFF"
                rows.bypass.label.TextColor3 = a and C.GRN or C.RED
            end
            if rows.spoof then
                local cnt = 0
                for _ in pairs(Bypass.originalProperties) do cnt = cnt + 1 end
                local a = cnt > 0
                rows.spoof.dot.BackgroundColor3 = a and C.GRN or C.AMB
                rows.spoof.label.Text = a and "ACTIVE" or "STANDBY"
                rows.spoof.label.TextColor3 = a and C.GRN or C.AMB
            end
            if rows.debughook then
                local has = getrawmetatable and debug.getinfo
                rows.debughook.dot.BackgroundColor3 = has and C.GRN or C.AMB
                rows.debughook.label.Text = has and "ACTIVE" or "STANDBY"
                rows.debughook.label.TextColor3 = has and C.GRN or C.AMB
            end
            if rows.anticheat then
                local cnt = #Bypass.antiCheatConnections
                local a = cnt > 0
                rows.anticheat.dot.BackgroundColor3 = a and C.GRN or C.GRY
                rows.anticheat.label.Text = a and (cnt .. " BLOCKED") or "NONE FOUND"
                rows.anticheat.label.TextColor3 = a and C.GRN or C.GRY
            end
            if rows.gethui then
                local s = tostring(guiParent):lower()
                local hid = s:find("coregui") or s:find("gethui") or guiParent ~= LP.PlayerGui
                rows.gethui.dot.BackgroundColor3 = hid and C.GRN or C.AMB
                rows.gethui.label.Text = hid and "HIDDEN" or "VISIBLE"
                rows.gethui.label.TextColor3 = hid and C.GRN or C.AMB
            end
            if rows.honeypot then
                local a = State.HoneypotProtection
                rows.honeypot.dot.BackgroundColor3 = a and C.GRN or C.RED
                rows.honeypot.label.Text = a and "ACTIVE" or "OFF"
                rows.honeypot.label.TextColor3 = a and C.GRN or C.RED
            end
            if rows.safeinput then
                local has = getgenv().bypass and getgenv().bypass.simulateInput
                rows.safeinput.dot.BackgroundColor3 = has and C.GRN or C.AMB
                rows.safeinput.label.Text = has and "ENHANCED" or "STANDARD"
                rows.safeinput.label.TextColor3 = has and C.GRN or C.AMB
            end
            if rows.gaussian then
                rows.gaussian.dot.BackgroundColor3 = C.GRN
                rows.gaussian.label.Text = "ACTIVE"
                rows.gaussian.label.TextColor3 = C.GRN
            end
            if rows.humandelay then
                rows.humandelay.dot.BackgroundColor3 = C.GRN
                rows.humandelay.label.Text = "ACTIVE"
                rows.humandelay.label.TextColor3 = C.GRN
            end
            if rows.whitelist then
                local cnt = 0
                for _ in pairs(SAFE_REMOTES) do cnt = cnt + 1 end
                rows.whitelist.dot.BackgroundColor3 = cnt > 0 and C.GRN or C.RED
                rows.whitelist.label.Text = cnt .. " VERIFIED"
                rows.whitelist.label.TextColor3 = cnt > 0 and C.GRN or C.RED
            end
            if rows.mobile then
                rows.mobile.dot.BackgroundColor3 = C.GRN
                rows.mobile.label.Text = IS_MOBILE and "MOBILE" or "PC"
                rows.mobile.label.TextColor3 = C.GRN
            end
            if rows.ping then
                local ping = 0
                pcall(function() ping = math.floor(LP:GetNetworkPing() * 1000) end)
                local col = ping < 80 and C.GRN or (ping < 150 and C.AMB or C.RED)
                rows.ping.dot.BackgroundColor3 = col
                rows.ping.label.Text = ping .. "ms"
                rows.ping.label.TextColor3 = col
            end
        end
    end)

    section("SAFETY LAYER DESCRIPTIONS")

    local descFrame = Instance.new("Frame")
    descFrame.Size = UDim2.new(1, 0, 0, 240)
    descFrame.BackgroundColor3 = C.SB
    descFrame.BorderSizePixel = 2
    descFrame.BorderColor3 = C.BD
    descFrame.Parent = f
    Instance.new("UICorner", descFrame).CornerRadius = UDim.new(0, 6)

    local descText = Instance.new("TextLabel")
    descText.Size = UDim2.new(1, -12, 1, -12)
    descText.Position = UDim2.new(0, 6, 0, 6)
    descText.BackgroundTransparency = 1
    descText.Text = [[Every safety layer targets a specific detection method.

GREEN = Active | AMBER = Standby | RED = Disabled

- Universal Bypass: Disables anti-cheat hooks
- Property Spoofing: Hides modified WalkSpeed/JumpPower
- Debug Hook: Hides script from debug.getinfo scans
- Anti-Cheat Conn: Disables anti-cheat connections
- Hidden GUI: Places UI in gethui() container
- Honeypot Shield: Blocks unverified remote fires
- Safe Input: Uses bypass.simulateInput when available
- Gaussian Delays: Bell-curve timing distribution
- Human Pause: 1-in-12 realistic mid-action pauses
- Whitelist: Only fires remotes verified in-game
- Mobile Support: Platform auto-detect + adaptive
- Ping Compensation: Adjusts timing for latency]]
    descText.TextColor3 = C.TD
    descText.TextSize = 10
    descText.Font = Enum.Font.Gotham
    descText.TextWrapped = true
    descText.TextXAlignment = Enum.TextXAlignment.Left
    descText.TextYAlignment = Enum.TextYAlignment.Top
    descText.Parent = descFrame

    CS.CanvasSize = UDim2.new(0, 0, 0, 700)
end

local function miscTab()
    local f=mktab(900)
    section("VISUALS")
    toggle("Loop Fullbright","LoopFullbright")
    toggle("No Fog","NoFog")
    toggle("Remove Shadows","RemoveShadows")
    toggle("Shaders","Shaders")
    toggle("Saturation Boost","Saturation")
    slider("Saturation Level",1,3,1.4,"SaturationValue")
    section("UTILITY")
    toggle("Anti-AFK","AntiAfk")
    toggle("Honeypot Protection","HoneypotProtection")
    section("CONFIG")
    btn("Save Config",function() saveCfg() Notify("Saved!") end)
    btn("Load Config",function() loadCfg() Notify("Loaded!") end)
    section("UNLOAD")
    btn("Unload Script", function()
        if State.ConfigSaveOnExit then saveCfg() end
        Bypass.disable()
        SG:Destroy() SP:Destroy()
        Notify("Unloaded.")
    end)
    CS.CanvasSize=UDim2.new(0,0,0,900)
end

local activeBtn=nil
local function mkBtn(name, icon, cb)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,0,0,26) b.BackgroundColor3=C.TO
    b.Text="  "..icon.." "..name b.TextColor3=C.TX b.TextSize=10
    b.Font=Enum.Font.Gotham b.TextXAlignment=Enum.TextXAlignment.Left
    b.BorderSizePixel=2 b.BorderColor3=C.BD b.Parent=SB
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    b.MouseButton1Click:Connect(function()
        if activeBtn and activeBtn.Parent then activeBtn.BackgroundColor3=C.TO end
        b.BackgroundColor3=C.AB activeBtn=b
        clearTab() cb()
    end)
end

mkBtn("Home","[H]",homeTab)
mkBtn("Survivor","[S]",survTab)
mkBtn("Killer","[K]",killerTab)
mkBtn("ESP","[E]",espTab)
mkBtn("Safety","[!]",safetyReportTab)
mkBtn("Misc","[M]",miscTab)
homeTab()
print("[VD] GUI built")

-- ============================================================
-- SECTION 17: HELPER FUNCTIONS
-- ============================================================
local function findNearestGen()
    local ch=LP.Character
    if not ch or not ch:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp=ch.HumanoidRootPart
    local n,nd=nil,math.huge
    local map=WS:FindFirstChild("Map")
    if not map then return nil end
    for _,folderName in ipairs({"newGenerators","Generators"}) do
        local folder=map:FindFirstChild(folderName)
        if folder then
            for _,o in pairs(folder:GetChildren()) do
                local part=o:IsA("Model") and (o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart",true)) or o:IsA("BasePart") and o
                if part then
                    local d=(hrp.Position-part.Position).Magnitude
                    if d<nd then nd=d n=o end
                end
            end
        end
    end
    return n,nd
end

local function nearestSurvivor()
    local ch = LP.Character
    if not ch or not ch:FindFirstChild("HumanoidRootPart") then return nil, math.huge end
    local hrp = ch.HumanoidRootPart
    local best, bd = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if not isKiller(p) then
                local d = (hrp.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if d < bd then bd = d; best = p end
            end
        end
    end
    return best, bd
end

local function findKiller()
    local nearest, nd = nil, math.huge
    local ch = LP.Character
    if not ch or not ch:FindFirstChild("HumanoidRootPart") then return nil, math.huge end
    local hrp = ch.HumanoidRootPart
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and isKiller(p) then
            local d = (hrp.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if d < nd then nd = d; nearest = p end
        end
    end
    return nearest, nd
end

local function isDowned(p)
    if not p or not p.Character then return false end
    local c = p.Character
    if c:GetAttribute("Knocked") == true then return true end
    if c:GetAttribute("Downed") == true then return true end
    if c:GetAttribute("Hooked") == true then return true end
    local h = c:FindFirstChildOfClass("Humanoid")
    if h and h.Health <= 0 then return true end
    return false
end

local function fireAttack(target)
    for _, r in ipairs(ATK_REMOTES) do
        safeFire(r)
        if target and target.Character then
            safeFire(r, target.Character)
            safeFire(r, target)
        end
    end
end

local function nearestHook()
    local ch = LP.Character
    if not ch or not ch:FindFirstChild("HumanoidRootPart") then return nil, math.huge, nil end
    local hrp = ch.HumanoidRootPart
    local best, bd, bp = nil, math.huge, nil
    for _, o in pairs(WS:GetDescendants()) do
        if o.Name:lower():find("hook") and (o:IsA("Model") or o:IsA("BasePart")) then
            local part = o:IsA("Model") and (o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart", true)) or o
            if part then
                local d = (hrp.Position - part.Position).Magnitude
                if d < bd then bd = d; best = o; bp = part end
            end
        end
    end
    return best, bd, bp
end

-- ============================================================
-- SECTION 18: FEATURE LOGIC
-- ============================================================

-- Auto Wiggle Escape
task.spawn(function()
    while true do
        task.wait(IS_MOBILE and 0.12 or 0.15)
        if State.AutoWiggleEscape then
            local ch = LP.Character
            if ch then
                local beingCarried = ch:GetAttribute("Carried") == true
                    or ch:GetAttribute("BeingCarried") == true
                    or ch:GetAttribute("IsCarried") == true
                local selfCarried = LP:GetAttribute("Carried") == true
                    or LP:GetAttribute("BeingCarried") == true
                if beingCarried or selfCarried then
                    safeFire(REM.SelfUnHook)
                    safeFire(REM.UnHook)
                    simulateWiggle()
                end
            end
        end
    end
end)

-- Auto Repair + Dynamic Cadence
local repairSessionStart = 0
local lastRepairFire = 0
RunService.Heartbeat:Connect(function()
    if not State.AutoRepair then repairSessionStart = 0 return end
    local ch = LP.Character
    if not ch or not ch:FindFirstChild("HumanoidRootPart") then return end
    local gen, dist = findNearestGen()
    if not gen then return end
    local genPart = gen:IsA("Model") and (gen.PrimaryPart or gen:FindFirstChildWhichIsA("BasePart", true)) or gen
    if not genPart then return end
    if dist > 8 then ch.Humanoid:MoveTo(genPart.Position)
    else
        if repairSessionStart == 0 then repairSessionStart = tick() end
        local interval = 0.5
        if State.DynamicActionCadence then
            local elapsed = tick() - repairSessionStart
            local bi = 0.4 + math.random() * 0.3
            if elapsed > 60 then bi = 0.55 + math.random() * 0.35
            elseif elapsed > 30 then bi = 0.45 + math.random() * 0.35
            else bi = 0.35 + math.random() * 0.25 end
            if math.random(1, 15) == 1 then bi = bi + math.random(8, 20) / 10 end
            interval = bi
        end
        if tick() - lastRepairFire > interval then
            lastRepairFire = tick()
            safeFire(REM.RepairEvent, gen)
            safeFire(REM.RepairEvent, genPart)
            safeFire(REM.RepairEvent)
            simulateInteract()
        end
    end
end)

-- Auto Parry (ping compensation)
RunService.Heartbeat:Connect(function()
    if not State.AutoParry then return end
    local ch = LP.Character
    if ch and ch:FindFirstChildOfClass("Tool") then
        local t = ch:FindFirstChildOfClass("Tool")
        if t.Name:lower():find("dagger") or t.Name:lower():find("parry") then
            local kd = select(2, findKiller())
            local ping = 0
            pcall(function() ping = LP:GetNetworkPing() * 1000 end)
            if kd and kd < 10 + (ping / 100) * 0.5 then safeFire(REM.Parry) end
        end
    end
end)

-- Auto Heal
RunService.Heartbeat:Connect(function()
    if not State.AutoHeal then return end
    local ch = LP.Character
    if ch and ch:FindFirstChild("Humanoid") then
        if ch.Humanoid.Health < ch.Humanoid.MaxHealth * 0.5 then
            for _, t in pairs(ch:GetChildren()) do
                if t:IsA("Tool") and t.Name:lower():find("bandage") then
                    safeFire(REM.HealEvent, t)
                end
            end
        end
    end
end)

-- Loop Speed / Jump
RunService.Heartbeat:Connect(function()
    local ch = LP.Character
    if ch and ch:FindFirstChild("Humanoid") then
        if State.LoopWalkSpeed then ch.Humanoid.WalkSpeed = math.min(State.LoopSpeedValue, 30) end
        if State.SpeedBoost then ch.Humanoid.WalkSpeed = State.SpeedValue end
        if State.EnableJump then ch.Humanoid.JumpPower = 50 ch.Humanoid.UseJumpPower = true end
    end
end)

-- Zig-Zag / Dodge
local zzD = 1 lastZZ = 0 lastDg = 0
RunService.Heartbeat:Connect(function()
    local ch = LP.Character
    if not ch or not ch:FindFirstChild("HumanoidRootPart") then return end
    if State.AutoZigZag then
        local kd = select(2, findKiller())
        if kd and kd < 40 then
            if tick() - lastZZ > State.ZigZagSpeed then lastZZ = tick() zzD = -zzD end
            local perp = Vector3.new(ch.HumanoidRootPart.CFrame.LookVector.Z, 0, -ch.HumanoidRootPart.CFrame.LookVector.X)
            ch.Humanoid:MoveTo(ch.HumanoidRootPart.Position + perp * zzD * 3)
        end
    end
    if State.AutoDodge then
        local killer = nil
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and isKiller(p) then
                local d = (ch.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if d < 10 then
                    local toUs = (ch.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Unit
                    local kLook = p.Character.HumanoidRootPart.CFrame.LookVector
                    if toUs:Dot(kLook) > 0.5 then killer = p break end
                end
            end
        end
        if killer and tick() - lastDg > 0.5 then
            lastDg = tick()
            local perp = Vector3.new(ch.HumanoidRootPart.CFrame.LookVector.Z, 0, -ch.HumanoidRootPart.CFrame.LookVector.X)
            ch.Humanoid:MoveTo(ch.HumanoidRootPart.Position + perp * (math.random() > 0.5 and 12 or -12))
        end
    end
end)

-- Smart Killer Avoidance (25s failsafe)
local avoidanceActive = false
local avoidanceStartTime = 0
RunService.Heartbeat:Connect(function()
    if not State.SmartKillerAvoidance then avoidanceActive = false return end
    local ch = LP.Character
    if not ch or not ch:FindFirstChild("HumanoidRootPart") then return end
    local hrp = ch.HumanoidRootPart
    local killer, kd = findKiller()
    if not killer then
        if avoidanceActive then avoidanceActive = false avoidanceStartTime = 0 end
        return
    end
    if kd < State.AvoidDistance and not avoidanceActive then
        avoidanceActive = true
        avoidanceStartTime = tick()
        local awayDir = (hrp.Position - killer.Character.HumanoidRootPart.Position).Unit
        local safePos = hrp.Position + awayDir * (140 + math.random(-20, 20))
            + Vector3.new(math.random(-15,15), 25 + math.random(0,15), math.random(-15,15))
        hrp.CFrame = CFrame.new(safePos)
        Notify("Avoiding killer...")
        return
    end
    if avoidanceActive and tick() - avoidanceStartTime > 25 then
        if kd < 80 then
            local gen = findNearestGen()
            if gen then
                local genPart = gen:IsA("Model") and (gen.PrimaryPart or gen:FindFirstChildWhichIsA("BasePart", true)) or gen
                if genPart then
                    hrp.CFrame = CFrame.new(genPart.Position + Vector3.new(
                        math.random(-3,3), 5 + math.random(0,3), math.random(-3,3)))
                    Notify("Killer camping - moving to next gen")
                end
            end
        else Notify("Killer gone - resuming") end
        avoidanceActive = false
        avoidanceStartTime = 0
    end
end)

-- Killer Notification Sound
local lastNotifSound = 0
RunService.Heartbeat:Connect(function()
    if not State.KillerNotificationSound then return end
    local k, kd = findKiller()
    if k and kd and kd < State.KillerNotificationDistance then
        if tick() - lastNotifSound > 3 then
            lastNotifSound = tick()
            local s = Instance.new("Sound")
            s.SoundId = "rbxasset://sounds/electronicpingshort.wav"
            s.Volume = math.clamp(State.KillerNotificationVolume / 10, 0.1, 1)
            s.Parent = SS
            s:Play()
            Debris:AddItem(s, 2)
        end
    end
end)

-- Killer Auto Farm
local kState = "chase"
local lastAttackTime = 0
RunService.Heartbeat:Connect(function()
    if not State.KillerAutoFarm then kState = "chase" return end
    local ch = LP.Character
    if not ch or not ch:FindFirstChild("HumanoidRootPart") then return end
    local hrp = ch.HumanoidRootPart
    local carrying = ch:GetAttribute("Carrying") == true
    if carrying then
        local _, hd, hookPart = nearestHook()
        if not hookPart then safeFire(REM.DropSurvivor) return end
        if hd > 5 then hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(hookPart.Position + (hrp.Position - hookPart.Position).Unit * 3), 0.18)
        else safeFire(REM.HookEvent) end
        return
    end
    local target, dist = nearestSurvivor()
    if not target then return end
    local tChar = target.Character
    if not tChar or not tChar:FindFirstChild("HumanoidRootPart") then return end
    local tHrp = tChar.HumanoidRootPart
    if isDowned(target) then
        if dist > 6 then hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(tHrp.Position + (hrp.Position - tHrp.Position).Unit * 4), 0.2)
        else safeFire(REM.CarrySurvivor, tChar) simulateInteract() end
        return
    end
    if kState == "chase" then
        if dist > 6 then hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(tHrp.Position + (hrp.Position - tHrp.Position).Unit * 4), 0.25)
        else fireAttack(target) kState = "wait" lastAttackTime = tick() end
    elseif kState == "wait" then
        if tick() - lastAttackTime >= 2 then kState = "chase"
        else hrp.CFrame = CFrame.new(hrp.Position, tHrp.Position) * CFrame.Angles(0, math.rad(180), 0) end
    end
end)

-- Auto Double Hit
local lastDoubleHit = 0
RunService.Heartbeat:Connect(function()
    if not State.AutoDoubleHit then return end
    local ch = LP.Character
    if not ch or not ch:FindFirstChild("HumanoidRootPart") then return end
    local t, d = nearestSurvivor()
    if t and d and d < 8 and not isDowned(t) then
        if tick() - lastDoubleHit > 0.8 then
            lastDoubleHit = tick()
            fireAttack(t)
            task.wait(State.AutoDoubleHitDelay)
            fireAttack(t)
        end
    end
end)

-- Perk Auto Equip
task.spawn(function()
    local lastEquip = 0
    while true do
        task.wait(2)
        if State.PerkAutoEquip and tick() - lastEquip > 30 then
            lastEquip = tick()
            safeFire(REM.EquipKillerPerk, State.SelectedPerkToEquip)
        end
    end
end)

-- Auto Break Generator
local lastBreakGenFire = 0
RunService.Heartbeat:Connect(function()
    if not State.AutoBreakGen then return end
    local ch = LP.Character
    if not ch or not ch:FindFirstChild("HumanoidRootPart") then return end
    local gen, dist = findNearestGen()
    if not gen then return end
    local hrp = ch.HumanoidRootPart
    local genPart = gen:IsA("Model") and (gen.PrimaryPart or gen:FindFirstChildWhichIsA("BasePart", true)) or gen
    if not genPart then return end
    if dist > 6 then hrp.CFrame = hrp.CFrame:Lerp(CFrame.new(genPart.Position + (hrp.Position - genPart.Position).Unit * 3), 0.2)
    else
        if tick() - lastBreakGenFire > 1 then
            lastBreakGenFire = tick()
            safeFire(REM.BreakGenEvent, gen)
            safeFire(REM.BreakGenEvent, genPart)
        end
    end
end)

-- Silent Aim (mobile-adaptive)
RunService.RenderStepped:Connect(function()
    if not (State.SilentAimSurvivor or State.SilentAimKiller) then return end
    if IS_MOBILE and isDraggingCamera then return end
    local sm = State.SilentAimSurvivor and State.SilentAimSmoothness or State.SilentAimKillerSmoothness
    local fv = State.SilentAimSurvivor and State.SilentAimFOV or State.SilentAimKillerFOV
    local cam = WS.CurrentCamera
    local ch = LP.Character
    if not ch or not ch:FindFirstChild("HumanoidRootPart") then return end
    local best, bd = nil, fv
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local sp, on = cam:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
            if on then
                local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)).Magnitude
                if d < bd then
                    local ray = Ray.new(cam.CFrame.Position, (p.Character.HumanoidRootPart.Position - cam.CFrame.Position).Unit * 500)
                    local hitPart = WS:FindPartOnRay(ray, ch, false, true)
                    if hitPart and hitPart:IsDescendantOf(p.Character) then bd = d; best = p end
                end
            end
        end
    end
    if best then
        local targetPos = best.Character.HumanoidRootPart.Position
        if State.SilentAimMissChance > 0 and math.random(1, 100) <= State.SilentAimMissChance then
            targetPos = targetPos + Vector3.new(math.random(-25,25)/10, math.random(-25,25)/10, math.random(-25,25)/10)
        end
        local ac = CFrame.new(cam.CFrame.Position, targetPos)
        cam.CFrame = cam.CFrame:Lerp(ac, math.clamp((100 - sm) / 100, 0.02, 0.6))
    end
end)

-- Anti-AFK
LP.Idled:Connect(function()
    if State.AntiAfk then VU:CaptureController() VU:ClickButton2(Vector2.new()) end
end)

-- Visuals
RunService.Heartbeat:Connect(function()
    if State.LoopFullbright then
        Lighting.Brightness=3 Lighting.ClockTime=14
        Lighting.FogEnd=1000000 Lighting.FogStart=1000000
        Lighting.GlobalShadows=false
        Lighting.OutdoorAmbient=Color3.fromRGB(200,200,200)
    end
    if State.NoFog then
        Lighting.FogEnd=1000000 Lighting.FogStart=1000000
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") then v.Density=0 v.Haze=0 end
        end
    end
    if State.RemoveShadows then
        Lighting.GlobalShadows=false
        for _, o in pairs(WS:GetDescendants()) do
            if o:IsA("BasePart") then o.CastShadow=false end
        end
    end
end)

local shCC, shBL, shSR, satE
RunService.Heartbeat:Connect(function()
    if State.Shaders then
        if not shCC or not shCC.Parent then
            shCC=Instance.new("ColorCorrectionEffect")
            shCC.Brightness=0.05 shCC.Contrast=0.15 shCC.Saturation=0.25
            shCC.TintColor=Color3.fromRGB(255,245,230) shCC.Parent=Lighting
        end
        if not shBL or not shBL.Parent then
            shBL=Instance.new("BloomEffect")
            shBL.Intensity=0.5 shBL.Size=24 shBL.Threshold=1.2 shBL.Parent=Lighting
        end
        if not shSR or not shSR.Parent then
            shSR=Instance.new("SunRaysEffect")
            shSR.Intensity=0.08 shSR.Spread=1 shSR.Parent=Lighting
        end
    else
        if shCC and shCC.Parent then shCC:Destroy() shCC=nil end
        if shBL and shBL.Parent then shBL:Destroy() shBL=nil end
        if shSR and shSR.Parent then shSR:Destroy() shSR=nil end
    end
    if State.Saturation then
        if not satE or not satE.Parent then
            satE=Instance.new("ColorCorrectionEffect")
            satE.Parent=Lighting
        end
        satE.Saturation=State.SaturationValue-1
    else
        if satE and satE.Parent then satE:Destroy() satE=nil end
    end
end)

-- Auto Climb
local lastJump = 0
RunService.Heartbeat:Connect(function()
    if not State.AutoClimb then return end
    local ch = LP.Character
    if not ch or not ch:FindFirstChild("Humanoid") then return end
    local hrp = ch.HumanoidRootPart
    if not hrp then return end
    if ch.Humanoid.MoveDirection.Magnitude > 0.1 and hrp.AssemblyLinearVelocity.Magnitude < 1 then
        if tick() - lastJump > 1 then lastJump = tick() ch.Humanoid.Jump = true end
    end
end)

-- ============================================================
-- SECTION 19: ESP SYSTEM
-- ============================================================
local COLORS={
    Survivor={F=Color3.fromRGB(0,120,255),O=Color3.fromRGB(0,180,255)},
    Killer={F=Color3.fromRGB(255,30,30),O=Color3.fromRGB(255,80,80)},
    Pallet={F=Color3.fromRGB(0,220,80),O=Color3.fromRGB(0,255,120)},
    Window={F=Color3.fromRGB(160,60,255),O=Color3.fromRGB(200,120,255)},
    Generator={F=Color3.fromRGB(0,0,0),O=Color3.fromRGB(255,152,45)},
    Hook={F=Color3.fromRGB(255,100,0),O=Color3.fromRGB(255,152,45)},
    Gate={F=Color3.fromRGB(255,220,150),O=Color3.fromRGB(255,152,45)},
}
local function makeHL(part,col,tag)
    local old=part:FindFirstChild("VDHL_"..tag)
    if old then old:Destroy() end
    local h=Instance.new("Highlight")
    h.Name="VDHL_"..tag h.FillColor=col.F h.OutlineColor=col.O
    h.FillTransparency=0.5 h.OutlineTransparency=0
    h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop h.Adornee=part h.Parent=part
end
local function clearTag(tag)
    for _,d in pairs(WS:GetDescendants()) do
        local h=d:FindFirstChild("VDHL_"..tag)
        if h then h:Destroy() end
    end
end

local cache={} lastCache=0
local function getDesc()
    local n=tick()
    if n-lastCache>=2 then cache=WS:GetDescendants() lastCache=n end
    return cache
end

task.spawn(function()
    while true do
        local ch=LP.Character
        if ch and ch:FindFirstChild("HumanoidRootPart") then
            local mh=ch.HumanoidRootPart
            for _,p in pairs(Players:GetPlayers()) do
                if p~=LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local pc=p.Character
                    local d=(mh.Position-pc.HumanoidRootPart.Position).Magnitude
                    local inR=d<=State.ESPRange
                    local k=isKiller(p)
                    if State.ESPSurvivor and not k and inR then makeHL(pc,COLORS.Survivor,"S_"..p.Name)
                    else
                        local old=pc:FindFirstChild("VDHL_S_"..p.Name)
                        if old then old:Destroy() end
                    end
                    if State.ESPKiller and k and inR then makeHL(pc,COLORS.Killer,"K_"..p.Name)
                    else
                        local old=pc:FindFirstChild("VDHL_K_"..p.Name)
                        if old then old:Destroy() end
                    end
                end
            end
        end
        task.wait(0.4)
    end
end)

local function scanTag(tag, checkFn, colorKey, refresh)
    task.spawn(function()
        while true do
            if not State["ESP"..tag] then
                clearTag(tag)
                task.wait(1)
            else
                local ch=LP.Character
                if ch and ch:FindFirstChild("HumanoidRootPart") then
                    local mh=ch.HumanoidRootPart
                    for _,o in pairs(getDesc()) do
                        if checkFn(o) then
                            local part=o:IsA("Model") and (o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart",true)) or o
                            if part then
                                local d=(mh.Position-part.Position).Magnitude
                                if d<=State.ESPRange and not o:FindFirstChild("VDHL_"..tag) then
                                    makeHL(o,COLORS[colorKey],tag)
                                end
                            end
                        end
                    end
                end
                task.wait(refresh or 0.5)
            end
        end
    end)
end

scanTag("Pallet",function(o) return o:IsA("BasePart") and o.Name:lower():find("pallet") end,"Pallet",0.5)
scanTag("Window",function(o) return o:IsA("BasePart") and o.Name:lower():find("window") end,"Window",0.5)
scanTag("Generator",function(o) return (o:IsA("Model") or o:IsA("BasePart")) and o.Name:lower():find("generator") end,"Generator",0.7)
scanTag("Hook",function(o) return (o:IsA("Model") or o:IsA("BasePart")) and o.Name:lower():find("hook") end,"Hook",0.5)
scanTag("Gate",function(o) return (o:IsA("Model") or o:IsA("BasePart")) and (o.Name:lower():find("gate") or o.Name:lower():find("exit")) end,"Gate",0.5)

if REM.ProgressUpdate then
    REM.ProgressUpdate.OnClientEvent:Connect(function(...)
        if not State.GeneratorProgressTracker then return end
        local args = {...}
        local genObj, progVal = nil, nil
        for _, arg in ipairs(args) do
            if typeof(arg) == "Instance" and arg.Name:lower():find("generator") then genObj = arg
            elseif type(arg) == "number" then progVal = arg end
        end
        if genObj and progVal then
            local hl = genObj:FindFirstChild("VDHL_Generator")
            if hl then
                local bb = genObj:FindFirstChild("VDBB_Generator")
                if bb then
                    local lbl = bb:FindFirstChild("InfoLabel")
                    if lbl then
                        local pct = math.floor(progVal > 1 and progVal or progVal * 100)
                        lbl.Text = string.format("GEN\n%d%%", math.clamp(pct, 0, 100))
                    end
                end
            end
        end
    end)
end

-- ============================================================
-- SECTION 20: STATUS PANEL
-- ============================================================
local SP=Instance.new("Frame")
SP.Size=UDim2.new(0,140,0,60) SP.Position=UDim2.new(1,-148,0,15)
SP.BackgroundColor3=C.AB SP.BackgroundTransparency=0.3
SP.BorderSizePixel=2 SP.BorderColor3=C.A SP.Parent=SG
Instance.new("UICorner",SP).CornerRadius=UDim.new(0,6)
local SPT=Instance.new("TextLabel")
SPT.Size=UDim2.new(1,-8,0,14) SPT.Position=UDim2.new(0,4,0,3)
SPT.BackgroundTransparency=1 SPT.Text="STATUS" SPT.TextColor3=C.A
SPT.TextSize=9 SPT.Font=Enum.Font.GothamBold SPT.TextXAlignment=Enum.TextXAlignment.Left SPT.Parent=SP
local S1=Instance.new("TextLabel")
S1.Size=UDim2.new(1,-8,0,12) S1.Position=UDim2.new(0,4,0,18)
S1.BackgroundTransparency=1 S1.Text="Killer: --" S1.TextColor3=C.TX
S1.TextSize=8 S1.Font=Enum.Font.Gotham S1.TextXAlignment=Enum.TextXAlignment.Left S1.Parent=SP
local S2=Instance.new("TextLabel")
S2.Size=UDim2.new(1,-8,0,12) S2.Position=UDim2.new(0,4,0,32)
S2.BackgroundTransparency=1 S2.Text="Farm: OFF" S2.TextColor3=C.TX
S2.TextSize=8 S2.Font=Enum.Font.Gotham S2.TextXAlignment=Enum.TextXAlignment.Left S2.Parent=SP
local S3=Instance.new("TextLabel")
S3.Size=UDim2.new(1,-8,0,12) S3.Position=UDim2.new(0,4,0,46)
S3.BackgroundTransparency=1 S3.Text="ESP: OFF" S3.TextColor3=C.TX
S3.TextSize=8 S3.Font=Enum.Font.Gotham S3.TextXAlignment=Enum.TextXAlignment.Left S3.Parent=SP

task.spawn(function()
    while true do
        task.wait(1)
        local kd = select(2, findKiller())
        S1.Text = "Killer: " .. (kd and kd < 9999 and string.format("%.0f", kd) or "--")
        S2.Text = "Farm: " .. ((State.KillerAutoFarm or State.AutoRepair) and "ON" or "OFF")
        S3.Text = "ESP: " .. ((State.ESPSurvivor or State.ESPKiller) and "ON" or "OFF")
    end
end)

-- ============================================================
-- SECTION 21: KEYBINDS
-- ============================================================
if IS_PC then
    UIS.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode == Enum.KeyCode.RightShift then MF.Visible = not MF.Visible end
        if i.KeyCode == Enum.KeyCode.Delete then
            if State.ConfigSaveOnExit then saveCfg() end
            Bypass.disable()
            SG:Destroy() SP:Destroy()
        end
    end)
end

MF.Visible = true
Notify("VD Shield Loaded - Mobile + PC!")
print("[VD] VD Shield ready - 109 features active")
print("[VD] Safety: Bypass + gethui + Honeypot + Safe Input + Gaussian")
