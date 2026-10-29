-- World effects: custom prompts, speech bubbles, bouncing arrows, blackout, stress, jumpscares,
-- taser, interrogation waypoint and the soundtrack.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local Audio = require(script.Parent.Audio)
local UI = require(script.Parent.UI)

local player = Players.LocalPlayer
local C = UI.Colors
local Effects = {}

local blackout = false

-- ===== Custom prompt: pink tag "[E] Take ID" like the screenshot =====
local function allowed(prompt: ProximityPrompt): boolean
	local list = prompt:GetAttribute("ForUsers")
	return list == nil or string.find(list, "," .. player.UserId .. ",", 1, true) ~= nil
end

local function showPrompt(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
	if prompt.Style ~= Enum.ProximityPromptStyle.Custom or not allowed(prompt) then
		return
	end
	local gui = UI.new("BillboardGui", {
		Name = "PromptUI",
		Size = UDim2.fromOffset(250, 64),
		AlwaysOnTop = true,
		LightInfluence = 0,
		Adornee = prompt.Parent,
		Parent = player:WaitForChild("PlayerGui"),
	})
	local key = UI.new(
		"Frame",
		{ Size = UDim2.fromOffset(56, 56), Position = UDim2.fromOffset(0, 4), BackgroundColor3 = Color3.fromRGB(70, 70, 80), Parent = gui }
	)
	UI.corner(key, 28)
	UI.stroke(key, 3, C.White)
	local keyText = if inputType == Enum.ProximityPromptInputType.Touch
		then "👆"
		elseif inputType == Enum.ProximityPromptInputType.Gamepad then "X"
		else UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)
	UI.text(key, keyText, { Size = UDim2.fromScale(0.6, 0.6), Position = UDim2.fromScale(0.2, 0.2), FontFace = UI.Bold })
	local ring = UI.new("Frame", {
		Size = UDim2.fromScale(1, 0),
		Position = UDim2.fromScale(0, 1),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = C.White,
		BackgroundTransparency = 0.5,
		Parent = key,
	})
	UI.corner(ring, 28)
	local tag = UI.new(
		"Frame",
		{ Size = UDim2.fromOffset(180, 50), Position = UDim2.fromOffset(62, 7), BackgroundColor3 = C.Pink, Rotation = -4, Parent = gui }
	)
	UI.corner(tag, 6)
	UI.new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(250, 190, 250), Color3.fromRGB(220, 120, 230)), Parent = tag })
	local label = UI.text(tag, prompt.ActionText, { Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1) })
	UI.outlined(label, 2.5)
	UI.pop(gui:FindFirstChildOfClass("Frame") :: Frame)
	local holding = false
	local c1 = prompt.PromptButtonHoldBegan:Connect(function()
		holding = true
		if prompt.HoldDuration > 0 then
			ring.Size = UDim2.fromScale(1, 0)
			UI.tween(ring, prompt.HoldDuration, { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Linear)
		end
	end)
	local c2 = prompt.PromptButtonHoldEnded:Connect(function()
		holding = false
		ring.Size = UDim2.fromScale(1, 0)
	end)
	local _ = holding
	-- Tap / click support
	local button = UI.new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = gui })
	gui.Active = true
	button.MouseButton1Down:Connect(function()
		prompt:InputHoldBegin()
	end)
	button.MouseButton1Up:Connect(function()
		prompt:InputHoldEnd()
	end)
	button.MouseLeave:Connect(function()
		prompt:InputHoldEnd()
	end)
	prompt.PromptHidden:Once(function()
		c1:Disconnect()
		c2:Disconnect()
		gui:Destroy()
	end)
end

