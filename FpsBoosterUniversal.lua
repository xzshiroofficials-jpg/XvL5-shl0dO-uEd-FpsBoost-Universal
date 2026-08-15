locall DISCORD_INVITE = "https://discord.gg/CYAmmsuRa"

local HUDColors = {
    WatermarkAccent = Color3.fromRGB(156, 125, 255), -- #9c7dff
    TargetHUDAccent = Color3.fromRGB(156, 125, 255), -- #9c7dff
    HUDBackground = Color3.fromRGB(94, 88, 115),     -- #5e5873
    HUDOutline = Color3.fromRGB(94, 88, 115),        -- #5e5873
    HUDTextColor = Color3.fromRGB(255, 255, 255),     -- #ffffff
    VisualizerColor = Color3.fromRGB(156, 125, 255), -- #9c7dff
    KeySystemAccent = Color3.fromRGB(156, 125, 255),
    KeySystemBg = Color3.fromRGB(12, 12, 18)
}

local function copyToClipboard(text)
    local setClipboard = setclipboard or writeclipboard or toclipboard or (Clipboard and Clipboard.set)
    if setClipboard then
        pcall(setClipboard, text)
        return true
    end
    return false
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

local table_clear = table.clear
local table_find = table.find
local table_insert = table.insert
local math_min = math.min
local math_clamp = math.clamp
local math_deg = math.deg
local math_rad = math.rad
local os_clock = os.clock
local vector3_new = Vector3.new
local cframe_new = CFrame.new
local cframe_lookAt = CFrame.lookAt

---------------------------------------------------------
-- 5-SECOND LOADING SYSTEM
---------------------------------------------------------
local function showLoadingScreen()
    local CoreGui = game:GetService("CoreGui")
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FLSAKEN_Loader"
    ScreenGui.DisplayOrder = 999999
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.fromOffset(330, 110)
    Frame.Position = UDim2.new(0.5, -165, 0.5, -55)
    Frame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 3)
    Corner.Parent = Frame

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(94, 88, 115)
    Stroke.Thickness = 1
    Stroke.Parent = Frame

    local TitleIcon = Instance.new("ImageLabel")
    TitleIcon.Name = "TitleIcon"
    TitleIcon.Size = UDim2.fromOffset(20, 20)
    TitleIcon.Position = UDim2.new(0, 10, 0, 14)
    TitleIcon.BackgroundTransparency = 1
    TitleIcon.Image = "rbxassetid://71081229545579"
    TitleIcon.Parent = Frame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -40, 0, 25)
    Title.Position = UDim2.new(0, 35, 0, 12)
    Title.BackgroundTransparency = 1
    Title.Text = "FlsSaken||Official"
    Title.TextColor3 = Color3.fromRGB(156, 125, 255)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 18
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Frame

    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(1, -20, 0, 20)
    Status.Position = UDim2.new(0, 10, 0, 38)
    Status.BackgroundTransparency = 1
    Status.Text = "Initializing script..."
    Status.TextColor3 = Color3.fromRGB(200, 200, 200)
    Status.Font = Enum.Font.SourceSans
    Status.TextSize = 13
    Status.TextXAlignment = Enum.TextXAlignment.Left
    Status.Parent = Frame

    local BarBg = Instance.new("Frame")
    BarBg.Size = UDim2.new(1, -20, 0, 8)
    BarBg.Position = UDim2.new(0, 10, 0, 72)
    BarBg.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    BarBg.BorderSizePixel = 0
    BarBg.Parent = Frame

    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(0, 3)
    BarCorner.Parent = BarBg

    local BarFill = Instance.new("Frame")
    BarFill.Size = UDim2.new(0, 0, 1, 0)
    BarFill.BackgroundColor3 = Color3.fromRGB(156, 125, 255)
    BarFill.BorderSizePixel = 0
    BarFill.Parent = BarBg

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(0, 3)
    FillCorner.Parent = BarFill

    local startTime = os_clock()
    local duration = 5.0

    while os_clock() - startTime < duration do
        local elapsed = os_clock() - startTime
        local progress = math_clamp(elapsed / duration, 0, 1)
        BarFill.Size = UDim2.new(progress, 0, 1, 0)
        
        if progress < 0.3 then
            Status.Text = "Loading framework & assets..."
        elseif progress < 0.7 then
            Status.Text = "Caching entities & setting up hooks..."
        else
            Status.Text = "Finalizing configuration..."
        end
        task.wait()
    end

    BarFill.Size = UDim2.new(1, 0, 1, 0)
    Status.Text = "Loaded successfully!"
    task.wait(0.3)
    ScreenGui:Destroy()
end

showLoadingScreen()

---------------------------------------------------------
-- SCRIPT LOGIC
---------------------------------------------------------
local Options, Toggles, Window, Library, ThemeManager, SaveManager
local Tabs
local killerHighlights = {}
local survivorHighlights = {}
local itemHighlights = {}
local generatorHighlights = {}
local trapHighlights = {}
local generatorPercentGuis = {}

local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

local visualKillerHighlightEnabled = false
local visualKillerOutlineTransparency = 0.5
local visualKillerFillTransparency = 0.85
local killerHighlightColor = Color3.fromRGB(255, 0, 0)

local visualSurvivorHighlightEnabled = false
local visualSurvivorOutlineTransparency = 0.5
local visualSurvivorFillTransparency = 0.85
local survivorHighlightColor = Color3.fromRGB(0, 255, 0)

local visualItemsHighlightEnabled = false
local visualItemsOutlineTransparency = 0.5
local visualItemsFillTransparency = 0.85
local itemsHighlightColor = Color3.fromRGB(255, 255, 0)

local visualGeneratorsHighlightEnabled = false
local visualGeneratorsShowPercentageEnabled = false
local visualGeneratorsOutlineTransparency = 0.5
local visualGeneratorsFillTransparency = 0.85
local generatorsHighlightColor = Color3.fromRGB(0, 255, 255)

local visualTrapsHighlightEnabled = false
local visualTrapsOutlineTransparency = 0.5
local visualTrapsFillTransparency = 0.85
local trapsHighlightColor = Color3.fromRGB(255, 100, 0)

local autoM1Enabled = false
local autoM1Range = 5
local autoM1ConeAngle = 90
local autoM1AimDuration = 1.5
local autoM1MaxPrediction = 0.2
local autoM1AimSpeed = 15
local autoM1VisualizerEnabled = true

local leftConeLine = nil
local rightConeLine = nil
local autoM1Circle = nil

local autoM1AimbotActive = false
local autoM1AimbotStart = 0
local autoM1AimbotTarget = nil

local projectileAimbotActive = false
local projectileAimbotTarget = nil
local projectileAimStartTime = 0
local previousCooldownStates = {}
local currentActiveSkill = nil

local allowedSurvivorNames = {
    "guest1337", "guest 1337", "chance", "builderman", "veeronica", 
    "noob", "shedletsky", "twotime", "two time", "dusekkar", 
    "007n7", "oo7n7", "jane doe", "janedoe", "elliot"
}

local skillConfigs = {
    ["Mass Infection"] = {
        enabled = true,
        duration = 1.25,
        speed = 35,
        prediction = 0.2
    },
    ["Entanglement"] = {
        enabled = true,
        duration = 0.65,
        speed = 35,
        prediction = 0.2
    },
    ["Corrupt Energy"] = {
        enabled = true,
        duration = 0.65,
        speed = 35,
        prediction = 0.2
    }
}

local guiCornerRadius = 8
local cornerConnection = nil

local staminaEnabled = false
local MAX_STAMINA = 100
local MIN_STAMINA = -20
local STAMINA_GAIN = 100
local STAMINA_LOSS = 5
local SPRINT_SPEED = 40
local INF_STAMINA = true

local fullBrightEnabled = false
local originalLightingSettings = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ColorShift_Bottom = Lighting.ColorShift_Bottom,
    ColorShift_Top = Lighting.ColorShift_Top,
    ExposureCompensation = Lighting.ExposureCompensation,
    GlobalShadows = Lighting.GlobalShadows,
    Brightness = Lighting.Brightness,
}

local LOBBY_POSITION = vector3_new(0, 5, 0)
local LOBBY_RADIUS = 220
local isUnloaded = false
local autoM1Connection = nil
local heartbeatAlignmentConnection = nil

local killerNameCheckCache = {}
local killerHumanoidCache = {}
local killerHrpCache = {}
local survivorHumanoidCache = {}
local survivorHrpCache = {}

local cachedItems = {}
local cachedGenerators = {}
local cachedTraps = {}
local cacheConnections = {}

local cachedHelpless = false
local lastHelplessCheck = 0
local HELPLESS_CACHE_INTERVAL = 0.5 

local cachedM1CD = false
local lastM1CDCheck = 0

local cachedSprintingModule = nil

local HUDRefs = {}

local function createInGameHUDOverlay()
    local CoreGui = game:GetService("CoreGui")
    local existingHUD = CoreGui:FindFirstChild("FLSHUDOverlay") or (LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("FLSHUDOverlay"))
    if existingHUD then existingHUD:Destroy() end

    local HUDGui = Instance.new("ScreenGui")
    HUDGui.Name = "FLSHUDOverlay"
    HUDGui.ResetOnSpawn = false
    HUDGui.DisplayOrder = 1000000
    pcall(function() HUDGui.Parent = CoreGui end)
    if not HUDGui.Parent then HUDGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local WatermarkFrame = Instance.new("Frame")
    WatermarkFrame.Name = "WatermarkFrame"
    WatermarkFrame.Size = UDim2.new(0, 360, 0, 30)
    WatermarkFrame.Position = UDim2.new(0, 15, 0, 15)
    WatermarkFrame.BackgroundColor3 = HUDColors.HUDBackground
    WatermarkFrame.BorderSizePixel = 0
    WatermarkFrame.Parent = HUDGui
    HUDRefs.WatermarkFrame = WatermarkFrame

    local WMCorner = Instance.new("UICorner")
    WMCorner.CornerRadius = UDim.new(0, 6)
    WMCorner.Parent = WatermarkFrame

    local WMStroke = Instance.new("UIStroke")
    WMStroke.Color = HUDColors.HUDOutline
    WMStroke.Thickness = 1
    WMStroke.Parent = WatermarkFrame
    HUDRefs.WMStroke = WMStroke

    local WMAccent = Instance.new("Frame")
    WMAccent.Name = "WMAccent"
    WMAccent.Size = UDim2.new(0, 3, 1, 0)
    WMAccent.BackgroundColor3 = HUDColors.WatermarkAccent
    WMAccent.BorderSizePixel = 0
    WMAccent.Parent = WatermarkFrame
    HUDRefs.WMAccent = WMAccent

    local WMAccentCorner = Instance.new("UICorner")
    WMAccentCorner.CornerRadius = UDim.new(0, 6)
    WMAccentCorner.Parent = WMAccent

    local WMIcon = Instance.new("ImageLabel")
    WMIcon.Name = "WMIcon"
    WMIcon.Size = UDim2.fromOffset(18, 18)
    WMIcon.Position = UDim2.new(0, 8, 0.5, -9)
    WMIcon.BackgroundTransparency = 1
    WMIcon.Image = "rbxassetid://71081229545579"
    WMIcon.Parent = WatermarkFrame

    local WMLabel = Instance.new("TextLabel")
    WMLabel.Name = "WMLabel"
    WMLabel.Size = UDim2.new(1, -36, 1, 0)
    WMLabel.Position = UDim2.new(0, 32, 0, 0)
    WMLabel.BackgroundTransparency = 1
    WMLabel.Text = "FlsSaken||Official  |  FPS: --  |  Ping: --ms  |  User: " .. LocalPlayer.Name
    WMLabel.TextColor3 = HUDColors.HUDTextColor
    WMLabel.TextSize = 12
    WMLabel.Font = Enum.Font.SourceSansBold
    WMLabel.TextXAlignment = Enum.TextXAlignment.Left
    WMLabel.Parent = WatermarkFrame
    HUDRefs.WMLabel = WMLabel

    local TargetHUD = Instance.new("Frame")
    TargetHUD.Name = "TargetHUD"
    TargetHUD.Size = UDim2.new(0, 240, 0, 52)
    TargetHUD.Position = UDim2.new(0.5, -120, 0.82, 0)
    TargetHUD.BackgroundColor3 = HUDColors.HUDBackground
    TargetHUD.BorderSizePixel = 0
    TargetHUD.Visible = false
    TargetHUD.Parent = HUDGui
    HUDRefs.TargetHUD = TargetHUD

    local TargetCorner = Instance.new("UICorner")
    TargetCorner.CornerRadius = UDim.new(0, 8)
    TargetCorner.Parent = TargetHUD

    local TargetStroke = Instance.new("UIStroke")
    TargetStroke.Name = "TargetStroke"
    TargetStroke.Color = HUDColors.HUDOutline
    TargetStroke.Thickness = 1.5
    TargetStroke.Parent = TargetHUD
    HUDRefs.TargetStroke = TargetStroke

    local TargetTitle = Instance.new("TextLabel")
    TargetTitle.Name = "TargetTitle"
    TargetTitle.Size = UDim2.new(1, -10, 0, 16)
    TargetTitle.Position = UDim2.new(0, 10, 0, 5)
    TargetTitle.BackgroundTransparency = 1
    TargetTitle.Text = "TARGET LOCK: NONE"
    TargetTitle.TextColor3 = HUDColors.TargetHUDAccent
    TargetTitle.TextSize = 11
    TargetTitle.Font = Enum.Font.SourceSansBold
    TargetTitle.TextXAlignment = Enum.TextXAlignment.Left
    TargetTitle.Parent = TargetHUD
    HUDRefs.TargetTitle = TargetTitle

    local TargetInfo = Instance.new("TextLabel")
    TargetInfo.Name = "TargetInfo"
    TargetInfo.Size = UDim2.new(1, -10, 0, 20)
    TargetInfo.Position = UDim2.new(0, 10, 0, 24)
    TargetInfo.BackgroundTransparency = 1
    TargetInfo.Text = "Health: 100%  |  Distance: 0m"
    TargetInfo.TextColor3 = HUDColors.HUDTextColor
    TargetInfo.TextSize = 12
    TargetInfo.Font = Enum.Font.SourceSans
    TargetInfo.TextXAlignment = Enum.TextXAlignment.Left
    TargetInfo.Parent = TargetHUD
    HUDRefs.TargetInfo = TargetInfo

    local lastFpsTime = os_clock()
    local frameCount = 0
    local currentFps = 60

    RunService.RenderStepped:Connect(function()
        if isUnloaded then HUDGui:Destroy() return end
        frameCount = frameCount + 1
        local now = os_clock()
        if now - lastFpsTime >= 0.5 then
            currentFps = math.floor(frameCount / (now - lastFpsTime))
            frameCount = 0
            lastFpsTime = now
            
            local ping = 0
            pcall(function()
                ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            end)
            
            WMLabel.Text = string.format("FlsSaken||Official  |  FPS: %d  |  Ping: %dms  |  User: %s", currentFps, ping, LocalPlayer.Name)
        end

        local activeTarget = autoM1AimbotTarget or projectileAimbotTarget
        if activeTarget and activeTarget.Parent then
            if not TargetHUD.Visible then
                TargetHUD.Visible = true
                TweenService:Create(TargetHUD, TweenInfo.new(0.2), { Size = UDim2.new(0, 240, 0, 52) }):Play()
            end
            local targetName = activeTarget.Name
            local player = Players:GetPlayerFromCharacter(activeTarget)
            if player then targetName = player.DisplayName end

            local hum = activeTarget:FindFirstChildWhichIsA("Humanoid")
            local thrp = activeTarget:FindFirstChild("HumanoidRootPart")
            local char, _, hrp = getCharacterInfo()

            local hpPct = hum and math.floor((hum.Health / math.max(hum.MaxHealth, 1)) * 100) or 0
            local dist = (hrp and thrp) and math.floor((thrp.Position - hrp.Position).Magnitude) or 0

            TargetTitle.Text = "TARGET LOCK: " .. targetName:upper()
            TargetInfo.Text = string.format("Health: %d%%  |  Distance: %dm", hpPct, dist)
        else
            TargetHUD.Visible = false
        end
    end)
