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
local TextService = cloneref(game:GetService("TextService"))
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Workspace = cloneref(game:GetService("Workspace"))

local LocalPlayer = Players.LocalPlayer
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled

local function safeGetUI()
    local ok, result = pcall(function() return gethui and gethui() or CoreGui end)
    return (ok and result) and result or CoreGui
end

local Theme = {
    Background = Color3.fromRGB(11, 12, 15),
    Surface = Color3.fromRGB(18, 20, 24),
    Panel = Color3.fromRGB(22, 25, 31),
    Inline = Color3.fromRGB(30, 33, 40),
    Border = Color3.fromRGB(54, 60, 72),
    Text = Color3.fromRGB(243, 244, 246),
    Muted = Color3.fromRGB(156, 163, 175),
    Accent = Color3.fromRGB(255, 132, 84),
    AccentSoft = Color3.fromRGB(255, 181, 140),
    Success = Color3.fromRGB(95, 219, 138),
    Error = Color3.fromRGB(255, 95, 95),
}

local Fonts = {
    Title = Enum.Font.GothamBold,
    Header = Enum.Font.GothamSemibold,
    Body = Enum.Font.Gotham,
    Mono = Enum.Font.Code,
}

local function create(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties or {}) do
        instance[property] = value
    end
    return instance
end

local function tween(instance, goal, info)
    local tweenInfo = info or TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
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
        Parent = parent, PaddingLeft = UDim.new(0, left or 0), PaddingRight = UDim.new(0, right or left or 0),
        PaddingTop = UDim.new(0, top or 0), PaddingBottom = UDim.new(0, bottom or top or 0),
    })
end

local function addList(parent, padding, horizontalAlignment)
    return create("UIListLayout", {
        Parent = parent, Padding = UDim.new(0, padding or 0),
        SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = horizontalAlignment or Enum.HorizontalAlignment.Left,
    })
end

local function setCanvasToLayout(scrollingFrame, layout, extraPadding)
    scrollingFrame.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + (extraPadding or 0))
end

local function copyArray(list)
    local result = {}
    for index, value in ipairs(list or {}) do result[index] = value end
    return result
end

local function formatNumber(value)
    if math.abs(value - math.floor(value)) < 0.001 then return tostring(math.floor(value)) end
    local text = string.format("%.2f", value)
    text = string.gsub(text, "0+$", "")
    text = string.gsub(text, "%.$", "")
    return text
end

local function roundToIncrement(value, minimum, increment)
    if not increment or increment <= 0 then return value end
    local relative = (value - minimum) / increment
    return minimum + math.floor(relative + 0.5) * increment
end

local function getDropdownValue(option)
    return type(option) == "table" and option[1] or option
end

local function contains(list, target)
    for _, value in ipairs(list) do
        if value == target then return true end
    end
    return false
end

local function makeDraggable(handle, target, library)
    local dragging, dragInput, dragStart, startPosition = false, nil, nil, nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true
        dragStart = input.Position
        startPosition = target.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    local connectionHost = library or { Connect = function(_, signal, callback) return signal:Connect(callback) end }

    connectionHost:Connect(UserInputService.InputChanged, function(input)
        if not dragging or input ~= dragInput then return end
        local delta = input.Position - dragStart
        target.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
    end)
end

local function makePanel(parent, properties)
    local props = {}
    for k, v in pairs(properties or {}) do props[k] = v end
    props.Parent = parent 
    local panel = create("Frame", props)
    addCorner(panel, props.CornerRadius or 12)
    addStroke(panel, Theme.Border, 1, 0.25)
    return panel
end

local Library = {
    Theme = Theme, Fonts = Fonts, Flags = Runtime.Flags, Connections = {},
    RootGui = nil, NotificationGui = nil, Blur = nil, Window = nil,
}

Runtime.Library = Library

function Library:Connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(self.Connections, connection)
    return connection
end

function Library:Destroy()
    for _, connection in ipairs(self.Connections) do pcall(function() connection:Disconnect() end) end
    self.Connections = {}
    if self.Blur then pcall(function() self.Blur:Destroy() end) self.Blur = nil end
    if self.NotificationGui then pcall(function() self.NotificationGui:Destroy() end) self.NotificationGui = nil end
    if self.RootGui then pcall(function() self.RootGui:Destroy() end) self.RootGui = nil end
    self.Window = nil
    Runtime.Library = nil
