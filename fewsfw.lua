

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--------------------------------------------------------------------------------
-- 100% ABSOLUTE TEARDOWN OF PREVIOUS RUNS
--------------------------------------------------------------------------------
local function purgePreviousRuns()
    pcall(function()
        if cleardrawcache then cleardrawcache() end
    end)
    
    local targets = {game:GetService("CoreGui")}
    if gethui then pcall(function() table.insert(targets, gethui()) end) end
    
    for _, container in ipairs(targets) do
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("ScreenGui") and (string.find(child.Name, "Ronaldo") or string.find(child.Name, "Zenith") or string.find(child.Name, "Matcha")) then
                pcall(function() child:Destroy() end)
            end
        end
    end
end

purgePreviousRuns()

--------------------------------------------------------------------------------
-- STATE CLEANUP REGISTRY (LIVE RELOAD SUPPORT)
--------------------------------------------------------------------------------
local cleanups = {}
local function addCleanup(fn)
    table.insert(cleanups, fn)
end

if STATE then
    STATE.onCleanup(function()
        for _, fn in ipairs(cleanups) do
            pcall(fn)
        end
        purgePreviousRuns()
    end)
end

--------------------------------------------------------------------------------
-- GAME CONTROLLERS
--------------------------------------------------------------------------------
local GunController = nil
local CameraController = nil
local currentTarget = nil

pcall(function() GunController = require(ReplicatedStorage.Modules.Client.Controllers.GunController) end)
pcall(function() CameraController = require(ReplicatedStorage.Modules.Client.Controllers.CameraController) end)

local Orig_GunApplyRecoil = GunController and GunController.ApplyRecoil
local Orig_GunGetFireDir = GunController and GunController.GetFireDirection

local Orig_CamRecoil = CameraController and CameraController.Recoil
local Orig_CamBoomKick = CameraController and CameraController.BoomKick
local Orig_CamShakeImpulse = CameraController and CameraController.ShakeImpulse

--------------------------------------------------------------------------------
-- CONFIGURATION (ALL OFF BY DEFAULT)
--------------------------------------------------------------------------------
local Config = {
    Combat = {
        SilentAim = false,        -- Muzzle Bullet Redirection
        CameraAim = false,        -- Muzzle Camera Lock
        AimKey = Enum.UserInputType.MouseButton2,
        AimPart = "Head",        -- "Head", "Torso", "HumanoidRootPart"
        FOV = 120,
        ShowFOV = false,
        FOVCenterMode = "ScreenCenter",
        Smoothness = 0.35,
        TeamCheck = true,         -- Team Check
    },
    GunMod = {
        NoRecoil = false,         -- 100% Zero Camera + Gun Recoil
        NoSpread = false,         -- 100% Pinpoint Accuracy
        InfiniteAmmo = false,     -- Instant Ammo Refill
        RapidFire = false,       -- Custom Rate of Fire
        CustomFireRate = 0.02,
        ForceAuto = false,        -- Full Auto Mode
    },
    Visuals = {
        Enabled = false,
        Boxes = false,
        Names = false,
        HealthBar = false,
        Tracers = false,
        Highlights = false,
        Crosshair = false,
        ShowTeammates = false,
        BoxColor = Color3.fromRGB(0, 230, 180),
        TracerColor = Color3.fromRGB(0, 190, 255),
        HighlightColor = Color3.fromRGB(255, 45, 85),
        TeammateColor = Color3.fromRGB(0, 200, 255),
    },
    Movement = {
        JumpEnabled = true,       -- Enable custom jump physics in TTK
        JumpPower = 38,           -- Clean ~5 stud jump height with gravity 128
        Bhop = false,             -- Auto-Jump on landing while Space held
        AirStrafe = false,        -- Instant air direction control
        StrafeSpeed = 28,         -- Air strafe velocity
        SpeedHack = false,
        SpeedValue = 32,
        Fullbright = false,
        CustomCamFOV = false,
        CamFOVValue = 90,
    }
}

