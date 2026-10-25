-- Lays out Hollow Acres: a rotting cornfield farm at sunset (400 x 400 studs), DBD Rotten Fields style.
--   center: two-story farmhouse · NW: barn + grain silos · SE: second barn · NE: windmill
--   N: abandoned combine harvester · SW: killer shack · everywhere else: tall walk-through corn
local Props = require(script.Parent.Props)

local MapBuilder = {}

local HALF = 200 -- the map spans -200..200 on X and Z
local rng = Random.new(66613)
local rgb = Color3.fromRGB

local reserved = {} -- { position: Vector3, radius: number } spots corn and props must not overlap

local function at(x: number, z: number, yawDeg: number?)
	return CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yawDeg or 0), 0)
end

local function reserve(x: number, z: number, radius: number)
	table.insert(reserved, { position = Vector3.new(x, 0, z), radius = radius })
end

local function isFree(x: number, z: number, radius: number)
	if math.abs(x) > HALF - 6 or math.abs(z) > HALF - 6 then
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

local function tryPlace(x: number, z: number, radius: number, build)
	if isFree(x, z, radius) then
		build(at(x, z, rng:NextNumber(0, 360)))
		reserve(x, z, radius)
		return true
	end
	return false
end

local terrain = workspace.Terrain

local function paintStrip(from: Vector2, to: Vector2, width: number, material: Enum.Material)
	local a, b = Vector3.new(from.X, -1, from.Y), Vector3.new(to.X, -1, to.Y)
	terrain:FillBlock(CFrame.lookAt((a + b) / 2, b), Vector3.new(width, 2, (b - a).Magnitude + width), material)
end

local function paintCircle(x: number, z: number, radius: number, material: Enum.Material)
	terrain:FillCylinder(CFrame.new(x, -1, z), 2, radius, material)
end

-- A dirt lane: painted mud, kept clear of corn
local function lane(from: Vector2, to: Vector2, width: number)
	paintStrip(from, to, width, Enum.Material.Mud)
	local length = (to - from).Magnitude
	for d = 0, length, width * 0.6 do
		local p = from:Lerp(to, d / length)
		reserve(p.X, p.Y, width * 0.5)
	end
end

local function buildTerrain()
	terrain:Clear()
	terrain:FillBlock(CFrame.new(0, -6, 0), Vector3.new(HALF * 2 + 260, 12, HALF * 2 + 260), Enum.Material.Grass)
	-- Tilled soil under the whole field, with patchy grass
	terrain:FillBlock(CFrame.new(0, -1, 0), Vector3.new(HALF * 2, 2, HALF * 2), Enum.Material.Ground)
	for _ = 1, 60 do
		paintCircle(
			rng:NextNumber(-HALF, HALF),
			rng:NextNumber(-HALF, HALF),
			rng:NextNumber(5, 14),
			if rng:NextNumber() < 0.6 then Enum.Material.LeafyGrass else Enum.Material.Mud
		)
	end
	paintCircle(0, 0, 48, Enum.Material.Grass) -- farmhouse yard
	-- Hills beyond the fence (exit corridors stay open)
	for i = 0, 47 do
		local angle = i / 48 * math.pi * 2
		local dist = HALF + rng:NextNumber(55, 85)
		local x = math.clamp(math.cos(angle) * dist * 1.25, -HALF - 85, HALF + 85)
		local z = math.clamp(math.sin(angle) * dist * 1.25, -HALF - 85, HALF + 85)
		if math.abs(x) > 50 or math.abs(z) < HALF then
			terrain:FillBall(
				Vector3.new(x, -12, z),
				rng:NextNumber(38, 52),
				if rng:NextNumber() < 0.25 then Enum.Material.Rock else Enum.Material.Grass
			)
		end
	end
	pcall(function()
		terrain.Decoration = true
	end)
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

