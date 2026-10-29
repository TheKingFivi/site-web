-- All 2D UI: lobby buttons, currencies, shift banner, objective card, rank card,
-- party/shop/skins/rewards menus, toasts, verdicts and results.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SocialService = game:GetService("SocialService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)

local player = Players.LocalPlayer
local C = UI.Colors

local HUD = {}

local gui: ScreenGui
local menuLayer: Frame
local lobbyLayer: Frame
local shiftLayer: Frame
local openMenu: GuiObject? = nil
local state = { InShift = false, Shift = nil }

local function closeMenu()
	if openMenu then
		openMenu:Destroy()
		openMenu = nil
	end
end
HUD.CloseMenu = closeMenu

-- Black strip toast like "Daily reward: $25 starting cash"
local toastHolder: Frame
function HUD.Toast(text: string, kind: string?)
	local color = if kind == "success" then C.Yellow elseif kind == "warn" then Color3.fromRGB(255, 120, 100) else C.White
	local strip = UI.new("Frame", {
		Size = UDim2.new(0.6, 0, 0, 44),
		BackgroundColor3 = C.Black,
		BackgroundTransparency = 0.15,
		Parent = toastHolder,
	})
	UI.new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.15, 0),
			NumberSequenceKeypoint.new(0.85, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = strip,
	})
	UI.text(strip, text, { TextColor3 = color, Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1) })
	task.delay(3.5, function()
		UI.tween(strip, 0.4, { BackgroundTransparency = 1 })
		local label = strip:FindFirstChildOfClass("TextLabel")
		if label then
			UI.tween(label, 0.4, { TextTransparency = 1 })
		end
		task.wait(0.45)
		strip:Destroy()
	end)
end