--------------------------------------------------------------------------------
-- RECOIL & GUN HOOKS
--------------------------------------------------------------------------------
if GunController then
    GunController.ApplyRecoil = function(self, ...)
        if Config.GunMod.NoRecoil then
            pcall(function()
                if self.RecoilSpring then self.RecoilSpring.t = Vector3.zero end
                if self.RecoilPushSpring then self.RecoilPushSpring.t = Vector3.zero end
                if self.RecoilShakeSpring then self.RecoilShakeSpring.t = Vector3.zero end
                if self.RecoilTiltSpring then self.RecoilTiltSpring.t = Vector3.zero end
            end)
            return
        end
        if Orig_GunApplyRecoil then return Orig_GunApplyRecoil(self, ...) end
    end
    addCleanup(function() if Orig_GunApplyRecoil then GunController.ApplyRecoil = Orig_GunApplyRecoil end end)

    GunController.GetFireDirection = function(self, ...)
        if Config.Combat.SilentAim and currentTarget and currentTarget.Character then
            local targetPart = currentTarget.Character:FindFirstChild(Config.Combat.AimPart) or currentTarget.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                local muzzlePos = nil
                pcall(function()
                    local muzzleCFrame = self:GetActiveProjectileMuzzleWorldCFrame()
                    if muzzleCFrame then muzzlePos = muzzleCFrame.Position end
                end)
                if not muzzlePos then muzzlePos = Camera.CFrame.Position end
                return (targetPart.Position - muzzlePos).Unit
            end
        end

        if Config.GunMod.NoSpread and self.GetAimDirection then
            return self:GetAimDirection()
        end

        if Orig_GunGetFireDir then return Orig_GunGetFireDir(self, ...) end
    end
    addCleanup(function() if Orig_GunGetFireDir then GunController.GetFireDirection = Orig_GunGetFireDir end end)
end

if CameraController then
    CameraController.Recoil = function(self, ...)
        if Config.GunMod.NoRecoil then return end
        if Orig_CamRecoil then return Orig_CamRecoil(self, ...) end
    end
    addCleanup(function() if Orig_CamRecoil then CameraController.Recoil = Orig_CamRecoil end end)

    CameraController.BoomKick = function(self, ...)
        if Config.GunMod.NoRecoil then return end
        if Orig_CamBoomKick then return Orig_CamBoomKick(self, ...) end
    end
    addCleanup(function() if Orig_CamBoomKick then CameraController.BoomKick = Orig_CamBoomKick end end)

    CameraController.ShakeImpulse = function(self, ...)
        if Config.GunMod.NoRecoil then return end
        if Orig_CamShakeImpulse then return Orig_CamShakeImpulse(self, ...) end
    end
end

--------------------------------------------------------------------------------
-- CUSTOM JUMP & BHOP PHYSICS (TTK TESTING COMPATIBLE)
--------------------------------------------------------------------------------
local lastJumpTick = 0
local function isOnGround(char)
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return false end
    if hum.FloorMaterial ~= Enum.Material.Air then return true end
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -3.4, 0), rayParams)
    return hit ~= nil
end

local function performJump()
    local now = tick()
    if now - lastJumpTick < 0.22 then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and isOnGround(char) then
        lastJumpTick = now
        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, Config.Movement.JumpPower or 38, hrp.AssemblyLinearVelocity.Z)
    end
end

local jumpKeyConn = UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.Space and Config.Movement.JumpEnabled then
        performJump()
    end
end)
addCleanup(function() jumpKeyConn:Disconnect() end)

--------------------------------------------------------------------------------
-- TARGET ACQUISITION, TEAM CHECK & CENTERING
--------------------------------------------------------------------------------
local function getScreenCenter()
    return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function isTeammate(player)
    if not Config.Combat.TeamCheck then return false end
    if player == LocalPlayer then return true end

    local myTeam = LocalPlayer:GetAttribute("Team")
    local theirTeam = player:GetAttribute("Team")
    if myTeam and theirTeam and myTeam ~= "" and myTeam == theirTeam then
        return true
    end

    if LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
        return true
    end

    if not LocalPlayer.Neutral and not player.Neutral and LocalPlayer.TeamColor == player.TeamColor then
        return true
    end

    return false
end

local function getTarget()
    local closest = nil
    local shortestDist = Config.Combat.FOV
    local center = getScreenCenter()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not isTeammate(player) and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local targetPart = player.Character:FindFirstChild(Config.Combat.AimPart) or player.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

--------------------------------------------------------------------------------
-- GUI CREATION (PURE MINIMALIST DARK THEME - NO EMOJIS, NO FOOTER)
--------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Musaed TTK Script"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local parentTarget = game:GetService("CoreGui")
pcall(function()
    if gethui then
        parentTarget = gethui()
    end
end)
ScreenGui.Parent = parentTarget

