-- =====================================================
--   ✦ NEBULA HUB - DUNGEON QUEST REBORN ✦
--   UI Pro | Tối ưu mobile | Auto Combat Pro
-- =====================================================

local player = game.Players.LocalPlayer
local uis = game:GetService("UserInputService")
local vu = game:GetService("VirtualUser")
local ws = game:GetService("Workspace")
local ts = game:GetService("TweenService")

-- ====== CẤU HÌNH ======
local Config = {
    AutoFarm = true,
    AutoSkill = true,
    AutoTP = true,
    WalkSpeed = 23,
    FarmRange = 120,
    TPRange = 40,
}

-- ====== BIẾN TOÀN CỤ ======
local char = player.Character
local hum = char and char:FindFirstChild("Humanoid")
local root = char and char:FindFirstChild("HumanoidRootPart")
local currentTarget = nil
local lastDodgeTime = 0
local lastTPTime = 0
local skillCooldown = {}
local gui = nil

-- ====== HÀM LẤY NHÂN VẬT ======
local function getChar()
    char = player.Character
    if char then
        hum = char:FindFirstChild("Humanoid")
        root = char:FindFirstChild("HumanoidRootPart")
    end
    return char, hum, root
end

-- ====== ĐỊNH VỊ QUÁI ======
local function findNearestEnemy()
    local char, hum, root = getChar()
    if not char or not root then return nil end
    local nearest, minDist = nil, math.huge
    for _, v in pairs(ws:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= char then
            local target = v:FindFirstChild("HumanoidRootPart")
            if target and v.Humanoid.Health > 0 then
                local dist = (target.Position - root.Position).Magnitude
                if dist < minDist and dist < Config.FarmRange then
                    minDist = dist
                    nearest = v
                end
            end
        end
    end
    return nearest, minDist
end

-- ====== SPAM SKILL ======
local function spamSkills()
    if not Config.AutoSkill or not hum then return end
    local skills = {}
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
            local cd = skillCooldown[tool.Name] or 0
            if tick() - cd > 0.5 then
                table.insert(skills, tool)
            end
        end
    end
    for _, skill in ipairs(skills) do
        hum:EquipTool(skill)
        task.wait(0.05)
        vu:ClickButton1(Vector2.new())
        skillCooldown[skill.Name] = tick()
    end
end

-- ====== TP KHI NÉ ======
local function teleportDodge(target, dist)
    if not Config.AutoTP or not root then return false end
    if not target or not target.HumanoidRootPart then return false end
    if tick() - lastTPTime < 1.5 then return false end
    if dist < 12 then
        local angle = math.rad(math.random(0, 360))
        local randomDir = Vector3.new(math.cos(angle), 0, math.sin(angle))
        local tpPos = target.HumanoidRootPart.Position + randomDir * Config.TPRange
        local hasTP = false
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("teleport") or tool.Name:lower():find("tp") or tool.Name:lower():find("blink")) then
                hum:EquipTool(tool)
                task.wait(0.05)
                vu:ClickButton1(Vector2.new())
                hasTP = true
                break
            end
        end
        if not hasTP then
            root.CFrame = CFrame.new(tpPos)
        end
        lastTPTime = tick()
        return true
    end
    return false
end

-- ====== NÉ THƯỜNG ======
local function normalDodge(target, dist)
    if not root or not hum then return false end
    if tick() - lastDodgeTime < 0.3 then return false end
    if dist < 20 then
        local angle = math.rad(math.random(0, 360))
        local randomDir = Vector3.new(math.cos(angle), 0, math.sin(angle))
        hum.Jump = true
        hum:MoveTo(target.HumanoidRootPart.Position + randomDir * 12)
        lastDodgeTime = tick()
        return true
    end
    return false
end

local function smartDodge(target, dist)
    if not target then return end
    if not normalDodge(target, dist) or dist < 8 then
        teleportDodge(target, dist)
    end