end

function Library:EnsureNotifications()
    if self.NotificationGui and self.NotificationGui.Parent then return end
    local notificationGui = create("ScreenGui", {
        Parent = safeGetUI(), Name = "SaloiHubNotifications", ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9999, IgnoreGuiInset = true,
    })
    local holder = create("Frame", {
        Parent = notificationGui, Name = "Holder", AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 16), Size = UDim2.fromOffset(330, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, BorderSizePixel = 0,
    })
    addList(holder, 10, Enum.HorizontalAlignment.Right)
    self.NotificationGui = notificationGui
    self.NotificationHolder = holder
end

function Library:Notify(data)
    self:EnsureNotifications()
    local title = data.Title or "Saloi Hub"
    local content = data.Content or data.Description or ""
    local duration = data.Duration or 4
    local accent = data.Color or Theme.Accent

    local notification = create("Frame", {
        Parent = self.NotificationHolder, Name = "Notification", Size = UDim2.fromOffset(330, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Surface, BackgroundTransparency = 1,
        BorderSizePixel = 0, ClipsDescendants = true,
    })
    addCorner(notification, 12)
    local stroke = addStroke(notification, Theme.Border, 1, 1)
    addPadding(notification, 14, 14, 12, 12)
    addList(notification, 6)

    create("Frame", { Parent = notification, Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = accent, BorderSizePixel = 0 })

    local titleLabel = create("TextLabel", {
        Parent = notification, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Text = title, TextColor3 = Theme.Text, TextTransparency = 1, TextSize = 15, Font = Fonts.Header,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, RichText = false,
    })

    local contentLabel = create("TextLabel", {
        Parent = notification, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Text = content, TextColor3 = Theme.Muted, TextTransparency = 1, TextWrapped = true, TextSize = 13,
        Font = Fonts.Body, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, RichText = false,
    })

    local durationBar = create("Frame", {
        Parent = notification, Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = Theme.Inline,
        BackgroundTransparency = 0.2, BorderSizePixel = 0,
    })
    addCorner(durationBar, 99)

    local fill = create("Frame", { Parent = durationBar, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = accent, BorderSizePixel = 0 })
    addCorner(fill, 99)

    tween(notification, { BackgroundTransparency = 0.04 })
    tween(stroke, { Transparency = 0.22 })
    tween(titleLabel, { TextTransparency = 0 })
    tween(contentLabel, { TextTransparency = 0 })
    tween(fill, { Size = UDim2.new(0, 0, 1, 0) }, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out))

    task.delay(duration, function()
        tween(notification, { BackgroundTransparency = 1 })
        tween(stroke, { Transparency = 1 })
        tween(titleLabel, { TextTransparency = 1 })
        tween(contentLabel, { TextTransparency = 1 })
        task.wait(0.2)
        pcall(function() notification:Destroy() end)
    end)
end

local WindowClass, TabClass = {}, {}
WindowClass.__index = WindowClass
TabClass.__index = TabClass

local function createCard(parent, fixedHeight)
    local card = create("Frame", {
        Parent = parent, Size = UDim2.new(1, 0, 0, fixedHeight or 0), AutomaticSize = fixedHeight and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, ClipsDescendants = true,
    })
    addCorner(card, 12)
    addStroke(card, Theme.Border, 1, 0.25)
    return card
end

