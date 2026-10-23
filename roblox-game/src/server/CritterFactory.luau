-- Builds a critter model out of parts (no uploaded meshes needed).
-- Swap this for real meshes later to make the game look even better.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Critters = require(Shared.Critters)
local Format = require(Shared.Format)

local CritterFactory = {}

local function newPart(props)
	local part = Instance.new("Part")
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic
	part.CanCollide = false
	for key, value in props do
		part[key] = value
	end
	return part
end

local function label(parent, name, text, color, order, height)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.LayoutOrder = order
	l.Size = UDim2.new(1, 0, 0, height or 20)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextColor3 = color
	l.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = l
	l.Parent = parent
	return l
end

-- Height from the ground to the body's center.
function CritterFactory.GroundOffset(def): number
	return def.Size * 0.6
end

-- opts.Price: show a price tag; opts.Accum: show the collected-cash label.
-- Returns the model and a table of labels.
function CritterFactory.Build(id: string, mutation: string?, opts)
	opts = opts or {}
	mutation = mutation or "None"
	local def = Critters.ById[id]
	local rarity = Critters.Rarities[def.Rarity]
	local mut = Critters.Mutations[mutation]
	local s = def.Size

	local model = Instance.new("Model")
	model.Name = def.Name
	model:SetAttribute("CritterId", id)
	model:SetAttribute("Mutation", mutation)

	local body = newPart({
		Name = "Body",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(s, s, s),
		Color = def.Color,
		Anchored = true,
	})
	body.Parent = model
	model.PrimaryPart = body

	local function attach(part, offset)
		part.Anchored = false
		part.Massless = true
		part.CFrame = body.CFrame * offset
		part.Parent = model
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = part
		weld.Parent = part
		return part
	end

	local accents = {}
	for _, x in { -1, 1 } do
		attach(
			newPart({ Shape = Enum.PartType.Ball, Size = Vector3.one * s * 0.3, Color = Color3.new(1, 1, 1) }),
			CFrame.new(x * s * 0.2, s * 0.12, -s * 0.38)
		)
		attach(
			newPart({ Shape = Enum.PartType.Ball, Size = Vector3.one * s * 0.15, Color = Color3.new(0.05, 0.05, 0.05) }),
			CFrame.new(x * s * 0.2, s * 0.12, -s * 0.52)
		)
		table.insert(
			accents,
			attach(
				newPart({ Size = Vector3.new(s * 0.18, s * 0.38, s * 0.18), Color = def.Accent }),
				CFrame.new(x * s * 0.27, s * 0.5, 0) * CFrame.Angles(0, 0, -x * 0.35)
			)
		)
		table.insert(
			accents,
			attach(
				newPart({ Size = Vector3.new(s * 0.22, s * 0.2, s * 0.3), Color = def.Accent }),
				CFrame.new(x * s * 0.22, -s * 0.5, -s * 0.05)
			)
		)
	end
	-- Little smile
	attach(
		newPart({ Size = Vector3.new(s * 0.24, s * 0.05, s * 0.05), Color = Color3.new(0.1, 0.05, 0.05) }),
		CFrame.new(0, -s * 0.12, -s * 0.48)
	)

	if rarity.Order >= 5 then
		local halo = attach(
			newPart({
				Name = "Halo",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.25, s * 0.7, s * 0.7),
				Color = rarity.Color,
				Material = Enum.Material.Neon,
				Transparency = 0.2,
			}),
			CFrame.new(0, s * 0.85, 0) * CFrame.Angles(0, 0, math.rad(90))
		)
		local light = Instance.new("PointLight")
		light.Color = rarity.Color
		light.Range = 12
		light.Parent = halo
	end
	if rarity.Order >= 6 then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = rarity.Color
		sparkles.Parent = body
	end

	if mutation ~= "None" and mut then
		for _, part in { body, table.unpack(accents) } do
			if mut.Color then
				part.Color = if part == body then mut.Color else mut.Color:Lerp(Color3.new(0, 0, 0), 0.25)
			end
			part.Material = mut.Material or part.Material
			if mutation == "Diamond" then
				part.Transparency = 0.15
				part.Reflectance = 0.3
			end
			if mutation == "Rainbow" then
				CollectionService:AddTag(part, "Rainbow")
			end
		end
		if mutation == "Moonlit" then
			local light = Instance.new("PointLight")
			light.Color = mut.Color
			light.Range = 10
			light.Parent = body
		end
	end

	-- Name tag
	local gui = Instance.new("BillboardGui")
	gui.Name = "Info"
	local lines = 3 + (if opts.Price then 1 else 0) + (if opts.Accum then 1 else 0)
	gui.Size = UDim2.fromOffset(200, lines * 22)
	gui.StudsOffsetWorldSpace = Vector3.new(0, s * 0.5 + 1.5 + lines * 0.45, 0)
	gui.MaxDistance = 70
	gui.LightInfluence = 0
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = gui

	local labels = {}
	local nameColor = if mut and mut.Color then mut.Color else Color3.new(1, 1, 1)
	labels.Name = label(gui, "Name", Critters.DisplayName(id, mutation), nameColor, 1, 24)
	if mutation == "Rainbow" then
		CollectionService:AddTag(labels.Name, "RainbowText")
	end
	labels.Rarity = label(gui, "Rarity", def.Rarity, rarity.Color, 2)
	labels.Income = label(gui, "Income", Format.Cash(Critters.Income(id, mutation)) .. "/s", Color3.fromRGB(110, 255, 120), 3)
	if opts.Price then
		labels.Price = label(gui, "Price", Format.Cash(opts.Price), Color3.fromRGB(255, 225, 90), 4)
	end
	if opts.Accum then
		labels.Accum = label(gui, "Accum", "💰 $0", Color3.fromRGB(255, 255, 255), 5)
	end
	gui.Parent = body

	return model, labels
end

return CritterFactory