end

-- ====== AUTO FARM ======
local function autoFarm()
    task.spawn(function()
        while true do
            task.wait(0.15)
            if not Config.AutoFarm then task.wait(1) continue end
            local char, hum, root = getChar()
            if not char or not hum or not root then continue end
            local target, dist = findNearestEnemy()
            currentTarget = target
            if target then
                smartDodge(target, dist)
                if dist > 10 then
                    hum:MoveTo(target.HumanoidRootPart.Position)
                end
                spamSkills()
                vu:ClickButton1(Vector2.new())
            end
        end
    end)
end

-- ====== SPEED & ANTI AFK ======
local function speedLoop()
    task.spawn(function()
        while true do
            task.wait(0.15)
            local char, hum = getChar()
            if char and hum then
                hum.WalkSpeed = Config.WalkSpeed
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end
        end
    end)
end

-- =====================================================
--   ✦ UI PRO - NEBULA HUB (TỐI ƯU MOBILE) ✦
-- =====================================================

local function createUI()
    gui = Instance.new("ScreenGui")
    gui.Name = "NebulaHub"
    gui.Parent = player:WaitForChild("PlayerGui")
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main Frame - bo tròn, trong suốt
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 280, 0, 380)
    main.Position = UDim2.new(0.5, -140, 0.25, 0)
    main.BackgroundColor3 = Color3.fromRGB(12, 12, 28)
    main.BackgroundTransparency = 0.08
    main.Parent = gui
    main.ClipsDescendants = true
    
    -- Đổ bóng
    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045230"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.Parent = main
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = main
    
    -- Thanh viền Neon
    local border = Instance.new("Frame")
    border.Size = UDim2.new(1, 0, 0, 2)
    border.Position = UDim2.new(0, 0, 0, 0)
    border.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
    border.BackgroundTransparency = 0.3
    border.Parent = main
    
    -- Header với gradient
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 45)
    header.BackgroundColor3 = Color3.fromRGB(25, 25, 50)
    header.BackgroundTransparency = 0.2
    header.Parent = main
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 16)
    headerCorner.Parent = header
    
    -- Icon + Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.7, 0, 1, 0)
    title.Position = UDim2.new(0.05, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "✦ NEBULA HUB"
    title.TextColor3 = Color3.fromRGB(0, 200, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = header
    
    -- Version
    local ver = Instance.new("TextLabel")
    ver.Size = UDim2.new(0.2, 0, 0.5, 0)
    ver.Position = UDim2.new(0.7, 0, 0.25, 0)
    ver.BackgroundTransparency = 1
    ver.Text = "v2.0"
    ver.TextColor3 = Color3.fromRGB(150, 150, 200)
    ver.TextScaled = true
    ver.Font = Enum.Font.GothamMedium
    ver.Parent = header
    
    -- Nút đóng
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 28, 0, 28)
    close.Position = UDim2.new(1, -36, 0, 8)
    close.BackgroundColor3 = Color3.fromRGB(200, 50, 60)
    close.Text = "✕"
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.TextScaled = true
    close.Font = Enum.Font.GothamBold
    close.Parent = header
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = close
    
    close.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
    
    -- Body (chứa toggle)
    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, -20, 0, 240)
    body.Position = UDim2.new(0, 10, 0, 55)
    body.BackgroundTransparency = 1
    body.Parent = main
    
    -- Hàm tạo toggle đẹp (dạng switch)
    local function createToggle(y, text, key, def, icon)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 42)
        frame.Position = UDim2.new(0, 0, 0, y)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 55)
        frame.BackgroundTransparency = 0.4
        frame.Parent = body
        
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 10)
        frameCorner.Parent = frame
        
        -- Icon
        local iconLabel = Instance.new("TextLabel")
        iconLabel.Size = UDim2.new(0, 30, 0, 30)
        iconLabel.Position = UDim2.new(0, 8, 0.5, -15)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = icon or "◆"
        iconLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
        iconLabel.TextScaled = true
        iconLabel.Parent = frame
        
        -- Label
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.5, 0, 1, 0)
        label.Position = UDim2.new(0, 45, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(220, 220, 255)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextScaled = true
        label.Font = Enum.Font.GothamMedium
        label.Parent = frame
        
        -- Switch
        local switch = Instance.new("TextButton")
        switch.Size = UDim2.new(0, 50, 0, 26)
        switch.Position = UDim2.new(0.88, -25, 0.5, -13)
        switch.BackgroundColor3 = def and Color3.fromRGB(0, 200, 120) or Color3.fromRGB(180, 50, 60)
        switch.Text = def and "ON" or "OFF"
        switch.TextColor3 = Color3.fromRGB(255, 255, 255)
        switch.TextScaled = true
        switch.Font = Enum.Font.GothamBold
        switch.Parent = frame
        
        local switchCorner = Instance.new("UICorner")
        switchCorner.CornerRadius = UDim.new(0, 8)
        switchCorner.Parent = switch
        
        local state = def
        switch.MouseButton1Click:Connect(function()
            state = not state
            Config[key] = state
            switch.BackgroundColor3 = state and Color3.fromRGB(0, 200, 120) or Color3.fromRGB(180, 50, 60)
            switch.Text = state and "ON" or "OFF"
            if key == "AutoFarm" and state then autoFarm() end
        end)
        
        return switch
    end
    
    -- Tạo các toggle với icon
    createToggle(0, "Auto Farm", "AutoFarm", true, "⚔️")
    createToggle(48, "Auto Skill", "AutoSkill", true, "🌀")
    createToggle(96, "Auto TP Dodge", "AutoTP", true, "🌊")
    
    -- Status bar (đẹp hơn)
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(1, 0, 0, 35)
    statusFrame.Position = UDim2.new(0, 0, 0, 148)
    statusFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 45)
    statusFrame.BackgroundTransparency = 0.4
    statusFrame.Parent = body
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 10)
    statusCorner.Parent = statusFrame
    
    local statusIcon = Instance.new("TextLabel")
    statusIcon.Size = UDim2.new(0, 25, 0, 25)
    statusIcon.Position = UDim2.new(0, 8, 0.5, -12.5)
    statusIcon.BackgroundTransparency = 1
    statusIcon.Text = "📡"
    statusIcon.TextScaled = true
    statusIcon.Parent = statusFrame
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0.8, 0, 1, 0)
    status.Position = UDim2.new(0, 40, 0, 0)
    status.BackgroundTransparency = 1
    status.Text = "Đang tìm quái..."
    status.TextColor3 = Color3.fromRGB(200, 200, 255)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextScaled = true
    status.Font = Enum.Font.GothamMedium
    status.Parent = statusFrame
    
    -- Cập nhật status
    task.spawn(function()
        while true do
            task.wait(0.3)
            if currentTarget then
                status.Text = "⚔️ " .. currentTarget.Name
                statusIcon.Text = "⚔️"
            else
                status.Text = "Đang tìm quái..."
                statusIcon.Text = "📡"
            end
        end
    end)
    
    -- Footer
    local footer = Instance.new("Frame")
    footer.Size = UDim2.new(1, 0, 0, 28)
    footer.Position = UDim2.new(0, 0, 1, -28)
    footer.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    footer.BackgroundTransparency = 0.3
    footer.Parent = main
    
    local footerCorner = Instance.new("UICorner")
    footerCorner.CornerRadius = UDim.new(0, 16)
    footerCorner.Parent = footer
    
    local footerText = Instance.new("TextLabel")
    footerText.Size = UDim2.new(1, 0, 1, 0)
    footerText.BackgroundTransparency = 1
    footerText.Text = "✦ F9 toggle | 🌙 Nebula Hub"
    footerText.TextColor3 = Color3.fromRGB(150, 150, 200)
    footerText.TextScaled = true
    footerText.Font = Enum.Font.GothamMedium
    footerText.Parent = footer
    
    -- Nút toggle nhỏ gọn
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 60, 0, 24)
    toggleBtn.Position = UDim2.new(1, -68, 1, -26)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
    toggleBtn.Text = "▶"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextScaled = true
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Parent = main
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 6)
    toggleCorner.Parent = toggleBtn
    
    -- Thu gọn/mở rộng UI
    local isMinimized = false
    toggleBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            main.Size = UDim2.new(0, 280, 0, 60)
            body.Visible = false
            footer.Visible = false
            toggleBtn.Text = "◀"
        else
            main.Size = UDim2.new(0, 280, 0, 380)
            body.Visible = true
            footer.Visible = true
            toggleBtn.Text = "▶"
        end
    end)
    
    return gui
