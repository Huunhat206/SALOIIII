--[[
    HNHAT HUB - PREMIUM UI REDESIGN
    Style: Solix Hub Inspired
]]

repeat wait() until game:IsLoaded()

local cloneref = cloneref or function(o) return o end
local CoreGui = cloneref(game:GetService("CoreGui"))
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Players = cloneref(game:GetService("Players") )
local LocalPlayer = Players.LocalPlayer
local HttpService = cloneref(game:GetService("HttpService"))

local Library = {
    Tabs = {},
    Elements = {},
    Theme = {
        ["Background"] = Color3.fromRGB(15, 12, 16),
        ["Inline"] = Color3.fromRGB(22, 20, 24),
        ["Border"] = Color3.fromRGB(41, 37, 45),
        ["Accent"] = Color3.fromRGB(232, 186, 248), -- Màu tím Solix
        ["Text"] = Color3.fromRGB(255, 255, 255),
        ["Inactive Text"] = Color3.fromRGB(185, 185, 185)
    }
}

-- ==========================================
-- HÀM TẠO INSTANCE NHANH (Inspired by Solix)
-- ==========================================
local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    return inst
end

-- ==========================================
-- HỆ THỐNG THÔNG BÁO (NOTIFICATION)
-- ==========================================
function Library:Notify(data)
    local title = data.Title or "HNHAT HUB"
    local desc = data.Content or ""
    local duration = data.Duration or 5

    -- Logic hiển thị Notification (Giống hệt Solix)
    warn("Notification: " .. title .. " - " .. desc)
    -- Phần này có thể tích hợp thêm Rayfield:Notify hoặc UI Notification tự chế
end

