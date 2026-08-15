local RobloxServices = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    UserInput = game:GetService("UserInputService"),
    Stats = game:GetService("Stats"),
    HttpService = game:GetService("HttpService"),
}

local LocalPlayer = RobloxServices.Players.LocalPlayer
local CurrentCamera = RobloxServices.Workspace.CurrentCamera

-- Helper to safely get GUI parent for CoreGui / PlayerGui
local function getGuiParent()
    local gethui = gethui or function()
        local ok, cg = pcall(function() return game:GetService("CoreGui") end)
        return (ok and cg) or LocalPlayer:FindFirstChildOfClass("PlayerGui")
    end
    return gethui()
end

-- Improved helper function to check if a character model belongs to a real human player
local function isRealPlayer(model)
    if not model or not model:IsA("Model") then return false end
    
    -- Direct player character check
    if RobloxServices.Players:GetPlayerFromCharacter(model) then
        return true
    end

    -- Fallback scan against connected real players
    for _, plr in ipairs(RobloxServices.Players:GetPlayers()) do
        if plr.Character == model or plr.Name == model.Name or plr.DisplayName == model.Name then
            return true
        end
    end
    return false
end

-- Helper to check if an instance belongs to an Accessory/Hat
local function isAccessory(inst)
    if not inst then return false end
    return inst:FindFirstAncestorOfClass("Accessory") ~= nil 
        or inst:FindFirstAncestorOfClass("Accoutrement") ~= nil
end

-- Helper to get team folder
local function getTeamFolder(name)
    local root = RobloxServices.Workspace:FindFirstChild("Players")
    return root and root:FindFirstChild(name)
end

-- ──────────────────────────────────────────────────
--  SHARED RF DISPATCHER SYSTEM
-- ──────────────────────────────────────────────────
local rfDispatch = {
    hooks = {},
    installed = false,
    originalCallback = nil
}

function rfDispatch:register(id, callback)
    self.hooks[id] = callback
end

function rfDispatch:install(remoteFunction)
    if self.installed or not remoteFunction then return end
    
    if typeof(getcallbackvalue) == "function" then
        pcall(function()
            self.originalCallback = getcallbackvalue(remoteFunction, "OnClientInvoke")
        end)
    else
        self.originalCallback = remoteFunction.OnClientInvoke
    end

    remoteFunction.OnClientInvoke = function(requestName, ...)
        for id, hookFunc in pairs(self.hooks) do
            local success, result = pcall(hookFunc, requestName, ...)
            if success and result ~= nil then
                return result
            end
        end
        
        if self.originalCallback then
            return self.originalCallback(requestName, ...)
        end
    end
    self.installed = true
end

function rfDispatch:uninstall(remoteFunction)
    if not self.installed then return end
    if remoteFunction and self.originalCallback then
        pcall(function()
            remoteFunction.OnClientInvoke = self.originalCallback
        end)
    end
    self.hooks = {}
    self.originalCallback = nil
    self.installed = false
end

-- ──────────────────────────────────────────────────
--  CONFIG PERSISTENCE SYSTEM
-- ──────────────────────────────────────────────────
local CONFIG_FOLDER = "Dumsekkah"
local CONFIG_FILE = "Dumsekkah/config.json"

local function safeWriteFile(path, contents)
    if typeof(writefile) == "function" then
        pcall(writefile, path, contents)
    end
end

local function safeReadFile(path)
    if typeof(readfile) == "function" then
        local ok, result = pcall(readfile, path)
        if ok then return result end
    end
    return nil
end

local function safeMakeFolder(folder)
    if typeof(makefolder) == "function" and typeof(isfolder) == "function" then
        if not isfolder(folder) then
            pcall(makefolder, folder)
        end
    end
end

-- Config State Variables
local stam = {
    on      = false,
    loss    = 10,
    gain    = 20,
    max     = 100,
    current = 100,
    noLoss  = false,
    thread  = nil,
}

local speedHack = { on = false, speed = 30, thread = nil, lastApplied = 0 }

local fpsBooster_enabled = false
local originalVisualStates = {}
local fpsBoosterConnection = nil
local fpsQueue = {}
local isProcessingFps = false

local killerVisualsEnabled = true
local killerNameLabelsEnabled = true
local killerIgnoreNPCs = true
local killerHighlightRate = 0.85
local killerScanRate = 0.5
local killerScanThread = nil
local killerHighlights = {}

local plasma_enabled               = false
local plasma_ignoreNPCs            = true
local plasma_targetSelectionMode   = "Nearest"
local plasma_aimOffset             = 0.0
local plasma_prediction            = 0.12
local plasma_predictionSpeed       = 10.0
local plasma_targetType            = "Killers"
local plasma_throughWalls          = false
local plasma_pingDetection         = true

-- Killer Ability Configs
local killerAutoDetectAbilities = true

local massInfection = {
    enabled = true,
    duration = 1.45,
    aimDuration = 0.50,
    spinSpeed = 45,
    keybind = Enum.KeyCode.E,
    isSpinning = false,
}

local entanglement = {
    enabled = true,
    duration = 0.40,
    aimDuration = 0.50,
    spinSpeed = 45,
    keybind = Enum.KeyCode.R,
    isSpinning = false,
}

-- Auto-Gen Flow Game Config
local flow = {
    on = false,
    nodeDelay = 0.04,
    lineDelay = 0.60
}

local targetBoxEnabled             = false
local sphere_visualsEnabled        = true
local sphere_size                  = 1.0
local sphere_transparency          = 0.85
local sphere_material              = Enum.Material.SmoothPlastic
local sphere_color                 = Color3.fromHex("#6366F1")
local cylinder_visualsEnabled      = true
local cylinder_thickness           = 0.2

local function saveConfig()
    safeMakeFolder(CONFIG_FOLDER)
    local data = {
        stam_on = stam.on,
        stam_noLoss = stam.noLoss,
        stam_loss = stam.loss,
        stam_gain = stam.gain,
        stam_max = stam.max,
        stam_current = stam.current,

        speed_on = speedHack.on,
        speed_speed = speedHack.speed,

        fpsBooster_enabled = fpsBooster_enabled,

        killerVisualsEnabled = killerVisualsEnabled,
        killerNameLabelsEnabled = killerNameLabelsEnabled,
        killerIgnoreNPCs = killerIgnoreNPCs,
        killerHighlightRate = killerHighlightRate,
        killerScanRate = killerScanRate,

        plasma_enabled = plasma_enabled,
        plasma_ignoreNPCs = plasma_ignoreNPCs,
        plasma_targetSelectionMode = plasma_targetSelectionMode,
        plasma_aimOffset = plasma_aimOffset,
        plasma_prediction = plasma_prediction,
        plasma_predictionSpeed = plasma_predictionSpeed,
        plasma_targetType = plasma_targetType,
        plasma_throughWalls = plasma_throughWalls,
        plasma_pingDetection = plasma_pingDetection,

        killerAutoDetectAbilities = killerAutoDetectAbilities,

        massInfection_enabled = massInfection.enabled,
        massInfection_duration = massInfection.duration,
        massInfection_aimDuration = massInfection.aimDuration,
        massInfection_spinSpeed = massInfection.spinSpeed,

        entanglement_enabled = entanglement.enabled,
        entanglement_duration = entanglement.duration,
        entanglement_aimDuration = entanglement.aimDuration,
        entanglement_spinSpeed = entanglement.spinSpeed,

        flow_on = flow.on,
        flow_nodeDelay = flow.nodeDelay,
        flow_lineDelay = flow.lineDelay,

        targetBoxEnabled = targetBoxEnabled,

        sphere_visualsEnabled = sphere_visualsEnabled,
        sphere_size = sphere_size,
        sphere_transparency = sphere_transparency,
        sphere_material = sphere_material.Name,
        sphere_color = sphere_color:ToHex(),
        cylinder_visualsEnabled = cylinder_visualsEnabled,
        cylinder_thickness = cylinder_thickness,
    }

    local ok, json = pcall(function() return RobloxServices.HttpService:JSONEncode(data) end)
    if ok and json then
        safeWriteFile(CONFIG_FILE, json)
    end
end

