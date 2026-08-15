-- Hit marker and kill message
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local hitRemote = ReplicatedStorage:WaitForChild("GunRemotes"):WaitForChild("HitConfirm")

local HIT_SOUND = "rbxassetid://122039660768000"

local gui = Instance.new("ScreenGui")
gui.Name = "HitMarkerGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- the marker is four short bars making an X in the middle of the screen
local marker = Instance.new("Frame")
marker.Size = UDim2.new(0, 40, 0, 40)
marker.Position = UDim2.new(0.5, -20, 0.5, -20)
marker.BackgroundTransparency = 1
marker.Visible = false
marker.Parent = gui

local bars = {}
local ANGLES = { 45, 135, 225, 315 }
for _, angle in ipairs(ANGLES) do
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 3, 0, 14)
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	bar.BorderSizePixel = 0
	bar.Rotation = angle
	local radians = math.rad(angle)
	bar.Position = UDim2.new(0.5, math.sin(radians) * 14, 0.5, -math.cos(radians) * 14)
	bar.Parent = marker
	table.insert(bars, bar)
end

local killLabel = Instance.new("TextLabel")
killLabel.Size = UDim2.new(0, 500, 0, 50)
killLabel.Position = UDim2.new(0.5, -250, 0.32, 0)
killLabel.BackgroundTransparency = 1
killLabel.TextScaled = true
killLabel.Font = Enum.Font.GothamBold
killLabel.TextStrokeTransparency = 0.4
killLabel.Text = ""
killLabel.TextTransparency = 1
killLabel.Parent = gui

local hitSound = Instance.new("Sound")
hitSound.SoundId = HIT_SOUND
hitSound.Volume = 0.7
hitSound.Parent = gui

local markerToken = 0

local function showMarker(color, size)
	markerToken += 1
	local myToken = markerToken

	for _, bar in ipairs(bars) do
		bar.BackgroundColor3 = color
		bar.Size = UDim2.new(0, 3, 0, size)
		bar.BackgroundTransparency = 0
	end
	marker.Visible = true

	hitSound.TimePosition = 0
	hitSound:Play()

	task.delay(0.12, function()
		if markerToken ~= myToken then
			return
		end
		for _, bar in ipairs(bars) do
			TweenService:Create(bar, TweenInfo.new(0.15), { BackgroundTransparency = 1 }):Play()
		end
		task.delay(0.16, function()
			if markerToken == myToken then
				marker.Visible = false
			end
		end)
	end)
end

local killToken = 0

local function showKill(text, color)
	killToken += 1
	local myToken = killToken

	killLabel.Text = text
	killLabel.TextColor3 = color
	killLabel.TextTransparency = 0

	task.delay(1.6, function()
		if killToken ~= myToken then
			return
		end
		TweenService:Create(killLabel, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
	end)
end

hitRemote.OnClientEvent:Connect(function(killed, headshot, victimName)
	if killed then
		showMarker(Color3.fromRGB(255, 70, 60), 20)
		showKill(headshot and ("HEADSHOT! You killed " .. victimName) or ("You killed " .. victimName),
			headshot and Color3.fromRGB(255, 200, 60) or Color3.fromRGB(255, 90, 80))
	elseif headshot then
		showMarker(Color3.fromRGB(255, 210, 70), 18)
	else
		showMarker(Color3.fromRGB(255, 255, 255), 14)
	end
end)
