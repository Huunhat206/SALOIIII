repeat task.wait() until game:IsLoaded()

local env = getgenv and getgenv() or _G
env.SALOI_HUB = env.SALOI_HUB or {}

local Hub = env.SALOI_HUB
Hub.State = Hub.State or {}
Hub.Runtime = Hub.Runtime or {}
Hub.Helpers = Hub.Helpers or {}

local State = Hub.State
State.AutoFarm = State.AutoFarm or false
State.SelectedNPC = State.SelectedNPC or "None"
State.AutoHitClosest = State.AutoHitClosest or false
State.HitDistance = State.HitDistance or 250
State.FarmOffset = State.FarmOffset or 3
State.SelectedIsland = State.SelectedIsland or "Starter Island"

local Runtime = Hub.Runtime
Runtime.Connections = Runtime.Connections or {}
Runtime.Tokens = Runtime.Tokens or {}
Runtime.ModuleStatus = {}
Runtime.Flags = Runtime.Flags or {}

function Hub.Helpers.ReplaceConnection(key, connection)
    local previous = Runtime.Connections[key]
    if previous then pcall(function() previous:Disconnect() end) end
    Runtime.Connections[key] = connection
    return connection
end

function Hub.Helpers.BumpToken(key)
    Runtime.Tokens[key] = (Runtime.Tokens[key] or 0) + 1
    return Runtime.Tokens[key]
end

function Hub.Helpers.IsTokenActive(key, token)
    return Runtime.Tokens[key] == token
end

if Runtime.Library and type(Runtime.Library.Destroy) == "function" then
    pcall(function() Runtime.Library:Destroy() end)
end

local cloneref = cloneref or function(object) return object end

local CoreGui = cloneref(game:GetService("CoreGui"))
local Lighting = cloneref(game:GetService("Lighting"))
local Players = cloneref(game:GetService("Players"))
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local Workspace = cloneref(game:GetService("Workspace"))
local HttpService = cloneref(game:GetService("HttpService"))

local LocalPlayer = Players.LocalPlayer
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled

local function safeGetUI()
    local ok, result = pcall(function() return gethui and gethui() or CoreGui end)
    return (ok and result) and result or CoreGui
end

-- ========================================================================
-- 🎨 PREMIUM THEME - Modern Dark with Orange Accent
-- ========================================================================
local Theme = {
    Background = Color3.fromRGB(12, 13, 18),
    BackgroundAlt = Color3.fromRGB(15, 16, 22),
    Surface = Color3.fromRGB(22, 24, 31),
    SurfaceHover = Color3.fromRGB(28, 30, 38),
    Panel = Color3.fromRGB(18, 20, 26),
    Inline = Color3.fromRGB(32, 35, 44),
    InlineHover = Color3.fromRGB(38, 42, 52),
    Border = Color3.fromRGB(45, 50, 62),
    BorderLight = Color3.fromRGB(58, 64, 78),
    Text = Color3.fromRGB(245, 247, 250),
    TextSecondary = Color3.fromRGB(200, 205, 215),
    Muted = Color3.fromRGB(140, 148, 162),
    MutedDark = Color3.fromRGB(100, 108, 122),
    Accent = Color3.fromRGB(255, 138, 76),
    AccentSoft = Color3.fromRGB(255, 186, 140),
    AccentDark = Color3.fromRGB(220, 100, 45),
    AccentGlow = Color3.fromRGB(255, 160, 100),
    Success = Color3.fromRGB(86, 211, 140),
    SuccessDark = Color3.fromRGB(50, 170, 100),
    Error = Color3.fromRGB(255, 95, 105),
    ErrorDark = Color3.fromRGB(210, 60, 70),
    Warning = Color3.fromRGB(255, 193, 87),
    Info = Color3.fromRGB(88, 170, 255),
    Shadow = Color3.fromRGB(0, 0, 0),
    Glass = Color3.fromRGB(25, 27, 35),
}

local Fonts = {
    Display = Enum.Font.GothamBold,
    Title = Enum.Font.GothamBold,
    Header = Enum.Font.GothamSemibold,
    Body = Enum.Font.Gotham,
    Caption = Enum.Font.Gotham,
    Mono = Enum.Font.Code,
    Icon = Enum.Font.Code, -- Sửa: Dùng Font.Code để icon không bị vỡ (hình vuông)
}

local Tweens = {
    Instant = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Normal = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Smooth = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Bounce = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    Elastic = TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
    Spring = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0),
}

-- Sửa: Thay thế Emoji bằng Unicode an toàn để tránh lỗi hình vuông
local Icons = {
    Home = "⌂",
    Dashboard = "◈",
    Settings = "⚙",
    Gear = "⚙",
    Play = "▶",
    Pause = "⏸",
    Stop = "⏹",
    Refresh = "↻",
    Close = "✕",
    Minimize = "─",
    Maximize = "□",
    Check = "✓",
    Cross = "✕",
    Plus = "＋",
    Arrow = "›",
    ArrowDown = "▾",
    ArrowUp = "▴",
    ArrowRight = "→",
    Target = "◎",
    Zap = "⚡",
    Fire = "!", -- Emoji 🔥 không hỗ trợ tốt trên PC, thay bằng ký tự an toàn hoặc giữ nguyên nếu mobile
    Star = "★",
    Heart = "♥",
    Shield = "⛨",
    Crown = "♛",
    Diamond = "◆",
    Sparkle = "✦",
    Online = "●",
    Offline = "○",
    Loading = "◐",
    Warning = "⚠",
    Info = "ⓘ",
    Success = "✓",
    Error = "✕",
    Search = "⌕",
    Filter = "☰",
    Menu = "☰",
    More = "⋯",
    Eye = "👁",
    Lock = "🔒",
    Farm = "≡", -- Thay 🌾
    Event = "★", -- Thay 🎉
    Teleport = "»", -- Thay ⚡ (duplicate nhưng dùng mũi tên)
    Player = "●", -- Thay 👤
    World = "◐", -- Thay 🌍
    Combat = "×", -- Thay ⚔
}

-- ========================================================================
-- 🛠️ HELPER FUNCTIONS
-- ========================================================================
local function create(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties or {}) do
        instance[property] = value
    end
    return instance
end

local function tween(instance, goal, info)
    local tweenInfo = info or Tweens.Normal
    local ok, animation = pcall(function() return TweenService:Create(instance, tweenInfo, goal) end)
    if ok and animation then
        animation:Play()
        return animation
    end
    return nil
end

local function addCorner(parent, radius)
    return create("UICorner", { Parent = parent, CornerRadius = UDim.new(0, radius or 10) })
end

local function addStroke(parent, color, thickness, transparency)
    return create("UIStroke", {
        Parent = parent, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = color or Theme.Border, Thickness = thickness or 1, Transparency = transparency or 0,
    })
end

local function addPadding(parent, left, right, top, bottom)
    return create("UIPadding", {
        Parent = parent, 
        PaddingLeft = UDim.new(0, left or 0), 
        PaddingRight = UDim.new(0, right or left or 0),
        PaddingTop = UDim.new(0, top or 0), 
        PaddingBottom = UDim.new(0, bottom or top or 0),
    })
end

local function addList(parent, padding, horizontalAlignment)
    return create("UIListLayout", {
        Parent = parent, Padding = UDim.new(0, padding or 0),
        SortOrder = Enum.SortOrder.LayoutOrder, 
        HorizontalAlignment = horizontalAlignment or Enum.HorizontalAlignment.Left,
    })
end

local function addGradient(parent, colorSequence, rotation, transparency)
    return create("UIGradient", {
        Parent = parent,
        Color = colorSequence or ColorSequence.new(Theme.Accent, Theme.AccentSoft),
        Rotation = rotation or 90,
        Transparency = transparency or NumberSequence.new(0),
    })
end