function Library:CreateWindow(options)
    self:EnsureNotifications()

    local finalWindowSize = IsMobile and UDim2.fromOffset(650, 380) or UDim2.fromOffset(800, 450)
    local startWindowSize = IsMobile and UDim2.fromOffset(600, 350) or UDim2.fromOffset(750, 400)

    local rootGui = create("ScreenGui", { Parent = safeGetUI(), Name = "SaloiHub", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9998 })
    self.RootGui = rootGui

    local blur = create("BlurEffect", { Parent = Lighting, Name = "SaloiHubBlur", Size = 0 })
    self.Blur = blur

    local overlay = create("Frame", { Parent = rootGui, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1 })

    local root = makePanel(rootGui, {
        Name = "Root", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = startWindowSize, BackgroundColor3 = Theme.Background, BackgroundTransparency = 0,
        BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 10
    })

    local sidebar = create("Frame", { Parent = root, Name = "Sidebar", Size = UDim2.new(0, 200, 1, 0), BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, ZIndex = 11 })
    addStroke(sidebar, Theme.Border, 1, 1)

    local divider = create("Frame", { Parent = root, Name = "Divider", Position = UDim2.new(0, 200, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, BackgroundTransparency = 0.4, ZIndex = 11 })

    local brandHolder = create("Frame", { Parent = sidebar, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 80), ZIndex = 12 })
    addPadding(brandHolder, 15, 15, 15, 15)

    local brandTitle = create("TextLabel", {
        Parent = brandHolder, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 25), Text = options.Name or "Saloi Hub",
        TextColor3 = Theme.Text, TextSize = 20, Font = Fonts.Title, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12
    })

    local brandAccent = create("Frame", { Parent = brandHolder, Position = UDim2.new(0, 0, 0, 30), Size = UDim2.fromOffset(40, 3), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 12 })
    addCorner(brandAccent, 99)

    local brandSubtitle = create("TextLabel", {
        Parent = brandHolder, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 40), Size = UDim2.new(1, 0, 0, 18),
        Text = options.Subtitle or "Custom local UI", TextColor3 = Theme.Muted, TextSize = 12, Font = Fonts.Body, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12
    })

    local tabScroller = create("ScrollingFrame", {
        Parent = sidebar, Name = "TabScroller", Position = UDim2.new(0, 0, 0, 80), Size = UDim2.new(1, 0, 1, -120),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.None, ZIndex = 12
    })
    addPadding(tabScroller, 10, 10, 5, 5)
    local tabLayout = addList(tabScroller, 6)
    self:Connect(tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function() setCanvasToLayout(tabScroller, tabLayout, 10) end)

    local sidebarFooter = create("TextLabel", {
        Parent = sidebar, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 15, 1, -10),
        Size = UDim2.new(1, -30, 0, 30), Text = string.format("Player: %s", LocalPlayer and LocalPlayer.Name or "Unknown"),
        TextColor3 = Theme.Muted, TextSize = 11, Font = Fonts.Body, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Bottom, ZIndex = 12
    })

    local contentHolder = create("Frame", { Parent = root, Name = "ContentHolder", Position = UDim2.new(0, 201, 0, 0), Size = UDim2.new(1, -201, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 11 })

    local topBar = create("Frame", { Parent = contentHolder, Name = "TopBar", Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 12 })
    addPadding(topBar, 20, 20, 15, 0)

    local headerTitle = create("TextLabel", {
        Parent = topBar, BackgroundTransparency = 1, Size = UDim2.new(1, -50, 0, 25), Text = options.Name or "Saloi Hub",
        TextColor3 = Theme.Text, TextSize = 18, Font = Fonts.Title, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12
    })

    local headerSubtitle = create("TextLabel", {
        Parent = topBar, BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 25), Size = UDim2.new(1, -50, 0, 18),
        Text = options.Subtitle or "Custom local UI", TextColor3 = Theme.Muted, TextSize = 12, Font = Fonts.Body, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12
    })

    local closeButton = create("TextButton", {
        Parent = topBar, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(35, 35),
        BackgroundColor3 = Theme.Inline, BorderSizePixel = 0, AutoButtonColor = false, Text = "✕", TextColor3 = Theme.Text, TextSize = 14, Font = Fonts.Title, ZIndex = 13
    })
    addCorner(closeButton, 8)
    addStroke(closeButton, Theme.Border, 1, 0.25)

    local pagesHolder = create("Frame", { Parent = contentHolder, Name = "PagesHolder", Position = UDim2.new(0, 0, 0, 60), Size = UDim2.new(1, 0, 1, -60), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 12 })

    local window = setmetatable({
        Library = self, Root = root, Sidebar = sidebar, TabScroller = tabScroller, TabLayout = tabLayout,
        PagesHolder = pagesHolder, HeaderTitle = headerTitle, HeaderSubtitle = headerSubtitle, Tabs = {}, ActiveTab = nil,
        WindowName = options.Name or "Saloi Hub", WindowSubtitle = options.Subtitle or "Custom local UI",
    }, WindowClass)

    self.Window = window

    -- =========================================================================
    -- NÚT BẬT/TẮT LOGO (Ô VUÔNG CHÈN ẢNH) - KÉO THẢ ĐƯỢC
    -- =========================================================================
    local openButton = create("ImageButton", {
        Parent = rootGui,
        Name = "OpenLogoButton",
        Size = UDim2.fromOffset(50, 50),
        Position = UDim2.new(0, 20, 0, 20), -- Vị trí lúc mới hiện (Góc trái)
        BackgroundColor3 = Theme.Panel,
        AutoButtonColor = true,
        Visible = false,
        ZIndex = 9999,
        -- BẠN HÃY DÁN ID ẢNH CỦA BẠN VÀO DÒNG BÊN DƯỚI (VD: "rbxassetid://123456789")
        Image = "https://github.com/Huunhat206/SALOIIII/blob/main/Saloi.png", 
    })
    addCorner(openButton, 10)
    addStroke(openButton, Theme.Accent, 2, 0)
    
    -- Kéo thả nút Logo
    makeDraggable(openButton, openButton, self)

    -- Hiệu ứng hover cho nút Logo
    openButton.MouseEnter:Connect(function() tween(openButton, { Size = UDim2.fromOffset(55, 55) }, TweenInfo.new(0.1)) end)
    openButton.MouseLeave:Connect(function() tween(openButton, { Size = UDim2.fromOffset(50, 50) }, TweenInfo.new(0.1)) end)

    closeButton.MouseEnter:Connect(function() tween(closeButton, { BackgroundColor3 = Theme.Accent }) end)
    closeButton.MouseLeave:Connect(function() tween(closeButton, { BackgroundColor3 = Theme.Inline }) end)
    
    -- NÚT X SẼ THU NHỎ HUB
    closeButton.MouseButton1Click:Connect(function()
        tween(blur, { Size = 0 }, TweenInfo.new(0.2))
        tween(overlay, { BackgroundTransparency = 1 }, TweenInfo.new(0.2))
        tween(root, { Size = startWindowSize }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        task.wait(0.2)
        root.Visible = false
        openButton.Visible = true -- Hiện Logo lên
    end)

    -- BẤM LOGO ĐỂ PHÓNG TO LẠI HUB
    openButton.MouseButton1Click:Connect(function()
        openButton.Visible = false -- Tắt Logo
        root.Visible = true
        tween(blur, { Size = 18 }, TweenInfo.new(0.25))
        tween(overlay, { BackgroundTransparency = 0.4 }, TweenInfo.new(0.2))
        tween(root, { Size = finalWindowSize }, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
    end)
    -- =========================================================================

    -- Animation lúc mới bật script
    tween(blur, { Size = 18 }, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    tween(overlay, { BackgroundTransparency = 0.4 }, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    tween(root, { Size = finalWindowSize }, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out))

    makeDraggable(topBar, root, self)
    return window
end

function WindowClass:SelectTab(targetTab)
    for _, tab in ipairs(self.Tabs) do
        local isActive = tab == targetTab
        tab.Page.Visible = isActive
        tween(tab.Button, { BackgroundColor3 = isActive and Theme.Accent or Theme.Surface })
        tween(tab.ButtonStroke, { Transparency = isActive and 0 or 0.35, Color = isActive and Theme.AccentSoft or Theme.Border })
        tween(tab.ButtonLabel, { TextColor3 = isActive and Theme.Background or Theme.Text })
        tween(tab.ButtonShadow, { BackgroundTransparency = isActive and 0.78 or 1 })
    end
    self.ActiveTab = targetTab
    self.HeaderTitle.Text = targetTab.Title
    self.HeaderSubtitle.Text = string.format("%s • %s", self.WindowName, targetTab.Title)
end

function WindowClass:CreateTab(title)
    local tabButton = create("TextButton", { Parent = self.TabScroller, Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, AutoButtonColor = false, Text = "", ZIndex = 13 })
    addCorner(tabButton, 10)
    local tabButtonStroke = addStroke(tabButton, Theme.Border, 1, 0.35)

    local tabButtonShadow = create("Frame", { Parent = tabButton, Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Theme.AccentSoft, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 12 })
    addCorner(tabButtonShadow, 10)

    local tabButtonLabel = create("TextLabel", {
        Parent = tabButton, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 12, 0, 0),
        Text = title, TextColor3 = Theme.Text, TextSize = 13, Font = Fonts.Header, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 14
    })

    local page = create("ScrollingFrame", {
        Parent = self.PagesHolder, Visible = false, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.None, ZIndex = 13
    })
    addPadding(page, 15, 15, 5, 15)
    local pageLayout = addList(page, 8)

    self.Library:Connect(pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function() setCanvasToLayout(page, pageLayout, 15) end)

    local tab = setmetatable({ Window = self, Title = title, Button = tabButton, ButtonStroke = tabButtonStroke, ButtonShadow = tabButtonShadow, ButtonLabel = tabButtonLabel, Page = page, Layout = pageLayout }, TabClass)

    tabButton.MouseEnter:Connect(function() if self.ActiveTab ~= tab then tween(tabButton, { BackgroundColor3 = Theme.Inline }) end end)
    tabButton.MouseLeave:Connect(function() if self.ActiveTab ~= tab then tween(tabButton, { BackgroundColor3 = Theme.Surface }) end end)
    tabButton.MouseButton1Click:Connect(function() self:SelectTab(tab) end)

    table.insert(self.Tabs, tab)
    if not self.ActiveTab then self:SelectTab(tab) end
    return tab
end

function TabClass:CreateSection(text)
    return create("TextLabel", { Parent = self.Page, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), Text = string.upper(text or "Section"), TextColor3 = Theme.AccentSoft, TextSize = 12, Font = Fonts.Header, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 14 })
end

function TabClass:CreateParagraph(data)
    local card = createCard(self.Page)
    card.ZIndex = 14
    addPadding(card, 12, 12, 12, 12)
    addList(card, 5)
    create("Frame", { Parent = card, Size = UDim2.new(0, 40, 0, 3), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 15 })
    create("TextLabel", { Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = data.Title or "Paragraph", TextColor3 = Theme.Text, TextSize = 15, Font = Fonts.Title, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 15 })
    create("TextLabel", { Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = data.Content or "", TextColor3 = Theme.Muted, TextSize = 12, Font = Fonts.Body, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 15 })
    return card
end

function TabClass:CreateLabel(text)
    local card = createCard(self.Page)
    card.ZIndex = 14
    addPadding(card, 12, 12, 10, 10)
    create("TextLabel", { Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = text or "", TextColor3 = Theme.Muted, TextSize = 12, Font = Fonts.Body, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 15 })
    return card
end

function TabClass:CreateButton(data)
    local card = createCard(self.Page, 45)
    card.ZIndex = 14
    local button = create("TextButton", { Parent = card, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = "", ZIndex = 16 })
    local label = create("TextLabel", { Parent = card, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -50, 1, 0), Text = data.Name or "Button", TextColor3 = Theme.Text, TextSize = 13, Font = Fonts.Header, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 15 })
    local arrow = create("TextLabel", { Parent = card, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, Text = "›", TextColor3 = Theme.Accent, TextSize = 20, Font = Fonts.Header, ZIndex = 15 })

    button.MouseEnter:Connect(function() tween(card, { BackgroundColor3 = Theme.Inline }) end)
    button.MouseLeave:Connect(function() tween(card, { BackgroundColor3 = Theme.Surface }) end)
    button.MouseButton1Click:Connect(function() if data.Callback then task.spawn(function() pcall(data.Callback) end) end end)

    return { Button = button, Label = label, Arrow = arrow }
