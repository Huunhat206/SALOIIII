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
    Enabled           = true,
    AutoSell          = false,
    SellInterval      = 3.0,
    IdleClickDelay    = 2.0,
    PingDelay         = 0.05,
    PerfectStrictness = 0.9,  -- nới rộng hơn để ít miss hơn
    AntiAFK           = true,
    AntiAFKInterval   = 60,   -- giây giữa mỗi lần anti-afk
    Debug             = false,
}

local ByteNetQuery      = ReplicatedStorage:WaitForChild("ByteNetQuery", 10)
local ByteNetUnreliable = ReplicatedStorage:WaitForChild("ByteNetUnreliable", 10)
local ByteNetReliable   = ReplicatedStorage:WaitForChild("ByteNetReliable", 10)

local SELL_BUF = buffer.fromstring("2")

-- ══════════ ANTI-AFK ══════════
local lastAFK = tick()
task.spawn(function()
    while true do
        task.wait(CFG.AntiAFKInterval)
        if not CFG.AntiAFK then continue end
        pcall(function()
            -- Jump giả để reset AFK timer
            local char = player.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Jump = true end
            -- VirtualUser fallback
            VirtualUser:CaptureController()
            VirtualUser:Button2Down(Vector2.new(0,0), camera.CFrame)
            task.wait(0.1)
            VirtualUser:Button2Up(Vector2.new(0,0), camera.CFrame)
        end)
        lastAFK = tick()
        if CFG.Debug then print("[AFK] Anti-AFK fired") end
    end
end)

-- ══════════ AUTO SELL ══════════
task.spawn(function()
    while true do
        if CFG.AutoSell and ByteNetReliable then
            pcall(function() ByteNetReliable:FireServer(SELL_BUF) end)
        end
        task.wait(CFG.SellInterval)
    end
end)

-- ══════════ OPEN FISHING ══════════
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
    -- Method 1: captured buffer (best, no mouse needed)
    if lastHitBuffer and ByteNetUnreliable then
        local ok = false
        pcall(function() ByteNetUnreliable:FireServer(lastHitBuffer); ok = true end)
        if ok then return end
    end
    -- Method 2: getconnections
    if not qteClickFunc then qteClickFunc = findQTEClickFunction() end
    if qteClickFunc and getconnections then
        local fired = false
        pcall(function()
            for _, c in pairs(getconnections(qteClickFunc.MouseButton1Click)) do c:Fire(); fired = true end
            for _, c in pairs(getconnections(qteClickFunc.Activated))        do c:Fire(); fired = true end
        end)
        if fired then return end
    end
    -- Method 3: VIM fallback
    local center = qteClickFunc
        and (qteClickFunc.AbsolutePosition + qteClickFunc.AbsoluteSize / 2)
        or  Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
    pcall(function()
        VIM:SendMouseButtonEvent(center.X, center.Y, 0, true,  game, 0)
        task.wait(0.02)
        VIM:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
    end)
end

-- Hook capture buffer
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

-- ══════════ ANGLE UTILS ══════════
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

-- ══════════ VELOCITY HISTORY (smoothed prediction) ══════════
-- Dùng rolling average của 5 frame thay vì chỉ 1 frame → ít bị giật lag
local ROT_HISTORY_SIZE = 5
local rotHistory = {}  -- {rot, time}

local function pushRotHistory(rot, t)
    table.insert(rotHistory, {rot=rot, t=t})
    if #rotHistory > ROT_HISTORY_SIZE then
        table.remove(rotHistory, 1)
    end
end

local function getSmoothedVelocity()
    if #rotHistory < 2 then return 0 end
    -- Linear regression qua tất cả điểm trong history
    local n   = #rotHistory
    local sumV = 0
    local count = 0
    for i = 2, n do
        local dt = rotHistory[i].t - rotHistory[i-1].t
        if dt > 0 and dt < 0.1 then
            local delta = rotHistory[i].rot - rotHistory[i-1].rot
            -- Wrap
            if delta > 180  then delta = delta - 360 end
            if delta < -180 then delta = delta + 360 end
            sumV  = sumV + (delta / dt)
            count = count + 1
        end
    end
    return count > 0 and (sumV / count) or 0
end

-- ══════════ MAIN LOOP ══════════
local lastIdleOpen = 0
local lastHitFire  = 0

