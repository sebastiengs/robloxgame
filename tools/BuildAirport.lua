-- Builds the second map: an airport with a terminal you can fight inside,
-- planes and luggage carts out on the apron.
-- It sits 2000 studs away from the warehouse map so both can exist at once.
-- Run from the Studio command bar in edit mode.

local ORIGIN = Vector3.new(2000, 0, 0)
local GROUND_TOP = 7

local old = workspace:FindFirstChild("Map_Airport")
if old then
	old:Destroy()
end

local map = Instance.new("Folder")
map.Name = "Map_Airport"
map.Parent = workspace

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
-- apron and runway
----------------------------------------------------------------
block("Ground", Vector3.new(520, 2, 240), Vector3.new(0, GROUND_TOP - 1, 0), Color3.fromRGB(70, 72, 78), Enum.Material.Asphalt)

-- runway down one side with painted stripes
onGround("Runway", Vector3.new(500, 0.2, 60), 0, -75, Color3.fromRGB(45, 46, 50), Enum.Material.Asphalt)
for i = -10, 10 do
	onGround("RunwayStripe", Vector3.new(16, 0.3, 2), i * 24, -75, Color3.fromRGB(230, 230, 230), Enum.Material.SmoothPlastic)
end
onGround("RunwayEdgeA", Vector3.new(500, 0.3, 1.5), 0, -104, Color3.fromRGB(230, 220, 120), Enum.Material.SmoothPlastic)
onGround("RunwayEdgeB", Vector3.new(500, 0.3, 1.5), 0, -46, Color3.fromRGB(230, 220, 120), Enum.Material.SmoothPlastic)

----------------------------------------------------------------
-- terminal building, open inside, doors on both long sides
----------------------------------------------------------------
local terminal = Instance.new("Folder")
terminal.Name = "Terminal"
terminal.Parent = map

local WALL_H = 26
local GLASS = Color3.fromRGB(150, 190, 210)
local WALL = Color3.fromRGB(215, 215, 220)

onGround("TerminalFloor", Vector3.new(220, 1, 90), 0, 60, Color3.fromRGB(200, 198, 195), Enum.Material.Marble, terminal)

-- long walls: the runway side is glass, the back side is solid, both with door gaps
local function longWall(z, color, material)
	onGround("Wall", Vector3.new(85, WALL_H, 2), -67.5, z, color, material, terminal)
	onGround("Wall", Vector3.new(85, WALL_H, 2), 67.5, z, color, material, terminal)
	block("WallTop", Vector3.new(50, 8, 2), Vector3.new(0, GROUND_TOP + WALL_H - 4, z), color, material, terminal)
end

longWall(15, GLASS, Enum.Material.Glass)
longWall(105, WALL, Enum.Material.Concrete)

-- end walls
local function endWall(x)
	onGround("EndWall", Vector3.new(2, WALL_H, 35), x, 32.5, WALL, Enum.Material.Concrete, terminal)
	onGround("EndWall", Vector3.new(2, WALL_H, 35), x, 87.5, WALL, Enum.Material.Concrete, terminal)
	block("EndWallTop", Vector3.new(2, 8, 20), Vector3.new(x, GROUND_TOP + WALL_H - 4, 60), WALL, Enum.Material.Concrete, terminal)
end

endWall(-110)
endWall(110)

-- roof with skylight gaps
for i = -3, 3 do
	block("Roof", Vector3.new(26, 1, 90), Vector3.new(i * 31, GROUND_TOP + WALL_H, 60), Color3.fromRGB(190, 190, 195), Enum.Material.Metal, terminal)
end

-- inside: check-in desks, seating blocks and pillars to hide behind
for i = -2, 2 do
	onGround("Pillar", Vector3.new(6, WALL_H, 6), i * 40, 60, Color3.fromRGB(180, 180, 185), Enum.Material.Concrete, terminal)
end

local function desk(x, z)
	onGround("CheckInDesk", Vector3.new(26, 6, 8), x, z, Color3.fromRGB(225, 225, 230), Enum.Material.SmoothPlastic, terminal)
	onGround("DeskSign", Vector3.new(20, 4, 1), x, z + 5, Color3.fromRGB(60, 90, 160), Enum.Material.SmoothPlastic, terminal)
end

desk(-70, 95)
desk(-20, 95)
desk(35, 95)
desk(85, 95)

local function seats(x, z)
	onGround("SeatRow", Vector3.new(24, 3, 5), x, z, Color3.fromRGB(60, 70, 100), Enum.Material.Fabric, terminal)
	onGround("SeatBack", Vector3.new(24, 5, 1.5), x, z + 2, Color3.fromRGB(50, 60, 90), Enum.Material.Fabric, terminal)
end

seats(-60, 35)
seats(-10, 35)
seats(45, 35)
seats(95, 35)

-- baggage carousel in the middle
onGround("Carousel", Vector3.new(60, 4, 16), 0, 75, Color3.fromRGB(90, 90, 95), Enum.Material.Metal, terminal)

----------------------------------------------------------------
-- planes out on the apron
-- NOTE: the blocky planes below were replaced in the saved place by three
-- copies of a real A320 model (asset 8959295293), scaled to 0.75.
----------------------------------------------------------------
local planes = Instance.new("Folder")
planes.Name = "Planes"
planes.Parent = map