local function loadConfig()
    local contents = safeReadFile(CONFIG_FILE)
    if not contents then return end

    local ok, data = pcall(function() return RobloxServices.HttpService:JSONDecode(contents) end)
    if not ok or type(data) ~= "table" then return end

    if data.stam_on ~= nil then stam.on = data.stam_on end
    if data.stam_noLoss ~= nil then stam.noLoss = data.stam_noLoss end
    if data.stam_loss ~= nil then stam.loss = data.stam_loss end
    if data.stam_gain ~= nil then stam.gain = data.stam_gain end
    if data.stam_max ~= nil then stam.max = data.stam_max end
    if data.stam_current ~= nil then stam.current = data.stam_current end

    if data.speed_on ~= nil then speedHack.on = data.speed_on end
    if data.speed_speed ~= nil then speedHack.speed = data.speed_speed end

    if data.fpsBooster_enabled ~= nil then fpsBooster_enabled = data.fpsBooster_enabled end

    if data.killerVisualsEnabled ~= nil then killerVisualsEnabled = data.killerVisualsEnabled end
    if data.killerNameLabelsEnabled ~= nil then killerNameLabelsEnabled = data.killerNameLabelsEnabled end
    if data.killerIgnoreNPCs ~= nil then killerIgnoreNPCs = data.killerIgnoreNPCs end
    if data.killerHighlightRate ~= nil then killerHighlightRate = data.killerHighlightRate end
    if data.killerScanRate ~= nil then killerScanRate = data.killerScanRate end

    if data.plasma_enabled ~= nil then plasma_enabled = data.plasma_enabled end
    if data.plasma_ignoreNPCs ~= nil then plasma_ignoreNPCs = data.plasma_ignoreNPCs end
    if data.plasma_targetSelectionMode ~= nil then plasma_targetSelectionMode = data.plasma_targetSelectionMode end
    if data.plasma_aimOffset ~= nil then plasma_aimOffset = data.plasma_aimOffset end
    if data.plasma_prediction ~= nil then plasma_prediction = data.plasma_prediction end
    if data.plasma_predictionSpeed ~= nil then plasma_predictionSpeed = data.plasma_predictionSpeed end
    if data.plasma_targetType ~= nil then plasma_targetType = data.plasma_targetType end
    if data.plasma_throughWalls ~= nil then plasma_throughWalls = data.plasma_throughWalls end
    if data.plasma_pingDetection ~= nil then plasma_pingDetection = data.plasma_pingDetection end

    if data.killerAutoDetectAbilities ~= nil then killerAutoDetectAbilities = data.killerAutoDetectAbilities end

    if data.massInfection_enabled ~= nil then massInfection.enabled = data.massInfection_enabled end
    if data.massInfection_duration ~= nil then massInfection.duration = data.massInfection_duration end
    if data.massInfection_aimDuration ~= nil then massInfection.aimDuration = data.massInfection_aimDuration end
    if data.massInfection_spinSpeed ~= nil then massInfection.spinSpeed = data.massInfection_spinSpeed end

    if data.entanglement_enabled ~= nil then entanglement.enabled = data.entanglement_enabled end
    if data.entanglement_duration ~= nil then entanglement.duration = data.entanglement_duration end
    if data.entanglement_aimDuration ~= nil then entanglement.aimDuration = data.entanglement_aimDuration end
    if data.entanglement_spinSpeed ~= nil then entanglement.spinSpeed = data.entanglement_spinSpeed end

    if data.flow_on ~= nil then flow.on = data.flow_on end
    if data.flow_nodeDelay ~= nil then flow.nodeDelay = data.flow_nodeDelay end
    if data.flow_lineDelay ~= nil then flow.lineDelay = data.flow_lineDelay end

    if data.targetBoxEnabled ~= nil then targetBoxEnabled = data.targetBoxEnabled end

    if data.sphere_visualsEnabled ~= nil then sphere_visualsEnabled = data.sphere_visualsEnabled end
    if data.sphere_size ~= nil then sphere_size = data.sphere_size end
    if data.sphere_transparency ~= nil then sphere_transparency = data.sphere_transparency end
    if data.sphere_material ~= nil then
        pcall(function() sphere_material = Enum.Material[data.sphere_material] end)
    end
    if data.sphere_color ~= nil then
        pcall(function() sphere_color = Color3.fromHex(data.sphere_color) end)
    end
    if data.cylinder_visualsEnabled ~= nil then cylinder_visualsEnabled = data.cylinder_visualsEnabled end
    if data.cylinder_thickness ~= nil then cylinder_thickness = data.cylinder_thickness end
end

-- Load configuration on startup
loadConfig()

-- ──────────────────────────────────────────────────
--  AUTO-GEN (GENERATOR AUTO SOLVER LOGIC)
-- ──────────────────────────────────────────────────
local function flowKey(n) return n.row.."-"..n.col end

local function flowNeighbour(r1,c1,r2,c2)
    if r2==r1-1 and c2==c1 then return"up" end; if r2==r1+1 and c2==c1 then return"down" end
    if r2==r1 and c2==c1-1 then return"left" end; if r2==r1 and c2==c1+1 then return"right" end; return false
end

local function flowOrder(path, endpoints)
    if not path or #path == 0 then return path end
    local lookup = {}
    for _, n in ipairs(path) do lookup[flowKey(n)] = n end
    local start
    for _, ep in ipairs(endpoints or {}) do
        for _, n in ipairs(path) do
            if n.row == ep.row and n.col == ep.col then start = { row = ep.row, col = ep.col }; break end
        end
        if start then break end
    end
    if not start then
        for _, n in ipairs(path) do
            local nb = 0
            for _, d in ipairs({{-1,0},{1,0},{0,-1},{0,1}}) do
                if lookup[(n.row+d[1]).."-"..(n.col+d[2])] then nb += 1 end
            end
            if nb == 1 then start = { row = n.row, col = n.col }; break end
        end
    end
    if not start then start = { row = path[1].row, col = path[1].col } end
    local pool, ordered = {}, {}
    for _, n in ipairs(path) do pool[flowKey(n)] = { row = n.row, col = n.col } end
    local cur = start
    table.insert(ordered, { row = cur.row, col = cur.col }); pool[flowKey(cur)] = nil
    while next(pool) do
        local moved = false
        for k, node in pairs(pool) do
            if flowNeighbour(cur.row, cur.col, node.row, node.col) then
                table.insert(ordered, { row = node.row, col = node.col })
                pool[k] = nil; cur = node; moved = true; break
            end
        end
        if not moved then break end
    end
    return ordered
end

local function flowSolve(puzzle)
    pcall(function()
        if not puzzle or not puzzle.Solution then return end
        local indices = {}
        for i = 1, #puzzle.Solution do indices[i] = i end
        for i = #indices, 2, -1 do local j = math.random(1, i); indices[i], indices[j] = indices[j], indices[i] end
        for _, ci in ipairs(indices) do
            local solution = puzzle.Solution[ci]; if not solution then continue end
            local ordered = flowOrder(solution, puzzle.targetPairs[ci])
            if not ordered or #ordered == 0 then continue end
            puzzle.paths[ci] = {}
            for _, node in ipairs(ordered) do
                table.insert(puzzle.paths[ci], { row = node.row, col = node.col })
                puzzle:updateGui(); task.wait(flow.nodeDelay)
            end
            task.wait(flow.lineDelay); puzzle:checkForWin()
        end
    end)
end

local function setupFlowHook()
    pcall(function()
        local storage = RobloxServices.ReplicatedStorage
        local modFolder  = storage:FindFirstChild("Modules")
        local miniFolder = modFolder and modFolder:FindFirstChild("Minigames")
        local fgFolder   = miniFolder and miniFolder:FindFirstChild("FlowGameManager")
        local fgModule   = fgFolder and fgFolder:FindFirstChild("FlowGame")
        if fgModule then
            local ok, FG = pcall(require, fgModule)
            if ok and FG and FG.new and not FG.__dusekkarHooked then
                FG.__dusekkarHooked = true
                local orig = FG.new
                FG.new = function(...)
                    local p = orig(...)
                    if flow.on then
                        task.spawn(function() task.wait(0.3); flowSolve(p) end)
                    end
                    return p
                end
            end
        end
    end)