RunService.Heartbeat:Connect(function()
    if not CFG.Enabled then return end
    local now = tick()

    -- QTE active check
    local qteActive = false
    local qteGui = PlayerGui:FindFirstChild("QTE")
    if qteGui and qteGui.Enabled then
        local main = qteGui:FindFirstChild("Main")
        if main and main.Visible then qteActive = true end
    end

    if not qteActive then
        -- Reset history khi QTE đóng
        rotHistory = {}
        local delay = math.max(2.0, CFG.IdleClickDelay)
        if now - lastIdleOpen >= delay then
            tryOpenFishing()
            lastIdleOpen = now
        end
        return
    end

    -- Init refs
    if not LineObj or not LineObj.Parent or not BarsFolder or not BarsFolder.Parent then
        initRefs()
    end
    if not LineObj or not BarsFolder then return end

    -- Lấy rotation hiện tại
    local currentRot = 0
    if not pcall(function() currentRot = LineObj.Rotation end) then return end

    -- Lưu history
    pushRotHistory(currentRot, now)

    -- Tính velocity đã smooth
    local vel = getSmoothedVelocity()

    -- Predict vị trí sau PingDelay giây
    local predictedRot = normAngle(currentRot + vel * CFG.PingDelay)

    if CFG.Debug and now % 1 < 0.02 then
        print(string.format("[v5] rot=%.1f vel=%.1f°/s pred=%.1f",
            currentRot, vel, predictedRot))
    end

    -- So sánh với từng Bar
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

                -- Strictness nới rộng → window lớn hơn → ít miss hơn
                local hitRadius = (arcDeg / 2) * CFG.PerfectStrictness

                local diff = angleDiff(predictedRot, normAngle(barRot))

                if CFG.Debug then
                    print(string.format("  %s | barRot=%.1f arc=±%.1f diff=%.1f %s",
                        bar.Name, barRot, hitRadius, diff,
                        diff <= hitRadius and "HIT!" or ""))
                end

                if diff <= hitRadius then
                    -- Cooldown ngắn hơn v4.7 (0.05 thay vì 0.08) → bắt được frame tốt hơn
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
sg.Name = "_MacroGUI"; sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true; sg.Parent = PlayerGui

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 205, 0, 210)
panel.Position = UDim2.new(0, 12, 0.5, -105)
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
titleLbl.BackgroundTransparency = 1; titleLbl.Text = "🎣 Hybrid Perfect v5.0"
titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 11
titleLbl.TextColor3 = Color3.fromRGB(200,200,225)
titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.Parent = topBar

-- Buttons
local function makeLargeBtn(text, y, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,-16,0,30); b.Position = UDim2.new(0,8,0,y)
    b.BackgroundColor3 = color; b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold; b.TextSize = 12
    b.TextColor3 = Color3.new(1,1,1); b.Text = text
    b.Parent = panel; Instance.new("UICorner", b).CornerRadius = UDim.new(0,7)
    return b
end

local toggleBtn = makeLargeBtn("AUTO FISH: ON",  30, Color3.fromRGB(35,175,95))
local sellBtn   = makeLargeBtn("AUTO SELL: OFF", 65, Color3.fromRGB(175,45,45))

-- Anti-AFK toggle
local afkBtn = Instance.new("TextButton")
afkBtn.Size = UDim2.new(1,-16,0,24); afkBtn.Position = UDim2.new(0,8,0,100)
afkBtn.BackgroundColor3 = Color3.fromRGB(40,100,175); afkBtn.BorderSizePixel = 0
afkBtn.Font = Enum.Font.GothamBold; afkBtn.TextSize = 11
afkBtn.TextColor3 = Color3.new(1,1,1); afkBtn.Text = "🛡 Anti-AFK: ON"
afkBtn.Parent = panel; Instance.new("UICorner", afkBtn).CornerRadius = UDim.new(0,6)
afkBtn.MouseButton1Click:Connect(function()
    CFG.AntiAFK = not CFG.AntiAFK
    afkBtn.BackgroundColor3 = CFG.AntiAFK
        and Color3.fromRGB(40,100,175) or Color3.fromRGB(60,60,80)
    afkBtn.Text = CFG.AntiAFK and "🛡 Anti-AFK: ON" or "🛡 Anti-AFK: OFF"
end)

