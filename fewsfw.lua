-- ==========================================
-- MUSAED HUB - DEVIL 3D UI v10 (ثيمات جديدة • معرض خلفيات بالصور • حفظ الإعدادات • FPS/Ping)
-- (نسخة كاملة + DEVIL UI FIX PACK في الآخر)
-- ==========================================
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local HUB_VERSION = "v10.0.0"
local SessionStarted = os.clock()
local SoundEnabled = true
local AnimationEnabled = true
local BackgroundMotionEnabled = true
local MenuTransparency = 0.12
local Notify

-- ==========================================
-- 1. الصوت وإعداد الحاوية الرئيسية
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MusaedAdvancedHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
else
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

-- مؤثرات صوتية للواجهة
local function CreateUISound(name, soundId, volume)
    local sound = Instance.new("Sound")
    sound.Name = name
    sound.SoundId = "rbxassetid://" .. tostring(soundId)
    sound.Volume = volume
    sound.Parent = ScreenGui
    return sound
end

local ClickSound = CreateUISound("ClickSound", "6895079853", 0.42)
local HoverSound = CreateUISound("HoverSound", "12221967", 0.16)
local SuccessSound = CreateUISound("SuccessSound", "6042053626", 0.38)
local ErrorSound = CreateUISound("ErrorSound", "138090596", 0.28)

local function PlaySound(sound)
    if not SoundEnabled or not sound then return end
    sound:Stop()
    sound:Play()
end

local function PlayClick()
    PlaySound(ClickSound)
end

local function AddButtonMotion(button)
    if not button then return end
    local originalSize = button.Size
    local hoverSize = UDim2.new(originalSize.X.Scale, originalSize.X.Offset + 4, originalSize.Y.Scale, originalSize.Y.Offset + 2)
    button.MouseEnter:Connect(function()
        PlaySound(HoverSound)
        if AnimationEnabled then
            TweenService:Create(button, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = hoverSize
            }):Play()
        end
    end)
    button.MouseLeave:Connect(function()
        if AnimationEnabled then
            TweenService:Create(button, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = originalSize
            }):Play()
        end
    end)
end

-- ==========================================
-- 2. محرك الثيمات (Theme Engine)
-- ==========================================
local CurrentAccent = Color3.fromRGB(52, 182, 189) -- التراكواز القياسي (#34b6bd)

local Backgrounds = {
    {Name = "Neon City", Id = "3445892210", Kind = "Image"},
    {Name = "Dark Matrix", Id = "562372164", Kind = "Image"},
    {Name = "Cyber Blue", Id = "8027497475", Kind = "Image"},
    {Name = "Phantom", Id = "1891941984", Kind = "Image"},
    {Name = "Abyss", Id = "7866490119", Kind = "Image"},
    {Name = "Crimson Pulse", Id = "6057464206", Kind = "Image"},
    {Name = "Void Horizon", Id = "4705269490", Kind = "Image"},
    {Name = "Electric Ruins", Id = "8373881910", Kind = "Image"},
}
local CurrentBackground = 1
local SelectedBackground = 1
local MainBackgroundImage

local function BackgroundAsset(id)
    return "rbxassetid://" .. tostring(id)
end

local function BackgroundThumb(id)
    return "rbxthumb://type=Asset&id=" .. tostring(id) .. "&w=768&h=432"
end

local BgCache = {}

local function SetImageWithFallback(imageObject, id)
    if not imageObject then return end

    local assetId = tostring(id or ""):gsub("rbxassetid://", "")
    imageObject:SetAttribute("BackgroundAssetId", assetId)
    imageObject:SetAttribute("BackgroundLoaded", false)
    imageObject:SetAttribute("BackgroundFailed", false)
    imageObject.ScaleType = Enum.ScaleType.Crop

    local token = (imageObject:GetAttribute("DEVIL_Token") or 0) + 1
    imageObject:SetAttribute("DEVIL_Token", token)

    local oldGradient = imageObject:FindFirstChild("DEVIL_BackgroundGradient")
    if oldGradient then oldGradient:Destroy() end

    local function ApplyGradient(c1, c2, c3)
        imageObject.Image = ""
        imageObject.ImageTransparency = 1
        imageObject.BackgroundTransparency = 0
        imageObject.BackgroundColor3 = c2
        local gradient = Instance.new("UIGradient")
        gradient.Name = "DEVIL_BackgroundGradient"
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, c1),
            ColorSequenceKeypoint.new(0.5, c2),
            ColorSequenceKeypoint.new(1, c3)
        })
        gradient.Rotation = 35
        gradient.Parent = imageObject
    end

    if assetId == "__GRADIENT_FALLBACK" then
        ApplyGradient(Color3.fromRGB(26, 43, 70), Color3.fromRGB(8, 14, 26), Color3.fromRGB(44, 18, 65))
        return
    end

    -- خلف الصورة لون غامق دايماً (ما يبان شفاف أثناء التحميل)
    imageObject.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
    imageObject.BackgroundTransparency = 0
    imageObject.ImageTransparency = 0.05

    local cached = BgCache[assetId]
    if cached then
        imageObject.Image = cached
        imageObject:SetAttribute("BackgroundLoaded", true)
        return
    end

    imageObject.Image = ""
    task.defer(function()
        local candidates = {
            "rbxthumb://type=Asset&id=" .. assetId .. "&w=768&h=432",
            "rbxassetid://" .. assetId,
            "rbxthumb://type=Asset&id=" .. assetId .. "&w=420&h=420",
            "http://www.roblox.com/asset/?id=" .. assetId,
        }
        for _, candidate in ipairs(candidates) do
            if imageObject:GetAttribute("DEVIL_Token") ~= token then return end
            imageObject.Image = candidate
            pcall(function() game:GetService("ContentProvider"):PreloadAsync({imageObject}) end)
            local t0 = os.clock()
            while not imageObject.IsLoaded and os.clock() - t0 < 1.5 do task.wait(0.1) end
            if imageObject:GetAttribute("DEVIL_Token") ~= token then return end
            if imageObject.IsLoaded then
                BgCache[assetId] = candidate
                imageObject:SetAttribute("BackgroundLoaded", true)
                return
            end
        end
        -- فشل كل شي: خلفية احتياطية + علامة فشل (المعرض يعرض زر إعادة المحاولة)
        imageObject:SetAttribute("BackgroundFailed", true)
        ApplyGradient(Color3.fromRGB(26, 43, 70), Color3.fromRGB(8, 14, 26), Color3.fromRGB(44, 18, 65))
    end)
end

local ThemeObjects = { Stroked = {}, TextColored = {}, BackgroundColored = {} }

local function RegisterThemeElement(object, category)
    table.insert(ThemeObjects[category], object)
end

local function UpdateTheme(newColor)
    CurrentAccent = newColor
    local tInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    for _, obj in ipairs(ThemeObjects.Stroked) do
        if obj and obj.Parent then
            TweenService:Create(obj, tInfo, {Color = newColor}):Play()
        end
    end
    for _, obj in ipairs(ThemeObjects.TextColored) do
        if obj and obj.Parent then
            TweenService:Create(obj, tInfo, {TextColor3 = newColor}):Play()
        end
    end
    for _, obj in ipairs(ThemeObjects.BackgroundColored) do
        if obj and obj.Parent then
            TweenService:Create(obj, tInfo, {BackgroundColor3 = newColor}):Play()
        end
    end
    local themeHook = rawget(_G, "MUSAED_THEME_HOOK")
    if themeHook then pcall(themeHook, newColor) end
end


-- ==========================================
-- 2.5 محرك الـ 3D Stack (طبقات حقيقية خلف المنيو، مو داخله)
-- كل طبقة تتبع حجم/مكان الإطار + اتجاه الماوس، وتتلون مع الثيم
-- ==========================================
local Stack3D = {Stacks = {}, Strength = 0.7, Enabled = true}

function Stack3D.Build(frame, radius, tag)
    local holder = Instance.new("Frame")
    holder.Name = "DEVIL_3D_" .. tostring(tag)
    holder.BackgroundTransparency = 1
    holder.BorderSizePixel = 0
    holder.Active = false
    holder.Size = UDim2.fromScale(1, 1)
    holder.Position = UDim2.fromScale(0, 0)
    holder.ZIndex = 0
    holder.Visible = false
    holder.Parent = ScreenGui

    local layers = {}
    local z = 0
    local function add(o)
        z += 1
        local f = Instance.new("Frame")
        f.Name = o.name
        f.BorderSizePixel = 0
        f.Active = false
        f.ZIndex = z
        f.BackgroundColor3 = Color3.new(0, 0, 0)
        f.BackgroundTransparency = o.tr
        f.Parent = holder
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, radius + (o.cr or 0))
        c.Parent = f
        o.f = f
        table.insert(layers, o)
        return f
    end

    -- ظلال ناعمة
    add({name = "ShadowFar",  tr = 0.90, ex = 54, ey = 40, t = 1.6, dy = 30, cr = 22})
    add({name = "ShadowNear", tr = 0.78, ex = 24, ey = 18, t = 1.2, dy = 14, cr = 10})
    -- لوحات متراصة تظهر من تحت المنيو
    add({name = "PanelB", tr = 0.42, ex = -64, ey = 0, t = 1, dy = 22, panel = 2})
    add({name = "PanelA", tr = 0.26, ex = -32, ey = 0, t = 1, dy = 11, panel = 1})
    -- سماكة المنيو (Extrusion): 8 طبقات من الأبعد للأقرب
    local N = 8
    local rim
    for i = N, 1, -1 do
        local f = add({name = "Slab" .. i, tr = 0.1, ex = 0, ey = 0, t = i / N, dy = 0, slab = i / N})
        if i == N then rim = f end
    end
    if rim then
        local st = Instance.new("UIStroke")
        st.Color = CurrentAccent
        st.Thickness = 1.4
        st.Transparency = 0.45
        st.Parent = rim
        RegisterThemeElement(st, "Stroked")
    end

    table.insert(Stack3D.Stacks, {frame = frame, holder = holder, layers = layers, px = 0, py = 0})
    return holder
end

function Stack3D.Step(dt)
    if not Stack3D.Enabled then
        for _, s in ipairs(Stack3D.Stacks) do
            if s.holder.Visible then s.holder.Visible = false end
        end
        return
    end
    local mp = UserInputService:GetMouseLocation()
    local a = math.min(1, dt * 9)
    local acc = CurrentAccent
    local black = Color3.new(0, 0, 0)
    local d = Stack3D.Strength

    for _, s in ipairs(Stack3D.Stacks) do
        local fr, holder = s.frame, s.holder
        local show = fr.Visible and fr.AbsoluteSize.X > 40 and fr.AbsoluteSize.Y > 40
        if holder.Visible ~= show then holder.Visible = show end
        if show then
            local ap, as = fr.AbsolutePosition, fr.AbsoluteSize
            local hx, hy = math.max(as.X * 0.5, 1), math.max(as.Y * 0.5, 1)
            local inside = mp.X >= ap.X and mp.X <= ap.X + as.X and mp.Y >= ap.Y and mp.Y <= ap.Y + as.Y
            local tx = inside and math.clamp((mp.X - (ap.X + hx)) / hx, -1, 1) or 0
            local ty = inside and math.clamp((mp.Y - (ap.Y + hy)) / hy, -1, 1) or 0
            s.px += (tx - s.px) * a
            s.py += (ty - s.py) * a

            local vx = -s.px * 10 * d
            local vy = (10 - s.py * 6) * d
            local bx = ap.X - holder.AbsolutePosition.X
            local by = ap.Y - holder.AbsolutePosition.Y

            for _, L in ipairs(s.layers) do
                local w, h = as.X + L.ex, as.Y + L.ey
                L.f.Size = UDim2.fromOffset(w, h)
                L.f.Position = UDim2.fromOffset(
                    bx + (as.X - w) / 2 + vx * L.t,
                    by + (as.Y - h) / 2 + vy * L.t + L.dy * math.min(d, 1.25)
                )
                if L.slab then
                    L.f.BackgroundColor3 = acc:Lerp(black, 0.55 + 0.35 * L.slab)
                elseif L.panel then
                    L.f.BackgroundColor3 = acc:Lerp(black, 0.52 + 0.16 * L.panel)
                end
            end
        end
    end
end

RunService.RenderStepped:Connect(function(dt)
    pcall(Stack3D.Step, dt)
end)

-- Forward declaration للواجهة الرئيسية والزر العائم
local MainFrame
local ToggleBtn

-- تطبيق الخلفية بدون أي اعتماد على نظام Key أو نافذة Key.
local function ApplySelectedBackground(index)
    index = tonumber(index) or 1
    if not Backgrounds[index] then return end
    SelectedBackground = index
    CurrentBackground = index
    local bg = Backgrounds[index]
    if MainBackgroundImage then
        SetImageWithFallback(MainBackgroundImage, bg.Id)
    end
end

-- ==========================================
-- 3. بدون نظام Key — تشغيل مباشر
-- ==========================================

-- ==========================================
-- 4. الزر العائم (Floating Button)

-- ==========================================
ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "UI_Toggle_Button"
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0, 25, 0.5, -25)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(12, 15, 20)
ToggleBtn.BackgroundTransparency = 0.15
ToggleBtn.Text = "N"
ToggleBtn.TextColor3 = CurrentAccent
ToggleBtn.TextSize = 22
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Active = true
ToggleBtn.Draggable = true
ToggleBtn.Visible = true -- تشغيل مباشر بدون Key
ToggleBtn.Parent = ScreenGui
AddButtonMotion(ToggleBtn)

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBtn

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = CurrentAccent
ToggleStroke.Thickness = 1.8
ToggleStroke.Parent = ToggleBtn
RegisterThemeElement(ToggleStroke, "Stroked")
RegisterThemeElement(ToggleBtn, "TextColored")

-- ==========================================
-- 5. الإطار الرئيسي (Main Frame)
-- ==========================================
MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 860, 0, 540)
MainFrame.Position = UDim2.new(0.5, -430, 0.5, -270)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 15, 20)
MainFrame.BackgroundTransparency = MenuTransparency
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = true -- تشغيل مباشر بدون Key
MainFrame.Parent = ScreenGui

-- DEVIL 3D shell: الطبقات الآن خارج المنيو وخلفه (ما تنقص بسبب ClipsDescendants)
local MainDepth = Stack3D.Build(MainFrame, 14, "Main")

local Main3DGradient = Instance.new("UIGradient")
Main3DGradient.Name = "DEVIL_3D_Gradient"
Main3DGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 45, 78)),
    ColorSequenceKeypoint.new(0.48, Color3.fromRGB(8, 16, 31)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(44, 18, 65))
})
Main3DGradient.Rotation = 28
Main3DGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.1),
    NumberSequenceKeypoint.new(0.55, 0.3),
    NumberSequenceKeypoint.new(1, 0.04)
})
Main3DGradient.Parent = MainFrame

local MainTopGlow = Instance.new("Frame")
MainTopGlow.Name = "DEVIL_3D_TopGlow"
MainTopGlow.Size = UDim2.new(1, -34, 0, 3)
MainTopGlow.Position = UDim2.new(0, 17, 0, 8)
MainTopGlow.BackgroundColor3 = CurrentAccent
MainTopGlow.BackgroundTransparency = 0.08
MainTopGlow.BorderSizePixel = 0
MainTopGlow.ZIndex = 3
MainTopGlow.Parent = MainFrame
local MainTopGlowCorner = Instance.new("UICorner")
MainTopGlowCorner.CornerRadius = UDim.new(1, 0)
MainTopGlowCorner.Parent = MainTopGlow
RegisterThemeElement(MainTopGlow, "BackgroundColored")

local NotificationHolder = Instance.new("Frame")
NotificationHolder.Name = "NotificationHolder"
NotificationHolder.Size = UDim2.new(0, 300, 0, 220)
NotificationHolder.Position = UDim2.new(1, -316, 0, 54)
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.ZIndex = 20
NotificationHolder.Parent = MainFrame

local NotificationList = Instance.new("UIListLayout")
NotificationList.FillDirection = Enum.FillDirection.Vertical
NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Right
NotificationList.VerticalAlignment = Enum.VerticalAlignment.Top
NotificationList.Padding = UDim.new(0, 8)
NotificationList.Parent = NotificationHolder

Notify = function(message, color)
    if not NotificationHolder then return end
    local accent = color or CurrentAccent
    local note = Instance.new("Frame")
    note.Name = "DEVIL_3D_Notification"
    note.Size = UDim2.new(1, 0, 0, 60)
    note.BackgroundColor3 = Color3.fromRGB(9, 16, 30)
    note.BackgroundTransparency = 0.05
    note.BorderSizePixel = 0
    note.ZIndex = 25
    note.Parent = NotificationHolder
    do
        local kids = {}
        for _, k in ipairs(NotificationHolder:GetChildren()) do
            if k:IsA("Frame") then table.insert(kids, k) end
        end
        if #kids > 4 then kids[1]:Destroy() end
    end

    local depth = Instance.new("Frame")
    depth.Size = UDim2.new(1, 8, 1, 8)
    depth.Position = UDim2.new(0, 6, 0, 7)
    depth.BackgroundColor3 = accent
    depth.BackgroundTransparency = 0.84
    depth.BorderSizePixel = 0
    depth.ZIndex = 24
    depth.Parent = note

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = note
    local stroke = Instance.new("UIStroke")
    stroke.Color = accent
    stroke.Thickness = 1.6
    stroke.Transparency = 0.12
    stroke.Parent = note

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 4, 1, -14)
    bar.Position = UDim2.new(0, 8, 0, 7)
    bar.BackgroundColor3 = accent
    bar.BorderSizePixel = 0
    bar.ZIndex = 26
    bar.Parent = note
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar

    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 34, 0, 34)
    icon.Position = UDim2.new(0, 20, 0.5, -17)
    icon.BackgroundColor3 = accent
    icon.BackgroundTransparency = 0.8
    icon.Text = "✓"
    icon.TextColor3 = accent
    icon.TextSize = 18
    icon.Font = Enum.Font.GothamBold
    icon.ZIndex = 26
    icon.Parent = note
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(1, 0)
    iconCorner.Parent = icon

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -72, 1, -12)
    text.Position = UDim2.new(0, 64, 0, 6)
    text.BackgroundTransparency = 1
    text.Text = tostring(message)
    text.TextColor3 = Color3.fromRGB(240, 246, 255)
    text.TextSize = 11
    text.Font = Enum.Font.GothamBold
    text.TextXAlignment = Enum.TextXAlignment.Right
    text.TextWrapped = true
    text.ZIndex = 26
    text.Parent = note

    local timerBar = Instance.new("Frame")
    timerBar.Size = UDim2.new(1, -20, 0, 2)
    timerBar.Position = UDim2.new(0, 10, 1, -5)
    timerBar.BackgroundColor3 = accent
    timerBar.BackgroundTransparency = 0.2
    timerBar.BorderSizePixel = 0
    timerBar.ZIndex = 27
    timerBar.Parent = note
    TweenService:Create(timerBar, TweenInfo.new(3.2, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()

    note.Position = UDim2.new(1, 34, 0, 0)
    if AnimationEnabled then
        TweenService:Create(note, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
    else
        note.Position = UDim2.new(0, 0, 0, 0)
    end
    task.delay(3.2, function()
        if note and note.Parent then
            local tween = TweenService:Create(note, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1, 34, 0, 0), BackgroundTransparency = 1})
            tween:Play()
            tween.Completed:Connect(function() if note then note:Destroy() end end)
        end
    end)
end

local MainScale = Instance.new("UIScale")
MainScale.Scale = 1
MainScale.Parent = MainFrame

local MainBacking = Instance.new("Frame")
MainBacking.Name = "DEVIL_Backing"
MainBacking.Size = UDim2.fromScale(1, 1)
MainBacking.BackgroundColor3 = Color3.fromRGB(8, 12, 20)
MainBacking.BorderSizePixel = 0
MainBacking.ZIndex = 0
MainBacking.Parent = MainFrame
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 14) c.Parent = MainBacking end

MainBackgroundImage = Instance.new("ImageLabel")
MainBackgroundImage.Name = "Background"
MainBackgroundImage.Size = UDim2.fromScale(1, 1)
MainBackgroundImage.Position = UDim2.fromScale(0, 0)
MainBackgroundImage.BackgroundTransparency = 1
SetImageWithFallback(MainBackgroundImage, Backgrounds[SelectedBackground].Id)
MainBackgroundImage.ImageTransparency = 0.05
MainBackgroundImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
MainBackgroundImage.ScaleType = Enum.ScaleType.Crop
MainBackgroundImage.ZIndex = 0
MainBackgroundImage.Parent = MainFrame

local MainOverlay = Instance.new("Frame")
MainOverlay.Name = "GlassOverlay"
MainOverlay.Size = UDim2.fromScale(1, 1)
MainOverlay.BackgroundColor3 = Color3.fromRGB(4, 8, 14)
MainOverlay.BackgroundTransparency = 0.68
MainOverlay.BorderSizePixel = 0
MainOverlay.ZIndex = 1
MainOverlay.Parent = MainFrame

do
    -- الخلفية بحجم المنيو بالضبط وبنفس زواياه
    MainBackgroundImage.Size = UDim2.fromScale(1, 1)
    MainBackgroundImage.Position = UDim2.fromScale(0, 0)
    for _, o in ipairs({MainBackgroundImage, MainOverlay}) do
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 14)
        c.Parent = o
    end
    -- لمعة متحركة فوق الخلفية بدل تكبيرها
    local sh = Instance.new("UIGradient")
    sh.Name = "DEVIL_Shine"
    sh.Rotation = 20
    sh.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.0),
        NumberSequenceKeypoint.new(0.5, 0.35),
        NumberSequenceKeypoint.new(1, 0.0)
    })
    sh.Parent = MainOverlay
end

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = CurrentAccent
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.2
MainStroke.Parent = MainFrame
RegisterThemeElement(MainStroke, "Stroked")

-- ==========================================
-- 6. الهيدر وشريط البحث (Header & Search)
-- ==========================================
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundTransparency = 1
Header.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 150, 1, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "DEVIL SCRIPT  •  " .. HUB_VERSION
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local StatusPill = Instance.new("TextLabel")
StatusPill.Name = "StatusPill"
StatusPill.Size = UDim2.new(0, 72, 0, 24)
StatusPill.Position = UDim2.new(0, 172, 0.5, -12)
StatusPill.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
StatusPill.BackgroundTransparency = 0.2
StatusPill.BorderSizePixel = 0
StatusPill.Text = "● ONLINE"
StatusPill.TextColor3 = Color3.fromRGB(80, 220, 160)
StatusPill.TextSize = 9
StatusPill.Font = Enum.Font.GothamBold
StatusPill.Parent = Header

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(1, 0)
StatusCorner.Parent = StatusPill

local StatusStroke = Instance.new("UIStroke")
StatusStroke.Color = Color3.fromRGB(80, 220, 160)
StatusStroke.Transparency = 0.55
StatusStroke.Thickness = 1
StatusStroke.Parent = StatusPill

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(0, 200, 0, 32)
SearchBox.Position = UDim2.new(1, -250, 0.5, -16)
SearchBox.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
SearchBox.BorderSizePixel = 0
SearchBox.PlaceholderText = "🔍 بحث عن ميزة..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(110, 120, 135)
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.TextSize = 12
SearchBox.Font = Enum.Font.GothamMedium
SearchBox.Parent = Header

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 8)
SearchCorner.Parent = SearchBox

local SearchStroke = Instance.new("UIStroke")
SearchStroke.Color = Color3.fromRGB(35, 42, 52)
SearchStroke.Thickness = 1
SearchStroke.Parent = SearchBox

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(22, 26, 34)
CloseBtn.Text = "—"
CloseBtn.TextColor3 = Color3.fromRGB(200, 210, 220)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

local NotificationBell = Instance.new("TextButton")
NotificationBell.Name = "DEVIL_NotificationBell"
NotificationBell.Size = UDim2.new(0, 32, 0, 32)
NotificationBell.Position = UDim2.new(1, -292, 0.5, -16)
NotificationBell.BackgroundColor3 = Color3.fromRGB(18, 28, 48)
NotificationBell.BorderSizePixel = 0
NotificationBell.Text = "🔔"
NotificationBell.TextSize = 15
NotificationBell.ZIndex = 5
NotificationBell.Parent = Header
local NotificationBellCorner = Instance.new("UICorner")
NotificationBellCorner.CornerRadius = UDim.new(0, 9)
NotificationBellCorner.Parent = NotificationBell
local NotificationBellStroke = Instance.new("UIStroke")
NotificationBellStroke.Color = CurrentAccent
NotificationBellStroke.Thickness = 1.2
NotificationBellStroke.Transparency = 0.18
NotificationBellStroke.Parent = NotificationBell
RegisterThemeElement(NotificationBellStroke, "Stroked")
local NotificationBadge = Instance.new("TextLabel")
NotificationBadge.Size = UDim2.new(0, 14, 0, 14)
NotificationBadge.Position = UDim2.new(1, -9, 0, -5)
NotificationBadge.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
NotificationBadge.Text = "1"
NotificationBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
NotificationBadge.TextSize = 9
NotificationBadge.Font = Enum.Font.GothamBold
NotificationBadge.ZIndex = 6
NotificationBadge.Parent = NotificationBell
local NotificationBadgeCorner = Instance.new("UICorner")
NotificationBadgeCorner.CornerRadius = UDim.new(1, 0)
NotificationBadgeCorner.Parent = NotificationBadge
NotificationBell.MouseButton1Click:Connect(function()
    PlayClick()
    if Notify then Notify("🔔 إشعار جديد — تم تفعيل الحماية بنجاح", Color3.fromRGB(80, 220, 160)) end
end)

local HeaderLine = Instance.new("Frame")
HeaderLine.Size = UDim2.new(1, -24, 0, 1)
HeaderLine.Position = UDim2.new(0, 12, 0, 50)
HeaderLine.BackgroundColor3 = CurrentAccent
HeaderLine.BackgroundTransparency = 0.8
HeaderLine.BorderSizePixel = 0
HeaderLine.Parent = MainFrame
RegisterThemeElement(HeaderLine, "BackgroundColored")

-- ==========================================
-- 7. الشريط الجانبي والتابات (Sidebar & Tabs)
-- ==========================================
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(1, -24, 0, 40)
Sidebar.Position = UDim2.new(0, 12, 0, 58)
Sidebar.BackgroundTransparency = 1
Sidebar.Parent = MainFrame

local SidebarList = Instance.new("UIListLayout")
SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
SidebarList.Padding = UDim.new(0, 4)
SidebarList.FillDirection = Enum.FillDirection.Horizontal
SidebarList.Parent = Sidebar

local NoResultsLabel = Instance.new("TextLabel")
NoResultsLabel.Name = "NoResults"
NoResultsLabel.Size = UDim2.new(1, 0, 0, 50)
NoResultsLabel.Position = UDim2.new(0, 0, 0.5, -25)
NoResultsLabel.BackgroundTransparency = 1
NoResultsLabel.Text = "لا توجد نتائج مطابقة للبحث"
NoResultsLabel.TextColor3 = Color3.fromRGB(150, 165, 180)
NoResultsLabel.TextSize = 14
NoResultsLabel.Font = Enum.Font.GothamBold
NoResultsLabel.Visible = false
NoResultsLabel.ZIndex = 10
NoResultsLabel.Parent = MainFrame

local PageContainer = Instance.new("Frame")
PageContainer.Size = UDim2.new(1, -24, 1, -116)
PageContainer.Position = UDim2.new(0, 12, 0, 108)
PageContainer.BackgroundTransparency = 1
PageContainer.Parent = MainFrame

local Tabs = {}
local Pages = {}
local AllCards = {}