-- Big centered banner
local bannerLabel: TextLabel
function HUD.Announce(text: string, hex: string?)
	if text == "" then
		return
	end
	bannerLabel.Text = text
	bannerLabel.TextColor3 = if hex then Color3.fromHex(hex) else C.White
	bannerLabel.TextTransparency = 0
	local stroke = bannerLabel:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = 0
	end
	local scale = bannerLabel:FindFirstChildOfClass("UIScale") or UI.new("UIScale", { Parent = bannerLabel })
	scale.Scale = 1.6
	UI.tween(scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(2.6, function()
		if bannerLabel.Text == text then
			UI.tween(bannerLabel, 0.6, { TextTransparency = 1 })
			if stroke then
				UI.tween(stroke, 0.6, { Transparency = 1 })
			end
		end
	end)
end

-- ===== Lobby HUD =====
local function sideButton(parent: Instance, order: number, icon: string, label: string, color: Color3, textColor: Color3, onClick: () -> ())
	local button = UI.new("TextButton", {
		Size = UDim2.fromOffset(104, 104),
		BackgroundColor3 = color,
		Text = "",
		LayoutOrder = order,
		AutoButtonColor = true,
		Parent = parent,
	})
	UI.corner(button, 14)
	UI.stroke(button, 4, C.NavyDark)
	UI.text(
		button,
		icon,
		{ Size = UDim2.new(1, 0, 0.58, 0), Position = UDim2.fromScale(0, 0.06), FontFace = UI.Bold, TextColor3 = textColor }
	)
	UI.text(button, label, { Size = UDim2.new(0.9, 0, 0.24, 0), Position = UDim2.fromScale(0.05, 0.68), TextColor3 = textColor })
	button.MouseButton1Click:Connect(onClick)
	return button
end

local function currencyPill(parent: Instance, order: number, icon: string, attribute: string, color: Color3)
	local frame = UI.new("Frame", { Size = UDim2.fromOffset(200, 58), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
	local pill = UI.new(
		"Frame",
		{ Size = UDim2.fromOffset(130, 48), Position = UDim2.fromOffset(30, 5), BackgroundColor3 = C.White, Parent = frame }
	)
	UI.corner(pill, 8)
	UI.stroke(pill, 3, C.NavyDark)
	local amount = UI.text(pill, "0", { Size = UDim2.new(1, -40, 0.75, 0), Position = UDim2.fromScale(0.28, 0.12), TextColor3 = C.Ink })
	UI.text(frame, icon, { Size = UDim2.fromOffset(58, 58), FontFace = UI.Bold })
	UI.button(frame, "+", C.Green, function()
		HUD.OpenShop("Currency")
	end, { Size = UDim2.fromOffset(48, 48), Position = UDim2.fromOffset(150, 5), FontFace = UI.Bold })
	local function update()
		amount.Text = Format.Abbrev(player:GetAttribute(attribute) or 0)
		amount.TextColor3 = C.Ink
	end
	player:GetAttributeChangedSignal(attribute):Connect(update)
	update()
	local _ = color
	return frame
end

local function buildLobby()
	lobbyLayer = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = gui })
	local side = UI.new("Frame", {
		Size = UDim2.fromOffset(110, 460),
		Position = UDim2.new(1, -16, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Parent = lobbyLayer,
	})
	UI.list(side, 14, false, Enum.HorizontalAlignment.Right)
	local rewards = sideButton(side, 1, "🎁", "REWARDS", C.White, C.Ink, function()
		HUD.OpenRewards()
	end)
	local dot = UI.new(
		"Frame",
		{ Size = UDim2.fromOffset(22, 22), Position = UDim2.new(1, -16, 0, -6), BackgroundColor3 = C.Red, Parent = rewards }
	)
	UI.corner(dot, 11)
	local function updateDot()
		dot.Visible = player:GetAttribute("DailyReady") == true
	end
	player:GetAttributeChangedSignal("DailyReady"):Connect(updateDot)
	updateDot()
	sideButton(side, 2, "👤+", "INVITE", C.Green, C.White, function()
		pcall(function()
			SocialService:PromptGameInvite(player)
		end)
	end)
	sideButton(side, 3, "🛒", "SHOP", C.White, C.Ink, function()
		HUD.OpenShop("Passes")
	end)
	sideButton(side, 4, "👔", "SKINS", C.White, C.Ink, function()
		HUD.OpenSkins()
	end)

	-- LIMITED HALLOWEEN button
	local halloween = UI.new("TextButton", {
		Size = UDim2.fromOffset(120, 120),
		Position = UDim2.new(0, 22, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 120, 20),
		Text = "",
		Parent = lobbyLayer,
	})
	UI.corner(halloween, 14)
	UI.stroke(halloween, 4, Color3.fromRGB(120, 40, 0))
	UI.text(halloween, "🎃", { Size = UDim2.fromScale(1, 0.62), Position = UDim2.fromScale(0, 0.05), FontFace = UI.Bold })
	UI.text(halloween, "HALLOWEEN", { Size = UDim2.fromScale(0.9, 0.2), Position = UDim2.fromScale(0.05, 0.72) })
	local limited = UI.new("Frame", {
		Size = UDim2.fromOffset(90, 28),
		Position = UDim2.fromOffset(-12, -14),
		Rotation = -10,
		BackgroundColor3 = Color3.fromRGB(120, 50, 200),
		Parent = halloween,
	})
	UI.corner(limited, 14)
	UI.text(limited, "LIMITED", { Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1) })
	halloween.MouseButton1Click:Connect(function()
		HUD.OpenSkins(true)
	end)
	task.spawn(function()
		local t = 0
		while halloween.Parent do
			t += RunService.Heartbeat:Wait()
			halloween.Rotation = math.sin(t * 2.4) * 3
		end
	end)

	-- Currencies (bottom left)
	local money = UI.new("Frame", {
		Size = UDim2.fromOffset(210, 130),
		Position = UDim2.new(0, 20, 1, -20),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		Parent = lobbyLayer,
	})
	UI.list(money, 10)
	currencyPill(money, 1, "🍬", "Candy", C.Candy)
	currencyPill(money, 2, "💵", "Cash", C.Cash)

	-- STEP INTO A ZONE TO START A SHIFT
	local hint = UI.new("TextLabel", {
		Size = UDim2.new(0.6, 0, 0, 40),
		Position = UDim2.new(0.5, 0, 1, -70),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		RichText = true,
		Text = 'STEP INTO A <font color="#3CDCFF">ZONE</font> TO START A SHIFT',
		FontFace = UI.Title,
		TextScaled = true,
		TextColor3 = C.White,
		Parent = lobbyLayer,
	})
	UI.outlined(hint, 2)
end

-- ===== Shift HUD =====
local shiftBanner: TextLabel
local objectiveCard: Frame
local objTitle: TextLabel
local objText: TextLabel
local objStep: TextLabel
local statusLabel: TextLabel
local blackoutLabel: TextLabel
local rankLabel: TextLabel
local stressFill: Frame
local stressText: TextLabel

local function buildShift()
	shiftLayer = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = gui })
	-- Top banner "Shift 1"
	local top = UI.new("Frame", {
		Size = UDim2.new(0.5, 0, 0, 66),
		Position = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = C.Black,
		Parent = shiftLayer,
	})
	UI.new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.2, 0),
			NumberSequenceKeypoint.new(0.8, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = top,
	})
	shiftBanner = UI.text(top, "Shift 1", { Size = UDim2.fromScale(0.5, 0.82), Position = UDim2.fromScale(0.25, 0.08) })

	-- NEXT OBJECTIVE card (top right)
	objectiveCard = UI.new("Frame", {
		Size = UDim2.fromOffset(440, 220),
		Position = UDim2.new(1, -16, 0, 84),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = C.Paper,
		Parent = shiftLayer,
	})
	UI.stroke(objectiveCard, 4, C.NavyDark)
	local header = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = C.Navy, Parent = objectiveCard })
	UI.new("UIGradient", { Color = ColorSequence.new(C.Navy, C.NavyDark), Rotation = 90, Parent = header })
	UI.text(header, "🚆", { Size = UDim2.fromOffset(46, 46), Position = UDim2.fromOffset(10, 5), FontFace = UI.Bold })
	UI.text(
		header,
		"NEXT OBJECTIVE",
		{ Size = UDim2.new(1, -80, 0, 44), Position = UDim2.fromOffset(66, 6), TextXAlignment = Enum.TextXAlignment.Left }
	)
	local portrait = UI.new("ViewportFrame", {
		Size = UDim2.fromOffset(150, 150),
		Position = UDim2.fromOffset(12, 64),
		BackgroundColor3 = Color3.fromRGB(150, 196, 240),
		Ambient = Color3.fromRGB(200, 200, 200),
		LightColor = Color3.new(1, 1, 1),
		Parent = objectiveCard,
	})
	UI.stroke(portrait, 3, C.NavyDark)
	UI.new(
		"UIGradient",
		{ Color = ColorSequence.new(Color3.fromRGB(200, 230, 255), Color3.fromRGB(120, 170, 230)), Rotation = 90, Parent = portrait }
	)
	task.spawn(function()
		local folder = ReplicatedStorage:WaitForChild("Portraits", 20)
		local source = folder and folder:WaitForChild("Supervisor", 20)
		if source then
			local model = source:Clone()
			model.Parent = portrait
			local head = model:FindFirstChild("Head") :: BasePart?
			local camera = UI.new("Camera", { FieldOfView = 30, Parent = portrait })
			if head then
				camera.CFrame = CFrame.lookAt((head.CFrame * CFrame.new(0, 0.1, -4.4)).Position, head.Position - Vector3.new(0, 0.2, 0))
			end
			portrait.CurrentCamera = camera
		end
	end)
	objTitle = UI.text(objectiveCard, "Check in the passenger", {
		Size = UDim2.new(1, -186, 0, 38),
		Position = UDim2.fromOffset(176, 64),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = C.Ink,
	})
	objText = UI.text(objectiveCard, "", {
		Size = UDim2.new(1, -186, 0, 70),
		Position = UDim2.fromOffset(176, 104),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextScaled = false,
		TextSize = 21,
		TextWrapped = true,
		FontFace = UI.Hand,
		TextColor3 = Color3.fromRGB(70, 74, 90),
	})
	local stepBox = UI.new(
		"Frame",
		{ Size = UDim2.fromOffset(124, 40), Position = UDim2.new(1, -136, 1, -50), BackgroundColor3 = C.White, Parent = objectiveCard }
	)
	UI.corner(stepBox, 4)
	UI.stroke(stepBox, 3, C.NavyDark)
	objStep =
		UI.text(stepBox, "Step 1/6", { Size = UDim2.fromScale(0.9, 0.85), Position = UDim2.fromScale(0.05, 0.08), TextColor3 = C.Ink })

	-- Status line under the card: strikes and check-ins left
	statusLabel = UI.text(shiftLayer, "", {
		Size = UDim2.fromOffset(440, 30),
		Position = UDim2.new(1, -16, 0, 312),
		AnchorPoint = Vector2.new(1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		RichText = true,
	})
	UI.outlined(statusLabel, 2)

	-- Blackout timer
	blackoutLabel = UI.text(
		shiftLayer,
		"",
		{ Size = UDim2.new(0.5, 0, 0, 44), Position = UDim2.new(0.25, 0, 0, 74), TextColor3 = Color3.fromRGB(255, 70, 60), Visible = false }
	)
	UI.outlined(blackoutLabel, 3)

	-- Rank card (bottom left): portrait, rank, cash, CRASH OUT bar, candy
	local card = UI.new("Frame", {
		Size = UDim2.fromOffset(400, 150),
		Position = UDim2.new(0, 20, 1, -20),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		Parent = shiftLayer,
	})
	local barBack = UI.new(
		"Frame",
		{ Size = UDim2.fromOffset(300, 60), Position = UDim2.fromOffset(96, 46), BackgroundColor3 = C.Black, Parent = card }
	)
	UI.corner(barBack, 6)
	UI.stroke(barBack, 4, Color3.fromRGB(70, 74, 84))
	stressFill = UI.new("Frame", {
		Size = UDim2.new(0.15, -8, 1, -8),
		Position = UDim2.fromOffset(4, 4),
		BackgroundColor3 = Color3.fromRGB(110, 240, 60),
		Parent = barBack,
	})
	UI.corner(stressFill, 4)
	stressText = UI.text(
		barBack,
		"15%",
		{ Size = UDim2.new(0.3, 0, 0.7, 0), Position = UDim2.new(0.66, 0, 0.15, 0), TextXAlignment = Enum.TextXAlignment.Right }
	)
	UI.outlined(stressText, 2)
	local frame = UI.new("Frame", {
		Size = UDim2.fromOffset(120, 120),
		Position = UDim2.fromOffset(0, 16),
		BackgroundColor3 = Color3.fromRGB(70, 74, 84),
		Rotation = 0,
		Parent = card,
	})
	UI.corner(frame, 30)
	UI.stroke(frame, 4, C.Black)
	local headshot = UI.new("ImageLabel", {
		Size = UDim2.new(1, -16, 1, -16),
		Position = UDim2.fromOffset(8, 8),
		BackgroundColor3 = Color3.fromRGB(150, 196, 240),
		Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150",
		Parent = frame,
	})
	UI.corner(headshot, 26)
	rankLabel = UI.text(
		card,
		"Trainee",
		{ Size = UDim2.fromOffset(200, 36), Position = UDim2.fromOffset(130, 6), TextXAlignment = Enum.TextXAlignment.Left }
	)
	UI.outlined(rankLabel, 2)
	local cash = UI.text(card, "$0", {
		Size = UDim2.fromOffset(110, 34),
		Position = UDim2.fromOffset(282, 8),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = C.Cash,
	})
	UI.outlined(cash, 2)
	local crash = UI.text(
		card,
		"CRASH OUT",
		{ Size = UDim2.fromOffset(150, 30), Position = UDim2.fromOffset(134, 112), TextXAlignment = Enum.TextXAlignment.Left }
	)
	UI.outlined(crash, 2)
	local candy = UI.text(card, "🍬 0", {
		Size = UDim2.fromOffset(110, 30),
		Position = UDim2.fromOffset(282, 112),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = C.Candy,
	})
	UI.outlined(candy, 2)
	local function update()
		rankLabel.Text = player:GetAttribute("Rank") or "Trainee"
		cash.Text = "$" .. Format.Abbrev(player:GetAttribute("Cash") or 0)
		candy.Text = "🍬 " .. Format.Abbrev(player:GetAttribute("Candy") or 0)
		local stress = player:GetAttribute("Stress") or 0
		UI.tween(stressFill, 0.4, { Size = UDim2.new(math.max(stress / 100, 0.03), -8, 1, -8) })
		stressFill.BackgroundColor3 = Color3.fromRGB(110, 240, 60):Lerp(Color3.fromRGB(240, 40, 30), stress / 100)
		stressText.Text = math.floor(stress) .. "%"
	end
	for _, attr in { "Rank", "Cash", "Candy", "Stress" } do
		player:GetAttributeChangedSignal(attr):Connect(update)
	end
	update()

	-- Quick buttons (bottom right): rules, radar, hint
	local quick = UI.new("Frame", {
		Size = UDim2.fromOffset(170, 220),
		Position = UDim2.new(1, -16, 1, -20),
		AnchorPoint = Vector2.new(1, 1),
		BackgroundTransparency = 1,
		Parent = shiftLayer,
	})
	UI.new("UIListLayout", {
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Parent = quick,
	})
	UI.button(quick, "📋 RULES", C.Navy, function()
		HUD.OnRules()
	end, { Size = UDim2.fromOffset(170, 50) })
	local radar = UI.button(quick, "📡 RADAR", Color3.fromRGB(110, 50, 190), function()
		local ok, text = Remotes.UseRadar:InvokeServer()
		HUD.Toast(text, if ok then "success" else "warn")
	end, { Size = UDim2.fromOffset(170, 50) })
	HUD.RadarButton = radar
	UI.button(quick, "🔍 HINT", Color3.fromRGB(230, 140, 20), function()
		if (player:GetAttribute("StoredHints") or 0) > 0 then
			local ok, text = Remotes.UseHint:InvokeServer()
			HUD.Toast(text, if ok then "success" else "warn")
		else
			HUD.Buy("Product", "Hint")
		end
	end, { Size = UDim2.fromOffset(170, 50) })
end

function HUD.SetObjective(data)
	if not data then
		return
	end
	objTitle.Text = data.Title
	objText.Text = data.Text
	objStep.Text = "Step " .. data.Step .. "/" .. data.Steps
	local scale = objectiveCard:FindFirstChildOfClass("UIScale") or UI.new("UIScale", { Parent = objectiveCard })
	scale.Scale = 1.06
	UI.tween(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
end

function HUD.State()
	return state
end

function HUD.SetShiftState(data)
	state.InShift = data ~= nil
	lobbyLayer.Visible = not state.InShift
	shiftLayer.Visible = state.InShift
	if not data then
		blackoutLabel.Visible = false
		return
	end
	state.Shift = data
	shiftBanner.Text = "Shift " .. data.Shift
	local strikes = string.rep("✖ ", data.Strikes) .. string.rep("○ ", math.max(data.MaxStrikes - data.Strikes, 0))
	statusLabel.Text = '<font color="#FF6A5A">' .. strikes .. "</font>  ·  " .. string.format("%02d", data.Remaining) .. " CHECK-INS LEFT"
	HUD.RadarButton.Visible = player:GetAttribute("Pass_AnomalyRadar") == true
	HUD.RadarButton.Text = "📡 RADAR (" .. (data.RadarLeft or 0) .. ")"
end

function HUD.SetBlackout(data)
	if not data or not data.Active then
		blackoutLabel.Visible = false
		HUD.BlackoutDeadline = nil
		if data and data.Won ~= nil then
			HUD.Announce(if data.Won then "POWER RESTORED" else "THE STATION IS LOST", if data.Won then "#7CFF6A" else "#FF3B30")
		end
		return
	end
	if data.Count then
		HUD.Announce("⚠ POWER FAILURE", "#FF3B30")
	end
	HUD.BlackoutDeadline = data.Deadline
	HUD.Breakers = data.Breakers .. "/" .. data.Total
	blackoutLabel.Visible = true
end

-- ===== Verdict stamp =====
function HUD.Verdict(data)
	local stampFrame = UI.new("Frame", {
		Size = UDim2.fromOffset(420, 120),
		Position = UDim2.fromScale(0.5, 0.42),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = -8,
		BackgroundTransparency = 1,
		Parent = gui,
	})
	local color = if data.Approved then C.Green else C.Red
	UI.stroke(stampFrame, 8, color)
	UI.corner(stampFrame, 10)
	local word = UI.text(
		stampFrame,
		if data.Approved then "APPROVED" else "DENIED",
		{ TextColor3 = color, FontFace = UI.Bold, Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1) }
	)
	local scale = UI.new("UIScale", { Scale = 2.2, Parent = stampFrame })
	UI.tween(scale, 0.18, { Scale = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	HUD.Toast(data.Text, if data.Correct then "success" else "warn")
	if not data.Correct then
		local flash =
			UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Red, BackgroundTransparency = 0.6, Parent = gui })
		UI.tween(flash, 0.8, { BackgroundTransparency = 1 })
		task.delay(0.9, function()
			flash:Destroy()
		end)
	end
	task.delay(1.4, function()
		UI.tween(word, 0.4, { TextTransparency = 1 })
		local s = stampFrame:FindFirstChildOfClass("UIStroke")
		if s then
			UI.tween(s, 0.4, { Transparency = 1 })
		end
		task.wait(0.45)
		stampFrame:Destroy()
	end)
end

-- ===== Results =====
function HUD.Results(data)
	closeMenu()
	local title = if data.Survived
		then "SHIFT " .. data.Shift .. " COMPLETE"
		elseif data.Why == "fired" then "YOU'RE FIRED"
		else "THE STATION IS LOST"
	local frame, body = UI.modal(
		menuLayer,
		"FROSTLINE CENTRAL · SHIFT REPORT",
		title,
		if data.Survived then "✅" else "💀",
		UDim2.fromOffset(620, 560),
		closeMenu
	)
	openMenu = frame
	UI.list(body, 8, false, Enum.HorizontalAlignment.Center)
	local summary = (if data.Perfect then "⭐ PERFECT SHIFT ⭐\n" else "") .. "Correct: " .. data.Correct .. "   Mistakes: " .. data.Wrong
	UI.text(body, summary, { Size = UDim2.new(1, 0, 0, if data.Perfect then 70 else 36), TextColor3 = C.Ink, LayoutOrder = 1 })
	UI.text(
		body,
		"+$" .. data.Cash .. "    +" .. data.Candy .. " 🍬",
		{ Size = UDim2.new(1, 0, 0, 44), TextColor3 = C.GreenDark, LayoutOrder = 2 }
	)
	if data.Escaped > 0 then
		UI.text(
			body,
			data.Escaped .. " of them boarded the train...",
			{ Size = UDim2.new(1, 0, 0, 30), TextColor3 = C.Red, LayoutOrder = 3 }
		)
	end
	local list = UI.new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, 240),
		BackgroundColor3 = C.PaperDark,
		ScrollBarThickness = 8,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		LayoutOrder = 4,
		Parent = body,
	})
	UI.corner(list, 8)
	UI.pad(list, 8)
	UI.list(list, 4)
	for i, entry in data.Log do
		local mark = if entry.Correct then "✅" else "❌"
		local action = if entry.Approved then "approved" else "denied"
		local extra = if entry.Anomaly
			then " — it was NOT human (" .. entry.Anomaly .. ")"
			elseif not entry.Correct then " — " .. entry.Reason
			else ""
		UI.text(list, mark .. " " .. entry.Name .. " " .. action .. extra, {
			Size = UDim2.new(1, 0, 0, 26),
			TextScaled = false,
			TextSize = 20,
			FontFace = UI.Hand,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = if entry.Correct then C.Ink else C.Red,
			LayoutOrder = i,
		})
	end
	UI.button(
		body,
		if data.Survived then "NEXT: SHIFT " .. data.NextShift .. " →" else "TRY AGAIN →",
		C.Green,
		closeMenu,
		{ Size = UDim2.fromOffset(320, 60), LayoutOrder = 5 }
	)