addCleanup(function() ScreenGui:Destroy() end)

-- Main Window
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 580, 0, 360)
MainFrame.Position = UDim2.new(0.5, -290, 0.5, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(28, 32, 44)
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 42)
Header.Position = UDim2.new(0, 0, 0, 0)
Header.BackgroundColor3 = Color3.fromRGB(18, 20, 27)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 8)
HeaderCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Text = "MUSAED TTK SCRIPT"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextColor3 = Color3.fromRGB(240, 243, 250)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.Size = UDim2.new(0, 200, 1, 0)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Parent = Header

local KeyHint = Instance.new("TextLabel")
KeyHint.Text = "[G] Toggle Menu"
KeyHint.Font = Enum.Font.GothamMedium
KeyHint.TextSize = 11
KeyHint.TextColor3 = Color3.fromRGB(120, 125, 145)
KeyHint.Position = UDim2.new(1, -140, 0, 0)
KeyHint.Size = UDim2.new(0, 124, 1, 0)
KeyHint.TextXAlignment = Enum.TextXAlignment.Right
KeyHint.BackgroundTransparency = 1
KeyHint.Parent = Header

-- Sidebar Navigation
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 140, 1, -42)
Sidebar.Position = UDim2.new(0, 0, 0, 42)
Sidebar.BackgroundColor3 = Color3.fromRGB(16, 17, 23)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SideList = Instance.new("UIListLayout")
SideList.SortOrder = Enum.SortOrder.LayoutOrder
SideList.Padding = UDim.new(0, 4)
SideList.Parent = Sidebar

local SidePad = Instance.new("UIPadding")
SidePad.PaddingTop = UDim.new(0, 10)
SidePad.PaddingLeft = UDim.new(0, 8)
SidePad.PaddingRight = UDim.new(0, 8)
SidePad.Parent = Sidebar

-- Content Container
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -140, 1, -42)
Content.Position = UDim2.new(0, 140, 0, 42)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

local pages = {}
local tabBtns = {}

local function createTab(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, -20, 1, -20)
    page.Position = UDim2.new(0, 10, 0, 10)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Color3.fromRGB(0, 230, 180)
    page.Visible = false
    page.Parent = Content

    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 6)
    list.Parent = page

    pages[name] = page

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(21, 23, 31)
    btn.Text = name
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(140, 145, 170)
    btn.TextXAlignment = Enum.TextXAlignment.Center
    btn.AutoButtonColor = false
    btn.Parent = Sidebar

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        for pName, p in pairs(pages) do p.Visible = (pName == name) end
        for _, b in pairs(tabBtns) do
            b.BackgroundColor3 = Color3.fromRGB(21, 23, 31)
            b.TextColor3 = Color3.fromRGB(140, 145, 170)
        end
        btn.BackgroundColor3 = Color3.fromRGB(0, 180, 140)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    table.insert(tabBtns, btn)
    return page
end

-- Controls Helpers
local function addToggle(page, labelText, defaultVal, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -6, 0, 34)
    f.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    f.Parent = page

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 6)
    fc.Parent = f

    local fs = Instance.new("UIStroke")
    fs.Color = Color3.fromRGB(28, 31, 44)
    fs.Thickness = 1
    fs.Parent = f

    local t = Instance.new("TextLabel")
    t.Text = labelText
    t.Font = Enum.Font.Gotham
    t.TextSize = 12
    t.TextColor3 = Color3.fromRGB(225, 230, 245)
    t.Position = UDim2.new(0, 12, 0, 0)
    t.Size = UDim2.new(0.7, 0, 1, 0)
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.BackgroundTransparency = 1
    t.Parent = f

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 38, 0, 18)
    btn.Position = UDim2.new(1, -48, 0.5, -9)
    btn.BackgroundColor3 = defaultVal and Color3.fromRGB(0, 200, 140) or Color3.fromRGB(38, 41, 56)
    btn.Text = ""
    btn.Parent = f

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 9)
    bc.Parent = btn

    local ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 14, 0, 14)
    ind.Position = defaultVal and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    ind.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ind.Parent = btn

    local ic = Instance.new("UICorner")
    ic.CornerRadius = UDim.new(1, 0)
    ic.Parent = ind

    local state = defaultVal
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 140) or Color3.fromRGB(38, 41, 56)
        ind.Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
        pcall(callback, state)
    end)
