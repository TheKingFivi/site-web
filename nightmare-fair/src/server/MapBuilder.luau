-- Lays out the whole Nightmare Fair map (500 x 500 studs) in themed zones, DBD-style:
--   NW corn maze · N Ferris wheel & bumper cars · NE junkyard
--   W haunted manor & graveyard · center carousel & midway · E circus tent
--   SW farm & barn · S main entrance & killer shack · SE lake & water tower
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local Props = require(script.Parent.Props)

local MapBuilder = {}

local HALF = 250 -- the map spans -250..250 on X and Z
local rng = Random.new(66613)
local rgb = Color3.fromRGB

local reserved = {} -- { position: Vector3, radius: number } spots props must not overlap
local boothSpots = {}

local function at(x: number, z: number, yawDeg: number?)
	return CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yawDeg or 0), 0)
end

local function reserve(x: number, z: number, radius: number)
	table.insert(reserved, { position = Vector3.new(x, 0, z), radius = radius })
end

local function isFree(x: number, z: number, radius: number)
	if math.abs(x) > HALF - 8 or math.abs(z) > HALF - 8 then
		return false
	end
	local p = Vector3.new(x, 0, z)
	for _, r in reserved do
		if (r.position - p).Magnitude < r.radius + radius then
			return false
		end
	end
	return true
end

local terrain = workspace.Terrain

-- Paints a strip of the ground with a terrain material without changing its height.
local function paintStrip(from: Vector2, to: Vector2, width: number, material: Enum.Material)
	local a, b = Vector3.new(from.X, -1, from.Y), Vector3.new(to.X, -1, to.Y)
	terrain:FillBlock(CFrame.lookAt((a + b) / 2, b), Vector3.new(width, 2, (b - a).Magnitude + width), material)
end

local function paintCircle(x: number, z: number, radius: number, material: Enum.Material)
	terrain:FillCylinder(CFrame.new(x, -1, z), 2, radius, material)
end

local function path(_, from: Vector2, to: Vector2, width: number)
	paintStrip(from, to, width, Enum.Material.Mud)
end

-- Sculpted ground: grass base, worn patches, zone floors, a real water lake, and hills beyond the fence.
local function buildTerrain()
	terrain:Clear()
	terrain:FillBlock(CFrame.new(0, -6, 0), Vector3.new(HALF * 2 + 260, 12, HALF * 2 + 260), Enum.Material.Grass)
	-- Worn, uneven ground so it isn't one flat color
	for _ = 1, 70 do
		local x, z = rng:NextNumber(-HALF, HALF), rng:NextNumber(-HALF, HALF)
		local material = ({ Enum.Material.LeafyGrass, Enum.Material.Ground, Enum.Material.Mud })[rng:NextInteger(1, 3)]
		paintCircle(x, z, rng:NextNumber(6, 18), material)
	end
	-- Zone floors
	paintCircle(0, 0, 30, Enum.Material.Cobblestone) -- carousel plaza
	terrain:FillBlock(CFrame.new(-167, -1, -167), Vector3.new(146, 2, 146), Enum.Material.Ground) -- corn field soil
	terrain:FillBlock(CFrame.new(170, -1, -170), Vector3.new(140, 2, 140), Enum.Material.Slate) -- junkyard gravel
	terrain:FillBlock(CFrame.new(-176, -1, 75), Vector3.new(64, 2, 52), Enum.Material.Mud) -- graveyard
	terrain:FillBlock(CFrame.new(-165, -1, 175), Vector3.new(70, 2, 60), Enum.Material.Ground) -- farmyard
	paintCircle(150, 0, 36, Enum.Material.Sand) -- circus ring sawdust
	-- Lake: dig a basin, fill it with water, muddy shore
	terrain:FillBlock(CFrame.new(175, -4, 175), Vector3.new(88, 8, 68), Enum.Material.Mud)
	terrain:FillBlock(CFrame.new(175, -3, 175), Vector3.new(80, 6, 60), Enum.Material.Air)
	terrain:FillBlock(CFrame.new(175, -4, 175), Vector3.new(80, 4, 60), Enum.Material.Water)
	-- Hills and rock outcrops beyond the fence (leave the two exit corridors open)
	for i = 0, 47 do
		local angle = i / 48 * math.pi * 2
		local dist = HALF + rng:NextNumber(55, 85)
		local x = math.clamp(math.cos(angle) * dist * 1.25, -HALF - 85, HALF + 85)
		local z = math.clamp(math.sin(angle) * dist * 1.25, -HALF - 85, HALF + 85)
		if math.abs(x) > 50 or math.abs(z) < HALF then
			local material = if rng:NextNumber() < 0.25 then Enum.Material.Rock else Enum.Material.Grass
			terrain:FillBall(Vector3.new(x, -12, z), rng:NextNumber(38, 52), material)
		end
	end
	pcall(function()
		terrain.Decoration = true -- animated grass blades
	end)
