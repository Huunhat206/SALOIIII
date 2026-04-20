local Window, Library = ...

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local env = getgenv and getgenv() or _G
env.SALOI_HUB = env.SALOI_HUB or {}

local Hub = env.SALOI_HUB
Hub.State = Hub.State or {}
Hub.Runtime = Hub.Runtime or {}
Hub.Helpers = Hub.Helpers or {}

local State = Hub.State
State.AutoFarm = State.AutoFarm or false
State.AutoHitClosest = State.AutoHitClosest or false
State.HitDistance = State.HitDistance or 250
State.FarmOffset = State.FarmOffset or 3
State.FarmPriorityList = State.FarmPriorityList or {} -- Danh sách NPC ưu tiên (Table)

local Runtime = Hub.Runtime
local Helpers = Hub.Helpers

-- Icons
local Icons = {
    Farm = "🌾",
    Target = "🎯",
    Search = "⌕",
    Refresh = "↻",
    Sword = "⚔",
    Range = "📏",
    Zap = "⚡",
    List = "☰"
}

-- Helper Notification
local function notify(title, content, duration, notifType)
    if Helpers.Notify then
        Helpers.Notify(title, content, duration or 4, notifType)
    else
        pcall(function()
            Library:Notify({ Title = title, Content = content, Duration = duration or 4, Type = notifType or "info" })
        end)
    end
end

-- Anti-Rubberband Teleport
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

-- Connection & Token Management
local function replaceConnection(key, connection)
    if Helpers.ReplaceConnection then return Helpers.ReplaceConnection(key, connection) end
    Runtime[key] = Runtime[key] or {}
    local previous = Runtime[key].Connection
    if previous then pcall(function() previous:Disconnect() end) end
    Runtime[key].Connection = connection
    return connection
end

local function bumpToken(key)
    if Helpers.BumpToken then return Helpers.BumpToken(key) end
    Runtime.Tokens = Runtime.Tokens or {}
    Runtime.Tokens[key] = (Runtime.Tokens[key] or 0) + 1
    return Runtime.Tokens[key]
end

local function isTokenActive(key, token)
    if Helpers.IsTokenActive then return Helpers.IsTokenActive(key, token) end
    Runtime.Tokens = Runtime.Tokens or {}
    return Runtime.Tokens[key] == token
end

-- NPC Functions
local function getBaseName(name)
    return string.match(string.gsub(name, "%d+$", ""), "^%s*(.-)%s*$") or ""
end

local function getNPCFolder() return workspace:FindFirstChild("NPCs") end

local function getNPCList()
    local names, seen = {}, {}
    local npcFolder = getNPCFolder()
    if npcFolder then
        for _, npc in ipairs(npcFolder:GetChildren()) do
            if npc:IsA("Model") then
                local base = getBaseName(npc.Name)
                if base ~= "" and not seen[base] then
                    seen[base] = true
                    table.insert(names, base)
                end
            end
        end
    end
    table.sort(names)
    if #names == 0 then names[1] = "None" end
    return names
end

local function getHitRemote()
    local combatSystem = ReplicatedStorage:FindFirstChild("CombatSystem")
    local remotes = combatSystem and combatSystem:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("RequestHit")
end

local function requestHit()
    local remote = getHitRemote()
    if remote then pcall(function() remote:FireServer() end) end
end

local function getValidRoot(npc)
    local root = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    if not root or (humanoid and humanoid.Health <= 0) then return nil end
    return root
end

-- Tìm mục tiêu gần nhất từ danh sách ưu tiên (Nhiều NPC)
local function findTargetFromList(priorityList, originPosition)
    local npcFolder = getNPCFolder()
    if not npcFolder then return nil end
    
    -- Tạo dictionary để tra cứu nhanh O(1)
    local targetMap = {}
    for _, name in ipairs(priorityList) do targetMap[name] = true end

    local closestRoot, closestDistance = nil, math.huge
    
    for _, npc in ipairs(npcFolder:GetChildren()) do
        if npc:IsA("Model") then
            local baseName = getBaseName(npc.Name)
            -- Kiểm tra xem NPC này có nằm trong danh sách ưu tiên không
            if targetMap[baseName] then
                local root = getValidRoot(npc)
                if root then
                    local dist = (root.Position - originPosition).Magnitude
                    if dist < closestDistance then
                        closestDistance = dist
                        closestRoot = root
                    end
                end
            end
        end
    end
    return closestRoot
end

-- Tìm mục tiêu sống gần nhất (Kill Aura)
local function findClosestAliveNPC(originPosition, maxDistance)
    local npcFolder = getNPCFolder()
    if not npcFolder then return nil end
    local closestRoot, closestDistance = nil, maxDistance or math.huge
    
    for _, npc in ipairs(npcFolder:GetChildren()) do
        if npc:IsA("Model") then
            local root = getValidRoot(npc)
            if root then
                local dist = (root.Position - originPosition).Magnitude
                if dist < closestDistance then
                    closestDistance = dist
                    closestRoot = root
                end
            end
        end
    end
    return closestRoot
