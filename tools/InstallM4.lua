local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")

local clientSource = [==[-- M4 client: full auto shooting, recoil, ammo, reload
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local tool = script.Parent
local player = Players.LocalPlayer
local fireRemote = ReplicatedStorage:WaitForChild("GunRemotes"):WaitForChild("FireGun")

local MAG_SIZE = 32
local FIRE_RATE = 0.1
local RELOAD_TIME = 2.5
local RANGE = 500
local RECOIL_PER_SHOT = 0.5
local MAX_RECOIL = 7
local RECOIL_RECOVER = 4

local ammo = MAG_SIZE
local firing = false
local reloading = false
local equipped = false
local lastShot = 0
local recoil = 0

local function getCamera()
	return workspace.CurrentCamera
end

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
	local camera = getCamera()
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
		fireRemote:FireServer(result.Instance, result.Position)
	end

	-- recoil kicks the gun upward, player pulls back down
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

local serverSource = [==[-- Gun server: takes shot reports from clients and applies damage
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

	if hitPart.Name == "Head" then
		hitHumanoid:TakeDamage(HEAD_DAMAGE)
	else
		hitHumanoid:TakeDamage(BODY_DAMAGE)
	end
end)
]==]

local old = ServerScriptService:FindFirstChild("GunServer")
if old then old:Destroy() end
local serverScript = Instance.new("Script")
serverScript.Name = "GunServer"
serverScript.Source = serverSource
serverScript.Parent = ServerScriptService

local remotes = ReplicatedStorage:FindFirstChild("GunRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "GunRemotes"
	remotes.Parent = ReplicatedStorage
end
if not remotes:FindFirstChild("FireGun") then
	local ev = Instance.new("RemoteEvent")
	ev.Name = "FireGun"
	ev.Parent = remotes
end

local oldTool = StarterPack:FindFirstChild("M4")
if oldTool then oldTool:Destroy() end

local tool = Instance.new("Tool")
tool.Name = "M4"
tool.RequiresHandle = true
tool.CanBeDropped = false

local handle = Instance.new("Part")
handle.Name = "Handle"
handle.Size = Vector3.new(0.4, 0.5, 3)
handle.Color = Color3.fromRGB(40, 40, 45)
handle.Material = Enum.Material.Metal
handle.CanCollide = false
handle.Parent = tool

local clientScript = Instance.new("LocalScript")
clientScript.Name = "M4Client"
clientScript.Source = clientSource
clientScript.Parent = tool

tool.Parent = StarterPack

print("M4 installed: StarterPack.M4, ServerScriptService.GunServer")
