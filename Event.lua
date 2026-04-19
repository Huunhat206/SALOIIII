local Window, Rayfield = ... 

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- HÀM DỊCH CHUYỂN TỨC THỜI (ANTI-RUBBERBAND)
-- ==========================================
local function BypassInstantTeleport(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    
    local direction = (targetCFrame.Position - hrp.Position).Unit
    if (targetCFrame.Position - hrp.Position).Magnitude < 1 then direction = Vector3.new(0, 0, 1) end 
    
    local args = { Vector3.new(direction.X, 0, direction.Z), 33, false }
    local dashRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("DashRemote")
    
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.Anchored = true
    
    pcall(function() dashRemote:FireServer(unpack(args)) end)
    hrp.CFrame = targetCFrame
    
    task.wait(0.15)
    
    pcall(function() dashRemote:FireServer(unpack(args)) end)
    hrp.CFrame = targetCFrame
    
    task.wait(0.05)
    hrp.Anchored = false
end

-- ==========================================
-- GIAO DIỆN SỰ KIỆN
-- ==========================================
local EggTab = Window:CreateTab("🥚 Sự Kiện", 4483362458)

EggTab:CreateButton({
   Name = "🚀 Auto Gom Trứng (Instant Bypass)",
   Callback = function()
       local easterEggsFolder = workspace:FindFirstChild("EasterEggs")
       if easterEggsFolder then
           local count = 0
           for _, item in ipairs(easterEggsFolder:GetDescendants()) do
               local targetCFrame = nil
               
               if item:IsA("Model") then
                   targetCFrame = item:GetPivot()
               elseif item:IsA("BasePart") and not item.Parent:IsA("Model") then
                   targetCFrame = item.CFrame
               end
               
               if targetCFrame then
                   local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                   if prompt or string.find(string.lower(item.Name), "egg") then
                       count = count + 1
                       
                       -- Dùng hàm Teleport xịn
                       BypassInstantTeleport(targetCFrame)
                       task.wait(0.1) 
                       
                       if prompt then
                           pcall(function() fireproximityprompt(prompt) end)
                           task.wait(prompt.HoldDuration + 0.1) 
                       else
                           task.wait(0.3) 
                       end
                   end
               end
           end
           Rayfield:Notify({Title = "Hoàn tất", Content = "Đã thu thập " .. count .. " trứng!", Duration = 3})
       else
           Rayfield:Notify({Title = "Lỗi", Content = "Không tìm thấy thư mục EasterEggs!", Duration = 3})
       end
   end,
})