local function addShadow(parent, opacity, size, offset)
    local shadow = create("ImageLabel", {
        Parent = parent, Name = "Shadow", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, offset and offset.X or 0, 0.5, offset and offset.Y or 4),
        Size = UDim2.new(1, size or 30, 1, size or 30), BackgroundTransparency = 1,
        Image = "rbxassetid://6015897843", ImageColor3 = Theme.Shadow,
        ImageTransparency = opacity or 0.5, ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450), ZIndex = (parent.ZIndex or 1) - 1,
    })
    return shadow
end

local function addGlow(parent, color, opacity, size)
    local glow = create("ImageLabel", {
        Parent = parent, Name = "Glow", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, size or 20, 1, size or 20),
        BackgroundTransparency = 1, Image = "rbxassetid://5028857084",
        ImageColor3 = color or Theme.Accent, ImageTransparency = opacity or 0.6,
        ZIndex = (parent.ZIndex or 1) - 1,
    })
    return glow
end

local function createRipple(parent, x, y, color)
    local ripple = create("Frame", {
        Parent = parent, Name = "Ripple",
        Position = UDim2.new(0, x - parent.AbsolutePosition.X, 0, y - parent.AbsolutePosition.Y),
        Size = UDim2.fromOffset(0, 0), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = color or Theme.AccentSoft, BackgroundTransparency = 0.5,
        BorderSizePixel = 0, ZIndex = (parent.ZIndex or 1) + 2,
    })
    addCorner(ripple, 999)
    local maxSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.5
    tween(ripple, { Size = UDim2.fromOffset(maxSize, maxSize), BackgroundTransparency = 1 }, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out))
    task.delay(0.6, function() pcall(function() ripple:Destroy() end) end)
end

local function createParticle(parent)
    local particle = create("Frame", {
        Parent = parent, Size = UDim2.fromOffset(math.random(2, 4), math.random(2, 4)),
        Position = UDim2.new(math.random(), 0, math.random(), 0), BackgroundColor3 = Theme.AccentSoft,
        BackgroundTransparency = math.random(30, 70) / 100, BorderSizePixel = 0, ZIndex = 2,
    })
    addCorner(particle, 999)
    local targetPos = UDim2.new(particle.Position.X.Scale + (math.random(-20, 20) / 100), 0, particle.Position.Y.Scale - 0.3, 0)
    tween(particle, { Position = targetPos, BackgroundTransparency = 1 }, TweenInfo.new(math.random(2, 4), Enum.EasingStyle.Sine, Enum.EasingDirection.Out))
    task.delay(4, function() pcall(function() particle:Destroy() end) end)
    return particle
end

local function setCanvasToLayout(scrollingFrame, layout, extraPadding)
    scrollingFrame.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + (extraPadding or 0))
end

local function copyArray(list) local result = {}; for index, value in ipairs(list or {}) do result[index] = value end; return result end
local function formatNumber(value)
    if math.abs(value - math.floor(value)) < 0.001 then return tostring(math.floor(value)) end
    local text = string.format("%.2f", value); text = string.gsub(text, "0+$", ""); text = string.gsub(text, "%.$", ""); return text
end
local function roundToIncrement(value, minimum, increment)
    if not increment or increment <= 0 then return value end; local relative = (value - minimum) / increment; return minimum + math.floor(relative + 0.5) * increment
end
local function getDropdownValue(option) return type(option) == "table" and option[1] or option end
local function contains(list, target) for _, value in ipairs(list) do if value == target then return true end end; return false end

local function makeDraggable(handle, target, library)
    local dragging, dragInput, dragStart, startPosition = false, nil, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true; dragStart = input.Position; startPosition = target.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end)
    handle.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
    local connectionHost = library or { Connect = function(_, signal, callback) return signal:Connect(callback) end }
    connectionHost:Connect(UserInputService.InputChanged, function(input)
        if not dragging or input ~= dragInput then return end
        local delta = input.Position - dragStart
        target.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end)
end

-- 🎨 Premium panel builder (ĐÃ SỬA LỖI CORNERRADIUS)
local function makePanel(parent, properties)
    local props = {}
    for k, v in pairs(properties or {}) do props[k] = v end
    props.Parent = parent 
    
    -- FIX: Lấy CornerRadius ra và xóa khỏi props để không gán vào Frame
    local radius = props.CornerRadius
    props.CornerRadius = nil
    
    local panel = create("Frame", props)
    addCorner(panel, radius or 14)
    addStroke(panel, Theme.Border, 1, 0.3)
    return panel
end

-- ========================================================================
-- 📚 LIBRARY CORE
-- ========================================================================
local Library = {
    Theme = Theme, Fonts = Fonts, Flags = Runtime.Flags, Connections = {},
    RootGui = nil, NotificationGui = nil, Blur = nil, Window = nil,
}
Runtime.Library = Library

function Library:Connect(signal, callback) local connection = signal:Connect(callback); table.insert(self.Connections, connection); return connection end
function Library:Destroy()
    for _, connection in ipairs(self.Connections) do pcall(function() connection:Disconnect() end) end
    self.Connections = {}
    if self.Blur then tween(self.Blur, { Size = 0 }, Tweens.Smooth); task.delay(0.4, function() pcall(function() self.Blur:Destroy() end) end); self.Blur = nil end
    if self.NotificationGui then pcall(function() self.NotificationGui:Destroy() end); self.NotificationGui = nil end
    if self.RootGui then pcall(function() self.RootGui:Destroy() end); self.RootGui = nil end
    self.Window = nil; Runtime.Library = nil
end

function Library:EnsureNotifications()
    if self.NotificationGui and self.NotificationGui.Parent then return end
    local notificationGui = create("ScreenGui", { Parent = safeGetUI(), Name = "SaloiHubNotifications", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999, IgnoreGuiInset = true })
    local holder = create("Frame", { Parent = notificationGui, Name = "Holder", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 20), Size = UDim2.fromOffset(340, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0 })
    addList(holder, 12, Enum.HorizontalAlignment.Right)
    self.NotificationGui = notificationGui; self.NotificationHolder = holder
end

