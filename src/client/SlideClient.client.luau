-- Slide: press Left Control while running.
-- The character drops into a knee slide, leans back and skids along the ground.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local SLIDE_START_SPEED = 58
local SLIDE_END_SPEED = 16
local SLIDE_TIME = 0.75
local MIN_RUN_SPEED = 10
local CAMERA_DIP = 2.0
local LEAN_BACK = 22 -- tipped back; the slide pose does most of the work
local ROLL = 10 -- and slightly over onto one side
local SLIDE_POSE = "rbxassetid://2506281703" -- Roblox's sit pose: legs out front, body reclined
local REQUIRE_RUNNING = true

-- how each joint is bent during the slide, in degrees
local POSE = {
	Root = CFrame.Angles(math.rad(-18), 0, 0),
	Waist = CFrame.Angles(math.rad(-12), 0, 0),
	RightHip = CFrame.Angles(math.rad(-70), 0, 0),
	RightKnee = CFrame.Angles(math.rad(100), 0, 0),
	LeftHip = CFrame.Angles(math.rad(-15), 0, 0),
	LeftKnee = CFrame.Angles(math.rad(20), 0, 0),
	RightShoulder = CFrame.Angles(0, 0, math.rad(-20)),
	LeftShoulder = CFrame.Angles(0, 0, math.rad(25)),
}

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

-- bend the character into the slide pose, and remember how to put it back
local function applyPose(character)
	local saved = {}
	for _, motor in ipairs(character:GetDescendants()) do
		if motor:IsA("Motor6D") and POSE[motor.Name] then
			saved[motor] = motor.C0
			motor.C0 = motor.C0 * POSE[motor.Name]
		end
	end
	return saved
end

local function restorePose(saved)
	for motor, c0 in pairs(saved) do
		if motor.Parent then
			motor.C0 = c0
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

	setAnimationsPaused(character, humanoid, true)
	local savedPose = applyPose(character)

	-- pose the body into the slide
	local poseTrack
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		local anim = Instance.new("Animation")
		anim.AnimationId = SLIDE_POSE
		local ok, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if ok and track then
			track.Priority = Enum.AnimationPriority.Action4
			track.Looped = true
			track:Play(0.06)
			poseTrack = track
		end
		anim:Destroy()
	end

	humanoid.AutoRotate = false
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	humanoid.PlatformStand = true
	humanoid.HipHeight = math.max(startHipHeight - 1.4, 0)
	humanoid.CameraOffset = Vector3.new(0, -CAMERA_DIP, 0)

	local attachment = Instance.new("Attachment")
	attachment.Parent = root

	local push = Instance.new("LinearVelocity")
	push.Attachment0 = attachment
	push.MaxForce = math.huge
	push.RelativeTo = Enum.ActuatorRelativeTo.World
	push.VectorVelocity = direction * SLIDE_START_SPEED
	push.Parent = root

	-- keep the body facing the way it slides, tipped back a little
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
		push.VectorVelocity = direction * (SLIDE_START_SPEED + (SLIDE_END_SPEED - SLIDE_START_SPEED) * alpha)

		if alpha >= 1 then
			connection:Disconnect()

			push:Destroy()
			lean:Destroy()
			attachment:Destroy()

			if poseTrack then
				poseTrack:Stop(0.1)
				poseTrack:Destroy()
			end

			restorePose(savedPose)

			local h, _, char = getParts()
			if h and char then
				h.PlatformStand = false
				h.AutoRotate = startAutoRotate
				h.WalkSpeed = startWalkSpeed
				h.JumpPower = startJumpPower
				h.HipHeight = startHipHeight
				h.CameraOffset = Vector3.new(0, 0, 0)
				h:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
				setAnimationsPaused(char, h, false)
			end

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