end

task.spawn(setupFlowHook)

-- ──────────────────────────────────────────────────
--  OPTIMIZED FPS BOOSTER
-- ──────────────────────────────────────────────────
local function optimizeInstance(inst)
    if not inst or isAccessory(inst) then return end

    if inst:IsA("Decal") or inst:IsA("Texture") then
        if originalVisualStates[inst] == nil then
            originalVisualStates[inst] = { property = "Transparency", value = inst.Transparency }
        end
        pcall(function() inst.Transparency = 1 end)
    elseif inst:IsA("ParticleEmitter") or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles") or inst:IsA("Trail") or inst:IsA("Beam") then
        if originalVisualStates[inst] == nil then
            originalVisualStates[inst] = { property = "Enabled", value = inst.Enabled }
        end
        pcall(function() inst.Enabled = false end)
    end
end

local function processFpsQueue()
    if isProcessingFps then return end
    isProcessingFps = true
    task.spawn(function()
        while #fpsQueue > 0 and fpsBooster_enabled do
            local processedCount = 0
            while #fpsQueue > 0 and processedCount < 150 do
                processedCount += 1
                local inst = table.remove(fpsQueue)
                if inst and inst.Parent then
                    optimizeInstance(inst)
                end
            end
            task.wait()
        end
        isProcessingFps = false
    end)
end

local function enableFpsBooster()
    fpsBooster_enabled = true
    fpsQueue = RobloxServices.Workspace:GetDescendants()
    processFpsQueue()

    if not fpsBoosterConnection then
        fpsBoosterConnection = RobloxServices.Workspace.DescendantAdded:Connect(function(desc)
            if fpsBooster_enabled then
                table.insert(fpsQueue, desc)
                processFpsQueue()
            end
        end)
    end
end

local function disableFpsBooster()
    fpsBooster_enabled = false
    fpsQueue = {}
    if fpsBoosterConnection then
        fpsBoosterConnection:Disconnect()
        fpsBoosterConnection = nil
    end
    for inst, state in pairs(originalVisualStates) do
        if inst and inst.Parent then
            pcall(function() inst[state.property] = state.value end)
        end
    end
    originalVisualStates = {}
end

if fpsBooster_enabled then
    enableFpsBooster()
end

-- ──────────────────────────────────────────────────
--  WINDUI MAIN GUI & INDIGO THEME CONFIG
-- ──────────────────────────────────────────────────
local WindUI = nil
local loadOk, loadErr = pcall(function()
    WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)

if not loadOk or not WindUI then
    WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end

WindUI:AddTheme({
    Name = "IndigoDark",
    Accent = Color3.fromHex("#6366F1"),
    Background = Color3.fromHex("#0F0F1A"),
    Container = Color3.fromHex("#181829"),
    Text = Color3.fromHex("#E0E7FF"),
    SubText = Color3.fromHex("#A5B4FC"),
    Border = Color3.fromHex("#312E81"),
})

WindUI:SetTheme("IndigoDark")

local Window = WindUI:CreateWindow({
    Title = "DUSEKKAR SA",
    Icon = "zap",
    Author = "by: FreshLeavesSaken",
    Folder = "DUSSEKA",
    Size = UDim2.fromOffset(450, 560),
    Theme = "IndigoDark",
})

-- ============================== STAMINA & SPEED MODS ==============================

local function stamModule()
    local ok, m = pcall(function()
        return require(RobloxServices.ReplicatedStorage.Systems.Character.Game.Sprinting)
    end)
    return ok and m or nil
end

local function stamIsKiller()
    local ch = LocalPlayer.Character; if not ch then return false end
    local kf = getTeamFolder("Killers")
    return kf and ch:IsDescendantOf(kf)
end

local function stamApply()
    pcall(function()
        local m = stamModule(); if not m then return end
        if not m.DefaultsSet then pcall(function() m.Init() end) end
        local forceNoLoss = stam.noLoss or stamIsKiller()
        m.StaminaLoss = stam.loss; m.StaminaGain = stam.gain
        local abilityCapActive = type(m.StaminaCap) == "number" and m.StaminaCap < (m.MaxStamina or math.huge)
        if not abilityCapActive then
            m.MaxStamina = stam.max
            if type(m.StaminaCap) == "number" then m.StaminaCap = stam.max end
        end
        m.StaminaLossDisabled = forceNoLoss
        if m.Stamina and m.Stamina > stam.max then m.Stamina = stam.current end
        pcall(function() if m.__staminaChangedEvent then m.__staminaChangedEvent:Fire() end end)
    end)
end

local function stamStart()
    if stam.thread then return end
    stam.thread = task.spawn(function()
        while stam.on do
            pcall(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    stamApply()
                end
            end)
            task.wait(0.5)
        end; stam.thread = nil
    end)
end

local function stamStop()
    stam.on = false
    if stam.thread then task.cancel(stam.thread); stam.thread = nil end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.delay(1.5, function()
        pcall(function()
            if stam.on then stamApply(); if not stam.thread then stamStart() end end
        end)
    end)
end)

-- Speed Hack Logic
local function speedModule()
    local ok, m = pcall(function()
        return require(RobloxServices.ReplicatedStorage.Systems.Character.Game.Sprinting)
    end)
    return ok and m or nil
end

local function speedApply()
    pcall(function()
        if not speedHack.on then return end
        local m = speedModule(); if not m then return end
        if not m.DefaultsSet then pcall(function() m.Init() end) end
        if speedHack.speed ~= speedHack.lastApplied then
            m.SprintSpeed = speedHack.speed; pcall(function() m.MaxSprintSpeed = speedHack.speed end)
            speedHack.lastApplied = speedHack.speed
        end
    end)
end

local function speedStart()
    if speedHack.thread then return end
    speedHack.thread = task.spawn(function()
        while speedHack.on do
            pcall(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    speedApply()
                end
            end)
            task.wait(0.2)
        end; speedHack.thread = nil
    end)
end

local function speedStop()
    speedHack.on = false
    if speedHack.thread then task.cancel(speedHack.thread); speedHack.thread = nil end
    pcall(function()
        local m = speedModule(); if m then m.SprintSpeed = 26; pcall(function() m.MaxSprintSpeed = 26 end) end
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    task.delay(1, function()
        pcall(function()
            speedHack.lastApplied = 0
            if speedHack.on then speedApply(); if not speedHack.thread then speedStart() end end
        end)
    end)
end)

-- ============================== FORSAKEN KILLER HIGHLIGHT & NAME SYSTEM ==============================

local function removeKillerVisuals(model)
    local data = killerHighlights[model]
    if data then
        if data.Connections then
            for _, conn in ipairs(data.Connections) do
                pcall(function() conn:Disconnect() end)
            end
        end
        if data.Highlight then
            pcall(function() data.Highlight:Destroy() end)
        end
        if data.Billboard then
            pcall(function() data.Billboard:Destroy() end)
        end
        killerHighlights[model] = nil
    end
end

local function applyKillerVisuals(model)
    if not model or not model:IsA("Model") then return end
    
    if killerIgnoreNPCs and not isRealPlayer(model) then
        removeKillerVisuals(model)
        return
    end

    removeKillerVisuals(model)

    local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
    if not head then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "KillerHighlight"
    highlight.Adornee = model
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineTransparency = 0.5
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = killerHighlightRate
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = killerVisualsEnabled
    highlight.Parent = model

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "KillerNameBillboard"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 150, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 300
    billboard.Enabled = killerNameLabelsEnabled

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = model.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeColor3 = Color3.fromRGB(255, 0, 0)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 13
    nameLabel.Parent = billboard

    billboard.Parent = model

    local connections = {}
    
    local ancConn = model.AncestryChanged:Connect(function(_, parent)
        if not parent then
            removeKillerVisuals(model)
        end
    end)
    table.insert(connections, ancConn)

    local hum = model:FindFirstChildOfClass("Humanoid")
    if hum then
        local diedConn = hum.Died:Connect(function()
            removeKillerVisuals(model)
        end)
        table.insert(connections, diedConn)
    end

    killerHighlights[model] = {
        Highlight = highlight,
        Billboard = billboard,
        Connections = connections
    }
