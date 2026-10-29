-- Real R15 characters for passengers and monsters, with animations, poses and speech.
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Passengers = require(Shared.Passengers)
local Remotes = require(Shared.Remotes)

local ProBody = require(script.Parent.ProBody)

-- Passenger hair styles -> the Blender Civilian hair pieces
local PRO_HAIR = { Short = "HairShort", Long = "HairLong", Bun = "HairBun", Pigtails = "HairLong", Spiky = "HairSpiky", Cap = "HairCap" }

local NPC = {}

-- Roblox's default R15 animations (used when Config.Animations is 0)
local DEFAULT_ANIMS = {
	Walk = 507777826,
	Idle = 507766388,
	Run = 507767714,
}

pcall(function()
	PhysicsService:RegisterCollisionGroup("NPC")
	PhysicsService:RegisterCollisionGroup("Players")
	PhysicsService:CollisionGroupSetCollidable("NPC", "NPC", false)
	PhysicsService:CollisionGroupSetCollidable("NPC", "Players", false)
end)

local function setGroup(model: Model, group: string)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.CollisionGroup = group
		end
	end
end
NPC.SetGroup = setGroup

local function animation(id: number): Animation
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. id
	return anim
end

-- Loads walk/idle tracks and switches between them while the NPC moves.
local function animate(model: Model, walkId: number, idleId: number, runSpeed: number?)
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = humanoid
	local walk = animator:LoadAnimation(animation(walkId))
	local idle = animator:LoadAnimation(animation(idleId))
	walk.Priority = Enum.AnimationPriority.Movement
	idle.Priority = Enum.AnimationPriority.Idle
	walk.Looped = true
	idle.Looped = true
	idle:Play()
	local moving = false
	humanoid.Running:Connect(function(speed)
		if speed > 0.6 and not moving then
			moving = true
			walk:Play(0.2)
			walk:AdjustSpeed(speed / (runSpeed or 12))
		elseif speed <= 0.6 and moving then
			moving = false
			walk:Stop(0.25)
		elseif moving then
			walk:AdjustSpeed(speed / (runSpeed or 12))
		end
	end)
	return animator
end

local function weld(part: BasePart, to: BasePart, offset: CFrame)
	part.Anchored = false
	part.CanCollide = false
	part.Massless = true
	part.CFrame = to.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = part
	w.Parent = part
end

local function add(
	model: Instance,
	to: BasePart?,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	material: Enum.Material?,
	shape: Enum.PartType?
): Part?
	if not to then
		return nil
	end
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.Parent = model
	weld(p, to, offset)
	return p
end

-- Hair built from parts (used when no Marketplace hair IDs are configured).
local function buildHair(model: Model, style: string, color: Color3)
	local head = model:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "Hair"
	folder.Parent = model
	local s = head.Size
	if style == "Bald" then
		return
	end
	if style == "Cap" then
		add(
			folder,
			head,
			Vector3.new(s.X * 1.08, s.Y * 0.35, s.Z * 1.08),
			CFrame.new(0, s.Y * 0.38, 0),
			color:Lerp(Color3.fromRGB(40, 60, 120), 0.6),
			Enum.Material.Fabric
		)
		add(
			folder,
			head,
			Vector3.new(s.X, 0.1, s.Z * 0.5),
			CFrame.new(0, s.Y * 0.22, -s.Z * 0.65),
			Color3.fromRGB(30, 40, 80),
			Enum.Material.Fabric
		)
		return
	end
	add(folder, head, Vector3.new(s.X * 1.08, s.Y * 0.4, s.Z * 1.1), CFrame.new(0, s.Y * 0.36, 0.05), color, Enum.Material.Fabric)
	add(folder, head, Vector3.new(s.X * 1.08, s.Y * 0.7, s.Z * 0.3), CFrame.new(0, s.Y * 0.1, s.Z * 0.45), color, Enum.Material.Fabric)
	if style == "Long" then
		add(folder, head, Vector3.new(s.X * 1.1, s.Y * 1.3, s.Z * 0.35), CFrame.new(0, -s.Y * 0.25, s.Z * 0.5), color, Enum.Material.Fabric)
		for _, x in { -1, 1 } do
			add(
				folder,
				head,
				Vector3.new(s.X * 0.18, s.Y * 1.1, s.Z * 0.8),
				CFrame.new(x * s.X * 0.52, -s.Y * 0.1, 0.1),
				color,
				Enum.Material.Fabric
			)
		end
	elseif style == "Bun" then
		add(folder, head, Vector3.new(0.7, 0.7, 0.7), CFrame.new(0, s.Y * 0.6, s.Z * 0.45), color, Enum.Material.Fabric, Enum.PartType.Ball)
	elseif style == "Pigtails" then
		for _, x in { -1, 1 } do
			add(folder, head, Vector3.new(0.45, 1.1, 0.45), CFrame.new(x * s.X * 0.62, -s.Y * 0.15, s.Z * 0.2), color, Enum.Material.Fabric)
		end
	elseif style == "Spiky" then
		for i = -2, 2 do
			local spike = Instance.new("WedgePart")
			spike.Size = Vector3.new(0.3, 0.6, 0.5)
			spike.Color = color
			spike.Material = Enum.Material.Fabric
			spike.Parent = folder
			weld(spike, head, CFrame.new(i * 0.24, s.Y * 0.7, 0.05) * CFrame.Angles(0, 0, math.rad(i * 10)))
		end
	end
