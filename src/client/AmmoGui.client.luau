-- Ammo counter, plus playing other players' gunshots
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "AmmoGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 200, 0, 60)
label.Position = UDim2.new(1, -230, 1, -100)
label.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
label.BackgroundTransparency = 0.35
label.BorderSizePixel = 0
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.Text = ""
label.Visible = false
label.Parent = gui

local function refresh()
	local gun = player:GetAttribute("GunName")
	local ammo = player:GetAttribute("Ammo")
	local magSize = player:GetAttribute("MagSize")
	local inRound = player:GetAttribute("InRound") == true

	if not gun or not ammo or not inRound then
		label.Visible = false
		return
	end

	label.Visible = true

	if player:GetAttribute("Reloading") then
		label.Text = "RELOADING"
		label.TextColor3 = Color3.fromRGB(255, 190, 60)
	else
		label.Text = ammo .. " / " .. (magSize or 0)
		label.TextColor3 = (ammo <= 5) and Color3.fromRGB(255, 90, 80) or Color3.fromRGB(255, 255, 255)
	end
end

player.AttributeChanged:Connect(refresh)
refresh()

-- gunshots from other players
local remotes = ReplicatedStorage:WaitForChild("GunRemotes")
local shotRemote = remotes:WaitForChild("ShotHeard")

shotRemote.OnClientEvent:Connect(function(handle)
	if not handle or not handle:IsA("BasePart") then
		return
	end

	-- show their muzzle flash too
	local muzzle = handle:FindFirstChild("Muzzle")
	if muzzle then
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
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://76727380063178"
	sound.Volume = 0.4
	sound.RollOffMaxDistance = 400
	sound.Parent = handle
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	task.delay(3, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end)