-- ===== Speech bubbles =====
local function speech(head: BasePart, text: string)
	if not head or not head.Parent then
		return
	end
	local old = head:FindFirstChild("Speech")
	if old then
		old:Destroy()
	end
	local gui = UI.new("BillboardGui", {
		Name = "Speech",
		Size = UDim2.fromScale(9, 1.3), -- studs, so bubbles shrink with distance
		StudsOffset = Vector3.new(0, 3.2, 0),
		MaxDistance = 60,
		LightInfluence = 0,
		Adornee = head,
		Parent = head,
	})
	local bubble = UI.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(235, 236, 240),
		BackgroundTransparency = 0.05,
		AutomaticSize = Enum.AutomaticSize.None,
		Parent = gui,
	})
	UI.corner(bubble, 16)
	local label = UI.text(bubble, "", {
		Size = UDim2.new(1, -24, 1, -12),
		Position = UDim2.fromOffset(12, 6),
		TextColor3 = Color3.fromRGB(40, 40, 50),
		FontFace = UI.Bold,
		TextScaled = true,
	})
	local tail = UI.new("Frame", {
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(0.5, -8, 1, -8),
		Rotation = 45,
		BackgroundColor3 = Color3.fromRGB(235, 236, 240),
		Parent = bubble,
	})
	local _ = tail
	-- Typewriter
	task.spawn(function()
		for i = 1, #text do
			if not label.Parent then
				return
			end
			label.Text = string.sub(text, 1, i)
			task.wait(0.025)
		end
		task.wait(math.clamp(#text * 0.06, 2.5, 6))
		if gui.Parent then
			gui:Destroy()
		end
	end)
end

-- ===== Blackout visuals =====
local blackoutCC: ColorCorrectionEffect
local stressCC: ColorCorrectionEffect
local blur: BlurEffect

local function setBlackout(data)
	blackout = data and data.Active == true
	if blackout then
		UI.tween(blackoutCC, 1.5, { Brightness = -0.18, Contrast = 0.25, Saturation = -0.4, TintColor = Color3.fromRGB(255, 190, 190) })
		Audio.Loop("Ambience", 0)
		Audio.Loop("ChaseMusic", 1)
	else
		UI.tween(blackoutCC, 1.5, { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1) })
		Audio.Loop("ChaseMusic", 0)
		Audio.Loop("Heartbeat", 0)
		if player:GetAttribute("InShift") then
			Audio.Loop("Ambience", 1)
		end
	end
end

-- Monster sounds (growl + breathing) attached when one appears near us
local function onDescendant(inst: Instance)
	if inst:IsA("Model") and inst:GetAttribute("Monster") then
		local head = inst:WaitForChild("Head", 5) :: BasePart?
		if head then
			Audio.Attach("MonsterGrowl", head)
			Audio.Attach("MonsterBreath", head)
			Audio.Attach("MonsterSteps", head)
		end
	end
end

local function nearestMonster(): (Model?, number)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return nil, math.huge
	end
	local best, dist = nil, math.huge
	for _, d in CollectionService:GetTagged("Monster") do
		if d:IsA("Model") then
			local root = d:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				local m = (root.Position - hrp.Position).Magnitude
				if m < dist then
					best, dist = d, m
				end
			end
		end
	end
	return best, dist
end

-- ===== Jumpscare =====
local scareGui: ScreenGui
local function jumpscare(monster: Model?)
	Audio.Play("Jumpscare")
	Audio.Play("MonsterScreech", nil, 0.85)
	local frame = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Black, Parent = scareGui })
	local vp = UI.new("ViewportFrame", {
		Size = UDim2.fromScale(1.2, 1.2),
		Position = UDim2.fromScale(-0.1, -0.1),
		BackgroundColor3 = Color3.fromRGB(20, 0, 0),
		Ambient = Color3.fromRGB(255, 160, 160),
		LightColor = Color3.fromRGB(255, 80, 60),
		Parent = frame,
	})
	if monster and monster.Parent then
		monster.Archivable = true
		local clone = monster:Clone()
		if clone then
			clone.Parent = vp
			local head = clone:FindFirstChild("Head") :: BasePart?
			local camera = UI.new("Camera", { FieldOfView = 50, Parent = vp })
			if head then
				camera.CFrame = CFrame.lookAt((head.CFrame * CFrame.new(0, 0, -2.2)).Position, head.Position)
			end
			vp.CurrentCamera = camera
		end
	end
	local flash = UI.new(
		"Frame",
		{ Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, Parent = frame }
	)
	UI.tween(flash, 0.25, { BackgroundTransparency = 1 })
	local t0 = os.clock()
	local conn = RunService.RenderStepped:Connect(function()
		local k = math.max(0, 1 - (os.clock() - t0) / 1.4)
		vp.Position = UDim2.fromScale(-0.1 + (math.random() - 0.5) * 0.06 * k, -0.1 + (math.random() - 0.5) * 0.06 * k)
		vp.Size = UDim2.fromScale(1.2 + (os.clock() - t0) * 0.4, 1.2 + (os.clock() - t0) * 0.4)
	end)
	task.wait(1.3)
	conn:Disconnect()
	vp:Destroy()
	local text = UI.text(
		frame,
		"You were knocked out...",
		{ Size = UDim2.new(0.6, 0, 0, 60), Position = UDim2.fromScale(0.2, 0.45), TextColor3 = Color3.fromRGB(200, 40, 40) }
	)
	local _ = text
	task.wait(1.5)
	UI.tween(frame, 1, { BackgroundTransparency = 1 })
	task.wait(1)
	frame:Destroy()
