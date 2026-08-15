-- Shows the round clock and the winner message
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local roundInfo = ReplicatedStorage:WaitForChild("RoundInfo")
local timeLeft = roundInfo:WaitForChild("TimeLeft")
local status = roundInfo:WaitForChild("Status")
local winner = roundInfo:WaitForChild("Winner")

local gui = Instance.new("ScreenGui")
gui.Name = "RoundGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local clock = Instance.new("TextLabel")
clock.Size = UDim2.new(0, 220, 0, 50)
clock.Position = UDim2.new(0.5, -110, 0, 0)
clock.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
clock.BackgroundTransparency = 0.4
clock.TextColor3 = Color3.fromRGB(255, 255, 255)
clock.TextScaled = true
clock.Font = Enum.Font.GothamBold
clock.Text = "10:00"
clock.Parent = gui

local message = Instance.new("TextLabel")
message.Size = UDim2.new(0, 600, 0, 60)
message.Position = UDim2.new(0.5, -300, 0.35, 0)
message.BackgroundTransparency = 1
message.TextColor3 = Color3.fromRGB(255, 220, 0)
message.TextScaled = true
message.Font = Enum.Font.GothamBold
message.Text = ""
message.Parent = gui

local mode = roundInfo:WaitForChild("Mode")

local modeLabel = Instance.new("TextLabel")
modeLabel.Size = UDim2.new(0, 220, 0, 24)
modeLabel.Position = UDim2.new(0.5, -110, 0, 52)
modeLabel.BackgroundTransparency = 1
modeLabel.TextColor3 = Color3.fromRGB(255, 220, 0)
modeLabel.TextScaled = true
modeLabel.Font = Enum.Font.GothamBold
modeLabel.Text = ""
modeLabel.Parent = gui

local function format(seconds)
	local minutes = math.floor(seconds / 60)
	return string.format("%d:%02d", minutes, seconds % 60)
end

local function refresh()
	-- the clock only shows while you are actually in the game
	gui.Enabled = player:GetAttribute("InRound") == true

	if status.Value == "Intermission" then
		clock.Text = "Next round: " .. format(timeLeft.Value)
	else
		clock.Text = format(timeLeft.Value)
	end
	message.Text = winner.Value
	local roundType = (mode.Value == "Team") and "TEAM ROUND" or "EVERYONE FOR THEMSELVES"
	local map = roundInfo:FindFirstChild("MapName")
	modeLabel.Text = map and (roundType .. "  -  " .. string.upper(map.Value)) or roundType
end

timeLeft.Changed:Connect(refresh)
status.Changed:Connect(refresh)
winner.Changed:Connect(refresh)
mode.Changed:Connect(refresh)
player.AttributeChanged:Connect(refresh)
refresh()