end

task.spawn(createInGameHUDOverlay)

local function trackCacheConnections(conn)
    table_insert(cacheConnections, conn)
end

local function disconnectCacheConnections()
    for _, conn in ipairs(cacheConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table_clear(cacheConnections)
end

local function isItemValid(child)
    if child:IsA("Tool") or child:IsA("Model") then
        local lowerName = child.Name:lower()
        if lowerName:find("medkit") or lowerName:find("cola") then
            return true
        end
    end
    return false
end

local function isGeneratorValid(child)
    return child.Name == "Generator" and child:IsA("Model")
end

local function getTrapCategory(nameLower)
    if nameLower:find("tripwire") or nameLower:find("trip wire") then
        return "Tripwires"
    elseif nameLower:find("subspace") or nameLower:find("tripmine") then
        return "Subspace Tripmine"
    elseif nameLower:find("footprint") or nameLower:find("digital") then
        return "Digital Footprints"
    elseif nameLower:find("seeker") then
        return "Seekers"
    elseif nameLower:find("bulb") then
        return "Lightbulbs"
    elseif nameLower:find("stigmatize") then
        return "Stigmatize"
    end
    return nil
end

local function isTrapValid(child)
    local trapCategory = nil
    
    if child:IsA("Model") then
        trapCategory = getTrapCategory(child.Name:lower())
    elseif child:IsA("BasePart") then
        local parent = child.Parent
        if parent and parent:IsA("Model") then
            trapCategory = getTrapCategory(parent.Name:lower())
        end
        if not trapCategory then
            trapCategory = getTrapCategory(child.Name:lower())
        end
    end
    
    if not trapCategory then
        return false
    end
    
    if Options and Options.TrapFilter then
        local enabledTraps = Options.TrapFilter.Value
        if type(enabledTraps) == "table" then
            return enabledTraps[trapCategory] == true
        end
    end
    
    return true
end

local function initialCacheScan()
    table_clear(cachedItems)
    table_clear(cachedGenerators)
    table_clear(cachedTraps)

    local function scan(parent)
        if not parent or parent == Workspace.Terrain then return end
        for _, child in ipairs(parent:GetChildren()) do
            if isUnloaded then return end
            if isItemValid(child) then
                table_insert(cachedItems, child)
            elseif isGeneratorValid(child) then
                table_insert(cachedGenerators, child)
            elseif isTrapValid(child) then
                table_insert(cachedTraps, child)
            end
            
            if child:IsA("Folder") or child.Name == "Map" or child.Name == "Arena" or child.Name == "Ingame" then
                scan(child)
            end
        end
    end

    for _, child in ipairs(Workspace:GetChildren()) do
        if child.Name ~= "Players" and child.Name ~= "Killers" and child ~= LocalPlayer.Character and child ~= Workspace.Terrain then
            if isItemValid(child) then
                table_insert(cachedItems, child)
            elseif isGeneratorValid(child) then
                table_insert(cachedGenerators, child)
            elseif isTrapValid(child) then
                table_insert(cachedTraps, child)
            end
            if child:IsA("Folder") or child.Name == "Map" or child.Name == "Arena" then
                scan(child)
            end
        end
    end
end

local function setupCacheListeners()
    local addedConn = Workspace.DescendantAdded:Connect(function(child)
        if isUnloaded then return end
        task.defer(function()
            if isUnloaded or not child:IsDescendantOf(Workspace) then return end
            if child == Workspace.Terrain then return end
            
            if isItemValid(child) then
                if not table_find(cachedItems, child) then
                    table_insert(cachedItems, child)
                end
            elseif isGeneratorValid(child) then
                if not table_find(cachedGenerators, child) then
                    table_insert(cachedGenerators, child)
                end
            elseif isTrapValid(child) then
                if not table_find(cachedTraps, child) then
                    table_insert(cachedTraps, child)
                end
            end
        end)
    end)
    trackCacheConnections(addedConn)

    local removedConn = Workspace.DescendantRemoving:Connect(function(child)
        local itemIdx = table_find(cachedItems, child)
        if itemIdx then
            table.remove(cachedItems, itemIdx)
        end
        local genIdx = table_find(cachedGenerators, child)
        if genIdx then
            table.remove(cachedGenerators, genIdx)
        end
        local trapIdx = table_find(cachedTraps, child)
        if trapIdx then
            table.remove(cachedTraps, trapIdx)
        end
    end)
    trackCacheConnections(removedConn)
end

local function isItemEquipped(item)
    if item:IsA("Tool") then
        local parent = item.Parent
        if parent and parent:FindFirstChildWhichIsA("Humanoid") then
            return true
        end
    end
    return false
end

local function safeConnect(button, eventName, callback)
    local event = nil
    pcall(function()
        event = button[eventName]
    end)
    if event and type(event) == "userdata" and type(event.Connect) == "function" then
        pcall(function()
            event:Connect(callback)
        end)
    end
end

function getCharacterInfo()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    return char, hum, hrp
end

local function isLocalPlayerSurvivor()
    local char = LocalPlayer.Character
    if not char then return false end
    
    local isKillerAttr = char:GetAttribute("Role") == "Killer" 
        or char:GetAttribute("role") == "Killer" 
        or char:GetAttribute("IsKiller") == true 
        or char:GetAttribute("isKiller") == true
    
    return not isKillerAttr
end

local function checkHelplessStatus()
    local now = os_clock()
    if now - lastHelplessCheck < HELPLESS_CACHE_INTERVAL then
        return cachedHelpless
    end
    lastHelplessCheck = now

    local character = LocalPlayer.Character
    if not character then 
        cachedHelpless = false
        return false 
    end

    for name, value in pairs(character:GetAttributes()) do
        if name:lower():find("helpless") then
            if value == true or value == "Helpless" or (type(value) == "number" and value > 0) then
                cachedHelpless = true
                return true
            end
        end
    end

    for _, child in ipairs(character:GetChildren()) do
        if child.Name:lower():find("helpless") then
            if child:IsA("ValueBase") then
                if child.Value == true or child.Value == 1 or (type(child.Value) == "number" and child.Value > 0) then
                    cachedHelpless = true
                    return true
                end
            else
                cachedHelpless = true
                return true
            end
        end
    end

    local statusFolders = {
        character:FindFirstChild("StatusEffects"),
        character:FindFirstChild("Status"),
        character:FindFirstChild("Effects"),
        LocalPlayer:FindFirstChild("StatusEffects"),
        LocalPlayer:FindFirstChild("Status"),
        LocalPlayer:FindFirstChild("Effects")
    }

    for _, statusFolder in ipairs(statusFolders) do
        if statusFolder then
            for _, child in ipairs(statusFolder:GetChildren()) do
                if child.Name:lower():find("helpless") then
                    if child:IsA("ValueBase") then
                        if child.Value == true or child.Value == 1 or (type(child.Value) == "number" and child.Value > 0) then
                            cachedHelpless = true
                            return true
                        end
                    else
                        cachedHelpless = true
                        return true
                    end
                end
            end
        end
    end

    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        local mainUI = playerGui:FindFirstChild("MainUI") or playerGui:FindFirstChild("Main")
        if mainUI and mainUI.Enabled then
            for _, child in ipairs(mainUI:GetChildren()) do
                if child.Name:lower():find("helpless") and child.Visible then
                    cachedHelpless = true
                    return true
                end
                if child.Name == "Status" or child.Name == "Effects" or child.Name == "StatusEffects" then
                    for _, subChild in ipairs(child:GetChildren()) do
                        if subChild.Name:lower():find("helpless") and (subChild:IsA("ValueBase") or subChild.Visible) then
                            cachedHelpless = true
                            return true
                        end
                    end
                end
            end
        end
    end

    cachedHelpless = false
    return false
end

local isCurrentlyInMatch = false
local lastInMatchCheck = 0
local IN_MATCH_CHECK_INTERVAL = 0.5

local function updateInMatchCache()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        isCurrentlyInMatch = false
        return
    end

    local distance = (char.HumanoidRootPart.Position - LOBBY_POSITION).Magnitude
    if distance <= LOBBY_RADIUS then
        isCurrentlyInMatch = false
        return
    end

    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        local mainUI = pg:FindFirstChild("MainUI")
        if mainUI and not mainUI.Enabled then
            isCurrentlyInMatch = false
            return
        end

        for _, uiName in ipairs({"Lobby", "LobbyUI", "Menu", "MenuUI", "MainMenu", "IntroUI", "SpectateUI"}) do
            local ui = pg:FindFirstChild(uiName)
            if ui and ui.Enabled then
                isCurrentlyInMatch = false
                return
            end
        end
    end

    local generatorExists = #cachedGenerators > 0

    local hasMap = Workspace:FindFirstChild("Map") or Workspace:FindFirstChild("Arena") or generatorExists
    if not hasMap and distance < 800 then
        isCurrentlyInMatch = false
        return
    end

    isCurrentlyInMatch = true
end

local function inMatch()
    if os_clock() - lastInMatchCheck >= IN_MATCH_CHECK_INTERVAL then
        lastInMatchCheck = os_clock()
        pcall(updateInMatchCache)
    end
    return isCurrentlyInMatch
end

local function notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3
        })
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    cachedSprintingModule = nil
    cachedM1Btn = nil
    cachedM1CooldownObj = nil
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then pcall(function() hum.AutoRotate = true end) end
end)

local function readCooldownValue(cdObj)
    if not cdObj then return nil end
    if cdObj:IsA("NumberValue") then
        return cdObj.Value
    end
    if cdObj:IsA("StringValue") then
        return tonumber(cdObj.Value)
    end
    if cdObj:IsA("TextLabel") or cdObj:IsA("TextBox") then
        return tonumber(cdObj.Text)
    end
    if cdObj.Value ~= nil then
        if type(cdObj.Value) == "number" then return cdObj.Value end
        if type(cdObj.Value) == "string" then return tonumber(cdObj.Value) end
    end
    if cdObj.Text ~= nil then
        return tonumber(cdObj.Text)
    end
    return nil
