local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")
local StarterPlayer = game:GetService("StarterPlayer")
local playerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

local gunClientSource = [==[-- Generic gun client. Reads its stats from attributes on the Tool.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local tool = script.Parent
local player = Players.LocalPlayer
local fireRemote = ReplicatedStorage:WaitForChild("GunRemotes"):WaitForChild("FireGun")

local MAG_SIZE = tool:GetAttribute("MagSize") or 32
local FIRE_RATE = tool:GetAttribute("FireRate") or 0.1
local RELOAD_TIME = tool:GetAttribute("ReloadTime") or 2.5
local RECOIL_PER_SHOT = tool:GetAttribute("RecoilPerShot") or 0.5
local RANGE = 500
local MAX_RECOIL = 7
local RECOIL_RECOVER = 4

local ammo = MAG_SIZE
local firing = false
local reloading = false
local equipped = false
local lastShot = 0
local recoil = 0

local function reload()
	if reloading or ammo == MAG_SIZE then
		return
	end
	reloading = true
	task.wait(RELOAD_TIME)
	ammo = MAG_SIZE
	reloading = false
end

local function shoot()
	local camera = workspace.CurrentCamera
	local character = player.Character
	if not character then
		return
	end

	ammo -= 1

	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector * RANGE

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local result = workspace:Raycast(origin, direction, params)
	if result then
		fireRemote:FireServer(result.Instance, result.Position, tool)
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
end)

tool.Unequipped:Connect(function()
	equipped = false
	firing = false
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
]==]
local gunServerSource = [==[-- Gun server: takes shot reports from clients and applies damage
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

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

fireRemote.OnServerEvent:Connect(function(player, hitPart, hitPosition, tool)
	if typeof(hitPart) ~= "Instance" or not hitPart:IsA("BasePart") then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
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

	if hitPart.Name == "Head" then
		hitHumanoid:TakeDamage(headDamage)
	else
		hitHumanoid:TakeDamage(bodyDamage)
	end
end)
]==]
local shopServerSource = [==[-- Shop: earn money for kills, buy guns between rounds
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local STARTER_GUN = "AK-47"
local PRICES = {
	["M4"] = 100,
	["AR-15"] = 500,
}

local templates = ReplicatedStorage:WaitForChild("GunTemplates")
local roundInfo = ReplicatedStorage:WaitForChild("RoundInfo")
local status = roundInfo:WaitForChild("Status")

local remotes = ReplicatedStorage:FindFirstChild("ShopRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "ShopRemotes"
	remotes.Parent = ReplicatedStorage
end

local buyRemote = remotes:FindFirstChild("BuyGun")
if not buyRemote then
	buyRemote = Instance.new("RemoteEvent")
	buyRemote.Name = "BuyGun"
	buyRemote.Parent = remotes
end

local function getCash(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	return leaderstats and leaderstats:FindFirstChild("Cash")
end

local function owns(player, gunName)
	return player:GetAttribute("Owns_" .. gunName) == true
end

local function giveLoadout(player, character)
	local backpack = player:WaitForChild("Backpack")
	for _, item in ipairs(backpack:GetChildren()) do
		if item:IsA("Tool") then
			item:Destroy()
		end
	end

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

buyRemote.OnServerEvent:Connect(function(player, gunName)
	local price = PRICES[gunName]
	if not price then
		return
	end
	if status.Value ~= "Intermission" then
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

	if player.Character then
		giveLoadout(player, player.Character)
	end
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		giveLoadout(player, character)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		giveLoadout(player, player.Character)
	end
end
]==]
local shopGuiSource = [==[-- Shop window, only usable between rounds
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local roundInfo = ReplicatedStorage:WaitForChild("RoundInfo")
local status = roundInfo:WaitForChild("Status")
local buyRemote = ReplicatedStorage:WaitForChild("ShopRemotes"):WaitForChild("BuyGun")

local GUNS = {
	{ name = "M4", price = 100 },
	{ name = "AR-15", price = 500 },
}

local gui = Instance.new("ScreenGui")
gui.Name = "ShopGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 60 + #GUNS * 60)
frame.Position = UDim2.new(0, 20, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
frame.BackgroundTransparency = 0.2
frame.Visible = false
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Text = "SHOP"
title.Parent = frame

local buttons = {}

for index, gun in ipairs(GUNS) do
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -20, 0, 50)
	button.Position = UDim2.new(0, 10, 0, 50 + (index - 1) * 60)
	button.BackgroundColor3 = Color3.fromRGB(50, 120, 60)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.Text = gun.name .. " - $" .. gun.price
	button.Parent = frame

	button.Activated:Connect(function()
		buyRemote:FireServer(gun.name)
	end)

	buttons[gun.name] = button
end

local function refresh()
	frame.Visible = status.Value == "Intermission"

	for _, gun in ipairs(GUNS) do
		local button = buttons[gun.name]
		if player:GetAttribute("Owns_" .. gun.name) then
			button.Text = gun.name .. " - OWNED"
			button.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
		else
			button.Text = gun.name .. " - $" .. gun.price
			button.BackgroundColor3 = Color3.fromRGB(50, 120, 60)
		end
	end
end

status.Changed:Connect(refresh)
player.AttributeChanged:Connect(refresh)
refresh()
]==]
local roundServerSource = [==[-- Round server: 10 minute timed rounds, most kills wins
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ROUND_SECONDS = 600
local INTERMISSION_SECONDS = 10
local RESPAWN_SECONDS = 5

Players.RespawnTime = RESPAWN_SECONDS

local roundInfo = ReplicatedStorage:FindFirstChild("RoundInfo")
if not roundInfo then
	roundInfo = Instance.new("Folder")
	roundInfo.Name = "RoundInfo"
	roundInfo.Parent = ReplicatedStorage
end

local function ensureValue(className, name, default)
	local value = roundInfo:FindFirstChild(name)
	if not value then
		value = Instance.new(className)
		value.Name = name
		value.Parent = roundInfo
	end
	value.Value = default
	return value
end

local timeLeft = ensureValue("IntValue", "TimeLeft", ROUND_SECONDS)
local status = ensureValue("StringValue", "Status", "Starting")
local winner = ensureValue("StringValue", "Winner", "")

local function setupPlayer(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local kills = leaderstats:FindFirstChild("Kills")
	if not kills then
		kills = Instance.new("IntValue")
		kills.Name = "Kills"
		kills.Parent = leaderstats
	end
	kills.Value = 0

	-- money is saved between rounds, so it is not reset here
	if not leaderstats:FindFirstChild("Cash") then
		local cash = Instance.new("IntValue")
		cash.Name = "Cash"
		cash.Value = 0
		cash.Parent = leaderstats
	end
end

local CASH_PER_KILL = 10

local function awardKill(killer)
	local leaderstats = killer:FindFirstChild("leaderstats")
	local kills = leaderstats and leaderstats:FindFirstChild("Kills")
	if kills then
		kills.Value += 1
	end
	local cash = leaderstats and leaderstats:FindFirstChild("Cash")
	if cash then
		cash.Value += CASH_PER_KILL
	end
end

local function watchCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then
		return
	end

	humanoid.Died:Connect(function()
		local creator = humanoid:FindFirstChild("creator")
		local killer = creator and creator.Value
		if killer and killer ~= player and killer:IsA("Player") then
			awardKill(killer)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	setupPlayer(player)
	player.CharacterAdded:Connect(function(character)
		watchCharacter(player, character)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
	if player.Character then
		watchCharacter(player, player.Character)
	end
end

local function findWinner()
	local best, bestKills = nil, -1
	for _, player in ipairs(Players:GetPlayers()) do
		local leaderstats = player:FindFirstChild("leaderstats")
		local kills = leaderstats and leaderstats:FindFirstChild("Kills")
		if kills and kills.Value > bestKills then
			best, bestKills = player, kills.Value
		end
	end
	return best, bestKills
end

task.spawn(function()
	while true do
		status.Value = "Intermission"
		winner.Value = ""
		for seconds = INTERMISSION_SECONDS, 1, -1 do
			timeLeft.Value = seconds
			task.wait(1)
		end

		status.Value = "Round"
		for _, player in ipairs(Players:GetPlayers()) do
			setupPlayer(player)
		end

		for seconds = ROUND_SECONDS, 1, -1 do
			timeLeft.Value = seconds
			task.wait(1)
		end

		status.Value = "Over"
		local best, bestKills = findWinner()
		winner.Value = best and (best.Name .. " wins with " .. bestKills .. " kills!") or "Nobody wins!"
		task.wait(5)
	end
end)
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

-- gun templates live in ReplicatedStorage and get handed out on spawn
local templates = ReplicatedStorage:FindFirstChild("GunTemplates")
if templates then templates:Destroy() end
templates = Instance.new("Folder")
templates.Name = "GunTemplates"
templates.Parent = ReplicatedStorage

local GUNS = {
	{name = "AK-47", body = 25, fireRate = 0.10, mag = 30, reload = 2.5, recoil = 0.55, color = Color3.fromRGB(120, 80, 40)},
	{name = "M4", body = 30, fireRate = 0.10, mag = 32, reload = 2.5, recoil = 0.50, color = Color3.fromRGB(40, 40, 45)},
	{name = "AR-15", body = 36, fireRate = 0.09, mag = 30, reload = 2.3, recoil = 0.42, color = Color3.fromRGB(70, 90, 110)},
}

for _, gun in ipairs(GUNS) do
	local tool = Instance.new("Tool")
	tool.Name = gun.name
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool:SetAttribute("BodyDamage", gun.body)
	tool:SetAttribute("HeadDamage", 100)
	tool:SetAttribute("FireRate", gun.fireRate)
	tool:SetAttribute("MagSize", gun.mag)
	tool:SetAttribute("ReloadTime", gun.reload)
	tool:SetAttribute("RecoilPerShot", gun.recoil)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 0.5, 3)
	handle.Color = gun.color
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Parent = tool

	replaceScript(tool, "GunClient", "LocalScript", gunClientSource)
	tool.Parent = templates
end

-- guns are handed out by the shop now, so clear the starter pack
for _, item in ipairs(StarterPack:GetChildren()) do
	if item:IsA("Tool") then item:Destroy() end
end

replaceScript(ServerScriptService, "GunServer", "Script", gunServerSource)
replaceScript(ServerScriptService, "ShopServer", "Script", shopServerSource)
replaceScript(ServerScriptService, "RoundServer", "Script", roundServerSource)
replaceScript(playerScripts, "ShopGui", "LocalScript", shopGuiSource)

print("Shop installed: AK-47 starter, M4 $100, AR-15 $500")
