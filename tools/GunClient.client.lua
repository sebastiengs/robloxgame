-- Generic gun client. Reads its stats from attributes on the Tool.
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
