-- The snowy lobby outside Frostline Central: party pads, skin pedestals, shop, daily rewards.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Build = require(script.Parent.Build)
local SkinLook = require(script.Parent.SkinLook)

local LobbyBuilder = {}

local SNOW = Color3.fromRGB(236, 242, 250)
local ROAD = Color3.fromRGB(44, 46, 54)
local WALL = Color3.fromRGB(206, 200, 186)
local NAVY = Color3.fromRGB(30, 46, 100)
local ORANGE = Color3.fromRGB(255, 130, 20)
local PAD_COLORS =
	{ Color3.fromRGB(255, 220, 40), Color3.fromRGB(40, 230, 255), Color3.fromRGB(255, 220, 40), Color3.fromRGB(40, 230, 255) }

local function billboard(parent: BasePart, size: UDim2, offset: Vector3, distance: number?): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Size = size
	gui.StudsOffsetWorldSpace = offset
	gui.MaxDistance = distance or 160
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.Parent = parent
	return gui
end

local function lamp(parent: Instance, cf: CFrame)
	local pro = Build.swap(parent, "StreetLamp", cf, Vector3.new(6, 17, 6))
	if pro then
		local glow = Build.ghost(parent, Vector3.new(1, 1, 1), cf * CFrame.new(0, 15, -2))
		Build.spotLight(glow, Enum.NormalId.Bottom, Color3.fromRGB(255, 226, 190), 40, 2.6, 110)
		return
	end
	Build.part(parent, Vector3.new(0.7, 16, 0.7), cf * CFrame.new(0, 8, 0), Color3.fromRGB(30, 32, 38), Enum.Material.Metal)
	Build.part(parent, Vector3.new(0.4, 0.4, 5), cf * CFrame.new(0, 16, -2.4), Color3.fromRGB(30, 32, 38), Enum.Material.Metal)
	local head =
		Build.part(parent, Vector3.new(1.6, 0.5, 2.6), cf * CFrame.new(0, 15.7, -4.6), Color3.fromRGB(255, 236, 200), Enum.Material.Neon)
	Build.spotLight(head, Enum.NormalId.Bottom, Color3.fromRGB(255, 226, 190), 40, 2.6, 110)
end

local function pine(parent: Instance, cf: CFrame, h: number, rng: Random)
	if Build.swap(parent, "PineTree", cf * CFrame.Angles(0, rng:NextNumber(0, 6), 0), Vector3.new(h * 0.6, h, h * 0.6)) then
		return
	end
	Build.part(parent, Vector3.new(1.4, h * 0.3, 1.4), cf * CFrame.new(0, h * 0.15, 0), Color3.fromRGB(70, 50, 36), Enum.Material.Wood)
	for tier = 0, 2 do
		local size = h * (0.55 - tier * 0.15)
		local cone = Build.ball(
			parent,
			size,
			cf * CFrame.new(0, h * (0.3 + tier * 0.22), 0) * CFrame.Angles(0, rng:NextNumber(0, 3), 0),
			Color3.fromRGB(30, 62, 44),
			Enum.Material.Grass
		)
		cone.Size = Vector3.new(size, h * 0.3, size)
		local cap = Build.part(
			parent,
			Vector3.new(h * 0.08, size * 0.75, size * 0.75),
			cf * CFrame.new(0, h * (0.3 + tier * 0.22) + h * 0.11, 0) * CFrame.Angles(0, 0, math.pi / 2),
			SNOW,
			Enum.Material.Snow
		)
		cap.Shape = Enum.PartType.Cylinder
	end
end

local function jackOLantern(parent: Instance, cf: CFrame, size: number)
	if Build.swap(parent, "Pumpkin", cf, Vector3.new(size * 1.3, size * 1.3, size * 1.3)) then
		return
	end
	local body = Build.ball(parent, size, cf * CFrame.new(0, size * 0.4, 0), ORANGE)
	body.Size = Vector3.new(size * 1.2, size * 0.85, size * 1.2)
	Build.part(parent, Vector3.new(0.2, 0.5, 0.2) * size, cf * CFrame.new(0, size * 0.9, 0), Color3.fromRGB(60, 90, 30))
	for _, x in { -0.22, 0.22 } do
		local eye = Build.wedge(
			parent,
			Vector3.new(0.05, 0.2, 0.22) * size,
			cf * CFrame.new(x * size, size * 0.5, -size * 0.58) * CFrame.Angles(0, math.pi / 2, 0),
			Color3.fromRGB(255, 220, 90),
			Enum.Material.Neon
		)
		eye.CanCollide = false
	end
	local mouth = Build.part(
		parent,
		Vector3.new(0.6, 0.14, 0.05) * size,
		cf * CFrame.new(0, size * 0.3, -size * 0.6),
		Color3.fromRGB(255, 220, 90),
		Enum.Material.Neon
	)
	mouth.CanCollide = false
	Build.pointLight(mouth, Color3.fromRGB(255, 150, 40), 10 + size * 2, 1.6)
