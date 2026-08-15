-- Third map: a small desert town with rocks and cars.
-- Sits 4000 studs away so all three maps can exist at once.
-- Run from the Studio command bar in edit mode.

local ORIGIN = Vector3.new(4000, 0, 0)
local GROUND_TOP = 7

local old = workspace:FindFirstChild("Map_Desert")
if old then
	old:Destroy()
end

local map = Instance.new("Folder")
map.Name = "Map_Desert"
map.Parent = workspace

local SAND = Color3.fromRGB(206, 178, 126)
local ADOBE = Color3.fromRGB(198, 165, 122)
local ADOBE_DARK = Color3.fromRGB(168, 136, 96)
local ROOF = Color3.fromRGB(140, 110, 78)
local ROCK = Color3.fromRGB(135, 122, 105)

local function block(name, size, position, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = ORIGIN + position
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.Concrete
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent or map
	return part
end

local function onGround(name, size, x, z, color, material, parent)
	return block(name, size, Vector3.new(x, GROUND_TOP + size.Y / 2, z), color, material, parent)
end

----------------------------------------------------------------
-- desert floor and a dirt road down the middle
----------------------------------------------------------------
block("Ground", Vector3.new(520, 2, 360), Vector3.new(0, GROUND_TOP - 1, 0), SAND, Enum.Material.Sand)
onGround("Road", Vector3.new(460, 0.2, 40), 0, 0, Color3.fromRGB(170, 145, 108), Enum.Material.Ground)

----------------------------------------------------------------
-- town buildings, hollow so you can fight inside
----------------------------------------------------------------
local town = Instance.new("Folder")
town.Name = "Town"
town.Parent = map

-- doorSide: "front" (-z wall), "back" (+z wall), "left" (-x), "right" (+x)
local function building(x, z, width, depth, height, doorSide, color)
	local model = Instance.new("Model")
	model.Name = "Building"
	model.Parent = town

	local T = 2 -- wall thickness
	local DOOR = 10 -- how wide the doorway is
	local wallColor = color or ADOBE

	onGround("Floor", Vector3.new(width, 0.4, depth), x, z, ADOBE_DARK, Enum.Material.Slate, model)

	-- a wall that runs along X, with an optional doorway in the middle
	local function wallX(zOffset, hasDoor)
		if hasDoor then
			local side = (width - DOOR) / 2
			onGround("Wall", Vector3.new(side, height, T), x - (DOOR + side) / 2, z + zOffset, wallColor, Enum.Material.Sandstone, model)
			onGround("Wall", Vector3.new(side, height, T), x + (DOOR + side) / 2, z + zOffset, wallColor, Enum.Material.Sandstone, model)
			block("WallTop", Vector3.new(DOOR, height - 9, T), Vector3.new(x, GROUND_TOP + height - (height - 9) / 2, z + zOffset), wallColor, Enum.Material.Sandstone, model)
		else
			onGround("Wall", Vector3.new(width, height, T), x, z + zOffset, wallColor, Enum.Material.Sandstone, model)
		end
	end

	-- a wall that runs along Z
	local function wallZ(xOffset, hasDoor)
		if hasDoor then
			local side = (depth - DOOR) / 2
			onGround("Wall", Vector3.new(T, height, side), x + xOffset, z - (DOOR + side) / 2, wallColor, Enum.Material.Sandstone, model)
			onGround("Wall", Vector3.new(T, height, side), x + xOffset, z + (DOOR + side) / 2, wallColor, Enum.Material.Sandstone, model)
			block("WallTop", Vector3.new(T, height - 9, DOOR), Vector3.new(x + xOffset, GROUND_TOP + height - (height - 9) / 2, z), wallColor, Enum.Material.Sandstone, model)
		else
			onGround("Wall", Vector3.new(T, height, depth), x + xOffset, z, wallColor, Enum.Material.Sandstone, model)
		end
	end

	wallX(-depth / 2, doorSide == "front")
	wallX(depth / 2, doorSide == "back")
	wallZ(-width / 2, doorSide == "left")
	wallZ(width / 2, doorSide == "right")

	-- window gaps on the two walls without the door
	local function window(px, pz, sizeVec)
		block("Window", sizeVec, Vector3.new(px, GROUND_TOP + height - 4, pz), wallColor, Enum.Material.Sandstone, model)
	end
	if doorSide ~= "front" then
		window(x - width / 4, z - depth / 2, Vector3.new(width / 4, 3, T))
		window(x + width / 4, z - depth / 2, Vector3.new(width / 4, 3, T))
	end

	-- flat roof with a lip, so it reads like a desert town
	block("Roof", Vector3.new(width + 3, 1.2, depth + 3), Vector3.new(x, GROUND_TOP + height, z), ROOF, Enum.Material.Slate, model)
	block("RoofLip", Vector3.new(width + 4, 2, 1.2), Vector3.new(x, GROUND_TOP + height + 1, z - depth / 2 - 1.5), ROOF, Enum.Material.Slate, model)
	block("RoofLip", Vector3.new(width + 4, 2, 1.2), Vector3.new(x, GROUND_TOP + height + 1, z + depth / 2 + 1.5), ROOF, Enum.Material.Slate, model)

	-- a crate or two inside for cover
	onGround("Crate", Vector3.new(7, 7, 7), x - width / 4, z + depth / 4, Color3.fromRGB(150, 110, 60), Enum.Material.WoodPlanks, model)
	onGround("Crate", Vector3.new(6, 5, 6), x + width / 3, z - depth / 3, Color3.fromRGB(150, 110, 60), Enum.Material.WoodPlanks, model)

	return model
end

-- north side of the road
building(-170, -60, 60, 50, 22, "back", ADOBE)
building(-80, -70, 50, 44, 26, "back", Color3.fromRGB(210, 180, 140))
building(10, -62, 56, 46, 22, "back", ADOBE)
building(110, -72, 62, 52, 28, "back", Color3.fromRGB(186, 152, 112))
building(200, -60, 48, 44, 22, "back", ADOBE)

-- south side of the road
building(-140, 62, 54, 46, 24, "front", Color3.fromRGB(210, 180, 140))
building(-40, 70, 60, 50, 22, "front", ADOBE)
building(60, 64, 50, 44, 26, "front", Color3.fromRGB(186, 152, 112))
building(160, 72, 58, 48, 24, "front", ADOBE)

----------------------------------------------------------------
-- rocks
----------------------------------------------------------------
local rocks = Instance.new("Folder")
rocks.Name = "Rocks"
rocks.Parent = map

local function rock(x, z, size)
	local r = onGround("Rock", Vector3.new(size, size * 0.8, size * 0.9), x, z, ROCK, Enum.Material.Rock, rocks)
	r.Shape = Enum.PartType.Ball
	r.Size = Vector3.new(size, size * 0.8, size * 0.9)
	r.Position = ORIGIN + Vector3.new(x, GROUND_TOP + size * 0.3, z)
	return r
end

rock(-230, -140, 22)
rock(-200, 130, 18)
rock(-120, -145, 26)
rock(-60, 140, 16)
rock(20, -150, 20)
rock(70, 135, 24)
rock(150, -140, 18)
rock(210, 145, 26)
rock(240, -100, 20)
rock(-245, 40, 24)
rock(0, 120, 14)
rock(120, -110, 16)

-- a couple of rock clusters as cover in the street
rock(-100, 0, 12)
rock(95, 8, 14)

----------------------------------------------------------------
-- border walls
----------------------------------------------------------------
local function border(size, position)
	local part = block("Border", size, position, Color3.fromRGB(90, 80, 65), Enum.Material.Sandstone)
	part.Transparency = 0.6
	return part
end

border(Vector3.new(520, 40, 2), Vector3.new(0, GROUND_TOP + 20, -180))
border(Vector3.new(520, 40, 2), Vector3.new(0, GROUND_TOP + 20, 180))
border(Vector3.new(2, 40, 360), Vector3.new(-260, GROUND_TOP + 20, 0))
border(Vector3.new(2, 40, 360), Vector3.new(260, GROUND_TOP + 20, 0))

print("Desert built at " .. tostring(ORIGIN) .. ": 9 buildings, rocks, road. Cars come next.")
