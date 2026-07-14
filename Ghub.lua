--[[
    GHUB - Blox Fruits Script
    Versão: 1.1
    CORRIGIDO - Interface funcionando
]]

-- Configurações Iniciais
local GHUB = {
    Key = "726gs5hhf#$44",
    Name = "GHUB",
    Version = "1.1",
    Developer = "GHUB Team"
}

-- Serviços
local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    Lighting = game:GetService("Lighting"),
    TweenService = game:GetService("TweenService"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
    VirtualUser = game:GetService("VirtualUser"),
    RunService = game:GetService("RunService"),
    HttpService = game:GetService("HttpService"),
    TeleportService = game:GetService("TeleportService"),
    Stats = game:GetService("Stats"),
    UserInputService = game:GetService("UserInputService")
}

local Player = Services.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local RootPart = Character:FindFirstChild("HumanoidRootPart")
local Remote = Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

-- Variáveis Globais do Script
local Global = {
    SelectedWeapon = "",
    FarmMode = false,
    AutoFarm = false,
    AutoBoss = false,
    AutoLevel = false,
    AutoStats = false,
    BringEnemy = false,
    RandomCFrame = false,
    FarmMastery = false,
    AimMethod = false,
    ABmethod = "",
    MousePos = CFrame.new(),
    HealthM = 0,
    CurrentWorld = nil,
    Bosses = {},
    Materials = {},
    PosMsList = {}
}

-- Configuração Inicial do Jogo
local function SetupGame()
    task.spawn(function()
        repeat task.wait() until game:IsLoaded() and Player
        task.wait(1)
        pcall(function()
            Remote:InvokeServer("SetTeam", "Pirates")
        end)
    end)
end

-- Verificação de Mundo
local function GetWorld()
    local placeId = game.PlaceId
    if placeId == 2753915549 or placeId == 85211729168715 then
        return 1
    elseif placeId == 4442272183 or placeId == 79091703265657 then
        return 2
    elseif placeId == 7449423635 or placeId == 100117331123089 then
        return 3
    else
        return nil
    end
end

-- Configuração de Bosses e Materiais por Mundo
local function SetupWorldData()
    local world = GetWorld()
    Global.CurrentWorld = world
    
    if world == 1 then
        Global.Bosses = {"The Gorilla King","Bobby","The Saw","Yeti","Mob Leader","Vice Admiral","Saber Expert","Warden","Chief Warden","Swan","Magma Admiral","Fishman Lord","Wysper","Thunder God","Cyborg","Ice Admiral","Greybeard"}
        Global.Materials = {"Leather + Scrap Metal", "Angel Wings", "Magma Ore", "Fish Tail"}
    elseif world == 2 then
        Global.Bosses = {"Diamond","Jeremy","Fajita","Don Swan","Smoke Admiral","Awakened Ice Admiral","Tide Keeper","Darkbeard","Cursed Captain","Order"}
        Global.Materials = {"Leather + Scrap Metal", "Radioactive Material", "Ectoplasm", "Mystic Droplet", "Magma Ore", "Vampire Fang"}
    elseif world == 3 then
        Global.Bosses = {"Stone","Hydra Leader","Kilo Admiral","Captain Elephant","Beautiful Pirate","Cake Queen","Longma","Soul Reaper"}
        Global.Materials = {"Scrap Metal", "Demonic Wisp", "Conjured Cocoa", "Dragon Scale", "Gunpowder", "Fish Tail", "Mini Tusk"}
    end
end

-- Funções de Utilidade
local function EquipWeapon(weaponName)
    if not weaponName then return false end
    local backpack = Player.Backpack
    local character = Player.Character
    
    if backpack:FindFirstChild(weaponName) then
        character.Humanoid:EquipTool(backpack:FindFirstChild(weaponName))
        return true
    end
    return false
end

