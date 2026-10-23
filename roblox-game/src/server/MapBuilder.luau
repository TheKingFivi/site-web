-- Builds the whole map from code: ground, Critter Road (the conveyor), lamps and 8 player bases.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local MapBuilder = {}

local PLOT_WIDTH = 60
local PLOT_DEPTH = 50
local WALL_HEIGHT = 8
local PLOT_FRONT = 14 -- distance from road center to plot front edge
local PLOT_XS = { -135, -45, 45, 135 }
local PLOT_COLORS = {
	Color3.fromRGB(255, 120, 120),
	Color3.fromRGB(255, 190, 90),
	Color3.fromRGB(250, 240, 110),
	Color3.fromRGB(120, 230, 120),
	Color3.fromRGB(110, 210, 255),
	Color3.fromRGB(140, 140, 255),
	Color3.fromRGB(210, 130, 255),
	Color3.fromRGB(255, 140, 210),
}

MapBuilder.PlotWidth = PLOT_WIDTH
MapBuilder.PlotDepth = PLOT_DEPTH

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

local function billboard(parent: BasePart, text: string, color: Color3, height: number, size: Vector2?)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(size and size.X or 160, size and size.Y or 40)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	gui.MaxDistance = 90
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Name = "Text"
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
	gui.Parent = parent
	return label
end