end

-- ===== Menus =====
function HUD.OpenParty(padIndex: number)
	closeMenu()
	local size, friendsOnly = 1, false
	local frame, body = UI.modal(menuLayer, "FROSTLINE CENTRAL", "CREATE PARTY", "🚆", UDim2.fromOffset(820, 520), closeMenu)
	openMenu = frame
	UI.text(body, "PARTY SIZE", { Size = UDim2.new(1, 0, 0, 74), TextColor3 = C.Ink })
	UI.text(
		body,
		"Maximum players, including you",
		{ Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, 74), TextColor3 = C.Navy }
	)
	local row =
		UI.new("Frame", { Size = UDim2.new(1, 0, 0, 130), Position = UDim2.fromOffset(0, 124), BackgroundTransparency = 1, Parent = body })
	UI.list(row, 22, true, Enum.HorizontalAlignment.Center)
	local buttons = {}
	local function paint()
		for i, b in buttons do
			b.BackgroundColor3 = if i == size then C.NavyDark else Color3.fromRGB(220, 232, 252)
			b.TextColor3 = if i == size then C.White else Color3.fromRGB(30, 60, 200)
		end
	end
	for i = 1, Config.Party.MaxSize do
		local b = UI.new(
			"TextButton",
			{ Size = UDim2.fromOffset(126, 126), Text = tostring(i), FontFace = UI.Title, TextScaled = true, LayoutOrder = i, Parent = row }
		)
		UI.corner(b, 6)
		UI.stroke(b, 3, C.NavyDark)
		UI.pad(b, 14)
		b.MouseButton1Click:Connect(function()
			size = i
			paint()
		end)
		buttons[i] = b
	end
	paint()
	UI.new("Frame", { Size = UDim2.new(1, -20, 0, 3), Position = UDim2.fromOffset(10, 272), BackgroundColor3 = C.NavyDark, Parent = body })
	local friends
	friends = UI.button(body, "👥 FRIENDS ONLY", Color3.fromRGB(200, 204, 214), function()
		friendsOnly = not friendsOnly
		friends.BackgroundColor3 = if friendsOnly then C.Navy else Color3.fromRGB(200, 204, 214)
		friends.TextColor3 = if friendsOnly then C.White else C.Ink
	end, { Size = UDim2.fromOffset(320, 78), Position = UDim2.new(0.5, -340, 0, 296), TextColor3 = C.Ink })
	UI.button(body, "CREATE PARTY →", C.Green, function()
		local ok, msg = Remotes.CreateParty:InvokeServer(padIndex, size, friendsOnly)
		HUD.Toast(msg, if ok then "success" else "warn")
		if ok then
			closeMenu()
		end
	end, { Size = UDim2.fromOffset(320, 78), Position = UDim2.new(0.5, 20, 0, 296) })