local function WeaponByTip(tip)
    for _, tool in pairs(Player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == tip then
            EquipWeapon(tool.Name)
            return true
        end
    end
    return false
end

local function UseSkill(weaponType, skill)
    if weaponType == "Melee" then
        WeaponByTip("Melee")
    elseif weaponType == "Sword" then
        WeaponByTip("Sword")
    elseif weaponType == "Blox Fruit" then
        WeaponByTip("Blox Fruit")
    elseif weaponType == "Gun" then
        WeaponByTip("Gun")
    end
    
    Services.VirtualInputManager:SendKeyEvent(true, skill, false, game)
    task.wait(0.05)
    Services.VirtualInputManager:SendKeyEvent(false, skill, false, game)
end

local function TeleportTo(position)
    if RootPart then
        RootPart.CFrame = position
    end
end

-- Sistema de Key
local function KeySystem()
    print("Iniciando sistema de key...")
    
    -- Aguardar o PlayerGui carregar
    repeat task.wait() until Player:FindFirstChild("PlayerGui")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GHUB_KeySystem"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = Player.PlayerGui
    
    -- Fundo escuro
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 0.5
    background.Parent = screenGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 450, 0, 250)
    mainFrame.Position = UDim2.new(0.5, -225, 0.5, -125)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mainFrame.BackgroundTransparency = 0
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = mainFrame
    
    -- Borda brilhante
    local border = Instance.new("Frame")
    border.Size = UDim2.new(1, 2, 1, 2)
    border.Position = UDim2.new(0, -1, 0, -1)
    border.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    border.BackgroundTransparency = 0.3
    border.BorderSizePixel = 0
    border.Parent = mainFrame
    
    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(0, 20)
    borderCorner.Parent = border
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 60, 0, 60)
    icon.Position = UDim2.new(0.5, -30, 0, 15)
    icon.BackgroundTransparency = 1
    icon.Text = "🔑"
    icon.TextColor3 = Color3.fromRGB(0, 200, 255)
    icon.TextScaled = true
    icon.Font = Enum.Font.GothamBold
    icon.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 75)
    title.BackgroundTransparency = 1
    title.Text = "GHUB v" .. GHUB.Version
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    local subTitle = Instance.new("TextLabel")
    subTitle.Size = UDim2.new(1, 0, 0, 30)
    subTitle.Position = UDim2.new(0, 0, 0, 115)
    subTitle.BackgroundTransparency = 1
    subTitle.Text = "Digite a chave de acesso"
    subTitle.TextColor3 = Color3.fromRGB(180, 180, 200)
    subTitle.TextScaled = true
    subTitle.Font = Enum.Font.Gotham
    subTitle.Parent = mainFrame
    
    local keyBox = Instance.new("TextBox")
    keyBox.Size = UDim2.new(0.8, 0, 0, 45)
    keyBox.Position = UDim2.new(0.1, 0, 0, 150)
    keyBox.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    keyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyBox.PlaceholderText = "Insira a chave aqui..."
    keyBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 180)
    keyBox.Text = ""
    keyBox.ClearTextOnFocus = false
    keyBox.Font = Enum.Font.Gotham
    keyBox.TextScaled = true
    keyBox.Parent = mainFrame
    
    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 10)
    keyCorner.Parent = keyBox
    
    local confirmBtn = Instance.new("TextButton")
    confirmBtn.Size = UDim2.new(0.4, 0, 0, 45)
    confirmBtn.Position = UDim2.new(0.3, 0, 0, 200)
    confirmBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    confirmBtn.Text = "ACESSAR"
    confirmBtn.Font = Enum.Font.GothamBold
    confirmBtn.TextScaled = true
    confirmBtn.Parent = mainFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 10)
    btnCorner.Parent = confirmBtn
    
    -- Efeito hover
    confirmBtn.MouseEnter:Connect(function()
        confirmBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
    end)
    
    confirmBtn.MouseLeave:Connect(function()
        confirmBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    end)
    
    local errorText = Instance.new("TextLabel")
    errorText.Size = UDim2.new(0.8, 0, 0, 25)
    errorText.Position = UDim2.new(0.1, 0, 0, 180)
    errorText.BackgroundTransparency = 1
    errorText.Text = ""
    errorText.TextColor3 = Color3.fromRGB(255, 50, 50)
    errorText.TextScaled = true
    errorText.Font = Enum.Font.Gotham
    errorText.Visible = false
    errorText.Parent = mainFrame
    
    local function ValidateKey()
        local inputKey = keyBox.Text
        if inputKey == GHUB.Key then
            print("Key correta! Abrindo interface...")
            screenGui:Destroy()
            task.wait(0.2)
            MainUI()
        else
            errorText.Visible = true
            errorText.Text = "❌ Chave incorreta! Tente novamente."
            keyBox.Text = ""
            keyBox.PlaceholderText = "Chave incorreta..."
            keyBox.PlaceholderColor3 = Color3.fromRGB(255, 50, 50)
            
            -- Efeito de shake
            local originalPos = mainFrame.Position
            for i = 1, 3 do
                mainFrame.Position = UDim2.new(0.5, -225 + (i % 2 == 0 and -10 or 10), 0.5, -125)
                task.wait(0.05)
            end
            mainFrame.Position = originalPos
            
            task.wait(1.5)
            errorText.Visible = false
            keyBox.PlaceholderText = "Insira a chave aqui..."
            keyBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 180)
        end
    end
    
    confirmBtn.MouseButton1Click:Connect(ValidateKey)
    keyBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            ValidateKey()
        end
    end)
    
    -- Enter key
    Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
            if keyBox:IsFocused() then
                ValidateKey()
            end
        end
    end)
end

