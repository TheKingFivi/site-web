-- Builds one Frostline checkpoint station: 4 inspection lanes, back rooms, and the snowy train platform.
-- Returns a table of markers (spawn points, passenger paths, prompts) used by the shift logic.
local CollectionService = game:GetService("CollectionService")

local Build = require(script.Parent.Build)

local StationBuilder = {}

local C = {
	Wall = Color3.fromRGB(206, 200, 186),
	WallDark = Color3.fromRGB(150, 146, 136),
	Stripe = Color3.fromRGB(32, 54, 120),
	Floor = Color3.fromRGB(70, 82, 112),
	FloorOfficer = Color3.fromRGB(96, 100, 110),
	Ceiling = Color3.fromRGB(214, 216, 222),
	Counter = Color3.fromRGB(116, 120, 138),
	CounterTop = Color3.fromRGB(176, 180, 192),
	Metal = Color3.fromRGB(160, 166, 176),
	DarkMetal = Color3.fromRGB(46, 48, 56),
	Glass = Color3.fromRGB(190, 220, 235),
	Screen = Color3.fromRGB(16, 30, 26),
	Wood = Color3.fromRGB(110, 78, 52),
	Snow = Color3.fromRGB(236, 242, 250),
	Locker = Color3.fromRGB(150, 40, 40),
	Seat = Color3.fromRGB(40, 90, 190),
	Orange = Color3.fromRGB(255, 130, 20),
	Purple = Color3.fromRGB(110, 50, 170),
}

local LANE_X = { -36, -12, 12, 36 }
local HALL = { X0 = -50, X1 = 50, Z0 = -42, Z1 = 54, H = 16 }

local function addPrompt(parent, action, object, hold, distance)
	local prompt = Build.prompt(parent, action, object, hold, distance or 7)
	prompt.Enabled = false
	return prompt
end

local function monitor(parent: Instance, cf: CFrame, width: number, height: number, title: string): (Part, TextLabel)
	Build.part(parent, Vector3.new(0.4, 1, 0.4), cf * CFrame.new(0, -height / 2 - 0.5, 0.2), C.DarkMetal)
	Build.part(parent, Vector3.new(1.4, 0.15, 0.9), cf * CFrame.new(0, -height / 2 - 1, 0.2), C.DarkMetal)
	Build.part(parent, Vector3.new(width + 0.3, height + 0.3, 0.3), cf * CFrame.new(0, 0, 0.12), C.DarkMetal)
	local screen = Build.part(parent, Vector3.new(width, height, 0.1), cf, C.Screen, Enum.Material.Neon)
	screen.Transparency = 0.05
	local label = Build.label(screen, Enum.NormalId.Front, title, Color3.fromRGB(90, 255, 160), Enum.Font.Code)
	CollectionService:AddTag(screen, "PowerScreen")
	return screen, label
end

local function locker(parent: Instance, cf: CFrame, color: Color3): (Model, ProximityPrompt)
	local m = Build.model(parent, "Locker")
	local pro = Build.swap(m, "Locker", cf, Vector3.new(3, 7.4, 2.6))
	local body
	if pro then
		body = Build.ghost(m, Vector3.new(3, 7.4, 2.6), cf * CFrame.new(0, 3.7, 0))
	else
		body = Build.part(m, Vector3.new(3, 7.4, 2.6), cf * CFrame.new(0, 3.7, 0), color, Enum.Material.Metal)
		body.CanCollide = true
		local door =
			Build.part(m, Vector3.new(2.7, 7, 0.12), cf * CFrame.new(0, 3.7, -1.32), color:Lerp(Color3.new(), 0.15), Enum.Material.Metal)
		door.Name = "Door"
		for i = 0, 4 do
			Build.part(m, Vector3.new(1.6, 0.12, 0.06), cf * CFrame.new(0, 6.4 - i * 0.28, -1.4), Color3.fromRGB(20, 20, 20))
		end
		Build.part(m, Vector3.new(0.12, 0.6, 0.12), cf * CFrame.new(1, 3.8, -1.42), C.Metal, Enum.Material.Metal)
	end
	local hide = Instance.new("Attachment")
	hide.Name = "HidePoint"
	hide.CFrame = CFrame.new(0, -0.6, 0.2) * CFrame.Angles(0, math.pi, 0)
	hide.Parent = body
	body.Name = "Body"
	m.PrimaryPart = body
	local prompt = Build.prompt(body, "Hide", "Locker", 0, 6)
	CollectionService:AddTag(m, "HideLocker")
	return m, prompt
end

local function chairRow(parent: Instance, cf: CFrame, seats: number)
	if Build.swap(parent, "WaitingChairs", cf, Vector3.new(seats * 2.4, 4.2, 2.4)) then
		return
	end
	for i = 0, seats - 1 do
		local s = cf * CFrame.new((i - (seats - 1) / 2) * 2.4, 0, 0)
		Build.part(parent, Vector3.new(2.1, 0.4, 2), s * CFrame.new(0, 1.8, 0), C.Seat)
		Build.part(parent, Vector3.new(2.1, 2.2, 0.35), s * CFrame.new(0, 3, 0.95) * CFrame.Angles(math.rad(-8), 0, 0), C.Seat)
	end
	local len = seats * 2.4
	Build.part(parent, Vector3.new(len, 0.3, 0.3), cf * CFrame.new(0, 1.4, 0), C.Metal, Enum.Material.Metal)
	for _, x in { -len / 2 + 0.6, len / 2 - 0.6 } do
		Build.part(parent, Vector3.new(0.3, 1.4, 1.6), cf * CFrame.new(x, 0.7, 0), C.Metal, Enum.Material.Metal)
	end
end

local function stanchion(parent: Instance, a: Vector3, b: Vector3)
	for _, p in { a, b } do
		if Build.swap(parent, "Stanchion", CFrame.new(p), Vector3.new(1, 3.2, 1)) then
			continue
		end
		Build.part(parent, Vector3.new(1, 0.2, 1), CFrame.new(p + Vector3.new(0, 0.1, 0)), C.Metal, Enum.Material.Metal)
		Build.cyl(parent, 3, 0.3, CFrame.new(p + Vector3.new(0, 1.6, 0)) * CFrame.Angles(0, 0, math.pi / 2), C.Metal, Enum.Material.Metal)
	end
	local mid = (a + b) / 2 + Vector3.new(0, 2.8, 0)
	local belt = Build.part(
		parent,
		Vector3.new(0.12, 0.25, (b - a).Magnitude),
		CFrame.lookAt(mid, b + Vector3.new(0, 2.8, 0)),
		Color3.fromRGB(30, 40, 90)
	)
	belt.CanCollide = false
end

local function poster(parent: Instance, cf: CFrame, size: Vector2, text: string, bg: Color3, fg: Color3)
	local p = Build.part(parent, Vector3.new(size.X, size.Y, 0.1), cf, bg)
	Build.label(p, Enum.NormalId.Front, text, fg, Enum.Font.GothamBold, bg)
	Build.part(parent, Vector3.new(size.X + 0.3, size.Y + 0.3, 0.08), cf * CFrame.new(0, 0, 0.06), Color3.fromRGB(30, 30, 30))
end

local function garland(parent: Instance, a: Vector3, b: Vector3, flags: number)
	local colors = { C.Orange, C.Purple, Color3.fromRGB(20, 20, 24) }
	for i = 1, flags do
		local t = (i - 0.5) / flags
		local sag = math.sin(t * math.pi) * 1.2
		local p = a:Lerp(b, t) - Vector3.new(0, sag, 0)
		local flag = Build.wedge(
			parent,
			Vector3.new(0.08, 1, 0.8),
			CFrame.lookAt(p, p + (b - a).Unit) * CFrame.Angles(0, math.pi / 2, math.pi),
			colors[i % 3 + 1]
		)
		flag.CanCollide = false
	end
end

local function pumpkin(parent: Instance, cf: CFrame, size: number)
	if Build.swap(parent, "Pumpkin", cf, Vector3.new(size * 1.3, size * 1.3, size * 1.3)) then
		return
	end
	local p = Build.ball(parent, size, cf * CFrame.new(0, size * 0.4, 0), C.Orange, Enum.Material.SmoothPlastic)
	p.Size = Vector3.new(size * 1.15, size * 0.85, size * 1.15)
	p.Shape = Enum.PartType.Ball
	Build.part(parent, Vector3.new(0.18, 0.4, 0.18) * size, cf * CFrame.new(0, size * 0.9, 0), Color3.fromRGB(60, 90, 30))
	local face = Build.part(
		parent,
		Vector3.new(size * 0.6, size * 0.25, 0.05),
		cf * CFrame.new(0, size * 0.38, -size * 0.56),
		Color3.fromRGB(255, 200, 60),
		Enum.Material.Neon
	)
	face.CanCollide = false
	Build.pointLight(face, Color3.fromRGB(255, 150, 40), 8, 1.2)
