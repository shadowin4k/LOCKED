--[[

	Universal Aimbot Module by Exunys © CC0 1.0 Universal (2023 - 2024)
	TOGGLE ADDED: Press C to enable / disable entire aimbot

]]

--// Cache
local game, workspace = game, workspace
local getrawmetatable, setmetatable, pcall, getgenv, next, tick =
	getrawmetatable, setmetatable, pcall, getgenv, next, tick

local Vector2new, Vector3zero, CFramenew, Color3fromRGB, Color3fromHSV =
	Vector2.new, Vector3.zero, CFrame.new, Color3.fromRGB, Color3.fromHSV

local Drawingnew, TweenInfonew = Drawing.new, TweenInfo.new
local mousemoverel = mousemoverel or (Input and Input.MouseMove)
local tablefind, tableremove = table.find, table.remove
local stringlower, stringsub = string.lower, string.sub
local mathclamp = math.clamp

--// Metatable fallback
local GameMetatable = getrawmetatable and getrawmetatable(game) or {
	__index = function(self, k) return self[k] end,
	__newindex = function(self, k, v) self[k] = v end
}

local __index = GameMetatable.__index
local __newindex = GameMetatable.__newindex

local getrenderproperty = getrenderproperty or __index
local setrenderproperty = setrenderproperty or __newindex

local GetService = __index(game, "GetService")

--// Services
local RunService = GetService(game, "RunService")
local UserInputService = GetService(game, "UserInputService")
local TweenService = GetService(game, "TweenService")
local Players = GetService(game, "Players")

--// Objects
local LocalPlayer = __index(Players, "LocalPlayer")
local Camera = __index(workspace, "CurrentCamera")

local FindFirstChild, FindFirstChildOfClass =
	__index(game, "FindFirstChild"),
	__index(game, "FindFirstChildOfClass")

local GetDescendants = __index(game, "GetDescendants")
local WorldToViewportPoint = __index(Camera, "WorldToViewportPoint")
local GetPartsObscuringTarget = __index(Camera, "GetPartsObscuringTarget")
local GetMouseLocation = __index(UserInputService, "GetMouseLocation")
local GetPlayers = __index(Players, "GetPlayers")

--// State
local RequiredDistance = 2000
local Typing = false
local Running = false
local ServiceConnections = {}
local Animation
local OriginalSensitivity

local Connect = __index(game, "DescendantAdded").Connect
local Disconnect

--// Prevent double load
if ExunysDeveloperAimbot and ExunysDeveloperAimbot.Exit then
	ExunysDeveloperAimbot:Exit()
end

--// Environment
getgenv().ExunysDeveloperAimbot = {
	DeveloperSettings = {
		UpdateMode = "RenderStepped",
		TeamCheckOption = "TeamColor",
		RainbowSpeed = 1
	},

	Settings = {
		Enabled = true,

		TeamCheck = false,
		AliveCheck = true,
		WallCheck = false,

		OffsetToMoveDirection = false,
		OffsetIncrement = 15,

		Sensitivity = 0,
		Sensitivity2 = 3.5,

		LockMode = 1,
		LockPart = "Head",

		TriggerKey = Enum.UserInputType.MouseButton2,
		Toggle = false,

		ToggleKey = Enum.KeyCode.C -- 🔥 GLOBAL TOGGLE
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
		Color = Color3fromRGB(255,255,255),
		OutlineColor = Color3fromRGB(0,0,0),
		LockedColor = Color3fromRGB(255,150,150)
	},

	Blacklisted = {},
	FOVCircleOutline = Drawingnew("Circle"),
	FOVCircle = Drawingnew("Circle")
}

local Environment = getgenv().ExunysDeveloperAimbot

setrenderproperty(Environment.FOVCircle, "Visible", false)
setrenderproperty(Environment.FOVCircleOutline, "Visible", false)