end

local function suitcase(model: Model, color: Color3): Model
	local bag = Instance.new("Model")
	bag.Name = "Suitcase"
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(0.7, 1.9, 2.4)
	body.Color = color
	body.Material = Enum.Material.SmoothPlastic
	body.Parent = bag
	local handle = Instance.new("Part")
	handle.Size = Vector3.new(0.2, 0.5, 0.8)
	handle.Color = Color3.fromRGB(30, 30, 30)
	handle.Parent = bag
	local stripe = Instance.new("Part")
	stripe.Size = Vector3.new(0.75, 0.2, 2.45)
	stripe.Color = Color3.fromRGB(30, 30, 34)
	stripe.Parent = bag
	bag.PrimaryPart = body
	local hand = model:FindFirstChild("RightHand") :: BasePart?
	if hand then
		weld(body, hand, CFrame.new(0.2, -1.1, 0))
		weld(handle, body, CFrame.new(0, 1.1, 0))
		weld(stripe, body, CFrame.new(0, 0.3, 0))
	end
	bag.Parent = model
	return bag
end

-- Detaches the suitcase from the hand and returns it as a loose, anchored model at `cf`.
function NPC.DropBag(model: Model, cf: CFrame): Model?
	local bag = model:FindFirstChild("Suitcase") :: Model?
	if not bag or not bag.PrimaryPart then
		return nil
	end
	for _, w in bag:GetDescendants() do
		if w:IsA("WeldConstraint") and w.Part0 and not w.Part0:IsDescendantOf(bag) then
			w:Destroy()
		end
	end
	for _, p in bag:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CollisionGroup = "NPC"
		end
	end
	bag.Parent = model.Parent
	bag:PivotTo(cf * CFrame.Angles(0, 0, math.pi / 2))
	return bag
end

