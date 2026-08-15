-- Health bar in the top right corner
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "HealthGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local holder = Instance.new("Frame")
holder.Size = UDim2.new(0, 240, 0, 34)
holder.Position = UDim2.new(1, -260, 0, 170)
holder.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
holder.BackgroundTransparency = 0.25
holder.BorderSizePixel = 0
holder.Parent = gui

local fill = Instance.new("Frame")
fill.Size = UDim2.new(1, -8, 1, -8)
fill.Position = UDim2.new(0, 4, 0, 4)
fill.BackgroundColor3 = Color3.fromRGB(70, 220, 90)
fill.BorderSizePixel = 0
fill.Parent = holder

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.Text = "100"
label.Visible = false -- just the bar, no number
label.Parent = holder

local function colorFor(fraction)
	if fraction > 0.6 then
		return Color3.fromRGB(70, 220, 90)
	elseif fraction > 0.3 then
		return Color3.fromRGB(240, 200, 60)
	end
	return Color3.fromRGB(230, 70, 60)
end

local function watch(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end

	local function update()
		local fraction = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
		fill.Size = UDim2.new(fraction, -8, 1, -8)
		fill.BackgroundColor3 = colorFor(fraction)
		label.Text = tostring(math.max(math.floor(humanoid.Health + 0.5), 0))
	end

	humanoid.HealthChanged:Connect(update)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update)
	update()
end

player.CharacterAdded:Connect(watch)

if player.Character then
	watch(player.Character)
end
