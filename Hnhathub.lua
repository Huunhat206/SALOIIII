local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local VirtualUser       = game:GetService("VirtualUser")
local VIM               = game:GetService("VirtualInputManager")

local player    = Players.LocalPlayer
local PlayerGui = player.PlayerGui
local camera    = workspace.CurrentCamera

local CFG = {
    Enabled        = true,
    AutoSell       = false,
    SellInterval   = 3.0,
    IdleClickDelay = 2.0,
    SpamRate       = 0.016, -- fire mỗi ~1 frame (60fps), giảm nếu lag
    Debug          = false,
}

local ByteNetUnreliable = ReplicatedStorage:WaitForChild("ByteNetUnreliable", 10)
local ByteNetReliable   = ReplicatedStorage:WaitForChild("ByteNetReliable", 10)
local SELL_BUF          = buffer.fromstring("2")
local lastHitBuffer     = nil

-- Auto sell loop
task.spawn(function()
    while true do
        if CFG.AutoSell and ByteNetReliable then
            pcall(function() ByteNetReliable:FireServer(SELL_BUF) end)
        end
        task.wait(CFG.SellInterval)
    end
end)

-- Mở vòng câu
local function tryOpenFishing()
    pcall(function()
        local char = player.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(0,0), camera.CFrame)
        task.wait(0.1)
        VirtualUser:Button1Up(Vector2.new(0,0), camera.CFrame)
    end)
end

-- Fire hit — ưu tiên remote, fallback VIM
local qteBtn = nil
local function findQTEBtn()
    local qte  = PlayerGui:FindFirstChild("QTE")
    local main = qte and qte:FindFirstChild("Main")
    if not main then return nil end
    for _, c in ipairs(main:GetDescendants()) do
        if c:IsA("TextButton") or c:IsA("ImageButton") then return c end
    end
end

local function fireHit()
    -- Method 1: FireServer với captured buffer (best)
    if lastHitBuffer and ByteNetUnreliable then
        pcall(function() ByteNetUnreliable:FireServer(lastHitBuffer) end)
        return
    end

    -- Method 2: getconnections fire trực tiếp
    if not qteBtn then qteBtn = findQTEBtn() end
    if qteBtn and getconnections then
        local fired = false
        pcall(function()
            for _, c in pairs(getconnections(qteBtn.MouseButton1Click)) do c:Fire(); fired = true end
            for _, c in pairs(getconnections(qteBtn.Activated))        do c:Fire(); fired = true end
        end)
        if fired then return end
    end

    -- Method 3: VIM click
    local cx = camera.ViewportSize.X / 2
    local cy = camera.ViewportSize.Y / 2
    pcall(function()
        VIM:SendMouseButtonEvent(cx, cy, 0, true,  game, 0)
        VIM:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
    end)
end

-- Hook capture buffer khi player click thủ công
if hookfunction and ByteNetUnreliable then
    local orig
    orig = hookfunction(ByteNetUnreliable.FireServer, newcclosure(function(self, ...)
        if self == ByteNetUnreliable then
            local a = {...}
            if a[1] and typeof(a[1]) == "buffer" then
                local qte  = PlayerGui:FindFirstChild("QTE")
                local main = qte and qte:FindFirstChild("Main")
                if main and main.Visible then
                    lastHitBuffer = a[1]
                end
            end
        end
        return orig(self, ...)
    end))
end

-- ══════════ MAIN LOOP ══════════
local lastIdle    = 0
local lastFire    = 0
local spamActive  = false