end

-- Builds the hall shell (floor, walls, ceiling, windows).
local function buildShell(m: Model, o: CFrame)
	local w = HALL.X1 - HALL.X0
	local d = HALL.Z1 - HALL.Z0
	local cx = (HALL.X0 + HALL.X1) / 2
	local cz = (HALL.Z0 + HALL.Z1) / 2
	-- Floors: passenger hall (blue carpet tiles), officer area and back rooms (grey)
	Build.part(m, Vector3.new(w, 1, HALL.Z1), o * CFrame.new(cx, -0.5, HALL.Z1 / 2), C.Floor, Enum.Material.Fabric)
	Build.part(m, Vector3.new(w, 1, -HALL.Z0), o * CFrame.new(cx, -0.5, HALL.Z0 / 2), C.FloorOfficer, Enum.Material.Concrete)
	local ceiling = Build.part(m, Vector3.new(w, 1, d), o * CFrame.new(cx, HALL.H + 0.5, cz), C.Ceiling, Enum.Material.SmoothPlastic)
	ceiling.Name = "Ceiling"
	-- Ceiling tile grid
	for x = HALL.X0 + 6, HALL.X1 - 6, 6 do
		Build.part(m, Vector3.new(0.15, 0.1, d), o * CFrame.new(x, HALL.H - 0.02, cz), C.WallDark)
	end
	for z = HALL.Z0 + 6, HALL.Z1 - 6, 6 do
		Build.part(m, Vector3.new(w, 0.1, 0.15), o * CFrame.new(cx, HALL.H - 0.02, z), C.WallDark)
	end
	-- Outer walls (front wall has the entrance; east wall has the platform door; windows on the east)
	local function wallRun(a: Vector3, b: Vector3, gaps)
		-- gaps: list of {from, to} distances along the wall that stay open (doorways, height 9)
		local dir = (b - a).Unit
		local len = (b - a).Magnitude
		local cursor = 0
		table.sort(gaps, function(g1, g2)
			return g1[1] < g2[1]
		end)
		for _, gap in gaps do
			if gap[1] > cursor then
				Build.wall(m, o * (a + dir * cursor), o * (a + dir * gap[1]), HALL.H, 1, C.Wall, Enum.Material.Plaster)
			end
			-- lintel above the doorway
			local la, lb = o * (a + dir * gap[1] + Vector3.new(0, 9, 0)), o * (a + dir * gap[2] + Vector3.new(0, 9, 0))
			local lintel = Build.wall(m, la, lb, HALL.H - 9, 1, C.Wall, Enum.Material.Plaster)
			lintel.Name = "Lintel"
			cursor = gap[2]
		end
		if cursor < len then
			Build.wall(m, o * (a + dir * cursor), o * b, HALL.H, 1, C.Wall, Enum.Material.Plaster)
		end
		-- Navy stripe and skirting
		local inward = Vector3.new(dir.Z, 0, -dir.X)
		for _, y in { 4.4 } do
			local s = Build.wall(
				m,
				o * (a + Vector3.new(0, y, 0) + inward * 0.55),
				o * (b + Vector3.new(0, y, 0) + inward * 0.55),
				0.8,
				0.1,
				C.Stripe
			)
			s.CanCollide = false
		end
	end
	wallRun(Vector3.new(HALL.X0, 0, HALL.Z1), Vector3.new(HALL.X1, 0, HALL.Z1), { { 44, 56 } }) -- entrance
	wallRun(Vector3.new(HALL.X1, 0, HALL.Z1), Vector3.new(HALL.X1, 0, HALL.Z0), { { 18, 26 }, { 58, 63 } }) -- platform door + staff door
	wallRun(Vector3.new(HALL.X1, 0, HALL.Z0), Vector3.new(HALL.X0, 0, HALL.Z0), {})
	wallRun(Vector3.new(HALL.X0, 0, HALL.Z0), Vector3.new(HALL.X0, 0, HALL.Z1), { { 24, 28 }, { 69, 75 } }) -- interrogation wing doors

	-- Entrance doors (glass, open frame) and canopy outside
	for _, x in { -6, 6 } do
		Build.part(m, Vector3.new(0.6, 9, 1.2), o * CFrame.new(x, 4.5, HALL.Z1), C.DarkMetal, Enum.Material.Metal)
	end
	local sign = Build.part(m, Vector3.new(26, 3, 0.4), o * CFrame.new(0, 12, HALL.Z1 + 0.8), Color3.fromRGB(20, 30, 70))
	Build.label(sign, Enum.NormalId.Back, "FROSTLINE BORDER CHECKPOINT", Color3.fromRGB(240, 245, 255), Enum.Font.GothamBlack)
	Build.label(sign, Enum.NormalId.Front, "SECURITY CHECK  ·  ALL PASSENGERS", Color3.fromRGB(240, 245, 255), Enum.Font.GothamBlack)

	-- East windows looking at the train
	for z = -6, 46, 13 do
		if not (z > 26 and z < 38) then
			local glass = Build.part(m, Vector3.new(1.2, 5, 8), o * CFrame.new(HALL.X1, 8, z), C.Glass, Enum.Material.Glass)
			glass.Transparency = 0.6
		end
	end
	-- Pillars
	for _, x in { -24, 0, 24 } do
		for _, z in { 36 } do
			Build.part(m, Vector3.new(2.2, HALL.H, 2.2), o * CFrame.new(x, HALL.H / 2, z), C.Wall, Enum.Material.Plaster)
			Build.part(m, Vector3.new(2.4, 0.8, 2.4), o * CFrame.new(x, 4.4, z), C.Stripe)
		end
	end
end

