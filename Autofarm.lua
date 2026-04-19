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

-- ==========================================
-- HÀM HỖ TRỢ (UTILITIES)
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
   PlaceholderText = "Nhập tên quái...",
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
   Name = "🔄 Tải lại danh sách NPC",
   Callback = function()
       fullNPCList = getNPCList()
       NPCDropdown:Refresh(fullNPCList, true)
       Rayfield:Notify({Title = "Thành công", Content = "Đã cập nhật NPC!", Duration = 3})
   end,
})

MainTab:CreateToggle({
   Name = "⚡ Bật Auto Farm (Teleport)",
   CurrentValue = false,
   Flag = "AutoFarmToggle", 
   Callback = function(Value)
       _G.AutoFarm = Value
   end,
})

-- ==========================================
-- 2. GIAO DIỆN: KILL AURA (VIP MODE)
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
   Name = "📏 Hit Distance",
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
-- VÒNG LẶP XỬ LÝ (CORE LOGIC)
-- ==========================================

-- Vòng lặp chính sử dụng Heartbeat để đảm bảo tốc độ nháy tọa độ không bị lộ
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Xử lý Kill Aura (Đánh quanh vị trí hiện tại)
    if _G.AutoHitClosest then
        local targetRoot = nil
        local shortestDist = _G.HitDistance
        
        local npcFolder = workspace:FindFirstChild("NPCs")
        if npcFolder then
            for _, npc in ipairs(npcFolder:GetChildren()) do
                local root = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
                local hum = npc:FindFirstChildOfClass("Humanoid")
                if root and (not hum or hum.Health > 0) then
                    local dist = (root.Position - hrp.Position).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        targetRoot = root
                    end
                end
            end
        end

        if targetRoot then
            -- Kỹ thuật nháy tọa độ trong 1 frame
            local oldCF = hrp.CFrame
            hrp.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
            
            pcall(function()
                ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
            end)
            
            hrp.CFrame = oldCF -- Trả về ngay lập tức để không bị tele trên màn hình
        end
    end
end)

-- Vòng lặp Auto Farm (Dùng cho việc bay đi farm quái cụ thể)
task.spawn(function()
    while task.wait() do
        if _G.AutoFarm and _G.SelectedNPC and _G.SelectedNPC ~= "None" then
            local npcFolder = workspace:FindFirstChild("NPCs")
            if npcFolder then
                for _, npc in ipairs(npcFolder:GetChildren()) do
                    if getBaseName(npc.Name) == _G.SelectedNPC then
                        local root = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
                        local hum = npc:FindFirstChildOfClass("Humanoid")
                        if root and (not hum or hum.Health > 0) then
                            local char = LocalPlayer.Character
                            if char and char:FindFirstChild("HumanoidRootPart") then
                                char.HumanoidRootPart.CFrame = root.CFrame * CFrame.new(0, 0, 3)
                                pcall(function()
                                    ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                                end)
                            end
                            break
                        end
                    end
                end
            end
        end
    end
end)
