-- Builds the haunted village from code: bonfire, houses, dead trees, graves, fog boundary.
local MapBuilder = {}

local MAP_RADIUS = 190
local HOUSE_RING = 115
local HOUSE_COUNT = 8

local rng = Random.new(31102026) -- fixed seed: same village every server

local function newPart(props, parent)
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

local function billboard(parent: BasePart, text: string, color: Color3, height: number)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(160, 36)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	gui.MaxDistance = 40
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Creepster
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = label
	label.Parent = gui
	gui.Parent = parent
	return label
end

local function buildBonfire(parent)
	local folder = Instance.new("Model")
	folder.Name = "Bonfire"
	folder.Parent = parent

	for i = 1, 10 do
		local angle = i / 10 * math.pi * 2
		newPart({
			Name = "Stone",
			Size = Vector3.new(1.6, 1.2, 1.6),
			CFrame = CFrame.new(math.cos(angle) * 4, 0.6, math.sin(angle) * 4) * CFrame.Angles(0, angle, 0),
			Color = Color3.fromRGB(80, 80, 85),
			Material = Enum.Material.Slate,
		}, folder)
	end
	for i = 1, 4 do
		newPart({
			Name = "Log",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(6, 1, 1),
			CFrame = CFrame.new(0, 0.8, 0) * CFrame.Angles(0, i * math.pi / 4, math.rad(18)),
			Color = Color3.fromRGB(90, 55, 30),
			Material = Enum.Material.Wood,
		}, folder)
	end
	local core = newPart({
		Name = "FireCore",
		Size = Vector3.new(2, 2, 2),
		Position = Vector3.new(0, 2, 0),
		Transparency = 1,
		CanCollide = false,
	}, folder)
	local fire = Instance.new("Fire")
	fire.Heat = 15
	fire.Size = 10
	fire.Color = Color3.fromRGB(255, 140, 30)
	fire.SecondaryColor = Color3.fromRGB(255, 60, 0)
	fire.Parent = core
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 150, 60)
	light.Brightness = 3
	light.Range = 30
	light.Shadows = true
	light.Parent = core

	-- Glowing ring on the ground that shows the safe zone
	local zone = newPart({
		Name = "SafeZone",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, 40, 40),
		CFrame = CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(255, 140, 40),
		Material = Enum.Material.Neon,
		Transparency = 0.85,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	}, folder)

	billboard(core, "🔥 BRING LOGS HERE", Color3.fromRGB(255, 190, 90), 6)
	return { Model = folder, Core = core, Fire = fire, Light = light, Zone = zone }
end

local function buildHouse(index: number, angle: number, parent)
	local center = Vector3.new(math.cos(angle) * HOUSE_RING, 0, math.sin(angle) * HOUSE_RING)
	local facing = CFrame.lookAt(center, Vector3.new(0, 0, 0)) -- front faces the bonfire
	local house = Instance.new("Model")
	house.Name = "House" .. index
	house.Parent = parent

	local wallColor = ({ Color3.fromRGB(70, 60, 75), Color3.fromRGB(60, 70, 65), Color3.fromRGB(85, 70, 55) })[index % 3 + 1]
	local function at(x, y, z)
		return facing * CFrame.new(x, y, z)
	end
	newPart(
		{ Name = "Body", Size = Vector3.new(20, 12, 16), CFrame = at(0, 6, 0), Color = wallColor, Material = Enum.Material.WoodPlanks },
		house
	)
	newPart({
		Name = "RoofL",
		Size = Vector3.new(22, 1, 10.5),
		CFrame = at(0, 14.5, 4) * CFrame.Angles(math.rad(-35), 0, 0),
		Color = Color3.fromRGB(35, 25, 30),
		Material = Enum.Material.Slate,
	}, house)
	newPart({
		Name = "RoofR",
		Size = Vector3.new(22, 1, 10.5),
		CFrame = at(0, 14.5, -4) * CFrame.Angles(math.rad(35), 0, 0),
		Color = Color3.fromRGB(35, 25, 30),
		Material = Enum.Material.Slate,
	}, house)
	for _, x in { -6, 6 } do
		newPart({
			Name = "Window",
			Size = Vector3.new(3, 3, 0.3),
			CFrame = at(x, 7, -8.05),
			Color = if rng:NextNumber() < 0.5 then Color3.fromRGB(255, 190, 80) else Color3.fromRGB(20, 20, 25),
			Material = Enum.Material.Neon,
		}, house)
	end
	local door = newPart({
		Name = "Door",
		Size = Vector3.new(4, 7, 0.4),
		CFrame = at(0, 3.5, -8.1),
		Color = Color3.fromRGB(60, 35, 20),
		Material = Enum.Material.Wood,
	}, house)
	-- Jack-o'-lantern on the porch
	local pumpkin = newPart({
		Name = "Pumpkin",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.2, 2.2, 2.2),
		CFrame = at(3.5, 1.1, -9.5),
		Color = Color3.fromRGB(255, 120, 20),
	}, house)
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 140, 40)
	glow.Range = 8
	glow.Brightness = 1.5
	glow.Parent = pumpkin

	return { Model = house, Door = door, Center = center }
