--[[ 
    Universal Aimbot Module by Exunys © CC0 1.0 Universal (2023 - 2024)
    TOGGLE ADDED: Press C to enable / disable entire aimbot
]]

--// Cache
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--// State
local Running = false
local Typing = false
local OriginalSensitivity
local LockedPlayer = nil
local Animation = nil
local RequiredDistance = 2000

--// Settings
local Settings = {
    Enabled = true,
    TriggerKey = Enum.UserInputType.MouseButton2, -- RMB to aim
    ToggleKey = Enum.KeyCode.C,                  -- C to toggle
    LockPart = "Head",
    Sensitivity = 0,
    Sensitivity2 = 3.5
}

--// FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Radius = 90
FOVCircle.Color = Color3.fromRGB(255,255,255)
FOVCircle.Thickness = 1

--// Helper Functions
local function CancelLock()
    LockedPlayer = nil
    FOVCircle.Color = Color3.fromRGB(255,255,255)
    if Animation then
        Animation:Cancel()
        Animation = nil
    end
    if OriginalSensitivity then
        UserInputService.MouseDeltaSensitivity = OriginalSensitivity
    end
end

local function GetMouseVector()
    local pos = UserInputService:GetMouseLocation()
    return Vector2.new(pos.X, pos.Y)
end

local function GetClosestPlayer()
    local closestDist = Settings.Enabled and FOVCircle.Radius or 2000
    local closest = nil
    for _, plr in next, Players:GetPlayers() do
        if plr == LocalPlayer then continue end
        local char = plr.Character
        if not char then continue end
        local part = char:FindFirstChild(Settings.LockPart)
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not part or not humanoid or humanoid.Health <= 0 then continue end

        local vec, onScreen = Camera:WorldToViewportPoint(part.Position)
        vec = Vector2.new(vec.X, vec.Y)
        local dist = (GetMouseVector() - vec).Magnitude
        if dist < closestDist and onScreen then
            closestDist = dist
            closest = plr
        end
    end
    LockedPlayer = closest
end

--// Connections
RunService.RenderStepped:Connect(function()
    FOVCircle.Position = GetMouseVector()
    if Running and Settings.Enabled then
        GetClosestPlayer()
        if LockedPlayer and LockedPlayer.Character and LockedPlayer.Character:FindFirstChild(Settings.LockPart) then
            local targetPos = LockedPlayer.Character[Settings.LockPart].Position
            if Settings.Sensitivity > 0 then
                Animation = TweenService:Create(Camera, TweenInfo.new(Settings.Sensitivity), {CFrame = CFrame.new(Camera.CFrame.Position, targetPos)})
                Animation:Play()
            else
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPos)
            end
        end
    else
        CancelLock()
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp or Typing then return end

    -- Toggle C
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Settings.ToggleKey then
        Settings.Enabled = not Settings.Enabled
        if not Settings.Enabled then
            Running = false
            CancelLock()
            FOVCircle.Visible = false
        else
            FOVCircle.Visible = true
        end
        return
    end

    -- RMB Trigger
    if Settings.Enabled and input.UserInputType == Settings.TriggerKey then
        Running = true
        FOVCircle.Visible = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Settings.TriggerKey then
        Running = false
        CancelLock()
        FOVCircle.Visible = Settings.Enabled
    end
end)

UserInputService.TextBoxFocused:Connect(function()
    Typing = true
end)

UserInputService.TextBoxFocusReleased:Connect(function()
    Typing = false
end)

--// Start
OriginalSensitivity = UserInputService.MouseDeltaSensitivity
FOVCircle.Visible = Settings.Enabled
