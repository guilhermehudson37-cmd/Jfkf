--[[
    Ghub - Blox Fruits Script
    Features:
    - Auto Farm (Tween movement, Melee only)
    - Bring Mobs (gathers enemies near player)
    - Auto Haki
    - Key System (valid key: jpeqck789)
]]

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Variables
local autoFarmEnabled = false
local autoHakiEnabled = false
local bringMobsCooldown = false
local farmLoopConnection = nil
local hakiLoopConnection = nil

-- Helper: Check if a model is an enemy (NPC)
local function isEnemy(model)
    if not model or not model:IsA("Model") then return false end
    if model == character then return false end
    -- Check for humanoid
    local hum = model:FindFirstChild("Humanoid")
    if not hum then return false end
    -- Additional checks: filter out players, friendly NPCs, etc.
    if hum.Health <= 0 then return false end
    -- Check if it's a player
    if Players:GetPlayerFromCharacter(model) then return false end
    -- You can add specific name filters for Blox Fruits enemies
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

-- Helper: Tween to position
local function tweenToPosition(targetPos, callback)
    local tweenInfo = TweenInfo.new(
        1, -- time
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )
    local goal = {CFrame = CFrame.new(targetPos)}
    local tween = TweenService:Create(rootPart, tweenInfo, goal)
    tween:Play()
    tween.Completed:Wait()
    if callback then callback() end
end

-- Helper: Attack using Melee (simulate left click)
local function meleeAttack()
    -- Simulate mouse click
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, "Left", 0)
    wait(0.1)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, "Left", 0)
end

-- Auto Farm logic
local function farmLoop()
    while autoFarmEnabled and task.wait(0.1) do
        local target = findNearestEnemy()
        if target then
            local targetPos = target.RootPart.Position
            -- Move to a position near the enemy (melee range)
            local direction = (targetPos - rootPart.Position).Unit
            local attackPos = targetPos - direction * 4 -- 4 studs away
            tweenToPosition(attackPos, function()
                -- After moving, attack
                meleeAttack()
            end)
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
        if dist <= 100 then -- limit radius
            -- Tween enemy to a position near player
            local targetPos = playerPos + Vector3.new(math.random(-8, 8), 0, math.random(-8, 8))
            local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(enemy.RootPart, tweenInfo, {CFrame = CFrame.new(targetPos)})
            tween:Play()
            gathered = gathered + 1
            task.wait(0.1)
        end
    end
    -- Optional: notify
    -- print("Brought " .. gathered .. " mobs")
    task.wait(1)
    bringMobsCooldown = false
end

-- Auto Haki
local function hakiLoop()
    while autoHakiEnabled and task.wait(0.5) do
        -- Check if Haki is already active (find a part/indicator)
        local hakiActive = false
        -- Example: check for a part named "Haki" in character
        if character:FindFirstChild("Haki") then
            hakiActive = true
        end
        -- If not active, press the Haki key (assume "G")
        if not hakiActive then
            -- Simulate press "G"
            VirtualInputManager:SendKeyEvent(true, "G", false, nil)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, "G", false, nil)
        end
    end
end

-- Toggle functions
local function toggleAutoFarm(state)
    autoFarmEnabled = state
    if autoFarmEnabled then
        if farmLoopConnection then farmLoopConnection:Disconnect() end
        farmLoopConnection = RunService.Heartbeat:Connect(farmLoop)
    else
        if farmLoopConnection then
            farmLoopConnection:Disconnect()
            farmLoopConnection = nil
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

-- GUI Creation
local function createMainGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Ghub"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 250)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -125)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Ghub"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame

    -- Auto Farm Toggle
    local farmToggle = Instance.new("TextButton")
    farmToggle.Size = UDim2.new(0.8, 0, 0, 35)
    farmToggle.Position = UDim2.new(0.1, 0, 0.2, 0)
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
    hakiToggle.Position = UDim2.new(0.1, 0, 0.4, 0)
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
    bringButton.Position = UDim2.new(0.1, 0, 0.6, 0)
    bringButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    bringButton.Text = "Bring Mobs"
    bringButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    bringButton.Font = Enum.Font.Gotham
    bringButton.TextScaled = true
    bringButton.Parent = mainFrame
    bringButton.MouseButton1Click:Connect(function()
        bringMobs()
    end)

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0.3, 0, 0, 30)
    closeBtn.Position = UDim2.new(0.35, 0, 0.8, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    closeBtn.Text = "Close"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.Gotham
    closeBtn.TextScaled = true
    closeBtn.Parent = mainFrame
    closeBtn.MouseButton1Click:Connect(function()
        -- Disable all features and destroy GUI
        toggleAutoFarm(false)
        toggleAutoHaki(false)
        screenGui:Destroy()
    end)
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

-- Start key GUI
createKeyGUI()

-- Cleanup on player respawn
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    -- Re-enable features if they were on
    if autoFarmEnabled then
        toggleAutoFarm(true)
    end
    if autoHakiEnabled then
        toggleAutoHaki(true)
    end
end)