end

local function getButtonVisualName(btn)
    local names = { btn.Name:lower() }
    for _, desc in ipairs(btn:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextBox") then
            local txt = desc.Text:lower()
            if txt ~= "" then
                table_insert(names, txt)
            end
        end
    end
    return names
end

local cachedM1Btn = nil
local function getM1Button()
    if cachedM1Btn and cachedM1Btn.Parent then
        return cachedM1Btn
    end
    
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local mainUI = pg:FindFirstChild("MainUI")
    if not mainUI then return nil end
    local container = mainUI:FindFirstChild("AbilityContainer")
    if not container then return nil end
    
    local blacklist = {
        "unstable", "eye", "eyes", "infection", "entanglement", "rejuvenate", "block", 
        "heal", "teleport", "ability", "skill", "shield", "dodge", "run", "dash",
        "behead", "gashing", "wound", "raging", "pace", "prankster", "void rush", "rush",
        "mass infection", "rejuvenate the rotten", "void", "nova", "observant", 
        "hallucination", "hallucinations", "blood hook", "bloodhook", "ascension", 
        "cataclysm", "hunter's feast", "hunters feast", "leap", "gaze", "corrupt", 
        "nature", "trap", "traps", "spike", "spikes", "corrupt energy", "pursuit", "infernal"
    }
    
    local targetNames = {
        "slash", "swing", "punch", "stab", "lacerate", "bite", "claw", "hit", "thrust", "dagger", "carving", "eviscerate"
    }
    
    local children = container:GetChildren()
    
    local function isBtnBlacklisted(btn)
        local names = getButtonVisualName(btn)
        for _, name in ipairs(names) do
            for _, bName in ipairs(blacklist) do
                if name:find(bName) then
                    return true
                end
            end
        end
        return false
    end
    
    for _, child in ipairs(children) do
        if child:IsA("GuiObject") and child.Visible then
            if not isBtnBlacklisted(child) then
                local names = getButtonVisualName(child)
                for _, name in ipairs(names) do
                    for _, tName in ipairs(targetNames) do
                        if name == tName then
                            cachedM1Btn = child
                            return child
                        end
                    end
                end
            end
        end
    end
    
    for _, child in ipairs(children) do
        if child:IsA("GuiObject") and child.Visible then
            if not isBtnBlacklisted(child) then
                local names = getButtonVisualName(child)
                for _, name in ipairs(names) do
                    for _, tName in ipairs(targetNames) do
                        if name:find(tName) then
                            cachedM1Btn = child
                            return child
                        end
                    end
                end
            end
        end
    end
    
    for _, child in ipairs(children) do
        if child:IsA("GuiObject") and child.Visible then
            if not isBtnBlacklisted(child) then
                local hotkey = child:FindFirstChild("Hotkey") or child:FindFirstChild("Keybind") or child:FindFirstChild("Key")
                if hotkey and (hotkey:IsA("TextLabel") or hotkey:IsA("TextBox")) then
                    local txt = hotkey.Text:lower()
                    if txt == "m1" or txt == "lmb" or txt == "click" or txt:find("mouse") then
                        cachedM1Btn = child
                        return child
                    end
                end
            end
        end
    end
    
    for _, child in ipairs(children) do
        if child:IsA("GuiObject") and child.Visible then
            if not isBtnBlacklisted(child) then
                local name = child.Name:lower()
                if name ~= "uipadding" and name ~= "uilistlayout" and name ~= "uigridlayout" then
                    cachedM1Btn = child
                    return child
                end
            end
        end
    end
    
    return nil
end

local cachedM1CooldownObj = nil
local function getM1Cooldown()
    if cachedM1CooldownObj and cachedM1CooldownObj.Parent then
        return cachedM1CooldownObj
    end

    local btn = getM1Button()
    if not btn then return nil end
    local cd = btn:FindFirstChild("CooldownTime")
        or btn:FindFirstChild("Cooldown")
        or btn:FindFirstChildWhichIsA("NumberValue")
        or btn:FindFirstChildWhichIsA("StringValue")
    if cd then 
        cachedM1CooldownObj = cd
        return cd 
    end
    local lbl = btn:FindFirstChild("CooldownLabel") or btn:FindFirstChild("Timer") or btn:FindFirstChild("CD")
    if lbl then 
        cachedM1CooldownObj = lbl
        return lbl 
    end
    return nil
end

local function isM1OnCooldown()
    local cdObj = getM1Cooldown()
    if not cdObj then return false end
    local val = readCooldownValue(cdObj)
    return (val and val > 0.1) or false
end

local function isM1OnCooldownCached()
    local now = os_clock()
    if now - lastM1CDCheck < 0.05 then
        return cachedM1CD
    end
    lastM1CDCheck = now
    cachedM1CD = isM1OnCooldown()
    return cachedM1CD
end

local function isValidKillerModel(model)
    if not model then return false end
    if model == LocalPlayer.Character then return false end
    
    if model:GetAttribute("NPC") == true or model:GetAttribute("IsNPC") == true then
        return false
    end

    local humanoid = killerHumanoidCache[model]
    if not humanoid or not humanoid.Parent then
        humanoid = model:FindFirstChildWhichIsA("Humanoid")
        killerHumanoidCache[model] = humanoid
    end

    if not humanoid or not humanoid.Health or humanoid.Health <= 0 then
        return false
    end

    local hrp = killerHrpCache[model]
    if not hrp or not hrp.Parent then
        hrp = model:FindFirstChild("HumanoidRootPart")
        killerHrpCache[model] = hrp
    end
    if not hrp then return false end

    local isClean = killerNameCheckCache[model]
    if isClean == nil then
        local lowerName = model.Name:lower()
        if lowerName:find("clone") or lowerName:find("npc") or lowerName:find("fake") then
            killerNameCheckCache[model] = false
            isClean = false
        else
            killerNameCheckCache[model] = true
            isClean = true
        end
    end

    return isClean
end

local function isValidSurvivor(model)
    if not model then return false end
    if model == LocalPlayer.Character then return false end
    
    if model:GetAttribute("NPC") == true or model:GetAttribute("IsNPC") == true then
        return false
    end

    if model.Parent and (model.Parent.Name == "Killers" or (model.Parent.Parent and model.Parent.Parent.Name == "Killers")) then
        return false
    end

    local isKillerAttr = model:GetAttribute("Role") == "Killer" 
        or model:GetAttribute("role") == "Killer" 
        or model:GetAttribute("IsKiller") == true 
        or model:GetAttribute("isKiller") == true
    if isKillerAttr then
        return false
    end

    local lowerName = model.Name:lower()
    local killerNames = {"slasher", "c00lkidd", "john doe", "noli", "1x1x1x1", "guest 666", "nosferatu", "jason", "doombringer", "azure", "slenderman", "zombie king", "kool killer", "drakobloxxer", "phosphorus", "charlatan", "flowers", "guest 1458", "the masked", "the decayed", "sorcus"}
    for _, kName in ipairs(killerNames) do
        if lowerName == kName or lowerName:find(kName) then
            return false
        end
    end

    local humanoid = survivorHumanoidCache[model]
    if not humanoid or not humanoid.Parent then
        humanoid = model:FindFirstChildWhichIsA("Humanoid")
        survivorHumanoidCache[model] = humanoid
    end

    if not humanoid or not humanoid.Health or humanoid.Health <= 0 then
        return false
    end

    local hrp = survivorHrpCache[model]
    if not hrp or not hrp.Parent then
        hrp = model:FindFirstChild("HumanoidRootPart")
        survivorHrpCache[model] = hrp
    end
    if not hrp then return false end

    local player = Players:GetPlayerFromCharacter(model)
    if player then
        if lowerName:find("clone") or lowerName:find("npc") or lowerName:find("fake") then
            return false
        end
        return true
    end

    local playersFolder = Workspace:FindFirstChild("Players")
    if playersFolder and model.Parent == playersFolder then
        if lowerName:find("clone") or lowerName:find("npc") or lowerName:find("fake") then
            return false
        end
        return true
    end

    if lowerName:find("clone") or lowerName:find("npc") or lowerName:find("fake") then
        return false
    end

    local survivorNames = {"twotime", "guest 1337", "dusekkar", "chance", "veeronica", "builderman", "taph", "noob", "shedletsky", "007n7", "elliot", "jane doe"}
    for _, sName in ipairs(survivorNames) do
        if lowerName:find(sName) then
            return true
        end
    end

    return false
end

local function isStrictTargetSurvivor(model)
    if not model then return false end
    if model == LocalPlayer.Character then return false end
    
    local humanoid = model:FindFirstChildWhichIsA("Humanoid")
    if not humanoid or not humanoid.Health or humanoid.Health <= 0 then
        return false
    end
    
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local lowerName = model.Name:lower()
    local player = Players:GetPlayerFromCharacter(model)
    local lowerDisplayName = player and player.DisplayName:lower() or ""
    
    for _, sName in ipairs(allowedSurvivorNames) do
        if lowerName == sName or lowerName:find(sName, 1, true) or lowerDisplayName == sName or lowerDisplayName:find(sName, 1, true) then
            return true
        end
    end
    
    return false
end

local function updateGuiCorners(radiusValue)
    local gui = Library and Library.ScreenGui
    if not gui then
        gui = game:GetService("CoreGui"):FindFirstChild("Obsidian") or game:GetService("CoreGui"):FindFirstChild("FreshLeavesSakenUI")
    end
    if gui then
        for _, child in ipairs(gui:GetDescendants()) do
            if child:IsA("UICorner") then
                pcall(function()
                    child.CornerRadius = UDim.new(0, radiusValue)
                end)
            end
        end
        
        if cornerConnection then
            cornerConnection:Disconnect()
            cornerConnection = nil
        end
        
        cornerConnection = gui.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("UICorner") then
                task.wait()
                pcall(function()
                    descendant.CornerRadius = UDim.new(0, guiCornerRadius)
                end)
            end
        end)
    end
end

local cachedKillers = {}
local lastKillersRefresh = 0
local KILLERS_REFRESH_INTERVAL = 0.5

local function updateKillersCache()
    table_clear(killerNameCheckCache)
    table_clear(killerHumanoidCache)
    table_clear(killerHrpCache)
    table_clear(cachedKillers)
    
    local playersFolder = Workspace:FindFirstChild("Players")
    
    local killersFolder = playersFolder and playersFolder:FindFirstChild("Killers")
    if killersFolder then
        for _, c in ipairs(killersFolder:GetChildren()) do
            if c:IsA("Model") and c:FindFirstChild("HumanoidRootPart") then
                table_insert(cachedKillers, c)
            end
        end
    end
    
    local workspaceKillers = Workspace:FindFirstChild("Killers")
    if workspaceKillers then
        for _, c in ipairs(workspaceKillers:GetChildren()) do
            if c:IsA("Model") and c:FindFirstChild("HumanoidRootPart") and not table_find(cachedKillers, c) then
                table_insert(cachedKillers, c)
            end
        end
    end

    if playersFolder then
        for _, c in ipairs(playersFolder:GetChildren()) do
            if c:IsA("Model") and c ~= LocalPlayer.Character and c:FindFirstChild("HumanoidRootPart") then
                local isKillerAttr = c:GetAttribute("Role") == "Killer" or c:GetAttribute("role") == "Killer" or c:GetAttribute("IsKiller") == true or c:GetAttribute("isKiller") == true
                if isKillerAttr then
                    if not table_find(cachedKillers, c) then
                        table_insert(cachedKillers, c)
                    end
                end
            end
        end
    end

    if #cachedKillers == 0 and inMatch() then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local charModel = p.Character
                local isKillerAttr = charModel:GetAttribute("Role") == "Killer" 
                    or charModel:GetAttribute("role") == "Killer" 
                    or charModel:GetAttribute("IsKiller") == true 
                    or charModel:GetAttribute("isKiller") == true
                
                if isKillerAttr then
                    table_insert(cachedKillers, charModel)
                end
            end
        end
    end
end

local function getKillersList()
    if os_clock() - lastKillersRefresh >= KILLERS_REFRESH_INTERVAL then
        lastKillersRefresh = os_clock()
        pcall(updateKillersCache)
    end
    return cachedKillers
end

local cachedSurvivors = {}
local lastSurvivorsRefresh = 0
local SURVIVORS_REFRESH_INTERVAL = 0.5 

local function updateSurvivorsCache()
    table_clear(survivorHumanoidCache)
    table_clear(survivorHrpCache)
    table_clear(cachedSurvivors)
    
    local killers = getKillersList()
    local playersFolder = Workspace:FindFirstChild("Players")
    
    if playersFolder then
        for _, c in ipairs(playersFolder:GetChildren()) do
            if c:IsA("Model") and c ~= LocalPlayer.Character and c:FindFirstChild("HumanoidRootPart") then
                if not table_find(killers, c) and isValidSurvivor(c) then
                    table_insert(cachedSurvivors, c)
                end
            end
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local charModel = p.Character
            if not table_find(killers, charModel) and isValidSurvivor(charModel) and not table_find(cachedSurvivors, charModel) then
                table_insert(cachedSurvivors, charModel)
            end
        end
    end
