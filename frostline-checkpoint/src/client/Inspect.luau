-- The inspection tool panels (passport, X-ray, body scan, CCTV, thermal, lie detector,
-- fingerprints, eye exam, brain scan, rulebook).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)

local C = UI.Colors
local Inspect = {}

local layer: Frame
local current: Frame? = nil
local cleanup: { RBXScriptConnection } = {}

local function close()
	for _, conn in cleanup do
		conn:Disconnect()
	end
	cleanup = {}
	if current then
		current:Destroy()
		current = nil
	end
end
Inspect.Close = close

-- A panel shell: dark frame with a title bar and close button.
local function panel(title: string, color: Color3, size: Vector2): Frame
	close()
	local frame = UI.new("Frame", {
		Size = UDim2.fromOffset(size.X, size.Y),
		Position = UDim2.new(0.34, 0, 0.52, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(24, 26, 32),
		Parent = layer,
	})
	UI.corner(frame, 12)
	UI.stroke(frame, 4, C.Black)
	local bar = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = color, Parent = frame })
	UI.corner(bar, 12)
	UI.new(
		"Frame",
		{ Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12), BackgroundColor3 = color, BorderSizePixel = 0, Parent = bar }
	)
	UI.text(
		bar,
		title,
		{ Size = UDim2.new(1, -80, 0.8, 0), Position = UDim2.fromScale(0.03, 0.1), TextXAlignment = Enum.TextXAlignment.Left }
	)
	UI.button(bar, "X", C.Red, close, { Size = UDim2.fromOffset(42, 42), Position = UDim2.new(1, -46, 0, 4), FontFace = UI.Bold })
	local body = UI.new(
		"Frame",
		{ Name = "Body", Size = UDim2.new(1, -24, 1, -64), Position = UDim2.fromOffset(12, 58), BackgroundTransparency = 1, Parent = frame }
	)
	-- A visible Modal button frees the mouse in first person while the panel is open
	UI.new(
		"TextButton",
		{ Name = "FreeMouse", Modal = true, BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(0, 0), Parent = frame }
	)
	current = frame
	UI.pop(frame)
	return body
end

-- Clone a character into a viewport, framed on the head (portrait) or full body.
local function viewport(parent: Instance, model: Model?, framing: string, mutate: ((Model) -> ())?): ViewportFrame
	local vp = UI.new("ViewportFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(190, 200, 214),
		Ambient = Color3.fromRGB(170, 170, 170),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-0.4, -1, -0.6),
		Parent = parent,
	})
	if not model or not model.Parent then
		UI.text(vp, "NO SIGNAL", { Size = UDim2.fromScale(0.8, 0.3), Position = UDim2.fromScale(0.1, 0.35), TextColor3 = C.Red })
		return vp
	end
	local was = model.Archivable
	model.Archivable = true
	local clone = model:Clone()
	model.Archivable = was
	if not clone then
		return vp
	end
	for _, d in clone:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Sound") then
			d:Destroy()
		end
	end
	local suitcase = clone:FindFirstChild("Suitcase")
	if suitcase then
		suitcase:Destroy()
	end
	if mutate then
		mutate(clone)
	end
	clone.Parent = vp
	local camera = UI.new("Camera", { FieldOfView = 26, Parent = vp })
	local head = clone:FindFirstChild("Head") :: BasePart?
	local root = clone:FindFirstChild("HumanoidRootPart") :: BasePart?
	if framing == "Portrait" and head then
		local front = head.CFrame
		camera.CFrame = CFrame.lookAt((front * CFrame.new(0, 0.05, -5.2)).Position, front.Position)
	elseif root then
		local front = root.CFrame
		camera.FieldOfView = 40
		camera.CFrame = CFrame.lookAt((front * CFrame.new(1.5, 3.5, -10)).Position, front.Position + Vector3.new(0, 0.5, 0))
	end
	vp.CurrentCamera = camera
	return vp
end

