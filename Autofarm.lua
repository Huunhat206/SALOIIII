local Window, Rayfield = ... -- Nhận giao diện từ Hnhathub.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Khởi tạo biến toàn cục cho các tính năng mới
_G.AutoHitClosest = false
_G.HitDistance = 250

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

-- Vòng lặp 2: Kill Aura (Đánh quái gần nhất trong phạm vi mà không bay tới)
-- ==========================================
task.spawn(function()
    while task.wait() do
        if _G.AutoHitClosest then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                local closestDistance = _G.HitDistance 
                local targetRoot = nil
                
                local npcFolder = workspace:FindFirstChild("NPCs")
                if npcFolder then
                    for _, npc in ipairs(npcFolder:GetChildren()) do
                        if npc:IsA("Model") then
                            local root = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
                            local hum = npc:FindFirstChildOfClass("Humanoid")
                            
                            -- Nếu quái tồn tại và còn sống
                            if root and (not hum or hum.Health > 0) then
                                local dist = (root.Position - hrp.Position).Magnitude
                                
                                if dist <= closestDistance then
                                    closestDistance = dist
                                    targetRoot = root
                                    
                                    -- THỦ THUẬT: Phóng to cơ thể quái để bao trùm lấy nhân vật
                                    -- Nhân 2.5 lần khoảng cách để đảm bảo viền Hitbox chắn chắn lấp đầy tới chỗ bạn đứng
                                    local newSize = dist * 2.5
                                    root.Size = Vector3.new(newSize, newSize, newSize)
                                    root.Transparency = 0.99 -- Làm tàng hình để không chắn tầm nhìn
                                    root.CanCollide = false  -- Tắt va chạm để bạn không bị kẹt
                                else
                                    -- Thu nhỏ lại kích thước chuẩn nếu quái văng ra khỏi tầm
                                    if root.Size.X > 10 then
                                        root.Size = Vector3.new(2, 2, 1)
                                        root.Transparency = 1
                                    end
                                end
                            end
                        end
                    end
                end
                
                -- Phát lệnh đánh. Máy chủ sẽ thấy rìa Hitbox khổng lồ của quái đang chạm vào bạn và đồng ý!
                if targetRoot then
                    pcall(function()
                        ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit"):FireServer()
                    end)
                end
            end
        else
            -- AN TOÀN: Nếu tắt Auto Hit, tự động thu nhỏ lại toàn bộ Hitbox trong map để game không bị lỗi
            local npcFolder = workspace:FindFirstChild("NPCs")
            if npcFolder then
                for _, npc in ipairs(npcFolder:GetChildren()) do
                    if npc:IsA("Model") then
                        local root = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
                        if root and root.Size.X > 10 then
                            root.Size = Vector3.new(2, 2, 1)
                            root.Transparency = 1
                        end
                    end
                end
            end
        end
    end
end)
