local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1529051893630767214/v6ipEYXDALSRIbIoLGS04Pn2CKXnE-8Sc7ggFo6-m8kyS8MITbpQk2t50iCHBxZ22aaj"
local PERM_KEY_WEBHOOK = "https://discord.com/api/webhooks/1530903766881013810/LcD_x44t32KUzUmM2RbVBVPxrOcE0mOtq8o7JHqN9kqZek8i76nzDiHOfFyZZpU-LUUV"
local DISCORD_INVITE = "https://discord.gg/CYAmmsuRa"
local KEY_SALT = "FLS_SECURE_SALT_2026"             -- Change this to change the key pool
local KEY_SAVE_FILE = "FLS_Permanent_Key.txt"

-- =================================================================
-- DETERMINISTIC DAILY & PRIVATE PERMANENT KEY GENERATION
-- =================================================================
-- Generates a daily key that changes automatically every 24 hours (UTC)
local function getDailyKey()
    local dateString = os.date("!%Y%m%d") -- Formats date as YYYYMMDD
    local combined = dateString .. KEY_SALT
    local num = 0
    for i = 1, #combined do
        num = (num + string.byte(combined, i) * i) % 999983
    end
    return "FLS-" .. tostring(num) .. "-K3Y"
end

local expectedKey = getDailyKey()

-- Generates 100 un-guessable secure private permanent keys
local function generatePermanentKeys()
    local keys = {}
    local orderedKeys = {}
    for i = 1, 100 do
        local seedStr = "SECRET_PERM_" .. tostring(i) .. "_" .. KEY_SALT .. "_CONFIDENTIAL"
        local num = 5381
        for j = 1, #seedStr do
            num = (num * 33 + string.byte(seedStr, j)) % 4294967296
        end
        local keyStr = string.format("FLS-PERM-%d-%08X", i, num)
        keys[keyStr] = true
        table.insert(orderedKeys, keyStr)
    end
    return keys, orderedKeys
end

local permanentKeysList, orderedPermKeys = generatePermanentKeys()

local function isPermanentKey(key)
    return permanentKeysList[key] == true
end

-- =================================================================
-- DISCORD NOTIFICATION SENDER (WITH MASTER KEY DISPATCH)
-- =================================================================
local function sendKeyToDiscord(key, isRequested)
    if DISCORD_WEBHOOK == "" then
        warn("[FLS Key System] Discord Webhook URL is empty.")
        return
    end

    local httpRequest = request or (http and http.request) or (syn and syn.request)
    if httpRequest then
        task.spawn(function()
            pcall(function()
                local response = httpRequest({
                    Url = DISCORD_WEBHOOK .. "?wait=true",
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json"
                    },
                    Body = game:GetService("HttpService"):JSONEncode({
                        username = "FreshLeavesSaken [FLS] Key Bot",
                        embeds = {{
                            title = isRequested and "[🔑]-FLS Key Requested!" or "[🔑]-New Daily Key!",
                            description = "FreshLeavesSaken Key System active! This message will self-destruct in 30 seconds.",
                            fields = {
                                { name = "Current Active Daily Key", value = "`" .. key .. "`", inline = false },
                                { name = "Rotation Schedule", value = "Changes every 24 hours at 00:00 UTC", inline = true },
                                { name = "System Date (UTC)", value = os.date("!%Y-%m-%d"), inline = true }
                            },
                            color = 5814783 -- Obsidian Slate Blue
                        }}
                    })
                })

                if response and response.Body then
                    local success, data = pcall(function()
                        return game:GetService("HttpService"):JSONEncode(response.Body)
                    end)

                    if success and data and data.id then
                        task.wait(30)
                        httpRequest({
                            Url = DISCORD_WEBHOOK .. "/messages/" .. tostring(data.id),
                            Method = "DELETE"
                        })
                    end
                end
            end)
        end)
    end
end

-- Sends the Master List of 100 Private Permanent Keys to the Dedicated Permanent Key Webhook Channel
local masterKeysSent = false
local function sendMasterPermKeysToWebhook()
    if masterKeysSent or PERM_KEY_WEBHOOK == "" then return end
    masterKeysSent = true

    local httpRequest = request or (http and http.request) or (syn and syn.request)
    if not httpRequest then return end

    task.spawn(function()
        pcall(function()
            -- Split 100 keys into 4 embed chunks (25 keys per embed) for Discord character limits
            for chunk = 1, 4 do
                local keyChunkList = {}
                local startIdx = (chunk - 1) * 25 + 1
                local endIdx = chunk * 25

                for i = startIdx, endIdx do
                    if orderedPermKeys[i] then
                        table.insert(keyChunkList, string.format("`%s`", orderedPermKeys[i]))
                    end
                end

                local chunkText = table.concat(keyChunkList, "\n")
                httpRequest({
                    Url = PERM_KEY_WEBHOOK,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = game:GetService("HttpService"):JSONEncode({
                        username = "FLS Master Perm Key Vault",
                        embeds = {{
                            title = string.format("[🔒] PRIVATE PERMANENT KEYS (Batch %d/4)", chunk),
                            description = "Here are 25 of your 100 Private Permanent Keys. Give these to trusted VIP users.\n\n" .. chunkText,
                            color = 16766720 -- Gold
                        }}
                    })
                })
                task.wait(1)
            end
        end)
    end)
end

