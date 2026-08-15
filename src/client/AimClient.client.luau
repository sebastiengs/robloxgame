-- Right click to aim. Snipers get a real scope view.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local NORMAL_FOV = 70
local AIM_FOV = 45
local SCOPE_FOV = 18

local aiming = false

local gui = Instance.new("ScreenGui")
gui.Name = "AimGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- the black scope ring, only used by guns with a scope
local scope = Instance.new("Frame")
scope.Size = UDim2.new(1, 0, 1, 0)
scope.BackgroundTransparency = 1
scope.Visible = false
scope.Parent = gui

local function edge(size, position)
	local part = Instance.new("Frame")
	part.Size = size
	part.Position = position
	part.BackgroundColor3 = Color3.new(0, 0, 0)
	part.BorderSizePixel = 0
	part.Parent = scope
	return part
end

edge(UDim2.new(0.28, 0, 1, 0), UDim2.new(0, 0, 0, 0))
edge(UDim2.new(0.28, 0, 1, 0), UDim2.new(0.72, 0, 0, 0))

local ring = Instance.new("Frame")
ring.Size = UDim2.new(0.44, 0, 1, 0)
ring.Position = UDim2.new(0.28, 0, 0, 0)
ring.BackgroundTransparency = 1
ring.Parent = scope

local circle = Instance.new("Frame")
circle.Size = UDim2.new(1, 0, 1, 0)
circle.BackgroundTransparency = 1
circle.Parent = ring

local crossV = Instance.new("Frame")
crossV.Size = UDim2.new(0, 2, 1, 0)
crossV.Position = UDim2.new(0.5, -1, 0, 0)
crossV.BackgroundColor3 = Color3.new(0, 0, 0)
crossV.BorderSizePixel = 0
crossV.Parent = ring

local crossH = Instance.new("Frame")
crossH.Size = UDim2.new(1, 0, 0, 2)
crossH.Position = UDim2.new(0, 0, 0.5, -1)
crossH.BackgroundColor3 = Color3.new(0, 0, 0)
crossH.BorderSizePixel = 0
crossH.Parent = ring

local function heldGun()
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	if tool and tool:GetAttribute("BodyDamage") then
		return tool
	end
	return nil
end

local function setAim(on)
	local tool = heldGun()
	if on and not tool then
		return
	end

	aiming = on

	local scoped = tool and tool:GetAttribute("Scoped") == true
	local goal = NORMAL_FOV
	if on then
		goal = scoped and SCOPE_FOV or AIM_FOV
	end

	TweenService:Create(camera, TweenInfo.new(0.18), { FieldOfView = goal }):Play()
	scope.Visible = on and scoped or false
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		setAim(true)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		setAim(false)
	end
end)

-- drop out of aim if the gun goes away or you die
RunService.Heartbeat:Connect(function()
	if aiming and not heldGun() then
		setAim(false)
	end
end)

player.CharacterAdded:Connect(function()
	setAim(false)
end)