local function addFacePart(head: BasePart, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CFrame = head.CFrame * offset
	p.Parent = head.Parent
	return p
end

local function field(parent: Instance, y: number, label: string, value: string, x: number?, width: number?)
	UI.text(parent, label, {
		Size = UDim2.fromOffset(width or 220, 18),
		Position = UDim2.fromOffset(x or 0, y),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(110, 70, 70),
		FontFace = UI.Bold,
	})
	UI.text(parent, value, {
		Size = UDim2.fromOffset(width or 220, 28),
		Position = UDim2.fromOffset(x or 0, y + 17),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = C.Ink,
		FontFace = UI.Mono,
	})
end

local tools = {}

function tools.Passport(data)
	local body = panel("🛂 PASSPORT & TICKET", Color3.fromRGB(120, 24, 36), Vector2.new(720, 520))
	-- Passport booklet
	local book = UI.new("Frame", { Size = UDim2.fromOffset(420, 330), BackgroundColor3 = Color3.fromRGB(246, 236, 220), Parent = body })
	UI.corner(book, 8)
	UI.stroke(book, 3, Color3.fromRGB(120, 24, 36))
	UI.text(book, "REPUBLIC OF " .. string.upper(data.Country) .. "  ·  PASSPORT", {
		Size = UDim2.new(1, -20, 0, 26),
		Position = UDim2.fromOffset(10, 6),
		TextColor3 = Color3.fromRGB(120, 24, 36),
		FontFace = UI.Bold,
	})
	local photoFrame = UI.new(
		"Frame",
		{ Size = UDim2.fromOffset(150, 186), Position = UDim2.fromOffset(12, 40), BackgroundColor3 = C.White, Parent = book }
	)
	UI.stroke(photoFrame, 2, Color3.fromRGB(80, 80, 80))
	viewport(photoFrame, data.Model, "Portrait", function(clone)
		local head = clone:FindFirstChild("Head") :: BasePart?
		if not head or not data.Photo then
			return
		end
		if data.Photo == "BlackEyes" then
			for _, x in { -0.2, 0.2 } do
				addFacePart(head, Vector3.new(0.22, 0.26, 0.05), CFrame.new(x, 0.12, -0.6), Color3.new(0, 0, 0))
			end
		elseif data.Photo == "WrongHair" then
			local hair = clone:FindFirstChild("Hair")
			local recolored = false
			if hair then
				for _, p in hair:GetDescendants() do
					if p:IsA("BasePart") then
						p.Color = Color3.fromRGB(250, 250, 250)
						recolored = true
					end
				end
			end
			if not recolored then
				addFacePart(head, Vector3.new(1.3, 0.5, 1.3), CFrame.new(0, 0.62, 0.05), Color3.fromRGB(240, 120, 20))
			end
		elseif data.Photo == "WideSmile" then
			addFacePart(head, Vector3.new(1.05, 0.12, 0.05), CFrame.new(0, -0.22, -0.6), Color3.fromRGB(30, 0, 0))
			for i = -4, 4 do
				addFacePart(head, Vector3.new(0.05, 0.08, 0.05), CFrame.new(i * 0.11, -0.17, -0.62), Color3.new(1, 1, 1))
			end
		end
	end)
	local info = UI.new(
		"Frame",
		{ Size = UDim2.fromOffset(240, 280), Position = UDim2.fromOffset(176, 40), BackgroundTransparency = 1, Parent = book }
	)
	field(info, 0, "SURNAME", string.upper(data.Last))
	field(info, 46, "GIVEN NAME", string.upper(data.First))
	field(info, 92, "DATE OF BIRTH", data.Birth)
	field(info, 138, "PASSPORT NO.", data.PassportNo)
	field(info, 184, "EXPIRES", data.Expiry)
	if data.Print then
		field(info, 230, "FINGERPRINT", string.upper(data.Print))
	end
	UI.text(book, "<<" .. string.upper(data.Last) .. "<<" .. string.upper(data.First) .. "<<<<<<<<<" .. data.PassportNo, {
		Size = UDim2.new(1, -20, 0, 22),
		Position = UDim2.new(0, 10, 1, -30),
		TextColor3 = Color3.fromRGB(80, 80, 90),
		FontFace = UI.Mono,
	})
	-- Ticket
	local ticket = UI.new("Frame", {
		Size = UDim2.fromOffset(260, 330),
		Position = UDim2.fromOffset(436, 0),
		BackgroundColor3 = Color3.fromRGB(250, 248, 240),
		Parent = body,
	})
	UI.corner(ticket, 8)
	UI.stroke(ticket, 3, C.Navy)
	local band = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = C.Navy, Parent = ticket })
	UI.corner(band, 8)
	UI.text(band, "🚆 FROSTLINE NIGHT TRAIN", { Size = UDim2.fromScale(0.92, 0.7), Position = UDim2.fromScale(0.04, 0.15) })
	local tinfo = UI.new(
		"Frame",
		{ Size = UDim2.new(1, -24, 1, -60), Position = UDim2.fromOffset(12, 54), BackgroundTransparency = 1, Parent = ticket }
	)
	field(tinfo, 0, "PASSENGER", string.upper(data.Ticket.Name), 0, 236)
	field(tinfo, 52, "DESTINATION", string.upper(data.Ticket.Destination), 0, 236)
	field(tinfo, 104, "VALID FOR", "NIGHT " .. data.Ticket.Night, 0, 236)
	field(tinfo, 156, "CLASS", "SLEEPER · CAR 3", 0, 236)
	UI.text(tinfo, "TODAY: " .. data.Today, {
		Size = UDim2.fromOffset(236, 24),
		Position = UDim2.fromOffset(0, 220),
		TextColor3 = C.Red,
		FontFace = UI.Bold,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	-- Stamp buttons
	UI.button(body, "✔ APPROVE (F)", C.Green, function()
		Remotes.Decide:InvokeServer(true)
	end, { Size = UDim2.fromOffset(330, 70), Position = UDim2.fromOffset(10, 352) })
	UI.button(body, "✖ DENY (G)", C.Red, function()
		Remotes.Decide:InvokeServer(false)
	end, { Size = UDim2.fromOffset(330, 70), Position = UDim2.fromOffset(356, 352) })
end

function tools.Rulebook(data)
	local body = panel("📋 TONIGHT'S RULES · SHIFT " .. (data.Shift or "?"), C.Navy, Vector2.new(620, 560))
	local paper = UI.new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(250, 248, 236),
		ScrollBarThickness = 8,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = body,
	})
	UI.corner(paper, 8)
	UI.pad(paper, 14)
	UI.list(paper, 10)
	for i, line in data.Lines do
		local label = UI.text(paper, i .. ". " .. line, {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextScaled = false,
			TextSize = 23,
			TextWrapped = true,
			FontFace = UI.Hand,
			TextColor3 = if string.find(line, "NOT human") then C.Red else C.Ink,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = i,
		})
		local _ = label
	end