local function CreateTab(name, iconText)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(0, 108, 0, 36)
    TabBtn.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
    TabBtn.BorderSizePixel = 0
    TabBtn.Text = "  " .. iconText .. " " .. name
    TabBtn.TextColor3 = Color3.fromRGB(140, 150, 165)
    TabBtn.TextSize = 12
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.TextXAlignment = Enum.TextXAlignment.Left
    TabBtn.Parent = Sidebar

    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 8)
    TabCorner.Parent = TabBtn

    local TabStroke = Instance.new("UIStroke")
    TabStroke.Color = CurrentAccent
    TabStroke.Thickness = 1
    TabStroke.Transparency = 1
    TabStroke.Parent = TabBtn

    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageColor3 = CurrentAccent
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.Visible = false
    Page.Parent = PageContainer
    RegisterThemeElement(Page, "BackgroundColored")

    local PageList = Instance.new("UIListLayout")
    PageList.SortOrder = Enum.SortOrder.LayoutOrder
    PageList.Padding = UDim.new(0, 8)
    PageList.Parent = Page

    -- DEVIL 3D tab motion: active glow + sliding page transition.
    local TabDepth = Instance.new("Frame")
    TabDepth.Name = "DEVIL_TabDepth"
    TabDepth.Size = UDim2.new(1, 5, 1, 5)
    TabDepth.Position = UDim2.new(0, 4, 0, 5)
    TabDepth.BackgroundColor3 = CurrentAccent
    TabDepth.BackgroundTransparency = 0.9
    TabDepth.BorderSizePixel = 0
    TabDepth.ZIndex = 0
    TabDepth.Parent = TabBtn
    local TabDepthCorner = Instance.new("UICorner")
    TabDepthCorner.CornerRadius = UDim.new(0, 9)
    TabDepthCorner.Parent = TabDepth

    local TabGlow = Instance.new("Frame")
    TabGlow.Name = "DEVIL_TabGlow"
    TabGlow.Size = UDim2.new(0, 3, 1, -10)
    TabGlow.Position = UDim2.new(0, 5, 0, 5)
    TabGlow.BackgroundColor3 = CurrentAccent
    TabGlow.BackgroundTransparency = 1
    TabGlow.BorderSizePixel = 0
    TabGlow.ZIndex = 3
    TabGlow.Parent = TabBtn
    local TabGlowCorner = Instance.new("UICorner")
    TabGlowCorner.CornerRadius = UDim.new(1, 0)
    TabGlowCorner.Parent = TabGlow
    RegisterThemeElement(TabGlow, "BackgroundColored")
    RegisterThemeElement(TabDepth, "BackgroundColored")

    TabBtn.MouseEnter:Connect(function()
        if AnimationEnabled then
            TweenService:Create(TabBtn, TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(TabBtn.Position.X.Scale, TabBtn.Position.X.Offset + 3, TabBtn.Position.Y.Scale, TabBtn.Position.Y.Offset)
            }):Play()
            TweenService:Create(TabDepth, TweenInfo.new(0.16), {BackgroundTransparency = 0.72}):Play()
        end
        TweenService:Create(TabGlow, TweenInfo.new(0.16), {BackgroundTransparency = 0.15}):Play()
    end)
    TabBtn.MouseLeave:Connect(function()
        if AnimationEnabled then
            TweenService:Create(TabBtn, TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(TabBtn.Position.X.Scale, TabBtn.Position.X.Offset - 3, TabBtn.Position.Y.Scale, TabBtn.Position.Y.Offset)
            }):Play()
            TweenService:Create(TabDepth, TweenInfo.new(0.16), {BackgroundTransparency = 0.9}):Play()
        end
        if TabBtn:GetAttribute("DEVIL_Active") then
            TweenService:Create(TabGlow, TweenInfo.new(0.16), {BackgroundTransparency = 0.15}):Play()
        else
            TweenService:Create(TabGlow, TweenInfo.new(0.16), {BackgroundTransparency = 1}):Play()
        end
    end)

    TabBtn.MouseButton1Click:Connect(function()
        PlayClick()

        local targetIndex = table.find(Tabs, TabBtn) or 1
        local currentIndex = DEVIL_EXTRA and DEVIL_EXTRA.State and DEVIL_EXTRA.State.ActiveTabIndex or 1
        local direction = targetIndex >= currentIndex and 1 or -1
        if DEVIL_EXTRA and DEVIL_EXTRA.State then
            DEVIL_EXTRA.State.ActiveTabIndex = targetIndex
        end

        for _, btn in pairs(Tabs) do
            btn:SetAttribute("DEVIL_Active", false)
            TweenService:Create(btn, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundColor3 = Color3.fromRGB(18, 22, 28),
                TextColor3 = Color3.fromRGB(140, 150, 165)
            }):Play()
            local stroke = btn:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Transparency = 1
            end
            local glow = btn:FindFirstChild("DEVIL_TabGlow")
            if glow then
                TweenService:Create(glow, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
            end
        end

        for _, otherPage in pairs(Pages) do
            if otherPage ~= Page then
                otherPage.Visible = false
            end
        end

        TabBtn:SetAttribute("DEVIL_Active", true)
        TweenService:Create(TabBtn, TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(27, 36, 52),
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
        TabStroke.Transparency = 0.18
        TweenService:Create(TabGlow, TweenInfo.new(0.22), {BackgroundTransparency = 0.08}):Play()

        Page.Visible = true
        local startX = direction * 42
        Page.Position = UDim2.new(0, startX, 0, 0)
        Page.BackgroundTransparency = 0.25
        if AnimationEnabled then
            TweenService:Create(Page, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1
            }):Play()
        else
            Page.Position = UDim2.new(0, 0, 0, 0)
            Page.BackgroundTransparency = 1
        end
    end)

    table.insert(Tabs, TabBtn)
    table.insert(Pages, Page)

    return Page, TabBtn
end

local HomePage, TabHome = CreateTab("الرئيسية", "⌂")
local FavoritesPage, TabFav = CreateTab("المفضلة", "⭐")
local ScriptsPage, Tab1 = CreateTab("السكربتات", "📜")
local FixesPage, Tab2 = CreateTab("التعديلات", "🛠️")
local ThemePage, Tab3 = CreateTab("الثيمات", "🎨")
local BackgroundPage, Tab4 = CreateTab("الخلفيات", "🖼️")
local SettingsPage, Tab5 = CreateTab("الإعدادات", "⚙")

-- ==========================================
-- DEVIL HOME HERO PANEL (visual-only dashboard)
-- ==========================================
local HomeHero = Instance.new("Frame")
HomeHero.Name = "DEVIL_PlayerDashboard"
HomeHero.Size = UDim2.new(1, -6, 0, 168)
HomeHero.BackgroundColor3 = Color3.fromRGB(13, 23, 40)
HomeHero.BackgroundTransparency = 0.06
HomeHero.BorderSizePixel = 0
HomeHero.LayoutOrder = 0
HomeHero.Parent = HomePage
local HomeHeroGradient = Instance.new("UIGradient")
HomeHeroGradient.Color = ColorSequence.new(Color3.fromRGB(24, 48, 82), Color3.fromRGB(33, 16, 55))
HomeHeroGradient.Rotation = 18
HomeHeroGradient.Transparency = NumberSequence.new(0.12)
HomeHeroGradient.Parent = HomeHero
local HomeHeroCorner = Instance.new("UICorner")
HomeHeroCorner.CornerRadius = UDim.new(0, 16)
HomeHeroCorner.Parent = HomeHero
local HomeHeroStroke = Instance.new("UIStroke")
HomeHeroStroke.Color = CurrentAccent
HomeHeroStroke.Thickness = 1.5
HomeHeroStroke.Transparency = 0.12
HomeHeroStroke.Parent = HomeHero
RegisterThemeElement(HomeHeroStroke, "Stroked")
local HeroTitle = Instance.new("TextLabel")
HeroTitle.Size = UDim2.new(1, -120, 0, 24)
HeroTitle.Position = UDim2.new(0, 18, 0, 12)
HeroTitle.BackgroundTransparency = 1
HeroTitle.Text = "معلومات اللاعب"
HeroTitle.TextColor3 = Color3.fromRGB(242, 247, 255)
HeroTitle.TextSize = 15
HeroTitle.Font = Enum.Font.GothamBold
HeroTitle.TextXAlignment = Enum.TextXAlignment.Right
HeroTitle.Parent = HomeHero
local HeroAvatar = Instance.new("ImageLabel")
HeroAvatar.Size = UDim2.new(0, 62, 0, 62)
HeroAvatar.Position = UDim2.new(1, -82, 0, 44)
HeroAvatar.BackgroundColor3 = Color3.fromRGB(20, 30, 48)
HeroAvatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
HeroAvatar.ScaleType = Enum.ScaleType.Crop
HeroAvatar.Parent = HomeHero
local HeroAvatarCorner = Instance.new("UICorner")
HeroAvatarCorner.CornerRadius = UDim.new(1, 0)
HeroAvatarCorner.Parent = HeroAvatar
local HeroAvatarStroke = Instance.new("UIStroke")
HeroAvatarStroke.Color = CurrentAccent
HeroAvatarStroke.Thickness = 2
HeroAvatarStroke.Parent = HeroAvatar
RegisterThemeElement(HeroAvatarStroke, "Stroked")
local HeroName = Instance.new("TextLabel")
HeroName.Size = UDim2.new(0, 250, 0, 23)
HeroName.Position = UDim2.new(1, -350, 0, 48)
HeroName.BackgroundTransparency = 1
HeroName.Text = LocalPlayer.DisplayName
HeroName.TextColor3 = Color3.fromRGB(255, 255, 255)
HeroName.TextSize = 16
HeroName.Font = Enum.Font.GothamBold
HeroName.TextXAlignment = Enum.TextXAlignment.Right
HeroName.Parent = HomeHero
local HeroStatus = Instance.new("TextLabel")
HeroStatus.Size = UDim2.new(0, 250, 0, 20)
HeroStatus.Position = UDim2.new(1, -350, 0, 74)
HeroStatus.BackgroundTransparency = 1
HeroStatus.Text = "● متصل الآن  •  ID: " .. tostring(LocalPlayer.UserId)
HeroStatus.TextColor3 = Color3.fromRGB(80, 220, 160)
HeroStatus.TextSize = 11
HeroStatus.Font = Enum.Font.GothamMedium
HeroStatus.TextXAlignment = Enum.TextXAlignment.Right
HeroStatus.Parent = HomeHero

local function HeroStat(x, label, value, color)
    local stat = Instance.new("Frame")
    stat.Size = UDim2.new(0, 170, 0, 56)
    stat.Position = UDim2.new(0, x, 1, -68)
    stat.BackgroundColor3 = Color3.fromRGB(12, 21, 37)
    stat.BackgroundTransparency = 0.1
    stat.BorderSizePixel = 0
    stat.Parent = HomeHero
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = stat
    local st = Instance.new("UIStroke")
    st.Color = color
    st.Transparency = 0.35
    st.Parent = stat
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -16, 0, 18)
    l.Position = UDim2.new(0, 8, 0, 7)
    l.BackgroundTransparency = 1
    l.Text = label
    l.TextColor3 = Color3.fromRGB(160, 177, 204)
    l.TextSize = 10
    l.Font = Enum.Font.GothamMedium
    l.TextXAlignment = Enum.TextXAlignment.Right
    l.Parent = stat
    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(1, -16, 0, 24)
    v.Position = UDim2.new(0, 8, 0, 25)
    v.BackgroundTransparency = 1
    v.Text = value
    v.TextColor3 = color
    v.TextSize = 16
    v.Font = Enum.Font.GothamBold
    v.TextXAlignment = Enum.TextXAlignment.Right
    v.Parent = stat
    return v
end

local HeroHealthValue = HeroStat(18, "الصحة", "—", Color3.fromRGB(255, 92, 116))
local HeroShieldValue = HeroStat(204, "الدرع", "—", Color3.fromRGB(71, 188, 255))
local HeroPointsValue = HeroStat(390, "النقاط", "—", Color3.fromRGB(255, 202, 78))

local function FindPlayerValue(names)
    local containers = {LocalPlayer:FindFirstChild("leaderstats"), LocalPlayer}
    for _, container in ipairs(containers) do
        if container then
            for _, name in ipairs(names) do
                local item = container:FindFirstChild(name)
                if item and (item:IsA("NumberValue") or item:IsA("IntValue") or item:IsA("StringValue")) then
                    return item
                end
            end
        end
    end
end

local function BindRealPlayerInfo()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
    local function refreshHealth()
        if not humanoid then return end
        local maxHealth = math.max(humanoid.MaxHealth, 1)
        HeroHealthValue.Text = string.format("%d%%", math.floor(math.clamp(humanoid.Health / maxHealth, 0, 1) * 100 + 0.5))
    end
    if humanoid then
        refreshHealth()
        humanoid.HealthChanged:Connect(refreshHealth)
        humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(refreshHealth)
    end
    local shield = FindPlayerValue({"Shield", "Armor", "Armour"})
    local points = FindPlayerValue({"Points", "Score", "Cash", "Coins"})
    if shield then
        HeroShieldValue.Text = tostring(shield.Value)
        shield.Changed:Connect(function(value) HeroShieldValue.Text = tostring(value) end)
    end
    if points then
        HeroPointsValue.Text = tostring(points.Value)
        points.Changed:Connect(function(value) HeroPointsValue.Text = tostring(value) end)
    end
end

task.spawn(function()
    pcall(BindRealPlayerInfo)
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.25)
        pcall(BindRealPlayerInfo)
    end)
end)

local function BuildReal3DPreview()
    if not HomeHero or not HeroAvatar then return end
    HeroAvatar.Visible = false
    local viewport = Instance.new("ViewportFrame")
    viewport.Name = "RealPlayer3D"
    viewport.Size = UDim2.new(0, 74, 0, 74)
    viewport.Position = UDim2.new(1, -88, 0, 40)
    viewport.BackgroundColor3 = Color3.fromRGB(8, 15, 28)
    viewport.BackgroundTransparency = 0.05
    viewport.BorderSizePixel = 0
    viewport.Ambient = Color3.fromRGB(180, 210, 255)
    viewport.LightColor = Color3.fromRGB(255, 255, 255)
    viewport.LightDirection = Vector3.new(-1, -1, -1)
    viewport.Parent = HomeHero
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = viewport
    local stroke = Instance.new("UIStroke")
    stroke.Color = CurrentAccent
    stroke.Thickness = 2
    stroke.Parent = viewport
    RegisterThemeElement(stroke, "Stroked")
    local world = Instance.new("WorldModel")
    world.Parent = viewport
    local camera = Instance.new("Camera")
    camera.FieldOfView = 30
    camera.Parent = viewport
    viewport.CurrentCamera = camera
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local previous = character.Archivable
    character.Archivable = true
    local clone = character:Clone()
    character.Archivable = previous
    if not clone then return end
    for _, object in ipairs(clone:GetDescendants()) do
        if object:IsA("Script") or object:IsA("LocalScript") or object:IsA("ModuleScript") then
            object:Destroy()
        elseif object:IsA("BasePart") then
            object.Anchored = true
            object.CanCollide = false
        end
    end
    clone.Parent = world
    clone:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(180), 0))
    camera.CFrame = CFrame.new(Vector3.new(0, 2.1, 6), Vector3.new(0, 1.4, 0))
end

task.spawn(function() pcall(BuildReal3DPreview) end)

-- ==========================================
-- 8. صانع الكروت (Cards Engine)
-- ==========================================
local function CreateCard(parentPage, titleText, descText, btnText, callback)
    local Card = Instance.new("Frame")
    Card.Name = titleText
    Card.Size = UDim2.new(1, -6, 0, 60)
    Card.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
    Card.BackgroundTransparency = 0.22
    Card.BorderSizePixel = 0
    Card.Parent = parentPage

    local CardGradient = Instance.new("UIGradient")
    CardGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 43, 70)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(14, 23, 39)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(39, 19, 56))
    })
    CardGradient.Rotation = 14
    CardGradient.Transparency = NumberSequence.new(0.16)
    CardGradient.Parent = Card

    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 9)
    CardCorner.Parent = Card

    local CardStroke = Instance.new("UIStroke")
    CardStroke.Color = Color3.fromRGB(32, 38, 48)
    CardStroke.Thickness = 1
    CardStroke.Parent = Card

    local StarBtn = Instance.new("TextButton")
    StarBtn.Size = UDim2.new(0, 24, 0, 24)
    StarBtn.Position = UDim2.new(0, 8, 0.5, -12)
    StarBtn.BackgroundTransparency = 1
    StarBtn.Text = "★"
    StarBtn.TextColor3 = Color3.fromRGB(80, 90, 105)
    StarBtn.TextSize = 16
    StarBtn.Font = Enum.Font.GothamBold
    StarBtn.Parent = Card
    AddButtonMotion(StarBtn)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(0.55, 0, 0, 20)
    TitleLabel.Position = UDim2.new(0, 36, 0, 10)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = titleText
    TitleLabel.TextColor3 = Color3.fromRGB(240, 245, 250)
    TitleLabel.TextSize = 13
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Card

    local DescLabel = Instance.new("TextLabel")
    DescLabel.Size = UDim2.new(0.55, 0, 0, 18)
    DescLabel.Position = UDim2.new(0, 36, 0, 30)
    DescLabel.BackgroundTransparency = 1
    DescLabel.Text = descText
    DescLabel.TextColor3 = Color3.fromRGB(130, 140, 155)
    DescLabel.TextSize = 10
    DescLabel.Font = Enum.Font.GothamMedium
    DescLabel.TextXAlignment = Enum.TextXAlignment.Left
    DescLabel.Parent = Card

    local ActionBtn = Instance.new("TextButton")
    ActionBtn.Size = UDim2.new(0, 80, 0, 32)
    ActionBtn.Position = UDim2.new(1, -90, 0.5, -16)
    ActionBtn.BackgroundColor3 = CurrentAccent
    ActionBtn.BackgroundTransparency = 0.08
    ActionBtn.BorderSizePixel = 0
    ActionBtn.Text = btnText
    ActionBtn.TextColor3 = Color3.fromRGB(12, 15, 20)
    ActionBtn.TextSize = 12
    ActionBtn.Font = Enum.Font.GothamBold
    ActionBtn.Parent = Card
    AddButtonMotion(ActionBtn)
    RegisterThemeElement(ActionBtn, "BackgroundColored")

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 7)
    BtnCorner.Parent = ActionBtn

    local isFavorite = false

    StarBtn.MouseButton1Click:Connect(function()
        PlayClick()
        isFavorite = not isFavorite
        if isFavorite then
            StarBtn.TextColor3 = Color3.fromRGB(255, 200, 60)
            Card.Parent = FavoritesPage
        else
            StarBtn.TextColor3 = Color3.fromRGB(80, 90, 105)
            Card.Parent = parentPage
        end
    end)

    ActionBtn.MouseButton1Click:Connect(function()
        PlayClick()
        TweenService:Create(ActionBtn, TweenInfo.new(0.1), {Size = UDim2.new(0, 74, 0, 28)}):Play()
        task.wait(0.1)
        TweenService:Create(ActionBtn, TweenInfo.new(0.1), {Size = UDim2.new(0, 80, 0, 32)}):Play()
        callback(ActionBtn, CardStroke)
        if Notify then Notify("✓ تم تنفيذ: " .. titleText, CurrentAccent) end
    end)

    table.insert(AllCards, {Card = Card, Title = titleText, Desc = descText, OriginalParent = parentPage})

    return Card
end