end

function TabClass:CreateToggle(data)
    local currentValue = data.CurrentValue == true
    if data.Flag then self.Window.Library.Flags[data.Flag] = currentValue end

    local card = createCard(self.Page, 50)
    card.ZIndex = 14
    local clickArea = create("TextButton", { Parent = card, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = "", ZIndex = 16 })
    create("TextLabel", { Parent = card, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -80, 0, 18), Text = data.Name or "Toggle", TextColor3 = Theme.Text, TextSize = 13, Font = Fonts.Header, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 15 })
    local stateLabel = create("TextLabel", { Parent = card, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 26), Size = UDim2.new(1, -80, 0, 14), Text = currentValue and "Enabled" or "Disabled", TextColor3 = Theme.Muted, TextSize = 11, Font = Fonts.Body, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 15 })

    local track = create("Frame", { Parent = card, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(40, 22), BackgroundColor3 = currentValue and Theme.Accent or Theme.Inline, BorderSizePixel = 0, ZIndex = 15 })
    addCorner(track, 99)
    local knob = create("Frame", { Parent = track, Position = currentValue and UDim2.new(1, -19, 0.5, -7.5) or UDim2.new(0, 4, 0.5, -7.5), Size = UDim2.fromOffset(15, 15), BackgroundColor3 = Theme.Text, BorderSizePixel = 0, ZIndex = 16 })
    addCorner(knob, 99)

    local controller = {}
    local function setValue(value, shouldTrigger)
        currentValue = value == true
        stateLabel.Text = currentValue and "Enabled" or "Disabled"
        if data.Flag then self.Window.Library.Flags[data.Flag] = currentValue end
        tween(track, { BackgroundColor3 = currentValue and Theme.Accent or Theme.Inline })
        tween(knob, { Position = currentValue and UDim2.new(1, -19, 0.5, -7.5) or UDim2.new(0, 4, 0.5, -7.5) })
        if shouldTrigger and data.Callback then task.spawn(function() pcall(data.Callback, currentValue) end) end
    end

    clickArea.MouseButton1Click:Connect(function() setValue(not currentValue, true) end)
    function controller:Set(value) setValue(value, true) end
    return controller
