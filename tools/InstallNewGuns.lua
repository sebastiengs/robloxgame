local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local playerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local gunClientSource = [==[-- Generic gun client. Reads its stats from attributes on the Tool.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local tool = script.Parent
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("GunRemotes")
local fireRemote = remotes:WaitForChild("FireGun")

local MAG_SIZE = tool:GetAttribute("MagSize") or 32
local FIRE_RATE = tool:GetAttribute("FireRate") or 0.1
local RELOAD_TIME = tool:GetAttribute("ReloadTime") or 2.5
local RECOIL_PER_SHOT = tool:GetAttribute("RecoilPerShot") or 0.5
local RANGE = 500
local MAX_RECOIL = 7
local RECOIL_RECOVER = 4

local SHOOT_SOUND = "rbxassetid://76727380063178"
local RELOAD_SOUND = "rbxassetid://137782748730401"

local ammo = MAG_SIZE
local firing = false
local reloading = false
local equipped = false
local lastShot = 0
local recoil = 0

-- the ammo counter reads these
local function publish()
	player:SetAttribute("Ammo", ammo)
	player:SetAttribute("MagSize", MAG_SIZE)
	player:SetAttribute("Reloading", reloading)
	player:SetAttribute("GunName", equipped and tool.Name or nil)
end

local function makeSound(id, volume)
	local handle = tool:FindFirstChild("Handle")
	if not handle then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = volume
	sound.RollOffMaxDistance = 400
	sound.Parent = handle
	return sound
end

-- the template we clone from; it never plays on its own
local shootSound = makeSound(SHOOT_SOUND, 0.4)

-- muzzle flash at the end of the barrel
local function flash()
	local handle = tool:FindFirstChild("Handle")
	local muzzle = handle and handle:FindFirstChild("Muzzle")
	if not muzzle then
		return
	end

	local burst = Instance.new("Part")
	burst.Name = "MuzzleFlash"
	burst.Shape = Enum.PartType.Ball
	burst.Size = Vector3.new(0.9, 0.9, 0.9)
	burst.Color = Color3.fromRGB(255, 210, 120)
	burst.Material = Enum.Material.Neon
	burst.Anchored = true
	burst.CanCollide = false
	burst.CanQuery = false
	burst.CFrame = CFrame.new(muzzle.WorldPosition)
	burst.Parent = workspace

	local light = Instance.new("PointLight")
	light.Brightness = 6
	light.Range = 18
	light.Color = Color3.fromRGB(255, 200, 110)
	light.Parent = burst

	game:GetService("Debris"):AddItem(burst, 0.05)
end
local reloadSound = makeSound(RELOAD_SOUND, 0.6)

local function reload()
	if reloading or ammo == MAG_SIZE then
		return
	end
	reloading = true
	publish()
	if reloadSound then
		reloadSound:Play()
	end
	task.wait(RELOAD_TIME)
	ammo = MAG_SIZE
	reloading = false
	publish()
end

local function shoot()
	local camera = workspace.CurrentCamera
	local character = player.Character
	if not character then
		return
	end

	ammo -= 1
	publish()

	flash()

	-- each shot gets its own copy, so they overlap and ring out
	-- instead of cutting each other off
	if shootSound then
		local shot = shootSound:Clone()
		shot.Parent = shootSound.Parent
		shot:Play()
		game:GetService("Debris"):AddItem(shot, shot.TimeLength + 0.5)
	end

	local origin = camera.CFrame.Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	-- shotguns throw a handful of pellets, everything else fires one bullet
	local pellets = tool:GetAttribute("Pellets") or 1
	local spread = tool:GetAttribute("Spread") or 0

	for i = 1, pellets do
		local aim = camera.CFrame.LookVector
		if spread > 0 then
			aim = (camera.CFrame * CFrame.Angles(
				math.rad((math.random() - 0.5) * spread),
				math.rad((math.random() - 0.5) * spread),
				0
			)).LookVector
		end

		local result = workspace:Raycast(origin, aim * RANGE, params)
		-- tell the server every shot, so other players hear it even when we miss
		fireRemote:FireServer(result and result.Instance or nil, result and result.Position or nil, tool)
	end

	recoil = math.min(recoil + RECOIL_PER_SHOT, MAX_RECOIL)
	camera.CFrame = camera.CFrame * CFrame.Angles(math.rad(RECOIL_PER_SHOT), 0, 0)
end

RunService.RenderStepped:Connect(function(dt)
	if firing and equipped and not reloading and ammo > 0 then
		local now = os.clock()
		if now - lastShot >= FIRE_RATE then
			lastShot = now
			shoot()
		end
	end

	if not firing and recoil > 0 then
		recoil = math.max(recoil - RECOIL_RECOVER * dt, 0)
	end

	if firing and ammo <= 0 and not reloading then
		task.spawn(reload)
	end
end)

tool.Equipped:Connect(function()
	equipped = true
	publish()
end)

tool.Unequipped:Connect(function()
	equipped = false
	firing = false
	publish()
end)

tool.Activated:Connect(function()
	firing = true
end)

tool.Deactivated:Connect(function()
	firing = false
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not equipped then
		return
	end
	if input.KeyCode == Enum.KeyCode.R then
		task.spawn(reload)
	end
end)

publish()
]==]
local gunServerSource = [==[-- Gun server: takes shot reports from clients and applies damage
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local DEFAULT_HEAD_DAMAGE = 100
local DEFAULT_BODY_DAMAGE = 30
local MAX_RANGE = 600

local remotes = ReplicatedStorage:FindFirstChild("GunRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "GunRemotes"
	remotes.Parent = ReplicatedStorage
end

local fireRemote = remotes:FindFirstChild("FireGun")
if not fireRemote then
	fireRemote = Instance.new("RemoteEvent")
	fireRemote.Name = "FireGun"
	fireRemote.Parent = remotes
end

local shotRemote = remotes:FindFirstChild("ShotHeard")
if not shotRemote then
	shotRemote = Instance.new("RemoteEvent")
	shotRemote.Name = "ShotHeard"
	shotRemote.Parent = remotes
end

-- tells the shooter their bullet landed
local hitRemote = remotes:FindFirstChild("HitConfirm")
if not hitRemote then
	hitRemote = Instance.new("RemoteEvent")
	hitRemote.Name = "HitConfirm"
	hitRemote.Parent = remotes
end

fireRemote.OnServerEvent:Connect(function(player, hitPart, hitPosition, tool)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	-- let everyone else hear the shot, hit or miss
	if typeof(tool) == "Instance" and tool:IsA("Tool") and tool.Parent == character then
		local handle = tool:FindFirstChild("Handle")
		if handle then
			for _, other in ipairs(Players:GetPlayers()) do
				if other ~= player then
					shotRemote:FireClient(other, handle)
				end
			end
		end
	end

	if typeof(hitPart) ~= "Instance" or not hitPart:IsA("BasePart") then
		return
	end

	-- the gun must really belong to this player
	local headDamage, bodyDamage = DEFAULT_HEAD_DAMAGE, DEFAULT_BODY_DAMAGE
	if typeof(tool) == "Instance" and tool:IsA("Tool") then
		local owner = tool.Parent
		if owner ~= character and owner ~= player:FindFirstChild("Backpack") then
			return
		end
		headDamage = tool:GetAttribute("HeadDamage") or headDamage
		bodyDamage = tool:GetAttribute("BodyDamage") or bodyDamage
	end

	if (root.Position - hitPart.Position).Magnitude > MAX_RANGE then
		return
	end

	local hitHumanoid = hitPart.Parent and hitPart.Parent:FindFirstChildOfClass("Humanoid")
	if not hitHumanoid or hitHumanoid.Health <= 0 then
		return
	end

	if hitPart.Parent == character then
		return
	end

	-- no shooting your own team in team rounds
	local victim = Players:GetPlayerFromCharacter(hitPart.Parent)
	if victim and victim.Team and player.Team and victim.Team == player.Team then
		return
	end

	-- tag the victim so the round script knows who gets the kill
	local oldTag = hitHumanoid:FindFirstChild("creator")
	if oldTag then
		oldTag:Destroy()
	end
	local tag = Instance.new("ObjectValue")
	tag.Name = "creator"
	tag.Value = player
	tag.Parent = hitHumanoid
	Debris:AddItem(tag, 10)

	local headshot = hitPart.Name == "Head"
	local damage = headshot and headDamage or bodyDamage

	-- guns like the Thompson and the shotgun get weaker far away
	if typeof(tool) == "Instance" then
		local rangeFull = tool:GetAttribute("RangeFull")
		local rangeMax = tool:GetAttribute("RangeMax")
		if rangeFull and rangeMax and rangeMax > rangeFull then
			local distance = (root.Position - hitPart.Position).Magnitude
			if distance > rangeFull then
				local fade = math.clamp((distance - rangeFull) / (rangeMax - rangeFull), 0, 1)
				damage = damage * (1 - fade * 0.65)
			end
		end
	end

	hitHumanoid:TakeDamage(damage)

	local killed = hitHumanoid.Health <= 0
	local victimName = victim and victim.Name or "someone"
	hitRemote:FireClient(player, killed, headshot, victimName)
end)
]==]
local lobbySource = [==[-- Lobby: players shop on the main screen as long as they like,
-- then press JOIN to drop into the round that is already running.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local STARTER_GUN = "AK-47"
local PRICES = {
	["M4"] = 100,
	["Thompson"] = 150,
	["M16"] = 300,
	["Shotgun"] = 400,
	["AR-15"] = 500,
	["Barrett"] = 800,
}

local LOBBY_POSITION = Vector3.new(0, 200, 0)
local ARENA_CENTER = Vector3.new(0, 45, 0)
local ARENA_SPREAD = 200
local BASES = {
	Red = Vector3.new(-160, 12, 0),
	Blue = Vector3.new(160, 12, 0),
}
local BASE_SPREAD = 16

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

local Teams = game:GetService("Teams")
local mode = roundInfo:WaitForChild("Mode")

local function smallerTeam()
	local counts = { Red = 0, Blue = 0 }
	for _, other in ipairs(Players:GetPlayers()) do
		if other.Team and counts[other.Team.Name] then
			counts[other.Team.Name] += 1
		end
	end
	if counts.Red <= counts.Blue then
		return Teams:FindFirstChild("Red")
	end
	return Teams:FindFirstChild("Blue")
end

local function placeCharacter(player, character)
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if not root then
		return
	end

	if player:GetAttribute("InRound") then
		-- the round script tells us where this map's spawns and bases are
		local function value(name, fallback)
			local v = roundInfo:FindFirstChild(name)
			return v and v.Value or fallback
		end

		local origin = value("MapOrigin", Vector3.zero)
		local center, spreadX, spreadZ

		if player.Team and player.Team.Name == "Red" then
			center, spreadX, spreadZ = value("RedBase", BASES.Red), BASE_SPREAD, BASE_SPREAD
		elseif player.Team and player.Team.Name == "Blue" then
			center, spreadX, spreadZ = value("BlueBase", BASES.Blue), BASE_SPREAD, BASE_SPREAD
		else
			center = value("SpawnCenter", ARENA_CENTER)
			local spread = value("SpawnSpread", Vector3.new(ARENA_SPREAD, 0, ARENA_SPREAD))
			spreadX, spreadZ = spread.X, spread.Z
		end

		-- try a few spots and skip any that would drop you onto a roof
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { character }

		local spot
		for _ = 1, 12 do
			local offsetX = (math.random() - 0.5) * spreadX
			local offsetZ = (math.random() - 0.5) * spreadZ
			local candidate = origin + center + Vector3.new(offsetX, 0, offsetZ)
			-- start the check below roof height, so spawning inside a building works
			local hit = workspace:Raycast(candidate * Vector3.new(1, 0, 1) + Vector3.new(0, origin.Y + 26, 0), Vector3.new(0, -60, 0), params)
			if hit and hit.Position.Y < origin.Y + 30 then
				spot = Vector3.new(candidate.X, hit.Position.Y + 4, candidate.Z)
				break
			end
		end

		root.CFrame = CFrame.new(spot or (origin + center))
		giveGuns(player)
	else
		root.CFrame = CFrame.new(LOBBY_POSITION + Vector3.new(0, 5, 0))
		clearTools(player)
	end
end

local function sendToLobby(player)
	player:SetAttribute("InRound", false)
	player.Team = nil
	player.Neutral = true
	player:LoadCharacter()
end

joinRemote.OnServerEvent:Connect(function(player)
	if player:GetAttribute("InRound") then
		return
	end

	-- team rounds put you on the smaller team and spawn you at its base
	if mode.Value == "Team" then
		local team = smallerTeam()
		if team then
			player.Team = team
			player.Neutral = false
		end
	else
		player.Team = nil
		player.Neutral = true
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
]==]
local function replaceScript(parent, name, className, source)
	local old = parent:FindFirstChild(name)
	if old then old:Destroy() end
	local s = Instance.new(className)
	s.Name = name
	s.Source = source
	s.Parent = parent
end
replaceScript(ServerScriptService, "GunServer", "Script", gunServerSource)
replaceScript(ServerScriptService, "LobbyServer", "Script", lobbySource)
replaceScript(playerScripts, "MainScreenGui", "LocalScript", mainSource)
for _, tool in ipairs(ReplicatedStorage.GunTemplates:GetChildren()) do
	replaceScript(tool, "GunClient", "LocalScript", gunClientSource)
end
print("Four new guns wired up")