-- Dashboard cards
CreateCard(HomePage, "مرحباً، " .. LocalPlayer.DisplayName, "MUSAED HUB جاهز للعمل • " .. HUB_VERSION, "فتح", function()
    Notify("ℹ لوحة التحكم جاهزة", CurrentAccent)
end)
CreateCard(HomePage, "حالة النظام", "الاتصال: ONLINE • اللاعب: " .. LocalPlayer.Name, "تحديث", function()
    Notify("✓ النظام يعمل بشكل طبيعي", Color3.fromRGB(80, 220, 160))
end)
CreateCard(HomePage, "الخلفية الحالية", "تغيير سريع للخلفية من صفحة الخلفيات", "تغيير", function()
    ApplySelectedBackground((SelectedBackground % #Backgrounds) + 1)
    Notify("🖼 تم تغيير الخلفية", CurrentAccent)
end)
CreateCard(HomePage, "آخر التحديثات", "خلفيات محسّنة • أصوات • أنيميشن • واجهة أكبر", "حسنًا", function()
    Notify("✓ أنت تستخدم أحدث إصدار " .. HUB_VERSION, CurrentAccent)
end)

-- Settings cards
CreateCard(SettingsPage, "الصوت", "تشغيل أو إيقاف أصوات الواجهة", "تشغيل", function(btn)
    SoundEnabled = not SoundEnabled
    btn.Text = SoundEnabled and "إيقاف" or "تشغيل"
    Notify(SoundEnabled and "🔊 تم تشغيل الصوت" or "🔇 تم إيقاف الصوت", CurrentAccent)
end)
CreateCard(SettingsPage, "الأنيميشن", "تفعيل حركات الأزرار والانتقالات", "تشغيل", function(btn)
    AnimationEnabled = not AnimationEnabled
    btn.Text = AnimationEnabled and "إيقاف" or "تشغيل"
    Notify(AnimationEnabled and "✨ تم تشغيل الأنيميشن" or "تم إيقاف الأنيميشن", CurrentAccent)
end)
CreateCard(SettingsPage, "الخلفية المتحركة", "تحريك الخلفية بشكل بطيء وناعم", "تشغيل", function(btn)
    BackgroundMotionEnabled = not BackgroundMotionEnabled
    btn.Text = BackgroundMotionEnabled and "إيقاف" or "تشغيل"
    Notify(BackgroundMotionEnabled and "🖼 تم تشغيل حركة الخلفية" or "تم إيقاف حركة الخلفية", CurrentAccent)
end)
CreateCard(SettingsPage, "حجم الواجهة", "التبديل بين حجم مناسب للشاشة", "تغيير", function()
    local camera = workspace.CurrentCamera
    if camera then
        local current = MainScale.Scale
        MainScale.Scale = current >= 1.05 and 0.82 or 1.08
        Notify("↔ تم تغيير حجم الواجهة", CurrentAccent)
    end
end)
CreateCard(SettingsPage, "إعادة ضبط", "إرجاع الثيم والخلفية والإعدادات الافتراضية", "إعادة", function()
    SoundEnabled = true
    AnimationEnabled = true
    BackgroundMotionEnabled = true
    UpdateTheme(Color3.fromRGB(52, 182, 189))
    ApplySelectedBackground(1)
    Notify("↻ تمت إعادة ضبط الإعدادات", CurrentAccent)
end)

-- ==========================================
-- 9. البروفايل (Player Profile)
-- ==========================================
local ProfileFrame = Instance.new("Frame")
ProfileFrame.Size = UDim2.new(0, 205, 0, 60)
ProfileFrame.Position = UDim2.new(0, 12, 1, -72)
ProfileFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
ProfileFrame.BackgroundTransparency = 0.18
ProfileFrame.BorderSizePixel = 0
ProfileFrame.Parent = MainFrame

local ProfileGradient = Instance.new("UIGradient")
ProfileGradient.Color = ColorSequence.new(Color3.fromRGB(21, 35, 58), Color3.fromRGB(31, 17, 49))
ProfileGradient.Rotation = 18
ProfileGradient.Transparency = NumberSequence.new(0.12)
ProfileGradient.Parent = ProfileFrame

local ProfileCorner = Instance.new("UICorner")
ProfileCorner.CornerRadius = UDim.new(0, 10)
ProfileCorner.Parent = ProfileFrame

local ProfileStroke = Instance.new("UIStroke")
ProfileStroke.Color = CurrentAccent
ProfileStroke.Thickness = 1
ProfileStroke.Transparency = 0.5
ProfileStroke.Parent = ProfileFrame
RegisterThemeElement(ProfileStroke, "Stroked")

local AvatarImg = Instance.new("ImageLabel")
AvatarImg.Size = UDim2.new(0, 46, 0, 46)
AvatarImg.Position = UDim2.new(0, 7, 0.5, -23)
AvatarImg.BackgroundColor3 = Color3.fromRGB(25, 30, 38)
AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=100&h=100"
AvatarImg.Parent = ProfileFrame

local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(1, 0)
AvatarCorner.Parent = AvatarImg

local PlayerName = Instance.new("TextLabel")
PlayerName.Size = UDim2.new(0, 145, 0, 18)
PlayerName.Position = UDim2.new(0, 62, 0, 9)
PlayerName.BackgroundTransparency = 1
PlayerName.Text = LocalPlayer.DisplayName
PlayerName.TextColor3 = Color3.fromRGB(240, 245, 250)
PlayerName.TextSize = 11
PlayerName.Font = Enum.Font.GothamBold
PlayerName.TextXAlignment = Enum.TextXAlignment.Left
PlayerName.Parent = ProfileFrame

local UserHandle = Instance.new("TextLabel")
UserHandle.Size = UDim2.new(0, 145, 0, 14)
UserHandle.Position = UDim2.new(0, 62, 0, 29)
UserHandle.BackgroundTransparency = 1
UserHandle.Text = "@" .. LocalPlayer.Name
UserHandle.TextColor3 = Color3.fromRGB(120, 130, 145)
UserHandle.TextSize = 9
UserHandle.Font = Enum.Font.GothamMedium
UserHandle.TextXAlignment = Enum.TextXAlignment.Left
UserHandle.Parent = ProfileFrame

-- ==========================================
-- 10. السكربتات والتعديلات والميزات
-- ==========================================
local function RunRemoteScript(url)
    if type(loadstring) ~= "function" then
        if Notify then Notify("✕ loadstring غير متاح في هذه البيئة", Color3.fromRGB(231, 76, 60)) end
        return false
    end

    local body
    local lastError = "تعذر تحميل الرابط"
    local httpRequest = request or http_request or (syn and syn.request) or (http and http.request)

    if type(httpRequest) == "function" then
        local ok, response = pcall(function()
            return httpRequest({Url = url, Method = "GET"})
        end)
        if ok and response and response.Body and (not response.StatusCode or response.StatusCode < 400) then
            body = response.Body
        elseif not ok then
            lastError = tostring(response)
        end
    end

    if not body then
        local HttpService = game:GetService("HttpService")
        local ok, result = pcall(function()
            return HttpService:GetAsync(url)
        end)
        if ok then
            body = result
        else
            lastError = tostring(result)
        end
    end

    if not body or body == "" then
        if Notify then Notify("✕ فشل تحميل السكربت: " .. lastError, Color3.fromRGB(231, 76, 60)) end
        return false
    end

    local chunk, compileError = loadstring(body)
    if not chunk then
        if Notify then Notify("✕ خطأ في كود السكربت البعيد", Color3.fromRGB(231, 76, 60)) end
        warn(compileError)
        return false
    end

    local ok, runtimeError = pcall(chunk)
    if not ok then
        if Notify then Notify("✕ حدث خطأ أثناء تشغيل السكربت", Color3.fromRGB(231, 76, 60)) end
        warn(runtimeError)
        return false
    end

    if Notify then Notify("✓ تم تشغيل السكربت", Color3.fromRGB(80, 220, 160)) end
    return true
end

CreateCard(ScriptsPage, "السكربت الرئيسي", "تشغيل سكربت musaed.lua الأصلي", "تشغيل", function()
    RunRemoteScript("https://raw.githubusercontent.com/musaed807/codex.lua/refs/heads/main/musaed.lua")
end)

CreateCard(ScriptsPage, "DevilSight Plus", "تشغيل سكربت DevilSight Plus", "تشغيل", function()
    RunRemoteScript("https://raw.githubusercontent.com/musaed807/DEVILSG/refs/heads/main/NOKEY%2B")
end)

CreateCard(ScriptsPage, "DevilSight", "تشغيل سكربت DevilSight", "تشغيل", function()
    RunRemoteScript("https://raw.githubusercontent.com/musaed807/DEVILSG/refs/heads/main/NOKEY")
end)

CreateCard(ScriptsPage, "السكربت الثاني", "تشغيل النسخة الإضافية (18)", "تشغيل", function()
    RunRemoteScript("https://raw.githubusercontent.com/musaed807/codex.lua/refs/heads/main/18")
end)

CreateCard(ScriptsPage, "التحكم في جرفكس اللعبه", "جرفكس", "تشغيل", function()
    RunRemoteScript("https://pastebin.com/raw/qjT0fUm1")
end)

-- 1. إزالة طلقات وهمية
local ShotFixConnection = nil
local ShotFixEnabled = false

CreateCard(FixesPage, "إزالة طلقات وهميه", "تعديل الكاميرا والـ Resolution", "تفعيل", function(btn, stroke)
    ShotFixEnabled = not ShotFixEnabled
    if ShotFixEnabled then
        btn.Text = "إيقاف"
        btn.BackgroundColor3 = Color3.fromRGB(225, 75, 75)
        stroke.Color = CurrentAccent
        getgenv().Resolution = {[".gg/scripters"] = 0.65}
        local Camera = workspace.CurrentCamera
        if ShotFixConnection == nil then
            ShotFixConnection = RunService.RenderStepped:Connect(function()
                Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, getgenv().Resolution[".gg/scripters"], 0, 0, 0, 1)
            end)
        end
    else
        btn.Text = "تفعيل"
        btn.BackgroundColor3 = CurrentAccent
        stroke.Color = Color3.fromRGB(32, 38, 48)
        if ShotFixConnection then
            ShotFixConnection:Disconnect()
            ShotFixConnection = nil
        end
    end
end)

-- 2. القفز اللانهائي (Infinite Jump)
local InfJumpEnabled = false
local InfJumpConnection = nil

CreateCard(FixesPage, "قفز لا نهائي", "إمكانية القفز المستمر في الهواء", "تفعيل", function(btn, stroke)
    InfJumpEnabled = not InfJumpEnabled
    if InfJumpEnabled then
        btn.Text = "إيقاف"
        btn.BackgroundColor3 = Color3.fromRGB(225, 75, 75)
        stroke.Color = CurrentAccent
        InfJumpConnection = UserInputService.JumpRequest:Connect(function()
            if InfJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
            end
        end)
    else
        btn.Text = "تفعيل"
        btn.BackgroundColor3 = CurrentAccent
        stroke.Color = Color3.fromRGB(32, 38, 48)
        if InfJumpConnection then
            InfJumpConnection:Disconnect()
            InfJumpConnection = nil
        end
    end
end)

-- 3. زيادة السرعة (Speed Boost)
local SpeedEnabled = false

CreateCard(FixesPage, "زيادة السرعة", "تغيير سرعة الحركة إلى 32", "تفعيل", function(btn, stroke)
    SpeedEnabled = not SpeedEnabled
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        if SpeedEnabled then
            btn.Text = "إيقاف"
            btn.BackgroundColor3 = Color3.fromRGB(225, 75, 75)
            stroke.Color = CurrentAccent
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 32
        else
            btn.Text = "تفعيل"
            btn.BackgroundColor3 = CurrentAccent
            stroke.Color = Color3.fromRGB(32, 38, 48)
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
        end
    end
end)

-- 4. إضاءة كاملة (Fullbright)
local FullbrightEnabled = false
local OldBrightness = Lighting.Brightness
local OldClockTime = Lighting.ClockTime
local OldGlobalShadows = Lighting.GlobalShadows

CreateCard(FixesPage, "إضاءة كاملة", "إلغاء الظلام ووضوح الرؤية الكامل", "تفعيل", function(btn, stroke)
    FullbrightEnabled = not FullbrightEnabled
    if FullbrightEnabled then
        btn.Text = "إيقاف"
        btn.BackgroundColor3 = Color3.fromRGB(225, 75, 75)
        stroke.Color = CurrentAccent
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    else
        btn.Text = "تفعيل"
        btn.BackgroundColor3 = CurrentAccent
        stroke.Color = Color3.fromRGB(32, 38, 48)
        Lighting.Brightness = OldBrightness
        Lighting.ClockTime = OldClockTime
        Lighting.GlobalShadows = OldGlobalShadows
    end
end)

-- 5. كاشف اللاعبين (ESP Highlight)
local EspEnabled = false
local EspHighlights = {}

CreateCard(FixesPage, "كاشف اللاعبين (ESP)", "إظهار حدود اللاعبين عبر الجدران", "تفعيل", function(btn, stroke)
    EspEnabled = not EspEnabled
    if EspEnabled then
        btn.Text = "إيقاف"
        btn.BackgroundColor3 = Color3.fromRGB(225, 75, 75)
        stroke.Color = CurrentAccent
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local highlight = Instance.new("Highlight")
                highlight.Name = "MusaedESP"
                highlight.FillColor = CurrentAccent
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.5
                highlight.Parent = plr.Character
                table.insert(EspHighlights, highlight)
            end
        end
    else
        btn.Text = "تفعيل"
        btn.BackgroundColor3 = CurrentAccent
        stroke.Color = Color3.fromRGB(32, 38, 48)
        for _, hl in ipairs(EspHighlights) do
            if hl and hl.Parent then
                hl:Destroy()
            end
        end
        EspHighlights = {}
    end
end)

-- 6. تخطي الجدران (Noclip)
local NoclipEnabled = false
local NoclipConnection = nil

CreateCard(FixesPage, "تخطي الجدران (Noclip)", "المرور عبر الحوائط والأجسام الصلبة", "تفعيل", function(btn, stroke)
    NoclipEnabled = not NoclipEnabled
    if NoclipEnabled then
        btn.Text = "إيقاف"
        btn.BackgroundColor3 = Color3.fromRGB(225, 75, 75)
        stroke.Color = CurrentAccent
        NoclipConnection = RunService.Stepped:Connect(function()
            if LocalPlayer.Character then
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        btn.Text = "تفعيل"
        btn.BackgroundColor3 = CurrentAccent
        stroke.Color = Color3.fromRGB(32, 38, 48)
        if NoclipConnection then
            NoclipConnection:Disconnect()
            NoclipConnection = nil
        end
    end
end)

-- 7. قوة القفز (Jump Boost)
local JumpBoostEnabled = false

CreateCard(FixesPage, "زيادة ارتفاع القفز", "رفع قوة القفز إلى 100", "تفعيل", function(btn, stroke)
    JumpBoostEnabled = not JumpBoostEnabled
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if JumpBoostEnabled then
            btn.Text = "إيقاف"
            btn.BackgroundColor3 = Color3.fromRGB(225, 75, 75)
            stroke.Color = CurrentAccent
            hum.UseJumpPower = true
            hum.JumpPower = 100
        else
            btn.Text = "تفعيل"
            btn.BackgroundColor3 = CurrentAccent
            stroke.Color = Color3.fromRGB(32, 38, 48)
            hum.JumpPower = 50
        end
    end
end)

-- 8. تكبير الهيت بوكس (Hitbox Expander)
local HitboxEnabled = false
local OriginalSizes = {}

CreateCard(FixesPage, "توسيع الهيت بوكس", "تكبير حجم الأعداء لسهولة التصويب", "تفعيل", function(btn, stroke)
    HitboxEnabled = not HitboxEnabled
    if HitboxEnabled then
        btn.Text = "إيقاف"
        btn.BackgroundColor3 = Color3.fromRGB(225, 75, 75)
        stroke.Color = CurrentAccent
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = plr.Character.HumanoidRootPart
                OriginalSizes[plr] = hrp.Size
                hrp.Size = Vector3.new(10, 10, 10)
                hrp.Transparency = 0.7
                hrp.BrickColor = BrickColor.new("Cyan")
                hrp.Material = Enum.Material.Neon
                hrp.CanCollide = false
            end
        end
    else
        btn.Text = "تفعيل"
        btn.BackgroundColor3 = CurrentAccent
        stroke.Color = Color3.fromRGB(32, 38, 48)
        for plr, origSize in pairs(OriginalSizes) do
            if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = plr.Character.HumanoidRootPart
                hrp.Size = origSize
                hrp.Transparency = 1
            end
        end
        OriginalSizes = {}
    end
end)

-- 9. إزالة الضباب (No Fog)
local FogEnabled = false
local OldFogEnd = Lighting.FogEnd

CreateCard(FixesPage, "إزالة الضباب", "إلغاء الضباب ورؤية الخريطة بوضوح", "تفعيل", function(btn, stroke)
    FogEnabled = not FogEnabled
    if FogEnabled then
        btn.Text = "إيقاف"
        btn.BackgroundColor3 = Color3.fromRGB(225, 75, 75)
        stroke.Color = CurrentAccent
        Lighting.FogEnd = 9e9
    else
        btn.Text = "تفعيل"
        btn.BackgroundColor3 = CurrentAccent
        stroke.Color = Color3.fromRGB(32, 38, 48)
        Lighting.FogEnd = OldFogEnd
    end
end)

-- 10. الطيران (Fly System)
local FlyEnabled = false
local FlySpeed = 50
local BodyVel, BodyGyro

CreateCard(FixesPage, "نظام الطيران (Fly)", "الطيران بحرية باستخدام مفاتيح الحركة", "تفعيل", function(btn, stroke)
    FlyEnabled = not FlyEnabled
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if FlyEnabled and hrp then
        btn.Text = "إيقاف"
        btn.BackgroundColor3 = Color3.fromRGB(225, 75, 75)
        stroke.Color = CurrentAccent
        BodyVel = Instance.new("BodyVelocity")
        BodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        BodyVel.Velocity = Vector3.new(0, 0, 0)
        BodyVel.Parent = hrp
        BodyGyro = Instance.new("BodyGyro")
        BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        BodyGyro.CFrame = hrp.CFrame
        BodyGyro.Parent = hrp
        task.spawn(function()
            while FlyEnabled and hrp and hrp.Parent do
                local cam = workspace.CurrentCamera
                local moveDir = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
                BodyVel.Velocity = moveDir * FlySpeed
                BodyGyro.CFrame = cam.CFrame
                task.wait()
            end
        end)
    else
        btn.Text = "تفعيل"
        btn.BackgroundColor3 = CurrentAccent
        stroke.Color = Color3.fromRGB(32, 38, 48)
        if BodyVel then BodyVel:Destroy() end
        if BodyGyro then BodyGyro:Destroy() end
    end
end)

-- 11. إعادة الاتصال (Rejoin Server)
CreateCard(FixesPage, "إعادة الاتصال (Rejoin)", "إعادة الدخول إلى نفس السيرفر فوراً", "تشغيل", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

-- [صفحة الثيمات]
local function CreateThemeOption(color, nameText)
    CreateCard(ThemePage, "ثيم " .. nameText, "تغيير إضاءة الواجهة إلى " .. nameText, "تطبيق", function()
        UpdateTheme(color)
    end)
end

CreateThemeOption(Color3.fromRGB(52, 182, 189), "التراكواز (افتراضي)")
CreateThemeOption(Color3.fromRGB(155, 89, 182), "البنفسجي النيون")
CreateThemeOption(Color3.fromRGB(46, 204, 113), "الأخضر الزمردي")
CreateThemeOption(Color3.fromRGB(231, 76, 60), "الأحمر الياقوتي")
CreateThemeOption(Color3.fromRGB(241, 196, 15), "الذهبي المضيء")

-- [صفحة الخلفيات]
for i, bg in ipairs(Backgrounds) do
    CreateCard(BackgroundPage, "خلفية " .. bg.Name, "تطبيق الخلفية على الواجهة كاملة", "تطبيق", function()
        ApplySelectedBackground(i)
    end)
end

-- ==========================================
-- DEVIL 3D EXPANSION PACK
-- ==========================================
_G.DEVIL_EXTRA = {Pages = {}, Tabs = {}, State = {}}
DEVIL_EXTRA = _G.DEVIL_EXTRA
DEVIL_EXTRA.State.SkinDescription = nil
DEVIL_EXTRA.State.SkinUserId = nil
DEVIL_EXTRA.State.SkinOriginal = nil

DEVIL_EXTRA.Pages.Avatar, DEVIL_EXTRA.Tabs.Avatar = CreateTab("AVATAR 3D", "🧍")
DEVIL_EXTRA.Pages.Player, DEVIL_EXTRA.Tabs.Player = CreateTab("PLAYER", "⚡")
DEVIL_EXTRA.Pages.Visuals, DEVIL_EXTRA.Tabs.Visuals = CreateTab("VISUALS", "◈")
DEVIL_EXTRA.Pages.Server, DEVIL_EXTRA.Tabs.Server = CreateTab("SERVER", "◉")
DEVIL_EXTRA.Pages.Info, DEVIL_EXTRA.Tabs.Info = CreateTab("INFO", "ⓘ")

Sidebar.Size = UDim2.new(1, -24, 0, 40)
SidebarList.Padding = UDim.new(0, 4)

-- 3D Avatar Studio
DEVIL_EXTRA.AvatarStudioFrame = Instance.new("Frame")
DEVIL_EXTRA.AvatarStudioFrame.Name = "DEVIL_AvatarStudio"
DEVIL_EXTRA.AvatarStudioFrame.Size = UDim2.new(1, -6, 0, 250)
DEVIL_EXTRA.AvatarStudioFrame.BackgroundColor3 = Color3.fromRGB(10, 18, 32)
DEVIL_EXTRA.AvatarStudioFrame.BackgroundTransparency = 0.05
DEVIL_EXTRA.AvatarStudioFrame.BorderSizePixel = 0
DEVIL_EXTRA.AvatarStudioFrame.Parent = DEVIL_EXTRA.Pages.Avatar
DEVIL_EXTRA.AvatarStudioCorner = Instance.new("UICorner")
DEVIL_EXTRA.AvatarStudioCorner.CornerRadius = UDim.new(0, 16)
DEVIL_EXTRA.AvatarStudioCorner.Parent = DEVIL_EXTRA.AvatarStudioFrame
DEVIL_EXTRA.AvatarStudioStroke = Instance.new("UIStroke")
DEVIL_EXTRA.AvatarStudioStroke.Color = CurrentAccent
DEVIL_EXTRA.AvatarStudioStroke.Thickness = 1.5
DEVIL_EXTRA.AvatarStudioStroke.Transparency = 0.15
DEVIL_EXTRA.AvatarStudioStroke.Parent = DEVIL_EXTRA.AvatarStudioFrame
RegisterThemeElement(DEVIL_EXTRA.AvatarStudioStroke, "Stroked")

DEVIL_EXTRA.AvatarInput = Instance.new("TextBox")
DEVIL_EXTRA.AvatarInput.Size = UDim2.new(0, 260, 0, 38)
DEVIL_EXTRA.AvatarInput.Position = UDim2.new(0, 18, 0, 18)
DEVIL_EXTRA.AvatarInput.BackgroundColor3 = Color3.fromRGB(18, 25, 38)
DEVIL_EXTRA.AvatarInput.BorderSizePixel = 0
DEVIL_EXTRA.AvatarInput.PlaceholderText = "Username أو UserId"
DEVIL_EXTRA.AvatarInput.PlaceholderColor3 = Color3.fromRGB(120, 135, 155)
DEVIL_EXTRA.AvatarInput.Text = ""
DEVIL_EXTRA.AvatarInput.TextColor3 = Color3.fromRGB(255,255,255)
DEVIL_EXTRA.AvatarInput.TextSize = 12
DEVIL_EXTRA.AvatarInput.Font = Enum.Font.GothamMedium
DEVIL_EXTRA.AvatarInput.Parent = DEVIL_EXTRA.AvatarStudioFrame
DEVIL_EXTRA.AvatarInputCorner = Instance.new("UICorner")
DEVIL_EXTRA.AvatarInputCorner.CornerRadius = UDim.new(0, 9)
DEVIL_EXTRA.AvatarInputCorner.Parent = DEVIL_EXTRA.AvatarInput

DEVIL_EXTRA.AvatarPreview = Instance.new("ViewportFrame")
DEVIL_EXTRA.AvatarPreview.Name = "Skin3DPreview"
DEVIL_EXTRA.AvatarPreview.Size = UDim2.new(0, 190, 0, 190)
DEVIL_EXTRA.AvatarPreview.Position = UDim2.new(1, -210, 0, 25)
DEVIL_EXTRA.AvatarPreview.BackgroundColor3 = Color3.fromRGB(5, 10, 18)
DEVIL_EXTRA.AvatarPreview.BorderSizePixel = 0
DEVIL_EXTRA.AvatarPreview.Ambient = Color3.fromRGB(170, 205, 255)
DEVIL_EXTRA.AvatarPreview.LightColor = Color3.fromRGB(255,255,255)
DEVIL_EXTRA.AvatarPreview.LightDirection = Vector3.new(-1,-1,-1)
DEVIL_EXTRA.AvatarPreview.Parent = DEVIL_EXTRA.AvatarStudioFrame
DEVIL_EXTRA.AvatarPreviewCorner = Instance.new("UICorner")
DEVIL_EXTRA.AvatarPreviewCorner.CornerRadius = UDim.new(0, 18)
DEVIL_EXTRA.AvatarPreviewCorner.Parent = DEVIL_EXTRA.AvatarPreview
DEVIL_EXTRA.AvatarWorld = Instance.new("WorldModel")
DEVIL_EXTRA.AvatarWorld.Name = "World"
DEVIL_EXTRA.AvatarWorld.Parent = DEVIL_EXTRA.AvatarPreview
DEVIL_EXTRA.AvatarCamera = Instance.new("Camera")
DEVIL_EXTRA.AvatarCamera.FieldOfView = 30
DEVIL_EXTRA.AvatarCamera.Parent = DEVIL_EXTRA.AvatarPreview
DEVIL_EXTRA.AvatarPreview.CurrentCamera = DEVIL_EXTRA.AvatarCamera

DEVIL_EXTRA.AvatarStatus = Instance.new("TextLabel")
DEVIL_EXTRA.AvatarStatus.Size = UDim2.new(0, 260, 0, 42)
DEVIL_EXTRA.AvatarStatus.Position = UDim2.new(0, 18, 0, 66)
DEVIL_EXTRA.AvatarStatus.BackgroundTransparency = 1
DEVIL_EXTRA.AvatarStatus.Text = "أدخل اسم اللاعب ثم اضغط معاينة 3D"
DEVIL_EXTRA.AvatarStatus.TextColor3 = Color3.fromRGB(165,180,200)
DEVIL_EXTRA.AvatarStatus.TextSize = 11
DEVIL_EXTRA.AvatarStatus.Font = Enum.Font.GothamMedium
DEVIL_EXTRA.AvatarStatus.TextWrapped = true
DEVIL_EXTRA.AvatarStatus.TextXAlignment = Enum.TextXAlignment.Left
DEVIL_EXTRA.AvatarStatus.Parent = DEVIL_EXTRA.AvatarStudioFrame

DEVIL_EXTRA.GetUserId = function(value)
    local text = tostring(value or ""):gsub("^%s+",""):gsub("%s+$","")
    local numeric = tonumber(text)
    if numeric then return math.floor(numeric) end
    if text == "" then return nil end
    local ok, result = pcall(function()
        return Players:GetUserIdFromNameAsync(text)
    end)
    return ok and result or nil
end

DEVIL_EXTRA.ClearPreview = function()
    for _, child in ipairs(DEVIL_EXTRA.AvatarWorld:GetChildren()) do
        child:Destroy()
    end
end

DEVIL_EXTRA.BuildSkinPreview = function(userId)
    DEVIL_EXTRA.ClearPreview()
    local okDesc, desc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserIdAsync(userId)
    end)
    if not okDesc or not desc then
        local fallbackOk, fallbackDesc = pcall(function()
            return Players:GetHumanoidDescriptionFromUserId(userId)
        end)
        if fallbackOk then desc = fallbackDesc end
    end
    if not desc then
        DEVIL_EXTRA.AvatarStatus.Text = "✕ تعذر تحميل سكن اللاعب"
        return false
    end
    DEVIL_EXTRA.State.SkinDescription = desc
    DEVIL_EXTRA.State.SkinUserId = userId

    local okModel, model = pcall(function()
        return Players:CreateHumanoidModelFromDescriptionAsync(desc, Enum.HumanoidRigType.R15)
    end)
    if not okModel or not model then
        local fallbackOk, fallbackModel = pcall(function()
            return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
        end)
        if fallbackOk then model = fallbackModel end
    end
    if not model then
        DEVIL_EXTRA.AvatarStatus.Text = "✕ تعذر إنشاء المعاينة 3D"
        return false
    end

    model.Name = "DEVIL_SkinPreview"
    for _, object in ipairs(model:GetDescendants()) do
        if object:IsA("Script") or object:IsA("LocalScript") or object:IsA("ModuleScript") then
            object:Destroy()
        elseif object:IsA("BasePart") then
            object.Anchored = true
            object.CanCollide = false
        end
    end
    model.Parent = DEVIL_EXTRA.AvatarWorld
    model:PivotTo(CFrame.new(0,0,0) * CFrame.Angles(0, math.rad(180), 0))
    DEVIL_EXTRA.AvatarCamera.CFrame = CFrame.new(Vector3.new(0,2.2,6), Vector3.new(0,1.35,0))
    DEVIL_EXTRA.AvatarStatus.Text = "✓ تم تحميل السكن 3D — UserId: " .. tostring(userId)
    return true
end

CreateCard(DEVIL_EXTRA.Pages.Avatar, "معاينة السكن 3D", "تحميل أي Avatar إلى نافذة ثلاثية الأبعاد", "معاينة", function()
    local userId = DEVIL_EXTRA.GetUserId(DEVIL_EXTRA.AvatarInput.Text)
    if not userId then
        DEVIL_EXTRA.AvatarStatus.Text = "✕ اكتب Username أو UserId صحيح"
        return
    end
    DEVIL_EXTRA.BuildSkinPreview(userId)
end)

CreateCard(DEVIL_EXTRA.Pages.Avatar, "تطبيق السكن محلياً", "تطبيق السكن المعاين على شخصيتك في الجلسة", "تطبيق", function()
    local desc = DEVIL_EXTRA.State.SkinDescription
    local character = LocalPlayer.Character
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if not desc or not hum then
        if Notify then Notify("✕ عاين سكن أولاً", Color3.fromRGB(231,76,60)) end
        return
    end
    if not DEVIL_EXTRA.State.SkinOriginal then
        local ok, original = pcall(function()
            return hum:GetAppliedDescription()
        end)
        if ok then DEVIL_EXTRA.State.SkinOriginal = original end
    end
    local ok = pcall(function()
        hum:ApplyDescription(desc)
    end)
    if not ok then
        pcall(function()
            hum:ApplyDescriptionAsync(desc)
        end)
    end
    if Notify then Notify("✓ تم تطبيق السكن محلياً", Color3.fromRGB(80,220,160)) end
end)

CreateCard(DEVIL_EXTRA.Pages.Avatar, "استرجاع السكن", "إرجاع السكن الذي كان موجوداً قبل التطبيق", "استرجاع", function()
    local character = LocalPlayer.Character
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    local original = DEVIL_EXTRA.State.SkinOriginal
    if hum and original then
        pcall(function() hum:ApplyDescription(original) end)
        DEVIL_EXTRA.State.SkinOriginal = nil
        if Notify then Notify("↻ تم استرجاع السكن", CurrentAccent) end
    end
end)

-- Player tools
CreateCard(DEVIL_EXTRA.Pages.Player, "Speed Boost PRO", "رفع السرعة إلى 32 مع دعم إعادة الشخصية", "تفعيل", function(btn)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        local enabled = btn:GetAttribute("Enabled") ~= true
        btn:SetAttribute("Enabled", enabled)
        hum.WalkSpeed = enabled and 32 or 16
        btn.Text = enabled and "إيقاف" or "تفعيل"
    end
end)

CreateCard(DEVIL_EXTRA.Pages.Player, "Jump Boost PRO", "رفع قوة القفز إلى 100", "تفعيل", function(btn)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        local enabled = btn:GetAttribute("Enabled") ~= true
        btn:SetAttribute("Enabled", enabled)
        hum.UseJumpPower = true
        hum.JumpPower = enabled and 100 or 50
        btn.Text = enabled and "إيقاف" or "تفعيل"
    end
end)

CreateCard(DEVIL_EXTRA.Pages.Player, "Reload Character", "إعادة تحميل الشخصية بسرعة", "إعادة", function()
    LocalPlayer:LoadCharacter()
end)

-- Visuals
CreateCard(DEVIL_EXTRA.Pages.Visuals, "Fullbright PRO", "سطوع قوي مع إزالة الظلال", "تفعيل", function(btn)
    local enabled = btn:GetAttribute("Enabled") ~= true
    btn:SetAttribute("Enabled", enabled)
    Lighting.Brightness = enabled and 3 or OldBrightness
    Lighting.ClockTime = enabled and 14 or OldClockTime
    Lighting.GlobalShadows = enabled and false or OldGlobalShadows
    btn.Text = enabled and "إيقاف" or "تفعيل"
end)

CreateCard(DEVIL_EXTRA.Pages.Visuals, "Background Motion", "حركة سينمائية ناعمة للخلفية", "تفعيل", function(btn)
    BackgroundMotionEnabled = not BackgroundMotionEnabled
    btn.Text = BackgroundMotionEnabled and "إيقاف" or "تفعيل"
end)

CreateCard(DEVIL_EXTRA.Pages.Visuals, "3D Parallax", "تأثير عمق بسيط للواجهة مع حركة الماوس", "تفعيل", function(btn)
    local enabled = btn:GetAttribute("Enabled") ~= false
    enabled = not enabled
    btn:SetAttribute("Enabled", enabled)
    btn.Text = enabled and "إيقاف" or "تفعيل"
    Stack3D.Enabled = enabled
    MainTopGlow.Visible = enabled
end)

-- Server
CreateCard(DEVIL_EXTRA.Pages.Server, "Server Info", "عرض معلومات السيرفر الحالي", "عرض", function()
    if Notify then
        Notify("PlaceId: " .. tostring(game.PlaceId) .. "  •  JobId: " .. string.sub(tostring(game.JobId),1,12) .. "...", CurrentAccent)
    end
end)

CreateCard(DEVIL_EXTRA.Pages.Server, "Copy JobId", "نسخ معرف السيرفر للحافظة", "نسخ", function()
    if setclipboard then
        setclipboard(tostring(game.JobId))
        if Notify then Notify("✓ تم نسخ JobId", Color3.fromRGB(80,220,160)) end
    end
end)

CreateCard(DEVIL_EXTRA.Pages.Server, "Rejoin Server", "إعادة الدخول إلى نفس السيرفر", "دخول", function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

-- Info
CreateCard(DEVIL_EXTRA.Pages.Info, "DEVIL 3D", "واجهة مطورة مبنية فوق سكربتك الأصلي بدون تغيير نظام المفتاح", "عرض", function()
    if Notify then Notify("DEVIL 3D Expansion • " .. HUB_VERSION, CurrentAccent) end
end)

CreateCard(DEVIL_EXTRA.Pages.Info, "Session Time", "مدة تشغيل السكربت الحالية", "تحديث", function()
    local seconds = math.max(0, math.floor(os.clock() - SessionStarted))
    if Notify then Notify("مدة الجلسة: " .. tostring(seconds) .. " ثانية", CurrentAccent) end
end)

-- دوران 3D بالسحب داخل المعاينة
DEVIL_EXTRA.AvatarPreview.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        DEVIL_EXTRA.State.Dragging = true
        DEVIL_EXTRA.State.LastX = input.Position.X
    end
end)

DEVIL_EXTRA.AvatarPreview.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        DEVIL_EXTRA.State.Dragging = false
    end
end)

DEVIL_EXTRA.AvatarPreview.InputChanged:Connect(function(input)
    if DEVIL_EXTRA.State.Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position.X - (DEVIL_EXTRA.State.LastX or input.Position.X)
        DEVIL_EXTRA.State.LastX = input.Position.X
        local model = DEVIL_EXTRA.AvatarWorld:FindFirstChild("DEVIL_SkinPreview")
        if model then
            model:PivotTo(model:GetPivot() * CFrame.Angles(0, math.rad(-delta * 0.6), 0))
        end
    end
end)

DEVIL_EXTRA.Pages.Avatar.Visible = false
DEVIL_EXTRA.Pages.Player.Visible = false
DEVIL_EXTRA.Pages.Visuals.Visible = false
DEVIL_EXTRA.Pages.Server.Visible = false
DEVIL_EXTRA.Pages.Info.Visible = false

-- ==========================================
-- 11. ربط الأحداث والبحث
-- ==========================================
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local query = string.lower(SearchBox.Text)
    local found = 0
    for _, item in ipairs(AllCards) do
        local matches = query == "" or string.find(string.lower(item.Title), query, 1, true) or string.find(string.lower(item.Desc), query, 1, true)
        item.Card.Visible = matches
        if matches then found += 1 end
    end
    NoResultsLabel.Visible = query ~= "" and found == 0
    if query ~= "" and found == 0 and Notify then
        Notify("لم يتم العثور على نتائج", Color3.fromRGB(231, 150, 90))
    end
end)

local function ToggleMainFrame(visible)
    PlayClick()
    if visible then
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 900, 0, 590),
            Position = UDim2.new(0.5, -450, 0.5, -295)
        }):Play()
    else
        local tween = TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        })
        tween:Play()
        tween.Completed:Connect(function()
            MainFrame.Visible = false
        end)
    end
end

CloseBtn.MouseButton1Click:Connect(function()
    ToggleMainFrame(false)
end)

