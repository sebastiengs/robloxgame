local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local playerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

local roundSource = [==[-- Round server: 10 minute timed rounds, most kills wins
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
local mode = ensureValue("StringValue", "Mode", "Solo")

-- the two teams used by team rounds
local Teams = game:GetService("Teams")
local function ensureTeam(name, color)
	local team = Teams:FindFirstChild(name)
	if not team then
		team = Instance.new("Team")
		team.Name = name
		team.AutoAssignable = false
		team.Parent = Teams
	end
	team.TeamColor = color
	return team
end

ensureTeam("Red", BrickColor.new("Bright red"))
ensureTeam("Blue", BrickColor.new("Bright blue"))

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

local function findSoloWinner()
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

local function findTeamWinner()
	local totals = { Red = 0, Blue = 0 }
	for _, player in ipairs(Players:GetPlayers()) do
		local team = player.Team
		local leaderstats = player:FindFirstChild("leaderstats")
		local kills = leaderstats and leaderstats:FindFirstChild("Kills")
		if team and kills and totals[team.Name] then
			totals[team.Name] += kills.Value
		end
	end

	if totals.Red == totals.Blue then
		return nil, totals
	end
	return (totals.Red > totals.Blue) and "Red" or "Blue", totals
end

task.spawn(function()
	while true do
		status.Value = "Intermission"
		winner.Value = ""

		-- rounds switch: teams, then everyone alone, then teams again
		mode.Value = (mode.Value == "Team") and "Solo" or "Team"

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

		if mode.Value == "Team" then
			local winningTeam, totals = findTeamWinner()
			if winningTeam then
				winner.Value = winningTeam .. " team wins! " .. totals.Red .. " - " .. totals.Blue
			else
				winner.Value = "It's a tie! " .. totals.Red .. " - " .. totals.Blue
			end
		else
			local best, bestKills = findSoloWinner()
			winner.Value = best and (best.Name .. " wins with " .. bestKills .. " kills!") or "Nobody wins!"
		end

		task.wait(5)
	end
end)
]==]
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
local BASES = {
	Red = Vector3.new(-90, 10, 0),
	Blue = Vector3.new(90, 10, 0),
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
		local base = player.Team and BASES[player.Team.Name]
		local spread = base and BASE_SPREAD or ARENA_SPREAD
		local center = base or ARENA_CENTER
		local offsetX = (math.random() - 0.5) * spread
		local offsetZ = (math.random() - 0.5) * spread
		root.CFrame = CFrame.new(center + Vector3.new(offsetX, 0, offsetZ))
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
local gunSource = [==[-- Gun server: takes shot reports from clients and applies damage
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

	if hitPart.Name == "Head" then
		hitHumanoid:TakeDamage(headDamage)
	else
		hitHumanoid:TakeDamage(bodyDamage)
	end
end)
]==]
local guiSource = [==[-- Shows the round clock and the winner message
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
	if status.Value == "Intermission" then
		clock.Text = "Next round: " .. format(timeLeft.Value)
	else
		clock.Text = format(timeLeft.Value)
	end
	message.Text = winner.Value
	modeLabel.Text = (mode.Value == "Team") and "TEAM ROUND" or "EVERYONE FOR THEMSELVES"
end

timeLeft.Changed:Connect(refresh)
status.Changed:Connect(refresh)
winner.Changed:Connect(refresh)
mode.Changed:Connect(refresh)
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

-- team bases at each end of the arena
local function makeBase(name, position, color)
	local old = workspace:FindFirstChild(name)
	if old then old:Destroy() end
	local pad = Instance.new("Part")
	pad.Name = name
	pad.Size = Vector3.new(30, 1, 30)
	pad.Position = position
	pad.Anchored = true
	pad.Color = color
	pad.Material = Enum.Material.SmoothPlastic
	pad.Parent = workspace
end

makeBase("RedBase", Vector3.new(-90, 8, 0), Color3.fromRGB(180, 50, 50))
makeBase("BlueBase", Vector3.new(90, 8, 0), Color3.fromRGB(50, 90, 190))

-- make sure there is ground between the bases
local floor = workspace:FindFirstChild("ArenaFloor")
if not floor then
	floor = Instance.new("Part")
	floor.Name = "ArenaFloor"
	floor.Parent = workspace
end
floor.Size = Vector3.new(260, 2, 120)
floor.Position = Vector3.new(0, 6, 0)
floor.Anchored = true
floor.Color = Color3.fromRGB(90, 95, 105)
floor.Material = Enum.Material.Concrete

replaceScript(ServerScriptService, "RoundServer", "Script", roundSource)
replaceScript(ServerScriptService, "LobbyServer", "Script", lobbySource)
replaceScript(ServerScriptService, "GunServer", "Script", gunSource)
replaceScript(playerScripts, "RoundGui", "LocalScript", guiSource)

print("Teams installed: rounds switch between Team and Solo, Red and Blue bases added")
