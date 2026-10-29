-- Dresses an R15 character (or a lobby mannequin with R15 part names) in an officer skin made of parts.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local SkinLook = {}

local function find(key: string)
	for _, skin in Config.Skins do
		if skin.Key == key then
			return skin
		end
	end
	return Config.Skins[1]
end
SkinLook.Find = find

local function weld(part: BasePart, to: BasePart, offset: CFrame)
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CFrame = to.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = part
	w.Parent = part
end

local function piece(
	folder: Instance,
	to: BasePart?,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	material: Enum.Material?,
	shape: Enum.PartType?
)
	if not to then
		return nil
	end
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.Fabric
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Parent = folder
	weld(p, to, offset)
	return p
end

local HATS = {}
function HATS.Cap(f, head, skin)
	piece(f, head, Vector3.new(1.35, 0.45, 1.35), CFrame.new(0, 0.62, 0), skin.Coat)
	piece(f, head, Vector3.new(1.3, 0.1, 0.7), CFrame.new(0, 0.42, -0.75), skin.Coat:Lerp(Color3.new(), 0.4))
	piece(f, head, Vector3.new(0.35, 0.3, 0.05), CFrame.new(0, 0.66, -0.68), skin.Trim, Enum.Material.Metal)
end
function HATS.Peaked(f, head, skin)
	piece(
		f,
		head,
		Vector3.new(0.35, 1.7, 1.7),
		CFrame.new(0, 0.85, 0) * CFrame.Angles(0, 0, math.pi / 2),
		skin.Coat,
		nil,
		Enum.PartType.Cylinder
	)
	piece(f, head, Vector3.new(1.3, 0.3, 1.3), CFrame.new(0, 0.6, 0), skin.Coat)
	piece(f, head, Vector3.new(1.35, 0.12, 1.35), CFrame.new(0, 0.62, 0), skin.Trim, Enum.Material.Metal)
	piece(
		f,
		head,
		Vector3.new(1.3, 0.1, 0.6),
		CFrame.new(0, 0.45, -0.75) * CFrame.Angles(math.rad(-12), 0, 0),
		Color3.fromRGB(20, 20, 20),
		Enum.Material.SmoothPlastic
	)
end
function HATS.Ushanka(f, head, skin)
	piece(f, head, Vector3.new(1.5, 0.6, 1.5), CFrame.new(0, 0.6, 0.05), Color3.fromRGB(240, 240, 240), Enum.Material.Fabric)
	for _, x in { -0.78, 0.78 } do
		piece(f, head, Vector3.new(0.18, 0.8, 1), CFrame.new(x, 0.05, 0.05), Color3.fromRGB(240, 240, 240), Enum.Material.Fabric)
	end
	piece(f, head, Vector3.new(0.4, 0.4, 0.05), CFrame.new(0, 0.65, -0.73), skin.Trim, Enum.Material.Metal)
end
function HATS.PlagueMask(f, head, skin)
	piece(
		f,
		head,
		Vector3.new(1.25, 1.25, 1.25),
		CFrame.new(0, 0, 0),
		Color3.fromRGB(26, 24, 22),
		Enum.Material.Leather,
		Enum.PartType.Ball
	)
	local beak = Instance.new("WedgePart")
	beak.Size = Vector3.new(0.5, 0.6, 1.4)
	beak.Color = Color3.fromRGB(30, 28, 26)
	beak.Material = Enum.Material.Leather
	beak.Parent = f
	weld(beak, head, CFrame.new(0, -0.25, -1.1) * CFrame.Angles(0, math.pi, 0))
	for _, x in { -0.28, 0.28 } do
		piece(
			f,
			head,
			Vector3.new(0.35, 0.35, 0.1),
			CFrame.new(x, 0.12, -0.6),
			Color3.fromRGB(200, 230, 255),
			Enum.Material.Glass,
			Enum.PartType.Ball
		)
	end
	piece(
		f,
		head,
		Vector3.new(0.12, 2.4, 2.4),
		CFrame.new(0, 0.65, 0) * CFrame.Angles(0, 0, math.pi / 2),
		skin.Coat,
		Enum.Material.Leather,
		Enum.PartType.Cylinder
	)
	piece(f, head, Vector3.new(1.3, 0.8, 1.3), CFrame.new(0, 1.05, 0), skin.Coat, Enum.Material.Leather)