-- =================================================================
-- KEY SYSTEM USER INTERFACE (OBSIDIAN THEMED)
-- =================================================================
local function loadKeySystem(onSuccess)
    -- Check for saved permanent key file to bypass Key System
    if isfile and readfile and isfile(KEY_SAVE_FILE) then
        local savedKey = ""
        pcall(function() savedKey = readfile(KEY_SAVE_FILE):gsub("%s+", "") end)
        if isPermanentKey(savedKey) then
            print("[FLS Key System] Permanent Key verified from local file! Bypassing Key System.")
            onSuccess()
            return
        end
    end

    local Players = game:GetService("Players")
    local CoreGui = game:GetService("CoreGui")
    local LocalPlayer = Players.LocalPlayer
    
    -- Clean up any existing instances of the Key UI
    local existingUI = CoreGui:FindFirstChild("FLSKeySystemUI") or (LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("FLSKeySystemUI"))
    if existingUI then existingUI:Destroy() end

    -- Create ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FLSKeySystemUI"
    ScreenGui.ResetOnSpawn = false
    
    -- Parent to CoreGui if available, fallback to PlayerGui
    local successParent, _ = pcall(function() ScreenGui.Parent = CoreGui end)
    if not successParent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Main Container Frame (Obsidian Charcoal Styling)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 360, 0, 210)
    MainFrame.Position = UDim2.new(0.5, -180, 0.5, -105)
    MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(45, 45, 55)
    MainStroke.Thickness = 1.5
    MainStroke.Parent = MainFrame

    -- Header Bar
    local HeaderBar = Instance.new("Frame")
    HeaderBar.Name = "HeaderBar"
    HeaderBar.Size = UDim2.new(1, 0, 0, 40)
    HeaderBar.BackgroundColor3 = Color3.fromRGB(24, 24, 29)
    HeaderBar.BorderSizePixel = 0
    HeaderBar.Parent = MainFrame

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 8)
    HeaderCorner.Parent = HeaderBar

    -- Fix header bottom rounded corners visually
    local HeaderFix = Instance.new("Frame")
    HeaderFix.Size = UDim2.new(1, 0, 0, 10)
    HeaderFix.Position = UDim2.new(0, 0, 1, -10)
    HeaderFix.BackgroundColor3 = Color3.fromRGB(24, 24, 29)
    HeaderFix.BorderSizePixel = 0
    HeaderFix.Parent = HeaderBar

    -- Title Label
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Size = UDim2.new(1, -20, 1, 0)
    TitleLabel.Position = UDim2.new(0, 15, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "FreshLeavesSaken Key System"
    TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
    TitleLabel.TextSize = 14
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = HeaderBar

    -- Subtitle / Version Badge
    local BadgeLabel = Instance.new("TextLabel")
    BadgeLabel.Name = "BadgeLabel"
    BadgeLabel.Size = UDim2.new(0, 50, 0, 20)
    BadgeLabel.Position = UDim2.new(1, -60, 0.5, -10)
    BadgeLabel.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
    BadgeLabel.Text = "FLS v1.0"
    BadgeLabel.TextColor3 = Color3.fromRGB(114, 137, 218)
    BadgeLabel.TextSize = 10
    BadgeLabel.Font = Enum.Font.GothamBold
    BadgeLabel.Parent = HeaderBar

    local BadgeCorner = Instance.new("UICorner")
    BadgeCorner.CornerRadius = UDim.new(0, 4)
    BadgeCorner.Parent = BadgeLabel

    -- TextBox Input
    local KeyInput = Instance.new("TextBox")
    KeyInput.Name = "KeyInput"
    KeyInput.Size = UDim2.new(0, 320, 0, 38)
    KeyInput.Position = UDim2.new(0.5, -160, 0, 55)
    KeyInput.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    KeyInput.BorderSizePixel = 0
    KeyInput.Text = ""
    KeyInput.PlaceholderText = "Paste daily or permanent key here..."
    KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
    KeyInput.TextSize = 13
    KeyInput.Font = Enum.Font.Gotham
    KeyInput.Parent = MainFrame

    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 6)
    InputCorner.Parent = KeyInput

    local InputStroke = Instance.new("UIStroke")
    InputStroke.Color = Color3.fromRGB(42, 42, 52)
    InputStroke.Thickness = 1
    InputStroke.Parent = KeyInput

    -- Status Feedback Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Size = UDim2.new(1, -40, 0, 20)
    StatusLabel.Position = UDim2.new(0, 20, 0, 102)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Daily keys change every 24h. Permanent keys saved forever."
    StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
    StatusLabel.TextSize = 11
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Parent = MainFrame

    -- Button Container
    local GetKeyButton = Instance.new("TextButton")
    GetKeyButton.Name = "GetKeyButton"
    GetKeyButton.Size = UDim2.new(0, 155, 0, 36)
    GetKeyButton.Position = UDim2.new(0.5, -160, 0, 150)
    GetKeyButton.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    GetKeyButton.BorderSizePixel = 0
    GetKeyButton.Text = "Get Key"
    GetKeyButton.TextColor3 = Color3.fromRGB(220, 220, 230)
    GetKeyButton.TextSize = 13
    GetKeyButton.Font = Enum.Font.GothamBold
    GetKeyButton.Parent = MainFrame

    local GetKeyCorner = Instance.new("UICorner")
    GetKeyCorner.CornerRadius = UDim.new(0, 6)
    GetKeyCorner.Parent = GetKeyButton

    local GetKeyStroke = Instance.new("UIStroke")
    GetKeyStroke.Color = Color3.fromRGB(55, 55, 70)
    GetKeyStroke.Thickness = 1
    GetKeyStroke.Parent = GetKeyButton

    local SubmitButton = Instance.new("TextButton")
    SubmitButton.Name = "SubmitButton"
    SubmitButton.Size = UDim2.new(0, 155, 0, 36)
    SubmitButton.Position = UDim2.new(0.5, 5, 0, 150)
    SubmitButton.BackgroundColor3 = Color3.fromRGB(114, 137, 218) -- Obsidian / Discord Blue
    SubmitButton.BorderSizePixel = 0
    SubmitButton.Text = "Verify Key"
    SubmitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SubmitButton.TextSize = 13
    SubmitButton.Font = Enum.Font.GothamBold
    SubmitButton.Parent = MainFrame

    local SubmitCorner = Instance.new("UICorner")
    SubmitCorner.CornerRadius = UDim.new(0, 6)
    SubmitCorner.Parent = SubmitButton

    -- Event Connections
    GetKeyButton.MouseButton1Click:Connect(function()
        local setClipboard = setclipboard or writeclipboard or toclipboard or (Clipboard and Clipboard.set)
        if setClipboard then
            pcall(setClipboard, DISCORD_INVITE)
            StatusLabel.Text = "Copied Discord link & sent key to channel!"
            StatusLabel.TextColor3 = Color3.fromRGB(114, 137, 218)
        else
            StatusLabel.Text = "Key sent to FLS Discord channel!"
            StatusLabel.TextColor3 = Color3.fromRGB(114, 137, 218)
        end
        
        -- Send notification/key to Discord Webhook
        sendKeyToDiscord(expectedKey, true)
    end)

    SubmitButton.MouseButton1Click:Connect(function()
        local input = KeyInput.Text:gsub("%s+", "") -- Remove whitespace

        if isPermanentKey(input) then
            StatusLabel.Text = "Permanent Key Verified! Saved forever..."
            StatusLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
            if writefile then
                pcall(writefile, KEY_SAVE_FILE, input)
            end
            task.wait(1)
            ScreenGui:Destroy()
            onSuccess() -- Load original script
        elseif input == expectedKey then
            StatusLabel.Text = "Correct Daily Key! Loading FreshLeavesSaken..."
            StatusLabel.TextColor3 = Color3.fromRGB(85, 255, 85)
            task.wait(0.8)
            ScreenGui:Destroy()
            onSuccess() -- Load original script
        else
            StatusLabel.Text = "Invalid key. Click 'Get Key' for Discord!"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 85, 85)
        end
    end)
end

