-- Rebuilds the AK-47 to match the real thing: curved banana magazine,
-- wood handguard and gas tube, hooded front sight, angled wood stock.
-- Run from the Studio command bar in edit mode.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local tool = ReplicatedStorage:WaitForChild("GunTemplates"):FindFirstChild("AK-47")
if not tool then
	error("No AK-47 template found")
end

local WOOD = Color3.fromRGB(112, 62, 32)
local WOOD_DARK = Color3.fromRGB(88, 48, 26)
local STEEL = Color3.fromRGB(88, 90, 94)
local BLUED = Color3.fromRGB(48, 50, 54)

for _, child in ipairs(tool:GetChildren()) do
	if child:IsA("BasePart") then
		child:Destroy()
	end
end

-- receiver is the Handle. Gun runs along Z, barrel toward -Z.
local handle = Instance.new("Part")
handle.Name = "Handle"
handle.Size = Vector3.new(0.52, 1.0, 3.0)
handle.Color = STEEL
handle.Material = Enum.Material.Metal
handle.CanCollide = false
handle.Massless = true
handle.TopSurface = Enum.SurfaceType.Smooth
handle.BottomSurface = Enum.SurfaceType.Smooth
handle.Parent = tool

local function piece(name, size, offset, color, material, angles, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.Metal
	part.CanCollide = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		part.Shape = shape
	end
	part.Parent = tool
	part.CFrame = handle.CFrame * CFrame.new(offset) * (angles or CFrame.new())

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = part
	weld.Parent = part
	return part
end

----------------------------------------------------------------
-- receiver details
----------------------------------------------------------------
-- dust cover ridge along the top
piece("DustCover", Vector3.new(0.46, 0.22, 2.6), Vector3.new(0, 0.58, -0.1), STEEL)
-- selector switch on the right side
piece("Selector", Vector3.new(0.12, 0.7, 0.9), Vector3.new(0.3, 0.25, 0.1), BLUED)
-- rear sight block
piece("RearSight", Vector3.new(0.5, 0.28, 0.5), Vector3.new(0, 0.68, -1.45), BLUED)
-- trigger guard and trigger
piece("TriggerGuard", Vector3.new(0.34, 0.16, 1.0), Vector3.new(0, -0.85, 0.55), BLUED)
piece("Trigger", Vector3.new(0.12, 0.45, 0.16), Vector3.new(0, -0.68, 0.45), BLUED, Enum.Material.Metal, CFrame.Angles(math.rad(12), 0, 0))
-- charging handle sticking out the right
piece("ChargingHandle", Vector3.new(0.55, 0.2, 0.35), Vector3.new(0.35, 0.42, 0.9), STEEL)

----------------------------------------------------------------
-- barrel, gas system, handguard
----------------------------------------------------------------
-- barrel
local barrel = piece(
	"Barrel",
	Vector3.new(4.4, 0.26, 0.26),
	Vector3.new(0, 0.22, -3.7),
	BLUED,
	Enum.Material.Metal,
	CFrame.Angles(0, math.rad(90), 0),
	Enum.PartType.Cylinder
)

-- lower wood handguard
piece("Handguard", Vector3.new(0.6, 0.62, 1.9), Vector3.new(0, 0.05, -2.35), WOOD, Enum.Material.Wood)
-- the little metal collar at the back of the handguard
piece("HandguardRing", Vector3.new(0.66, 0.7, 0.3), Vector3.new(0, 0.1, -1.45), STEEL)

-- upper wood handguard sitting on the gas tube
piece("GasTubeWood", Vector3.new(0.52, 0.5, 1.7), Vector3.new(0, 0.52, -2.5), WOOD, Enum.Material.Wood)
-- gas tube in front of it
piece(
	"GasTube",
	Vector3.new(1.5, 0.3, 0.3),
	Vector3.new(0, 0.52, -4.1),
	BLUED,
	Enum.Material.Metal,
	CFrame.Angles(0, math.rad(90), 0),
	Enum.PartType.Cylinder
)
-- gas block with the slanted port
piece("GasBlock", Vector3.new(0.42, 0.75, 0.5), Vector3.new(0, 0.38, -4.55), BLUED, Enum.Material.Metal, CFrame.Angles(math.rad(-18), 0, 0))

----------------------------------------------------------------
-- front sight
----------------------------------------------------------------
piece("FrontSightBase", Vector3.new(0.42, 0.6, 0.42), Vector3.new(0, 0.42, -5.55), BLUED)
piece("FrontSightPost", Vector3.new(0.12, 0.42, 0.12), Vector3.new(0, 0.8, -5.55), BLUED)
-- the hood around the post, built from two sides and a top
piece("SightHoodLeft", Vector3.new(0.1, 0.42, 0.3), Vector3.new(-0.18, 0.8, -5.55), BLUED)
piece("SightHoodRight", Vector3.new(0.1, 0.42, 0.3), Vector3.new(0.18, 0.8, -5.55), BLUED)
piece("SightHoodTop", Vector3.new(0.46, 0.1, 0.3), Vector3.new(0, 1.0, -5.55), BLUED)

-- muzzle end
piece(
	"Muzzle",
	Vector3.new(0.5, 0.36, 0.36),
	Vector3.new(0, 0.22, -6.15),
	BLUED,
	Enum.Material.Metal,
	CFrame.Angles(0, math.rad(90), 0),
	Enum.PartType.Cylinder
)

----------------------------------------------------------------
-- curved banana magazine, built from segments that lean forward
----------------------------------------------------------------
local MAG_SEGMENTS = 4
local segHeight = 0.62
local step = 0.42 -- less than the height, so segments overlap into a solid curve

for i = 1, MAG_SEGMENTS do
	local lean = 6 + i * 6 -- each segment tips a bit further forward
	local y = -0.75 - (i - 0.5) * step
	local z = -0.2 - (i * i) * 0.055
	piece(
		"Magazine",
		Vector3.new(0.46, segHeight, 0.9 - i * 0.06),
		Vector3.new(0, y, z),
		BLUED,
		Enum.Material.Metal,
		CFrame.Angles(math.rad(lean), 0, 0)
	)
end

-- magazine release catch
piece("MagCatch", Vector3.new(0.2, 0.3, 0.22), Vector3.new(0, -0.95, 0.42), BLUED)

----------------------------------------------------------------
-- pistol grip and stock
----------------------------------------------------------------
piece("PistolGrip", Vector3.new(0.5, 1.35, 0.62), Vector3.new(0, -1.15, 1.15), WOOD, Enum.Material.Wood, CFrame.Angles(math.rad(22), 0, 0))
piece("GripCap", Vector3.new(0.5, 0.18, 0.6), Vector3.new(0, -1.78, 1.4), BLUED, Enum.Material.Metal, CFrame.Angles(math.rad(22), 0, 0))

-- stock: wrist, comb and butt, all sloping down to the rear
piece("StockWrist", Vector3.new(0.5, 0.7, 1.1), Vector3.new(0, -0.35, 2.0), WOOD, Enum.Material.Wood, CFrame.Angles(math.rad(-6), 0, 0))
piece("StockBody", Vector3.new(0.52, 0.95, 1.9), Vector3.new(0, -0.7, 3.1), WOOD, Enum.Material.Wood, CFrame.Angles(math.rad(-8), 0, 0))
piece("StockButt", Vector3.new(0.54, 1.15, 0.32), Vector3.new(0, -1.05, 4.05), WOOD_DARK, Enum.Material.Wood, CFrame.Angles(math.rad(-8), 0, 0))
-- sling loop on the side of the stock
piece("SlingLoop", Vector3.new(0.16, 0.3, 0.3), Vector3.new(0.3, -0.55, 2.7), BLUED)

tool.Grip = CFrame.new(0, -1.05, 1.3)

print("AK-47 rebuilt: curved magazine, wood furniture, hooded front sight, angled stock")