end

-- ====== KHỞI TẠO ======
createUI()
speedLoop()
autoFarm()

player.CharacterAdded:Connect(function(c)
    char = c
    hum = c:WaitForChild("Humanoid")
    root = c:WaitForChild("HumanoidRootPart")
    task.wait(1)
    speedLoop()
    if Config.AutoFarm then autoFarm() end
end)

if getChar() then
    if Config.AutoFarm then autoFarm() end
end

-- F9 Toggle
uis.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.F9 and not gp then
        local g = player.PlayerGui:FindFirstChild("NebulaHub")
        if g then g.Enabled = not g.Enabled end
    end
end)

print("✦ Nebula Hub loaded!")
print("📌 Press F9 to toggle GUI")
print("🌙 UI Pro | Tối ưu Mobile")lCount = dodgeFailCount + 1
    return false
end

-- ====== 3. NÉ ĐÒN TỔNG HỢP ======
local function smartDodge(target, info)
    if not target or not target.HumanoidRootPart then return end
    
    -- Thử né thường trước
    local dodged = normalDodge(target, info)
    
    -- Nếu né thường thất bại hoặc không đủ an toàn, dùng TP
    if not dodged or (info and info.Distance < 8) then
        if Config.AutoTP then
            teleportDodge(target, info)
        end
    end
