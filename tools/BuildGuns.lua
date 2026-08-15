-- Gives every gun template a real looking model: receiver, barrel, handguard,
-- stock, pistol grip, magazine, rail and sights.
-- Run from the Studio command bar in edit mode.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local templates = ReplicatedStorage:FindFirstChild("GunTemplates")
if not templates then
	error("No GunTemplates folder — run the shop install first")
end

local STYLES = {
	["AK-47"] = {
		metal = Color3.fromRGB(45, 45, 48),
		furniture = Color3.fromRGB(120, 75, 40),
		furnitureMaterial = Enum.Material.Wood,
		sight = false,
		barrelLength = 5.4,
	},
	["M4"] = {
		metal = Color3.fromRGB(30, 30, 33),
		furniture = Color3.fromRGB(38, 38, 42),
		furnitureMaterial = Enum.Material.Metal,
		sight = true,
		barrelLength = 5.0,
	},
	["AR-15"] = {
		metal = Color3.fromRGB(60, 65, 72),
		furniture = Color3.fromRGB(120, 110, 90),
		furnitureMaterial = Enum.Material.Metal,
		sight = true,
		barrelLength = 5.8,
	},
}

local function buildGun(tool, style)
	-- clear the old parts
	for _, child in ipairs(tool:GetChildren()) do
		if child:IsA("BasePart") then
			child:Destroy()
		end
	end

	-- receiver is the Handle, gun points down -Z
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.5, 1.1, 4.4)
	handle.Color = style.metal
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Massless = true
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	handle.Parent = tool

	local function piece(name, size, offset, color, material, angles)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Color = color
		part.Material = material or Enum.Material.Metal
		part.CanCollide = false
		part.Massless = true
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Parent = tool

		part.CFrame = handle.CFrame * CFrame.new(offset) * (angles or CFrame.new())

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = part
		weld.Parent = part
		return part
	end

	-- barrel
	local barrel = piece(
		"Barrel",
		Vector3.new(style.barrelLength, 0.34, 0.34),
		Vector3.new(0, 0.15, -2.2 - style.barrelLength / 2),
		style.metal,
		Enum.Material.Metal,
		CFrame.Angles(0, math.rad(90), 0)
	)
	barrel.Shape = Enum.PartType.Cylinder

	-- muzzle
	local muzzle = piece(
		"Muzzle",
		Vector3.new(0.8, 0.5, 0.5),
		Vector3.new(0, 0.15, -2.2 - style.barrelLength - 0.2),
		style.metal,
		Enum.Material.Metal,
		CFrame.Angles(0, math.rad(90), 0)
	)
	muzzle.Shape = Enum.PartType.Cylinder

	-- handguard over the barrel
	piece(
		"Handguard",
		Vector3.new(0.62, 0.72, 3.4),
		Vector3.new(0, 0.12, -3.9),
		style.furniture,
		style.furnitureMaterial
	)

	-- stock
	piece("StockTube", Vector3.new(0.4, 0.5, 1.4), Vector3.new(0, 0.05, 2.9), style.metal, Enum.Material.Metal)
	piece(
		"Stock",
		Vector3.new(0.55, 1.15, 2.2),
		Vector3.new(0, -0.15, 4.2),
		style.furniture,
		style.furnitureMaterial,
		CFrame.Angles(math.rad(-4), 0, 0)
	)

	-- pistol grip
	piece(
		"Grip",
		Vector3.new(0.55, 1.7, 0.85),
		Vector3.new(0, -1.15, 1.5),
		style.furniture,
		style.furnitureMaterial,
		CFrame.Angles(math.rad(18), 0, 0)
	)

	-- magazine, slightly curved forward
	piece(
		"Magazine",
		Vector3.new(0.5, 2.1, 0.95),
		Vector3.new(0, -1.4, -0.1),
		style.metal,
		Enum.Material.Metal,
		CFrame.Angles(math.rad(-10), 0, 0)
	)

	-- top rail
	piece("Rail", Vector3.new(0.42, 0.18, 3.6), Vector3.new(0, 0.63, -0.9), style.metal, Enum.Material.Metal)

	-- charging handle
	piece("ChargingHandle", Vector3.new(0.9, 0.22, 0.5), Vector3.new(0, 0.45, 1.9), style.metal, Enum.Material.Metal)

	-- front sight post
	piece("FrontSight", Vector3.new(0.16, 0.62, 0.22), Vector3.new(0, 0.85, -5.2), style.metal, Enum.Material.Metal)

	if style.sight then
		-- red dot sight body and glowing lens
		piece("SightBody", Vector3.new(0.62, 0.7, 1.0), Vector3.new(0, 1.05, -0.4), style.metal, Enum.Material.Metal)
		local lens = piece(
			"SightLens",
			Vector3.new(0.46, 0.46, 0.12),
			Vector3.new(0, 1.12, -0.92),
			Color3.fromRGB(255, 60, 50),
			Enum.Material.Neon
		)
		lens.Shape = Enum.PartType.Cylinder
		lens.CFrame = handle.CFrame * CFrame.new(0, 1.12, -0.92) * CFrame.Angles(0, math.rad(90), 0)
	else
		-- iron rear sight instead
		piece("RearSight", Vector3.new(0.5, 0.4, 0.25), Vector3.new(0, 0.82, 0.3), style.metal, Enum.Material.Metal)
	end

	-- worked out by testing in game: barrel points forward, gun sits upright
	tool.Grip = CFrame.new(0, -1.05, 1.3)
end

for name, style in pairs(STYLES) do
	local tool = templates:FindFirstChild(name)
	if tool then
		buildGun(tool, style)
	end
end

print("Guns rebuilt: barrel, handguard, stock, grip, magazine, rail and sights")