end

local function candle(parent: Instance, cf: CFrame, h: number)
	Build.cyl(parent, h, 0.6, cf * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(245, 240, 220))
	local flame = Build.ball(parent, 0.35, cf * CFrame.new(0, h + 0.25, 0), Color3.fromRGB(255, 200, 80), Enum.Material.Neon)
	flame.CanCollide = false
	flame.Size = Vector3.new(0.25, 0.45, 0.25)
	Build.pointLight(flame, Color3.fromRGB(255, 170, 70), 7, 0.9)
end

local function facade(parent: Instance)
	local f = Build.model(parent, "Facade")
	local z = -78
	Build.part(f, Vector3.new(170, 34, 16), CFrame.new(0, 17, z), WALL, Enum.Material.Plaster)
	Build.part(f, Vector3.new(172, 2, 18), CFrame.new(0, 35, z), Color3.fromRGB(60, 64, 74), Enum.Material.Slate)
	Build.part(f, Vector3.new(170.4, 2, 0.4), CFrame.new(0, 8, z + 8.1), NAVY)
	-- Clock tower
	Build.part(f, Vector3.new(22, 56, 18), CFrame.new(0, 28, z - 2), WALL, Enum.Material.Plaster)
	Build.wedge(f, Vector3.new(24, 10, 10), CFrame.new(0, 61, z + 3), Color3.fromRGB(60, 64, 74), Enum.Material.Slate)
	Build.wedge(
		f,
		Vector3.new(24, 10, 10),
		CFrame.new(0, 61, z - 7) * CFrame.Angles(0, math.pi, 0),
		Color3.fromRGB(60, 64, 74),
		Enum.Material.Slate
	)
	local clock = Build.cyl(
		f,
		1,
		13,
		CFrame.new(0, 44, z + 7.3) * CFrame.Angles(0, math.pi / 2, 0),
		Color3.fromRGB(250, 246, 230),
		Enum.Material.SmoothPlastic
	)
	Build.label(clock, Enum.NormalId.Left, "XII", Color3.fromRGB(20, 20, 20), Enum.Font.Antique)
	Build.pointLight(clock, Color3.fromRGB(255, 240, 200), 30, 1.5)
	Build.part(f, Vector3.new(0.4, 5, 0.3), CFrame.new(0, 45.8, z + 8), Color3.fromRGB(20, 20, 20))
	Build.part(f, Vector3.new(3.8, 0.4, 0.3), CFrame.new(1.6, 44, z + 8), Color3.fromRGB(20, 20, 20))
	-- Name sign
	local sign = Build.part(f, Vector3.new(60, 6, 1), CFrame.new(0, 28, z + 8.6), Color3.fromRGB(150, 24, 30))
	Build.label(sign, Enum.NormalId.Back, "FROSTLINE CENTRAL", Color3.fromRGB(255, 244, 230), Enum.Font.GothamBlack)
	Build.label(sign, Enum.NormalId.Front, "FROSTLINE CENTRAL", Color3.fromRGB(255, 244, 230), Enum.Font.GothamBlack)
	Build.pointLight(sign, Color3.fromRGB(255, 120, 100), 24, 1)
	-- Tall arched windows
	for _, x in { -70, -55, -40, 40, 55, 70 } do
		local w = Build.part(f, Vector3.new(8, 16, 0.6), CFrame.new(x, 18, z + 8.1), Color3.fromRGB(255, 214, 140), Enum.Material.Neon)
		w.Transparency = 0.15
		local top = Build.cyl(
			f,
			0.6,
			8,
			CFrame.new(x, 26, z + 8.1) * CFrame.Angles(0, math.pi / 2, 0),
			Color3.fromRGB(255, 214, 140),
			Enum.Material.Neon
		)
		top.Transparency = 0.15
		for k = -1, 1 do
			Build.part(f, Vector3.new(0.3, 16, 0.7), CFrame.new(x + k * 2.6, 18, z + 8.2), Color3.fromRGB(40, 40, 44))
		end
		Build.part(f, Vector3.new(8, 0.3, 0.7), CFrame.new(x, 18, z + 8.2), Color3.fromRGB(40, 40, 44))
	end
	-- Main doors, one per party pad
	for i, x in { -48, -16, 16, 48 } do
		Build.part(f, Vector3.new(12, 14, 0.8), CFrame.new(x, 7, z + 8.2), Color3.fromRGB(34, 38, 48), Enum.Material.Metal)
		for _, dx in { -3, 3 } do
			local glass =
				Build.part(f, Vector3.new(4.6, 11, 0.9), CFrame.new(x + dx, 6, z + 8.3), Color3.fromRGB(120, 160, 200), Enum.Material.Glass)
			glass.Transparency = 0.4
		end
		local num = Build.part(f, Vector3.new(6, 2.4, 0.5), CFrame.new(x, 15.6, z + 8.5), Color3.fromRGB(20, 20, 24))
		Build.label(num, Enum.NormalId.Back, "GATE " .. i, PAD_COLORS[i], Enum.Font.GothamBlack)
	end
	-- Halloween bunting along the roof
	for i = 0, 40 do
		local x = -84 + i * 4.2
		local flag = Build.wedge(
			f,
			Vector3.new(0.1, 2, 2),
			CFrame.new(x, 32, z + 8.6) * CFrame.Angles(0, math.pi / 2, math.pi),
			if i % 2 == 0 then ORANGE else Color3.fromRGB(110, 50, 170)
		)
		flag.CanCollide = false
	end
