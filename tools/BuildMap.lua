-- Builds the Enemies map: a warehouse in the middle, container yards at each end.
-- Run this from the Studio command bar in edit mode.

local Lighting = game:GetService("Lighting")

local GROUND_TOP = 7

local old = workspace:FindFirstChild("Map")
if old then
	old:Destroy()
end

local map = Instance.new("Folder")
map.Name = "Map"
map.Parent = workspace

-- older loose parts from earlier builds
for _, name in ipairs({ "ArenaFloor", "RedBase", "BlueBase", "Baseplate" }) do
	local part = workspace:FindFirstChild(name)
	if part then
		part:Destroy()
	end
end

local function block(name, size, position, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.Concrete
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent or map
	return part
end

-- sits a block on the ground by its height
local function onGround(name, size, x, z, color, material, parent)
	return block(name, size, Vector3.new(x, GROUND_TOP + size.Y / 2, z), color, material, parent)
end

----------------------------------------------------------------
-- ground
----------------------------------------------------------------
local ground = block(
	"Ground",
	Vector3.new(520, 2, 240),
	Vector3.new(0, GROUND_TOP - 1, 0),
	Color3.fromRGB(85, 88, 95),
	Enum.Material.Concrete
)
ground.TopSurface = Enum.SurfaceType.Smooth

----------------------------------------------------------------
-- warehouse shell: 160 long, 120 deep, walls 30 tall
----------------------------------------------------------------
local warehouse = Instance.new("Folder")
warehouse.Name = "Warehouse"
warehouse.Parent = map

local WALL_HEIGHT = 30
local WALL_THICK = 2
local WALL_COLOR = Color3.fromRGB(150, 150, 155)

-- warehouse floor
onGround("WarehouseFloor", Vector3.new(240, 1, 120), 0, 0, Color3.fromRGB(120, 120, 125), Enum.Material.Concrete, warehouse)

-- long side walls with a door gap in the middle of each
local function sideWall(z)
	onGround("SideWall", Vector3.new(105, WALL_HEIGHT, WALL_THICK), -67.5, z, WALL_COLOR, Enum.Material.Metal, warehouse)
	onGround("SideWall", Vector3.new(105, WALL_HEIGHT, WALL_THICK), 67.5, z, WALL_COLOR, Enum.Material.Metal, warehouse)
	-- header above the door gap
	block(
		"SideWallTop",
		Vector3.new(30, 12, WALL_THICK),
		Vector3.new(0, GROUND_TOP + WALL_HEIGHT - 6, z),
		WALL_COLOR,
		Enum.Material.Metal,
		warehouse
	)
end

sideWall(-60)
sideWall(60)

-- end walls with a big loading door gap
local function endWall(x)
	onGround("EndWall", Vector3.new(WALL_THICK, WALL_HEIGHT, 45), x, -37.5, WALL_COLOR, Enum.Material.Metal, warehouse)
	onGround("EndWall", Vector3.new(WALL_THICK, WALL_HEIGHT, 45), x, 37.5, WALL_COLOR, Enum.Material.Metal, warehouse)
	block(
		"EndWallTop",
		Vector3.new(WALL_THICK, 12, 30),
		Vector3.new(x, GROUND_TOP + WALL_HEIGHT - 6, 0),
		WALL_COLOR,
		Enum.Material.Metal,
		warehouse
	)
end

endWall(-120)
endWall(120)

-- roof panels with skylight gaps so it is not pitch dark inside
for i = -3, 3 do
	block(
		"RoofPanel",
		Vector3.new(28, 1, 120),
		Vector3.new(i * 34, GROUND_TOP + WALL_HEIGHT, 0),
		Color3.fromRGB(105, 108, 115),
		Enum.Material.Metal,
		warehouse
	)
end

----------------------------------------------------------------
-- things to hide behind
----------------------------------------------------------------
local function crate(x, z, size, parent)
	local part = onGround(
		"Crate",
		size,
		x,
		z,
		Color3.fromRGB(150, 110, 60),
		Enum.Material.WoodPlanks,
		parent or warehouse
	)
	return part
end

-- big freight crates inside
crate(-95, -30, Vector3.new(16, 14, 16))
crate(-95, 30, Vector3.new(16, 14, 16))
crate(-60, 0, Vector3.new(20, 10, 12))
crate(-30, -35, Vector3.new(14, 16, 14))
crate(-25, 35, Vector3.new(18, 12, 18))
crate(0, -45, Vector3.new(24, 8, 10))
crate(0, 45, Vector3.new(24, 8, 10))
crate(30, 0, Vector3.new(20, 12, 20))
crate(60, -30, Vector3.new(16, 14, 16))
crate(65, 30, Vector3.new(18, 10, 14))
crate(95, -10, Vector3.new(16, 14, 16))
crate(95, 40, Vector3.new(14, 16, 14))

-- shelves: a long top on two legs, low enough to shoot over
local function shelf(x, z, length)
	onGround("ShelfLeg", Vector3.new(3, 10, 8), x - length / 2 + 2, z, Color3.fromRGB(70, 75, 85), Enum.Material.Metal, warehouse)
	onGround("ShelfLeg", Vector3.new(3, 10, 8), x + length / 2 - 2, z, Color3.fromRGB(70, 75, 85), Enum.Material.Metal, warehouse)
	block(
		"ShelfTop",
		Vector3.new(length, 1.5, 10),
		Vector3.new(x, GROUND_TOP + 10, z),
		Color3.fromRGB(90, 95, 105),
		Enum.Material.Metal,
		warehouse
	)
end

shelf(-80, -50, 40)
shelf(-10, 50, 40)
shelf(45, -50, 40)
shelf(105, 50, 40)

----------------------------------------------------------------
-- cars, inside and outside
----------------------------------------------------------------
local function car(x, z, color, parent, turned)
	local model = Instance.new("Model")
	model.Name = "Car"
	model.Parent = parent or map

	local lengthAxis = turned and "Z" or "X"
	local bodySize = (lengthAxis == "X") and Vector3.new(16, 4, 7) or Vector3.new(7, 4, 16)
	local cabinSize = (lengthAxis == "X") and Vector3.new(8, 3.5, 6.5) or Vector3.new(6.5, 3.5, 8)

	block("Body", bodySize, Vector3.new(x, GROUND_TOP + 3, z), color, Enum.Material.Metal, model)
	block("Cabin", cabinSize, Vector3.new(x, GROUND_TOP + 6.5, z), color, Enum.Material.Metal, model)

	local wheelOffsets = (lengthAxis == "X")
			and { Vector3.new(-5, 0, -3.5), Vector3.new(5, 0, -3.5), Vector3.new(-5, 0, 3.5), Vector3.new(5, 0, 3.5) }
		or { Vector3.new(-3.5, 0, -5), Vector3.new(-3.5, 0, 5), Vector3.new(3.5, 0, -5), Vector3.new(3.5, 0, 5) }

	for _, offset in ipairs(wheelOffsets) do
		local wheel = block(
			"Wheel",
			Vector3.new(1.5, 3, 3),
			Vector3.new(x + offset.X, GROUND_TOP + 1.5, z + offset.Z),
			Color3.fromRGB(25, 25, 28),
			Enum.Material.Rubber,
			model
		)
		wheel.Shape = Enum.PartType.Cylinder
		wheel.CFrame = CFrame.new(wheel.Position) * CFrame.Angles(0, 0, math.rad(90))
		if lengthAxis == "Z" then
			wheel.CFrame = CFrame.new(wheel.Position) * CFrame.Angles(0, math.rad(90), math.rad(90))
		end
	end
end

-- inside
car(-70, -50, Color3.fromRGB(180, 60, 55), warehouse, false)
car(-5, 40, Color3.fromRGB(60, 90, 170), warehouse, true)
car(85, -40, Color3.fromRGB(230, 220, 200), warehouse, false)

----------------------------------------------------------------
-- container yards at each end
----------------------------------------------------------------
local yard = Instance.new("Folder")
yard.Name = "Yard"
yard.Parent = map

local CONTAINER_COLORS = {
	Color3.fromRGB(180, 70, 60),
	Color3.fromRGB(70, 120, 180),
	Color3.fromRGB(80, 150, 90),
	Color3.fromRGB(200, 160, 60),
	Color3.fromRGB(140, 90, 170),
}

local function container(x, z, turned, stack, colorIndex)
	local size = turned and Vector3.new(10, 10, 24) or Vector3.new(24, 10, 10)
	local color = CONTAINER_COLORS[((colorIndex - 1) % #CONTAINER_COLORS) + 1]
	onGround("Container", size, x, z, color, Enum.Material.CorrodedMetal, yard)
	if stack then
		local top = CONTAINER_COLORS[(colorIndex % #CONTAINER_COLORS) + 1]
		block("Container", size, Vector3.new(x, GROUND_TOP + 15, z), top, Enum.Material.CorrodedMetal, yard)
	end
end

local function buildYard(centerX, flip)
	local s = flip and -1 or 1
	container(centerX + s * 20, -45, false, false, 1)
	container(centerX + s * 5, -20, true, true, 2)
	container(centerX - s * 20, 0, false, false, 3)
	container(centerX + s * 15, 25, true, false, 4)
	container(centerX - s * 10, 48, false, true, 5)
	container(centerX + s * 35, 10, true, false, 3)
	car(centerX - s * 30, -35, Color3.fromRGB(200, 190, 180), yard, true)
	car(centerX + s * 32, 45, Color3.fromRGB(70, 70, 75), yard, false)
end

buildYard(-185, false)
buildYard(185, true)

----------------------------------------------------------------
-- team bases
----------------------------------------------------------------
-- no visible spawn pads: teams just appear on the ground at each end

----------------------------------------------------------------
-- a wall around the whole map so nobody falls off
----------------------------------------------------------------
local function border(size, position)
	local part = block("Border", size, position, Color3.fromRGB(60, 62, 70), Enum.Material.Metal)
	part.Transparency = 0.6
	return part
end

border(Vector3.new(520, 40, 2), Vector3.new(0, GROUND_TOP + 20, -120))
border(Vector3.new(520, 40, 2), Vector3.new(0, GROUND_TOP + 20, 120))
border(Vector3.new(2, 40, 240), Vector3.new(-260, GROUND_TOP + 20, 0))
border(Vector3.new(2, 40, 240), Vector3.new(260, GROUND_TOP + 20, 0))

-- keep the warehouse interior readable
Lighting.Ambient = Color3.fromRGB(70, 70, 75)
Lighting.OutdoorAmbient = Color3.fromRGB(110, 110, 120)

print("Map built: warehouse, two container yards, cars, bases at -160 and 160")