end

local function buildCornMaze(parent)
	local maze = Props.Model("CornMaze", parent)
	local x0, x1, z0, z1 = -238, -96, -238, -96
	-- Outer walls with openings on the east and south sides
	Props.CornWall(Vector3.new(x0, 0, z0), Vector3.new(x1, 0, z0), maze)
	Props.CornWall(Vector3.new(x0, 0, z0), Vector3.new(x0, 0, z1), maze)
	Props.CornWall(Vector3.new(x0, 0, z1), Vector3.new(-180, 0, z1), maze)
	Props.CornWall(Vector3.new(-160, 0, z1), Vector3.new(x1, 0, z1), maze)
	Props.CornWall(Vector3.new(x1, 0, z0), Vector3.new(x1, 0, -190), maze)
	Props.CornWall(Vector3.new(x1, 0, -170), Vector3.new(x1, 0, z1), maze)
	-- Inner rows with random gaps
	for row = 1, 5 do
		local z = z0 + row * 24
		local gap = rng:NextNumber(x0 + 20, x1 - 30)
		Props.CornWall(Vector3.new(x0 + 10, 0, z), Vector3.new(gap, 0, z), maze)
		Props.CornWall(Vector3.new(gap + 16, 0, z), Vector3.new(x1 - 10, 0, z), maze)
		if row % 2 == 0 then
			local x = rng:NextNumber(x0 + 30, x1 - 30)
			if math.abs(x + 167) < 10 then
				x += 24 -- keep the maze's ritual pumpkin reachable
			end
			Props.CornWall(Vector3.new(x, 0, z + 4), Vector3.new(x, 0, z + 18), maze)
		end
	end
	for i = 1, 3 do
		Props.Scarecrow(at(rng:NextNumber(x0 + 15, x1 - 15), z0 + i * 24 + 12, rng:NextNumber(0, 360)), maze)
	end
	reserve(-167, -167, 100)
end

local function buildJunkyard(parent)
	local yard = Props.Model("Junkyard", parent)
	local spots = {
		{ 115, -120 },
		{ 140, -205 },
		{ 190, -110 },
		{ 215, -175 },
		{ 175, -230 },
		{ 120, -175 },
		{ 205, -140 },
		{ 145, -130 },
	}
	for _, s in spots do
		Props.CarPile(at(s[1], s[2], rng:NextNumber(0, 360)), yard)
		reserve(s[1], s[2], 10)
	end
	for _, s in { { 185, -195 }, { 125, -225 }, { 230, -105 } } do
		Props.BrokenTeacup(at(s[1], s[2], rng:NextNumber(0, 360)), yard)
		reserve(s[1], s[2], 7)
	end
	local sign = Props.Part({
		Name = "JunkSign",
		Size = Vector3.new(14, 3, 0.5),
		CFrame = at(100, -100, 45) * CFrame.new(0, 8, 0),
		Color = rgb(60, 55, 50),
		Material = Enum.Material.CorrodedMetal,
	}, yard)
	Props.Sign(sign, Enum.NormalId.Front, "RIDE GRAVEYARD", rgb(255, 140, 60))
	Props.Part(
		{ Name = "SignPost", Size = Vector3.new(0.6, 7, 0.6), CFrame = at(100, -100) * CFrame.new(0, 3.5, 0), Color = rgb(45, 45, 52) },
		yard
	)
end

