-- Lobby: players shop on the main screen as long as they like,
-- then press JOIN to drop into the round that is already running.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local STARTER_GUN = "AK-47"
local PRICES = {
	["M4"] = 350,
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
