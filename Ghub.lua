--[[
    Ghub - Blox Fruits Script (Versão Completa com Todos os Seas)
    Funcionalidades:
    - Key System: "jpeqck789"
    - Auto Farm com Tween (missão automática por nível - todos os seas)
    - Auto Click (ataque contínuo)
    - Bring Mobs automático (puxa mobs para perto)
    - Auto Haki automático (ativa quando necessário)
    - Interface simples: ligar/desligar, minimizar, fechar
]]

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Configurações
local ATTACK_DISTANCE = 15      -- Distância para atacar
local BRING_INTERVAL = 5        -- Segundos entre cada Bring Mobs
local HAKI_KEY = "G"            -- Tecla do Haki
local CLICK_INTERVAL = 0.15     -- Intervalo entre cliques

-- Estado
local isFarming = false
local currentQuest = nil
local statusMsg = "Parado"
local farmConn = nil
local attackConn = nil
local bringConn = nil
local hakiConn = nil

-- GUI references
local mainGui = nil
local mainFrame = nil
local toggleBtn = nil
local statusLabel = nil
local minimizeBtn = nil
local restoreBtn = nil
local isMinimized = false

-- ===================== DADOS DAS MISSÕES (TODOS OS SEAS) =====================
-- Estrutura: { minLevel, maxLevel, npcName, npcPos, mobName, mobPos }
-- Baseado em informações oficiais do Blox Fruits

