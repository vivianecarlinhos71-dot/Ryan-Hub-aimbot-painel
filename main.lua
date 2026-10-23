-- Carregamento Seguro do Rayfield com fallback
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
end)

if not success or not Rayfield then
    Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end

local Window = Rayfield:CreateWindow({
   Name = "FPS GOD | Delta V3 Mobile",
   LoadingTitle = "Carregando Funções Pro...",
   ConfigurationSaving = {Enabled = false}
})

-- Variáveis de Configuração
local Settings = {
    Aimbot = false,
    AutoShot = false,
    Tracers = false,
    ESP = false,
    HologramESP = false,
    HealthESP = false,
    DistanceESP = false,
    NoRecoil = false,
    Noclip = false,
    WallCheck = true,
    FOV = 150,
    AimPart = "Head",
    TeamCheck = false,
    Spin = false,
    InfiniteJump = false,
    PlayerCounter = false,
    RGB_Counter = false,
    Xray = false
}

local Camera = workspace.CurrentCamera
local LocalPlayer = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CurrentTarget = nil 

-- Função para verificar se o jogador tem arma
local function HasWeaponEquippedOrOnBack(character)
    if not character then return false end

    for _, child in pairs(character:GetChildren()) do
        if child:IsA("Tool") then
            return true
        end
    end

    local player = game.Players:GetPlayerFromCharacter(character)
    if player and player:FindFirstChild("Backpack") and #player.Backpack:GetChildren() > 0 then
        return true
    end

    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("Model") or part:IsA("Accessory") or part:IsA("Tool") then
            local name = part.Name:lower()
            if name:find("gun") or name:find("rifle") or name:find("weapon") or name:find("pistol") or name:find("sword") or name:find("arma") then
                return true
            end
        end
    end

    return false
end

-- === SISTEMA DA MIRA ===
local CrosshairCenter, CrosshairOuter
pcall(function()
    CrosshairCenter = Drawing.new("Circle")
    CrosshairCenter.Filled = true
    CrosshairCenter.Radius = 2
    CrosshairCenter.Color = Color3.fromRGB(255, 0, 0)
    CrosshairCenter.Transparency = 1
    CrosshairCenter.Visible = true

    CrosshairOuter = Drawing.new("Circle")
    CrosshairOuter.Filled = false
    CrosshairOuter.Radius = 8 
    CrosshairOuter.Thickness = 1.5
    CrosshairOuter.Color = Color3.fromRGB(255, 0, 0)
    CrosshairOuter.Transparency = 0.8
    CrosshairOuter.Visible = true
end)

local function UpdateCrosshair()
    if CrosshairCenter and CrosshairOuter then
        local CenterPosition = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        CrosshairCenter.Position = CenterPosition
        CrosshairOuter.Position = CenterPosition
    end
end

-- UI do Contador de Players
local PlayerCountLabel
pcall(function()
    PlayerCountLabel = Drawing.new("Text")
    PlayerCountLabel.Visible = false
    PlayerCountLabel.Size = 25
    PlayerCountLabel.Center = true
    PlayerCountLabel.Outline = true
    PlayerCountLabel.Position = Vector2.new(Camera.ViewportSize.X / 2, 50)
    PlayerCountLabel.Color = Color3.fromRGB(255, 0, 0)
end)