end

local function buildTree(position: Vector3, parent)
	local height = rng:NextNumber(10, 18)
	local tree = Instance.new("Model")
	tree.Name = "DeadTree"
	tree.Parent = parent
	local trunk = newPart({
		Name = "Trunk",
		Size = Vector3.new(1.6, height, 1.6),
		CFrame = CFrame.new(position + Vector3.new(0, height / 2, 0))
			* CFrame.Angles(0, rng:NextNumber(0, 6), math.rad(rng:NextNumber(-6, 6))),
		Color = Color3.fromRGB(45, 35, 30),
		Material = Enum.Material.Wood,
	}, tree)
	for _ = 1, rng:NextInteger(2, 4) do
		local length = rng:NextNumber(4, 8)
		local base = trunk.Position + Vector3.new(0, rng:NextNumber(0, height / 2), 0)
		newPart({
			Name = "Branch",
			Size = Vector3.new(0.6, length, 0.6),
			CFrame = CFrame.new(base)
				* CFrame.Angles(0, rng:NextNumber(0, 6.28), math.rad(rng:NextNumber(30, 70)))
				* CFrame.new(0, length / 2, 0),
			Color = Color3.fromRGB(45, 35, 30),
			Material = Enum.Material.Wood,
			CanCollide = false,
		}, tree)
	end
end

local function buildGrave(position: Vector3, parent)
	local yaw = rng:NextNumber(-0.3, 0.3)
	local stone = newPart({
		Name = "Grave",
		Size = Vector3.new(2.4, 3, 0.6),
		CFrame = CFrame.new(position + Vector3.new(0, 1.5, 0)) * CFrame.Angles(math.rad(rng:NextNumber(-8, 8)), yaw, 0),
		Color = Color3.fromRGB(110, 110, 120),
		Material = Enum.Material.Slate,
	}, parent)
	local text = Instance.new("SurfaceGui")
	text.Face = Enum.NormalId.Front
	text.LightInfluence = 1
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Creepster
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(40, 40, 45)
	label.Text = "R.I.P"
	label.Parent = text
	text.Parent = stone
end

-- Returns a random ground position in the playable area that isn't inside a house.
function MapBuilder.RandomSpot(houses, minRadius: number?, rand: Random?): Vector3
	rand = rand or Random.new()
	for _ = 1, 30 do
		local angle = rand:NextNumber(0, math.pi * 2)
		local radius = rand:NextNumber(minRadius or 25, MAP_RADIUS - 10)
		local spot = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		local clear = true
		for _, house in houses do
			if (house.Center - spot).Magnitude < 16 then
				clear = false
				break
			end
		end
		if clear then
			return spot
		end
	end
	return Vector3.new(0, 0, 40)
end

function MapBuilder.Build()
	local existing = workspace:FindFirstChild("Baseplate")
	if existing then
		existing:Destroy()
	end

	local map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = workspace

	newPart({
		Name = "Ground",
		Size = Vector3.new(500, 2, 500),
		Position = Vector3.new(0, -1, 0),
		Color = Color3.fromRGB(35, 45, 30),
		Material = Enum.Material.Grass,
	}, map)

	local bonfire = buildBonfire(map)

	local houses = {}
	for i = 1, HOUSE_COUNT do
		table.insert(houses, buildHouse(i, (i - 0.5) / HOUSE_COUNT * math.pi * 2, map))
	end

	local nature = Instance.new("Folder")
	nature.Name = "Nature"
	nature.Parent = map
	for _ = 1, 70 do
		buildTree(MapBuilder.RandomSpot(houses, 35, rng), nature)
	end
	-- Graveyard cluster plus scattered graves
	for row = 0, 3 do
		for col = 0, 5 do
			buildGrave(Vector3.new(-40 + col * 5, 0, 55 + row * 6), nature)
		end
	end
	for _ = 1, 20 do
		buildGrave(MapBuilder.RandomSpot(houses, 30, rng), nature)
	end

	-- Invisible boundary with a ring of crooked fence posts
	for i = 0, 63 do
		local angle = i / 64 * math.pi * 2
		local pos = Vector3.new(math.cos(angle) * MAP_RADIUS, 0, math.sin(angle) * MAP_RADIUS)
		newPart({
			Name = "Barrier",
			Size = Vector3.new(20, 40, 2),
			CFrame = CFrame.lookAt(pos + Vector3.new(0, 20, 0), Vector3.new(0, 20, 0)),
			Transparency = 1,
		}, map)
		newPart({
			Name = "FencePost",
			Size = Vector3.new(0.8, 6, 0.8),
			CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-12, 12))),
			Color = Color3.fromRGB(50, 40, 35),
			Material = Enum.Material.Wood,
		}, map)
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "BonfireSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(6, 0.2, 6)
	spawn.Position = Vector3.new(0, 0.1, 9)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = map

	for _, name in { "Pickups", "Monsters" } do
		local folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = workspace
	end

	return { Bonfire = bonfire, Houses = houses, Radius = MAP_RADIUS }
end

return MapBuilder
