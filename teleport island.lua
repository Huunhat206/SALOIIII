local Window, Library = ...

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local env = getgenv and getgenv() or _G
env.SALOI_HUB = env.SALOI_HUB or {}

local Hub = env.SALOI_HUB
Hub.State = Hub.State or {}
Hub.Helpers = Hub.Helpers or {}

local State = Hub.State
State.SelectedIsland = State.SelectedIsland or "Starter Island"

-- Icons (Sử dụng bộ icon Unicode để đồng nhất với theme)
local Icons = {
    Map = "🗺",      -- World Map
    Search = "⌕",    -- Search
    Teleport = "⚡",  -- Zap
    Island = "🏝",   -- Island
    Success = "✓",
    Error = "✕",
    Info = "ⓘ"
}

-- Helper Notification
local function notify(title, content, duration, notifType)
    if Hub.Helpers.Notify then
        Hub.Helpers.Notify(title, content, duration or 4, notifType)
    else
        pcall(function()
            Library:Notify({
                Title = title,
                Content = content,
                Duration = duration or 4,
                Type = notifType or "info"
            })
        end)
    end
end

-- Bypass Teleport Logic (Tối ưu hóa)
local function bypassTeleport(targetCFrame)
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    -- Reset Velocity & Anchor
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.Anchored = true

    -- Bypass Dash
    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    local dashRemote = remoteEvents and remoteEvents:FindFirstChild("DashRemote")
    
    if dashRemote then
        local direction = (targetCFrame.Position - hrp.Position).Unit
        pcall(function() dashRemote:FireServer(Vector3.new(direction.X, 0, direction.Z), 33, false) end)
    end

    -- Teleport
    hrp.CFrame = targetCFrame
    task.wait(0.15)

    if dashRemote then
        pcall(function() dashRemote:FireServer(Vector3.new(0, 0, 1), 33, false) end)
    end

    hrp.CFrame = targetCFrame
    task.wait(0.05)
    hrp.Anchored = false
    return true
end

-- Data Islands
local islandMap = {
    ["Starter Island"] = "StarterIsland",
    ["Jungle Island"] = "JungleIsland",
    ["Desert Island"] = "DesertIsland",
    ["Snow Island"] = "SnowIsland",
    ["Sailor Island"] = "SailorIsland",
    ["Shibuya Station"] = "ShibuyaStation",
    ["Hollow Island"] = "HollowIsland",
    ["Boss Island"] = "BossIsland",
    ["Dungeon Island"] = "DungeonIsland",
    ["Shinjuku Island"] = "ShinjukuIsland",
    ["Slime Island"] = "SlimeIsland",
    ["Academy Island"] = "AcademyIsland",
    ["Judgement Island"] = "JudgementIsland",
    ["Soul Dominion"] = "SoulDominionIsland",
    ["Ninja Island"] = "NinjaIsland",
    ["Lawless Island"] = "LawlessIsland",
    ["Tower Island"] = "TowerIsland",
    ["Easter Island"] = "EasterIsland",
    ["World Island"] = "WorldIsland",
}

local islandList = {}
for name in pairs(islandMap) do table.insert(islandList, name) end
table.sort(islandList)

-- Validate State
if not table.find(islandList, State.SelectedIsland) then
    State.SelectedIsland = "Starter Island"
end

-- Find Island CFrame (Logic tìm kiếm thông minh hơn)
local function findIslandCFrame(folderName)
    local container = Workspace:FindFirstChild(folderName)
    if not container then return nil end

    -- Ưu tiên tìm Spawn Point
    for _, desc in ipairs(container:GetDescendants()) do
        if string.find(string.lower(desc.Name), "spawn", 1, true) then
            if desc:IsA("BasePart") then return desc.CFrame end
            if desc:IsA("Model") then return desc:GetPivot() end
        end
    end

    -- Fallback: Lấy vị trí model hoặc part đầu tiên
    if container:IsA("Model") then return container:GetPivot() end
    for _, desc in ipairs(container:GetDescendants()) do
        if desc:IsA("BasePart") then return desc.CFrame end
    end
    
    return nil
end

-- UI Construction
local Tab = Window:CreateTab("Teleport", Icons.Map)

Tab:CreateParagraph({
    Title = "Island Teleport",
    Content = "Hệ thống dịch chuyển tức thời sử dụng Bypass Dash để chống lag và rubbebanding. Chọn đảo từ danh sách hoặc tìm kiếm nhanh."
})

Tab:CreateSection("Island Selection")

-- Search Input
Tab:CreateInput({
    Name = "Search Island",
    PlaceholderText = "Type to filter...",
    Icon = Icons.Search,
    Callback = function(text)
        local filtered = {}
        local keyword = string.lower(text or "")
        
        for _, islandName in ipairs(islandList) do
            if keyword == "" or string.find(string.lower(islandName), keyword, 1, true) then
                table.insert(filtered, islandName)
            end
        end
        
        if #filtered == 0 then
            filtered = {"No Results"}
        end

        IslandDropdown:Refresh(filtered, false)
    end
})

-- Dropdown
local IslandDropdown = Tab:CreateDropdown({
    Name = "Select Destination",
    Options = islandList,
    CurrentOption = { State.SelectedIsland },
    Icon = Icons.Island,
    Callback = function(option)
        local selected = type(option) == "table" and option[1] or option
        if selected and selected ~= "No Results" then
            State.SelectedIsland = selected
        end
    end
})

-- Teleport Button
Tab:CreateButton({
    Name = "Instant Teleport",
    Icon = Icons.Teleport,
    Callback = function()
        local folderName = islandMap[State.SelectedIsland]
        if not folderName then
            notify("Error", "Vui lòng chọn đảo hợp lệ.", 3, "error")
            return
        end

        notify("Teleport", "Đang di chuyển đến: " .. State.SelectedIsland, 3, "info")
        
        local cframe = findIslandCFrame(folderName)
        if cframe then
            local success = bypassTeleport(cframe + Vector3.new(0, 5, 0)) -- Cộng thêm 5 stud độ cao để tránh kẹt
            if success then
                notify("Success", "Đã đến: " .. State.SelectedIsland, 3, "success")
            else
                notify("Error", "Dịch chuyển thất bại (Character lỗi).", 3, "error")
            end
        else
            notify("Error", "Không tìm thấy vị trí đảo: " .. tostring(folderName), 4, "error")
        end
    end
})

Tab:CreateLabel("Hỗ trợ " .. tostring(#islandList) .. " đảo.")