end

function tools.XRay(data)
	local body = panel("☢ X-RAY · LUGGAGE", Color3.fromRGB(40, 70, 160), Vector2.new(620, 460))
	local screen = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(10, 26, 60), Parent = body })
	UI.corner(screen, 8)
	UI.new(
		"UIGradient",
		{ Color = ColorSequence.new(Color3.fromRGB(20, 50, 110), Color3.fromRGB(6, 14, 40)), Rotation = 90, Parent = screen }
	)
	-- Suitcase outline
	local case = UI.new(
		"Frame",
		{ Size = UDim2.new(1, -40, 1, -40), Position = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, Parent = screen }
	)
	UI.stroke(case, 4, Color3.fromRGB(120, 200, 255))
	UI.corner(case, 16)
	UI.pad(case, 16)
	UI.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(170, 150),
		CellPadding = UDim2.fromOffset(12, 12),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = case,
	})
	for _, item in data.Items do
		local cell = UI.new("Frame", { BackgroundTransparency = 1, Parent = case })
		local icon = UI.text(cell, item.Icon, { Size = UDim2.new(1, 0, 0.72, 0), FontFace = UI.Bold, TextTransparency = 0.15 })
		local _ = icon
		UI.text(cell, item.Name, {
			Size = UDim2.new(1, 0, 0.24, 0),
			Position = UDim2.fromScale(0, 0.74),
			TextColor3 = Color3.fromRGB(170, 220, 255),
			FontFace = UI.Mono,
		})
		if item.Category == "Anomalous" then
			task.spawn(function()
				while cell.Parent do
					icon.Rotation = math.random(-4, 4)
					task.wait(0.08)
				end
			end)
		end
	end
end