function Library:Notify(data)
    self:EnsureNotifications()
    local title = data.Title or "Saloi Hub"
    local content = data.Content or data.Description or ""
    local duration = data.Duration or 4
    local notifType = data.Type or "info"
    local typeConfig = {
        success = { color = Theme.Success, icon = Icons.Check },
        error = { color = Theme.Error, icon = Icons.Cross },
        warning = { color = Theme.Warning, icon = Icons.Warning },
        info = { color = Theme.Accent, icon = Icons.Info },
    }
    local config = typeConfig[notifType] or typeConfig.info
    local accent = data.Color or config.color

    local notification = create("Frame", { Parent = self.NotificationHolder, Name = "Notification", Size = UDim2.fromOffset(340, 0), Position = UDim2.new(1, 60, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Surface, BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true })
    addCorner(notification, 14)
    local stroke = addStroke(notification, Theme.BorderLight, 1.5, 1)
    addShadow(notification, 0.7, 30, Vector2.new(0, 6))
    addPadding(notification, 16, 16, 14, 14)
    
    local contentHolder = create("Frame", { Parent = notification, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
    addList(contentHolder, 8)
    local accentBar = create("Frame", { Parent = notification, Size = UDim2.new(0, 3, 1, -4), Position = UDim2.new(0, 0, 0, 2), BackgroundColor3 = accent, BorderSizePixel = 0 })
    addCorner(accentBar, 99)
    addGradient(accentBar, ColorSequence.new({ ColorSequenceKeypoint.new(0, accent), ColorSequenceKeypoint.new(1, Theme.AccentSoft) }), 90)

    local headerRow = create("Frame", { Parent = contentHolder, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 })
    local iconCircle = create("Frame", { Parent = headerRow, Size = UDim2.fromOffset(22, 22), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = accent, BackgroundTransparency = 0.85, BorderSizePixel = 0 })
    addCorner(iconCircle, 999); addStroke(iconCircle, accent, 1, 0.5)
    create("TextLabel", { Parent = iconCircle, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = config.icon, TextColor3 = accent, TextSize = 13, Font = Fonts.Icon, TextXAlignment = Enum.TextXAlignment.Center })

    local titleLabel = create("TextLabel", { Parent = headerRow, BackgroundTransparency = 1, Position = UDim2.new(0, 30, 0, 0), Size = UDim2.new(1, -30, 1, 0), Text = title, TextColor3 = Theme.Text, TextTransparency = 1, TextSize = 14, Font = Fonts.Title, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center })
    local contentLabel = create("TextLabel", { Parent = contentHolder, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = content, TextColor3 = Theme.TextSecondary, TextTransparency = 1, TextWrapped = true, TextSize = 12, Font = Fonts.Body, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top })

    local durationTrack = create("Frame", { Parent = contentHolder, Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = Theme.Inline, BackgroundTransparency = 0.3, BorderSizePixel = 0 })
    addCorner(durationTrack, 99)
    local fill = create("Frame", { Parent = durationTrack, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = accent, BorderSizePixel = 0 })
    addCorner(fill, 99); addGradient(fill, ColorSequence.new(accent, Theme.AccentSoft), 90)

    notification.Position = UDim2.new(1, 60, 0, 0)
    tween(notification, { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0.05 }, Tweens.Bounce)
    tween(stroke, { Transparency = 0.3 }, Tweens.Smooth)
    task.wait(0.05); tween(titleLabel, { TextTransparency = 0 }, Tweens.Smooth)
    task.wait(0.05); tween(contentLabel, { TextTransparency = 0 }, Tweens.Smooth)
    tween(fill, { Size = UDim2.new(0, 0, 1, 0) }, TweenInfo.new(duration, Enum.EasingStyle.Linear))

    task.delay(duration, function()
        tween(notification, { Position = UDim2.new(1, 60, 0, 0), BackgroundTransparency = 1 }, Tweens.Smooth)
        tween(stroke, { Transparency = 1 }, Tweens.Normal)
        tween(titleLabel, { TextTransparency = 1 }, Tweens.Normal)
        tween(contentLabel, { TextTransparency = 1 }, Tweens.Normal)
        task.wait(0.4); pcall(function() notification:Destroy() end)
    end)
end

-- ========================================================================
-- 🖼️ WINDOW & TAB CLASSES
-- ========================================================================
local WindowClass, TabClass = {}, {}
WindowClass.__index = WindowClass; TabClass.__index = TabClass

local function createCard(parent, fixedHeight)
    local card = create("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, fixedHeight or 0), AutomaticSize = fixedHeight and Enum.AutomaticSize.None or Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, ClipsDescendants = true })
    addCorner(card, 12); addStroke(card, Theme.Border, 1, 0.35)
    return card
end

function Library:CreateWindow(options)
    self:EnsureNotifications()
    local finalWindowSize = IsMobile and UDim2.fromOffset(680, 400) or UDim2.fromOffset(820, 470)
    local startWindowSize = UDim2.fromOffset(100, 100)

    local rootGui = create("ScreenGui", { Parent = safeGetUI(), Name = "SaloiHub", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9998 })
    self.RootGui = rootGui

    local blur = create("BlurEffect", { Parent = Lighting, Name = "SaloiHubBlur", Size = 0 })
    self.Blur = blur

    local overlay = create("Frame", { Parent = rootGui, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1 })
    local root = makePanel(rootGui, { Name = "Root", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = startWindowSize, BackgroundColor3 = Theme.Background, BackgroundTransparency = 0.02, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 10, CornerRadius = 16 })
    addShadow(root, 0.4, 60, Vector2.new(0, 12))
    addGradient(root, ColorSequence.new({ ColorSequenceKeypoint.new(0, Theme.Background), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(14, 15, 20)), ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 17, 22)) }), 135)

    local particleContainer = create("Frame", { Parent = root, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 10, ClipsDescendants = true })
    task.spawn(function() while particleContainer.Parent do if root.Visible then createParticle(particleContainer) end; task.wait(0.8) end end)

    local sidebar = create("Frame", { Parent = root, Name = "Sidebar", Size = UDim2.new(0, 210, 1, 0), BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 11 })
    addGradient(sidebar, ColorSequence.new({ ColorSequenceKeypoint.new(0, Theme.Panel), ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 18, 24)) }), 180)

    local divider = create("Frame", { Parent = root, Name = "Divider", Position = UDim2.new(0, 210, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = Theme.BorderLight, BorderSizePixel = 0, BackgroundTransparency = 0.3, ZIndex = 11 })
    addGradient(divider, ColorSequence.new({ ColorSequenceKeypoint.new(0, Theme.Border), ColorSequenceKeypoint.new(0.5, Theme.Accent), ColorSequenceKeypoint.new(1, Theme.Border) }), 90, NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 0.9) }))

    local brandHolder = create("Frame", { Parent = sidebar, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 90), ZIndex = 12 })
    addPadding(brandHolder, 18, 18, 18, 15)

    local logoCircle = create("Frame", { Parent = brandHolder, Size = UDim2.fromOffset(36, 36), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 13 })
    addCorner(logoCircle, 12); addGradient(logoCircle, ColorSequence.new(Theme.Accent, Theme.AccentDark), 135); addGlow(logoCircle, Theme.Accent, 0.5, 15)
    create("TextLabel", { Parent = logoCircle, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "S", TextColor3 = Theme.Background, TextSize = 20, Font = Fonts.Display, ZIndex = 14 })

    local brandTitle = create("TextLabel", { Parent = brandHolder, BackgroundTransparency = 1, Position = UDim2.new(0, 46, 0, 2), Size = UDim2.new(1, -46, 0, 22), Text = options.Name or "Saloi Hub", TextColor3 = Theme.Text, TextSize = 18, Font = Fonts.Display, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12 })
    local brandSubtitle = create("TextLabel", { Parent = brandHolder, BackgroundTransparency = 1, Position = UDim2.new(0, 46, 0, 22), Size = UDim2.new(1, -46, 0, 16), Text = "Premium Edition", TextColor3 = Theme.AccentSoft, TextSize = 11, Font = Fonts.Header, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12 })
    
    local brandSeparator = create("Frame", { Parent = brandHolder, Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, BackgroundTransparency = 0.5, ZIndex = 12 })
    addGradient(brandSeparator, ColorSequence.new({ ColorSequenceKeypoint.new(0, Theme.Accent), ColorSequenceKeypoint.new(1, Theme.Border) }), 0, NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) }))

    local tabScroller = create("ScrollingFrame", { Parent = sidebar, Name = "TabScroller", Position = UDim2.new(0, 0, 0, 90), Size = UDim2.new(1, 0, 1, -130), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent, ScrollBarImageTransparency = 0.3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.None, ZIndex = 12 })
    addPadding(tabScroller, 12, 12, 8, 8)
    local tabLayout = addList(tabScroller, 6)
    self:Connect(tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function() setCanvasToLayout(tabScroller, tabLayout, 15) end)

    local userFooter = create("Frame", { Parent = sidebar, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Theme.Surface, BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 12 })
    addPadding(userFooter, 15, 15, 10, 10)
    local userSeparator = create("Frame", { Parent = userFooter, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, BackgroundTransparency = 0.5, ZIndex = 12 })
    
    local userAvatar = create("Frame", { Parent = userFooter, Size = UDim2.fromOffset(30, 30), Position = UDim2.new(0, 0, 0.5, -15), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 13 })
    addCorner(userAvatar, 999); addGradient(userAvatar, ColorSequence.new(Theme.Accent, Theme.AccentDark), 135)
    
    task.spawn(function()
        pcall(function()
            local userId = LocalPlayer and LocalPlayer.UserId or 0
            local thumb = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
            local img = create("ImageLabel", { Parent = userAvatar, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = thumb, ZIndex = 14 })
            addCorner(img, 999)
        end)
    end)
    
    local onlineDot = create("Frame", { Parent = userAvatar, Size = UDim2.fromOffset(9, 9), Position = UDim2.new(1, -8, 1, -8), BackgroundColor3 = Theme.Success, BorderSizePixel = 0, ZIndex = 15 })
    addCorner(onlineDot, 999); addStroke(onlineDot, Theme.Panel, 2, 0)
    
    create("TextLabel", { Parent = userFooter, BackgroundTransparency = 1, Position = UDim2.new(0, 40, 0, 4), Size = UDim2.new(1, -40, 0, 14), Text = LocalPlayer and LocalPlayer.DisplayName or "Unknown", TextColor3 = Theme.Text, TextSize = 12, Font = Fonts.Header, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 13 })
    create("TextLabel", { Parent = userFooter, BackgroundTransparency = 1, Position = UDim2.new(0, 40, 0, 19), Size = UDim2.new(1, -40, 0, 12), Text = "@" .. (LocalPlayer and LocalPlayer.Name or "player"), TextColor3 = Theme.Muted, TextSize = 10, Font = Fonts.Body, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 13 })

    local contentHolder = create("Frame", { Parent = root, Name = "ContentHolder", Position = UDim2.new(0, 211, 0, 0), Size = UDim2.new(1, -211, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 11 })
    local topBar = create("Frame", { Parent = contentHolder, Name = "TopBar", Size = UDim2.new(1, 0, 0, 65), BackgroundColor3 = Theme.Surface, BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 12 })
    addPadding(topBar, 22, 22, 16, 0)
    
    local topBarBorder = create("Frame", { Parent = topBar, Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, BackgroundTransparency = 0.5, ZIndex = 12 })
    local breadcrumbIcon = create("TextLabel", { Parent = topBar, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 3), Size = UDim2.fromOffset(22, 22), Text = Icons.Diamond, TextColor3 = Theme.Accent, TextSize = 16, Font = Fonts.Icon, ZIndex = 13 })
    local headerTitle = create("TextLabel", { Parent = topBar, BackgroundTransparency = 1, Position = UDim2.new(0, 28, 0, 0), Size = UDim2.new(1, -130, 0, 26), Text = options.Name or "Saloi Hub", TextColor3 = Theme.Text, TextSize = 20, Font = Fonts.Display, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 13 })
    local headerSubtitle = create("TextLabel", { Parent = topBar, BackgroundTransparency = 1, Position = UDim2.new(0, 28, 0, 28), Size = UDim2.new(1, -130, 0, 16), Text = options.Subtitle or "Premium UI", TextColor3 = Theme.Muted, TextSize = 12, Font = Fonts.Body, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12 })

    local function createControlButton(parentTopBar, icon, position, hoverColor)
        local btn = create("TextButton", { Parent = parentTopBar, AnchorPoint = Vector2.new(1, 0), Position = position, Size = UDim2.fromOffset(32, 32), BackgroundColor3 = Theme.Inline, BackgroundTransparency = 0.3, BorderSizePixel = 0, AutoButtonColor = false, Text = icon, TextColor3 = Theme.TextSecondary, TextSize = 14, Font = Fonts.Icon, ZIndex = 14 })
        addCorner(btn, 8); addStroke(btn, Theme.Border, 1, 0.4)
        btn.MouseEnter:Connect(function() tween(btn, { BackgroundColor3 = hoverColor or Theme.InlineHover, BackgroundTransparency = 0, TextColor3 = Theme.Text, Size = UDim2.fromOffset(34, 34) }, Tweens.Fast) end)
        btn.MouseLeave:Connect(function() tween(btn, { BackgroundColor3 = Theme.Inline, BackgroundTransparency = 0.3, TextColor3 = Theme.TextSecondary, Size = UDim2.fromOffset(32, 32) }, Tweens.Fast) end)
        return btn
    end

    local minimizeButton = createControlButton(topBar, Icons.Minimize, UDim2.new(1, -45, 0, 3), Theme.Warning)
    local closeButton = createControlButton(topBar, Icons.Close, UDim2.new(1, 0, 0, 3), Theme.Error)

    local pagesHolder = create("Frame", { Parent = contentHolder, Name = "PagesHolder", Position = UDim2.new(0, 0, 0, 65), Size = UDim2.new(1, 0, 1, -65), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 12 })
    addPadding(pagesHolder, 8, 8, 0, 0)

    local window = setmetatable({
        Library = self, Root = root, Sidebar = sidebar, TabScroller = tabScroller, TabLayout = tabLayout,
        PagesHolder = pagesHolder, HeaderTitle = headerTitle, HeaderSubtitle = headerSubtitle, 
        BreadcrumbIcon = breadcrumbIcon, Tabs = {}, ActiveTab = nil,
        WindowName = options.Name or "Saloi Hub", WindowSubtitle = options.Subtitle or "Premium UI",
    }, WindowClass)

    self.Window = window

    -- 🎯 FLOATING LOGO BUTTON
    local openButton = create("TextButton", { Parent = rootGui, Name = "OpenLogoButton", Size = UDim2.fromOffset(55, 55), Position = UDim2.new(0, 25, 0, 25), BackgroundColor3 = Theme.Surface, AutoButtonColor = false, Visible = false, Text = "", ZIndex = 9999 })
    addCorner(openButton, 16); addStroke(openButton, Theme.Accent, 2, 0); addShadow(openButton, 0.5, 40, Vector2.new(0, 8))
    addGradient(openButton, ColorSequence.new({ ColorSequenceKeypoint.new(0, Theme.Surface), ColorSequenceKeypoint.new(1, Theme.Panel) }), 135)
    
    local logoGlow = addGlow(openButton, Theme.Accent, 0.6, 25)
    local logoImage = create("ImageLabel", { Parent = openButton, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = "", ZIndex = 10000 })
    addCorner(logoImage, 16)
    
    local fallbackLogo = create("TextLabel", { Parent = openButton, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "S", TextColor3 = Theme.Accent, TextSize = 26, Font = Fonts.Display, ZIndex = 10000 })
    
    task.spawn(function()
        pcall(function()
            local rawUrl = "https://raw.githubusercontent.com/Huunhat206/SALOIIII/main/Saloi.png"
            local fileName = "SaloiLogo_Fix.png"
            if not isfile(fileName) then writefile(fileName, game:HttpGet(rawUrl)) end
            local asset = getcustomasset(fileName)
            if asset and asset ~= "" then logoImage.Image = asset; fallbackLogo.Visible = false end
        end)
    end)
    
    makeDraggable(openButton, openButton, self)
    
    openButton.MouseEnter:Connect(function() tween(openButton, { Size = UDim2.fromOffset(62, 62) }, Tweens.Bounce); tween(logoGlow, { ImageTransparency = 0.2, Size = UDim2.new(1, 40, 1, 40) }, Tweens.Smooth) end)
    openButton.MouseLeave:Connect(function() tween(openButton, { Size = UDim2.fromOffset(55, 55) }, Tweens.Bounce); tween(logoGlow, { ImageTransparency = 0.6, Size = UDim2.new(1, 25, 1, 25) }, Tweens.Smooth) end)
    
    task.spawn(function()
        while openButton.Parent do
            if openButton.Visible then
                tween(logoGlow, { ImageTransparency = 0.4 }, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
                task.wait(1.2)
                tween(logoGlow, { ImageTransparency = 0.8 }, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
                task.wait(1.2)
            else task.wait(0.5) end
        end
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        createRipple(closeButton, UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y, Theme.Error)
        tween(blur, { Size = 0 }, Tweens.Smooth)
        tween(overlay, { BackgroundTransparency = 1 }, Tweens.Smooth)
        tween(root, { Size = UDim2.fromOffset(50, 50), Position = UDim2.new(0, 50, 0, 50) }, Tweens.Smooth)
        task.wait(0.35)
        root.Visible = false; root.Position = UDim2.fromScale(0.5, 0.5)
        openButton.Visible = true; openButton.Size = UDim2.fromOffset(0, 0)
        tween(openButton, { Size = UDim2.fromOffset(55, 55) }, Tweens.Bounce)
    end)

    local isMinimized = false
    minimizeButton.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            tween(root, { Size = UDim2.fromOffset(finalWindowSize.X.Offset, 65) }, Tweens.Smooth)
            minimizeButton.Text = Icons.Plus
        else
            tween(root, { Size = finalWindowSize }, Tweens.Smooth)
            minimizeButton.Text = Icons.Minimize
        end
    end)

    openButton.MouseButton1Click:Connect(function()
        tween(openButton, { Size = UDim2.fromOffset(0, 0) }, Tweens.Fast)
        task.wait(0.15)
        openButton.Visible = false; openButton.Size = UDim2.fromOffset(55, 55)
        root.Visible = true; root.Size = UDim2.fromOffset(100, 100)
        tween(blur, { Size = 18 }, Tweens.Smooth)
        tween(overlay, { BackgroundTransparency = 0.5 }, Tweens.Smooth)
        tween(root, { Size = finalWindowSize }, Tweens.Bounce)
    end)

    tween(blur, { Size = 18 }, Tweens.Smooth)
    tween(overlay, { BackgroundTransparency = 0.5 }, Tweens.Smooth)
    tween(root, { Size = finalWindowSize }, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out))

    makeDraggable(topBar, root, self)
    return window
