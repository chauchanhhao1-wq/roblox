-- =====================================================
--   🔥 NOVA ULTIMATE HUB - DUNGEON QUEST REBORN v4.1
--   PHẦN 1/2: Cấu hình + Hàm chính
-- =====================================================

local player = game.Players.LocalPlayer
local uis = game:GetService("UserInputService")
local vu = game:GetService("VirtualUser")
local ws = game:GetService("Workspace")
local rs = game:GetService("RunService")
local tps = game:GetService("TweenService")

local Config = {
    AutoFarm = false, AutoAttack = true, AutoSkill = true,
    AutoDungeon = false, AutoStart = true, AutoBackLobby = false,
    WalkSpeed = 23, JumpPower = 60, AttackDelay = 0.3,
    FarmRange = 100, CombatStyle = "Balanced", DodgeChance = 40,
    ESP = false, AntiAFK = true, SpeedHack = true,
    InfiniteJump = false, NoClip = false,
}

local char = player.Character
local hum = char and char:FindFirstChild("Humanoid")
local root = char and char:FindFirstChild("HumanoidRootPart")
local currentTarget = nil
local isFighting = false
local lastDodgeTime = 0
local skillCooldown = {}

local function getChar()
    char = player.Character
    if char then
        hum = char:FindFirstChild("Humanoid")
        root = char:FindFirstChild("HumanoidRootPart")
    end
    return char, hum, root
end

local function getAvailableSkills()
    local skills = {}
    if char then
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
                local cooldown = skillCooldown[tool.Name] or 0
                if tick() - cooldown > 1.5 then
                    table.insert(skills, tool)
                end
            end
        end
        table.sort(skills, function(a, b) return a.Name > b.Name end)
    end
    return skills
end

local function smartMove(targetPos, shouldDodge)
    if not root or not hum then return end
    if shouldDodge and Config.CombatStyle ~= "Defensive" then
        local angle = tick() * 3
        local side = Vector3.new(math.sin(angle), 0, math.cos(angle))
        hum:MoveTo(targetPos + side * 5 + Vector3.new(0, 2, 0))
    else
        hum:MoveTo(targetPos)
    end
    if shouldDodge and math.random(1, 100) < Config.DodgeChance and tick() - lastDodgeTime > 1 then
        hum.Jump = true
        lastDodgeTime = tick()
    end
end

local function useSkills(target)
    if not target or not target.HumanoidRootPart then return end
    local skills = getAvailableSkills()
    for _, skill in ipairs(skills) do
        if skill then
            local dist = (target.HumanoidRootPart.Position - root.Position).Magnitude
            local isMelee = dist < 20
            local skillType = skill:GetAttribute("Type") or "Melee"
            if (isMelee and skillType == "Melee") or (not isMelee and skillType == "Ranged") then
                hum:EquipTool(skill)
                task.wait(0.05)
                vu:ClickButton1(Vector2.new())
                skillCooldown[skill.Name] = tick()
                break
            end
        end
    end
end

local function autoFarm()
    task.spawn(function()
        while true do
            task.wait(Config.AttackDelay)
            if not Config.AutoFarm then isFighting = false task.wait(1) continue end
            local char, hum, root = getChar()
            if not char or not hum or not root then continue end
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
            currentTarget = nearest
            if nearest and nearest.HumanoidRootPart then
                isFighting = true
                local targetPos = nearest.HumanoidRootPart.Position
                local shouldDodge = Config.CombatStyle ~= "Aggressive" or minDist < 20
                smartMove(targetPos, shouldDodge)
                if Config.AutoSkill and minDist < Config.FarmRange then useSkills(nearest) end
                if Config.AutoAttack then vu:ClickButton1(Vector2.new()) end
                if Config.CombatStyle == "Defensive" and minDist < 15 then
                    local retreatPos = root.Position - (targetPos - root.Position).Unit * 20
                    hum:MoveTo(retreatPos)
                elseif Config.CombatStyle == "Balanced" then
                    local angle = tick() * 2
                    hum:MoveTo(targetPos + Vector3.new(math.cos(angle) * 10, 2, math.sin(angle) * 10))
                end
            else
                isFighting = false
                if Config.AutoDungeon then
                    for _, v in pairs(ws:GetChildren()) do
                        if v:IsA("BasePart") and (v.Name:lower():find("portal") or v.Name:lower():find("start")) then
                            hum:MoveTo(v.Position)
                            break
                        end
                    end
                end
            end
        end
    end)
end