end
function HATS.Pumpkin(f, head, _skin)
	local p = piece(
		f,
		head,
		Vector3.new(1.9, 1.6, 1.9),
		CFrame.new(0, 0.1, 0),
		Color3.fromRGB(255, 130, 20),
		Enum.Material.SmoothPlastic,
		Enum.PartType.Ball
	)
	local _ = p
	piece(f, head, Vector3.new(0.2, 0.4, 0.2), CFrame.new(0, 1, 0), Color3.fromRGB(60, 90, 30))
	for _, x in { -0.35, 0.35 } do
		piece(f, head, Vector3.new(0.3, 0.3, 0.05), CFrame.new(x, 0.25, -0.92), Color3.fromRGB(255, 220, 80), Enum.Material.Neon)
	end
	piece(f, head, Vector3.new(0.9, 0.2, 0.05), CFrame.new(0, -0.25, -0.93), Color3.fromRGB(255, 220, 80), Enum.Material.Neon)
end
function HATS.Witch(f, head, skin)
	piece(
		f,
		head,
		Vector3.new(0.1, 2.6, 2.6),
		CFrame.new(0, 0.55, 0) * CFrame.Angles(0, 0, math.pi / 2),
		skin.Coat,
		Enum.Material.Fabric,
		Enum.PartType.Cylinder
	)
	for i = 0, 3 do
		local s = 1.25 - i * 0.28
		piece(f, head, Vector3.new(s, 0.45, s), CFrame.new(0, 0.85 + i * 0.4, 0.05 * i) * CFrame.Angles(math.rad(-6 * i), 0, 0), skin.Coat)
	end
	piece(f, head, Vector3.new(1.3, 0.18, 1.3), CFrame.new(0, 0.7, 0), skin.Trim, Enum.Material.Neon)