-- ==========================================
-- GIAO DIỆN CHÍNH (MAIN UI)
-- ==========================================
function Library:CreateWindow(title, subtitle)
    local ScreenGui = Create("ScreenGui", {
        Name = "HnhatHub_Premium",
        Parent = CoreGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Global
    })

    -- Hiệu ứng Blur nền
    local Blur = Create("BlurEffect", {
        Parent = game:GetService("Lighting"),
        Size = 0
    })
    TweenService:Create(Blur, TweenInfo.new(0.5), {Size = 20}):Play()

    -- Khung chính
    local MainFrame = Create("Frame", {
        Name = "MainFrame",
        Parent = ScreenGui,
        Size = UDim2.new(0, 580, 0, 380),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = self.Theme.Background,
        BackgroundTransparency = 0.1,
        ClipsDescendants = true
    })

    Create("UICorner", { Parent = MainFrame, CornerRadius = UDim.new(0, 10) })
    Create("UIStroke", {
        Parent = MainFrame,
        Color = self.Theme.Border,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    })

    -- Header (Tiêu đề)
    local Header = Create("Frame", {
        Name = "Header",
        Parent = MainFrame,
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 1
    })

    local TitleLabel = Create("TextLabel", {
        Parent = Header,
        Text = title,
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 20, 0, 15),
        TextColor3 = self.Theme.Accent,
        TextSize = 24,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1
    })

    -- Sidebar (Chứa các Tab)
    local Sidebar = Create("ScrollingFrame", {
        Name = "Sidebar",
        Parent = MainFrame,
        Size = UDim2.new(0, 160, 1, -70),
        Position = UDim2.new(0, 10, 0, 60),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })

    Create("UIListLayout", { Parent = Sidebar, Padding = UDim.new(0, 5) })

    -- Container (Chứa nội dung Tab)
    local Container = Create("Frame", {
        Name = "Container",
        Parent = MainFrame,
        Size = UDim2.new(1, -190, 1, -70),
        Position = UDim2.new(0, 180, 0, 60),
        BackgroundColor3 = self.Theme.Inline,
        BackgroundTransparency = 0.5
    })
    Create("UICorner", { Parent = Container, CornerRadius = UDim.new(0, 8) })

    -- Làm UI có thể kéo được
    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; startPos = MainFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    -- Hàm tạo Tab
    local Window = {}
    function Window:CreateTab(name, iconId)
        local TabButton = Create("TextButton", {
            Parent = Sidebar,
            Size = UDim2.new(1, -10, 0, 35),
            BackgroundColor3 = Library.Theme.Element,
            BackgroundTransparency = 1,
            Text = "  " .. name,
            TextColor3 = Library.Theme["Inactive Text"],
            TextSize = 14,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false
        })
        Create("UICorner", { Parent = TabButton, CornerRadius = UDim.new(0, 6) })

        local Page = Create("ScrollingFrame", {
            Parent = Container,
            Size = UDim2.new(1, -10, 1, -10),
            Position = UDim2.new(0, 5, 0, 5),
            Visible = false,
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Library.Theme.Accent,
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        })
        Create("UIListLayout", { Parent = Page, Padding = UDim.new(0, 8) })
        Create("UIPadding", { Parent = Page, PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5) })

        TabButton.MouseButton1Click:Connect(function()
            for _, v in pairs(Container:GetChildren()) do if v:IsA("ScrollingFrame") then v.Visible = false end end
            for _, v in pairs(Sidebar:GetChildren()) do 
                if v:IsA("TextButton") then 
                    TweenService:Create(v, TweenInfo.new(0.2), {TextColor3 = Library.Theme["Inactive Text"], BackgroundTransparency = 1}):Play()
                end 
            end
            Page.Visible = true
            TweenService:Create(TabButton, TweenInfo.new(0.2), {TextColor3 = Library.Theme.Accent, BackgroundTransparency = 0.8}):Play()
        end)

        -- Hàm tạo các Element (Toggle, Button, Slider)
        local Tab = {}
        
        function Tab:CreateToggle(data)
            local toggle = Create("TextButton", {
                Parent = Page,
                Size = UDim2.new(1, -10, 0, 40),
                BackgroundColor3 = Color3.fromRGB(30, 27, 33),
                Text = "  " .. data.Name,
                TextColor3 = Library.Theme.Text,
                TextSize = 14,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false
            })
            Create("UICorner", { Parent = toggle, CornerRadius = UDim.new(0, 6) })
            
            local box = Create("Frame", {
                Parent = toggle,
                Size = UDim2.new(0, 20, 0, 20),
                Position = UDim2.new(1, -30, 0.5, -10),
                BackgroundColor3 = Color3.fromRGB(50, 45, 55)
            })
            Create("UICorner", { Parent = box, CornerRadius = UDim.new(0, 4) })

            local enabled = data.CurrentValue or false
            local function update()
                TweenService:Create(box, TweenInfo.new(0.2), {BackgroundColor3 = enabled and Library.Theme.Accent or Color3.fromRGB(50, 45, 55)}):Play()
                data.Callback(enabled)
            end
            toggle.MouseButton1Click:Connect(function() enabled = not enabled; update() end)
            return toggle
        end

        function Tab:CreateButton(data)
            local btn = Create("TextButton", {
                Parent = Page,
                Size = UDim2.new(1, -10, 0, 40),
                BackgroundColor3 = Color3.fromRGB(35, 32, 40),
                Text = data.Name,
                TextColor3 = Library.Theme.Text,
                TextSize = 14,
                Font = Enum.Font.GothamSemibold
            })
            Create("UICorner", { Parent = btn, CornerRadius = UDim.new(0, 6) })
            btn.MouseButton1Click:Connect(data.Callback)
        end

        function Tab:CreateSection(name)
            local txt = Create("TextLabel", {
                Parent = Page,
                Size = UDim2.new(1, 0, 0, 25),
                Text = name:upper(),
                TextColor3 = Library.Theme.Accent,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                BackgroundTransparency = 1,
                TextXAlignment = Enum.TextXAlignment.Left
            })
        end

        return Tab
    end
    
    return Window
end

-- ==========================================
-- KHỞI CHẠY HUB
-- ==========================================
local Window = Library:CreateWindow("HNHAT HUB", "Solix Edition")

-- Load các module
local repoUrl = "https://raw.githubusercontent.com/Huunhat206/SALOIIII/main/"

local function loadModule(name)
    local success, err = pcall(function()
        loadstring(game:HttpGet(repoUrl .. name .. "?v=" .. tostring(tick()))) (Window, Library)
    end)
    if not success then warn("Lỗi load module: " .. name .. " -> " .. err) end
end

loadModule("Autofarm.lua")
loadModule("Event.lua")
loadModule("teleport%20island.lua")

Library:Notify({Title = "Success", Content = "Hnhat Hub Loaded Successfully!", Duration = 5})