end

local function getSurvivorsList()
    if os_clock() - lastSurvivorsRefresh >= SURVIVORS_REFRESH_INTERVAL then
        lastSurvivorsRefresh = os_clock()
        pcall(updateSurvivorsCache)
    end
    return cachedSurvivors
end

local function getItemsList()
    return cachedItems
end

local function getGeneratorsList()
    return cachedGenerators
end

local function getTrapsList()
    return cachedTraps
end

local function getGeneratorProgress(gen)
    local progressObj = gen:FindFirstChild("Progress")
    if progressObj and (progressObj:IsA("ValueBase") or progressObj:IsA("NumberValue") or progressObj:IsA("IntValue")) then
        return progressObj.Value
    end
    
    local attr = gen:GetAttribute("Progress") or gen:GetAttribute("Percentage") or gen:GetAttribute("Percent")
    if attr then return tonumber(attr) end
    
    for _, descendant in ipairs(gen:GetDescendants()) do
        if descendant.Name == "Progress" and descendant:IsA("ValueBase") then
            return descendant.Value
        end
    end
    return 0
end

local function getProjectileTarget()
    local targets = {}
    local useStrict = Toggles and Toggles.StrictAimbotOnly and Toggles.StrictAimbotOnly.Value or false
    
    for _, survivor in ipairs(getSurvivorsList()) do
        if useStrict then
            if isStrictTargetSurvivor(survivor) then
                table_insert(targets, survivor)
            end
        else
            if isValidSurvivor(survivor) then
                table_insert(targets, survivor)
            end
        end
    end
    
    local char, _, hrp = getCharacterInfo()
    if not hrp then return nil end
    
    local bestTarget = nil
    local bestValue = math.huge
    local targetMode = (Options and Options.ProjectileTargetMode) and Options.ProjectileTargetMode.Value or "Nearest"
    
    if targetMode == "Nearest" then
        for _, t in ipairs(targets) do
            local thrp = t:FindFirstChild("HumanoidRootPart")
            if thrp then
                local dist = (thrp.Position - hrp.Position).Magnitude
                if dist < bestValue then
                    bestValue = dist
                    bestTarget = t
                end
            end
        end
    elseif targetMode == "Lowest" then
        for _, t in ipairs(targets) do
            local hum = t:FindFirstChildWhichIsA("Humanoid")
            if hum and hum.Health > 0 then
                if hum.Health < bestValue then
                    bestValue = hum.Health
                    bestTarget = t
                end
            end
        end
    elseif targetMode == "Nearest & Lowest" then
        local closeTargets = {}
        for _, t in ipairs(targets) do
            local thrp = t:FindFirstChild("HumanoidRootPart")
            local hum = t:FindFirstChildWhichIsA("Humanoid")
            if thrp and hum and hum.Health > 0 then
                local dist = (thrp.Position - hrp.Position).Magnitude
                if dist <= 80 then
                    table_insert(closeTargets, {model = t, health = hum.Health, dist = dist})
                end
            end
        end
        
        if #closeTargets > 0 then
            local lowestHealth = math.huge
            for _, ct in ipairs(closeTargets) do
                if ct.health < lowestHealth then
                    lowestHealth = ct.health
                    bestTarget = ct.model
                end
            end
        else
            local nearestDist = math.huge
            for _, t in ipairs(targets) do
                local thrp = t:FindFirstChild("HumanoidRootPart")
                if thrp then
                    local dist = (thrp.Position - hrp.Position).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        bestTarget = t
                    end
                end
            end
        end
    end
    
    return bestTarget
end

local function triggerProjectileAim(skillName)
    if not Toggles or not Toggles.ProjectileAimEnabled or not Toggles.ProjectileAimEnabled.Value then return end
    if not inMatch() then return end
    
    local config = skillConfigs[skillName]
    if not config or not config.enabled then return end
    
    local aimDelay = (Options and Options.ProjectileAimDelay) and Options.ProjectileAimDelay.Value or 0
    task.delay(aimDelay, function()
        if isUnloaded or not inMatch() then return end
        local target = getProjectileTarget()
        if target then
            projectileAimbotActive = true
            projectileAimStartTime = os_clock()
            projectileAimbotTarget = target
            currentActiveSkill = skillName
            
            local _, humanoid, _ = getCharacterInfo()
            if humanoid then
                pcall(function() humanoid.AutoRotate = false end)
            end
        end
    end)
end

local trackedProjectiles = {
    ["mass infection"] = "Mass Infection",
    ["massinfection"] = "Mass Infection",
    ["corrupt energy"] = "Corrupt Energy",
    ["corruptenergy"] = "Corrupt Energy",
    ["entanglement"] = "Entanglement"
}

local function getButtonCooldown(btn)
    if not btn then return nil end
    local cd = btn:FindFirstChild("CooldownTime")
        or btn:FindFirstChild("Cooldown")
        or btn:FindFirstChildWhichIsA("NumberValue")
        or btn:FindFirstChildWhichIsA("StringValue")
    if cd then return cd end
    local lbl = btn:FindFirstChild("CooldownLabel") or btn:FindFirstChild("Timer") or btn:FindFirstChild("CD")
    if lbl then return lbl end
    return nil
end

local function getTrackedAbilityButtons()
    local buttons = {}
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return buttons end
    local mainUI = pg:FindFirstChild("MainUI")
    if not mainUI then return buttons end
    local container = mainUI:FindFirstChild("AbilityContainer")
    if not container then return buttons end
    
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("GuiObject") and child.Visible then
            local names = getButtonVisualName(child)
            for _, name in ipairs(names) do
                for tName, _ in pairs(trackedProjectiles) do
                    if name == tName or name:find(tName, 1, true) then
                        buttons[tName] = child
                        break
                    end
                end
            end
        end
    end
    return buttons
end

local hookedButtons = {}
local function updateTrackedAbilityHooks()
    local btns = getTrackedAbilityButtons()
    for tName, btn in pairs(btns) do
        if btn and not hookedButtons[btn] then
            hookedButtons[btn] = true
            local skillName = trackedProjectiles[tName]
            safeConnect(btn, "MouseButton1Click", function()
                triggerProjectileAim(skillName)
            end)
            safeConnect(btn, "Activated", function()
                triggerProjectileAim(skillName)
            end)
        end
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if isUnloaded then return end
    if not Toggles or not Toggles.ProjectileAimEnabled or not Toggles.ProjectileAimEnabled.Value then return end
    
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local btns = getTrackedAbilityButtons()
        for tName, btn in pairs(btns) do
            local hotkey = btn:FindFirstChild("Hotkey") or btn:FindFirstChild("Keybind") or btn:FindFirstChild("Key")
            if hotkey and (hotkey:IsA("TextLabel") or hotkey:IsA("TextBox")) then
                local txt = hotkey.Text:upper()
                if txt ~= "" and Enum.KeyCode[txt] == input.KeyCode then
                    local skillName = trackedProjectiles[tName]
                    triggerProjectileAim(skillName)
                end
            end
        end
    end
end)

local function triggerAutoM1Aimbot(target)
    if not inMatch() or autoM1AimbotActive or projectileAimbotActive then return end
    
    autoM1AimbotActive = true
    autoM1AimbotStart = os_clock()
    autoM1AimbotTarget = target
    
    local _, humanoid, _ = getCharacterInfo()
    if humanoid then
        pcall(function() humanoid.AutoRotate = true end)
    end
end

local function tryActivateButton(btn)
    if not btn then return false end
    local activated = false

    pcall(function()
        if btn.Activate then 
            btn:Activate() 
            activated = true
        end
    end)

    if type(getconnections) == "function" then
        for _, event in ipairs({btn.MouseButton1Click, btn.Activated}) do
            if event then
                pcall(function()
                    for _, conn in ipairs(getconnections(event)) do
                        if conn.Function then
                            pcall(conn.Function)
                            activated = true
                        elseif conn.Fire then
                            pcall(function() conn:Fire() end)
                            activated = true
                        end
                    end
                end)
            end
        end
    end

    if not activated and VirtualInputManager then
        pcall(function()
            local absPos = btn.AbsolutePosition
            local absSize = btn.AbsoluteSize
            local inset = GuiService:GetGuiInset()
            local clickX = absPos.X + (absSize.X / 2)
            local clickY = absPos.Y + (absSize.Y / 2) + inset.Y
            
            VirtualInputManager:SendTouchEvent(1, 0, clickX, clickY)
            task.wait(0.01)
            VirtualInputManager:SendTouchEvent(1, 2, clickX, clickY)
            
            VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 1)
            task.wait(0.01)
            VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 1)
            activated = true
        end)
    end

    return activated
end

local function applyFullBright()
    if fullBrightEnabled then
        if Lighting.Ambient ~= Color3.fromRGB(255, 255, 255) then Lighting.Ambient = Color3.fromRGB(255, 255, 255) end
        if Lighting.OutdoorAmbient ~= Color3.fromRGB(255, 255, 255) then Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255) end
        if Lighting.ColorShift_Bottom ~= Color3.fromRGB(0, 0, 0) then Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0) end
        if Lighting.ColorShift_Top ~= Color3.fromRGB(0, 0, 0) then Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0) end
        if Lighting.ExposureCompensation ~= 0.5 then Lighting.ExposureCompensation = 0.5 end
        if Lighting.GlobalShadows ~= false then Lighting.GlobalShadows = false end
        if Lighting.Brightness ~= 2 then Lighting.Brightness = 2 end
    else
        if Lighting.Ambient ~= originalLightingSettings.Ambient then Lighting.Ambient = originalLightingSettings.Ambient end
        if Lighting.OutdoorAmbient ~= originalLightingSettings.OutdoorAmbient then Lighting.OutdoorAmbient = originalLightingSettings.OutdoorAmbient end
        if Lighting.ColorShift_Bottom ~= originalLightingSettings.ColorShift_Bottom then Lighting.ColorShift_Bottom = originalLightingSettings.ColorShift_Bottom end
        if Lighting.ColorShift_Top ~= originalLightingSettings.ColorShift_Top then Lighting.ColorShift_Top = originalLightingSettings.ColorShift_Top end
        if Lighting.ExposureCompensation ~= originalLightingSettings.ExposureCompensation then Lighting.ExposureCompensation = originalLightingSettings.ExposureCompensation end
        if Lighting.GlobalShadows ~= originalLightingSettings.GlobalShadows then Lighting.GlobalShadows = originalLightingSettings.GlobalShadows end
        if Lighting.Brightness ~= originalLightingSettings.Brightness then Lighting.Brightness = originalLightingSettings.Brightness end
    end
end

local function applyCustomStats(stamina)
    if not stamina then return end
    stamina.MaxStamina = MAX_STAMINA
    stamina.MinStamina = MIN_STAMINA
    stamina.StaminaGain = STAMINA_GAIN
    stamina.StaminaLoss = STAMINA_LOSS
    stamina.SprintSpeed = SPRINT_SPEED
    stamina.StaminaLossDisabled = INF_STAMINA
end

local function getSprintingModule()
    if cachedSprintingModule then 
        return cachedSprintingModule 
    end
    
    local success, res = pcall(function()
        local Sprinting = game:GetService("ReplicatedStorage").Systems.Character.Game.Sprinting
        return require(Sprinting)
    end)
    
    if success and type(res) == "table" then
        cachedSprintingModule = res
        return res
    end
    
    local sprintingModule = nil
    pcall(function()
        for _, v in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if v:IsA("ModuleScript") and (v.Name == "Sprinting" or v.Name == "Sprint" or v.Name == "SprintingSystem") then
                sprintingModule = v
                break
            end
        end
    end)
    
    if sprintingModule then
        local ok, req = pcall(require, sprintingModule)
        if ok and type(req) == "table" then
            cachedSprintingModule = req
            return req
        end
    end
    
    return nil
end

task.spawn(function()
    local wasHelpless = false
    while true do
        if isUnloaded then break end
        local isHelpless = checkHelplessStatus()
        
        if isHelpless and not wasHelpless then
            print("[FLS HUB] Helpless status detected on survivor character.")
            wasHelpless = true
        elseif not isHelpless and wasHelpless then
            print("[FLS HUB] Helpless status cleared. Character abilities restored.")
            wasHelpless = false
        end
        task.wait(0.5)
    end
end)

local successLoad, loadError = pcall(function()
    local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
    Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
    ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
    SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
end)

if not successLoad or not Library then
    warn("Obsidian framework failed to initialize: " .. tostring(loadError))
end

local ui_refs = {}