-- One inspection lane. Returns its markers.
local function buildLane(m: Model, o: CFrame, index: number, L: number)
	local lane = Build.model(m, "Lane" .. index)
	local function at(x, y, z)
		return o * CFrame.new(L + x, y, z)
	end
	local markers = { Index = index, Prompts = {} }

	-- Counter (full lane width) with glass and a service slot
	Build.part(lane, Vector3.new(24, 3.4, 2.4), at(0, 1.7, 0), C.Counter, Enum.Material.SmoothPlastic)
	Build.part(lane, Vector3.new(24.2, 0.25, 2.8), at(0, 3.5, 0), C.CounterTop, Enum.Material.Marble)
	Build.part(lane, Vector3.new(24, 0.6, 0.1), at(0, 2.2, 1.22), C.Stripe)
	for _, seg in { { -12, -3 }, { 1, 12 } } do
		local glass =
			Build.part(lane, Vector3.new(seg[2] - seg[1], 6.2, 0.2), at((seg[1] + seg[2]) / 2, 6.75, 0.4), C.Glass, Enum.Material.Glass)
		glass.Transparency = 0.75
	end
	local slotGlass = Build.part(lane, Vector3.new(4, 4.4, 0.2), at(-1, 7.65, 0.4), C.Glass, Enum.Material.Glass)
	slotGlass.Transparency = 0.75
	Build.part(lane, Vector3.new(24, 0.4, 0.5), at(0, 10, 0.4), C.DarkMetal, Enum.Material.Metal)
	-- Lane sign above the window: "LANE 2 · 05 PASSENGERS LEFT"
	local signPart = Build.part(lane, Vector3.new(9, 2.2, 0.4), at(-1, 11.6, 0.4), Color3.fromRGB(10, 14, 12))
	local signLabel =
		Build.label(signPart, Enum.NormalId.Back, "LANE " .. index .. "  ·  CLOSED", Color3.fromRGB(90, 255, 120), Enum.Font.Code)
	Build.label(signPart, Enum.NormalId.Front, "LANE " .. index, Color3.fromRGB(90, 255, 120), Enum.Font.Code)
	markers.SignLabel = signLabel
	CollectionService:AddTag(signPart, "PowerScreen")

	-- ID tray in the slot (passenger slides the passport here)
	local tray = Build.part(lane, Vector3.new(2.2, 0.25, 1.6), at(-1, 3.75, 0.1), C.Metal, Enum.Material.Metal)
	tray.Name = "Tray"
	local passport = Build.part(lane, Vector3.new(0.9, 0.08, 1.2), at(-1, 3.9, 0.1), Color3.fromRGB(110, 20, 30))
	passport.Transparency = 1
	passport.Name = "PassportProp"
	markers.PassportProp = passport
	markers.Prompts.TakeID = addPrompt(tray, "Take ID", "Tray", 0, 7)

	-- Service bell (passenger side)
	Build.cyl(lane, 0.25, 1, at(-3.6, 3.75, 0.8) * CFrame.Angles(0, 0, math.pi / 2), C.DarkMetal)
	Build.ball(lane, 0.8, at(-3.6, 3.95, 0.8), C.Metal, Enum.Material.Metal)

	-- Stamps: APPROVE (green) and DENY (red)
	local function stamp(x, color, text)
		local base = Build.part(lane, Vector3.new(1, 0.5, 1), at(x, 3.85, -0.6), color)
		Build.cyl(lane, 1, 0.35, at(x, 4.5, -0.6) * CFrame.Angles(0, 0, math.pi / 2), C.Wood, Enum.Material.Wood)
		Build.ball(lane, 0.6, at(x, 5.05, -0.6), C.Wood, Enum.Material.Wood)
		local tag = Build.part(lane, Vector3.new(1.6, 0.5, 0.05), at(x, 3.95, -1.25), Color3.fromRGB(20, 20, 20))
		Build.label(tag, Enum.NormalId.Front, text, color, Enum.Font.GothamBlack)
		return base
	end
	local approve = stamp(-5, Color3.fromRGB(40, 190, 80), "APPROVE")
	local deny = stamp(-7, Color3.fromRGB(210, 40, 40), "DENY")
	markers.Prompts.Approve = addPrompt(approve, "APPROVE", "Stamp", 0.4, 6)
	markers.Prompts.Deny = addPrompt(deny, "DENY", "Stamp", 0.4, 6)
	markers.Prompts.Approve.KeyboardKeyCode = Enum.KeyCode.F
	markers.Prompts.Deny.KeyboardKeyCode = Enum.KeyCode.G

	-- Rulebook clipboard
	local clip =
		Build.part(lane, Vector3.new(1.3, 0.1, 1.7), at(-9.5, 3.7, -0.5) * CFrame.Angles(0, math.rad(12), 0), C.Wood, Enum.Material.Wood)
	Build.part(lane, Vector3.new(1.1, 0.05, 1.4), at(-9.5, 3.78, -0.45) * CFrame.Angles(0, math.rad(12), 0), Color3.fromRGB(245, 245, 235))
	markers.Prompts.Rulebook = addPrompt(clip, "Rulebook", "Today's rules", 0, 6)
	markers.Prompts.Rulebook.KeyboardKeyCode = Enum.KeyCode.R

	-- Interrogation call button (red phone)
	local phone = Build.part(lane, Vector3.new(1.2, 0.5, 0.9), at(-11, 3.9, -0.6), Color3.fromRGB(170, 20, 24))
	Build.part(lane, Vector3.new(1.3, 0.3, 0.4), at(-11, 4.3, -0.6), Color3.fromRGB(120, 10, 14))
	local phoneTag = Build.part(lane, Vector3.new(1.8, 0.45, 0.05), at(-11, 3.9, -1.08), Color3.fromRGB(20, 20, 20))
	Build.label(phoneTag, Enum.NormalId.Front, "INTERROGATION", Color3.fromRGB(255, 80, 80), Enum.Font.GothamBlack)
	markers.Prompts.Interrogate = addPrompt(phone, "Interrogate", "Send to room " .. index, 0.6, 6)
	markers.Prompts.Interrogate.KeyboardKeyCode = Enum.KeyCode.Q

	-- Thermal camera on a stand
	local thermal = Build.part(lane, Vector3.new(0.7, 0.7, 1.3), at(-8.2, 4.6, -0.3), Color3.fromRGB(230, 200, 40))
	Build.cyl(lane, 0.3, 0.55, at(-8.2, 4.6, 0.4) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(20, 20, 20))
	Build.part(lane, Vector3.new(0.2, 0.9, 0.2), at(-8.2, 4, -0.3), C.DarkMetal)
	markers.Prompts.Thermal = addPrompt(thermal, "Thermal", "Camera", 0, 6)
	markers.Prompts.Thermal.KeyboardKeyCode = Enum.KeyCode.T

	-- X-ray monitor and body-scan monitor (face the officer: -Z)
	local xrayScreen, xrayLabel = monitor(lane, at(6.5, 5.4, -0.5), 2.6, 1.7, "X-RAY\nWAITING")
	markers.Prompts.XRay = addPrompt(xrayScreen, "X-Ray", "Monitor", 0, 7)
	markers.Prompts.XRay.KeyboardKeyCode = Enum.KeyCode.X
	markers.XRayLabel = xrayLabel
	local scanScreen, scanLabel = monitor(lane, at(9.6, 5.4, -0.5), 2.6, 1.7, "BODY SCAN\nWAITING")
	markers.Prompts.Skeleton = addPrompt(scanScreen, "Body Scan", "Monitor", 0, 7)
	markers.Prompts.Skeleton.KeyboardKeyCode = Enum.KeyCode.B
	markers.ScanLabel = scanLabel

	-- CCTV wall screen (left partition)
	local cctv, cctvLabel = monitor(lane, at(-11.3, 7.5, -5) * CFrame.Angles(0, -math.pi / 2, 0), 5, 3, "CAM 0" .. index .. "\n● REC")
	markers.Prompts.Camera = addPrompt(cctv, "Cameras", "CCTV", 0, 9)
	markers.Prompts.Camera.KeyboardKeyCode = Enum.KeyCode.C
	markers.CctvLabel = cctvLabel
	-- Security camera pointing at the counter
	local camBody = Build.part(
		lane,
		Vector3.new(0.8, 0.8, 1.6),
		at(-6, 13, 8) * CFrame.Angles(math.rad(-25), math.rad(160), 0),
		Color3.fromRGB(235, 235, 235)
	)
	Build.part(lane, Vector3.new(0.2, 2.6, 0.2), at(-6, 14.6, 8.4), C.DarkMetal)
	local redLed = Build.ball(lane, 0.2, camBody.CFrame * CFrame.new(0.3, 0.3, -0.8), Color3.fromRGB(255, 40, 40), Enum.Material.Neon)
	redLed.CanCollide = false

	-- Officer desk behind (PC, phone, chair)
	if not Build.swap(lane, "OfficeDesk", at(4, 0, -5.5), Vector3.new(8, 3.25, 2.6)) then
		Build.part(lane, Vector3.new(8, 0.3, 2.6), at(4, 3.1, -5.5), C.Wood, Enum.Material.WoodPlanks)
		for _, x in { 0.4, 7.6 } do
			Build.part(lane, Vector3.new(0.3, 3, 2.4), at(x, 1.5, -5.5), C.DarkMetal, Enum.Material.Metal)
		end
	end
	monitor(lane, at(4, 4.7, -6) * CFrame.Angles(0, math.pi, 0), 2.2, 1.4, "FROSTLINE OS\nLOGGED IN")
	Build.part(lane, Vector3.new(2, 0.1, 0.7), at(4, 3.3, -5), Color3.fromRGB(30, 30, 30))
	Build.part(lane, Vector3.new(0.9, 0.4, 0.6), at(6.6, 3.45, -5.3), Color3.fromRGB(20, 20, 20))
	local mug = Build.cyl(lane, 0.5, 0.4, at(1.5, 3.5, -5.2) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(250, 250, 250))
	mug.CanCollide = false
	-- Office chair
	if not Build.swap(lane, "OfficeChair", at(-1, 0, -3.8) * CFrame.Angles(0, math.pi, 0), Vector3.new(2.2, 4.4, 2.2)) then
		Build.part(lane, Vector3.new(1.8, 0.4, 1.8), at(-1, 2, -3.6), Color3.fromRGB(20, 20, 24))
		Build.part(lane, Vector3.new(1.8, 2, 0.3), at(-1, 3.2, -4.5), Color3.fromRGB(20, 20, 24))
		Build.cyl(lane, 1.6, 0.3, at(-1, 1, -3.6) * CFrame.Angles(0, 0, math.pi / 2), C.Metal, Enum.Material.Metal)
	end

	-- Partition walls between lanes (officer side), with a navy stripe
	for _, x in { -12, 12 } do
		if math.abs(L + x) < 50 then
			Build.part(lane, Vector3.new(0.6, 10, 12), at(x, 5, -6), C.Wall, Enum.Material.Plaster)
			Build.part(lane, Vector3.new(0.7, 0.8, 12), at(x, 4.4, -6), C.Stripe)
		end
	end
	-- Lane booth ceiling light + officer light
	Build.ceilingLight(lane, at(-1, HALL.H - 0.2, -4), 24)
	Build.ceilingLight(lane, at(-1, HALL.H - 0.2, 6), 26)
	Build.ceilingLight(lane, at(-1, HALL.H - 0.2, 18), 26)

	-- X-ray conveyor: along Z on the passenger side at x = +7.5, from z=22 to z=3
	local beltX = 7.5
	-- The machine faces the passenger (-Z of a pro model points at the queue). Fits a 3.6 x 6.5 x 19 box.
	if not Build.swap(lane, "XRayMachine", at(beltX, 0, 12.5) * CFrame.Angles(0, math.pi, 0), Vector3.new(3.8, 6.5, 19)) then
		Build.part(lane, Vector3.new(3, 2.6, 19), at(beltX, 1.3, 12.5), C.Counter)
		local belt = Build.part(lane, Vector3.new(2.6, 0.12, 19), at(beltX, 2.66, 12.5), Color3.fromRGB(26, 26, 28), Enum.Material.Fabric)
		belt.Name = "Belt"
		-- Rollers detail
		for z = 4, 21, 1.5 do
			Build.part(lane, Vector3.new(2.7, 0.05, 0.1), at(beltX, 2.73, z), Color3.fromRGB(60, 60, 64))
		end
		-- Tunnel housing with lead curtains
		Build.part(lane, Vector3.new(3.6, 3.6, 6), at(beltX, 4.5, 12), Color3.fromRGB(220, 222, 228))
		Build.part(lane, Vector3.new(0.3, 4.2, 6), at(beltX - 1.8, 2.4, 12), Color3.fromRGB(220, 222, 228))
		Build.part(lane, Vector3.new(0.3, 4.2, 6), at(beltX + 1.8, 2.4, 12), Color3.fromRGB(220, 222, 228))
		for _, z in { 9, 15 } do
			for i = -1, 1 do
				local strip = Build.part(lane, Vector3.new(0.75, 2, 0.05), at(beltX + i * 0.85, 3.7, z), Color3.fromRGB(40, 40, 46))
				strip.CanCollide = false
				strip.Transparency = 0.2
			end
		end
		local xlogo = Build.part(lane, Vector3.new(0.05, 1, 3), at(beltX - 1.83, 4.5, 12), Color3.fromRGB(240, 210, 40))
		Build.label(xlogo, Enum.NormalId.Left, "☢ X-RAY", Color3.fromRGB(20, 20, 20), Enum.Font.GothamBlack)
	end
	markers.BagStart = at(beltX, 3.3, 20.5)
	markers.BagMid = at(beltX, 3.3, 12)
	markers.BagEnd = at(beltX, 3.3, 4)

	-- Body scanner arch (passenger walks into it and raises their arms)
	local archZ = 11
	local proArch = Build.swap(lane, "BodyScanner", at(0, 0, archZ) * CFrame.Angles(0, math.pi, 0), Vector3.new(5.4, 9.4, 3))
	for _, x in if proArch then {} else { -2.2, 2.2 } do
		Build.part(lane, Vector3.new(0.9, 8.4, 2.4), at(x, 4.2, archZ), Color3.fromRGB(230, 232, 238))
		local strip = Build.part(lane, Vector3.new(0.1, 7, 0.3), at(x * 0.78, 4.4, archZ), Color3.fromRGB(90, 200, 255), Enum.Material.Neon)
		strip.CanCollide = false
		CollectionService:AddTag(strip, "PowerScreen")
	end
	if not proArch then
		Build.part(lane, Vector3.new(5.3, 1, 2.4), at(0, 8.9, archZ), Color3.fromRGB(230, 232, 238))
	end
	local scanLight = Build.part(lane, Vector3.new(3.4, 0.1, 0.4), at(0, 8.35, archZ), Color3.fromRGB(90, 200, 255), Enum.Material.Neon)
	scanLight.CanCollide = false
	if proArch then
		scanLight.Transparency = 1
	end
	markers.ScanLight = scanLight
	local pad = Build.part(lane, Vector3.new(3.4, 0.08, 2.2), at(0, 0.04, archZ), Color3.fromRGB(240, 200, 40))
	Build.label(pad, Enum.NormalId.Top, "STAND HERE", Color3.fromRGB(20, 20, 20), Enum.Font.GothamBlack)

	-- Queue stanchions
	stanchion(lane, (at(-3, 0, 16)).Position, (at(-3, 0, 30)).Position)
	stanchion(lane, (at(3.5, 0, 10)).Position, (at(3.5, 0, 16)).Position)
	stanchion(lane, (at(-8, 0, 30)).Position, (at(-3, 0, 30)).Position)

	-- Passenger path
	markers.Points = {
		Entry = at(-1, 0, 47),
		Back = at(0, 0, 26),
		Queue = at(-1, 0, 28),
		Bag = at(4.7, 0, 20.5),
		ScanWait = at(0, 0, 15),
		Scan = at(0, 0, archZ),
		Counter = at(-1, 0, 2.8),
	}
	markers.OfficerSpawn = at(-1, 3, -3.2) * CFrame.Angles(0, math.pi, 0)
	markers.Center = at(0, 0, 0).Position
	return markers