function tools.Skeleton(data)
	local body = panel("🦴 BODY SCAN", Color3.fromRGB(30, 120, 140), Vector2.new(480, 560))
	local screen = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(6, 30, 36), Parent = body })
	UI.corner(screen, 8)
	local s = data.Skeleton
	local bone = Color3.fromRGB(220, 250, 255)
	local function line(x, y, w, h, rot)
		local f = UI.new("Frame", {
			Size = UDim2.fromOffset(w, h),
			Position = UDim2.fromOffset(x, y),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = rot or 0,
			BackgroundColor3 = bone,
			Parent = screen,
		})
		UI.corner(f, math.min(w, h) // 2)
		return f
	end
	local cx = 228
	local stretch = if s.LongArms then 1.5 else 1
	if s.Skull > 0 then
		local skull = line(cx, 64, 62, 72)
		UI.corner(skull, 30)
		for _, dx in { -12, 12 } do
			local eye = UI.new("Frame", {
				Size = UDim2.fromOffset(14, 16),
				Position = UDim2.fromOffset(31 + dx - 7, 28),
				BackgroundColor3 = Color3.fromRGB(6, 30, 36),
				Parent = skull,
			})
			UI.corner(eye, 7)
		end
	end
	if s.Ribs ~= "None" then
		line(cx, 230, 10, 200) -- spine
		local pairs_ = if s.Ribs == "Extra" then 10 else 6
		for i = 1, pairs_ do
			local y = 130 + i * (120 / pairs_)
			line(cx - 34, y, 60, 6, 12)
			line(cx + 34, y, 60, 6, -12)
		end
		line(cx, 336, 90, 16) -- pelvis
	end
	for side = -1, 1, 2 do
		if s.Arms > 0 then
			line(cx + side * 80, 160 + 40 * stretch, 10, 110 * stretch, side * -12)
			line(cx + side * 98, 160 + 80 * stretch + 60 * stretch, 9, 100 * stretch, side * -4)
		end
		if s.Legs > 0 then
			line(cx + side * 28, 400, 12, 120, side * 4)
			line(cx + side * 34, 486, 11, 100, 0)
		end
	end
	local height = math.floor(data.Height * 175) / 100
	UI.text(screen, "HEIGHT " .. height .. " m", {
		Size = UDim2.fromOffset(200, 26),
		Position = UDim2.fromOffset(10, 8),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = C.Cyan,
		FontFace = UI.Mono,
	})
	-- Scan sweep
	local sweep = UI.new(
		"Frame",
		{ Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = C.Cyan, BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = screen }
	)
	table.insert(
		cleanup,
		RunService.RenderStepped:Connect(function()
			sweep.Position = UDim2.fromScale(0, (os.clock() * 0.4) % 1)
		end)
	)
end

function tools.Camera(data)
	local body = panel("📹 CCTV · CAM 0" .. (data.Lane or 1), Color3.fromRGB(30, 30, 34), Vector2.new(640, 480))
	local holder = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, Parent = body })
	local vp = viewport(holder, data.Model, "Full", function(clone)
		if not data.TrueForm then
			return
		end
		-- The camera sees what it really is
		for _, p in clone:GetDescendants() do
			if p:IsA("BasePart") then
				p.Color = Color3.fromRGB(12, 12, 14)
				p.Material = Enum.Material.SmoothPlastic
			elseif p:IsA("Decal") then
				p:Destroy()
			end
		end
		local head = clone:FindFirstChild("Head") :: BasePart?
		if head then
			head.Size *= Vector3.new(1, 1.35, 1)
			for _, x in { -0.24, 0.24 } do
				addFacePart(head, Vector3.new(0.26, 0.36, 0.05), CFrame.new(x, 0.18, -0.62), Color3.new(1, 1, 1), Enum.Material.Neon)
			end
			addFacePart(head, Vector3.new(0.9, 0.5, 0.05), CFrame.new(0, -0.35, -0.62), Color3.fromRGB(120, 0, 0), Enum.Material.Neon)
		end
	end)
	vp.BackgroundColor3 = Color3.fromRGB(40, 50, 44)
	vp.ImageColor3 = Color3.fromRGB(170, 255, 190)
	vp.Ambient = Color3.fromRGB(120, 140, 120)
	-- Scanlines + noise + timestamp
	for i = 0, 40 do
		UI.new("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.fromScale(0, i / 40),
			BackgroundColor3 = C.Black,
			BackgroundTransparency = 0.75,
			BorderSizePixel = 0,
			Parent = holder,
		})
	end
	local rec = UI.text(holder, "● REC", {
		Size = UDim2.fromOffset(100, 30),
		Position = UDim2.fromOffset(12, 10),
		TextColor3 = C.Red,
		FontFace = UI.Mono,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local clock = UI.text(holder, "", {
		Size = UDim2.fromOffset(240, 26),
		Position = UDim2.new(1, -252, 1, -36),
		TextColor3 = C.White,
		FontFace = UI.Mono,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	local noise = UI.new(
		"Frame",
		{ Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.95, Parent = holder }
	)
	table.insert(
		cleanup,
		RunService.RenderStepped:Connect(function()
			rec.Visible = os.clock() % 1 < 0.6
			clock.Text = os.date("!%H:%M:%S", 4380 + math.floor(os.clock())) .. "  12/2026"
			noise.BackgroundTransparency = 0.9 + math.random() * 0.08
			if data.TrueForm and math.random() < 0.04 then
				vp.Position = UDim2.fromOffset(math.random(-8, 8), 0)
			else
				vp.Position = UDim2.new()
			end
		end)
	)
end

function tools.Thermal(data)
	local body = panel("🌡 THERMAL CAMERA", Color3.fromRGB(190, 80, 20), Vector2.new(460, 480))
	local screen = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(10, 0, 40), Parent = body })
	UI.corner(screen, 8)
	local t = data.Temperature
	local heat = math.clamp((t - 5) / 35, 0, 1)
	local hot = Color3.fromRGB(40, 60, 255):Lerp(Color3.fromRGB(255, 220, 40), heat)
	if t >= 38 then
		hot = Color3.fromRGB(255, 70, 20)
	end
	-- Silhouette
	local head =
		UI.new("Frame", { Size = UDim2.fromOffset(80, 96), Position = UDim2.new(0.5, -40, 0, 40), BackgroundColor3 = hot, Parent = screen })
	UI.corner(head, 40)
	local torso = UI.new(
		"Frame",
		{ Size = UDim2.fromOffset(170, 220), Position = UDim2.new(0.5, -85, 0, 140), BackgroundColor3 = hot, Parent = screen }
	)
	UI.corner(torso, 30)
	UI.new("UIGradient", { Color = ColorSequence.new(hot, hot:Lerp(Color3.fromRGB(80, 0, 160), 0.6)), Rotation = 90, Parent = torso })
	UI.new("UIGradient", { Color = ColorSequence.new(hot, hot:Lerp(Color3.fromRGB(80, 0, 160), 0.4)), Rotation = 90, Parent = head })
	local reading = UI.text(
		screen,
		string.format("%.1f °C", t),
		{ Size = UDim2.new(1, 0, 0, 56), Position = UDim2.new(0, 0, 1, -64), TextColor3 = C.White, FontFace = UI.Mono }
	)
	UI.outlined(reading, 2)
end

function tools.Interview(data)
	local body = panel("🎙 LIE DETECTOR · INTERROGATION", Color3.fromRGB(150, 30, 30), Vector2.new(680, 560))
	local graph = UI.new(
		"Frame",
		{ Size = UDim2.new(1, 0, 0, 170), BackgroundColor3 = Color3.fromRGB(246, 244, 232), ClipsDescendants = true, Parent = body }
	)
	UI.corner(graph, 8)
	for i = 1, 4 do
		UI.new("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.fromScale(0, i / 5),
			BackgroundColor3 = Color3.fromRGB(200, 170, 170),
			BorderSizePixel = 0,
			Parent = graph,
		})
	end
	local bars = {}
	local N = 90
	for i = 1, N do
		bars[i] = UI.new("Frame", {
			Size = UDim2.new(1 / N, 1, 0, 2),
			Position = UDim2.fromScale((i - 1) / N, 0.5),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BorderSizePixel = 0,
			Parent = graph,
		})
	end
	local spikeUntil = 0
	local values = table.create(N, 0)
	local acc = 0
	table.insert(
		cleanup,
		RunService.RenderStepped:Connect(function(dt)
			acc += dt
			if acc < 0.03 then
				return
			end
			acc = 0
			table.remove(values, 1)
			local amp = if os.clock() < spikeUntil then 0.85 else 0.12
			table.insert(values, (math.random() * 2 - 1) * amp)
			for i, v in values do
				bars[i].Size = UDim2.new(1 / N, 1, math.abs(v), 2)
				bars[i].BackgroundColor3 = if math.abs(v) > 0.5 then C.Red else Color3.fromRGB(30, 30, 30)
			end
		end)
	)
	local transcript = UI.new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, 170),
		Position = UDim2.fromOffset(0, 180),
		BackgroundColor3 = Color3.fromRGB(34, 36, 44),
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = body,
	})
	UI.corner(transcript, 8)
	UI.pad(transcript, 10)
	UI.list(transcript, 6)
	local order = 0
	local function say(who: string, text: string, color: Color3)
		order += 1
		UI.text(transcript, who .. ": " .. text, {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextScaled = false,
			TextSize = 21,
			TextWrapped = true,
			FontFace = UI.Hand,
			TextColor3 = color,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = order,
		})
		transcript.CanvasPosition = Vector2.new(0, 10000)
	end
	local buttons =
		UI.new("Frame", { Size = UDim2.new(1, 0, 0, 130), Position = UDim2.fromOffset(0, 360), BackgroundTransparency = 1, Parent = body })
	UI.list(buttons, 6)
	for i, q in data.Questions do
		UI.button(buttons, "❓ " .. q, C.Navy, function()
			say("YOU", q, C.Cyan)
			local result = Remotes.Ask:InvokeServer(i)
			if result then
				task.wait(0.6)
				say(string.upper(data.Name or "SUSPECT"), result.Answer, if result.Spike then Color3.fromRGB(255, 120, 120) else C.White)
				if result.Spike then
					spikeUntil = os.clock() + 2.5
				end
			end
		end, { Size = UDim2.new(1, 0, 0, 38), LayoutOrder = i, TextXAlignment = Enum.TextXAlignment.Left })
	end