if Library then
    Library.ForceCheckbox = false
    Library.ShowToggleFrameInKeybinds = true

    Window = Library:CreateWindow({
        Title = "FlsSaken||Official",
        Footer = "FreshLeavesSaken • Indigo Framework",
        NotifySide = "Right",
        ShowCustomCursor = true,
    })

    pcall(function()
        Library:SetDPIScale(75)
    end)

    task.spawn(function()
        local titleLabel = nil
        for i = 1, 20 do
            if not Library.ScreenGui then task.wait(0.05) continue end
            for _, desc in ipairs(Library.ScreenGui:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Text == "FlsSaken||Official" then
                    titleLabel = desc
                    break
                end
            end
            if titleLabel then break end
            task.wait(0.05)
        end

        if titleLabel then
            local topbar = titleLabel.Parent
            if topbar then
                local titleDecal = Instance.new("ImageLabel")
                titleDecal.Name = "TitleDecalIcon"
                titleDecal.BackgroundTransparency = 1
                titleDecal.Image = "rbxassetid://71081229545579"
                titleDecal.Size = UDim2.fromOffset(18, 18)
                titleDecal.Position = UDim2.new(0, 8, 0.5, -9)
                titleDecal.Parent = topbar

                titleLabel.Position = UDim2.new(0, 30, titleLabel.Position.Y.Scale, titleLabel.Position.Y.Offset)

                local discordBtn = Instance.new("ImageButton")
                discordBtn.Name = "DiscordTopRightButton"
                discordBtn.BackgroundTransparency = 1
                discordBtn.Image = "rbxassetid://15243171358"
                discordBtn.ImageColor3 = HUDColors.WatermarkAccent
                discordBtn.Size = UDim2.fromOffset(16, 16)
                discordBtn.ZIndex = titleLabel.ZIndex + 5

                local rightOffset = -28
                for _, child in ipairs(topbar:GetChildren()) do
                    if (child:IsA("ImageButton") or child:IsA("TextButton")) and child.Name ~= "DiscordTopRightButton" then
                        if child.Position.X.Scale >= 0.8 then
                            local offset = child.Position.X.Offset
                            if offset < rightOffset then
                                rightOffset = offset - 22
                            end
                        end
                    end
                end

                discordBtn.Position = UDim2.new(1, rightOffset, 0.5, -8)
                discordBtn.Parent = topbar

                titleLabel.Size = UDim2.new(1, rightOffset - 35, 1, 0)
                titleLabel.TextTruncate = Enum.TextTruncate.AtEnd

                discordBtn.MouseButton1Click:Connect(function()
                    if copyToClipboard(DISCORD_INVITE) then
                        notify("Discord Invite Copied", "Link copied to clipboard! Paste it into your browser.", 5)
                    else
                        notify("Discord Server Invite", DISCORD_INVITE, 10)
                    end
                end)

                discordBtn.MouseEnter:Connect(function()
                    discordBtn.ImageColor3 = Color3.fromRGB(180, 155, 255)
                end)
                discordBtn.MouseLeave:Connect(function()
                    discordBtn.ImageColor3 = HUDColors.WatermarkAccent
                end)
            end
        end
    end)

    Tabs = {
        Main = Window:AddTab("Main", "alert-circle"),
        Combat = Window:AddTab("Gameplay", "swords"),
        Killer = Window:AddTab("Killer", "skull"),
        Visuals = Window:AddTab("Visuals", "eye"),
        ["UI Settings"] = Window:AddTab("Settings", "settings"),
    }

    ---------------------------------------------------------
    -- MAIN TAB SETUP
    ---------------------------------------------------------
    local MainLeftGroup = Tabs.Main:AddLeftGroupbox("Community & Hub Banner")
    local MainRightGroup = Tabs.Main:AddRightGroupbox("Credits & Development")

    local logoFrame = Instance.new("Frame")
    logoFrame.Name = "FLS_BannerFrame"
    logoFrame.Size = UDim2.new(1, 0, 0, 140)
    logoFrame.BackgroundTransparency = 1
    logoFrame.BorderSizePixel = 0
    logoFrame.Parent = MainLeftGroup.Container

    local logoImg = Instance.new("ImageLabel")
    logoImg.Name = "FLS_BannerImage"
    logoImg.Size = UDim2.new(1, 0, 1, 0)
    logoImg.BackgroundTransparency = 1
    logoImg.Image = "rbxassetid://72407443718889"
    logoImg.ScaleType = Enum.ScaleType.Crop
    logoImg.Parent = logoFrame

    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 6)
    logoCorner.Parent = logoImg

    task.spawn(function()
        local imageFileName = "FLS_Logo_FreshLeaves.png"
        local downloaded = false

        if writefile and getcustomasset then
            pcall(function()
                if not isfile or not isfile(imageFileName) then
                    local data = game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/assets/banner.png")
                    if data and #data > 100 then
                        writefile(imageFileName, data)
                    end
                end
                if isfile and isfile(imageFileName) then
                    logoImg.Image = getcustomasset(imageFileName)
                    downloaded = true
                end
            end)
        end

        if not downloaded or logoImg.Image == "" then
            logoImg.Image = "rbxassetid://72407443718889" 
        end
    end)

    MainLeftGroup:AddDivider()

    MainLeftGroup:AddButton("Copy Discord Server Invite", function()
        if copyToClipboard(DISCORD_INVITE) then
            notify("Discord Server", "Server invite link copied to clipboard!", 5)
        else
            notify("Discord Server", DISCORD_INVITE, 8)
        end
    end)

    ---------------------------------------------------------
    -- CREDITS SECTION
    ---------------------------------------------------------
    local ownerHeader = MainRightGroup:AddLabel("PROJECT OWNER:", true)
    local ownerName = MainRightGroup:AddLabel("FreshTropicalLeaves", true)
    local ownerSub = MainRightGroup:AddLabel("(The one who made almost everything)", true)

    pcall(function()
        if ownerHeader and ownerHeader.TextLabel then
            ownerHeader.TextLabel.TextColor3 = Color3.fromRGB(255, 65, 65)
            ownerHeader.TextLabel.Font = Enum.Font.SourceSansBold
        end
        if ownerName and ownerName.TextLabel then
            ownerName.TextLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            ownerName.TextLabel.Font = Enum.Font.SourceSansBold
            ownerName.TextLabel.TextSize = 15
        end
        if ownerSub and ownerSub.TextLabel then
            ownerSub.TextLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            ownerSub.TextLabel.TextWrapped = true
        end
    end)

    MainRightGroup:AddDivider()

    local logoHeader = MainRightGroup:AddLabel("GRAPHICS & LOGO:", true)
    local logoName = MainRightGroup:AddLabel("Christiana Amane", true)
    local logoSub = MainRightGroup:AddLabel("(The one who made the logo)", true)

    pcall(function()
        if logoHeader and logoHeader.TextLabel then
            logoHeader.TextLabel.TextColor3 = Color3.fromRGB(180, 180, 220)
            logoHeader.TextLabel.Font = Enum.Font.SourceSansBold
        end
        if logoName and logoName.TextLabel then
            logoName.TextLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
            logoName.TextLabel.Font = Enum.Font.SourceSansBold
        end
        if logoSub and logoSub.TextLabel then
            logoSub.TextLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
            logoSub.TextLabel.TextWrapped = true
            logoSub.TextLabel.TextTruncate = Enum.TextTruncate.AtEnd
        end
    end)

    ---------------------------------------------------------
    -- GAMEPLAY / KILLER / VISUALS / SETTINGS SETUP
    ---------------------------------------------------------
    local CombatGroup = Tabs.Combat:AddLeftGroupbox("Stamina Engine")
    local KillerGroup = Tabs.Killer:AddLeftGroupbox("Auto Melee (M1) System")
    local ProjectileGroup = Tabs.Killer:AddRightGroupbox("Projectile Aimbot (CA-Aim)")
    local VisualsLeftGroup = Tabs.Visuals:AddLeftGroupbox("ESP Visuals & Overlays")

    CombatGroup:AddToggle("EnStaminaMod", {
        Text = "Custom Stamina Logic",
        Tooltip = "Overrides sprinting system parameters.",
        Default = false,
        Callback = function(Value)
            staminaEnabled = Value
            if staminaEnabled then
                local stamina = getSprintingModule()
                if stamina then pcall(applyCustomStats, stamina) end
            end
        end,
    })

    CombatGroup:AddToggle("InfStam", {
        Text = "Unlimited Stamina",
        Tooltip = "Completely disables stamina consumption.",
        Default = true,
        Callback = function(Value)
            INF_STAMINA = Value
            if staminaEnabled then
                local stamina = getSprintingModule()
                if stamina then pcall(applyCustomStats, stamina) end
            end
        end,
    })

    CombatGroup:AddInput("MaxStaminaVal", {
        Text = "Maximum Stamina",
        Default = tostring(MAX_STAMINA),
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "100",
        Callback = function(Value)
            MAX_STAMINA = tonumber(Value) or 100
            if staminaEnabled then
                local stamina = getSprintingModule()
                if stamina then pcall(applyCustomStats, stamina) end
            end
        end,
    })

    CombatGroup:AddInput("MinStaminaVal", {
        Text = "Minimum Threshold",
        Default = tostring(MIN_STAMINA),
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "-20",
        Callback = function(Value)
            MIN_STAMINA = tonumber(Value) or -20
            if staminaEnabled then
                local stamina = getSprintingModule()
                if stamina then pcall(applyCustomStats, stamina) end
            end
        end,
    })

    CombatGroup:AddInput("StaminaGainVal", {
        Text = "Regeneration Rate",
        Default = tostring(STAMINA_GAIN),
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "100",
        Callback = function(Value)
            STAMINA_GAIN = tonumber(Value) or 100
            if staminaEnabled then
                local stamina = getSprintingModule()
                if stamina then pcall(applyCustomStats, stamina) end
            end
        end,
    })

    CombatGroup:AddInput("StaminaLossVal", {
        Text = "Depletion Rate",
        Default = tostring(STAMINA_LOSS),
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "5",
        Callback = function(Value)
            STAMINA_LOSS = tonumber(Value) or 5
            if staminaEnabled then
                local stamina = getSprintingModule()
                if stamina then pcall(applyCustomStats, stamina) end
            end
        end,
    })

    CombatGroup:AddInput("SprintSpeedVal", {
        Text = "Sprint Velocity",
        Default = tostring(SPRINT_SPEED),
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "40",
        Callback = function(Value)
            SPRINT_SPEED = tonumber(Value) or 40
            if staminaEnabled then
                local stamina = getSprintingModule()
                if stamina then pcall(applyCustomStats, stamina) end
            end
        end,
    })

    KillerGroup:AddToggle("AutoM1Toggle", {
        Text = "Enable Auto M1",
        Tooltip = "Automatically targets and executes melee strikes on nearby survivors.",
        Default = false,
        Callback = function(Value)
            autoM1Enabled = Value
        end,
    })

    KillerGroup:AddToggle("AutoM1VisualizerToggle", {
        Text = "Field Visualizer",
        Tooltip = "Displays target range circle and angle FOV cone lines.",
        Default = true,
        Callback = function(Value)
            autoM1VisualizerEnabled = Value
        end,
    })

    KillerGroup:AddSlider("AutoM1Range", {
        Text = "Targeting Distance",
        Default = 5,
        Min = 1,
        Max = 20,
        Rounding = 1,
        Tooltip = "Maximum detection distance for melee strikes.",
        Callback = function(Value)
            autoM1Range = tonumber(Value) or 5
        end,
    })

    KillerGroup:AddSlider("AutoM1ConeAngle", {
        Text = "Scan Angle Cone",
        Default = 90,
        Min = 1,
        Max = 180,
        Rounding = 0,
        Suffix = "°",
        Tooltip = "Frontal detection window constraint angle.",
        Callback = function(Value)
            autoM1ConeAngle = tonumber(Value) or 90
        end,
    })

    KillerGroup:AddInput("AutoM1AimDuration", {
        Text = "Lock Duration",
        Default = "1.5",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "e.g., 1.5",
        Callback = function(Value)
            autoM1AimDuration = tonumber(Value) or 1.5
        end,
    })

    KillerGroup:AddSlider("AutoM1MaxPrediction", {
        Text = "Prediction Lead Time",
        Default = 0.2,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Suffix = "s",
        Tooltip = "Target movement velocity tracking offset.",
        Callback = function(Value)
            autoM1MaxPrediction = tonumber(Value) or 0.2
        end,
    })

    KillerGroup:AddSlider("AutoM1AimSpeed", {
        Text = "Rotation Speed",
        Default = 15,
        Min = 1,
        Max = 50,
        Rounding = 1,
        Tooltip = "Camera alignment smoothing speed toward target.",
        Callback = function(Value)
            autoM1AimSpeed = tonumber(Value) or 15
        end,
    })

    ProjectileGroup:AddToggle("ProjectileAimEnabled", {
        Text = "Enable Projectile Aim",
        Tooltip = "Locks rotation toward target entity upon triggering projectile abilities.",
        Default = false,
    })

    ProjectileGroup:AddToggle("StrictAimbotOnly", {
        Text = "Strict Target Filter",
        Tooltip = "Only locks onto explicitly whitelisted target names.",
        Default = false,
    })

    ProjectileGroup:AddDropdown("ProjectileTargetMode", {
        Values = { "Nearest", "Lowest", "Nearest & Lowest" },
        Default = "Nearest",
        Text = "Target Priority System",
        Tooltip = "Priority sorting conditions for projectile aimbot.",
    })

    ProjectileGroup:AddToggle("ProjectileVelocityPrediction", {
        Text = "Velocity Lead Prediction",
        Tooltip = "Calculates motion velocity vectors to lead moving targets.",
        Default = true,
    })

    ProjectileGroup:AddSlider("ProjectileAimDelay", {
        Text = "Activation Delay",
        Default = 0,
        Min = 0,
        Max = 3,
        Rounding = 2,
        Suffix = "s",
        Tooltip = "Delay before rotation lock is initiated.",
    })

    ProjectileGroup:AddDivider()
    ProjectileGroup:AddLabel("Mass Infection")
    ProjectileGroup:AddToggle("MassInfectionEnabled", {
        Text = "Mass Infection Aim",
        Default = true,
        Callback = function(Value)
            skillConfigs["Mass Infection"].enabled = Value
        end,
    })
    ProjectileGroup:AddSlider("MassInfectionDuration", {
        Text = "Lock Duration",
        Default = 1.25,
        Min = 0.1,
        Max = 5,
        Rounding = 2,
        Suffix = "s",
        Callback = function(Value)
            skillConfigs["Mass Infection"].duration = tonumber(Value) or 1.25
        end,
    })
    ProjectileGroup:AddSlider("MassInfectionSpeed", {
        Text = "Rotation Speed",
        Default = 35,
        Min = 1,
        Max = 100,
        Rounding = 1,
        Callback = function(Value)
            skillConfigs["Mass Infection"].speed = tonumber(Value) or 35
        end,
    })
    ProjectileGroup:AddSlider("MassInfectionPrediction", {
        Text = "Prediction Strength",
        Default = 0.2,
        Min = 0,
        Max = 2,
        Rounding = 2,
        Suffix = "s",
        Callback = function(Value)
            skillConfigs["Mass Infection"].prediction = tonumber(Value) or 0.2
        end,
    })

    ProjectileGroup:AddDivider()
    ProjectileGroup:AddLabel("Entanglement")
    ProjectileGroup:AddToggle("EntanglementEnabled", {
        Text = "Entanglement Aim",
        Default = true,
        Callback = function(Value)
            skillConfigs["Entanglement"].enabled = Value
        end,
    })
    ProjectileGroup:AddSlider("EntanglementDuration", {
        Text = "Lock Duration",
        Default = 0.65,
        Min = 0.1,
        Max = 5,
        Rounding = 2,
        Suffix = "s",
        Callback = function(Value)
            skillConfigs["Entanglement"].duration = tonumber(Value) or 0.65
        end,
    })
    ProjectileGroup:AddSlider("EntanglementSpeed", {
        Text = "Rotation Speed",
        Default = 35,
        Min = 1,
        Max = 100,
        Rounding = 1,
        Callback = function(Value)
            skillConfigs["Entanglement"].speed = tonumber(Value) or 35
        end,
    })
    ProjectileGroup:AddSlider("EntanglementPrediction", {
        Text = "Prediction Strength",
        Default = 0.2,
        Min = 0,
        Max = 2,
        Rounding = 2,
        Suffix = "s",
        Callback = function(Value)
            skillConfigs["Entanglement"].prediction = tonumber(Value) or 0.2
        end,
    })

    ProjectileGroup:AddDivider()
    ProjectileGroup:AddLabel("Corrupt Energy")
    ProjectileGroup:AddToggle("CorruptEnergyEnabled", {
        Text = "Corrupt Energy Aim",
        Default = true,
        Callback = function(Value)
            skillConfigs["Corrupt Energy"].enabled = Value
        end,
    })
    ProjectileGroup:AddSlider("CorruptEnergyDuration", {
        Text = "Lock Duration",
        Default = 0.65,
        Min = 0.1,
        Max = 5,
        Rounding = 2,
        Suffix = "s",
        Callback = function(Value)
            skillConfigs["Corrupt Energy"].duration = tonumber(Value) or 0.65
        end,
    })
    ProjectileGroup:AddSlider("CorruptEnergySpeed", {
        Text = "Rotation Speed",
        Default = 35,
        Min = 1,
        Max = 100,
        Rounding = 1,
        Callback = function(Value)
            skillConfigs["Corrupt Energy"].speed = tonumber(Value) or 35
        end,
    })
    ProjectileGroup:AddSlider("CorruptEnergyPrediction", {
        Text = "Prediction Strength",
        Default = 0.2,
        Min = 0,
        Max = 2,
        Rounding = 2,
        Suffix = "s",
        Callback = function(Value)
            skillConfigs["Corrupt Energy"].prediction = tonumber(Value) or 0.2
        end,
    })

    VisualsLeftGroup:AddToggle("KillerHighlight", {
        Text = "Killer Visuals",
        Tooltip = "Highlight and outline killer entities.",
        Default = false,
        Callback = function(Value)
            visualKillerHighlightEnabled = Value
        end,
    }):AddColorPicker("KillerHighlightColor", {
        Default = Color3.fromRGB(255, 0, 0),
        Title = "Killer Accent Color",
        Callback = function(Value)
            killerHighlightColor = Value
        end
    })

    VisualsLeftGroup:AddInput("KillerOutlineTransparency", {
        Text = "Outline Transparency",
        Default = "0.5",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "0.5",
        Callback = function(Value)
            visualKillerOutlineTransparency = tonumber(Value) or 0.5
            for _, hl in pairs(killerHighlights) do
                if hl then hl.OutlineTransparency = visualKillerOutlineTransparency end
            end
        end,
    })

    VisualsLeftGroup:AddInput("KillerFillTransparency", {
        Text = "Fill Transparency",
        Default = "0.85",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "0.85",
        Callback = function(Value)
            visualKillerFillTransparency = tonumber(Value) or 0.85
            for _, hl in pairs(killerHighlights) do
                if hl then hl.FillTransparency = visualKillerFillTransparency end
            end
        end
    })

    VisualsLeftGroup:AddDivider()

    VisualsLeftGroup:AddToggle("SurvivorHighlight", {
        Text = "Survivor Visuals",
        Tooltip = "Highlight and outline survivor entities.",
        Default = false,
        Callback = function(Value)
            visualSurvivorHighlightEnabled = Value
        end,
    }):AddColorPicker("SurvivorHighlightColor", {
        Default = Color3.fromRGB(0, 255, 0),
        Title = "Survivor Accent Color",
        Callback = function(Value)
            survivorHighlightColor = Value
        end
    })

    VisualsLeftGroup:AddInput("SurvivorOutlineTransparency", {
        Text = "Outline Transparency",
        Default = "0.5",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "0.5",
        Callback = function(Value)
            visualSurvivorOutlineTransparency = tonumber(Value) or 0.5
            for _, hl in pairs(survivorHighlights) do
                if hl then hl.OutlineTransparency = visualSurvivorOutlineTransparency end
            end
        end,
    })

    VisualsLeftGroup:AddInput("SurvivorFillTransparency", {
        Text = "Fill Transparency",
        Default = "0.85",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "0.85",
        Callback = function(Value)
            visualSurvivorFillTransparency = tonumber(Value) or 0.85
            for _, hl in pairs(survivorHighlights) do
                if hl then hl.FillTransparency = visualSurvivorFillTransparency end
            end
        end
    })

    VisualsLeftGroup:AddDivider()

    VisualsLeftGroup:AddToggle("ItemsHighlight", {
        Text = "Item Visuals",
        Tooltip = "Highlight and outline dropped items (Medkits, Cola).",
        Default = false,
        Callback = function(Value)
            visualItemsHighlightEnabled = Value
        end,
    }):AddColorPicker("ItemsHighlightColor", {
        Default = Color3.fromRGB(255, 255, 0),
        Title = "Item Accent Color",
        Callback = function(Value)
            itemsHighlightColor = Value
        end
    })

    VisualsLeftGroup:AddInput("ItemsOutlineTransparency", {
        Text = "Outline Transparency",
        Default = "0.5",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "0.5",
        Callback = function(Value)
            visualItemsOutlineTransparency = tonumber(Value) or 0.5
            for _, hl in pairs(itemHighlights) do
                if hl then hl.OutlineTransparency = visualItemsOutlineTransparency end
            end
        end,
    })

    VisualsLeftGroup:AddInput("ItemsFillTransparency", {
        Text = "Fill Transparency",
        Default = "0.85",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "0.85",
        Callback = function(Value)
            visualItemsFillTransparency = tonumber(Value) or 0.85
            for _, hl in pairs(itemHighlights) do
                if hl then hl.FillTransparency = visualItemsFillTransparency end
            end
        end
    })

    VisualsLeftGroup:AddDivider()

    VisualsLeftGroup:AddToggle("GeneratorsHighlight", {
        Text = "Generator Visuals",
        Tooltip = "Highlight and outline generator objectives.",
        Default = false,
        Callback = function(Value)
            visualGeneratorsHighlightEnabled = Value
        end,
    }):AddColorPicker("GeneratorsHighlightColor", {
        Default = Color3.fromRGB(0, 255, 255),
        Title = "Generator Accent Color",
        Callback = function(Value)
            generatorsHighlightColor = Value
        end
    })

    VisualsLeftGroup:AddToggle("ShowGenPercentage", {
        Text = "Progress HUD Label",
        Tooltip = "Displays floating progress percentage labels above generators.",
        Default = false,
        Callback = function(Value)
            visualGeneratorsShowPercentageEnabled = Value
        end,
    })

    VisualsLeftGroup:AddInput("GeneratorsOutlineTransparency", {
        Text = "Outline Transparency",
        Default = "0.5",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "0.5",
        Callback = function(Value)
            visualGeneratorsOutlineTransparency = tonumber(Value) or 0.5
            for _, hl in pairs(generatorHighlights) do
                if hl then hl.OutlineTransparency = visualGeneratorsOutlineTransparency end
            end
        end,
    })

    VisualsLeftGroup:AddInput("GeneratorsFillTransparency", {
        Text = "Fill Transparency",
        Default = "0.85",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "0.85",
        Callback = function(Value)
            visualGeneratorsFillTransparency = tonumber(Value) or 0.85
            for _, hl in pairs(generatorHighlights) do
                if hl then hl.FillTransparency = visualGeneratorsFillTransparency end
            end
        end
    })

    VisualsLeftGroup:AddDivider()

    VisualsLeftGroup:AddToggle("TrapsHighlight", {
        Text = "Trap Visuals",
        Tooltip = "Highlight and outline traps and deployables.",
        Default = false,
        Callback = function(Value)
            visualTrapsHighlightEnabled = Value
        end,
    }):AddColorPicker("TrapsHighlightColor", {
        Default = Color3.fromRGB(255, 100, 0),
        Title = "Trap Accent Color",
        Callback = function(Value)
            trapsHighlightColor = Value
        end
    })

    VisualsLeftGroup:AddDropdown("TrapFilter", {
        Values = { "Tripwires", "Subspace Tripmine", "Digital Footprints", "Seekers", "Lightbulbs", "Stigmatize" },
        Default = { "Tripwires", "Subspace Tripmine", "Digital Footprints", "Seekers", "Lightbulbs", "Stigmatize" },
        Multi = true,
        Text = "Targeted Trap Types",
        Tooltip = "Select which trap types to target and highlight.",
    })

    VisualsLeftGroup:AddInput("TrapsOutlineTransparency", {
        Text = "Outline Transparency",
        Default = "0.5",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "0.5",
        Callback = function(Value)
            visualTrapsOutlineTransparency = tonumber(Value) or 0.5
            for _, hl in pairs(trapHighlights) do
                if hl then hl.OutlineTransparency = visualTrapsOutlineTransparency end
            end
        end,
    })

    VisualsLeftGroup:AddInput("TrapsFillTransparency", {
        Text = "Fill Transparency",
        Default = "0.85",
        Numeric = true,
        ClearTextOnFocus = false,
        Placeholder = "0.85",
        Callback = function(Value)
            visualTrapsFillTransparency = tonumber(Value) or 0.85
            for _, hl in pairs(trapHighlights) do
                if hl then hl.FillTransparency = visualTrapsFillTransparency end
            end
        end
    })

    VisualsLeftGroup:AddDivider()

    VisualsLeftGroup:AddToggle("FullBrightToggle", {
        Text = "Full Brightness",
        Tooltip = "Overrides environment lighting for full map visibility.",
        Default = false,
        Callback = function(Value)
            fullBrightEnabled = Value
            pcall(applyFullBright)
        end,
    })

    Options = Library.Options
    Toggles = Library.Toggles

    ui_refs.Library = Library
    ui_refs.Window = Window
    ui_refs.Options = Options
    ui_refs.Toggles = Toggles

    local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Interface Preferences", "wrench")
    local ThemeCustomGroup = Tabs["UI Settings"]:AddRightGroupbox("Custom UI & HUD Theme Colors")

    ThemeCustomGroup:AddLabel("Watermark Accent Color"):AddColorPicker("WatermarkAccentColor", {
        Default = HUDColors.WatermarkAccent,
        Title = "Watermark Accent Color",
        Callback = function(Value)
            HUDColors.WatermarkAccent = Value
            if HUDRefs.WMAccent then HUDRefs.WMAccent.BackgroundColor3 = Value end
        end
    })

    ThemeCustomGroup:AddLabel("HUD Outline Color"):AddColorPicker("HUDOutlineColor", {
        Default = HUDColors.HUDOutline,
        Title = "HUD Outline Color",
        Callback = function(Value)
            HUDColors.HUDOutline = Value
            if HUDRefs.WMStroke then HUDRefs.WMStroke.Color = Value end
            if HUDRefs.TargetStroke then HUDRefs.TargetStroke.Color = Value end
        end
    })

    ThemeCustomGroup:AddLabel("HUD Font / Text Color"):AddColorPicker("HUDTextColor", {
        Default = HUDColors.HUDTextColor,
        Title = "HUD Font / Text Color",
        Callback = function(Value)
            HUDColors.HUDTextColor = Value
            if HUDRefs.WMLabel then HUDRefs.WMLabel.TextColor3 = Value end
            if HUDRefs.TargetInfo then HUDRefs.TargetInfo.TextColor3 = Value end
        end
    })

    ThemeCustomGroup:AddLabel("HUD Background Color"):AddColorPicker("HUDBackgroundColor", {
        Default = HUDColors.HUDBackground,
        Title = "HUD Background Color",
        Callback = function(Value)
            HUDColors.HUDBackground = Value
            if HUDRefs.WatermarkFrame then HUDRefs.WatermarkFrame.BackgroundColor3 = Value end
            if HUDRefs.TargetHUD then HUDRefs.TargetHUD.BackgroundColor3 = Value end
        end
    })

    ThemeCustomGroup:AddLabel("Target HUD Accent Color"):AddColorPicker("TargetHUDAccentColor", {
        Default = HUDColors.TargetHUDAccent,
        Title = "Target HUD Accent Color",
        Callback = function(Value)
            HUDColors.TargetHUDAccent = Value
            if HUDRefs.TargetTitle then HUDRefs.TargetTitle.TextColor3 = Value end
        end
    })

    ThemeCustomGroup:AddLabel("Visualizer Range Color"):AddColorPicker("VisualizerColorPicker", {
        Default = HUDColors.VisualizerColor,
        Title = "Visualizer Range Color",
        Callback = function(Value)
            HUDColors.VisualizerColor = Value
            if autoM1Circle then autoM1Circle.Color3 = Value end
            if leftConeLine then leftConeLine.Color3 = Value end
            if rightConeLine then rightConeLine.Color3 = Value end
        end
    })

    MenuGroup:AddToggle("KeybindMenuOpen", {
        Default = Library.KeybindFrame.Visible,
        Text = "Keybind Overlay",
        Callback = function(value)
            Library.KeybindFrame.Visible = value
        end,
    })
    MenuGroup:AddToggle("ShowCustomCursor", {
        Text = "Custom Crosshair Cursor",
        Default = true,
        Callback = function(Value)
            Library.ShowCustomCursor = Value
        end,
    })
    MenuGroup:AddDropdown("NotificationSide", {
        Values = { "Left", "Right" },
        Default = "Right",
        Text = "Notification Screen Placement",
        Callback = function(Value)
            pcall(function() Library:SetNotifySide(Value) end)
        end,
    })
    MenuGroup:AddDropdown("DPIDropdown", {
        Values = { "75%" },
        Default = "75%",
        Text = "UI Scale (DPI)",
        Callback = function(Value)
            pcall(function() Library:SetDPIScale(75) end)
        end,
    })

    MenuGroup:AddSlider("GuiCornerRadius", {
        Text = "Corner Roundness",
        Default = 8,
        Min = 0,
        Max = 20,
        Rounding = 0,
        Tooltip = "Adjust GUI corner roundness.",
        Callback = function(Value)
            guiCornerRadius = tonumber(Value) or 8
            pcall(updateGuiCorners, guiCornerRadius)
        end,
    })

    MenuGroup:AddDivider()
    MenuGroup:AddLabel("Toggle Menu Key"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu Keybind" })

    MenuGroup:AddButton("Unload Interface", function()
        isUnloaded = true
        disconnectCacheConnections()
        if cornerConnection then
            pcall(function() cornerConnection:Disconnect() end)
            cornerConnection = nil
        end
        if autoM1Connection then
            pcall(function() autoM1Connection:Disconnect() end)
            autoM1Connection = nil
        end
        if heartbeatAlignmentConnection then
            pcall(function() heartbeatAlignmentConnection:Disconnect() end)
            heartbeatAlignmentConnection = nil
        end
        if leftConeLine then pcall(function() leftConeLine:Destroy() end) end
        if rightConeLine then pcall(function() rightConeLine:Destroy() end) end
        if autoM1Circle then pcall(function() autoM1Circle:Destroy() end) end
        for _, hl in pairs(killerHighlights) do
            if hl then pcall(function() hl:Destroy() end) end
        end
        for _, hl in pairs(survivorHighlights) do
            if hl then pcall(function() hl:Destroy() end) end
        end
        for _, hl in pairs(itemHighlights) do
            if hl then pcall(function() hl:Destroy() end) end
        end
        for _, hl in pairs(generatorHighlights) do
            if hl then pcall(function() hl:Destroy() end) end
        end
        for _, hl in pairs(trapHighlights) do
            if hl then pcall(function() hl:Destroy() end) end
        end
        for _, gui in pairs(generatorPercentGuis) do
            if gui then pcall(function() gui:Destroy() end) end
        end
        table_clear(generatorPercentGuis)
        table_clear(trapHighlights)
        Library:Unload()
    end)

    _G.FreshLeavesSakenUI = _G.FreshLeavesSakenUI or {}
    _G.FreshLeavesSakenUI.refs = ui_refs

    Library.ToggleKeybind = Options.MenuKeybind
    
    if ThemeManager then
        pcall(function()
            ThemeManager:SetLibrary(Library)
            ThemeManager:SetFolder("FreshLeavesSaken")
            if Tabs and Tabs["UI Settings"] then
                ThemeManager:ApplyToTab(Tabs["UI Settings"])
            end
        end)
    end

    if SaveManager then
        pcall(function()
            SaveManager:SetLibrary(Library)
            SaveManager:IgnoreThemeSettings()
            SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
            SaveManager:SetFolder("FreshLeavesSaken/games")
            SaveManager:SetSubFolder("Forsaken")
            if Tabs and Tabs["UI Settings"] then
                SaveManager:BuildConfigSection(Tabs["UI Settings"])
            end
            SaveManager:LoadAutoloadConfig()
        end)
    end
    
    task.spawn(function()
        task.wait(0.5)
        pcall(updateGuiCorners, guiCornerRadius)
        pcall(function() Library:SetDPIScale(75) end)
    end)
end

heartbeatAlignmentConnection = RunService.Heartbeat:Connect(function(dt)
    if isUnloaded then return end
    
    if autoM1AimbotActive and autoM1AimbotTarget and autoM1AimbotTarget.Parent then
        local elapsed = os_clock() - autoM1AimbotStart
        local aimDur = autoM1AimDuration
        
        if elapsed >= aimDur or not inMatch() then
            autoM1AimbotActive = false
            autoM1AimbotTarget = nil
            local _, humanoid, _ = getCharacterInfo()
            if humanoid then
                pcall(function() humanoid.AutoRotate = true end)
            end
            return
        end
        
        local char, humanoid, hrp = getCharacterInfo()
        local khrp = autoM1AimbotTarget:FindFirstChild("HumanoidRootPart")
        if hrp and khrp then
            local predictedKPos = khrp.Position
            if autoM1MaxPrediction > 0 then
                local vel = khrp.AssemblyLinearVelocity or khrp.Velocity
                if vel and vel.Magnitude > 0.1 then
                    predictedKPos = khrp.Position + (vel * autoM1MaxPrediction)
                end
            end
            
            local targetLook = vector3_new(predictedKPos.X, hrp.Position.Y, predictedKPos.Z)
            if (targetLook - hrp.Position).Magnitude > 0.001 then
                local targetRotation = cframe_lookAt(hrp.Position, targetLook) - hrp.Position
                local alpha = (autoM1AimSpeed >= 50) and 1 or (1 - math.exp(-autoM1AimSpeed * dt))
                hrp.CFrame = hrp.CFrame:Lerp(cframe_new(hrp.Position) * targetRotation, alpha)
            end
        end
    end

    if projectileAimbotActive then
        if not inMatch() then
            projectileAimbotActive = false
            projectileAimbotTarget = nil
            currentActiveSkill = nil
            local _, humanoid, _ = getCharacterInfo()
            if humanoid then pcall(function() humanoid.AutoRotate = true end) end
        else
            local config = skillConfigs[currentActiveSkill] or { duration = 0.65, speed = 35, prediction = 0.2 }
            local elapsed = os_clock() - projectileAimStartTime
            local aimDur = config.duration
            
            if not projectileAimbotTarget or not projectileAimbotTarget.Parent then
                projectileAimbotTarget = getProjectileTarget()
            else
                local hum = projectileAimbotTarget:FindFirstChildWhichIsA("Humanoid")
                if not hum or hum.Health <= 0 then
                    projectileAimbotTarget = getProjectileTarget()
                end
            end

            if elapsed >= aimDur or not projectileAimbotTarget then
                projectileAimbotActive = false
                projectileAimbotTarget = nil
                currentActiveSkill = nil
                local _, humanoid, _ = getCharacterInfo()
                if humanoid then
                    pcall(function() humanoid.AutoRotate = true end)
                end
            else
                local char, humanoid, hrp = getCharacterInfo()
                if humanoid then
                    pcall(function() humanoid.AutoRotate = false end)
                end
                
                local thrp = projectileAimbotTarget:FindFirstChild("HumanoidRootPart")
                if hrp and thrp then
                    local predictedPos = thrp.Position
                    local useVelocity = Toggles and Toggles.ProjectileVelocityPrediction and Toggles.ProjectileVelocityPrediction.Value
                    
                    if useVelocity then
                        local vel = thrp.AssemblyLinearVelocity or thrp.Velocity
                        if vel and vel.Magnitude > 0.05 then
                            local distance = (thrp.Position - hrp.Position).Magnitude
                            local projSpeed = config.speed or 35
                            local travelTime = distance / (projSpeed > 0 and projSpeed or 35)
                            local predScale = config.prediction or 1.0
                            local predTime = travelTime * predScale
                            predictedPos = thrp.Position + (vel * predTime)
                        end
                    end
                    
                    local targetLook = vector3_new(predictedPos.X, hrp.Position.Y, predictedPos.Z)
                    if (targetLook - hrp.Position).Magnitude > 0.001 then
                        local targetRotation = cframe_lookAt(hrp.Position, targetLook) - hrp.Position
                        local aimSpeed = config.speed or 35
                        local alpha = (aimSpeed >= 100) and 1 or (1 - math.exp(-aimSpeed * dt))
                        hrp.CFrame = hrp.CFrame:Lerp(cframe_new(hrp.Position) * targetRotation, alpha)
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.02)
        if isUnloaded then break end
        if not Toggles or not Toggles.ProjectileAimEnabled or not Toggles.ProjectileAimEnabled.Value then continue end
        
        pcall(function()
            updateTrackedAbilityHooks()
            local btns = getTrackedAbilityButtons()
            for tName, btn in pairs(btns) do
                local cdObj = getButtonCooldown(btn)
                if cdObj then
                    local cdVal = readCooldownValue(cdObj) or 0
                    local prevState = previousCooldownStates[btn] or 0
                    
                    if (cdVal - prevState) > 1 then
                        local skillName = trackedProjectiles[tName]
                        triggerProjectileAim(skillName)
                    end
                    previousCooldownStates[btn] = cdVal
                else
                    previousCooldownStates[btn] = 0
                end
            end
        end)
    end
end)