end

-- ====== AUTO COMBAT ======
local function autoCombat()
    task.spawn(function()
        while true do
            task.wait(0.2)
            if not Config.AutoFarm then 
                isFighting = false
                task.wait(1) 
                continue 
            end
            
            local char, hum, root = getChar()
            if not char or not hum or not root then continue end
            
            local target = findBestTarget()
            
            if target then
                currentTarget = target
                isFighting = true
                local info = analyzeEnemy(target)
                
                if info then
                    -- Di chuyển đến quái
                    if info.Distance > 15 then
                        hum:MoveTo(info.Position)
                    end
                    
                    -- Tung skill
                    if Config.AutoSkill then
                        useSkills(target, false)
                    end
                    
                    -- Tấn công thường
                    vu:ClickButton1(Vector2.new())
                    
                    -- Né đòn thông minh (kết hợp normal + TP)
                    smartDodge(target, info)
                    
                    -- Heal
                    if Config.AutoHeal and hum.Health / hum.MaxHealth < Config.HealThreshold / 100 then
                        useSkills(target, true)
                    end
                end
            else
                isFighting = false
                for _, v in pairs(ws:GetChildren()) do
                    if v:IsA("BasePart") and (v.Name:lower():find("portal") or v.Name:lower():find("start")) then
                        hum:MoveTo(v.Position)
                        break
                    end
                end
            end
        end
    end)
end

-- ====== SPEED HACK & ANTI AFK ======
local function speedLoop()
    task.spawn(function()
        while true do
            task.wait(0.15)
            local char, hum = getChar()
            if char and hum then
                hum.WalkSpeed = Config.WalkSpeed
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end
        end
    end)
end

