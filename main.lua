-- Khởi tạo Thư viện Giao diện Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu'))()

local Window = Rayfield:CreateWindow({
   Name = "⚔️ Dungeon Quest Reborn - Super Hub",
   LoadingTitle = "Đang tải Script...",
   LoadingSubtitle = "by Master Scripter",
   ConfigurationSaving = {
      Enabled = false
   },
   KeySystem = false -- Tắt hệ thống Key để dùng luôn cho tiện
})

-- Tạo các Tab chức năng trên Menu
local MainTab = Window:CreateTab("Main (Cày Cuốc)", 4483362458) 
local CombatTab = Window:CreateTab("Combat (Né Chiêu)", 4483362534)

-- BIẾN ĐIỀU KHIỂN (TOGGLES)
getgenv().KillAura = false
getgenv().BringMobs = false
getgenv().AutoDodgeActive = false
getgenv().GodMode = false

---------------------------------------------------------------------------
-- TAB 1: MAIN (CÀY CUỐC & BẤT TỬ)
---------------------------------------------------------------------------

-- Nút Bật/Tắt Kill Aura (Tự sát thương quái xung quanh)
MainTab:CreateToggle({
   Name = "Auto Kill Aura (Tự Đánh Quái)",
   CurrentValue = false,
   Callback = function(Value)
      getgenv().KillAura = Value
      if Value then
         task.spawn(function()
            while getgenv().KillAura do
               pcall(function()
                  local player = game.Players.LocalPlayer
                  local character = player.Character
                  -- Tìm vũ khí đang cầm trong tay nhân vật
                  local weapon = character:FindFirstChildOfClass("Tool")
                  
                  if weapon then
                     -- Quét quái vật trong thư mục Enemies của game
                     for _, mob in pairs(game.Workspace.Enemies:GetChildren()) do
                        local mobRoot = mob:FindFirstChild("HumanoidRootPart")
                        local myRoot = character:FindFirstChild("HumanoidRootPart")
                        
                        if mobRoot and myRoot and (myRoot.Position - mobRoot.Position).Magnitude <= 20 then
                           -- Gửi tín hiệu chém quái về Server game
                           weapon:Activate()
                           task.wait(0.1)
                        end
                     end
                  end
               end)
               task.wait(0.1)
            end
         end)
      end
   end,
})

-- Nút Bật/Tắt Bring Mobs (Hút quái lại một chỗ)
MainTab:CreateToggle({
   Name = "Bring Mobs (Gom Quái Lại Gần)",
   CurrentValue = false,
   Callback = function(Value)
      getgenv().BringMobs = Value
      if Value then
         task.spawn(function()
            while getgenv().BringMobs do
               pcall(function()
                  local myRoot = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                  if myRoot then
                     for _, mob in pairs(game.Workspace.Enemies:GetChildren()) do
                        local mobRoot = mob:FindFirstChild("HumanoidRootPart")
                        if mobRoot and (myRoot.Position - mobRoot.Position).Magnitude <= 50 then
                           -- Dịch chuyển quái đến ngay trước mặt bạn để dễ chém
                           mobRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -5)
                        end
                     end
                  end
               end)
               task.wait(0.3)
            end
         end)
      end
   end,
})

-- Nút Bật/Tắt God Mode (Bất tử cơ bản bằng cách chặn nhận sát thương)
MainTab:CreateToggle({
   Name = "Semi-God Mode (Hạn Chế Sát Thương)",
   CurrentValue = false,
   Callback = function(Value)
      getgenv().GodMode = Value
      pcall(function()
         local humanoid = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
         if humanoid then
            -- Thay đổi trạng thái nhân vật để không bị dính hiệu ứng choáng/ngã của Boss
            humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, Value)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not Value)
         end
      end)
   end,
})

---------------------------------------------------------------------------
-- TAB 2: COMBAT (TỰ ĐỘNG NÉ CHIÊU - CODE ĐÃ HOÀN THIỆN)
---------------------------------------------------------------------------

local DETECT_RADIUS = 25
local DODGE_SPEED = 65
local DODGE_DURATION = 0.3
local DANGER_NAMES = {"indicator", "hitbox", "aoe", "warning", "redzone", "danger", "spellcircle", "bossattack"}

local function isDangerZone(object)
   if not object:IsA("BasePart") then return false end
   local objName = object.Name:lower()
   for _, name in ipairs(DANGER_NAMES) do
      if objName:find(name) then return true end
   end
   if object.BrickColor.Name == "Bright red" or object.BrickColor.Name == "Deep orange" then
      if object.Transparency < 1 then return true end
   end
   return false
end

local function dodgeAwayFrom(dangerPosition, rootPart, humanoid)
   local currentPos = rootPart.Position
   local direction = (currentPos - dangerPosition).Unit
   direction = Vector3.new(direction.X, 0, direction.Z).Unit
   
   local attachment = Instance.new("Attachment", rootPart)
   local linearVelocity = Instance.new("LinearVelocity")
   linearVelocity.MaxForce = 99999
   linearVelocity.VectorVelocity = direction * DODGE_SPEED
   linearVelocity.Attachment0 = attachment
   linearVelocity.Parent = rootPart
   
   humanoid:MoveTo(currentPos + (direction * 15))
   task.wait(DODGE_DURATION)
   linearVelocity:Destroy()
   attachment:Destroy()
end

CombatTab:CreateToggle({
   Name = "Auto Dodge Skill (Tự Động Né Vòng Đỏ)",
   CurrentValue = false,
   Callback = function(Value)
      getgenv().AutoDodgeActive = Value
      if Value then
         task.spawn(function()
            Rayfield:Notify({Name = "Auto Dodge", Content = "Đã kích hoạt né chiêu thông minh!", Duration = 3})
            while getgenv().AutoDodgeActive do
               pcall(function()
                  local character = game.Players.LocalPlayer.Character
                  local rootPart = character:FindFirstChild("HumanoidRootPart")
                  local humanoid = character:FindFirstChildOfClass("Humanoid")
                  if not rootPart or not humanoid or humanoid.Health <= 0 then return end
                  
                  for _, obj in ipairs(game.Workspace:GetChildren()) do
                     if isDangerZone(obj) then
                        local distance = (rootPart.Position - obj.Position).Magnitude
                        if distance <= DETECT_RADIUS then
                           dodgeAwayFrom(obj.Position, rootPart, humanoid)
                           task.wait(0.4)
                           break
                        end
                     end
                  end
               end)
               task.wait(0.05)
            end
         end)
      end
   end,
})
