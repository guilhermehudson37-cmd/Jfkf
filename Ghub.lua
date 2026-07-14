-- g Hub - Auto Farm
-- Script criado para Blox Fruits

local gHub = {}
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variáveis principais
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
local Character = LP.Character or LP.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Configurações
local Config = {
    Distance = 15, -- Distância de combate
    TweenSpeed = 300, -- Velocidade do Tween
    AutoClickDelay = 0.1 -- Delay entre clicks
}

-- Sistema de Key
local KeySystem = {}
KeySystem.ValidKeys = {
    ["GHUB-FREE-2024"] = true,
    ["BLOX-FRUITS-AUTO"] = true,
    ["FARM-KEY-001"] = true
}

function KeySystem:ValidateKey(key)
    return self.ValidKeys[key] or false
end

function KeySystem:RequestKey()
    -- Em um script real, você implementaria uma interface para o usuário digitar a key
    -- Aqui está apenas um exemplo de validação
    local key = "GHUB-FREE-2024" -- Simulação de key inserida
    return self:ValidateKey(key)
end

-- Sistema de NPC por nível
local QuestNPCs = {
    -- Nível 1-10: Bandit
    {MinLevel = 1, MaxLevel = 10, NPC = "Bandit", Quest = "Bandit", Mobs = {"Bandit"}},
    -- Nível 10-25: Monkey
    {MinLevel = 10, MaxLevel = 25, NPC = "Monkey", Quest = "Monkey", Mobs = {"Monkey"}},
    -- Nível 25-40: Pirate
    {MinLevel = 25, MaxLevel = 40, NPC = "Pirate", Quest = "Pirate", Mobs = {"Pirate"}},
    -- Nível 40-60: Marine
    {MinLevel = 40, MaxLevel = 60, NPC = "Marine", Quest = "Marine", Mobs = {"Marine"}},
    -- Nível 60-90: Desert Bandit
    {MinLevel = 60, MaxLevel = 90, NPC = "Desert Bandit", Quest = "Desert Bandit", Mobs = {"Desert Bandit"}},
    -- Nível 90-120: Snow Bandit
    {MinLevel = 90, MaxLevel = 120, NPC = "Snow Bandit", Quest = "Snow Bandit", Mobs = {"Snow Bandit"}},
    -- Nível 120-150: Chief Warden
    {MinLevel = 120, MaxLevel = 150, NPC = "Chief Warden", Quest = "Chief Warden", Mobs = {"Chief Warden"}},
    -- Nível 150-190: Swan Pirate
    {MinLevel = 150, MaxLevel = 190, NPC = "Swan Pirate", Quest = "Swan Pirate", Mobs = {"Swan Pirate"}},
    -- Nível 190-240: Factory Staff
    {MinLevel = 190, MaxLevel = 240, NPC = "Factory Staff", Quest = "Factory Staff", Mobs = {"Factory Staff"}},
    -- Nível 240-300: Magma Admiral
    {MinLevel = 240, MaxLevel = 300, NPC = "Magma Admiral", Quest = "Magma Admiral", Mobs = {"Magma Admiral"}},
    -- Nível 300-350: Fishman Lord
    {MinLevel = 300, MaxLevel = 350, NPC = "Fishman Lord", Quest = "Fishman Lord", Mobs = {"Fishman Lord"}},
    -- Nível 350-400: Wysper
    {MinLevel = 350, MaxLevel = 400, NPC = "Wysper", Quest = "Wysper", Mobs = {"Wysper"}},
    -- Nível 400-450: Thunder God
    {MinLevel = 400, MaxLevel = 450, NPC = "Thunder God", Quest = "Thunder God", Mobs = {"Thunder God"}},
    -- Nível 450-500: Cyborg
    {MinLevel = 450, MaxLevel = 500, NPC = "Cyborg", Quest = "Cyborg", Mobs = {"Cyborg"}},
    -- Nível 500-550: Ice Admiral
    {MinLevel = 500, MaxLevel = 550, NPC = "Ice Admiral", Quest = "Ice Admiral", Mobs = {"Ice Admiral"}},
    -- Nível 550-600: Greybeard
    {MinLevel = 550, MaxLevel = 600, NPC = "Greybeard", Quest = "Greybeard", Mobs = {"Greybeard"}},
    -- Nível 600-700: Diamond
    {MinLevel = 600, MaxLevel = 700, NPC = "Diamond", Quest = "Diamond", Mobs = {"Diamond"}},
    -- Nível 700-800: Jeremy
    {MinLevel = 700, MaxLevel = 800, NPC = "Jeremy", Quest = "Jeremy", Mobs = {"Jeremy"}},
    -- Nível 800-900: Fajita
    {MinLevel = 800, MaxLevel = 900, NPC = "Fajita", Quest = "Fajita", Mobs = {"Fajita"}},
    -- Nível 900-1000: Don Swan
    {MinLevel = 900, MaxLevel = 1000, NPC = "Don Swan", Quest = "Don Swan", Mobs = {"Don Swan"}},
    -- Nível 1000-1100: Smoke Admiral
    {MinLevel = 1000, MaxLevel = 1100, NPC = "Smoke Admiral", Quest = "Smoke Admiral", Mobs = {"Smoke Admiral"}},
    -- Nível 1100-1200: Awakened Ice Admiral
    {MinLevel = 1100, MaxLevel = 1200, NPC = "Awakened Ice Admiral", Quest = "Awakened Ice Admiral", Mobs = {"Awakened Ice Admiral"}},
    -- Nível 1200-1300: Tide Keeper
    {MinLevel = 1200, MaxLevel = 1300, NPC = "Tide Keeper", Quest = "Tide Keeper", Mobs = {"Tide Keeper"}},
    -- Nível 1300-1400: Darkbeard
    {MinLevel = 1300, MaxLevel = 1400, NPC = "Darkbeard", Quest = "Darkbeard", Mobs = {"Darkbeard"}},
    -- Nível 1400-1500: Cursed Captain
    {MinLevel = 1400, MaxLevel = 1500, NPC = "Cursed Captain", Quest = "Cursed Captain", Mobs = {"Cursed Captain"}},
    -- Nível 1500-1600: Order
    {MinLevel = 1500, MaxLevel = 1600, NPC = "Order", Quest = "Order", Mobs = {"Order"}},
    -- Nível 1600-1700: Stone
    {MinLevel = 1600, MaxLevel = 1700, NPC = "Stone", Quest = "Stone", Mobs = {"Stone"}},
    -- Nível 1700-1800: Hydra Leader
    {MinLevel = 1700, MaxLevel = 1800, NPC = "Hydra Leader", Quest = "Hydra Leader", Mobs = {"Hydra Leader"}},
    -- Nível 1800-1900: Kilo Admiral
    {MinLevel = 1800, MaxLevel = 1900, NPC = "Kilo Admiral", Quest = "Kilo Admiral", Mobs = {"Kilo Admiral"}},
    -- Nível 1900-2000: Captain Elephant
    {MinLevel = 1900, MaxLevel = 2000, NPC = "Captain Elephant", Quest = "Captain Elephant", Mobs = {"Captain Elephant"}},
    -- Nível 2000-2100: Beautiful Pirate
    {MinLevel = 2000, MaxLevel = 2100, NPC = "Beautiful Pirate", Quest = "Beautiful Pirate", Mobs = {"Beautiful Pirate"}},
    -- Nível 2100-2200: Cake Queen
    {MinLevel = 2100, MaxLevel = 2200, NPC = "Cake Queen", Quest = "Cake Queen", Mobs = {"Cake Queen"}},
    -- Nível 2200-2300: Longma
    {MinLevel = 2200, MaxLevel = 2300, NPC = "Longma", Quest = "Longma", Mobs = {"Longma"}},
    -- Nível 2300-2400: Soul Reaper
    {MinLevel = 2300, MaxLevel = 2400, NPC = "Soul Reaper", Quest = "Soul Reaper", Mobs = {"Soul Reaper"}},
}

