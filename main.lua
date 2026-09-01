-- =============================================================================
-- DUNGEON QUEST REBORN - ADVANCED BYPASS SUPER HUB
-- =============================================================================

-- Tải thư viện UI Rayfield ổn định nhất cho thiết bị di động
local Rayfield = loadstring(game:HttpGet('https://githubusercontent.com'))()

local Window = Rayfield:CreateWindow({
   Name = "⚔️ Dungeon Quest Reborn - Ultimate Bypass Hub",
   LoadingTitle = "Đang tải hệ thống bảo mật...",
   LoadingSubtitle = "by Master Scripter",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false -- Tắt Key để người dùng mở lên là chạy được ngay
})

-- Tạo các phân mục Menu dễ nhìn
local FarmTab = Window:CreateTab("Auto Farm (Bypass)", 4483362458) 
local MovementTab = Window:CreateTab("Di Chuyển & Né", 4483362534)

-- Các biến toàn cục quản lý trạng thái Bật/Tắt
getgenv().CameraFarmActive = false
getgenv().AutoDodgeActive = false
getgenv().AntiCheatSpeedLock = false

-- Các hằng số cấu hình hệ thống né chiêu bằng Lực Vật Lý (Bypass CFrame Check)
local DETECT_RADIUS = 25
local DODGE_SPEED = 65
local DODGE_DURATION = 0.3
local DANGER_NAMES = {"indicator", "hitbox", "aoe", "warning", "redzone", "danger", "spellcircle", "bossattack", "projectile"}

-- =============================================================================
-- TAB 1: AUTO FARM (BYPASS ANTI-CHEAT BẰNG CAMERA GÓC NHÌN)
-- =============================================================================

local RunService = game:GetService("RunService")
local Camera = game.Workspace.CurrentCamera
local Player = game.Players.LocalPlayer

FarmTab:CreateToggle({
   Name = "Auto Farm (Bypass Camera Quái Vật)",
   CurrentValue = false,
   Callback = function(Value)
      getgenv().CameraFarmActive = Value
      if Value then
         task.spawn(function()
            Rayfield:Notify({Name = "Auto Farm", Content = "Đã kích hoạt chế độ Farm ẩn danh qua Camera!", Duration = 3})
            while getgenv().CameraFarmActive do
               pcall(function()
                  local character = Player.Character
                  local weapon = character and character:FindFirstChildOfClass("Tool")
                  
                  -- Quét mục tiêu từ thư mục quái vật của trò chơi
                  for _, mob in pairs(game.Workspace.Enemies:GetChildren()) do
                     local mobRoot = mob:FindFirstChild("HumanoidRootPart")
                     local mobHumanoid = mob:FindFirstChildOfClass("Humanoid")
                     
                     if mobRoot and mobHumanoid and mobHumanoid.Health > 0 and getgenv().CameraFarmActive do
                        -- CHUYỂN GÓC NHÌN CHỐNG ANTI-CHEAT: Khóa camera vào quái, giữ nhân vật đứng im tại chỗ an toàn
                        Camera.CameraType = Enum.CameraType.Scriptable
                        
                        while mobHumanoid.Health > 0 and getgenv().CameraFarmActive do
                           -- Đồng bộ vị trí góc nhìn của Camera bám theo quái vật
                           Camera.CFrame = CFrame.new(mobRoot.Position + Vector3.new(0, 10, 12), mobRoot.Position)
                           
                           -- Spam lệnh vung vũ khí tấn công từ xa mà không cần dịch chuyển nhân vật
                           if weapon then
                              weapon:Activate()
                           end
                           RunService.RenderStepped:Wait()
                        end
                     end
                  end
               end)
               task.wait(0.5)
            end
            
            -- TRẢ LẠI GÓC NHÌN GỐC KHI TẮT MÁY FARM
            Camera.CameraType = Enum.CameraType.Custom
            if Player.Character and Player.Character:FindFirstChild("Humanoid") then
               Camera.CameraSubject = Player.Character.Humanoid
            end
         end)
      else
         -- Dự phòng trường hợp tắt ngang xương khi đang farm, trả lại camera ngay
         Camera.CameraType = Enum.CameraType.Custom
         if Player.Character and Player.Character:FindFirstChild("Humanoid") then
            Camera.CameraSubject = Player.Character.Humanoid
         end
      end
   end,
})

-- =============================================================================
-- TAB 2: DI CHUYỂN AN TOÀN & TỰ ĐỘNG NÉ ĐÒN
-- =============================================================================

-- Nút 1: Khóa tốc độ an toàn (Mức 24 - Bằng tốc độ kỹ năng Inner Focus của game)
MovementTab:CreateToggle({
   Name = "Bypass Speed Lock (Giữ tốc độ 24 an toàn)",
   CurrentValue = false,
   Callback = function(Value)
      getgenv().AntiCheatSpeedLock = Value
      if Value then
         task.spawn(function()
            Rayfield:Notify({Name = "Speed Bypass", Content = "Đã khóa tốc độ ở mức 24 an toàn trước Anti-Cheat!", Duration = 3})
            while getgenv().AntiCheatSpeedLock do
               pcall(function()
                  local character = Player.Character
                  local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                  if humanoid and humanoid.Health > 0 then
                     if humanoid.WalkSpeed ~= 24 then
                        humanoid.WalkSpeed = 24
                     end
                  end
               end)
               task.wait(0.1)
            end
         end)
      end
   end,
})

-- Hàm kiểm tra xem vật thể có phải vùng sát thương nguy hiểm không
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

-- Hàm lướt né đòn bằng cơ chế vật lý (Bypass cơ chế quét dịch chuyển của game)
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

-- Nút 2: Tự động phát hiện vòng đỏ và kích hoạt cơ chế lướt vật lý né chiêu
MovementTab:CreateToggle({
   Name = "Auto Dodge Skill (Lướt né vòng đỏ bằng Vật lý)",
   CurrentValue = false,
   Callback = function(Value)
      getgenv().AutoDodgeActive = Value
      if Value then
         task.spawn(function()
            Rayfield:Notify({Name = "Auto Dodge", Content = "Đã bật quét chiêu thức quái vật toàn thời gian!", Duration = 3})
            while getgenv().AutoDodgeActive do
               pcall(function()
                  local character = Player.Character
                  local rootPart = character:FindFirstChild("HumanoidRootPart")
                  local humanoid = character:FindFirstChildOfClass("Humanoid")
                  if not rootPart or not humanoid or humanoid.Health <= 0 then return end
                  
                  for _, obj in ipairs(game.Workspace:GetChildren()) do
                     if isDangerZone(obj) then
                        local distance = (rootPart.Position - obj.Position).Magnitude
                        if distance <= DETECT_RADIUS then
                           dodgeAwayFrom(obj.Position, rootPart, humanoid)
                           task.wait(0.4) -- Khoảng nghỉ ngắn chống spam lực đẩy làm văng nhân vật
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
   
