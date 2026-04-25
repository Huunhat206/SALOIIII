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
    IdleClickDelay = 2.0,   -- chỉ dùng khi lần đầu, sau đó instant
    EarlyHit       = 2.0,
    CastDelay      = 0.15,  -- giây chờ sau khi QTE đóng trước khi cast (0 = ngay lập tức)
    Debug          = false,
}

-- ══════════ ANTI-AFK ══════════
player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
    if CFG.Debug then print("🛡️ [Anti-AFK] fired") end
end)

local ByteNetQuery      = ReplicatedStorage:WaitForChild("ByteNetQuery", 10)
local ByteNetUnreliable = ReplicatedStorage:WaitForChild("ByteNetUnreliable", 10)
local ByteNetReliable   = ReplicatedStorage:WaitForChild("ByteNetReliable", 10)

local SELL_BUF = buffer.fromstring("2")

task.spawn(function()
    while true do
        if CFG.AutoSell and ByteNetReliable then
            pcall(function() ByteNetReliable:FireServer(SELL_BUF) end)
        end
        task.wait(CFG.SellInterval)
    end
end)

-- ══════════ CAST ══════════
local isCasting = false  -- chống cast chồng

local function tryOpenFishing()
    if isCasting then return end
    isCasting = true
    pcall(function()
        local char = player.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(0,0), camera.CFrame)
        task.wait(0.1)
        VirtualUser:Button1Up(Vector2.new(0,0), camera.CFrame)
    end)
    task.wait(0.2)  -- buffer nhỏ để game nhận input
    isCasting = false
end

-- ══════════ FIRE HIT ══════════
local qteClickFunc  = nil
local lastHitBuffer = nil

local function findQTEClickFunction()
    local qte  = PlayerGui:FindFirstChild("QTE")
    local main = qte and qte:FindFirstChild("Main")
    if not main then return nil end
    for _, c in ipairs(main:GetDescendants()) do
        if c:IsA("TextButton") or c:IsA("ImageButton") then return c end
    end
end

local function fireQTEHit()
    if lastHitBuffer and ByteNetUnreliable then
        local ok = false
        pcall(function() ByteNetUnreliable:FireServer(lastHitBuffer); ok = true end)
        if ok then return end
    end
    if not qteClickFunc then qteClickFunc = findQTEClickFunction() end
    if qteClickFunc and getconnections then
        local fired = false
        pcall(function()
            for _, c in pairs(getconnections(qteClickFunc.MouseButton1Click)) do c:Fire(); fired = true end
            for _, c in pairs(getconnections(qteClickFunc.Activated))        do c:Fire(); fired = true end
        end)
        if fired then return end
    end
    local center = qteClickFunc
        and (qteClickFunc.AbsolutePosition + qteClickFunc.AbsoluteSize / 2)
        or  Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
    pcall(function()
        VIM:SendMouseButtonEvent(center.X, center.Y, 0, true,  game, 0)
        task.wait(0.02)
        VIM:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
    end)
end

if hookfunction and ByteNetUnreliable then
    local orig
    orig = hookfunction(ByteNetUnreliable.FireServer, newcclosure(function(self, ...)
        if self == ByteNetUnreliable then
            local a = {...}
            if a[1] and typeof(a[1]) == "buffer" then
                local qte  = PlayerGui:FindFirstChild("QTE")
                local main = qte and qte:FindFirstChild("Main")
                if main and main.Visible then lastHitBuffer = a[1] end
            end
        end
        return orig(self, ...)
    end))
end

-- ══════════ ANGLE ══════════
local function normAngle(a) return a % 360 end
local function angleDiff(a, b)
    local d = math.abs(normAngle(a) - normAngle(b))
    return d > 180 and 360 - d or d
end

-- ══════════ REFS ══════════
local QTE, MainFrame, LineObj, BarsFolder
local function initRefs()
    QTE        = PlayerGui:FindFirstChild("QTE")
    if not QTE then return false end
    MainFrame  = QTE:FindFirstChild("Main")
    if not MainFrame then return false end
    LineObj    = MainFrame:FindFirstChild("Line")
    BarsFolder = MainFrame:FindFirstChild("Bars")
    return LineObj ~= nil and BarsFolder ~= nil
end

-- ══════════ MAIN LOOP ══════════
local lastIdleOpen  = 0
local lastHitFire   = 0
local wasQTEActive  = false  -- track trạng thái frame trước
local justClosed    = false  -- flag để cast ngay