end

local function buildBackRooms(m: Model, o: CFrame, markers)
	local rooms = Build.model(m, "BackRooms")
	local function at(x, y, z)
		return o * CFrame.new(x, y, z)
	end
	-- Wall between officer area and corridor (z = -12) with a door per lane
	local doorsAt = { -37, -13, 11, 35 }
	local cursor = HALL.X0
	for _, dx in doorsAt do
		Build.wall(rooms, (at(cursor, 0, -12)).Position, (at(dx - 2.5, 0, -12)).Position, HALL.H, 0.8, C.Wall, Enum.Material.Plaster)
		Build.wall(rooms, (at(dx - 2.5, 9, -12)).Position, (at(dx + 2.5, 9, -12)).Position, HALL.H - 9, 0.8, C.Wall, Enum.Material.Plaster)
		cursor = dx + 2.5
	end
	Build.wall(rooms, (at(cursor, 0, -12)).Position, (at(HALL.X1, 0, -12)).Position, HALL.H, 0.8, C.Wall, Enum.Material.Plaster)
	-- Corridor lights
	for x = -44, 44, 11 do
		Build.ceilingLight(rooms, at(x, HALL.H - 0.2, -16), 20)
	end
	-- Wall between corridor and rooms (z = -20) with doors into each room, and room dividers
	local roomDoors = { -33, 0, 33 }
	cursor = HALL.X0
	for _, dx in roomDoors do
		Build.wall(rooms, (at(cursor, 0, -20)).Position, (at(dx - 3, 0, -20)).Position, HALL.H, 0.8, C.Wall, Enum.Material.Plaster)
		Build.wall(rooms, (at(dx - 3, 9, -20)).Position, (at(dx + 3, 9, -20)).Position, HALL.H - 9, 0.8, C.Wall, Enum.Material.Plaster)
		cursor = dx + 3
	end
	Build.wall(rooms, (at(cursor, 0, -20)).Position, (at(HALL.X1, 0, -20)).Position, HALL.H, 0.8, C.Wall, Enum.Material.Plaster)
	for _, x in { -17, 17 } do
		Build.wall(rooms, (at(x, 0, -20)).Position, (at(x, 0, HALL.Z0)).Position, HALL.H, 0.8, C.Wall, Enum.Material.Plaster)
	end
	local function roomSign(x, text, color)
		local s = Build.part(rooms, Vector3.new(6, 1.2, 0.2), at(x, 10, -19.5), color)
		Build.label(s, Enum.NormalId.Back, text, Color3.new(1, 1, 1), Enum.Font.GothamBlack)
	end
	roomSign(-33, "STORAGE", Color3.fromRGB(80, 80, 90))
	roomSign(0, "BREAK ROOM", C.Stripe)
	roomSign(33, "⚡ FUSE ROOM", Color3.fromRGB(170, 120, 20))

	markers.Lockers = {}
	markers.Breakers = {}

	-- BREAK ROOM (x -17..17): coffee machine, time clock, sofa, table, lockers, TV
	for x = -12, 12, 8 do
		Build.ceilingLight(rooms, at(x, HALL.H - 0.2, -31), 22)
	end
	local proCoffee = Build.swap(rooms, "CoffeeMachine", at(-13, 0, -40.5) * CFrame.Angles(0, math.pi, 0), Vector3.new(3.4, 6, 2.6))
	local machine = if proCoffee
		then Build.ghost(rooms, Vector3.new(3, 6, 2.4), at(-13, 3, -40.5))
		else Build.part(rooms, Vector3.new(3, 6, 2.4), at(-13, 3, -40.5), Color3.fromRGB(40, 40, 46), Enum.Material.Metal)
	local machineFront = Build.part(rooms, Vector3.new(2.4, 2, 0.1), at(-13, 4.4, -39.25), Color3.fromRGB(120, 60, 30), Enum.Material.Neon)
	Build.label(machineFront, Enum.NormalId.Back, "☕ HOT COFFEE", Color3.new(1, 1, 1), Enum.Font.GothamBlack)
	if proCoffee then
		machineFront:Destroy()
	end
	CollectionService:AddTag(machineFront, "PowerScreen")
	markers.Coffee = Build.prompt(machine, "Drink coffee", "Calms your nerves", 1.5, 7)
	local clock = Build.part(rooms, Vector3.new(2.6, 3.4, 1), at(-5, 5, -41.4), Color3.fromRGB(190, 190, 196), Enum.Material.Metal)
	Build.label(clock, Enum.NormalId.Back, "TIME CLOCK\n⏱", Color3.fromRGB(20, 20, 20), Enum.Font.GothamBlack)
	markers.TimeClock = clock
	-- Table and chairs
	Build.cyl(rooms, 0.3, 6, at(3, 3, -30) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(230, 230, 230))
	Build.part(rooms, Vector3.new(0.6, 3, 0.6), at(3, 1.5, -30), C.Metal)
	for i = 0, 3 do
		local a = i * math.pi / 2
		local cf = at(3 + math.cos(a) * 4, 0, -30 + math.sin(a) * 4)
		Build.part(rooms, Vector3.new(1.8, 0.3, 1.8), cf * CFrame.new(0, 1.8, 0), C.Seat)
	end
	-- Sofa
	Build.part(rooms, Vector3.new(9, 1.6, 3), at(9, 0.8, -39.5), Color3.fromRGB(110, 40, 40), Enum.Material.Fabric)
	Build.part(rooms, Vector3.new(9, 3, 1), at(9, 2, -41), Color3.fromRGB(110, 40, 40), Enum.Material.Fabric)
	-- TV
	monitor(rooms, at(9, 9, -41.3) * CFrame.Angles(0, math.pi, 0), 6, 3.4, "📺 FROSTLINE NEWS\nBLIZZARD WARNING TONIGHT")
	-- Fridge
	Build.part(rooms, Vector3.new(3, 7, 3), at(15, 3.5, -38), Color3.fromRGB(235, 235, 240), Enum.Material.Metal)
	poster(
		rooms,
		at(-16.5, 6, -28) * CFrame.Angles(0, -math.pi / 2, 0),
		Vector2.new(4, 5),
		"TAKE A\nBREATH.\nOne shift at a time.",
		Color3.fromRGB(220, 235, 255),
		C.Stripe
	)
	for i = 0, 2 do
		local _, prompt = locker(rooms, at(-14 + i * 3.2, 0, -21.8) * CFrame.Angles(0, math.pi, 0), C.Locker)
		table.insert(markers.Lockers, prompt)
	end
	markers.BreakRoomSpawn = at(0, 3, -32)

	-- STORAGE (x -50..-17): shelves, boxes, lockers, breaker
	for x = -44, -22, 11 do
		Build.ceilingLight(rooms, at(x, HALL.H - 0.2, -31), 18)
	end
	for row = 0, 1 do
		local z = -28 - row * 8
		Build.part(rooms, Vector3.new(16, 0.3, 3), at(-36, 2, z), C.Metal, Enum.Material.Metal)
		Build.part(rooms, Vector3.new(16, 0.3, 3), at(-36, 5, z), C.Metal, Enum.Material.Metal)
		Build.part(rooms, Vector3.new(16, 0.3, 3), at(-36, 8, z), C.Metal, Enum.Material.Metal)
		for _, x in { -44, -28 } do
			Build.part(rooms, Vector3.new(0.3, 9, 3), at(x, 4.5, z), C.DarkMetal, Enum.Material.Metal)
		end
		for i = 0, 5 do
			local h = 1.4 + (i % 3) * 0.3
			Build.part(
				rooms,
				Vector3.new(2, h, 2),
				at(-42 + i * 2.6, 2.15 + h / 2, z),
				Color3.fromRGB(170, 130, 80),
				Enum.Material.Cardboard
			)
			Build.part(rooms, Vector3.new(1.8, 1.4, 2), at(-41.5 + i * 2.6, 5.85, z), Color3.fromRGB(160, 120, 74), Enum.Material.Cardboard)
		end
	end
	for i = 0, 3 do
		local _, prompt = locker(rooms, at(-48.5, 0, -38 + i * 3.2) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(70, 80, 100))
		table.insert(markers.Lockers, prompt)
	end

	-- FUSE ROOM (x 17..50)
	for x = 22, 44, 11 do
		Build.ceilingLight(rooms, at(x, HALL.H - 0.2, -31), 18)
	end
	for i = 0, 4 do
		Build.part(rooms, Vector3.new(3.2, 7, 1.4), at(22 + i * 4, 3.5, -41), Color3.fromRGB(110, 116, 110), Enum.Material.Metal)
		Build.part(rooms, Vector3.new(0.3, 0.3, 0.1), at(23 + i * 4, 6, -40.25), Color3.fromRGB(40, 255, 80), Enum.Material.Neon)
	end
	for y = 12, 14, 1 do
		Build.cyl(rooms, 32, 0.6, at(33, y, -40), Color3.fromRGB(150, 110, 60), Enum.Material.Metal)
	end
	for i = 0, 1 do
		local _, prompt = locker(rooms, at(48.5, 0, -30 + i * 3.2) * CFrame.Angles(0, -math.pi / 2, 0), C.Locker)
		table.insert(markers.Lockers, prompt)
	end

	-- Breakers (power comes back when all three are flipped)
	local function breaker(cf: CFrame, name: string)
		local box =
			Build.part(rooms, Vector3.new(3, 4, 0.8), cf * CFrame.new(0, 5, 0), Color3.fromRGB(80, 84, 80), Enum.Material.DiamondPlate)
		local lever = Build.part(
			rooms,
			Vector3.new(0.4, 1.4, 0.4),
			cf * CFrame.new(0, 4.6, -0.6) * CFrame.Angles(math.rad(40), 0, 0),
			Color3.fromRGB(200, 30, 30)
		)
		local light =
			Build.part(rooms, Vector3.new(0.5, 0.5, 0.2), cf * CFrame.new(0.9, 6.4, -0.45), Color3.fromRGB(255, 40, 40), Enum.Material.Neon)
		local tag = Build.part(rooms, Vector3.new(2.8, 0.6, 0.05), cf * CFrame.new(0, 7.4, -0.42), Color3.fromRGB(240, 200, 40))
		Build.label(tag, Enum.NormalId.Front, "⚡ BREAKER " .. name, Color3.fromRGB(20, 20, 20), Enum.Font.GothamBlack)
		local prompt = Build.prompt(box, "Restore power", "Breaker " .. name, 3, 7)
		prompt.Enabled = false
		table.insert(markers.Breakers, { Box = box, Lever = lever, Light = light, Prompt = prompt, Name = name, Base = cf })
	end
	breaker(at(33, 0, -41.5) * CFrame.Angles(0, math.pi, 0), "A")
	breaker(at(-40, 0, -21), "B")
	breaker(at(49.4, 0, 46) * CFrame.Angles(0, math.pi / 2, 0), "C") -- out in the hall, near the platform

	-- Back-wall lockers in the officer corridor
	for i = 0, 1 do
		local _, prompt = locker(rooms, at(-49 + 0.5, 0, -16.5 + i * 3.2) * CFrame.Angles(0, math.pi / 2, 0), C.Locker)
		table.insert(markers.Lockers, prompt)
	end
