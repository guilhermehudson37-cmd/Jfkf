--[[
    Ghub - Blox Fruits Script (Melhorado)
    Features:
    - Auto Farm com Tween (distância de 15 studs)
    - Auto Click (ataque contínuo enquanto próximo)
    - Bring Mobs
    - Auto Haki (melhor detecção)
    - Minimizar/Expandir Hub
    - Key System (jpeqck789)
]]

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Config
local ATTACK_DISTANCE = 15 -- Distância de ataque
local HAKI_KEY = "G"       -- Tecla para ativar Haki
local AUTO_CLICK_INTERVAL = 0.15 -- Intervalo entre ataques

-- Variables
local autoFarmEnabled = false
local autoHakiEnabled = false
local autoClickEnabled = false
local bringMobsCooldown = false
local farmLoopConnection = nil
local hakiLoopConnection = nil
local attackLoopConnection = nil
local isMinimized = false

-- GUI references
local mainScreenGui = nil
local mainFrame = nil
local minimizeButton = nil
local restoreButton = nil

-- Helper: Check if a model is an enemy (NPC)
local function isEnemy(model)
    if not model or not model:IsA("Model") then return false end
    if model == character then return false end
    local hum = model:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    -- Add specific filters for Blox Fruits (ex: exclude friendly NPCs)
    return true
end

-- Helper: Get all enemies
local function getEnemies()
    local enemies = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and isEnemy(obj) then
            local root = obj:FindFirstChild("HumanoidRootPart")
            if root then
                table.insert(enemies, {
                    Model = obj,
                    Humanoid = obj:FindFirstChild("Humanoid"),
                    RootPart = root
                })
            end
        end
    end
    return enemies
end

-- Helper: Find nearest enemy
local function findNearestEnemy()
    local enemies = getEnemies()
    local nearest = nil
    local minDist = math.huge
    local playerPos = rootPart.Position
    for _, enemy in ipairs(enemies) do
        local dist = (enemy.RootPart.Position - playerPos).Magnitude
        if dist < minDist then
            minDist = dist
            nearest = enemy
        end
    end
    return nearest
end

-- Helper: Tween to position (using CFrame)
local function tweenToPosition(targetPos)
    local tweenInfo = TweenInfo.new(
        0.8, -- time
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )
    local goal = {CFrame = CFrame.new(targetPos)}
    local tween = TweenService:Create(rootPart, tweenInfo, goal)
    tween:Play()
    tween.Completed:Wait()
end

-- Auto Farm movement logic
local function farmLoop()
    while autoFarmEnabled and task.wait(0.1) do
        local target = findNearestEnemy()
        if target then
            local targetPos = target.RootPart.Position
            local currentPos = rootPart.Position
            local distance = (targetPos - currentPos).Magnitude
            if distance > ATTACK_DISTANCE then
                -- Move towards enemy until ATTACK_DISTANCE away
                local direction = (targetPos - currentPos).Unit
                local goalPos = targetPos - direction * ATTACK_DISTANCE
                tweenToPosition(goalPos)
            end
            -- Se já estiver na distância, o ataque contínuo será feito pelo attackLoop
        end
    end
end

-- Auto Click loop (ataque contínuo)
local function attackLoop()
    while autoFarmEnabled and autoClickEnabled and task.wait(AUTO_CLICK_INTERVAL) do
        local target = findNearestEnemy()
        if target then
            local dist = (target.RootPart.Position - rootPart.Position).Magnitude
            if dist <= ATTACK_DISTANCE + 2 then -- margem
                -- Simula clique esquerdo
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, "Left", 0)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, "Left", 0)
            end
        end
    end
end

-- Bring Mobs
local function bringMobs()
    if bringMobsCooldown then return end
    bringMobsCooldown = true
    local playerPos = rootPart.Position
    local enemies = getEnemies()
    local gathered = 0
    for _, enemy in ipairs(enemies) do
        local dist = (enemy.RootPart.Position - playerPos).Magnitude
        if dist <= 100 then
            local targetPos = playerPos + Vector3.new(math.random(-8, 8), 0, math.random(-8, 8))
            local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(enemy.RootPart, tweenInfo, {CFrame = CFrame.new(targetPos)})
            tween:Play()
            gathered = gathered + 1
            task.wait(0.08)
        end
    end
    task.wait(1)
    bringMobsCooldown = false