end

function TabClass:CreateInput(data)
    local card = createCard(self.Page, 75)
    card.ZIndex = 14
    create("TextLabel", { Parent = card, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -24, 0, 18), Text = data.Name or "Input", TextColor3 = Theme.Text, TextSize = 13, Font = Fonts.Header, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 15 })
    local inputHolder = create("Frame", { Parent = card, Position = UDim2.new(0, 12, 0, 30), Size = UDim2.new(1, -24, 0, 32), BackgroundColor3 = Theme.Inline, BorderSizePixel = 0, ZIndex = 15 })
    addCorner(inputHolder, 8)
    addStroke(inputHolder, Theme.Border, 1, 0.35)

    local textBox = create("TextBox", { Parent = inputHolder, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -20, 1, 0), ClearTextOnFocus = false, Text = data.Default or "", PlaceholderText = data.PlaceholderText or "", TextColor3 = Theme.Text, PlaceholderColor3 = Theme.Muted, TextSize = 12, Font = Fonts.Body, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 16 })

    textBox.FocusLost:Connect(function()
        local value = textBox.Text
        if data.Callback then task.spawn(function() pcall(data.Callback, value) end) end
        if data.RemoveTextAfterFocusLost then textBox.Text = "" end
    end)
    return { Input = textBox }