end

function WindowClass:SelectTab(targetTab)
    for _, tab in ipairs(self.Tabs) do
        local isActive = tab == targetTab
        if isActive then
            tab.Page.Visible = true
            tab.Page.Position = UDim2.new(0.03, 0, 0, 0)
            for _, child in ipairs(tab.Page:GetChildren()) do if child:IsA("Frame") or child:IsA("TextLabel") then child.Position = child.Position + UDim2.new(0.01, 0, 0, 0) end end
            tween(tab.Page, { Position = UDim2.new(0, 0, 0, 0) }, Tweens.Smooth)
        else task.delay(0.15, function() if self.ActiveTab ~= tab then tab.Page.Visible = false end end) end
        tween(tab.Button, { BackgroundColor3 = isActive and Theme.Accent or Theme.Surface, BackgroundTransparency = isActive and 0 or 0.3 }, Tweens.Smooth)
        tween(tab.ButtonStroke, { Transparency = isActive and 0 or 0.4, Color = isActive and Theme.AccentSoft or Theme.Border }, Tweens.Smooth)
        tween(tab.ButtonLabel, { TextColor3 = isActive and Theme.Background or Theme.TextSecondary }, Tweens.Smooth)
        if tab.IconLabel then tween(tab.IconLabel, { TextColor3 = isActive and Theme.Background or Theme.Accent }, Tweens.Smooth) end
        if tab.Indicator then tween(tab.Indicator, { Size = isActive and UDim2.new(0, 3, 0.6, 0) or UDim2.new(0, 3, 0, 0), BackgroundTransparency = isActive and 0 or 1 }, Tweens.Bounce) end
    end
    self.ActiveTab = targetTab
    self.HeaderTitle.Text = targetTab.Title
    self.HeaderSubtitle.Text = string.format("%s > %s", self.WindowName, targetTab.Title)
    tween(self.BreadcrumbIcon, { Rotation = 180 }, Tweens.Smooth)
    task.delay(0.35, function() self.BreadcrumbIcon.Rotation = 0 end)