end

local function partyPad(parent: Instance, index: number, center: Vector3)
	local m = Build.model(parent, "PartyPad" .. index)
	local color = PAD_COLORS[index]
	local size = Vector3.new(22, 0, 16)
	Build.part(
		m,
		Vector3.new(size.X, 0.2, size.Z),
		CFrame.new(center + Vector3.new(0, 0.1, 0)),
		Color3.fromRGB(28, 30, 36),
		Enum.Material.SmoothPlastic
	)
	-- Glowing outline + light
	for _, side in
		{
			{ Vector3.new(size.X, 0.25, 0.6), Vector3.new(0, 0.2, size.Z / 2) },
			{ Vector3.new(size.X, 0.25, 0.6), Vector3.new(0, 0.2, -size.Z / 2) },
			{ Vector3.new(0.6, 0.25, size.Z), Vector3.new(size.X / 2, 0.2, 0) },
			{ Vector3.new(0.6, 0.25, size.Z), Vector3.new(-size.X / 2, 0.2, 0) },
		}
	do
		local edge = Build.part(m, side[1], CFrame.new(center + side[2]), color, Enum.Material.Neon)
		edge.CanCollide = false
	end
	local glow = Build.part(m, Vector3.new(1, 1, 1), CFrame.new(center + Vector3.new(0, 1, 0)), color)
	glow.Transparency = 1
	glow.CanCollide = false
	Build.pointLight(glow, color, 22, 1.4)
	-- Translucent glow walls
	for _, side in
		{
			{ Vector3.new(size.X, 3, 0.1), Vector3.new(0, 1.6, size.Z / 2) },
			{ Vector3.new(size.X, 3, 0.1), Vector3.new(0, 1.6, -size.Z / 2) },
			{ Vector3.new(0.1, 3, size.Z), Vector3.new(size.X / 2, 1.6, 0) },
			{ Vector3.new(0.1, 3, size.Z), Vector3.new(-size.X / 2, 1.6, 0) },
		}
	do
		local wall = Build.part(m, side[1], CFrame.new(center + side[2]), color, Enum.Material.Neon)
		wall.Transparency = 0.82
		wall.CanCollide = false
		wall.CanQuery = false
	end
	-- Board on a post: "0/4 · STEP IN"
	local post = Build.part(
		m,
		Vector3.new(0.6, 12, 0.6),
		CFrame.new(center + Vector3.new(0, 6, -size.Z / 2 - 1)),
		Color3.fromRGB(30, 30, 36),
		Enum.Material.Metal
	)
	local gui = billboard(post, UDim2.fromOffset(240, 120), Vector3.new(0, 8.5, 0), 220)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(245, 247, 252)
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 4
	stroke.Color = Color3.fromRGB(20, 26, 48)
	stroke.Parent = frame
	local count = Instance.new("TextLabel")
	count.Name = "Count"
	count.Size = UDim2.fromScale(1, 0.62)
	count.BackgroundTransparency = 1
	count.Font = Enum.Font.FredokaOne
	count.TextScaled = true
	count.TextColor3 = Color3.fromRGB(20, 26, 48)
	count.Text = "0/4"
	count.Parent = frame
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.fromScale(1, 0.32)
	status.Position = UDim2.fromScale(0, 0.62)
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.FredokaOne
	status.TextScaled = true
	status.TextColor3 = Color3.fromRGB(20, 26, 48)
	status.Text = "STEP IN"
	status.Parent = frame
	-- Bouncing arrow (animated on clients)
	local arrow = Build.wedge(
		m,
		Vector3.new(1.2, 3, 3),
		CFrame.new(center + Vector3.new(0, 9, 0)) * CFrame.Angles(math.pi, 0, 0),
		Color3.fromRGB(40, 140, 255),
		Enum.Material.Neon
	)
	arrow.CanCollide = false
	local shaft = Build.part(
		m,
		Vector3.new(1.2, 2.4, 1.2),
		CFrame.new(center + Vector3.new(0, 11.6, 0.6)),
		Color3.fromRGB(40, 140, 255),
		Enum.Material.Neon
	)
	shaft.CanCollide = false
	CollectionService:AddTag(arrow, "BounceArrow")
	CollectionService:AddTag(shaft, "BounceArrow")
	return { Index = index, Center = center, Size = size, Count = count, Status = status, Model = m }