end

function TabClass:CreateDropdown(data)
    local options = copyArray(data.Options)
    if #options == 0 then options[1] = "None" end
    local selected = getDropdownValue(data.CurrentOption) or options[1]
    if not contains(options, selected) then selected = options[1] end
    if data.Flag then self.Window.Library.Flags[data.Flag] = selected end

    local card = createCard(self.Page)
    card.ZIndex = 14
    addPadding(card, 12, 12, 10, 10)
    addList(card, 8)
    create("TextLabel", { Parent = card, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), Text = data.Name or "Dropdown", TextColor3 = Theme.Text, TextSize = 13, Font = Fonts.Header, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 15 })

    local selector = create("TextButton", { Parent = card, Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.Inline, BorderSizePixel = 0, AutoButtonColor = false, Text = "", ZIndex = 15 })
    addCorner(selector, 8)
    addStroke(selector, Theme.Border, 1, 0.35)

    local selectorText = create("TextLabel", { Parent = selector, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -30, 1, 0), Text = tostring(selected), TextColor3 = Theme.Text, TextSize = 12, Font = Fonts.Body, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 16 })
    local arrow = create("TextLabel", { Parent = selector, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Text = "▾", TextColor3 = Theme.Accent, TextSize = 16, Font = Fonts.Header, ZIndex = 16 })

    local optionsHolder = create("Frame", { Parent = card, Visible = false, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 15 })
    addList(optionsHolder, 5)

    local optionButtons = {}
    local isOpen = false
    local controller = {}

    local function rebuildButtons()
        for _, button in ipairs(optionButtons) do pcall(function() button:Destroy() end) end
        optionButtons = {}
        for _, optionValue in ipairs(options) do
            local optionButton = create("TextButton", { Parent = optionsHolder, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = optionValue == selected and Theme.Accent or Theme.Surface, BorderSizePixel = 0, AutoButtonColor = false, Text = "", ZIndex = 16 })
            addCorner(optionButton, 8)
            addStroke(optionButton, optionValue == selected and Theme.AccentSoft or Theme.Border, 1, optionValue == selected and 0 or 0.45)
            local optionLabel = create("TextLabel", { Parent = optionButton, BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -20, 1, 0), Text = tostring(optionValue), TextColor3 = optionValue == selected and Theme.Background or Theme.Text, TextSize = 12, Font = Fonts.Body, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 17 })

            optionButton.MouseEnter:Connect(function() if optionValue ~= selected then tween(optionButton, { BackgroundColor3 = Theme.Inline }) end end)
            optionButton.MouseLeave:Connect(function() if optionValue ~= selected then tween(optionButton, { BackgroundColor3 = Theme.Surface }) end end)
            optionButton.MouseButton1Click:Connect(function()
                selected = optionValue
                selectorText.Text = tostring(selected)
                if data.Flag then self.Window.Library.Flags[data.Flag] = selected end
                isOpen = false
                optionsHolder.Visible = false
                arrow.Text = "▾"
                rebuildButtons()
                if data.Callback then task.spawn(function() pcall(data.Callback, { selected }) end) end
            end)
            table.insert(optionButtons, optionButton)
            table.insert(optionButtons, optionLabel)
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

    selector.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        optionsHolder.Visible = isOpen
        arrow.Text = isOpen and "▴" or "▾"
    end)

    rebuildButtons()
    function controller:Refresh(newOptions, keepSelection) refresh(newOptions, keepSelection) end
    function controller:Set(newValue)
        if contains(options, newValue) then
            selected = newValue
            selectorText.Text = tostring(selected)
            rebuildButtons()
        end
    end
    return controller