end

function WindowClass:CreateTab(title, icon)
    icon = icon or Icons.Diamond
    local tabButton = create("TextButton", { Parent = self.TabScroller, Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = Theme.Surface, BackgroundTransparency = 0.3, BorderSizePixel = 0, AutoButtonColor = false, Text = "", ZIndex = 13, ClipsDescendants = true })
    addCorner(tabButton, 11)
    local tabButtonStroke = addStroke(tabButton, Theme.Border, 1, 0.4)

    local indicator = create("Frame", { Parent = tabButton, Position = UDim2.new(0, 0, 0.2, 0), Size = UDim2.new(0, 3, 0, 0), AnchorPoint = Vector2.new(0, 0), BackgroundColor3 = Theme.AccentSoft, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 14 })
    addCorner(indicator, 99); addGradient(indicator, ColorSequence.new(Theme.Accent, Theme.AccentSoft), 90)

    local iconLabel = create("TextLabel", { Parent = tabButton, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0, 24, 1, 0), Text = icon, TextColor3 = Theme.Accent, TextSize = 15, Font = Fonts.Icon, ZIndex = 14 })
    local tabButtonLabel = create("TextLabel", { Parent = tabButton, BackgroundTransparency = 1, Position = UDim2.new(0, 40, 0, 0), Size = UDim2.new(1, -50, 1, 0), Text = title, TextColor3 = Theme.TextSecondary, TextSize = 13, Font = Fonts.Header, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 14 })

    local page = create("ScrollingFrame", { Parent = self.PagesHolder, Visible = false, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = Theme.Accent, ScrollBarImageTransparency = 0.5, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.None, ZIndex = 13 })
    addPadding(page, 16, 16, 8, 16)
    local pageLayout = addList(page, 10)
    self.Library:Connect(pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function() setCanvasToLayout(page, pageLayout, 20) end)

    local tab = setmetatable({ Window = self, Title = title, Icon = icon, Button = tabButton, ButtonStroke = tabButtonStroke, ButtonLabel = tabButtonLabel, IconLabel = iconLabel, Page = page, Layout = pageLayout, Indicator = indicator }, TabClass)

    tabButton.MouseEnter:Connect(function() if self.ActiveTab ~= tab then tween(tabButton, { BackgroundColor3 = Theme.Inline, BackgroundTransparency = 0 }, Tweens.Fast); tween(tabButtonLabel, { TextColor3 = Theme.Text, Position = UDim2.new(0, 44, 0, 0) }, Tweens.Fast); tween(iconLabel, { Position = UDim2.new(0, 14, 0, 0) }, Tweens.Fast) end end)
    tabButton.MouseLeave:Connect(function() if self.ActiveTab ~= tab then tween(tabButton, { BackgroundColor3 = Theme.Surface, BackgroundTransparency = 0.3 }, Tweens.Fast); tween(tabButtonLabel, { TextColor3 = Theme.TextSecondary, Position = UDim2.new(0, 40, 0, 0) }, Tweens.Fast); tween(iconLabel, { Position = UDim2.new(0, 12, 0, 0) }, Tweens.Fast) end end)
    tabButton.MouseButton1Click:Connect(function() createRipple(tabButton, UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y); self:SelectTab(tab) end)

    table.insert(self.Tabs, tab)
    if not self.ActiveTab then self:SelectTab(tab) end
    return tab
end

function TabClass:CreateSection(text, icon)
    icon = icon or Icons.Diamond
    local holder = create("Frame", { Parent = self.Page, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32), ZIndex = 14 })
    local iconLabel = create("TextLabel", { Parent = holder, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.fromOffset(18, 100), Text = icon, TextColor3 = Theme.Accent, TextSize = 13, Font = Fonts.Icon, TextYAlignment = Enum.TextYAlignment.Bottom, ZIndex = 15 })
    local line = create("Frame", { Parent = holder, Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, BackgroundTransparency = 0.5, ZIndex = 14 })
    addGradient(line, ColorSequence.new({ ColorSequenceKeypoint.new(0, Theme.Accent), ColorSequenceKeypoint.new(0.4, Theme.Border), ColorSequenceKeypoint.new(1, Theme.Border) }), 0)
    return create("TextLabel", { Parent = holder, BackgroundTransparency = 1, Position = UDim2.new(0, 24, 0, 0), Size = UDim2.new(1, -24, 1, 0), Text = string.upper(text or "Section"), TextColor3 = Theme.AccentSoft, TextSize = 12, Font = Fonts.Header, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Bottom, ZIndex = 15 })
end

function TabClass:CreateParagraph(data)
    local card = createCard(self.Page); card.ZIndex = 14
    addPadding(card, 16, 16, 14, 14); addList(card, 6)
    local accentBar = create("Frame", { Parent = card, Size = UDim2.new(0, 50, 0, 3), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 15 })
    addCorner(accentBar, 99); addGradient(accentBar, ColorSequence.new(Theme.Accent, Theme.AccentSoft), 0)
    create("TextLabel", { Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = data.Title or "Paragraph", TextColor3 = Theme.Text, TextSize = 16, Font = Fonts.Display, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 15 })
    create("TextLabel", { Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = data.Content or "", TextColor3 = Theme.TextSecondary, TextSize = 12, Font = Fonts.Body, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 15 })
    return card