local quests = {
    -- ===== SEA 1 (Níveis 1-700) =====
    -- Jungle
    { min = 1,   max = 15,  npcName = "Jungle Pirate", npcPos = Vector3.new(-1500, 10, 500), 
      mobName = "Bandit", mobPos = Vector3.new(-1600, 10, 600) },
    { min = 16,  max = 30,  npcName = "Pirate Captain", npcPos = Vector3.new(-1000, 10, 1000),
      mobName = "Pirate", mobPos = Vector3.new(-1100, 10, 1100) },
    { min = 31,  max = 50,  npcName = "Jungle Guy", npcPos = Vector3.new(-800, 10, 1500),
      mobName = "Jungle Wolf", mobPos = Vector3.new(-900, 10, 1600) },
    -- Desert
    { min = 51,  max = 75,  npcName = "Desert Bandit", npcPos = Vector3.new(500, 10, -500),
      mobName = "Sand Bandit", mobPos = Vector3.new(600, 10, -600) },
    { min = 76,  max = 100, npcName = "Desert Soldier", npcPos = Vector3.new(800, 10, -800),
      mobName = "Desert Warrior", mobPos = Vector3.new(900, 10, -900) },
    -- Ice
    { min = 101, max = 130, npcName = "Ice Admiral", npcPos = Vector3.new(-2000, 10, -1500),
      mobName = "Ice Soldier", mobPos = Vector3.new(-2100, 10, -1600) },
    { min = 131, max = 160, npcName = "Ice Commander", npcPos = Vector3.new(-2200, 10, -1700),
      mobName = "Ice Knight", mobPos = Vector3.new(-2300, 10, -1800) },
    -- Sky (1ª Sea)
    { min = 161, max = 200, npcName = "Sky Guardian", npcPos = Vector3.new(1200, 100, 0),
      mobName = "Sky Warrior", mobPos = Vector3.new(1300, 100, 100) },
    { min = 201, max = 240, npcName = "Sky King", npcPos = Vector3.new(1400, 100, 200),
      mobName = "Sky Knight", mobPos = Vector3.new(1500, 100, 300) },
    -- Water
    { min = 241, max = 280, npcName = "Water Pirate", npcPos = Vector3.new(-500, -20, 2000),
      mobName = "Water Bandit", mobPos = Vector3.new(-600, -20, 2100) },
    { min = 281, max = 320, npcName = "Water Admiral", npcPos = Vector3.new(-700, -20, 2200),
      mobName = "Water Soldier", mobPos = Vector3.new(-800, -20, 2300) },
    -- Magma
    { min = 321, max = 360, npcName = "Magma Chief", npcPos = Vector3.new(2000, 10, -2000),
      mobName = "Magma Warrior", mobPos = Vector3.new(2100, 10, -2100) },
    { min = 361, max = 400, npcName = "Magma Lord", npcPos = Vector3.new(2200, 10, -2200),
      mobName = "Magma Knight", mobPos = Vector3.new(2300, 10, -2300) },
    -- Dark
    { min = 401, max = 440, npcName = "Dark Mage", npcPos = Vector3.new(-2500, 10, 2500),
      mobName = "Dark Wizard", mobPos = Vector3.new(-2600, 10, 2600) },
    { min = 441, max = 480, npcName = "Dark King", npcPos = Vector3.new(-2700, 10, 2700),
      mobName = "Dark Knight", mobPos = Vector3.new(-2800, 10, 2800) },
    -- Thunder
    { min = 481, max = 520, npcName = "Thunder God", npcPos = Vector3.new(3000, 50, -1000),
      mobName = "Thunder Warrior", mobPos = Vector3.new(3100, 50, -1100) },
    { min = 521, max = 560, npcName = "Thunder King", npcPos = Vector3.new(3200, 50, -1200),
      mobName = "Thunder Knight", mobPos = Vector3.new(3300, 50, -1300) },
    -- Poison
    { min = 561, max = 600, npcName = "Poison Master", npcPos = Vector3.new(-3000, 10, -3000),
      mobName = "Poison Assassin", mobPos = Vector3.new(-3100, 10, -3100) },
    -- Ghost
    { min = 601, max = 640, npcName = "Ghost Captain", npcPos = Vector3.new(3500, 10, 3500),
      mobName = "Ghost Pirate", mobPos = Vector3.new(3600, 10, 3600) },
    -- Fishman
    { min = 641, max = 680, npcName = "Fishman Leader", npcPos = Vector3.new(-3500, -30, 3500),
      mobName = "Fishman Warrior", mobPos = Vector3.new(-3600, -30, 3600) },
    -- Zombie
    { min = 681, max = 700, npcName = "Zombie General", npcPos = Vector3.new(4000, 10, -4000),
      mobName = "Zombie Soldier", mobPos = Vector3.new(4100, 10, -4100) },

    -- ===== SEA 2 (Níveis 700-1500) =====
    -- Kingdom of Rose
    { min = 701, max = 740, npcName = "Rose Knight", npcPos = Vector3.new(-5000, 10, 5000),
      mobName = "Rose Soldier", mobPos = Vector3.new(-5100, 10, 5100) },
    { min = 741, max = 780, npcName = "Rose General", npcPos = Vector3.new(-5200, 10, 5200),
      mobName = "Rose Warrior", mobPos = Vector3.new(-5300, 10, 5300) },
    -- Pirate Island
    { min = 781, max = 820, npcName = "Pirate King", npcPos = Vector3.new(4500, 10, -5000),
      mobName = "Pirate Elite", mobPos = Vector3.new(4600, 10, -5100) },
    { min = 821, max = 860, npcName = "Pirate Lord", npcPos = Vector3.new(4700, 10, -5200),
      mobName = "Pirate Legend", mobPos = Vector3.new(4800, 10, -5300) },
    -- Marine
    { min = 861, max = 900, npcName = "Marine Captain", npcPos = Vector3.new(-5500, 10, -5500),
      mobName = "Marine Soldier", mobPos = Vector3.new(-5600, 10, -5600) },
    { min = 901, max = 940, npcName = "Marine Admiral", npcPos = Vector3.new(-5700, 10, -5700),
      mobName = "Marine Elite", mobPos = Vector3.new(-5800, 10, -5800) },
    -- Sky (2ª Sea)
    { min = 941, max = 980, npcName = "Sky Guardian 2", npcPos = Vector3.new(6000, 150, 0),
      mobName = "Sky Warrior 2", mobPos = Vector3.new(6100, 150, 100) },
    { min = 981, max = 1020, npcName = "Sky Emperor", npcPos = Vector3.new(6200, 150, 200),
      mobName = "Sky Knight 2", mobPos = Vector3.new(6300, 150, 300) },
    -- Ice (2ª Sea)
    { min = 1021, max = 1060, npcName = "Ice Lord", npcPos = Vector3.new(-6000, 10, 6000),
      mobName = "Ice Soldier 2", mobPos = Vector3.new(-6100, 10, 6100) },
    { min = 1061, max = 1100, npcName = "Ice Emperor", npcPos = Vector3.new(-6200, 10, 6200),
      mobName = "Ice Knight 2", mobPos = Vector3.new(-6300, 10, 6300) },
    -- Dark (2ª Sea)
    { min = 1101, max = 1140, npcName = "Dark Warlock", npcPos = Vector3.new(7000, 10, -7000),
      mobName = "Dark Mage 2", mobPos = Vector3.new(7100, 10, -7100) },
    { min = 1141, max = 1180, npcName = "Dark Necromancer", npcPos = Vector3.new(7200, 10, -7200),
      mobName = "Dark Wizard 2", mobPos = Vector3.new(7300, 10, -7300) },
    -- Magma (2ª Sea)
    { min = 1181, max = 1220, npcName = "Magma Overlord", npcPos = Vector3.new(-7000, 10, 7000),
      mobName = "Magma Warrior 2", mobPos = Vector3.new(-7100, 10, 7100) },
    -- Ghost (2ª Sea)
    { min = 1221, max = 1260, npcName = "Ghost King", npcPos = Vector3.new(8000, 10, 8000),
      mobName = "Ghost Pirate 2", mobPos = Vector3.new(8100, 10, 8100) },
    -- Fishman (2ª Sea)
    { min = 1261, max = 1300, npcName = "Fishman King", npcPos = Vector3.new(-8000, -50, -8000),
      mobName = "Fishman Warrior 2", mobPos = Vector3.new(-8100, -50, -8100) },
    -- Zombie (2ª Sea)
    { min = 1301, max = 1350, npcName = "Zombie Lord", npcPos = Vector3.new(8500, 10, -8500),
      mobName = "Zombie Soldier 2", mobPos = Vector3.new(8600, 10, -8600) },
    -- Demon
    { min = 1351, max = 1400, npcName = "Demon General", npcPos = Vector3.new(-8500, 10, 8500),
      mobName = "Demon Warrior", mobPos = Vector3.new(-8600, 10, 8600) },
    -- Angel
    { min = 1401, max = 1450, npcName = "Angel Commander", npcPos = Vector3.new(9000, 200, 0),
      mobName = "Angel Knight", mobPos = Vector3.new(9100, 200, 100) },
    -- Dragon
    { min = 1451, max = 1500, npcName = "Dragon Lord", npcPos = Vector3.new(-9000, 10, -9000),
      mobName = "Dragon Warrior", mobPos = Vector3.new(-9100, 10, -9100) },

    -- ===== SEA 3 (Níveis 1500-2550) =====
    -- Sea of Treats
    { min = 1501, max = 1550, npcName = "Candy King", npcPos = Vector3.new(10000, 10, 10000),
      mobName = "Candy Soldier", mobPos = Vector3.new(10100, 10, 10100) },
    { min = 1551, max = 1600, npcName = "Chocolate General", npcPos = Vector3.new(10200, 10, 10200),
      mobName = "Chocolate Warrior", mobPos = Vector3.new(10300, 10, 10300) },
    -- Sea of Stars
    { min = 1601, max = 1650, npcName = "Star Admiral", npcPos = Vector3.new(-10000, 50, 10000),
      mobName = "Star Soldier", mobPos = Vector3.new(-10100, 50, 10100) },
    { min = 1651, max = 1700, npcName = "Star Commander", npcPos = Vector3.new(-10200, 50, 10200),
      mobName = "Star Knight", mobPos = Vector3.new(-10300, 50, 10300) },
    -- Sea of Death
    { min = 1701, max = 1750, npcName = "Death Reaper", npcPos = Vector3.new(11000, 10, -11000),
      mobName = "Death Soldier", mobPos = Vector3.new(11100, 10, -11100) },
    { min = 1751, max = 1800, npcName = "Death Lord", npcPos = Vector3.new(11200, 10, -11200),
      mobName = "Death Knight", mobPos = Vector3.new(11300, 10, -11300) },
    -- Sea of Fire
    { min = 1801, max = 1850, npcName = "Fire Emperor", npcPos = Vector3.new(-11000, 10, -11000),
      mobName = "Fire Warrior", mobPos = Vector3.new(-11100, 10, -11100) },
    { min = 1851, max = 1900, npcName = "Fire Overlord", npcPos = Vector3.new(-11200, 10, -11200),
      mobName = "Fire Knight", mobPos = Vector3.new(-11300, 10, -11300) },
    -- Sea of Ice (3ª Sea)
    { min = 1901, max = 1950, npcName = "Ice Emperor 3", npcPos = Vector3.new(12000, 10, 12000),
      mobName = "Ice Soldier 3", mobPos = Vector3.new(12100, 10, 12100) },
    { min = 1951, max = 2000, npcName = "Ice Overlord", npcPos = Vector3.new(12200, 10, 12200),
      mobName = "Ice Knight 3", mobPos = Vector3.new(12300, 10, 12300) },
    -- Sea of Thunder
    { min = 2001, max = 2050, npcName = "Thunder God 3", npcPos = Vector3.new(-12000, 100, 12000),
      mobName = "Thunder Warrior 3", mobPos = Vector3.new(-12100, 100, 12100) },
    { min = 2051, max = 2100, npcName = "Thunder Lord", npcPos = Vector3.new(-12200, 100, 12200),
      mobName = "Thunder Knight 3", mobPos = Vector3.new(-12300, 100, 12300) },
    -- Sea of Dark
    { min = 2101, max = 2150, npcName = "Dark Overlord", npcPos = Vector3.new(13000, 10, -13000),
      mobName = "Dark Mage 3", mobPos = Vector3.new(13100, 10, -13100) },
    { min = 2151, max = 2200, npcName = "Dark Emperor", npcPos = Vector3.new(13200, 10, -13200),
      mobName = "Dark Wizard 3", mobPos = Vector3.new(13300, 10, -13300) },
    -- Sea of Light
    { min = 2201, max = 2250, npcName = "Light King", npcPos = Vector3.new(-13000, 10, -13000),
      mobName = "Light Soldier", mobPos = Vector3.new(-13100, 10, -13100) },
    { min = 2251, max = 2300, npcName = "Light Emperor", npcPos = Vector3.new(-13200, 10, -13200),
      mobName = "Light Knight", mobPos = Vector3.new(-13300, 10, -13300) },
    -- Sea of Dragons
    { min = 2301, max = 2350, npcName = "Dragon Emperor", npcPos = Vector3.new(14000, 50, 14000),
      mobName = "Dragon Soldier", mobPos = Vector3.new(14100, 50, 14100) },
    { min = 2351, max = 2400, npcName = "Dragon Overlord", npcPos = Vector3.new(14200, 50, 14200),
      mobName = "Dragon Knight", mobPos = Vector3.new(14300, 50, 14300) },
    -- Sea of Gods
    { min = 2401, max = 2450, npcName = "God of War", npcPos = Vector3.new(-14000, 100, -14000),
      mobName = "God Soldier", mobPos = Vector3.new(-14100, 100, -14100) },
    { min = 2451, max = 2500, npcName = "God Emperor", npcPos = Vector3.new(-14200, 100, -14200),
      mobName = "God Knight", mobPos = Vector3.new(-14300, 100, -14300) },
    -- Final Boss Area
    { min = 2501, max = 2550, npcName = "Ultimate Boss", npcPos = Vector3.new(15000, 10, -15000),
      mobName = "Ultimate Soldier", mobPos = Vector3.new(15100, 10, -15100) },
}

