--For clearing up underline spam in Visual Studio Code
--local getgenv, Iris, ESP, BetterLib, Get, FormatSemVer, makefolder, CEHGF, EXECUTOR_FILING_FUNCTIONS, Config, FormatHours, CountList

local SCRIPT_NAME = "Emden404Hub"
local SCRIPT_VERSION = {
    --Semantic Versioning
    Major = 1;
    Minor = 1;
    Patch = 7;
}

local genv = getgenv()

if not BetterLib then
    local OldGet = game.HttpGet or game.HttpGetAsync or nil
    assert(OldGet, "No HttpGet function found.")
    -- Load BetterLib first (if it's not already loaded), since every other loaded stuff will depend on it. If BetterLib fails to load, everything else won't work, but at least the error will be more informative.
    loadstring(OldGet(game, "https://raw.githubusercontent.com/Brycki404/BetterLib/refs/heads/main/main.lua", true))()
end
-- Begin Script:

-- Load Dependencies:

if not Iris then
    local IrisLoaderUrl = "https://raw.githubusercontent.com/Brycki404/Iris/refs/heads/main/loader.lua"
    genv.Iris = loadstring(Get(IrisLoaderUrl))()
end

if not ESP then
    local ESP404LibUrl = "https://raw.githubusercontent.com/Brycki404/ESP404Lib/refs/heads/main/main.lua"
    genv.ESP = loadstring(Get(ESP404LibUrl))()
end

-- Loaded Dependencies!

-- Generic Helpers
function genv.FormatHours(seconds: number): string
    seconds = math.max(0, math.floor(seconds)) -- clamp + remove decimals

    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60

    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

function genv.FormatMinutes(seconds: number): string
    seconds = math.max(0, math.floor(seconds))
    local minutes = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%02d:%02d", minutes, secs)
end

function genv.FormatSemVer(versionTable: { Major: number?, Minor: number?, Patch: number? }): string
    assert(type(versionTable) == "table", "FormatSemVer expects a table")

    local major = versionTable.Major or 0
    local minor = versionTable.Minor or 0
    local patch = versionTable.Patch or 0

    return string.format("%d.%d.%d", major, minor, patch)
end
local ver = FormatSemVer(SCRIPT_VERSION)

local Emden_GameId = 4457060041
if game.GameId ~= Emden_GameId then
    warn("[EXECUTOR ERROR]: Script: "..SCRIPT_NAME.." v:"..ver.." failed to load because you're not playing Emden.")
    return
end

-- Setup executor workspace file directory for saving configs and settings:

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--Check Executor Has Global Function
function genv.CEHGF(name: string): boolean
    if genv[name] and type(genv[name]) == "function" then
        return true
    end
    return false
end

genv.EXECUTOR_FILING_FUNCTIONS = {
    "readfile";
    "listfiles";
    "writefile";
    "makefolder";
    "appendfile";
    "isfile";
    "isfolder";
    "delfile";
    "delfolder";
    "loadfile";
    "dofile";
}

genv.EXECUTOR_FILING_ENABLED = true
for i, name in ipairs(EXECUTOR_FILING_FUNCTIONS) do
    if not CEHGF(name) then
        EXECUTOR_FILING_ENABLED = false
        warn("Executor does not support file functions. File saving/loading features will be disabled. Missing function: " .. name)
        break
    end
end

if EXECUTOR_FILING_ENABLED then
    SCRIPT_DIRECTORY_PATH = SCRIPT_NAME .. "_" .. ver
    makefolder(SCRIPT_DIRECTORY_PATH)
    CONFIG_DIRECTORY_PATH = SCRIPT_DIRECTORY_PATH .. "/Configs"
    makefolder(CONFIG_DIRECTORY_PATH)
end

-- Done setting up file directory!

HEALTH_DISPLAY_TYPES = {
    None = "None";
    ["Vertical Bar"] = "Vertical Bar";
    ["Horizontal Bar"] = "Horizontal Bar";
    Text = "Text";
}
SELECTABLE_HEALTH_DISPLAY_TYPES = {
    [1] = HEALTH_DISPLAY_TYPES.None;
    [2] = HEALTH_DISPLAY_TYPES["Vertical Bar"];
    [3] = HEALTH_DISPLAY_TYPES["Horizontal Bar"];
    [4] = HEALTH_DISPLAY_TYPES.Text;
}

ESP_TYPES = {
    ["Box"] = "Box";
    ["Quad"] = "Quad";
    ["Rect"] = "Rect";
}
SELECTABLE_ESP_TYPES = {
    [1] = ESP_TYPES.Box;
    [2] = ESP_TYPES.Quad;
    [3] = ESP_TYPES.Rect;
}

TRACER_ORIGINS = ESP.TRACER_ORIGINS or {
    Mouse = "Mouse";
    Bottom = "Bottom";
    Top = "Top";
    Center = "Center";
}
SELECTABLE_TRACER_ORIGINS = ESP.SELECTABLE_TRACER_ORIGINS or {
    [1] = TRACER_ORIGINS.Mouse;
    [2] = TRACER_ORIGINS.Bottom;
    [3] = TRACER_ORIGINS.Top;
    [4] = TRACER_ORIGINS.Center;
}

TRACER_TARGETS = ESP.TRACER_TARGETS or {
    Center = "Center";
    Top = "Top";
    Bottom = "Bottom";
}
SELECTABLE_TRACER_TARGETS = ESP.SELECTABLE_TRACER_TARGETS or {
    [1] = TRACER_TARGETS.Center;
    [2] = TRACER_TARGETS.Top;
    [3] = TRACER_TARGETS.Bottom;
}

-- External States
local initESPType = table.find(SELECTABLE_ESP_TYPES, ESP_TYPES.Box)
local initTracerOrigin = table.find(SELECTABLE_TRACER_ORIGINS, TRACER_ORIGINS.Center)
local initTracerTarget = table.find(SELECTABLE_TRACER_TARGETS, TRACER_TARGETS.Bottom)
local initHealthDisplayType = table.find(SELECTABLE_HEALTH_DISPLAY_TYPES, HEALTH_DISPLAY_TYPES["Vertical Bar"])

genv.Config = {
    ["showMainWindow"] = Iris.State(true);
    ["showBackground"] = Iris.State(false);
    ["backgroundColor"] = Iris.State(Color3.fromRGB(115, 140, 152));
    ["backgroundTransparency"] = Iris.State(0);
    ["showRuntimeInfo"] = Iris.State(false);
    ["showStyleEditor"] = Iris.State(false);
    ["showDebugWindow"] = Iris.State(false);
    --Referring to Iris' GlobalConfig:
    ["IrisSizingConfig"] = Iris.State({});
    ["IrisColorsConfig"] = Iris.State({});
    ["IrisFontsConfig"] = Iris.State({});

    ["windowKeyCode"] = Iris.State("F3");

    ["antis"] = Iris.State({
        ["antiCuffEnabled"] = false;
        ["antiRagdollEnabled"] = false;
        ["antiTazerEnabled"] = false;
        ["antiHackBypassEnabled"] = false;
    });

    ["carDamageDisabled"] = Iris.State(false);
    ["vehicleNoclipEnabled"] = Iris.State(false);

    ["ghostriderEnabled"] = Iris.State(false);
    ["nitrousKeybind"] = Iris.State("LeftShift");
    ["airbrakeKeybind"] = Iris.State("LeftCtrl");
    ["nitrous"] = Iris.State(100);
    ["airbrake"] = Iris.State(0.005);  -- Range 0 to 1 (0.1 is slow stop, 0.9 is almost instant)

    ["rocketLeagueControls"] = Iris.State({
        ["airRollEnabled"] = false;
        ["airPitchEnabled"] = false;
        ["powerSlideEnabled"] = false;
    });
    ["airRollLeftKeybind"] = Iris.State("R");
    ["airRollRightKeybind"] = Iris.State("T");
    ["airPitchUpKeybind"] = Iris.State("F");
    ["airPitchDownKeybind"] = Iris.State("V");
    ["powerSlideLeftKeybind"] = Iris.State("A");
    ["powerSlideRightKeybind"] = Iris.State("D");
    ["airRollStrength"] = Iris.State(50000); -- Degrees
    ["airPitchStrength"] = Iris.State(50000); -- Degrees
    ["powerSlideStrength"] = Iris.State(50000); -- Degrees

    ["ESP"] = {
        ["MasterMaxRenderDistance"] = Iris.State(20000);
        ["MasterShapes"] = Iris.State(true);
        ["MasterText"] = Iris.State(true);
        ["MasterTracers"] = Iris.State(false);
        ["Categories"] = {
            ["Player"] = {
                ["MaxRenderDistance"] = Iris.State(20000);
                ["Shapes"] = Iris.State(true);
                ["Text"] = Iris.State(true);
                ["Tracers"] = Iris.State(false);
                ["Color"] = Iris.State(Color3.new(1, 1, 1));
                ["Transparency"] = Iris.State(0);
                ["ESPType"] = Iris.State(initESPType);
                ["TracerOrigin"] = Iris.State(initTracerOrigin);
                ["TracerTarget"] = Iris.State(initTracerTarget);

                ["MaxHealthDistance"] = Iris.State(300);
                ["HealthDisplayType"] = Iris.State(initHealthDisplayType);
                ["DisplayHealthText"] = Iris.State(true);
            };
        };
    };
}

local SelectableCategories = {
    [1] = "None";
    [2] = "Player";
};
local SelectedCategory = Iris.State(1);

-- Dex++
local dexLoaded = Iris.State(false)
local DEX_URL = "https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"
local RunDex = nil
RunDex = function()
    RunDex = nil
    loadstring(Get(DEX_URL))()
end
-- Hydroxide
local hydroxideLoaded = Iris.State(false)
local RunHydroxide = nil
RunHydroxide = function()
    RunHydroxide = nil
    local owner = "Upbolt"
    local branch = "revision"

    local function webImport(file)
        return loadstring(Get(("https://raw.githubusercontent.com/%s/Hydroxide/%s/%s.lua"):format(owner, branch, file)), file .. '.lua')()
    end

    webImport("init")
    webImport("ui/main")
end
-- Vehicle Fling
local vehicleFlingLoaded = Iris.State(false)
local RunVehicleFling = nil
RunVehicleFling = function()
    RunVehicleFling = nil
    -- ==========================================
    -- GUI SETUP
    -- ==========================================
    local screenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
    screenGui.Name = "MassiveFlingGui"

    -- Invisible container to hold both Search Bar and the List
    local container = Instance.new("Frame", screenGui)
    container.Size = UDim2.new(0, 280, 0, 500) 
    container.Position = UDim2.new(0.05, 0, 0.2, 0)
    container.BackgroundTransparency = 1

    -- Search Bar
    local searchBar = Instance.new("TextBox", container)
    searchBar.Size = UDim2.new(1, 0, 0, 45)
    searchBar.Position = UDim2.new(0, 0, 0, 0)
    searchBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    searchBar.TextColor3 = Color3.new(1, 1, 1)
    searchBar.PlaceholderText = "Search username..."
    searchBar.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    searchBar.Font = Enum.Font.SourceSansBold
    searchBar.TextSize = 20
    searchBar.ClearTextOnFocus = false

    -- Player List
    local frame = Instance.new("ScrollingFrame", container)
    frame.Size = UDim2.new(1, 0, 1, -50) -- Fills the rest of the container
    frame.Position = UDim2.new(0, 0, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    frame.ScrollBarThickness = 8

    local layout = Instance.new("UIListLayout", frame)
    layout.Padding = UDim.new(0, 5)

    local targetPlayer = nil
    local isSpamming = false

    -- ==========================================
    -- VEHICLE DETECTION
    -- ==========================================
    local function getMySeat()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.SeatPart then
                return hum.SeatPart 
            end
        end
        return nil
    end

    local function getMyVehicleModel()
        local seat = getMySeat()
        if seat then
            local current = seat
            while current and current.Parent and current.Parent ~= workspace do
                current = current.Parent
                if current:IsA("Model") and (current:FindFirstChild("Chassis") or current:FindFirstChild("Body") or current:FindFirstChild("Seats")) then
                    return current
                end
            end
            if seat.Parent:IsA("Model") then return seat.Parent end
        end
        return nil
    end

    -- ==========================================
    -- THE PHYSICS LOOP
    -- ==========================================
    RunService.Heartbeat:Connect(function()
        if isSpamming and targetPlayer and targetPlayer.Character then
            local carModel = getMyVehicleModel()
            local seat = getMySeat()
            local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if carModel and seat and targetRoot then
                carModel:PivotTo(targetRoot.CFrame)
                
                seat.AssemblyLinearVelocity = Vector3.new(0, 50, 0) 
                seat.AssemblyAngularVelocity = Vector3.new(0, 15000, 0) 
            end
        end
    end)

    -- ==========================================
    -- POPULATE PLAYER LIST (WITH SEARCH FILTER)
    -- ==========================================
    local function updateList(filterText)
        -- Default to empty string if nil
        filterText = filterText and string.lower(filterText) or ""
        
        for _, child in ipairs(frame:GetChildren()) do 
            if child:IsA("TextButton") then child:Destroy() end 
        end
        
        local buttonCount = 0
        
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local playerName = string.lower(p.Name)
                
                -- If search is empty OR the player's name contains the search text, show them
                if filterText == "" or string.find(playerName, filterText, 1, true) then
                    buttonCount = buttonCount + 1
                    
                    local btn = Instance.new("TextButton", frame)
                    btn.Size = UDim2.new(1, -15, 0, 50) 
                    btn.Text = "FLING: " .. p.Name 
                    
                    -- Keep the button green if they are the current active target
                    if targetPlayer == p and isSpamming then
                        btn.Text = "🛑 STOP FLINGING"
                        btn.BackgroundColor3 = Color3.fromRGB(30, 70, 30)
                    else
                        btn.BackgroundColor3 = Color3.fromRGB(70, 30, 30)
                    end
                    
                    btn.TextColor3 = Color3.new(1, 1, 1)
                    btn.Font = Enum.Font.SourceSansBold
                    btn.TextSize = 22 
                    btn.TextWrapped = true
                    
                    btn.MouseButton1Click:Connect(function()
                        if targetPlayer == p and isSpamming then
                            -- TURN OFF SAFELY
                            isSpamming = false
                            targetPlayer = nil
                            
                            btn.Text = "FLING: " .. p.Name 
                            btn.BackgroundColor3 = Color3.fromRGB(70, 30, 30)
                            
                            local seat = getMySeat()
                            local carModel = getMyVehicleModel()
                            if seat and carModel then
                                seat.AssemblyLinearVelocity = Vector3.zero
                                seat.AssemblyAngularVelocity = Vector3.zero
                                carModel:PivotTo(carModel:GetPivot() * CFrame.new(0, 5, 0))
                            end
                        else
                            -- TURN ON
                            targetPlayer = p
                            isSpamming = true
                            btn.Text = "🛑 STOP FLINGING"
                            btn.BackgroundColor3 = Color3.fromRGB(30, 70, 30)
                            
                            -- Force a UI update so other buttons reset their colors if you switched targets mid-fling
                            updateList(searchBar.Text)
                        end
                    end)
                end
            end
        end
        frame.CanvasSize = UDim2.new(0, 0, 0, buttonCount * 55)
    end

    -- Update list dynamically as you type
    searchBar:GetPropertyChangedSignal("Text"):Connect(function()
        updateList(searchBar.Text)
    end)

    -- Initial Load & Connections
    updateList()
    Players.PlayerAdded:Connect(function() updateList(searchBar.Text) end)
    Players.PlayerRemoving:Connect(function() updateList(searchBar.Text) end)

    -- Toggle Menu with 'K'
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Enum.KeyCode.K then
            container.Visible = not container.Visible
        end
    end)
end

local antisConnection = nil
local function antisChanged(antis)
    if antis == nil then
        antis = Config.antis:get()
    end
    local amountEnabled = 0
    local enable = true
    for _, v in pairs(antis) do
        if v == true then
            amountEnabled += 1
        end
    end
    if amountEnabled == 0 then
        enable = false
    end
    if enable then
        if not antisConnection then
            antisConnection = RunService.Heartbeat:Connect(function()
                local antisNow = Config.antis:get()
                local disable = false
                for _, v in pairs(antisNow) do
                    if v == true then
                        amountEnabled += 1
                    end
                end
                if amountEnabled == 0 then
                    disable = true
                end
                amountEnabled = 0
                if disable then
                    antisConnection:Disconnect()
                    antisConnection = nil
                    return
                end

                local ch = LocalPlayer.Character
                if ch then
                    local hu = ch:FindFirstChildOfClass("Humanoid")
                    if hu then
                        if antis.antiCuffEnabled and hu:GetAttribute("CuffState") ~= 1 then
                            hu:SetAttribute("CuffState", 1)
                        end
                        if antis.antiRagdollEnabled and hu:GetAttribute("Ragdoll") == true then
                            hu:SetAttribute("Ragdoll", false)
                        end
                        if antis.antiTazerEnabled and hu:GetAttribute("IsTazerd") == true then
                            hu:SetAttribute("IsTazerd", false)
                        end
                    end
                    if antis.antiHackBypassEnabled then
                        local antihack_alt = ch:FindFirstChild("Antihack_alt")
                        local antihack = ch:FindFirstChild("Antihack")
                        if antihack_alt then
                            antihack_alt:Destroy()
                        end
                        if antihack then
                            antihack:Destroy()
                        end
                    end
                end
            end)
        end
    else
        if antisConnection then
            if antisConnection.Connected then
                antisConnection:Disconnect()
            end
            antisConnection = nil
        end
    end
end

local disableCarDamageConnection = nil
local oldCrashStep = nil
local function newCrashStep(_, p63)
    return 0
end
local function carDamageDisabledChanged(disabled)
    if disabled == nil then
        disabled = Config.carDamageDisabled:get()
    end
    if disabled then
        if not disableCarDamageConnection then
            disableCarDamageConnection = RunService.Heartbeat:Connect(function()
                local ch = LocalPlayer.Character
                if ch then
                    local occupantScript = ch:FindFirstChild("OccupantScript")
                    if occupantScript then
                        local driverScript = occupantScript:FindFirstChild("DriverScript")
                        if driverScript then
                            local vehicleObj = driverScript:FindFirstChild("VehicleObject")
                            if vehicleObj then
                                local vehicle = vehicleObj.Value
                                if vehicle then
                                    local vehicleScripts = vehicle:FindFirstChild("Scripts")
                                    if vehicleScripts then
                                        local chassisHandlerModule = vehicleScripts:FindFirstChild("ChassisHandler")
                                        if chassisHandlerModule then
                                            local chassisHandler = require(chassisHandlerModule)
                                            if oldCrashStep == nil then
                                                oldCrashStep = chassisHandler.CrashStep
                                            end
                                            chassisHandler.CrashStep = newCrashStep
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    else
        if disableCarDamageConnection then
            if disableCarDamageConnection.Connected then
                disableCarDamageConnection:Disconnect()
            end
            disableCarDamageConnection = nil
        end
    end
end

local vehicleNoclipConnection = nil
local vs = workspace:FindFirstChild("Vehicles")
local originalCollisions = {}
local function resetCollisions(v: Instance)
    local tab = originalCollisions[v] or nil
    if tab then
       for p, cc in pairs(tab) do
           p.CanCollide = cc
       end
    else
        tab = {}
        for _, p in ipairs(v:GetDescendants()) do
            if p:IsA("BasePart") then
                tab[p] = p.CanCollide
            end
        end
        originalCollisions[v] = tab
    end
end
local function vehicleNoclipEnabledChanged(enabled)
    if not vs then
        vs = workspace:FindFirstChild("Vehicles")
    end
    if enabled == nil then
        enabled = Config.carDamageDisabled:get()
    end
    if vs and enabled then
        if not vehicleNoclipConnection then
            vehicleNoclipConnection = RunService.Heartbeat:Connect(function()
                local myv = nil
                local ch = LocalPlayer.Character
                if ch then
                    local occupantScript = ch:FindFirstChild("OccupantScript")
                    if occupantScript then
                        local driverScript = occupantScript:FindFirstChild("DriverScript")
                        if driverScript then
                            local vehicleObj = driverScript:FindFirstChild("VehicleObject")
                            if vehicleObj then
                                myv = vehicleObj.Value
                            end
                        end
                    end
                end
                for _, v in ipairs(vs:GetChildren()) do
                    resetCollisions(v)
                    if v ~= myv then
                        for _, p in ipairs(v:GetDescendants()) do
                            if p:IsA("BasePart") then
                                p.CanCollide = false
                            end
                        end
                    end
                end
            end)
        end
    else
        if vehicleNoclipConnection then
            if vehicleNoclipConnection.Connected then
                vehicleNoclipConnection:Disconnect()
            end
            vehicleNoclipConnection = nil
        end
    end
end

local ghostriderConnection = nil
local function ghostriderEnabledChanged(enabled)
    if enabled == nil then
        enabled = Config.ghostriderEnabled:get()
    end
    if enabled then
        if not ghostriderConnection then
            ghostriderConnection = RunService.PreSimulation:Connect(function()
                local intens = Config.nitrous:get()
                local brakePower = Config.airbrake:get()

                local subject = workspace.CurrentCamera.CameraSubject
                local targetPart = nil

                -- Determine the target (Seat or Part)
                if subject:IsA("Humanoid") and subject.SeatPart then
                    targetPart = subject.SeatPart
                elseif subject:IsA("BasePart") then
                    targetPart = subject
                end

                if not targetPart then return end

                -- BOOST LOGIC (Left Shift)
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                    targetPart:ApplyImpulse(targetPart.CFrame.LookVector * Vector3.new(intens, intens, intens))
                end

                -- SMOOTH BRAKE LOGIC (Left Control)
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                    -- We 'Lerp' the current velocity toward a zero vector
                    -- This creates a "Tween" effect for physics
                    targetPart.AssemblyLinearVelocity = targetPart.AssemblyLinearVelocity:Lerp(Vector3.zero, brakePower)
                    
                    -- We also smooth out the spinning/rotation so it doesn't jitter
                    targetPart.AssemblyAngularVelocity = targetPart.AssemblyAngularVelocity:Lerp(Vector3.zero, brakePower)
                end
            end)
        end
    else
        if ghostriderConnection then
            if ghostriderConnection.Connected then
                ghostriderConnection:Disconnect()
            end
            ghostriderConnection = nil
        end
    end
end

local function extendToolHitbox()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    local handle = tool:FindFirstChild("Handle")
    if not handle then return end
    if typeof(handle) ~= "Instance" or not handle:IsA("BasePart") then return end
    local a = Instance.new("SelectionBox", handle)
    a.Adornee = handle
    handle.Size=Vector3.new(20, 20, 20)
    handle.Transparency = 1
end

local rocketleagueConnection = nil
local function rocketLeagueControlsChanged(controls)
    if controls == nil then
        controls = Config.rocketLeagueControls:get()
    end
    local amountEnabled = 0
    local enable = true
    for _, v in pairs(controls) do
        if v == true then
            amountEnabled += 1
        end
    end
    if amountEnabled == 0 then
        enable = false
    end
    if enable then
        if not rocketleagueConnection then
            rocketleagueConnection = RunService.PreSimulation:Connect(function(dt: number)
                local controlsNow = Config.rocketLeagueControls:get()
                local disable = false
                for _, v in pairs(controlsNow) do
                    if v == true then
                        amountEnabled += 1
                    end
                end
                if amountEnabled == 0 then
                    disable = true
                end
                amountEnabled = 0
                if disable then
                    rocketleagueConnection:Disconnect()
                    rocketleagueConnection = nil
                    return
                end

                local airRollStrength = math.rad(Config.airRollStrength:get())
                local airPitchStrength = math.rad(Config.airPitchStrength:get())
                local powerSlideStrength = math.rad(Config.powerSlideStrength:get())

                local keybinds = {
                    airRollLeft = {controlsNow.airRollEnabled, Config.airRollLeftKeybind:get(), "LookVector", -airRollStrength};
                    airRollRight = {controlsNow.airRollEnabled, Config.airRollRightKeybind:get(), "LookVector", airRollStrength};
                    airPitchUp = {controlsNow.airPitchEnabled, Config.airPitchUpKeybind:get(), "RightVector" , airPitchStrength};
                    airPitchDown = {controlsNow.airPitchEnabled, Config.airPitchDownKeybind:get(), "RightVector", -airPitchStrength};
                    powerSlideLeft = {controlsNow.powerSlideEnabled, Config.powerSlideLeftKeybind:get(), "UpVector", powerSlideStrength};
                    powerSlideRight = {controlsNow.powerSlideEnabled, Config.powerSlideRightKeybind:get(), "UpVector", -powerSlideStrength};
                }

                local subject = workspace.CurrentCamera.CameraSubject
                local targetPart = nil

                -- Determine the target (Seat or Part)
                if subject:IsA("Humanoid") and subject.SeatPart then
                    targetPart = subject.SeatPart
                elseif subject:IsA("BasePart") then
                    targetPart = subject
                end

                if not targetPart then return end
                
                for _, k in pairs(keybinds) do
                    if k[1] ~= true then
                        continue
                    end
                    local keyCodeName = k[2]
                    if not keyCodeName then
                        continue
                    end
                    local keyCode = Enum.KeyCode[keyCodeName]
                    if not keyCode then
                        continue
                    end
                    local dir = k[3]
                    if not dir then
                        continue
                    end
                    local strength = k[4]
                    if not strength then
                        continue
                    end
                    local must = k[5]
                    if must ~= nil and UserInputService:IsKeyDown(must) == false then
                        continue
                    end
                    local mustnt = k[6]
                    if mustnt ~= nil and UserInputService:IsKeyDown(mustnt) == true then
                        continue
                    end
                    if UserInputService:IsKeyDown(keyCode) then
                        targetPart:ApplyAngularImpulse(targetPart.CFrame[dir] * strength)
                    end
                end
                local aav = targetPart.AssemblyAngularVelocity
                local rx, ry, rz = aav.X, aav.Y, aav.Z
                local eachmax = math.rad(90)
                if controlsNow.airPitchEnabled then
                    local max = eachmax
                    rx = math.clamp(rx, -max, max)
                end
                if controlsNow.powerSlideEnabled then
                    local max = eachmax
                    ry = math.clamp(ry, -max, max)
                end
                if controlsNow.airRollEnabled then
                    local max = eachmax
                    rz = math.clamp(rz, -max, max)
                end
                targetPart.AssemblyAngularVelocity = Vector3.new(rx, ry, rz)
            end)
        end
    else
        if rocketleagueConnection then
            if rocketleagueConnection.Connected then
                rocketleagueConnection:Disconnect()
            end
            rocketleagueConnection = nil
        end
    end
end

function setPropertiesRecursively(instance, properties)
    for i, v in pairs(properties) do
        if instance[i] ~= nil then
            if type(instance[i]) == "table" and type(v) == "table" then
                setPropertiesRecursively(instance[i], v)
            else
                instance[i] = v
            end
        end
    end
end

local ak47Tampered = false
local weaponModule = ReplicatedStorage.Client.Database.ToolInformation.Informations.Weapon
local weaponMod = require(weaponModule)
local function tamperGun(gun: string)
    local gun = weaponMod.Data[gun]

    -- print(repr(gun, reprSettings))

    local newProperties = {
        MaxAmmo = math.huge;
        Ammo = math.huge;
        CameraSettings = {
            Recoil = {
                Angle = 0;
            };
        };
        Damage = {
            Head = 100;
            Torso = 100;
            Limbs = 100;
        };
        ProjectileProperties = {
            MaxDistance = 10000;
        };
        MuzzleVelocity = 10000;
        Range = 10000;
        FullDamageRange = 0;
        Firerate = 10000;
        ReloadTime = 0.003;
        BurstShotCount = 100;
        ClimbRate = 0;
    }

    setPropertiesRecursively(gun, newProperties)
end

--AutoBus
local autobus_thread = nil
local autobus_enabled = Iris.State(false)
do
    local DefaultBusLocationsTable = {
        BusStop_4OrangeInv = { 904.1454467773438, 68.958984375, 834.0386352539062, -0.7661795616149902, 0, 0.6426267623901367, 0, 1, 0, -0.6426267623901367, 0, -0.7661795616149902 },
        BusStop_5Rot = { -1563.828125, 41.515625, -538.75390625, 0.938283383846283, 0, -0.34586742520332336, 0, 1, 0, 0.34586742520332336, 0, 0.938283383846283 },
        BusStop_5OrangeInv = { 642.195556640625, 41.515625, -2004.3958740234375, 0.9986181855201721, 0, 0.05255195498466492, 0, 1, 0, -0.05255195498466492, 0, 0.9986181855201721 },
        BusStop_6RotInv = { 612.1533813476562, 41.515625, -2003.4979248046875, -0.9986186027526855, 0, -0.05255195498466492, 0, 1, 0, 0.05255195498466492, 0, -0.9986186027526855 },
        BusStop_7RotInv = { -561.9729614257812, 41.51171875, -1204.152587890625, -0.9993922710418701, 0, -0.03486879914999008, 0, 1, 0, 0.03486879914999008, 0, -0.9993922710418701 },
        BusStop_1Rot = { 20.845703125, 68.958984375, 681.998046875, 0.9848124980926514, 0, 0.17362114787101746, 0, 1, 0, -0.17362114787101746, 0, 0.9848124980926514 },
        BusStop_2Orange = { -2097.86767578125, 41.515625, 425.59649658203125, -0.017623186111450195, 0, 0.9998448491096497, 0, 1, 0, -0.9998448491096497, 0, -0.017623186111450195 },
        BusStop_6OrangeInv = { -2332.544921875, 41.515625, -1221.6705322265625, -0.9658845663070679, 0, 0.25897300243377686, 0, 1, 0, -0.25897300243377686, 0, -0.9658845663070679 },
        BusStop_7Rot = { -2096.721435546875, 41.515625, 471.6341857910156, 0.01762288808822632, 0, -0.9998448491096497, 0, 1, 0, 0.9998448491096497, 0, 0.01762288808822632 },
        BusStop_2RotInv = { -2097.859375, 41.515625, 426.078125, -0.017623186111450195, 0, 0.9998448491096497, 0, 1, 0, -0.9998448491096497, 0, -0.017623186111450195 },
        BusStop_1RotInv = { 72.849609375, 68.958984375, 726.095703125, 0.9848124980926514, 0, 0.17362114787101746, 0, 1, 0, -0.17362114787101746, 0, 0.9848124980926514 },
        BusStop_3OrangeInv = { 830.0198364257812, 41.36328125, 1545.96484375, -1, 0, 0, 0, 1, 0, 0, 0, -1 },
        BusStop_5RotInv = { -525.1734619140625, 41.578125, -1102.8594970703125, 0.9993919134140015, 0, 0.03486879914999008, 0, 1, 0, -0.03486879914999008, 0, 0.9993919134140015 },
        BusStop_3Orange = { -2288.2734375, 41.515625, -1210.1875, 0.9658845663070679, 0, -0.25897300243377686, 0, 1, 0, 0.25897300243377686, 0, 0.9658845663070679 },
        BusStop_4Orange = { 612.56640625, 41.515625, -2003.51953125, -0.9986186027526855, 0, -0.05255195498466492, 0, 1, 0, 0.05255195498466492, 0, -0.9986186027526855 },
        BusStop_Start = { -12.13671875, 68.9609375, 1011.41796875, 0.9848124980926514, 0, 0.17362114787101746, 0, 1, 0, -0.17362114787101746, 0, 0.9848124980926514 },
        BusStop_1Orange = { 93.435546875, 68.958984375, 618.572265625, 0.9848124980926514, 0, 0.17362114787101746, 0, 1, 0, -0.17362114787101746, 0, 0.9848124980926514 },
        BusStop_3RotInv = { -2288.28125, 41.515625, -1210.15625, -0.9658845663070679, 0, 0.25897300243377686, 0, 1, 0, -0.25897300243377686, 0, -0.9658845663070679 },
        BusStop_2OrangeInv = { 892.01953125, 68.958984375, 823.86328125, -0.7661795616149902, 0, 0.6426267623901367, 0, 1, 0, -0.6426267623901367, 0, -0.7661795616149902 },
        BusStop_4RotInv = { -1578.69140625, 41.515625, -586.09765625, -0.9382835626602173, 0, 0.34586742520332336, 0, 1, 0, -0.34586742520332336, 0, -0.9382835626602173 },
        BusStop_5Orange = { 830.9609375, 41.36328125, 1545.96484375, -1, 0, 0, 0, 1, 0, 0, 0, -1 },
        BusStop_4Rot = { -561.64453125, 41.51171875, -1204.1640625, -0.9993922710418701, 0, -0.03486879914999008, 0, 1, 0, 0.03486879914999008, 0, -0.9993922710418701 },
        BusStop_1OrangeInv = { 0.58984375, 68.958984375, 790.365234375, 0.9848124980926514, 0, 0.17362114787101746, 0, 1, 0, -0.17362114787101746, 0, 0.9848124980926514 },
        BusStop_6Rot = { -2332.0546875, 41.515625, -1221.5390625, -0.9658845663070679, 0, 0.25897300243377686, 0, 1, 0, -0.25897300243377686, 0, -0.9658845663070679 },
        BusStop_7OrangeInv = { -2096.7265625, 41.515625, 471.3359375, 0.01762288808822632, 0, -0.9998448491096497, 0, 1, 0, 0.9998448491096497, 0, 0.01762288808822632 },
        BusStop_6Orange = { 903.943359375, 68.958984375, 833.869140625, -0.7661795616149902, 0, 0.6426267623901367, 0, 1, 0, -0.6426267623901367, 0, -0.7661795616149902 },
        BusStop_3Rot = { 641.94921875, 41.515625, -2004.3828125, 0.9986181855201721, 0, 0.05255195498466492, 0, 1, 0, -0.05255195498466492, 0, 0.9986181855201721 },
        BusStop_2Rot = { -525.40234375, 41.578125, -1102.8515625, 0.9993919134140015, 0, 0.03486879914999008, 0, 1, 0, -0.03486879914999008, 0, 0.9993919134140015 }
    }

    masterBusLocations = {}

    saveLocations = nil

    if EXECUTOR_FILING_ENABLED then
        local SAVE_FILE_PATH = SCRIPT_DIRECTORY_PATH.."/AutoBus_Locations.json"

        saveLocations = function()
            if writefile then
                local saveTable = {}
                for name, cf in pairs(masterBusLocations) do
                    saveTable[name] = {cf:GetComponents()}
                end
                writefile(SAVE_FILE_PATH, HttpService:JSONEncode(saveTable))
            end
        end

        function loadLocations()
            if isfile and isfile(SAVE_FILE_PATH) then
                local jsonData = readfile(SAVE_FILE_PATH)
                local success, saveTable = pcall(function() return HttpService:JSONDecode(jsonData) end)
                if success and type(saveTable) == "table" then
                    if #saveTable == 0 then
                        saveTable = DefaultBusLocationsTable
                    end
                    for name, comps in pairs(saveTable) do
                        masterBusLocations[name] = CFrame.new(table.unpack(comps))
                    end
                end
            end
        end

        loadLocations()
    else
        masterBusLocations = DefaultBusLocationsTable
    end

    -- ==========================================
    -- VEHICLE DETECTION
    -- ==========================================
    function getMyBus()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.SeatPart then
                local vehicle = humanoid.SeatPart
                local busModel = vehicle
                while vehicle and vehicle.Parent and vehicle.Parent ~= game.Workspace do
                    vehicle = vehicle.Parent
                    if vehicle:IsA("Model") then
                        busModel = vehicle
                    elseif vehicle:IsA("Folder") then
                        break
                    end
                end
                return busModel
            end
        end
        return nil
    end

    function setEntireBusVelocity(bus, linearVelocity)
        for _, part in ipairs(bus:GetDescendants()) do
            if part:IsA("BasePart") then
                part.AssemblyLinearVelocity = linearVelocity
                part.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end

    -- ==========================================
    -- PROMPT DETECTION
    -- ==========================================
    function waitForPromptToClear()
        -- This looks for the "Stop Your Vehicle" text in your PlayerGui
        -- The script will wait here until that specific text disappears
        local startTime = tick()
        repeat 
            task.wait(0.5)
            local promptFound = false
            -- Search through PlayerGui for the specific text from your video
            local guiObjects = LocalPlayer.PlayerGui:GetDescendants()
            for _, obj in ipairs(guiObjects) do
                if obj:IsA("TextLabel") and (obj.Text:find("Stop Your Vehicle") or obj.Text:find("have to stop")) then
                    if obj.Visible == true and obj.TextTransparency < 1 then
                        promptFound = true
                        break
                    end
                end
            end
        until not promptFound or (tick() - startTime > 10) -- Max 10s timeout safety
    end

    -- ==========================================
    -- CORE LOGIC
    -- ==========================================
    function executeTeleport(bus, targetCFrame)
        local rootPart = bus.PrimaryPart or bus:FindFirstChildWhichIsA("BasePart", true)
        
        if rootPart then
            -- 60 studs back, 3 studs up
            local backwardOffset = -targetCFrame.LookVector * 60
            local spawnCFrame = (targetCFrame + backwardOffset) + Vector3.new(0, 3, 0)
            
            setEntireBusVelocity(bus, Vector3.zero)
            bus:PivotTo(spawnCFrame)
            
            local driveSpeed = targetCFrame.LookVector * 60
            setEntireBusVelocity(bus, driveSpeed)
            
            task.wait(1.5)
            
            -- Hard Brake
            setEntireBusVelocity(bus, Vector3.zero)
            
            -- NEW: Wait for the game UI to finish before moving to the next stop
            waitForPromptToClear()
        end
        
        task.wait(1) -- Short buffer after prompt clears
    end
end

-- Iris Init
table.insert(Iris.Internal._initFunctions, function()
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.fromScale(1, 1)
    background.BackgroundColor3 = Config.backgroundColor:get()
    background.BackgroundTransparency = Config.backgroundTransparency:get()

    local widget
    if Iris._config.UseScreenGUIs then
        widget = Instance.new("ScreenGui")
        widget.Name = "Iris_Background"
        widget.IgnoreGuiInset = true
        widget.DisplayOrder = Iris._config.DisplayOrderOffset - 1
        widget.ScreenInsets = Enum.ScreenInsets.None
        widget.Enabled = true

        background.Parent = widget
    else
        background.ZIndex = Iris._config.DisplayOrderOffset - 1
        widget = background
    end

    Config.backgroundColor:onChange(function(value: Color3)
        background.BackgroundColor3 = value
    end)
    Config.backgroundTransparency:onChange(function(value: number)
        background.BackgroundTransparency = value
    end)

    Config.showBackground:onChange(function(show: boolean)
        if show then
            widget.Parent = Iris.Internal.parentInstance
        else
            widget.Parent = nil
        end
    end)
end)

-- Iris Helpers
local function helpMarker(helpText: string)
    Iris.PushConfig({ TextColor = Iris._config.TextDisabledColor })
    local text = Iris.Text({ "(?)" })
    Iris.PopConfig()

    Iris.PushConfig({ ContentWidth = UDim.new(0, 350) })
    if text.hovered() then
        Iris.Tooltip({ helpText })
    end
    Iris.PopConfig()
end

local function textAndHelpMarker(text: string, helpText: string)
    Iris.SameLine()
    do
        Iris.Text({ text })
        helpMarker(helpText)
    end
    Iris.End()
end

local function keybindButton(text: string, state)
    Iris.SameLine()
    do
        Iris.Text({ text })
        -- the button has a clicked event, returning true when it is pressed
        local currentKeyCodeName = state:get()
        if Iris.Button({currentKeyCodeName}).clicked() then
            -- run code if we click the button
            UserInputService.InputBegan:Once(function(input: InputObject, gameProcessedEvent: boolean)
                if not gameProcessedEvent then
                    if input and input.KeyCode and input.KeyCode.Name and input.KeyCode.Name ~= currentKeyCodeName then
                        state:set(input.KeyCode.Name)
                    end
                end
            end)
        end
    end
    Iris.End()
end

local function color4Picker(text: string, colorState, transparencyState)
    local ColorPicker = Iris.InputColor4({"Color"}, {
        color = Iris.WeakState(colorState:get());
        transparency = Iris.WeakState(transparencyState:get());
    })
    ColorPicker.state.color:set(colorState:get())
    ColorPicker.state.transparency:set(transparencyState:get())
    if ColorPicker.numberChanged() then
        colorState:set(ColorPicker.state.color:get())
        transparencyState:set(ColorPicker.state.transparency:get())
    end
end

-- shows list of runtime widgets and states, including IDs. shows other info about runtime and can show widgets/state info in depth.
local function runtimeInfo()
    local runtimeInfoWindow = Iris.Window({ "Runtime Info" }, { isOpened = Config.showRuntimeInfo })
    do
        local lastVDOM = Iris.Internal._lastVDOM
        local states = Iris.Internal._states

        local numSecondsDisabled = Iris.State(3)
        local rollingDT = Iris.State(0)
        local lastT = Iris.State(os.clock())

        Iris.SameLine()
        do
            Iris.InputNum({ [Iris.Args.InputNum.Text] = "", [Iris.Args.InputNum.Format] = "%d Seconds", [Iris.Args.InputNum.Max] = 10 }, { number = numSecondsDisabled })
            if Iris.Button({ "Disable" }).clicked() then
                Iris.Disabled = true
                task.delay(numSecondsDisabled:get(), function()
                    Iris.Disabled = false
                end)
            end
        end
        Iris.End()

        local t = os.clock()
        local dt = t - lastT.value
        rollingDT.value += (dt - rollingDT.value) * 0.2
        lastT.value = t
        Iris.Text({ string.format("Average %.3f ms/frame (%.1f FPS)", rollingDT.value * 1000, 1 / rollingDT.value) })

        Iris.Text({
            string.format("Window Position: (%d, %d), Window Size: (%d, %d)", runtimeInfoWindow.position.value.X, runtimeInfoWindow.position.value.Y, runtimeInfoWindow.size.value.X, runtimeInfoWindow.size.value.Y),
        })
    end
    Iris.End()
end

local function debugPanel()
    Iris.Window({ "Debug Panel" }, { isOpened = Config.showDebugWindow })
    do
        Iris.CollapsingHeader({ "Widgets" })
        do
            Iris.SeparatorText({ "GuiService" })
            Iris.Text({ `GuiOffset: {Iris.Internal._utility.GuiOffset}` })
            Iris.Text({ `MouseOffset: {Iris.Internal._utility.MouseOffset}` })

            Iris.SeparatorText({ "UserInputService" })
            Iris.Text({ `MousePosition: {Iris.Internal._utility.UserInputService:GetMouseLocation()}` })
            Iris.Text({ `MouseLocation: {Iris.Internal._utility.getMouseLocation()}` })

            Iris.Text({ `Left Control: {Iris.Internal._utility.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)}` })
            Iris.Text({ `Right Control: {Iris.Internal._utility.UserInputService:IsKeyDown(Enum.KeyCode.RightControl)}` })
        end
        Iris.End()
    end
    Iris.End()
end

local function mainMenuBar()
    Iris.MenuBar()
    do
        Iris.Menu({ "Configs" })
        do
            Iris.MenuItem({ "New" })
            Iris.MenuItem({ "Open" })
            Iris.MenuItem({ "Save" })
        end
        Iris.End()

        Iris.Menu({ "Tools" })
        do
            Iris.MenuToggle({ "Runtime Info" }, { isChecked = Config.showRuntimeInfo })
            Iris.MenuToggle({ "Style Editor" }, { isChecked = Config.showStyleEditor })
            Iris.MenuToggle({ "Debug Panel" }, { isChecked = Config.showDebugWindow })
        end
        Iris.End()
    end
    Iris.End()
end

-- allows users to edit state
local styleEditor
do
    styleEditor = function()
        local styleList = {
            {
                "Sizing",
                function()
                    Iris.SameLine()
                    do
                        if Iris.Button({ "Update" }).clicked() then
                            Iris.UpdateGlobalConfig(Config.IrisSizingConfig.value)
                            Config.IrisSizingConfig:set({})
                        end

                        helpMarker("Update the global config with these changes.")
                    end
                    Iris.End()

                    local function SliderInput(input: string, arguments: { any })
                        local Input = Iris[input](arguments, { number = Iris.WeakState(Iris._config[arguments[1]]) })
                        if Input.numberChanged() then
                            Config.IrisSizingConfig.value[arguments[1]] = Input.number:get()
                        end
                    end

                    local function BooleanInput(arguments: { any })
                        local Input = Iris.Checkbox(arguments, { isChecked = Iris.WeakState(Iris._config[arguments[1]]) })
                        if Input.checked() or Input.unchecked() then
                            Config.IrisSizingConfig.value[arguments[1]] = Input.isChecked:get()
                        end
                    end

                    Iris.SeparatorText({ "Main" })
                    SliderInput("SliderVector2", { "WindowPadding", nil, Vector2.zero, Vector2.new(20, 20) })
                    SliderInput("SliderVector2", { "WindowResizePadding", nil, Vector2.zero, Vector2.new(20, 20) })
                    SliderInput("SliderVector2", { "FramePadding", nil, Vector2.zero, Vector2.new(20, 20) })
                    SliderInput("SliderVector2", { "ItemSpacing", nil, Vector2.zero, Vector2.new(20, 20) })
                    SliderInput("SliderVector2", { "ItemInnerSpacing", nil, Vector2.zero, Vector2.new(20, 20) })
                    SliderInput("SliderVector2", { "CellPadding", nil, Vector2.zero, Vector2.new(20, 20) })
                    SliderInput("SliderNum", { "IndentSpacing", 1, 0, 36 })
                    SliderInput("SliderNum", { "ScrollbarSize", 1, 0, 20 })
                    SliderInput("SliderNum", { "GrabMinSize", 1, 0, 20 })

                    Iris.SeparatorText({ "Borders & Rounding" })
                    SliderInput("SliderNum", { "FrameBorderSize", 0.1, 0, 1 })
                    SliderInput("SliderNum", { "WindowBorderSize", 0.1, 0, 1 })
                    SliderInput("SliderNum", { "PopupBorderSize", 0.1, 0, 1 })
                    SliderInput("SliderNum", { "SeparatorTextBorderSize", 1, 0, 20 })
                    SliderInput("SliderNum", { "FrameRounding", 1, 0, 12 })
                    SliderInput("SliderNum", { "GrabRounding", 1, 0, 12 })
                    SliderInput("SliderNum", { "PopupRounding", 1, 0, 12 })

                    Iris.SeparatorText({ "Widgets" })
                    SliderInput("SliderVector2", { "DisplaySafeAreaPadding", nil, Vector2.zero, Vector2.new(20, 20) })
                    SliderInput("SliderVector2", { "SeparatorTextPadding", nil, Vector2.zero, Vector2.new(36, 36) })
                    SliderInput("SliderUDim", { "ItemWidth", nil, UDim.new(), UDim.new(1, 200) })
                    SliderInput("SliderUDim", { "ContentWidth", nil, UDim.new(), UDim.new(1, 200) })
                    SliderInput("SliderNum", { "ImageBorderSize", 1, 0, 12 })
                    local TitleInput = Iris.ComboEnum({ "WindowTitleAlign" }, { index = Iris.WeakState(Iris._config.WindowTitleAlign) }, Enum.LeftRight)
                    if TitleInput.closed() then
                        Config.IrisSizingConfig.value["WindowTitleAlign"] = TitleInput.index:get()
                    end
                    BooleanInput({ "RichText" })
                    BooleanInput({ "TextWrapped" })

                    Iris.SeparatorText({ "Config" })
                    BooleanInput({ "UseScreenGUIs" })
                    SliderInput("DragNum", { "DisplayOrderOffset", 1, 0 })
                    SliderInput("DragNum", { "ZIndexOffset", 1, 0 })
                    SliderInput("SliderNum", { "MouseDoubleClickTime", 0.1, 0, 5 })
                    SliderInput("SliderNum", { "MouseDoubleClickMaxDist", 0.1, 0, 20 })
                end,
            },
            {
                "Colors",
                function()
                    Iris.SameLine()
                    do
                        if Iris.Button({ "Update" }).clicked() then
                            Iris.UpdateGlobalConfig(Config.IrisColorsConfig.value)
                            Config.IrisColorsConfig:set({})
                        end
                        helpMarker("Update the global config with these changes.")
                    end
                    Iris.End()

                    local color4s = {
                        "Text",
                        "TextDisabled",
                        "WindowBg",
                        "PopupBg",
                        "Border",
                        "BorderActive",
                        "ScrollbarGrab",
                        "TitleBg",
                        "TitleBgActive",
                        "TitleBgCollapsed",
                        "MenubarBg",
                        "FrameBg",
                        "FrameBgHovered",
                        "FrameBgActive",
                        "Button",
                        "ButtonHovered",
                        "ButtonActive",
                        "Image",
                        "SliderGrab",
                        "SliderGrabActive",
                        "Header",
                        "HeaderHovered",
                        "HeaderActive",
                        "SelectionImageObject",
                        "SelectionImageObjectBorder",
                        "TableBorderStrong",
                        "TableBorderLight",
                        "TableRowBg",
                        "TableRowBgAlt",
                        "NavWindowingHighlight",
                        "NavWindowingDimBg",
                        "Separator",
                        "CheckMark",
                    }

                    for _, vColor in color4s do
                        local Input = Iris.InputColor4({ vColor }, {
                            color = Iris.WeakState(Iris._config[vColor .. "Color"]),
                            transparency = Iris.WeakState(Iris._config[vColor .. "Transparency"]),
                        })
                        if Input.numberChanged() then
                            Config.IrisColorsConfig.value[vColor .. "Color"] = Input.color:get()
                            Config.IrisColorsConfig.value[vColor .. "Transparency"] = Input.transparency:get()
                        end
                    end
                end,
            },
            {
                "Fonts",
                function()
                    Iris.SameLine()
                    do
                        if Iris.Button({ "Update" }).clicked() then
                            Iris.UpdateGlobalConfig(Config.IrisFontsConfig.value)
                            Config.IrisFontsConfig:set({})
                        end

                        helpMarker("Update the global config with these changes.")
                    end
                    Iris.End()

                    local fonts: { [string]: Font } = {
                        ["Code (default)"] = Font.fromEnum(Enum.Font.Code),
                        ["Ubuntu (template)"] = Font.fromEnum(Enum.Font.Ubuntu),
                        ["Arial"] = Font.fromEnum(Enum.Font.Arial),
                        ["Highway"] = Font.fromEnum(Enum.Font.Highway),
                        ["Roboto"] = Font.fromEnum(Enum.Font.Roboto),
                        ["Roboto Mono"] = Font.fromEnum(Enum.Font.RobotoMono),
                        ["Noto Sans"] = Font.new("rbxassetid://12187370747"),
                        ["Builder Sans"] = Font.fromEnum(Enum.Font.BuilderSans),
                        ["Builder Mono"] = Font.new("rbxassetid://16658246179"),
                        ["Sono"] = Font.new("rbxassetid://12187374537"),
                    }

                    Iris.Text({ `Current Font: {Iris._config.TextFont.Family} Weight: {Iris._config.TextFont.Weight} Style: {Iris._config.TextFont.Style}` })
                    Iris.SeparatorText({ "Size" })

                    local TextSize = Iris.SliderNum({ "Font Size", 1, 4, 20 }, { number = Iris.WeakState(Iris._config.TextSize) })
                    if TextSize.numberChanged() then
                        Config.IrisFontsConfig.value["TextSize"] = TextSize.state.number:get()
                    end

                    Iris.SeparatorText({ "Properties" })

                    local TextFont = Iris.WeakState(Iris._config.TextFont.Family)
                    local FontWeight = Iris.ComboEnum({ "Font Weight" }, { index = Iris.WeakState(Iris._config.TextFont.Weight) }, Enum.FontWeight)
                    local FontStyle = Iris.ComboEnum({ "Font Style" }, { index = Iris.WeakState(Iris._config.TextFont.Style) }, Enum.FontStyle)

                    Iris.SeparatorText({ "Fonts" })
                    for name, font in fonts do
                        font = Font.new(font.Family, FontWeight.state.index.value, FontStyle.state.index.value)
                        Iris.SameLine()
                        do
                            Iris.PushConfig({
                                TextFont = font,
                            })

                            if Iris.Selectable({ `{name} | "The quick brown fox jumps over the lazy dog."`, font.Family }, { index = TextFont }).selected() then
                                Config.IrisFontsConfig.value["TextFont"] = font
                            end
                            Iris.PopConfig()
                        end
                        Iris.End()
                    end
                end,
            },
        }

        Iris.Window({ "Style Editor" }, { isOpened = Config.showStyleEditor })
        do
            Iris.Text({ "Customize the look of Iris in realtime." })

            local ThemeState = Iris.State("Dark Theme")
            if Iris.ComboArray({ "Theme" }, { index = ThemeState }, { "Dark Theme", "Light Theme" }).closed() then
                if ThemeState.value == "Dark Theme" then
                    Iris.UpdateGlobalConfig(Iris.TemplateConfig.colorDark)
                elseif ThemeState.value == "Light Theme" then
                    Iris.UpdateGlobalConfig(Iris.TemplateConfig.colorLight)
                end
            end

            local SizeState = Iris.State("Classic Size")
            if Iris.ComboArray({ "Size" }, { index = SizeState }, { "Classic Size", "Larger Size" }).closed() then
                if SizeState.value == "Classic Size" then
                    Iris.UpdateGlobalConfig(Iris.TemplateConfig.sizeDefault)
                elseif SizeState.value == "Larger Size" then
                    Iris.UpdateGlobalConfig(Iris.TemplateConfig.sizeClear)
                end
            end

            Iris.SameLine()
            do
                if Iris.Button({ "Revert" }).clicked() then
                    Iris.UpdateGlobalConfig(Iris.TemplateConfig.colorDark)
                    Iris.UpdateGlobalConfig(Iris.TemplateConfig.sizeDefault)
                    ThemeState:set("Dark Theme")
                    SizeState:set("Classic Size")
                end

                helpMarker("Reset Iris to the default theme and size.")
            end
            Iris.End()

            Iris.TabBar()
            do
                for i, v in ipairs(styleList) do
                    Iris.Tab({ v[1] })
                    do
                        styleList[i][2]()
                    end
                    Iris.End()
                end
            end
            Iris.End()

            Iris.Separator()
        end
        Iris.End()
    end
end

local ConfigDisplayNames = {
    ["antiCuffEnabled"] = "Anti-Cuff Enabled";
    ["antiRagdollEnabled"] = "Anti-Ragdoll Enabled";
    ["antiTazerEnabled"] = "Anti-Tazer Enabled";
    ["antiHackBypassEnabled"] = "Anti-Hack Bypass Enabled";
    ["airRollEnabled"] = "Air Roll Enabled";
    ["airPitchEnabled"] = "Air Pitch Enabled";
    ["powerSlideEnabled"] = "Power Slide Enabled";
}

-- Widgets
Iris:Connect(function()
    --Connected to RunService.Heartbeat (~60 FPS)

    local sessionTime = FormatHours(time())
    local window = Iris.Window({"Emden Hub by @Brycki404 (" .. ver .. ") " .. sessionTime}, {
        size = Iris.State(Vector2.new(600, 550));
        position = Iris.State(Vector2.new(100, 25));
        isOpened = Config.showMainWindow;
    })
    -- the window has opened and uncollapsed events, which return booleans
    if window.state.isOpened:get() and window.state.isUncollapsed:get() then
        -- run the window code only if the window is actually open and uncollapsed,
        -- which is more efficient.
        Iris.Text({"Version: " .. ver})
        Iris.Text({"Your Session Time: " .. sessionTime})
        keybindButton("Toggle UI Keybind", Config.windowKeyCode)

        mainMenuBar()

        Iris.TabBar()
        do
            Iris.Tab({"ESP"})
            do
                Iris.SeparatorText({"Master Settings"})

                local MasterMaxRenderDistance = Iris.DragNum({"Max Render Distance", 1, 0, 20000}, { number = Config.ESP.MasterMaxRenderDistance })
                if MasterMaxRenderDistance.numberChanged() then
                    Config.ESP.MasterMaxRenderDistance:set(MasterMaxRenderDistance.state.number:get())
                end

                local MasterShapes = Iris.Checkbox({"Shapes Enabled"}, { isChecked = Config.ESP.MasterShapes })
                if MasterShapes.checked() or MasterShapes.unchecked() then
                    Config.ESP.MasterShapes:set(MasterShapes.state.isChecked:get())
                end

                local MasterText = Iris.Checkbox({"Text Enabled"}, { isChecked = Config.ESP.MasterText })
                if MasterText.checked() or MasterText.unchecked() then
                    Config.ESP.MasterText:set(MasterText.state.isChecked:get())
                end

                local MasterTracers = Iris.Checkbox({"Tracers Enabled"}, { isChecked = Config.ESP.MasterTracers })
                if MasterTracers.checked() or MasterTracers.unchecked() then
                    Config.ESP.MasterTracers:set(MasterTracers.state.isChecked:get())
                end

                local CategoryChanged = false
                local NewSelectedCategory = nil

                local NumCategories = CountList(SelectableCategories)
                if NumCategories > 0 then
                    Iris.SeparatorText({"Categories"})

                    local thisCategoryIndex = SelectedCategory:get()
                    local thisCategoryName = SelectableCategories[thisCategoryIndex]
                    
                    Iris.Text({"Selected Category: " .. thisCategoryName})
                    Iris.Combo({""}, {index = SelectedCategory})
                    for i, categoryName in ipairs(SelectableCategories) do
                        local thisCategoryConfig = Config.ESP.Categories[categoryName]
                        if thisCategoryConfig then
                            if thisCategoryConfig.HealthDisplayType ~= nil then
                                if not thisCategoryConfig.HealthDisplayTypeOnChangeCallbackSetup then
                                    thisCategoryConfig.HealthDisplayTypeOnChangeCallbackSetup = true
                                    thisCategoryConfig.HealthDisplayType:onChange(function(newIndex)
                                        local thisHealthDisplayType = SELECTABLE_HEALTH_DISPLAY_TYPES[newIndex]
                                        if thisHealthDisplayType == HEALTH_DISPLAY_TYPES.None then
                                            thisCategoryConfig.DisplayHealthText:set(false)
                                        elseif thisHealthDisplayType == HEALTH_DISPLAY_TYPES.Text then
                                            thisCategoryConfig.DisplayHealthText:set(true)
                                        end
                                    end)
                                end
                            end
                        end
                        if Iris.Selectable({categoryName, i}, {index = SelectedCategory}).selected() then
                            CategoryChanged = true
                            NewSelectedCategory = i
                            SelectedCategory:set(i)
                        end
                    end
                    Iris.End()

                    Iris.Separator()

                    thisCategoryIndex = NewSelectedCategory or SelectedCategory:get()
                    thisCategoryName = SelectableCategories[thisCategoryIndex]
                    local thisCategoryConfig = Config.ESP.Categories[thisCategoryName]
                    if thisCategoryConfig then
                        local MaxRenderDistance = Iris.SliderNum({"Max Render Distance", 1, 0, 300}, { number = thisCategoryConfig.MaxRenderDistance })
                        if MaxRenderDistance.numberChanged() then
                            thisCategoryConfig.MaxRenderDistance:set(MaxRenderDistance.state.number:get())
                        end

                        local Shapes = Iris.Checkbox({"Shapes Enabled"}, { isChecked = thisCategoryConfig.Shapes })
                        if Shapes.checked() or Shapes.unchecked() then
                            thisCategoryConfig.Shapes:set(Shapes.state.isChecked:get())
                        end

                        local Text = Iris.Checkbox({"Text Enabled"}, { isChecked = thisCategoryConfig.Text })
                        if Text.checked() or Text.unchecked() then
                            thisCategoryConfig.Text:set(Text.state.isChecked:get())
                        end

                        local Tracers = Iris.Checkbox({"Tracers Enabled"}, { isChecked = thisCategoryConfig.Tracers })
                        if Tracers.checked() or Tracers.unchecked() then
                            thisCategoryConfig.Tracers:set(Tracers.state.isChecked:get())
                        end

                        color4Picker("Color", thisCategoryConfig.Color, thisCategoryConfig.Transparency)

                        local NumESPTypes = CountList(SELECTABLE_ESP_TYPES)
                        if NumESPTypes > 0 then
                            local thisESPTypeIndex = thisCategoryConfig.ESPType:get()
                            local thisESPType = SELECTABLE_ESP_TYPES[thisESPTypeIndex]
                            Iris.Text({"ESP Type: " .. thisESPType})
                            Iris.Combo({""}, {index = thisCategoryConfig.ESPType})
                            for i, esptype in ipairs(SELECTABLE_ESP_TYPES) do
                                Iris.Selectable({esptype, i}, {index = thisCategoryConfig.ESPType})
                            end
                            Iris.End()
                        end

                        local NumTracerOrigins = CountList(SELECTABLE_TRACER_ORIGINS)
                        if NumTracerOrigins > 0 then
                            local thisOriginIndex = thisCategoryConfig.TracerOrigin:get()
                            local thisOrigin = SELECTABLE_TRACER_ORIGINS[thisOriginIndex]
                            Iris.Text({"Tracer Origin: " .. thisOrigin})
                            Iris.Combo({""}, {index = thisCategoryConfig.TracerOrigin})
                            for i, origin in ipairs(SELECTABLE_TRACER_ORIGINS) do
                                Iris.Selectable({origin, i}, {index = thisCategoryConfig.TracerOrigin})
                            end
                            Iris.End()
                        end

                        local NumTracerTargets = CountList(SELECTABLE_TRACER_TARGETS)
                        if NumTracerTargets > 0 then
                            local thisTargetIndex = thisCategoryConfig.TracerTarget:get()
                            local thisTarget = SELECTABLE_TRACER_TARGETS[thisTargetIndex]
                            Iris.Text({"Tracer Target: " .. thisTarget})
                            Iris.Combo({""}, {index = thisCategoryConfig.TracerTarget})
                            for i, target in ipairs(SELECTABLE_TRACER_TARGETS) do
                                Iris.Selectable({target, i}, {index = thisCategoryConfig.TracerTarget})
                            end
                            Iris.End()
                        end

                        if thisCategoryConfig.MaxHealthDistance ~= nil then
                            local MaxHealthDistance = Iris.SliderNum({"Max Health Distance", 1, 0, 300}, { number = thisCategoryConfig.MaxHealthDistance})
                            if MaxRenderDistance.numberChanged() then
                                thisCategoryConfig.MaxHealthDistance:set(MaxHealthDistance.state.number:get())
                            end
                        end

                        if thisCategoryConfig.HealthDisplayType ~= nil then
                            local NumHealthDisplayTypes = CountList(SELECTABLE_HEALTH_DISPLAY_TYPES)
                            if NumHealthDisplayTypes > 0 then
                                local thisHealthDisplayTypeIndex = thisCategoryConfig.HealthDisplayType:get()
                                local thisHealthDisplayType = SELECTABLE_HEALTH_DISPLAY_TYPES[thisHealthDisplayTypeIndex]
                                Iris.Text({"Health Display Type: " .. thisHealthDisplayType})
                                Iris.Combo({""}, {index = thisCategoryConfig.HealthDisplayType})
                                for i, healthDisplayType in ipairs(SELECTABLE_HEALTH_DISPLAY_TYPES) do
                                    Iris.Selectable({healthDisplayType, i}, {index = thisCategoryConfig.HealthDisplayType})
                                end
                                Iris.End()
                            end
                        end
                        
                        if thisCategoryConfig.DisplayHealthText ~= nil then
                            local thisHealthDisplayTypeIndex = thisCategoryConfig.HealthDisplayType:get()
                            local thisHealthDisplayType = SELECTABLE_HEALTH_DISPLAY_TYPES[thisHealthDisplayTypeIndex]
                            if thisHealthDisplayType == HEALTH_DISPLAY_TYPES["Vertical Bar"] or thisHealthDisplayType == HEALTH_DISPLAY_TYPES["Horizontal Bar"] then
                                local DisplayHealthText = Iris.Checkbox({"Display Health Text"}, { isChecked = thisCategoryConfig.DisplayHealthText })
                                if DisplayHealthText.checked() or DisplayHealthText.unchecked() then
                                    thisCategoryConfig.DisplayHealthText:set(DisplayHealthText.state.isChecked:get())
                                end
                            end
                        end
                    end
                end;
            end
            Iris.End()

            Iris.Tab({"External Scripts"})
            do
                Iris.Text({"The following scripts are not owned by Brycki404 and could be altered by their owners to run malicious code! Run at your own discretion!"})
                
                if dexLoaded:get() then
                    Iris.Text("Dex++ Loaded!")
                else
                    if Iris.Button({"Run Dex++"}).clicked() then
                        dexLoaded:set(true)
                        if RunDex ~= nil and type(RunDex) == "function" then
                            task.spawn(RunDex)
                        end
                    end
                end
                
                if hydroxideLoaded:get() then
                    Iris.Text("Hydroxide Loaded!")
                else
                    if Iris.Button({"Run Hydroxide"}).clicked() then
                        hydroxideLoaded:set(true)
                        if RunHydroxide ~= nil and type(RunHydroxide) == "function" then
                            task.spawn(RunHydroxide)
                        end
                    end
                end

                if vehicleFlingLoaded:get() then
                    Iris.Text("Vehicle Fling Loaded!")
                else
                    if Iris.Button({"Run Vehicle Fling"}).clicked() then
                        vehicleFlingLoaded:set(true)
                        if RunVehicleFling ~= nil and type(RunVehicleFling) == "function" then
                            task.spawn(RunVehicleFling)
                        end
                    end
                end
            end
            Iris.End()

            Iris.Tab("Vehicles")
            do
                local CarDamageDisabled = Iris.Checkbox({"Car Damage Disabled"}, { isChecked = Config.carDamageDisabled })
                if CarDamageDisabled.checked() or CarDamageDisabled.unchecked() then
                    local newDisabled = CarDamageDisabled.state.isChecked:get()
                    Config.carDamageDisabled:set(newDisabled)
                    carDamageDisabledChanged(newDisabled)
                end

                local VehicleNoclipEnabled = Iris.Checkbox({"Vehicle Noclip Enabled"}, { isChecked = Config.vehicleNoclipEnabled })
                if VehicleNoclipEnabled.checked() or VehicleNoclipEnabled.unchecked() then
                    local newEnabled = VehicleNoclipEnabled.state.isChecked:get()
                    Config.vehicleNoclipEnabled:set(newEnabled)
                    vehicleNoclipEnabledChanged(newEnabled)
                end
                
                local GhostriderEnabled = Iris.Checkbox({"Ghost Rider Enabled"}, { isChecked = Config.ghostriderEnabled })
                if GhostriderEnabled.checked() or GhostriderEnabled.unchecked() then
                    local newEnabled = GhostriderEnabled.state.isChecked:get()
                    Config.ghostriderEnabled:set(newEnabled)
                    ghostriderEnabledChanged(newEnabled)
                end

                if GhostriderEnabled.state.isChecked:get() then
                    local nitrous = Iris.SliderNum({"Ghost Rider Nitrous", 1, 0, 5000}, { number = Config.nitrous })
                    if nitrous.numberChanged() then
                        Config.nitrous:set(nitrous.state.number:get())
                    end

                    local airbrake = Iris.SliderNum({"Ghost Rider Airbrake", 0.001, 0, 1}, { number = Config.airbrake })
                    if airbrake.numberChanged() then
                        Config.airbrake:set(airbrake.state.number:get())
                    end
                end

                Iris.SeparatorText({ "Vehicles: This is Rocket League!" })

                for i, bool: boolean in pairs(Config.rocketLeagueControls:get()) do
                    local ConfigDisplayName = ConfigDisplayNames[i] or i
                    local checkbox = Iris.Checkbox({ConfigDisplayName}, { isChecked = Iris.WeakState(bool) })
                    if checkbox.checked() or checkbox.unchecked() then
                        local newBool = checkbox.state.isChecked:get()
                        local rocketLeagueControls = Config.rocketLeagueControls:get()
                        rocketLeagueControls[i] = newBool
                        Config.rocketLeagueControls:set(rocketLeagueControls)
                        rocketLeagueControlsChanged(rocketLeagueControls)
                    end

                    if checkbox.state.isChecked:get() then
                        if i == "airRollEnabled" then
                            keybindButton("Air Roll Left Keybind", Config.airRollLeftKeybind)
                            keybindButton("Air Roll Right Keybind", Config.airRollRightKeybind)

                            local airRollStrength = Iris.SliderNum({ "Air Roll Strength" , 10000, 1000, 100000}, { number = Config.airRollStrength })
                            if airRollStrength.numberChanged() then
                                Config.airRollStrength:set(airRollStrength.state.number:get())
                            end
                        elseif i == "airPitchEnabled" then
                            keybindButton("Air Pitch Up Keybind", Config.airPitchUpKeybind)
                            keybindButton("Air Pitch Down Keybind", Config.airPitchDownKeybind)

                            local airPitchStrength = Iris.SliderNum({ "Air Pitch Strength" , 10000, 1000, 200000}, { number = Config.airPitchStrength })
                            if airPitchStrength.numberChanged() then
                                Config.airPitchStrength:set(airPitchStrength.state.number:get())
                            end
                        elseif i  == "powerSlideEnabled" then
                            keybindButton("Power Slide Left Keybind", Config.powerSlideLeftKeybind)
                            keybindButton("Power Slide Right Keybind", Config.powerSlideRightKeybind)

                            local powerSlideStrength = Iris.SliderNum({ "Power Slide Strength" , 10000, 200, 50000}, { number = Config.powerSlideStrength })
                            if powerSlideStrength.numberChanged() then
                                Config.powerSlideStrength:set(powerSlideStrength.state.number:get())
                            end
                        end
                    end
                end
            end
            Iris.End()

            Iris.Tab("Auto Farm")
            do
                Iris.Text({"Auto farming scripts that can be toggled on and off."})
                Iris.SeparatorText({"Auto Bus"})
                local AutoBusEnabled = Iris.Checkbox({"Auto Bus Enabled"}, { isChecked = autobus_enabled })
                if AutoBusEnabled.checked() or AutoBusEnabled.unchecked() then
                    local newDisabled = AutoBusEnabled.state.isChecked:get()
                    autobus_enabled:set(newDisabled)
                    if autobus_thread ~= nil then
                        task.cancel(autobus_thread)
                        autobus_thread = nil
                    else
                        autobus_thread = task.spawn(function()
                            while autobus_enabled:get() == true do
                                local bus = getMyBus()
                                local nextStopName = LocalPlayer:GetAttribute("LastBusStation")
                                
                                if bus and nextStopName then
                                    if masterBusLocations[nextStopName] then
                                        executeTeleport(bus, masterBusLocations[nextStopName])
                                    else
                                        for _, stop in ipairs(CollectionService:GetTagged("BusStop")) do
                                            if stop.Name == nextStopName then
                                                local pad = stop:FindFirstChild("Pad")
                                                if pad then
                                                    masterBusLocations[nextStopName] = pad.CFrame
                                                    if saveLocations and type(saveLocations) == "function" then
                                                        saveLocations()
                                                    end
                                                    executeTeleport(bus, pad.CFrame)
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                                task.wait(0.1)
                            end
                        end)
                    end
                end
                Iris.Separator()
            end
            Iris.End()

            Iris.Tab({"Other"})
            do
                for i, bool: boolean in pairs(Config.antis:get()) do
                    local ConfigDisplayName = ConfigDisplayNames[i] or i
                    local checkbox = Iris.Checkbox({ConfigDisplayName}, { isChecked = Iris.WeakState(bool) })
                    if checkbox.checked() or checkbox.unchecked() then
                        local newBool = checkbox.state.isChecked:get()
                        local antis = Config.antis:get()
                        antis[i] = newBool
                        Config.antis:set(antis)
                        antisChanged(antis)
                    end
                end

                Iris.SeparatorText({ "Tools" })

                local hitboxExtendTool = Iris.Button({"Extend Hitbox (Melee)"})
                if hitboxExtendTool.clicked() then
                    extendToolHitbox()
                end

                if ak47Tampered == false then
                    local TamperAK47 = Iris.Button({"Tamper AK47"})
                    if ak47Tampered == false and TamperAK47.clicked() then
                        ak47Tampered = true
                        tamperGun("AK47")
                    end
                end            
            end
            Iris.End()
        end
        Iris.End()
    end
    Iris.End()

    if Config.showRuntimeInfo.value then
        runtimeInfo()
    end
    if Config.showDebugWindow.value then
        debugPanel()
    end
    if Config.showStyleEditor.value then
        styleEditor()
    end
end)

--Anti AFK
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

--Virtual Input (for keyboard inputs)
local VirtualInputManager = game:GetService("VirtualInputManager")
function genv.sendkeyevent(isPressed: boolean, keyCode: Enum.KeyCode)
    assert(isPressed ~= nil, "[ERROR] sendkeyevent parameter[1] \"isPressed\" must be a boolean!")
    assert(keyCode ~= nil, "[ERROR] sendkeyevent parameter[2] \"keyCode\" must be an Enum.KeyCode!")
    if VirtualInputManager and VirtualInputManager.SendKeyEvent then
        VirtualInputManager:SendKeyEvent(isPressed, keyCode, false, nil)
    else
        warn("VirtualInputManager isn't accessible")
    end
end

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
    if not gameProcessedEvent then
        local validWindowKeyCode = Enum.KeyCode[Config.windowKeyCode:get()]
        if validWindowKeyCode then
            if input.KeyCode == validWindowKeyCode then
                Config.showMainWindow:set(not Config.showMainWindow:get())
            end
        end
    end
end)

--ESP
do
    local ESPList = {}

    function DrawGenericShape(entry, calculations)
        local thisConfig = nil
        local thisESPTypeIndex = nil
        local thisESPType = nil
        local thisTracerOriginIndex = nil
        local thisTracerOrigin = nil
        local thisTracerTargetIndex = nil
        local thisTracerTarget = nil
        if entry.Category then
            thisConfig = Config.ESP.Categories[entry.Category]
            if thisConfig then
                thisESPTypeIndex = thisConfig.ESPType:get()
                thisESPType = SELECTABLE_ESP_TYPES[thisESPTypeIndex]

                thisTracerOriginIndex = thisConfig.TracerOrigin:get()
                thisTracerOrigin = SELECTABLE_TRACER_ORIGINS[thisTracerOriginIndex]

                thisTracerTargetIndex = thisConfig.TracerTarget:get()
                thisTracerTarget = SELECTABLE_TRACER_TARGETS[thisTracerTargetIndex]
            end
        end

        local CF = calculations.CF
        local Size = calculations.Size
        local ViewportPoint = calculations.ViewportPoint
        local ScreenPosition = calculations.ScreenPosition
        local ScreenSize = calculations.ScreenSize
        local OnScreen = calculations.OnScreen
        local ScreenPoints = calculations.ScreenPoints
        local Anchors = calculations.Anchors
        local FailedRenderDistance = calculations.FailedRenderDistance

        local baseZIndex = 1
        local bumpZIndex = thisConfig.ZIndexBump and type(thisConfig.ZIndexBump) == "number" and thisConfig.ZIndexBump or 0
        bumpZIndex = math.ceil(math.max(0, bumpZIndex))
        baseZIndex += bumpZIndex

        local drawing = nil
        local properties = {}
        properties.color = thisConfig and thisConfig.Color:get() or nil
        properties.visible = Config.ESP.MasterShapes:get() and (thisConfig and thisConfig.Shapes:get() or false) == true and OnScreen and not FailedRenderDistance or false
        properties.tracer = Config.ESP.MasterTracers:get() == true and (thisConfig and thisConfig.Tracers:get() or false) == true and ViewportPoint.Z > 0 and {} or nil
        if properties.tracer then
            properties.tracer.origin = thisTracerOrigin
            properties.tracer.target = thisTracerTarget
            properties.tracer.color = properties.color
        end

        local transparency = 1 - (thisConfig and thisConfig.Transparency:get()/255 or 0) --opposite from Roblox's Transparency!!!

        if thisConfig and thisESPType == ESP_TYPES.Box then
            --Box
            properties.data = {}
            properties.data.ZIndex = baseZIndex
            properties.data.Transparency = transparency
            properties.data.ScreenPoints = ScreenPoints
            properties.data.Anchors = Anchors
            
            drawing = ESP:createBox3D(properties)
        elseif thisConfig and thisESPType == ESP_TYPES.Quad then
            --Quad
            properties.data = {}
            properties.data.ZIndex = baseZIndex
            properties.data.Transparency = transparency
            properties.data.ScreenPoints = ScreenPoints
            properties.data.Anchors = Anchors

            drawing = ESP:createRect3D(properties)
        else
            --Rect
            properties.data = {}
            properties.data.ZIndex = baseZIndex
            properties.data.Transparency = transparency
            properties.data.ScreenPoints = ScreenPoints
            properties.data.Anchors = Anchors
            
            drawing = ESP:createRect2D(properties)
        end

        return drawing
    end

    function DrawText(entry, calculations)
        local thisConfig = nil
        if entry.Category then
            thisConfig = Config.ESP.Categories[entry.Category]
        end

        local OnScreen = calculations.OnScreen
        if not OnScreen then
            return nil
        end

        local visible = Config.ESP.MasterText:get() and (thisConfig and thisConfig.Text:get() or true)
        if not visible then
            return nil
        end

        local FailedRenderDistance = calculations.FailedRenderDistance
        if FailedRenderDistance then
            return nil
        end

        local CF = calculations.CF
        local Size = calculations.Size
        local ViewportPoint = calculations.ViewportPoint
        local ScreenPosition = calculations.ScreenPosition
        local ScreenSize = calculations.ScreenSize
        local Anchors = calculations.Anchors
        
        local baseZIndex = 91
        local bumpZIndex = thisConfig.ZIndexBump and type(thisConfig.ZIndexBump) == "number" and thisConfig.ZIndexBump or 0
        bumpZIndex = math.ceil(math.max(0, bumpZIndex))
        baseZIndex += bumpZIndex

        local properties = {}
        properties.color = thisConfig and thisConfig.Color:get() or nil
        properties.data = {}
        properties.data.ZIndex = baseZIndex
        properties.data.Transparency = 1
        properties.data.Text = entry.DisplayName
        properties.data.Pos = Vector2.new(math.floor(ScreenPosition.X+0.5), math.floor(ScreenPosition.Y+0.5))
        
        local drawing = ESP:createText(properties)

        return drawing
    end

    function DrawHealthbar(entry, calculations, displayType)
        if displayType == HEALTH_DISPLAY_TYPES.None then return nil end
        if not entry.Humanoid then return nil end

        local thisConfig = nil
        if entry.Category then
            thisConfig = Config.ESP.Categories[entry.Category]
        end

        local maxHealth = entry.Humanoid.MaxHealth
        local health = math.clamp(entry.Humanoid.Health, 0, maxHealth)
        local healthString = string.format("hp: %d/%d", math.ceil(health), math.ceil(maxHealth))
        local healthFraction = health/maxHealth

        local OnScreen = calculations.OnScreen
        if not OnScreen then
            return nil
        end

        local visible = Config.ESP.MasterText:get() and (thisConfig and thisConfig.Text:get() or true)
        if not visible then
            return nil
        end

        local FailedHealthDistance = calculations.FailedHealthDistance
        if FailedHealthDistance then
            return nil
        end

        local CF = calculations.CF
        local Size = calculations.Size
        local ViewportPoint = calculations.ViewportPoint
        local ScreenPosition = calculations.ScreenPosition
        local ScreenSize = calculations.ScreenSize
        local Anchors = calculations.Anchors

        local baseZIndex = 51
        local bumpZIndex = thisConfig.ZIndexBump and type(thisConfig.ZIndexBump) == "number" and thisConfig.ZIndexBump or 0
        bumpZIndex = math.ceil(math.max(0, bumpZIndex))
        baseZIndex += 3 * bumpZIndex

        local drawings = {}

        -- Based on ScreenPosition and ScreenSize to move the bar where I want it relative to the Model
        local textBoxWidth = ScreenSize.X
        local textBoxHeight = math.min(30, ScreenSize.Y * 0.15)
        local textBoxPos = Anchors.Top - Vector2.yAxis * textBoxHeight * 1.5
        
        local transparency = 1 - (thisConfig and thisConfig.Transparency:get()/255 or 0) --opposite from Roblox's Transparency!!!

        --BoxFill

        local fillproperties = {}
        fillproperties.data = {}
        fillproperties.data.ZIndex = baseZIndex
        fillproperties.data.Filled = true
        fillproperties.data.FillColor = Color3.new(1)
        fillproperties.data.FillTransparency = 1 - (1 - transparency) * (1 - 0.35) --opposite from Roblox's Transparency!!!
        fillproperties.data.Transparency = 0
        fillproperties.data.Thickness = 0

        --BoxOutline

        local outlineproperties = {}
        outlineproperties.data = {}
        outlineproperties.data.ZIndex = baseZIndex + 1
        outlineproperties.data.Transparency = transparency
        outlineproperties.data.Thickness = 1

        --Text

        local textproperties = {}
        textproperties.data = {}
        textproperties.data.ZIndex = baseZIndex + 2
        textproperties.data.Transparency = 1
        textproperties.data.Text = healthString
        textproperties.data.Pos = Vector2.new(math.floor(textBoxPos.X+0.5), math.floor(textBoxPos.Y+0.5))

        if displayType == HEALTH_DISPLAY_TYPES["Vertical Bar"] then
            local barWidth = math.min(30, ScreenSize.X * 0.15)
            local barHeight = ScreenSize.Y

            local barScreenPoints = {
                TopLeft = Anchors.TopLeft - Vector2.xAxis * barWidth;
                TopRight = Anchors.TopLeft;
                BottomRight = Anchors.BottomLeft;
                BottomLeft = Anchors.BottomLeft - Vector2.xAxis * barWidth;
            }

            local fillHeight = barHeight * healthFraction

            local fillScreenPoints = {
                TopLeft = barScreenPoints.BottomLeft - Vector2.yAxis * fillHeight;
                TopRight = barScreenPoints.BottomRight - Vector2.yAxis * fillHeight;
                BottomRight = barScreenPoints.BottomRight;
                BottomLeft = barScreenPoints.BottomLeft;
            }

            -- Fill anchored to the bottom\

            fillproperties.data.ScreenPoints = fillScreenPoints
            outlineproperties.data.ScreenPoints = barScreenPoints

            drawings.filling = ESP:createRect2D(fillproperties)
            drawings.outline = ESP:createRect2D(outlineproperties)
        elseif displayType == HEALTH_DISPLAY_TYPES["Horizontal Bar"] then
            local barWidth = textBoxWidth
            local barHeight = textBoxHeight
            local barScreenPoints = {
                TopLeft = Anchors.TopLeft - Vector2.xAxis * barHeight;
                TopRight = Anchors.TopLeft - Vector2.xAxis * barHeight;
                BottomRight = Anchors.TopRight;
                BottomLeft = Anchors.TopRight;
            }
            
            local fillWidth = barWidth * healthFraction

            local fillScreenPoints = {
                TopLeft = barScreenPoints.TopLeft;
                TopRight = barScreenPoints.TopLeft + Vector2.xAxis * fillWidth;
                BottomRight = barScreenPoints.BottomLeft + Vector2.xAxis * fillWidth;
                BottomLeft = barScreenPoints.BottomLeft;
            }

            -- Fill anchored to the left

            fillproperties.data.ScreenPoints = fillScreenPoints
            outlineproperties.data.ScreenPoints = barScreenPoints

            drawings.filling = ESP:createRect2D(fillproperties)
            drawings.outline = ESP:createRect2D(outlineproperties)
        end

        drawings.textlabel = ESP:createText(textproperties)

        return drawings
    end

    function DrawGenericESP(entry)
        if not entry.Model or not entry.Part then
            return
        end

        local thisConfig = nil
        local thisESPTypeIndex = nil
        local thisESPType = nil
        if entry.Category then
            thisConfig = Config.ESP.Categories[entry.Category]
            if thisConfig then
                if thisConfig.ESPType ~= nil then
                    thisESPTypeIndex = thisConfig.ESPType:get()
                    thisESPType = SELECTABLE_ESP_TYPES[thisESPTypeIndex]
                end
            end
        end
        local calculations = nil
        if thisESPType == ESP_TYPES.Box then
            calculations = ESP.CalculateBox3D(entry.Model)
        elseif thisESPType == ESP_TYPES.Quad then
            calculations = ESP.CalculateRect3D(entry.Model)
        else
            --Rect
            --also when Category == nil -> "default" category
            calculations = ESP.CalculateRect2D(entry.Model)
        end

        local itsPos = calculations and calculations.CF and calculations.CF.Position or nil
        if not itsPos then
            return
        end
        
        local MyDistanceSquared = ESP.GetMyDistanceSquared(itsPos)
        local MaxRenderDistanceSquared = math.min(Config.ESP.MasterMaxRenderDistance:get() or 20000, (thisConfig ~= nil and thisConfig.MaxRenderDistance ~= nil and thisConfig.MaxRenderDistance:get()) or 20000)
        if MaxRenderDistanceSquared and type(MaxRenderDistanceSquared) == "number" then
            --Unsquared, so Square it
            MaxRenderDistanceSquared = MaxRenderDistanceSquared * MaxRenderDistanceSquared
            calculations.FailedRenderDistance = MyDistanceSquared > MaxRenderDistanceSquared
        else
            MaxRenderDistanceSquared = math.huge
            calculations.FailedRenderDistance = false
        end
        local MaxHealthDistanceSquared = (thisConfig ~= nil and thisConfig.MaxHealthDistance ~= nil and thisConfig.MaxHealthDistance:get() or 300)
        if MaxHealthDistanceSquared and type(MaxHealthDistanceSquared) == "number" then
            --Unsquared, so Square it
            MaxHealthDistanceSquared = MaxHealthDistanceSquared * MaxHealthDistanceSquared
            calculations.FailedHealthDistance = MyDistanceSquared > MaxHealthDistanceSquared
        end

        if entry.Category == "Player" then
            if not thisConfig then
                return
            end

            local healthDisplayTypeIndex = thisConfig.HealthDisplayType:get()
            local healthDisplayType = SELECTABLE_HEALTH_DISPLAY_TYPES[healthDisplayTypeIndex]

            DrawGenericShape(entry, calculations)
            DrawText(entry, calculations)
            DrawHealthbar(entry, calculations, healthDisplayType)

        else
            --"default" category, when Category == nil
            DrawGenericShape(entry, calculations)
            DrawText(entry, calculations)
        end
    end

    function Draw(model, params)
        local displayName = params.DisplayName
        local category = params.Category
        local part = params.Part
        local humanoid = params.Humanoid

        local id = tostring(model:GetDebugId())
        local entry = {
            id = id;
            DisplayName = displayName;
            Category = category;
            Model = model;
            Part = part;
            Humanoid = humanoid;
        }
        ESPList[id] = entry
    end

    function makeESP(Model: Instance)
        if not Model or not Model:IsA("BasePart") and not Model:IsA("Model") then
            return
        end
        local id = tostring(Model:GetDebugId())
        if not ESPList[id] then
           if Model:IsDescendantOf(workspace) and Model:IsA("Model") then
                local Humanoid = Model:FindFirstChildOfClass("Humanoid")
                if Humanoid then
                    local gotPlayer = Players:GetPlayerFromCharacter(Model)
                    if gotPlayer then
                        if gotPlayer ~= LocalPlayer then
                            Draw(Model, {
                                Part = Model.PrimaryPart or Model:FindFirstChild("HumanoidRootPart");
                                DisplayName = gotPlayer.Name;
                                Category = "Player";
                                Humanoid = Humanoid;
                            })
                        end
                    end
                end
            end
        end
    end

    for i: number, v: Instance in ipairs(workspace.Characters:GetChildren()) do
        task.spawn(function()
            if v:IsA("Model") then
                if v:FindFirstChildOfClass("Humanoid") then
                    makeESP(v)
                end
            end
        end)
    end

    local workspace_child_added_connection = workspace.Characters.ChildAdded:Connect(function(v)
        task.spawn(makeESP, v)
    end)

    local function drawFunction()
        for modelId, entry in pairs(ESPList) do
            if not entry.Model or not entry.Part then
                table.clear(entry)
                entry = nil
                continue
            end
            DrawGenericESP(entry)
        end
    end

    local esp_update_draw_thread = task.spawn(function()
        local framerate = 60
        local frameTime = 1/framerate
        local lastTime = nil
        while true do
            if not lastTime or os.clock() - lastTime >= frameTime then
                ESP:render(drawFunction)
                lastTime = os.clock()
            end
            task.wait()
        end
    end)
end
