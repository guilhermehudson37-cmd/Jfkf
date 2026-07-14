--[[
    Ghub - Blox Fruits Script (Versão Avançada)
    - Auto Farm: 
        * Obtém missão automaticamente com base no level
        * Navega até o NPC da missão usando Tween
        * Interage com o NPC para pegar a missão
        * Vai até a área dos mobs da missão
        * Farm contínuo com Auto Click e Bring Mobs automático
    - Auto Haki: ativa automaticamente quando necessário (sem toggle)
    - Bring Mobs: integrado ao farm, puxa mobs periodicamente
    - Sistema de Key: "jpeqck789"
    - Interface com minimizar e fechar
]]

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Config
local ATTACK_DISTANCE = 15      -- Distância de ataque
local BRING_INTERVAL = 5        -- Segundos entre cada Bring Mobs
local HAKI_KEY = "G"            -- Tecla do Haki
local AUTO_CLICK_INTERVAL = 0.15

-- Variáveis de estado
local autoFarmEnabled = false
local autoHakiEnabled = true    -- Sempre ativo
local farmLoopConnection = nil
local hakiLoopConnection = nil
local attackLoopConnection = nil
local bringLoopConnection = nil
local statusText = "Desligado"
local isMinimized = false
local currentQuest = nil        -- Armazena informações da missão atual

-- GUI references
local mainScreenGui = nil
local mainFrame = nil
local minimizeButton = nil
local restoreButton = nil
local statusLabel = nil
local farmToggle = nil

-- Helper: Obter nível do jogador
local function getPlayerLevel()
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local level = leaderstats:FindFirstChild("Level") or leaderstats:FindFirstChild("Levels")
        if level then
            return level.Value
        end
    end
    return 0
end

-- Dados das missões por nível (exemplo simplificado)
-- Estrutura: { minLevel, maxLevel, npcName, npcLocation, mobName, mobLocation }
local quests = {
    { min = 1, max = 10, npcName = "Pirate Villager", npcLocation = Vector3.new(-100, 10, 50), 
      mobName = "Bandit", mobLocation = Vector3.new(-200, 10, 100) },
    { min = 11, max = 25, npcName = "Pirate Captain", npcLocation = Vector3.new(0, 10, 0),
      mobName = "Pirate", mobLocation = Vector3.new(100, 10, 50) },
    -- Adicione mais níveis conforme necessário
    { min = 26, max = 50, npcName = "Jungle Guy", npcLocation = Vector3.new(200, 10, -100),
      mobName = "Jungle Wolf", mobLocation = Vector3.new(250, 10, -150) },
    { min = 51, max = 100, npcName = "Ice Admiral", npcLocation = Vector3.new(-300, 10, 200),
      mobName = "Ice Soldier", mobLocation = Vector3.new(-350, 10, 250) },
}

-- Função para obter a missão apropriada para o nível atual
local function getQuestForLevel(level)
    for _, q in ipairs(quests) do
        if level >= q.min and level <= q.max then
            return q
        end
    end
    return nil
end

-- Verifica se um modelo é um mob da missão atual
local function isQuestMob(model)
    if not currentQuest then return false end
    if not model or not model:IsA("Model") then return false end
    if model == character then return false end
    local hum = model:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    -- Verifica se o nome contém o nome do mob da missão
    local mobName = currentQuest.mobName
    if model.Name:find(mobName) then
        return true
    end
    return false
end

-- Obtém todos os mobs da missão ativa
local function getQuestMobs()
    local mobs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and isQuestMob(obj) then
            local root = obj:FindFirstChild("HumanoidRootPart")
            if root then
                table.insert(mobs, {
                    Model = obj,
                    Humanoid = obj:FindFirstChild("Humanoid"),
                    RootPart = root
                })
            end
        end
    end
    return mobs
end

-- Encontra o mob mais próximo da missão
local function findNearestQuestMob()
    local mobs = getQuestMobs()
    local nearest = nil
    local minDist = math.huge
    local playerPos = rootPart.Position
    for _, mob in ipairs(mobs) do
        local dist = (mob.RootPart.Position - playerPos).Magnitude
        if dist < minDist then
            minDist = dist
            nearest = mob
        end
    end
    return nearest
end

-- Helper: Tween para uma posição
local function tweenToPosition(targetPos, callback)
    local tweenInfo = TweenInfo.new(
        0.8,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )
    local goal = {CFrame = CFrame.new(targetPos)}
    local tween = TweenService:Create(rootPart, tweenInfo, goal)
    tween:Play()
    tween.Completed:Wait()
    if callback then callback() end