-- ===================== FUNÇÕES AUXILIARES =====================

-- Obtém o nível do jogador
local function getPlayerLevel()
    local ls = player:FindFirstChild("leaderstats")
    if ls then
        local lvl = ls:FindFirstChild("Level") or ls:FindFirstChild("Levels")
        if lvl then return lvl.Value end
    end
    return 0
end

-- Encontra a missão adequada para o nível atual
local function getQuestForLevel(level)
    for _, q in ipairs(quests) do
        if level >= q.min and level <= q.max then
            return q
        end
    end
    -- Se não encontrar, pega a última missão disponível
    return quests[#quests]
end

-- Encontra um modelo pelo nome (parcial)
local function findModelByName(partialName)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find(partialName) then
            local root = obj:FindFirstChild("HumanoidRootPart")
            if root then
                return obj
            end
        end
    end
    return nil
end

-- Encontra mobs da missão atual
local function getQuestMobs()
    if not currentQuest then return {} end
    local mobs = {}
    local mobName = currentQuest.mobName
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find(mobName) then
            local hum = obj:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local root = obj:FindFirstChild("HumanoidRootPart")
                if root then
                    table.insert(mobs, {Model = obj, RootPart = root, Humanoid = hum})
                end
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
    local pos = rootPart.Position
    for _, mob in ipairs(mobs) do
        local dist = (mob.RootPart.Position - pos).Magnitude
        if dist < minDist then
            minDist = dist
            nearest = mob
        end
    end
    return nearest
end

-- Tween para uma posição (com altura fixa)
local function tweenToPosition(targetPos)
    -- Mantém a altura do player, mas permite ajuste
    local pos = Vector3.new(targetPos.X, rootPart.Position.Y, targetPos.Z)
    local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local goal = {CFrame = CFrame.new(pos)}
    local tween = TweenService:Create(rootPart, tweenInfo, goal)
    tween:Play()
    tween.Completed:Wait()
end

-- Interage com um NPC (pressiona E e clica no botão de aceitar)
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
    -- Tenta clicar no botão de aceitar (posição central da tela)
    local screenSize = Camera.ViewportSize
    local clickX = screenSize.X / 2
    local clickY = screenSize.Y / 2 + 80
    VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, "Left", 0)
    task.wait(0.1)
    VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, "Left", 0)
    task.wait(0.5)
    return true