end

local function updateAllKillerVisuals()
    local playersFolder = RobloxServices.Workspace:FindFirstChild("Players")
    local killersFolder = playersFolder and playersFolder:FindFirstChild("Killers")
    
    for model, _ in pairs(killerHighlights) do
        if not model or not model.Parent or (killerIgnoreNPCs and not isRealPlayer(model)) then
            removeKillerVisuals(model)
        end
    end

    if killersFolder then
        for _, killerModel in ipairs(killersFolder:GetChildren()) do
            if killerModel:IsA("Model") and not killerHighlights[killerModel] then
                applyKillerVisuals(killerModel)
            end
        end
    end
end

local function stopKillerScanLoop()
    if killerScanThread then
        task.cancel(killerScanThread)
        killerScanThread = nil
    end
end

local function startKillerScanLoop()
    stopKillerScanLoop()
    killerScanThread = task.spawn(function()
        while true do
            updateAllKillerVisuals()
            task.wait(math.clamp(killerScanRate, 0.05, 5.0))
        end
    end)
end

task.spawn(function()
    local playersFolder = RobloxServices.Workspace:WaitForChild("Players", 10)
    if not playersFolder then return end

    local killersFolder = playersFolder:WaitForChild("Killers", 10)
    if killersFolder then
        killersFolder.ChildAdded:Connect(function(child)
            task.wait(0.1)
            if child:IsA("Model") then
                applyKillerVisuals(child)
            end
        end)
        killersFolder.ChildRemoved:Connect(function(child)
            removeKillerVisuals(child)
        end)
    end

    startKillerScanLoop()
end)

if stam.on then stamStart() end
if speedHack.on then speedStart() end

-- ============================== GUI TABS ==============================

local tabDusekkar = Window:Tab({ Title = "Dusekkar Aim", Icon = "zap", IconColor = Color3.fromHex("#818CF8"), ShowTabTitle = false })
local tabKillerAbilities = Window:Tab({ Title = "Killer Abilities", Icon = "skull", IconColor = Color3.fromHex("#EF4444"), ShowTabTitle = false })
local tabGenerator = Window:Tab({ Title = "Generator", Icon = "circuit-board", IconColor = Color3.fromHex("#10B981"), ShowTabTitle = false })
local tabPlayer = Window:Tab({ Title = "Local Player", Icon = "user", IconColor = Color3.fromHex("#A5B4FC"), ShowTabTitle = false })
local tabVisuals = Window:Tab({ Title = "Killers ESP", Icon = "eye", IconColor = Color3.fromHex("#6366F1"), ShowTabTitle = false })

-- Generator Auto Solve Tab
do
    local sec_gen = tabGenerator:Section({ Title = "Auto-Gen (Generator Auto Solve)", Opened = true })

    sec_gen:Toggle({
        Title = "Enable Auto-Gen", Default = flow.on, Type = "Checkbox", Flag = "flowOn",
        Callback = function(on)
            flow.on = on
            saveConfig()
        end
    })

    sec_gen:Slider({
        Title = "Node Solve Speed (s)", Flag = "flowNodeDelay", Step = 0.01,
        Value = { Min = 0.01, Max = 0.50, Default = flow.nodeDelay },
        Callback = function(v)
            flow.nodeDelay = v
            saveConfig()
        end
    })

    sec_gen:Slider({
        Title = "Line Pause Delay (s)", Flag = "flowLineDelay", Step = 0.05,
        Value = { Min = 0.00, Max = 1.00, Default = flow.lineDelay },
        Callback = function(v)
            flow.lineDelay = v
            saveConfig()
        end
    })
end

-- Local Player Settings Tab
do
    local sec_stamina = tabPlayer:Section({ Title = "Stamina Modifications", Opened = true })

    sec_stamina:Toggle({
        Title = "Custom Stamina",
        Type = "Checkbox",
        Flag = "stamOn",
        Default = stam.on,
        Callback = function(on)
            pcall(function()
                stam.on = on
                if on then stamStart() else stamStop() end
                saveConfig()
            end)
        end
    })

    sec_stamina:Toggle({
        Title = "Infinite Stamina",
        Type = "Checkbox",
        Flag = "stamNoLoss",
        Default = stam.noLoss,
        Callback = function(on)
            pcall(function()
                stam.noLoss = on
                stamApply()
                if on and not stam.on then
                    stam.on = true
                    stamStart()
                end
                saveConfig()
            end)
        end
    })

    sec_stamina:Slider({
        Title = "Loss Rate", Flag = "stamLoss", Step = 1, Value = { Min = 0, Max = 50, Default = stam.loss },
        Callback = function(v) pcall(function() stam.loss = v; saveConfig() end) end
    })

    sec_stamina:Slider({
        Title = "Gain Rate", Flag = "stamGain", Step = 1, Value = { Min = 0, Max = 50, Default = stam.gain },
        Callback = function(v) pcall(function() stam.gain = v; saveConfig() end) end
    })

    sec_stamina:Slider({
        Title = "Max Pool", Flag = "stamMax", Step = 1, Value = { Min = 50, Max = 500, Default = stam.max },
        Callback = function(v) pcall(function() stam.max = v; saveConfig() end) end
    })

    sec_stamina:Slider({
        Title = "Current Value", Flag = "stamCurrent", Step = 1, Value = { Min = 0, Max = 500, Default = stam.current },
        Callback = function(v) pcall(function() stam.current = v; saveConfig() end) end
    })

    local sec_speed = tabPlayer:Section({ Title = "Speed Hack", Opened = true })

    sec_speed:Toggle({
        Title = "Custom Sprint Speed", Type = "Checkbox", Flag = "speedOn", Default = speedHack.on,
        Callback = function(on)
            pcall(function()
                speedHack.on = on
                speedHack.lastApplied = 0
                if on then speedStart() else speedStop() end
                saveConfig()
            end)
        end
    })

    sec_speed:Input({
        Title = "Sprint Speed Value", Flag = "speedValue", Default = tostring(speedHack.speed), Placeholder = "e.g. 30",
        Callback = function(t)
            pcall(function()
                local n = tonumber(t)
                if n and n > 0 and n <= 200 then
                    speedHack.speed = n
                    speedHack.lastApplied = 0
                    saveConfig()
                end
            end)
        end
    })

    local sec_performance = tabPlayer:Section({ Title = "Performance & FPS Optimization", Opened = true })

    sec_performance:Toggle({
        Title = "FPS Booster (Remove Decals & Particles)", Type = "Checkbox", Flag = "fpsBoosterEnabled", Default = fpsBooster_enabled,
        Callback = function(on)
            pcall(function()
                if on then enableFpsBooster() else disableFpsBooster() end
                saveConfig()
            end)
        end
    })
end

-- Visuals ESP Tab
do
    local sec_esp = tabVisuals:Section({ Title = "Forsaken Killers Visuals", Opened = true })

    sec_esp:Toggle({
        Title = "Highlight Killers", Default = killerVisualsEnabled, Type = "Checkbox", Flag = "killerHighlightEnabled",
        Callback = function(on)
            killerVisualsEnabled = on
            for _, data in pairs(killerHighlights) do
                if data.Highlight then data.Highlight.Enabled = on end
            end
            saveConfig()
        end
    })

    sec_esp:Toggle({
        Title = "Show Killer Name Labels", Default = killerNameLabelsEnabled, Type = "Checkbox", Flag = "killerNamesEnabled",
        Callback = function(on)
            killerNameLabelsEnabled = on
            for _, data in pairs(killerHighlights) do
                if data.Billboard then data.Billboard.Enabled = on end
            end
            saveConfig()
        end
    })

    sec_esp:Toggle({
        Title = "Ignore NPCs / Bots", Default = killerIgnoreNPCs, Type = "Checkbox", Flag = "killerIgnoreNPCs",
        Callback = function(on)
            killerIgnoreNPCs = on
            updateAllKillerVisuals()
            saveConfig()
        end
    })

    sec_esp:Slider({
        Title = "Highlight Scan Speed / Interval (s)", Flag = "killerScanRate", Step = 0.05, Value = { Min = 0.05, Max = 3.0, Default = killerScanRate },
        Callback = function(v)
            killerScanRate = v
            startKillerScanLoop()
            saveConfig()
        end
    })

    sec_esp:Slider({
        Title = "Highlight Transparency / Fill Rate", Flag = "killerHighlightRate", Step = 0.05, Value = { Min = 0.0, Max = 1.0, Default = killerHighlightRate },
        Callback = function(v)
            killerHighlightRate = v
            for _, data in pairs(killerHighlights) do
                if data.Highlight then data.Highlight.FillTransparency = v end
            end
            saveConfig()
        end
    })

    sec_esp:Button({
        Title = "Refresh Killer Visuals Now",
        Callback = function() updateAllKillerVisuals() end
    })