ToggleBtn.MouseButton1Click:Connect(function()
    ToggleMainFrame(not MainFrame.Visible)
end)

-- ==========================================
-- Responsive UI
-- ==========================================
local function UpdateUIScale()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local scale = math.clamp(math.min(viewport.X / 1100, viewport.Y / 800), 0.62, 1.08)
    MainScale.Scale = scale
end

UpdateUIScale()

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateUIScale)
end

-- تفعيل التاب الأول تلقائياً
Tab1.BackgroundColor3 = Color3.fromRGB(24, 30, 38)
Tab1.TextColor3 = Color3.fromRGB(255, 255, 255)
Tab1:FindFirstChildOfClass("UIStroke").Transparency = 0.3

ScriptsPage.Visible = false
HomePage.Visible = true
TabHome.BackgroundColor3 = Color3.fromRGB(24, 30, 38)
TabHome.TextColor3 = Color3.fromRGB(255, 255, 255)
TabHome:FindFirstChildOfClass("UIStroke").Transparency = 0.3

-- حركة الخلفية: الحجم ثابت = حجم المنيو، والحركة عبر لمعة تتحرك فوقها
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        local t = os.clock() - SessionStarted
        for _, pair in ipairs({{MainBackgroundImage, MainFrame}}) do
            local img, fr = pair[1], pair[2]
            if img then
                img.Size = UDim2.fromScale(1, 1)
                img.Position = UDim2.fromScale(0, 0)
            end
            local ov = fr and fr:FindFirstChild("GlassOverlay")
            local sh = ov and ov:FindFirstChild("DEVIL_Shine")
            if sh and BackgroundMotionEnabled and fr.Visible then
                sh.Offset = Vector2.new(math.sin(t * 0.35) * 0.45, math.cos(t * 0.27) * 0.2)
                sh.Rotation = 20 + math.sin(t * 0.2) * 14
            end
        end
        task.wait(0.04)
    end
end)

local function SetHubBackground(imageObject)
    local bg = Backgrounds[CurrentBackground]
    if not bg or not imageObject then return end
    SetImageWithFallback(imageObject, bg.Id)
    imageObject.ImageTransparency = 0
    imageObject.ScaleType = Enum.ScaleType.Crop
end

local function NextHubBackground(imageObject)
    CurrentBackground = CurrentBackground % #Backgrounds + 1
    SetHubBackground(imageObject)
end

local function PreviousHubBackground(imageObject)
    CurrentBackground = (CurrentBackground - 2) % #Backgrounds + 1
    SetHubBackground(imageObject)
end

-- ==========================================
-- DEVIL ULTRA PACK — ALL-IN-ONE EXPANSION
-- ==========================================
DEVIL_EXTRA.State.Connections = DEVIL_EXTRA.State.Connections or {}
DEVIL_EXTRA.State.ESP = DEVIL_EXTRA.State.ESP or {}
DEVIL_EXTRA.State.ESPEnabled = false
DEVIL_EXTRA.State.NoclipEnabled = false
DEVIL_EXTRA.State.FlyEnabled = false
DEVIL_EXTRA.State.InfiniteJumpEnabled = false
DEVIL_EXTRA.State.NightVisionEnabled = false
DEVIL_EXTRA.State.FOVEnabled = false
DEVIL_EXTRA.State.SavedCFrame = nil
DEVIL_EXTRA.State.FlySpeed = 70
DEVIL_EXTRA.State.CustomAccent = CurrentAccent

DEVIL_EXTRA.Notify = function(message, color)
    if Notify then
        Notify(tostring(message), color or CurrentAccent)
    end
end

DEVIL_EXTRA.GetCharacter = function()
    local character = LocalPlayer.Character
    if not character then return nil, nil, nil end
    local hum = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    return character, hum, root
end

DEVIL_EXTRA.HexToColor = function(value)
    local hex = tostring(value or ""):gsub("#", ""):gsub("%s", "")
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1,2), 16)
    local g = tonumber(hex:sub(3,4), 16)
    local b = tonumber(hex:sub(5,6), 16)
    if not r or not g or not b then return nil end
    return Color3.fromRGB(r,g,b)
end

DEVIL_EXTRA.SetButtonState = function(button, enabled)
    if not button then return end
    button:SetAttribute("Enabled", enabled)
    button.Text = enabled and "إيقاف" or "تفعيل"
end

DEVIL_EXTRA.Disconnect = function(key)
    local connection = DEVIL_EXTRA.State.Connections[key]
    if connection then
        pcall(function() connection:Disconnect() end)
        DEVIL_EXTRA.State.Connections[key] = nil
    end
end

DEVIL_EXTRA.Pages.Tools, DEVIL_EXTRA.Tabs.Tools = CreateTab("DEVIL+", "✦")
DEVIL_EXTRA.Pages.Teleport, DEVIL_EXTRA.Tabs.Teleport = CreateTab("TELEPORT", "⌁")
DEVIL_EXTRA.Pages.ESP, DEVIL_EXTRA.Tabs.ESP = CreateTab("ESP", "◉")
DEVIL_EXTRA.Pages.Settings, DEVIL_EXTRA.Tabs.Settings = CreateTab("SETTINGS", "⚙")

DEVIL_EXTRA.Pages.Tools.Visible = false
DEVIL_EXTRA.Pages.Teleport.Visible = false
DEVIL_EXTRA.Pages.ESP.Visible = false
DEVIL_EXTRA.Pages.Settings.Visible = false

-- PLAYER / MOVEMENT PRO
CreateCard(DEVIL_EXTRA.Pages.Player, "Infinite Jump", "قفز مستمر أثناء الضغط على زر القفز", "تفعيل", function(btn)
    DEVIL_EXTRA.State.InfiniteJumpEnabled = not DEVIL_EXTRA.State.InfiniteJumpEnabled
    DEVIL_EXTRA.SetButtonState(btn, DEVIL_EXTRA.State.InfiniteJumpEnabled)
    DEVIL_EXTRA.Disconnect("InfiniteJump")
    if DEVIL_EXTRA.State.InfiniteJumpEnabled then
        DEVIL_EXTRA.State.Connections.InfiniteJump = UserInputService.JumpRequest:Connect(function()
            local _, hum = DEVIL_EXTRA.GetCharacter()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end
end)

CreateCard(DEVIL_EXTRA.Pages.Player, "Noclip PRO", "المرور من الجدران مع تشغيل وإيقاف مباشر", "تفعيل", function(btn)
    DEVIL_EXTRA.State.NoclipEnabled = not DEVIL_EXTRA.State.NoclipEnabled
    DEVIL_EXTRA.SetButtonState(btn, DEVIL_EXTRA.State.NoclipEnabled)
    DEVIL_EXTRA.Disconnect("Noclip")
    if DEVIL_EXTRA.State.NoclipEnabled then
        DEVIL_EXTRA.State.Connections.Noclip = RunService.Stepped:Connect(function()
            local character = LocalPlayer.Character
            if character then
                for _, object in ipairs(character:GetDescendants()) do
                    if object:IsA("BasePart") then
                        object.CanCollide = false
                    end
                end
            end
        end)
    end
end)

CreateCard(DEVIL_EXTRA.Pages.Player, "Fly PRO", "طيران WASD + Space + LeftShift", "تفعيل", function(btn)
    DEVIL_EXTRA.State.FlyEnabled = not DEVIL_EXTRA.State.FlyEnabled
    DEVIL_EXTRA.SetButtonState(btn, DEVIL_EXTRA.State.FlyEnabled)
    DEVIL_EXTRA.Disconnect("Fly")
    local character, hum, root = DEVIL_EXTRA.GetCharacter()
    if DEVIL_EXTRA.State.FlyEnabled and root then
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Name = "DEVIL_FlyVelocity"
        bodyVelocity.MaxForce = Vector3.new(1e9,1e9,1e9)
        bodyVelocity.Velocity = Vector3.zero
        bodyVelocity.Parent = root
        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.Name = "DEVIL_FlyGyro"
        bodyGyro.MaxTorque = Vector3.new(1e9,1e9,1e9)
        bodyGyro.P = 90000
        bodyGyro.Parent = root
        DEVIL_EXTRA.State.FlyVelocity = bodyVelocity
        DEVIL_EXTRA.State.FlyGyro = bodyGyro
        DEVIL_EXTRA.State.Connections.Fly = RunService.RenderStepped:Connect(function()
            if not DEVIL_EXTRA.State.FlyEnabled or not root.Parent then return end
            local camera = workspace.CurrentCamera
            if not camera then return end
            local direction = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then direction -= Vector3.new(0,1,0) end
            bodyVelocity.Velocity = direction * DEVIL_EXTRA.State.FlySpeed
            bodyGyro.CFrame = camera.CFrame
            if hum then hum.PlatformStand = true end
        end)
    else
        if DEVIL_EXTRA.State.FlyVelocity then DEVIL_EXTRA.State.FlyVelocity:Destroy() end
        if DEVIL_EXTRA.State.FlyGyro then DEVIL_EXTRA.State.FlyGyro:Destroy() end
        DEVIL_EXTRA.State.FlyVelocity = nil
        DEVIL_EXTRA.State.FlyGyro = nil
        if hum then hum.PlatformStand = false end
    end
end)

CreateCard(DEVIL_EXTRA.Pages.Player, "Save Position", "حفظ مكانك الحالي للعودة له لاحقاً", "حفظ", function()
    local _, _, root = DEVIL_EXTRA.GetCharacter()
    if root then
        DEVIL_EXTRA.State.SavedCFrame = root.CFrame
        DEVIL_EXTRA.Notify("✓ تم حفظ الموقع", Color3.fromRGB(80,220,160))
    end
end)

CreateCard(DEVIL_EXTRA.Pages.Player, "Return Position", "الرجوع للمكان المحفوظ", "رجوع", function()
    local _, _, root = DEVIL_EXTRA.GetCharacter()
    if root and DEVIL_EXTRA.State.SavedCFrame then
        root.CFrame = DEVIL_EXTRA.State.SavedCFrame
        DEVIL_EXTRA.Notify("✓ رجعت للموقع المحفوظ", CurrentAccent)
    else
        DEVIL_EXTRA.Notify("✕ لا يوجد موقع محفوظ", Color3.fromRGB(231,76,60))
    end
end)

CreateCard(DEVIL_EXTRA.Pages.Player, "FOV 100", "توسيع مجال الرؤية مع استرجاعه عند الإيقاف", "تفعيل", function(btn)
    DEVIL_EXTRA.State.FOVEnabled = not DEVIL_EXTRA.State.FOVEnabled
    DEVIL_EXTRA.SetButtonState(btn, DEVIL_EXTRA.State.FOVEnabled)
    local camera = workspace.CurrentCamera
    if camera then camera.FieldOfView = DEVIL_EXTRA.State.FOVEnabled and 100 or 70 end
end)

-- TELEPORT
DEVIL_EXTRA.TeleportInput = Instance.new("TextBox")
DEVIL_EXTRA.TeleportInput.Size = UDim2.new(1,-30,0,40)
DEVIL_EXTRA.TeleportInput.Position = UDim2.new(0,15,0,15)
DEVIL_EXTRA.TeleportInput.BackgroundColor3 = Color3.fromRGB(18,25,38)
DEVIL_EXTRA.TeleportInput.BorderSizePixel = 0
DEVIL_EXTRA.TeleportInput.PlaceholderText = "اكتب Username للاعب..."
DEVIL_EXTRA.TeleportInput.Text = ""
DEVIL_EXTRA.TeleportInput.TextColor3 = Color3.fromRGB(255,255,255)
DEVIL_EXTRA.TeleportInput.TextSize = 12
DEVIL_EXTRA.TeleportInput.Font = Enum.Font.GothamMedium
DEVIL_EXTRA.TeleportInput.ClearTextOnFocus = false
DEVIL_EXTRA.TeleportInput.Parent = DEVIL_EXTRA.Pages.Teleport
DEVIL_EXTRA.TeleportInputCorner = Instance.new("UICorner")
DEVIL_EXTRA.TeleportInputCorner.CornerRadius = UDim.new(0,10)
DEVIL_EXTRA.TeleportInputCorner.Parent = DEVIL_EXTRA.TeleportInput

CreateCard(DEVIL_EXTRA.Pages.Teleport, "Teleport To Player", "الانتقال إلى لاعب بالاسم داخل السيرفر", "انتقال", function()
    local wanted = tostring(DEVIL_EXTRA.TeleportInput.Text or ""):lower():gsub("^%s+",""):gsub("%s+$","")
    local target = nil
    if wanted ~= "" then
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Name:lower() == wanted or player.DisplayName:lower() == wanted then
                target = player
                break
            end
        end
    end
    local _, _, root = DEVIL_EXTRA.GetCharacter()
    local targetRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if root and targetRoot then
        root.CFrame = targetRoot.CFrame * CFrame.new(0,0,3)
        DEVIL_EXTRA.Notify("✓ تم الانتقال إلى " .. target.Name, Color3.fromRGB(80,220,160))
    else
        DEVIL_EXTRA.Notify("✕ اللاعب غير موجود داخل السيرفر", Color3.fromRGB(231,76,60))
    end
end)

CreateCard(DEVIL_EXTRA.Pages.Teleport, "Teleport To Spawn", "العودة إلى Spawn/SpawnLocation الأقرب", "انتقال", function()
    local _, _, root = DEVIL_EXTRA.GetCharacter()
    local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
    if root and spawn then
        root.CFrame = spawn.CFrame + Vector3.new(0,4,0)
        DEVIL_EXTRA.Notify("✓ تم الانتقال إلى Spawn", CurrentAccent)
    else
        DEVIL_EXTRA.Notify("✕ ما لقيت SpawnLocation", Color3.fromRGB(231,76,60))
    end
end)

-- ESP SYSTEM
DEVIL_EXTRA.ClearESP = function()
    for player, gui in pairs(DEVIL_EXTRA.State.ESP) do
        pcall(function() gui:Destroy() end)
        DEVIL_EXTRA.State.ESP[player] = nil
    end
end

DEVIL_EXTRA.AddESP = function(player)
    if player == LocalPlayer or not DEVIL_EXTRA.State.ESPEnabled then return end
    local character = player.Character
    local head = character and character:FindFirstChild("Head")
    if not head then return end
    if DEVIL_EXTRA.State.ESP[player] and DEVIL_EXTRA.State.ESP[player].Parent then return end
    local bill = Instance.new("BillboardGui")
    bill.Name = "DEVIL_ESP"
    bill.Size = UDim2.new(0,180,0,42)
    bill.StudsOffset = Vector3.new(0,3,0)
    bill.AlwaysOnTop = true
    bill.Adornee = head
    bill.Parent = head
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1,1)
    label.BackgroundTransparency = 1
    label.TextColor3 = CurrentAccent
    label.TextStrokeTransparency = 0.35
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.Text = player.DisplayName .. "  [" .. player.Name .. "]"
    label.Parent = bill
    DEVIL_EXTRA.State.ESP[player] = bill
end

DEVIL_EXTRA.RefreshESP = function()
    if not DEVIL_EXTRA.State.ESPEnabled then
        DEVIL_EXTRA.ClearESP()
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        DEVIL_EXTRA.AddESP(player)
    end
end

CreateCard(DEVIL_EXTRA.Pages.ESP, "Player ESP", "أسماء اللاعبين فوق الشخصيات", "تفعيل", function(btn)
    DEVIL_EXTRA.State.ESPEnabled = not DEVIL_EXTRA.State.ESPEnabled
    DEVIL_EXTRA.SetButtonState(btn, DEVIL_EXTRA.State.ESPEnabled)
    if DEVIL_EXTRA.State.ESPEnabled then
        DEVIL_EXTRA.RefreshESP()
    else
        DEVIL_EXTRA.ClearESP()
    end
end)

CreateCard(DEVIL_EXTRA.Pages.ESP, "Distance ESP", "عرض المسافة بجانب أسماء اللاعبين", "تفعيل", function(btn)
    DEVIL_EXTRA.State.DistanceESP = not DEVIL_EXTRA.State.DistanceESP
    DEVIL_EXTRA.SetButtonState(btn, DEVIL_EXTRA.State.DistanceESP)
    DEVIL_EXTRA.Disconnect("DistanceESP")
    if DEVIL_EXTRA.State.DistanceESP then
        DEVIL_EXTRA.State.Connections.DistanceESP = RunService.RenderStepped:Connect(function()
            local _, _, root = DEVIL_EXTRA.GetCharacter()
            if not root then return end
            for player, gui in pairs(DEVIL_EXTRA.State.ESP) do
                local head = player.Character and player.Character:FindFirstChild("Head")
                local label = gui and gui:FindFirstChildOfClass("TextLabel")
                if head and label then
                    local distance = math.floor((root.Position - head.Position).Magnitude)
                    label.Text = player.DisplayName .. "  •  " .. tostring(distance) .. "m"
                end
            end
        end)
    end
end)

DEVIL_EXTRA.State.Connections.PlayerAddedESP = Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.8)
        if DEVIL_EXTRA.State.ESPEnabled then DEVIL_EXTRA.AddESP(player) end
    end)
end)

-- VISUALS PRO
CreateCard(DEVIL_EXTRA.Pages.Visuals, "Night Vision", "إضاءة قوية ورؤية أوضح في المناطق المظلمة", "تفعيل", function(btn)
    DEVIL_EXTRA.State.NightVisionEnabled = not DEVIL_EXTRA.State.NightVisionEnabled
    DEVIL_EXTRA.SetButtonState(btn, DEVIL_EXTRA.State.NightVisionEnabled)
    if DEVIL_EXTRA.State.NightVisionEnabled then
        Lighting.Brightness = 4
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = OldBrightness
        Lighting.ClockTime = OldClockTime
        Lighting.FogEnd = OldFogEnd or Lighting.FogEnd
        Lighting.GlobalShadows = OldGlobalShadows
    end
end)

CreateCard(DEVIL_EXTRA.Pages.Visuals, "Remove Fog", "إزالة الضباب قدر الإمكان", "تفعيل", function(btn)
    local enabled = btn:GetAttribute("Enabled") ~= true
    btn:SetAttribute("Enabled", enabled)
    btn.Text = enabled and "إيقاف" or "تفعيل"
    if enabled then
        DEVIL_EXTRA.State.OldFogEnd = Lighting.FogEnd
        Lighting.FogEnd = 100000
    else
        Lighting.FogEnd = DEVIL_EXTRA.State.OldFogEnd or 1000
    end
end)

CreateCard(DEVIL_EXTRA.Pages.Visuals, "Camera Shake OFF", "محاولة تقليل اهتزاز الكاميرا عبر إعادة ضبطها", "تفعيل", function(btn)
    DEVIL_EXTRA.State.CameraStable = not DEVIL_EXTRA.State.CameraStable
    DEVIL_EXTRA.SetButtonState(btn, DEVIL_EXTRA.State.CameraStable)
    DEVIL_EXTRA.Disconnect("CameraStable")
    if DEVIL_EXTRA.State.CameraStable then
        DEVIL_EXTRA.State.Connections.CameraStable = RunService.RenderStepped:Connect(function()
            local camera = workspace.CurrentCamera
            if camera and camera.CameraType == Enum.CameraType.Custom then
                if DEVIL_EXTRA.State.FOVEnabled then camera.FieldOfView = 100 end
            end
        end)
    end
end)

-- DEVIL+ UTILITIES
DEVIL_EXTRA.PerformanceLabel = Instance.new("TextLabel")
DEVIL_EXTRA.PerformanceLabel.Size = UDim2.new(1,-30,0,42)
DEVIL_EXTRA.PerformanceLabel.Position = UDim2.new(0,15,0,15)
DEVIL_EXTRA.PerformanceLabel.BackgroundColor3 = Color3.fromRGB(10,18,30)
DEVIL_EXTRA.PerformanceLabel.BackgroundTransparency = 0.15
DEVIL_EXTRA.PerformanceLabel.TextColor3 = CurrentAccent
DEVIL_EXTRA.PerformanceLabel.Text = "DEVIL MONITOR • FPS: -- • PING: --"
DEVIL_EXTRA.PerformanceLabel.TextSize = 12
DEVIL_EXTRA.PerformanceLabel.Font = Enum.Font.GothamBold
DEVIL_EXTRA.PerformanceLabel.Parent = DEVIL_EXTRA.Pages.Tools
DEVIL_EXTRA.PerformanceCorner = Instance.new("UICorner")
DEVIL_EXTRA.PerformanceCorner.CornerRadius = UDim.new(0,10)
DEVIL_EXTRA.PerformanceCorner.Parent = DEVIL_EXTRA.PerformanceLabel
RegisterThemeElement(DEVIL_EXTRA.PerformanceLabel, "TextColored")

DEVIL_EXTRA.State.Connections.Monitor = RunService.RenderStepped:Connect(function(delta)
    if DEVIL_EXTRA.PerformanceLabel and DEVIL_EXTRA.PerformanceLabel.Parent then
        local fps = delta > 0 and math.floor(1/delta) or 0
        local ping = 0
        pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
        DEVIL_EXTRA.PerformanceLabel.Text = "DEVIL MONITOR • FPS: " .. tostring(fps) .. " • PING: " .. tostring(ping) .. "ms"
    end
end)

CreateCard(DEVIL_EXTRA.Pages.Tools, "Anti AFK", "منع الخمول بإرسال حركة دورية للعبة", "تفعيل", function(btn)
    DEVIL_EXTRA.State.AntiAFK = not DEVIL_EXTRA.State.AntiAFK
    DEVIL_EXTRA.SetButtonState(btn, DEVIL_EXTRA.State.AntiAFK)
    if DEVIL_EXTRA.State.AntiAFK then
        DEVIL_EXTRA.State.Connections.AntiAFK = task.spawn(function()
            while DEVIL_EXTRA.State.AntiAFK and ScreenGui and ScreenGui.Parent do
                task.wait(45)
                if DEVIL_EXTRA.State.AntiAFK then
                    local _, hum = DEVIL_EXTRA.GetCharacter()
                    if hum then hum.Jump = true end
                end
            end
        end)
    end
end)

CreateCard(DEVIL_EXTRA.Pages.Tools, "Rejoin", "إعادة الدخول إلى السيرفر الحالي", "دخول", function()
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
end)

CreateCard(DEVIL_EXTRA.Pages.Tools, "Reset Camera", "إرجاع الكاميرا للوضع الطبيعي", "إعادة", function()
    local camera = workspace.CurrentCamera
    if camera then
        camera.CameraType = Enum.CameraType.Custom
        local _, hum = DEVIL_EXTRA.GetCharacter()
        if hum then camera.CameraSubject = hum end
        camera.FieldOfView = DEVIL_EXTRA.State.FOVEnabled and 100 or 70
    end
end)

CreateCard(DEVIL_EXTRA.Pages.Tools, "FPS Boost", "تقليل بعض مؤثرات الإضاءة المحلية لتحسين الأداء", "تفعيل", function(btn)
    DEVIL_EXTRA.State.FPSBoost = not DEVIL_EXTRA.State.FPSBoost
    DEVIL_EXTRA.SetButtonState(btn, DEVIL_EXTRA.State.FPSBoost)
    if DEVIL_EXTRA.State.FPSBoost then
        DEVIL_EXTRA.State.OldGlobalShadows = Lighting.GlobalShadows
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
    else
        Lighting.GlobalShadows = DEVIL_EXTRA.State.OldGlobalShadows ~= false and DEVIL_EXTRA.State.OldGlobalShadows or OldGlobalShadows
    end
end)

-- SETTINGS / CUSTOM ACCENT
DEVIL_EXTRA.AccentInput = Instance.new("TextBox")
DEVIL_EXTRA.AccentInput.Size = UDim2.new(1,-30,0,40)
DEVIL_EXTRA.AccentInput.Position = UDim2.new(0,15,0,15)
DEVIL_EXTRA.AccentInput.BackgroundColor3 = Color3.fromRGB(18,25,38)
DEVIL_EXTRA.AccentInput.BorderSizePixel = 0
DEVIL_EXTRA.AccentInput.PlaceholderText = "لون HEX مثل #34B6BD"
DEVIL_EXTRA.AccentInput.Text = "#34B6BD"
DEVIL_EXTRA.AccentInput.TextColor3 = Color3.fromRGB(255,255,255)
DEVIL_EXTRA.AccentInput.TextSize = 12
DEVIL_EXTRA.AccentInput.Font = Enum.Font.GothamMedium
DEVIL_EXTRA.AccentInput.ClearTextOnFocus = false
DEVIL_EXTRA.AccentInput.Parent = DEVIL_EXTRA.Pages.Settings
DEVIL_EXTRA.AccentCorner = Instance.new("UICorner")
DEVIL_EXTRA.AccentCorner.CornerRadius = UDim.new(0,10)
DEVIL_EXTRA.AccentCorner.Parent = DEVIL_EXTRA.AccentInput

CreateCard(DEVIL_EXTRA.Pages.Settings, "Custom Accent", "اختيار لون الواجهة من HEX", "تطبيق", function()
    local color = DEVIL_EXTRA.HexToColor(DEVIL_EXTRA.AccentInput.Text)
    if color then
        DEVIL_EXTRA.State.CustomAccent = color
        UpdateTheme(color)
        DEVIL_EXTRA.Notify("✓ تم تغيير لون DEVIL", color)
    else
        DEVIL_EXTRA.Notify("✕ صيغة HEX غير صحيحة", Color3.fromRGB(231,76,60))
    end
end)

CreateCard(DEVIL_EXTRA.Pages.Settings, "Cyan Theme", "الثيم الأزرق/التراكواز", "تطبيق", function()
    UpdateTheme(Color3.fromRGB(52,182,189))
end)
CreateCard(DEVIL_EXTRA.Pages.Settings, "Purple Theme", "ثيم بنفسجي نيون", "تطبيق", function()
    UpdateTheme(Color3.fromRGB(155,89,182))
end)
CreateCard(DEVIL_EXTRA.Pages.Settings, "Crimson Theme", "ثيم أحمر قوي", "تطبيق", function()
    UpdateTheme(Color3.fromRGB(231,76,60))
end)
CreateCard(DEVIL_EXTRA.Pages.Settings, "Gold Theme", "ثيم ذهبي", "تطبيق", function()
    UpdateTheme(Color3.fromRGB(241,196,15))
end)

CreateCard(DEVIL_EXTRA.Pages.Settings, "Animations", "تشغيل أو إيقاف حركات الواجهة", "تفعيل", function(btn)
    AnimationEnabled = not AnimationEnabled
    DEVIL_EXTRA.SetButtonState(btn, AnimationEnabled)
end)

CreateCard(DEVIL_EXTRA.Pages.Settings, "UI Sounds", "تشغيل أو إيقاف أصوات الواجهة", "تفعيل", function(btn)
    SoundEnabled = not SoundEnabled
    DEVIL_EXTRA.SetButtonState(btn, SoundEnabled)
end)

CreateCard(DEVIL_EXTRA.Pages.Settings, "Compact Mode", "تصغير الواجهة لتوفير مساحة", "تفعيل", function(btn)
    DEVIL_EXTRA.State.Compact = not DEVIL_EXTRA.State.Compact
    DEVIL_EXTRA.SetButtonState(btn, DEVIL_EXTRA.State.Compact)
    if DEVIL_EXTRA.State.Compact then
        MainFrame.Size = UDim2.new(0,760,0,500)
    else
        MainFrame.Size = UDim2.new(0,860,0,540)
    end
end)