end

local PRINT_GLYPH = {
	Whorl = "🌀",
	Loop = "➰",
	Arch = "⌒",
	["Double Loop"] = "➿",
	["Tented Arch"] = "⛛",
	Spiral = "@",
	Smudged = "▒",
	None = "",
}

function tools.Fingerprint(data)
	local body = panel("🖐 FINGERPRINT SCANNER", Color3.fromRGB(30, 110, 170), Vector2.new(560, 380))
	local function card(x, title, pattern)
		local f = UI.new("Frame", {
			Size = UDim2.fromOffset(250, 290),
			Position = UDim2.fromOffset(x, 0),
			BackgroundColor3 = Color3.fromRGB(230, 244, 255),
			Parent = body,
		})
		UI.corner(f, 10)
		UI.stroke(f, 3, C.Navy)
		UI.text(f, title, { Size = UDim2.new(1, -10, 0, 30), Position = UDim2.fromOffset(5, 6), TextColor3 = C.Ink })
		local pad = UI.new("Frame", {
			Size = UDim2.fromOffset(160, 180),
			Position = UDim2.new(0.5, -80, 0, 44),
			BackgroundColor3 = Color3.fromRGB(250, 250, 250),
			Parent = f,
		})
		UI.corner(pad, 70)
		UI.text(pad, if pattern then PRINT_GLYPH[pattern] or "?" else "—", {
			Size = UDim2.fromScale(0.8, 0.8),
			Position = UDim2.fromScale(0.1, 0.1),
			TextColor3 = Color3.fromRGB(40, 40, 60),
			FontFace = UI.Bold,
		})
		UI.text(f, if pattern == "None" then "NO PRINT DETECTED" else string.upper(pattern or "NOT ON FILE"), {
			Size = UDim2.new(1, -10, 0, 30),
			Position = UDim2.new(0, 5, 1, -40),
			TextColor3 = if pattern == "None" then C.Red else C.Ink,
			FontFace = UI.Mono,
		})
	end
	card(0, "SCANNED NOW", data.Scanned)
	card(276, "PRINTED IN PASSPORT", data.Printed)
