-- Tải thư viện UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Khởi tạo biến toàn cục để các file con có thể đọc được
_G.AutoFarm = false
_G.SelectedNPC = "None"
_G.SelectedIsland = "Starter Island"

-- Tạo Window chính
local Window = Rayfield:CreateWindow({
   Name = "H.N.H.A.T Hub",
   LoadingTitle = "Đang tải hệ thống...",
   LoadingSubtitle = "Modular Version",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

-- Hàm hỗ trợ tải module từ GitHub
local function loadModule(url)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))
    end)
    if success and type(result) == "function" then
        -- Truyền 2 biến Window và Rayfield vào bên trong file con
        result(Window, Rayfield)
    else
        warn("Lỗi khi tải module: " .. tostring(url))
    end
end

-- ==========================================
-- GỌI CÁC TAB TỪ GITHUB
-- ==========================================
local repoUrl = "https://raw.githubusercontent.com/Huunhat206/SALOIIII/main/"

loadModule(repoUrl .. "Autofarm.lua")
loadModule(repoUrl .. "Event.lua")
loadModule(repoUrl .. "teleport%20island.lua")