end

-- ============================== PLASMA BEAM SILENT AIM & VELOCITY PREDICTION ==============================
local currentPredictedPos          = nil
local lastTargetHRP                = nil
local lastFrameTime                = os.clock()

local targetBoxGui                 = nil
local plasma_rf                    = nil

local visualSphere                 = nil
local visualCylinder               = nil
local renderConnection             = nil
local plasma_motionData            = {}

local function plasmaGetVelocity(part)
    if not part or not part.Parent then return Vector3.zero, Vector3.zero end

    local model = part.Parent
    local hum = model and model:FindFirstChildOfClass("Humanoid")

    local now = os.clock()
    local pos = part.Position
    local data = plasma_motionData[part]

    if not data then
        plasma_motionData[part] = { 
            lastPos = pos, 
            lastTime = now, 
            vel = Vector3.zero, 
            accel = Vector3.zero,
            isLagging = false,
        }
        return Vector3.zero, Vector3.zero
    end

    local dt = now - data.lastTime
    if dt < 0.005 then
        return data.vel, data.accel
    end

    local deltaPos = (pos - data.lastPos)
    local deltaVel = deltaPos / dt
    data.lastPos = pos
    data.lastTime = now

    local physVel = Vector3.zero
    if part:IsA("BasePart") then
        physVel = part.AssemblyLinearVelocity or part.Velocity or Vector3.zero
    end

    local rawVel = (deltaPos.Magnitude > physVel.Magnitude) and deltaVel or physVel

    local horizontalVel = Vector3.new(rawVel.X, 0, rawVel.Z)
    local isStandingStill = (hum and hum.MoveDirection.Magnitude < 0.05) or (horizontalVel.Magnitude < 0.8)

    if plasma_pingDetection then
        if dt > 0.12 or (deltaPos.Magnitude < 0.01 and physVel.Magnitude > 2) then
            data.isLagging = true
        else
            data.isLagging = false
        end
    else
        data.isLagging = false
    end

    if isStandingStill then
        data.vel = Vector3.zero
        data.accel = Vector3.zero
        return Vector3.zero, Vector3.zero
    end

    if rawVel.Magnitude > 250 then rawVel = Vector3.zero end

    local rawAccel = (rawVel - data.vel) / dt
    if rawAccel.Magnitude > 150 then rawAccel = Vector3.zero end

    local dot = 1
    if data.vel.Magnitude > 1 and rawVel.Magnitude > 1 then
        dot = data.vel.Unit:Dot(rawVel.Unit)
    end

    local smoothFactor = math.clamp(dt * 18.0, 0.1, 0.75)
    if dot < 0.3 then smoothFactor = math.clamp(dt * 30.0, 0.3, 0.9) end

    local newVel = data.vel:Lerp(rawVel, smoothFactor)
    local newAccel = data.accel:Lerp(rawAccel, smoothFactor * 0.5)

    data.vel = newVel
    data.accel = newAccel

    return newVel, newAccel
end

local function calculateTargetPos(hrpPart)
    if not hrpPart or not hrpPart.Parent then return nil, true end
    local model = hrpPart.Parent
    
    local torsoPart = model:FindFirstChild("Torso") 
        or model:FindFirstChild("UpperTorso") 
        or hrpPart

    local heightOffset = Vector3.new(0, plasma_aimOffset, 0)
    local originPos = torsoPart.Position + heightOffset

    local isTargetLagging = false
    local pingSeconds = 0

    pcall(function()
        local pingItem = RobloxServices.Stats.Network.ServerStatsItem["Data Ping"]
        if pingItem then pingSeconds = (pingItem:GetValue() / 1000) end
    end)

    local data = plasma_motionData[torsoPart]
    if plasma_pingDetection then
        if pingSeconds > 0.25 or (data and data.isLagging) then
            isTargetLagging = true
        end
    end

    local vel, accel = plasmaGetVelocity(torsoPart)
    local hum = model:FindFirstChildOfClass("Humanoid")
    
    local isStationary = (vel.Magnitude < 0.1) 
        or (hum and hum.MoveDirection.Magnitude < 0.05) 
        or (Vector3.new(vel.X, 0, vel.Z).Magnitude < 0.8)

    if isStationary or isTargetLagging then
        return originPos, true
    else
        local leadTime = plasma_prediction + (pingSeconds * 0.5)
        local predictedOffset = (vel * leadTime) + (0.5 * accel * (leadTime ^ 2))

        if predictedOffset.Magnitude > 35 then
            predictedOffset = predictedOffset.Unit * 35
        end

        local targetPos = originPos + predictedOffset

        local rayDir = targetPos - originPos
        if rayDir.Magnitude > 0.05 then
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Exclude

            local ignoreList = { model }
            if LocalPlayer.Character then table.insert(ignoreList, LocalPlayer.Character) end
            if visualSphere then table.insert(ignoreList, visualSphere) end
            if visualCylinder then table.insert(ignoreList, visualCylinder) end

            rayParams.FilterDescendantsInstances = ignoreList

            local hitResult = RobloxServices.Workspace:Raycast(originPos, rayDir, rayParams)
            if hitResult then
                targetPos = hitResult.Position + (hitResult.Normal * 0.2)
            end
        end

        return targetPos, false
    end
end

-- Helper to get Lowest HP and Nearest Survivor
local function getLowestNearestSurvivor()
    local char = LocalPlayer.Character
    if not char then return nil end
    local myHRP = char:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end

    local pf = RobloxServices.Workspace:FindFirstChild("Players")
    local survivorsFolder = pf and pf:FindFirstChild("Survivors")
    
    local candidateModels = {}
    if survivorsFolder then
        for _, m in ipairs(survivorsFolder:GetChildren()) do
            table.insert(candidateModels, m)
        end
    else
        for _, plr in ipairs(RobloxServices.Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                table.insert(candidateModels, plr.Character)
            end
        end
    end

    local bestHRP, bestScore = nil, math.huge
    for _, model in ipairs(candidateModels) do
        if model:IsA("Model") and model ~= char then
            if not (plasma_ignoreNPCs and not isRealPlayer(model)) then
                local hrp = model:FindFirstChild("HumanoidRootPart")
                local hum = model:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local dist = (hrp.Position - myHRP.Position).Magnitude
                    local score = (hum.Health * 10) + dist
                    if score < bestScore then
                        bestScore = score
                        bestHRP = hrp
                    end
                end
            end
        end
    end

    return bestHRP
end

-- ============================== KILLER ABILITIES (AUTOMATIC FORSAKEN DETECTION) ==============================

local function executeKillerAbilitySpinAndAim(abilityConfig, abilityName)
    if abilityConfig.isSpinning then return end
    abilityConfig.isSpinning = true

    task.spawn(function()
        local char = LocalPlayer.Character
        if not char then
            abilityConfig.isSpinning = false
            return
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            abilityConfig.isSpinning = false
            return
        end

        ------------------------------------------------------------------
        -- PHASE 1: SPIN DURATION (Rotates ONLY character body)
        ------------------------------------------------------------------
        local spinStart = os.clock()
        local spinDuration = math.clamp(abilityConfig.duration, 0.05, 10.0)
        local speed = math.clamp(abilityConfig.spinSpeed, 1, 300)

        while os.clock() - spinStart < spinDuration do
            local dt = task.wait()
            if not LocalPlayer.Character or not hrp.Parent then break end
            
            -- Rotate character HumanoidRootPart only
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(speed * dt * 60), 0)
        end

        ------------------------------------------------------------------
        -- PHASE 2: AIM LOCK DURATION (Locks ONLY character body toward target)
        ------------------------------------------------------------------
        local aimStart = os.clock()
        local aimDuration = math.clamp(abilityConfig.aimDuration or 0.5, 0.05, 10.0)

        while os.clock() - aimStart < aimDuration do
            local dt = task.wait()
            if not LocalPlayer.Character or not hrp.Parent then break end

            local targetHRP = getLowestNearestSurvivor()
            if targetHRP and targetHRP.Parent then
                local predictedTargetPos = calculateTargetPos(targetHRP)
                if predictedTargetPos then
                    -- Rotate ONLY the character's HumanoidRootPart toward predicted target position
                    local targetPosSameY = Vector3.new(predictedTargetPos.X, hrp.Position.Y, predictedTargetPos.Z)
                    if (targetPosSameY - hrp.Position).Magnitude > 0.01 then
                        hrp.CFrame = CFrame.lookAt(hrp.Position, targetPosSameY)
                    end
                end
            end
        end

        abilityConfig.isSpinning = false
    end)