function NPC.Passenger(record, cf: CFrame, parent: Instance): Model
	local desc = Instance.new("HumanoidDescription")
	local skin = Passengers.SkinColors[record.Look.Skin]
	local shirt = Passengers.ShirtColors[record.Look.Shirt]
	local pants = Passengers.PantsColors[record.Look.Pants]
	desc.HeadColor = skin
	desc.LeftArmColor = skin
	desc.RightArmColor = skin
	desc.TorsoColor = shirt
	desc.LeftLegColor = pants
	desc.RightLegColor = pants
	local rng = Random.new(record.Seed)
	local looks = Config.PassengerLooks
	local function pickId(list)
		if #list == 0 then
			return nil
		end
		return tonumber(list[rng:NextInteger(1, #list)])
	end
	local hairId, shirtId, pantsId, faceId = pickId(looks.Hair), pickId(looks.Shirts), pickId(looks.Pants), pickId(looks.Faces)
	if hairId then
		desc.HairAccessory = tostring(hairId)
	end
	if shirtId then
		desc.Shirt = shirtId
	end
	if pantsId then
		desc.Pants = pantsId
	end
	if faceId then
		desc.Face = faceId
	end
	local model: Model
	local ok, result = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if ok and result then
		model = result
	else
		warn("[NPC] Could not create passenger:", result)
		model = Instance.new("Model")
	end
	model.Name = record.First .. " " .. record.Last
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local animateScript = model:FindFirstChild("Animate")
	if animateScript then
		animateScript:Destroy()
	end
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.WalkSpeed = 9
		humanoid.BreakJointsOnDeath = false
	end
	-- Blender cartoon body, unless the owner configured real catalog clothing
	local usePro = not (hairId or shirtId or pantsId or faceId) and ProBody.Has("Civilian")
	if not hairId and not usePro then
		buildHair(model, record.Look.Hair, Passengers.HairColors[record.Look.HairColor])
	end
	-- Shirt sleeves (part-built) so clothes read clearly without catalog items
	if not shirtId and not usePro then
		for _, name in { "LeftUpperArm", "RightUpperArm" } do
			local arm = model:FindFirstChild(name) :: BasePart?
			if arm then
				add(model, arm, arm.Size + Vector3.new(0.06, -0.2, 0.06), CFrame.new(0, 0.1, 0), shirt, Enum.Material.Fabric)
			end
		end
	end
	local bagColors = {
		Color3.fromRGB(40, 40, 46),
		Color3.fromRGB(120, 30, 30),
		Color3.fromRGB(30, 60, 120),
		Color3.fromRGB(150, 120, 70),
		Color3.fromRGB(60, 90, 60),
	}
	suitcase(model, bagColors[rng:NextInteger(1, #bagColors)])
	pcall(function()
		model:ScaleTo(record.Look.Height)
	end)
	if usePro then
		ProBody.Apply(model, "Civilian", {
			Skin = skin,
			Shirt = shirt,
			Pants = pants,
			Hair = Passengers.HairColors[record.Look.HairColor],
		}, PRO_HAIR[record.Look.Hair])
	end
	model:PivotTo(cf + Vector3.new(0, 3, 0))
	model.Parent = parent
	setGroup(model, "NPC")
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		hrp:SetNetworkOwner(nil)
	end
	if humanoid then
		animate(
			model,
			if Config.Animations.PassengerWalk ~= 0 then Config.Animations.PassengerWalk else DEFAULT_ANIMS.Walk,
			if Config.Animations.PassengerIdle ~= 0 then Config.Animations.PassengerIdle else DEFAULT_ANIMS.Idle,
			12
		)
	end
	model:SetAttribute("Passenger", true)
	return model
end

-- Walk to a point; returns when there (or after a timeout).
function NPC.WalkTo(model: Model, target: Vector3, timeout: number?): boolean
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not hrp then
		return false
	end
	local deadline = os.clock() + (timeout or 20)
	while model.Parent and os.clock() < deadline do
		humanoid:MoveTo(target)
		local flat = Vector3.new(hrp.Position.X - target.X, 0, hrp.Position.Z - target.Z)
		if flat.Magnitude < 1.6 then
			return true
		end
		task.wait(0.25)
	end
	return false
end

function NPC.Face(model: Model, lookAt: Vector3)
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		local pos = hrp.Position
		hrp.CFrame = CFrame.lookAt(pos, Vector3.new(lookAt.X, pos.Y, lookAt.Z))
	end
end

-- Procedural poses using the shoulder joints (or uploaded animations when configured).
local poses = {}
local function motor(model: Model, partName: string, motorName: string): Motor6D?
	local part = model:FindFirstChild(partName)
	return part and part:FindFirstChild(motorName) :: Motor6D?
end

function NPC.Pose(model: Model, pose: string?)
	local right = motor(model, "RightUpperArm", "RightShoulder")
	local left = motor(model, "LeftUpperArm", "LeftShoulder")
	if not right or not left then
		return
	end
	local base = poses[model]
	if not base then
		base = { R = right.C0, L = left.C0 }
		poses[model] = base
		model.Destroying:Connect(function()
			poses[model] = nil
		end)
	end
	local animKey = if pose == "ArmsUp"
		then "PassengerScanPose"
		elseif pose == "HandOver" then "PassengerHandOver"
		elseif pose == "PlaceBag" then "PassengerPlaceBag"
		else nil
	if animKey and Config.Animations[animKey] ~= 0 then
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if animator then
			local track = animator:LoadAnimation(animation(Config.Animations[animKey]))
			track.Priority = Enum.AnimationPriority.Action
			track:Play()
			return
		end
	end
	if pose == "ArmsUp" then
		right.C0 = base.R * CFrame.Angles(math.rad(170), 0, math.rad(-10))
		left.C0 = base.L * CFrame.Angles(math.rad(170), 0, math.rad(10))
	elseif pose == "HandOver" then
		right.C0 = base.R * CFrame.Angles(math.rad(75), 0, math.rad(10))
		left.C0 = base.L
	elseif pose == "PlaceBag" then
		right.C0 = base.R * CFrame.Angles(math.rad(50), 0, 0)
		left.C0 = base.L
	else
		right.C0 = base.R
		left.C0 = base.L
	end
end

function NPC.Say(model: Model, text: string)
	local head = model:FindFirstChild("Head")
	if head then
		Remotes.Speech:FireAllClients(head, text)
	end
end

-- The thing that comes out when the lights go out.
function NPC.Monster(cf: CFrame, parent: Instance): Model
	local desc = Instance.new("HumanoidDescription")
	local black = Color3.fromRGB(14, 14, 18)
	desc.HeadColor = Color3.fromRGB(200, 200, 205)
	desc.LeftArmColor = black
	desc.RightArmColor = black
	desc.TorsoColor = black
	desc.LeftLegColor = black
	desc.RightLegColor = black
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		model = Instance.new("Model")
	end
	model.Name = "TheThing"
	local animateScript = model:FindFirstChild("Animate")
	if animateScript then
		animateScript:Destroy()
	end
	local head = model:FindFirstChild("Head") :: BasePart?
	local face = head and head:FindFirstChildOfClass("Decal")
	if face then
		face:Destroy()
	end
	-- Hollow eyes, a stretched mouth, claws and spines
	if head then
		for _, x in { -0.22, 0.22 } do
			local eye = add(
				model,
				head,
				Vector3.new(0.28, 0.36, 0.08),
				CFrame.new(x, 0.15, -0.58),
				Color3.fromRGB(255, 255, 255),
				Enum.Material.Neon
			)
			if eye then
				local light = Instance.new("PointLight")
				light.Color = Color3.fromRGB(255, 255, 255)
				light.Range = 7
				light.Brightness = 1.5
				light.Parent = eye
			end
		end
		add(model, head, Vector3.new(0.75, 0.6, 0.08), CFrame.new(0, -0.32, -0.58), Color3.fromRGB(30, 0, 0), Enum.Material.SmoothPlastic)
		for i = -3, 3 do
			add(model, head, Vector3.new(0.06, 0.16, 0.05), CFrame.new(i * 0.1, -0.08, -0.62), Color3.fromRGB(240, 236, 220))
			add(model, head, Vector3.new(0.06, 0.16, 0.05), CFrame.new(i * 0.1, -0.56, -0.62), Color3.fromRGB(240, 236, 220))
		end
	end
	for _, handName in { "LeftHand", "RightHand" } do
		local hand = model:FindFirstChild(handName) :: BasePart?
		for k = -1, 1 do
			if hand then
				local claw = Instance.new("WedgePart")
				claw.Size = Vector3.new(0.1, 1.1, 0.25)
				claw.Color = Color3.fromRGB(230, 226, 210)
				claw.Parent = model
				weld(claw, hand, CFrame.new(k * 0.15, -0.8, -0.1) * CFrame.Angles(math.rad(-10), 0, 0))
			end
		end
	end
	local upper = model:FindFirstChild("UpperTorso") :: BasePart?
	for i = 0, 4 do
		if upper then
			local spine = Instance.new("WedgePart")
			spine.Size = Vector3.new(0.12, 0.5, 0.45)
			spine.Color = Color3.fromRGB(200, 196, 186)
			spine.Parent = model
			weld(spine, upper, CFrame.new(0, 0.7 - i * 0.35, 0.6))
		end
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.WalkSpeed = Config.LightsOut.MonsterSpeed
		humanoid.BreakJointsOnDeath = false
	end
	pcall(function()
		model:ScaleTo(1.45)
	end)
	ProBody.Apply(model, "Monster") -- Blender monster body, when imported
	model:PivotTo(cf + Vector3.new(0, 4, 0))
	model.Parent = parent
	setGroup(model, "NPC")
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		hrp:SetNetworkOwner(nil)
	end
	if humanoid then
		animate(
			model,
			if Config.Animations.MonsterRun ~= 0 then Config.Animations.MonsterRun else DEFAULT_ANIMS.Run,
			if Config.Animations.MonsterIdle ~= 0 then Config.Animations.MonsterIdle else DEFAULT_ANIMS.Idle,
			16
		)
	end
	model:SetAttribute("Monster", true)
	game:GetService("CollectionService"):AddTag(model, "Monster")
	return model
end

-- An NPC for the supervisor portrait (cloned into ViewportFrames on clients).
function NPC.Supervisor(parent: Instance): Model?
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = Color3.fromRGB(234, 196, 164)
	desc.TorsoColor = Color3.fromRGB(30, 46, 100)
	desc.LeftArmColor = Color3.fromRGB(30, 46, 100)
	desc.RightArmColor = Color3.fromRGB(30, 46, 100)
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok or not model then
		return nil
	end
	model.Name = "Supervisor"
	local pro = ProBody.Apply(model, "SkinStandard")
	local head = model:FindFirstChild("Head") :: BasePart?
	if head and not pro then
		add(model, head, Vector3.new(1.35, 0.45, 1.35), CFrame.new(0, 0.62, 0), Color3.fromRGB(20, 26, 50), Enum.Material.Fabric)
		add(model, head, Vector3.new(1.3, 0.1, 0.7), CFrame.new(0, 0.42, -0.75), Color3.fromRGB(10, 10, 14))
		add(model, head, Vector3.new(0.5, 0.3, 0.05), CFrame.new(0, 0.66, -0.68), Color3.fromRGB(230, 190, 60), Enum.Material.Metal)
	end
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
		end
	end
	model.Parent = parent
	return model
end

return NPC