end

-- Logic Setup
local fullNPCList = getNPCList()

-- UI Construction
local Tab = Window:CreateTab("Auto Farm", Icons.Farm)

Tab:CreateParagraph({
    Title = "Smart Farm System",
    Content = "Hỗ trợ chọn nhiều mục tiêu cùng lúc. Kích hoạt Kill Aura để tự động đánh quái xung quanh hoặc chọn danh sách cụ thể để Farm."
})

Tab:CreateSection("Target Selection")

-- Input Search
Tab:CreateInput({
    Name = "Search NPC",
    PlaceholderText = "Filter names...",
    Icon = Icons.Search,
    Callback = function(text)
        local filtered = {}
        local keyword = string.lower(text or "")
        for _, npcName in ipairs(fullNPCList) do
            if keyword == "" or string.find(string.lower(npcName), keyword, 1, true) then
                table.insert(filtered, npcName)
            end
        end
        if #filtered == 0 then filtered = {"No Results"} end
        if NPCDropdown then NPCDropdown:Refresh(filtered, false) end
    end
})

-- Dropdown (Multiselect)
NPCDropdown = Tab:CreateDropdown({
    Name = "Select Targets",
    Options = fullNPCList,
    CurrentOption = State.FarmPriorityList, -- Truyền table danh sách đã chọn
    MultipleOptions = true, -- BẬT CHẾ ĐỘ MULTISELECT
    Icon = Icons.Target,
    Callback = function(option)
        -- Callback trả về table các giá trị đang được chọn
        State.FarmPriorityList = option
    end
})

Tab:CreateButton({
    Name = "Reload NPC List",
    Icon = Icons.Refresh,
    Callback = function()
        fullNPCList = getNPCList()
        if NPCDropdown then NPCDropdown:Refresh(fullNPCList, false) end
        notify("Auto Farm", "NPC List Refreshed!", 3, "success")
    end
})

Tab:CreateSection("Farm Settings")

Tab:CreateToggle({
    Name = "Enable Auto Farm",
    CurrentValue = State.AutoFarm,
    Icon = Icons.Zap,
    Callback = function(value) State.AutoFarm = value end
})

Tab:CreateSlider({
    Name = "Stand Offset",
    Range = { 2, 10 },
    Increment = 1,
    Suffix = " Studs",
    CurrentValue = State.FarmOffset,
    Callback = function(value) State.FarmOffset = value end
})

Tab:CreateSection("Combat Settings")

Tab:CreateToggle({
    Name = "Auto Hit Closest (Kill Aura)",
    CurrentValue = State.AutoHitClosest,
    Icon = Icons.Sword,
    Callback = function(value) State.AutoHitClosest = value end
})

Tab:CreateSlider({
    Name = "Hit Distance",
    Range = { 25, 500 },
    Increment = 5,
    Suffix = " Studs",
    CurrentValue = State.HitDistance,
    Callback = function(value) State.HitDistance = value end
})

-- MAIN LOGIC LOOPS

-- Kill Aura Loop (Micro-stutter for hit)
local auraToken = bumpToken("AutoFarm_Aura")
replaceConnection("AutoFarm_Aura", RunService.Heartbeat:Connect(function()
    if not isTokenActive("AutoFarm_Aura", auraToken) or not State.AutoHitClosest then return end

    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local target = findClosestAliveNPC(hrp.Position, State.HitDistance)
    if target then
        local oldCFrame = hrp.CFrame
        -- Teleport tạm thời để hit
        hrp.CFrame = target.CFrame * CFrame.new(0, 0, State.FarmOffset)
        requestHit()
        -- Teleport về ngay lập tức (trong cùng frame)
        hrp.CFrame = oldCFrame
    end
end))

-- Auto Farm Loop (Smart Movement)
local farmToken = bumpToken("AutoFarm_Loop")
task.spawn(function()
    while isTokenActive("AutoFarm_Loop", farmToken) do
        if State.AutoFarm then
            local character = LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")

            if hrp then
                local targetRoot
                
                -- Logic: Nếu có danh sách ưu tiên -> Tìm trong danh sách. Nếu không -> Tìm cái gần nhất.
                if #State.FarmPriorityList > 0 then
                    targetRoot = findTargetFromList(State.FarmPriorityList, hrp.Position)
                else
                    -- Nếu không chọn NPC nào, tự động farm quái gần nhất (fallback)
                    targetRoot = findClosestAliveNPC(hrp.Position)
                end

                if targetRoot then
                    local targetCF = targetRoot.CFrame * CFrame.new(0, 0, State.FarmOffset)
                    local dist = (hrp.Position - targetCF.Position).Magnitude
                    
                    if dist > 50 then
                        -- Xa quá: Dùng Bypass Dash
                        bypassTeleport(targetCF)
                    else
                        -- Gần: Teleport thường
                        hrp.CFrame = targetCF
                        requestHit()
                    end
                end
            end
        end
        task.wait(0.1) -- Loop interval
    end
end)




