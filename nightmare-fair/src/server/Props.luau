-- A library of carnival props, all built from parts so the game needs no uploaded assets.
-- Every builder takes a CFrame (position + facing) and a parent, and returns what it built.
local CollectionService = game:GetService("CollectionService")

local Props = {}

local rgb = Color3.fromRGB
Props.Colors = {
	red = rgb(190, 35, 45),
	cream = rgb(235, 225, 200),
	purple = rgb(95, 50, 130),
	teal = rgb(40, 140, 140),
	gold = rgb(230, 175, 60),
	wood = rgb(95, 65, 40),
	darkWood = rgb(55, 38, 28),
	iron = rgb(45, 45, 52),
	pumpkin = rgb(240, 120, 25),
}
local C = Props.Colors

local rng = Random.new(1031)

function Props.Part(props, parent)
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		part[key] = value
	end
	part.Parent = parent
	return part
end
local P = Props.Part

function Props.Model(name: string, parent)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

function Props.Light(parent: BasePart, color: Color3, range: number, brightness: number?)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness or 1.5
	light.Shadows = false
	light.Parent = parent
	return light
end

function Props.Sign(part: BasePart, face: Enum.NormalId, text: string, color: Color3, font: Enum.Font?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = font or Enum.Font.Creepster
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Parent = label
	label.Parent = gui
	gui.Parent = part
	return label
end

function Props.Billboard(part: BasePart, text: string, color: Color3, height: number, maxDistance: number?)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(180, 40)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	gui.MaxDistance = maxDistance or 50
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = label
	label.Parent = gui
	gui.Parent = part
	return label
end

-- Makes a model spin on the client (cheap and smooth). Axis is in the model's own space.
function Props.MakeSpin(model: Model, axis: string, speed: number)
	model:SetAttribute("SpinAxis", axis)
	model:SetAttribute("SpinSpeed", speed)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
		end
	end
	CollectionService:AddTag(model, "Spin")
end

-- Small props ------------------------------------------------------------

function Props.Crate(cf: CFrame, parent, size: number?)
	size = size or 4
	local crate = P({
		Name = "Crate",
		Size = Vector3.one * size,
		CFrame = cf * CFrame.new(0, size / 2, 0),
		Color = C.wood,
		Material = Enum.Material.WoodPlanks,
	}, parent)
	return crate
end

function Props.CrateStack(cf: CFrame, parent)
	local model = Props.Model("Crates", parent)
	Props.Crate(cf * CFrame.new(-2.1, 0, 0), model)
	Props.Crate(cf * CFrame.new(2.1, 0, 0) * CFrame.Angles(0, 0.2, 0), model)
	Props.Crate(cf * CFrame.new(0, 4, 0) * CFrame.Angles(0, -0.3, 0), model)
	return model
end

function Props.Barrel(cf: CFrame, parent)
	local barrel = P({
		Name = "Barrel",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4.4, 3.2, 3.2),
		CFrame = cf * CFrame.new(0, 2.2, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.darkWood,
		Material = Enum.Material.Wood,
	}, parent)
	for _, y in { -1.3, 1.3 } do
		P({
			Name = "Hoop",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, 3.35, 3.35),
			CFrame = cf * CFrame.new(0, 2.2 + y, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color = C.iron,
			Material = Enum.Material.Metal,
			CanCollide = false,
		}, parent)
	end
	return barrel
end

function Props.HayBale(cf: CFrame, parent)
	return P({
		Name = "HayBale",
		Size = Vector3.new(5, 2.6, 3),
		CFrame = cf * CFrame.new(0, 1.3, 0),
		Color = rgb(205, 170, 80),
		Material = Enum.Material.Fabric,
	}, parent)
end

function Props.PumpkinPile(cf: CFrame, parent)
	local model = Props.Model("PumpkinPile", parent)
	for i = 1, 5 do
		local s = rng:NextNumber(1.4, 2.6)
		local p = P({
			Name = "Pumpkin",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * s,
			CFrame = cf * CFrame.new(rng:NextNumber(-2.5, 2.5), s / 2, rng:NextNumber(-2.5, 2.5)),
			Color = C.pumpkin,
			CanCollide = false,
		}, model)
		if i == 1 then
			P({
				Name = "Face",
				Size = Vector3.new(s * 0.5, s * 0.25, 0.1),
				CFrame = p.CFrame * CFrame.new(0, 0, -s * 0.48),
				Color = rgb(255, 210, 80),
				Material = Enum.Material.Neon,
				CanCollide = false,
			}, model)
			Props.Light(p, rgb(255, 150, 40), 10, 1)
		end
	end
	return model
end

function Props.Scarecrow(cf: CFrame, parent)
	local model = Props.Model("Scarecrow", parent)
	P({
		Name = "Pole",
		Size = Vector3.new(0.5, 9, 0.5),
		CFrame = cf * CFrame.new(0, 4.5, 0),
		Color = C.darkWood,
		Material = Enum.Material.Wood,
	}, model)
	P({
		Name = "Arms",
		Size = Vector3.new(6, 0.4, 0.4),
		CFrame = cf * CFrame.new(0, 6.6, 0),
		Color = C.darkWood,
		Material = Enum.Material.Wood,
		CanCollide = false,
	}, model)
	P({
		Name = "Shirt",
		Size = Vector3.new(2.4, 3, 1.2),
		CFrame = cf * CFrame.new(0, 5.6, 0),
		Color = rgb(120, 70, 50),
		Material = Enum.Material.Fabric,
		CanCollide = false,
	}, model)
	local head = P({
		Name = "Head",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 2,
		CFrame = cf * CFrame.new(0, 8.1, 0),
		Color = rgb(200, 180, 140),
		Material = Enum.Material.Fabric,
		CanCollide = false,
	}, model)
	for _, x in { -0.35, 0.35 } do
		P({
			Name = "Eye",
			Size = Vector3.new(0.3, 0.3, 0.1),
			CFrame = head.CFrame * CFrame.new(x, 0.15, -0.95),
			Color = rgb(255, 40, 40),
			Material = Enum.Material.Neon,
			CanCollide = false,
		}, model)
	end
	P({
		Name = "Hat",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 3.2, 3.2),
		CFrame = cf * CFrame.new(0, 9, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = rgb(50, 40, 30),
		CanCollide = false,
	}, model)
	return model
end

function Props.Tombstone(cf: CFrame, parent)
	local stone = P({
		Name = "Tombstone",
		Size = Vector3.new(2.4, 3.2, 0.7),
		CFrame = cf * CFrame.new(0, 1.6, 0) * CFrame.Angles(math.rad(rng:NextNumber(-8, 8)), 0, math.rad(rng:NextNumber(-5, 5))),
		Color = rgb(105, 105, 115),
		Material = Enum.Material.Slate,
	}, parent)
	Props.Sign(stone, Enum.NormalId.Front, "R.I.P", rgb(40, 40, 45))
	return stone
end

function Props.DeadTree(cf: CFrame, parent)
	local model = Props.Model("DeadTree", parent)
	local height = rng:NextNumber(14, 24)
	local trunk = P({
		Name = "Trunk",
		Size = Vector3.new(2, height, 2),
		CFrame = cf
			* CFrame.new(0, height / 2, 0)
			* CFrame.Angles(math.rad(rng:NextNumber(-4, 4)), rng:NextNumber(0, 6), math.rad(rng:NextNumber(-4, 4))),
		Color = rgb(40, 32, 28),
		Material = Enum.Material.Wood,
	}, model)
	for _ = 1, rng:NextInteger(3, 5) do
		local length = rng:NextNumber(5, 10)
		local base = trunk.CFrame.Position + Vector3.new(0, rng:NextNumber(0, height / 2), 0)
		P({
			Name = "Branch",
			Size = Vector3.new(0.7, length, 0.7),
			CFrame = CFrame.new(base)
				* CFrame.Angles(0, rng:NextNumber(0, 6.28), math.rad(rng:NextNumber(35, 70)))
				* CFrame.new(0, length / 2, 0),
			Color = rgb(40, 32, 28),
			Material = Enum.Material.Wood,
			CanCollide = false,
		}, model)
	end
	return model
end

function Props.LampPost(cf: CFrame, parent)
	local model = Props.Model("LampPost", parent)
	P({
		Name = "Post",
		Size = Vector3.new(0.7, 13, 0.7),
		CFrame = cf * CFrame.new(0, 6.5, 0),
		Color = C.iron,
		Material = Enum.Material.Metal,
	}, model)
	P({
		Name = "Arm",
		Size = Vector3.new(0.4, 0.4, 2.5),
		CFrame = cf * CFrame.new(0, 12.6, -1),
		Color = C.iron,
		Material = Enum.Material.Metal,
		CanCollide = false,
	}, model)
	local bulb = P({
		Name = "Bulb",
		Size = Vector3.new(1.4, 1.6, 1.4),
		CFrame = cf * CFrame.new(0, 11.9, -2),
		Color = rgb(255, 210, 140),
		Material = Enum.Material.Neon,
		CanCollide = false,
	}, model)
	Props.Light(bulb, rgb(255, 190, 120), 26, 1.6)
	return model
end

-- A droopy line of colored bulbs between two points.
function Props.StringLights(a: Vector3, b: Vector3, parent, count: number?)
	count = count or 10
	local colors = { rgb(255, 80, 80), rgb(255, 200, 60), rgb(90, 220, 120), rgb(110, 160, 255), rgb(220, 110, 255) }
	for i = 0, count do
		local t = i / count
		local sag = math.sin(t * math.pi) * 2.5
		local pos = a:Lerp(b, t) - Vector3.new(0, sag, 0)
		local bulb = P({
			Name = "Bulb",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.7,
			Position = pos,
			Color = colors[i % #colors + 1],
			Material = Enum.Material.Neon,
			CanCollide = false,
			CanQuery = false,
		}, parent)
		if i % 4 == 0 then
			Props.Light(bulb, bulb.Color, 10, 0.8)
		end
	end
end

function Props.Fence(a: Vector3, b: Vector3, parent, height: number?)
	height = height or 16
	local mid = (a + b) / 2
	local length = (b - a).Magnitude
	local cf = CFrame.lookAt(mid, b) * CFrame.Angles(0, math.rad(90), 0)
	local wall = P({
		Name = "Fence",
		Size = Vector3.new(length, height, 1.2),
		CFrame = cf + Vector3.new(0, height / 2, 0),
		Color = rgb(70, 50, 35),
		Material = Enum.Material.WoodPlanks,
	}, parent)
	for i = 0, math.floor(length / 10) do
		local pos = a:Lerp(b, math.min(1, i * 10 / length))
		P({
			Name = "Post",
			Size = Vector3.new(1.6, height + 2, 1.6),
			Position = pos + Vector3.new(0, (height + 2) / 2, 0),
			Color = rgb(45, 32, 25),
			Material = Enum.Material.Wood,
		}, parent)
	end
	return wall
end

-- Medium props ------------------------------------------------------------

local BOOTH_GAMES =
	{ "RING TOSS", "DUCK SHOOT", "WHACK-A-GHOUL", "FORTUNES", "TEST YOUR NERVE", "BALLOON POP", "SKEE-BONE", "CANDY APPLES" }

function Props.Booth(cf: CFrame, parent, colorA: Color3?, title: string?)
	local model = Props.Model("Booth", parent)
	colorA = colorA or C.red
	local colorB = C.cream
	P({
		Name = "Floor",
		Size = Vector3.new(12, 0.6, 8),
		CFrame = cf * CFrame.new(0, 0.3, 0),
		Color = C.darkWood,
		Material = Enum.Material.WoodPlanks,
	}, model)
	P({
		Name = "Back",
		Size = Vector3.new(12, 9, 0.6),
		CFrame = cf * CFrame.new(0, 4.5, 3.7),
		Color = colorA,
		Material = Enum.Material.WoodPlanks,
	}, model)
	for _, x in { -5.7, 5.7 } do
		P({
			Name = "Side",
			Size = Vector3.new(0.6, 9, 8),
			CFrame = cf * CFrame.new(x, 4.5, 0),
			Color = colorB,
			Material = Enum.Material.WoodPlanks,
		}, model)
	end
	P({
		Name = "Counter",
		Size = Vector3.new(11, 3.6, 1.4),
		CFrame = cf * CFrame.new(0, 1.8, -3.2),
		Color = colorA,
		Material = Enum.Material.WoodPlanks,
	}, model)
	P({ Name = "CounterTop", Size = Vector3.new(12, 0.4, 2), CFrame = cf * CFrame.new(0, 3.7, -3.2), Color = C.gold }, model)
	-- Striped awning
	for i = 0, 5 do
		P({
			Name = "Awning",
			Size = Vector3.new(2, 0.3, 5),
			CFrame = cf * CFrame.new(-5 + i * 2, 9.8, -4.2) * CFrame.Angles(math.rad(25), 0, 0),
			Color = if i % 2 == 0 then colorA else colorB,
			Material = Enum.Material.Fabric,
			CanCollide = false,
		}, model)
	end
	P({ Name = "Roof", Size = Vector3.new(12.4, 0.6, 8.4), CFrame = cf * CFrame.new(0, 9.3, 0), Color = colorA }, model)
	local sign = P({ Name = "SignBoard", Size = Vector3.new(10, 2.4, 0.4), CFrame = cf * CFrame.new(0, 11.4, -2), Color = C.purple }, model)
	Props.Sign(sign, Enum.NormalId.Front, title or BOOTH_GAMES[rng:NextInteger(1, #BOOTH_GAMES)], C.gold)
	-- Prizes on shelves
	P({ Name = "Shelf", Size = Vector3.new(10, 0.3, 1.2), CFrame = cf * CFrame.new(0, 5.5, 3), Color = C.darkWood }, model)
	for i = 0, 6 do
		P({
			Name = "Prize",
			Shape = if i % 2 == 0 then Enum.PartType.Ball else Enum.PartType.Block,
			Size = Vector3.one * 1.1,
			CFrame = cf * CFrame.new(-4.2 + i * 1.4, 6.3, 3),
			Color = Color3.fromHSV(rng:NextNumber(), 0.6, 0.9),
			CanCollide = false,
		}, model)
	end
	local bulbs = P({
		Name = "Glow",
		Size = Vector3.new(11, 0.3, 0.3),
		CFrame = cf * CFrame.new(0, 8.7, -3.9),
		Color = rgb(255, 220, 140),
		Material = Enum.Material.Neon,
		CanCollide = false,
	}, model)
	Props.Light(bulbs, rgb(255, 200, 120), 16, 1.2)
	return model
end

function Props.TicketBooth(cf: CFrame, parent)
	local model = Props.Model("TicketBooth", parent)
	P(
		{
			Name = "Body",
			Size = Vector3.new(7, 8, 7),
			CFrame = cf * CFrame.new(0, 4, 0),
			Color = C.red,
			Material = Enum.Material.WoodPlanks,
		},
		model
	)
	P({
		Name = "Window",
		Size = Vector3.new(4, 3, 0.2),
		CFrame = cf * CFrame.new(0, 5, -3.55),
		Color = rgb(255, 200, 90),
		Material = Enum.Material.Neon,
	}, model)
	P({ Name = "Roof", Shape = Enum.PartType.Ball, Size = Vector3.new(9, 9, 9), CFrame = cf * CFrame.new(0, 8, 0), Color = C.gold }, model)
	local sign = P({ Name = "Sign", Size = Vector3.new(6, 1.6, 0.3), CFrame = cf * CFrame.new(0, 7.2, -3.7), Color = C.purple }, model)
	Props.Sign(sign, Enum.NormalId.Front, "TICKETS", C.gold)
	return model
end

function Props.PopcornCart(cf: CFrame, parent)
	local model = Props.Model("PopcornCart", parent)
	P({ Name = "Cart", Size = Vector3.new(5, 3, 3), CFrame = cf * CFrame.new(0, 2.5, 0), Color = C.red }, model)
	P({
		Name = "Glass",
		Size = Vector3.new(4.4, 3, 2.6),
		CFrame = cf * CFrame.new(0, 5.5, 0),
		Color = rgb(255, 240, 200),
		Material = Enum.Material.Glass,
		Transparency = 0.4,
	}, model)
	P({
		Name = "Corn",
		Size = Vector3.new(4.2, 1.2, 2.4),
		CFrame = cf * CFrame.new(0, 4.6, 0),
		Color = rgb(255, 235, 160),
		Material = Enum.Material.Pebble,
		CanCollide = false,
	}, model)
	P({ Name = "Top", Size = Vector3.new(5.4, 0.6, 3.4), CFrame = cf * CFrame.new(0, 7.3, 0), Color = C.red }, model)
	for _, x in { -2, 2 } do
		P({
			Name = "Wheel",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.4, 2.2, 2.2),
			CFrame = cf * CFrame.new(x, 1.1, -1.6) * CFrame.Angles(0, math.rad(90), 0),
			Color = C.iron,
		}, model)
	end
	return model
end

-- Big landmarks -----------------------------------------------------------

function Props.FerrisWheel(cf: CFrame, parent)
	local model = Props.Model("FerrisWheel", parent)
	local radius, hubHeight = 28, 33
	local hub = cf * CFrame.new(0, hubHeight, 0)
	-- Supports (static)
	for _, z in { -5, 5 } do
		for _, x in { -1, 1 } do
			local foot = (cf * CFrame.new(x * 16, 0, z)).Position
			local top = (hub * CFrame.new(0, 0, z)).Position
			local mid = (foot + top) / 2
			P({
				Name = "Leg",
				Size = Vector3.new(1.4, (top - foot).Magnitude, 1.4),
				CFrame = CFrame.lookAt(mid, top) * CFrame.Angles(math.rad(90), 0, 0),
				Color = C.iron,
				Material = Enum.Material.Metal,
			}, model)
		end
	end
	P({
		Name = "Base",
		Size = Vector3.new(40, 1, 16),
		CFrame = cf * CFrame.new(0, 0.5, 0),
		Color = rgb(60, 55, 60),
		Material = Enum.Material.Concrete,
	}, model)

	-- Rotor (spins on the client)
	local rotor = Props.Model("Rotor", model)
	local center = P({
		Name = "Hub",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(12, 3, 3),
		CFrame = hub * CFrame.Angles(0, math.rad(90), 0),
		Color = C.gold,
		Material = Enum.Material.Metal,
	}, rotor)
	rotor.PrimaryPart = center
	local segments = 24
	for side = -1, 1, 2 do
		for i = 0, segments - 1 do
			local a = i / segments * math.pi * 2
			local b = (i + 1) / segments * math.pi * 2
			local pa = hub * CFrame.new(math.cos(a) * radius, math.sin(a) * radius, side * 3)
			local pb = hub * CFrame.new(math.cos(b) * radius, math.sin(b) * radius, side * 3)
			local mid = (pa.Position + pb.Position) / 2
			P({
				Name = "Rim",
				Size = Vector3.new(0.8, 0.8, (pb.Position - pa.Position).Magnitude + 0.4),
				CFrame = CFrame.lookAt(mid, pb.Position),
				Color = if i % 2 == 0 then rgb(255, 90, 90) else rgb(255, 220, 90),
				Material = Enum.Material.Neon,
			}, rotor)
		end
	end
	local spokes = 12
	for i = 0, spokes - 1 do
		local a = i / spokes * math.pi * 2
		local tip = hub * CFrame.new(math.cos(a) * radius, math.sin(a) * radius, 0)
		local mid = (hub.Position + tip.Position) / 2
		P({
			Name = "Spoke",
			Size = Vector3.new(0.5, 0.5, radius),
			CFrame = CFrame.lookAt(mid, tip.Position),
			Color = C.cream,
			Material = Enum.Material.Metal,
		}, rotor)
		local cabin = P({
			Name = "Cabin",
			Size = Vector3.new(4, 3.4, 4.4),
			CFrame = tip * CFrame.new(0, -2.6, 0),
			Color = Color3.fromHSV(i / spokes, 0.65, 0.85),
			Material = Enum.Material.SmoothPlastic,
		}, rotor)
		P({ Name = "CabinRoof", Size = Vector3.new(4.6, 0.4, 5), CFrame = cabin.CFrame * CFrame.new(0, 2.4, 0), Color = C.cream }, rotor)
	end
	Props.Light(center, rgb(255, 120, 120), 40, 2)
	Props.MakeSpin(rotor, "Z", 0.12)

	local sign = P({ Name = "Sign", Size = Vector3.new(18, 3, 0.5), CFrame = cf * CFrame.new(0, 4, -8.5), Color = C.purple }, model)
	Props.Sign(sign, Enum.NormalId.Front, "WHEEL OF WOE", C.gold)
	return model
end

function Props.Carousel(cf: CFrame, parent)
	local model = Props.Model("Carousel", parent)
	local radius = 14
	P({
		Name = "Platform",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.2, radius * 2, radius * 2),
		CFrame = cf * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.darkWood,
		Material = Enum.Material.WoodPlanks,
	}, model)
	P({
		Name = "Pole",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(16, 3, 3),
		CFrame = cf * CFrame.new(0, 8.6, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.gold,
		Material = Enum.Material.Metal,
	}, model)

	local rotor = Props.Model("Rotor", model)
	local top = P({
		Name = "Crown",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 3,
		CFrame = cf * CFrame.new(0, 22, 0),
		Color = C.gold,
		Material = Enum.Material.Metal,
	}, rotor)
	rotor.PrimaryPart = top
	local panels = 16
	for i = 0, panels - 1 do
		local a = (i + 0.5) / panels * math.pi * 2
		local edge = cf * CFrame.new(math.cos(a) * (radius + 1), 15, math.sin(a) * (radius + 1))
		local apex = cf * CFrame.new(0, 21.5, 0)
		local mid = (edge.Position + apex.Position) / 2
		P({
			Name = "Canopy",
			Size = Vector3.new(radius * 2 * math.pi / panels + 0.8, 0.4, (apex.Position - edge.Position).Magnitude),
			CFrame = CFrame.lookAt(mid, apex.Position),
			Color = if i % 2 == 0 then C.red else C.cream,
			Material = Enum.Material.Fabric,
		}, rotor)
		local fringe = P({
			Name = "Fringe",
			Size = Vector3.new(radius * 2 * math.pi / panels, 1.4, 0.3),
			CFrame = CFrame.lookAt(edge.Position - Vector3.new(0, 0.7, 0), cf.Position + Vector3.new(0, 14.3, 0)),
			Color = C.gold,
			Material = Enum.Material.Neon,
		}, rotor)
		if i % 4 == 0 then
			Props.Light(fringe, rgb(255, 200, 120), 18, 1)
		end
	end
	local horses = 8
	for i = 0, horses - 1 do
		local a = i / horses * math.pi * 2
		local spot = cf * CFrame.new(math.cos(a) * (radius - 4), 0, math.sin(a) * (radius - 4))
		local facing = CFrame.lookAt(spot.Position, spot.Position + Vector3.new(-math.sin(a), 0, math.cos(a)))
		local height = 4 + (i % 2) * 1.2
		P({
			Name = "HorsePole",
			Size = Vector3.new(0.4, 14, 0.4),
			CFrame = facing * CFrame.new(0, 8, 0),
			Color = C.gold,
			Material = Enum.Material.Metal,
		}, rotor)
		local color = if i % 3 == 0 then rgb(30, 30, 35) elseif i % 3 == 1 then C.cream else rgb(140, 40, 50)
		P({ Name = "HorseBody", Size = Vector3.new(1.6, 1.8, 4), CFrame = facing * CFrame.new(0, height, 0), Color = color }, rotor)
		P({
			Name = "HorseNeck",
			Size = Vector3.new(1, 2.2, 1),
			CFrame = facing * CFrame.new(0, height + 1.5, -1.8) * CFrame.Angles(math.rad(-25), 0, 0),
			Color = color,
		}, rotor)
		P({ Name = "HorseHead", Size = Vector3.new(1, 1, 2), CFrame = facing * CFrame.new(0, height + 2.6, -2.6), Color = color }, rotor)
		for _, lx in { -0.5, 0.5 } do
			for _, lz in { -1.5, 1.5 } do
				P({
					Name = "HorseLeg",
					Size = Vector3.new(0.4, 2, 0.4),
					CFrame = facing * CFrame.new(lx, height - 1.6, lz) * CFrame.Angles(math.rad(lz * 12), 0, 0),
					Color = color,
				}, rotor)
			end
		end
		P({ Name = "Saddle", Size = Vector3.new(1.8, 0.4, 1.4), CFrame = facing * CFrame.new(0, height + 1, 0.3), Color = C.purple }, rotor)
	end
	Props.MakeSpin(rotor, "Y", 0.35)
	return model
end

function Props.CircusTent(cf: CFrame, parent)
	local model = Props.Model("CircusTent", parent)
	local radius, wall, apex = 34, 12, 32
	local panels = 28
	for i = 0, panels - 1 do
		local a = (i + 0.5) / panels * math.pi * 2
		-- Two doorways, opposite each other, so the tent is a loop
		local isDoor = i == 0 or i == 1 or i == panels / 2 or i == panels / 2 + 1
		local edge = cf * CFrame.new(math.cos(a) * radius, 0, math.sin(a) * radius)
		local face = CFrame.lookAt(edge.Position, cf.Position)
		local width = radius * 2 * math.pi / panels + 0.6
		if not isDoor then
			P({
				Name = "Wall",
				Size = Vector3.new(width, wall, 0.8),
				CFrame = face * CFrame.new(0, wall / 2, 0),
				Color = if i % 2 == 0 then C.red else C.cream,
				Material = Enum.Material.Fabric,
			}, model)
		else
			P({
				Name = "DoorTop",
				Size = Vector3.new(width, 3, 0.8),
				CFrame = face * CFrame.new(0, wall - 1.5, 0),
				Color = C.gold,
				Material = Enum.Material.Fabric,
			}, model)
		end
		local top = cf * CFrame.new(0, apex, 0)
		local rim = edge * CFrame.new(0, wall, 0)
		local mid = (rim.Position + top.Position) / 2
		P({
			Name = "Roof",
			Size = Vector3.new(width + 1, 0.5, (top.Position - rim.Position).Magnitude),
			CFrame = CFrame.lookAt(mid, top.Position),
			Color = if i % 2 == 0 then C.red else C.cream,
			Material = Enum.Material.Fabric,
		}, model)
	end
	P({
		Name = "CenterPole",
		Size = Vector3.new(1.4, apex + 6, 1.4),
		CFrame = cf * CFrame.new(0, (apex + 6) / 2, 0),
		Color = C.gold,
		Material = Enum.Material.Metal,
	}, model)
	local flag = P({
		Name = "Flag",
		Size = Vector3.new(4, 2.4, 0.2),
		CFrame = cf * CFrame.new(2, apex + 5, 0),
		Color = C.purple,
		Material = Enum.Material.Fabric,
		CanCollide = false,
	}, model)
	Props.Sign(flag, Enum.NormalId.Front, "☠", C.gold, Enum.Font.GothamBlack)
	-- Ring curb and benches inside
	for i = 0, 23 do
		local a = i / 24 * math.pi * 2
		local spot = cf * CFrame.new(math.cos(a) * 13, 0, math.sin(a) * 13)
		P({
			Name = "Curb",
			Size = Vector3.new(3.6, 1.2, 1),
			CFrame = CFrame.lookAt(spot.Position, cf.Position) * CFrame.new(0, 0.6, 0),
			Color = if i % 2 == 0 then C.red else C.gold,
		}, model)
	end
	for _, a in { 0.8, 2.3, 3.95, 5.45 } do
		for row = 0, 1 do
			local spot = cf * CFrame.new(math.cos(a) * (22 + row * 4), 0, math.sin(a) * (22 + row * 4))
			P({
				Name = "Bench",
				Size = Vector3.new(12, 1.2 + row * 1.4, 2),
				CFrame = CFrame.lookAt(spot.Position, cf.Position) * CFrame.new(0, 0.6 + row * 0.7, 0),
				Color = C.wood,
				Material = Enum.Material.WoodPlanks,
			}, model)
		end
	end
	local lamp = P({
		Name = "Spotlight",
		Size = Vector3.new(2, 1, 2),
		CFrame = cf * CFrame.new(0, apex - 6, 0),
		Color = rgb(255, 230, 180),
		Material = Enum.Material.Neon,
		CanCollide = false,
	}, model)
	Props.Light(lamp, rgb(255, 210, 160), 45, 1.5)
	return model
end

function Props.HauntedManor(cf: CFrame, parent)
	local model = Props.Model("HauntedManor", parent)
	local w, d, h = 44, 32, 16
	local wallColor = rgb(60, 50, 65)
	local function wall(size, offset)
		return P({ Name = "Wall", Size = size, CFrame = cf * offset, Color = wallColor, Material = Enum.Material.WoodPlanks }, model)
	end
	P({
		Name = "Floor",
		Size = Vector3.new(w, 0.6, d),
		CFrame = cf * CFrame.new(0, 0.3, 0),
		Color = rgb(50, 35, 30),
		Material = Enum.Material.WoodPlanks,
	}, model)
	-- Outer walls with doorways front, back and sides
	for _, z in { -d / 2, d / 2 } do
		wall(Vector3.new(w / 2 - 4, h, 1), CFrame.new(-(w / 4 + 2), h / 2, z))
		wall(Vector3.new(w / 2 - 4, h, 1), CFrame.new(w / 4 + 2, h / 2, z))
		wall(Vector3.new(8, h - 9, 1), CFrame.new(0, h - (h - 9) / 2, z))
	end
	for _, x in { -w / 2, w / 2 } do
		wall(Vector3.new(1, h, d / 2 - 4), CFrame.new(x, h / 2, -(d / 4 + 2)))
		wall(Vector3.new(1, h, d / 2 - 4), CFrame.new(x, h / 2, d / 4 + 2))
		wall(Vector3.new(1, h - 9, 8), CFrame.new(x, h - (h - 9) / 2, 0))
	end
	-- Inner walls make small rooms and loops
	wall(Vector3.new(1, h, 12), CFrame.new(-8, h / 2, -8))
	wall(Vector3.new(1, h, 12), CFrame.new(8, h / 2, 8))
	wall(Vector3.new(12, h, 1), CFrame.new(-14, h / 2, 6))
	wall(Vector3.new(12, h, 1), CFrame.new(14, h / 2, -6))
	-- Roof
	for _, z in { -1, 1 } do
		P({
			Name = "Roof",
			Size = Vector3.new(w + 4, 1, d / 2 + 4),
			CFrame = cf * CFrame.new(0, h + 5, z * d / 4) * CFrame.Angles(z * math.rad(-32), 0, 0),
			Color = rgb(30, 22, 30),
			Material = Enum.Material.Slate,
		}, model)
	end
	P({
		Name = "Ceiling",
		Size = Vector3.new(w, 0.6, d),
		CFrame = cf * CFrame.new(0, h + 0.3, 0),
		Color = rgb(40, 30, 35),
		Material = Enum.Material.WoodPlanks,
	}, model)
	P({
		Name = "Tower",
		Size = Vector3.new(8, 14, 8),
		CFrame = cf * CFrame.new(w / 2 - 6, h + 10, -d / 2 + 6),
		Color = wallColor,
		Material = Enum.Material.WoodPlanks,
	}, model)
	P({
		Name = "TowerTop",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 9,
		CFrame = cf * CFrame.new(w / 2 - 6, h + 18, -d / 2 + 6),
		Color = rgb(30, 22, 30),
	}, model)
	-- Glowing windows
	for _, x in { -16, -8, 8, 16 } do
		for _, z in { -d / 2 - 0.55, d / 2 + 0.55 } do
			local lit = rng:NextNumber() < 0.6
			P({
				Name = "Window",
				Size = Vector3.new(3, 4, 0.2),
				CFrame = cf * CFrame.new(x, 10, z),
				Color = if lit then rgb(140, 255, 160) else rgb(15, 15, 20),
				Material = Enum.Material.Neon,
			}, model)
		end
	end
	local sign = P(
		{ Name = "Sign", Size = Vector3.new(18, 3.4, 0.6), CFrame = cf * CFrame.new(0, h + 1.8, -d / 2 - 0.8), Color = rgb(25, 15, 25) },
		model
	)
	Props.Sign(sign, Enum.NormalId.Front, "HAUNTED MANOR", rgb(140, 255, 160))
	for _, spot in { CFrame.new(-14, h - 2, -8), CFrame.new(14, h - 2, 8), CFrame.new(0, h - 2, 0) } do
		local lamp = P({
			Name = "Chandelier",
			Size = Vector3.new(1.4, 1.4, 1.4),
			CFrame = cf * spot,
			Color = rgb(140, 255, 160),
			Material = Enum.Material.Neon,
			CanCollide = false,
		}, model)
		Props.Light(lamp, rgb(140, 255, 160), 18, 1)
	end
	return model
end

function Props.EntranceArch(cf: CFrame, parent, text: string)
	local model = Props.Model("Arch", parent)
	for _, x in { -10, 10 } do
		P({ Name = "Pillar", Size = Vector3.new(3, 22, 3), CFrame = cf * CFrame.new(x, 11, 0), Color = C.red }, model)
		local ball = P({
			Name = "Topper",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 3.6,
			CFrame = cf * CFrame.new(x, 23.6, 0),
			Color = C.gold,
			Material = Enum.Material.Neon,
		}, model)
		Props.Light(ball, rgb(255, 200, 100), 22, 1.4)
	end
	local board = P({ Name = "Board", Size = Vector3.new(26, 5, 1), CFrame = cf * CFrame.new(0, 19, 0), Color = C.purple }, model)
	Props.Sign(board, Enum.NormalId.Front, text, C.gold)
	Props.Sign(board, Enum.NormalId.Back, text, C.gold)
	return model
end

-- Zone props (farm, junkyard, lake, loops) --------------------------------

-- A straight wall of tall corn. Corn mazes are built from these.
function Props.CornWall(a: Vector3, b: Vector3, parent)
	local mid = (a + b) / 2
	local length = (b - a).Magnitude
	local cf = CFrame.lookAt(mid, b)
	local wall = P({
		Name = "Corn",
		Size = Vector3.new(3, 11, length),
		CFrame = cf + Vector3.new(0, 5.5, 0),
		Color = rgb(120, 125, 50),
		Material = Enum.Material.Grass,
	}, parent)
	for i = 0, math.floor(length / 3) do
		P({
			Name = "Tassel",
			Size = Vector3.new(0.3, 2.2, 0.3),
			CFrame = cf
				* CFrame.new(rng:NextNumber(-1.2, 1.2), 12, -length / 2 + i * 3)
				* CFrame.Angles(rng:NextNumber(-0.3, 0.3), 0, rng:NextNumber(-0.3, 0.3)),
			Color = rgb(200, 170, 80),
			CanCollide = false,
			CanQuery = false,
		}, parent)
	end
	return wall
end

function Props.Barn(cf: CFrame, parent)
	local model = Props.Model("Barn", parent)
	local w, d, h = 36, 26, 14
	local red = rgb(130, 35, 30)
	local function wall(size, offset)
		return P({ Name = "Wall", Size = size, CFrame = cf * offset, Color = red, Material = Enum.Material.WoodPlanks }, model)
	end
	P({
		Name = "Floor",
		Size = Vector3.new(w, 0.5, d),
		CFrame = cf * CFrame.new(0, 0.25, 0),
		Color = rgb(90, 70, 45),
		Material = Enum.Material.WoodPlanks,
	}, model)
	for _, z in { -d / 2, d / 2 } do
		wall(Vector3.new(w / 2 - 6, h, 1), CFrame.new(-(w / 4 + 3), h / 2, z))
		wall(Vector3.new(w / 2 - 6, h, 1), CFrame.new(w / 4 + 3, h / 2, z))
		-- Big barn doors, swung open
		P({
			Name = "BarnDoor",
			Size = Vector3.new(6, 11, 0.6),
			CFrame = cf * CFrame.new(-9, 5.5, z + (if z < 0 then -3 else 3)) * CFrame.Angles(0, math.rad(80), 0),
			Color = rgb(150, 45, 35),
			Material = Enum.Material.WoodPlanks,
		}, model)
	end
	wall(Vector3.new(1, h, d), CFrame.new(-w / 2, h / 2, 0))
	wall(Vector3.new(1, h, d / 2 - 5), CFrame.new(w / 2, h / 2, -(d / 4 + 2.5)))
	wall(Vector3.new(1, h, d / 2 - 5), CFrame.new(w / 2, h / 2, d / 4 + 2.5))
	for _, z in { -1, 1 } do
		P({
			Name = "Roof",
			Size = Vector3.new(w + 3, 1, d / 2 + 4),
			CFrame = cf * CFrame.new(0, h + 5, z * d / 4) * CFrame.Angles(z * math.rad(-38), 0, 0),
			Color = rgb(60, 55, 55),
			Material = Enum.Material.CorrodedMetal,
		}, model)
	end
	-- Hay loft and bales inside
	P({
		Name = "Loft",
		Size = Vector3.new(12, 1, d - 2),
		CFrame = cf * CFrame.new(-w / 2 + 7, 8, 0),
		Color = rgb(90, 70, 45),
		Material = Enum.Material.WoodPlanks,
	}, model)
	for i = 0, 3 do
		Props.HayBale(cf * CFrame.new(-w / 2 + 4 + (i % 2) * 6, 0, -6 + i * 4), model)
	end
	Props.HayBale(cf * CFrame.new(-w / 2 + 6, 8.5, 2), model)
	local bulb = P({
		Name = "Bulb",
		Size = Vector3.one,
		CFrame = cf * CFrame.new(4, h - 1, 0),
		Color = rgb(255, 210, 140),
		Material = Enum.Material.Neon,
		CanCollide = false,
	}, model)
	Props.Light(bulb, rgb(255, 200, 130), 26, 1)
	return model
end

function Props.WreckedCar(cf: CFrame, parent)
	local model = Props.Model("WreckedCar", parent)
	local color = Color3.fromHSV(rng:NextNumber(), 0.35, rng:NextNumber(0.3, 0.55))
	local tilt = cf * CFrame.Angles(math.rad(rng:NextNumber(-6, 6)), 0, math.rad(rng:NextNumber(-8, 8)))
	P({
		Name = "Body",
		Size = Vector3.new(7, 2.6, 14),
		CFrame = tilt * CFrame.new(0, 2, 0),
		Color = color,
		Material = Enum.Material.CorrodedMetal,
	}, model)
	P({
		Name = "Cabin",
		Size = Vector3.new(6.4, 2.4, 6.5),
		CFrame = tilt * CFrame.new(0, 4.4, 1),
		Color = color,
		Material = Enum.Material.CorrodedMetal,
	}, model)
	P({
		Name = "Windows",
		Size = Vector3.new(6.5, 1.6, 6.6),
		CFrame = tilt * CFrame.new(0, 4.6, 1),
		Color = rgb(30, 35, 40),
		Material = Enum.Material.Glass,
		Transparency = 0.3,
	}, model)
	for _, x in { -3.4, 3.4 } do
		for _, z in { -4.5, 4.5 } do
			P({
				Name = "Tire",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(1.2, 2.8, 2.8),
				CFrame = tilt * CFrame.new(x, 1.2, z),
				Color = rgb(25, 25, 25),
			}, model)
		end
	end
	return model
end

function Props.CarPile(cf: CFrame, parent)
	local model = Props.Model("CarPile", parent)
	Props.WreckedCar(cf, model)
	Props.WreckedCar(cf * CFrame.new(0.5, 4.6, 1) * CFrame.Angles(0, 0.4, 0), model)
	if rng:NextNumber() < 0.5 then
		Props.WreckedCar(cf * CFrame.new(-0.4, 9.2, -1) * CFrame.Angles(0, -0.5, 0), model)
	end
	return model
end

-- A fallen teacup ride, half buried
function Props.BrokenTeacup(cf: CFrame, parent)
	local model = Props.Model("BrokenTeacup", parent)
	local cup = P({
		Name = "Cup",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(6, 9, 9),
		CFrame = cf * CFrame.new(0, 3, 0) * CFrame.Angles(math.rad(70), 0, math.rad(20)),
		Color = Color3.fromHSV(rng:NextNumber(), 0.5, 0.8),
		Material = Enum.Material.SmoothPlastic,
	}, model)
	P({
		Name = "Rim",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 9.6, 9.6),
		CFrame = cup.CFrame * CFrame.new(3, 0, 0),
		Color = C.gold,
	}, model)
	return model
end

function Props.WaterTower(cf: CFrame, parent)
	local model = Props.Model("WaterTower", parent)
	for _, x in { -5, 5 } do
		for _, z in { -5, 5 } do
			P({
				Name = "Leg",
				Size = Vector3.new(1.2, 30, 1.2),
				CFrame = cf * CFrame.new(x, 15, z),
				Color = C.iron,
				Material = Enum.Material.Metal,
			}, model)
		end
	end
	local tank = P({
		Name = "Tank",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(12, 16, 16),
		CFrame = cf * CFrame.new(0, 36, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = rgb(110, 100, 90),
		Material = Enum.Material.CorrodedMetal,
	}, model)
	Props.Sign(
		P(
			{ Name = "Paint", Size = Vector3.new(12, 4, 0.2), CFrame = cf * CFrame.new(0, 37, -8.1), Transparency = 1, CanCollide = false },
			model
		),
		Enum.NormalId.Front,
		"NIGHTMARE FAIR",
		C.red
	)
	P({
		Name = "Cap",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(17, 8, 17),
		CFrame = cf * CFrame.new(0, 42, 0),
		Color = rgb(80, 75, 70),
		Material = Enum.Material.CorrodedMetal,
	}, model)
	local beacon = P({
		Name = "Beacon",
		Size = Vector3.one * 1.2,
		CFrame = cf * CFrame.new(0, 46.5, 0),
		Color = rgb(255, 40, 40),
		Material = Enum.Material.Neon,
	}, model)
	Props.Light(beacon, rgb(255, 40, 40), 30, 2)
	return model, tank
end

function Props.Lake(cf: CFrame, parent, size: Vector2)
	local model = Props.Model("Lake", parent)
	P({
		Name = "Water",
		Size = Vector3.new(size.X, 1, size.Y),
		CFrame = cf * CFrame.new(0, -0.3, 0),
		Color = rgb(25, 45, 55),
		Material = Enum.Material.Glass,
		Transparency = 0.15,
		Reflectance = 0.2,
	}, model)
	-- Water is impassable: invisible wall around the edge keeps players on land
	P({ Name = "Blocker", Size = Vector3.new(size.X - 4, 14, size.Y - 4), CFrame = cf * CFrame.new(0, 7, 0), Transparency = 1 }, model)
	-- Dock
	P({
		Name = "Dock",
		Size = Vector3.new(6, 0.8, 24),
		CFrame = cf * CFrame.new(0, 0.6, -size.Y / 2 - 6),
		Color = C.wood,
		Material = Enum.Material.WoodPlanks,
	}, model)
	P({
		Name = "Boat",
		Size = Vector3.new(5, 1.6, 10),
		CFrame = cf * CFrame.new(5, 0.3, -size.Y / 2 + 4) * CFrame.Angles(0, 0.3, math.rad(-8)),
		Color = rgb(90, 60, 40),
		Material = Enum.Material.Wood,
	}, model)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		P({
			Name = "Rock",
			Size = Vector3.new(rng:NextNumber(3, 6), rng:NextNumber(2, 4), rng:NextNumber(3, 6)),
			CFrame = cf
				* CFrame.new(math.cos(a) * size.X / 2, 1, math.sin(a) * size.Y / 2)
				* CFrame.Angles(rng:NextNumber(0, 1), rng:NextNumber(0, 6), 0),
			Color = rgb(80, 80, 85),
			Material = Enum.Material.Rock,
		}, model)
	end
	return model
end

function Props.Rocks(cf: CFrame, parent)
	local model = Props.Model("Rocks", parent)
	for _ = 1, 3 do
		P({
			Name = "Rock",
			Size = Vector3.new(rng:NextNumber(4, 9), rng:NextNumber(3, 7), rng:NextNumber(4, 9)),
			CFrame = cf
				* CFrame.new(rng:NextNumber(-3, 3), 1.5, rng:NextNumber(-3, 3))
				* CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6), rng:NextNumber(-0.4, 0.4)),
			Color = rgb(75, 75, 82),
			Material = Enum.Material.Rock,
		}, model)
	end
	return model
end

function Props.Tractor(cf: CFrame, parent)
	local model = Props.Model("Tractor", parent)
	P({
		Name = "Body",
		Size = Vector3.new(4, 3, 8),
		CFrame = cf * CFrame.new(0, 3, 0),
		Color = rgb(60, 110, 50),
		Material = Enum.Material.CorrodedMetal,
	}, model)
	P({ Name = "Seat", Size = Vector3.new(3, 3, 3), CFrame = cf * CFrame.new(0, 5.5, 2), Color = rgb(40, 40, 40) }, model)
	P({ Name = "Pipe", Size = Vector3.new(0.6, 3, 0.6), CFrame = cf * CFrame.new(1, 6, -2.5), Color = C.iron }, model)
	for _, x in { -2.6, 2.6 } do
		P({
			Name = "BigWheel",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.4, 6, 6),
			CFrame = cf * CFrame.new(x, 3, 2.2),
			Color = rgb(25, 25, 25),
		}, model)
		P({
			Name = "SmallWheel",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1, 3.4, 3.4),
			CFrame = cf * CFrame.new(x, 1.7, -3),
			Color = rgb(25, 25, 25),
		}, model)
	end
	return model