end

function HUD.Buy(kind: string, key: string)
	local info = if kind == "Pass" then Config.GamePasses[key] else Config.Products[key]
	if not info or info.Id == 0 then
		HUD.Toast("This item isn't set up yet (add its ID in Config).", "warn")
		return
	end
	if kind == "Pass" then
		MarketplaceService:PromptGamePassPurchase(player, info.Id)
	else
		MarketplaceService:PromptProductPurchase(player, info.Id)
	end
end

local function shopCard(parent: Instance, order: number, info, owned: boolean, onBuy: () -> ())
	local card = UI.new("Frame", { Size = UDim2.new(1, -12, 0, 92), BackgroundColor3 = C.White, LayoutOrder = order, Parent = parent })
	UI.corner(card, 10)
	UI.stroke(card, 3, C.NavyDark)
	UI.text(card, info.Name, {
		Size = UDim2.new(0.62, 0, 0, 40),
		Position = UDim2.fromOffset(14, 6),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = C.Ink,
	})
	UI.text(card, info.Description, {
		Size = UDim2.new(0.62, 0, 0, 36),
		Position = UDim2.fromOffset(14, 48),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(80, 86, 100),
		FontFace = UI.Hand,
	})
	UI.button(
		card,
		if owned then "OWNED" else " " .. info.Price .. " R$",
		if owned then Color3.fromRGB(150, 150, 160) else C.Green,
		function()
			if not owned then
				onBuy()
			end
		end,
		{ Size = UDim2.fromOffset(170, 62), Position = UDim2.new(1, -184, 0, 15) }
	)
