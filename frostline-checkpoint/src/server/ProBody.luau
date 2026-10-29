-- Blender-made bodies (officer skins, passengers, the monster) worn over a Roblox R15 rig.
-- The imported pieces are named <Owner>_<BodyPart>_<Role or n> and come with three anchors
-- (<Owner>_AnchorA/B/C) that mark the modelling frame, so any scale/rotation the importer applied
-- is undone here. Each piece is welded to its body part, so normal R15 animations move it.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProBody = {}

-- Reference R15 body the pieces were modelled on (centre relative to UpperTorso, size). Must match
-- models/source/characters.py.
local REF = {
	Head = { Vector3.new(0, 1.45, 0), Vector3.new(1.2, 1.2, 1.2) },
	UpperTorso = { Vector3.new(0, 0, 0), Vector3.new(2, 1.6, 1) },
	LowerTorso = { Vector3.new(0, -1.0, 0), Vector3.new(2, 0.4, 1) },
	LeftUpperArm = { Vector3.new(-1.5, 0.215, 0), Vector3.new(1, 1.17, 1) },
	RightUpperArm = { Vector3.new(1.5, 0.215, 0), Vector3.new(1, 1.17, 1) },
	LeftLowerArm = { Vector3.new(-1.5, -0.895, 0), Vector3.new(1, 1.05, 1) },
	RightLowerArm = { Vector3.new(1.5, -0.895, 0), Vector3.new(1, 1.05, 1) },
	LeftHand = { Vector3.new(-1.5, -1.57, 0), Vector3.new(1, 0.3, 1) },
	RightHand = { Vector3.new(1.5, -1.57, 0), Vector3.new(1, 0.3, 1) },
	LeftUpperLeg = { Vector3.new(-0.5, -1.81, 0), Vector3.new(1, 1.215, 1) },
	RightUpperLeg = { Vector3.new(0.5, -1.81, 0), Vector3.new(1, 1.215, 1) },
	LeftLowerLeg = { Vector3.new(-0.5, -3.02, 0), Vector3.new(1, 1.2, 1) },
	RightLowerLeg = { Vector3.new(0.5, -3.02, 0), Vector3.new(1, 1.2, 1) },
	LeftFoot = { Vector3.new(-0.5, -3.77, 0), Vector3.new(1, 0.3, 1) },
	RightFoot = { Vector3.new(0.5, -3.77, 0), Vector3.new(1, 0.3, 1) },
}

local cache = {} -- [owner] = set | false

local function findPart(folder: Instance, name: string): BasePart?
	local found = folder:FindFirstChild(name, true)
	return if found and found:IsA("BasePart") then found else nil
end

-- Reads the imported pieces for an owner (e.g. "SkinPlague", "Civilian", "Monster") once.
function ProBody.Set(owner: string)
	if cache[owner] ~= nil then
		return cache[owner] or nil
	end
	local folder = ReplicatedStorage:FindFirstChild("ProModels")
	local a = folder and findPart(folder, owner .. "_AnchorA")
	local b = folder and findPart(folder, owner .. "_AnchorB")
	local c = folder and findPart(folder, owner .. "_AnchorC")
	if not (folder and a and b and c) then
		cache[owner] = false
		return nil
	end
	local origin = a.Position
	local up = b.Position - origin
	local right = c.Position - origin
	local studs = up.Magnitude / 10 -- importer scale
	local frame = CFrame.fromMatrix(origin, right.Unit, up.Unit)
	local pieces = {}
	local prefix = owner .. "_"
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") and string.sub(d.Name, 1, #prefix) == prefix and not string.find(d.Name, "_Anchor", 1, true) then
			local rest = string.sub(d.Name, #prefix + 1)
			local body, role = string.match(rest, "^(%a+)_(.+)$")
			if body and REF[body] then
				local inFrame = frame:ToObjectSpace(d.CFrame)
				local pos = inFrame.Position / studs
				table.insert(pieces, {
					Template = d,
					Body = body,
					Role = role,
					Rel = CFrame.new(pos - REF[body][1]) * inFrame.Rotation,
					Size = d.Size / studs,
				})
			end
		end
	end
	local set = if #pieces > 0 then { Pieces = pieces } else false
	cache[owner] = set
	return set or nil
end

function ProBody.Has(owner: string): boolean
	return ProBody.Set(owner) ~= nil
end

local function hide(d: Instance)
	if d:IsA("BasePart") or d:IsA("Decal") then
		if d:GetAttribute("ProBodyT") == nil then
			d:SetAttribute("ProBodyT", (d :: any).Transparency)
		end
		(d :: any).Transparency = 1
	end
end

-- Hides the blocky body parts, their faces and worn accessories (not carried things like the suitcase).
local function hideOriginal(model: Model)
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
			hide(child)
			for _, d in child:GetChildren() do
				hide(d)
			end
		elseif child:IsA("Accessory") or (child:IsA("Folder") and (child.Name == "Hair" or child.Name == "SkinParts")) then
			for _, d in child:GetDescendants() do
				hide(d)
			end
		end
	end
end

function ProBody.Remove(model: Model)
	local old = model:FindFirstChild("ProBody")
	if old then
		old:Destroy()
	end
	for _, d in model:GetDescendants() do
		local t = d:GetAttribute("ProBodyT")
		if t ~= nil and (d:IsA("BasePart") or d:IsA("Decal")) then
			d.Transparency = t
			d:SetAttribute("ProBodyT", nil)
		end
	end
end

-- Dresses `model` (an R15 character, NPC or mannequin) in the owner's Blender body.
-- tints: optional { [role] = Color3 } (e.g. Skin, Shirt, Pants, Hair); hair: the one Hair* role to show.
-- Returns true when applied (false = no imported pieces; the caller falls back to its own look).
function ProBody.Apply(model: Model, owner: string, tints: { [string]: Color3 }?, hair: string?): boolean
	local set = ProBody.Set(owner)
	if not set then
		return false
	end
	ProBody.Remove(model)
	local folder = Instance.new("Folder")
	folder.Name = "ProBody"
	folder.Parent = model
	for _, piece in set.Pieces do
		local role = piece.Role
		if string.sub(role, 1, 4) == "Hair" and role ~= hair then
			continue
		end
		local bodyPart = model:FindFirstChild(piece.Body) :: BasePart?
		if not bodyPart then
			continue
		end
		local ratio = bodyPart.Size / REF[piece.Body][2]
		local localRatio = piece.Rel.Rotation:VectorToObjectSpace(ratio)
		localRatio = Vector3.new(math.abs(localRatio.X), math.abs(localRatio.Y), math.abs(localRatio.Z))
		local clone = piece.Template:Clone()
		clone.Size = piece.Size * localRatio
		clone.CFrame = bodyPart.CFrame * CFrame.new(piece.Rel.Position * ratio) * piece.Rel.Rotation
		clone.Anchored = bodyPart.Anchored
		clone.CanCollide = false
		clone.CanQuery = false
		clone.CanTouch = false
		clone.Massless = true
		clone.Transparency = 0
		if tints then
			local key = if string.sub(role, 1, 4) == "Hair" then "Hair" else role
			if tints[key] then
				clone.Color = tints[key]
			end
		end
		if not bodyPart.Anchored then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = bodyPart
			weld.Part1 = clone
			weld.Parent = clone
		end
		clone.Parent = folder
	end
	hideOriginal(model)
	return true
end

return ProBody