end

-- Função para interagir com NPC (pressiona E e clica no NPC)
local function interactWithNPC(npcModel)
    if not npcModel then return false end
    local npcRoot = npcModel:FindFirstChild("HumanoidRootPart") or npcModel:FindFirstChild("Head")
    if not npcRoot then return false end
    -- Move para perto do NPC
    local npcPos = npcRoot.Position
    local dir = (npcPos - rootPart.Position).Unit
    local standPos = npcPos - dir * 5
    tweenToPosition(standPos)
    task.wait(0.5)
    -- Pressiona E para interagir
    VirtualInputManager:SendKeyEvent(true, "E", false, nil)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, "E", false, nil)
    task.wait(0.5)
    -- Agora esperamos o diálogo e clicamos no botão "Aceitar" (ou similar)
    -- Para simplicidade, esperamos 1s e depois clicamos em uma posição fixa onde o botão costuma aparecer
    -- Em Blox Fruits, o botão de aceitar geralmente está no centro inferior
    -- Mas podemos tentar detectar o botão pela GUI
    -- Vamos usar um clique na tela (posição central) - isso pode ser ajustado
    local screenSize = Camera.ViewportSize
    local clickX = screenSize.X / 2
    local clickY = screenSize.Y / 2 + 100 -- Ajuste conforme necessário
    VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, "Left", 0)
    task.wait(0.1)
    VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, "Left", 0)
    task.wait(0.5)
    return true
end

-- Função para pegar a missão
local function takeQuest()
    if not currentQuest then return false end
    -- Encontra o NPC com base no nome
    local npc = nil
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find(currentQuest.npcName) then
            npc = obj
            break
        end
    end
    if not npc then
        statusText = "NPC não encontrado!"
        return false
    end
    statusText = "Interagindo com " .. currentQuest.npcName
    return interactWithNPC(npc)
end

-- Função para fazer Bring Mobs (puxa mobs próximos para perto do jogador)
local function bringMobs()
    local mobs = getQuestMobs()
    local playerPos = rootPart.Position
    for _, mob in ipairs(mobs) do
        local dist = (mob.RootPart.Position - playerPos).Magnitude
        if dist <= 100 then -- raio de busca
            local targetPos = playerPos + Vector3.new(math.random(-6, 6), 0, math.random(-6, 6))
            local tween = TweenService:Create(mob.RootPart, TweenInfo.new(0.6, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)})
            tween:Play()
            task.wait(0.08)
        end
    end
end

-- Função de ataque (Auto Click)
local function attackLoop()
    while autoFarmEnabled and task.wait(AUTO_CLICK_INTERVAL) do
        local target = findNearestQuestMob()
        if target then
            local dist = (target.RootPart.Position - rootPart.Position).Magnitude
            if dist <= ATTACK_DISTANCE + 2 then
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, "Left", 0)
                task.wait(0.05)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, "Left", 0)
            end
        end
    end
end

-- Loop principal do Auto Farm
local function farmLoop()
    while autoFarmEnabled and task.wait(0.1) do
        -- 1. Verifica se há missão ativa, senão obtém uma
        if not currentQuest then
            local level = getPlayerLevel()
            currentQuest = getQuestForLevel(level)
            if not currentQuest then
                statusText = "Nível sem missão definida"
                task.wait(2)
                continue
            end
            -- Tenta pegar a missão
            statusText = "Pegando missão..."
            local success = takeQuest()
            if not success then
                statusText = "Falha ao pegar missão"
                task.wait(3)
                continue
            else
                statusText = "Missão obtida!"
                task.wait(1)
            end
        end

        -- 2. Move para a área dos mobs
        local mobArea = currentQuest.mobLocation
        local currentPos = rootPart.Position
        if (mobArea - currentPos).Magnitude > 20 then
            statusText = "Indo para área dos mobs..."
            tweenToPosition(mobArea)
            task.wait(0.5)
        end

        -- 3. Procura um mob da missão para atacar
        local target = findNearestQuestMob()
        if target then
            local targetPos = target.RootPart.Position
            local dist = (targetPos - currentPos).Magnitude
            if dist > ATTACK_DISTANCE then
                -- Move para perto do mob
                local direction = (targetPos - currentPos).Unit
                local goalPos = targetPos - direction * ATTACK_DISTANCE
                tweenToPosition(goalPos)
                task.wait(0.3)
            end
            -- O ataque contínuo é feito pelo attackLoop
            statusText = "Farmando " .. currentQuest.mobName
        else
            statusText = "Procurando mobs..."
            -- Se não há mobs, talvez estejamos na área errada, tenta ir para o centro
            tweenToPosition(mobArea)
            task.wait(1)
        end
    end