CreateCard(DEVIL_EXTRA.Pages.Settings, "3D Depth", "قوة العمق خلف المنيو (خفيف / متوسط / قوي)", "خفيف", function(btn)
    local levels = {{"خفيف", 0.7}, {"متوسط", 1}, {"قوي", 1.6}}
    DEVIL_EXTRA.State.DepthIdx = ((DEVIL_EXTRA.State.DepthIdx or 1) % #levels) + 1
    local l = levels[DEVIL_EXTRA.State.DepthIdx]
    Stack3D.Strength = l[2]
    btn.Text = l[1]
end)

CreateCard(DEVIL_EXTRA.Pages.Settings, "Menu Opacity", "شفافية جسم المنيو (صلب / عادي / زجاجي)", "عادي", function(btn)
    local levels = {{"صلب", 0}, {"عادي", 0.05}, {"زجاجي", 0.35}}
    DEVIL_EXTRA.State.OpacityIdx = ((DEVIL_EXTRA.State.OpacityIdx or 2) % #levels) + 1
    local l = levels[DEVIL_EXTRA.State.OpacityIdx]
    if MainBackgroundImage and MainBackgroundImage.Image ~= "" then TweenService:Create(MainBackgroundImage, TweenInfo.new(0.25), {ImageTransparency = l[2]}):Play() end
    btn.Text = l[1]
end)

CreateCard(DEVIL_EXTRA.Pages.Settings, "Background Dim", "تعتيم الخلفية خلف النصوص (خفيف / عادي / غامق)", "عادي", function(btn)
    local levels = {{"خفيف", 0.85}, {"عادي", 0.68}, {"غامق", 0.45}}
    DEVIL_EXTRA.State.DimIdx = ((DEVIL_EXTRA.State.DimIdx or 2) % #levels) + 1
    local l = levels[DEVIL_EXTRA.State.DimIdx]
    local ov = MainFrame:FindFirstChild("GlassOverlay")
    if ov then TweenService:Create(ov, TweenInfo.new(0.25), {BackgroundTransparency = l[2]}):Play() end
    btn.Text = l[1]
end)

-- SEARCH / COMMAND PALETTE
DEVIL_EXTRA.SearchInput = Instance.new("TextBox")
DEVIL_EXTRA.SearchInput.Size = UDim2.new(1,-30,0,40)
DEVIL_EXTRA.SearchInput.Position = UDim2.new(0,15,0,15)
DEVIL_EXTRA.SearchInput.BackgroundColor3 = Color3.fromRGB(18,25,38)
DEVIL_EXTRA.SearchInput.BorderSizePixel = 0
DEVIL_EXTRA.SearchInput.PlaceholderText = "بحث سريع عن أي ميزة..."
DEVIL_EXTRA.SearchInput.Text = ""
DEVIL_EXTRA.SearchInput.TextColor3 = Color3.fromRGB(255,255,255)
DEVIL_EXTRA.SearchInput.TextSize = 12
DEVIL_EXTRA.SearchInput.Font = Enum.Font.GothamMedium
DEVIL_EXTRA.SearchInput.ClearTextOnFocus = false
DEVIL_EXTRA.SearchInput.Parent = DEVIL_EXTRA.Pages.Tools
DEVIL_EXTRA.SearchCorner = Instance.new("UICorner")
DEVIL_EXTRA.SearchCorner.CornerRadius = UDim.new(0,10)
DEVIL_EXTRA.SearchCorner.Parent = DEVIL_EXTRA.SearchInput

DEVIL_EXTRA.SearchHint = Instance.new("TextLabel")
DEVIL_EXTRA.SearchHint.Size = UDim2.new(1,-30,0,30)
DEVIL_EXTRA.SearchHint.Position = UDim2.new(0,15,0,60)
DEVIL_EXTRA.SearchHint.BackgroundTransparency = 1
DEVIL_EXTRA.SearchHint.Text = "CTRL + K  •  اكتب اسم الميزة ثم اضغط Enter"
DEVIL_EXTRA.SearchHint.TextColor3 = Color3.fromRGB(125,145,170)
DEVIL_EXTRA.SearchHint.TextSize = 10
DEVIL_EXTRA.SearchHint.Font = Enum.Font.GothamMedium
DEVIL_EXTRA.SearchHint.TextXAlignment = Enum.TextXAlignment.Left
DEVIL_EXTRA.SearchHint.Parent = DEVIL_EXTRA.Pages.Tools

DEVIL_EXTRA.OpenCommand = function()
    if DEVIL_EXTRA.SearchInput and DEVIL_EXTRA.SearchInput.Parent then
        DEVIL_EXTRA.SearchInput:CaptureFocus()
    end
end

DEVIL_EXTRA.State.Connections.CommandKey = UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.K and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        DEVIL_EXTRA.OpenCommand()
    end
end)

DEVIL_EXTRA.SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
    local query = tostring(DEVIL_EXTRA.SearchInput.Text or ""):lower()
    if query == "" then
        DEVIL_EXTRA.SearchHint.Text = "CTRL + K  •  اكتب اسم الميزة ثم اضغط Enter"
        return
    end
    local found = 0
    for _, object in ipairs(MainFrame:GetDescendants()) do
        if object:IsA("TextButton") and object ~= ToggleBtn then
            local text = tostring(object.Text or "")
            local parent = object.Parent
            local isTab = parent == Sidebar or (parent and parent.Name == "Sidebar")
            if not isTab and text ~= "" then
                local match = text:lower():find(query, 1, true) ~= nil
                object:SetAttribute("DEVIL_SearchMatch", match)
                if match then found += 1 end
            end
        end
    end
    DEVIL_EXTRA.SearchHint.Text = "نتائج البحث: " .. tostring(found) .. "  •  المطابقة داخل أسماء الأزرار"
end)

DEVIL_EXTRA.SearchInput.FocusLost:Connect(function(enterPressed)
    if not enterPressed then return end
    local query = tostring(DEVIL_EXTRA.SearchInput.Text or ""):lower()
    if query == "" then return end
    for _, object in ipairs(MainFrame:GetDescendants()) do
        if object:IsA("TextButton") and object ~= ToggleBtn then
            local text = tostring(object.Text or "")
            local match = text:lower():find(query, 1, true) ~= nil
            if match and object:GetAttribute("DEVIL_SearchMatch") then
                pcall(function() object:Activate() end)
                break
            end
        end
    end
end)

-- إعادة تطبيق حالات الأدوات بعد Respawn
DEVIL_EXTRA.State.Connections.CharacterAdded = LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.8)
    if DEVIL_EXTRA.State.FlyEnabled then
        DEVIL_EXTRA.State.FlyEnabled = false
        if DEVIL_EXTRA.State.FlyVelocity then DEVIL_EXTRA.State.FlyVelocity:Destroy() end
        if DEVIL_EXTRA.State.FlyGyro then DEVIL_EXTRA.State.FlyGyro:Destroy() end
        DEVIL_EXTRA.State.FlyVelocity = nil
        DEVIL_EXTRA.State.FlyGyro = nil
        DEVIL_EXTRA.Disconnect("Fly")
    end
    if DEVIL_EXTRA.State.ESPEnabled then
        DEVIL_EXTRA.ClearESP()
        task.wait(0.2)
        DEVIL_EXTRA.RefreshESP()
    end
end)

DEVIL_EXTRA.State.Connections.ThemeRefresh = RunService.Heartbeat:Connect(function()
    if DEVIL_EXTRA.PerformanceLabel and DEVIL_EXTRA.PerformanceLabel.Parent then
        DEVIL_EXTRA.PerformanceLabel.TextColor3 = CurrentAccent
    end
end)

DEVIL_EXTRA.Notify("DEVIL ULTRA PACK جاهز • كل الإضافات مفعلة", CurrentAccent)

-- =========================================================
-- MUSAED DEVIL 3D MENU ENGINE
-- =========================================================
_G.MUSAED_DEVIL_3D = _G.MUSAED_DEVIL_3D or {}
DEVIL3D = _G.MUSAED_DEVIL_3D

DEVIL3D.State = DEVIL3D.State or {}
DEVIL3D.State.Enabled = true
DEVIL3D.State.Hovering = false
DEVIL3D.State.MouseX = 0
DEVIL3D.State.MouseY = 0

DEVIL3D.DepthLeft = DEVIL3D.DepthLeft or Instance.new("Frame")
DEVIL3D.DepthLeft.Name = "DEVIL_3D_LeftDepth"
DEVIL3D.DepthLeft.Size = UDim2.new(0, 7, 1, -34)
DEVIL3D.DepthLeft.Position = UDim2.new(0, -2, 0, 22)
DEVIL3D.DepthLeft.BackgroundColor3 = CurrentAccent
DEVIL3D.DepthLeft.BackgroundTransparency = 0.82
DEVIL3D.DepthLeft.BorderSizePixel = 0
DEVIL3D.DepthLeft.ZIndex = 0
DEVIL3D.DepthLeft.Parent = MainFrame
DEVIL3D.DepthLeft.Visible = false

DEVIL3D.DepthRight = DEVIL3D.DepthRight or Instance.new("Frame")
DEVIL3D.DepthRight.Name = "DEVIL_3D_RightDepth"
DEVIL3D.DepthRight.Size = UDim2.new(0, 7, 1, -34)
DEVIL3D.DepthRight.Position = UDim2.new(1, -5, 0, 22)
DEVIL3D.DepthRight.BackgroundColor3 = CurrentAccent
DEVIL3D.DepthRight.BackgroundTransparency = 0.86
DEVIL3D.DepthRight.BorderSizePixel = 0
DEVIL3D.DepthRight.ZIndex = 0
DEVIL3D.DepthRight.Parent = MainFrame
DEVIL3D.DepthRight.Visible = false

DEVIL3D.BottomDepth = DEVIL3D.BottomDepth or Instance.new("Frame")
DEVIL3D.BottomDepth.Name = "DEVIL_3D_BottomDepth"
DEVIL3D.BottomDepth.Size = UDim2.new(1, -28, 0, 8)
DEVIL3D.BottomDepth.Position = UDim2.new(0, 14, 1, -2)
DEVIL3D.BottomDepth.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
DEVIL3D.BottomDepth.BackgroundTransparency = 0.48
DEVIL3D.BottomDepth.BorderSizePixel = 0
DEVIL3D.BottomDepth.ZIndex = 0
DEVIL3D.BottomDepth.Parent = MainFrame
DEVIL3D.BottomDepth.Visible = false

DEVIL3D.EdgeGlow = DEVIL3D.EdgeGlow or Instance.new("UIStroke")
DEVIL3D.EdgeGlow.Name = "DEVIL_3D_EdgeGlow"
DEVIL3D.EdgeGlow.Color = CurrentAccent
DEVIL3D.EdgeGlow.Thickness = 1.7
DEVIL3D.EdgeGlow.Transparency = 0.22
DEVIL3D.EdgeGlow.Parent = MainFrame
RegisterThemeElement(DEVIL3D.EdgeGlow, "Stroked")
RegisterThemeElement(DEVIL3D.DepthLeft, "BackgroundColored")
RegisterThemeElement(DEVIL3D.DepthRight, "BackgroundColored")

DEVIL3D.LightBar = DEVIL3D.LightBar or Instance.new("Frame")
DEVIL3D.LightBar.Name = "DEVIL_3D_SweepingLight"
DEVIL3D.LightBar.Size = UDim2.new(0, 130, 0, 2)
DEVIL3D.LightBar.Position = UDim2.new(-0.18, 0, 0, 10)
DEVIL3D.LightBar.BackgroundColor3 = CurrentAccent
DEVIL3D.LightBar.BackgroundTransparency = 0.05
DEVIL3D.LightBar.BorderSizePixel = 0
DEVIL3D.LightBar.ZIndex = 8
DEVIL3D.LightBar.Parent = MainFrame
local DEVIL3DLightGradient = Instance.new("UIGradient")
DEVIL3DLightGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.5, 0),
    NumberSequenceKeypoint.new(1, 1)
})
DEVIL3DLightGradient.Parent = DEVIL3D.LightBar
RegisterThemeElement(DEVIL3D.LightBar, "BackgroundColored")

DEVIL3D.Sweep = function()
    if not DEVIL3D.LightBar or not DEVIL3D.LightBar.Parent then return end
    if not AnimationEnabled then return end
    DEVIL3D.LightBar.Position = UDim2.new(-0.18, 0, 0, 10)
    TweenService:Create(
        DEVIL3D.LightBar,
        TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        {Position = UDim2.new(1.05, 0, 0, 10)}
    ):Play()
end

task.spawn(function()
    while DEVIL3D and DEVIL3D.State and DEVIL3D.State.Enabled do
        task.wait(2.7)
        pcall(DEVIL3D.Sweep)
    end
end)

DEVIL3D.BindPageScroll = function(page)
    if not page or page:GetAttribute("DEVIL_SmoothScroll") then return end
    page:SetAttribute("DEVIL_SmoothScroll", true)
    page.ScrollBarThickness = 3
    page.ScrollBarImageTransparency = 0.08
    page.ScrollingDirection = Enum.ScrollingDirection.Y

    page.InputChanged:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end
        local amount = -input.Position.Z * 42
        local maxY = math.max(0, page.AbsoluteCanvasSize.Y - page.AbsoluteWindowSize.Y)
        local target = math.clamp(page.CanvasPosition.Y + amount, 0, maxY)
        if AnimationEnabled then
            TweenService:Create(
                page,
                TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {CanvasPosition = Vector2.new(0, target)}
            ):Play()
        else
            page.CanvasPosition = Vector2.new(0, target)
        end
    end)
end

for _, page in ipairs(Pages) do
    pcall(function() DEVIL3D.BindPageScroll(page) end)
end

DEVIL3D.UpdateTilt = function(x, y)
    if not MainFrame or not MainFrame.Parent then return end
    if not DEVIL3D.State.Hovering then return end

    local centerX = MainFrame.AbsolutePosition.X + MainFrame.AbsoluteSize.X * 0.5
    local centerY = MainFrame.AbsolutePosition.Y + MainFrame.AbsoluteSize.Y * 0.5
    local nx = math.clamp((x - centerX) / math.max(MainFrame.AbsoluteSize.X * 0.5, 1), -1, 1)
    local ny = math.clamp((y - centerY) / math.max(MainFrame.AbsoluteSize.Y * 0.5, 1), -1, 1)

    DEVIL3D.State.MouseX = nx
    DEVIL3D.State.MouseY = ny
end

MainFrame.MouseEnter:Connect(function()
    DEVIL3D.State.Hovering = true
    if AnimationEnabled then
        TweenService:Create(
            DEVIL3D.EdgeGlow,
            TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Thickness = 2.2, Transparency = 0.05}
        ):Play()
    end
end)

MainFrame.MouseLeave:Connect(function()
    DEVIL3D.State.Hovering = false
    if AnimationEnabled then
        TweenService:Create(
            DEVIL3D.EdgeGlow,
            TweenInfo.new(0.22),
            {Thickness = 1.7, Transparency = 0.22}
        ):Play()
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and DEVIL3D.State.Hovering then
        pcall(function()
            DEVIL3D.UpdateTilt(input.Position.X, input.Position.Y)
        end)
    end
end)

if Tabs[1] and Pages[1] then
    for _, btn in ipairs(Tabs) do
        btn:SetAttribute("DEVIL_Active", false)
    end
    Tabs[1]:SetAttribute("DEVIL_Active", true)
    local firstStroke = Tabs[1]:FindFirstChildOfClass("UIStroke")
    if firstStroke then firstStroke.Transparency = 0.18 end
    local firstGlow = Tabs[1]:FindFirstChild("DEVIL_TabGlow")
    if firstGlow then firstGlow.BackgroundTransparency = 0.08 end
    Pages[1].Visible = true
    Pages[1].Position = UDim2.new(0, 0, 0, 0)
    if DEVIL_EXTRA and DEVIL_EXTRA.State then
        DEVIL_EXTRA.State.ActiveTabIndex = 1
    end
end

DEVIL3D.Notify = function(message)
    if Notify then
        pcall(function() Notify(message, CurrentAccent) end)
    end
end

DEVIL3D.Notify("DEVIL 3D MENU • Smooth Slides • 3D Depth", CurrentAccent)

-- ==========================================================
-- DEVIL UI FIX PACK  (الصقه في آخر السكربت، بعد آخر سطر)
-- شريط تابات قابل للسحب + أسهم + سلايد صفحات + ضبط الأحجام + 3D Stack
-- ==========================================================
xpcall(function()

    ---------------------------------------------------------
    -- أدوات صغيرة
    ---------------------------------------------------------
    local function Round(obj, r)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r)
        c.Parent = obj
        return c
    end

    local function Outline(obj, th, tr)
        local s = Instance.new("UIStroke")
        s.Color = CurrentAccent
        s.Thickness = th
        s.Transparency = tr
        s.Parent = obj
        RegisterThemeElement(s, "Stroked")
        return s
    end

    local QUART = Enum.EasingStyle.Quart
    local OUT = Enum.EasingDirection.Out

    ---------------------------------------------------------
    -- 1) ضبط الهيدر (العنوان كان يتداخل مع ONLINE)
    ---------------------------------------------------------
    Title.Size = UDim2.new(0, 200, 1, 0)
    Title.TextSize = 15
    StatusPill.Position = UDim2.new(0, 224, 0.5, -12)

    ---------------------------------------------------------
    -- 2) شريط التابات: ScrollingFrame داخل المنيو + أسهم
    ---------------------------------------------------------
    local Bar = Instance.new("ScrollingFrame")
    Bar.Name = "DEVIL_TabBar"
    Bar.Size = UDim2.new(1, -100, 0, 46)
    Bar.Position = UDim2.new(0, 50, 0, 54)
    Bar.BackgroundTransparency = 1
    Bar.BorderSizePixel = 0
    Bar.ScrollBarThickness = 0
    Bar.ScrollingDirection = Enum.ScrollingDirection.X
    Bar.AutomaticCanvasSize = Enum.AutomaticSize.X
    Bar.CanvasSize = UDim2.new(0, 0, 0, 0)
    Bar.ClipsDescendants = true
    Bar.Parent = MainFrame

    local barPad = Instance.new("UIPadding")
    barPad.PaddingLeft = UDim.new(0, 4)
    barPad.PaddingRight = UDim.new(0, 4)
    barPad.Parent = Bar

    SidebarList.Parent = Bar
    SidebarList.Padding = UDim.new(0, 6)
    SidebarList.VerticalAlignment = Enum.VerticalAlignment.Center

    for _, b in ipairs(Tabs) do
        b.Parent = Bar
        b.AutomaticSize = Enum.AutomaticSize.X
        b.Size = UDim2.new(0, 0, 0, 36)
        b.TextXAlignment = Enum.TextXAlignment.Center
        b.Text = b.Text:gsub("^%s+", "")
        local p = Instance.new("UIPadding")
        p.PaddingLeft = UDim.new(0, 16)
        p.PaddingRight = UDim.new(0, 16)
        p.Parent = b
    end
    Sidebar.Visible = false

    local function MakeArrow(txt, pos)
        local a = Instance.new("TextButton")
        a.Size = UDim2.new(0, 34, 0, 34)
        a.Position = pos
        a.BackgroundColor3 = Color3.fromRGB(18, 28, 48)
        a.BorderSizePixel = 0
        a.AutoButtonColor = false
        a.Text = txt
        a.TextColor3 = Color3.fromRGB(235, 242, 255)
        a.TextSize = 22
        a.Font = Enum.Font.GothamBold
        a.ZIndex = 5
        a.Parent = MainFrame
        Round(a, 9)
        Outline(a, 1.2, 0.2)
        AddButtonMotion(a)
        return a
    end

    local ArrowL = MakeArrow("‹", UDim2.new(0, 10, 0, 60))
    local ArrowR = MakeArrow("›", UDim2.new(1, -44, 0, 60))

    local function ScrollBar(delta)
        local maxX = math.max(0, Bar.AbsoluteCanvasSize.X - Bar.AbsoluteSize.X)
        local target = math.clamp(Bar.CanvasPosition.X + delta, 0, maxX)
        TweenService:Create(Bar, TweenInfo.new(0.3, QUART, OUT), {CanvasPosition = Vector2.new(target, 0)}):Play()
    end

    local function RefreshArrows()
        local maxX = math.max(0, Bar.AbsoluteCanvasSize.X - Bar.AbsoluteSize.X)
        ArrowL.TextTransparency = Bar.CanvasPosition.X <= 2 and 0.65 or 0
        ArrowR.TextTransparency = Bar.CanvasPosition.X >= maxX - 2 and 0.65 or 0
    end
    Bar:GetPropertyChangedSignal("CanvasPosition"):Connect(RefreshArrows)
    Bar:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(RefreshArrows)

    ArrowL.MouseButton1Click:Connect(function() PlayClick() ScrollBar(-260) end)
    ArrowR.MouseButton1Click:Connect(function() PlayClick() ScrollBar(260) end)

    Bar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            ScrollBar(-input.Position.Z * 120)
        end
    end)

    local function CenterTab(btn)
        if not btn then return end
        local x = btn.AbsolutePosition.X - Bar.AbsolutePosition.X + Bar.CanvasPosition.X
        local target = x - (Bar.AbsoluteSize.X - btn.AbsoluteSize.X) / 2
        local maxX = math.max(0, Bar.AbsoluteCanvasSize.X - Bar.AbsoluteSize.X)
        target = math.clamp(target, 0, maxX)
        TweenService:Create(Bar, TweenInfo.new(0.35, QUART, OUT), {CanvasPosition = Vector2.new(target, 0)}):Play()
    end

    ---------------------------------------------------------
    -- 3) حجم منطقة الصفحات (البروفايل كان يغطي آخر الكروت)
    ---------------------------------------------------------
    PageContainer.Size = UDim2.new(1, -24, 1, -186)
    PageContainer.Position = UDim2.new(0, 12, 0, 108)
    PageContainer.ClipsDescendants = true

    for _, p in ipairs(Pages) do
        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 3)
        pad.PaddingBottom = UDim.new(0, 12)
        pad.PaddingLeft = UDim.new(0, 3)
        pad.PaddingRight = UDim.new(0, 3)
        pad.Parent = p

        -- يمنع وميض اللون أثناء السلايد
        p.BackgroundTransparency = 1
        p:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
            if p.BackgroundTransparency ~= 1 then p.BackgroundTransparency = 1 end
        end)
    end

    -- ترتيب العناصر الخاصة داخل الصفحات + عرض موحد
    HomeHero.LayoutOrder = -1
    DEVIL_EXTRA.AvatarStudioFrame.LayoutOrder = -1
    DEVIL_EXTRA.TeleportInput.LayoutOrder = -1
    DEVIL_EXTRA.TeleportInput.Size = UDim2.new(1, -6, 0, 40)
    DEVIL_EXTRA.AccentInput.LayoutOrder = -1
    DEVIL_EXTRA.AccentInput.Size = UDim2.new(1, -6, 0, 40)
    DEVIL_EXTRA.PerformanceLabel.LayoutOrder = -3
    DEVIL_EXTRA.PerformanceLabel.Size = UDim2.new(1, -6, 0, 42)
    DEVIL_EXTRA.SearchInput.LayoutOrder = -2
    DEVIL_EXTRA.SearchInput.Size = UDim2.new(1, -6, 0, 40)
    DEVIL_EXTRA.SearchHint.LayoutOrder = -1
    DEVIL_EXTRA.SearchHint.Size = UDim2.new(1, -6, 0, 26)

    ---------------------------------------------------------
    -- 4) الكروت: قص النص الطويل + حافة 3D + هوفر + Pop
    ---------------------------------------------------------
    local isCard = {}
    for _, item in ipairs(AllCards) do
        local card = item.Card
        if card then
            isCard[card] = true
            for _, d in ipairs(card:GetChildren()) do
                if d:IsA("TextLabel") then d.TextTruncate = Enum.TextTruncate.AtEnd end
            end

            local ledge = Instance.new("Frame")
            ledge.Name = "DEVIL_Ledge"
            ledge.Size = UDim2.new(1, -20, 0, 3)
            ledge.Position = UDim2.new(0, 10, 1, -4)
            ledge.BackgroundColor3 = CurrentAccent
            ledge.BackgroundTransparency = 0.72
            ledge.BorderSizePixel = 0
            ledge.Parent = card
            Round(ledge, 3)
            RegisterThemeElement(ledge, "BackgroundColored")

            local stroke = card:FindFirstChildOfClass("UIStroke")
            local sc = Instance.new("UIScale")
            sc.Name = "DEVIL_Pop"
            sc.Parent = card

            card.MouseEnter:Connect(function()
                if not AnimationEnabled then return end
                TweenService:Create(sc, TweenInfo.new(0.18, QUART, OUT), {Scale = 1.012}):Play()
                TweenService:Create(ledge, TweenInfo.new(0.18), {BackgroundTransparency = 0.25}):Play()
                if stroke then TweenService:Create(stroke, TweenInfo.new(0.18), {Thickness = 1.9}):Play() end
            end)
            card.MouseLeave:Connect(function()
                TweenService:Create(sc, TweenInfo.new(0.2, QUART, OUT), {Scale = 1}):Play()
                TweenService:Create(ledge, TweenInfo.new(0.2), {BackgroundTransparency = 0.72}):Play()
                if stroke then TweenService:Create(stroke, TweenInfo.new(0.2), {Thickness = 1}):Play() end
            end)
        end
    end

    -- Pop للوحات الكبيرة (Hero / Avatar Studio)
    for _, p in ipairs(Pages) do
        for _, child in ipairs(p:GetChildren()) do
            if child:IsA("Frame") and not child:FindFirstChild("DEVIL_Pop") then
                local sc = Instance.new("UIScale")
                sc.Name = "DEVIL_Pop"
                sc.Parent = child
            end
        end
    end

    local function Pop(page)
        if not AnimationEnabled then return end
        local i = 0
        for _, child in ipairs(page:GetChildren()) do
            local s = child:FindFirstChild("DEVIL_Pop")
            if s then
                i += 1
                s.Scale = 0.9
                task.delay(math.min(i * 0.035, 0.4), function()
                    TweenService:Create(s, TweenInfo.new(0.34, Enum.EasingStyle.Back, OUT), {Scale = 1}):Play()
                end)
            end
        end
    end

    for _, p in ipairs(Pages) do
        p:GetPropertyChangedSignal("Visible"):Connect(function()
            if p.Visible then Pop(p) end
        end)
    end

    ---------------------------------------------------------
    -- 5) شريط التنقل السفلي (سلايد): السابق / الاسم / التالي / تقدم
    ---------------------------------------------------------
    local Nav = Instance.new("Frame")
    Nav.Name = "DEVIL_NavBar"
    Nav.Size = UDim2.new(1, -240, 0, 60)
    Nav.Position = UDim2.new(0, 228, 1, -72)
    Nav.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
    Nav.BackgroundTransparency = 0.18
    Nav.BorderSizePixel = 0
    Nav.Parent = MainFrame
    Round(Nav, 10)
    Outline(Nav, 1, 0.5)

    local navGrad = Instance.new("UIGradient")
    navGrad.Color = ColorSequence.new(Color3.fromRGB(21, 35, 58), Color3.fromRGB(31, 17, 49))
    navGrad.Rotation = 18
    navGrad.Transparency = NumberSequence.new(0.12)
    navGrad.Parent = Nav

    local function NavButton(txt, pos)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 40, 0, 40)
        b.Position = pos
        b.BackgroundColor3 = CurrentAccent
        b.BorderSizePixel = 0
        b.AutoButtonColor = false
        b.Text = txt
        b.TextColor3 = Color3.fromRGB(7, 10, 14)
        b.TextSize = 22
        b.Font = Enum.Font.GothamBold
        b.Parent = Nav
        Round(b, 10)
        RegisterThemeElement(b, "BackgroundColored")
        AddButtonMotion(b)
        return b
    end

    local NavPrev = NavButton("‹", UDim2.new(0, 10, 0.5, -20))
    local NavNext = NavButton("›", UDim2.new(1, -50, 0.5, -20))

    local NavLabel = Instance.new("TextLabel")
    NavLabel.Size = UDim2.new(1, -120, 0, 24)
    NavLabel.Position = UDim2.new(0, 60, 0, 9)
    NavLabel.BackgroundTransparency = 1
    NavLabel.TextColor3 = Color3.fromRGB(240, 246, 255)
    NavLabel.TextSize = 13
    NavLabel.Font = Enum.Font.GothamBold
    NavLabel.TextTruncate = Enum.TextTruncate.AtEnd
    NavLabel.Text = ""
    NavLabel.Parent = Nav

    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, -128, 0, 6)
    Track.Position = UDim2.new(0, 64, 1, -18)
    Track.BackgroundColor3 = Color3.fromRGB(30, 40, 58)
    Track.BorderSizePixel = 0
    Track.Parent = Nav
    Round(Track, 3)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(0, 0, 1, 0)
    Fill.BackgroundColor3 = CurrentAccent
    Fill.BorderSizePixel = 0
    Fill.Parent = Track
    Round(Fill, 3)
    RegisterThemeElement(Fill, "BackgroundColored")

    local function UpdateNav(i)
        local btn = Tabs[i]
        if not btn then return end
        NavLabel.Text = btn.Text .. "   •   " .. i .. " / " .. #Tabs
        TweenService:Create(Fill, TweenInfo.new(0.35, QUART, OUT), {Size = UDim2.new(i / #Tabs, 0, 1, 0)}):Play()
        CenterTab(btn)
    end

    local function SelectTab(i, dir)
        local n = #Tabs
        i = ((i - 1) % n) + 1
        local btn, page = Tabs[i], Pages[i]
        if not btn or not page then return end
        dir = dir or 1
        DEVIL_EXTRA.State.ActiveTabIndex = i

        for _, b in ipairs(Tabs) do
            b:SetAttribute("DEVIL_Active", false)
            TweenService:Create(b, TweenInfo.new(0.22, QUART, OUT), {
                BackgroundColor3 = Color3.fromRGB(18, 22, 28),
                TextColor3 = Color3.fromRGB(140, 150, 165)
            }):Play()
            local st = b:FindFirstChildOfClass("UIStroke")
            if st then st.Transparency = 1 end
            local gl = b:FindFirstChild("DEVIL_TabGlow")
            if gl then TweenService:Create(gl, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play() end
        end
        for _, p in ipairs(Pages) do
            if p ~= page then p.Visible = false end
        end

        btn:SetAttribute("DEVIL_Active", true)
        TweenService:Create(btn, TweenInfo.new(0.26, QUART, OUT), {
            BackgroundColor3 = Color3.fromRGB(27, 36, 52),
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
        local st = btn:FindFirstChildOfClass("UIStroke")
        if st then st.Transparency = 0.18 end
        local gl = btn:FindFirstChild("DEVIL_TabGlow")
        if gl then TweenService:Create(gl, TweenInfo.new(0.22), {BackgroundTransparency = 0.08}):Play() end

        page.Position = UDim2.new(0, dir * 70, 0, 0)
        page.Visible = true
        TweenService:Create(page, TweenInfo.new(0.34, QUART, OUT), {Position = UDim2.new(0, 0, 0, 0)}):Play()
        UpdateNav(i)
    end

    NavPrev.MouseButton1Click:Connect(function()
        PlayClick()
        SelectTab((DEVIL_EXTRA.State.ActiveTabIndex or 1) - 1, -1)
    end)
    NavNext.MouseButton1Click:Connect(function()
        PlayClick()
        SelectTab((DEVIL_EXTRA.State.ActiveTabIndex or 1) + 1, 1)
    end)

    -- النقر المباشر على أي تاب (الكود الأصلي يشتغل أولاً ثم نحدّث الشريط)
    for idx, b in ipairs(Tabs) do
        b.MouseButton1Click:Connect(function() UpdateNav(idx) end)
    end

    -- كيبورد: Ctrl + ← / →
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not MainFrame.Visible then return end
        if UserInputService:GetFocusedTextBox() then return end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            local cur = DEVIL_EXTRA.State.ActiveTabIndex or 1
            if input.KeyCode == Enum.KeyCode.Right then SelectTab(cur + 1, 1)
            elseif input.KeyCode == Enum.KeyCode.Left then SelectTab(cur - 1, -1) end
        end
    end)

    task.defer(function()
        task.wait(0.3)
        UpdateNav(DEVIL_EXTRA.State.ActiveTabIndex or 1)
        RefreshArrows()
    end)

    ---------------------------------------------------------
    -- 6) الحافة المضيئة الدوّارة + اختصار إظهار/إخفاء المنيو
    --    (الـ 3D Stack نفسه صار من Stack3D خلف المنيو)
    ---------------------------------------------------------
    local edgeGrad = Instance.new("UIGradient")
    edgeGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.88),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 0.88)
    })
    edgeGrad.Parent = DEVIL3D.EdgeGlow

    DEVIL3D.UpdateTilt = function() end -- الميلان يُحسب داخل Stack3D

    RunService.RenderStepped:Connect(function()
        if MainFrame.Visible then
            edgeGrad.Rotation = (os.clock() * 55) % 360
        end
    end)

    -- RightShift: إظهار/إخفاء المنيو
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.RightShift and ToggleBtn and ToggleBtn.Visible then
            ToggleMainFrame(not MainFrame.Visible)
        end
    end)

    Notify("✓ DEVIL UI v9: 3D خلف المنيو • خلفية بحجم المنيو • RightShift للإخفاء", CurrentAccent)

