local Window, Rayfield = ...

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local function BypassInstantTeleport(targetCFrame)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    
    local direction = (targetCFrame.Position - hrp.Position).Unit
    if (targetCFrame.Position - hrp.Position).Magnitude < 1 then direction = Vector3.new(0, 0, 1) end 
    
    local args = { Vector3.new(direction.X, 0, direction.Z), 33, false }
    local dashRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("DashRemote")
    
    -- Dịch chuyển tức thời
    hrp.CFrame = targetCFrame
    
    -- Lần Dash 1 (Đánh lừa đợt 1)
    pcall(function()
        dashRemote:FireServer(unpack(args))
    end)
    
    -- Nghỉ nửa nhịp để server ghi nhận, sau đó neo lại vị trí chống trượt
    task.wait(0.05)
    hrp.CFrame = targetCFrame
    
    -- Lần Dash 2 (Chốt hạ qua mặt Anti-Cheat)
    pcall(function()
        dashRemote:FireServer(unpack(args))
    end)
    
    -- Đợi hoạt ảnh dash xong và chốt vị trí lần cuối cùng
    task.wait(0.1)
    hrp.CFrame = targetCFrame
end

local islandMap = {
    ["Starter Island"] = "StarterIsland", ["Jungle Island"] = "JungleIsland", ["Desert Island"] = "DesertIsland",
    ["Snow Island"] = "SnowIsland", ["Sailor Island"] = "SailorIsland", ["Shibuya Station"] = "ShibuyaStation",
    ["Hollow Island"] = "HollowIsland", ["Boss Island"] = "BossIsland", ["Dungeon Island"] = "DungeonIsland",
    ["Shinjuku Island"] = "ShinjukuIsland", ["Slime Island"] = "SlimeIsland", ["Academy Island"] = "AcademyIsland",
    ["Judgement Island"] = "JudgementIsland", ["Soul Dominion"] = "SoulDominionIsland", ["Ninja Island"] = "NinjaIsland",
    ["Lawless Island"] = "LawlessIsland", ["Tower Island"] = "TowerIsland", ["Easter Island"] = "EasterIsland",
    ["World Island"] = "WorldIsland"
}

local fullIslandList = {}
for name, _ in pairs(islandMap) do table.insert(fullIslandList, name) end
table.sort(fullIslandList) 

local TeleportTab = Window:CreateTab("🌍 Dịch Chuyển", 4483362458)
local IslandDropdown 

TeleportTab:CreateInput({
   Name = "🔍 Tìm kiếm Đảo",
   PlaceholderText = "Nhập tên đảo vào đây...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       local filteredList = {}
       if Text == "" then
           filteredList = fullIslandList
       else
           for _, island in ipairs(fullIslandList) do
               if string.find(string.lower(island), string.lower(Text), 1, true) then table.insert(filteredList, island) end
           end
           if #filteredList == 0 then table.insert(filteredList, "Không tìm thấy") end
       end
       if IslandDropdown then IslandDropdown:Refresh(filteredList, true) end
   end,
})

IslandDropdown = TeleportTab:CreateDropdown({
   Name = "🏝️ Chọn Đảo",
   Options = fullIslandList,
   CurrentOption = {"Starter Island"},
   MultipleOptions = false,
   Flag = "IslandDropdown", 
   Callback = function(Option)
       if Option[1] ~= "Không tìm thấy" then _G.SelectedIsland = Option[1] end
   end,
})

TeleportTab:CreateButton({
   Name = "⚡ Dịch Chuyển Tức Thời (Bypass)",
   Callback = function()
       local folderName = islandMap[_G.SelectedIsland]
       local islandFolder = nil
       for _, child in ipairs(workspace:GetChildren()) do
           if child.Name == folderName and child:IsA("Folder") then
               islandFolder = child; break
           end
       end
       
       if islandFolder then
           local targetCFrame = nil
           for _, v in ipairs(islandFolder:GetDescendants()) do
               if string.find(string.lower(v.Name), "spawnpoint") then
                   if v:IsA("BasePart") then targetCFrame = v.CFrame; break
                   elseif v:IsA("Model") then targetCFrame = v:GetPivot(); break end
               end
           end
           
           if not targetCFrame then
               for _, v in ipairs(islandFolder:GetDescendants()) do
                   if v:IsA("BasePart") then targetCFrame = v.CFrame; break end
               end
           end
           
           if targetCFrame then
               BypassInstantTeleport(targetCFrame + Vector3.new(0, 5, 0))
               Rayfield:Notify({Title = "Thành công", Content = "Đã đáp xuống " .. _G.SelectedIsland, Duration = 3})
           else
               Rayfield:Notify({Title = "Lỗi", Content = "Đảo này trống rỗng (không có khối nào)!", Duration = 3})
           end
       else
           Rayfield:Notify({Title = "Lỗi", Content = "Không tìm thấy Thư mục mang tên " .. tostring(folderName), Duration = 3})
       end
   end,
})