RunService.Heartbeat:Connect(function()
    if not CFG.Enabled then return end

    local now = tick()

    -- Check QTE active
    local qteActive = false
    local qteGui = PlayerGui:FindFirstChild("QTE")
    if qteGui and qteGui.Enabled then
        local main = qteGui:FindFirstChild("Main")
        if main and main.Visible then qteActive = true end
    end

    if not qteActive then
        spamActive = false
        local delay = math.max(2.0, CFG.IdleClickDelay)
        if now - lastIdle >= delay then
            tryOpenFishing()
            lastIdle = now
        end
        return
    end

    -- QTE active → spam fire mỗi SpamRate giây
    -- Server tự catch khi rotation của nó align với white zone
    if now - lastFire >= CFG.SpamRate then
        spamActive = true
        fireHit()
        lastFire = now
    end
end)

-- ══════════ GUI ══════════
pcall(function()
    if PlayerGui:FindFirstChild("_MacroGUI") then
        PlayerGui:FindFirstChild("_MacroGUI"):Destroy()
    end
end)

local sg = Instance.new("ScreenGui")
sg.Name = "_MacroGUI"; sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true; sg.Parent = PlayerGui

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 200, 0, 165)
panel.Position = UDim2.new(0, 12, 0.5, -82)
panel.BackgroundColor3 = Color3.fromRGB(14,14,18)
panel.BorderSizePixel = 0; panel.Parent = sg
Instance.new("UICorner", panel).CornerRadius = UDim.new(0,10)

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1,0,0,26)
topBar.BackgroundColor3 = Color3.fromRGB(26,26,34)
topBar.BorderSizePixel = 0; topBar.Parent = panel
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0,10)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1,-10,1,0); titleLbl.Position = UDim2.new(0,10,0,0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "🎣 Fish & Sell v5.1  [SPAM]"
titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 11
titleLbl.TextColor3 = Color3.fromRGB(200,200,225)
titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.Parent = topBar

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1,-16,0,32); toggleBtn.Position = UDim2.new(0,8,0,30)
toggleBtn.BackgroundColor3 = Color3.fromRGB(35,175,95); toggleBtn.BorderSizePixel = 0
toggleBtn.Font = Enum.Font.GothamBold; toggleBtn.TextSize = 13
toggleBtn.TextColor3 = Color3.new(1,1,1); toggleBtn.Text = "AUTO FISH: ON"
toggleBtn.Parent = panel
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,7)

local sellBtn = Instance.new("TextButton")
sellBtn.Size = UDim2.new(1,-16,0,30); sellBtn.Position = UDim2.new(0,8,0,67)
sellBtn.BackgroundColor3 = Color3.fromRGB(175,45,45); sellBtn.BorderSizePixel = 0
sellBtn.Font = Enum.Font.GothamBold; sellBtn.TextSize = 12
sellBtn.TextColor3 = Color3.new(1,1,1); sellBtn.Text = "AUTO SELL: OFF"
sellBtn.Parent = panel
Instance.new("UICorner", sellBtn).CornerRadius = UDim.new(0,7)

local bufLbl = Instance.new("TextLabel")
bufLbl.Size = UDim2.new(1,-16,0,14); bufLbl.Position = UDim2.new(0,8,0,102)
bufLbl.BackgroundTransparency = 1; bufLbl.Font = Enum.Font.Gotham; bufLbl.TextSize = 10
bufLbl.TextColor3 = Color3.fromRGB(200,140,50)
bufLbl.Text = "Click 1 lần để capture buffer"
bufLbl.TextXAlignment = Enum.TextXAlignment.Left; bufLbl.Parent = panel

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1,-16,0,14); statusLbl.Position = UDim2.new(0,8,0,118)
statusLbl.BackgroundTransparency = 1; statusLbl.Font = Enum.Font.Gotham; statusLbl.TextSize = 10
statusLbl.TextColor3 = Color3.fromRGB(100,100,130); statusLbl.Text = "○ Đợi câu..."
statusLbl.TextXAlignment = Enum.TextXAlignment.Left; statusLbl.Parent = panel