end

function HUD.OpenShop(tab: string?)
	closeMenu()
	local frame, body = UI.modal(menuLayer, "FROSTLINE CENTRAL", "STATION SHOP", "🛒", UDim2.fromOffset(760, 600), closeMenu)
	openMenu = frame
	local tabs = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 54), BackgroundTransparency = 1, Parent = body })
	UI.list(tabs, 10, true)
	local list = UI.new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -66),
		Position = UDim2.fromOffset(0, 66),
		BackgroundTransparency = 1,
		ScrollBarThickness = 8,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = body,
	})
	UI.list(list, 10)
	local function show(name)
		for _, child in list:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		if name == "Passes" then
			for i, key in Config.PassOrder do
				shopCard(list, i, Config.GamePasses[key], player:GetAttribute("Pass_" .. key) == true, function()
					HUD.Buy("Pass", key)
				end)
			end
		else
			local keys = if name == "Currency"
				then { "CandySmall", "CandyLarge", "CashSmall", "CashLarge" }
				else { "Hint", "Revive", "PowerSurge" }
			for i, key in keys do
				shopCard(list, i, Config.Products[key], false, function()
					HUD.Buy("Product", key)
				end)
			end
		end
	end
	for i, entry in { { "Passes", "⭐ PASSES" }, { "Items", "⚡ ITEMS" }, { "Currency", "🍬 CANDY & CASH" } } do
		UI.button(tabs, entry[2], C.Navy, function()
			show(entry[1])
		end, { Size = UDim2.fromOffset(220, 50), LayoutOrder = i })
	end
	show(tab or "Passes")
