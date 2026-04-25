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
    PingDelay      = 0.05,
    Debug          = true,
}

local ByteNetQuery       = ReplicatedStorage:WaitForChild("ByteNetQuery", 10)
local ByteNetUnreliable  = ReplicatedStorage:WaitForChild("ByteNetUnreliable", 10)
local ByteNetReliable    = ReplicatedStorage:WaitForChild("ByteNetReliable", 10)

local SELL_BUF = buffer.fromstring("2")

task.spawn(function()
    while true do
        if CFG.AutoSell and ByteNetReliable then
            pcall(function() ByteNetReliable:FireServer(SELL_BUF) end)
        end
        task.wait(CFG.SellInterval)
    end
end)

local function tryOpenFishing()
    pcall(function()
        local char = player.Character
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end
        
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(0, 0), camera.CFrame)
        task.wait(0.1)
        VirtualUser:Button1Up(Vector2.new(0, 0), camera.CFrame)
    end)
end

local qteClickFunc = nil 
local function findQTEClickFunction()
    local qte = PlayerGui:FindFirstChild("QTE")
    if not qte then return nil end
    local main = qte:FindFirstChild("Main")
    if not main then return nil end

    for _, child in ipairs(main:GetDescendants()) do
        if child:IsA("TextButton") or child:IsA("ImageButton") then
            return child
        end
    end
    return nil
end

local lastHitBuffer = nil
local function fireQTEHit()
    if lastHitBuffer and ByteNetUnreliable then
        local ok = false
        pcall(function() ByteNetUnreliable:FireServer(lastHitBuffer); ok = true end)
        if ok then return end
    end

    if not qteClickFunc then qteClickFunc = findQTEClickFunction() end
    if qteClickFunc then
        local fired = false
        if getconnections then
            pcall(function()
                for _, conn in pairs(getconnections(qteClickFunc.MouseButton1Click)) do conn:Fire(); fired = true end
                for _, conn in pairs(getconnections(qteClickFunc.Activated)) do conn:Fire(); fired = true end
            end)
        end
        if fired then return end
    end

    local center = qteClickFunc and (qteClickFunc.AbsolutePosition + qteClickFunc.AbsoluteSize / 2) or Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
    pcall(function()
        VIM:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
        task.wait(0.02)
        VIM:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
    end)
end

if hookfunction and ByteNetUnreliable then
    local origFire
    origFire = hookfunction(ByteNetUnreliable.FireServer, newcclosure(function(self, ...)
        if self == ByteNetUnreliable then
            local args = {...}
            if args[1] and typeof(args[1]) == "buffer" then
                local qte = PlayerGui:FindFirstChild("QTE")
                local main = qte and qte:FindFirstChild("Main")
                if main and main.Visible then lastHitBuffer = args[1] end
            end
        end
        return origFire(self, ...)
    end))
end

local QTE, MainFrame, LineObj, BarsFolder
local function initRefs()
    QTE = PlayerGui:FindFirstChild("QTE")
    if not QTE then return false end
    MainFrame  = QTE:FindFirstChild("Main")
    if not MainFrame then return false end
    LineObj    = MainFrame:FindFirstChild("Line")
    BarsFolder = MainFrame:FindFirstChild("Bars")
    return LineObj ~= nil and BarsFolder ~= nil
end

local lastRot = nil
local lastTime = tick()
local lastIdleOpen = 0
local lastHitFire = 0