-- Spam rate buttons
local rateLbl = Instance.new("TextLabel")
rateLbl.Size = UDim2.new(1,-16,0,14); rateLbl.Position = UDim2.new(0,8,0,134)
rateLbl.BackgroundTransparency = 1; rateLbl.Font = Enum.Font.Gotham; rateLbl.TextSize = 10
rateLbl.TextColor3 = Color3.fromRGB(120,120,150)
rateLbl.TextXAlignment = Enum.TextXAlignment.Left; rateLbl.Parent = panel

local function updateRateLbl()
    rateLbl.Text = string.format("Spam rate: %.3fs/fire (~%.0f/s)",
        CFG.SpamRate, 1/CFG.SpamRate)
end
updateRateLbl()

local btnRow = Instance.new("Frame")
btnRow.Size = UDim2.new(1,-16,0,24); btnRow.Position = UDim2.new(0,8,0,150)
btnRow.BackgroundTransparency = 1; btnRow.Parent = panel

local function makeBtn(text, xoff)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,82,1,0); b.Position = UDim2.new(0,xoff,0,0)
    b.BackgroundColor3 = Color3.fromRGB(50,50,70); b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold; b.TextSize = 11
    b.TextColor3 = Color3.new(1,1,1); b.Text = text; b.Parent = btnRow
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    return b
end

local btnSlow = makeBtn("Chậm hơn", 0)
local btnFast = makeBtn("Nhanh hơn", 88)

btnSlow.MouseButton1Click:Connect(function()
    CFG.SpamRate = math.min(0.5, CFG.SpamRate + 0.016); updateRateLbl()
end)
btnFast.MouseButton1Click:Connect(function()
    -- Tối thiểu 0.016 (~1 frame), không nên dưới mức đó sẽ spam quá
    CFG.SpamRate = math.max(0.016, CFG.SpamRate - 0.016); updateRateLbl()
end)

-- Status update
RunService.Heartbeat:Connect(function()
    if lastHitBuffer then
        bufLbl.Text = "✓ Buffer captured - fully auto!"
        bufLbl.TextColor3 = Color3.fromRGB(80,200,120)
    end
    local qteGui = PlayerGui:FindFirstChild("QTE")
    local main   = qteGui and qteGui:FindFirstChild("Main")
    local active = main and main.Visible or false
    if spamActive and active then
        statusLbl.Text = "⚡ Spamming..."
        statusLbl.TextColor3 = Color3.fromRGB(255,200,50)
    elseif active then
        statusLbl.Text = "● QTE đang chạy"
        statusLbl.TextColor3 = Color3.fromRGB(80,200,120)
    else
        statusLbl.Text = "○ Đợi câu..."
        statusLbl.TextColor3 = Color3.fromRGB(100,100,130)
    end
end)

local function setFishing(s)
    CFG.Enabled = s
    toggleBtn.BackgroundColor3 = s and Color3.fromRGB(35,175,95) or Color3.fromRGB(175,45,45)
    toggleBtn.Text = s and "AUTO FISH: ON" or "AUTO FISH: OFF"
end
local function setSelling(s)
    CFG.AutoSell = s
    sellBtn.BackgroundColor3 = s and Color3.fromRGB(35,175,95) or Color3.fromRGB(175,45,45)
    sellBtn.Text = s and "AUTO SELL: ON" or "AUTO SELL: OFF"
end

toggleBtn.MouseButton1Click:Connect(function() setFishing(not CFG.Enabled) end)
sellBtn.MouseButton1Click:Connect(function() setSelling(not CFG.AutoSell) end)

-- Drag (mouse + touch)
local drag, dStart, dPos = false, nil, nil
topBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        drag=true; dStart=i.Position; dPos=panel.Position
    end
end)
topBar.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then drag=false end
end)
UserInputService.InputChanged:Connect(function(i)
    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
              or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dStart
        panel.Position = UDim2.new(dPos.X.Scale, dPos.X.Offset+d.X,
                                   dPos.Y.Scale, dPos.Y.Offset+d.Y)
    end
end)

print("[Fish v5.1 SPAM] Loaded ✓ | Click thủ công 1 lần vào QTE!")