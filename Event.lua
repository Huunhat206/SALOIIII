local Window, Library = ...

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local env = getgenv and getgenv() or _G
env.SALOI_HUB = env.SALOI_HUB or {}

local Hub = env.SALOI_HUB
Hub.Helpers = Hub.Helpers or {}

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

local function getEggTarget(item)
    local targetCFrame

    if item:IsA("Model") then
        targetCFrame = item:GetPivot()
    elseif item:IsA("BasePart") and not item.Parent:IsA("Model") then
        targetCFrame = item.CFrame
    end

    if not targetCFrame then
        return nil, nil
    end

    local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
    local isEggNamed = string.find(string.lower(item.Name), "egg", 1, true) ~= nil

    if prompt or isEggNamed then
        return targetCFrame, prompt
    end

    return nil, nil
end

local EventTab = Window:CreateTab("🎉 Event", 4483362458)

EventTab:CreateParagraph({
    Title = "Event Tools",
    Content = "Tab nay gom cac tinh nang theo su kien. Hien tai da ho tro auto nhat trung trong workspace.EasterEggs.",
})

EventTab:CreateSection("Easter Event")

EventTab:CreateButton({
    Name = "🥚 Auto Gom Trung",
    Callback = function()
        local easterEggsFolder = workspace:FindFirstChild("EasterEggs")
        if not easterEggsFolder then
            notify("Event", "Khong tim thay folder EasterEggs.", 4)
            return
        end

        local totalEggs = 0
        for _, item in ipairs(easterEggsFolder:GetDescendants()) do
            local targetCFrame, prompt = getEggTarget(item)
            if targetCFrame then
                totalEggs = totalEggs + 1
                bypassInstantTeleport(targetCFrame + Vector3.new(0, 3, 0))
                task.wait(0.1)

                if prompt and fireproximityprompt then
                    pcall(function()
                        fireproximityprompt(prompt)
                    end)
                    task.wait(prompt.HoldDuration + 0.1)
                else
                    task.wait(0.25)
                end
            end
        end

        if totalEggs > 0 then
            notify("Event", "Da thu thap " .. tostring(totalEggs) .. " trung.", 4)
        else
            notify("Event", "Khong tim thay trung hop le trong EasterEggs.", 4)
        end
    end,
})

EventTab:CreateLabel("Neu executor co fireproximityprompt, script se tuong tac prompt tu dong.")