end

function TabClass:CreateLabel(text)
    local card = createCard(self.Page); card.ZIndex = 14
    addPadding(card, 14, 14, 12, 12)
    local iconDot = create("Frame", { Parent = card, Position = UDim2.new(0, 0, 0, 5), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 15 })
    addCorner(iconDot, 999)
    create("TextLabel", { Parent = card, BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -14, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = text or "", TextColor3 = Theme.TextSecondary, TextSize = 12, Font = Fonts.Body, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 15 })
    return card
end

function TabClass:CreateButton(data)
    local card = createCard(self.Page, 48); card.ZIndex = 14
    local button = create("TextButton", { Parent = card, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = "", ZIndex = 16 })
    local iconContainer = create("Frame", { Parent = card, Position = UDim2.new(0, 12, 0.5, -14), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.85, BorderSizePixel = 0, ZIndex = 15 })
    addCorner(iconContainer, 8); addStroke(iconContainer, Theme.Accent, 1, 0.5)
    local iconLabel = create("TextLabel", { Parent = iconContainer, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = data.Icon or Icons.Play, TextColor3 = Theme.Accent, TextSize = 13, Font = Fonts.Icon, ZIndex = 16 })
    local label = create("TextLabel", { Parent = card, BackgroundTransparency = 1, Position = UDim2.new(0, 50, 0, 0), Size = UDim2.new(1, -85, 1, 0), Text = data.Name or "Button", TextColor3 = Theme.Text, TextSize = 13, Font = Fonts.Header, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 15 })
    local arrow = create("TextLabel", { Parent = card, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, Text = Icons.Arrow, TextColor3 = Theme.Accent, TextSize = 20, Font = Fonts.Header, ZIndex = 15 })

    button.MouseEnter:Connect(function() tween(card, { BackgroundColor3 = Theme.SurfaceHover }, Tweens.Fast); tween(iconContainer, { BackgroundTransparency = 0.7 }, Tweens.Fast); tween(arrow, { Position = UDim2.new(1, -10, 0.5, 0), TextColor3 = Theme.AccentSoft }, Tweens.Fast) end)
    button.MouseLeave:Connect(function() tween(card, { BackgroundColor3 = Theme.Surface }, Tweens.Fast); tween(iconContainer, { BackgroundTransparency = 0.85 }, Tweens.Fast); tween(arrow, { Position = UDim2.new(1, -14, 0.5, 0), TextColor3 = Theme.Accent }, Tweens.Fast) end)
    button.MouseButton1Click:Connect(function()
        local mouse = UserInputService:GetMouseLocation()
        createRipple(card, mouse.X, mouse.Y)
        tween(card, { Size = UDim2.new(1, -4, 0, 46) }, Tweens.Fast)
        task.delay(0.1, function() tween(card, { Size = UDim2.new(1, 0, 0, 48) }, Tweens.Bounce) end)
        if data.Callback then task.spawn(function() pcall(data.Callback) end) end
    end)
    return { Button = button, Label = label, Arrow = arrow }
end

function TabClass:CreateToggle(data)
    local currentValue = data.CurrentValue == true
    if data.Flag then self.Window.Library.Flags[data.Flag] = currentValue end
    local card = createCard(self.Page, 54); card.ZIndex = 14
    local clickArea = create("TextButton", { Parent = card, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = "", ZIndex = 16 })
    
    local iconContainer = create("Frame", { Parent = card, Position = UDim2.new(0, 12, 0.5, -14), Size = UDim2.fromOffset(28, 28), BackgroundColor3 = currentValue and Theme.Success or Theme.Inline, BackgroundTransparency = 0.8, BorderSizePixel = 0, ZIndex = 15 })
    addCorner(iconContainer, 8)
    local iconStroke = addStroke(iconContainer, currentValue and Theme.Success or Theme.Border, 1, 0.5)
    local iconText = create("TextLabel", { Parent = iconContainer, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = data.Icon or Icons.Zap, TextColor3 = currentValue and Theme.Success or Theme.Muted, TextSize = 13, Font = Fonts.Icon, ZIndex = 16 })
    
    create("TextLabel", { Parent = card, BackgroundTransparency = 1, Position = UDim2.new(0, 50, 0, 9), Size = UDim2.new(1, -110, 0, 18), Text = data.Name or "Toggle", TextColor3 = Theme.Text, TextSize = 13, Font = Fonts.Header, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 15 })
    local stateLabel = create("TextLabel", { Parent = card, BackgroundTransparency = 1, Position = UDim2.new(0, 50, 0, 28), Size = UDim2.new(1, -110, 0, 14), Text = currentValue and (Icons.Check .. " Active") or (Icons.Cross .. " Inactive"), TextColor3 = currentValue and Theme.Success or Theme.Muted, TextSize = 11, Font = Fonts.Body, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 15 })

    local track = create("Frame", { Parent = card, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(44, 24), BackgroundColor3 = currentValue and Theme.Accent or Theme.Inline, BorderSizePixel = 0, ZIndex = 15 })
    addCorner(track, 99)
    if currentValue then addGradient(track, ColorSequence.new(Theme.Accent, Theme.AccentSoft), 0) end
    
    local knob = create("Frame", { Parent = track, Position = currentValue and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = Theme.Text, BorderSizePixel = 0, ZIndex = 16 })
    addCorner(knob, 999)
    local knobShadow = addShadow(knob, 0.6, 8, Vector2.new(0, 1))

    local controller = {}
    local function setValue(value, shouldTrigger)
        currentValue = value == true
        stateLabel.Text = currentValue and (Icons.Check .. " Active") or (Icons.Cross .. " Inactive")
        tween(stateLabel, { TextColor3 = currentValue and Theme.Success or Theme.Muted }, Tweens.Normal)
        tween(iconContainer, { BackgroundColor3 = currentValue and Theme.Success or Theme.Inline }, Tweens.Normal)
        tween(iconStroke, { Color = currentValue and Theme.Success or Theme.Border }, Tweens.Normal)
        tween(iconText, { TextColor3 = currentValue and Theme.Success or Theme.Muted }, Tweens.Normal)
        if data.Flag then self.Window.Library.Flags[data.Flag] = currentValue end
        tween(track, { BackgroundColor3 = currentValue and Theme.Accent or Theme.Inline }, Tweens.Normal)
        tween(knob, { Position = currentValue and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9), Size = UDim2.fromOffset(20, 20) }, Tweens.Bounce)
        task.delay(0.2, function() tween(knob, { Size = UDim2.fromOffset(18, 18) }, Tweens.Fast) end)
        if shouldTrigger and data.Callback then task.spawn(function() pcall(data.Callback, currentValue) end) end
    end

    clickArea.MouseEnter:Connect(function() tween(card, { BackgroundColor3 = Theme.SurfaceHover }, Tweens.Fast) end)
    clickArea.MouseLeave:Connect(function() tween(card, { BackgroundColor3 = Theme.Surface }, Tweens.Fast) end)
    clickArea.MouseButton1Click:Connect(function() local mouse = UserInputService:GetMouseLocation(); createRipple(card, mouse.X, mouse.Y); setValue(not currentValue, true) end)
    function controller:Set(value) setValue(value, true) end
    return controller
end