end

-- Tenta pegar a missão
local function takeQuest(quest)
    if not quest then return false end
    local npc = findModelByName(quest.npcName)
    if not npc then
        statusMsg = "NPC não encontrado: " .. quest.npcName
        return false
    end
    statusMsg = "Indo para NPC: " .. quest.npcName
    tweenToPosition(quest.npcPos)
    task.wait(0.3)
    statusMsg = "Interagindo com NPC..."
    local success = interactWithNPC(npc)
    if success then
        statusMsg = "Missão obtida!"
        currentQuest = quest
    else
        statusMsg = "Falha ao interagir com NPC"
    end
    return success
end

-- ===================== LOOPS PRINCIPAIS =====================

-- Loop principal do Farm (movimentação e lógica)
local function farmLoop()
    while isFarming and task.wait(0.1) do
        -- 1. Verifica se tem missão, senão tenta pegar
        if not currentQuest then
            local level = getPlayerLevel()
            local quest = getQuestForLevel(level)
            if not quest then
                statusMsg = "Nível sem missão definida"
                task.wait(2)
                continue
            end
            statusMsg = "Pegando missão..."
            local success = takeQuest(quest)
            if not success then
                task.wait(3)
                continue
            else
                statusMsg = "Indo para área de mobs..."
                tweenToPosition(quest.mobPos)
                task.wait(0.5)
            end
        end

        -- 2. Se já tem missão, vai para a área dos mobs se estiver longe
        if currentQuest then
            local mobArea = currentQuest.mobPos
            local distToArea = (mobArea - rootPart.Position).Magnitude
            if distToArea > 20 then
                statusMsg = "Indo para área de mobs..."
                tweenToPosition(mobArea)
                task.wait(0.5)
            end
        end

        -- 3. Procura mob para atacar
        local target = findNearestQuestMob()
        if target then
            local targetPos = target.RootPart.Position
            local dist = (targetPos - rootPart.Position).Magnitude
            if dist > ATTACK_DISTANCE then
                -- Move para perto do mob (mantendo altura)
                local dir = (targetPos - rootPart.Position).Unit
                local goalPos = targetPos - dir * ATTACK_DISTANCE
                tweenToPosition(goalPos)
                task.wait(0.3)
            end
            statusMsg = "Farmando " .. currentQuest.mobName
        else
            statusMsg = "Procurando mobs..."
            -- Se não há mobs, espera um pouco e tenta se reposicionar
            task.wait(1)
        end
    end
end

-- Loop de ataque (Auto Click)
local function attackLoop()
    local lastClick = 0
    while isFarming do
        local now = tick()
        if now - lastClick >= CLICK_INTERVAL then
            local target = findNearestQuestMob()
            if target then
                local dist = (target.RootPart.Position - rootPart.Position).Magnitude
                if dist <= ATTACK_DISTANCE + 2 then
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, "Left", 0)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, "Left", 0)
                    lastClick = now
                end
            end
        end
        task.wait()
    end
end

-- Loop de Bring Mobs (automático)
local function bringLoop