RunService.Heartbeat:Connect(function()
    if not CFG.Enabled then return end
    local now = tick()

    local qteActive = false
    local qteGui = PlayerGui:FindFirstChild("QTE")
    if qteGui and qteGui.Enabled then
        local main = qteGui:FindFirstChild("Main")
        if main and main.Visible then qteActive = true end
    end

    if not qteActive then
        lastRot = nil
        local delayTime = CFG.IdleClickDelay < 2 and 2.0 or CFG.IdleClickDelay
        if now - lastIdleOpen >= delayTime then
            tryOpenFishing()
            lastIdleOpen = now
        end
        return 
    end

    if not LineObj or not LineObj.Parent or not BarsFolder or not BarsFolder.Parent then initRefs() end
    if not LineObj or not BarsFolder then return end

    local currentRot = 0
    if not pcall(function() currentRot = LineObj.Rotation end) then return end

    if lastRot then
        local dt = now - lastTime
        if dt > 0 and dt < 0.5 then
            local delta = currentRot - lastRot
            if delta > 180 then delta = delta - 360
            elseif delta < -180 then delta = delta + 360 end
            
            local vel = delta / dt
            
            if math.abs(vel) > 10 then
                local bars = BarsFolder:GetChildren()
                for i = 1, #bars do
                    local bar = bars[i]
                    if (bar:IsA("ImageLabel") or bar:IsA("Frame")) and bar.Visible then
                        local barRot = 0
                        pcall(function() barRot = bar.Rotation end)
                        
                        local dist = barRot - currentRot
                        if dist > 180 then dist = dist - 360
                        elseif dist < -180 then dist = dist + 360 end
                        
                        if (vel > 0 and dist > 0 and dist < 120) or (vel < 0 and dist < 0 and dist > -120) then
                            local timeToCenter = dist / vel
                            
                            if timeToCenter <= CFG.PingDelay and timeToCenter >= -0.05 then
                                if now - lastHitFire >= 0.1 then
                                    fireQTEHit()
                                    lastHitFire = now
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    lastRot = currentRot
    lastTime = now
end)