end

local function executeMassInfection()
    executeKillerAbilitySpinAndAim(massInfection, "MassInfection")
end

local function executeEntanglement()
    executeKillerAbilitySpinAndAim(entanglement, "Entanglement")
end

------------------------------------------------------------------
-- AUTOMATIC FORSAKEN ABILITY CAST DETECTOR
------------------------------------------------------------------
local lastAbilityTriggerTime = 0

local function checkAndTriggerAbility(strName)
    if not killerAutoDetectAbilities then return end
    if type(strName) ~= "string" or #strName < 3 then return end

    local now = os.clock()
    if now - lastAbilityTriggerTime < 0.2 then return end

    local lower = strName:lower()

    if massInfection.enabled and (lower:find("mass") or lower:find("infection")) then
        lastAbilityTriggerTime = now
        executeMassInfection()
    elseif entanglement.enabled and (lower:find("entangl") or lower:find("tangle")) then
        lastAbilityTriggerTime = now
        executeEntanglement()
    end
end

-- Hook outgoing remotes for Forsaken ability casts
if typeof(hookmetamethod) == "function" then
    local oldNc
    oldNc = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if (method == "FireServer" or method == "InvokeServer") then
            local args = {...}
            for _, arg in ipairs(args) do
                if type(arg) == "string" then
                    checkAndTriggerAbility(arg)
                elseif type(arg) == "table" then
                    for _, v in pairs(arg) do
                        if type(v) == "string" then
                            checkAndTriggerAbility(v)
                        end
                    end
                end
            end
        end
        return oldNc(self, ...)
    end)
end

-- Listen to Character animations and instances for ability use
local function setupCharacterAbilityListeners(character)
    if not character then return end

    character.ChildAdded:Connect(function(child)
        checkAndTriggerAbility(child.Name)
    end)

    task.spawn(function()
        local hum = character:WaitForChild("Humanoid", 5)
        if not hum then return end
        local animator = hum:WaitForChild("Animator", 5) or hum
        animator.AnimationPlayed:Connect(function(track)
            if track and track.Animation then
                checkAndTriggerAbility(track.Animation.Name)
            end
        end)
    end)
end

if LocalPlayer.Character then
    setupCharacterAbilityListeners(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(setupCharacterAbilityListeners)

-- Input Keybind Listener for Killer Abilities
RobloxServices.UserInput.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if massInfection.enabled and input.KeyCode == massInfection.keybind then
            executeMassInfection()
        elseif entanglement.enabled and input.KeyCode == entanglement.keybind then
            executeEntanglement()
        end
    end
end)

-- Killer Abilities Section GUI Construction
do
    local sec_auto = tabKillerAbilities:Section({ Title = "Forsaken Auto-Detection", Opened = true })

    sec_auto:Toggle({
        Title = "Auto-Detect Ability Casts (Forsaken)", Default = killerAutoDetectAbilities, Type = "Checkbox", Flag = "autoDetectAbilities",
        Callback = function(on)
            killerAutoDetectAbilities = on
            saveConfig()
        end
    })

    local sec_mass = tabKillerAbilities:Section({ Title = "Mass Infection Aimbot", Opened = true })

    sec_mass:Toggle({
        Title = "Enable Mass Infection Aimbot", Default = massInfection.enabled, Type = "Checkbox", Flag = "massInfectionEnabled",
        Callback = function(on)
            massInfection.enabled = on
            saveConfig()
        end
    })

    sec_mass:Slider({
        Title = "Spin Duration (s)", Flag = "massInfectionDuration", Step = 0.05,
        Value = { Min = 0.1, Max = 5.0, Default = massInfection.duration },
        Callback = function(v)
            massInfection.duration = v
            saveConfig()
        end
    })

    sec_mass:Slider({
        Title = "Aim Lock Duration (s)", Flag = "massInfectionAimDuration", Step = 0.05,
        Value = { Min = 0.05, Max = 5.0, Default = massInfection.aimDuration },
        Callback = function(v)
            massInfection.aimDuration = v
            saveConfig()
        end
    })

    sec_mass:Slider({
        Title = "Spin Speed", Flag = "massInfectionSpeed", Step = 1,
        Value = { Min = 5, Max = 150, Default = massInfection.spinSpeed },
        Callback = function(v)
            massInfection.spinSpeed = v
            saveConfig()
        end
    })

    sec_mass:Keybind({
        Title = "Mass Infection Keybind", Flag = "massInfectionKeybind", Default = "E",
        Callback = function(key)
            if key then massInfection.keybind = key end
        end
    })

    sec_mass:Button({
        Title = "Trigger Mass Infection Now",
        Callback = function() executeMassInfection() end
    })

    local sec_entangle = tabKillerAbilities:Section({ Title = "Entanglement Aimbot", Opened = true })

    sec_entangle:Toggle({
        Title = "Enable Entanglement Aimbot", Default = entanglement.enabled, Type = "Checkbox", Flag = "entanglementEnabled",
        Callback = function(on)
            entanglement.enabled = on
            saveConfig()
        end
    })

    sec_entangle:Slider({
        Title = "Spin Duration (s)", Flag = "entanglementDuration", Step = 0.05,
        Value = { Min = 0.05, Max = 3.0, Default = entanglement.duration },
        Callback = function(v)
            entanglement.duration = v
            saveConfig()
        end
    })

    sec_entangle:Slider({
        Title = "Aim Lock Duration (s)", Flag = "entanglementAimDuration", Step = 0.05,
        Value = { Min = 0.05, Max = 5.0, Default = entanglement.aimDuration },
        Callback = function(v)
            entanglement.aimDuration = v
            saveConfig()
        end
    })

    sec_entangle:Slider({
        Title = "Spin Speed", Flag = "entanglementSpeed", Step = 1,
        Value = { Min = 5, Max = 150, Default = entanglement.spinSpeed },
        Callback = function(v)
            entanglement.spinSpeed = v
            saveConfig()
        end
    })

    sec_entangle:Keybind({
        Title = "Entanglement Keybind", Flag = "entanglementKeybind", Default = "R",
        Callback = function(key)
            if key then entanglement.keybind = key end
        end
    })

    sec_entangle:Button({
        Title = "Trigger Entanglement Now",
        Callback = function() executeEntanglement() end
    })
end

