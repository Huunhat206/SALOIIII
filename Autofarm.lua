local Window, Rayfield = ... -- Nhận giao diện từ Hnhathub.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Khởi tạo biến toàn cục
_G.AutoFarm = false
_G.SelectedNPC = "None"
_G.AutoHitClosest = false
_G.HitDistance = 250

-- Biến hỗ trợ cho kỹ thuật Hook
local TargetForHook = nil

-- ==========================================
-- KỸ THUẬT GHOST POSITION HOOK (ANTI-TELEPORT)
-- Can thiệp vào nhân hệ thống để giả lập vị trí khi Server kiểm tra
-- ==========================================
local mt = getrawmetatable(game)
local oldIndex = mt.__index
setreadonly(mt, false)

mt.__index = newcclosure(function(self, index)
    -- Nếu đang bật Kill Aura và hệ thống check tọa độ của nhân vật
    if _G.AutoHitClosest and TargetForHook and index == "CFrame" and self.Name == "HumanoidRootPart" then
        -- Trả về tọa độ "giả" sát mục tiêu để đánh lừa Magnitude Check của Server
        return TargetForHook.CFrame * CFrame.new(0, 0, 2)
    end
    return oldIndex(self, index)
end)

setreadonly(mt, true)

-- ==========================================
-- HÀM LỌC VÀ LẤY DANH SÁCH NPC
-- ==========================================
local function getBaseName(name)
    local baseName = string.gsub(name, "%d+$", "") 
    return string.match(baseName, "^%s*(.-)%s*$") 
end

local function getNPCList()
    local list = {}
    local dict = {}
    local npcFolder = workspace:FindFirstChild("NPCs")
    if npcFolder then
        for _, npc in ipairs(npcFolder:GetChildren()) do
            if npc:IsA("Model") then
                local baseName = getBaseName(npc.Name)
                if not dict[baseName] then
                    dict[baseName] = true
                    table.insert(list, baseName)
                end
            end
        end
    end
    table.sort(list)
    if #list == 0 then table.insert(list, "None") end
    return list
end

local fullNPCList = getNPCList()
local MainTab = Window:CreateTab("🗡️ Auto Farm", 4483362458)
local NPCDropdown 

-- ==========================================
-- 1. GIAO DIỆN: FARM THEO MỤC TIÊU
-- ==========================================
MainTab:CreateSection("Farm Theo Mục Tiêu")

MainTab:CreateInput({
   Name = "🔍 Tìm kiếm NPC",
   PlaceholderText = "Nhập tên quái vào đây...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       local filteredList = {}
       if Text == "" then
           filteredList = fullNPCList
       else
           for _, npc in ipairs(fullNPCList) do
               if string.find(string.lower(npc), string.lower(Text), 1, true) then
                   table.insert(filteredList, npc)
               end
           end
           if #filteredList == 0 then table.insert(filteredList, "Không tìm thấy") end
       end
       if NPCDropdown then NPCDropdown:Refresh(filteredList, true) end
   end,
})

NPCDropdown = MainTab:CreateDropdown({
   Name = "🎯 Chọn mục tiêu (NPC)",
   Options = fullNPCList,
   CurrentOption = {"None"},
   MultipleOptions = false,
   Flag = "NPCDropdown", 
   Callback = function(Option)
       if Option[1] ~= "Không tìm thấy" then _G.SelectedNPC = Option[1] end
   end,
})

MainTab:CreateButton({
   Name = "🔄 Tải lại danh sách NPC (Quét map)",
   Callback = function()
       fullNPCList = getNPCList()
       NPCDropdown:Refresh(fullNPCList, true)
       Rayfield:Notify({Title = "Thành công", Content = "Đã cập nhật lại toàn bộ NPC!", Duration = 3, Image = 4483362458})
   end,
})

MainTab:CreateToggle({
   Name = "⚡ Bật Auto Farm (Bay tới mục tiêu)",
   CurrentValue = false,
   Flag = "AutoFarmToggle", 
   Callback = function(Value)
       _G.AutoFarm = Value
   end,
})

-- ==========================================
-- 2. GIAO DIỆN: KILL AURA
-- ==========================================
MainTab:CreateSection("Kill Aura (Đánh Xung Quanh)")

MainTab:CreateToggle({
   Name = "⚔️ Auto Hit Closest Mob",
   CurrentValue = false,
   Flag = "AutoHitToggle", 
   Callback = function(Value)
       _G.AutoHitClosest = Value
   end,
})

MainTab:CreateSlider({
   Name = "📏 Hit Distance (Phạm vi đánh)",
   Range = {10, 500},
   Increment = 10,
   Suffix = " Studs",
   CurrentValue = 250,
   Flag = "HitDistanceSlider",
   Callback = function(Value)
       _G.HitDistance = Value
   end,
})

-- ==========================================
-- VÒNG LẶP XỬ LÝ CHÍNH
-- ==========================================

-- Vòng lặp 1: Auto Farm cơ bản (Bay tới sau lưng NPC đã chọn)
task.spawn(function()
    while task.wait() do
        if _G.AutoFarm and _G.SelectedNPC and _G.SelectedNPC ~= "None" then
            local targetPart = nil
            local npcFolder = workspace:FindFirstChild("NPCs")
            
            if npcFolder then
                for _, npc in ipairs(npcFolder:GetChildren()) do
                    if npc:IsA("Model") and getBaseName(npc.Name) == _G.SelectedNPC then
                        local root = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart or npc:FindFirstChildWhichIsA("BasePart")
                        local hum = npc:FindFirstChildOfClass("Humanoid")
                        if root and (not hum or hum.Health > 0) then
                            targetPart = root
                            break
                        end
                    end
                end
            end
            
            if targetPart then
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    character.HumanoidRootPart.CFrame = targetPart.CFrame * CFrame.new(0, 0, 3)
                    pcall(function()
                        ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit"):FireServer()
                    end)
                end
            end
        end
    end
end)

-- Vòng lặp 2: KILL AURA (SỬ DỤNG GHOST HOOK)
task.spawn(function()
    while task.wait() do
        if _G.AutoHitClosest then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                local closestDistance = _G.HitDistance 
                TargetForHook = nil
                
                -- Tìm quái gần nhất trong map
                local npcFolder = workspace:FindFirstChild("NPCs")
                if npcFolder then
                    for _, npc in ipairs(npcFolder:GetChildren()) do
                        if npc:IsA("Model") then
                            local root = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
                            local hum = npc:FindFirstChildOfClass("Humanoid")
                            
                            if root and (not hum or hum.Health > 0) then
                                local dist = (root.Position - hrp.Position).Magnitude
                                if dist <= closestDistance then
                                    closestDistance = dist
                                    TargetForHook = root -- Gán mục tiêu để Meta Hook xử lý tọa độ giả
                                end
                            end
                        end
                    end
                end
                
                -- Thực hiện đòn đánh
                if TargetForHook then
                    pcall(function()
                        -- Khi Server gọi lệnh kiểm tra vị trí của bạn, 
                        -- nó sẽ nhận được vị trí giả ngay sát con quái nhờ đoạn Hook ở đầu script.
                        ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit"):FireServer()
                    end)
                end
            end
        else
            TargetForHook = nil -- Reset khi tắt tính năng
        end
    end
end)