end, function(err)
    warn("[DEVIL UI FIX] " .. tostring(err))
end)

-- ==========================================================
-- DEVIL UI PRO PACK v10
-- ثيمات جديدة • معرض خلفيات بالصور • حفظ الإعدادات • شريط FPS/Ping • اختصارات
-- ==========================================================
xpcall(function()
    local HttpService = game:GetService("HttpService")
    local StatsService = game:GetService("Stats")

    local function Round(o, r)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r)
        c.Parent = o
        return c
    end
    local function Dark(c, a) return c:Lerp(Color3.new(0, 0, 0), a) end

    -- شيل كروت الثيمات/الخلفيات القديمة (تحل محلها معارض مرئية)
    local function PurgeCards(page)
        for i = #AllCards, 1, -1 do
            local it = AllCards[i]
            if it.OriginalParent == page then
                if it.Card then it.Card:Destroy() end
                table.remove(AllCards, i)
            end
        end
    end
    PurgeCards(ThemePage)
    PurgeCards(BackgroundPage)

    ---------------------------------------------------------
    -- 1) الثيمات (15 ثيم)
    ---------------------------------------------------------
    local Themes = {
        {"التراكواز", Color3.fromRGB(52, 182, 189)},
        {"البنفسجي النيون", Color3.fromRGB(155, 89, 182)},
        {"الزمردي", Color3.fromRGB(46, 204, 113)},
        {"الياقوتي", Color3.fromRGB(231, 76, 60)},
        {"الذهبي", Color3.fromRGB(241, 196, 15)},
        {"أزرق جليدي", Color3.fromRGB(90, 190, 255)},
        {"وردي ناري", Color3.fromRGB(255, 70, 160)},
        {"غروب برتقالي", Color3.fromRGB(255, 140, 50)},
        {"ليموني سام", Color3.fromRGB(170, 255, 60)},
        {"أزرق ملكي", Color3.fromRGB(65, 105, 255)},
        {"روز جولد", Color3.fromRGB(232, 160, 150)},
        {"فضي", Color3.fromRGB(200, 210, 225)},
        {"نعناعي", Color3.fromRGB(100, 255, 200)},
        {"قرمزي ليلي", Color3.fromRGB(200, 30, 70)},
        {"نيلي منتصف الليل", Color3.fromRGB(110, 100, 235)},
    }

    local themeGrid = Instance.new("Frame")
    themeGrid.Name = "DEVIL_ThemeGrid"
    themeGrid.BackgroundTransparency = 1
    themeGrid.Size = UDim2.new(1, -6, 0, 0)
    themeGrid.AutomaticSize = Enum.AutomaticSize.Y
    themeGrid.LayoutOrder = -1
    themeGrid.Parent = ThemePage
    local tgl = Instance.new("UIGridLayout")
    tgl.CellSize = UDim2.new(0, 128, 0, 92)
    tgl.CellPadding = UDim2.new(0, 8, 0, 8)
    tgl.SortOrder = Enum.SortOrder.LayoutOrder
    tgl.Parent = themeGrid

    local themeTiles = {}
    local function SameColor(a, b)
        return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) < 0.02
    end
    local function MarkThemes()
        for i, th in ipairs(Themes) do
            local t = themeTiles[i]
            local on = SameColor(th[2], CurrentAccent)
            t.ck.Visible = on
            t.st.Transparency = on and 0.05 or 0.75
        end
    end

    for i, th in ipairs(Themes) do
        local b = Instance.new("TextButton")
        b.Name = "Theme_" .. i
        b.LayoutOrder = i
        b.Text = ""
        b.AutoButtonColor = false
        b.BackgroundColor3 = Color3.fromRGB(16, 22, 32)
        b.BackgroundTransparency = 0.1
        b.BorderSizePixel = 0
        b.Parent = themeGrid
        Round(b, 10)

        local st = Instance.new("UIStroke")
        st.Color = th[2]
        st.Thickness = 1.6
        st.Transparency = 0.75
        st.Parent = b

        local sw = Instance.new("Frame")
        sw.Size = UDim2.new(1, -12, 0, 48)
        sw.Position = UDim2.new(0, 6, 0, 6)
        sw.BorderSizePixel = 0
        sw.BackgroundColor3 = Color3.new(1, 1, 1)
        sw.Parent = b
        Round(sw, 8)
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new(th[2], Dark(th[2], 0.78))
        g.Rotation = 35
        g.Parent = sw

        local nm = Instance.new("TextLabel")
        nm.Size = UDim2.new(1, -12, 0, 24)
        nm.Position = UDim2.new(0, 6, 0, 60)
        nm.BackgroundTransparency = 1
        nm.Text = th[1]
        nm.TextColor3 = Color3.fromRGB(235, 242, 250)
        nm.TextSize = 11
        nm.Font = Enum.Font.GothamBold
        nm.TextTruncate = Enum.TextTruncate.AtEnd
        nm.Parent = b

        local ck = Instance.new("TextLabel")
        ck.Size = UDim2.new(0, 20, 0, 20)
        ck.Position = UDim2.new(1, -28, 0, 10)
        ck.BackgroundColor3 = Color3.fromRGB(8, 12, 18)
        ck.Text = "✓"
        ck.TextColor3 = th[2]
        ck.TextSize = 13
        ck.Font = Enum.Font.GothamBold
        ck.Visible = false
        ck.ZIndex = 3
        ck.Parent = b
        Round(ck, 10)

        b.MouseEnter:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.16), {BackgroundColor3 = Color3.fromRGB(26, 36, 52)}):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.16), {BackgroundColor3 = Color3.fromRGB(16, 22, 32)}):Play()
        end)
        b.MouseButton1Click:Connect(function()
            PlayClick()
            UpdateTheme(th[2])
            if Notify then Notify("🎨 ثيم " .. th[1], th[2]) end
        end)
        themeTiles[i] = {b = b, st = st, ck = ck}
    end

    -- تبديل تلقائي
    local cycleOn = false
    CreateCard(ThemePage, "تبديل ثيمات تلقائي", "يغيّر الثيم كل 6 ثواني", "تشغيل", function(btn)
        cycleOn = not cycleOn
        btn.Text = cycleOn and "إيقاف" or "تشغيل"
        if cycleOn then
            task.spawn(function()
                local idx = 1
                while cycleOn and ScreenGui and ScreenGui.Parent do
                    idx = idx % #Themes + 1
                    UpdateTheme(Themes[idx][2])
                    task.wait(6)
                end
            end)
        end
    end)

    ---------------------------------------------------------
    -- 2) معرض الخلفيات: كل خلفية تبين صورتها
    ---------------------------------------------------------
    local bgGrid = Instance.new("Frame")
    bgGrid.Name = "DEVIL_BackgroundGallery"
    bgGrid.BackgroundTransparency = 1
    bgGrid.Size = UDim2.new(1, -6, 0, 0)
    bgGrid.AutomaticSize = Enum.AutomaticSize.Y
    bgGrid.LayoutOrder = -1
    bgGrid.Parent = BackgroundPage
    local bgl = Instance.new("UIGridLayout")
    bgl.CellSize = UDim2.new(0, 266, 0, 150)
    bgl.CellPadding = UDim2.new(0, 8, 0, 8)
    bgl.SortOrder = Enum.SortOrder.LayoutOrder
    bgl.Parent = bgGrid

    local bgTiles = {}
    local function MarkBackgrounds(idx)
        for i, t in ipairs(bgTiles) do
            t.ck.Visible = (i == idx)
            t.st.Transparency = (i == idx) and 0.05 or 0.75
        end
    end

    for i, bg in ipairs(Backgrounds) do
        local tile = Instance.new("TextButton")
        tile.Name = "Background_" .. i
        tile.LayoutOrder = i
        tile.Text = ""
        tile.AutoButtonColor = false
        tile.BackgroundColor3 = Color3.fromRGB(10, 14, 22)
        tile.BorderSizePixel = 0
        tile.Parent = bgGrid
        Round(tile, 12)

        local st = Instance.new("UIStroke")
        st.Color = CurrentAccent
        st.Thickness = 2
        st.Transparency = 0.75
        st.Parent = tile
        RegisterThemeElement(st, "Stroked")

        local img = Instance.new("ImageLabel")
        img.Size = UDim2.fromScale(1, 1)
        img.BackgroundTransparency = 1
        img.BorderSizePixel = 0
        img.ZIndex = 1
        img.Parent = tile
        Round(img, 12)
        SetImageWithFallback(img, bg.Id)

        local status = Instance.new("TextLabel")
        status.Size = UDim2.new(1, -20, 0, 20)
        status.Position = UDim2.new(0, 10, 0.5, -10)
        status.BackgroundTransparency = 1
        status.Text = "جاري تحميل الصورة..."
        status.TextColor3 = Color3.fromRGB(150, 165, 185)
        status.TextSize = 11
        status.Font = Enum.Font.GothamMedium
        status.ZIndex = 2
        status.Parent = tile

        local strip = Instance.new("Frame")
        strip.Size = UDim2.new(1, 0, 0, 44)
        strip.Position = UDim2.new(0, 0, 1, -44)
        strip.BackgroundColor3 = Color3.new(0, 0, 0)
        strip.BorderSizePixel = 0
        strip.ZIndex = 3
        strip.Parent = tile
        Round(strip, 12)
        local sg = Instance.new("UIGradient")
        sg.Rotation = 90
        sg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0.15)
        })
        sg.Parent = strip

        local nm = Instance.new("TextLabel")
        nm.Size = UDim2.new(1, -20, 0, 20)
        nm.Position = UDim2.new(0, 12, 1, -26)
        nm.BackgroundTransparency = 1
        nm.Text = bg.Name
        nm.TextColor3 = Color3.fromRGB(255, 255, 255)
        nm.TextSize = 13
        nm.Font = Enum.Font.GothamBold
        nm.TextXAlignment = Enum.TextXAlignment.Left
        nm.ZIndex = 4
        nm.Parent = tile

        local ck = Instance.new("TextLabel")
        ck.Size = UDim2.new(0, 26, 0, 26)
        ck.Position = UDim2.new(1, -36, 0, 10)
        ck.BackgroundColor3 = CurrentAccent
        ck.Text = "✓"
        ck.TextColor3 = Color3.fromRGB(5, 8, 12)
        ck.TextSize = 14
        ck.Font = Enum.Font.GothamBold
        ck.Visible = false
        ck.ZIndex = 5
        ck.Parent = tile
        Round(ck, 13)
        RegisterThemeElement(ck, "BackgroundColored")

        img:GetAttributeChangedSignal("BackgroundLoaded"):Connect(function()
            if img:GetAttribute("BackgroundLoaded") then status.Visible = false end
        end)
        img:GetAttributeChangedSignal("BackgroundFailed"):Connect(function()
            if img:GetAttribute("BackgroundFailed") then
                status.Visible = true
                status.Text = "تعذر تحميل الصورة • اضغط للمحاولة مرة ثانية"
            end
        end)
        if img:GetAttribute("BackgroundLoaded") then status.Visible = false end

        tile.MouseEnter:Connect(function()
            TweenService:Create(st, TweenInfo.new(0.15), {Transparency = 0.2}):Play()
        end)
        tile.MouseLeave:Connect(function()
            local on = (SelectedBackground == i)
            TweenService:Create(st, TweenInfo.new(0.15), {Transparency = on and 0.05 or 0.75}):Play()
        end)
        tile.MouseButton1Click:Connect(function()
            PlayClick()
            if img:GetAttribute("BackgroundFailed") then
                status.Text = "جاري تحميل الصورة..."
                BgCache[tostring(bg.Id)] = nil
                SetImageWithFallback(img, bg.Id)
            end
            ApplySelectedBackground(i)
            if Notify then Notify("🖼 تم تطبيق خلفية " .. bg.Name, CurrentAccent) end
        end)
        bgTiles[i] = {tile = tile, img = img, st = st, ck = ck}
    end

    CreateCard(BackgroundPage, "إعادة تحميل الخلفيات", "إذا ما ظهرت الصور اضغط هنا", "تحديث", function()
        for k in pairs(BgCache) do BgCache[k] = nil end
        for i, t in ipairs(bgTiles) do SetImageWithFallback(t.img, Backgrounds[i].Id) end
        local bgNow = Backgrounds[SelectedBackground]
        if bgNow then
            if MainBackgroundImage then SetImageWithFallback(MainBackgroundImage, bgNow.Id) end
        end
    end)

    ---------------------------------------------------------
    -- 3) شريط FPS / Ping في الهيدر
    ---------------------------------------------------------
    local perf = Instance.new("TextLabel")
    perf.Name = "DEVIL_PerfPill"
    perf.Size = UDim2.new(0, 160, 0, 24)
    perf.Position = UDim2.new(0, 304, 0.5, -12)
    perf.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
    perf.BackgroundTransparency = 0.2
    perf.BorderSizePixel = 0
    perf.Text = "FPS --  •  PING --"
    perf.TextColor3 = Color3.fromRGB(170, 190, 215)
    perf.TextSize = 10
    perf.Font = Enum.Font.GothamBold
    perf.Parent = Header
    Round(perf, 12)

    local frames, acc = 0, 0
    RunService.RenderStepped:Connect(function(dt)
        frames = frames + 1
        acc = acc + dt
        if acc >= 0.5 and MainFrame.Visible then
            local fps = math.floor(frames / acc + 0.5)
            local ping = 0
            pcall(function() ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5) end)
            perf.Text = "FPS " .. fps .. "  •  PING " .. ping .. "ms"
            perf.TextColor3 = (fps >= 50 and Color3.fromRGB(110, 230, 170)) or (fps >= 30 and Color3.fromRGB(240, 200, 90)) or Color3.fromRGB(240, 100, 90)
            frames, acc = 0, 0
        elseif acc >= 0.5 then
            frames, acc = 0, 0
        end
    end)

    ---------------------------------------------------------
    -- 4) اختصارات
    ---------------------------------------------------------
    local shortcutCard = CreateCard(DEVIL_EXTRA.Pages.Settings, "الاختصارات", "RightShift • Ctrl+K • Ctrl+← / →", "عرض", function()
        if Notify then Notify("RightShift: إخفاء/إظهار  •  Ctrl+K: بحث  •  Ctrl+←/→: تنقل التابات", CurrentAccent) end
    end)
    for _, d in ipairs(shortcutCard:GetChildren()) do
        if d:IsA("TextLabel") then d.TextTruncate = Enum.TextTruncate.AtEnd end
    end

    ---------------------------------------------------------
    -- 5) حفظ وتحميل الإعدادات (لو الـ executor يدعم writefile)
    ---------------------------------------------------------
    local CFG = "MusaedHub_Config_v10.json"
    local lastSaved = ""
    local function SaveNow()
        if type(writefile) ~= "function" then return end
        local ok, js = pcall(function()
            return HttpService:JSONEncode({
                r = math.floor(CurrentAccent.R * 255 + 0.5),
                g = math.floor(CurrentAccent.G * 255 + 0.5),
                b = math.floor(CurrentAccent.B * 255 + 0.5),
                bg = SelectedBackground,
                sound = SoundEnabled,
                anim = AnimationEnabled,
                motion = BackgroundMotionEnabled,
            })
        end)
        if ok and js ~= lastSaved then
            lastSaved = js
            pcall(writefile, CFG, js)
        end
    end

    local function Tint(frame, accent)
        local ov = frame and frame:FindFirstChild("GlassOverlay")
        if ov then
            TweenService:Create(ov, TweenInfo.new(0.35), {BackgroundColor3 = Dark(accent, 0.9)}):Play()
        end
    end

    _G.MUSAED_THEME_HOOK = function(color)
        MarkThemes()
        Tint(MainFrame, color)
        task.delay(1, SaveNow)
    end
    _G.MUSAED_BG_HOOK = function(index)
        MarkBackgrounds(index)
        task.delay(1, SaveNow)
    end

    if type(isfile) == "function" and type(readfile) == "function" then
        pcall(function()
            if isfile(CFG) then
                local d = HttpService:JSONDecode(readfile(CFG))
                if type(d.r) == "number" then UpdateTheme(Color3.fromRGB(d.r, d.g, d.b)) end
                if type(d.bg) == "number" and Backgrounds[d.bg] then ApplySelectedBackground(d.bg) end
                if type(d.sound) == "boolean" then SoundEnabled = d.sound end
                if type(d.anim) == "boolean" then AnimationEnabled = d.anim end
                if type(d.motion) == "boolean" then BackgroundMotionEnabled = d.motion end
            end
        end)
    end

    MarkThemes()
    MarkBackgrounds(SelectedBackground)
    Tint(MainFrame, CurrentAccent)

    task.spawn(function()
        while ScreenGui and ScreenGui.Parent do
            task.wait(8)
            SaveNow()
        end
    end)

    Notify("✓ DEVIL v10: 15 ثيم • معرض خلفيات بالصور • حفظ تلقائي", CurrentAccent)
end, function(err)
    warn("[DEVIL PRO PACK] " .. tostring(err))
end)