local function autoDungeon()
    task.spawn(function()
        while true do
            task.wait(2)
            if not Config.AutoDungeon then task.wait(1) continue end
            local char, hum, root = getChar()
            if not char or not root then continue end
            if isFighting then continue end
            for _, v in pairs(ws:GetChildren()) do
                if v:IsA("BasePart") and (v.Name:lower():find("portal") or v.Name:lower():find("start") or v.Name:lower():find("gate")) then
                    local dist = (v.Position - root.Position).Magnitude
                    if dist < 15 then
                        local click = v:FindFirstChildOfClass("ClickDetector")
                        if click then fireclickdetector(click) end
                        if Config.AutoStart then
                            task.wait(0.5)
                            for _, ui in pairs(player.PlayerGui:GetDescendants()) do
                                if ui:IsA("TextButton") and (ui.Name:lower():find("start") or ui.Text:lower():find("start")) then
                                    ui:Click()
                                    break
                                end
                            end
                        end
                    elseif dist < Config.FarmRange then
                        hum:MoveTo(v.Position)
                    end
                end
            end
        end
    end)
end

local function autoBackLobby()
    task.spawn(function()
        while true do
            task.wait(5)
            if not Config.AutoBackLobby then task.wait(1) continue end
            local char, hum = getChar()
            if not char or not hum or hum.Health <= 0 then
                for _, ui in pairs(player.PlayerGui:GetDescendants()) do
                    if ui:IsA("TextButton") and (ui.Name:lower():find("back") or ui.Text:lower():find("lobby") or ui.Text:lower():find("back")) then
                        ui:Click()
                        break
                    end
                end
            end
        end
    end)
end

local function toggleNoClip(state)
    if getChar() and root then root.CanCollide = not state end
end

local function toggleESP(state)
    if state then
        task.spawn(function()
            while Config.ESP do
                task.wait(1)
                for _, v in pairs(ws:GetChildren()) do
                    if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= char then
                        if not v:FindFirstChild("ESPTag") then
                            local bill = Instance.new("BillboardGui")
                            bill.Name = "ESPTag"
                            bill.Size = UDim2.new(0, 180, 0, 35)
                            bill.Adornee = v.HumanoidRootPart
                            bill.AlwaysOnTop = true
                            bill.Parent = v
                            local label = Instance.new("TextLabel")
                            label.Size = UDim2.new(1, 0, 1, 0)
                            label.BackgroundTransparency = 1
                            local hp = v.Humanoid.Health
                            label.Text = v.Name .. " | ❤️ " .. hp
                            label.TextColor3 = hp > 50 and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                            label.TextScaled = true
                            label.Parent = bill
                        end
                    end
                end
            end
        end)
    else
        for _, v in pairs(ws:GetChildren()) do
            if v:FindFirstChild("ESPTag") then v.ESPTag:Destroy() end
        end
    end
end

local function speedLoop()
    task.spawn(function()
        while true do
            task.wait(0.15)
            local char, hum = getChar()
            if char and hum then
                if Config.SpeedHack then hum.WalkSpeed = Config.WalkSpeed end
                if Config.InfiniteJump then hum.JumpPower = 999999 end
                if Config.AntiAFK then
                    vu:CaptureController()
                    vu:ClickButton2(Vector2.new())
                end
            end
        end
    end)
end
-- =====================================================
--   🔥 NOVA ULTIMATE HUB - DUNGEON QUEST REBORN v4.1
--   PHẦN 2/2: UI + KHỞI TẠO
-- =====================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NovaUltimateUI"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 420)
mainFrame.Position = UDim2.new(0.5, -160, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
mainFrame.BackgroundTransparency = 0.08
mainFrame.Parent = screenGui
mainFrame.ClipsDescendants = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
titleBar.BackgroundTransparency = 0.2
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 12)
titleCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(0.8, 0, 1, 0)
titleText.Position = UDim2.new(0.05, 0, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "🔥 NOVA ULTIMATE"
titleText.TextColor3 = Color3.fromRGB(255, 200, 50)
titleText.TextScaled = true
titleText.Font = Enum.Font.GothamBold
titleText.Parent = titleBar

local version = Instance.new("TextLabel")
version.Size = UDim2.new(0.2, 0, 0.6, 0)
version.Position = UDim2.new(0.75, 0, 0.2, 0)
version.BackgroundTransparency = 1
version.Text = "v4.1"
version.TextColor3 = Color3.fromRGB(150, 150, 200)
version.TextScaled = true
version.Font = Enum.Font.GothamMedium
version.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled = true
closeBtn.Parent = titleBar
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, 0, 0, 35)
tabBar.Position = UDim2.new(0, 0, 0, 40)
tabBar.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
tabBar.BackgroundTransparency = 0.3
tabBar.Parent = mainFrame

local tabs = {"⚔️ Combat", "⚙️ Utility", "👁️ Visual"}
local tabButtons = {}
local tabFrames = {}

