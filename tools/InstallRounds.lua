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
end

local function awardKill(killer)
	local leaderstats = killer:FindFirstChild("leaderstats")
	local kills = leaderstats and leaderstats:FindFirstChild("Kills")
	if kills then
		kills.Value += 1
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
end

timeLeft.Changed:Connect(refresh)
status.Changed:Connect(refresh)
winner.Changed:Connect(refresh)
refresh()
]==]

local gunSource = [==[-- Gun server: takes shot reports from clients and applies damage
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local HEAD_DAMAGE = 100
local BODY_DAMAGE = 30
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

fireRemote.OnServerEvent:Connect(function(player, hitPart, hitPosition)
	if typeof(hitPart) ~= "Instance" or not hitPart:IsA("BasePart") then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
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
	game:GetService("Debris"):AddItem(tag, 10)

	if hitPart.Name == "Head" then
		hitHumanoid:TakeDamage(HEAD_DAMAGE)
	else
		hitHumanoid:TakeDamage(BODY_DAMAGE)
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

replaceScript(ServerScriptService, "RoundServer", "Script", roundSource)
replaceScript(ServerScriptService, "GunServer", "Script", gunSource)
replaceScript(playerScripts, "RoundGui", "LocalScript", guiSource)

print("Rounds installed: RoundServer, RoundGui, GunServer updated")