-- Pulo Infinito
UserInputService.JumpRequest:Connect(function()
    if Settings.InfiniteJump then
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

-- Loop do Noclip
RunService.Stepped:Connect(function()
    if Settings.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- Círculo do FOV
local FOVCircle
pcall(function()
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 1.5
    FOVCircle.Color = Color3.fromRGB(0, 255, 0)
    FOVCircle.Transparency = 0.7
    FOVCircle.Filled = false
    FOVCircle.Visible = true
end)

-- Função Raio-X
local function ApplyXray()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and LocalPlayer.Character and not obj:IsDescendantOf(LocalPlayer.Character) then
            if Settings.Xray then
                if not obj:GetAttribute("OriginalTransparency") then
                    obj:SetAttribute("OriginalTransparency", obj.Transparency)
                end
                obj.Transparency = 0.5 
            else
                local original = obj:GetAttribute("OriginalTransparency")
                if original then
                    obj.Transparency = original
                    obj:SetAttribute("OriginalTransparency", nil)
                end
            end
        end
    end
end

-- Sistema de WallCheck
local function IsVisible(part, character)
    if not Settings.WallCheck then return true end
    if not part or not character then return false end
    
    local Origin = Camera.CFrame.Position
    local Destination = part.Position
    local Direction = Destination - Origin
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, character, Camera}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    
    local raycastResult = workspace:Raycast(Origin, Direction, raycastParams)
    
    if raycastResult then
        local hitPart = raycastResult.Instance
        if hitPart and (not hitPart.CanCollide or hitPart.Transparency >= 0.7) then
            return true
        end
        return false
    end
    
    return true
end

-- Validação de Alvo
local function IsValidTarget(part)
    if not part or not part.Parent then return false end
    local character = part.Parent
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local player = game.Players:GetPlayerFromCharacter(character)
    
    if humanoid and humanoid.Health > 0 then
        if Settings.TeamCheck and player and player.Team == LocalPlayer.Team then return false end
        local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
        local CenterScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local distance = (Vector2.new(pos.X, pos.Y) - CenterScreen).Magnitude
        if distance < Settings.FOV and onScreen and IsVisible(part, character) then
            return true
        end
    end
    return false
end

-- Aimbot
local function GetClosestPlayer()
    if CurrentTarget and IsValidTarget(CurrentTarget) then
        return CurrentTarget
    end

    local target = nil
    local shortestDistance = math.huge
    local CenterScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(Settings.AimPart) then
            local hum = v.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then 
                if Settings.TeamCheck and v.Team == LocalPlayer.Team then continue end
                local part = v.Character[Settings.AimPart]
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                local distance = (Vector2.new(pos.X, pos.Y) - CenterScreen).Magnitude
                if distance < Settings.FOV and onScreen and IsVisible(part, v.Character) then
                    if distance < shortestDistance then
                        target = part
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    
    CurrentTarget = target 
    return target
end

-- Sistema de ESP
local function CreateESP(player)
    local Box, Tracer, HealthBox, DistanceLabel
    pcall(function()
        Box = Drawing.new("Square")
        Box.Visible = false
        Box.Color = Color3.fromRGB(255, 0, 0)
        Box.Thickness = 1.5
        Box.Filled = false

        Tracer = Drawing.new("Line")
        Tracer.Visible = false
        Tracer.Color = Color3.fromRGB(255, 255, 0) 
        Tracer.Thickness = 1.5

        HealthBox = Drawing.new("Square")
        HealthBox.Visible = false
        HealthBox.Thickness = 1
        HealthBox.Color = Color3.fromRGB(0, 255, 0) 
        HealthBox.Filled = true 

        DistanceLabel = Drawing.new("Text")
        DistanceLabel.Visible = false
        DistanceLabel.Color = Color3.fromRGB(255, 255, 255)
        DistanceLabel.Size = 14
        DistanceLabel.Center = true
        DistanceLabel.Outline = true
    end)

    if not Box then return end

    local Connection
    Connection = RunService.RenderStepped:Connect(function()
        if not player or not player.Parent then
            pcall(function()
                Box:Remove()
                Tracer:Remove()
                HealthBox:Remove()
                DistanceLabel:Remove()
            end)
            Connection:Disconnect()
            return
        end

        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
            local RootPart = char.HumanoidRootPart
            local Humanoid = char.Humanoid
            local pos, onScreen = Camera:WorldToViewportPoint(RootPart.Position)

            local Highlight = char:FindFirstChild("HologramESP")
            local hasWeapon = HasWeaponEquippedOrOnBack(char)

            if Settings.HologramESP and hasWeapon then
                if not Highlight then
                    Highlight = Instance.new("Highlight")
                    Highlight.Name = "HologramESP"
                    Highlight.FillColor = Color3.fromRGB(0, 255, 255)
                    Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    Highlight.FillTransparency = 0.4
                    Highlight.OutlineTransparency = 0
                    Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    Highlight.Adornee = char
                    Highlight.Parent = char
                end
                Highlight.Enabled = true
            else
                if Highlight then
                    Highlight.Enabled = false
                end
            end

            if onScreen then
                if Settings.Tracers then
                    Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                    Tracer.To = Vector2.new(pos.X, pos.Y)
                    Tracer.Visible = true
                else
                    Tracer.Visible = false
                end

                local TopWorld = (RootPart.CFrame * CFrame.new(0, 3, 0)).Position
                local BottomWorld = (RootPart.CFrame * CFrame.new(0, -3.5, 0)).Position
                
                local TopLeft = Camera:WorldToViewportPoint(TopWorld)
                local BottomLeft = Camera:WorldToViewportPoint(BottomWorld)

                local sizeY = math.abs(TopLeft.Y - BottomLeft.Y)
                local sizeX = sizeY * 0.6 
                local boxX = pos.X - sizeX / 2
                local boxY = TopLeft.Y

                if Settings.ESP then
                    Box.Size = Vector2.new(sizeX, sizeY)
                    Box.Position = Vector2.new(boxX, boxY)
                    Box.Visible = true
                else
                    Box.Visible = false
                end

                if Settings.HealthESP then
                    local healthPercent = math.clamp(Humanoid.Health / Humanoid.MaxHealth, 0, 1)
                    local barWidth = 3 
                    
                    HealthBox.Size = Vector2.new(barWidth, sizeY * healthPercent)
                    HealthBox.Position = Vector2.new(boxX - (barWidth + 3), boxY + sizeY - (sizeY * healthPercent))
                    HealthBox.Visible = true
                else
                    HealthBox.Visible = false
                end

                if Settings.DistanceESP then
                    local dist = math.floor((RootPart.Position - Camera.CFrame.Position).Magnitude)
                    DistanceLabel.Text = "[" .. tostring(dist) .. "m]"
                    DistanceLabel.Position = Vector2.new(pos.X, boxY - 16)
                    DistanceLabel.Visible = true
                else
                    DistanceLabel.Visible = false
                end
            else
                Box.Visible = false
                Tracer.Visible = false
                HealthBox.Visible = false
                DistanceLabel.Visible = false
            end
        else
            Box.Visible = false
            Tracer.Visible = false
            HealthBox.Visible = false
            DistanceLabel.Visible = false
        end
    end)
end

for _, v in pairs(game.Players:GetPlayers()) do
    if v ~= LocalPlayer then CreateESP(v) end
end
game.Players.PlayerAdded:Connect(function(v)
    if v ~= LocalPlayer then CreateESP(v) end
end)

-- Loop Geral do Jogo
RunService.RenderStepped:Connect(function()
    UpdateCrosshair() 
    
    if FOVCircle then
        FOVCircle.Radius = Settings.FOV
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Visible = (Settings.FOV > 0)
    end

    if Settings.PlayerCounter and PlayerCountLabel then
        PlayerCountLabel.Text = "PLAYERS: " .. tostring(#game.Players:GetPlayers())
        PlayerCountLabel.Visible = true
        if Settings.RGB_Counter then
            PlayerCountLabel.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
        else
            PlayerCountLabel.Color = Color3.fromRGB(255, 0, 0)
        end
    elseif PlayerCountLabel then
        PlayerCountLabel.Visible = false
    end

    if Settings.Aimbot then
        local target = GetClosestPlayer()
        if target then 
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position) 
            if Settings.AutoShot then
                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool then tool:Activate() end
            end
        else
            CurrentTarget = nil 
        end
    else
        CurrentTarget = nil 
    end

    if Settings.Spin then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(50), 0)
        end
    end
end)