end

function tools.Eyes(data)
	local body = panel("👁 EYE EXAM", Color3.fromRGB(90, 60, 150), Vector2.new(560, 380))
	local light = false
	local eyes = {}
	for i, x in { 70, 290 } do
		local white = UI.new("Frame", {
			Size = UDim2.fromOffset(180, 120),
			Position = UDim2.fromOffset(x - 30, 30),
			BackgroundColor3 = Color3.fromRGB(245, 240, 236),
			Parent = body,
		})
		UI.corner(white, 60)
		local iris = UI.new("Frame", {
			Size = UDim2.fromOffset(84, 84),
			Position = UDim2.new(0.5, -42, 0.5, -42),
			BackgroundColor3 = Color3.fromRGB(70, 110, 160),
			Parent = white,
		})
		UI.corner(iris, 42)
		local pupil = UI.new("Frame", {
			Size = UDim2.fromOffset(38, 38),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = C.Black,
			Parent = iris,
		})
		UI.corner(pupil, 19)
		if data.Eyes == "NoPupils" then
			pupil.Visible = false
			iris.BackgroundColor3 = Color3.fromRGB(235, 235, 240)
		elseif data.Eyes == "Slit" then
			pupil.Size = UDim2.fromOffset(10, 70)
			iris.BackgroundColor3 = Color3.fromRGB(200, 170, 40)
		elseif data.Eyes == "Glowing" then
			iris.BackgroundColor3 = Color3.fromRGB(120, 230, 255)
			pupil.BackgroundColor3 = Color3.fromRGB(220, 250, 255)
		end
		eyes[i] = pupil
	end
	UI.button(body, "🔦 SHINE LIGHT", Color3.fromRGB(200, 160, 20), function()
		light = not light
		for _, pupil in eyes do
			if data.Eyes == "Normal" then
				UI.tween(pupil, 0.3, { Size = if light then UDim2.fromOffset(16, 16) else UDim2.fromOffset(38, 38) })
			end
		end
	end, { Size = UDim2.fromOffset(300, 64), Position = UDim2.new(0.5, -150, 0, 200) })