end

function Props.Coffin(cf: CFrame, parent)
	local model = Props.Model("Coffin", parent)
	P({
		Name = "Box",
		Size = Vector3.new(3, 1.6, 7),
		CFrame = cf * CFrame.new(0, 0.8, 0),
		Color = rgb(50, 30, 25),
		Material = Enum.Material.Wood,
	}, model)
	P({
		Name = "Lid",
		Size = Vector3.new(3.2, 0.4, 7.2),
		CFrame = cf * CFrame.new(2, 0.5, 0.4) * CFrame.Angles(0, 0.3, math.rad(-12)),
		Color = rgb(60, 36, 28),
		Material = Enum.Material.Wood,
	}, model)
	return model
end

function Props.BumperCars(cf: CFrame, parent)
	local model = Props.Model("BumperCars", parent)
	P({
		Name = "Floor",
		Size = Vector3.new(40, 0.6, 28),
		CFrame = cf * CFrame.new(0, 0.3, 0),
		Color = rgb(50, 50, 60),
		Material = Enum.Material.DiamondPlate,
	}, model)
	for _, x in { -20, 20 } do
		P({ Name = "Rail", Size = Vector3.new(0.8, 2, 28), CFrame = cf * CFrame.new(x, 1.3, 0), Color = C.gold }, model)
	end
	for _, z in { -14, 14 } do
		P({ Name = "Rail", Size = Vector3.new(14, 2, 0.8), CFrame = cf * CFrame.new(-13, 1.3, z), Color = C.gold }, model)
		P({ Name = "Rail", Size = Vector3.new(14, 2, 0.8), CFrame = cf * CFrame.new(13, 1.3, z), Color = C.gold }, model)
	end
	for _, x in { -18, 18 } do
		for _, z in { -12, 12 } do
			P({ Name = "Post", Size = Vector3.new(1, 14, 1), CFrame = cf * CFrame.new(x, 7, z), Color = C.iron }, model)
		end
	end
	P({
		Name = "Ceiling",
		Size = Vector3.new(40, 0.5, 28),
		CFrame = cf * CFrame.new(0, 14.2, 0),
		Color = rgb(40, 40, 45),
		Material = Enum.Material.DiamondPlate,
	}, model)
	local sign = P({ Name = "Sign", Size = Vector3.new(20, 3, 0.4), CFrame = cf * CFrame.new(0, 16, -14), Color = C.purple }, model)
	Props.Sign(sign, Enum.NormalId.Front, "BUMPER SCARS", C.gold)
	for i = 1, 7 do
		local spot = cf * CFrame.new(rng:NextNumber(-15, 15), 0.6, rng:NextNumber(-10, 10)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
		local color = Color3.fromHSV(i / 7, 0.7, 0.8)
		P({ Name = "BumperCar", Size = Vector3.new(4, 1.6, 5), CFrame = spot * CFrame.new(0, 0.8, 0), Color = color }, model)
		P({ Name = "Bumper", Size = Vector3.new(4.6, 0.8, 5.6), CFrame = spot * CFrame.new(0, 0.4, 0), Color = rgb(30, 30, 30) }, model)
		P(
			{ Name = "Antenna", Size = Vector3.new(0.2, 12, 0.2), CFrame = spot * CFrame.new(0, 7, 2), Color = C.iron, CanCollide = false },
			model
		)
	end
	local lamp = P({
		Name = "Lamp",
		Size = Vector3.new(2, 0.5, 2),
		CFrame = cf * CFrame.new(0, 13.7, 0),
		Color = rgb(150, 180, 255),
		Material = Enum.Material.Neon,
		CanCollide = false,
	}, model)
	Props.Light(lamp, rgb(150, 180, 255), 30, 1.2)
	return model
end

-- DBD-style "killer shack": a small hut with a window opening and a pallet loop around it.
function Props.Shack(cf: CFrame, parent)
	local model = Props.Model("Shack", parent)
	local function wall(size, offset, color)
		return P(
			{ Name = "Wall", Size = size, CFrame = cf * offset, Color = color or rgb(85, 70, 60), Material = Enum.Material.WoodPlanks },
			model
		)
	end
	wall(Vector3.new(16, 10, 1), CFrame.new(0, 5, 8))
	wall(Vector3.new(1, 10, 16), CFrame.new(-8, 5, 0))
	-- Front wall with a doorway
	wall(Vector3.new(5, 10, 1), CFrame.new(-5.5, 5, -8))
	wall(Vector3.new(5, 10, 1), CFrame.new(5.5, 5, -8))
	wall(Vector3.new(6, 3, 1), CFrame.new(0, 8.5, -8))
	-- Side wall with a low window
	wall(Vector3.new(1, 3.5, 16), CFrame.new(8, 1.75, 0))
	wall(Vector3.new(1, 3, 16), CFrame.new(8, 8.5, 0))
	wall(Vector3.new(1, 3.5, 5), CFrame.new(8, 5.25, -5.5))
	wall(Vector3.new(1, 3.5, 5), CFrame.new(8, 5.25, 5.5))
	P({
		Name = "Roof",
		Size = Vector3.new(19, 1, 19),
		CFrame = cf * CFrame.new(0, 10.5, 0) * CFrame.Angles(0, 0, math.rad(6)),
		Color = rgb(55, 50, 50),
		Material = Enum.Material.CorrodedMetal,
	}, model)
	local bulb = P({
		Name = "Bulb",
		Size = Vector3.one * 0.8,
		CFrame = cf * CFrame.new(0, 9, 0),
		Color = rgb(255, 220, 160),
		Material = Enum.Material.Neon,
		CanCollide = false,
	}, model)
	Props.Light(bulb, rgb(255, 200, 140), 16, 1)
	return model
end

-- An L-shaped wall section (a classic chase loop).
function Props.LWall(cf: CFrame, parent)
	local model = Props.Model("LWall", parent)
	local color = rgb(95, 90, 95)
	P(
		{
			Name = "Wall",
			Size = Vector3.new(16, 9, 1.4),
			CFrame = cf * CFrame.new(0, 4.5, 0),
			Color = color,
			Material = Enum.Material.Brick,
		},
		model
	)
	P({
		Name = "Wall",
		Size = Vector3.new(1.4, 9, 12),
		CFrame = cf * CFrame.new(7.3, 4.5, 6.7),
		Color = color,
		Material = Enum.Material.Brick,
	}, model)
	P({
		Name = "Rubble",
		Size = Vector3.new(4, 1.5, 3),
		CFrame = cf * CFrame.new(-6, 0.75, 2) * CFrame.Angles(0, 0.5, 0.2),
		Color = color,
		Material = Enum.Material.Brick,
	}, model)
	return model
end

function Props.FortuneTent(cf: CFrame, parent)
	local model = Props.Model("FortuneTent", parent)
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		if i ~= 0 then
			local edge = cf * CFrame.new(math.cos(a) * 7, 0, math.sin(a) * 7)
			P({
				Name = "Wall",
				Size = Vector3.new(4.8, 8, 0.5),
				CFrame = CFrame.lookAt(edge.Position, cf.Position) * CFrame.new(0, 4, 0),
				Color = if i % 2 == 0 then C.purple else C.teal,
				Material = Enum.Material.Fabric,
			}, model)
		end
	end
	P({
		Name = "Roof",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(16, 9, 16),
		CFrame = cf * CFrame.new(0, 8, 0),
		Color = C.purple,
		Material = Enum.Material.Fabric,
	}, model)
	P({
		Name = "Table",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(3, 3, 3),
		CFrame = cf * CFrame.new(0, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.darkWood,
	}, model)
	local ball = P({
		Name = "CrystalBall",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 1.4,
		CFrame = cf * CFrame.new(0, 3.7, 0),
		Color = rgb(150, 220, 255),
		Material = Enum.Material.Neon,
	}, model)
	Props.Light(ball, rgb(150, 220, 255), 14, 1.2)
	return model
end

-- Gameplay objects --------------------------------------------------------

function Props.RitualPumpkin(cf: CFrame, parent)
	local model = Props.Model("RitualPumpkin", parent)
	P({
		Name = "Altar",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.4, 8, 8),
		CFrame = cf * CFrame.new(0, 0.7, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = rgb(70, 65, 75),
		Material = Enum.Material.Slate,
	}, model)
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		local candle = P({
			Name = "Candle",
			Size = Vector3.new(0.5, 1.4, 0.5),
			CFrame = cf * CFrame.new(math.cos(a) * 3.4, 2.1, math.sin(a) * 3.4),
			Color = C.cream,
			CanCollide = false,
		}, model)
		P({
			Name = "Wick",
			Size = Vector3.new(0.25, 0.4, 0.25),
			CFrame = candle.CFrame * CFrame.new(0, 0.9, 0),
			Color = rgb(255, 170, 60),
			Material = Enum.Material.Neon,
			CanCollide = false,
		}, model)
	end
	local pumpkin = P({
		Name = "Pumpkin",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(5, 5, 5),
		CFrame = cf * CFrame.new(0, 3.6, 0),
		Color = rgb(150, 75, 25),
	}, model)
	P({
		Name = "Stem",
		Size = Vector3.new(0.6, 1.2, 0.6),
		CFrame = cf * CFrame.new(0, 6.5, 0),
		Color = rgb(60, 80, 30),
		CanCollide = false,
	}, model)
	local face = {}
	for _, x in { -0.9, 0.9 } do
		table.insert(
			face,
			P({
				Name = "Eye",
				Size = Vector3.new(1, 0.9, 0.2),
				CFrame = pumpkin.CFrame * CFrame.new(x, 0.6, -2.4),
				Color = rgb(30, 20, 15),
				Material = Enum.Material.SmoothPlastic,
				CanCollide = false,
			}, model)
		)
	end
	table.insert(
		face,
		P({
			Name = "Mouth",
			Size = Vector3.new(2.6, 0.6, 0.2),
			CFrame = pumpkin.CFrame * CFrame.new(0, -0.8, -2.35),
			Color = rgb(30, 20, 15),
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
		}, model)
	)
	local light = Props.Light(pumpkin, rgb(255, 150, 40), 30, 0)
	return { Model = model, Pumpkin = pumpkin, Face = face, Light = light, Position = cf.Position }
end

function Props.CrowCage(cf: CFrame, parent)
	local model = Props.Model("CrowCage", parent)
	local radius, height = 3.6, 9
	P({
		Name = "Base",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, radius * 2 + 1, radius * 2 + 1),
		CFrame = cf * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C.iron,
		Material = Enum.Material.Metal,
	}, model)
	P({
		Name = "Top",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(radius * 2 + 1, 3, radius * 2 + 1),
		CFrame = cf * CFrame.new(0, height + 1, 0),
		Color = C.iron,
		Material = Enum.Material.Metal,
	}, model)
	for i = 0, 13 do
		local a = i / 14 * math.pi * 2
		-- Leave a gap in front so rescuers can reach in
		if i ~= 0 then
			P({
				Name = "Bar",
				Size = Vector3.new(0.3, height, 0.3),
				CFrame = cf * CFrame.new(math.cos(a) * radius, height / 2 + 1, math.sin(a) * radius),
				Color = rgb(80, 75, 70),
				Material = Enum.Material.Metal,
			}, model)
		end
	end
	P({
		Name = "Hook",
		Size = Vector3.new(0.6, 6, 0.6),
		CFrame = cf * CFrame.new(0, height + 5, 0),
		Color = C.iron,
		Material = Enum.Material.Metal,
		CanCollide = false,
	}, model)
	-- Crows perched on top
	for _, x in { -1.6, 1.4 } do
		local crow = P({
			Name = "Crow",
			Size = Vector3.new(0.8, 0.9, 1.6),
			CFrame = cf * CFrame.new(x, height + 2.8, 0) * CFrame.Angles(0, x, 0),
			Color = rgb(15, 15, 20),
			CanCollide = false,
		}, model)
		P({
			Name = "CrowEye",
			Size = Vector3.new(0.15, 0.15, 0.1),
			CFrame = crow.CFrame * CFrame.new(0.25, 0.25, -0.8),
			Color = rgb(255, 40, 40),
			Material = Enum.Material.Neon,
			CanCollide = false,
		}, model)
	end
	local glow = P(
		{ Name = "Glow", Size = Vector3.new(0.5, 0.5, 0.5), CFrame = cf * CFrame.new(0, height, 0), Transparency = 1, CanCollide = false },
		model
	)
	local light = Props.Light(glow, rgb(255, 40, 40), 16, 1)
	-- Invisible part the prompts attach to, at the cage door
	local door = P({
		Name = "DoorZone",
		Size = Vector3.new(3, 4, 1),
		CFrame = cf * CFrame.new(radius + 0.5, 3, 0),
		Transparency = 1,
		CanCollide = false,
	}, model)
	Props.Billboard(door, "🐦‍⬛ CROW CAGE", rgb(255, 90, 90), 4, 40)
	return { Model = model, Door = door, Light = light, Inside = cf * CFrame.new(0, 4.2, 0), Position = cf.Position }
end

-- A pallet in a gap between two crate stacks. Returns the pallet part and its standing/dropped CFrames.
function Props.PalletSpot(cf: CFrame, parent)
	local model = Props.Model("PalletSpot", parent)
	Props.CrateStack(cf * CFrame.new(-7.4, 0, 0), model)
	Props.CrateStack(cf * CFrame.new(7.4, 0, 0), model)
	local standing = cf * CFrame.new(-4.2, 3.2, 0) * CFrame.Angles(0, 0, math.rad(-20))
	local dropped = cf * CFrame.new(0, 3, 0)
	local pallet = P({
		Name = "Pallet",
		Size = Vector3.new(6.6, 6, 0.8),
		CFrame = standing,
		Color = rgb(150, 110, 70),
		Material = Enum.Material.WoodPlanks,
		CanCollide = false,
	}, model)
	for _, y in { -2, 0, 2 } do
		P({
			Name = "Slat",
			Size = Vector3.new(6.8, 0.6, 0.3),
			CFrame = pallet.CFrame * CFrame.new(0, y, -0.5),
			Color = rgb(110, 80, 50),
			Material = Enum.Material.Wood,
			CanCollide = false,
			CanQuery = false,
		}, model)
	end
	return { Model = model, Pallet = pallet, Standing = standing, Dropped = dropped, Position = cf.Position }
end

function Props.Bell(cf: CFrame, parent)
	local model = Props.Model("GhostBell", parent)
	P({
		Name = "Post",
		Size = Vector3.new(0.8, 10, 0.8),
		CFrame = cf * CFrame.new(-2, 5, 0),
		Color = C.darkWood,
		Material = Enum.Material.Wood,
	}, model)
	P({
		Name = "Post",
		Size = Vector3.new(0.8, 10, 0.8),
		CFrame = cf * CFrame.new(2, 5, 0),
		Color = C.darkWood,
		Material = Enum.Material.Wood,
	}, model)
	P({
		Name = "Beam",
		Size = Vector3.new(5, 0.8, 0.8),
		CFrame = cf * CFrame.new(0, 10, 0),
		Color = C.darkWood,
		Material = Enum.Material.Wood,
	}, model)
	local bell = P({
		Name = "Bell",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.6, 2.8, 2.6),
		CFrame = cf * CFrame.new(0, 8.2, 0),
		Color = rgb(170, 220, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.2,
	}, model)
	Props.Light(bell, rgb(150, 200, 255), 14, 1)
	Props.Billboard(bell, "🔔 GHOST BELL", rgb(170, 220, 255), 3, 35)
	return { Model = model, Bell = bell }
end

function Props.ExitGate(cf: CFrame, parent)
	local model = Props.Model("ExitGate", parent)
	for _, x in { -9.5, 9.5 } do
		P({
			Name = "GatePost",
			Size = Vector3.new(3, 20, 3),
			CFrame = cf * CFrame.new(x, 10, 0),
			Color = C.iron,
			Material = Enum.Material.Metal,
		}, model)
	end
	local top = P({
		Name = "GateTop",
		Size = Vector3.new(22, 3, 3),
		CFrame = cf * CFrame.new(0, 21.5, 0),
		Color = C.iron,
		Material = Enum.Material.Metal,
	}, model)
	Props.Sign(top, Enum.NormalId.Front, "EXIT", rgb(255, 60, 60))
	local doors = {}
	for _, x in { -4, 4 } do
		local door = P({
			Name = "Door",
			Size = Vector3.new(8, 18, 0.8),
			CFrame = cf * CFrame.new(x, 9, 0),
			Color = rgb(70, 60, 55),
			Material = Enum.Material.DiamondPlate,
		}, model)
		table.insert(doors, { Part = door, Closed = door.CFrame, Open = door.CFrame * CFrame.new(x * 1.9, 0, 0) })
	end
	local box = P({
		Name = "SwitchBox",
		Size = Vector3.new(2.4, 3.4, 1.4),
		CFrame = cf * CFrame.new(13, 4, -1.5),
		Color = rgb(80, 80, 90),
		Material = Enum.Material.Metal,
	}, model)
	local lamp = P({
		Name = "Lamp",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 1.2,
		CFrame = cf * CFrame.new(13, 6.4, -1.5),
		Color = rgb(255, 40, 40),
		Material = Enum.Material.Neon,
	}, model)
	local light = Props.Light(lamp, rgb(255, 40, 40), 14, 1.5)
	-- Beyond the gate: the way out
	local escape = P(
		{ Name = "EscapeZone", Size = Vector3.new(18, 12, 10), CFrame = cf * CFrame.new(0, 6, 9), Transparency = 1, CanCollide = false },
		model
	)
	return { Model = model, Doors = doors, Switch = box, Lamp = lamp, Light = light, Escape = escape }
end

return Props