end

-- Auto Haki
local function hakiLoop()
    while autoHakiEnabled and task.wait(0.5) do
        local hakiActive = false
        -- Verifica se existe algum indicador de Haki ativo (ex: parte com nome específico)
        for _, child in ipairs(character:GetChildren()) do
            if child.Name:lower():find("haki") or child.Name:lower():find("ken") then
                hakiActive = true
                break
            end
        end
        -- Alternativa: verificar se o jogador tem um atributo booleano
        if not hakiActive then
            -- Ativa Haki pressionando a tecla
            VirtualInputManager:SendKeyEvent(true, HAKI_KEY, false, nil)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, HAKI_KEY, false, nil)
        end
    end
end

-- Toggle functions
local function toggleAutoFarm(state)
    autoFarmEnabled = state
    if autoFarmEnabled then
        if farmLoopConnection then farmLoopConnection:Disconnect() end
        farmLoopConnection = RunService.Heartbeat:Connect(farmLoop)
        -- Auto click liga automaticamente com o farm
        toggleAutoClick(state)
    else
        if farmLoopConnection then
            farmLoopConnection:Disconnect()
            farmLoopConnection = nil
        end
        toggleAutoClick(false)
    end
end

local function toggleAutoClick(state)
    autoClickEnabled = state
    if autoClickEnabled and autoFarmEnabled then
        if attackLoopConnection then attackLoopConnection:Disconnect() end
        attackLoopConnection = RunService.Heartbeat:Connect(attackLoop)
    else
        if attackLoopConnection then
            attackLoopConnection:Disconnect()
            attackLoopConnection = nil
        end
    end
end

local function toggleAutoHaki(state)
    autoHakiEnabled = state
    if autoHakiEnabled then
        if hakiLoopConnection then hakiLoopConnection:Disconnect() end
        hakiLoopConnection = RunService.Heartbeat:Connect(hakiLoop)
    else
        if hakiLoopConnection then
            hakiLoopConnection:Disconnect()
            hakiLoopConnection = nil
        end
    end
end

-- GUI: Minimizar e Restaurar
local function minimizeGUI()
    if mainFrame then
        mainFrame.Visible = false
        isMinimized = true
        if restoreButton then
            restoreButton.Visible = true
        end
    end
end

local function restoreGUI()
    if mainFrame then
        mainFrame.Visible = true
        isMinimized = false
        if restoreButton then
            restoreButton.Visible = false
        end
    end
end