local function buildGraveyard(parent)
	local yard = Props.Model("Graveyard", parent)
	for row = 0, 4 do
		for col = 0, 6 do
			if rng:NextNumber() < 0.85 then
				Props.Tombstone(at(-200 + col * 8 + rng:NextNumber(-1, 1), 55 + row * 9, rng:NextNumber(-10, 10)), yard)
			end
		end
	end
	Props.Coffin(at(-150, 70, 30), yard)
	Props.Coffin(at(-140, 95, -20), yard)
	Props.Fence(Vector3.new(-210, 0, 45), Vector3.new(-160, 0, 45), yard, 3)
	Props.DeadTree(at(-130, 60), yard)
	Props.DeadTree(at(-215, 100), yard)
	reserve(-175, 75, 38)
end

local function buildFarm(parent)
	local farm = Props.Model("Farm", parent)
	Props.Barn(at(-165, 175), farm)
	reserve(-165, 175, 26)
	Props.Tractor(at(-120, 200, 30), farm)
	reserve(-120, 200, 6)
	for i = 0, 5 do
		Props.HayBale(at(-125 + (i % 3) * 6, 150 + math.floor(i / 3) * 4, 90), farm)
	end
	reserve(-119, 152, 10)
	for i = 0, 3 do
		Props.PumpkinPile(at(-215 + i * 12, 225), farm)
		Props.Scarecrow(at(-210 + i * 14, 130, rng:NextNumber(0, 360)), farm)
	end
	-- Small corn patches
	Props.CornWall(Vector3.new(-235, 0, 115), Vector3.new(-235, 0, 150), farm)
	Props.CornWall(Vector3.new(-100, 0, 225), Vector3.new(-60, 0, 225), farm)
	reserve(-205, 225, 25)
end

local function buildLake(parent)
	local lake = Props.Model("LakeZone", parent)
	Props.Lake(at(175, 175), lake, Vector2.new(80, 60))
	reserve(175, 175, 50)
	Props.WaterTower(at(110, 135), lake)
	reserve(110, 135, 10)
	for _, s in { { 225, 120 }, { 125, 225 }, { 230, 225 } } do
		Props.Rocks(at(s[1], s[2]), lake)
		reserve(s[1], s[2], 8)
	end
end