local function buildPlot(index: number, x: number, side: number, parent: Instance)
	local inward = Vector3.new(0, 0, side)
	local right = Vector3.new(1, 0, 0)
	local front = Vector3.new(x, 0, side * PLOT_FRONT)
	local color = PLOT_COLORS[index]

	local function at(lateral, depth, y)
		return front + right * lateral + inward * depth + Vector3.new(0, y, 0)
	end

	local model = Instance.new("Model")
	model.Name = "Plot" .. index
	model:SetAttribute("PlotIndex", index)
	model.Parent = parent

	newPart({
		Name = "Floor",
		Size = Vector3.new(PLOT_WIDTH, 1, PLOT_DEPTH),
		Position = at(0, PLOT_DEPTH / 2, 0.5),
		Color = Color3.fromRGB(70, 74, 90),
		Material = Enum.Material.Slate,
	}, model)

	local wallProps = { Color = color, Material = Enum.Material.SmoothPlastic, Transparency = 0.15 }
	local function wall(name, size, pos)
		local p = newPart({ Name = name, Size = size, Position = pos }, model)
		for k, v in wallProps do
			p[k] = v
		end
		return p
	end
	local wy = 1 + WALL_HEIGHT / 2
	wall("BackWall", Vector3.new(PLOT_WIDTH, WALL_HEIGHT, 1), at(0, PLOT_DEPTH, wy))
	wall("LeftWall", Vector3.new(1, WALL_HEIGHT, PLOT_DEPTH), at(-PLOT_WIDTH / 2, PLOT_DEPTH / 2, wy))
	wall("RightWall", Vector3.new(1, WALL_HEIGHT, PLOT_DEPTH), at(PLOT_WIDTH / 2, PLOT_DEPTH / 2, wy))
	wall("FrontLeft", Vector3.new(22, WALL_HEIGHT, 1), at(-19, 0.5, wy))
	wall("FrontRight", Vector3.new(22, WALL_HEIGHT, 1), at(19, 0.5, wy))

	local laser = newPart({
		Name = "Laser",
		Size = Vector3.new(16, WALL_HEIGHT, 0.4),
		Position = at(0, 0.5, wy),
		Color = Color3.fromRGB(255, 40, 60),
		Material = Enum.Material.Neon,
		Transparency = 1,
		CanCollide = false,
	}, model)

	local sign = newPart({
		Name = "Sign",
		Size = Vector3.new(16, 3, 0.6),
		Position = at(0, 0.5, 1 + WALL_HEIGHT + 1.5),
		Color = color,
	}, model)
	local surface = Instance.new("SurfaceGui")
	surface.Face = if side == 1 then Enum.NormalId.Front else Enum.NormalId.Back
	surface.LightInfluence = 0
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 40
	local signLabel = Instance.new("TextLabel")
	signLabel.Size = UDim2.fromScale(1, 1)
	signLabel.BackgroundTransparency = 1
	signLabel.Font = Enum.Font.FredokaOne
	signLabel.TextScaled = true
	signLabel.TextColor3 = Color3.new(1, 1, 1)
	signLabel.Text = "Empty Plot"
	local signStroke = Instance.new("UIStroke")
	signStroke.Thickness = 3
	signStroke.Parent = signLabel
	signLabel.Parent = surface
	surface.Parent = sign

	local pedestals = {}
	for row = 1, 4 do
		for col = 1, 5 do
			local pos = at((col - 3) * 10, 6 + row * 8, 1.5)
			local pedestal = newPart({
				Name = "Pedestal" .. ((row - 1) * 5 + col),
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(1, 6, 6),
				CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
				Color = color,
				Material = Enum.Material.Marble,
			}, model)
			local label = billboard(pedestal, "Empty", Color3.fromRGB(200, 200, 200), 1.5, Vector2.new(90, 24))
			table.insert(pedestals, { Part = pedestal, Label = label })
		end
	end

	local collectPad = newPart({
		Name = "CollectPad",
		Size = Vector3.new(6, 0.4, 6),
		Position = at(22, 6, 1.2),
		Color = Color3.fromRGB(60, 255, 120),
		Material = Enum.Material.Neon,
	}, model)
	billboard(collectPad, "💰 COLLECT", Color3.fromRGB(120, 255, 150), 3)

	local lockButton = newPart({
		Name = "LockButton",
		Size = Vector3.new(6, 0.4, 6),
		Position = at(-22, 6, 1.2),
		Color = Color3.fromRGB(80, 160, 255),
		Material = Enum.Material.Neon,
	}, model)
	local lockLabel = billboard(lockButton, "🔒 LOCK BASE", Color3.fromRGB(150, 200, 255), 3)

	local spawnPos = at(0, 8, 4)
	return {
		Index = index,
		Model = model,
		Front = front,
		Inward = inward,
		Right = right,
		Width = PLOT_WIDTH,
		Depth = PLOT_DEPTH,
		Color = color,
		Laser = laser,
		SignLabel = signLabel,
		Pedestals = pedestals,
		CollectPad = collectPad,
		LockButton = lockButton,
		LockLabel = lockLabel,
		SpawnCFrame = CFrame.lookAt(spawnPos, spawnPos - inward),
	}
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
		Size = Vector3.new(700, 2, 700),
		Position = Vector3.new(0, -1, 0),
		Color = Color3.fromRGB(90, 170, 80),
		Material = Enum.Material.Grass,
	}, map)

	local roadLength = (Config.Conveyor.EndX - Config.Conveyor.StartX) + 20
	newPart({
		Name = "CritterRoad",
		Size = Vector3.new(roadLength, Config.Conveyor.RoadTop, 16),
		Position = Vector3.new(0, Config.Conveyor.RoadTop / 2, 0),
		Color = Color3.fromRGB(45, 45, 55),
		Material = Enum.Material.Concrete,
	}, map)
	for _, z in { -8.3, 8.3 } do
		newPart({
			Name = "RoadStripe",
			Size = Vector3.new(roadLength, 0.5, 0.6),
			Position = Vector3.new(0, 0.25, z),
			Color = Color3.fromRGB(255, 220, 60),
			Material = Enum.Material.Neon,
		}, map)
	end

	-- Entrance and exit arches
	for _, x in { Config.Conveyor.StartX - 5, Config.Conveyor.EndX + 5 } do
		newPart(
			{ Name = "ArchL", Size = Vector3.new(2, 14, 2), Position = Vector3.new(x, 7, -9), Color = Color3.fromRGB(120, 80, 200) },
			map
		)
		newPart(
			{ Name = "ArchR", Size = Vector3.new(2, 14, 2), Position = Vector3.new(x, 7, 9), Color = Color3.fromRGB(120, 80, 200) },
			map
		)
		local top = newPart({
			Name = "ArchTop",
			Size = Vector3.new(2, 3, 20),
			Position = Vector3.new(x, 15.5, 0),
			Color = Color3.fromRGB(160, 110, 255),
			Material = Enum.Material.Neon,
		}, map)
		billboard(top, "🐾 CRITTER ROAD", Color3.fromRGB(255, 255, 255), 3, Vector2.new(260, 50))
	end

	-- Lamp posts that light up the night during Moon Raids
	for x = Config.Conveyor.StartX, Config.Conveyor.EndX, 40 do
		for _, z in { -11, 11 } do
			newPart(
				{ Name = "LampPost", Size = Vector3.new(0.6, 10, 0.6), Position = Vector3.new(x, 5, z), Color = Color3.fromRGB(40, 40, 50) },
				map
			)
			local bulb = newPart({
				Name = "LampBulb",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(1.6, 1.6, 1.6),
				Position = Vector3.new(x, 10.5, z),
				Color = Color3.fromRGB(255, 230, 160),
				Material = Enum.Material.Neon,
			}, map)
			local light = Instance.new("PointLight")
			light.Range = 24
			light.Brightness = 1.5
			light.Color = Color3.fromRGB(255, 220, 160)
			light.Parent = bulb
		end
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 0.5, 40)
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = Color3.fromRGB(160, 110, 255)
	spawn.Material = Enum.Material.Neon
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = map

	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = workspace

	local plots = {}
	for _, side in { 1, -1 } do
		for _, x in PLOT_XS do
			table.insert(plots, buildPlot(#plots + 1, x, side, plotsFolder))
		end
	end

	local conveyorFolder = Instance.new("Folder")
	conveyorFolder.Name = "RoadCritters"
	conveyorFolder.Parent = workspace

	return plots
end

return MapBuilder
