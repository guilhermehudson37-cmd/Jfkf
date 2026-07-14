--[[
    g Hub - Auto Farm for Blox Fruits
    Version: 1.0
    Requirements: Local Script (run inside a LocalScript within a ScreenGui)
    Note: This script is a functional skeleton. For actual use, adjust the 
    NPC, quest, and mob interaction functions according to the current game version.
]]

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Constants
local VALID_KEY = "gHub2024" -- Fixed key for validation
local ATTACK_KEY = Enum.KeyCode.One -- Attack key (adjust according to the game)
local COMBAT_DISTANCE = 15 -- Ideal distance to attack mobs (in studs)
local ATTACK_INTERVAL = 0.5 -- Interval between attack clicks (seconds)

-- NPC table by level (example - adjust to the actual game)
local NPC_TABLE = {
    {level = 1, npc = "NPC_1", mobs = {"Mob_1"}, pos = Vector3.new(0, 0, 0)},
    {level = 10, npc = "NPC_2", mobs = {"Mob_2"}, pos = Vector3.new(100, 0, 100)},
    {level = 20, npc = "NPC_3", mobs = {"Mob_3"}, pos = Vector3.new(200, 0, 200)},
    -- Add more levels as needed
}

-- State variables
local autoFarmActive = false
local currentQuest = nil
local currentNPC = nil
local targetMobs = {}
local loopTask = nil

-- ======================== KEY SYSTEM ========================

-- Create login screen
local function createLoginScreen()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "gHubLogin"
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 250)
    frame.Position = UDim2.new(0.5, -200, 0.5, -125)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.2, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "g Hub"
    title.TextColor3 = Color3.fromRGB(255, 200, 100)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    local keyLabel = Instance.new("TextLabel")
    keyLabel.Size = UDim2.new(1, 0, 0.2, 0)
    keyLabel.Position = UDim2.new(0, 0, 0.3, 0)
    keyLabel.BackgroundTransparency = 1
    keyLabel.Text = "Enter Key:"
    keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyLabel.TextScaled = true
    keyLabel.Font = Enum.Font.Gotham
    keyLabel.Parent = frame

    local keyBox = Instance.new("TextBox")
    keyBox.Size = UDim2.new(0.8, 0, 0.2, 0)
    keyBox.Position = UDim2.new(0.1, 0, 0.5, 0)
    keyBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    keyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyBox.Text = ""
    keyBox.PlaceholderText = "Type the key..."
    keyBox.Font = Enum.Font.Gotham
    keyBox.TextScaled = true
    keyBox.ClearTextOnFocus = false
    keyBox.Parent = frame

    local validateBtn = Instance.new("TextButton")
    validateBtn.Size = UDim2.new(0.4, 0, 0.2, 0)
    validateBtn.Position = UDim2.new(0.3, 0, 0.75, 0)
    validateBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
    validateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    validateBtn.Text = "Validate"
    validateBtn.Font = Enum.Font.GothamBold
    validateBtn.TextScaled = true
    validateBtn.Parent = frame

    local message = Instance.new("TextLabel")
    message.Size = UDim2.new(1, 0, 0.15, 0)
    message.Position = UDim2.new(0, 0, 0.85, 0)
    message.BackgroundTransparency = 1
    message.Text = ""
    message.TextColor3 = Color3.fromRGB(255, 0, 0)
    message.TextScaled = true
    message.Font = Enum.Font.Gotham
    message.Parent = frame

    return screenGui, keyBox, validateBtn, message
end

-- Validate key
local function validateKey(key)
    return key == VALID_KEY
end

-- ======================== MAIN INTERFACE ========================

