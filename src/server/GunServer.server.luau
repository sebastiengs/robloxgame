-- Gun server: takes shot reports from clients and applies damage
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local DEFAULT_HEAD_DAMAGE = 100
local DEFAULT_BODY_DAMAGE = 30
local MAX_RANGE = 600

local remotes = ReplicatedStorage:FindFirstChild("GunRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "GunRemotes"
	remotes.Parent = ReplicatedStorage
end

local fireRemote = remotes:FindFirstChild("FireGun")
if not fireRemote then
	fireRemote = Instance.new("RemoteEvent")
	fireRemote.Name = "FireGun"
	fireRemote.Parent = remotes
end

local shotRemote = remotes:FindFirstChild("ShotHeard")
if not shotRemote then
	shotRemote = Instance.new("RemoteEvent")
	shotRemote.Name = "ShotHeard"
	shotRemote.Parent = remotes
end

-- tells the shooter their bullet landed
local hitRemote = remotes:FindFirstChild("HitConfirm")
if not hitRemote then
	hitRemote = Instance.new("RemoteEvent")
	hitRemote.Name = "HitConfirm"
	hitRemote.Parent = remotes
end

fireRemote.OnServerEvent:Connect(function(player, hitPart, hitPosition, tool)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	-- let everyone else hear the shot, hit or miss
	if typeof(tool) == "Instance" and tool:IsA("Tool") and tool.Parent == character then
		local handle = tool:FindFirstChild("Handle")
		if handle then
			for _, other in ipairs(Players:GetPlayers()) do
				if other ~= player then
					shotRemote:FireClient(other, handle)
				end
			end
		end
	end

	if typeof(hitPart) ~= "Instance" or not hitPart:IsA("BasePart") then
		return
	end

	-- the gun must really belong to this player
	local headDamage, bodyDamage = DEFAULT_HEAD_DAMAGE, DEFAULT_BODY_DAMAGE
	if typeof(tool) == "Instance" and tool:IsA("Tool") then
		local owner = tool.Parent
		if owner ~= character and owner ~= player:FindFirstChild("Backpack") then
			return
		end
		headDamage = tool:GetAttribute("HeadDamage") or headDamage
		bodyDamage = tool:GetAttribute("BodyDamage") or bodyDamage
	end

	if (root.Position - hitPart.Position).Magnitude > MAX_RANGE then
		return
	end

	local hitHumanoid = hitPart.Parent and hitPart.Parent:FindFirstChildOfClass("Humanoid")
	if not hitHumanoid or hitHumanoid.Health <= 0 then
		return
	end

	if hitPart.Parent == character then
		return
	end

	-- no shooting your own team in team rounds
	local victim = Players:GetPlayerFromCharacter(hitPart.Parent)
	if victim and victim.Team and player.Team and victim.Team == player.Team then
		return
	end

	-- tag the victim so the round script knows who gets the kill
	local oldTag = hitHumanoid:FindFirstChild("creator")
	if oldTag then
		oldTag:Destroy()
	end
	local tag = Instance.new("ObjectValue")
	tag.Name = "creator"
	tag.Value = player
	tag.Parent = hitHumanoid
	Debris:AddItem(tag, 10)

	local headshot = hitPart.Name == "Head"
	local damage = headshot and headDamage or bodyDamage

	-- guns like the Thompson and the shotgun get weaker far away
	if typeof(tool) == "Instance" then
		local rangeFull = tool:GetAttribute("RangeFull")
		local rangeMax = tool:GetAttribute("RangeMax")
		if rangeFull and rangeMax and rangeMax > rangeFull then
			local distance = (root.Position - hitPart.Position).Magnitude
			if distance > rangeFull then
				local fade = math.clamp((distance - rangeFull) / (rangeMax - rangeFull), 0, 1)
				damage = damage * (1 - fade * 0.65)
			end
		end
	end

	hitHumanoid:TakeDamage(damage)

	local killed = hitHumanoid.Health <= 0
	local victimName = victim and victim.Name or "someone"
	hitRemote:FireClient(player, killed, headshot, victimName)
end)