function TabClass:CreateInput(data)
    local card = createCard(self.Page, 80); card.ZIndex = 14
    local iconContainer = create("Frame", { Parent = card, Position = UDim2.new(0, 12, 0, 10), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, ZIndex = 15 })
    create("TextLabel", { Parent = iconContainer, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = data.Icon or Icons.Search, TextColor3 = Theme.Accent, TextSize = 14, Font = Fonts.Icon, ZIndex = 15 })
    create("TextLabel", { Parent = card, BackgroundTransparency = 1, Position = UDim2.new(0, 36, 0, 10), Size = UDim2.new(1, -48, 0, 20), Text = data.Name or "Input", TextColor3 = Theme.Text, TextSize = 13, Font = Fonts.Header, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 15 })
    
    local inputHolder = create("Frame", { Parent = card, Position = UDim2.new(0, 12, 0, 36), Size = UDim2.new(1, -24, 0, 34), BackgroundColor3 = Theme.Inline, BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 15 })
    addCorner(inputHolder, 10)
    local inputStroke = addStroke(inputHolder, Theme.Border, 1, 0.4)

    local textBox = create("TextBox", { Parent = inputHolder, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -24, 1, 0), ClearTextOnFocus = false, Text = data.Default or "", PlaceholderText = data.PlaceholderText or "Enter text...", TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Muted, TextSize = 13, Font = Fonts.Body, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 16 })

    textBox.Focused:Connect(function() tween(inputStroke, { Color = Theme.Accent, Transparency = 0 }, Tweens.Normal); tween(inputHolder, { BackgroundTransparency = 0 }, Tweens.Normal) end)
    textBox.FocusLost:Connect(function() tween(inputStroke, { Color = Theme.Border, Transparency = 0.4 }, Tweens.Normal); tween(inputHolder, { BackgroundTransparency = 0.2 }, Tweens.Normal); local value = textBox.Text; if data.Callback then task.spawn(function() pcall(data.Callback, value) end) end; if data.RemoveTextAfterFocusLost then textBox.Text = "" end end)
    return { Input = textBox }
end

function TabClass:CreateDropdown(data)
    local options = copyArray(data.Options)
    if #options == 0 then options[1] = "None" end
    local selected = getDropdownValue(data.CurrentOption) or options[1]
    if not contains(options, selected) then selected = options[1] end
    if data.Flag then self.Window.Library.Flags[data.Flag] = selected end

    local card = createCard(self.Page); card.ZIndex = 14
    addPadding(card, 14, 14, 12, 12); addList(card, 10)
    
    local titleRow = create("Frame", { Parent = card, Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, ZIndex = 15 })
    create("TextLabel", { Parent = titleRow, BackgroundTransparency = 1, Size = UDim2.fromOffset(18, 18), Position = UDim2.new(0, 0, 0, 0), Text = data.Icon or Icons.Menu, TextColor3 = Theme.Accent, TextSize = 14, Font = Fonts.Icon, ZIndex = 15 })
    create("TextLabel", { Parent = titleRow, BackgroundTransparency = 1, Position = UDim2.new(0, 24, 0, 0), Size = UDim2.new(1, -24, 1, 0), Text = data.Name or "Dropdown", TextColor3 = Theme.Text, TextSize = 13, Font = Fonts.Header, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 15 })

    local selector = create("TextButton", { Parent = card, Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.Inline, BackgroundTransparency = 0.2, BorderSizePixel = 0, AutoButtonColor = false, Text = "", ZIndex = 15 })
    addCorner(selector, 10)
    local selectorStroke = addStroke(selector, Theme.Border, 1, 0.4)
    local selectorText = create("TextLabel", { Parent = selector, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -36, 1, 0), Text = tostring(selected), TextColor3 = Theme.Text, TextSize = 12, Font = Fonts.Body, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 16 })
    local arrow = create("TextLabel", { Parent = selector, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Text = Icons.ArrowDown, TextColor3 = Theme.Accent, TextSize = 14, Font = Fonts.Header, ZIndex = 16 })

    local optionsHolder = create("Frame", { Parent = card, Visible = false, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 15 })
    addList(optionsHolder, 4)

    local optionButtons = {}
    local isOpen = false
    local controller = {}

    local function rebuildButtons()
        for _, button in ipairs(optionButtons) do pcall(function() button:Destroy() end) end
        optionButtons = {}
        for _, optionValue in ipairs(options) do
            local isSelected = optionValue == selected
            local optionButton = create("TextButton", { Parent = optionsHolder, Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = isSelected and Theme.Accent or Theme.Surface, BackgroundTransparency = isSelected and 0 or 0.3, BorderSizePixel = 0, AutoButtonColor = false, Text = "", ZIndex = 16 })
            addCorner(optionButton, 8); addStroke(optionButton, isSelected and Theme.AccentSoft or Theme.Border, 1, isSelected and 0 or 0.5)
            local checkIcon = create("TextLabel", { Parent = optionButton, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.fromOffset(14, 32), Text = isSelected and Icons.Check or " ", TextColor3 = isSelected and Theme.Background or Theme.Muted, TextSize = isSelected and 12 or 16, Font = Fonts.Icon, ZIndex = 17 })
            local optionLabel = create("TextLabel", { Parent = optionButton, BackgroundTransparency = 1, Position = UDim2.new(0, 30, 0, 0), Size = UDim2.new(1, -40, 1, 0), Text = tostring(optionValue), TextColor3 = isSelected and Theme.Background or Theme.TextSecondary, TextSize = 12, Font = Fonts.Body, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 17 })
            optionButton.MouseEnter:Connect(function() if not isSelected then tween(optionButton, { BackgroundColor3 = Theme.Inline, BackgroundTransparency = 0 }, Tweens.Fast) end end)
            optionButton.MouseLeave:Connect(function() if not isSelected then tween(optionButton, { BackgroundColor3 = Theme.Surface, BackgroundTransparency = 0.3 }, Tweens.Fast) end end)
            optionButton.MouseButton1Click:Connect(function()
                selected = optionValue; selectorText.Text = tostring(selected)
                if data.Flag then self.Window.Library.Flags[data.Flag] = selected end
                isOpen = false; tween(arrow, { Rotation = 0 }, Tweens.Smooth)
                task.delay(0.15, function() optionsHolder.Visible = false end)
                rebuildButtons()
                if data.Callback then task.spawn(function() pcall(data.Callback, { selected }) end) end
            end)
            table.insert(optionButtons, optionButton)
        end
    end

    local function refresh(newOptions, keepSelection)
        options = copyArray(newOptions)
        if #options == 0 then options[1] = "None" end
        if not keepSelection or not contains(options, selected) then selected = options[1] end
        selectorText.Text = tostring(selected)
        if data.Flag then self.Window.Library.Flags[data.Flag] = selected end
        rebuildButtons()
    end

    selector.MouseEnter:Connect(function() tween(selectorStroke, { Color = Theme.Accent, Transparency = 0 }, Tweens.Fast); tween(selector, { BackgroundTransparency = 0 }, Tweens.Fast) end)
    selector.MouseLeave:Connect(function() if not isOpen then tween(selectorStroke, { Color = Theme.Border, Transparency = 0.4 }, Tweens.Fast); tween(selector, { BackgroundTransparency = 0.2 }, Tweens.Fast) end end)
    selector.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        optionsHolder.Visible = isOpen
        tween(arrow, { Rotation = isOpen and 180 or 0 }, Tweens.Smooth)
        tween(selectorStroke, { Color = isOpen and Theme.Accent or Theme.Border, Transparency = isOpen and 0 or 0.4 }, Tweens.Fast)
    end)

    rebuildButtons()
    function controller:Refresh(newOptions, keepSelection) refresh(newOptions, keepSelection) end
    function controller:Set(newValue) if contains(options, newValue) then selected = newValue; selectorText.Text = tostring(selected); rebuildButtons() end end
    return controller
end