pcall(function() if PlayerGui:FindFirstChild("_MacroGUI") then PlayerGui:FindFirstChild("_MacroGUI"):Destroy() end end)
local sg = Instance.new("ScreenGui"); sg.Name = "_MacroGUI"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true; sg.Parent = PlayerGui
local panel = Instance.new("Frame"); panel.Size = UDim2.new(0, 200, 0, 175); panel.Position = UDim2.new(0, 12, 0.5, -87); panel.BackgroundColor3 = Color3.fromRGB(14,14,18); panel.BorderSizePixel = 0; panel.Parent = sg; Instance.new("UICorner", panel).CornerRadius = UDim.new(0,10)
local topBar = Instance.new("Frame"); topBar.Size = UDim2.new(1,0,0,26); topBar.BackgroundColor3 = Color3.fromRGB(26,26,34); topBar.BorderSizePixel = 0; topBar.Parent = panel; Instance.new("UICorner", topBar).CornerRadius = UDim.new(0,10)
local titleLbl = Instance.new("TextLabel"); titleLbl.Size = UDim2.new(1,-10,1,0); titleLbl.Position = UDim2.new(0,10,0,0); titleLbl.BackgroundTransparency = 1; titleLbl.Text = "🎣 Dynamic Velocity v4.6"; titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 11; titleLbl.TextColor3 = Color3.fromRGB(200,200,225); titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.Parent = topBar
local toggleBtn = Instance.new("TextButton"); toggleBtn.Size = UDim2.new(1,-16,0,32); toggleBtn.Position = UDim2.new(0,8,0,30); toggleBtn.BackgroundColor3 = Color3.fromRGB(35,175,95); toggleBtn.BorderSizePixel = 0; toggleBtn.Font = Enum.Font.GothamBold; toggleBtn.TextSize = 13; toggleBtn.TextColor3 = Color3.new(1,1,1); toggleBtn.Text = "AUTO FISH: ON"; toggleBtn.Parent = panel; Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,7)
local sellBtn = Instance.new("TextButton"); sellBtn.Size = UDim2.new(1,-16,0,30); sellBtn.Position = UDim2.new(0,8,0,67); sellBtn.BackgroundColor3 = Color3.fromRGB(175,45,45); sellBtn.BorderSizePixel = 0; sellBtn.Font = Enum.Font.GothamBold; sellBtn.TextSize = 12; sellBtn.TextColor3 = Color3.new(1,1,1); sellBtn.Text = "AUTO SELL: OFF"; sellBtn.Parent = panel; Instance.new("UICorner", sellBtn).CornerRadius = UDim.new(0,7)
local bufLbl = Instance.new("TextLabel"); bufLbl.Size = UDim2.new(1,-16,0,14); bufLbl.Position = UDim2.new(0,8,0,102); bufLbl.BackgroundTransparency = 1; bufLbl.Font = Enum.Font.Gotham; bufLbl.TextSize = 10; bufLbl.TextColor3 = Color3.fromRGB(200,140,50); bufLbl.Text = "Click 1 lần để capture buffer"; bufLbl.TextXAlignment = Enum.TextXAlignment.Left; bufLbl.Parent = panel
local statusLbl = Instance.new("TextLabel"); statusLbl.Size = UDim2.new(1,-16,0,14); statusLbl.Position = UDim2.new(0,8,0,117); statusLbl.BackgroundTransparency = 1; statusLbl.Font = Enum.Font.Gotham; statusLbl.TextSize = 10; statusLbl.TextColor3 = Color3.fromRGB(100,100,130); statusLbl.Text = "○ Đợi câu..."; statusLbl.TextXAlignment = Enum.TextXAlignment.Left; statusLbl.Parent = panel
local earlyLbl = Instance.new("TextLabel"); earlyLbl.Size = UDim2.new(1,-16,0,14); earlyLbl.Position = UDim2.new(0,8,0,131); earlyLbl.BackgroundTransparency = 1; earlyLbl.Font = Enum.Font.Gotham; earlyLbl.TextSize = 10; earlyLbl.TextColor3 = Color3.fromRGB(120,120,150); earlyLbl.Text = string.format("Ping mạng: %d ms", CFG.PingDelay * 1000); earlyLbl.TextXAlignment = Enum.TextXAlignment.Left; earlyLbl.Parent = panel
local btnRow = Instance.new("Frame"); btnRow.Size = UDim2.new(1,-16,0,24); btnRow.Position = UDim2.new(0,8,0,146); btnRow.BackgroundTransparency = 1; btnRow.Parent = panel
local function makeBtn(text, xoff) local b = Instance.new("TextButton"); b.Size = UDim2.new(0,54,1,0); b.Position = UDim2.new(0,xoff,0,0); b.BackgroundColor3 = Color3.fromRGB(50,50,70); b.BorderSizePixel = 0; b.Font = Enum.Font.GothamBold; b.TextSize = 12; b.TextColor3 = Color3.new(1,1,1); b.Text = text; b.Parent = btnRow; Instance.new("UICorner", b).CornerRadius = UDim.new(0,6); return b end
local btnM = makeBtn("- 10ms", 0); local btnP = makeBtn("+ 10ms", 60)
btnM.MouseButton1Click:Connect(function() CFG.PingDelay = math.max(0, CFG.PingDelay - 0.010); earlyLbl.Text = string.format("Ping mạng: %d ms", CFG.PingDelay * 1000) end)
btnP.MouseButton1Click:Connect(function() CFG.PingDelay = math.min(0.5, CFG.PingDelay + 0.010); earlyLbl.Text = string.format("Ping mạng: %d ms", CFG.PingDelay * 1000) end)
RunService.Heartbeat:Connect(function()
    if lastHitBuffer then bufLbl.Text = "✓ Buffer captured!"; bufLbl.TextColor3 = Color3.fromRGB(80,200,120) end
    if MainFrame then
        local active = false; pcall(function() active = MainFrame.Visible end)
        statusLbl.Text = active and "● QTE đang chạy" or "○ Đợi câu..."
        statusLbl.TextColor3 = active and Color3.fromRGB(80,200,120) or Color3.fromRGB(100,100,130)
    end
end)
local function setFishing(s) CFG.Enabled = s; toggleBtn.BackgroundColor3 = s and Color3.fromRGB(35,175,95) or Color3.fromRGB(175,45,45); toggleBtn.Text = s and "AUTO FISH: ON" or "AUTO FISH: OFF" end
local function setSelling(s) CFG.AutoSell = s; sellBtn.BackgroundColor3 = s and Color3.fromRGB(35,175,95) or Color3.fromRGB(175,45,45); sellBtn.Text = s and "AUTO SELL: ON" or "AUTO SELL: OFF" end
toggleBtn.MouseButton1Click:Connect(function() setFishing(not CFG.Enabled) end)
sellBtn.MouseButton1Click:Connect(function() setSelling(not CFG.AutoSell) end)
local drag, dStart, dPos = false, nil, nil
topBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag=true; dStart=i.Position; dPos=panel.Position end end)
topBar.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag=false end end)
UserInputService.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - dStart; panel.Position = UDim2.new(dPos.X.Scale, dPos.X.Offset+d.X, dPos.Y.Scale, dPos.Y.Offset+d.Y) end end)