for i = 1, 3 do
    local frame = Instance.new("ScrollingFrame")
    frame.Size = UDim2.new(1, -10, 1, -85)
    frame.Position = UDim2.new(0, 5, 0, 80)
    frame.BackgroundTransparency = 1
    frame.Visible = (i == 1)
    frame.CanvasSize = UDim2.new(0, 0, 0, 0)
    frame.ScrollBarThickness = 3
    frame.Parent = mainFrame
    tabFrames[i] = frame
end

for i, text in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/3, 0, 1, 0)
    btn.Position = UDim2.new((i-1)/3, 0, 0, 0)
    btn.BackgroundColor3 = i == 1 and Color3.fromRGB(50, 50, 80) or Color3.fromRGB(25, 25, 40)
    btn.BackgroundTransparency = 0.2
    btn.Text = text
    btn.TextColor3 = i == 1 and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(150, 150, 200)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.Parent = tabBar
    btn.MouseButton1Click:Connect(function()
        for j, b in ipairs(tabButtons) do
            b.BackgroundColor3 = j == i and Color3.fromRGB(50, 50, 80) or Color3.fromRGB(25, 25, 40)
            b.TextColor3 = j == i and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(150, 150, 200)
        end
        for j, frame in ipairs(tabFrames) do
            frame.Visible = (j == i)
        end
    end)
    tabButtons[i] = btn
end

local function createToggle(parent, y, text, key, def)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.92, 0, 0, 32)
    frame.Position = UDim2.new(0.04, 0, 0, y)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 48)
    frame.BackgroundTransparency = 0.4
    frame.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0.05, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextScaled = true
    label.Font = Enum.Font.GothamMedium
    label.Parent = frame
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 45, 0, 22)
    btn.Position = UDim2.new(0.88, -22, 0.5, -11)
    btn.BackgroundColor3 = def and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(180, 50, 50)
    btn.Text = def and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.Parent = frame
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    local state = def
    btn.MouseButton1Click:Connect(function()
        state = not state
        Config[key] = state
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(180, 50, 50)
        btn.Text = state and "ON" or "OFF"
        if key == "AutoFarm" and state then autoFarm() end
        if key == "AutoDungeon" and state then autoDungeon() end
        if key == "AutoBackLobby" and state then autoBackLobby() end
        if key == "ESP" then toggleESP(state) end
        if key == "NoClip" then toggleNoClip(state) end
    end)
    return btn
end