-- PlasmaBeam Aim Tab
do
    local sec_027 = tabDusekkar:Section({ Title = "PlasmaBeam Silent Aim", Opened = true })

    local function isTargetVisible(targetPart)
        local char = LocalPlayer.Character
        if not char then return false end
        
        local origin = CurrentCamera.CFrame.Position
        local dest = targetPart.Position
        local direction = dest - origin
        
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {char, CurrentCamera}
        
        local result = RobloxServices.Workspace:Raycast(origin, direction, params)
        if result then
            local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
            if hitModel and hitModel == targetPart.Parent then return true end
            return false
        end
        return true
    end

    local function plasmaGetTarget()
        local char = LocalPlayer.Character; if not char then return nil end
        local myHRP = char:FindFirstChild("HumanoidRootPart"); if not myHRP then return nil end
        
        local pf = RobloxServices.Workspace:FindFirstChild("Players")
        local targetFolder = pf and pf:FindFirstChild(plasma_targetType)
        if not targetFolder then return nil end
        
        local best, bestScore = nil, math.huge
        for _, model in ipairs(targetFolder:GetChildren()) do
            if model ~= char then
                if not (plasma_ignoreNPCs and not isRealPlayer(model)) then
                    local hrp = model:FindFirstChild("HumanoidRootPart")
                    local hum = model:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        if plasma_throughWalls or isTargetVisible(hrp) then
                            local d = (hrp.Position - myHRP.Position).Magnitude
                            local score = math.huge

                            if plasma_targetSelectionMode == "Nearest" then
                                score = d
                            elseif plasma_targetSelectionMode == "LowestHp" then
                                score = (hum.Health * 10000) + d
                            elseif plasma_targetSelectionMode == "LowestHp&Nearest" then
                                score = (hum.Health) * d
                            end

                            if score < bestScore then 
                                bestScore = score
                                best = hrp 
                            end
                        end
                    end
                end
            end
        end
        return best
    end

    local function destroyPredictionVisuals()
        if visualSphere then visualSphere:Destroy(); visualSphere = nil end
        if visualCylinder then visualCylinder:Destroy(); visualCylinder = nil end
    end

    local function updatePredictionVisuals(targetPos, originPos)
        if not sphere_visualsEnabled then
            destroyPredictionVisuals()
            return
        end

        if not visualSphere or not visualSphere.Parent then
            visualSphere = Instance.new("Part")
            visualSphere.Name = "PredictionSphere"
            visualSphere.Shape = Enum.PartType.Ball
            visualSphere.CanCollide = false
            visualSphere.CanQuery = false
            visualSphere.CanTouch = false
            visualSphere.Anchored = true
            visualSphere.CastShadow = false
            visualSphere.Parent = RobloxServices.Workspace
        end

        visualSphere.Color = sphere_color
        visualSphere.Transparency = sphere_transparency
        visualSphere.Material = sphere_material
        visualSphere.Size = Vector3.new(sphere_size, sphere_size, sphere_size)
        visualSphere.CFrame = CFrame.new(targetPos)

        if cylinder_visualsEnabled and originPos then
            local dist = (targetPos - originPos).Magnitude
            if dist > 0.05 then
                if not visualCylinder or not visualCylinder.Parent then
                    visualCylinder = Instance.new("Part")
                    visualCylinder.Name = "PredictionCylinder"
                    visualCylinder.Shape = Enum.PartType.Cylinder
                    visualCylinder.CanCollide = false
                    visualCylinder.CanQuery = false
                    visualCylinder.CanTouch = false
                    visualCylinder.Anchored = true
                    visualCylinder.CastShadow = false
                    visualCylinder.Parent = RobloxServices.Workspace
                end

                visualCylinder.Color = sphere_color
                visualCylinder.Transparency = sphere_transparency
                visualCylinder.Material = sphere_material
                visualCylinder.Size = Vector3.new(dist, cylinder_thickness, cylinder_thickness)

                local midPoint = (originPos + targetPos) / 2
                visualCylinder.CFrame = CFrame.lookAt(midPoint, targetPos) * CFrame.Angles(0, math.rad(90), 0)
            elseif visualCylinder then
                visualCylinder:Destroy(); visualCylinder = nil
            end
        elseif visualCylinder then
            visualCylinder:Destroy(); visualCylinder = nil
        end
    end

    local function startVisualizer()
        if renderConnection then return end
        
        local updateEvent = RobloxServices.RunService.PreRender or RobloxServices.RunService.RenderStepped
        lastFrameTime = os.clock()

        renderConnection = updateEvent:Connect(function()
            if not plasma_enabled then
                currentPredictedPos = nil
                lastTargetHRP = nil
                destroyPredictionVisuals()
                return
            end
            
            local now = os.clock()
            local dt = math.clamp(now - lastFrameTime, 0.001, 0.1)
            lastFrameTime = now

            local hrp = plasmaGetTarget()
            if hrp then
                local rawTargetPos, isDirectAim = calculateTargetPos(hrp)
                
                local targetModel = hrp.Parent
                local originPart = targetModel and (targetModel:FindFirstChild("Torso") or targetModel:FindFirstChild("UpperTorso") or hrp)
                local originPos = originPart and (originPart.Position + Vector3.new(0, plasma_aimOffset, 0)) or hrp.Position

                if hrp ~= lastTargetHRP or not currentPredictedPos or isDirectAim then
                    currentPredictedPos = rawTargetPos
                    lastTargetHRP = hrp
                else
                    if plasma_predictionSpeed >= 9.8 then
                        currentPredictedPos = rawTargetPos
                    else
                        local lerpRate = plasma_predictionSpeed * 12.0
                        local lerpAlpha = math.clamp(dt * lerpRate, 0.02, 1.0)
                        currentPredictedPos = currentPredictedPos:Lerp(rawTargetPos, lerpAlpha)
                    end
                end

                if currentPredictedPos and currentPredictedPos.X == currentPredictedPos.X then
                    updatePredictionVisuals(currentPredictedPos, originPos)
                end
            else
                currentPredictedPos = nil
                lastTargetHRP = nil
                destroyPredictionVisuals()
            end
        end)
    end

    local function stopVisualizer()
        if renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end
        currentPredictedPos = nil
        lastTargetHRP = nil
        destroyPredictionVisuals()
    end

    local function updateTargetBoxVisuals(button)
        if not button then return end
        if plasma_targetType == "Survivors" then
            button.Text = "Target: Survivor"
            button.TextColor3 = Color3.fromRGB(129, 140, 248)
        else
            button.Text = "Target: Killer"
            button.TextColor3 = Color3.fromRGB(248, 113, 113)
        end
    end

    local function syncTargetBoxVisuals()
        if targetBoxGui then
            local button = targetBoxGui:FindFirstChildOfClass("TextButton")
            if button then updateTargetBoxVisuals(button) end
        end
    end

    local function destroyTargetBox()
        if targetBoxGui then
            targetBoxGui:Destroy()
            targetBoxGui = nil
        end
    end

    local function createTargetBox()
        destroyTargetBox()

        local parent = getGuiParent()
        if not parent then return end

        targetBoxGui = Instance.new("ScreenGui")
        targetBoxGui.Name = "TargetBoxChangerGui"
        targetBoxGui.ResetOnSpawn = false
        targetBoxGui.Parent = parent

        local button = Instance.new("TextButton")
        button.Size = UDim2.fromOffset(140, 35)
        button.Position = UDim2.new(1, -150, 0, 70)
        button.BackgroundColor3 = Color3.fromHex("#181829")
        button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamBold
        button.TextSize = 13
        button.Parent = targetBoxGui

        local uiCorner = Instance.new("UICorner")
        uiCorner.CornerRadius = UDim.new(0, 8)
        uiCorner.Parent = button

        local uiStroke = Instance.new("UIStroke")
        uiStroke.Color = Color3.fromHex("#4338CA")
        uiStroke.Thickness = 1.5
        uiStroke.Parent = button

        updateTargetBoxVisuals(button)

        button.MouseButton1Click:Connect(function()
            if plasma_targetType == "Killers" then
                plasma_targetType = "Survivors"
            else
                plasma_targetType = "Killers"
            end
            updateTargetBoxVisuals(button)
            saveConfig()
        end)
    end

    local function plasmaUnpatch()
        if plasma_rf then rfDispatch:uninstall(plasma_rf) end
        plasma_rf = nil
        stopVisualizer()
        destroyTargetBox()
    end
    
    LocalPlayer.CharacterAdded:Connect(function() 
        plasma_motionData = {} 
        lastTargetHRP = nil
    end)

    sec_027:Toggle({
        Title = "Enable PlasmaBeam Aim", Default = plasma_enabled, Type = "Checkbox", Flag = "plasmaEnabled",
        Callback = function(on) 
            plasma_enabled = on 
            if on then startVisualizer() else stopVisualizer() end
            saveConfig()
        end
    })

    sec_027:Toggle({
        Title = "Ignore NPCs / Bots", Default = plasma_ignoreNPCs, Type = "Checkbox", Flag = "plasmaIgnoreNPCs",
        Callback = function(on) plasma_ignoreNPCs = on; saveConfig() end
    })

    sec_027:Toggle({
        Title = "Ping & Lag Auto-Detection", Default = plasma_pingDetection, Type = "Checkbox", Flag = "plasmaPingDetection",
        Callback = function(on) plasma_pingDetection = on; saveConfig() end
    })

    sec_027:Dropdown({
        Title = "Target Priority", Values = {"Nearest", "LowestHp", "LowestHp&Nearest"}, Default = plasma_targetSelectionMode, Flag = "plasmaTargetSelectionMode",
        Callback = function(v) plasma_targetSelectionMode = v; saveConfig() end
    })

    sec_027:Dropdown({
        Title = "Target Type", Values = {"Killers", "Survivors"}, Default = plasma_targetType, Flag = "plasmaTargetType",
        Callback = function(v) 
            plasma_targetType = v 
            syncTargetBoxVisuals()
            saveConfig()
        end
    })

    sec_027:Toggle({
        Title = "TargetBoxChanger Widget", Default = targetBoxEnabled, Type = "Checkbox", Flag = "targetBoxChanger",
        Callback = function(on)
            targetBoxEnabled = on
            if on then createTargetBox() else destroyTargetBox() end
            saveConfig()
        end
    })

    sec_027:Toggle({
        Title = "Protect Through Walls", Default = plasma_throughWalls, Type = "Checkbox", Flag = "plasmaThroughWalls",
        Callback = function(on) plasma_throughWalls = on; saveConfig() end
    })
    
    sec_027:Slider({
        Title = "Prediction (s)", Flag = "plasmaPrediction", Value = {Min=0.0, Max=1.0, Default=plasma_prediction}, Step = 0.01,
        Callback = function(v) plasma_prediction = v; saveConfig() end
    })

    sec_027:Slider({
        Title = "Prediction Speed Multiplier", Flag = "plasmaPredictionSpeed", Value = {Min=0.1, Max=10.0, Default=plasma_predictionSpeed}, Step = 0.1,
        Callback = function(v) plasma_predictionSpeed = v; saveConfig() end
    })
    
    sec_027:Slider({
        Title = "Aim Height Offset", Flag = "plasmaAimOffset", Value = {Min=-5.0, Max=5.0, Default=plasma_aimOffset}, Step = 0.1,
        Callback = function(v) plasma_aimOffset = v; saveConfig() end
    })

    local sec_sphere = tabDusekkar:Section({ Title = "PredictedSphere & Line Config", Opened = true })

    sec_sphere:Toggle({
        Title = "Enable Visualizer Sphere", Default = sphere_visualsEnabled, Type = "Checkbox", Flag = "sphereVisualsEnabled",
        Callback = function(on)
            sphere_visualsEnabled = on
            if not on then destroyPredictionVisuals() end
            saveConfig()
        end
    })

    sec_sphere:Toggle({
        Title = "Enable Connecting Cylinder", Default = cylinder_visualsEnabled, Type = "Checkbox", Flag = "cylinderVisualsEnabled",
        Callback = function(on)
            cylinder_visualsEnabled = on
            if not on and visualCylinder then
                visualCylinder:Destroy()
                visualCylinder = nil
            end
            saveConfig()
        end
    })

    sec_sphere:Colorpicker({
        Title = "Visuals Color", Default = sphere_color, Flag = "sphereColor",
        Callback = function(color) sphere_color = color; saveConfig() end
    })

    sec_sphere:Input({
        Title = "Sphere Size", Default = tostring(sphere_size), Placeholder = "Enter size (e.g. 1.0)", Flag = "sphereSize",
        Callback = function(text)
            local num = tonumber(text)
            if num then sphere_size = num; saveConfig() end
        end
    })

    sec_sphere:Input({
        Title = "Cylinder Thickness", Default = tostring(cylinder_thickness), Placeholder = "Enter thickness (e.g. 0.2)", Flag = "cylinderThickness",
        Callback = function(text)
            local num = tonumber(text)
            if num then cylinder_thickness = num; saveConfig() end
        end
    })

    sec_sphere:Input({
        Title = "Transparency", Default = tostring(sphere_transparency), Placeholder = "Enter opacity (0 to 1)", Flag = "sphereTransparency",
        Callback = function(text)
            local num = tonumber(text)
            if num then sphere_transparency = math.clamp(num, 0, 1); saveConfig() end
        end
    })

    local sphereMaterials = {"SmoothPlastic", "Neon", "ForceField", "Glass", "Plastic", "Wood", "Metal"}
    sec_sphere:Dropdown({
        Title = "Material", Values = sphereMaterials, Default = sphere_material.Name, Flag = "sphereMaterial",
        Callback = function(selectedMaterial)
            local success, matEnum = pcall(function() return Enum.Material[selectedMaterial] end)
            if success and matEnum then sphere_material = matEnum; saveConfig() end
        end
    })

    local sec_028 = tabDusekkar:Section({ Title = "Control", Opened = true })
    sec_028:Button({
        Title = "Unload PlasmaBeam Hook", Callback = function()
            plasma_enabled = false; plasmaUnpatch()
        end
    })

    local function getRemoteFunction()
        local storage = RobloxServices.ReplicatedStorage
        local modules = storage:WaitForChild("Modules", 5)
        if not modules then return nil end
        local net1 = modules:WaitForChild("Network", 5)
        if not net1 then return nil end
        local net2 = net1:WaitForChild("Network", 5)
        if not net2 then return nil end
        return net2:WaitForChild("RemoteFunction", 5)
    end

    local function plasmaPatch()
        local rf = getRemoteFunction()
        if not rf then warn("[dusekkar] Shared RF not found"); return end
        
        plasma_rf = rf
        rfDispatch:install(rf)
        
        rfDispatch:register("plasma", function(reqName, ...)
            if reqName ~= "GetMousePosition" or not plasma_enabled then return nil end
            
            if currentPredictedPos and currentPredictedPos.X == currentPredictedPos.X then
                return currentPredictedPos
            end

            local hrp = plasmaGetTarget()
            if not hrp then return nil end
            
            local rawTargetPos = calculateTargetPos(hrp)
            return rawTargetPos
        end)

        if plasma_enabled then
            startVisualizer()
            if targetBoxEnabled then createTargetBox() end
        end
    end

    task.spawn(plasmaPatch)