autoM1Connection = RunService.Heartbeat:Connect(function()
    if isUnloaded then
        if autoM1Connection then
            pcall(function() autoM1Connection:Disconnect() end)
            autoM1Connection = nil
        end
        return
    end

    if autoM1AimbotActive or projectileAimbotActive then return end

    if not autoM1Enabled then return end
    if isM1OnCooldownCached() then return end
    if not inMatch() then return end
    if checkHelplessStatus() then return end

    local m1Btn = getM1Button()
    if m1Btn then
        local char, humanoid, hrp = getCharacterInfo()
        if hrp and humanoid then
            local survivors = getSurvivorsList()
            for _, survivor in pairs(survivors) do
                if isValidSurvivor(survivor) then
                    local khrp = survivor:FindFirstChild("HumanoidRootPart")
                    if khrp then
                        local dist = (khrp.Position - hrp.Position).Magnitude
                        if dist <= autoM1Range then
                            local relative = khrp.Position - hrp.Position
                            local rel2d = vector3_new(relative.X, 0, relative.Z)
                            local frontVec = hrp.CFrame.LookVector
                            local front2d = vector3_new(frontVec.X, 0, frontVec.Z)
                            local passesCone = false

                            if rel2d.Magnitude > 0.001 and front2d.Magnitude > 0.001 then
                                local dot = rel2d.Unit:Dot(front2d.Unit)
                                local angleRad = math.acos(math_clamp(dot, -1, 1))
                                local angleDeg = math_deg(angleRad)
                                if angleDeg <= (autoM1ConeAngle or 90) then
                                    passesCone = true
                                end
                            end

                            if passesCone then
                                triggerAutoM1Aimbot(survivor)
                                tryActivateButton(m1Btn)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end)

