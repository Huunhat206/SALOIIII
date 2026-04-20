local Window, Library = ...

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
State.SelectedNPC = State.SelectedNPC or "None"
State.AutoHitClosest = State.AutoHitClosest or false
State.HitDistance = State.HitDistance or 250
State.FarmOffset = State.FarmOffset or 3

local Runtime = Hub.Runtime
local Helpers = Hub.Helpers

-- HÀM ANTI-RUBBERBAND CHO AUTOFARM
local function bypassInstantTeleport(targetCFrame)
    local character = LocalPlayer.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end

    local delta = targetCFrame.Position - humanoidRootPart.Position
    local direction = delta.Magnitude > 1 and delta.Unit or Vector3.new(0, 0, 1)

    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    local dashRemote = remoteEvents and remoteEvents:FindFirstChild("DashRemote")
    local args = { Vector3.new(direction.X, 0, direction.Z), 33, false }

    humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
    humanoidRootPart.Anchored = true

    if dashRemote then pcall(function() dashRemote:FireServer(table.unpack(args)) end) end
    
    humanoidRootPart.CFrame = targetCFrame
    task.wait(0.15)
    
    if dashRemote then pcall(function() dashRemote:FireServer(table.unpack(args)) end) end
    
    humanoidRootPart.CFrame = targetCFrame
    task.wait(0.05)
    humanoidRootPart.Anchored = false
    return true
end

local function notify(title, content, duration)
    if Helpers.Notify then
        Helpers.Notify(title, content, duration)
        return
    end
    pcall(function() Library:Notify({Title = title, Content = content, Duration = duration or 4}) end)
end

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

local function getBaseName(name)
    local baseName = string.gsub(name, "%d+$", "")
    return string.match(baseName, "^%s*(.-)%s*$")
end

local function getNPCFolder() return workspace:FindFirstChild("NPCs") end

local function getNPCList()
    local names, seen = {}, {}
    local npcFolder = getNPCFolder()
    if npcFolder then
        for _, npc in ipairs(npcFolder:GetChildren()) do
            if npc:IsA("Model") then
                local baseName = getBaseName(npc.Name)
                if baseName ~= "" and not seen[baseName] then
                    seen[baseName] = true
                    table.insert(names, baseName)
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

local function findClosestTargetByName(targetName, originPosition)
    local npcFolder = getNPCFolder()
    if not npcFolder then return nil end
    local closestRoot
    local closestDistance = math.huge
    for _, npc in ipairs(npcFolder:GetChildren()) do
        if npc:IsA("Model") and getBaseName(npc.Name) == targetName then
            local root = getValidRoot(npc)
            if root then
                local distance = (root.Position - originPosition).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestRoot = root
                end
            end
        end
    end
    return closestRoot
end

local function findClosestAliveNPC(originPosition, maxDistance)
    local npcFolder = getNPCFolder()
    if not npcFolder then return nil end
    local closestRoot
    local closestDistance = maxDistance or math.huge
    for _, npc in ipairs(npcFolder:GetChildren()) do
        if npc:IsA("Model") then
            local root = getValidRoot(npc)
            if root then
                local distance = (root.Position - originPosition).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestRoot = root
                end
            end
        end
    end
    return closestRoot
end

local function getDropdownValue(option)
    return type(option) == "table" and option[1] or option
end

local fullNPCList = getNPCList()
local initialNPC = State.SelectedNPC
local hasInitialNPC = false

for _, npcName in ipairs(fullNPCList) do
    if npcName == initialNPC then hasInitialNPC = true break end
end
if not hasInitialNPC then
    initialNPC = fullNPCList[1] or "None"
    State.SelectedNPC = initialNPC
end

local AutoFarmTab = Window:CreateTab("⚔️ Auto Farm")
local NPCDropdown

AutoFarmTab:CreateParagraph({
    Title = "Farm Hub",
    Content = "Chon quai theo ten de farm on dinh hoac bat Kill Aura de danh mob gan nhat.",
})

AutoFarmTab:CreateSection("Target Farm")

AutoFarmTab:CreateInput({
    Name = "🔎 Tim NPC",
    PlaceholderText = "Nhap ten quai...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local filtered = {}
        local keyword = string.lower(text or "")
        if keyword == "" then
            filtered = fullNPCList
        else
            for _, npcName in ipairs(fullNPCList) do
                if string.find(string.lower(npcName), keyword, 1, true) then
                    table.insert(filtered, npcName)
                end
            end
        end
        if #filtered == 0 then filtered[1] = "Không tìm thấy" end
        if NPCDropdown then NPCDropdown:Refresh(filtered, true) end
    end,
})

