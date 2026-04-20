local Window, Library = ...

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local env = getgenv and getgenv() or _G
env.SALOI_HUB = env.SALOI_HUB or {}

local Hub = env.SALOI_HUB
Hub.State = Hub.State or {}
Hub.Helpers = Hub.Helpers or {}

local State = Hub.State
State.SelectedIsland = State.SelectedIsland or "Starter Island"

local Helpers = Hub.Helpers

local function notify(title, content, duration)
    if Helpers.Notify then
        Helpers.Notify(title, content, duration)
        return
    end

    pcall(function()
        Library:Notify({
            Title = title,
            Content = content,
            Duration = duration or 4,
        })
    end)
end

local function bypassInstantTeleport(targetCFrame)
    local character = LocalPlayer.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return false
    end

    local delta = targetCFrame.Position - humanoidRootPart.Position
    local direction = delta.Magnitude > 1 and delta.Unit or Vector3.new(0, 0, 1)
    local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    local dashRemote = remoteEvents and remoteEvents:FindFirstChild("DashRemote")
    local args = { Vector3.new(direction.X, 0, direction.Z), 33, false }

    humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
    humanoidRootPart.Anchored = true

    if dashRemote then
        pcall(function()
            dashRemote:FireServer(table.unpack(args))
        end)
    end

    humanoidRootPart.CFrame = targetCFrame
    task.wait(0.15)

    if dashRemote then
        pcall(function()
            dashRemote:FireServer(table.unpack(args))
        end)
    end

    humanoidRootPart.CFrame = targetCFrame
    task.wait(0.05)
    humanoidRootPart.Anchored = false

    return true
end

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
for islandName in pairs(islandMap) do
    table.insert(islandList, islandName)
end
table.sort(islandList)

local initialIsland = State.SelectedIsland
local hasInitialIsland = false

for _, islandName in ipairs(islandList) do
    if islandName == initialIsland then
        hasInitialIsland = true
        break
    end
end

if not hasInitialIsland then
    initialIsland = "Starter Island"
    State.SelectedIsland = initialIsland
end

local function getDropdownValue(option)
    if type(option) == "table" then
        return option[1]
    end

    return option
end

local function findIslandContainer(folderName)
    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name == folderName then
            return child
        end
    end

    return nil
end

local function findTeleportCFrame(container)
    for _, descendant in ipairs(container:GetDescendants()) do
        local loweredName = string.lower(descendant.Name)
        if string.find(loweredName, "spawn", 1, true) then
            if descendant:IsA("BasePart") then
                return descendant.CFrame
            end

            if descendant:IsA("Model") then
                return descendant:GetPivot()
            end
        end
    end

    if container:IsA("Model") then
        return container:GetPivot()
    end

    for _, descendant in ipairs(container:GetDescendants()) do
        if descendant:IsA("BasePart") then
            return descendant.CFrame
        end
    end

    return nil
end

local TeleportTab = Window:CreateTab("🗺️ Teleport", 4483362458)
local IslandDropdown

TeleportTab:CreateParagraph({
    Title = "Island Teleport",
    Content = "Chon dao nhanh theo dropdown, tim theo ten va teleport bang bypass dash de han che rubberband.",
})

TeleportTab:CreateSection("Teleport Island")

TeleportTab:CreateInput({
    Name = "🔎 Tim dao",
    PlaceholderText = "Nhap ten dao...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local filtered = {}
        local keyword = string.lower(text or "")

        if keyword == "" then
            filtered = islandList
        else
            for _, islandName in ipairs(islandList) do
                if string.find(string.lower(islandName), keyword, 1, true) then
                    table.insert(filtered, islandName)
                end
            end
        end

        if #filtered == 0 then
            filtered[1] = "Không tìm thấy"
        end

        if IslandDropdown then
            IslandDropdown:Refresh(filtered, true)
        end
    end,
})

IslandDropdown = TeleportTab:CreateDropdown({
    Name = "🏝️ Chon dao",
    Options = islandList,
    CurrentOption = { initialIsland },
    MultipleOptions = false,
    Flag = "SALOI_SelectedIsland",
    Callback = function(option)
        local selected = getDropdownValue(option)
        if selected and selected ~= "Không tìm thấy" then
            State.SelectedIsland = selected
        end
    end,
})

TeleportTab:CreateButton({
    Name = "⚡ Teleport toi dao da chon",
    Callback = function()
        local folderName = islandMap[State.SelectedIsland]
        if not folderName then
            notify("Teleport", "Ban chua chon dao hop le.", 4)
            return
        end

        local islandContainer = findIslandContainer(folderName)
        if not islandContainer then
            notify("Teleport", "Khong tim thay khu vuc " .. tostring(folderName) .. ".", 4)
            return
        end

        local targetCFrame = findTeleportCFrame(islandContainer)
        if not targetCFrame then
            notify("Teleport", "Khong tim thay vi tri ha canh trong " .. State.SelectedIsland .. ".", 4)
            return
        end

        bypassInstantTeleport(targetCFrame + Vector3.new(0, 5, 0))
        notify("Teleport", "Da den " .. State.SelectedIsland .. ".", 4)
    end,
})

TeleportTab:CreateLabel("Ho tro " .. tostring(#islandList) .. " dao trong danh sach.")