local bufLbl = Instance.new("TextLabel")
bufLbl.Size = UDim2.new(1,-16,0,13); bufLbl.Position = UDim2.new(0,8,0,130)
bufLbl.BackgroundTransparency = 1; bufLbl.Font = Enum.Font.Gotham; bufLbl.TextSize = 10
bufLbl.TextColor3 = Color3.fromRGB(200,140,50)
bufLbl.Text = "Click 1 lần để capture buffer"
bufLbl.TextXAlignment = Enum.TextXAlignment.Left; bufLbl.Parent = panel

local statusLbl = Instance.new("TextLabel")
statusLbl.Size = UDim2.new(1,-16,0,13); statusLbl.Position = UDim2.new(0,8,0,145)
statusLbl.BackgroundTransparency = 1; statusLbl.Font = Enum.Font.Gotham; statusLbl.TextSize = 10
statusLbl.TextColor3 = Color3.fromRGB(100,100,130); statusLbl.Text = "○ Đợi câu..."
statusLbl.TextXAlignment = Enum.TextXAlignment.Left; statusLbl.Parent = panel

local afkLbl = Instance.new("TextLabel")
afkLbl.Size = UDim2.new(1,-16,0,13); afkLbl.Position = UDim2.new(0,8,0,160)
afkLbl.BackgroundTransparency = 1; afkLbl.Font = Enum.Font.Gotham; afkLbl.TextSize = 10
afkLbl.TextColor3 = Color3.fromRGB(100,140,200); afkLbl.Text = "AFK reset: chờ..."
afkLbl.TextXAlignment = Enum.TextXAlignment.Left; afkLbl.Parent = panel

local earlyLbl = Instance.new("TextLabel")
earlyLbl.Size = UDim2.new(1,-16,0,13); earlyLbl.Position = UDim2.new(0,8,0,174)
earlyLbl.BackgroundTransparency = 1; earlyLbl.Font = Enum.Font.Gotham; earlyLbl.TextSize = 10
earlyLbl.TextColor3 = Color3.fromRGB(120,120,150)
earlyLbl.Text = string.format("Ping bù: %d ms", CFG.PingDelay * 1000)
earlyLbl.TextXAlignment = Enum.TextXAlignment.Left; earlyLbl.Parent = panel

local btnRow = Instance.new("Frame")
btnRow.Size = UDim2.new(1,-16,0,24); btnRow.Position = UDim2.new(0,8,0,188)
btnRow.BackgroundTransparency = 1; btnRow.Parent = panel

local function makeSmallBtn(text, xoff)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0,54,1,0); b.Position = UDim2.new(0,xoff,0,0)
    b.BackgroundColor3 = Color3.fromRGB(50,50,70); b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold; b.TextSize = 11
    b.TextColor3 = Color3.new(1,1,1); b.Text = text; b.Parent = btnRow
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    return b
end

local btnM = makeSmallBtn("- 10ms", 0)
local btnP = makeSmallBtn("+ 10ms", 60)
btnM.MouseButton1Click:Connect(function()
    CFG.PingDelay = math.max(0, CFG.PingDelay - 0.01)
    earlyLbl.Text = string.format("Ping bù: %d ms", CFG.PingDelay * 1000)
end)
btnP.MouseButton1Click:Connect(function()
    CFG.PingDelay = math.min(0.5, CFG.PingDelay + 0.01)
    earlyLbl.Text = string.format("Ping bù: %d ms", CFG.PingDelay * 1000)
end)

-- Status update loop
RunService.Heartbeat:Connect(function()
    if lastHitBuffer then
        bufLbl.Text = "✓ Buffer captured!"
        bufLbl.TextColor3 = Color3.fromRGB(80,200,120)
    end
    if MainFrame then
        local active = false
        pcall(function() active = MainFrame.Visible end)
        statusLbl.Text = active and "● QTE đang chạy" or "○ Đợi câu..."
        statusLbl.TextColor3 = active
            and Color3.fromRGB(80,200,120) or Color3.fromRGB(100,100,130)
    end
    -- AFK countdown
    local nextAFK = math.max(0, math.ceil(CFG.AntiAFKInterval - (tick() - lastAFK)))
    afkLbl.Text = CFG.AntiAFK
        and string.format("AFK reset: %ds nữa", nextAFK)
        or  "AFK reset: OFF"
    afkLbl.TextColor3 = CFG.AntiAFK
        and Color3.fromRGB(100,160,220) or Color3.fromRGB(80,80,80)
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

print("[Hybrid Perfect v5.0] Loaded ✓")
print(">> Click thủ công 1 lần vào QTE để capture buffer!")