RunService.Heartbeat:Connect(function()
    if not CFG.Enabled then return end
    local now = tick()

    -- Lấy trạng thái QTE frame này
    local qteActive = false
    local qteGui = PlayerGui:FindFirstChild("QTE")
    if qteGui and qteGui.Enabled then
        local main = qteGui:FindFirstChild("Main")
        if main and main.Visible then qteActive = true end
    end

    -- ── Detect QTE vừa đóng → cast ngay ──
    if wasQTEActive and not qteActive then
        -- QTE vừa tắt frame này → spawn cast ngay
        justClosed = true
        task.spawn(function()
            task.wait(CFG.CastDelay)  -- 0.15s mặc định, chỉnh về 0 nếu muốn true instant
            if CFG.Enabled and not qteActive then
                if CFG.Debug then print("[Macro] QTE closed → instant cast!") end
                tryOpenFishing()
                lastIdleOpen = tick()
            end
            justClosed = false
        end)
    end
    wasQTEActive = qteActive

    -- ── Idle fallback (lần đầu hoặc nếu cần re-cast) ──
    if not qteActive and not justClosed then
        local delay = math.max(2.0, CFG.IdleClickDelay)
        if now - lastIdleOpen >= delay then
            if CFG.Debug then print("[Macro] Idle cast") end
            tryOpenFishing()
            lastIdleOpen = now
        end
        return
    end

    if not qteActive then return end

    -- ── QTE đang active → check hit ──
    if not LineObj or not LineObj.Parent or not BarsFolder or not BarsFolder.Parent then
        initRefs()
    end
    if not LineObj or not BarsFolder then return end

    local lineRot = 0
    if not pcall(function() lineRot = LineObj.Rotation end) then return end
    lineRot = normAngle(lineRot + CFG.EarlyHit)

    local bars = BarsFolder:GetChildren()
    for i = 1, #bars do
        local bar = bars[i]
        if bar:IsA("ImageLabel") or bar:IsA("Frame") then
            local visible = false
            pcall(function() visible = bar.Visible end)
            if visible then
                local barRot = 0
                pcall(function() barRot = bar.Rotation end)

                local arcDeg = 15
                local n = bar.Name:match("_(%d+)$")
                if n then arcDeg = tonumber(n) or 15 end

                if angleDiff(lineRot, normAngle(barRot)) <= arcDeg / 2 then
                    if now - lastHitFire >= 0.05 then
                        fireQTEHit()
                        lastHitFire = now
                    end
                end
            end
        end
    end
end)

-- ══════════ GUI ══════════
pcall(function()
    if PlayerGui:FindFirstChild("_MacroGUI") then
        PlayerGui:FindFirstChild("_MacroGUI"):Destroy()
    end
end)

local sg = Instance.new("ScreenGui")
sg.Name = "_MacroGUI"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true; sg.Parent = PlayerGui

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 200, 0, 195)
panel.Position = UDim2.new(0, 12, 0.5, -97)
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
titleLbl.BackgroundTransparency = 1; titleLbl.Text = "🎣 Fish & Sell v4.5"
titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 11
titleLbl.TextColor3 = Color3.fromRGB(200,200,225)
titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.Parent = topBar

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1,-16,0,32); toggleBtn.Position = UDim2.new(0,8,0,30)
toggleBtn.BackgroundColor3 = Color3.fromRGB(35,175,95); toggleBtn.BorderSizePixel = 0
toggleBtn.Font = Enum.Font.GothamBold; toggleBtn.TextSize = 13
toggleBtn.TextColor3 = Color3.new(1,1,1); toggleBtn.Text = "AUTO FISH: ON"
toggleBtn.Parent = panel; Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,7)

local sellBtn = Instance.new("TextButton")
sellBtn.Size = UDim2.new(1,-16,0,30); sellBtn.Position = UDim2.new(0,8,0,67)
sellBtn.BackgroundColor3 = Color3.fromRGB(175,45,45); sellBtn.BorderSizePixel = 0
sellBtn.Font = Enum.Font.GothamBold; sellBtn.TextSize = 12
sellBtn.TextColor3 = Color3.new(1,1,1); sellBtn.Text = "AUTO SELL: OFF"
sellBtn.Parent = panel; Instance.new("UICorner", sellBtn).CornerRadius = UDim.new(0,7)

local bufLbl = Instance.new("TextLabel")
bufLbl.Size = UDim2.new(1,-16,0,13); bufLbl.Position = UDim2.new(0,8,0,103)
bufLbl.BackgroundTransparency = 1; bufLbl.Font = Enum.Font.Gotham; bufLbl.TextSize = 10
bufLbl.TextColor3 = Color3.fromRGB(200,140,50); bufLbl.Text = "Click 1 lần để capture buffer"
bufLbl.TextXAlignment = Enum.TextXAlignment.Left; bufLbl.Parent = panel

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1,-16,0,13); statusLbl.Position = UDim2.new(0,8,0,118)
statusLbl.BackgroundTransparency = 1; statusLbl.Font = Enum.Font.Gotham; statusLbl.TextSize = 10
statusLbl.TextColor3 = Color3.fromRGB(100,100,130); statusLbl.Text = "○ Đợi câu..."
statusLbl.TextXAlignment = Enum.TextXAlignment.Left; statusLbl.Parent = panel