local function renderVisualizers()
    if isUnloaded then return end
    
    local char, _, hrp = getCharacterInfo()
    local active = autoM1Enabled and autoM1VisualizerEnabled and inMatch() and hrp
    
    if active then
        if not autoM1Circle then
            autoM1Circle = Instance.new("CylinderHandleAdornment")
            autoM1Circle.Height = 0.02
            autoM1Circle.Color3 = HUDColors.VisualizerColor
            autoM1Circle.Transparency = 0.55
            autoM1Circle.ZIndex = 10
            autoM1Circle.AlwaysOnTop = true
            autoM1Circle.Parent = Workspace:FindFirstChild("Terrain") or Workspace
        end
        autoM1Circle.Adornee = hrp
        autoM1Circle.Radius = autoM1Range
        autoM1Circle.Color3 = HUDColors.VisualizerColor
        autoM1Circle.CFrame = cframe_new(0, -hrp.Size.Y/2, 0) * CFrame.Angles(math_rad(90), 0, 0)
        autoM1Circle.Visible = true

        if not leftConeLine then
            leftConeLine = Instance.new("LineHandleAdornment")
            leftConeLine.Color3 = HUDColors.VisualizerColor
            leftConeLine.Thickness = 3
            leftConeLine.ZIndex = 10
            leftConeLine.AlwaysOnTop = true
            leftConeLine.Parent = Workspace:FindFirstChild("Terrain") or Workspace
        end
        leftConeLine.Adornee = hrp
        leftConeLine.Length = autoM1Range
        leftConeLine.Color3 = HUDColors.VisualizerColor
        leftConeLine.CFrame = CFrame.Angles(0, math_rad(180 + autoM1ConeAngle / 2), 0)
        leftConeLine.Visible = true

        if not rightConeLine then
            rightConeLine = Instance.new("LineHandleAdornment")
            rightConeLine.Color3 = HUDColors.VisualizerColor
            rightConeLine.Thickness = 3
            rightConeLine.ZIndex = 10
            rightConeLine.AlwaysOnTop = true
            rightConeLine.Parent = Workspace:FindFirstChild("Terrain") or Workspace
        end
        rightConeLine.Adornee = hrp
        rightConeLine.Length = autoM1Range
        rightConeLine.Color3 = HUDColors.VisualizerColor
        rightConeLine.CFrame = CFrame.Angles(0, math_rad(180 - autoM1ConeAngle / 2), 0)
        rightConeLine.Visible = true
    else
        if autoM1Circle then autoM1Circle.Visible = false end
        if leftConeLine then leftConeLine.Visible = false end
        if rightConeLine then rightConeLine.Visible = false end
    end