-- Dispatch initial key and private permanent master keys to Discord asynchronously
task.spawn(function()
    sendKeyToDiscord(expectedKey, false)
    sendMasterPermKeysToWebhook()
end)

-- =================================================================
-- WRAPPER EXECUTION GATEWAY
-- =================================================================
loadKeySystem(function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local ToggleService = game:GetService("TweenService") -- Match original structure
    local TweenService = game:GetService("TweenService")
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Lighting = game:GetService("Lighting")
    local HttpService = game:GetService("HttpService")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer

    -- Localized Globals for High-Frequency Optimization
    local table_clear = table.clear
    local table_find = table.find
    local table_insert = table.insert
    local math_min = math.min
    local math_clamp = math_clamp
    local math_deg = math_deg
    local math_rad = math_rad
    local os_clock = os.time
    local vector3_new = Vector3.new
    local cframe_new = CFrame.new
    local cframe_lookAt = CFrame.lookAt

    -- File-level scoping for Linoria UI components and services
    local Options, Toggles, Window, Library, ThemeManager, SaveManager
    local Tabs
    local killerHighlights = {}
    local survivorHighlights = {}
    local itemHighlights = {}
    local generatorHighlights = {}
    local trapHighlights = {}
    local generatorPercentGuis = {}

    -- VirtualInputManager setup
    local VirtualInputManager = nil
    pcall(function()
        VirtualInputManager = game:GetService("VirtualInputManager")
    end)

    -- Configurations
    local enabled = false

    -- AutoGen Configurations
    local autoGenEnabled = false
    local autoGenSpeed = 1.0
    local currentInteractingGen = nil
    local lastGenInteractionTime = 0

    -- Visual Configurations
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

    -- Auto M1 Configurations
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

    -- Projectile Aim Configurations
    local projectileAimbotActive = false
    local projectileAimbotTarget = nil
    local projectileAimStartTime = 0
    local previousCooldownStates = {}
    local currentActiveSkill = nil

    -- Strict Aimbot Target List
    local allowedSurvivorNames = {
        "guest1337", "guest 1337", "chance", "builderman", "veeronica", 
        "noob", "shedletsky", "twotime", "two time", "dusekkar", 
        "007n7", "oo7n7", "jane doe", "janedoe", "elliot"
    }

    -- Central skill configuration table mapped to individually serializable options
    local skillConfigs = {
        ["Mass Infection"] = {
            enabled = true,
            duration = 0.65,
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

    -- UI Styling Configurations
    local guiCornerRadius = 8
    local cornerConnection = nil

    -- Stamina Configurations
    local staminaEnabled = false
    local MAX_STAMINA = 100
    local MIN_STAMINA = -20
    local STAMINA_GAIN = 100
    local STAMINA_LOSS = 5
    local SPRINT_SPEED = 40
    local INF_STAMINA = true

    -- Full Bright Configurations
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

    -- Lobby Configurations
    local LOBBY_POSITION = vector3_new(0, 5, 0)
    local LOBBY_RADIUS = 220
    local isUnloaded = false
    local autoM1Connection = nil
    local heartbeatAlignmentConnection = nil

    -- High Efficiency Cache Tables
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

    local function isTrapValid(child)
        if child:IsA("Model") then
            local lowerName = child.Name:lower()
            if lowerName:find("footprint") or lowerName:find("digital") or 
               lowerName:find("tripwire") or lowerName:find("trip wire") or 
               lowerName:find("subspace") or lowerName:find("tripmine") or 
               lowerName:find("seeker") or lowerName:find("bulb") or 
               lowerName:find("stigmatize") then
                return true
            end
        elseif child:IsA("BasePart") then
            local parent = child.Parent
            if parent and parent:IsA("Model") then
                local parentName = parent.Name:lower()
                if parentName:find("footprint") or parentName:find("digital") or 
                   parentName:find("tripwire") or parentName:find("trip wire") or 
                   parentName:find("subspace") or parentName:find("tripmine") or 
                   parentName:find("seeker") or parentName:find("bulb") or 
                   parentName:find("stigmatize") then
                    return false -- Let parent model handle the outline
                end
            end
            local lowerName = child.Name:lower()
            if lowerName:find("footprint") or lowerName:find("digital") or 
               lowerName:find("tripwire") or lowerName:find("trip wire") or 
               lowerName:find("subspace") or lowerName:find("tripmine") or 
               lowerName:find("seeker") or lowerName:find("bulb") or 
               lowerName:find("stigmatize") then
                return true
            end
        end
        return false
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

    local function getCharacterInfo()
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

    -- Helper function to extract any name from button instance & internal visual labels
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
        
        -- Exclude complex utility and non-M1 abilities across all killer kits
        local blacklist = {
            "unstable", "eye", "eyes", "infection", "entanglement", "rejuvenate", "block", 
            "heal", "teleport", "ability", "skill", "shield", "dodge", "run", "dash",
            "behead", "gashing", "wound", "raging", "pace", "prankster", "void rush", "rush",
            "mass infection", "rejuvenate the rotten", "void", "nova", "observant", 
            "hallucination", "hallucinations", "blood hook", "bloodhook", "ascension", 
            "cataclysm", "hunter's feast", "hunters feast", "leap", "gaze", "corrupt", 
            "nature", "trap", "traps", "spike", "spikes", "corrupt energy", "pursuit", "infernal"
        }
        
        -- Target basic attack keywords
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
        
        -- Pass 1: Exact visual name target match
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
        
        -- Pass 2: Visual substring target match
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
        
        -- Pass 3: Hotkey checks (M1, LMB, Click)
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
        
        -- Pass 4: Fallback to the first non-blacklisted button
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
        
        -- Exclude NPCs
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
        
        -- Exclude NPCs
        if model:GetAttribute("NPC") == true or model:GetAttribute("IsNPC") == true then
            return false
        end

        -- Parent hierarchy check to filter out players in the killer directory
        if model.Parent and (model.Parent.Name == "Killers" or (model.Parent.Parent and model.Parent.Parent.Name == "Killers")) then
            return false
        end

        -- Explicit killer role markers
        local isKillerAttr = model:GetAttribute("Role") == "Killer" 
            or model:GetAttribute("role") == "Killer" 
            or model:GetAttribute("IsKiller") == true 
            or model:GetAttribute("isKiller") == true
        if isKillerAttr then
            return false
        end

        -- Comprehensive check against known killers to prevent green highlights on killers
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
            gui = game:GetService("CoreGui"):FindFirstChild("Obsidian") or game:GetService("CoreGui"):FindFirstChild("FreshLeavesSaken")
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

    -- ITEM CACHE SYSTEM: Event-driven updates
    local function getItemsList()
        return cachedItems
    end

    -- GENERATORS CACHE SYSTEM: Event-driven updates
    local function getGeneratorsList()
        return cachedGenerators
    end

    -- TRAPS CACHE SYSTEM: Event-driven updates
    local function getTrapsList()
        return cachedTraps
    end

    -- Helper to safely extract current generator progress percentage
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

    -- PROJECTILE AIM: Calculates dynamic target relative selection based on GUI Options
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
            -- Pick lowest health from players nearby (within 80 studs), fallback to closest overall
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
        if not inMatch() or projectileAimbotActive then return end
        
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

    -- PROJECTILE AIM: Dynamic hooks scanning for targeted projectile abilities
    local trackedProjectiles = {
        ["mass infection"] = "Mass Infection",
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
                        if name == tName or name:find(tName) then
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

    -- Hook input events for direct key triggers
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
        if not inMatch() or autoM1AimbotActive then return end
        
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

        local ok, conns = pcall(function()
            if type(getconnections) == "function" then
                local foundConns = {}
                local events = {btn.MouseButton1Click, btn.Activated}
                for _, event in ipairs(events) do
                    if event then
                        for _, conn in ipairs(getconnections(event)) do
                            table_insert(foundConns, conn)
                        end
                    end
                end
                return foundConns
            end
            return nil
        end)

        if ok and conns then
            for _, conn in ipairs(conns) do
                pcall(function()
                    if conn.Function then
                        conn.Function()
                        activated = true
                    elseif conn.func then
                        conn.func()
                        activated = true
                    elseif conn.Fire then
                        conn.Fire()
                        activated = true
                    end
                end)
            end
        end

        if not activated and VirtualInputManager then
            pcall(function()
                local absPos = btn.AbsolutePosition
                local absSize = btn.AbsoluteSize
                local clickX = absPos.X + (absSize.X / 2)
                local clickY = absPos.Y + (absSize.Y / 2) + 58
                
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

    -- Find the closest generator within range
    local function getClosestGenerator()
        local char, _, hrp = getCharacterInfo()
        if not hrp then return nil, math.huge end
        
        local closestGen = nil
        local minDistance = math.huge
        for _, gen in ipairs(cachedGenerators) do
            if gen and gen.Parent then
                local primaryPart = gen.PrimaryPart or gen:FindFirstChildWhichIsA("BasePart")
                if primaryPart then
                    local dist = (primaryPart.Position - hrp.Position).Magnitude
                    if dist < minDistance then
                        minDistance = dist
                        closestGen = gen
                    end
                end
            end
        end
        return closestGen, minDistance
    end

    -- Safe execution of AutoGen solver logic
    local function solveGenerator(obj)
        if obj and obj.Parent then
            local remotes = obj:FindFirstChild("Remotes")
            local re = remotes and remotes:FindFirstChild("RE")
            if re and re:IsA("RemoteEvent") then
                pcall(function() re:FireServer() end)
            end
        end
    end

    -- Safely applies custom stats to the retrieved Sprinting module
    local function applyCustomStats(stamina)
        if not stamina then return end
        stamina.MaxStamina = MAX_STAMINA
        stamina.MinStamina = MIN_STAMINA
        stamina.StaminaGain = STAMINA_GAIN
        stamina.StaminaLoss = STAMINA_LOSS
        stamina.SprintSpeed = SPRINT_SPEED
        stamina.StaminaLossDisabled = INF_STAMINA
    end

    -- Retrieves the Sprinting module dynamically via structural indexing or recursive search
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
        
        -- Recursive fallback search inside ReplicatedStorage
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
                print("[SCRIPT ALERT]: Survivor is now HELPLESS! Skills locked.")
                wasHelpless = true
            elseif not isHelpless and wasHelpless then
                print("[SCRIPT ALERT]: Helpless status cleared. Skills available.")
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
        warn("Obsidian library failed to load correctly: " .. tostring(loadError))
    end

    local ui_refs = {}

    if Library then
        Library.ForceCheckbox = false
        Library.ShowToggleFrameInKeybinds = true

        Window = Library:CreateWindow({
            Title = "FreshLeavesSaken [FLS] ⭐",
            Footer = "FreshLeavesSaken | Join the Discord! :D",
            NotifySide = "Right",
            ShowCustomCursor = true,
        })

        task.spawn(function()
            local titleLabel = nil
            for i = 1, 20 do
                if not Library.ScreenGui then task.wait(0.05) continue end
                for _, desc in ipairs(Library.ScreenGui:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Text == "FreshLeavesSaken [FLS] ⭐" then
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
                    local discordBtn = Instance.new("ImageButton")
                    discordBtn.Name = "DiscordTopRightButton"
                    discordBtn.BackgroundTransparency = 1
                    discordBtn.Image = "rbxassetid://15243171358"
                    discordBtn.ImageColor3 = Color3.fromRGB(114, 137, 218)
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

                    titleLabel.Size = UDim2.new(1, rightOffset - 15, 1, 0)
                    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd

                    discordBtn.MouseButton1Click:Connect(function()
                        local setClipboard = setclipboard or writeclipboard or toclipboard or (Clipboard and Clipboard.set)
                        if setClipboard then
                            pcall(setClipboard, DISCORD_INVITE)
                            notify("Discord Invite Copied", "Link copied to clipboard! Paste it into your browser.", 5)
                        else
                            notify("Discord Server Invite", DISCORD_INVITE, 10)
                        end
                    end)

                    discordBtn.MouseEnter:Connect(function()
                        discordBtn.ImageColor3 = Color3.fromRGB(140, 160, 255)
                    end)
                    discordBtn.MouseLeave:Connect(function()
                        discordBtn.ImageColor3 = Color3.fromRGB(114, 137, 218)
                    end)
                end
            end
        end)

        Tabs = {
            Combat = Window:AddTab("Combat", "swords"),
            Killer = Window:AddTab("Killer", "skull"),
            AutoGen = Window:AddTab("AutoGen", "cpu"),
            Visuals = Window:AddTab("Visuals", "eye"),
            Stamina = Window:AddTab("Stamina", "zap"),
            ["UI Settings"] = Window:AddTab("Settings", "settings"),
        }

        local CombatGroup = Tabs.Combat:AddLeftGroupbox("Combat Execution")
        local KillerGroup = Tabs.Killer:AddLeftGroupbox("Auto M1 Configuration")
        local ProjectileGroup = Tabs.Killer:AddRightGroupbox("Projectile Aim (CA-Aim)")
        local AutoGenGroup = Tabs.AutoGen:AddLeftGroupbox("Auto Generator Configuration")
        local VisualsLeftGroup = Tabs.Visuals:AddLeftGroupbox("Visual Configurations")
        local StaminaLeftGroup = Tabs.Stamina:AddLeftGroupbox("Stamina Configurations")

        CombatGroup:AddButton("Twotime", function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/xzshiroofficials-jpg/Secret/refs/heads/main/Twotime.lua"))()
        end)

        CombatGroup:AddButton("Shedletsky", function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/xzshiroofficials-jpg/Secret/refs/heads/main/Shedletsky.lua"))()
        end)

        CombatGroup:AddButton("Elliot", function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/xzshiroofficials-jpg/Secret/refs/heads/main/Elliot.lua"))()
        end)

        CombatGroup:AddButton("Chance", function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/xzshiroofficials-jpg/Secret/refs/heads/main/Chance.lua"))()
        end)

        CombatGroup:AddButton("JaneDoe", function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/xzshiroofficials-jpg/Secret/refs/heads/main/Janetoe.lua"))()
        end)

        KillerGroup:AddToggle("AutoM1Toggle", {
            Text = "Auto M1",
            Tooltip = "Automatically aligns and hits target survivors in front of you",
            Default = false,
            Callback = function(Value)
                autoM1Enabled = Value
            end,
        })

        KillerGroup:AddToggle("AutoM1VisualizerToggle", {
            Text = "Visualizer",
            Tooltip = "Toggles range circle and cone line visuals",
            Default = true,
            Callback = function(Value)
                autoM1VisualizerEnabled = Value
            end,
        })

        KillerGroup:AddSlider("AutoM1Range", {
            Text = "Range",
            Default = 5,
            Min = 1,
            Max = 20,
            Rounding = 1,
            Tooltip = "Maximum distance scanning survivors",
            Callback = function(Value)
                autoM1Range = tonumber(Value) or 5
            end,
        })

        KillerGroup:AddSlider("AutoM1ConeAngle", {
            Text = "Cone Angle",
            Default = 90,
            Min = 1,
            Max = 180,
            Rounding = 0,
            Suffix = "°",
            Tooltip = "Target scanning window constraint in front of you",
            Callback = function(Value)
                autoM1ConeAngle = tonumber(Value) or 90
            end,
        })

        KillerGroup:AddInput("AutoM1AimDuration", {
            Text = "Aimbot Duration",
            Default = "1.5",
            Numeric = true,
            ClearTextOnFocus = false,
            Placeholder = "e.g. 1.5",
            Callback = function(Value)
                autoM1AimDuration = tonumber(Value) or 1.5
            end,
        })

        KillerGroup:AddSlider("AutoM1MaxPrediction", {
            Text = "Max Prediction Limit",
            Default = 0.2,
            Min = 0,
            Max = 1,
            Rounding = 2,
            Suffix = "s",
            Tooltip = "Velocity tracking projection timeframe",
            Callback = function(Value)
                autoM1MaxPrediction = tonumber(Value) or 0.2
            end,
        })

        KillerGroup:AddSlider("AutoM1AimSpeed", {
            Text = "Aim Speed (Smoothing)",
            Default = 15,
            Min = 1,
            Max = 50,
            Rounding = 1,
            Tooltip = "Adjust rotation smoothing toward the target. 50 is instant snap.",
            Callback = function(Value)
                autoM1AimSpeed = tonumber(Value) or 15
            end,
        })

        -- Projectile Aim Configuration UI Setup
        ProjectileGroup:AddToggle("ProjectileAimEnabled", {
            Text = "Enable Projectile Aim",
            Tooltip = "Snaps body facing direction towards targeted entities when projectile abilities are triggered",
            Default = false,
        })

        ProjectileGroup:AddToggle("StrictAimbotOnly", {
            Text = "Strict Target List Only",
            Tooltip = "If enabled, only targets players whose character names match the restricted survivor list. If disabled, targets all valid survivors in the lobby.",
            Default = false,
        })

        ProjectileGroup:AddDropdown("ProjectileTargetMode", {
            Values = { "Nearest", "Lowest", "Nearest & Lowest" },
            Default = "Nearest",
            Text = "Target Priority",
            Tooltip = "Specific conditions evaluating targeted entities",
        })

        ProjectileGroup:AddToggle("ProjectileVelocityPrediction", {
            Text = "Velocity Prediction",
            Tooltip = "Offsets projectiles tracking utilizing movement projections",
            Default = true,
        })

        ProjectileGroup:AddSlider("ProjectileAimDelay", {
            Text = "Aim Delay",
            Default = 0,
            Min = 0,
            Max = 3,
            Rounding = 2,
            Suffix = "s",
            Tooltip = "Transition delay latency prior to tracking alignment execution",
        })

        -- Separated and explicit Controls for Config Saving persistence
        ProjectileGroup:AddDivider()
        ProjectileGroup:AddLabel("--- Mass Infection ---")
        ProjectileGroup:AddToggle("MassInfectionEnabled", {
            Text = "Enable Mass Infection Aim",
            Default = true,
            Callback = function(Value)
                skillConfigs["Mass Infection"].enabled = Value
            end,
        })
        ProjectileGroup:AddSlider("MassInfectionDuration", {
            Text = "Mass Infection Aimbot Duration",
            Default = 0.65,
            Min = 0.1,
            Max = 5,
            Rounding = 2,
            Suffix = "s",
            Callback = function(Value)
                skillConfigs["Mass Infection"].duration = tonumber(Value) or 0.65
            end,
        })
        ProjectileGroup:AddSlider("MassInfectionSpeed", {
            Text = "Mass Infection Aim Speed (Smoothing)",
            Default = 35,
            Min = 1,
            Max = 100,
            Rounding = 1,
            Tooltip = "How fast the aimbot rotates towards the target. 100 is instant snap.",
            Callback = function(Value)
                skillConfigs["Mass Infection"].speed = tonumber(Value) or 35
            end,
        })
        ProjectileGroup:AddSlider("MassInfectionPrediction", {
            Text = "Mass Infection Prediction Strength",
            Default = 0.2,
            Min = 0,
            Max = 2,
            Rounding = 2,
            Suffix = "s",
            Tooltip = "Scale factor for dynamic travel-time prediction",
            Callback = function(Value)
                skillConfigs["Mass Infection"].prediction = tonumber(Value) or 0.2
            end,
        })

        -- Separated and explicit Controls for Config Saving persistence
        ProjectileGroup:AddDivider()
        ProjectileGroup:AddLabel("--- Entanglement ---")
        ProjectileGroup:AddToggle("EntanglementEnabled", {
            Text = "Enable Entanglement Aim",
            Default = true,
            Callback = function(Value)
                skillConfigs["Entanglement"].enabled = Value
            end,
        })
        ProjectileGroup:AddSlider("EntanglementDuration", {
            Text = "Entanglement Aimbot Duration",
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
            Text = "Entanglement Aim Speed (Smoothing)",
            Default = 35,
            Min = 1,
            Max = 100,
            Rounding = 1,
            Tooltip = "How fast the aimbot rotates towards the target. 100 is instant snap.",
            Callback = function(Value)
                skillConfigs["Entanglement"].speed = tonumber(Value) or 35
            end,
        })
        ProjectileGroup:AddSlider("EntanglementPrediction", {
            Text = "Entanglement Prediction Strength",
            Default = 0.2,
            Min = 0,
            Max = 2,
            Rounding = 2,
            Suffix = "s",
            Tooltip = "Scale factor for dynamic travel-time prediction",
            Callback = function(Value)
                skillConfigs["Entanglement"].prediction = tonumber(Value) or 0.2
            end,
        })

        -- AutoGen Category Configuration
        AutoGenGroup:AddToggle("AutoGenToggle", {
            Text = "Auto Gen",
            Tooltip = "Automatically completes active generator puzzles dynamically",
            Default = false,
            Callback = function(Value)
                autoGenEnabled = Value
            end,
        })

        AutoGenGroup:AddSlider("AutoGenSpeed", {
            Text = "AutoGen Speed Interval",
            Default = 1.0,
            Min = 0.1,
            Max = 5.0,
            Rounding = 1,
            Suffix = "s",
            Tooltip = "Delay interval (seconds) between automatic solver cycles (lower = faster)",
            Callback = function(Value)
                autoGenSpeed = tonumber(Value) or 1.0
            end,
        })

        -- Killer Visual Setup
        VisualsLeftGroup:AddToggle("KillerHighlight", {
            Text = "Killer",
            Tooltip = "Highlight and outline killers",
            Default = false,
            Callback = function(Value)
                visualKillerHighlightEnabled = Value
            end,
        }):AddColorPicker("KillerHighlightColor", {
            Default = Color3.fromRGB(255, 0, 0),
            Title = "Killer Highlight Color",
            Callback = function(Value)
                killerHighlightColor = Value
            end
        })

        VisualsLeftGroup:AddInput("KillerOutlineTransparency", {
            Text = "Killer Outline Transparency",
            Default = "0.5",
            Numeric = true,
            ClearTextOnFocus = false,
            Placeholder = "e.g. 0.5",
            Callback = function(Value)
                visualKillerOutlineTransparency = tonumber(Value) or 0.5
                for _, hl in pairs(killerHighlights) do
                    if hl then hl.OutlineTransparency = visualKillerOutlineTransparency end
                end
            end,
        })

        VisualsLeftGroup:AddInput("KillerFillTransparency", {
            Text = "Killer Fill Transparency",
            Default = "0.85",
            Numeric = true,
            ClearTextOnFocus = false,
            Placeholder = "e.g. 0.85",
            Callback = function(Value)
                visualKillerFillTransparency = tonumber(Value) or 0.85
                for _, hl in pairs(killerHighlights) do
                    if hl then hl.FillTransparency = visualKillerFillTransparency end
                end
            end
        })

        VisualsLeftGroup:AddDivider()

        -- Survivor Visual Setup
        VisualsLeftGroup:AddToggle("SurvivorHighlight", {
            Text = "Survivor",
            Tooltip = "Highlight and outline survivors",
            Default = false,
            Callback = function(Value)
                visualSurvivorHighlightEnabled = Value
            end,
        }):AddColorPicker("SurvivorHighlightColor", {
            Default = Color3.fromRGB(0, 255, 0),
            Title = "Survivor Highlight Color",
            Callback = function(Value)
                survivorHighlightColor = Value
            end
        })

        VisualsLeftGroup:AddInput("SurvivorOutlineTransparency", {
            Text = "Survivor Outline Transparency",
            Default = "0.5",
            Numeric = true,
            ClearTextOnFocus = false,
            Placeholder = "e.g. 0.5",
            Callback = function(Value)
                visualSurvivorOutlineTransparency = tonumber(Value) or 0.5
                for _, hl in pairs(survivorHighlights) do
                    if hl then hl.OutlineTransparency = visualSurvivorOutlineTransparency end
                end
            end,
        })

        VisualsLeftGroup:AddInput("SurvivorFillTransparency", {
            Text = "Survivor Fill Transparency",
            Default = "0.85",
            Numeric = true,
            ClearTextOnFocus = false,
            Placeholder = "e.g. 0.85",
            Callback = function(Value)
                visualSurvivorFillTransparency = tonumber(Value) or 0.85
                for _, hl in pairs(survivorHighlights) do
                    if hl then hl.FillTransparency = visualSurvivorFillTransparency end
                end
            end
        })

        VisualsLeftGroup:AddDivider()

        -- Items Visual Setup
        VisualsLeftGroup:AddToggle("ItemsHighlight", {
            Text = "Items",
            Tooltip = "Highlight and outline items (Medkit, Cola)",
            Default = false,
            Callback = function(Value)
                visualItemsHighlightEnabled = Value
            end,
        }):AddColorPicker("ItemsHighlightColor", {
            Default = Color3.fromRGB(255, 255, 0),
            Title = "Items Highlight Color",
            Callback = function(Value)
                itemsHighlightColor = Value
            end
        })

        VisualsLeftGroup:AddInput("ItemsOutlineTransparency", {
            Text = "Items Outline Transparency",
            Default = "0.5",
            Numeric = true,
            ClearTextOnFocus = false,
            Placeholder = "e.g. 0.5",
            Callback = function(Value)
                visualItemsOutlineTransparency = tonumber(Value) or 0.5
                for _, hl in pairs(itemHighlights) do
                    if hl then hl.OutlineTransparency = visualItemsOutlineTransparency end
                end
            end,
        })

        VisualsLeftGroup:AddInput("ItemsFillTransparency", {
            Text = "Items Fill Transparency",
            Default = "0.85",
            Numeric = true,
            ClearTextOnFocus = false,
            Placeholder = "e.g. 0.85",
            Callback = function(Value)
                visualItemsFillTransparency = tonumber(Value) or 0.85
                for _, hl in pairs(itemHighlights) do
                    if hl then hl.FillTransparency = visualItemsFillTransparency end
                end
            end
        })

        VisualsLeftGroup:AddDivider()

        -- Generators Visual Setup
        VisualsLeftGroup:AddToggle("GeneratorsHighlight", {
            Text = "Generators",
            Tooltip = "Highlight and outline generators",
            Default = false,
            Callback = function(Value)
                visualGeneratorsHighlightEnabled = Value
            end,
        }):AddColorPicker("GeneratorsHighlightColor", {
            Default = Color3.fromRGB(0, 255, 255),
            Title = "Generators Highlight Color",
            Callback = function(Value)
                generatorsHighlightColor = Value
            end
        })

        VisualsLeftGroup:AddToggle("ShowGenPercentage", {
            Text = "Show Gen Percentage",
            Tooltip = "Shows the completion progress overlay above generators",
            Default = false,
            Callback = function(Value)
                visualGeneratorsShowPercentageEnabled = Value
            end,
        })

        VisualsLeftGroup:AddInput("GeneratorsOutlineTransparency", {
            Text = "Generators Outline Transparency",
            Default = "0.5",
            Numeric = true,
            ClearTextOnFocus = false,
            Placeholder = "e.g. 0.5",
            Callback = function(Value)
                visualGeneratorsOutlineTransparency = tonumber(Value) or 0.5
                for _, hl in pairs(generatorHighlights) do
                    if hl then hl.OutlineTransparency = visualGeneratorsOutlineTransparency end
                end
            end,
        })

        VisualsLeftGroup:AddInput("GeneratorsFillTransparency", {
            Text = "Generators Fill Transparency",
            Default = "0.85",
            Numeric = true,
            ClearTextOnFocus = false,
            Placeholder = "e.g. 0.85",
            Callback = function(Value)
                visualGeneratorsFillTransparency = tonumber(Value) or 0.85
                for _, hl in pairs(generatorHighlights) do
                    if hl then hl.FillTransparency = visualGeneratorsFillTransparency end
                end
            end
        })

        VisualsLeftGroup:AddDivider()

        -- Traps Visual Setup
        VisualsLeftGroup:AddToggle("TrapsHighlight", {
            Text = "Traps",
            Tooltip = "Highlight and outline traps (Digital Footprints, Tripwires, Subspace Tripmines, Seeker Bulbs, Stigmatize Plants)",
            Default = false,
            Callback = function(Value)
                visualTrapsHighlightEnabled = Value
            end,
        }):AddColorPicker("TrapsHighlightColor", {
            Default = Color3.fromRGB(255, 100, 0),
            Title = "Traps Highlight Color",
            Callback = function(Value)
                trapsHighlightColor = Value
            end
        })

        VisualsLeftGroup:AddInput("TrapsOutlineTransparency", {
            Text = "Traps Outline Transparency",
            Default = "0.5",
            Numeric = true,
            ClearTextOnFocus = false,
            Placeholder = "e.g. 0.5",
            Callback = function(Value)
                visualTrapsOutlineTransparency = tonumber(Value) or 0.5
                for _, hl in pairs(trapHighlights) do
                    if hl then hl.OutlineTransparency = visualTrapsOutlineTransparency end
                end
            end,
        })

        VisualsLeftGroup:AddInput("TrapsFillTransparency", {
            Text = "Traps Fill Transparency",
            Default = "0.85",
            Numeric = true,
            ClearTextOnFocus = false,
            Placeholder = "e.g. 0.85",
            Callback = function(Value)
                visualTrapsFillTransparency = tonumber(Value) or 0.85
                for _, hl in pairs(trapHighlights) do
                    if hl then hl.FillTransparency = visualTrapsFillTransparency end
                end
            end
        })

        VisualsLeftGroup:AddDivider()

        VisualsLeftGroup:AddToggle("FullBrightToggle", {
            Text = "Full Bright",
            Tooltip = "Forces global environment illumination",
            Default = false,
            Callback = function(Value)
                fullBrightEnabled = Value
                pcall(applyFullBright)
            end,
        })

        -- Stamina Configuration Tab UI
        StaminaLeftGroup:AddToggle("EnStaminaMod", {
            Text = "EnStaminaMod",
            Tooltip = "Enables custom stamina configurations from Sprinting module",
            Default = false,
            Callback = function(Value)
                staminaEnabled = Value
                if staminaEnabled then
                    local stamina = getSprintingModule()
                    if stamina then pcall(applyCustomStats, stamina) end
                end
            end,
        })

        StaminaLeftGroup:AddToggle("InfStam", {
            Text = "InfStam",
            Tooltip = "Disables stamina drain (StaminaLossDisabled = true)",
            Default = true,
            Callback = function(Value)
                INF_STAMINA = Value
                if staminaEnabled then
                    local stamina = getSprintingModule()
                    if stamina then pcall(applyCustomStats, stamina) end
                end
            end,
        })

        StaminaLeftGroup:AddInput("MaxStaminaVal", {
            Text = "Max Stamina",
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

        StaminaLeftGroup:AddInput("MinStaminaVal", {
            Text = "Min Stamina",
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

        StaminaLeftGroup:AddInput("StaminaGainVal", {
            Text = "Stamina Gain",
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

        StaminaLeftGroup:AddInput("StaminaLossVal", {
            Text = "Stamina Loss",
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

        StaminaLeftGroup:AddInput("SprintSpeedVal", {
            Text = "Sprint Speed",
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

        Options = Library.Options
        Toggles = Library.Toggles

        ui_refs.Library = Library
        ui_refs.Window = Window
        ui_refs.Options = Options
        ui_refs.Toggles = Toggles

        local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Setting", "wrench")

        MenuGroup:AddToggle("KeybindMenuOpen", {
            Default = Library.KeybindFrame.Visible,
            Text = "Open Keybind Menu",
            Callback = function(value)
                Library.KeybindFrame.Visible = value
            end,
        })
        MenuGroup:AddToggle("ShowCustomCursor", {
            Text = "Custom Cursor",
            Default = true,
            Callback = function(Value)
                Library.ShowCustomCursor = Value
            end,
        })
        MenuGroup:AddDropdown("NotificationSide", {
            Values = { "Left", "Right" },
            Default = "Right",
            Text = "Notification Side",
            Callback = function(Value)
                pcall(function() Library:SetNotifySide(Value) end)
            end,
        })
        MenuGroup:AddDropdown("DPIDropdown", {
            Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
            Default = "100%",
            Text = "DPI Scale",
            Callback = function(Value)
                Value = Value:gsub("%%", "")
                local DPI = tonumber(Value)
                pcall(function() Library:SetDPIScale(DPI) end)
            end,
        })

        MenuGroup:AddSlider("GuiCornerRadius", {
            Text = "GUI Corner Radius",
            Default = 8,
            Min = 0,
            Max = 20,
            Rounding = 0,
            Tooltip = "Adjust GUI corner roundness",
            Callback = function(Value)
                guiCornerRadius = tonumber(Value) or 8
                pcall(updateGuiCorners, guiCornerRadius)
            end,
        })

        MenuGroup:AddDivider()
        MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

        MenuGroup:AddButton("unload script", function()
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
                ThemeManager:SetFolder("freshleavessaken")
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
                SaveManager:SetFolder("freshleavessaken/games")
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
        end)
    end

    heartbeatAlignmentConnection = RunService.Heartbeat:Connect(function(dt)
        if isUnloaded then return end
        
        -- Handle Auto M1 Alignment
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
                    
                    -- Dynamic, frame-rate independent rotation smoothing
                    local alpha = (autoM1AimSpeed >= 50) and 1 or (1 - math.exp(-autoM1AimSpeed * dt))
                    hrp.CFrame = hrp.CFrame:Lerp(cframe_new(hrp.Position) * targetRotation, alpha)
                end
            end
        end

        -- Handle Projectile Aim Alignment (Character Aimbot only - no Camera interaction)
        if projectileAimbotActive and projectileAimbotTarget and projectileAimbotTarget.Parent then
            local config = skillConfigs[currentActiveSkill] or { duration = 0.65, speed = 35, prediction = 0.2 }
            local elapsed = os_clock() - projectileAimStartTime
            local aimDur = config.duration
            
            if elapsed >= aimDur or not inMatch() then
                projectileAimbotActive = false
                projectileAimbotTarget = nil
                currentActiveSkill = nil
                local _, humanoid, _ = getCharacterInfo()
                if humanoid then
                    pcall(function() humanoid.AutoRotate = true end)
                end
                return
            end
            
            local char, humanoid, hrp = getCharacterInfo()
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
                    
                    -- Smooth, frame-rate independent rotation lerping
                    local aimSpeed = config.speed or 35
                    local alpha = (aimSpeed >= 100) and 1 or (1 - math.exp(-aimSpeed * dt))
                    hrp.CFrame = hrp.CFrame:Lerp(cframe_new(hrp.Position) * targetRotation, alpha)
                end
            end
        end
    end)

    -- Track cooldown transitions to trigger CA-Aim on dynamic skills
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
                        
                        -- Detect sudden transition into a positive cooldown state (skill execution)
                        -- Trigger aim dynamically on activation delta change
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

        if autoM1AimbotActive then return end

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

    local function updateM1Circle(hrp)
        if not autoM1Enabled or not autoM1VisualizerEnabled or not hrp then
            if autoM1Circle then
                autoM1Circle:Destroy()
                autoM1Circle = nil
            end
            return
        end

        if not autoM1Circle then
            autoM1Circle = Instance.new("CylinderHandleAdornment")
            autoM1Circle.Height = 0.01
            autoM1Circle.Color3 = Color3.fromRGB(0, 255, 0)
            autoM1Circle.Transparency = 0.6
            autoM1Circle.ZIndex = 10
            autoM1Circle.AlwaysOnTop = true
            autoM1Circle.Parent = Workspace:FindFirstChild("Terrain") or Workspace
        end

        autoM1Circle.Adornee = hrp
        autoM1Circle.Radius = autoM1Range
        autoM1Circle.CFrame = cframe_new(0, -hrp.Size.Y/2, 0) * CFrame.Angles(math_rad(90), 0, 0)
    end

    -- Visualizer refresh rate loop
    task.spawn(function()
        while true do
            task.wait(0.25)
            if isUnloaded then 
                if leftConeLine then pcall(function() leftConeLine:Destroy() end) end
                if rightConeLine then pcall(function() rightConeLine:Destroy() end) end
                if autoM1Circle then pcall(function() autoM1Circle:Destroy() end) end
                break 
            end
            
            local char, _, hrp = getCharacterInfo()
            
            if autoM1Enabled and autoM1VisualizerEnabled and inMatch() and hrp then
                updateM1Circle(hrp)
                
                if leftConeLine then
                    leftConeLine.Adornee = hrp
                    leftConeLine.Length = autoM1Range
                    leftConeLine.CFrame = CFrame.Angles(0, math_rad(180 + autoM1ConeAngle / 2), 0)
                else
                    leftConeLine = Instance.new("LineHandleAdornment")
                    leftConeLine.Color3 = Color3.fromRGB(0, 255, 0)
                    leftConeLine.Thickness = 3
                    leftConeLine.ZIndex = 10
                    leftConeLine.AlwaysOnTop = true
                    leftConeLine.Adornee = hrp
                    leftConeLine.Length = autoM1Range
                    leftConeLine.CFrame = CFrame.Angles(0, math_rad(180 + autoM1ConeAngle / 2), 0)
                    leftConeLine.Parent = Workspace:FindFirstChild("Terrain") or Workspace
                end
                
                if rightConeLine then
                    rightConeLine.Adornee = hrp
                    rightConeLine.Length = autoM1Range
                    rightConeLine.CFrame = CFrame.Angles(0, math_rad(180 - autoM1ConeAngle / 2), 0)
                else
                    rightConeLine = Instance.new("LineHandleAdornment")
                    rightConeLine.Color3 = Color3.fromRGB(0, 255, 0)
                    rightConeLine.Thickness = 3
                    rightConeLine.ZIndex = 10
                    rightConeLine.AlwaysOnTop = true
                    rightConeLine.Adornee = hrp
                    rightConeLine.Length = autoM1Range
                    rightConeLine.CFrame = CFrame.Angles(0, math_rad(180 - autoM1ConeAngle / 2), 0)
                    rightConeLine.Parent = Workspace:FindFirstChild("Terrain") or Workspace
                end
            else
                if leftConeLine then pcall(function() leftConeLine:Destroy() end) leftConeLine = nil end
                if rightConeLine then pcall(function() rightConeLine:Destroy() end) rightConeLine = nil end
                updateM1Circle(nil)
            end
        end
    end)

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
        end

        for model, hl in pairs(trapHighlights) do
            if not model or not model.Parent or not table_find(traps, model) then
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

    -- Initialize Event-Driven Caches
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

    -- Stamina Modifier Loop
    task.spawn(function()
        while true do
            task.wait(0.5) -- Responsive interval for enforcement
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

    -- AutoGen Proximity Tracker Loop
    task.spawn(function()
        while true do
            task.wait(0.1)
            if isUnloaded then break end
            
            if autoGenEnabled and inMatch() then
                local closestGen, dist = getClosestGenerator()
                -- Adjust interaction tracking range threshold (9 studs)
                if closestGen and dist <= 9 then
                    if currentInteractingGen ~= closestGen then
                        currentInteractingGen = closestGen
                        lastGenInteractionTime = os_clock() -- Restarts timer on switch / initial approach
                    end
                else
                    currentInteractingGen = nil
                    lastGenInteractionTime = 0
                end
            else
                currentInteractingGen = nil
                lastGenInteractionTime = 0
            end
        end
    end)

    -- AutoGen Execution Loop (Listens strictly to speed interval)
    task.spawn(function()
        while true do
            task.wait(0.05) -- Fast check to process exact speed interval transition
            if isUnloaded then break end
            
            if autoGenEnabled and inMatch() and currentInteractingGen then
                local now = os_clock()
                if now - lastGenInteractionTime >= autoGenSpeed then
                    pcall(solveGenerator, currentInteractingGen)
                    lastGenInteractionTime = now -- Enforce another interval wait
                end
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
end)