end

local function addSlider(page, labelText, minVal, maxVal, defaultVal, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -6, 0, 46)
    f.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    f.Parent = page

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 6)
    fc.Parent = f

    local fs = Instance.new("UIStroke")
    fs.Color = Color3.fromRGB(28, 31, 44)
    fs.Thickness = 1
    fs.Parent = f

    local t = Instance.new("TextLabel")
    t.Text = labelText
    t.Font = Enum.Font.Gotham
    t.TextSize = 12
    t.TextColor3 = Color3.fromRGB(225, 230, 245)
    t.Position = UDim2.new(0, 12, 0, 4)
    t.Size = UDim2.new(0.6, 0, 0, 18)
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.BackgroundTransparency = 1
    t.Parent = f

    local valTxt = Instance.new("TextLabel")
    valTxt.Text = tostring(defaultVal)
    valTxt.Font = Enum.Font.GothamBold
    valTxt.TextSize = 12
    valTxt.TextColor3 = Color3.fromRGB(0, 230, 180)
    valTxt.Position = UDim2.new(1, -68, 0, 4)
    valTxt.Size = UDim2.new(0, 56, 0, 18)
    valTxt.TextXAlignment = Enum.TextXAlignment.Right
    valTxt.BackgroundTransparency = 1
    valTxt.Parent = f

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, -24, 0, 5)
    bg.Position = UDim2.new(0, 12, 0, 30)
    bg.BackgroundColor3 = Color3.fromRGB(38, 41, 56)
    bg.Parent = f

    local bgc = Instance.new("UICorner")
    bgc.CornerRadius = UDim.new(1, 0)
    bgc.Parent = bg

    local fill = Instance.new("Frame")
    local pct = (defaultVal - minVal) / (maxVal - minVal)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 200, 140)
    fill.Parent = bg

    local fillc = Instance.new("UICorner")
    fillc.CornerRadius = UDim.new(1, 0)
    fillc.Parent = fill

    local dragging = false
    local function update(input)
        local pos = math.clamp((input.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        local val = math.floor(minVal + (maxVal - minVal) * pos)
        valTxt.Text = tostring(val)
        pcall(callback, val)
    end

    bg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true update(input) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then update(input) end
    end)
end

-- Create Pages
local combatPage = createTab("Combat")
local gunModPage = createTab("Gun Mods")
local visualsPage = createTab("Visuals")
local movementPage = createTab("Movement")

tabBtns[1].BackgroundColor3 = Color3.fromRGB(0, 180, 140)
tabBtns[1].TextColor3 = Color3.fromRGB(255, 255, 255)
pages["Combat"].Visible = true

-- Combat Controls
addToggle(combatPage, "Team Check (Ignore Allies)", Config.Combat.TeamCheck, function(v) Config.Combat.TeamCheck = v end)
addToggle(combatPage, "Muzzle Silent Aim (Bullet Trace)", Config.Combat.SilentAim, function(v) Config.Combat.SilentAim = v end)
addToggle(combatPage, "Muzzle Camera Lock (RMB)", Config.Combat.CameraAim, function(v) Config.Combat.CameraAim = v end)
addToggle(combatPage, "Show FOV Circle", Config.Combat.ShowFOV, function(v) Config.Combat.ShowFOV = v end)
addSlider(combatPage, "Aimbot FOV Radius", 30, 400, Config.Combat.FOV, function(v) Config.Combat.FOV = v end)

-- Gun Mod Controls
addToggle(gunModPage, "100% No Recoil (Cam + Weapon)", Config.GunMod.NoRecoil, function(v) Config.GunMod.NoRecoil = v end)
addToggle(gunModPage, "100% No Spread (Pinpoint)", Config.GunMod.NoSpread, function(v) Config.GunMod.NoSpread = v end)
addToggle(gunModPage, "Infinite Ammo Refill", Config.GunMod.InfiniteAmmo, function(v) Config.GunMod.InfiniteAmmo = v end)
addToggle(gunModPage, "Force Full-Auto Mode", Config.GunMod.ForceAuto, function(v) Config.GunMod.ForceAuto = v end)
addToggle(gunModPage, "Rapid Fire Boost", Config.GunMod.RapidFire, function(v) Config.GunMod.RapidFire = v end)

-- Visuals Controls
addToggle(visualsPage, "Master ESP Toggle", Config.Visuals.Enabled, function(v) Config.Visuals.Enabled = v end)
addToggle(visualsPage, "Chams (Wallhack Highlight)", Config.Visuals.Highlights, function(v) Config.Visuals.Highlights = v end)
addToggle(visualsPage, "Show Teammates in ESP", Config.Visuals.ShowTeammates, function(v) Config.Visuals.ShowTeammates = v end)
addToggle(visualsPage, "2D Bounding Boxes", Config.Visuals.Boxes, function(v) Config.Visuals.Boxes = v end)
addToggle(visualsPage, "Name & Distance", Config.Visuals.Names, function(v) Config.Visuals.Names = v end)
addToggle(visualsPage, "Health Bars", Config.Visuals.HealthBar, function(v) Config.Visuals.HealthBar = v end)
addToggle(visualsPage, "Tracers", Config.Visuals.Tracers, function(v) Config.Visuals.Tracers = v end)

-- Movement & World Controls
addToggle(movementPage, "Enable Jump in TTK", Config.Movement.JumpEnabled, function(v) Config.Movement.JumpEnabled = v end)
addSlider(movementPage, "Jump Height", 25, 55, Config.Movement.JumpPower, function(v) Config.Movement.JumpPower = v end)
addToggle(movementPage, "Bunny Hop (Hold Space)", Config.Movement.Bhop, function(v) Config.Movement.Bhop = v end)
addToggle(movementPage, "Air Strafe (Instant Direction)", Config.Movement.AirStrafe, function(v) Config.Movement.AirStrafe = v end)
addSlider(movementPage, "Air Strafe Speed", 16, 60, Config.Movement.StrafeSpeed, function(v) Config.Movement.StrafeSpeed = v end)
addToggle(movementPage, "Speed Hack (Fast Movement)", Config.Movement.SpeedHack, function(v) Config.Movement.SpeedHack = v end)
addSlider(movementPage, "Speed Multiplier", 20, 100, Config.Movement.SpeedValue, function(v) Config.Movement.SpeedValue = v end)
addToggle(movementPage, "Infinite Jump (Air Jump)", Config.Movement.InfiniteJump, function(v) Config.Movement.InfiniteJump = v end)
addToggle(movementPage, "Custom Camera FOV", Config.Movement.CustomCamFOV, function(v) Config.Movement.CustomCamFOV = v end)
addSlider(movementPage, "Camera Field of View", 70, 120, Config.Movement.CamFOVValue, function(v) Config.Movement.CamFOVValue = v end)
addToggle(movementPage, "Fullbright / Clear World", Config.Movement.Fullbright, function(v)
    Config.Movement.Fullbright = v
    if v then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
    else
        Lighting.GlobalShadows = true
    end
end)

-- Keybind Toggle (G Key)
local uiVisible = true
local inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.G then
        uiVisible = not uiVisible
        MainFrame.Visible = uiVisible
    end
end)
addCleanup(function() inputConn:Disconnect() end)