local function createMainInterface()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "gHubMain"
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 350, 0, 300)
    frame.Position = UDim2.new(0.02, 0, 0.2, 0)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.15, 0)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "g Hub - Auto Farm"
    title.TextColor3 = Color3.fromRGB(255, 200, 100)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    -- Single tab: Auto Farm
    local tab = Instance.new("Frame")
    tab.Size = UDim2.new(1, 0, 0.85, 0)
    tab.Position = UDim2.new(0, 0, 0.15, 0)
    tab.BackgroundTransparency = 1
    tab.Parent = frame

    -- Toggle button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0.6, 0, 0.2, 0)
    toggleBtn.Position = UDim2.new(0.2, 0, 0.05, 0)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Text = "Start Auto Farm"
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextScaled = true
    toggleBtn.Parent = tab

    -- Status display
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(1, 0, 0.6, 0)
    statusFrame.Position = UDim2.new(0, 0, 0.3, 0)
    statusFrame.BackgroundTransparency = 1
    statusFrame.Parent = tab

    local labels = {}
    local infoTexts = {
        "Level: ",
        "NPC: ",
        "Quest: ",
        "Status: "
    }
    for i, info in ipairs(infoTexts) do
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0.25, 0)
        lbl.Position = UDim2.new(0, 0, (i-1)*0.25, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = info
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextScaled = true
        lbl.Font = Enum.Font.Gotham
        lbl.Parent = statusFrame
        labels[i] = lbl
    end

    -- Function to update status
    local function updateStatus(level, npcName, quest, status)
        labels[1].Text = "Level: " .. tostring(level)
        labels[2].Text = "NPC: " .. tostring(npcName or "None")
        labels[3].Text = "Quest: " .. tostring(quest or "None")
        labels[4].Text = "Status: " .. tostring(status or "Idle")
    end

    return screenGui, toggleBtn, updateStatus
end

-- ======================== HELPER FUNCTIONS ========================

-- Get player level (example - adapt)
local function getPlayerLevel()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local level = leaderstats:FindFirstChild("Level")
        if level then
            return level.Value
        end
    end
    return 1
end

-- Find appropriate NPC for current level
local function getNPCForLevel(level)
    local selected = nil
    for _, entry in ipairs(NPC_TABLE) do
        if level >= entry.level then
            selected = entry
        end
    end
    return selected
end

-- Move character to target position using Tween
local function moveToPosition(targetPos)
    if not HumanoidRootPart then return end
    local tweenInfo = TweenInfo.new(
        2, -- duration
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(HumanoidRootPart, tweenInfo, {CFrame = CFrame.new(targetPos)})
    tween:Play()
    tween.Completed:Wait()
end

-- Interact with NPC (simulate click or prompt)
local function interactWithNPC(npcName)
    local npc = workspace:FindFirstChild(npcName)
    if npc then
        local prompt = npc:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            prompt:InputHoldBegin(LocalPlayer)
            wait(0.5)
            prompt:InputHoldEnd(LocalPlayer)
            return true
        else
            warn("NPC " .. npcName .. " does not have a ProximityPrompt.")
            return false
        end
    else
        warn("NPC " .. npcName .. " not found in Workspace.")
        return false
    end
end

-- Accept the quest (after interaction, may need to click buttons)
local function acceptQuest()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for _, child in ipairs(playerGui:GetDescendants()) do
            if child:IsA("TextButton") and child.Name:find("Accept") then
                child:Click()
                return true
            end
        end
    end
    return false
end

-- Turn in the quest
local function turnInQuest()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for _, child in ipairs(playerGui:GetDescendants()) do
            if child:IsA("TextButton") and (child.Name:find("Complete") or child.Name:find("Finish")) then
                child:Click()
                return true
            end
        end
    end
    return false
end

-- Locate quest mobs (returns list of parts with given names)
local function findMobs(mobNames)
    local mobs = {}
    for _, name in ipairs(mobNames) do
        local mob = workspace:FindFirstChild(name)
        if mob then
            table.insert(mobs, mob)
        end
    end
    return mobs
end

-- Attack mobs (auto-click)
local function attackMobs(mobs, distance)
    local attacking = true
    local attackTask = nil
    local function attackLoop()
        while attacking do
            -- Check for alive mobs
            local targets = {}
            for _, mob in ipairs(mobs) do
                if mob and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                    table.insert(targets, mob)
                end
            end
            if #targets == 0 then
                attacking = false
                break
            end
            -- Move to the closest mob
            local closest = nil
            local minDist = math.huge
            for _, mob in ipairs(targets) do
                local dist = (HumanoidRootPart.Position - mob.PrimaryPart.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = mob
                end
            end
            if closest then
                if minDist > distance then
                    moveToPosition(closest.PrimaryPart.Position)
                end
                -- Simulate attack key press
                UserInputService:SetKeyDown(ATTACK_KEY)
                wait(0.1)
                UserInputService:SetKeyUp(ATTACK_KEY)
            end
            wait(ATTACK_INTERVAL)
        end
    end
    attackTask = coroutine.create(attackLoop)
    coroutine.resume(attackTask)
    return function() attacking = false end -- stop function
end

-- ======================== AUTO FARM LOOP ========================

local function startAutoFarm()
    if loopTask then return end
    autoFarmActive = true

    local function loop()
        while autoFarmActive do
            local level = getPlayerLevel()
            local npcInfo = getNPCForLevel(level)
            if not npcInfo then
                wait(5)
                continue
            end

            -- 1. Go to NPC
            moveToPosition(npcInfo.pos)
            wait(1)

            -- 2. Interact and accept quest
            interactWithNPC(npcInfo.npc)
            wait(1)
            if acceptQuest() then
                currentNPC = npcInfo.npc
                currentQuest = "Hunt " .. table.concat(npcInfo.mobs, ", ")
            else
                wait(2)
                continue
            end

            -- 3. Locate mobs
            local mobs = findMobs(npcInfo.mobs)
            if #mobs == 0 then
                wait(2)
                continue
            end

            -- 4. Attack mobs until done
            local stopAttack = attackMobs(mobs, COMBAT_DISTANCE)

            -- 5. Wait for quest completion (placeholder - check via GUI or counters)
            wait(30) -- Replace with actual completion detection

            stopAttack() -- Stop attacking

            -- 6. Return to NPC and turn in
            moveToPosition(npcInfo.pos)
            wait(1)
            interactWithNPC(npcInfo.npc)
            wait(1)
            if turnInQuest() then
                currentQuest = "Turned in"
            else
                wait(2)
            end

            wait(1)
        end
    end

    loopTask = coroutine.create(loop)
    coroutine.resume(loopTask)
end

local function stopAutoFarm()
    autoFarmActive = false
    if loopTask then
        loopTask = nil
    end
end

-- ======================== INITIALIZATION ========================

local function main()
    -- Login Screen
    local loginGui, keyBox, validateBtn, msgLabel = createLoginScreen()

    -- Main Screen (initially hidden)
    local mainGui, toggleBtn, updateStatus = createMainInterface()
    mainGui.Enabled = false

    -- Validation event
    validateBtn.MouseButton1Click:Connect(function()
        local key = keyBox.Text
        if validateKey(key) then
            loginGui.Enabled = false
            mainGui.Enabled = true
            msgLabel.Text = ""
            updateStatus(getPlayerLevel(), "None", "None", "Disabled")
        else
            msgLabel.Text = "Invalid key. Try again."
            msgLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
    end)

    -- Toggle button event
    toggleBtn.MouseButton1Click:Connect(function()
        if autoFarmActive then
            stopAutoFarm()
            toggleBtn.Text = "Start Auto Farm"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
            updateStatus(getPlayerLevel(), currentNPC or "None", currentQuest or "None", "Disabled")
        else
            startAutoFarm()
            toggleBtn.Text = "Stop Auto Farm"
            toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
            updateStatus(getPlayerLevel(), currentNPC or "Searching...", currentQuest or "Searching...", "Active")
        end
    end)

    -- Periodic status update while farm is active
    RunService.Heartbeat:Connect(function()
        if mainGui.Enabled and autoFarmActive then
            local level = getPlayerLevel()
            updateStatus(level, currentNPC or "Searching...", currentQuest or "Searching...", "Active")
        end
    end)
end

-- Run
main()
