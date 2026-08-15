local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local playerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

local lobbySource = [==[-- Lobby: players shop on the main screen as long as they like,
-- then press JOIN to drop into the round that is already running.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local STARTER_GUN = "AK-47"
local PRICES = {
	["M4"] = 100,
	["AR-15"] = 500,
}

local LOBBY_POSITION = Vector3.new(0, 200, 0)
local ARENA_CENTER = Vector3.new(0, 10, 0)
local ARENA_SPREAD = 60

local templates = ReplicatedStorage:WaitForChild("GunTemplates")
local roundInfo = ReplicatedStorage:WaitForChild("RoundInfo")
local status = roundInfo:WaitForChild("Status")

local remotes = ReplicatedStorage:FindFirstChild("ShopRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "ShopRemotes"
	remotes.Parent = ReplicatedStorage
end

local function ensureRemote(name)
	local remote = remotes:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotes
	end
	return remote
end

local buyRemote = ensureRemote("BuyGun")
local joinRemote = ensureRemote("JoinGame")

local function getCash(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild("Cash")
end

local function owns(player, gunName)
	return player:GetAttribute("Owns_" .. gunName) == true
end

local function clearTools(player)
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") then
				item:Destroy()
			end
		end
	end
	local character = player.Character
	if character then
		for _, item in ipairs(character:GetChildren()) do
			if item:IsA("Tool") then
				item:Destroy()
			end
		end
	end
end

local function giveGuns(player)
	clearTools(player)
	local backpack = player:WaitForChild("Backpack")

	local starter = templates:FindFirstChild(STARTER_GUN)
	if starter then
		starter:Clone().Parent = backpack
	end

	for gunName in pairs(PRICES) do
		if owns(player, gunName) then
			local template = templates:FindFirstChild(gunName)
			if template then
				template:Clone().Parent = backpack
			end
		end
	end
end

local function placeCharacter(player, character)
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if not root then
		return
	end

	if player:GetAttribute("InRound") then
		local offsetX = (math.random() - 0.5) * ARENA_SPREAD
		local offsetZ = (math.random() - 0.5) * ARENA_SPREAD
		root.CFrame = CFrame.new(ARENA_CENTER + Vector3.new(offsetX, 0, offsetZ))
		giveGuns(player)
	else
		root.CFrame = CFrame.new(LOBBY_POSITION + Vector3.new(0, 5, 0))
		clearTools(player)
	end
end

local function sendToLobby(player)
	player:SetAttribute("InRound", false)
	player:LoadCharacter()
end

joinRemote.OnServerEvent:Connect(function(player)
	if player:GetAttribute("InRound") then
		return
	end
	player:SetAttribute("InRound", true)
	player:LoadCharacter()
end)

buyRemote.OnServerEvent:Connect(function(player, gunName)
	local price = PRICES[gunName]
	if not price then
		return
	end
	-- you can only shop from the main screen
	if player:GetAttribute("InRound") then
		return
	end
	if owns(player, gunName) then
		return
	end

	local cash = getCash(player)
	if not cash or cash.Value < price then
		return
	end

	cash.Value -= price
	player:SetAttribute("Owns_" .. gunName, true)
end)

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("InRound", false)
	player.CharacterAdded:Connect(function(character)
		placeCharacter(player, character)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player:GetAttribute("InRound") == nil then
		player:SetAttribute("InRound", false)
	end
	player.CharacterAdded:Connect(function(character)
		placeCharacter(player, character)
	end)
	if player.Character then
		placeCharacter(player, player.Character)
	end
end

-- when a round ends, everyone goes back to the main screen
status.Changed:Connect(function(newStatus)
	if newStatus == "Over" then
		for _, player in ipairs(Players:GetPlayers()) do
			if player:GetAttribute("InRound") then
				sendToLobby(player)
			end
		end
	end
end)
]==]
local mainSource = [==[-- Main screen: shop as long as you like, then join the round
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("ShopRemotes")
local buyRemote = remotes:WaitForChild("BuyGun")
local joinRemote = remotes:WaitForChild("JoinGame")

local GUNS = {
	{ name = "M4", price = 100 },
	{ name = "AR-15", price = 500 },
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

local buttons = {}

for index, gun in ipairs(GUNS) do
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0.4, 0, 0.1, 0)
	button.Position = UDim2.new(0.3, 0, 0.32 + (index - 1) * 0.13, 0)
	button.BackgroundColor3 = Color3.fromRGB(50, 120, 60)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.Text = gun.name
	button.Parent = screen

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

local function getCashValue()
	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash")
	return cash and cash.Value or 0
end

local function refresh()
	screen.Visible = player:GetAttribute("InRound") ~= true
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
]==]

local function replaceScript(parent, name, className, source)
	local old = parent:FindFirstChild(name)
	if old then old:Destroy() end
	local s = Instance.new(className)
	s.Name = name
	s.Source = source
	s.Parent = parent
	return s
end

-- lobby floor so players have somewhere to stand on the main screen
local oldFloor = workspace:FindFirstChild("LobbyFloor")
if oldFloor then oldFloor:Destroy() end
local floor = Instance.new("Part")
floor.Name = "LobbyFloor"
floor.Size = Vector3.new(80, 2, 80)
floor.Position = Vector3.new(0, 198, 0)
floor.Anchored = true
floor.Color = Color3.fromRGB(35, 38, 48)
floor.Material = Enum.Material.SmoothPlastic
floor.Parent = workspace

local oldShop = ServerScriptService:FindFirstChild("ShopServer")
if oldShop then oldShop:Destroy() end
local oldShopGui = playerScripts:FindFirstChild("ShopGui")
if oldShopGui then oldShopGui:Destroy() end

replaceScript(ServerScriptService, "LobbyServer", "Script", lobbySource)
replaceScript(playerScripts, "MainScreenGui", "LocalScript", mainSource)

print("Lobby installed: main screen with shop and JOIN GAME")