--------------------------------------------------------------------------------
-- DRAWING OVERLAYS & RENDER STEP
--------------------------------------------------------------------------------
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(0, 230, 180)
fovCircle.Thickness = 1.5
fovCircle.Filled = false
fovCircle.Transparency = 0.85
fovCircle.Visible = false

addCleanup(function() fovCircle:Remove() end)

local crosshairH = Drawing.new("Line")
local crosshairV = Drawing.new("Line")
crosshairH.Color = Color3.fromRGB(0, 230, 180)
crosshairH.Thickness = 1
crosshairH.Transparency = 0.7

crosshairV.Color = Color3.fromRGB(0, 230, 180)
crosshairV.Thickness = 1
crosshairV.Transparency = 0.7

addCleanup(function()
    crosshairH:Remove()
    crosshairV:Remove()
end)

local espCache = {}
local function removePlayerESP(player)
    if espCache[player] then
        for _, obj in pairs(espCache[player]) do
            if obj and obj.Remove then pcall(function() obj:Remove() end)
            elseif typeof(obj) == "Instance" then pcall(function() obj:Destroy() end) end
        end
        espCache[player] = nil
    end
end

addCleanup(function()
    for player, _ in pairs(espCache) do removePlayerESP(player) end
end)

local function getPlayerESP(player)
    if espCache[player] then return espCache[player] end

    local cache = {
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        healthBg = Drawing.new("Square"),
        healthFill = Drawing.new("Square"),
        tracer = Drawing.new("Line"),
    }

    cache.box.Thickness = 1.5
    cache.box.Color = Config.Visuals.BoxColor
    cache.box.Filled = false

    cache.name.Size = 13
    cache.name.Center = true
    cache.name.Outline = true
    cache.name.Color = Color3.fromRGB(255, 255, 255)

    cache.healthBg.Filled = true
    cache.healthBg.Color = Color3.fromRGB(20, 20, 20)
    cache.healthFill.Filled = true

    cache.tracer.Thickness = 1
    cache.tracer.Color = Config.Visuals.TracerColor

    espCache[player] = cache
    return cache