end

-- Global Config & Unload System Tab
local sec_system = tabPlayer:Section({ Title = "Configuration & System" })

sec_system:Button({
    Title = "Save Configuration",
    Callback = function()
        saveConfig()
        WindUI:Notify({ Title = "Config Saved", Content = "Your settings have been saved locally.", Duration = 3 })
    end
})

sec_system:Button({
    Title = "Load Last Configuration",
    Callback = function()
        loadConfig()
        WindUI:Notify({ Title = "Config Loaded", Content = "Your settings have been reloaded.", Duration = 3 })
    end
})

sec_system:Button({
    Title = "Unload Script Completely",
    Callback = function()
        saveConfig()

        stamStop()
        speedStop()
        stopKillerScanLoop()
        disableFpsBooster()

        local storage = RobloxServices.ReplicatedStorage
        local modules = storage:FindFirstChild("Modules")
        local net1 = modules and modules:FindFirstChild("Network")
        local net2 = net1 and net1:FindFirstChild("Network")
        local rf = net2 and net2:FindFirstChild("RemoteFunction")

        if rf then rfDispatch:uninstall(rf) end
        
        for model, _ in pairs(killerHighlights) do
            removeKillerVisuals(model)
        end
        
        local guiParent = getGuiParent()
        local targetBox = guiParent and guiParent:FindFirstChild("TargetBoxChangerGui")
        if targetBox then pcall(function() targetBox:Destroy() end) end
        
        local sphere = RobloxServices.Workspace:FindFirstChild("PredictionSphere")
        if sphere then pcall(function() sphere:Destroy() end) end

        local cylinder = RobloxServices.Workspace:FindFirstChild("PredictionCylinder")
        if cylinder then pcall(function() cylinder:Destroy() end) end
        
        pcall(function() Window:Destroy() end)
    end
})
