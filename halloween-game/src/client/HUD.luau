-- All on-screen UI, built from code: night timer, bonfire, battery, stamina, shop, haunt menu,
-- downed screen, jumpscares, danger vignette and monster radar.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local player = Players.LocalPlayer

local HUD = {}

local SCARY = Enum.Font.Creepster
local FONT = Enum.Font.FredokaOne
local COLORS = {
	panel = Color3.fromRGB(20, 14, 24),
	panelLight = Color3.fromRGB(38, 28, 44),
	pumpkin = Color3.fromRGB(255, 130, 30),
	blood = Color3.fromRGB(200, 30, 40),
	green = Color3.fromRGB(70, 200, 100),
	purple = Color3.fromRGB(150, 90, 230),
	bone = Color3.fromRGB(240, 230, 210),
	dim = Color3.fromRGB(170, 160, 170),
}
local TOAST_COLORS = { success = Color3.fromRGB(40, 140, 70), error = COLORS.blood, info = Color3.fromRGB(80, 60, 120) }

local function new(className: string, props, children)
	local inst = Instance.new(className)
	for key, value in props or {} do
		if key ~= "Parent" then
			inst[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function corner(radius: number?)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 10) })
end

local function outline()
	return new("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0), Transparency = 0.1 })
end

local function border(color: Color3)
	return new("UIStroke", { Thickness = 2, Color = color, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function text(props)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = props.Font or FONT
	props.TextColor3 = props.TextColor3 or COLORS.bone
	props.TextScaled = if props.TextScaled == nil then true else props.TextScaled
	return new("TextLabel", props, { outline() })
end

local function button(props, color: Color3)
	props.BackgroundColor3 = color
	props.Font = props.Font or FONT
	props.TextColor3 = COLORS.bone
	props.TextScaled = true
	props.AutoButtonColor = true
	return new("TextButton", props, {
		corner(8),
		outline(),
		new(
			"UIPadding",
			{ PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }
		),
		border(color:Lerp(Color3.new(0, 0, 0), 0.4)),
	})
end

local function bar(parent, position: UDim2, size: UDim2, color: Color3, label: string)
	local frame = new(
		"Frame",
		{ Position = position, Size = size, BackgroundColor3 = Color3.fromRGB(15, 10, 15), BackgroundTransparency = 0.2, Parent = parent },
		{ corner(6), border(Color3.fromRGB(60, 50, 60)) }
	)
	local fill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, Parent = frame }, { corner(6) })
	local caption = text({ Size = UDim2.new(1, -10, 1, -4), Position = UDim2.fromOffset(5, 2), Text = label, ZIndex = 2, Parent = frame })
	return function(fraction: number, newLabel: string?)
		fill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
		if newLabel then
			caption.Text = newLabel
		end
	end
end

local function now()
	return workspace:GetServerTimeNow()
end

function HUD.Start(Controls)
	local gui = new("ScreenGui", {
		Name = "HollowHUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})

	-- Danger vignette (red edges when The Hollow is close)
	local vignette = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = gui })
	local edges = {}
	for _, spec in
		{
			{ UDim2.fromScale(1, 0.25), UDim2.fromScale(0, 0), 90 },
			{ UDim2.fromScale(1, 0.25), UDim2.fromScale(0, 0.75), -90 },
			{ UDim2.fromScale(0.2, 1), UDim2.fromScale(0, 0), 0 },
			{ UDim2.fromScale(0.2, 1), UDim2.fromScale(0.8, 0), 180 },
		}
	do
		local edge = new(
			"Frame",
			{
				Size = spec[1],
				Position = spec[2],
				BackgroundColor3 = COLORS.blood,
				BorderSizePixel = 0,
				BackgroundTransparency = 1,
				Parent = vignette,
			},
			{
				new("UIGradient", { Rotation = spec[3], Transparency = NumberSequence.new(0, 1) }),
			}
		)
		table.insert(edges, edge)
	end

	-- Top: phase, timer, bonfire
	local top = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 44),
		Size = UDim2.fromOffset(300, 108),
		BackgroundColor3 = COLORS.panel,
		BackgroundTransparency = 0.25,
		Parent = gui,
	}, { corner(12), border(COLORS.pumpkin) })
	local phaseLabel = text({
		Size = UDim2.new(1, -16, 0, 40),
		Position = UDim2.fromOffset(8, 4),
		Font = SCARY,
		Text = "SURVIVE THE HOLLOW",
		TextColor3 = COLORS.pumpkin,
		Parent = top,
	})
	local timerLabel = text({ Size = UDim2.new(1, -16, 0, 24), Position = UDim2.fromOffset(8, 44), Text = "", Parent = top })
	local setBonfire = bar(top, UDim2.fromOffset(12, 74), UDim2.new(1, -24, 0, 24), COLORS.pumpkin, "🔥 Bonfire")

	local radarLabel = text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 158),
		Size = UDim2.fromOffset(200, 26),
		Text = "",
		TextColor3 = Color3.fromRGB(255, 120, 120),
		Parent = gui,
	})

	-- Candy
	local candyLabel = text({
		Position = UDim2.fromOffset(16, 52),
		Size = UDim2.fromOffset(200, 34),
		Text = "🍬 0",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = COLORS.pumpkin,
		Parent = gui,
	})

	-- Bottom-left: battery & stamina
	local meters = new(
		"Frame",
		{
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 16, 1, -20),
			Size = UDim2.fromOffset(240, 64),
			BackgroundTransparency = 1,
			Parent = gui,
		}
	)
	local setBattery = bar(meters, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 28), Color3.fromRGB(240, 220, 120), "🔦 Lantern (F)")
	local setStamina = bar(meters, UDim2.fromOffset(0, 34), UDim2.new(1, 0, 0, 28), Color3.fromRGB(90, 170, 255), "👟 Stamina (Shift)")

	-- Announcements & toasts
	local announceLabel = text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 190),
		Size = UDim2.new(0.85, 0, 0, 36),
		Font = SCARY,
		Text = "",
		TextTransparency = 1,
		Parent = gui,
	})
	local announceStroke = announceLabel:FindFirstChildOfClass("UIStroke")
	local announceToken = 0
	local function announce(message: string, colorHex: string?)
		announceToken += 1
		local token = announceToken
		announceLabel.Text = message
		announceLabel.TextColor3 = if colorHex then Color3.fromHex(colorHex) else COLORS.bone
		announceLabel.TextTransparency = 0
		announceStroke.Transparency = 0.1
		task.delay(5, function()
			if token == announceToken then
				TweenService:Create(announceLabel, TweenInfo.new(1), { TextTransparency = 1 }):Play()
				TweenService:Create(announceStroke, TweenInfo.new(1), { Transparency = 1 }):Play()
			end
		end)
	end

	local toastHolder = new(
		"Frame",
		{
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -100),
			Size = UDim2.fromOffset(420, 200),
			BackgroundTransparency = 1,
			Parent = gui,
		},
		{
			new(
				"UIListLayout",
				{
					VerticalAlignment = Enum.VerticalAlignment.Bottom,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0, 6),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}
			),
		}
	)
	local toastCount = 0
	local function toast(message: string, kind: string?)
		toastCount += 1
		local frame = new(
			"Frame",
			{
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundColor3 = TOAST_COLORS[kind or "info"] or TOAST_COLORS.info,
				LayoutOrder = toastCount,
				Parent = toastHolder,
			},
			{ corner(8) }
		)
		text({ Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4), Text = message, Parent = frame })
		task.delay(3.5, function()
			TweenService:Create(frame, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
			task.wait(0.4)
			frame:Destroy()
		end)
		local extra = #toastHolder:GetChildren() - 5
		if extra > 0 then
			for _, child in toastHolder:GetChildren() do
				if child:IsA("Frame") and extra > 0 then
					child:Destroy()
					extra -= 1
				end
			end
		end
	end
	Remotes.Notify.OnClientEvent:Connect(toast)
	Remotes.Announce.OnClientEvent:Connect(announce)

	-- Jumpscare
	local scare =
		new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Visible = false, ZIndex = 50, Parent = gui })
	local face = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.7, 0.7),
		BackgroundColor3 = Color3.fromRGB(230, 100, 10),
		ZIndex = 51,
		Parent = scare,
	}, { new("UIAspectRatioConstraint", {}), new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
	for _, x in { 0.3, 0.7 } do
		new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, 0.38),
			Size = UDim2.fromScale(0.28, 0.28),
			BackgroundTransparency = 1,
			Text = "▲",
			TextScaled = true,
			Font = Enum.Font.GothamBlack,
			TextColor3 = Color3.fromRGB(255, 240, 80),
			ZIndex = 52,
			Parent = face,
		})
	end
	new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.7),
		Size = UDim2.fromScale(0.7, 0.25),
		BackgroundTransparency = 1,
		Text = "VVVVVV",
		TextScaled = true,
		Font = Enum.Font.GothamBlack,
		TextColor3 = Color3.fromRGB(255, 240, 80),
		ZIndex = 52,
		Parent = face,
	})
	local function jumpscare()
		scare.Visible = true
		face.Size = UDim2.fromScale(0.4, 0.4)
		TweenService:Create(face, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Size = UDim2.fromScale(0.95, 0.95) }):Play()
		local camera = workspace.CurrentCamera
		local started = os.clock()
		local connection
		connection = RunService.RenderStepped:Connect(function()
			local elapsed = os.clock() - started
			if elapsed > 0.8 then
				connection:Disconnect()
				scare.Visible = false
				return
			end
			scare.BackgroundColor3 = if math.floor(elapsed * 20) % 2 == 0 then Color3.new(0, 0, 0) else COLORS.blood
			if camera then
				camera.CFrame *= CFrame.Angles(math.rad(math.random(-3, 3)), math.rad(math.random(-3, 3)), 0)
			end
		end)
	end
	Remotes.Jumpscare.OnClientEvent:Connect(jumpscare)

	-- Panels
	local panels = {}
	local function makePanel(name: string, title: string, size: Vector2)
		local panel = new("Frame", {
			Name = name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.55),
			Size = UDim2.fromOffset(size.X, size.Y),
			BackgroundColor3 = COLORS.panel,
			Visible = false,
			ZIndex = 10,
			Parent = gui,
		}, { corner(14), border(COLORS.pumpkin) })
		text({
			Size = UDim2.new(1, -80, 0, 38),
			Position = UDim2.fromOffset(16, 8),
			Font = SCARY,
			Text = title,
			TextColor3 = COLORS.pumpkin,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = panel,
		})
		local close =
			button({ Size = UDim2.fromOffset(36, 36), Position = UDim2.new(1, -46, 0, 8), Text = "X", Parent = panel }, COLORS.blood)
		close.Activated:Connect(function()
			panel.Visible = false
		end)
		local scroll = new("ScrollingFrame", {
			Position = UDim2.fromOffset(12, 54),
			Size = UDim2.new(1, -24, 1, -66),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 6,
			Parent = panel,
		}, { new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
		panels[name] = panel
		return panel, scroll
	end
	local function togglePanel(name: string)
		for key, panel in panels do
			panel.Visible = key == name and not panel.Visible
		end
	end

	local function row(scroll, order: number, title: string, description: string)
		local frame = new(
			"Frame",
			{ Size = UDim2.new(1, -10, 0, 66), BackgroundColor3 = COLORS.panelLight, LayoutOrder = order, Parent = scroll },
			{ corner(8) }
		)
		text({
			Size = UDim2.new(1, -140, 0, 26),
			Position = UDim2.fromOffset(10, 6),
			Text = title,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = frame,
		})
		local desc = text({
			Size = UDim2.new(1, -140, 0, 28),
			Position = UDim2.fromOffset(10, 32),
			Text = description,
			TextColor3 = COLORS.dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Parent = frame,
		})
		local buy = button(
			{
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(110, 42),
				Text = "",
				Parent = frame,
			},
			COLORS.green
		)
		return buy, desc
	end
	local function header(scroll, order: number, title: string)
		text({
			Size = UDim2.new(1, -10, 0, 26),
			Text = title,
			TextColor3 = COLORS.pumpkin,
			LayoutOrder = order,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = scroll,
		})
	end

	local function promptPurchase(item, isPass: boolean)
		if item.Id == 0 then
			toast("This item isn't set up yet (Id = 0 in Config).", "error")
			return
		end
		if isPass then
			MarketplaceService:PromptGamePassPurchase(player, item.Id)
		else
			MarketplaceService:PromptProductPurchase(player, item.Id)
		end
	end

	-- Shop
	local _, shopScroll = makePanel("Shop", "SHOP", Vector2.new(480, 460))
	local order = 0
	order += 1
	header(shopScroll, order, "🍬 UPGRADES (candy)")
	for _, key in Config.UpgradeOrder do
		local upgrade = Config.Upgrades[key]
		order += 1
		local buy, desc = row(shopScroll, order, upgrade.Name, upgrade.Description)
		buy.BackgroundColor3 = COLORS.pumpkin
		local function refresh()
			local level = player:GetAttribute("Up_" .. key) or 0
			local cost = upgrade.Costs[level + 1]
			desc.Text = upgrade.Description .. "  (Lv " .. level .. "/" .. #upgrade.Costs .. ")"
			buy.Text = if cost then "🍬 " .. Format.Abbrev(cost) else "MAX"
		end
		player:GetAttributeChangedSignal("Up_" .. key):Connect(refresh)
		refresh()
		buy.Activated:Connect(function()
			local ok, success, message = pcall(Remotes.BuyUpgrade.InvokeServer, Remotes.BuyUpgrade, key)
			if ok then
				toast(message, if success then "success" else "error")
			end
		end)
	end
	order += 1
	header(shopScroll, order, "⭐ GAME PASSES (forever)")
	for _, key in Config.PassOrder do
		local pass = Config.GamePasses[key]
		order += 1
		local buy = row(shopScroll, order, pass.Name, pass.Description)
		local function refresh()
			if player:GetAttribute("Pass_" .. key) then
				buy.Text = "OWNED"
				buy.BackgroundColor3 = Color3.fromRGB(70, 65, 75)
			else
				buy.Text = "R$ " .. pass.Price
			end
		end
		player:GetAttributeChangedSignal("Pass_" .. key):Connect(refresh)
		refresh()
		buy.Activated:Connect(function()
			if not player:GetAttribute("Pass_" .. key) then
				promptPurchase(pass, true)
			end
		end)
	end
	order += 1
	header(shopScroll, order, "⚡ BOOSTS")
	for _, key in Config.ProductOrder do
		if key ~= "HauntPlayer" then
			local product = Config.Products[key]
			order += 1
			local buy = row(shopScroll, order, product.Name, product.Description)
			buy.Text = "R$ " .. product.Price
			buy.Activated:Connect(function()
				promptPurchase(product, false)
			end)
		end
	end

	-- Haunt menu
	local hauntPanel, hauntScroll = makePanel("Haunt", "HAUNT A PLAYER", Vector2.new(400, 400))
	local function refreshHaunt()
		for _, child in hauntScroll:GetChildren() do
			if child:IsA("Frame") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		header(
			hauntScroll,
			0,
			"Pick who The Hollow chases for " .. Config.HauntDuration .. "s (R$ " .. Config.Products.HauntPlayer.Price .. ")"
		)
		local count = 0
		for _, other in Players:GetPlayers() do
			if other ~= player then
				count += 1
				local buy = row(hauntScroll, count, "👻 " .. other.DisplayName, "@" .. other.Name)
				buy.Text = "HAUNT"
				buy.BackgroundColor3 = COLORS.purple
				buy.Activated:Connect(function()
					Remotes.SetHauntTarget:FireServer(other.UserId)
					promptPurchase(Config.Products.HauntPlayer, false)
				end)
			end
		end
		if count == 0 then
			text({
				Size = UDim2.new(1, -10, 0, 40),
				Text = "Nobody else is here yet. Invite a friend!",
				LayoutOrder = 1,
				Parent = hauntScroll,
			})
		end
	end

	-- Side buttons
	local side = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(140, 180),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local shopButton = button({ Size = UDim2.fromOffset(140, 50), Text = "🛒 SHOP", LayoutOrder = 1, Parent = side }, COLORS.pumpkin)
	local hauntButton = button({ Size = UDim2.fromOffset(140, 50), Text = "👻 HAUNT", LayoutOrder = 2, Parent = side }, COLORS.purple)
	local lanternButton =
		button({ Size = UDim2.fromOffset(140, 50), Text = "🔦 LANTERN", LayoutOrder = 3, Parent = side }, Color3.fromRGB(150, 130, 60))
	shopButton.Activated:Connect(function()
		togglePanel("Shop")
	end)
	hauntButton.Activated:Connect(function()
		refreshHaunt()
		togglePanel("Haunt")
	end)
	lanternButton.Activated:Connect(Controls.ToggleLantern)

	-- Downed / dead screen
	local downed = new(
		"Frame",
		{
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(80, 0, 0),
			BackgroundTransparency = 0.55,
			Visible = false,
			ZIndex = 20,
			Parent = gui,
		}
	)
	local downedTitle = text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.22),
		Size = UDim2.fromOffset(600, 70),
		Font = SCARY,
		Text = "YOU'RE DOWN",
		TextColor3 = Color3.fromRGB(255, 80, 80),
		ZIndex = 21,
		Parent = downed,
	})
	local downedSub = text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.22, 74),
		Size = UDim2.fromOffset(600, 30),
		Text = "",
		ZIndex = 21,
		Parent = downed,
	})
	local reviveRow = new(
		"Frame",
		{
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0.22, 120),
			Size = UDim2.fromOffset(620, 54),
			BackgroundTransparency = 1,
			ZIndex = 21,
			Parent = downed,
		},
		{
			new(
				"UIListLayout",
				{
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0, 10),
				}
			),
		}
	)
	local secondWindButton = button(
		{ Size = UDim2.fromOffset(190, 52), Text = "💖 SECOND WIND", ZIndex = 22, Parent = reviveRow },
		Color3.fromRGB(200, 60, 120)
	)
	local tokenButton =
		button({ Size = UDim2.fromOffset(190, 52), Text = "💖 USE TOKEN", ZIndex = 22, Parent = reviveRow }, Color3.fromRGB(200, 60, 120))
	local buyReviveButton = button(
		{ Size = UDim2.fromOffset(190, 52), Text = "💖 REVIVE  R$ " .. Config.Products.SelfRevive.Price, ZIndex = 22, Parent = reviveRow },
		COLORS.green
	)
	local function useRevive(kind: string)
		local ok, success, message = pcall(Remotes.UseRevive.InvokeServer, Remotes.UseRevive, kind)
		if ok then
			toast(message, if success then "success" else "error")
		end
	end
	secondWindButton.Activated:Connect(function()
		useRevive("SecondWind")
	end)
	tokenButton.Activated:Connect(function()
		useRevive("Token")
	end)
	buyReviveButton.Activated:Connect(function()
		promptPurchase(Config.Products.SelfRevive, false)
	end)

	-- End-of-round banner
	local endBanner = text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(700, 90),
		Font = SCARY,
		Text = "",
		Visible = false,
		Parent = gui,
	})

	-- Live updates
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		local t = now()

		-- Danger vignette and radar every frame for smooth pulsing
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local nearest, nearestDistance = nil, math.huge
		if root then
			for _, monster in workspace:WaitForChild("Monsters"):GetChildren() do
				local pivot = monster:GetPivot().Position
				local distance = (pivot - root.Position).Magnitude
				if distance < nearestDistance then
					nearest, nearestDistance = pivot, distance
				end
			end
		end
		local danger = if nearest then math.clamp(1 - nearestDistance / 45, 0, 1) else 0
		local pulse = 0.75 + 0.25 * math.sin(os.clock() * (4 + danger * 8))
		for _, edge in edges do
			edge.BackgroundTransparency = 1 - danger * 0.75 * pulse
		end
		if nearest and player:GetAttribute("Pass_MonsterRadar") then
			local camera = workspace.CurrentCamera
			local flatLook = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
			local toMonster = Vector3.new(nearest.X - root.Position.X, 0, nearest.Z - root.Position.Z)
			local arrow = "⬆"
			if flatLook.Magnitude > 0.01 and toMonster.Magnitude > 0.01 then
				local angle = math.deg(math.atan2(flatLook:Cross(toMonster).Y, flatLook:Dot(toMonster)))
				local arrows = { "⬆", "↗", "➡", "↘", "⬇", "↙", "⬅", "↖" }
				arrow = arrows[(math.floor((-angle + 22.5) / 45) % 8) + 1]
			end
			radarLabel.Text = "📡 👹 " .. arrow .. " " .. math.floor(nearestDistance) .. "m"
		else
			radarLabel.Text = ""
		end

		elapsed += dt
		if elapsed < 0.1 then
			return
		end
		elapsed = 0

		local phase = workspace:GetAttribute("Phase") or "Waiting"
		local night = workspace:GetAttribute("Night") or 0
		local remaining = Format.Time((workspace:GetAttribute("PhaseEndsAt") or t) - t)
		local daylight = t < (workspace:GetAttribute("DaylightUntil") or 0)
		if phase == "Night" then
			phaseLabel.Text = if night == Config.BloodMoonNight then "BLOOD MOON" else "NIGHT " .. night .. " / " .. Config.Nights
			phaseLabel.TextColor3 = if night == Config.BloodMoonNight then Color3.fromRGB(255, 60, 60) else COLORS.pumpkin
			timerLabel.Text = if daylight
				then "☀️ Daylight! " .. Format.Time(workspace:GetAttribute("DaylightUntil") - t)
				else "Survive until dawn: " .. remaining
		elseif phase == "Dawn" then
			phaseLabel.Text = "DAWN"
			phaseLabel.TextColor3 = Color3.fromRGB(255, 210, 140)
			timerLabel.Text = "Night " .. (night + 1) .. " in " .. remaining
		elseif phase == "Intermission" then
			phaseLabel.Text = "SURVIVE THE HOLLOW"
			phaseLabel.TextColor3 = COLORS.pumpkin
			timerLabel.Text = "Night falls in " .. remaining
		elseif phase == "Victory" or phase == "GameOver" then
			phaseLabel.Text = if phase == "Victory" then "YOU ESCAPED" else "GAME OVER"
			timerLabel.Text = "New game in " .. remaining
		else
			phaseLabel.Text = "SURVIVE THE HOLLOW"
			timerLabel.Text = "Waiting for players..."
		end
		endBanner.Visible = phase == "Victory" or phase == "GameOver"
		endBanner.Text = if phase == "Victory" then "🏆 YOU SURVIVED 5 NIGHTS 🏆" else "💀 THE HOLLOW WINS 💀"
		endBanner.TextColor3 = if phase == "Victory" then Color3.fromRGB(255, 215, 80) else Color3.fromRGB(255, 60, 60)

		local fuel = workspace:GetAttribute("BonfireFuel") or 0
		local maxFuel = workspace:GetAttribute("BonfireMax") or 1
		setBonfire(fuel / maxFuel, if fuel <= 0 then "🔥 FIRE IS OUT! BRING LOGS" else "🔥 Bonfire " .. math.floor(fuel) .. "s")

		candyLabel.Text = "🍬 " .. Format.Abbrev(player:GetAttribute("Candy") or 0)

		local battery = player:GetAttribute("Battery") or 0
		local batteryMax = player:GetAttribute("BatteryMax") or 1
		if player:GetAttribute("Pass_InfiniteBattery") then
			setBattery(1, "🔦 Lantern ∞ (F)")
		else
			setBattery(battery / batteryMax, "🔦 Lantern " .. math.floor(battery) .. "s (F)")
		end
		lanternButton.Text = if player:GetAttribute("FlashlightOn") then "🔦 LIGHT ON" else "🔦 LIGHT OFF"
		setStamina(Controls.Stamina / Controls.StaminaMax(), if Controls.Sprinting then "👟 RUNNING" else "👟 Stamina (Shift)")

		local isDowned = player:GetAttribute("Downed")
		local isDead = player:GetAttribute("Dead")
		downed.Visible = (isDowned or isDead) and phase == "Night"
		if downed.Visible then
			if isDowned then
				downedTitle.Text = "YOU'RE DOWN"
				downedSub.Text = "A teammate can revive you. Bleeding out in " .. Format.Time((player:GetAttribute("DownedUntil") or t) - t)
			else
				downedTitle.Text = "YOU DIED"
				downedSub.Text = "You'll be back at dawn... or get back in now."
			end
			secondWindButton.Visible = player:GetAttribute("Pass_SecondWind") == true
			local tokens = player:GetAttribute("ReviveTokens") or 0
			tokenButton.Visible = tokens > 0
			tokenButton.Text = "💖 USE TOKEN (" .. tokens .. ")"
		end
	end)

	Players.PlayerAdded:Connect(function()
		if hauntPanel.Visible then
			refreshHaunt()
		end
	end)
	Players.PlayerRemoving:Connect(function()
		if hauntPanel.Visible then
			task.defer(refreshHaunt)
		end
	end)
end

return HUD