end

function TabClass:CreateSlider(data)
    local minimum = (data.Range and data.Range[1]) or 0
    local maximum = (data.Range and data.Range[2]) or 100
    local increment = data.Increment or 1
    local suffix = data.Suffix or ""
    local value = math.clamp(data.CurrentValue or minimum, minimum, maximum)

    if data.Flag then self.Window.Library.Flags[data.Flag] = value end

    local card = createCard(self.Page, 75)
    card.ZIndex = 14
    create("TextLabel", { Parent = card, BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -90, 0, 18), Text = data.Name or "Slider", TextColor3 = Theme.Text, TextSize = 13, Font = Fonts.Header, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 15 })
    local valueLabel = create("TextLabel", { Parent = card, BackgroundTransparency = 1, Position = UDim2.new(1, -94, 0, 8), Size = UDim2.new(0, 80, 0, 18), Text = formatNumber(value) .. suffix, TextColor3 = Theme.AccentSoft, TextSize = 12, Font = Fonts.Header, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 15 })

    local track = create("Frame", { Parent = card, Position = UDim2.new(0, 12, 0, 42), Size = UDim2.new(1, -24, 0, 8), BackgroundColor3 = Theme.Inline, BorderSizePixel = 0, ZIndex = 15 })
    addCorner(track, 99)
    local fill = create("Frame", { Parent = track, Size = UDim2.new((value - minimum) / math.max(maximum - minimum, 1), 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, ZIndex = 16 })
    addCorner(fill, 99)
    local thumb = create("Frame", { Parent = track, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new((value - minimum) / math.max(maximum - minimum, 1), 0, 0.5, 0), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Theme.Text, BorderSizePixel = 0, ZIndex = 17 })
    addCorner(thumb, 99)
    local dragZone = create("TextButton", { Parent = track, Size = UDim2.new(1, 0, 1, 10), Position = UDim2.new(0, 0, 0, -5), BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 18 })

    local dragging = false
    local controller = {}

    local function updateSlider(newValue, shouldTrigger)
        newValue = math.clamp(newValue, minimum, maximum)
        newValue = roundToIncrement(newValue, minimum, increment)
        value = math.clamp(newValue, minimum, maximum)

        if data.Flag then self.Window.Library.Flags[data.Flag] = value end
        local percent = (value - minimum) / math.max(maximum - minimum, 1)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        thumb.Position = UDim2.new(percent, 0, 0.5, 0)
        valueLabel.Text = formatNumber(value) .. suffix
        if shouldTrigger and data.Callback then task.spawn(function() pcall(data.Callback, value) end) end
    end

    local function updateFromInput(inputPositionX)
        local relativeX = inputPositionX - track.AbsolutePosition.X
        local percent = math.clamp(relativeX / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local newValue = minimum + (maximum - minimum) * percent
        updateSlider(newValue, true)
    end

    dragZone.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true
        updateFromInput(input.Position.X)
    end)

    self.Window.Library:Connect(UserInputService.InputChanged, function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then updateFromInput(input.Position.X) end
    end)

    self.Window.Library:Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)

    function controller:Set(newValue) updateSlider(newValue, true) end
    return controller