NPCDropdown = AutoFarmTab:CreateDropdown({
    Name = "🎯 Chon muc tieu",
    Options = fullNPCList,
    CurrentOption = { initialNPC },
    MultipleOptions = false,
    Flag = "SALOI_SelectedNPC",
    Callback = function(option)
        local selected = getDropdownValue(option)
        if selected and selected ~= "Không tìm thấy" then State.SelectedNPC = selected end
    end,
})

AutoFarmTab:CreateButton({
    Name = "🔄 Tai lai danh sach NPC",
    Callback = function()
        fullNPCList = getNPCList()
        if NPCDropdown then NPCDropdown:Refresh(fullNPCList, true) end
        if State.SelectedNPC ~= "None" then
            local found = false
            for _, npcName in ipairs(fullNPCList) do
                if npcName == State.SelectedNPC then found = true break end
            end
            if not found then State.SelectedNPC = "None" end
        end
        notify("Auto Farm", "Da cap nhat danh sach NPC.", 4)
    end,
})

AutoFarmTab:CreateToggle({
    Name = "⚡ Bat Auto Farm",
    CurrentValue = State.AutoFarm,
    Flag = "SALOI_AutoFarm",
    Callback = function(value) State.AutoFarm = value end,
})

AutoFarmTab:CreateSlider({
    Name = "📍 Do lech dung farm",
    Range = { 2, 8 },
    Increment = 1,
    Suffix = " Studs",
    CurrentValue = State.FarmOffset,
    Flag = "SALOI_FarmOffset",
    Callback = function(value) State.FarmOffset = value end,
})

AutoFarmTab:CreateSection("Kill Aura")

AutoFarmTab:CreateToggle({
    Name = "⚔️ Auto Hit Closest Mob",
    CurrentValue = State.AutoHitClosest,
    Flag = "SALOI_AutoHitClosest",
    Callback = function(value) State.AutoHitClosest = value end,
})

AutoFarmTab:CreateSlider({
    Name = "📏 Hit Distance",
    Range = { 25, 500 },
    Increment = 5,
    Suffix = " Studs",
    CurrentValue = State.HitDistance,
    Flag = "SALOI_HitDistance",
    Callback = function(value) State.HitDistance = value end,
})

-- LOGIC AUTO HIT (MICRO-STUTTER)
local auraToken = bumpToken("AutoFarm_Aura")
replaceConnection("AutoFarm_Aura", RunService.Heartbeat:Connect(function()
    if not isTokenActive("AutoFarm_Aura", auraToken) or not State.AutoHitClosest then return end

    local character = LocalPlayer.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    local targetRoot = findClosestAliveNPC(humanoidRootPart.Position, State.HitDistance)
    if not targetRoot then return end

    local oldCFrame = humanoidRootPart.CFrame
    humanoidRootPart.CFrame = targetRoot.CFrame * CFrame.new(0, 0, State.FarmOffset)
    requestHit()
    humanoidRootPart.CFrame = oldCFrame
end))

-- LOGIC AUTO FARM (SMART DISTANCE CHECK)
local farmToken = bumpToken("AutoFarm_Loop")
task.spawn(function()
    while isTokenActive("AutoFarm_Loop", farmToken) do
        if State.AutoFarm then
            local character = LocalPlayer.Character
            local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

            if humanoidRootPart then
                local targetRoot
                if State.SelectedNPC and State.SelectedNPC ~= "None" then
                    targetRoot = findClosestTargetByName(State.SelectedNPC, humanoidRootPart.Position)
                else
                    targetRoot = findClosestAliveNPC(humanoidRootPart.Position)
                end

                if targetRoot then
                    local targetCF = targetRoot.CFrame * CFrame.new(0, 0, State.FarmOffset)
                    local dist = (humanoidRootPart.Position - targetCF.Position).Magnitude
                    
                    if dist > 50 then
                        -- Xa quá thì xài Bypass Dash để khỏi bị tele ngược
                        bypassInstantTeleport(targetCF)
                    else
                        -- Ở gần thì cứ thế mà bám đuôi chém
                        humanoidRootPart.CFrame = targetCF
                        requestHit()
                    end
                end
            end
        end
        task.wait(0.12)
    end
end)