end

function HUD.OpenSkins(halloweenFirst: boolean?)
	closeMenu()
	local frame, body = UI.modal(menuLayer, "FROSTLINE CENTRAL", "SKINS", "👔", UDim2.fromOffset(820, 620), closeMenu)
	openMenu = frame
	local grid = UI.new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScrollBarThickness = 8,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = body,
	})
	UI.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(240, 230),
		CellPadding = UDim2.fromOffset(12, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})
	local function render()
		for _, child in grid:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
		for i, skin in Config.Skins do
			local owned = player:GetAttribute("OwnedSkin_" .. skin.Key) == true
			local equipped = player:GetAttribute("Skin") == skin.Key
			local card = UI.new(
				"Frame",
				{ BackgroundColor3 = C.White, LayoutOrder = if halloweenFirst and skin.Halloween then i - 100 else i, Parent = grid }
			)
			UI.corner(card, 10)
			UI.stroke(card, 3, if skin.Halloween then Color3.fromRGB(230, 110, 10) else C.NavyDark)
			local swatch = UI.new(
				"Frame",
				{ Size = UDim2.new(1, -20, 0, 100), Position = UDim2.fromOffset(10, 10), BackgroundColor3 = skin.Coat, Parent = card }
			)
			UI.corner(swatch, 8)
			UI.new("Frame", {
				Size = UDim2.new(0, 14, 1, 0),
				Position = UDim2.new(0.5, -7, 0, 0),
				BackgroundColor3 = skin.Trim,
				BorderSizePixel = 0,
				Parent = swatch,
			})
			if skin.Halloween then
				UI.text(swatch, "🎃", { Size = UDim2.fromOffset(40, 40), Position = UDim2.new(1, -44, 0, 4), FontFace = UI.Bold })
			end
			UI.text(card, skin.Name, { Size = UDim2.new(1, -16, 0, 34), Position = UDim2.fromOffset(8, 114), TextColor3 = C.Ink })
			local label = if equipped
				then "EQUIPPED"
				elseif owned then "EQUIP"
				else (if skin.Currency == "Candy" then "🍬 " else "$") .. Format.Abbrev(skin.Price)
			local color = if equipped then Color3.fromRGB(150, 150, 160) elseif owned then C.Navy else C.Green
			UI.button(card, label, color, function()
				if equipped then
					return
				end
				local ok, msg
				if owned then
					ok, msg = Remotes.EquipSkin:InvokeServer(skin.Key)
				else
					ok, msg = Remotes.BuySkin:InvokeServer(skin.Key)
				end
				HUD.Toast(msg, if ok then "success" else "warn")
				if not ok and not owned then
					HUD.OpenShop("Currency")
					return
				end
				render()
			end, { Size = UDim2.new(1, -20, 0, 60), Position = UDim2.fromOffset(10, 156) })
		end
	end
	render()