end

RunService.RenderStepped:Connect(renderVisualizers)

local function clearKillerHighlights()
    for model, hl in pairs(killerHighlights) do
        if hl then pcall(function() hl:Destroy() end) end
    end
    table_clear(killerHighlights)
end

local function clearSurvivorHighlights()
    for model, hl in pairs(survivorHighlights) do
        if hl then pcall(function() hl:Destroy() end) end
    end
    table_clear(survivorHighlights)
end

local function clearItemHighlights()
    for model, hl in pairs(itemHighlights) do
        if hl then pcall(function() hl:Destroy() end) end
    end
    table_clear(itemHighlights)
end

local function clearGeneratorHighlights()
    for model, hl in pairs(generatorHighlights) do
        if hl then pcall(function() hl:Destroy() end) end
    end
    table_clear(generatorHighlights)
end

local function clearTrapHighlights()
    for model, hl in pairs(trapHighlights) do
        if hl then pcall(function() hl:Destroy() end) end
    end
    table_clear(trapHighlights)
end

local function clearGeneratorPercentGuis()
    for model, gui in pairs(generatorPercentGuis) do
        if gui then pcall(function() gui:Destroy() end) end
    end
    table_clear(generatorPercentGuis)
end

local function updateKillerHighlights()
    if not visualKillerHighlightEnabled then
        clearKillerHighlights()
        return
    end

    local killers = getKillersList()
    for _, killer in ipairs(killers) do
        if isValidKillerModel(killer) then
            local hl = killerHighlights[killer]
            if not hl or not hl.Parent then
                hl = Instance.new("Highlight")
                hl.OutlineColor = killerHighlightColor
                hl.OutlineTransparency = visualKillerOutlineTransparency
                hl.FillColor = killerHighlightColor
                hl.FillTransparency = visualKillerFillTransparency
                hl.Adornee = killer
                hl.Parent = killer
                killerHighlights[killer] = hl
            else
                hl.OutlineColor = killerHighlightColor
                hl.FillColor = killerHighlightColor
                hl.OutlineTransparency = visualKillerOutlineTransparency
                hl.FillTransparency = visualKillerFillTransparency
            end
        end
    end

    for model, hl in pairs(killerHighlights) do
        if not model or not model.Parent or not table_find(killers, model) or not isValidKillerModel(model) then
            if hl then pcall(function() hl:Destroy() end) end
            killerHighlights[model] = nil
        end
    end
end

local function updateSurvivorHighlights()
    if not visualSurvivorHighlightEnabled then
        clearSurvivorHighlights()
        return
    end

    local survivors = getSurvivorsList()
    for _, survivor in ipairs(survivors) do
        if isValidSurvivor(survivor) then
            local hl = survivorHighlights[survivor]
            if not hl or not hl.Parent then
                hl = Instance.new("Highlight")
                hl.OutlineColor = survivorHighlightColor
                hl.OutlineTransparency = visualSurvivorOutlineTransparency
                hl.FillColor = survivorHighlightColor
                hl.FillTransparency = visualSurvivorFillTransparency
                hl.Adornee = survivor
                hl.Parent = survivor
                survivorHighlights[survivor] = hl
            else
                hl.OutlineColor = survivorHighlightColor
                hl.FillColor = survivorHighlightColor
                hl.OutlineTransparency = visualSurvivorOutlineTransparency
                hl.FillTransparency = visualSurvivorFillTransparency
            end
        end
    end

    for model, hl in pairs(survivorHighlights) do
        if not model or not model.Parent or not table_find(survivors, model) or not isValidSurvivor(model) then
            if hl then pcall(function() hl:Destroy() end) end
            survivorHighlights[model] = nil
        end
    end
end

local function updateItemHighlights()
    if not visualItemsHighlightEnabled then
        clearItemHighlights()
        return
    end

    local items = getItemsList()
    for _, item in ipairs(items) do
        if not isItemEquipped(item) then
            local hl = itemHighlights[item]
            if not hl or not hl.Parent then
                hl = Instance.new("Highlight")
                hl.OutlineColor = itemsHighlightColor
                hl.OutlineTransparency = visualItemsOutlineTransparency
                hl.FillColor = itemsHighlightColor
                hl.FillTransparency = visualItemsFillTransparency
                hl.Adornee = item
                hl.Parent = item
                itemHighlights[item] = hl
            else
                hl.OutlineColor = itemsHighlightColor
                hl.FillColor = itemsHighlightColor
                hl.OutlineTransparency = visualItemsOutlineTransparency
                hl.FillTransparency = visualItemsFillTransparency
            end
        else
            local hl = itemHighlights[item]
            if hl then
                pcall(function() hl:Destroy() end)
                itemHighlights[item] = nil
            end
        end
    end

    for model, hl in pairs(itemHighlights) do
        if not model or not model.Parent or not table_find(items, model) or isItemEquipped(model) then
            if hl then pcall(function() hl:Destroy() end) end
            itemHighlights[model] = nil
        end
    end
end

local function updateGeneratorHighlights()
    if not visualGeneratorsHighlightEnabled then
        clearGeneratorHighlights()
        return
    end

    local generators = getGeneratorsList()
    for _, generator in ipairs(generators) do
        local hl = generatorHighlights[generator]
        if not hl or not hl.Parent then
            hl = Instance.new("Highlight")
            hl.OutlineColor = generatorsHighlightColor
            hl.OutlineTransparency = visualGeneratorsOutlineTransparency
            hl.FillColor = generatorsHighlightColor
            hl.FillTransparency = visualGeneratorsFillTransparency
            hl.Adornee = generator
            hl.Parent = generator
            generatorHighlights[generator] = hl
        else
            hl.OutlineColor = generatorsHighlightColor
            hl.FillColor = generatorsHighlightColor
            hl.OutlineTransparency = visualGeneratorsOutlineTransparency
            hl.FillTransparency = visualGeneratorsFillTransparency
        end
    end

    for model, hl in pairs(generatorHighlights) do
        if not model or not model.Parent or not table_find(generators, model) then
            if hl then pcall(function() hl:Destroy() end) end
            generatorHighlights[model] = nil
        end
    end
end

local function updateTrapHighlights()
    if not visualTrapsHighlightEnabled then
        clearTrapHighlights()
        return
    end

    local traps = getTrapsList()
    for _, trap in ipairs(traps) do
        if isTrapValid(trap) then
            local hl = trapHighlights[trap]
            if not hl or not hl.Parent then
                hl = Instance.new("Highlight")
                hl.OutlineColor = trapsHighlightColor
                hl.OutlineTransparency = visualTrapsOutlineTransparency
                hl.FillColor = trapsHighlightColor
                hl.FillTransparency = visualTrapsFillTransparency
                hl.Adornee = trap
                hl.Parent = trap
                trapHighlights[trap] = hl
            else
                hl.OutlineColor = trapsHighlightColor
                hl.FillColor = trapsHighlightColor
                hl.OutlineTransparency = visualTrapsOutlineTransparency
                hl.FillTransparency = visualTrapsFillTransparency
            end
        else
            local hl = trapHighlights[trap]
            if hl then
                pcall(function() hl:Destroy() end)
                trapHighlights[trap] = nil
            end
        end
    end

    for model, hl in pairs(trapHighlights) do
        if not model or not model.Parent or not table_find(traps, model) or not isTrapValid(model) then
            if hl then pcall(function() hl:Destroy() end) end
            trapHighlights[model] = nil
        end
    end
end

local function updateGeneratorPercentGuis()
    if not visualGeneratorsHighlightEnabled or not visualGeneratorsShowPercentageEnabled then
        clearGeneratorPercentGuis()
        return
    end

    local generators = getGeneratorsList()
    for _, generator in ipairs(generators) do
        if generator and generator.Parent then
            local primaryPart = generator.PrimaryPart or generator:FindFirstChildWhichIsA("BasePart")
            if primaryPart then
                local gui = generatorPercentGuis[generator]
                if not gui or not gui.Parent then
                    gui = Instance.new("BillboardGui")
                    gui.Name = "GeneratorPercentGui"
                    gui.Size = UDim2.new(0, 100, 0, 30)
                    gui.AlwaysOnTop = true
                    gui.StudsOffset = Vector3.new(0, 4, 0)
                    
                    local label = Instance.new("TextLabel")
                    label.Name = "PercentLabel"
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.TextColor3 = generatorsHighlightColor
                    label.TextSize = 14
                    label.Font = Enum.Font.SourceSansBold
                    label.TextStrokeTransparency = 0
                    label.TextStrokeColor3 = Color3.new(0, 0, 0)
                    label.Parent = gui
                    
                    gui.Adornee = primaryPart
                    gui.Parent = generator
                    generatorPercentGuis[generator] = gui
                end
                
                local pct = math.floor(getGeneratorProgress(generator))
                local label = gui:FindFirstChild("PercentLabel")
                if label then
                    label.Text = string.format("%d%%", pct)
                    label.TextColor3 = generatorsHighlightColor
                end
            end
        end
    end

    for model, gui in pairs(generatorPercentGuis) do
        if not model or not model.Parent or not table_find(generators, model) then
            if gui then pcall(function() gui:Destroy() end) end
            generatorPercentGuis[model] = nil
        end
    end
end

pcall(initialCacheScan)
pcall(setupCacheListeners)

task.spawn(function()
    while true do
        task.wait(0.2)
        if isUnloaded then
            clearKillerHighlights()
            clearSurvivorHighlights()
            clearItemHighlights()
            clearGeneratorHighlights()
            clearGeneratorPercentGuis()
            clearTrapHighlights()
            break
        end
        pcall(updateKillerHighlights)
        pcall(updateSurvivorHighlights)
        pcall(updateItemHighlights)
        pcall(updateGeneratorHighlights)
        pcall(updateGeneratorPercentGuis)
        pcall(updateTrapHighlights)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if isUnloaded then break end
        if staminaEnabled and inMatch() then
            pcall(function()
                local stamina = getSprintingModule()
                if stamina then
                    applyCustomStats(stamina)
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if isUnloaded then break end
        if fullBrightEnabled then
            pcall(applyFullBright)
        end
    end
end)