end

--------------------------------------------------------------------------------
-- MAIN STEPPING LOOP
--------------------------------------------------------------------------------
local renderConn = RunService.RenderStepped:Connect(function()
    local screenCenter = getScreenCenter()
    currentTarget = getTarget()

    -- Custom Camera FOV
    if Config.Movement.CustomCamFOV then
        Camera.FieldOfView = Config.Movement.CamFOVValue
    end

    -- Speed Hack (CFrame Boost)
    if Config.Movement.SpeedHack and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (hum.MoveDirection * ((Config.Movement.SpeedValue - 16) / 60))
        end
    end

    -- Bunny Hop (Auto Jump on ground while Space is held)
    if Config.Movement.Bhop and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        performJump()
    end

    -- Air Strafe (Instant air direction control without cooldown or inertia lag)
    if Config.Movement.AirStrafe and LocalPlayer.Character then
        local char = LocalPlayer.Character
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.Health > 0 and not isOnGround(char) then
            if hum.MoveDirection.Magnitude > 0.05 then
                local currentVy = hrp.AssemblyLinearVelocity.Y
                local horizMag = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z).Magnitude
                local strafeSpeed = math.max(horizMag, Config.Movement.StrafeSpeed or 28)
                local newHoriz = hum.MoveDirection.Unit * strafeSpeed
                hrp.AssemblyLinearVelocity = Vector3.new(newHoriz.X, currentVy, newHoriz.Z)
            end
        end
    end

    -- FOV Circle
    fovCircle.Position = screenCenter
    fovCircle.Radius = Config.Combat.FOV
    fovCircle.Visible = Config.Combat.ShowFOV

    -- Centered Crosshair
    if Config.Visuals.Crosshair then
        crosshairH.From = Vector2.new(screenCenter.X - 6, screenCenter.Y)
        crosshairH.To = Vector2.new(screenCenter.X + 6, screenCenter.Y)
        crosshairH.Visible = true

        crosshairV.From = Vector2.new(screenCenter.X, screenCenter.Y - 6)
        crosshairV.To = Vector2.new(screenCenter.X, screenCenter.Y + 6)
        crosshairV.Visible = true
    else
        crosshairH.Visible = false
        crosshairV.Visible = false
    end

    -- Gun Mods Handling
    if GunController and GunController.Weapon and GunController.Weapon.IsEquipped then
        local weapon = GunController.Weapon
        if Config.GunMod.InfiniteAmmo and weapon.MagAmmo and weapon.MaxMagSize then
            weapon.MagAmmo = weapon.MaxMagSize
        end
        if Config.GunMod.ForceAuto then
            weapon.FireMode = "auto"
        end
        if Config.GunMod.RapidFire and weapon.FireRate then
            weapon.FireRate = Config.GunMod.CustomFireRate
            if weapon.Config then weapon.Config.fire_rate = Config.GunMod.CustomFireRate end
        end
    end

    -- Camera Lock Aimbot
    if Config.Combat.CameraAim and UserInputService:IsMouseButtonPressed(Config.Combat.AimKey) and currentTarget and currentTarget.Character then
        local targetPart = currentTarget.Character:FindFirstChild(Config.Combat.AimPart) or currentTarget.Character:FindFirstChild("HumanoidRootPart")
        if targetPart then
            local targetViewport = Camera:WorldToViewportPoint(targetPart.Position)
            local target2D = Vector2.new(targetViewport.X, targetViewport.Y)
            local delta = target2D - screenCenter
            mousemoverel(delta.X * Config.Combat.Smoothness, delta.Y * Config.Combat.Smoothness)
        end
    end

    -- ESP & Chams Loop
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local esp = getPlayerESP(player)
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local isAlly = isTeammate(player)

            -- Chams (Highlights) - Independent of 2D screen visibility for true wallhack
            local shouldShowChams = Config.Visuals.Highlights and Config.Visuals.Enabled and char and hum and hum.Health > 0
            if shouldShowChams and isAlly and not Config.Visuals.ShowTeammates then
                shouldShowChams = false
            end

            if shouldShowChams then
                local hl = esp.highlight
                if not hl or hl.Parent ~= char then
                    if hl then pcall(function() hl:Destroy() end) end
                    hl = Instance.new("Highlight")
                    hl.Name = "Ronaldo_Chams"
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.FillTransparency = 0.45
                    hl.OutlineTransparency = 0
                    hl.Adornee = char
                    hl.Parent = char
                    esp.highlight = hl
                end
                hl.FillColor = isAlly and Config.Visuals.TeammateColor or Config.Visuals.HighlightColor
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.Enabled = true
            elseif esp.highlight then
                pcall(function() esp.highlight:Destroy() end)
                esp.highlight = nil
            end

            -- 2D Drawings (Boxes, Names, HealthBar, Tracers)
            local shouldShow2D = Config.Visuals.Enabled and char and hum and hum.Health > 0 and hrp
            if shouldShow2D and isAlly and not Config.Visuals.ShowTeammates then
                shouldShow2D = false
            end

            if shouldShow2D then
                local head = char:FindFirstChild("Head") or hrp
                local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.6, 0))
                local footPos, footOnScreen = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.2, 0))

                if headOnScreen and footOnScreen then
                    local boxHeight = math.abs(footPos.Y - headPos.Y)
                    local boxWidth = boxHeight * 0.6
                    local boxPos = Vector2.new(headPos.X - boxWidth / 2, headPos.Y)
                    local drawColor = isAlly and Config.Visuals.TeammateColor or Config.Visuals.BoxColor

                    if Config.Visuals.Boxes then
                        esp.box.Size = Vector2.new(boxWidth, boxHeight)
                        esp.box.Position = boxPos
                        esp.box.Color = drawColor
                        esp.box.Visible = true
                    else esp.box.Visible = false end

                    if Config.Visuals.Names then
                        local dist = math.floor((hrp.Position - Camera.CFrame.Position).Magnitude)
                        esp.name.Text = string.format("%s [%dm]", player.DisplayName or player.Name, dist)
                        esp.name.Position = Vector2.new(headPos.X, headPos.Y - 16)
                        esp.name.Color = isAlly and Config.Visuals.TeammateColor or Color3.fromRGB(255, 255, 255)
                        esp.name.Visible = true
                    else esp.name.Visible = false end

                    if Config.Visuals.HealthBar then
                        local hpPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        local barWidth = 3
                        local barHeight = boxHeight
                        esp.healthBg.Size = Vector2.new(barWidth, barHeight)
                        esp.healthBg.Position = Vector2.new(boxPos.X - 6, boxPos.Y)
                        esp.healthBg.Visible = true

                        esp.healthFill.Size = Vector2.new(barWidth, barHeight * hpPct)
                        esp.healthFill.Position = Vector2.new(boxPos.X - 6, boxPos.Y + (barHeight * (1 - hpPct)))
                        esp.healthFill.Color = Color3.fromRGB(255 * (1 - hpPct), 255 * hpPct, 0)
                        esp.healthFill.Visible = true
                    else
                        esp.healthBg.Visible = false
                        esp.healthFill.Visible = false
                    end

                    if Config.Visuals.Tracers then
                        esp.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        esp.tracer.To = Vector2.new(footPos.X, footPos.Y)
                        esp.tracer.Color = isAlly and Config.Visuals.TeammateColor or Config.Visuals.TracerColor
                        esp.tracer.Visible = true
                    else esp.tracer.Visible = false end
                else
                    esp.box.Visible = false
                    esp.name.Visible = false
                    esp.healthBg.Visible = false
                    esp.healthFill.Visible = false
                    esp.tracer.Visible = false
                end
            else
                esp.box.Visible = false
                esp.name.Visible = false
                esp.healthBg.Visible = false
                esp.healthFill.Visible = false
                esp.tracer.Visible = false
            end
        end
    end
end)

addCleanup(function() renderConn:Disconnect() end)

print("[MUSAED TTK SCRIPT] Pure Dark Minimalist Loaded!")