end

Hub.Helpers.Notify = function(title, content, duration)
    if Runtime.Library then
        Runtime.Library:Notify({ Title = title, Content = content, Duration = duration or 4 })
    end
end

local Window = Library:CreateWindow({ Name = "Saloi Hub", Subtitle = "Auto Farm • Event • Teleport" })
Runtime.Window = Window

local HomeTab = Window:CreateTab("🏠 Dashboard")
HomeTab:CreateParagraph({
    Title = "Saloi Hub",
    Content = "Da fix loi mat UI (Go bo Image Shadow bi loi). Bấm dấu X để thu nhỏ thành 1 ô vuông Logo trên màn hình.",
})

-- ==========================================
-- HỆ THỐNG TẢI MODULE TỪ GITHUB (ONLINE)
-- ==========================================

local repoUrl = "https://raw.githubusercontent.com/Huunhat206/SALOIIII/main/"

local function loadModuleFromWeb(fileName, label)
    local safeFileName = string.gsub(fileName, " ", "%%20")
    local url = repoUrl .. safeFileName .. "?v=" .. tostring(tick())
    
    local success, source = pcall(function() return game:HttpGet(url) end)
    
    if not success then
        local msg = "Loi HTTP GET."
        Runtime.ModuleStatus[label] = msg
        return false, msg
    end
    
    local func, compileErr = loadstring(source)
    if not func then
        local msg = "Loi Compile: " .. tostring(compileErr)
        Runtime.ModuleStatus[label] = msg
        return false, msg
    end
    
    local runSuccess, runErr = pcall(func, Window, Library)
    if not runSuccess then
        local msg = "Loi Runtime: " .. tostring(runErr)
        Runtime.ModuleStatus[label] = msg
        return false, msg
    end
    
    Runtime.ModuleStatus[label] = "Loaded (GitHub)"
    return true, "Success"
end

local modules = {
    { label = "Auto Farm", fileName = "Autofarm.lua" },
    { label = "Event", fileName = "Event.lua" },
    { label = "Teleport Island", fileName = "teleport island.lua" },
}

local loadedCount = 0
for _, mod in ipairs(modules) do
    local ok, message = loadModuleFromWeb(mod.fileName, mod.label)
    if ok then
        loadedCount = loadedCount + 1
    else
        Hub.Helpers.Notify("Module Lỗi", mod.label .. ": " .. tostring(message), 6)
    end
end

-- ==========================================
-- GIAO DIỆN TRẠNG THÁI
-- ==========================================

HomeTab:CreateSection("Trạng thái module")
for _, mod in ipairs(modules) do
    HomeTab:CreateLabel(mod.label .. ": " .. (Runtime.ModuleStatus[mod.label] or "Chua load"))
end

HomeTab:CreateSection("Điều khiển")
HomeTab:CreateButton({
    Name = "📣 Báo lại trạng thái",
    Callback = function()
        Hub.Helpers.Notify("Saloi Hub", "Da nap " .. tostring(loadedCount) .. "/" .. tostring(#modules) .. " module.", 5)
    end,
})

HomeTab:CreateButton({
    Name = "❌ TẮT HẲN SCRIPT (XÓA)",
    Callback = function()
        Library:Destroy()
    end,
})

Hub.Helpers.Notify("Saloi Hub", "Khoi dong xong. Da nap " .. tostring(loadedCount) .. "/" .. tostring(#modules) .. " module.", 5)