end

-- ===== Taser =====
local function bolt(from: Vector3, to: Vector3)
	local segments = 8
	local last = from
	local parts = {}
	for i = 1, segments do
		local p = from:Lerp(to, i / segments)
		if i < segments then
			p += Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 1.2
		end
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.Material = Enum.Material.Neon
		part.Color = Color3.fromRGB(140, 220, 255)
		local len = (p - last).Magnitude
		part.Size = Vector3.new(0.15, 0.15, len)
		part.CFrame = CFrame.lookAt((last + p) / 2, p)
		part.Parent = workspace
		table.insert(parts, part)
		last = p
	end
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(140, 220, 255)
	light.Range = 16
	light.Brightness = 4
	light.Parent = parts[#parts]
	task.delay(0.15, function()
		for _, p in parts do
			p:Destroy()
		end
	end)
end

local function hookTaser(char: Model)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name == "Taser" and not child:GetAttribute("Hooked") then
			child:SetAttribute("Hooked", true)
			child.Activated:Connect(function()
				local mouse = player:GetMouse()
				Remotes.Taser:FireServer(mouse.Hit.Position)
			end)
		end
	end)
end

-- ===== Waypoint to the interrogation room =====
local waypointPart: Part?
local function updateWaypoint()
	local pos = player:GetAttribute("Waypoint")
	if waypointPart then
		waypointPart:Destroy()
		waypointPart = nil
	end
	if typeof(pos) ~= "Vector3" then
		return
	end
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Transparency = 1
	part.Position = pos + Vector3.new(0, 4, 0)
	part.Parent = workspace
	waypointPart = part
	local gui = UI.new("BillboardGui", { Size = UDim2.fromOffset(160, 80), AlwaysOnTop = true, LightInfluence = 0, Parent = part })
	UI.outlined(UI.text(gui, "⬇ ROOM", { Size = UDim2.new(1, 0, 0.6, 0), TextColor3 = Color3.fromRGB(255, 90, 90) }), 2)
	local dist = UI.text(gui, "", { Size = UDim2.new(1, 0, 0.4, 0), Position = UDim2.fromScale(0, 0.6) })
	UI.outlined(dist, 2)
	task.spawn(function()
		while waypointPart == part do
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				dist.Text = math.floor((hrp.Position - pos).Magnitude) .. " studs"
			end
			task.wait(0.2)
		end
	end)
end