end

local function buildHallDecor(m: Model, o: CFrame, markers)
	local decor = Build.model(m, "Decor")
	local function at(x, y, z)
		return o * CFrame.new(x, y, z)
	end
	-- Waiting seats near the entrance
	for _, x in { -24, 0, 24 } do
		chairRow(decor, at(x, 0, 43) * CFrame.Angles(0, math.pi, 0), 4)
	end
	-- Departure board
	local board = Build.part(decor, Vector3.new(18, 4.4, 0.6), at(-30, 11, HALL.Z1 - 0.8), Color3.fromRGB(10, 10, 12))
	Build.label(
		board,
		Enum.NormalId.Front,
		"NIGHT TRAIN   01:30   VARN CENTRAL   BOARDING\nNIGHT TRAIN   02:10   LUNMARK        DELAYED\nNIGHT TRAIN   03:00   ???            ???",
		Color3.fromRGB(255, 200, 60),
		Enum.Font.Code
	)
	CollectionService:AddTag(board, "PowerScreen")
	-- Wall clock
	local clock = Build.cyl(decor, 0.3, 3.4, at(26, 11, HALL.Z1 - 0.7) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(250, 250, 250))
	Build.label(clock, Enum.NormalId.Right, "01:13", Color3.fromRGB(20, 20, 20), Enum.Font.GothamBlack)
	-- Posters
	poster(
		decor,
		at(-49.4, 7, 42) * CFrame.Angles(0, -math.pi / 2, 0),
		Vector2.new(5, 6.5),
		"REPORT\nANYTHING\nUNUSUAL",
		C.Stripe,
		Color3.new(1, 1, 1)
	)
	poster(
		decor,
		at(-49.4, 7, 14) * CFrame.Angles(0, -math.pi / 2, 0),
		Vector2.new(5, 6.5),
		"THEY\nLOOK\nLIKE US",
		Color3.fromRGB(240, 235, 225),
		Color3.fromRGB(150, 20, 20)
	)
	poster(decor, at(10, 7, HALL.Z1 - 0.6), Vector2.new(4.5, 6), "REST\nBETWEEN\nSHIFTS", Color3.fromRGB(240, 240, 245), C.Stripe)
	poster(
		decor,
		at(-10, 7, HALL.Z1 - 0.6),
		Vector2.new(4.5, 6),
		"NO SHARP\nOBJECTS\nNO ANIMALS",
		Color3.fromRGB(240, 200, 40),
		Color3.fromRGB(20, 20, 20)
	)
	-- Halloween garlands across the hall
	for _, x in { -36, -12, 12, 36 } do
		garland(decor, (at(x - 10, 13.5, 1)).Position, (at(x + 10, 13.5, 1)).Position, 12)
	end
	garland(decor, (at(-40, 13, HALL.Z1 - 1)).Position, (at(40, 13, HALL.Z1 - 1)).Position, 30)
	for _, x in { -46, -26, 26, 46 } do
		pumpkin(decor, at(x, 0, 50), 2)
	end
	-- Plants, bins, wet-floor sign, vending machine
	for _, x in { -48, 48 } do
		if Build.swap(decor, "Plant", at(x, 0, 39), Vector3.new(3.4, 6, 3.4)) then
			continue
		end
		Build.cyl(decor, 2, 2, at(x, 1, 39) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(70, 60, 50))
		local leaves = Build.ball(decor, 3.4, at(x, 3.6, 39), Color3.fromRGB(40, 110, 50), Enum.Material.Grass)
		leaves.Size = Vector3.new(3, 4, 3)
	end
	if not Build.swap(decor, "VendingMachine", at(-46, 0, 50.5), Vector3.new(4, 7.5, 3)) then
		Build.part(decor, Vector3.new(4, 7.5, 3), at(-46, 3.75, 50.5), Color3.fromRGB(180, 30, 40))
		local vendFront = Build.part(decor, Vector3.new(2.6, 5, 0.1), at(-46.4, 4.4, 49), Color3.fromRGB(200, 230, 255), Enum.Material.Neon)
		vendFront.Transparency = 0.3
		CollectionService:AddTag(vendFront, "PowerScreen")
	end
	local wet = Build.wedge(decor, Vector3.new(1.4, 2.6, 1.2), at(-44, 1.3, 47), Color3.fromRGB(250, 210, 30))
	Build.label(wet, Enum.NormalId.Front, "⚠ WET", Color3.fromRGB(20, 20, 20), Enum.Font.GothamBlack)
	-- Platform door sign
	local exitSign = Build.part(decor, Vector3.new(0.3, 1.4, 6), at(49.3, 10.2, 31.5), Color3.fromRGB(20, 120, 50))
	Build.label(exitSign, Enum.NormalId.Left, "PLATFORM 3 →", Color3.new(1, 1, 1), Enum.Font.GothamBlack)
	-- Ceiling lights over the hall
	for x = -44, 44, 11 do
		for z = 26, 50, 12 do
			Build.ceilingLight(decor, at(x, HALL.H - 0.2, z), 24)
		end
	end
	-- Emergency lights (off until a blackout)
	for x = -40, 40, 20 do
		for _, z in { -16, 10, 40 } do
			local e =
				Build.part(decor, Vector3.new(1, 0.6, 1), at(x, HALL.H - 0.4, z), Color3.fromRGB(90, 0, 0), Enum.Material.SmoothPlastic)
			local light = Build.pointLight(e, Color3.fromRGB(255, 30, 20), 26, 0, false)
			light.Name = "Emergency"
			CollectionService:AddTag(e, "EmergencyLight")
		end
	end
	for _, z in { -30 } do
		for _, x in { -33, 0, 33 } do
			local e = Build.part(decor, Vector3.new(1, 0.6, 1), at(x, HALL.H - 0.4, z), Color3.fromRGB(90, 0, 0))
			local light = Build.pointLight(e, Color3.fromRGB(255, 30, 20), 24, 0, false)
			light.Name = "Emergency"
			CollectionService:AddTag(e, "EmergencyLight")
		end
	end
	markers.PlatformDoor = at(53, 0, 32)
	markers.HallSide = at(42, 0, 33) -- inside the hall, in front of the platform door
	markers.HallDoorIn = at(0, 0, 48) -- just inside the entrance
	markers.Outside = at(0, 0, 64) -- the street (passengers arrive and leave here)
