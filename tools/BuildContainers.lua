-- Rebuilds the shipping containers with ribbed sides, doors and corner blocks.
-- Run from the Studio command bar in edit mode.

local GROUND_TOP = 7

local map = workspace:FindFirstChild("Map")
if not map then
	error("No Map folder — run BuildMap first")
end

local yard = map:FindFirstChild("Yard")
if not yard then
	yard = Instance.new("Folder")
	yard.Name = "Yard"
	yard.Parent = map
end

-- clear the old boxy containers
for _, child in ipairs(yard:GetChildren()) do
	if child.Name == "Container" then
		child:Destroy()
	end
end

local LENGTH = 32
local WIDTH = 9
local HEIGHT = 9
local RIB_STEP = 2.4

local COLORS = {
	Color3.fromRGB(150, 60, 50),
	Color3.fromRGB(55, 95, 140),
	Color3.fromRGB(60, 110, 75),
	Color3.fromRGB(170, 135, 55),
	Color3.fromRGB(110, 75, 130),
}

local function part(name, size, cframe, color, material, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Anchored = true
	p.Color = color
	p.Material = material or Enum.Material.CorrodedMetal
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- builds one container centred at `position`, running along its own X axis
local function buildContainer(position, turned, color)
	local model = Instance.new("Model")
	model.Name = "Container"
	model.Parent = yard

	local base = CFrame.new(position)
	if turned then
		base = base * CFrame.Angles(0, math.rad(90), 0)
	end

	local darker = Color3.new(color.R * 0.7, color.G * 0.7, color.B * 0.7)
	local corner = Color3.fromRGB(45, 45, 48)

	-- main shell
	part("Shell", Vector3.new(LENGTH, HEIGHT, WIDTH), base, color, Enum.Material.CorrodedMetal, model)

	-- roof cap, slightly lighter and a touch wider
	part(
		"Roof",
		Vector3.new(LENGTH + 0.3, 0.6, WIDTH + 0.3),
		base * CFrame.new(0, HEIGHT / 2, 0),
		Color3.new(math.min(color.R * 1.2, 1), math.min(color.G * 1.2, 1), math.min(color.B * 1.2, 1)),
		Enum.Material.CorrodedMetal,
		model
	)

	-- corrugated ribs down both long sides
	local ribCount = math.floor((LENGTH - 4) / RIB_STEP)
	local startX = -(ribCount - 1) * RIB_STEP / 2
	for i = 0, ribCount - 1 do
		local x = startX + i * RIB_STEP
		for _, side in ipairs({ -1, 1 }) do
			part(
				"Rib",
				Vector3.new(0.9, HEIGHT - 1.6, 0.35),
				base * CFrame.new(x, 0, side * (WIDTH / 2 + 0.15)),
				darker,
				Enum.Material.CorrodedMetal,
				model
			)
		end
	end

	-- rails along top and bottom of each side
	for _, side in ipairs({ -1, 1 }) do
		for _, y in ipairs({ -HEIGHT / 2 + 0.5, HEIGHT / 2 - 0.5 }) do
			part(
				"Rail",
				Vector3.new(LENGTH, 1, 0.5),
				base * CFrame.new(0, y, side * (WIDTH / 2 + 0.2)),
				darker,
				Enum.Material.Metal,
				model
			)
		end
	end

	-- doors on one end: two panels with lock bars and handles
	local doorX = LENGTH / 2 + 0.25
	for _, side in ipairs({ -1, 1 }) do
		part(
			"Door",
			Vector3.new(0.5, HEIGHT - 1, WIDTH / 2 - 0.6),
			base * CFrame.new(doorX, 0, side * (WIDTH / 4)),
			darker,
			Enum.Material.Metal,
			model
		)
	end

	for _, offset in ipairs({ -3, -1, 1, 3 }) do
		local bar = part(
			"LockBar",
			Vector3.new(HEIGHT - 2, 0.45, 0.45),
			base * CFrame.new(doorX + 0.4, 0, offset),
			Color3.fromRGB(70, 70, 75),
			Enum.Material.Metal,
			model
		)
		bar.Shape = Enum.PartType.Cylinder
		bar.CFrame = base * CFrame.new(doorX + 0.4, 0, offset) * CFrame.Angles(0, 0, math.rad(90))
	end

	-- plain back end
	part(
		"BackEnd",
		Vector3.new(0.5, HEIGHT - 1, WIDTH - 0.6),
		base * CFrame.new(-doorX, 0, 0),
		darker,
		Enum.Material.CorrodedMetal,
		model
	)

	-- corner castings
	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				part(
					"Corner",
					Vector3.new(2, 1.6, 1.6),
					base * CFrame.new(sx * (LENGTH / 2 - 0.6), sy * (HEIGHT / 2 - 0.6), sz * (WIDTH / 2 - 0.4)),
					corner,
					Enum.Material.Metal,
					model
				)
			end
		end
	end

	return model
end

local function place(x, z, turned, stack, colorIndex)
	local color = COLORS[((colorIndex - 1) % #COLORS) + 1]
	buildContainer(Vector3.new(x, GROUND_TOP + HEIGHT / 2, z), turned, color)
	if stack then
		local top = COLORS[(colorIndex % #COLORS) + 1]
		buildContainer(Vector3.new(x, GROUND_TOP + HEIGHT * 1.5 + 0.3, z), turned, top)
	end
end

local function buildYard(centerX, flip)
	local s = flip and -1 or 1
	place(centerX + s * 20, -45, false, false, 1)
	place(centerX + s * 5, -20, true, true, 2)
	place(centerX - s * 20, 0, false, false, 3)
	place(centerX + s * 15, 25, true, false, 4)
	place(centerX - s * 10, 48, false, true, 5)
	place(centerX + s * 35, 10, true, false, 3)
end

buildYard(-185, false)
buildYard(185, true)

print("Containers rebuilt with ribs, doors and corner blocks")