end

function HUD.OpenRewards()
	closeMenu()
	local frame, body = UI.modal(menuLayer, "FROSTLINE CENTRAL", "DAILY REWARDS", "🎁", UDim2.fromOffset(860, 420), closeMenu)
	openMenu = frame
	local row = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 170), BackgroundTransparency = 1, Parent = body })
	UI.list(row, 8, true, Enum.HorizontalAlignment.Center)
	local streak = player:GetAttribute("DailyStreak") or 0
	local ready = player:GetAttribute("DailyReady") == true
	local nextDay = (if ready then streak else streak - 1) % #Config.DailyRewards + 1
	for day, reward in Config.DailyRewards do
		local isNext = day == nextDay
		local card = UI.new(
			"Frame",
			{ Size = UDim2.fromOffset(104, 160), BackgroundColor3 = if isNext then C.Yellow else C.White, LayoutOrder = day, Parent = row }
		)
		UI.corner(card, 10)
		UI.stroke(card, 3, C.NavyDark)
		UI.text(card, "DAY " .. day, { Size = UDim2.new(1, -10, 0, 30), Position = UDim2.fromOffset(5, 6), TextColor3 = C.Ink })
		UI.text(
			card,
			if reward.Candy and not reward.Cash then "🍬" elseif reward.Cash and reward.Candy then "🎁" else "💵",
			{ Size = UDim2.new(1, 0, 0, 56), Position = UDim2.fromOffset(0, 40), FontFace = UI.Bold }
		)
		local text = {}
		if reward.Cash then
			table.insert(text, "$" .. reward.Cash)
		end
		if reward.Candy then
			table.insert(text, reward.Candy .. " 🍬")
		end
		UI.text(
			card,
			table.concat(text, "\n"),
			{ Size = UDim2.new(1, -10, 0, 50), Position = UDim2.fromOffset(5, 100), TextColor3 = C.Ink }
		)
	end
	UI.button(
		body,
		if ready then "CLAIM DAY " .. nextDay .. "!" else "COME BACK TOMORROW",
		if ready then C.Green else Color3.fromRGB(150, 150, 160),
		function()
			if not ready then
				return
			end
			local ok, msg = Remotes.ClaimDaily:InvokeServer()
			HUD.Toast(msg, if ok then "success" else "warn")
			closeMenu()
		end,
		{ Size = UDim2.fromOffset(360, 66), Position = UDim2.new(0.5, -180, 0, 196) }
	)
	if player:GetAttribute("Pass_VIP") then
		UI.text(
			body,
			"👑 VIP: rewards doubled",
			{ Size = UDim2.new(1, 0, 0, 28), Position = UDim2.fromOffset(0, 270), TextColor3 = Color3.fromRGB(200, 150, 20) }
		)
	end