-- ====== GUI ======
local function createGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "NovaAutoCombat"
    gui.Parent = player:WaitForChild("PlayerGui")
    gui.ResetOnSpawn = false
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 320)
    frame.Position = UDim2.new(0.5, -140, 0.3, 0)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
    frame.BackgroundTransparency = 0.05
    frame.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    -- Title
    local title = Instance.new("TextButton")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
    title.Text = "🌀 Nova Auto Combat v5.0"
    title.TextColor3 = Color3.fromRGB(100, 200, 255)
    title.TextScaled = true
    title.Parent = frame
    
    -- Close
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 25, 0, 25)
    close.Position = UDim2.new(1, -30, 0, 5)
    close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    close.Text = "✕"
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.TextScaled = true
    close.Parent = frame
    close.MouseButton1Click:Connect(function() gui:Destroy() end)
    
    local function createToggle(y, text, key, def)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.9, 0, 0, 28)
        btn.Position = UDim2.new(0.05, 0, 0, y)
        btn.BackgroundColor3 = def and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(180, 50, 50)
        btn.Text = text .. ": " .. (def and "ON" or "OFF")
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextScaled = true
        btn.Parent = frame
        
        local state = def
        btn.MouseButton1Click:Connect(function()
            state = not state
            Config[key] = state
            btn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(180, 50, 50)
            btn.Text = text .. ": " .. (state and "ON" or "OFF")
        end)
        return btn
    end
    
    createToggle(45, "⚔️ Auto Farm", "AutoFarm", true)
    createToggle(80, "🌀 Auto Skill", "AutoSkill", true)
    createToggle(115, "🛡️ Auto Dodge", "AutoDodge", true)
    createToggle(150, "🌀 Auto TP Dodge", "AutoTP", true)
    createToggle(185, "❤️ Auto Heal", "AutoHeal", true)
    
    -- Status
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0.9, 0, 0, 25)
    status.Position = UDim2.new(0.05, 0, 0, 225)
    status.BackgroundTransparency = 1
    status.Text = "🎯 Status: Đang chờ..."
    status.TextColor3 = Color3.fromRGB(200, 200, 255)
    status.TextScaled = true
    status.Parent = frame
    
    task.spawn(function()
        while true do
            task.wait(0.5)
            if isFighting and currentTarget then
                local info = analyzeEnemy(currentTarget)
                if info then
                    status.Text = "⚔️ " .. info.Name .. " | ❤️ " .. math.round(info.HealthPercent) .. "%"
                else
                    status.Text = "🎯 Đang tìm quái..."
                end
            else
                status.Text = "🎯 Đang tìm quái..."
            end
        end
    end)
    
    -- Footer
    local footer = Instance.new("TextLabel")
    footer.Size = UDim2.new(1, 0, 0, 20)
    footer.Position = UDim2.new(0, 0, 1, -22)
    footer.BackgroundTransparency = 1
    footer.Text = "🔹 F9 | ⚡ Né thường + TP khẩn cấp"
    footer.TextColor3 = Color3.fromRGB(150, 150, 200)
    footer.TextScaled = true
    footer.Parent = frame
    
    return gui
end

-- ====== KHỞI TẠO ======
createGUI()
speedLoop()
autoCombat()

player.CharacterAdded:Connect(function(c)
    char = c
    hum = c:WaitForChild("Humanoid")
    root = c:WaitForChild("HumanoidRootPart")
    task.wait(1)
    speedLoop()
    if Config.AutoFarm then autoCombat() end
end)

if getChar() then
    if Config.AutoFarm then autoCombat() end
end

uis.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.F9 and not gp then
        local g = player.PlayerGui:FindFirstChild("NovaAutoCombat")
        if g then g.Enabled = not g.Enabled end
    end
end)

print("🌀 Nova Auto Combat v5.0 loaded!")
print("📌 Press F9 to toggle GUI")
print("⚡ Né thường → TP khẩn cấp khi nguy hiểm")