end

local function buildPlatform(m: Model, o: CFrame, markers)
	local plat = Build.model(m, "Platform")
	local function at(x, y, z)
		return o * CFrame.new(x, y, z)
	end
	-- Snowy ground around the station
	Build.part(plat, Vector3.new(400, 2, 400), at(0, -1.5, 0), C.Snow, Enum.Material.Snow)
	-- Platform slab
	Build.part(plat, Vector3.new(16, 0.6, 120), at(58, 0.3, 6), Color3.fromRGB(120, 124, 130), Enum.Material.Concrete)
	Build.part(plat, Vector3.new(0.8, 0.05, 120), at(65.4, 0.63, 6), Color3.fromRGB(240, 200, 30))
	-- Canopy
	Build.part(plat, Vector3.new(18, 0.6, 120), at(58, 14, 6), Color3.fromRGB(60, 64, 72), Enum.Material.Metal)
	for z = -50, 60, 14 do
		Build.part(plat, Vector3.new(0.8, 13, 0.8), at(54, 7.5, z), C.DarkMetal, Enum.Material.Metal)
		local lamp = Build.part(plat, Vector3.new(1.6, 0.4, 1.6), at(58, 13.5, z), Color3.fromRGB(255, 220, 160), Enum.Material.Neon)
		Build.spotLight(lamp, Enum.NormalId.Bottom, Color3.fromRGB(255, 214, 160), 26, 2, 100)
		CollectionService:AddTag(lamp, "PowerLight")
	end
	-- Rails
	for _, x in { 70, 75 } do
		Build.part(plat, Vector3.new(0.5, 0.5, 300), at(x, 0.25, 6), C.Metal, Enum.Material.Metal)
	end
	for z = -140, 150, 3 do
		Build.part(plat, Vector3.new(9, 0.3, 1), at(72.5, 0.05, z), Color3.fromRGB(70, 50, 36), Enum.Material.Wood)
	end
	-- The night train: three carriages
	local train = Build.model(plat, "Train")
	for car = 0, 2 do
		local z = -40 + car * 44
		if Build.swap(train, "TrainCar", at(72.5, 0.6, z), Vector3.new(9.6, 12, 43)) then
			continue
		end
		local body = Build.part(train, Vector3.new(9.4, 10, 42), at(72.5, 6.4, z), Color3.fromRGB(26, 40, 64), Enum.Material.Metal)
		Build.part(train, Vector3.new(9.6, 1, 42.2), at(72.5, 4, z), Color3.fromRGB(150, 20, 26), Enum.Material.Metal)
		Build.part(train, Vector3.new(8.6, 1, 41), at(72.5, 11.8, z), Color3.fromRGB(60, 64, 70), Enum.Material.Metal)
		for w = -16, 16, 6 do
			local window =
				Build.part(train, Vector3.new(0.2, 2.6, 4), at(67.75, 8, z + w), Color3.fromRGB(255, 214, 140), Enum.Material.Neon)
			window.Transparency = 0.25
		end
		local door = Build.part(train, Vector3.new(0.2, 7, 3.6), at(67.75, 5, z + 20), Color3.fromRGB(80, 90, 100), Enum.Material.Metal)
		door.Name = "Door"
		for _, wz in { -15, 15 } do
			Build.cyl(train, 9.6, 2.4, at(72.5, 1.6, z + wz), Color3.fromRGB(20, 20, 20), Enum.Material.Metal)
		end
		local _ = body
	end
	local nose = Build.wedge(train, Vector3.new(9.4, 10, 8), at(72.5, 6.4, 86), Color3.fromRGB(26, 40, 64), Enum.Material.Metal)
	local _ = nose
	local headlight = Build.ball(train, 1.6, at(72.5, 4.5, 89.5), Color3.fromRGB(255, 250, 220), Enum.Material.Neon)
	Build.spotLight(headlight, Enum.NormalId.Front, Color3.fromRGB(255, 250, 220), 60, 3, 50)
	markers.TrainDoor = at(66, 1, 24)
	markers.MonsterSpawn = at(64, 1.5, 24)

	-- Snow falling around the station
	local emitterPart = Build.part(plat, Vector3.new(220, 1, 220), at(0, 60, 0), Color3.new(1, 1, 1))
	emitterPart.Transparency = 1
	emitterPart.CanCollide = false
	emitterPart.CanQuery = false
	local snow = Instance.new("ParticleEmitter")
	snow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	snow.Rate = 220
	snow.Lifetime = NumberRange.new(12, 16)
	snow.Speed = NumberRange.new(4, 7)
	snow.SpreadAngle = Vector2.new(12, 12)
	snow.Size = NumberSequence.new(0.35)
	snow.Color = ColorSequence.new(Color3.new(1, 1, 1))
	snow.EmissionDirection = Enum.NormalId.Bottom
	snow.Acceleration = Vector3.new(2, 0, 1)
	snow.LightEmission = 0.3
	snow.Parent = emitterPart
	-- Pine trees
	local rng = Random.new(42)
	for _ = 1, 70 do
		local angle = rng:NextNumber(0, math.pi * 2)
		local dist = rng:NextNumber(95, 170)
		local x, z = math.cos(angle) * dist, math.sin(angle) * dist
		if not (x > 50 and x < 100) then
			local h = rng:NextNumber(18, 34)
			if Build.swap(plat, "PineTree", at(x, 0, z) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), Vector3.new(h * 0.6, h, h * 0.6)) then
				continue
			end
			Build.part(plat, Vector3.new(1.4, h * 0.3, 1.4), at(x, h * 0.15, z), Color3.fromRGB(70, 50, 36), Enum.Material.Wood)
			for tier = 0, 2 do
				local size = h * (0.55 - tier * 0.15)
				local cone = Build.part(
					plat,
					Vector3.new(size, h * 0.3, size),
					at(x, h * (0.3 + tier * 0.22), z) * CFrame.Angles(0, rng:NextNumber(0, 3), 0),
					Color3.fromRGB(30, 60, 44),
					Enum.Material.Grass
				)
				cone.Shape = Enum.PartType.Ball
				Build.part(
					plat,
					Vector3.new(size * 0.7, 0.6, size * 0.7),
					at(x, h * (0.3 + tier * 0.22) + h * 0.12, z),
					C.Snow,
					Enum.Material.Snow
				).Shape =
					Enum.PartType.Cylinder
			end
		end
	end
	-- Street lamps at the entrance
	for _, x in { -14, 14 } do
		Build.part(plat, Vector3.new(0.6, 14, 0.6), at(x, 7, 62), C.DarkMetal, Enum.Material.Metal)
		local lamp = Build.part(plat, Vector3.new(2, 0.5, 1.2), at(x, 14, 61), Color3.fromRGB(255, 220, 170), Enum.Material.Neon)
		Build.spotLight(lamp, Enum.NormalId.Bottom, Color3.fromRGB(255, 210, 160), 30, 2.4, 90)
		CollectionService:AddTag(lamp, "PowerLight")
	end