end

function HUD.Init()
	gui = UI.new("ScreenGui", {
		Name = "FrostlineHUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})
	HUD.Gui = gui
	buildLobby()
	buildShift()
	menuLayer = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5, Parent = gui })
	toastHolder =
		UI.new("Frame", { Size = UDim2.new(1, 0, 0, 200), Position = UDim2.fromScale(0, 0.3), BackgroundTransparency = 1, Parent = gui })
	UI.list(toastHolder, 6, false, Enum.HorizontalAlignment.Center)
	bannerLabel = UI.text(gui, "", { Size = UDim2.new(0.7, 0, 0, 110), Position = UDim2.new(0.15, 0, 0.16, 0), TextTransparency = 1 })
	UI.outlined(bannerLabel, 4)
	-- Scale the layers down on small screens (phones)
	for _, layer in { lobbyLayer, shiftLayer, menuLayer } do
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
	end

	Remotes.Notify.OnClientEvent:Connect(HUD.Toast)
	Remotes.Announce.OnClientEvent:Connect(HUD.Announce)
	Remotes.Objective.OnClientEvent:Connect(HUD.SetObjective)
	Remotes.ShiftState.OnClientEvent:Connect(HUD.SetShiftState)
	Remotes.Verdict.OnClientEvent:Connect(HUD.Verdict)
	Remotes.Results.OnClientEvent:Connect(HUD.Results)
	Remotes.Blackout.OnClientEvent:Connect(HUD.SetBlackout)
	Remotes.PartyPrompt.OnClientEvent:Connect(HUD.OpenParty)
	Remotes.OpenMenu.OnClientEvent:Connect(function(name, arg)
		if name == "Shop" then
			HUD.OpenShop()
		elseif name == "Skins" then
			HUD.OpenSkins(arg ~= nil and arg ~= "Standard")
		elseif name == "Rewards" then
			HUD.OpenRewards()
		end
	end)
	RunService.Heartbeat:Connect(function()
		if HUD.BlackoutDeadline then
			local left = math.max(0, math.floor(HUD.BlackoutDeadline - workspace:GetServerTimeNow()))
			blackoutLabel.Text = "⚡ RESTORE POWER  " .. (HUD.Breakers or "") .. "   ·   " .. Format.Time(left)
		end
	end)
	HUD.SetShiftState(nil)
end

HUD.OnRules = function() end

return HUD