--- Interface (Rayfield) ---

-- 1. Aba de Combate
local CombatTab = Window:CreateTab("Combate", 4483362458)

CombatTab:CreateToggle({
   Name = "Ativar Aimbot",
   CurrentValue = false,
   Callback = function(Value) Settings.Aimbot = Value end,
})

CombatTab:CreateToggle({
    Name = "Verificar Paredes (WallCheck)",
    CurrentValue = true, 
    Callback = function(Value) Settings.WallCheck = Value end,
 })

CombatTab:CreateToggle({
    Name = "Tiro Automático",
    CurrentValue = false,
    Callback = function(Value) Settings.AutoShot = Value end,
 })

-- 2. Aba Visual
local VisualTab = Window:CreateTab("Visual", 4483362458)

VisualTab:CreateToggle({
    Name = "ESP Holograma (Corpo + Armas)",
    CurrentValue = false,
    Callback = function(Value) Settings.HologramESP = Value end,
})

VisualTab:CreateToggle({
    Name = "Raio-X (Wallhack)",
    CurrentValue = false,
    Callback = function(Value) 
        Settings.Xray = Value 
        ApplyXray()
    end,
})

VisualTab:CreateToggle({
    Name = "Contador de Players",
    CurrentValue = false,
    Callback = function(Value) Settings.PlayerCounter = Value end,
})

VisualTab:CreateToggle({
    Name = "Contador em RGB",
    CurrentValue = false,
    Callback = function(Value) Settings.RGB_Counter = Value end,
})

VisualTab:CreateToggle({
   Name = "Ativar Box ESP",
   CurrentValue = false,
   Callback = function(Value) Settings.ESP = Value end,
})

VisualTab:CreateToggle({
    Name = "Linhas Centrais (Tracers)",
    CurrentValue = false,
    Callback = function(Value) Settings.Tracers = Value end,
 })

VisualTab:CreateToggle({
   Name = "Barra de Vida Quadrada Lateral",
   CurrentValue = false,
   Callback = function(Value) Settings.HealthESP = Value end,
})

VisualTab:CreateToggle({
   Name = "Mostrar Distância",
   CurrentValue = false,
   Callback = function(Value) Settings.DistanceESP = Value end,
})

-- 3. Aba de Player / Extras (Nova Aba)
local PlayerTab = Window:CreateTab("Player / Extras", 4483362458)

PlayerTab:CreateToggle({
    Name = "Noclip (Atravessar Paredes)",
    CurrentValue = false,
    Callback = function(Value) Settings.Noclip = Value end,
 })

PlayerTab:CreateToggle({
   Name = "Infinite Jump (Pulo Infinito)",
   CurrentValue = false,
   Callback = function(Value) Settings.InfiniteJump = Value end,
})

PlayerTab:CreateToggle({
   Name = "Spin (Giro Automático)",
   CurrentValue = false,
   Callback = function(Value) Settings.Spin = Value end,
})

PlayerTab:CreateSection("Ajustes de Mira")

PlayerTab:CreateSlider({
   Name = "Raio do FOV",
   Range = {50, 800},
   Increment = 10,
   CurrentValue = 150,
   Callback = function(Value) Settings.FOV = Value end,
})