--// Helpers
local function FixUsername(str)
	for _, v in next, GetPlayers(Players) do
		if stringsub(stringlower(v.Name), 1, #str) == stringlower(str) then
			return v.Name
		end
	end
end

local function GetRainbowColor()
	local s = Environment.DeveloperSettings.RainbowSpeed
	return Color3fromHSV(tick() % s / s, 1, 1)
end

local function ConvertVector(v)
	return Vector2new(v.X, v.Y)
end

local function CancelLock()
	Environment.Locked = nil
	setrenderproperty(Environment.FOVCircle, "Color", Environment.FOVSettings.Color)
	__newindex(UserInputService, "MouseDeltaSensitivity", OriginalSensitivity)
	if Animation then Animation:Cancel() end
end

local function GetClosestPlayer()
	local Settings = Environment.Settings
	local LockPart = Settings.LockPart

	if not Environment.Locked then
		RequiredDistance = Environment.FOVSettings.Enabled and Environment.FOVSettings.Radius or 2000

		for _, v in next, GetPlayers(Players) do
			local c = v.Character
			local h = c and FindFirstChildOfClass(c, "Humanoid")

			if v ~= LocalPlayer and c and h and FindFirstChild(c, LockPart)
			and not tablefind(Environment.Blacklisted, v.Name) then

				if Settings.AliveCheck and h.Health <= 0 then continue end
				if Settings.TeamCheck and v.TeamColor == LocalPlayer.TeamColor then continue end

				local pos = c[LockPart].Position
				local vec, onScreen = WorldToViewportPoint(Camera, pos)
				local dist = (GetMouseLocation(UserInputService) - ConvertVector(vec)).Magnitude

				if dist < RequiredDistance and onScreen then
					RequiredDistance = dist
					Environment.Locked = v
				end
			end
		end
	else
		CancelLock()
	end
end

--// Load
local function Load()
	OriginalSensitivity = UserInputService.MouseDeltaSensitivity

	ServiceConnections.Render = Connect(RunService.RenderStepped, function()
		if not Environment.Settings.Enabled then return end
		if Running then GetClosestPlayer() end
	end)

	ServiceConnections.InputBegan = Connect(UserInputService.InputBegan, function(i, gp)
		if gp or Typing then return end

		-- 🔥 GLOBAL TOGGLE
		if i.KeyCode == Environment.Settings.ToggleKey then
			Environment.Settings.Enabled = not Environment.Settings.Enabled
			if not Environment.Settings.Enabled then
				Running = false
				CancelLock()
				setrenderproperty(Environment.FOVCircle, "Visible", false)
				setrenderproperty(Environment.FOVCircleOutline, "Visible", false)
			end
			return
		end

		if i.UserInputType == Environment.Settings.TriggerKey then
			Running = true
		end
	end)

	ServiceConnections.InputBegan = Connect(UserInputService.InputBegan, function(i, gp)
	if gp or Typing then return end

	-- 🔥 GLOBAL TOGGLE (C)
	if i.UserInputType == Enum.UserInputType.Keyboard
	and i.KeyCode == Environment.Settings.ToggleKey then

		Environment.Settings.Enabled = not Environment.Settings.Enabled

		if not Environment.Settings.Enabled then
			Running = false
			CancelLock()

			setrenderproperty(Environment.FOVCircle, "Visible", false)
			setrenderproperty(Environment.FOVCircleOutline, "Visible", false)
		end

		return
	end

	-- 🎯 AIM TRIGGER (RMB)
	if i.UserInputType == Environment.Settings.TriggerKey
	and Environment.Settings.Enabled then
		Running = true
	end
end)

--// Exit
function Environment.Exit(self)
	for _, c in next, ServiceConnections do
		pcall(function() c:Disconnect() end)
	end
	self.FOVCircle:Remove()
	self.FOVCircleOutline:Remove()
	getgenv().ExunysDeveloperAimbot = nil
end

Environment.Load = Load
setmetatable(Environment, { __call = Load })

Load()
return Environment
