-- Round server: 10 minute timed rounds, most kills wins
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
local mapName = ensureValue("StringValue", "MapName", "Warehouse")

-- the two maps sit in different places in the world, so both can exist at once
-- each map says where solo players drop in and where the two team bases are,
-- so nobody spawns on a roof or inside a building
local MAPS = {
	{
		name = "Warehouse",
		origin = Vector3.new(0, 0, 0),
		spawnCenter = Vector3.new(0, 25, 0),
		spawnSpread = Vector3.new(420, 0, 200),
		redBase = Vector3.new(-240, 12, 0),
		blueBase = Vector3.new(240, 12, 0),
	},
	{
		name = "Airport",
		origin = Vector3.new(2000, 0, 0),
		spawnCenter = Vector3.new(0, 45, -75),
		spawnSpread = Vector3.new(400, 0, 170),
		redBase = Vector3.new(-230, 12, -60),
		blueBase = Vector3.new(230, 12, -60),
	},
	{
		name = "Desert",
		origin = Vector3.new(4000, 0, 0),
		spawnCenter = Vector3.new(0, 55, 0),
		spawnSpread = Vector3.new(500, 0, 380),
		-- the desert streets sit at 16, so spawns start a little higher here
		redBase = Vector3.new(-255, 21, 175),
		blueBase = Vector3.new(255, 21, -175),
	},
}

local function ensureVector(name, default)
	local value = roundInfo:FindFirstChild(name)
	if not value then
		value = Instance.new("Vector3Value")
		value.Name = name
		value.Parent = roundInfo
	end
	value.Value = default
	return value
end

local mapOrigin = ensureVector("MapOrigin", MAPS[1].origin)
local spawnCenter = ensureVector("SpawnCenter", MAPS[1].spawnCenter)
local spawnSpread = ensureVector("SpawnSpread", MAPS[1].spawnSpread)
local redBase = ensureVector("RedBase", MAPS[1].redBase)
local blueBase = ensureVector("BlueBase", MAPS[1].blueBase)

local lastMapIndex = 1

local function pickMap()
	-- never the same map twice in a row
	local index = lastMapIndex
	while index == lastMapIndex do
		index = math.random(1, #MAPS)
	end
	lastMapIndex = index

	local picked = MAPS[index]
	mapName.Value = picked.name
	mapOrigin.Value = picked.origin
	spawnCenter.Value = picked.spawnCenter
	spawnSpread.Value = picked.spawnSpread
	redBase.Value = picked.redBase
	blueBase.Value = picked.blueBase
end

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
		pickMap()

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
