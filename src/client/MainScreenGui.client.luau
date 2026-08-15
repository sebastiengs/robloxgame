-- Main screen: shop as long as you like, then join the round
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("ShopRemotes")
local buyRemote = remotes:WaitForChild("BuyGun")
local joinRemote = remotes:WaitForChild("JoinGame")

local GUNS = {
	{ name = "M4", price = 350 },
	{ name = "Thompson", price = 150 },
	{ name = "M16", price = 300 },
	{ name = "Shotgun", price = 400 },
	{ name = "AR-15", price = 500 },
	{ name = "Barrett", price = 800 },
}

local gui = Instance.new("ScreenGui")
gui.Name = "MainScreenGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local screen = Instance.new("Frame")
screen.Size = UDim2.new(1, 0, 1, 0)
screen.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
screen.BackgroundTransparency = 0.15
screen.Visible = false
screen.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.6, 0, 0.12, 0)
title.Position = UDim2.new(0.2, 0, 0.04, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Text = "ENEMIES"
title.Parent = screen

local cashLabel = Instance.new("TextLabel")
cashLabel.Size = UDim2.new(0.4, 0, 0.08, 0)
cashLabel.Position = UDim2.new(0.3, 0, 0.19, 0)
cashLabel.BackgroundTransparency = 1
cashLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
cashLabel.TextScaled = true
cashLabel.Font = Enum.Font.GothamBold
cashLabel.Text = "Money: 0"
cashLabel.Parent = screen

-- the gun list starts hidden behind the GUNS button
local shop = Instance.new("Frame")
shop.Size = UDim2.new(1, 0, 1, 0)
shop.BackgroundTransparency = 1
shop.Visible = false
shop.Parent = screen

local gunsButton = Instance.new("TextButton")
gunsButton.Size = UDim2.new(0.4, 0, 0.13, 0)
gunsButton.Position = UDim2.new(0.3, 0, 0.36, 0)
gunsButton.BackgroundColor3 = Color3.fromRGB(50, 120, 60)
gunsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
gunsButton.TextScaled = true
gunsButton.Font = Enum.Font.GothamBold
gunsButton.Text = "GUNS"
gunsButton.Parent = screen

local backButton = Instance.new("TextButton")
backButton.Size = UDim2.new(0.34, 0, 0.09, 0)
backButton.Position = UDim2.new(0.33, 0, 0.85, 0)
backButton.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
backButton.TextColor3 = Color3.fromRGB(255, 255, 255)
backButton.TextScaled = true
backButton.Font = Enum.Font.GothamBold
backButton.Text = "BACK"
backButton.Parent = shop

local buttons = {}

for index, gun in ipairs(GUNS) do
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0.34, 0, 0.085, 0)
	button.Position = UDim2.new(0.33, 0, 0.26 + (index - 1) * 0.095, 0)
	button.BackgroundColor3 = Color3.fromRGB(50, 120, 60)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.Text = gun.name
	button.Parent = shop

	button.Activated:Connect(function()
		buyRemote:FireServer(gun.name)
	end)

	buttons[gun.name] = button
end

local joinButton = Instance.new("TextButton")
joinButton.Size = UDim2.new(0.4, 0, 0.13, 0)
joinButton.Position = UDim2.new(0.3, 0, 0.72, 0)
joinButton.BackgroundColor3 = Color3.fromRGB(200, 60, 50)
joinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
joinButton.TextScaled = true
joinButton.Font = Enum.Font.GothamBold
joinButton.Text = "JOIN GAME"
joinButton.Parent = screen

joinButton.Activated:Connect(function()
	joinRemote:FireServer()
end)

-- swap between the front screen and the gun list
local function showShop(open)
	shop.Visible = open
	gunsButton.Visible = not open
	joinButton.Visible = not open
end

gunsButton.Activated:Connect(function()
	showShop(true)
end)

backButton.Activated:Connect(function()
	showShop(false)
end)

local function getCashValue()
	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash")
	return cash and cash.Value or 0
end

local function refresh()
	local inRound = player:GetAttribute("InRound") == true
	screen.Visible = not inRound
	if inRound then
		showShop(false) -- always come back to the front screen
	end
	cashLabel.Text = "Money: " .. getCashValue()

	for _, gun in ipairs(GUNS) do
		local button = buttons[gun.name]
		if player:GetAttribute("Owns_" .. gun.name) then
			button.Text = gun.name .. "  -  OWNED"
			button.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
		else
			button.Text = gun.name .. "  -  $" .. gun.price
			button.BackgroundColor3 = Color3.fromRGB(50, 120, 60)
		end
	end
end

player.AttributeChanged:Connect(refresh)

task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	local cash = leaderstats and leaderstats:WaitForChild("Cash", 10)
	if cash then
		cash.Changed:Connect(refresh)
	end
	refresh()
end)

refresh()