local function buildMidway(parent)
	local midway = Props.Model("Midway", parent)
	Props.Carousel(at(0, 0), midway)
	reserve(0, 0, 18)
	-- Booth rows along both main paths, facing the path
	local colors = { Props.Colors.red, Props.Colors.purple, Props.Colors.teal, Props.Colors.gold }
	local n = 0
	for _, z in { 35, 60, 85, -35, -60 } do
		for _, side in { -1, 1 } do
			n += 1
			Props.Booth(at(side * 22, z, if side < 0 then -90 else 90), midway, colors[n % #colors + 1])
			table.insert(boothSpots, at(side * 22, z, if side < 0 then -90 else 90))
			reserve(side * 22, z, 8)
		end
	end
	for _, x in { 40, 65, 90, -40, -65 } do
		for _, side in { -1, 1 } do
			n += 1
			Props.Booth(at(x, side * 22, if side < 0 then 0 else 180), midway, colors[n % #colors + 1])
			table.insert(boothSpots, at(x, side * 22, if side < 0 then 0 else 180))
			reserve(x, side * 22, 8)
		end
	end
	for _, s in { { 12, 105 }, { -12, -80 }, { 105, 12 }, { -85, -12 } } do
		Props.PopcornCart(at(s[1], s[2], rng:NextNumber(0, 360)), midway)
		reserve(s[1], s[2], 4)
	end
end

local function buildPathsAndLights(parent)
	local paths = Props.Model("Paths", parent)
	path(paths, Vector2.new(0, -HALF), Vector2.new(0, HALF), 14)
	path(paths, Vector2.new(-HALF, 0), Vector2.new(HALF, 0), 14)
	path(paths, Vector2.new(-150, 0), Vector2.new(-150, 160), 9)
	path(paths, Vector2.new(150, 0), Vector2.new(150, -110), 9)
	path(paths, Vector2.new(0, 120), Vector2.new(110, 120), 9)
	-- Lamp posts with string lights between them, along the main paths
	local lights = Props.Model("Lights", parent)
	local previous = {}
	for i = -7, 7 do
		local d = i * 32
		for key, pos in { NS = Vector3.new(9, 0, d), EW = Vector3.new(d, 0, -9) } do
			if math.abs(d) > 20 and isFree(pos.X, pos.Z, 1.5) then
				Props.LampPost(CFrame.new(pos) * CFrame.Angles(0, if key == "NS" then math.rad(90) else 0, 0), lights)
				local top = pos + Vector3.new(0, 12.5, 0)
				if previous[key] and (previous[key] - top).Magnitude < 40 then
					Props.StringLights(previous[key], top, lights, 9)
				end
				previous[key] = top
			else
				previous[key] = nil
			end
		end
	end
end

local function buildBoundary(parent)
	local boundary = Props.Model("Boundary", parent)
	local gap = 12
	-- North and south walls have a gap in the middle for the exit gates
	for _, z in { -HALF, HALF } do
		Props.Fence(Vector3.new(-HALF, 0, z), Vector3.new(-gap, 0, z), boundary)
		Props.Fence(Vector3.new(gap, 0, z), Vector3.new(HALF, 0, z), boundary)
	end
	Props.Fence(Vector3.new(-HALF, 0, -HALF), Vector3.new(-HALF, 0, HALF), boundary)
	Props.Fence(Vector3.new(HALF, 0, -HALF), Vector3.new(HALF, 0, HALF), boundary)
	-- Fog-covered forest outside the fence
	local forest = Props.Model("Forest", parent)
	for _ = 1, 120 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local dist = rng:NextNumber(HALF + 15, HALF + 70)
		local x = math.clamp(math.cos(angle) * dist * 1.3, -HALF - 70, HALF + 70)
		local z = math.clamp(math.sin(angle) * dist * 1.3, -HALF - 70, HALF + 70)
		if math.abs(x) > HALF + 10 or math.abs(z) > HALF + 10 then
			Props.DeadTree(at(x, z), forest)
		end
	end
	-- Walls around the escape area beyond each gate so players can't wander off
	for _, z in { -HALF, HALF } do
		local s = math.sign(z)
		Props.Fence(Vector3.new(-gap, 0, z), Vector3.new(-gap, 0, z + s * 24), boundary)
		Props.Fence(Vector3.new(gap, 0, z), Vector3.new(gap, 0, z + s * 24), boundary)
		Props.Fence(Vector3.new(-gap, 0, z + s * 24), Vector3.new(gap, 0, z + s * 24), boundary)
	end
end

local function buildLobby(parent)
	local lobby = Props.Model("Lobby", parent)
	local origin = CFrame.new(0, 0, -900)
	Props.Part({
		Name = "Floor",
		Size = Vector3.new(90, 2, 90),
		CFrame = origin * CFrame.new(0, -1, 0),
		Color = rgb(45, 30, 50),
		Material = Enum.Material.Slate,
	}, lobby)
	for _, spec in { { 0, -45, 0 }, { 0, 45, 0 }, { -45, 0, 90 }, { 45, 0, 90 } } do
		Props.Part({
			Name = "Wall",
			Size = Vector3.new(90, 14, 2),
			CFrame = origin * CFrame.new(spec[1], 7, spec[2]) * CFrame.Angles(0, math.rad(spec[3]), 0),
			Color = rgb(70, 40, 60),
			Material = Enum.Material.WoodPlanks,
		}, lobby)
	end
	Props.EntranceArch(origin * CFrame.new(0, 0, 30), lobby, "NIGHTMARE FAIR")
	Props.Carousel(origin * CFrame.new(0, 0, -14), lobby)
	for _, x in { -32, 32 } do
		Props.TicketBooth(origin * CFrame.new(x, 0, 30), lobby)
		Props.PumpkinPile(origin * CFrame.new(x, 0, -32), lobby)
		Props.LampPost(origin * CFrame.new(x, 0, 0), lobby)
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 0.4, 12)
	spawn.CFrame = origin * CFrame.new(0, 0.2, 18)
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = rgb(150, 60, 160)
	spawn.Material = Enum.Material.Neon
	spawn.Parent = lobby
	return origin * CFrame.new(0, 3, 18)
end

local function tryPlace(x: number, z: number, radius: number, build)
	if isFree(x, z, radius) then
		build(at(x, z, rng:NextNumber(0, 360)))
		reserve(x, z, radius)
		return true
	end
	return false
end

local function dressMap(map, pumpkinSpots)
	local dressing = Instance.new("Folder")
	dressing.Name = "SetDressing"
	dressing.Parent = map

	-- A line of dead trees just inside the fence
	for d = -HALF + 20, HALF - 20, 30 do
		for _, spot in { { d, -HALF + 10 }, { d, HALF - 10 }, { -HALF + 10, d }, { HALF - 10, d } } do
			if math.abs(spot[1]) > 30 or math.abs(spot[2]) < HALF - 30 then
				tryPlace(spot[1] + rng:NextNumber(-4, 4), spot[2] + rng:NextNumber(-3, 3), 4, function(cf)
					Props.DeadTree(cf, dressing)
				end)
			end
		end
	end

	-- Behind the game booths: supply crates and barrels
	for i, cf in boothSpots do
		local back = cf * CFrame.new(if i % 2 == 0 then 8 else -8, 0, 6)
		local p = back.Position
		tryPlace(p.X, p.Z, 2.5, function(c)
			if i % 3 == 0 then
				Props.CrateStack(c, dressing)
			else
				Props.Barrel(c, dressing)
			end
		end)
	end

	-- Every Ritual Pumpkin has an offering pile and a scarecrow keeping watch
	for i, s in pumpkinSpots do
		tryPlace(s[1] + 8, s[2] + 5, 3, function(cf)
			Props.PumpkinPile(cf, dressing)
		end)
		if i % 2 == 1 then
			tryPlace(s[1] - 8, s[2] - 6, 2, function(cf)
				Props.Scarecrow(cf, dressing)
			end)
		end
	end

	-- Corn field edge: scarecrows facing the midway
	for z = -225, -110, 38 do
		tryPlace(-88, z, 2, function(cf)
			Props.Scarecrow(cf, dressing)
		end)
	end

	-- Junkyard: tire stacks and oil barrels between the car piles
	for _, s in { { 130, -140 }, { 165, -120 }, { 200, -160 }, { 150, -190 }, { 225, -205 }, { 110, -205 }, { 185, -235 } } do
		tryPlace(s[1], s[2], 3, function(cf)
			Props.TireStack(cf, dressing)
		end)
		tryPlace(s[1] + 5, s[2] + 4, 2, function(cf)
			Props.Barrel(cf, dressing)
		end)
	end

	-- Farm: fenced pumpkin patch, hay stacks along the barn
	Props.LowFence(Vector3.new(-228, 0, 215), Vector3.new(-170, 0, 215), dressing)
	Props.LowFence(Vector3.new(-228, 0, 238), Vector3.new(-170, 0, 238), dressing)
	for i = 0, 3 do
		tryPlace(-190 + i * 7, 150, 3, function(cf)
			Props.HayBale(cf, dressing)
		end)
	end

	-- Graveyard: dead trees around its edge
	for _, s in { { -212, 52 }, { -140, 50 }, { -212, 102 }, { -150, 104 } } do
		tryPlace(s[1], s[2], 3, function(cf)
			Props.DeadTree(cf, dressing)
		end)
	end

	-- Lake shore and the map corners: rock outcrops
	for _, s in { { 128, 160 }, { 222, 150 }, { 140, 222 }, { -228, -228 }, { 228, 228 }, { -228, 228 } } do
		tryPlace(s[1], s[2], 6, function(cf)
			Props.Rocks(cf, dressing)
		end)
	end
end

function MapBuilder.Build()
	local existing = workspace:FindFirstChild("Baseplate")
	if existing then
		existing:Destroy()
	end
	table.clear(reserved)
	table.clear(boothSpots)

	local map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = workspace

	buildTerrain()

	-- Reserve the main paths so clutter doesn't block them
	for i = -HALF, HALF, 10 do
		reserve(0, i, 8)
		reserve(i, 0, 8)
	end

	local result = { Pumpkins = {}, Cages = {}, Pallets = {}, Bells = {}, Gates = {} }

	-- Gameplay objects first so their spots stay clear
	local objectives = Instance.new("Folder")
	objectives.Name = "Objectives"
	objectives.Parent = map

	local pumpkinSpots = { { -167, -178 }, { 167, -165 }, { -150, 0 }, { 157, 0 }, { -152, 175 }, { 95, 205 }, { 45, -95 } }
	for i = 1, Config.Pumpkins.Total do
		local s = pumpkinSpots[i]
		table.insert(result.Pumpkins, Props.RitualPumpkin(at(s[1], s[2], rng:NextNumber(0, 360)), objectives))
		reserve(s[1], s[2], 7)
	end

	for _, s in
		{ { -80, -135 }, { 110, -95 }, { -105, 40 }, { 100, 50 }, { -60, 125 }, { 60, 165 }, { -40, -105 }, { 215, -40 }, { -215, 40 } }
	do
		table.insert(result.Cages, Props.CrowCage(at(s[1], s[2], rng:NextNumber(0, 360)), objectives))
		reserve(s[1], s[2], 6)
	end

	for _, s in { { -220, -60 }, { 220, 60 }, { -60, 228 }, { 60, -228 } } do
		table.insert(result.Bells, Props.Bell(at(s[1], s[2], rng:NextNumber(0, 360)), objectives))
		reserve(s[1], s[2], 4)
	end

	for _, z in { -HALF, HALF } do
		local gate = Props.ExitGate(at(0, z, if z < 0 then 180 else 0), objectives)
		table.insert(result.Gates, gate)
	end

	-- Landmarks and zones
	local landmarks = Instance.new("Folder")
	landmarks.Name = "Landmarks"
	landmarks.Parent = map
	Props.FerrisWheel(at(0, -150), landmarks)
	reserve(0, -150, 24)
	Props.BumperCars(at(-55, -150), landmarks)
	reserve(-55, -150, 24)
	Props.CircusTent(at(150, 0), landmarks)
	reserve(150, 0, 38)
	Props.HauntedManor(at(-150, 0, 90), landmarks)
	reserve(-150, 0, 30)
	Props.FortuneTent(at(-85, 95), landmarks)
	reserve(-85, 95, 9)
	Props.Shack(at(-45, 165, 20), landmarks)
	reserve(-45, 165, 12)
	Props.EntranceArch(at(0, 215), landmarks, "NIGHTMARE FAIR")
	for _, x in { -20, 20 } do
		Props.TicketBooth(at(x, 205), landmarks)
		reserve(x, 205, 6)
	end

	buildCornMaze(landmarks)
	buildJunkyard(landmarks)
	buildGraveyard(landmarks)
	buildFarm(landmarks)
	buildLake(landmarks)
	buildMidway(landmarks)

	-- Chase loops: pallets between crate stacks, and L-walls
	local loops = Instance.new("Folder")
	loops.Name = "Loops"
	loops.Parent = map
	local palletSpots = {
		{ 32, -28, 0 },
		{ -32, 28, 0 },
		{ 72, 40, 90 },
		{ -70, -40, 90 },
		{ 120, -60, 0 },
		{ -118, -55, 0 },
		{ 200, -80, 90 },
		{ -205, -75, 90 },
		{ 195, 60, 0 },
		{ -190, 140, 0 },
		{ 125, 95, 90 },
		{ -110, 125, 90 },
		{ 30, 140, 0 },
		{ -15, 190, 90 },
		{ 75, 228, 0 },
		{ -135, 225, 0 },
		{ 160, -110, 0 },
		{ -60, -200, 90 },
		{ 60, -195, 90 },
		{ 225, 15, 90 },
		{ -228, -20, 90 },
		{ 0, 70, 0 },
	}
	for _, s in palletSpots do
		table.insert(result.Pallets, Props.PalletSpot(at(s[1], s[2], s[3]), loops))
		reserve(s[1], s[2], 11)
	end
	for _, s in
		{
			{ 60, -60, 0 },
			{ -75, 60, 90 },
			{ 90, 90, 180 },
			{ -100, -95, 270 },
			{ 40, 195, 90 },
			{ 195, 105, 0 },
			{ -195, -20, 180 },
			{ 100, -150, 90 },
		}
	do
		if isFree(s[1], s[2], 9) then
			Props.LWall(at(s[1], s[2], s[3]), loops)
			reserve(s[1], s[2], 10)
		end
	end

	buildPathsAndLights(map)
	buildBoundary(map)

	-- Set dressing: every prop is placed on purpose, around the place it belongs to
	dressMap(map, pumpkinSpots)

	-- Spawns
	result.SurvivorSpawns = {
		CFrame.new(-120, 4, -75),
		CFrame.new(120, 4, 110),
		CFrame.new(-110, 4, 215),
		CFrame.new(215, 4, -75),
		CFrame.new(-215, 4, 75),
		CFrame.new(90, 4, -215),
	}
	result.KillerSpawn = CFrame.new(0, 4, -40)
	result.LobbySpawn = buildLobby(map)
	result.Half = HALF
	return result
end

return MapBuilder
