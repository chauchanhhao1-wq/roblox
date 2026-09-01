-- =====================================================
--   🤖 NOVA AUTO COMBAT - DUNGEON QUEST REBORN v5.0
--   Tự động: Di chuyển → Phân tích → Tung skill → Né đòn + TP
-- =====================================================

local player = game.Players.LocalPlayer
local uis = game:GetService("UserInputService")
local vu = game:GetService("VirtualUser")
local ws = game:GetService("Workspace")
local rs = game:GetService("RunService")
local tps = game:GetService("TweenService")

-- ====== CẤU HÌNH ======
local Config = {
    AutoFarm = true,
    AutoSkill = true,
    AutoDodge = true,
    AutoHeal = true,
    AutoTP = true,          -- Bật/tắt Teleport né đòn
    WalkSpeed = 23,
    FarmRange = 120,
    DodgeChance = 60,
    HealThreshold = 40,
    TPRange = 50,           -- Khoảng cách TP tối đa
}

-- ====== BIẾN TOÀN CỤ ======
local char = player.Character
local hum = char and char:FindFirstChild("Humanoid")
local root = char and char:FindFirstChild("HumanoidRootPart")
local currentTarget = nil
local lastDodgeTime = 0
local lastTPTime = 0
local skillCooldown = {}
local isFighting = false
local dodgeFailCount = 0

-- ====== HÀM LẤY NHÂN VẬT ======
local function getChar()
    char = player.Character
    if char then
        hum = char:FindFirstChild("Humanoid")
        root = char:FindFirstChild("HumanoidRootPart")
    end
    return char, hum, root
end

-- ====== PHÂN TÍCH QUÁI ======
local function analyzeEnemy(enemy)
    if not enemy or not enemy:FindFirstChild("Humanoid") then return nil end
    
    local enemyHum = enemy.Humanoid
    local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
    
    if not enemyRoot or enemyHum.Health <= 0 then return nil end
    
    local info = {
        Name = enemy.Name,
        Health = enemyHum.Health,
        MaxHealth = enemyHum.MaxHealth,
        Position = enemyRoot.Position,
        Distance = root and (enemyRoot.Position - root.Position).Magnitude or 999,
        IsBoss = enemy.Name:lower():find("boss") or enemy.Name:lower():find("king") or false,
        HealthPercent = (enemyHum.Health / enemyHum.MaxHealth) * 100,
        IsDangerous = (enemyHum.Health / enemyHum.MaxHealth) > 0.7,
    }
    
    return info
end

