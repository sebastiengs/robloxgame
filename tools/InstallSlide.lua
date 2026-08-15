local StarterPlayer = game:GetService("StarterPlayer")
local scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

local slideSource = [==[-- Slide: press Left Control while running to slide a short distance
-- The character drops low, leans back onto one leg and skids along the ground.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local SLIDE_START_SPEED = 58
local SLIDE_END_SPEED = 14
local SLIDE_TIME = 0.7
local MIN_RUN_SPEED = 10
local CAMERA_DIP = 2.2
local LEAN_BACK = 38 -- degrees tipped back, feet first
local ROLL = 25 -- degrees onto one side
local REQUIRE_RUNNING = true

local sliding = false

local function getParts()
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then
		return nil
	end
	return humanoid, root, character
end

local function setAnimationsPaused(character, humanoid, paused)
	local animate = character:FindFirstChild("Animate")
	if animate then
		animate.Disabled = paused
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator and paused then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			track:Stop(0)
		end
	end
end

local function slide()
	if sliding then
		return
	end

	local humanoid, root, character = getParts()
	if not humanoid then
		return
	end

	-- you have to be running to slide
	local speed = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude
	if REQUIRE_RUNNING and humanoid.MoveDirection.Magnitude == 0 and speed < MIN_RUN_SPEED then
		return
	end
	if humanoid.FloorMaterial == Enum.Material.Air then
		return
	end

	sliding = true

	local direction = root.CFrame.LookVector
	if humanoid.MoveDirection.Magnitude > 0 then
		direction = humanoid.MoveDirection
	end
	direction = Vector3.new(direction.X, 0, direction.Z).Unit

	local startHipHeight = humanoid.HipHeight
	local startAutoRotate = humanoid.AutoRotate
	local startWalkSpeed = humanoid.WalkSpeed
	local startJumpPower = humanoid.JumpPower

	-- freeze the running animation so the legs stop pumping
	setAnimationsPaused(character, humanoid, true)

	humanoid.AutoRotate = false
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	-- PlatformStand stops the humanoid from forcing the body upright
	humanoid.PlatformStand = true
	humanoid.HipHeight = math.max(startHipHeight - 1.5, 0)
	humanoid.CameraOffset = Vector3.new(0, -CAMERA_DIP, 0)

	local attachment = Instance.new("Attachment")
	attachment.Parent = root

	local push = Instance.new("LinearVelocity")
	push.Attachment0 = attachment
	push.MaxForce = math.huge
	push.RelativeTo = Enum.ActuatorRelativeTo.World
	push.VectorVelocity = direction * SLIDE_START_SPEED
	push.Parent = root

	-- tip the body BACK and roll onto one side, feet leading the slide
	local lean = Instance.new("AlignOrientation")
	lean.Attachment0 = attachment
	lean.Mode = Enum.OrientationAlignmentMode.OneAttachment
	lean.RigidityEnabled = true
	lean.CFrame = CFrame.lookAt(Vector3.zero, direction)
		* CFrame.Angles(math.rad(LEAN_BACK), 0, math.rad(ROLL))
	lean.Parent = root

	local elapsed = 0
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		local alpha = math.clamp(elapsed / SLIDE_TIME, 0, 1)
		local currentSpeed = SLIDE_START_SPEED + (SLIDE_END_SPEED - SLIDE_START_SPEED) * alpha
		push.VectorVelocity = direction * currentSpeed

		if alpha >= 1 then
			connection:Disconnect()

			push:Destroy()
			lean:Destroy()
			attachment:Destroy()

			local h, _, char = getParts()
			if h and char then
				h.AutoRotate = startAutoRotate
				h.WalkSpeed = startWalkSpeed
				h.JumpPower = startJumpPower
				h.HipHeight = startHipHeight
				h.CameraOffset = Vector3.new(0, 0, 0)
				h.PlatformStand = false
				h:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
				h:ChangeState(Enum.HumanoidStateType.GettingUp)
				setAnimationsPaused(char, h, false)
			end

			-- no cooldown: you can slide again straight away
			sliding = false
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.C then
		slide()
	end
end)

player.CharacterAdded:Connect(function()
	sliding = false
end)
]==]

local old = scripts:FindFirstChild("SlideClient")
if old then old:Destroy() end

local s = Instance.new("LocalScript")
s.Name = "SlideClient"
s.Source = slideSource
s.Parent = scripts

print("Slide installed: StarterPlayerScripts.SlideClient")
