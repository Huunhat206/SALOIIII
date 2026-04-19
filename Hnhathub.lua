--[[
    AUTOFARM MODULE - SOLIX UI EDITION
]]

local Tab, Library = ... -- Nhận biến từ Hnhathub.lua truyền sang

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
    return #list > 0 and list or {"None"}
end

local fullNPCList = getNPCList()

-- ==========================================
-- GIAO DIỆN (Sử dụng đối tượng Tab mới)
-- ==========================================

Tab:CreateSection("Farm Theo Mục Tiêu")

-- Trong Solix UI mới, nếu chưa viết hàm Input thì ta dùng Label + Dropdown tạm thời
Tab:CreateButton({
    Name = "🔄 Tải lại danh sách NPC",
    Callback = function()
        fullNPCList = getNPCList()
        -- Thông báo thành công
        Library:Notify({Title = "Hệ thống", Content = "Đã cập nhật danh sách NPC!", Duration = 3})
    end,
})

-- Lưu ý: Bạn cần chọn NPC trước khi bật Toggle
-- (Nếu UI chưa có Dropdown, tôi sẽ giả lập logic chọn quái gần nhất cho bạn)

Tab:CreateToggle({
    Name = "⚡ Bật Auto Farm (Dịch chuyển tới quái)",
    CurrentValue = false,
    Callback = function(Value)
        _G.AutoFarm = Value
    end,
})

Tab:CreateSection("Kill Aura (VIP Mode)")

Tab:CreateToggle({
    Name = "⚔️ Auto Hit Closest Mob",
    CurrentValue = false,
    Callback = function(Value)
        _G.AutoHitClosest = Value
    end,
})

-- ==========================================
-- VÒNG LẶP XỬ LÝ (CORE LOGIC)
-- ==========================================

-- Vòng lặp chính sử dụng Heartbeat để nháy tọa độ (Anti-Teleport)
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- XỬ LÝ KILL AURA
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
            -- Kỹ thuật nháy tọa độ ảo (Micro-Stutter)
            local oldCF = hrp.CFrame
            hrp.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
            
            pcall(function()
                ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
            end)
            
            hrp.CFrame = oldCF
        end
    end

    -- XỬ LÝ AUTO FARM (BAY TỚI QUÁI)
    if _G.AutoFarm then
        local target = nil
        local npcFolder = workspace:FindFirstChild("NPCs")
        
        -- Nếu chưa chọn quái cụ thể, tự tìm con gần nhất
        for _, npc in ipairs(npcFolder:GetChildren()) do
            local root = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if root and (not hum or hum.Health > 0) then
                target = root
                break
            end
        end

        if target then
            hrp.CFrame = target.CFrame * CFrame.new(0, 0, 3)
            pcall(function()
                ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
            end)
        end
    end
end)