end

-- Loop do Bring Mobs (executado em paralelo)
local function bringLoop()
    while autoFarmEnabled and task.wait(BRING_INTERVAL) do
        if currentQuest then
            bringMobs()
        end
    end
end

-- Auto Haki (sempre ativo)
local function hakiLoop()
    while autoHakiEnabled and task.wait(0.5) do
        local hakiActive = false
        -- Verifica se algum filho do personagem indica Haki ativo
        for _, child in ipairs(character:GetChildren()) do
            local name = child.Name:lower()
            if name:find("haki") or name:find("ken") or name:find("observation") then
                hakiActive = true
                break
            end
        end
        if not hakiActive then
            VirtualInputManager:SendKeyEvent(true, HAKI_KEY, false, nil)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, HAKI_KEY, false, nil)
        end
    end
end

-- Funções de toggle
local function toggleAutoFarm(state)
    autoFarmEnabled = state
    if autoFarmEnabled then
        -- Inicia todos os loops
        if farmLoopConnection then farmLoopConnection:Disconnect() end
        farmLoopConnection = RunService.Heartbeat:Connect(farmLoop)
        
        if attackLoopConnection then attackLoopConnection:Disconnect() end
        attackLoopConnection = RunService.Heartbeat:Connect(attackLoop)
        
        if bringLoopConnection then bringLoopConnection:Disconnect() end
        bringLoopConnection = RunService.Heartbeat:Connect(bringLoop)
        
        -- Auto Haki já está rodando
        statusText = "Iniciando..."
    else
        if farmLoopConnection then farmLoopConnection:Disconnect(); farmLoopConnection = nil end
        if attackLoopConnection then attackLoopConnection:Disconnect(); attackLoopConnection = nil end
        if bringLoopConnection then bringLoopConnection:Disconnect(); bringLoopConnection = nil end
        currentQuest = nil
        statusText = "Desligado"
    end
    -- Atualiza GUI
    if farmToggle then
        farmToggle.Text = "Auto Farm: " .. (state and "ON" or "OFF")
        farmToggle.BackgroundColor3 = state and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(60, 60, 60)
    end
    if statusLabel then
        statusLabel.Text = "Status: " .. statusText
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

-- Criação da GUI Principal
local function createMainGUI()
    mainScreenGui = Instance.new("ScreenGui")
    mainScreenGui.Name = "Ghub"
    mainScreenGui.ResetOnSpawn = false
    mainScreenGui.Parent = CoreGui

    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 200)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = mainScreenGui

    -- Título e botão minimizar
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

    -- Toggle Auto Farm
    farmToggle = Instance.new("TextButton")
    farmToggle.Size = UDim2.new(0.8, 0, 0, 35)
    farmToggle.Position = UDim2.new(0.1, 0, 0.2, 0)
    farmToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    farmToggle.Text = "Auto Farm: OFF"
    farmToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    farmToggle.Font = Enum.Font.Gotham
    farmToggle.TextScaled = true
    farmToggle.Parent = mainFrame
    farmToggle.MouseButton1Click:Connect(function()
        toggleAutoFarm(not autoFarmEnabled)
    end)

    -- Status Label
    statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0.9, 0, 0, 30)
    statusLabel.Position = UDim2.new(0.05, 0, 0.5, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Status: " .. statusText
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextScaled = true
    statusLabel.Parent = mainFrame

    -- Botão Fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0.3, 0, 0, 30)
    closeBtn.Position = UDim2.new(0.35, 0, 0.75, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    closeBtn.Text = "Close"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.Gotham
    closeBtn.TextScaled = true
    closeBtn.Parent = mainFrame
    closeBtn.MouseButton1Click:Connect(function()
        toggleAutoFarm(false)
        if mainScreenGui then mainScreenGui:Destroy() end
        if restoreButton then restoreButton:Destroy() end
        autoHakiEnabled = false -- Desliga Haki também
        if hakiLoopConnection then hakiLoopConnection:Disconnect() end
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

    -- Inicia o Auto Haki (sempre ativo)
    autoHakiEnabled = true
    if hakiLoopConnection then hakiLoopConnection:Disconnect() end
    hakiLoopConnection = RunService.Heartbeat:Connect(hakiLoop)
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

-- Iniciar
createKeyGUI()

-- Cleanup ao respawn
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    -- Reativa loops se necessário
    if autoFarmEnabled then
        toggleAutoFarm(true)
    end
end)