end

function tools.Brain(data)
	local body = panel("🧠 NEURO-SCAN", Color3.fromRGB(150, 40, 150), Vector2.new(560, 440))
	local screen = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(14, 10, 26), Parent = body })
	UI.corner(screen, 8)
	local dots = { {}, {} }
	for side = 1, 2 do
		local half = UI.new("Frame", {
			Size = UDim2.fromOffset(210, 260),
			Position = UDim2.fromOffset(if side == 1 then 50 else 276, 40),
			BackgroundColor3 = Color3.fromRGB(60, 40, 80),
			Parent = screen,
		})
		UI.corner(half, 100)
		for i = 1, 24 do
			local d = UI.new("Frame", {
				Size = UDim2.fromOffset(18, 18),
				Position = UDim2.fromScale(0.15 + ((i - 1) % 4) * 0.2, 0.1 + math.floor((i - 1) / 4) * 0.14),
				BackgroundColor3 = Color3.fromRGB(255, 80, 200),
				BackgroundTransparency = 1,
				Parent = half,
			})
			UI.corner(d, 9)
			dots[side][i] = d
		end
	end
	UI.text(screen, "SCANNING...", {
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0, 0, 1, -40),
		TextColor3 = Color3.fromRGB(255, 160, 230),
		FontFace = UI.Mono,
	})
	local acc = 0
	table.insert(
		cleanup,
		RunService.RenderStepped:Connect(function(dt)
			acc += dt
			if acc < 0.12 then
				return
			end
			acc = 0
			for i = 1, 24 do
				local a, b
				if data.Brain == "Flat" then
					a, b = 1, 1
				elseif data.Brain == "Mirror" then
					a = if math.random() < 0.3 then 0 else 1
					b = a
				elseif data.Brain == "Static" then
					a, b = math.random() * 0.6, math.random() * 0.6
					dots[1][i].BackgroundColor3 = Color3.fromRGB(200, 200, 200)
					dots[2][i].BackgroundColor3 = Color3.fromRGB(200, 200, 200)
				else
					a = if math.random() < 0.25 then 0 else 1
					b = if math.random() < 0.25 then 0 else 1
				end
				dots[1][i].BackgroundTransparency = a
				dots[2][i].BackgroundTransparency = b
			end
		end)
	)
end

function Inspect.Open(key: string, data)
	local builder = tools[key]
	if builder and data then
		builder(data)
	end
end

function Inspect.Init(gui: ScreenGui)
	layer = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = gui })
	local s = UI.new("UIScale", { Parent = layer })
	local function apply()
		local camera = workspace.CurrentCamera
		local size = camera and camera.ViewportSize or Vector2.new(1920, 1080)
		s.Scale = math.clamp(math.min(size.X / 1600, size.Y / 900), 0.5, 1.1)
		layer.Size = UDim2.fromScale(1 / s.Scale, 1 / s.Scale)
	end
	apply()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(apply)
	end
	Remotes.OpenTool.OnClientEvent:Connect(Inspect.Open)
	Remotes.CloseTools.OnClientEvent:Connect(close)
end

return Inspect