end

-- Interrogation wing (west): a corridor and one room per lane. Passengers enter from the hall,
-- officers from the staff corridor.
local function buildInterrogation(m: Model, o: CFrame, markers)
	local wing = Build.model(m, "Interrogation")
	local function at(x, y, z)
		return o * CFrame.new(x, y, z)
	end
	local X0, X1, Z0, Z1 = -86, -50, -20, 42
	Build.part(
		wing,
		Vector3.new(X1 - X0, 1, Z1 - Z0),
		at((X0 + X1) / 2, -0.5, (Z0 + Z1) / 2),
		Color3.fromRGB(84, 86, 92),
		Enum.Material.Concrete
	)
	Build.part(
		wing,
		Vector3.new(X1 - X0, 1, Z1 - Z0),
		at((X0 + X1) / 2, 12.5, (Z0 + Z1) / 2),
		Color3.fromRGB(150, 150, 154),
		Enum.Material.Concrete
	)
	local wallColor = Color3.fromRGB(150, 154, 150)
	Build.wall(wing, (at(X0, 0, Z0)).Position, (at(X0, 0, Z1)).Position, 12, 1, wallColor, Enum.Material.Concrete)
	Build.wall(wing, (at(X0, 0, Z0)).Position, (at(X1, 0, Z0)).Position, 12, 1, wallColor, Enum.Material.Concrete)
	Build.wall(wing, (at(X0, 0, Z1)).Position, (at(X1, 0, Z1)).Position, 12, 1, wallColor, Enum.Material.Concrete)
	local sign = Build.part(wing, Vector3.new(0.3, 1.4, 8), at(-50.8, 10.4, 30), Color3.fromRGB(150, 20, 24))
	Build.label(sign, Enum.NormalId.Right, "← INTERROGATION", Color3.new(1, 1, 1), Enum.Font.GothamBlack)
	-- Corridor x -60..-50, lights
	for z = -14, 38, 10 do
		Build.ceilingLight(wing, at(-55, 11.8, z), 18)
	end
	-- Rooms x -86..-60, each 15 deep, doors on the corridor side
	markers.Interrogation = {}
	local roomDepth = 15
	for i = 1, 4 do
		local z0 = Z0 + 1 + (i - 1) * roomDepth
		local z1 = z0 + roomDepth
		local zc = (z0 + z1) / 2
		-- Corridor-side wall with a door, and a one-way mirror
		Build.wall(wing, (at(-60, 0, z0)).Position, (at(-60, 0, zc - 2.5)).Position, 12, 0.8, wallColor, Enum.Material.Concrete)
		Build.wall(wing, (at(-60, 0, zc + 2.5)).Position, (at(-60, 0, z1)).Position, 12, 0.8, wallColor, Enum.Material.Concrete)
		Build.wall(wing, (at(-60, 8.5, zc - 2.5)).Position, (at(-60, 8.5, zc + 2.5)).Position, 3.5, 0.8, wallColor, Enum.Material.Concrete)
		if i < 4 then
			Build.wall(wing, (at(X0, 0, z1)).Position, (at(-60, 0, z1)).Position, 12, 0.8, wallColor, Enum.Material.Concrete)
		end
		local mirror = Build.part(wing, Vector3.new(0.3, 3.6, 5), at(-60, 5.6, z0 + 3.2), Color3.fromRGB(40, 50, 60), Enum.Material.Glass)
		mirror.Reflectance = 0.5
		mirror.Transparency = 0.25
		local plate = Build.part(wing, Vector3.new(0.2, 1, 4), at(-59.5, 10, zc), Color3.fromRGB(20, 20, 20))
		Build.label(plate, Enum.NormalId.Right, "ROOM " .. i, Color3.fromRGB(255, 80, 80), Enum.Font.GothamBlack)
		-- Table, chairs, hanging lamp
		local tx = -73
		Build.part(wing, Vector3.new(4, 0.3, 7), at(tx, 3.2, zc), Color3.fromRGB(90, 92, 96), Enum.Material.Metal)
		for _, dz in { -3, 3 } do
			for _, dx in { -1.7, 1.7 } do
				Build.part(wing, Vector3.new(0.3, 3.1, 0.3), at(tx + dx, 1.55, zc + dz), C.DarkMetal, Enum.Material.Metal)
			end
		end
		local function chair(cf, isSeat: boolean?)
			local seatPart: BasePart =
				Build.part(wing, Vector3.new(2, 0.3, 2), cf * CFrame.new(0, 2, 0), Color3.fromRGB(60, 60, 64), Enum.Material.Metal)
			if isSeat then
				local seat = Instance.new("Seat")
				seat.Anchored = true
				seat.Size = seatPart.Size
				seat.CFrame = seatPart.CFrame
				seat.Color = seatPart.Color
				seat.Material = seatPart.Material
				seat.CanTouch = false -- players can't sit by touching it; the server seats suspects
				seat.Parent = wing
				seatPart:Destroy()
				seatPart = seat
			end
			Build.part(wing, Vector3.new(2, 2.4, 0.3), cf * CFrame.new(0, 3.3, 1), Color3.fromRGB(60, 60, 64), Enum.Material.Metal)
			for _, dx in { -0.8, 0.8 } do
				for _, dz in { -0.8, 0.8 } do
					Build.part(wing, Vector3.new(0.2, 2, 0.2), cf * CFrame.new(dx, 1, dz), C.DarkMetal, Enum.Material.Metal)
				end
			end
			return seatPart
		end
		local suspectSeat = chair(at(tx, 0, zc + 5), true) -- suspect (faces -Z)
		chair(at(tx, 0, zc - 5) * CFrame.Angles(0, math.pi, 0)) -- officer
		Build.part(wing, Vector3.new(0.1, 4, 0.1), at(tx, 10, zc), C.DarkMetal)
		local shade = Build.part(wing, Vector3.new(2.2, 0.8, 2.2), at(tx, 7.8, zc), Color3.fromRGB(40, 44, 40), Enum.Material.Metal)
		local bulb = Build.ball(wing, 0.7, at(tx, 7.3, zc), Color3.fromRGB(255, 240, 200), Enum.Material.Neon)
		Build.spotLight(bulb, Enum.NormalId.Bottom, Color3.fromRGB(255, 236, 190), 16, 3, 70)
		CollectionService:AddTag(bulb, "PowerLight")
		local _ = shade
		-- Devices on the table
		local room = { Index = i, Prompts = {} }
		local polygraph = Build.part(wing, Vector3.new(1.8, 0.8, 1.2), at(tx - 1, 3.75, zc - 2), C.DarkMetal, Enum.Material.Metal)
		local paper = Build.part(wing, Vector3.new(1.3, 0.05, 0.7), at(tx - 1, 4.17, zc - 2), Color3.fromRGB(240, 240, 230))
		paper.CanCollide = false
		for k = 0, 2 do
			Build.part(wing, Vector3.new(0.05, 0.05, 2.6), at(tx - 1.6 + k * 0.4, 3.4, zc + 0.6), Color3.fromRGB(200, 40, 40)).CanCollide =
				false
		end
		room.Prompts.Interview = addPrompt(polygraph, "Lie Detector", "Ask questions", 0, 7)
		local reader = Build.part(wing, Vector3.new(1.3, 0.35, 1.3), at(tx + 1.1, 3.55, zc + 1.6), C.DarkMetal, Enum.Material.Metal)
		Build.part(wing, Vector3.new(0.8, 0.05, 0.8), at(tx + 1.1, 3.75, zc + 1.6), Color3.fromRGB(80, 200, 255), Enum.Material.Neon).CanCollide =
			false
		room.Prompts.Fingerprint = addPrompt(reader, "Fingerprints", "Scanner", 0, 7)
		room.Prompts.Fingerprint.KeyboardKeyCode = Enum.KeyCode.T
		local lamp = Build.cyl(wing, 1, 0.45, at(tx + 1.2, 4.1, zc - 1.8) * CFrame.Angles(0, math.pi / 2, 0), C.Metal, Enum.Material.Metal)
		Build.part(wing, Vector3.new(0.6, 0.5, 0.6), at(tx + 1.2, 3.6, zc - 1.8), C.DarkMetal)
		room.Prompts.Eyes = addPrompt(lamp, "Eye Exam", "Lamp", 0, 7)
		room.Prompts.Eyes.KeyboardKeyCode = Enum.KeyCode.Y
		-- Brain scanner: a helmet on an arm above the suspect's chair + a screen on the wall
		Build.part(wing, Vector3.new(0.4, 9, 0.4), at(tx + 2.6, 4.5, zc + 6.6), C.Metal, Enum.Material.Metal)
		Build.part(wing, Vector3.new(2.8, 0.4, 0.4), at(tx + 1.3, 8.8, zc + 6.6), C.Metal, Enum.Material.Metal)
		local helmet = Build.ball(wing, 1.8, at(tx, 8.2, zc + 5.6), Color3.fromRGB(220, 224, 232), Enum.Material.SmoothPlastic)
		helmet.Size = Vector3.new(2, 1.4, 2)
		for k = 0, 5 do
			local a = k * math.pi / 3
			Build.ball(
				wing,
				0.25,
				at(tx + math.cos(a) * 0.85, 8.1, zc + 5.6 + math.sin(a) * 0.85),
				Color3.fromRGB(80, 200, 255),
				Enum.Material.Neon
			).CanCollide =
				false
		end
		local brainScreen, brainLabel =
			monitor(wing, at(X0 + 0.7, 6.5, zc) * CFrame.Angles(0, -math.pi / 2, 0), 4.4, 2.6, "NEURO-SCAN\nIDLE")
		room.Prompts.Brain = addPrompt(brainScreen, "Brain Scan", "Neuro-scanner", 0, 14)
		room.Prompts.Brain.KeyboardKeyCode = Enum.KeyCode.B
		room.BrainLabel = brainLabel
		local _ = helmet
		-- Verdict stamps in the room
		local function stamp(dz, color, text)
			local base = Build.part(wing, Vector3.new(1, 0.5, 1), at(tx - 1.2, 3.6, zc + dz), color)
			Build.cyl(wing, 1, 0.35, at(tx - 1.2, 4.25, zc + dz) * CFrame.Angles(0, 0, math.pi / 2), C.Wood, Enum.Material.Wood)
			local tag = Build.part(
				wing,
				Vector3.new(1.6, 0.5, 0.05),
				at(tx - 2.05, 3.45, zc + dz) * CFrame.Angles(0, math.pi / 2, 0),
				Color3.fromRGB(20, 20, 20)
			)
			Build.label(tag, Enum.NormalId.Back, text, color, Enum.Font.GothamBlack)
			return base
		end
		room.Prompts.Approve = addPrompt(stamp(-0.2, Color3.fromRGB(40, 190, 80), "APPROVE"), "APPROVE", "Stamp", 0.4, 6)
		room.Prompts.Deny = addPrompt(stamp(1.2, Color3.fromRGB(210, 40, 40), "DENY"), "DENY", "Stamp", 0.4, 6)
		room.Prompts.Approve.KeyboardKeyCode = Enum.KeyCode.F
		room.Prompts.Deny.KeyboardKeyCode = Enum.KeyCode.G
		room.Seat = at(tx + 4, 0, zc + 5) -- walk here, then get seated
		room.SeatPart = suspectSeat
		room.Door = at(-57, 0, zc)
		room.OfficerSpot = at(tx, 3, zc - 4.6)
		markers.Interrogation[i] = room
	end
	markers.WingHallDoor = at(-47, 0, 30)
	markers.WingCorridorTop = at(-55, 0, 30)
end

-- origin: where this station sits in the world. Returns markers.
function StationBuilder.Build(parent: Instance, origin: CFrame, name: string)
	local m = Build.model(parent, name)
	local markers = { Model = m, Origin = origin, Lanes = {} }
	buildShell(m, origin)
	for i, x in LANE_X do
		markers.Lanes[i] = buildLane(m, origin, i, x)
	end
	buildBackRooms(m, origin, markers)
	buildHallDecor(m, origin, markers)
	buildPlatform(m, origin, markers)
	buildInterrogation(m, origin, markers)
	markers.Bounds =
		{ Min = origin * Vector3.new(HALL.X0 - 30, -5, HALL.Z0 - 10), Max = origin * Vector3.new(HALL.X1 + 40, 30, HALL.Z1 + 20) }
	return markers
end

return StationBuilder