-- ====== TÌM QUÁI MỤC TIÊU ======
local function findBestTarget()
    local char, hum, root = getChar()
    if not char or not root then return nil end
    
    local bestTarget = nil
    local bestScore = -math.huge
    
    for _, v in pairs(ws:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= char then
            local info = analyzeEnemy(v)
            if info and info.Distance < Config.FarmRange then
                local score = 1000 / (info.Distance + 1)
                score = score + (100 - info.HealthPercent) * 2
                if info.IsBoss then score = score + 500 end
                
                if score > bestScore then
                    bestScore = score
                    bestTarget = v
                end
            end
        end
    end
    
    return bestTarget
end

-- ====== LẤY SKILL ======
local function getAvailableSkills()
    local skills = {}
    if char then
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
                local cd = skillCooldown[tool.Name] or 0
                if tick() - cd > 1.5 then
                    local skillType = "Normal"
                    if tool.Name:lower():find("ulti") or tool.Name:lower():find("ult") then
                        skillType = "Ultimate"
                    elseif tool.Name:lower():find("heal") or tool.Name:lower():find("health") then
                        skillType = "Heal"
                    elseif tool.Name:lower():find("shield") or tool.Name:lower():find("def") then
                        skillType = "Defense"
                    elseif tool.Name:lower():find("teleport") or tool.Name:lower():find("tp") or tool.Name:lower():find("blink") then
                        skillType = "Teleport"
                    end
                    
                    table.insert(skills, {
                        Tool = tool,
                        Name = tool.Name,
                        Type = skillType,
                        Priority = skillType == "Ultimate" and 1 or 
                                   skillType == "Heal" and 2 or 
                                   skillType == "Defense" and 3 or
                                   skillType == "Teleport" and 4 or 5
                    })
                end
            end
        end
        table.sort(skills, function(a, b) return a.Priority < b.Priority end)
    end
    return skills
end

-- ====== TUNG SKILL ======
local function useSkills(target, forceHeal)
    if not target or not target.HumanoidRootPart then return end
    
    local targetPos = target.HumanoidRootPart.Position
    local dist = root and (targetPos - root.Position).Magnitude or 999
    
    local skills = getAvailableSkills()
    for _, skillData in ipairs(skills) do
        local skill = skillData.Tool
        if skill then
            local shouldUse = false
            
            if skillData.Type == "Ultimate" then
                shouldUse = dist < 30
            elseif skillData.Type == "Heal" then
                if forceHeal or (hum and (hum.Health / hum.MaxHealth) * 100 < Config.HealThreshold) then
                    shouldUse = true
                end
            elseif skillData.Type == "Defense" then
                shouldUse = dist < 15 and Config.AutoDodge
            elseif skillData.Type == "Teleport" then
                shouldUse = false -- Teleport dùng riêng để né
            else
                shouldUse = dist < 40
            end
            
            if shouldUse then
                hum:EquipTool(skill)
                task.wait(0.05)
                vu:ClickButton1(Vector2.new())
                skillCooldown[skill.Name] = tick()
                break
            end
        end
    end
end

-- ====== 2. NÉ ĐÒN BẰNG TELEPORT ======
local function teleportDodge(target, info)
    if not Config.AutoTP or not root then return false end
    if not target or not target.HumanoidRootPart then return false end
    
    -- Kiểm tra cooldown TP
    if tick() - lastTPTime < 2 then return false end
    
    -- Điều kiện dùng TP né:
    local shouldTP = false
    
    -- 1. Quái ở quá gần và nguy hiểm
    if info and info.Distance < 10 then
        shouldTP = true
    end
    
    -- 2. Boss sắp tung skill (giả lập)
    if info and info.IsBoss and info.Distance < 20 and math.random(1, 100) < 30 then
        shouldTP = true
    end
    
    -- 3. Né bình thường thất bại nhiều lần
    if dodgeFailCount > 3 then
        shouldTP = true
        dodgeFailCount = 0
    end
    
    if shouldTP then
        -- Tìm vị trí TP an toàn (xung quanh quái nhưng đủ xa)
        local angle = math.rad(math.random(0, 360))
        local randomDir = Vector3.new(math.cos(angle), 0, math.sin(angle))
        local tpPos = target.HumanoidRootPart.Position + randomDir * Config.TPRange
        
        -- Đảm bảo TP trong phạm vi cho phép
        local dist = (tpPos - root.Position).Magnitude
        if dist < 100 then -- Giới hạn TP
            -- Dùng skill Teleport nếu có
            local skills = getAvailableSkills()
            for _, skillData in ipairs(skills) do
                if skillData.Type == "Teleport" then
                    hum:EquipTool(skillData.Tool)
                    task.wait(0.05)
                    vu:ClickButton1(Vector2.new())
                    skillCooldown[skillData.Name] = tick()
                    lastTPTime = tick()
                    
                    -- Di chuyển đến vị trí an toàn
                    hum:MoveTo(tpPos)
                    
                    -- Hiệu ứng TP (chỉ hiển thị)
                    local tpEffect = Instance.new("Part")
                    tpEffect.Size = Vector3.new(2, 2, 2)
                    tpEffect.Position = root.Position
                    tpEffect.Anchored = true
                    tpEffect.CanCollide = false
                    tpEffect.Material = Enum.Material.Neon
                    tpEffect.BrickColor = BrickColor.new("Bright blue")
                    tpEffect.Parent = ws
                    
                    task.spawn(function()
                        task.wait(0.3)
                        tpEffect:Destroy()
                    end)
                    
                    print("🌀 Teleport né đòn thành công!")
                    return true
                end
            end
            
            -- Nếu không có skill Teleport, dùng CFrame để dịch chuyển
            root.CFrame = CFrame.new(tpPos)
            lastTPTime = tick()
            print("🌀 Instant TP né đòn!")
            return true
        end
    end
    
    return false
end

-- ====== 1. NÉ ĐÒN THÔNG THƯỜNG ======
local function normalDodge(target, info)
    if not Config.AutoDodge or not root or not hum then return false end
    if not target or not target.HumanoidRootPart then return false end
    
    local shouldDodge = false
    
    if info and info.Distance < 20 then
        if math.random(1, 100) < Config.DodgeChance then
            shouldDodge = true
        end
    end
    
    if info and info.IsBoss and info.Distance < 25 then
        shouldDodge = true
    end
    
    if shouldDodge and tick() - lastDodgeTime > 0.8 then
        local angle = math.rad(math.random(30, 150))
        local randomDir = Vector3.new(math.cos(angle), 0, math.sin(angle))
        local dodgePos = target.HumanoidRootPart.Position + randomDir * 15 + Vector3.new(0, 2, 0)
        hum:MoveTo(dodgePos)
        
        if math.random(1, 100) < 30 then
            hum.Jump = true
        end
        
        lastDodgeTime = tick()
        dodgeFailCount = 0 -- Reset fail count khi né thành công
        return true
    end
    
    -- Nếu không né được, tăng fail count
    dodgeFailCount = dodgeFailCount + 1
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