local function plane(x, z, color)
	local model = Instance.new("Model")
	model.Name = "Plane"
	model.Parent = planes

	local bodyY = GROUND_TOP + 12

	-- fuselage
	-- a cylinder's length runs along its X axis, so no rotation needed here
	local body = block("Fuselage", Vector3.new(90, 14, 14), Vector3.new(x, bodyY, z), color, Enum.Material.Metal, model)
	body.Shape = Enum.PartType.Cylinder

	-- nose and tail cone
	local nose = block("Nose", Vector3.new(12, 12, 12), Vector3.new(x - 48, bodyY, z), color, Enum.Material.Metal, model)
	nose.Shape = Enum.PartType.Ball

	-- wings
	block("WingLeft", Vector3.new(26, 1.6, 46), Vector3.new(x + 4, bodyY - 3, z - 30), color, Enum.Material.Metal, model)
	block("WingRight", Vector3.new(26, 1.6, 46), Vector3.new(x + 4, bodyY - 3, z + 30), color, Enum.Material.Metal, model)

	-- engines under the wings
	local function engine(offsetZ)
		local e = block("Engine", Vector3.new(16, 9, 9), Vector3.new(x + 2, bodyY - 8, z + offsetZ), Color3.fromRGB(70, 72, 78), Enum.Material.Metal, model)
		e.Shape = Enum.PartType.Cylinder
	end
	engine(-28)
	engine(28)

	-- tail fin and stabilisers
	block("TailFin", Vector3.new(16, 22, 1.6), Vector3.new(x + 40, bodyY + 16, z), color, Enum.Material.Metal, model)
	block("Stabiliser", Vector3.new(12, 1.4, 30), Vector3.new(x + 42, bodyY + 4, z), color, Enum.Material.Metal, model)

	-- landing gear
	block("GearFront", Vector3.new(2, 10, 2), Vector3.new(x - 34, GROUND_TOP + 5, z), Color3.fromRGB(60, 60, 65), Enum.Material.Metal, model)
	block("GearLeft", Vector3.new(2, 10, 2), Vector3.new(x + 6, GROUND_TOP + 5, z - 8), Color3.fromRGB(60, 60, 65), Enum.Material.Metal, model)
	block("GearRight", Vector3.new(2, 10, 2), Vector3.new(x + 6, GROUND_TOP + 5, z + 8), Color3.fromRGB(60, 60, 65), Enum.Material.Metal, model)

	-- boarding stairs, so the plane is cover you can run around
	for step = 1, 8 do
		block("Stair", Vector3.new(8, 1, 3), Vector3.new(x - 20 - step * 2.5, GROUND_TOP + 12 - step * 1.4, z + 14), Color3.fromRGB(150, 150, 155), Enum.Material.Metal, model)
	end
end

plane(-120, -10, Color3.fromRGB(235, 235, 240))
plane(60, -20, Color3.fromRGB(210, 90, 80))
plane(-40, -110, Color3.fromRGB(90, 130, 200))

----------------------------------------------------------------
-- luggage carts and baggage
----------------------------------------------------------------
local carts = Instance.new("Folder")
carts.Name = "LuggageCarts"
carts.Parent = map

local BAG_COLORS = {
	Color3.fromRGB(140, 60, 60),
	Color3.fromRGB(60, 90, 130),
	Color3.fromRGB(90, 100, 70),
	Color3.fromRGB(60, 60, 65),
}

local function cart(x, z, turned)
	local model = Instance.new("Model")
	model.Name = "LuggageCart"
	model.Parent = carts

	local length = turned and Vector3.new(9, 1.2, 18) or Vector3.new(18, 1.2, 9)
	block("CartBed", length, Vector3.new(x, GROUND_TOP + 4, z), Color3.fromRGB(120, 120, 60), Enum.Material.Metal, model)

	-- side rails
	if turned then
		block("Rail", Vector3.new(0.6, 4, 18), Vector3.new(x - 4.2, GROUND_TOP + 6, z), Color3.fromRGB(100, 100, 50), Enum.Material.Metal, model)
		block("Rail", Vector3.new(0.6, 4, 18), Vector3.new(x + 4.2, GROUND_TOP + 6, z), Color3.fromRGB(100, 100, 50), Enum.Material.Metal, model)
	else
		block("Rail", Vector3.new(18, 4, 0.6), Vector3.new(x, GROUND_TOP + 6, z - 4.2), Color3.fromRGB(100, 100, 50), Enum.Material.Metal, model)
		block("Rail", Vector3.new(18, 4, 0.6), Vector3.new(x, GROUND_TOP + 6, z + 4.2), Color3.fromRGB(100, 100, 50), Enum.Material.Metal, model)
	end

	-- wheels
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			local w = block("Wheel", Vector3.new(1.2, 3, 3), Vector3.new(x + sx * 6, GROUND_TOP + 1.5, z + sz * 3), Color3.fromRGB(30, 30, 32), Enum.Material.Rubber, model)
			w.Shape = Enum.PartType.Cylinder
			w.CFrame = CFrame.new(ORIGIN + Vector3.new(x + sx * 6, GROUND_TOP + 1.5, z + sz * 3)) * CFrame.Angles(0, math.rad(90), 0)
		end
	end

	-- a stack of suitcases on top
	for i = 1, 3 do
		local color = BAG_COLORS[((i + math.floor(x)) % #BAG_COLORS) + 1]
		block("Suitcase", Vector3.new(6, 2.5, 4), Vector3.new(x - 3 + i * 2, GROUND_TOP + 6 + i * 2.6, z), color, Enum.Material.Fabric, model)
	end
end

cart(-150, 0, false)
cart(-95, -45, true)
cart(-15, -55, false)
cart(30, 5, true)
cart(110, -35, false)
cart(150, 10, true)
cart(-60, 5, false)
cart(90, -70, true)

----------------------------------------------------------------
-- border walls
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

print("Airport built at " .. tostring(ORIGIN) .. ": terminal, 3 planes, luggage carts, runway")