function TabClass:CreateSlider(data)
    local minimum = (data.Range and data.Range[1]) or 0
    local maximum = (data.Range and data.Range[2]) or 100
    local increment = data.Increment or 1
    local suffix = data.Suffix or ""
    local value = math.clamp(data.CurrentValue or minimum, minimum, maximum)
    if data.Flag then self.Window.Library.Flags[data.Flag] = value end

    local card = createCard(self.Page, 82); card.ZIndex = 14
    
    create("TextLabel", { Parent = card, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 10), Size = UDim2.fromOffset(18, 18), Text = data.Icon or Icons.Target, TextColor3 = Theme.Accent, TextSize = 14, Font = Fonts.Icon, ZIndex = 15 })
    create("TextLabel", { Parent = card, BackgroundTransparency = 1, Position = UDim2.new(0, 36, 0, 10), Size = UDim2.new(1, -110, 0, 20), Text = data.Name or "Slider", TextColor3 = Theme.Text, TextSize = 13, Font = Fonts.Header, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 15 })
    
    local valueBadge = create("Frame", { Parent = card, Position = UDim2.new(1, -80, 0, 8), Size = UDim2.fromOffset(68, 24), BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.85, BorderSizePixel = 0, ZIndex = 15 })
    addCorner(valueBadge, 8); addStroke(valueBadge, Theme.Accent, 1, 0.5)
    local valueLabel = create("TextLabel", { Parent = valueBadge, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = formatNumber(value) .. suffix, TextColor3 = Theme.AccentSoft, TextSize = 12, Font = Fonts.Header, ZIndex = 16 })

    local track = create("Frame", { Parent = card, Position = UDim2.new(0, 14, 0, 48), Size = UDim2.new(1, -28, 0, 6), BackgroundColor3 = Theme.Inline, BorderSizePixel = 0, ZIndex = 15 })
    addCorner(track, 99)
    local fill = create("Frame", { Parent = track, Size = UDim2.new((value - minimum) / math.max(maximum - minimum, 1), 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 16 })
    addCorner(fill, 99); addGradient(fill, ColorSequence.new(Theme.Accent, Theme.AccentSoft), 90)
    
    local thumb = create("Frame", { Parent = track, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new((value - minimum) / math.max(maximum - minimum, 1), 0, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Theme.Text, BorderSizePixel = 0, ZIndex = 17 })
    addCorner(thumb, 999); addStroke(thumb, Theme.Accent, 2.5, 0)
    local thumbGlow = addGlow(thumb, Theme.Accent, 0.6, 12)
    
    create("TextLabel", { Parent = card, BackgroundTransparency = 1, Position = UDim2.new(0, 14, 1, -18), Size = UDim2.new(0, 50, 0, 14), Text = formatNumber(minimum), TextColor3 = Theme.MutedDark, TextSize = 10, Font = Fonts.Body, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 15 })
    create("TextLabel", { Parent = card, BackgroundTransparency = 1, Position = UDim2.new(1, -64, 1, -18), Size = UDim2.new(0, 50, 0, 14), Text = formatNumber(maximum), TextColor3 = Theme.MutedDark, TextSize = 10, Font = Fonts.Body, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 15 })
    
    local dragZone = create("TextButton", { Parent = track, Size = UDim2.new(1, 0, 1, 16), Position = UDim2.new(0, 0, 0, -8), BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 18 })

    local dragging = false
    local controller = {}

    local function updateSlider(newValue, shouldTrigger, skipTween)
        newValue = math.clamp(newValue, minimum, maximum)
        newValue = roundToIncrement(newValue, minimum, increment)
        value = math.clamp(newValue, minimum, maximum)
        if data.Flag then self.Window.Library.Flags[data.Flag] = value end
        local percent = (value - minimum) / math.max(maximum - minimum, 1)
        if skipTween then fill.Size = UDim2.new(percent, 0, 1, 0); thumb.Position = UDim2.new(percent, 0, 0.5, 0)
        else tween(fill, { Size = UDim2.new(percent, 0, 1, 0) }, Tweens.Fast); tween(thumb, { Position = UDim2.new(percent, 0, 0.5, 0) }, Tweens.Fast) end
        valueLabel.Text = formatNumber(value) .. suffix
        if shouldTrigger and data.Callback then task.spawn(function() pcall(data.Callback, value) end) end
    end

    local function updateFromInput(inputPositionX)
        local relativeX = inputPositionX - track.AbsolutePosition.X
        local percent = math.clamp(relativeX / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local newValue = minimum + (maximum - minimum) * percent
        updateSlider(newValue, true, true)
    end

    dragZone.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true
        tween(thumb, { Size = UDim2.fromOffset(20, 20) }, Tweens.Bounce)
        tween(thumbGlow, { ImageTransparency = 0.3 }, Tweens.Fast)
        tween(valueBadge, { BackgroundTransparency = 0.6 }, Tweens.Fast)
        updateFromInput(input.Position.X)
    end)

    self.Window.Library:Connect(UserInputService.InputChanged, function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then updateFromInput(input.Position.X) end
    end)

    self.Window.Library:Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                tween(thumb, { Size = UDim2.fromOffset(16, 16) }, Tweens.Bounce)
                tween(thumbGlow, { ImageTransparency = 0.6 }, Tweens.Normal)
                tween(valueBadge, { BackgroundTransparency = 0.85 }, Tweens.Normal)
            end
        end
    end)

    function controller:Set(newValue) updateSlider(newValue, true) end
    return controller
end

-- ========================================================================
-- 🚀 CREATE HUB
-- ========================================================================
Hub.Helpers.Notify = function(title, content, duration, notifType)
    if Runtime.Library then Runtime.Library:Notify({ Title = title, Content = content, Duration = duration or 4, Type = notifType or "info" }) end
end

local Window = Library:CreateWindow({ Name = "Saloi Hub", Subtitle = "Premium Edition v3.0" })
Runtime.Window = Window

local HomeTab = Window:CreateTab("Dashboard", Icons.Dashboard)
HomeTab:CreateParagraph({ Title = "Welcome to Saloi Hub Premium", Content = "UI fixed: CornerRadius error fixed. Icons updated for better compatibility." })

local modules = {
    { label = "Auto Farm", fileName = "Autofarm.lua", icon = Icons.Farm },
    { label = "Event", fileName = "Event.lua", icon = Icons.Event },
    { label = "Teleport Island", fileName = "teleport island.lua", icon = Icons.Teleport },
}

local function loadModuleFromWeb(fileName, label)
    local safeFileName = string.gsub(fileName, " ", "%%20")
    local url = "https://raw.githubusercontent.com/Huunhat206/SALOIIII/main/" .. safeFileName .. "?v=" .. tostring(tick())
    local success, source = pcall(function() return game:HttpGet(url) end)
    if not success then Runtime.ModuleStatus[label] = "HTTP Error"; return false, "HTTP Error" end
    local func, compileErr = loadstring(source)
    if not func then Runtime.ModuleStatus[label] = "Compile: " .. tostring(compileErr); return false, "Compile Error" end
    local runSuccess, runErr = pcall(func, Window, Library)
    if not runSuccess then Runtime.ModuleStatus[label] = "Runtime: " .. tostring(runErr); return false, "Runtime Error" end
    Runtime.ModuleStatus[label] = "Loaded"
    return true, "Success"
end

local loadedCount = 0
for _, mod in ipairs(modules) do
    local ok, message = loadModuleFromWeb(mod.fileName, mod.label)
    if ok then loadedCount = loadedCount + 1 else Hub.Helpers.Notify("Module Error", mod.label .. ": " .. tostring(message), 6, "error") end
end

HomeTab:CreateSection("Module Status", Icons.Sparkle)
for _, mod in ipairs(modules) do
    local status = Runtime.ModuleStatus[mod.label] or "Not loaded"
    local symbol = status == "Loaded" and Icons.Check or Icons.Cross
    HomeTab:CreateLabel(symbol .. "  " .. mod.label .. "  ->  " .. status)
end

HomeTab:CreateSection("Controls", Icons.Gear)
HomeTab:CreateButton({ Name = "Report Status", Icon = Icons.Info, Callback = function() Hub.Helpers.Notify("Saloi Hub", "Loaded " .. tostring(loadedCount) .. "/" .. tostring(#modules) .. " modules.", 5, "success") end })
HomeTab:CreateButton({ Name = "Destroy Script", Icon = Icons.Cross, Callback = function() Library:Destroy() end })

Hub.Helpers.Notify("Saloi Hub Premium", "System loaded " .. tostring(loadedCount) .. "/" .. tostring(#modules) .. " modules.", 5, "success")