-- Criar GUI Principal
local function createMainGUI()
    mainScreenGui = Instance.new("ScreenGui")
    mainScreenGui.Name = "Ghub"
    mainScreenGui.ResetOnSpawn = false
    mainScreenGui.Parent = CoreGui

    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 280)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -140)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = mainScreenGui

    -- Title + Minimize button
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0.8, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Ghub"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame

    minimizeButton = Instance.new("TextButton")
    minimizeButton.Size = UDim2.new(0, 40, 0, 40)
    minimizeButton.Position = UDim2.new(1, -50, 0, 0)
    minimizeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    minimizeButton.Text = "_"
    minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    minimizeButton.Font = Enum.Font.Gotham
    minimizeButton.TextScaled = true
    minimizeButton.Parent = mainFrame
    minimizeButton.MouseButton1Click:Connect(minimizeGUI)

    -- Auto Farm Toggle
    local farmToggle = Instance.new("TextButton")
    farmToggle.Size = UDim2.new(0.8, 0, 0, 35)
    farmToggle.Position = UDim2.new(0.1, 0, 0.15, 0)
    farmToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    farmToggle.Text = "Auto Farm: OFF"
    farmToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    farmToggle.Font = Enum.Font.Gotham
    farmToggle.TextScaled = true
    farmToggle.Parent = mainFrame
    farmToggle.MouseButton1Click:Connect(function()
        local newState = not autoFarmEnabled
        toggleAutoFarm(newState)
        farmToggle.Text = "Auto Farm: " .. (newState and "ON" or "OFF")
        farmToggle.BackgroundColor3 = newState and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(60, 60, 60)
    end)

    -- Auto Haki Toggle
    local hakiToggle = Instance.new("TextButton")
    hakiToggle.Size = UDim2.new(0.8, 0, 0, 35)
    hakiToggle.Position = UDim2.new(0.1, 0, 0.33, 0)
    hakiToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    hakiToggle.Text = "Auto Haki: OFF"
    hakiToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    hakiToggle.Font = Enum.Font.Gotham
    hakiToggle.TextScaled = true
    hakiToggle.Parent = mainFrame
    hakiToggle.MouseButton1Click:Connect(function()
        local newState = not autoHakiEnabled
        toggleAutoHaki(newState)
        hakiToggle.Text = "Auto Haki: " .. (newState and "ON" or "OFF")
        hakiToggle.BackgroundColor3 = newState and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(60, 60, 60)
    end)

    -- Bring Mobs Button
    local bringButton = Instance.new("TextButton")
    bringButton.Size = UDim2.new(0.8, 0, 0, 35)
    bringButton.Position = UDim2.new(0.1, 0, 0.51, 0)
    bringButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    bringButton.Text = "Bring Mobs"
    bringButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    bringButton.Font = Enum.Font.Gotham
    bringButton.TextScaled = true
    bringButton.Parent = mainFrame
    bringButton.MouseButton1Click:Connect(bringMobs)

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0.3, 0, 0, 30)
    closeBtn.Position = UDim2.new(0.35, 0, 0.7, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    closeBtn.Text = "Close"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.Gotham
    closeBtn.TextScaled = true
    closeBtn.Parent = mainFrame
    closeBtn.MouseButton1Click:Connect(function()
        toggleAutoFarm(false)
        toggleAutoHaki(false)
        if mainScreenGui then mainScreenGui:Destroy() end
        if restoreButton then restoreButton:Destroy() end
    end)

    -- Botão de restauração (aparece quando minimizado)
    restoreButton = Instance.new("TextButton")
    restoreButton.Size = UDim2.new(0, 50, 0, 50)
    restoreButton.Position = UDim2.new(1, -60, 0, 10)
    restoreButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    restoreButton.Text = "G"
    restoreButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    restoreButton.Font = Enum.Font.GothamBold
    restoreButton.TextScaled = true
    restoreButton.Visible = false
    restoreButton.Parent = mainScreenGui
    restoreButton.MouseButton1Click:Connect(restoreGUI)
end

-- Key System GUI
local function createKeyGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GhubKey"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 150)
    frame.Position = UDim2.new(0.5, -150, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Enter Key"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0.8, 0, 0, 30)
    textBox.Position = UDim2.new(0.1, 0, 0.3, 0)
    textBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.Font = Enum.Font.Gotham
    textBox.TextScaled = true
    textBox.PlaceholderText = "Key"
    textBox.Parent = frame

    local submitBtn = Instance.new("TextButton")
    submitBtn.Size = UDim2.new(0.5, 0, 0, 30)
    submitBtn.Position = UDim2.new(0.25, 0, 0.6, 0)
    submitBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    submitBtn.Text = "Submit"
    submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitBtn.Font = Enum.Font.Gotham
    submitBtn.TextScaled = true
    submitBtn.Parent = frame

    local errorLabel = Instance.new("TextLabel")
    errorLabel.Size = UDim2.new(1, 0, 0, 20)
    errorLabel.Position = UDim2.new(0, 0, 0.85, 0)
    errorLabel.BackgroundTransparency = 1
    errorLabel.Text = ""
    errorLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    errorLabel.TextScaled = true
    errorLabel.Font = Enum.Font.Gotham
    errorLabel.Parent = frame

    submitBtn.MouseButton1Click:Connect(function()
        local input = textBox.Text
        if input == "jpeqck789" then
            screenGui:Destroy()
            createMainGUI()
        else
            errorLabel.Text = "Invalid Key!"
            textBox.Text = ""
            task.wait(2)
            errorLabel.Text = ""
        end
    end)
end

-- Iniciar Key GUI
createKeyGUI()

-- Cleanup on respawn
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    if autoFarmEnabled then
        toggleAutoFarm(true)
    end
    if autoHakiEnabled then
        toggleAutoHaki(true)
    end
end)