-- Interface Principal
local function MainUI()
    print("Carregando interface principal...")
    
    -- Aguardar o PlayerGui
    repeat task.wait() until Player:FindFirstChild("PlayerGui")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GHUB_Main"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = Player.PlayerGui
    
    -- Fundo escuro
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 0.3
    background.Parent = screenGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 550, 0, 650)
    mainFrame.Position = UDim2.new(0.5, -275, 0.5, -325)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BackgroundTransparency = 0
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 20)
    mainCorner.Parent = mainFrame
    
    -- Borda gradiente
    local gradientBorder = Instance.new("Frame")
    gradientBorder.Size = UDim2.new(1, 2, 1, 2)
    gradientBorder.Position = UDim2.new(0, -1, 0, -1)
    gradientBorder.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    gradientBorder.BackgroundTransparency = 0.2
    gradientBorder.BorderSizePixel = 0
    gradientBorder.Parent = mainFrame
    
    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(0, 20)
    borderCorner.Parent = gradientBorder
    
    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 60)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    titleBar.BackgroundTransparency = 0
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 20)
    titleCorner.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -80, 1, 0)
    titleText.Position = UDim2.new(0, 20, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "⚡ GHUB v" .. GHUB.Version
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextScaled = true
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -50, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextScaled = true
    closeBtn.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 10)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    -- Tabs
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, -20, 0, 55)
    tabContainer.Position = UDim2.new(0, 10, 0, 65)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainFrame
    
    local tabs = {"⚔ Farm", "👑 Boss", "⭐ Mastery", "📊 Stats", "⚙ Settings"}
    local tabButtons = {}
    local currentTab = nil
    
    for i, tabName in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1/#tabs, -5, 1, -5)
        btn.Position = UDim2.new((i-1)/#tabs + 0.01, 0, 0.5, -27.5)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
        btn.TextColor3 = Color3.fromRGB(200, 200, 220)
        btn.Text = tabName
        btn.Font = Enum.Font.GothamBold
        btn.TextScaled = true
        btn.Parent = tabContainer
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn
        
        tabButtons[tabName] = btn
        
        btn.MouseButton1Click:Connect(function()
            if currentTab then
                currentTab.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
                currentTab.TextColor3 = Color3.fromRGB(200, 200, 220)
            end
            btn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            currentTab = btn
            SwitchTab(tabName)
        end)
    end
    
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Size = UDim2.new(1, -20, 1, -140)
    contentFrame.Position = UDim2.new(0, 10, 0, 125)
    contentFrame.BackgroundTransparency = 1
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentFrame.ScrollBarThickness = 4
    contentFrame.Parent = mainFrame
    
    local function CreateToggle(parent, text, defaultValue, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 45)
        frame.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
        frame.BackgroundTransparency = 0.5
        frame.Parent = parent
        
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 10)
        frameCorner.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(220, 220, 240)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.TextScaled = true
        label.Parent = frame
        
        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(0, 55, 0, 30)
        toggle.Position = UDim2.new(0.85, 0, 0.5, -15)
        toggle.BackgroundColor3 = defaultValue and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(100, 100, 130)
        toggle.Text = defaultValue and "ON" or "OFF"
        toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggle.TextScaled = true
        toggle.Font = Enum.Font.GothamBold
        toggle.Parent = frame
        
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 8)
        toggleCorner.Parent = toggle
        
        local toggleState = defaultValue
        
        toggle.MouseButton1Click:Connect(function()
            toggleState = not toggleState
            toggle.BackgroundColor3 = toggleState and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(100, 100, 130)
            toggle.Text = toggleState and "ON" or "OFF"
            callback(toggleState)
        end)
        
        return toggle, function()
            toggleState = defaultValue
            toggle.BackgroundColor3 = defaultValue and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(100, 100, 130)
            toggle.Text = defaultValue and "ON" or "OFF"
        end
    end
    
    local function CreateButton(parent, text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 40)
        btn.BackgroundColor3 = Color3.fromRGB(0, 130, 220)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Text = text
        btn.Font = Enum.Font.GothamBold
        btn.TextScaled = true
        btn.Parent = parent
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 10)
        btnCorner.Parent = btn
        
        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
        end)
        
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(0, 130, 220)
        end)
        
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    -- Criar tabs
    local function CreateTab(tabName)
        local tab = Instance.new("Frame")
        tab.Size = UDim2.new(1, 0, 1, 0)
        tab.BackgroundTransparency = 1
        tab.Visible = false
        tab.Parent = contentFrame
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = tab
        
        return tab
    end
    
    -- Tab Farm
    local farmTab = CreateTab("⚔ Farm")
    
    local farmOptions = {"Auto Farm", "Auto Level", "Farm Mastery", "Bring Enemy", "Random CFrame"}
    local farmValues = {}
    
    for _, option in ipairs(farmOptions) do
        local _, setValue = CreateToggle(farmTab, option, false, function(value)
            Global[option:gsub(" ", "")] = value
            print(option .. ":", value)
        end)
        farmValues[option] = setValue
    end
    
    CreateButton(farmTab, "🎯 Selecionar Alvo", function()
        print("Abrindo seleção de alvo...")
        -- Lógica de seleção de alvo
    end)
    
    -- Tab Boss
    local bossTab = CreateTab("👑 Boss")
    CreateToggle(bossTab, "Auto Boss", false, function(value)
        Global.AutoBoss = value
    end)
    CreateButton(bossTab, "🔍 Procurar Boss", function()
        print("Procurando boss...")
    end)
    
    -- Tab Mastery
    local masteryTab = CreateTab("⭐ Mastery")
    CreateToggle(masteryTab, "Farm Mastery", false, function(value)
        G
