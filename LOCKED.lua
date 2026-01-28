
```lua
task.spawn(function()
    wait(math.random(5,15))
    
    --[[ Universal Aimbot Module by GenericDeveloper © CC0 1.0 Universal (2023 - 2024) ]]--
    
    --// Cache
    local game, workspace = game, workspace
    local getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick = getrawmetatable, getmetatable, setmetatable, pcall, getgenv, next, tick
    local Vector2new, Vector3zero, CFramenew, Color3fromRGB, Color3fromHSV, Drawingnew, TweenInfonew = Vector2.new, Vector3.zero, CFrame.new, Color3.fromRGB, Color3.fromHSV, Drawing.new, TweenInfo.new
    local getupvalue, mousemoverel, tablefind, tableremove, stringlower, stringsub, mathclamp = debug.getupvalue, mousemoverel or (Input and Input.MouseMove), table.find, table.remove, string.lower, string.sub, math.clamp
    local GameMetatable = getrawmetatable and getrawmetatable(game) or {
        __index = function(self, Index) return self[Index] end,
        __newindex = function(self, Index, Value) self[Index] = Value end
    }
    local __index = GameMetatable.__index
    local __newindex = GameMetatable.__newindex
    local getrenderproperty, setrenderproperty = getrenderproperty or __index, setrenderproperty or __newindex
    local GetService = __index(game, "GetService")
    
    --// Services
    local RunService = GetService(game, "RunService")
    local UserInputService = GetService(game, "UserInputService")
    local TweenService = GetService(game, "TweenService")
    local Players = GetService(game, "Players")
    
    --// Service Methods
    local LocalPlayer = __index(Players, "LocalPlayer")
    local Camera = __index(workspace, "CurrentCamera")
    local FindFirstChild, FindFirstChildOfClass = __index(game, "FindFirstChild"), __index(game, "FindFirstChildOfClass")
    local GetDescendants = __index(game, "GetDescendants")
    local WorldToViewportPoint = __index(Camera, "WorldToViewportPoint")
    local GetPartsObscuringTarget = __index(Camera, "GetPartsObscuringTarget")
    local GetMouseLocation = __index(UserInputService, "GetMouseLocation")
    local GetPlayers = __index(Players, "GetPlayers")
    
    --// Variables
    local RequiredDistance, Typing, Running, ServiceConnections, Animation, OriginalSensitivity = 2000, false, false, {}
    local Connect, Disconnect = __index(game, "DescendantAdded").Connect
    
    --// Environment Check for Detection
    if #getnilinstances() > 50 or getconnections and #getconnections(game.Loaded) ~= 1 then
        return
    end
    
    --// Anti-Screenshot
    game:GetService("RunService").Heartbeat:Connect(function()
        if game:GetService("Players").LocalPlayer.Character then
            local head = game:GetService("Players").LocalPlayer.Character:FindFirstChild("Head")
            if head and math.random(1, 100) == 1 then
                head.Transparency = 0.9
            end
        end
    end)
    
    --// Keybind Rotation
    local triggerKeys = {Enum.UserInputType.MouseButton2, Enum.KeyCode.Q, Enum.KeyCode.LeftAlt}
    local currentKeyIndex = 1
    local lastKeyChange = tick()
    
    local function rotateKeybind()
        if tick() - lastKeyChange > math.random(120, 180) then
            currentKeyIndex = (currentKeyIndex % #triggerKeys) + 1
            lastKeyChange = tick()
        end
        return triggerKeys[currentKeyIndex]
    end
    
    --// Humanized Aim Variables
    local aimJitterX = 0
    local aimJitterY = 0
    local lastJitterUpdate = tick()
    local lockAcceleration = 0
    local lockStartTime = 0
    
    --// FOV Circle Alternative (Part-based)
    local fakeFOVPart = Instance.new("Part")
    fakeFOVPart.Transparency = 0.9
    fakeFOVPart.Anchored = true
    fakeFOVPart.CanCollide = false
    fakeFOVPart.Size = Vector3.new(0.1, 0.1, 0.1)
    fakeFOVPart.Color = Color3.fromRGB(255, 255, 255)
    fakeFOVPart.Material = Enum.Material.ForceField
    fakeFOVPart.Parent = workspace
    
    --// Checking for multiple processes
    if GenericAimbotModule and GenericAimbotModule.Exit then
        GenericAimbotModule:Exit()
    end
    
    --// Environment
    getgenv().GenericAimbotModule = {
        DeveloperSettings = {
            UpdateMode = "RenderStepped",
            TeamCheckOption = "TeamColor",
            RainbowSpeed = 1 -- Bigger = Slower
        },
        Settings = {
            Enabled = true,
            TeamCheck = false,
            AliveCheck = true,
            WallCheck = false,
            OffsetToMoveDirection = false,
            OffsetIncrement = 15,
            Sensitivity = 0, -- Animation length (in seconds) before fully locking onto target
            Sensitivity2 = 3.5, -- mousemoverel Sensitivity
            LockMode = 1, -- 1 = CFrame; 2 = mousemoverel
            LockPart = "Head", -- Body part to lock on
            TriggerKey = rotateKeybind(),
            Toggle = false
        },
        FOVSettings = {
            Enabled = true,
            Visible = true,
            Radius = 90,
            NumSides = 60,
            Thickness = 1,
            Transparency = 1,
            Filled = false,
            RainbowColor = false,
            RainbowOutlineColor = false,
            Color = Color3fromRGB(255, 255, 255),
            OutlineColor = Color3.fromRGB(0, 0, 0),
            LockedColor = Color3fromRGB(255, 150, 150)
        },
        Blacklisted = {},
        FOVCircleOutline = Drawingnew("Circle"),
        FOVCircle = Drawingnew("Circle")
    }
    
    local Environment = getgenv().GenericAimbotModule
    setrenderproperty(Environment.FOVCircle, "Visible", false)
    setrenderproperty(Environment.FOVCircleOutline, "Visible", false)
    
    --// Core Functions
    local FixUsername = function(String)
        local Result
        for _, Value in next, GetPlayers(Players) do
            local Name = __index(Value, "Name")
            if stringsub(stringlower(Name), 1, #String) == stringlower(String) then
                Result = Name
            end
        end
        return Result
    end
    
    local GetRainbowColor = function()
        local RainbowSpeed = Environment.DeveloperSettings.RainbowSpeed
        return Color3fromHSV(tick() % RainbowSpeed / RainbowSpeed, 1, 1)
    end
    
    local ConvertVector = function(Vector)
        return Vector2new(Vector.X, Vector.Y)
    end
    
    local CancelLock = function()
        Environment.Locked = nil
        local FOVCircle = Environment.FOVCircle
        setrenderproperty(FOVCircle, "Color", Environment.FOVSettings.Color)
        __newindex(UserInputService, "MouseDeltaSensitivity", OriginalSensitivity)
        if Animation then
            Animation:Cancel()
        end
        lockAcceleration = 0
        lockStartTime = 0
    end
    
    local GetClosestPlayer = function()
        local Settings = Environment.Settings
        local LockPart = Settings.LockPart
        if not Environment.Locked then
            RequiredDistance = Environment.FOVSettings.Enabled and Environment.FOVSettings.Radius or 2000
            for _, Value in next, GetPlayers(Players) do
                local Character = __index(Value, "Character")
                local Humanoid = Character and FindFirstChildOfClass(Character, "Humanoid")
                if Value ~= LocalPlayer and not tablefind(Environment.Blacklisted, __index(Value, "Name")) and Character and FindFirstChild(Character, LockPart) and Humanoid then
                    local PartPosition, TeamCheckOption = __index(Character[LockPart], "Position"), Environment.DeveloperSettings.TeamCheckOption
                    if Settings.TeamCheck and __index(Value, TeamCheckOption) == __index(LocalPlayer, TeamCheckOption) then
                        continue
                    end
                    if Settings.AliveCheck and __index(Humanoid, "Health") <= 0 then
                        continue
                    end
                    if Settings.WallCheck then
                        local BlacklistTable = GetDescendants(__index(LocalPlayer, "Character"))
                        for _, Value in next, GetDescendants(Character) do
                            BlacklistTable[#BlacklistTable + 1] = Value
                        end
                        if #GetPartsObscuringTarget(Camera, {PartPosition}, BlacklistTable) > 0 then
                            continue
                        end
                    end
                    local Vector, OnScreen, Distance = WorldToViewportPoint(Camera, PartPosition)
                    Vector = ConvertVector(Vector)
                    Distance = (GetMouseLocation(UserInputService) - Vector).Magnitude
                    if Distance < RequiredDistance and OnScreen then
                        RequiredDistance, Environment.Locked = Distance, Value
                    end
                end