local function createSlider(parent, y, text, key, min, max, def)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.92, 0, 0, 45)
    frame.Position = UDim2.new(0.04, 0, 0, y)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 48)
    frame.BackgroundTransparency = 0.4
    frame.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 18)
    label.Position = UDim2.new(0.05, 0, 0, 2)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. def
    label.TextColor3 = Color3.fromRGB(220, 220, 255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextScaled = true
    label.Font = Enum.Font.GothamMedium
    label.Parent = frame
    local track = Instance.new("Frame")
    track.Size = UDim2.new(0.75, 0, 0, 4)
    track.Position = UDim2.new(0.1, 0, 0, 32)
    track.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    track.Parent = frame
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(0, 2)
    trackCorner.Parent = track
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((def - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    fill.Parent = track
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 2)
    fillCorner.Parent = fill
    local handle = Instance.new("TextButton")
    handle.Size = UDim2.new(0, 16, 0, 16)
    handle.Position = UDim2.new((def - min) / (max - min), -8, 0.5, -8)
    handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    handle.Text = ""
    handle.Parent = track
    local handleCorner = Instance.new("UICorner")
    handleCorner.CornerRadius = UDim.new(0, 8)
    handleCorner.Parent = handle
    local function updateSlider(value)
        value = math.clamp(value, min, max)
        Config[key] = value
        label.Text = text .. ": " .. math.round(value)
        fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        handle.Position = UDim2.new((value - min) / (max - min), -8, 0.5, -8)
    end
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            while uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local mousePos = uis:GetMouseLocation()
                local trackPos = track.AbsolutePosition
                local trackSize = track.AbsoluteSize
                local percent = (mousePos.X - trackPos.X) / trackSize.X
                updateSlider(min + percent * (max - min))
                task.wait()
            end
        end
    end)
    return handle
end

-- TAB 1: Combat
local cTab = tabFrames[1]
createToggle(cTab, 5, "⚔️ Auto Farm", "AutoFarm", false)
createToggle(cTab, 42, "⚡ Auto Attack", "AutoAttack", true)
createToggle(cTab, 79, "🌀 Auto Skill", "AutoSkill", true)
createToggle(cTab, 116, "🏰 Auto Dungeon", "AutoDungeon", false)
createToggle(cTab, 153, "▶️ Auto Start", "AutoStart", true)
createToggle(cTab, 190, "🏠 Auto Back Lobby", "AutoBackLobby", false)
createSlider(cTab, 235, "🎯 Farm Range", "FarmRange", 30, 200, 100)
createSlider(cTab, 285, "⚡ Attack Speed", "AttackDelay", 0.1, 1, 0.3)

-- TAB 2: Utility
local uTab = tabFrames[2]
createToggle(uTab, 5, "⚡ Speed Hack", "SpeedHack", true)
createToggle(uTab, 42, "🦘 Infinite Jump", "InfiniteJump", false)
createToggle(uTab, 79, "🔄 No Clip", "NoClip", false)
createToggle(uTab, 116, "💤 Anti AFK", "AntiAFK", true)
createSlider(uTab, 160, "🏃 WalkSpeed", "WalkSpeed", 16, 35, 23)
createSlider(uTab, 210, "🦿 Jump Power", "JumpPower", 40, 100, 60)

-- Combat Style
local styleFrame = Instance.new("Frame")
styleFrame.Size = UDim2.new(0.92, 0, 0, 32)
styleFrame.Position = UDim2.new(0.04, 0, 0, 260)
styleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 48)
styleFrame.BackgroundTransparency = 0.4
styleFrame.Parent = uTab
local styleCorner = Instance.new("UICorner")
styleCorner.CornerRadius = UDim.new(0, 6)
styleCorner.Parent = styleFrame
local styleLabel = Instance.new("TextLabel")
styleLabel.Size = UDim2.new(0.4, 0, 1, 0)
styleLabel.Position = UDim2.new(0.05, 0, 0, 0)
styleLabel.BackgroundTransparency = 1
styleLabel.Text = "⚔️ Style"
styleLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
styleLabel.TextXAlignment = Enum.TextXAlignment.Left
styleLabel.TextScaled = true
styleLabel.Font = Enum.Font.GothamMedium
styleLabel.Parent = styleFrame
local styleDropdown = Instance.new("TextButton")
styleDropdown.Size = UDim2.new(0.4, 0, 0.7, 0)
styleDropdown.Position = UDim2.new(0.55, 0, 0.15, 0)
styleDropdown.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
styleDropdown.Text = Config.CombatStyle
styleDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
styleDropdown.TextScaled = true
styleDropdown.Font = Enum.Font.GothamBold
styleDropdown.Parent = styleFrame
local styleCorner2 = Instance.new("UICorner")
styleCorner2.CornerRadius = UDim.new(0, 6)
styleCorner2.Parent = styleDropdown
local styles = {"Aggressive", "Balanced", "Defensive"}
local styleIndex = 2
styleDropdown.MouseButton1Click:Connect(function()
    styleIndex = styleIndex % 3 + 1
    Config.CombatStyle = styles[styleIndex]
    styleDropdown.Text = styles[styleIndex]
end)
createSlider(uTab, 300, "🛡️ Dodge Chance %", "DodgeChance", 10, 80, 40)

-- TAB 3: Visual
local vTab = tabFrames[3]
createToggle(vTab, 5, "👁️ ESP Monster", "ESP", false)

-- Footer
local footer = Instance.new("Frame")
footer.Size = UDim2.new(1, 0, 0, 22)
footer.Position = UDim2.new(0, 0, 1, -22)
footer.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
footer.BackgroundTransparency = 0.3
footer.Parent = mainFrame
local footerCorner = Instance.new("UICorner")
footerCorner.CornerRadius = UDim.new(0, 12)
footerCorner.Parent = footer
local footerText = Instance.new("TextLabel")
footerText.Size = UDim2.new(1, 0, 1, 0)
footerText.BackgroundTransparency = 1
footerText.Text = "🔹 Press F9 | Made with ❤️"
footerText.TextColor3 = Color3.fromRGB(150, 150, 200)
footerText.TextScaled = true
footerText.Font = Enum.Font.GothamMedium
footerText.Parent = footer

-- KHỞI TẠO
speedLoop()

player.CharacterAdded:Connect(function(c)
    char = c
    hum = c:WaitForChild("Humanoid")
    root = c:WaitForChild("HumanoidRootPart")
    task.wait(1)
    speedLoop()
    if Config.AutoFarm then autoFarm() end
    if Config.AutoDungeon then autoDungeon() end
    if Config.AutoBackLobby then autoBackLobby() end
    if Config.ESP then toggleESP(true) end
    if Config.NoClip then toggleNoClip(true) end
end)

if getChar() then
    if Config.AutoFarm then autoFarm() end
    if Config.AutoDungeon then autoDungeon() end
    if Config.AutoBackLobby then autoBackLobby() end
    if Config.ESP then toggleESP(true) end
    if Config.NoClip then toggleNoClip(true) end
end

uis.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.F9 and not gp then
        if screenGui then screenGui.Enabled = not screenGui.Enabled end
    end
end)

print("✅ Nova Ultimate v4.1 loaded! Press F9 to toggle GUI.")