function Effects.Init()
	ProximityPromptService.PromptShown:Connect(showPrompt)
	Remotes.Speech.OnClientEvent:Connect(speech)

	-- Bouncing arrows over the party pads
	local arrows = {}
	local function addArrow(part)
		arrows[part] = part.CFrame
	end
	for _, part in CollectionService:GetTagged("BounceArrow") do
		addArrow(part)
	end
	CollectionService:GetInstanceAddedSignal("BounceArrow"):Connect(addArrow)

	blackoutCC = UI.new("ColorCorrectionEffect", { Name = "BlackoutCC", Parent = Lighting })
	stressCC = UI.new("ColorCorrectionEffect", { Name = "StressCC", Parent = Lighting })
	blur = UI.new("BlurEffect", { Name = "StressBlur", Size = 0, Parent = Lighting })
	scareGui = UI.new(
		"ScreenGui",
		{ Name = "Scare", IgnoreGuiInset = true, DisplayOrder = 50, ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") }
	)

	Remotes.Blackout.OnClientEvent:Connect(setBlackout)
	Remotes.Scare.OnClientEvent:Connect(function(monster)
		task.spawn(jumpscare, monster)
	end)
	Remotes.Sfx.OnClientEvent:Connect(function(name, position, origin)
		if name == "Taser" and typeof(position) == "Vector3" and typeof(origin) == "Vector3" then
			bolt(origin, position)
		end
		Audio.Play(name, position)
	end)
	workspace.DescendantAdded:Connect(onDescendant)
	if player.Character then
		hookTaser(player.Character)
	end
	player.CharacterAdded:Connect(hookTaser)
	player:GetAttributeChangedSignal("Waypoint"):Connect(updateWaypoint)
	player:GetAttributeChangedSignal("InShift"):Connect(function()
		if player:GetAttribute("InShift") then
			Audio.Loop("LobbyMusic", 0)
			Audio.Loop("Ambience", 1)
		else
			Audio.Loop("Ambience", 0)
			Audio.Loop("ChaseMusic", 0)
			Audio.Loop("Heartbeat", 0)
			Audio.Loop("LobbyMusic", 1)
		end
	end)
	Audio.Loop("LobbyMusic", 1)

	local whisperAt = 0
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for part, base in arrows do
			if part.Parent then
				part.CFrame = base * CFrame.new(0, math.sin(t * 3) * 0.8, 0)
			else
				arrows[part] = nil
			end
		end
		-- Blackout: flicker + heartbeat by distance
		if blackout then
			local _, dist = nearestMonster()
			local closeness = math.clamp(1 - dist / 70, 0, 1)
			local hb = Audio.Loop("Heartbeat", 0.2 + closeness * 0.8)
			if hb then
				hb.PlaybackSpeed = 0.9 + closeness * 0.7
			end
			blackoutCC.Brightness = -0.18 + (if math.random() < 0.03 then 0.15 else 0)
			local camera = workspace.CurrentCamera
			if camera and closeness > 0.6 then
				camera.CFrame *= CFrame.new((math.random() - 0.5) * 0.06 * closeness, (math.random() - 0.5) * 0.06 * closeness, 0)
			end
		end
		-- Stress: colors drain, the view swims, whispers start
		local stress = (player:GetAttribute("Stress") or 0) / 100
		local k = math.clamp((stress - 0.5) / 0.5, 0, 1)
		stressCC.Saturation = -0.6 * k
		stressCC.Contrast = 0.2 * k
		blur.Size = if stress >= 1 then 6 + math.sin(t * 2) * 4 else 0
		local camera = workspace.CurrentCamera
		if camera then
			camera.FieldOfView = 70 + (if stress >= 1 then math.sin(t * 1.3) * 6 else 0)
		end
		if k > 0.6 and t > whisperAt then
			whisperAt = t + 12 + math.random() * 10
			Audio.Play("Whispers")
		end
	end)
end

return Effects