-- Cast delay label + buttons
local castLbl = Instance.new("TextLabel")
castLbl.Size = UDim2.new(1,-16,0,13); castLbl.Position = UDim2.new(0,8,0,133)
castLbl.BackgroundTransparency = 1; castLbl.Font = Enum.Font.Gotham; castLbl.TextSize = 10
castLbl.TextColor3 = Color3.fromRGB(100,180,255)
castLbl.Text = string.format("Cast delay: %.2fs", CFG.CastDelay)
castLbl.TextXAlignment = Enum.TextXAlignment.Left; castLbl.Parent = panel

local earlyLbl = Instance.new("TextLabel")
earlyLbl.Size = UDim2.new(1,-16,0,13); earlyLbl.Position = UDim2.new(0,8,0,148)
earlyLbl.BackgroundTransparency = 1; earlyLbl.Font = Enum.Font.Gotham; earlyLbl.TextSize = 10
earlyLbl.TextColor3 = Color3.fromRGB(120,120,150)
earlyLbl.Text = string.format("Bù sớm: %.0f°", CFG.EarlyHit)
earlyLbl.TextXAlignment = Enum.TextXAlignment.Left; earlyLbl.Parent = panel

-- Row 1: cast delay buttons
local castRow = Instance.new("Frame")
castRow.Size = UDim2.new(1,-16,0,24); castRow.Position = UDim2.new(0,8,0,163)
castRow.BackgroundTransparency = 1; castRow.Parent = panel

-- Row 2: early hit buttons
local earlyRow = Instance.new("Frame")
earlyRow.Size = UDim2.new(1,-16,0,24); earlyRow.Position = UDim2.new(0,8,0,169)
earlyRow.BackgroundTransparency = 1; earlyRow.Parent = panel

local function makeBtn(text, xoff, parent)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,54,1,0); b.Position = UDim2.new(0,xoff,0,0)
    b.BackgroundColor3 = Color3.fromRGB(50,50,70); b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold; b.TextSize = 11
    b.TextColor3 = Color3.new(1,1,1); b.Text = text; b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    return b
end

-- Dùng 1 row, 4 buttons cạnh nhau
local btnRow = Instance.new("Frame")
btnRow.Size = UDim2.new(1,-16,0,24); btnRow.Position = UDim2.new(0,8,0,163)
btnRow.BackgroundTransparency = 1; btnRow.Parent = panel

local bcM = makeBtn("-cast", 0,   btnRow)
local bcP = makeBtn("+cast", 56,  btnRow)
local beM = makeBtn("- 1°",  116, btnRow)
local beP = makeBtn("+ 1°",  0,   btnRow)

-- Reposition 4 buttons đều nhau
bcM.Size = UDim2.new(0,42,1,0); bcM.Position = UDim2.new(0,0,  0,0)
bcP.Size = UDim2.new(0,42,1,0); bcP.Position = UDim2.new(0,46, 0,0)
beM.Size = UDim2.new(0,42,1,0); beM.Position = UDim2.new(0,96, 0,0)
beP.Size = UDim2.new(0,42,1,0); beP.Position = UDim2.new(0,142,0,0)

bcM.Text = "-0.05s"; bcP.Text = "+0.05s"
beM.Text = "- 1°";  beP.Text = "+ 1°"

bcM.MouseButton1Click:Connect(function()
    CFG.CastDelay = math.max(0, CFG.CastDelay - 0.05)
    castLbl.Text = string.format("Cast delay: %.2fs", CFG.CastDelay)
end)
bcP.MouseButton1Click:Connect(function()
    CFG.CastDelay = math.min(2, CFG.CastDelay + 0.05)
    castLbl.Text = string.format("Cast delay: %.2fs", CFG.CastDelay)
end)
beM.MouseButton1Click:Connect(function()
    CFG.EarlyHit = math.max(-15, CFG.EarlyHit - 1)
    earlyLbl.Text = string.format("Bù sớm: %.0f°", CFG.EarlyHit)
end)
beP.MouseButton1Click:Connect(function()
    CFG.EarlyHit = math.min(30, CFG.EarlyHit + 1)
    earlyLbl.Text = string.format("Bù sớm: %.0f°", CFG.EarlyHit)
end)

-- Status update
RunService.Heartbeat:Connect(function()
    if lastHitBuffer then
        bufLbl.Text = "✓ Buffer captured!"
        bufLbl.TextColor3 = Color3.fromRGB(80,200,120)
    end
    if MainFrame then
        local active = false; pcall(function() active = MainFrame.Visible end)
        if active then
            statusLbl.Text = "● QTE đang chạy"
            statusLbl.TextColor3 = Color3.fromRGB(80,200,120)
        elseif justClosed then
            statusLbl.Text = "⚡ Casting..."
            statusLbl.TextColor3 = Color3.fromRGB(255,200,50)
        else
            statusLbl.Text = "○ Đợi câu..."
            statusLbl.TextColor3 = Color3.fromRGB(100,100,130)
        end
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

print("[Fish & Sell v4.5] Loaded ✓")