-- ==========================================================
-- MUSAED HUB v11 FEATURE PACK
-- Profiles • Onboarding • Command Palette • Tooltips • Focus
-- Player Monitor • Waypoints • Console • Notes • Timers
-- Panic • Compact • Resize • Particles • Auto Theme • Glass
-- ==========================================================
xpcall(function()
    local HttpService = game:GetService("HttpService")
    local Stats = game:GetService("Stats")
    local Feature = _G.MUSAED_V11 or {}
    _G.MUSAED_V11 = Feature
    Feature.State = Feature.State or {
        Profiles = {}, ActiveProfile = nil, Focus = false, Compact = false,
        Panic = false, ParticleOn = true, AutoTheme = true, BlurOn = true,
        SmartPerformance = true, Notes = "", Waypoints = {}, Events = {},
        Stopwatch = 0, TimerLeft = 0, TimerRunning = false, StopwatchRunning = false
    }
    local S = Feature.State
    local Connections = Feature.Connections or {}
    Feature.Connections = Connections
    local function Disconnect(key)
        if Connections[key] then pcall(function() Connections[key]:Disconnect() end) Connections[key] = nil end
    end
    local function safe(fn, ...) return pcall(fn, ...) end
    local function Round(o, r)
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r) c.Parent = o return c
    end
    local function Stroke(o, color, transparency)
        local s = Instance.new("UIStroke") s.Color = color or CurrentAccent s.Transparency = transparency or 0.35 s.Thickness = 1 s.Parent = o return s
    end
    local function Label(parent, text, size, pos, color)
        local l = Instance.new("TextLabel") l.BackgroundTransparency = 1 l.Text = text l.TextColor3 = color or Color3.fromRGB(235,242,250)
        l.TextSize = size or 12 l.Font = Enum.Font.GothamMedium l.TextXAlignment = Enum.TextXAlignment.Left l.Size = UDim2.new(1, -24, 0, 24) l.Position = pos or UDim2.new(0,12,0,0) l.Parent = parent return l
    end
    local function Button(parent, text, pos, size, callback)
        local b = Instance.new("TextButton") b.AutoButtonColor = false b.Text = text b.TextColor3 = Color3.fromRGB(235,242,250)
        b.TextSize = 11 b.Font = Enum.Font.GothamBold b.BackgroundColor3 = Color3.fromRGB(22,30,44) b.BorderSizePixel = 0
        b.Size = size or UDim2.new(0,110,0,30) b.Position = pos or UDim2.new() b.Parent = parent Round(b,8) Stroke(b, CurrentAccent, 0.45)
        b.MouseEnter:Connect(function() if AnimationEnabled then TweenService:Create(b,TweenInfo.new(.12),{BackgroundColor3=Color3.fromRGB(35,48,68)}):Play() end end)
        b.MouseLeave:Connect(function() if AnimationEnabled then TweenService:Create(b,TweenInfo.new(.12),{BackgroundColor3=Color3.fromRGB(22,30,44)}):Play() end end)
        b.MouseButton1Click:Connect(function() PlayClick() if callback then safe(callback,b) end end)
        return b
    end
    local function Input(parent, placeholder, pos, size)
        local t = Instance.new("TextBox") t.ClearTextOnFocus = false t.PlaceholderText = placeholder t.Text = "" t.TextColor3 = Color3.fromRGB(255,255,255)
        t.PlaceholderColor3 = Color3.fromRGB(120,135,155) t.TextSize = 11 t.Font = Enum.Font.GothamMedium t.BackgroundColor3 = Color3.fromRGB(14,21,32)
        t.BorderSizePixel = 0 t.Size = size or UDim2.new(1,-24,0,34) t.Position = pos or UDim2.new(0,12,0,0) t.Parent = parent Round(t,8) Stroke(t,Color3.fromRGB(55,72,98),.35) return t
    end
    local function NotifyV(text, color)
        if Notify then Notify("• " .. tostring(text), color or CurrentAccent) end
        table.insert(S.Events, 1, os.date("%H:%M:%S") .. "  " .. tostring(text))
        while #S.Events > 60 do table.remove(S.Events) end
    end

    -- event console
    local function MakeWindow(name, title, size)
        local f = Instance.new("Frame") f.Name=name f.Size=size or UDim2.new(0,420,0,300) f.Position=UDim2.new(.5,-210,.5,-150)
        f.BackgroundColor3=Color3.fromRGB(10,16,26) f.BackgroundTransparency=.08 f.BorderSizePixel=0 f.Visible=false f.Active=true f.Draggable=true f.ZIndex=50 f.Parent=ScreenGui Round(f,14) Stroke(f,CurrentAccent,.18)
        local top=Instance.new("Frame") top.Size=UDim2.new(1,0,0,40) top.BackgroundTransparency=1 top.Parent=f
        Label(top,title,14,UDim2.new(0,14,0,8),Color3.fromRGB(255,255,255)).Size=UDim2.new(1,-60,0,24)
        Button(top,"×",UDim2.new(1,-38,0,6),UDim2.new(0,28,0,28),function() f.Visible=false end)
        return f
    end
    local ConsoleWindow=MakeWindow("V11Console","سجل الأحداث",UDim2.new(0,460,0,300))
    local ConsoleList=Instance.new("ScrollingFrame") ConsoleList.Size=UDim2.new(1,-24,1,-54) ConsoleList.Position=UDim2.new(0,12,0,44) ConsoleList.BackgroundTransparency=1 ConsoleList.BorderSizePixel=0 ConsoleList.AutomaticCanvasSize=Enum.AutomaticSize.Y ConsoleList.Parent=ConsoleWindow
    local cl=Instance.new("UIListLayout") cl.Padding=UDim.new(0,4) cl.Parent=ConsoleList
    local function RefreshConsole()
        for _,c in ipairs(ConsoleList:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
        for _,msg in ipairs(S.Events) do Label(ConsoleList,msg,10,nil,Color3.fromRGB(180,195,215)).Size=UDim2.new(1,-4,0,18) end
    end

    -- notes, timer and stopwatch
    local NotesWindow=MakeWindow("V11Notes","ملاحظات سريعة",UDim2.new(0,420,0,300))
    local NotesBox=Input(NotesWindow,"اكتب ملاحظتك هنا...",UDim2.new(0,12,0,52),UDim2.new(1,-24,1,-108)) NotesBox.MultiLine=true NotesBox.TextYAlignment=Enum.TextYAlignment.Top
    NotesBox.Text=S.Notes
    Button(NotesWindow,"حفظ",UDim2.new(0,12,1,-46),UDim2.new(0,100,0,32),function() S.Notes=NotesBox.Text NotifyV("تم حفظ الملاحظات",Color3.fromRGB(100,230,170)) end)
    local TimerWindow=MakeWindow("V11Timer","المؤقت والستوب ووتش",UDim2.new(0,360,0,220))
    local ClockLabel=Label(TimerWindow,"00:00:00",24,UDim2.new(0,12,0,52),CurrentAccent) ClockLabel.TextXAlignment=Enum.TextXAlignment.Center ClockLabel.Size=UDim2.new(1,-24,0,42)
    local Seconds=Input(TimerWindow,"ثواني المؤقت",UDim2.new(0,12,0,100),UDim2.new(0,150,0,32))
    Button(TimerWindow,"بدء/إيقاف",UDim2.new(0,174,0,100),UDim2.new(0,90,0,32),function()
        if tonumber(Seconds.Text) and not S.TimerRunning then S.TimerLeft=tonumber(Seconds.Text) end S.TimerRunning=not S.TimerRunning S.StopwatchRunning=S.TimerRunning
    end)
    Button(TimerWindow,"تصفير",UDim2.new(0,12,0,146),UDim2.new(0,100,0,30),function() S.TimerLeft=0 S.Stopwatch=0 S.TimerRunning=false S.StopwatchRunning=false end)
    Connections.Clock=RunService.Heartbeat:Connect(function(dt)
        if S.TimerRunning then S.TimerLeft=math.max(0,S.TimerLeft-dt) if S.TimerLeft<=0 then S.TimerRunning=false NotifyV("انتهى المؤقت",Color3.fromRGB(240,190,80)) end end
        if S.StopwatchRunning then S.Stopwatch=S.Stopwatch+dt end
        local sec=math.floor((S.TimerLeft>0 and S.TimerLeft or S.Stopwatch)+.5) ClockLabel.Text=string.format("%02d:%02d:%02d",math.floor(sec/3600),math.floor(sec/60)%60,sec%60)
    end)

    -- player monitor
    local PlayerWindow=MakeWindow("V11Players","مراقب اللاعبين",UDim2.new(0,520,0,360))
    local PlayerList=Instance.new("ScrollingFrame") PlayerList.Size=UDim2.new(1,-24,1,-54) PlayerList.Position=UDim2.new(0,12,0,44) PlayerList.BackgroundTransparency=1 PlayerList.BorderSizePixel=0 PlayerList.AutomaticCanvasSize=Enum.AutomaticSize.Y PlayerList.Parent=PlayerWindow
    local pl=Instance.new("UIListLayout") pl.Padding=UDim.new(0,5) pl.Parent=PlayerList
    local function RefreshPlayers()
        for _,c in ipairs(PlayerList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        local _,_,myRoot=DEVIL_EXTRA.GetCharacter()
        for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer then
            local row=Instance.new("Frame") row.Size=UDim2.new(1,-4,0,40) row.BackgroundColor3=Color3.fromRGB(18,26,39) row.BorderSizePixel=0 row.Parent=PlayerList Round(row,8)
            local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid") local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            local hp=hum and math.floor(hum.Health) or 0 local dist=(myRoot and root) and math.floor((myRoot.Position-root.Position).Magnitude) or 0
            Label(row,p.DisplayName.."  ["..p.Name.."]  • HP "..hp.." • "..dist.."m",10,UDim2.new(0,10,0,8)).Size=UDim2.new(1,-190,0,24)
            Button(row,"انتقال",UDim2.new(1,-165,0,5),UDim2.new(0,72,0,30),function() if root and myRoot then myRoot.CFrame=root.CFrame*CFrame.new(0,0,3) NotifyV("تم الانتقال إلى "..p.Name) end end)
            Button(row,"مراقبة",UDim2.new(1,-85,0,5),UDim2.new(0,72,0,30),function() if p.Character then workspace.CurrentCamera.CameraSubject=p.Character:FindFirstChildOfClass("Humanoid") end end)
        end end
    end
    Button(PlayerWindow,"تحديث",UDim2.new(1,-90,0,6),UDim2.new(0,72,0,28),RefreshPlayers)
    Connections.PlayerRefresh=Players.PlayerAdded:Connect(function() if PlayerWindow.Visible then RefreshPlayers() end end)
    Connections.PlayerRefresh2=Players.PlayerRemoving:Connect(function() if PlayerWindow.Visible then RefreshPlayers() end end)

    -- waypoints
    local WaypointWindow=MakeWindow("V11Waypoints","حفظ المواقع",UDim2.new(0,420,0,330))
    local WaypointName=Input(WaypointWindow,"اسم الموقع",UDim2.new(0,12,0,52),UDim2.new(1,-130,0,32))
    Button(WaypointWindow,"حفظ موقعي",UDim2.new(1,-108,0,52),UDim2.new(0,96,0,32),function()
        local _,_,r=DEVIL_EXTRA.GetCharacter() if r and WaypointName.Text~="" then S.Waypoints[WaypointName.Text]=r.CFrame WaypointName.Text="" NotifyV("تم حفظ الموقع") end
    end)
    local WayList=Instance.new("ScrollingFrame") WayList.Size=UDim2.new(1,-24,1,-100) WayList.Position=UDim2.new(0,12,0,94) WayList.BackgroundTransparency=1 WayList.BorderSizePixel=0 WayList.AutomaticCanvasSize=Enum.AutomaticSize.Y WayList.Parent=WaypointWindow
    local wl=Instance.new("UIListLayout") wl.Padding=UDim.new(0,5) wl.Parent=WayList
    local function RefreshWaypoints()
        for _,c in ipairs(WayList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        for n,cf in pairs(S.Waypoints) do local row=Instance.new("Frame") row.Size=UDim2.new(1,-4,0,34) row.BackgroundTransparency=.1 row.BackgroundColor3=Color3.fromRGB(18,26,39) row.Parent=WayList Round(row,7) Label(row,n,11,UDim2.new(0,10,0,5)).Size=UDim2.new(1,-120,0,24) Button(row,"رجوع",UDim2.new(1,-82,0,2),UDim2.new(0,72,0,30),function() local _,_,r=DEVIL_EXTRA.GetCharacter() if r then r.CFrame=cf end end) end
    end

    -- command palette
    local Palette=MakeWindow("V11Palette","Command Palette  •  Ctrl+K",UDim2.new(0,500,0,360)) Palette.Position=UDim2.new(.5,-250,.5,-180)
    local PaletteInput=Input(Palette,"اكتب اسم ميزة ثم Enter...",UDim2.new(0,12,0,52),UDim2.new(1,-24,0,36))
    local Suggest=Instance.new("ScrollingFrame") Suggest.Size=UDim2.new(1,-24,1,-104) Suggest.Position=UDim2.new(0,12,0,96) Suggest.BackgroundTransparency=1 Suggest.BorderSizePixel=0 Suggest.AutomaticCanvasSize=Enum.AutomaticSize.Y Suggest.Parent=Palette
    local sl=Instance.new("UIListLayout") sl.Padding=UDim.new(0,4) sl.Parent=Suggest
    local Commands={}
    local function Command(name, fn) Commands[name]=fn end
    local function RunCommand(query)
        query=(query or ""):lower() for name,fn in pairs(Commands) do if name:lower():find(query,1,true) then safe(fn) NotifyV("تم تشغيل: "..name) return true end end return false
    end
    local function RefreshSuggestions()
        for _,c in ipairs(Suggest:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end local q=PaletteInput.Text:lower()
        for name,fn in pairs(Commands) do if q=="" or name:lower():find(q,1,true) then Button(Suggest,name,nil,UDim2.new(1,-4,0,32),fn) end end
    end
    PaletteInput:GetPropertyChangedSignal("Text"):Connect(RefreshSuggestions)
    PaletteInput.FocusLost:Connect(function(enter) if enter then RunCommand(PaletteInput.Text) PaletteInput.Text="" Palette.Visible=false end end)

    -- header controls
    local EnabledPill=Label(Header,"0 ميزات شغالة",11,UDim2.new(0,470,0,13),CurrentAccent) EnabledPill.Size=UDim2.new(0,110,0,24) EnabledPill.TextXAlignment=Enum.TextXAlignment.Center Round(EnabledPill,12) EnabledPill.BackgroundColor3=Color3.fromRGB(18,28,48) EnabledPill.BackgroundTransparency=.15
    EnabledPill.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then PlayerWindow.Visible=true RefreshPlayers() end end)
    local function CountEnabled()
        local n=0 for _,v in pairs(DEVIL_EXTRA.State or {}) do if type(v)=="boolean" and v then n=n+1 end end EnabledPill.Text=tostring(n).." ميزات شغالة" end
    Connections.Count=RunService.Heartbeat:Connect(CountEnabled)

    -- focus + compact + panic
    local function SetFocus(on)
        S.Focus=on
        Header.Visible=not on Sidebar.Visible=not on
        for _,p in ipairs(Pages) do p.Visible=(not on) and p.Visible or false end
        NotifyV(on and "وضع التركيز: نشط" or "وضع التركيز: متوقف")
    end
    local function SetCompact(on)
        S.Compact=on MainFrame.Size=on and UDim2.new(0,360,0,74) or UDim2.new(0,720,0,560)
        Header.Visible=not on Sidebar.Visible=not on PageContainer.Visible=not on ProfileFrame.Visible=not on
    end
    local function Panic()
        S.Panic=true for k in pairs(Connections) do if k~="Clock" then Disconnect(k) end end
        if DEVIL_EXTRA and DEVIL_EXTRA.Disconnect then for k in pairs(DEVIL_EXTRA.State.Connections or {}) do DEVIL_EXTRA.Disconnect(k) end end
        if DEVIL_EXTRA then DEVIL_EXTRA.State.ESPEnabled=false if DEVIL_EXTRA.ClearESP then DEVIL_EXTRA.ClearESP() end end
        Stack3D.Enabled=false MainFrame.Visible=false ToggleBtn.Visible=true NotifyV("PANIC: تم إيقاف وإخفاء كل الميزات",Color3.fromRGB(240,90,90))
    end
    Command("فتح المنيو",function() S.Panic=false MainFrame.Visible=true ToggleBtn.Visible=false end)
    Command("وضع التركيز",function() SetFocus(not S.Focus) end)
    Command("الوضع المصغر",function() SetCompact(not S.Compact) end)
    Command("المراقب",function() PlayerWindow.Visible=true RefreshPlayers() end)
    Command("المواقع",function() WaypointWindow.Visible=true RefreshWaypoints() end)
    Command("الملاحظات",function() NotesWindow.Visible=true end)
    Command("المؤقت",function() TimerWindow.Visible=true end)
    Command("سجل الأحداث",function() ConsoleWindow.Visible=true RefreshConsole() end)
    Command("Panic",Panic)
    Command("إخفاء المنيو",function() MainFrame.Visible=false ToggleBtn.Visible=true end)
    Connections.Shortcuts=UserInputService.InputBegan:Connect(function(input,processed)
        if processed then return end
        if input.KeyCode==Enum.KeyCode.LeftControl or input.KeyCode==Enum.KeyCode.RightControl then return end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and input.KeyCode==Enum.KeyCode.K then Palette.Visible=not Palette.Visible if Palette.Visible then PaletteInput:CaptureFocus() RefreshSuggestions() end end
        if input.KeyCode==Enum.KeyCode.RightShift then MainFrame.Visible=not MainFrame.Visible ToggleBtn.Visible=not MainFrame.Visible end
        if input.KeyCode==Enum.KeyCode.F8 then Panic() end
    end)

    -- tooltips: attach to every button without replacing existing text
    local Tip=Instance.new("TextLabel") Tip.Name="V11Tooltip" Tip.Size=UDim2.new(0,210,0,30) Tip.BackgroundColor3=Color3.fromRGB(7,12,20) Tip.TextColor3=Color3.fromRGB(240,245,255) Tip.TextSize=10 Tip.Font=Enum.Font.GothamMedium Tip.Visible=false Tip.ZIndex=100 Tip.Parent=ScreenGui Round(Tip,7) Stroke(Tip,CurrentAccent,.25)
    local function AddTip(obj,text) if not obj:IsA("GuiButton") or obj:GetAttribute("V11Tip") then return end obj:SetAttribute("V11Tip",true) obj.MouseEnter:Connect(function() Tip.Text=text or obj.Text Tip.Visible=true Tip.Position=UDim2.fromOffset(UserInputService:GetMouseLocation().X+12,UserInputService:GetMouseLocation().Y+12) end) obj.MouseLeave:Connect(function() Tip.Visible=false end) end
    for _,obj in ipairs(ScreenGui:GetDescendants()) do AddTip(obj,obj:GetAttribute("Tooltip") or obj.Text) end
    Connections.TooltipScan=ScreenGui.DescendantAdded:Connect(function(obj) task.defer(function() AddTip(obj,obj:GetAttribute("Tooltip") or obj.Text) end) end)

    -- glass + particles behind menu
    local blur=Lighting:FindFirstChild("MusaedHubBlur") or Instance.new("BlurEffect") blur.Name="MusaedHubBlur" blur.Size=14 blur.Enabled=true blur.Parent=Lighting
    local ParticleLayer=Instance.new("Frame") ParticleLayer.Name="V11Particles" ParticleLayer.Size=UDim2.fromScale(1,1) ParticleLayer.BackgroundTransparency=1 ParticleLayer.ZIndex=0 ParticleLayer.Parent=ScreenGui
    for i=1,28 do local dot=Instance.new("Frame") dot.Size=UDim2.fromOffset(math.random(1,3),math.random(1,3)) dot.Position=UDim2.fromScale(math.random(),math.random()) dot.BackgroundColor3=CurrentAccent dot.BackgroundTransparency=.35 dot.BorderSizePixel=0 dot.Parent=ParticleLayer Round(dot,4) task.spawn(function() while dot.Parent do local d=math.random(5,12) TweenService:Create(dot,TweenInfo.new(d,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Position=UDim2.fromScale(math.random(),math.random()),BackgroundColor3=CurrentAccent}):Play() task.wait(d) end end) end
    ParticleLayer.ZIndex=0 MainFrame.ZIndex=10 ToggleBtn.ZIndex=20

    -- automatic day/night theme and smart performance
    Connections.Environment=RunService.Heartbeat:Connect(function()
        local h=tonumber(os.date("%H")) or 12
        if S.AutoTheme and (h>=7 and h<19) then Lighting.ClockTime=14 else Lighting.ClockTime=1 end
        if S.SmartPerformance then local fps=0 pcall(function() fps=Stats.Workspace.Heartbeat:GetValue() end) if fps>0 and fps<30 then Stack3D.Enabled=false ParticleLayer.Visible=false blur.Enabled=false elseif not S.Focus then ParticleLayer.Visible=S.ParticleOn blur.Enabled=S.BlurOn end end
    end)

    -- persistent profiles
    local ProfileWindow=MakeWindow("V11Profiles","Profiles",UDim2.new(0,410,0,300))
    local ProfileName=Input(ProfileWindow,"اسم البروفايل مثل: قتال",UDim2.new(0,12,0,52),UDim2.new(1,-130,0,32))
    local function Snapshot() return {r=math.floor(CurrentAccent.R*255),g=math.floor(CurrentAccent.G*255),b=math.floor(CurrentAccent.B*255),bg=SelectedBackground,sound=SoundEnabled,anim=AnimationEnabled,motion=BackgroundMotionEnabled,compact=S.Compact,focus=S.Focus} end
    local function ApplyProfile(d) if d.r then UpdateTheme(Color3.fromRGB(d.r,d.g,d.b)) end if d.bg then ApplySelectedBackground(d.bg) end SoundEnabled=d.sound~=false AnimationEnabled=d.anim~=false BackgroundMotionEnabled=d.motion~=false if d.compact~=nil then SetCompact(d.compact) end if d.focus~=nil then SetFocus(d.focus) end end
    Button(ProfileWindow,"حفظ",UDim2.new(1,-108,0,52),UDim2.new(0,96,0,32),function() if ProfileName.Text~="" then S.Profiles[ProfileName.Text]=Snapshot() S.ActiveProfile=ProfileName.Text NotifyV("تم حفظ البروفايل "..ProfileName.Text) ProfileName.Text="" end end)
    local ProfileList=Instance.new("ScrollingFrame") ProfileList.Size=UDim2.new(1,-24,1,-102) ProfileList.Position=UDim2.new(0,12,0,96) ProfileList.BackgroundTransparency=1 ProfileList.BorderSizePixel=0 ProfileList.AutomaticCanvasSize=Enum.AutomaticSize.Y ProfileList.Parent=ProfileWindow local prl=Instance.new("UIListLayout") prl.Padding=UDim.new(0,5) prl.Parent=ProfileList
    local function RefreshProfiles() for _,c in ipairs(ProfileList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end for n,d in pairs(S.Profiles) do local row=Instance.new("Frame") row.Size=UDim2.new(1,-4,0,34) row.BackgroundColor3=Color3.fromRGB(18,26,39) row.Parent=ProfileList Round(row,7) Label(row,n,11,UDim2.new(0,10,0,5)).Size=UDim2.new(1,-120,0,24) Button(row,"تفعيل",UDim2.new(1,-82,0,2),UDim2.new(0,72,0,30),function() ApplyProfile(d) S.ActiveProfile=n NotifyV("تم تفعيل البروفايل "..n) end) end end
    Command("البروفايلات",function() ProfileWindow.Visible=true RefreshProfiles() end)
    Command("قتال",function() if S.Profiles["قتال"] then ApplyProfile(S.Profiles["قتال"]) end end)
    Command("استكشاف",function() if S.Profiles["استكشاف"] then ApplyProfile(S.Profiles["استكشاف"]) end end)
    Button(MainFrame,"Profiles",UDim2.new(1,-220,0,8),UDim2.new(0,90,0,30),function() ProfileWindow.Visible=true RefreshProfiles() end)
    Button(MainFrame,"Panic",UDim2.new(1,-120,0,8),UDim2.new(0,80,0,30),Panic)

    -- onboarding, first open only
    local Intro=MakeWindow("V11Intro","جولة تعريفية",UDim2.new(0,430,0,250)) Intro.Position=UDim2.new(.5,-215,.5,-125)
    local IntroText=Label(Intro,"مرحباً بك في MUSAED HUB\n\n1) التابات للتنقل بين الأدوات.\n2) Ctrl+K يفتح Command Palette.\n3) عداد الهيدر يعرض الميزات الشغالة.\n4) F8 يوقف كل شيء فوراً.\n5) استخدم Profiles لحفظ إعداداتك.",12,UDim2.new(0,18,0,52)) IntroText.Size=UDim2.new(1,-36,0,140) IntroText.TextWrapped=true
    Button(Intro,"ابدأ",UDim2.new(.5,-55,1,-48),UDim2.new(0,110,0,32),function() Intro.Visible=false if type(writefile)=="function" then pcall(writefile,"MusaedHub_Onboarded.txt","1") end end)
    local onboarded=false if type(isfile)=="function" then pcall(function() onboarded=isfile("MusaedHub_Onboarded.txt") end) end if not onboarded then Intro.Visible=true end

    -- loading screen on first open
    local Load=Instance.new("Frame") Load.Size=UDim2.fromScale(1,1) Load.BackgroundColor3=Color3.fromRGB(7,12,20) Load.BackgroundTransparency=.04 Load.ZIndex=90 Load.Parent=ScreenGui local lt=Label(Load,"جارٍ تجهيز الهب...",15,UDim2.new(0,0,.5,-35),CurrentAccent) lt.TextXAlignment=Enum.TextXAlignment.Center lt.Size=UDim2.new(1,0,0,26) local track=Instance.new("Frame") track.Size=UDim2.new(.65,0,0,7) track.Position=UDim2.new(.175,0,.5,5) track.BackgroundColor3=Color3.fromRGB(25,35,50) track.BorderSizePixel=0 track.Parent=Load Round(track,5) local fill=Instance.new("Frame") fill.Size=UDim2.new(0,0,1,0) fill.BackgroundColor3=CurrentAccent fill.BorderSizePixel=0 fill.Parent=track Round(fill,5) TweenService:Create(fill,TweenInfo.new(.9,Enum.EasingStyle.Quad),{Size=UDim2.fromScale(1,1)}):Play() task.delay(1,function() if Load then Load:Destroy() end end)

    -- save extension state where supported
    local stateFile="MusaedHub_V11.json" local function SaveV11() if type(writefile)~="function" then return end local ok,j=pcall(function() return HttpService:JSONEncode({profiles=S.Profiles,waypoints=S.Waypoints,notes=S.Notes,auto=S.AutoTheme,particles=S.ParticleOn,blur=S.BlurOn}) end) if ok then pcall(writefile,stateFile,j) end end
    if type(isfile)=="function" and type(readfile)=="function" then pcall(function() if isfile(stateFile) then local d=HttpService:JSONDecode(readfile(stateFile)) if type(d)=="table" then for k,v in pairs(d) do if S[k]~=nil then S[k]=v end end end end end) end
    Connections.AutoSave=RunService.Heartbeat:Connect(function() if math.floor(os.clock())%15==0 then SaveV11() end end)
    NotifyV("v11 جاهز: Profiles • Ctrl+K • Focus • Player Monitor • Panic",CurrentAccent)
end,function(err) warn("[MUSAED v11] "..tostring(err)) end)


-- ==========================================================
-- v11.1 finishing touches: resize handle • reconnect alert • theme audio
-- ==========================================================
xpcall(function()
    local HttpService = game:GetService("HttpService")
    local ResizeHandle = Instance.new("TextButton")
    ResizeHandle.Name = "V11ResizeHandle"
    ResizeHandle.Size = UDim2.fromOffset(22,22)
    ResizeHandle.Position = UDim2.new(1,-28,1,-28)
    ResizeHandle.BackgroundColor3 = CurrentAccent
    ResizeHandle.BackgroundTransparency = .18
    ResizeHandle.Text = "↘"
    ResizeHandle.TextColor3 = Color3.fromRGB(7,12,20)
    ResizeHandle.TextSize = 14
    ResizeHandle.Font = Enum.Font.GothamBold
    ResizeHandle.AutoButtonColor = false
    ResizeHandle.ZIndex = 30
    ResizeHandle.Parent = MainFrame
    local rc=Instance.new("UICorner") rc.CornerRadius=UDim.new(1,0) rc.Parent=ResizeHandle
    local rs=Instance.new("UIStroke") rs.Color=CurrentAccent rs.Transparency=.2 rs.Parent=ResizeHandle
    RegisterThemeElement(rs,"Stroked") RegisterThemeElement(ResizeHandle,"BackgroundColored")
    local resizing=false local startMouse local startSize
    ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then resizing=true startMouse=input.Position startSize=MainFrame.AbsoluteSize end
    end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then resizing=false end end)
    UserInputService.InputChanged:Connect(function(input)
        if resizing and input.UserInputType==Enum.UserInputType.MouseMovement then
            local delta=input.Position-startMouse
            local w=math.clamp(startSize.X+delta.X,560,1100) local h=math.clamp(startSize.Y+delta.Y,420,800)
            MainFrame.Size=UDim2.fromOffset(w,h) ResizeHandle.Position=UDim2.new(1,-28,1,-28)
        end
    end)
    Feature.State.AutoReconnect=Feature.State.AutoReconnect or false
    local ReconnectBtn=Button(SettingsPage,"منبه إعادة الاتصال",nil,UDim2.new(1,-6,0,42),function(btn)
        Feature.State.AutoReconnect=not Feature.State.AutoReconnect btn.Text=Feature.State.AutoReconnect and "إيقاف المنبه" or "تفعيل المنبه" NotifyV(Feature.State.AutoReconnect and "منبه إعادة الاتصال نشط" or "تم إيقاف منبه إعادة الاتصال")
    end)
    ReconnectBtn.LayoutOrder=20
    Connections.TeleportFail=TeleportService.TeleportInitFailed:Connect(function(player,result,placeId)
        if player==LocalPlayer then NotifyV("فشل الاتصال: "..tostring(result),Color3.fromRGB(240,100,90)) end
    end)
    Connections.Reconnect=LocalPlayer.OnTeleport:Connect(function(state)
        if state==Enum.TeleportState.Failed and Feature.State.AutoReconnect then
            NotifyV("انقطع الاتصال، محاولة إعادة الدخول...",Color3.fromRGB(240,190,80))
            task.delay(2,function() pcall(function() TeleportService:Teleport(game.PlaceId,LocalPlayer) end) end)
        end
    end)
    -- Each theme gets a gentle click pitch variation without external assets.
    local function UpdateThemeAudio(color)
        local pitch=0.88+color.G*0.28
        for _,sound in ipairs({ClickSound,HoverSound,SuccessSound,ErrorSound}) do if sound then sound.PlaybackSpeed=pitch end end
    end
    Connections.ThemeAudio=RunService.Heartbeat:Connect(function()
        if Feature.State.LastThemeAudio~=CurrentAccent then Feature.State.LastThemeAudio=CurrentAccent UpdateThemeAudio(CurrentAccent) end
    end)
    -- Persist the final window dimensions when the executor supports files.
    Connections.SaveLayout=RunService.Heartbeat:Connect(function()
        if math.floor(os.clock())%20==0 and type(writefile)=="function" then
            pcall(function() writefile("MusaedHub_Layout.json",HttpService:JSONEncode({w=MainFrame.AbsoluteSize.X,h=MainFrame.AbsoluteSize.Y})) end)
        end
    end)
    if type(isfile)=="function" and type(readfile)=="function" then pcall(function()
        if isfile("MusaedHub_Layout.json") then local d=HttpService:JSONDecode(readfile("MusaedHub_Layout.json")) if d.w and d.h then MainFrame.Size=UDim2.fromOffset(math.clamp(d.w,560,1100),math.clamp(d.h,420,800)) end end
    end) end
end,function(err) warn("[MUSAED v11.1] "..tostring(err)) end)


-- ==========================================================
-- UI POLISH
-- ==========================================================
xpcall(function()
    local HttpService = game:GetService("HttpService")

    local function MaskRecent(value)
        value = tostring(value or "")
        if #value <= 3 then
            return value
        end
        return value:sub(1,3) .. string.rep("•", #value - 3)
    end

    -- Recent-key storage. This block is intentionally self-contained so
    -- missing executor file APIs cannot break the main menu.
    local RecentKeys = {}
    local RecentFile = "MusaedHub_RecentKeys.json"

    local function SaveRecentKeys()
        if type(writefile) ~= "function" then
            return
        end
        pcall(function()
            writefile(RecentFile, HttpService:JSONEncode(RecentKeys))
        end)
    end

    local function LoadRecentKeys()
        if type(isfile) ~= "function" or type(readfile) ~= "function" then
            return
        end
        pcall(function()
            if isfile(RecentFile) then
                local data = HttpService:JSONDecode(readfile(RecentFile))
                if type(data) == "table" then
                    RecentKeys = data
                end
            end
        end)
    end

    local function AddRecentKey(key)
        key = tostring(key or ""):upper():gsub("^%s+", ""):gsub("%s+$", "")
        if key == "" then
            return
        end

        for i = #RecentKeys, 1, -1 do
            if tostring(RecentKeys[i]) == key then
                table.remove(RecentKeys, i)
            end
        end

        table.insert(RecentKeys, 1, key)
        while #RecentKeys > 5 do
            table.remove(RecentKeys)
        end
        SaveRecentKeys()
    end

    LoadRecentKeys()

    -- Main menu visual polish: layered top glow and a small live-status marker.
    if MainFrame and MainFrame.Parent and Header and Header.Parent then
        local PolishGlow = Instance.new("Frame")
        PolishGlow.Name = "V11HeaderGlow"
        PolishGlow.Size = UDim2.new(1, -26, 0, 3)
        PolishGlow.Position = UDim2.new(0, 13, 0, 52)
        PolishGlow.BackgroundColor3 = CurrentAccent
        PolishGlow.BackgroundTransparency = 0.12
        PolishGlow.BorderSizePixel = 0
        PolishGlow.ZIndex = 9
        PolishGlow.Parent = MainFrame

        local pg = Instance.new("UIGradient")
        pg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 1)
        })
        pg.Parent = PolishGlow

        RegisterThemeElement(PolishGlow, "BackgroundColored")

        local MenuVersion = Instance.new("TextLabel")
        MenuVersion.Size = UDim2.new(0, 90, 0, 18)
        MenuVersion.Position = UDim2.new(1, -112, 0, 12)
        MenuVersion.BackgroundTransparency = 1
        MenuVersion.Text = "V11 • READY"
        MenuVersion.TextColor3 = CurrentAccent
        MenuVersion.TextSize = 9
        MenuVersion.Font = Enum.Font.GothamBold
        MenuVersion.TextXAlignment = Enum.TextXAlignment.Right
        MenuVersion.Parent = Header
        RegisterThemeElement(MenuVersion, "TextColored")
    end
end, function(err)
    warn("[MUSAED KEY VAULT] " .. tostring(err))
end)