function MapBuilder.Build()
	local existing = workspace:FindFirstChild("Baseplate")
	if existing then
		existing:Destroy()
	end
	table.clear(reserved)

	local map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = workspace
	buildTerrain()

	local result = { Pumpkins = {}, Cages = {}, Pallets = {}, Bells = {}, Gates = {}, Lockers = {} }
	local objectives = Instance.new("Folder")
	objectives.Name = "Objectives"
	objectives.Parent = map
	local buildings = Instance.new("Folder")
	buildings.Name = "Buildings"
	buildings.Parent = map

	local function addLocker(cf: CFrame, style: string?)
		table.insert(result.Lockers, Props.Locker(cf, objectives, style))
	end
	local function addPumpkin(cf: CFrame)
		table.insert(result.Pumpkins, Props.RitualPumpkin(cf, objectives))
		reserve(cf.X, cf.Z, 7)
	end

	-- Lanes through the corn: they wander like real tractor paths instead of running ruler-straight
	local function wander(points, width)
		for i = 1, #points - 1 do
			local a, b = points[i], points[i + 1]
			local mid = (a + b) / 2 + Vector2.new(rng:NextNumber(-10, 10), rng:NextNumber(-10, 10))
			lane(a, mid, width)
			lane(mid, b, width)
		end
	end
	wander({ Vector2.new(0, -HALF), Vector2.new(-8, -110), Vector2.new(0, -45) }, 12)
	wander({ Vector2.new(0, 45), Vector2.new(10, 120), Vector2.new(0, HALF) }, 12)
	wander({ Vector2.new(-HALF + 10, 18), Vector2.new(-110, 6), Vector2.new(-48, 0) }, 9)
	wander({ Vector2.new(48, 0), Vector2.new(110, -14), Vector2.new(HALF - 10, -6) }, 9)
	wander({ Vector2.new(-120, -100), Vector2.new(-75, -70), Vector2.new(-30, -40) }, 9)
	wander({ Vector2.new(125, 95), Vector2.new(85, 70), Vector2.new(38, 40) }, 9)
	wander({ Vector2.new(115, -110), Vector2.new(70, -75), Vector2.new(30, -40) }, 8)
	wander({ Vector2.new(-125, 120), Vector2.new(-80, 80), Vector2.new(-36, 38) }, 8)
	wander({ Vector2.new(-170, -150), Vector2.new(-90, -160), Vector2.new(-45, -150) }, 7)
	wander({ Vector2.new(60, 150), Vector2.new(120, 160), Vector2.new(175, 150) }, 7)

	-- The farmhouse (main building), porch facing the south gate
	local house = Props.Farmhouse(at(0, 0, 180), buildings)
	reserve(0, 0, 42)
	for _, cf in house.Lockers do
		addLocker(cf, "wood")
	end
	addPumpkin(house.Pumpkin)

	-- Barns
	local barnA, barnB = at(-120, -100, 90), at(125, 95, 0)
	Props.Barn(barnA, buildings)
	Props.Barn(barnB, buildings)
	reserve(-120, -100, 26)
	reserve(125, 95, 26)
	addPumpkin(barnA * CFrame.new(6, 0, 0))
	addPumpkin(barnB * CFrame.new(6, 0, 0))
	for _, barn in { barnA, barnB } do
		addLocker(barn * CFrame.new(11, 0.5, 10.5), "metal")
		addLocker(barn * CFrame.new(-11, 0.5, -10.5) * CFrame.Angles(0, math.pi, 0), "metal")
	end
	for _, s in { { -160, -55 }, { -178, -62 }, { -165, -78 } } do
		Props.Silo(at(s[1], s[2], rng:NextNumber(0, 360)), buildings)
		reserve(s[1], s[2], 9)
	end
	addLocker(at(-150, -66, 120), "metal")
	reserve(-150, -66, 4)

	-- Windmill, combine, killer shack, outhouse, tractors
	Props.Windmill(at(115, -110, 200), buildings)
	reserve(115, -110, 9)
	addLocker(at(106, -102, 135), "metal")
	reserve(106, -102, 4)
	Props.Combine(at(-45, -160, 25), buildings)
	reserve(-45, -160, 17)
	addLocker(at(-26, -170, 200), "metal")
	reserve(-26, -170, 4)
	local shack = at(-125, 120, 20)
	Props.Shack(shack, buildings)
	reserve(-125, 120, 13)
	addPumpkin(shack * CFrame.new(1, 0, 1))
	addLocker(shack * CFrame.new(-5.2, 0.5, 5.4), "metal")
	Props.Outhouse(at(48, 55, 200), buildings)
	reserve(48, 55, 5)
	Props.Tractor(at(62, -42, 70), buildings)
	reserve(62, -42, 7)
	Props.Tractor(at(-68, 44, 250), buildings)
	reserve(-68, 44, 7)

	-- Corn clearings with Ritual Pumpkins
	for _, s in { { 78, -92 }, { -70, 95 }, { 150, 12 } } do
		reserve(s[1], s[2], 14)
		addPumpkin(at(s[1], s[2], rng:NextNumber(0, 360)))
		paintCircle(s[1], s[2], 13, Enum.Material.Mud)
	end

	-- Crow Cages
	for _, s in { { -40, -62 }, { 40, -72 }, { -92, -18 }, { 92, 26 }, { -40, 132 }, { 42, 140 }, { -160, 30 }, { 165, -60 } } do
		table.insert(result.Cages, Props.CrowCage(at(s[1], s[2], rng:NextNumber(0, 360)), objectives))
		reserve(s[1], s[2], 7)
	end

	-- Ghost bells in the four corners
	for _, s in { { -172, -172 }, { 172, -172 }, { -172, 172 }, { 172, 172 } } do
		table.insert(result.Bells, Props.Bell(at(s[1], s[2], rng:NextNumber(0, 360)), objectives))
		reserve(s[1], s[2], 5)
	end

	-- Exit gates north and south
	for _, z in { -HALF, HALF } do
		table.insert(result.Gates, Props.ExitGate(at(0, z, if z < 0 then 180 else 0), objectives))
	end

	-- Pallets at the edge of lanes and around buildings (chase loops)
	local loops = Instance.new("Folder")
	loops.Name = "Loops"
	loops.Parent = map
	for _, s in
		{
			{ 22, -40, 90 },
			{ -24, 42, 90 },
			{ -60, 0, 0 },
			{ 60, 0, 0 },
			{ -95, -70, 45 },
			{ 98, 68, 45 },
			{ -150, -120, 0 },
			{ 150, 125, 0 },
			{ 85, -135, 90 },
			{ -85, 150, 90 },
			{ 0, -75, 0 },
			{ 0, 80, 0 },
			{ -175, -10, 90 },
			{ 178, -15, 90 },
			{ -110, 165, 0 },
			{ 120, -165, 0 },
		}
	do
		table.insert(result.Pallets, Props.PalletSpot(at(s[1], s[2], s[3]), loops))
		reserve(s[1], s[2], 11)
	end
	for _, s in { { 30, 110, 0 }, { -38, -112, 90 }, { 140, -30, 180 }, { -140, 60, 270 } } do
		if isFree(s[1], s[2], 9) then
			Props.LWall(at(s[1], s[2], s[3]), loops)
			reserve(s[1], s[2], 10)
		end
	end

	-- Set dressing around the buildings
	local dressing = Instance.new("Folder")
	dressing.Name = "SetDressing"
	dressing.Parent = map
	for _, s in { { -100, -125 }, { -140, -80 }, { 145, 75 }, { 105, 120 } } do
		tryPlace(s[1], s[2], 7, function(cf)
			Props.HayStack(cf, dressing)
		end)
	end
	for _, s in { { -60, -150 }, { -30, -145 }, { 75, -50 }, { -82, 50 } } do
		tryPlace(s[1], s[2], 2.5, function(cf)
			Props.TireStack(cf, dressing)
		end)
	end
	for _, s in { { 25, 38 }, { -28, -36 }, { 30, -38 }, { -30, 30 } } do
		tryPlace(s[1], s[2], 3, function(cf)
			Props.CrateStack(cf, dressing)
		end)
	end
	for _, cage in result.Cages do
		tryPlace(cage.Position.X + 6, cage.Position.Z - 5, 2, function(cf)
			Props.Barrel(cf, dressing)
		end)
	end
	for _, pumpkin in result.Pumpkins do
		tryPlace(pumpkin.Position.X + 8, pumpkin.Position.Z + 5, 3, function(cf)
			Props.PumpkinPile(cf, dressing)
		end)
	end
	Props.LowFence(Vector3.new(-48, 0, 48), Vector3.new(-48, 0, -48), dressing)
	Props.LowFence(Vector3.new(48, 0, -48), Vector3.new(48, 0, 20), dressing)

	-- Work lights by the barn doors and the farmhouse yard
	for _, cf in { barnA * CFrame.new(-8, 0, -16), barnB * CFrame.new(-8, 0, -16), at(-30, 34, 0), at(30, -34, 180), at(-112, 112, 45) } do
		Props.LampPost(cf, dressing)
	end

	-- Scarecrows standing in the corn
	for _ = 1, 14 do
		tryPlace(rng:NextNumber(-HALF + 20, HALF - 20), rng:NextNumber(-HALF + 20, HALF - 20), 3, function(cf)
			Props.Scarecrow(cf, dressing)
		end)
	end

	buildBoundary(map)

	-- Finally, plant the corn in everything that's left
	local corn = Instance.new("Folder")
	corn.Name = "Cornfield"
	corn.Parent = map
	Props.CornField(-HALF + 6, -HALF + 6, HALF - 6, HALF - 6, corn, isFree)

	result.SurvivorSpawns = {
		CFrame.new(-150, 4, -150),
		CFrame.new(150, 4, 150),
		CFrame.new(-160, 4, 150),
		CFrame.new(160, 4, -150),
		CFrame.new(-175, 4, 60),
		CFrame.new(175, 4, -100),
	}
	result.KillerSpawn = CFrame.new(0, 4, -58)
	result.LobbySpawn = buildLobby(map)
	result.Half = HALF
	return result
end

return MapBuilder