-- Função para obter o NPC atual baseado no nível
function gHub:GetCurrentNPC()
    local level = LP.Data.Level.Value
    for _, npcData in ipairs(QuestNPCs) do
        if level >= npcData.MinLevel and level <= npcData.MaxLevel then
            return npcData
        end
    end
    return QuestNPCs[#QuestNPCs] -- Retorna o último NPC se nível for muito alto
end

-- Função para encontrar o NPC no mundo
function gHub:FindNPC(npcName)
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name == npcName and v:FindFirstChild("HumanoidRootPart") then
            return v
        end
    end
    return nil
end

-- Função para encontrar mobs da missão
function gHub:FindQuestMobs(mobNames)
    local mobs = {}
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            for _, mobName in ipairs(mobNames) do
                if v.Name == mobName then
                    table.insert(mobs, v)
                end
            end
        end
    end
    return mobs
end

-- Função para mover com Tween
function gHub:TweenToPosition(targetCFrame)
    if not HumanoidRootPart then return end
    
    local tweenInfo = TweenInfo.new(
        (HumanoidRootPart.Position - targetCFrame.Position).Magnitude / Config.TweenSpeed,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )
    
    local tween = TweenService:Create(HumanoidRootPart, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    tween.Completed:Wait()
end

-- Função para aceitar missão
function gHub:AcceptQuest(npcName)
    local npc = self:FindNPC(npcName)
    if not npc then return false end
    
    -- Move para o NPC
    local npcPos = npc.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
    self:TweenToPosition(npcPos)
    task.wait(1)
    
    -- Interage com o NPC
    CommF:InvokeServer("Quest", "Start", npcName)
    task.wait(1)
    
    return true
end

-- Função para completar missão
function gHub:CompleteQuest(npcName)
    local npc = self:FindNPC(npcName)
    if not npc then return false end
    
    -- Move para o NPC
    local npcPos = npc.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
    self:TweenToPosition(npcPos)
    task.wait(1)
    
    -- Completa a missão
    CommF:InvokeServer("Quest", "Complete", npcName)
    task.wait(1)
    
    return true
end

-- Sistema de Auto Click
function gHub:AutoClick()
    local tool = LP.Character:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(Config.AutoClickDelay)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

-- Combate contra mobs
function gHub:FarmMobs(mobNames, questNPC)
    local killed = 0
    local questInfo = CommF:InvokeServer("Quest", "Check", questNPC)
    local requiredKills = questInfo and questInfo.Required or 10
    
    while killed < requiredKills and self.Running do
        -- Verifica se o nível mudou
        local currentNPC = self:GetCurrentNPC()
        if currentNPC.NPC ~= questNPC then
            return false -- Sai para trocar de missão
        end
        
        local mobs = self:FindQuestMobs(mobNames)
        if #mobs > 0 then
            -- Encontra o mob mais próximo
            local closestMob = nil
            local closestDist = math.huge
            
            for _, mob in ipairs(mobs) do
                local dist = (HumanoidRootPart.Position - mob.HumanoidRootPart.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestMob = mob
                end
            end
            
            if closestMob then
                -- Move para perto do mob com distância configurável
                local mobPos = closestMob.HumanoidRootPart.CFrame * CFrame.new(0, 0, Config.Distance)
                self:TweenToPosition(mobPos)
                task.wait(0.5)
                
                -- Auto Click no mob
                local startTime = tick()
                while closestMob and closestMob.Humanoid.Health > 0 and self.Running do
                    self:AutoClick()
                    task.wait(0.1)
                    
                    -- Se o mob morrer, incrementa o contador
                    if not closestMob:FindFirstChild("Humanoid") or closestMob.Humanoid.Health <= 0 then
                        killed = killed + 1
                        break
                    end
                end
            end
        else
            -- Se não encontrar mobs, espera um pouco e tenta novamente
            task.wait(1)
        end
    end
    
    return true
end

-- Loop principal do Auto Farm
function gHub:AutoFarmLoop()
    while self.Running do
        -- Obtém o NPC atual baseado no nível
        local npcData = self:GetCurrentNPC()
        
        -- Aceita a missão
        if not self:AcceptQuest(npcData.NPC) then
            task.wait(1)
            continue
        end
        
        -- Farm de mobs
        local success = self:FarmMobs(npcData.Mobs, npcData.NPC)
        
        -- Se o nível mudou durante o farm, recomeça o loop
        if not success then
            continue
        end
        
        -- Completa a missão
        self:CompleteQuest(npcData.NPC)
        task.wait(1)
    end
end

-- Inicia o Auto Farm
function gHub:Start()
    -- Verifica a key
    if not KeySystem:RequestKey() then
        warn("g Hub: Key inválida! Auto Farm não ativado.")
        return
    end
    
    self.Running = true
    print("g Hub: Auto Farm iniciado!")
    
    task.spawn(function()
        self:AutoFarmLoop()
    end)
end

-- Para o Auto Farm
function gHub:Stop()
    self.Running = false
    print("g Hub: Auto Farm parado!")
end

-- Cria o comando global
_G.gHub = gHub

print("g Hub carregado com sucesso! Use _G.gHub:Start() para iniciar o Auto Farm.")