end
function HATS.Fangs(f, head, skin)
	-- Slicked hair and a tall collar
	piece(f, head, Vector3.new(1.25, 0.35, 1.25), CFrame.new(0, 0.58, 0.05), Color3.fromRGB(10, 10, 12), Enum.Material.SmoothPlastic)
	local spike = Instance.new("WedgePart")
	spike.Size = Vector3.new(0.3, 0.25, 0.4)
	spike.Color = Color3.fromRGB(10, 10, 12)
	spike.Parent = f
	weld(spike, head, CFrame.new(0, 0.45, -0.55) * CFrame.Angles(math.pi, 0, 0))
	for _, x in { -0.18, 0.18 } do
		piece(f, head, Vector3.new(0.08, 0.16, 0.05), CFrame.new(x, -0.3, -0.6), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
	end
	piece(
		f,
		head,
		Vector3.new(2.2, 1.4, 0.15),
		CFrame.new(0, -0.3, 0.6) * CFrame.Angles(math.rad(-10), 0, 0),
		skin.Trim,
		Enum.Material.Fabric
	)
end
function HATS.Hood(f, head, skin)
	piece(f, head, Vector3.new(1.55, 1.6, 1.55), CFrame.new(0, 0.15, 0.12), skin.Coat, Enum.Material.Fabric, Enum.PartType.Ball)
	piece(f, head, Vector3.new(1.0, 1.0, 0.1), CFrame.new(0, -0.05, -0.58), Color3.fromRGB(5, 8, 14), Enum.Material.SmoothPlastic)
	for _, x in { -0.22, 0.22 } do
		piece(f, head, Vector3.new(0.18, 0.12, 0.05), CFrame.new(x, 0.08, -0.65), skin.Trim, Enum.Material.Neon)
	end
end

-- Remove any skin we added before.
function SkinLook.Clear(model: Model)
	local old = model:FindFirstChild("SkinParts")
	if old then
		old:Destroy()
	end
end

function SkinLook.Apply(model: Model, key: string)
	SkinLook.Clear(model)
	local skin = find(key)
	local folder = Instance.new("Folder")
	folder.Name = "SkinParts"
	folder.Parent = model
	local upper = model:FindFirstChild("UpperTorso") :: BasePart?
	local lower = model:FindFirstChild("LowerTorso") :: BasePart?
	local head = model:FindFirstChild("Head") :: BasePart?
	if not upper then
		return
	end
	local us = upper.Size
	-- Coat over the torso
	piece(folder, upper, us + Vector3.new(0.14, 0.1, 0.14), CFrame.new(0, 0, 0), skin.Coat)
	if lower then
		piece(folder, lower, lower.Size + Vector3.new(0.16, 0.2, 0.16), CFrame.new(0, 0.05, 0), skin.Coat)
		piece(
			folder,
			lower,
			Vector3.new(lower.Size.X + 0.2, 0.18, lower.Size.Z + 0.2),
			CFrame.new(0, 0.2, 0),
			Color3.fromRGB(26, 22, 20),
			Enum.Material.Leather
		)
		piece(folder, lower, Vector3.new(0.3, 0.22, 0.05), CFrame.new(0, 0.2, -lower.Size.Z / 2 - 0.11), skin.Trim, Enum.Material.Metal)
	end
	-- Collar, trim stripe, badge, shoulder boards
	piece(folder, upper, Vector3.new(us.X * 0.55, 0.22, us.Z + 0.2), CFrame.new(0, us.Y / 2, 0), skin.Coat:Lerp(Color3.new(), 0.3))
	piece(folder, upper, Vector3.new(0.12, us.Y, 0.05), CFrame.new(0, 0, -us.Z / 2 - 0.09), skin.Trim, Enum.Material.SmoothPlastic)
	piece(
		folder,
		upper,
		Vector3.new(0.32, 0.38, 0.05),
		CFrame.new(-us.X * 0.26, us.Y * 0.18, -us.Z / 2 - 0.1),
		skin.Trim,
		Enum.Material.Metal
	)
	for _, side in { -1, 1 } do
		piece(
			folder,
			upper,
			Vector3.new(0.5, 0.08, 0.6),
			CFrame.new(side * us.X * 0.42, us.Y / 2 + 0.06, 0),
			skin.Trim,
			Enum.Material.Metal
		)
	end
	for _, name in { "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm" } do
		local arm = model:FindFirstChild(name) :: BasePart?
		if arm then
			piece(folder, arm, arm.Size + Vector3.new(0.1, 0.02, 0.1), CFrame.new(), skin.Coat)
		end
	end
	local leftLower = model:FindFirstChild("LeftLowerArm") :: BasePart?
	if leftLower then
		piece(
			folder,
			leftLower,
			Vector3.new(leftLower.Size.X + 0.14, 0.12, leftLower.Size.Z + 0.14),
			CFrame.new(0, -leftLower.Size.Y * 0.3, 0),
			skin.Trim
		)
	end
	if head and HATS[skin.Hat] then
		HATS[skin.Hat](folder, head, skin)
	end
end

-- A standing mannequin with R15 part names (no Humanoid), so Apply works on it.
function SkinLook.Mannequin(parent: Instance, cf: CFrame, key: string): Model
	local m = Instance.new("Model")
	m.Name = "Mannequin"
	local skinTone = Color3.fromRGB(234, 196, 164)
	local function part(name, size, offset, color)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf * offset
		p.Color = color
		p.Anchored = true
		p.Material = Enum.Material.SmoothPlastic
		p.Parent = m
		return p
	end
	part("LeftLowerLeg", Vector3.new(0.9, 1.6, 0.9), CFrame.new(-0.5, 0.8, 0), Color3.fromRGB(30, 30, 36))
	part("RightLowerLeg", Vector3.new(0.9, 1.6, 0.9), CFrame.new(0.5, 0.8, 0), Color3.fromRGB(30, 30, 36))
	part("LeftUpperLeg", Vector3.new(0.9, 1.2, 0.9), CFrame.new(-0.5, 2.2, 0), Color3.fromRGB(34, 36, 44))
	part("RightUpperLeg", Vector3.new(0.9, 1.2, 0.9), CFrame.new(0.5, 2.2, 0), Color3.fromRGB(34, 36, 44))
	part("LowerTorso", Vector3.new(2, 0.6, 1), CFrame.new(0, 3.1, 0), Color3.fromRGB(34, 36, 44))
	part("UpperTorso", Vector3.new(2, 1.6, 1), CFrame.new(0, 4.2, 0), Color3.fromRGB(34, 36, 44))
	part("LeftUpperArm", Vector3.new(0.9, 1.2, 0.9), CFrame.new(-1.45, 4.35, 0), skinTone)
	part("RightUpperArm", Vector3.new(0.9, 1.2, 0.9), CFrame.new(1.45, 4.35, 0), skinTone)
	part("LeftLowerArm", Vector3.new(0.85, 1.1, 0.85), CFrame.new(-1.45, 3.2, 0), skinTone)
	part("RightLowerArm", Vector3.new(0.85, 1.1, 0.85), CFrame.new(1.45, 3.2, 0), skinTone)
	local head = part("Head", Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 5.65, 0), skinTone)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Head
	mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	mesh.Parent = head
	local face = Instance.new("Decal")
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head
	m.PrimaryPart = head
	m.Parent = parent
	SkinLook.Apply(m, key)
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
		end
	end
	return m
end

return SkinLook