end

local function pedestal(parent: Instance, cf: CFrame, skin, color: Color3)
	local m = Build.model(parent, "Pedestal_" .. skin.Key)
	Build.cyl(m, 1.4, 7, cf * CFrame.new(0, 0.7, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(34, 34, 40), Enum.Material.Slate)
	local ring = Build.cyl(m, 0.3, 7.3, cf * CFrame.new(0, 1.3, 0) * CFrame.Angles(0, 0, math.pi / 2), color, Enum.Material.Neon)
	ring.CanCollide = false
	Build.pointLight(ring, color, 12, 1.4)
	local man = SkinLook.Mannequin(m, cf * CFrame.new(0, 1.45, 0), skin.Key)
	local _ = man
	local tagPart = Build.part(
		m,
		Vector3.new(2.6, 1, 0.3),
		cf * CFrame.new(0, 1.2, -3.6) * CFrame.Angles(math.rad(-25), 0, 0),
		Color3.fromRGB(16, 16, 20)
	)
	local price = if skin.Price == 0 then "FREE" else (if skin.Currency == "Candy" then "🍬 " else "$") .. skin.Price
	Build.label(
		tagPart,
		Enum.NormalId.Front,
		price,
		if skin.Currency == "Candy" then ORANGE else Color3.fromRGB(110, 255, 140),
		Enum.Font.GothamBlack
	)
	local base = m:FindFirstChildWhichIsA("BasePart") :: BasePart
	local nameGui = billboard(base, UDim2.fromOffset(200, 40), Vector3.new(0, 9.4, 0), 90)
	local name = Instance.new("TextLabel")
	name.Size = UDim2.fromScale(1, 1)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.FredokaOne
	name.TextScaled = true
	name.TextColor3 = if skin.Halloween then Color3.fromRGB(255, 190, 60) else Color3.fromRGB(150, 230, 255)
	name.TextStrokeTransparency = 0.3
	name.Text = skin.Name
	name.Parent = nameGui
	local prompt = Build.prompt(base, "View Skins", skin.Name, 0, 10)
	prompt:SetAttribute("Skin", skin.Key)
	return m
end

function LobbyBuilder.Build(parent: Instance)
	local lobby = Build.model(parent, "Lobby")
	local markers = { Pads = {} }
	-- Ground: snow with a cleared road and plaza
	Build.part(lobby, Vector3.new(420, 2, 420), CFrame.new(0, -1, 0), SNOW, Enum.Material.Snow)
	Build.part(lobby, Vector3.new(170, 0.2, 60), CFrame.new(0, 0.1, -40), ROAD, Enum.Material.Asphalt)
	Build.part(lobby, Vector3.new(30, 0.2, 110), CFrame.new(0, 0.1, 25), ROAD, Enum.Material.Asphalt)
	for z = -5, 75, 10 do
		Build.part(lobby, Vector3.new(0.6, 0.22, 5), CFrame.new(0, 0.12, z), Color3.fromRGB(240, 240, 240))
	end
	-- Sidewalk curbs with snow banks
	for _, x in { -16, 16 } do
		Build.part(lobby, Vector3.new(2, 1.2, 110), CFrame.new(x, 0.6, 25), Color3.fromRGB(160, 162, 170), Enum.Material.Concrete)
	end
	facade(lobby)
	for i, x in { -48, -16, 16, 48 } do
		markers.Pads[i] = partyPad(lobby, i, Vector3.new(x, 0.2, -50))
	end

	-- HALLOWEEN SKINS row (west) with a bat-wing arch
	local skins = Build.model(lobby, "Skins")
	local halloween, standard = {}, {}
	for _, skin in Config.Skins do
		table.insert(if skin.Halloween then halloween else standard, skin)
	end
	for i, skin in halloween do
		pedestal(skins, CFrame.new(-60, 0, -12 + i * 12) * CFrame.Angles(0, -math.pi / 2, 0), skin, ORANGE)
		jackOLantern(skins, CFrame.new(-52, 0, -6 + i * 12), 2)
		candle(skins, CFrame.new(-53, 0, -9 + i * 12), 1.6)
		candle(skins, CFrame.new(-52.2, 0, -10 + i * 12), 1)
	end
	local arch = Build.part(skins, Vector3.new(1, 7, 40), CFrame.new(-66, 18, 24), Color3.fromRGB(26, 14, 10))
	Build.label(arch, Enum.NormalId.Right, "🎃 Halloween Skins\nCollect Candy · Unlock Skins", ORANGE, Enum.Font.Creepster)
	Build.pointLight(arch, ORANGE, 30, 1.4)
	for _, dz in { -22, 22 } do
		Build.wedge(
			skins,
			Vector3.new(1, 8, 12),
			CFrame.new(-66, 20, 24 + dz) * CFrame.Angles(0, if dz > 0 then 0 else math.pi, 0),
			Color3.fromRGB(26, 14, 10)
		)
	end
	for _, z in { 2, 46 } do
		Build.part(skins, Vector3.new(1.2, 22, 1.2), CFrame.new(-66, 11, z), Color3.fromRGB(26, 14, 10), Enum.Material.Wood)
	end
	-- UNIFORMS row (east)
	for i, skin in standard do
		pedestal(skins, CFrame.new(60, 0, -12 + i * 12) * CFrame.Angles(0, math.pi / 2, 0), skin, Color3.fromRGB(40, 200, 255))
	end
	local uniSign = Build.part(skins, Vector3.new(1, 5, 30), CFrame.new(66, 16, 24), NAVY)
	Build.label(uniSign, Enum.NormalId.Left, "OFFICER UNIFORMS", Color3.fromRGB(150, 230, 255), Enum.Font.GothamBlack)
	for _, z in { 10, 38 } do
		Build.part(skins, Vector3.new(1, 18, 1), CFrame.new(66, 9, z), Color3.fromRGB(30, 30, 36), Enum.Material.Metal)
	end

	-- Shop kiosk
	local shop = Build.model(lobby, "Shop")
	Build.part(shop, Vector3.new(16, 9, 10), CFrame.new(34, 4.5, 40), Color3.fromRGB(30, 40, 80), Enum.Material.SmoothPlastic)
	Build.part(shop, Vector3.new(18, 1, 12), CFrame.new(34, 9.5, 40), Color3.fromRGB(240, 240, 250))
	local window = Build.part(shop, Vector3.new(12, 4, 0.3), CFrame.new(34, 5, 45.1), Color3.fromRGB(120, 230, 255), Enum.Material.Neon)
	window.Transparency = 0.2
	local shopSign = Build.part(shop, Vector3.new(14, 3, 0.4), CFrame.new(34, 12, 45), Color3.fromRGB(20, 20, 24))
	Build.label(shopSign, Enum.NormalId.Back, "🛒 STATION SHOP", Color3.fromRGB(120, 230, 255), Enum.Font.GothamBlack)
	Build.pointLight(window, Color3.fromRGB(120, 230, 255), 22, 1.6)
	markers.ShopPrompt = Build.prompt(window, "Shop", "Station Shop", 0, 12)

	-- Daily rewards board
	local daily = Build.model(lobby, "Daily")
	Build.part(daily, Vector3.new(14, 9, 1), CFrame.new(-34, 6.5, 40) * CFrame.Angles(0, math.rad(200), 0), Color3.fromRGB(20, 20, 24))
	local dailyFace = Build.part(
		daily,
		Vector3.new(13, 8, 0.2),
		CFrame.new(-34, 6.5, 40) * CFrame.Angles(0, math.rad(200), 0) * CFrame.new(0, 0, -0.6),
		Color3.fromRGB(255, 196, 40),
		Enum.Material.Neon
	)
	Build.label(dailyFace, Enum.NormalId.Front, "🎁 DAILY\nREWARDS", Color3.fromRGB(30, 20, 10), Enum.Font.GothamBlack)
	for _, x in { -5.5, 5.5 } do
		Build.part(
			daily,
			Vector3.new(0.6, 6, 0.6),
			CFrame.new(-34, 0, 40) * CFrame.Angles(0, math.rad(200), 0) * CFrame.new(x, 1, 0),
			Color3.fromRGB(30, 30, 36)
		)
	end
	markers.DailyPrompt = Build.prompt(dailyFace, "Claim", "Daily Reward", 0, 12)

	-- Street lamps, trees, fences, pumpkins
	for z = -20, 70, 18 do
		lamp(lobby, CFrame.new(-18, 0, z) * CFrame.Angles(0, -math.pi / 2, 0))
		lamp(lobby, CFrame.new(18, 0, z) * CFrame.Angles(0, math.pi / 2, 0))
	end
	local rng = Random.new(7)
	for _ = 1, 90 do
		local x = rng:NextNumber(-200, 200)
		local z = rng:NextNumber(-200, 200)
		if math.abs(x) > 80 or z > 90 or z < -95 then
			pine(lobby, CFrame.new(x, 0, z), rng:NextNumber(18, 36), rng)
		end
	end
	for z = -60, 85, 6 do
		for _, x in { -80, 80 } do
			Build.part(lobby, Vector3.new(0.5, 5, 0.5), CFrame.new(x, 2.5, z), Color3.fromRGB(30, 30, 34), Enum.Material.Metal)
			Build.part(lobby, Vector3.new(0.3, 0.3, 6), CFrame.new(x, 4.6, z + 3), Color3.fromRGB(30, 30, 34), Enum.Material.Metal)
			Build.part(lobby, Vector3.new(0.3, 0.3, 6), CFrame.new(x, 1.4, z + 3), Color3.fromRGB(30, 30, 34), Enum.Material.Metal)
		end
	end
	for _, pos in
		{
			Vector3.new(-22, 0, -20),
			Vector3.new(22, 0, -20),
			Vector3.new(-24, 0, 10),
			Vector3.new(24, 0, 10),
			Vector3.new(-12, 0, 62),
			Vector3.new(12, 0, 62),
		}
	do
		jackOLantern(lobby, CFrame.new(pos), 2.6)
	end
	-- Snow particles over the lobby
	local emitterPart = Build.part(lobby, Vector3.new(260, 1, 260), CFrame.new(0, 70, 0), Color3.new(1, 1, 1))
	emitterPart.Transparency = 1
	emitterPart.CanCollide = false
	emitterPart.CanQuery = false
	local snow = Instance.new("ParticleEmitter")
	snow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	snow.Rate = 260
	snow.Lifetime = NumberRange.new(14, 18)
	snow.Speed = NumberRange.new(4, 6)
	snow.Size = NumberSequence.new(0.35)
	snow.EmissionDirection = Enum.NormalId.Bottom
	snow.Acceleration = Vector3.new(1.5, 0, 1)
	snow.LightEmission = 0.3
	snow.Parent = emitterPart

	-- Spawn
	local spawn = Instance.new("SpawnLocation")
	spawn.Size = Vector3.new(12, 0.4, 12)
	spawn.CFrame = CFrame.new(0, 0.3, 60)
	spawn.Anchored = true
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = lobby
	markers.Spawn = CFrame.new(0, 3, 60) * CFrame.Angles(0, 0, 0)
	return markers
end

return LobbyBuilder