-- ==========================================================
-- MUSAED HUB v12 ULTIMATE CONTROL CENTER
-- Dashboard • Widgets • Profiles Pro • Presets • Backup • Hotkeys
-- Notification Center • Performance Modes • Lock Layout • Focus Pro
-- ==========================================================
xpcall(function()
    local HttpService=game:GetService("HttpService")
    local Stats=game:GetService("Stats")
    local V12=_G.MUSAED_V12 or {}
    _G.MUSAED_V12=V12
    V12.State=V12.State or {Performance="Balanced",Locked=false,KeySaving=true,FocusPro=false,WidgetOn=true,NotifyOn=true,Hotkeys=true}
    local Q=V12.State
    local S=(_G.MUSAED_V11 and _G.MUSAED_V11.State) or {}
    local V12Connections=V12.Connections or {} V12.Connections=V12Connections
    local function Safe(fn,...) return pcall(fn,...) end
    local function Round(o,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r) c.Parent=o return c end
    local function V12Stroke(o,tr) local s=Instance.new("UIStroke") s.Color=CurrentAccent s.Transparency=tr or .35 s.Thickness=1 s.Parent=o return s end
    local function V12Label(p,text,pos,size,color)
        local l=Instance.new("TextLabel") l.BackgroundTransparency=1 l.Text=text l.TextColor3=color or Color3.fromRGB(235,242,250) l.TextSize=size or 11 l.Font=Enum.Font.GothamMedium l.TextXAlignment=Enum.TextXAlignment.Left l.Size=UDim2.new(1,-20,0,24) l.Position=pos or UDim2.new(0,10,0,0) l.Parent=p return l
    end
    local function V12Btn(p,text,pos,size,fn)
        local b=Instance.new("TextButton") b.Text=text b.TextColor3=Color3.fromRGB(235,242,250) b.TextSize=10 b.Font=Enum.Font.GothamBold b.BackgroundColor3=Color3.fromRGB(20,30,45) b.BorderSizePixel=0 b.AutoButtonColor=false b.Size=size or UDim2.new(0,110,0,30) b.Position=pos or UDim2.new() b.Parent=p Round(b,7) V12Stroke(b,.45)
        b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(.12),{BackgroundColor3=Color3.fromRGB(35,52,74)}):Play() end)
        b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(.12),{BackgroundColor3=Color3.fromRGB(20,30,45)}):Play() end)
        b.MouseButton1Click:Connect(function() PlayClick() if fn then Safe(fn,b) end end) return b
    end
    local function Toast(text,color) if Notify then Notify(text,color or CurrentAccent) end if S.Events then table.insert(S.Events,1,os.date("%H:%M:%S").."  "..tostring(text)) end end
    local function MakeV12Window(name,title,w,h)
        local f=ScreenGui:FindFirstChild(name) or Instance.new("Frame") f.Name=name f.Size=UDim2.fromOffset(w,h) f.Position=UDim2.new(.5,-w/2,.5,-h/2) f.BackgroundColor3=Color3.fromRGB(9,15,25) f.BackgroundTransparency=.06 f.BorderSizePixel=0 f.Visible=false f.Active=true f.Draggable=not Q.Locked f.ZIndex=70 f.Parent=ScreenGui Round(f,14) V12Stroke(f,.18)
        if not f:FindFirstChild("V12Title") then local t=V12Label(f,title,UDim2.new(0,14,0,9),14,Color3.fromRGB(255,255,255)) t.Name="V12Title" t.Size=UDim2.new(1,-60,0,24) V12Btn(f,"×",UDim2.new(1,-38,0,6),UDim2.fromOffset(28,28),function() f.Visible=false end) end return f
    end

    -- Dashboard overlay with quick controls and active-feature list.
    local Dash=MakeV12Window("V12Dashboard","CONTROL CENTER  •  لوحة التحكم",560,410)
    local DashStats=V12Label(Dash,"جارٍ تحديث الحالة...",UDim2.new(0,16,0,46),11,CurrentAccent) DashStats.Name="Stats"
    local ActiveList=Instance.new("ScrollingFrame") ActiveList.Size=UDim2.new(1,-32,0,180) ActiveList.Position=UDim2.new(0,16,0,82) ActiveList.BackgroundColor3=Color3.fromRGB(13,22,35) ActiveList.BackgroundTransparency=.2 ActiveList.BorderSizePixel=0 ActiveList.AutomaticCanvasSize=Enum.AutomaticSize.Y ActiveList.Parent=Dash Round(ActiveList,10) local al=Instance.new("UIListLayout") al.Padding=UDim.new(0,3) al.Parent=ActiveList
    local function RefreshActive()
        for _,c in ipairs(ActiveList:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end local n=0
        for name,on in pairs((DEVIL_EXTRA and DEVIL_EXTRA.State) or {}) do if type(on)=="boolean" and on then n=n+1 V12Label(ActiveList,"●  "..tostring(name),10,nil,Color3.fromRGB(105,230,170)).Size=UDim2.new(1,-10,0,21) end end
        DashStats.Text=string.format("%d ميزات نشطة  •  Profile: %s  •  Mode: %s",n,tostring(S.ActiveProfile or "مخصص"),Q.Performance)
        if n==0 then V12Label(ActiveList,"لا توجد ميزات مفعلة حالياً",10,nil,Color3.fromRGB(140,155,175)).Size=UDim2.new(1,-10,0,21) end
    end
    V12Btn(Dash,"تحديث القائمة",UDim2.new(0,16,1,-54),UDim2.fromOffset(112,34),RefreshActive)
    V12Btn(Dash,"Command Palette",UDim2.new(0,138,1,-54),UDim2.fromOffset(125,34),function() local p=ScreenGui:FindFirstChild("V11Palette") if p then p.Visible=true end end)
    V12Btn(Dash,"Panic",UDim2.new(0,275,1,-54),UDim2.fromOffset(90,34),function() if _G.MUSAED_V11 then S.Panic=true end MainFrame.Visible=false ToggleBtn.Visible=true Toast("PANIC: تم إخفاء المنيو",Color3.fromRGB(240,90,90)) end)
    if Header then V12Btn(Header,"Dashboard",UDim2.new(0,584,0,10),UDim2.fromOffset(92,30),function() Dash.Visible=true RefreshActive() end) end

    -- Widget dock: compact, movable, and hidden by one switch.
    local Dock=ScreenGui:FindFirstChild("V12WidgetDock") or Instance.new("Frame") Dock.Name="V12WidgetDock" Dock.Size=UDim2.fromOffset(210,104) Dock.Position=UDim2.new(1,-225,0,90) Dock.BackgroundColor3=Color3.fromRGB(8,14,24) Dock.BackgroundTransparency=.16 Dock.BorderSizePixel=0 Dock.Active=true Dock.Draggable=true Dock.ZIndex=25 Dock.Parent=ScreenGui Round(Dock,10) V12Stroke(Dock,.35)
    local WidgetText=V12Label(Dock,"WIDGETS",UDim2.new(0,10,0,6),9,CurrentAccent) WidgetText.Size=UDim2.new(1,-20,0,18)
    local WidgetInfo=V12Label(Dock,"FPS --  •  PING --\nPlayers --\nProfile --",UDim2.new(0,10,0,28),10,Color3.fromRGB(200,215,235)) WidgetInfo.Size=UDim2.new(1,-20,0,65)
    V12Connections.Widgets=RunService.Heartbeat:Connect(function()
        if not Q.WidgetOn then Dock.Visible=false return end Dock.Visible=true
        local count=0 for _,v in pairs((DEVIL_EXTRA and DEVIL_EXTRA.State) or {}) do if type(v)=="boolean" and v then count=count+1 end end
        local ping=0 pcall(function() ping=math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()+.5) end)
        WidgetInfo.Text=string.format("FPS --  •  PING %dms\nFeatures %d  •  Players %d\nProfile %s",ping,count,#Players:GetPlayers(),tostring(S.ActiveProfile or "مخصص"))
    end)

    -- Performance presets.
    local function SetPerformance(mode)
        Q.Performance=mode
        if mode=="Performance" then Stack3D.Enabled=false if Lighting:FindFirstChild("MusaedHubBlur") then Lighting.MusaedHubBlur.Enabled=false end local p=ScreenGui:FindFirstChild("V11Particles") if p then p.Visible=false end
        elseif mode=="Cinematic" then Stack3D.Enabled=true if Lighting:FindFirstChild("MusaedHubBlur") then Lighting.MusaedHubBlur.Enabled=true end local p=ScreenGui:FindFirstChild("V11Particles") if p then p.Visible=true end
        else Stack3D.Enabled=true if Lighting:FindFirstChild("MusaedHubBlur") then Lighting.MusaedHubBlur.Enabled=true end local p=ScreenGui:FindFirstChild("V11Particles") if p then p.Visible=true end end Toast("وضع الأداء: "..mode,CurrentAccent)
    end
    local PerfPanel=Instance.new("Frame") PerfPanel.Name="V12PerformancePanel" PerfPanel.Size=UDim2.new(1,-6,0,58) PerfPanel.BackgroundColor3=Color3.fromRGB(16,24,37) PerfPanel.BorderSizePixel=0 PerfPanel.LayoutOrder=18 PerfPanel.Parent=SettingsPage Round(PerfPanel,9) V12Label(PerfPanel,"أوضاع الأداء",UDim2.new(0,10,0,5),10,Color3.fromRGB(180,195,215)).Size=UDim2.new(0,110,0,22)
    V12Btn(PerfPanel,"Performance",UDim2.new(0,120,0,14),UDim2.fromOffset(100,30),function() SetPerformance("Performance") end)
    V12Btn(PerfPanel,"Balanced",UDim2.new(0,228,0,14),UDim2.fromOffset(90,30),function() SetPerformance("Balanced") end)
    V12Btn(PerfPanel,"Cinematic",UDim2.new(0,326,0,14),UDim2.fromOffset(90,30),function() SetPerformance("Cinematic") end)

    -- Layout lock and focus pro.
    V12Btn(SettingsPage,"قفل مكان المنيو",nil,UDim2.new(1,-6,0,42),function(btn) Q.Locked=not Q.Locked MainFrame.Draggable=not Q.Locked Dock.Draggable=not Q.Locked btn.Text=Q.Locked and "فتح تحريك المنيو" or "قفل مكان المنيو" Toast(Q.Locked and "تم قفل أماكن النوافذ" or "تم فتح تحريك النوافذ") end).LayoutOrder=19
    V12Btn(SettingsPage,"Focus Pro",nil,UDim2.new(1,-6,0,42),function(btn)
        Q.FocusPro=not Q.FocusPro btn.Text=Q.FocusPro and "إيقاف Focus Pro" or "تشغيل Focus Pro"
        Header.Visible=not Q.FocusPro Sidebar.Visible=not Q.FocusPro Dock.Visible=not Q.FocusPro
        for _,p in ipairs(Pages) do if Q.FocusPro then p.Visible=(p==Pages[1]) end end Toast(Q.FocusPro and "Focus Pro نشط" or "Focus Pro متوقف")
    end).LayoutOrder=20
    V12Btn(SettingsPage,"إظهار/إخفاء Widgets",nil,UDim2.new(1,-6,0,42),function(btn) Q.WidgetOn=not Q.WidgetOn btn.Text=Q.WidgetOn and "إخفاء Widgets" or "إظهار Widgets" Dock.Visible=Q.WidgetOn end).LayoutOrder=21

    -- Notification center.
    local Notif=MakeV12Window("V12Notifications","مركز الإشعارات",460,330)
    local NList=Instance.new("ScrollingFrame") NList.Size=UDim2.new(1,-24,1,-92) NList.Position=UDim2.new(0,12,0,50) NList.BackgroundTransparency=1 NList.BorderSizePixel=0 NList.AutomaticCanvasSize=Enum.AutomaticSize.Y NList.Parent=Notif local nl=Instance.new("UIListLayout") nl.Padding=UDim.new(0,4) nl.Parent=NList
    local function RefreshNotifications() for _,c in ipairs(NList:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end for _,e in ipairs(S.Events or {}) do V12Label(NList,e,10,nil,Color3.fromRGB(190,205,225)).Size=UDim2.new(1,-6,0,20) end end
    V12Btn(Notif,"مسح السجل",UDim2.new(0,12,1,-38),UDim2.fromOffset(100,30),function() if S.Events then table.clear(S.Events) end RefreshNotifications() end)
    if NotificationBell then NotificationBell.MouseButton1Click:Connect(function() Notif.Visible=true RefreshNotifications() end) end

    -- Profile pro tools: export/import, duplicate, and reset.
    local ProfileTools=Instance.new("Frame") ProfileTools.Name="V12ProfileTools" ProfileTools.Size=UDim2.new(1,-6,0,58) ProfileTools.BackgroundColor3=Color3.fromRGB(16,24,37) ProfileTools.BorderSizePixel=0 ProfileTools.LayoutOrder=22 ProfileTools.Parent=SettingsPage Round(ProfileTools,9) V12Label(ProfileTools,"Profiles Pro",UDim2.new(0,10,0,5),10,Color3.fromRGB(180,195,215)).Size=UDim2.new(0,100,0,20)
    V12Btn(ProfileTools,"تصدير",UDim2.new(0,106,0,14),UDim2.fromOffset(72,30),function() if type(setclipboard)=="function" then local ok,j=pcall(function() return HttpService:JSONEncode(S.Profiles or {}) end) if ok then setclipboard(j) Toast("تم نسخ Profiles") end else Toast("النسخ غير متاح",Color3.fromRGB(240,190,80)) end end)
    V12Btn(ProfileTools,"نسخ الحالي",UDim2.new(0,184,0,14),UDim2.fromOffset(92,30),function() if S.Profiles then local base=S.ActiveProfile or "مخصص" S.Profiles[base.." Copy"]={r=math.floor(CurrentAccent.R*255),g=math.floor(CurrentAccent.G*255),b=math.floor(CurrentAccent.B*255),bg=SelectedBackground,sound=SoundEnabled,anim=AnimationEnabled,motion=BackgroundMotionEnabled} Toast("تم نسخ البروفايل الحالي") end end)
    V12Btn(ProfileTools,"Reset UI",UDim2.new(0,282,0,14),UDim2.fromOffset(82,30),function() Q.Performance="Balanced" Q.FocusPro=false Q.WidgetOn=true SetPerformance("Balanced") MainFrame.Visible=true Header.Visible=true Sidebar.Visible=true Dock.Visible=true Toast("تمت إعادة ضبط الواجهة") end)

    -- Key privacy switch and single-key deletion helper.
    local KeyPrivacy=V12Btn(SettingsPage,"حفظ الكيات: تشغيل",nil,UDim2.new(1,-6,0,42),function(btn) Q.KeySaving=not Q.KeySaving btn.Text=Q.KeySaving and "حفظ الكيات: تشغيل" or "حفظ الكيات: إيقاف" Toast(Q.KeySaving and "تم تشغيل حفظ الكيات" or "تم إيقاف حفظ الكيات") end) KeyPrivacy.LayoutOrder=23
    -- Patch the existing vault listener by making the state visible to it on future runs.
    if type(_G.MUSAED_V11)=="table" then _G.MUSAED_V11.KeySaving=Q.KeySaving end

    -- Aliases and configurable quick hotkeys.
    local Palette=ScreenGui:FindFirstChild("V11Palette")
    local function AddCommandAlias(name,fn)
        if Palette then local marker=Palette:FindFirstChild("V12Alias_"..name) if marker then return end end
        if _G.MUSAED_V12.Commands then _G.MUSAED_V12.Commands[name]=fn end
    end
    V12.Commands=V12.Commands or {}
    V12.Commands["dashboard"]=function() Dash.Visible=true RefreshActive() end
    V12.Commands["players"]=function() local p=ScreenGui:FindFirstChild("V11Players") if p then p.Visible=true end end
    V12.Commands["notes"]=function() local p=ScreenGui:FindFirstChild("V11Notes") if p then p.Visible=true end end
    V12.Commands["performance"]=function() SetPerformance("Performance") end
    V12.Commands["balanced"]=function() SetPerformance("Balanced") end
    V12.Commands["cinematic"]=function() SetPerformance("Cinematic") end
    V12.Commands["focus"]=function() Q.FocusPro=not Q.FocusPro end
    V12Connections.Hotkeys=UserInputService.InputBegan:Connect(function(input,processed)
        if processed or not Q.Hotkeys then return end
        if input.KeyCode==Enum.KeyCode.F1 and S.Profiles and S.Profiles["قتال"] then local d=S.Profiles["قتال"] if d.r then UpdateTheme(Color3.fromRGB(d.r,d.g,d.b)) end if d.bg then ApplySelectedBackground(d.bg) end S.ActiveProfile="قتال" Toast("تم تفعيل Profile قتال") end
        if input.KeyCode==Enum.KeyCode.F2 and S.Profiles and S.Profiles["استكشاف"] then local d=S.Profiles["استكشاف"] if d.r then UpdateTheme(Color3.fromRGB(d.r,d.g,d.b)) end if d.bg then ApplySelectedBackground(d.bg) end S.ActiveProfile="استكشاف" Toast("تم تفعيل Profile استكشاف") end
        if input.KeyCode==Enum.KeyCode.F3 then Dash.Visible=not Dash.Visible RefreshActive() end
    end)

    -- Keep dashboard data fresh without rebuilding the whole menu.
    V12Connections.Dashboard=RunService.Heartbeat:Connect(function() if Dash.Visible then RefreshActive() end end)
    Toast("v12 Ultimate جاهز: Dashboard • Widgets • Profiles Pro • Performance",CurrentAccent)
end,function(err) warn("[MUSAED v12 ULTIMATE] "..tostring(err)) end)


-- v12 command bridge: aliases work from the existing Ctrl+K palette.
xpcall(function()
    local V12=_G.MUSAED_V12 or {} local cmds=V12.Commands or {}
    local palette=ScreenGui:FindFirstChild("V11Palette")
    local input=palette and palette:FindFirstChildWhichIsA("TextBox",true)
    local function ExecuteAlias(q)
        q=tostring(q or ""):lower():gsub("^%s+",""):gsub("%s+$","")
        for name,fn in pairs(cmds) do if q==name:lower() or name:lower():find(q,1,true) and #q>2 then pcall(fn) if Notify then Notify("✓ الأمر: "..name,CurrentAccent) end return true end end
        return false
    end
    if input then input.FocusLost:Connect(function(enter) if enter then ExecuteAlias(input.Text) end end) end
end,function(err) warn("[MUSAED COMMAND BRIDGE] "..tostring(err)) end)


-- ==========================================================
-- MUSAED HUB v13 DESIGN SYSTEM
-- Unified sizing • clean icon labels • responsive key menu • spacing polish
-- ==========================================================
xpcall(function()
    local function Round(o,r)
        if not o or not o:IsA("GuiObject") then return end
        if not o:FindFirstChild("V13Corner") then local c=Instance.new("UICorner") c.Name="V13Corner" c.CornerRadius=UDim.new(0,r) c.Parent=o end
    end
    local function AddLine(o,color,tr)
        if not o or not o:IsA("GuiObject") then return end
        local s=o:FindFirstChild("V13Stroke") or Instance.new("UIStroke") s.Name="V13Stroke" s.Color=color or CurrentAccent s.Transparency=tr or .5 s.Thickness=1 s.Parent=o
    end
    local function CleanIcons(text)
        text=tostring(text or "")
        local map={
            ["🔑"]="KEY",["🔔"]="NOTIFY",["🔍"]="SEARCH",["⭐"]="★",["📜"]="SCRIPTS",["🛠️"]="TOOLS",["🛠"]="TOOLS",
            ["🎨"]="THEME",["🖼️"]="BG",["🖼"]="BG",["⚙"]="SET",["⌂"]="HOME",["✦"]="PLUS",["⌁"]="TP",["◉"]="ESP",
            ["🔊"]="SOUND",["🔇"]="MUTE",["✨"]="FX",["↻"]="RESET",["↔"]="SIZE",["✓"]="OK",["✕"]="X",["•"]="·"
        }
        for a,b in pairs(map) do text=text:gsub(a,b) end
        return text
    end
    -- Replace device-dependent emoji across the whole UI with stable labels.
    for _,obj in ipairs(ScreenGui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            if obj.Text and obj.Text~="" then obj.Text=CleanIcons(obj.Text) end
            if obj.PlaceholderText and obj.PlaceholderText~="" then obj.PlaceholderText=CleanIcons(obj.PlaceholderText) end
        end
    end
    -- Main menu canvas: larger on desktop, still responsive through MainScale.
    MainFrame.Size=UDim2.fromOffset(900,590)
    MainFrame.Position=UDim2.new(.5,-450,.5,-295)
    MainFrame.BackgroundTransparency=.10
    MainFrame.ClipsDescendants=true
    Round(MainFrame,16) AddLine(MainFrame,CurrentAccent,.12)
    if Header then Header.Size=UDim2.new(1,0,0,58) end
    if Title then Title.Position=UDim2.new(0,18,0,0) Title.Size=UDim2.fromOffset(210,58) Title.TextSize=15 end
    if StatusPill then StatusPill.Position=UDim2.new(0,238,.5,-12) StatusPill.Size=UDim2.fromOffset(82,24) StatusPill.TextSize=9 end
    if SearchBox then SearchBox.Position=UDim2.new(1,-300,.5,-17) SearchBox.Size=UDim2.fromOffset(220,34) SearchBox.TextSize=11 Round(SearchBox,9) end
    if CloseBtn then CloseBtn.Position=UDim2.new(1,-42,.5,-17) CloseBtn.Size=UDim2.fromOffset(34,34) CloseBtn.Text="—" CloseBtn.TextSize=16 Round(CloseBtn,9) end
    if NotificationBell then NotificationBell.Position=UDim2.new(1,-344,.5,-17) NotificationBell.Size=UDim2.fromOffset(34,34) NotificationBell.Text="NOTIFY" NotificationBell.TextSize=8 Round(NotificationBell,9) end
    if HeaderLine then HeaderLine.Position=UDim2.new(0,14,0,58) HeaderLine.Size=UDim2.new(1,-28,0,1) end
    if PageContainer then PageContainer.Position=UDim2.new(0,16,0,116) PageContainer.Size=UDim2.new(1,-32,1,-188) end
    if ProfileFrame then ProfileFrame.Position=UDim2.new(0,16,1,-72) ProfileFrame.Size=UDim2.fromOffset(225,58) end
    -- Tab sizing and a consistent active state.
    for _,tab in ipairs(Tabs or {}) do
        tab.Size=UDim2.fromOffset(math.clamp(tab.TextBounds.X+34,92,150),38)
        tab.TextSize=11 tab.Font=Enum.Font.GothamBold Round(tab,9) AddLine(tab,CurrentAccent,.72)
    end
    -- Cards: consistent height, padding, and action button dimensions.
    for _,item in ipairs(AllCards or {}) do
        local card=item.Card
        if card and card.Parent then
            card.Size=UDim2.new(1,-10,0,68) card.BackgroundTransparency=.12 Round(card,10) AddLine(card,Color3.fromRGB(55,70,95),.62)
            for _,child in ipairs(card:GetChildren()) do
                if child:IsA("TextButton") then
                    if child.Text=="★" or child.Text=="☆" then child.Size=UDim2.fromOffset(28,28) child.Position=UDim2.new(0,9,.5,-14) else child.Size=UDim2.fromOffset(96,36) child.Position=UDim2.new(1,-108,.5,-18) end
                    child.TextSize=11 Round(child,8)
                elseif child:IsA("TextLabel") then child.TextSize=child.TextSize<=10 and 10 or 12 end
            end
        end
    end
    ScreenGui.DescendantAdded:Connect(function(obj)
        task.defer(function()
            if obj:IsA("TextButton") then obj.Text=CleanIcons(obj.Text) obj.Font=Enum.Font.GothamBold Round(obj,8) end
        end)
    end)
    if Notify then Notify("V13 DESIGN: واجهة موحدة • مقاسات محسنة • رموز ثابتة",CurrentAccent) end
end,function(err) warn("[MUSAED v13 DESIGN] "..tostring(err)) end)

-- ==========================================================
-- MUSAED HUB v14 ICON LAYER
-- Safe standalone icon layer
-- ==========================================================
do
    local ok, err = xpcall(function()
        local Icons = {
            home = "6031225810",
            search = "6031280882",
            settings = "6031289458",
            star = "6031075938",
            key = "6031289458",
            tools = "6031289458",
            image = "6031225810",
            players = "6031075938",
            teleport = "6031225810",
            panic = "6031094678",
            notes = "6031280882",
            timer = "6031075938",
            profile = "6031075938",
            dashboard = "6031225810"
        }

        local function IconFor(value)
            local text = tostring(value or ""):lower()
            if text:find("home", 1, true) or text:find("رئيس", 1, true) then return Icons.home end
            if text:find("search", 1, true) or text:find("بحث", 1, true) then return Icons.search end
            if text:find("set", 1, true) or text:find("إعداد", 1, true) or text:find("gear", 1, true) then return Icons.settings end
            if text:find("theme", 1, true) or text:find("ثيم", 1, true) then return Icons.star end
            if text:find("bg", 1, true) or text:find("خلف", 1, true) then return Icons.image end
            if text:find("script", 1, true) or text:find("سكربت", 1, true) then return Icons.tools end
            if text:find("tool", 1, true) or text:find("devil", 1, true) or text:find("تعد", 1, true) then return Icons.tools end
            if text:find("player", 1, true) or text:find("لاعب", 1, true) or text:find("esp", 1, true) then return Icons.players end
            if text:find("teleport", 1, true) or text:find("انتقال", 1, true) then return Icons.teleport end
            if text:find("profile", 1, true) or text:find("بروف", 1, true) then return Icons.profile end
            if text:find("panic", 1, true) then return Icons.panic end
            if text:find("note", 1, true) or text:find("ملاحظ", 1, true) then return Icons.notes end
            if text:find("timer", 1, true) or text:find("مؤقت", 1, true) then return Icons.timer end
            if text:find("key", 1, true) or text:find("مفتاح", 1, true) or text:find("activate", 1, true) then return Icons.key end
            if text == "★" then return Icons.star end
            return nil
        end

        local function AddImageIcon(button, id)
            if not button or not button:IsA("GuiButton") or not id then return end
            if button:GetAttribute("V14Icon") then return end
            button:SetAttribute("V14Icon", true)

            local icon = Instance.new("ImageLabel")
            icon.Name = "V14Icon"
            icon.Size = UDim2.fromOffset(17, 17)
            icon.Position = UDim2.new(0, 9, 0.5, -8)
            icon.BackgroundTransparency = 1
            icon.Image = "rbxassetid://" .. id
            icon.ImageColor3 = CurrentAccent
            icon.ScaleType = Enum.ScaleType.Fit
            icon.ZIndex = button.ZIndex + 1
            icon.Parent = button

            local pad = button:FindFirstChild("V14IconPadding")
            if not pad then
                pad = Instance.new("UIPadding")
                pad.Name = "V14IconPadding"
                pad.Parent = button
            end
            pad.PaddingLeft = UDim.new(0, 30)
            pad.PaddingRight = UDim.new(0, 8)
            button.TextXAlignment = Enum.TextXAlignment.Left
        end

        local function Iconify(obj)
            if not obj or not obj:IsA("GuiButton") then return end
            local id = IconFor(obj.Text)
            if id then
                AddImageIcon(obj, id)
            end
        end

        if ScreenGui then
            for _, obj in ipairs(ScreenGui:GetDescendants()) do
                Iconify(obj)
            end
            ScreenGui.DescendantAdded:Connect(function(obj)
                task.defer(function()
                    Iconify(obj)
                end)
            end)
        end

        if Title and not Title:FindFirstChild("V14TitleIcon") then
            local titleIcon = Instance.new("ImageLabel")
            titleIcon.Name = "V14TitleIcon"
            titleIcon.Size = UDim2.fromOffset(18, 18)
            titleIcon.Position = UDim2.new(0, 0, 0.5, -9)
            titleIcon.BackgroundTransparency = 1
            titleIcon.Image = "rbxassetid://" .. Icons.dashboard
            titleIcon.ImageColor3 = CurrentAccent
            titleIcon.Parent = Title

            local titlePad = Instance.new("UIPadding")
            titlePad.PaddingLeft = UDim.new(0, 26)
            titlePad.Parent = Title
        end

        local function NormalizeMain()
            if not MainFrame or not MainFrame.Visible then return end
            if MainFrame.Size.X.Offset < 880 or MainFrame.Size.Y.Offset < 570 then
                MainFrame.Size = UDim2.fromOffset(900, 590)
            end
            MainFrame.Position = UDim2.new(0.5, -450, 0.5, -295)
        end

        if ToggleBtn then
            ToggleBtn.MouseButton1Click:Connect(function()
                task.defer(NormalizeMain)
            end)
        end

        if Notify then
            Notify("V14 ICONS: تم تفعيل طبقة الأيقونات", CurrentAccent)
        end
    end, function(message)
        warn("[MUSAED v14 ICONS] " .. tostring(message))
    end)
end
