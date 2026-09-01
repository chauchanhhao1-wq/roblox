-- ====== Cấu Hình ======
local player = game.Players.LocalPlayer
local uis = game:GetService("UserInputService")
local vu = game:GetService("VirtualUser")

local Config = {
    WalkSpeed = 23,          -- Tốc độ di chuyển
    HealThreshold = 50,      -- Ngưỡng máu để tự động hồi (%)
    AutoFarm = false,        -- Bật/tắt Auto Farm
    AutoDungeon = false,     -- Bật/tắt Auto Dungeon
    AutoHeal = false,        -- Bật/tắt Auto Heal
    SpeedHack = false,       -- Bật/tắt Speed Hack
    ESP = false,             -- Bật/tắt ESP
    AntiAFK = true           -- Bật/tắt chống AFK
}

-- ====== Hàm lấy nhân vật ======
local function getChar()
    local char = player.Character
    if char then
        return char, char:FindFirstChild("Humanoid"), char:FindFirstChild("HumanoidRootPart")
    end
    return nil, nil, nil
end

-- ====== Speed Hack & Chống AFK ======
task.spawn(function()
    while true do
        task.wait(0.15)
        local char, hum = getChar()
        if char and hum then
            if Config.SpeedHack and Config.WalkSpeed then
                hum.WalkSpeed = Config.WalkSpeed
            end
            if Config.AntiAFK then
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end
        end
    end
end)

-- ====== Auto Heal ======
task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.AutoHeal then
            local char, hum = getChar()
            if char and hum then
                local healthPercent = (hum.Health / hum.MaxHealth) * 100
                if healthPercent < Config.HealThreshold then
                    for _, item in pairs(player.Backpack:GetChildren()) do
                        if item:IsA("Tool") and (item.Name:lower():find("health") or item.Name:lower():find("potion")) then
                            hum:EquipTool(item)
                            task.wait(0.2)
                            vu:ClickButton1(Vector2.new())
                            break
                        end
                    end
                end
            end
        end
    end
end)

-- ====== Auto Farm & Dungeon ======
task.spawn(function()
    while true do
        task.wait(0.3)
        local char, hum, root = getChar()
        if not char or not hum or not root then continue end
        
        -- 1. Auto Farm: Tìm quái gần nhất để tấn công
        if Config.AutoFarm then
            local nearest, minDist = nil, math.huge
            for _, v in pairs(game.Workspace:GetChildren()) do
                if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= char then
                    local target = v:FindFirstChild("HumanoidRootPart")
                    if target and v.Humanoid.Health > 0 then
                        local dist = (target.Position - root.Position).Magnitude
                        if dist < minDist and dist < 100 then
                            minDist = dist
                            nearest = v
                        end
                    end
                end
            end
            
            if nearest and nearest.HumanoidRootPart then
                hum:MoveTo(nearest.HumanoidRootPart.Position)
                vu:ClickButton1(Vector2.new()) -- Tấn công
            end
        end
        
        -- 2. Auto Dungeon: Tìm portal để vào dungeon mới
        if Config.AutoDungeon then
            for _, v in pairs(game.Workspace:GetChildren()) do
                if v:IsA("BasePart") and (v.Name:lower():find("portal") or v.Name:lower():find("start")) then
                    if (v.Position - root.Position).Magnitude < 20 then
                        fireclickdetector(v:FindFirstChildOfClass("ClickDetector") or v)
                    elseif Config.AutoFarm == false then -- Chỉ di chuyển nếu không có quái để farm
                        hum:MoveTo(v.Position)
                    end
                end
            end
        end
    end
end)

-- ====== ESP ======
task.spawn(function()
    while true do
        task.wait(1)
        if Config.ESP then
            for _, v in pairs(game.Workspace:GetChildren()) do
                if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= player.Character then
                    if not v:FindFirstChild("ESPTag") then
                        local bill = Instance.new("BillboardGui")
                        bill.Name = "ESPTag"
                        bill.Size = UDim2.new(0, 150, 0, 30)
                        bill.Adornee = v.HumanoidRootPart
                        bill.AlwaysOnTop = true
                        bill.Parent = v
                        
                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 1
                        label.Text = v.Name .. " | ❤️ " .. v.Humanoid.Health
                        label.TextColor3 = Color3.fromRGB(255, 0, 0)
                        label.TextScaled = true
                        label.Parent = bill
                    end
                end
            end
        else
            -- Xóa ESP khi tắt
            for _, v in pairs(game.Workspace:GetChildren()) do
                if v:FindFirstChild("ESPTag") then
                    v.ESPTag:Destroy()
                end
            end
        end
    end
end)

-- ====== GUI ======
local gui = Instance.new("ScreenGui")
gui.Name = "NovaLight"
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 250)
frame.Position = UDim2.new(0.5, -100, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.BackgroundTransparency = 0.05
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local title = Instance.new("TextButton")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
title.Text = "⚡ Nova Light"
title.TextColor3 = Color3.fromRGB(255, 200, 50)
title.TextScaled = true
title.Parent = frame

-- Hàm tạo toggle
local function createToggle(y, text, key, default)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 28)
    btn.Position = UDim2.new(0.05, 0, 0, y)
    btn.BackgroundColor3 = default and Color3.fromRGB(0, 200, 50) or Color3.fromRGB(200, 50, 0)
    btn.Text = text .. ": " .. (default and "ON" or "OFF")
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Parent = frame
    
    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        Config[key] = state
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 50) or Color3.fromRGB(200, 50, 0)
        btn.Text = text .. ": " .. (state and "ON" or "OFF")
    end)
    return btn
end

-- Tạo các toggle
createToggle(40, "⚔️ Auto Farm", "AutoFarm", false)
createToggle(75, "🏰 Auto Dungeon", "AutoDungeon", false)
createToggle(110, "❤️ Auto Heal", "AutoHeal", false)
createToggle(145, "⚡ Speed Hack", "SpeedHack", true)
createToggle(180, "👁️ ESP", "ESP", false)
createToggle(215, "💤 Anti AFK", "AntiAFK", true)

-- Đóng GUI
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.9, 0, 0, 25)
closeBtn.Position = UDim2.new(0.05, 0, 0, 250)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "❌ Đóng"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled = true
closeBtn.Parent = frame
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- Toggle GUI bằng F9
uis.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.F9 and not gameProcessed then
        local gui = player.PlayerGui:FindFirstChild("NovaLight")
        if gui then
            gui.Enabled = not gui.Enabled
        end
    end
end)

print("✅ Nova Light loaded! Press F9 to toggle GUI.")
