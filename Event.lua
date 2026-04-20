local Window, Library = ...

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Environment
local env = getgenv and getgenv() or _G
env.SALOI_HUB = env.SALOI_HUB or {}
local Hub = env.SALOI_HUB
Hub.State = Hub.State or {}
Hub.Helpers = Hub.Helpers or {}
Hub.Runtime = Hub.Runtime or {}

local State = Hub.State
State.AutoEaster = State.AutoEaster or false
local Runtime = Hub.Runtime

-- Icons
local Icons = {
    Egg = "🥚",
    Loop = "🔄",
    Check = "✅",
    Cross = "✕",
    Zap = "⚡"
}

-- Helper: Notify
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

-- Helper: Connection Manager
local function replaceConnection(key, connection)
    if Hub.Helpers.ReplaceConnection then return Hub.Helpers.ReplaceConnection(key, connection) end
    Runtime[key] = Runtime[key] or {}
    local previous = Runtime[key].Connection
    if previous then pcall(function() previous:Disconnect() end) end
    Runtime[key].Connection = connection
    return connection
end

-- Helper: Bypass Teleport
local function bypassTeleport(targetCFrame)
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local delta = targetCFrame.Position - hrp.Position
    local direction = delta.Magnitude > 1 and delta.Unit or Vector3.new(0, 0, 1)

    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    local dashRemote = remoteEvents and remoteEvents:FindFirstChild("DashRemote")

    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.Anchored = true

    if dashRemote then
        pcall(function() dashRemote:FireServer(Vector3.new(direction.X, 0, direction.Z), 33, false) end)
    end

    hrp.CFrame = targetCFrame
    task.wait(0.15)

    if dashRemote then
        pcall(function() dashRemote:FireServer(Vector3.new(direction.X, 0, direction.Z), 33, false) end)
    end

    hrp.CFrame = targetCFrame
    task.wait(0.05)
    hrp.Anchored = false
    return true
end

-- Logic: Egg Scanner
local function getEggTarget(item)
    local targetCFrame = nil
    if item:IsA("Model") then
        targetCFrame = item:GetPivot()
    elseif item:IsA("BasePart") then
        targetCFrame = item.CFrame
    end

    if not targetCFrame then return nil, nil end

    local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
    local isEggNamed = string.find(string.lower(item.Name), "egg", 1, true) ~= nil

    if prompt or isEggNamed then
        return targetCFrame, prompt
    end
    return nil, nil
end

-- Logic: Collect Logic
local function collectEgg(item)
    local targetCFrame, prompt = getEggTarget(item)
    if not targetCFrame then return false end

    -- Teleport
    bypassTeleport(targetCFrame + Vector3.new(0, 3, 0))
    task.wait(0.1)

    -- Interact
    if prompt and fireproximityprompt then
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(prompt.HoldDuration + 0.1)
    else
        -- Nếu không có prompt, chờ một chút để server sync
        task.wait(0.25)
    end
    return true
end

-- UI Construction
local Tab = Window:CreateTab("Event", Icons.Egg)

Tab:CreateParagraph({
    Title = "Event Tools",
    Content = "Hỗ trợ tự động thu thập trứng sự kiện (Easter Eggs) trong workspace. Bật Auto Farm để tự động tìm kiếm liên tục."
})

Tab:CreateSection("Easter Event")

Tab:CreateButton({
    Name = "Collect All Eggs (One-time)",
    Icon = Icons.Check,
    Callback = function()
        local easterEggsFolder = workspace:FindFirstChild("EasterEggs")
        if not easterEggsFolder then
            notify("Event", "Không tìm thấy folder EasterEggs.", 4, "error")
            return
        end

        local collected = 0
        local items = easterEggsFolder:GetDescendants()
        
        for _, item in ipairs(items) do
            if getEggTarget(item) then
                collectEgg(item)
                collected = collected + 1
            end
        end

        if collected > 0 then
            notify("Event", string.format("Đã thu thập %d trứng.", collected), 4, "success")
        else
            notify("Event", "Không tìm thấy trứng nào.", 4, "info")
        end
    end
})

Tab:CreateToggle({
    Name = "Auto Farm Eggs (Loop)",
    CurrentValue = State.AutoEaster,
    Icon = Icons.Loop,
    Callback = function(value)
        State.AutoEaster = value
        
        if value then
            notify("Event", "Bắt đầu Auto Farm Eggs...", 3, "info")
            task.spawn(function()
                while State.AutoEaster do
                    local easterEggsFolder = workspace:FindFirstChild("EasterEggs")
                    if easterEggsFolder then
                        for _, item in ipairs(easterEggsFolder:GetDescendants()) do
                            if not State.AutoEaster then break end -- Stop nếu tắt toggle
                            if getEggTarget(item) then
                                collectEgg(item)
                            end
                        end
                    end
                    task.wait(1) -- Chờ 1 giây trước khi quét lại
                end
            end)
        else
            notify("Event", "Đã dừng Auto Farm Eggs.", 3, "info")
        end
    end
})

Tab:CreateLabel("Lưu ý: Tính năng Loop sẽ tự động nhặt trứng mới xuất hiện.")
