-- All on-screen UI, built from code.
-- Lobby: killer picker, wardrobe, shop (bundles, Mystery Crate, passes, boosts).
-- Match: timer, pumpkins, survivor states, skill checks, heartbeat, cage/carry screens, killer power.
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Cosmetics = require(Shared.Cosmetics)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local player = Players.LocalPlayer

local HUD = {}

local SCARY = Enum.Font.SpecialElite
local FONT = Enum.Font.Oswald
local C = {
	panel = Color3.fromRGB(12, 11, 13),
	panel2 = Color3.fromRGB(26, 24, 28),
	red = Color3.fromRGB(150, 22, 30),
	gold = Color3.fromRGB(176, 140, 82),
	green = Color3.fromRGB(58, 64, 60),
	purple = Color3.fromRGB(70, 52, 78),
	bone = Color3.fromRGB(226, 220, 208),
	dim = Color3.fromRGB(150, 144, 140),
	grey = Color3.fromRGB(46, 44, 48),
}
local TOAST = { success = Color3.fromRGB(34, 48, 38), error = Color3.fromRGB(70, 16, 20), info = Color3.fromRGB(30, 28, 34) }
local HEALTH_ICON = { Healthy = "❤️", Injured = "🩸", Downed = "🆘", Carried = "😱", Caged = "🐦‍⬛" }

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
local function corner(r: number?)
	return new("UICorner", { CornerRadius = UDim.new(0, math.min(r or 3, 3)) }) -- sharp, DBD-like
end
local function outline()
	return new("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0), Transparency = 0.1 })
end
local function border(color: Color3, thickness: number?)
	return new("UIStroke", { Thickness = thickness or 2, Color = color, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
local function text(props)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = props.Font or FONT
	props.TextColor3 = props.TextColor3 or C.bone
	props.TextScaled = if props.TextScaled == nil then true else props.TextScaled
	return new("TextLabel", props, { outline() })
end
local function button(props, color: Color3)
	props.BackgroundColor3 = color
	props.Font = props.Font or FONT
	props.TextColor3 = C.bone
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
local function now()
	return workspace:GetServerTimeNow()
end
local function invoke(remote: RemoteFunction, ...)
	local ok, success, message, extra = pcall(remote.InvokeServer, remote, ...)
	if not ok then
		return false, "Something went wrong. Try again."
	end
	return success, message, extra
end

function HUD.Start(Audio)
	local gui = new("ScreenGui", {
		Name = "FairHUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})

	------------------------------------------------------------------ toasts / announcements
	local toastHolder = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -150),
		Size = UDim2.fromOffset(440, 220),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		new("UIListLayout", {
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local toastCount = 0
	local function toast(message: string, kind: string?)
		toastCount += 1
		local frame = new("Frame", {
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = TOAST[kind or "info"] or TOAST.info,
			LayoutOrder = toastCount,
			Parent = toastHolder,
		}, { corner(8) })
		text({ Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4), Text = message, Parent = frame })
		task.delay(3.5, function()
			TweenService:Create(frame, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
			task.wait(0.4)
			frame:Destroy()
		end)
		local frames = {}
		for _, child in toastHolder:GetChildren() do
			if child:IsA("Frame") then
				table.insert(frames, child)
			end
		end
		table.sort(frames, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		for i = 1, #frames - 5 do
			frames[i]:Destroy()
		end
	end
	local announceLabel = text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 150),
		Size = UDim2.new(0.85, 0, 0, 34),
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
		announceLabel.TextColor3 = if colorHex then Color3.fromHex(colorHex) else C.bone
		announceLabel.TextTransparency = 0
		announceStroke.Transparency = 0.1
		task.delay(5, function()
			if token == announceToken then
				TweenService:Create(announceLabel, TweenInfo.new(1), { TextTransparency = 1 }):Play()
				TweenService:Create(announceStroke, TweenInfo.new(1), { Transparency = 1 }):Play()
			end
		end)
	end
	Remotes.Notify.OnClientEvent:Connect(toast)
	Remotes.Announce.OnClientEvent:Connect(announce)

	------------------------------------------------------------------ red vignette + scare flash
	local vignette = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = gui })
	local edges = {}
	for _, spec in
		{
			{ UDim2.fromScale(1, 0.22), UDim2.fromScale(0, 0), 90 },
			{ UDim2.fromScale(1, 0.22), UDim2.fromScale(0, 0.78), -90 },
			{ UDim2.fromScale(0.18, 1), UDim2.fromScale(0, 0), 0 },
			{ UDim2.fromScale(0.18, 1), UDim2.fromScale(0.82, 0), 180 },
		}
	do
		table.insert(
			edges,
			new("Frame", {
				Size = spec[1],
				Position = spec[2],
				BackgroundColor3 = C.red,
				BorderSizePixel = 0,
				BackgroundTransparency = 1,
				Parent = vignette,
			}, { new("UIGradient", { Rotation = spec[3], Transparency = NumberSequence.new(0, 1) }) })
		)
	end
	local flash =
		new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.red, BackgroundTransparency = 1, ZIndex = 40, Parent = gui })
	Remotes.Scare.OnClientEvent:Connect(function(kind)
		flash.BackgroundColor3 = if kind == "trap" then Color3.fromRGB(120, 110, 100) else C.red
		flash.BackgroundTransparency = 0.25
		TweenService:Create(flash, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
		local camera = workspace.CurrentCamera
		local started = os.clock()
		local connection
		connection = RunService.RenderStepped:Connect(function()
			if os.clock() - started > 0.35 then
				connection:Disconnect()
				return
			end
			camera.CFrame *= CFrame.Angles(math.rad(math.random(-2, 2)), math.rad(math.random(-2, 2)), 0)
		end)
	end)

	------------------------------------------------------------------ top bar
	local top = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 44),
		Size = UDim2.fromOffset(340, 96),
		BackgroundColor3 = C.panel,
		BackgroundTransparency = 0.2,
		Parent = gui,
	}, { corner(12), border(C.red) })
	local titleLabel = text({
		Size = UDim2.new(1, -16, 0, 40),
		Position = UDim2.fromOffset(8, 4),
		Font = SCARY,
		Text = "NIGHTMARE FAIR",
		TextColor3 = C.red,
		Parent = top,
	})
	local subLabel = text({ Size = UDim2.new(1, -16, 0, 22), Position = UDim2.fromOffset(8, 44), Text = "", Parent = top })
	local objectiveLabel =
		text({ Size = UDim2.new(1, -16, 0, 22), Position = UDim2.fromOffset(8, 68), Text = "", TextColor3 = C.gold, Parent = top })

	-- Currency (top-left)
	local wallet = text({
		Position = UDim2.fromOffset(16, 52),
		Size = UDim2.fromOffset(260, 30),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = C.gold,
		Parent = gui,
	})

	-- Survivor list (right side)
	local roster = new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 150),
		Size = UDim2.fromOffset(220, 260),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.Name }),
	})

	------------------------------------------------------------------ survivor widgets
	local center = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -40),
		Size = UDim2.fromOffset(380, 100),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	local workFrame = new("Frame", {
		Position = UDim2.fromOffset(0, 70),
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundColor3 = Color3.fromRGB(15, 10, 15),
		Visible = false,
		Parent = center,
	}, { corner(6), border(C.grey) })
	local workFill = new(
		"Frame",
		{ Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(255, 140, 30), Parent = workFrame },
		{ corner(6) }
	)
	text({ Size = UDim2.new(1, 0, 1, -2), Text = "🎃 Lighting the pumpkin... (walk away to stop)", ZIndex = 2, Parent = workFrame })

	-- Skill check
	local skill = new(
		"Frame",
		{ Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 60), BackgroundTransparency = 1, Visible = false, Parent = center }
	)
	local track = new("Frame", {
		Position = UDim2.fromOffset(0, 26),
		Size = UDim2.new(1, -90, 0, 26),
		BackgroundColor3 = Color3.fromRGB(20, 12, 20),
		Parent = skill,
	}, { corner(6), border(C.bone) })
	local goodZone = new(
		"Frame",
		{ Size = UDim2.fromScale(0.14, 1), BackgroundColor3 = Color3.fromRGB(240, 232, 220), BackgroundTransparency = 0.3, Parent = track }
	)
	local greatZone = new("Frame", { Size = UDim2.fromScale(0.035, 1), BackgroundColor3 = C.gold, Parent = track })
	local needle = new(
		"Frame",
		{ Size = UDim2.new(0, 4, 1, 8), Position = UDim2.new(0, 0, 0, -4), BackgroundColor3 = C.red, ZIndex = 3, Parent = track }
	)
	text({ Size = UDim2.new(1, 0, 0, 22), Text = "SKILL CHECK! Press SPACE in the zone", TextColor3 = C.gold, Parent = skill })
	local hitButton = button(
		{ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 20), Size = UDim2.fromOffset(80, 38), Text = "HIT!" },
		C.gold
	)
	hitButton.Parent = skill

	local active = nil -- { Id, Start, ZoneStart }
	local SKILL_DURATION = 1.25
	local function finishSkill(result: string)
		if not active then
			return
		end
		local id = active.Id
		active = nil
		skill.Visible = false
		ContextActionService:UnbindAction("SkillCheckHit")
		Remotes.SkillCheck:FireServer(id, result)
		if result == "great" then
			Audio.Play("Great")
			toast("GREAT skill check", "success")
		elseif result == "miss" then
			toast("Missed!", "error")
		end
	end
	local function pressSkill()
		if not active then
			return
		end
		local pos = (os.clock() - active.Start) / SKILL_DURATION
		if pos >= active.ZoneStart and pos <= active.ZoneStart + 0.035 then
			finishSkill("great")
		elseif pos >= active.ZoneStart and pos <= active.ZoneStart + 0.14 then
			finishSkill("good")
		else
			finishSkill("miss")
		end
	end
	hitButton.Activated:Connect(pressSkill)
	Remotes.SkillCheck.OnClientEvent:Connect(function(id)
		local zoneStart = 0.45 + math.random() * 0.35
		active = { Id = id, Start = os.clock() + 0.35, ZoneStart = zoneStart }
		goodZone.Position = UDim2.fromScale(zoneStart, 0)
		greatZone.Position = UDim2.fromScale(zoneStart, 0)
		skill.Visible = true
		ContextActionService:BindActionAtPriority("SkillCheckHit", function(_, state)
			if state == Enum.UserInputState.Begin then
				pressSkill()
			end
			return Enum.ContextActionResult.Sink
		end, false, 3000, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
	end)

	-- Heartbeat (terror radius)
	local heart = text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 1, -170),
		Size = UDim2.fromOffset(60, 60),
		Text = "❤",
		TextColor3 = C.red,
		Visible = false,
		Parent = gui,
	})

	-- Status overlay (downed / carried / caged / trapped / ghost / killer frozen)
	local status = text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.36),
		Size = UDim2.fromOffset(620, 50),
		Font = SCARY,
		Text = "",
		Visible = false,
		Parent = gui,
	})
	local statusSub = text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.36, 40),
		Size = UDim2.fromOffset(620, 26),
		Text = "",
		Visible = false,
		Parent = gui,
	})
	local cageButtons = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.36, 64),
		Size = UDim2.fromOffset(420, 46),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	}, {
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 10),
		}),
	})
	local useBreakOut = button({ Size = UDim2.fromOffset(200, 44), Text = "🗝️ USE BREAK OUT", Parent = cageButtons }, C.gold)
	local buyBreakOut = button(
		{ Size = UDim2.fromOffset(200, 44), Text = "🗝️ BREAK OUT  R$ " .. Config.Products.SelfRescue.Price, Parent = cageButtons },
		C.green
	)

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
	useBreakOut.Activated:Connect(function()
		local ok, message = invoke(Remotes.UseSelfRescue)
		toast(message, if ok then "success" else "error")
	end)
	buyBreakOut.Activated:Connect(function()
		promptPurchase(Config.Products.SelfRescue, false)
	end)

	-- Killer power widget
	local power = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -30),
		Size = UDim2.fromOffset(360, 60),
		BackgroundColor3 = C.panel,
		BackgroundTransparency = 0.2,
		Visible = false,
		Parent = gui,
	}, { corner(10), border(C.red) })
	local powerLabel = text({ Size = UDim2.new(1, -16, 0, 28), Position = UDim2.fromOffset(8, 4), Text = "", Parent = power })
	local attackLabel =
		text({ Size = UDim2.new(1, -16, 0, 22), Position = UDim2.fromOffset(8, 32), Text = "", TextColor3 = C.dim, Parent = power })

	------------------------------------------------------------------ lobby panels
	local panels = {}
	local function makePanel(name: string, title: string, size: Vector2)
		local panel = new("Frame", {
			Name = name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.55),
			Size = UDim2.fromOffset(size.X, size.Y),
			BackgroundColor3 = C.panel,
			Visible = false,
			ZIndex = 10,
			Parent = gui,
		}, { corner(14), border(C.red, 3) })
		text({
			Size = UDim2.new(1, -80, 0, 40),
			Position = UDim2.fromOffset(16, 8),
			Font = SCARY,
			Text = title,
			TextColor3 = C.red,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = panel,
		})
		local close = button({ Size = UDim2.fromOffset(36, 36), Position = UDim2.new(1, -46, 0, 10), Text = "X", Parent = panel }, C.red)
		close.Activated:Connect(function()
			panel.Visible = false
		end)
		local scroll = new("ScrollingFrame", {
			Position = UDim2.fromOffset(12, 56),
			Size = UDim2.new(1, -24, 1, -68),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 6,
			Parent = panel,
		}, {
			new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		})
		panels[name] = panel
		return panel, scroll
	end
	local function togglePanel(name: string)
		for key, panel in panels do
			panel.Visible = key == name and not panel.Visible
		end
	end
	local function header(scroll, order: number, title: string, color: Color3?)
		return text({
			Size = UDim2.new(1, -10, 0, 26),
			Text = title,
			TextColor3 = color or C.gold,
			LayoutOrder = order,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = scroll,
		})
	end
	local function row(scroll, order: number, title: string, description: string, height: number?, accent: Color3?)
		local frame = new(
			"Frame",
			{ Size = UDim2.new(1, -10, 0, height or 66), BackgroundColor3 = C.panel2, LayoutOrder = order, Parent = scroll },
			{ corner(8) }
		)
		if accent then
			border(accent).Parent = frame
		end
		local titleLabel2 = text({
			Size = UDim2.new(1, -150, 0, 26),
			Position = UDim2.fromOffset(10, 6),
			Text = title,
			TextColor3 = accent or C.bone,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = frame,
		})
		local desc = text({
			Size = UDim2.new(1, -150, 1, -38),
			Position = UDim2.fromOffset(10, 32),
			Text = description,
			TextColor3 = C.dim,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			TextScaled = false,
			TextSize = 15,
			Parent = frame,
		})
		local buy = button(
			{ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(124, 42), Text = "" },
			C.green
		)
		buy.Parent = frame
		return buy, desc, titleLabel2
	end

	-- Killers
	local _, killerScroll = makePanel("Killers", "CHOOSE YOUR KILLER", Vector2.new(500, 440))
	local killerRefreshers = {}
	for i, key in Config.KillerOrder do
		local info = Config.Killers[key]
		local buy = row(killerScroll, i, info.Name .. "  ·  " .. info.Ability, info.Description, 80, info.Color)
		local function refresh()
			local unlocked = player:GetAttribute("Unlocked_" .. key)
			if player:GetAttribute("PreferredKiller") == key and unlocked then
				buy.Text = "✅ SELECTED"
				buy.BackgroundColor3 = C.grey
			elseif unlocked then
				buy.Text = "SELECT"
				buy.BackgroundColor3 = C.green
			elseif info.PassKey then
				buy.Text = "🎟️ " .. Format.Abbrev(info.Price) .. " / R$"
				buy.BackgroundColor3 = C.purple
			else
				buy.Text = "🎟️ " .. Format.Abbrev(info.Price)
				buy.BackgroundColor3 = C.gold
			end
		end
		table.insert(killerRefreshers, refresh)
		buy.Activated:Connect(function()
			if player:GetAttribute("Unlocked_" .. key) then
				local ok, message = invoke(Remotes.SelectKiller, key)
				toast(message, if ok then "success" else "error")
			elseif info.PassKey and (player:GetAttribute("Tickets") or 0) < info.Price then
				promptPurchase(Config.GamePasses[info.PassKey], true)
			else
				local ok, message = invoke(Remotes.BuyKiller, key)
				toast(message, if ok then "success" else "error")
			end
		end)
		player:GetAttributeChangedSignal("Unlocked_" .. key):Connect(refresh)
	end
	player:GetAttributeChangedSignal("PreferredKiller"):Connect(function()
		for _, refresh in killerRefreshers do
			refresh()
		end
	end)
	for _, refresh in killerRefreshers do
		refresh()
	end

	-- Wardrobe
	local _, wardrobeScroll = makePanel("Wardrobe", "WARDROBE", Vector2.new(520, 480))
	local order = 0
	for _, section in { { "Hat", "🎭 HATS & MASKS (survivors)" }, { "Trail", "✨ TRAILS (everyone)" }, { "Skin", "🔪 KILLER SKINS" } } do
		order += 1
		header(wardrobeScroll, order, section[2])
		for _, item in Cosmetics.Items do
			if item.Type == section[1] then
				order += 1
				local rarity = Cosmetics.Rarities[item.Rarity]
				local detail = item.Rarity .. (if item.Killer then " · " .. Config.Killers[item.Killer].Name else "")
				local buy = row(wardrobeScroll, order, item.Name, detail, 58, rarity.Color)
				local slot = if item.Type == "Skin" then "Skin_" .. item.Killer else "Equip_" .. item.Type
				local function refresh()
					if player:GetAttribute("Owned_" .. item.Id) then
						local equipped = player:GetAttribute(slot) == item.Id
						buy.Text = if equipped then "✅ EQUIPPED" else "EQUIP"
						buy.BackgroundColor3 = if equipped then C.grey else C.green
					elseif item.Price then
						buy.Text = "🎟️ " .. Format.Abbrev(item.Price)
						buy.BackgroundColor3 = C.gold
					else
						buy.Text = "🎁 BUNDLE / CRATE"
						buy.BackgroundColor3 = C.purple
					end
				end
				player:GetAttributeChangedSignal("Owned_" .. item.Id):Connect(refresh)
				player:GetAttributeChangedSignal(slot):Connect(refresh)
				refresh()
				buy.Activated:Connect(function()
					if player:GetAttribute("Owned_" .. item.Id) then
						local ok, message = invoke(Remotes.Equip, item.Id)
						toast(message, if ok then "success" else "error")
					elseif item.Price then
						local ok, message = invoke(Remotes.BuyCosmetic, item.Id)
						toast(message, if ok then "success" else "error")
					else
						togglePanel("Shop")
					end
				end)
			end
		end
	end

	-- Shop
	local _, shopScroll = makePanel("Shop", "SHOP", Vector2.new(540, 500))
	order = 0
	order += 1
	header(shopScroll, order, "🎁 BUNDLES", C.gold)
	for _, key in Cosmetics.BundleOrder do
		local bundle = Cosmetics.Bundles[key]
		local product = Config.Products[key]
		order += 1
		local buy, desc = row(shopScroll, order, bundle.Name .. "   " .. bundle.Badge, product.Description, 74, C.gold)
		buy.Text = "R$ " .. product.Price
		if bundle.OneTime then
			local function refresh()
				if player:GetAttribute("StarterBought") then
					desc.Text = "Already claimed. Buying again gives " .. bundle.Tickets * 2 .. " 🎟️."
				end
			end
			player:GetAttributeChangedSignal("StarterBought"):Connect(refresh)
			refresh()
		end
		buy.Activated:Connect(function()
			promptPurchase(product, false)
		end)
	end
	order += 1
	header(shopScroll, order, "📦 MYSTERY CRATE", C.purple)
	order += 1
	local odds = Cosmetics.Crate.Odds
	local crateBuy = row(
		shopScroll,
		order,
		"Mystery Crate",
		string.format(
			"Random hat, trail or skin. Odds: Common %d%% · Rare %d%% · Epic %d%% · Legendary %d%%. Duplicates refund %d 🎟️.",
			odds.Common,
			odds.Rare,
			odds.Epic,
			odds.Legendary,
			Cosmetics.Crate.DuplicateRefund
		),
		84,
		C.purple
	)
	crateBuy.Text = "🎟️ " .. Cosmetics.Crate.Price
	crateBuy.BackgroundColor3 = C.purple
	crateBuy.Activated:Connect(function()
		local ok, message, id = invoke(Remotes.OpenCrate)
		if ok and id then
			local item = Cosmetics.ById[id]
			announce("📦 " .. message, Cosmetics.Rarities[item.Rarity].Color:ToHex())
		else
			toast(message, "error")
		end
	end)
	order += 1
	header(shopScroll, order, "⭐ GAME PASSES (forever)")
	for _, key in Config.PassOrder do
		local pass = Config.GamePasses[key]
		order += 1
		local buy = row(shopScroll, order, pass.Name, pass.Description)
		local function refresh()
			local owned = player:GetAttribute("Pass_" .. key)
			buy.Text = if owned then "OWNED" else "R$ " .. pass.Price
			buy.BackgroundColor3 = if owned then C.grey else C.green
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
	header(shopScroll, order, "⚡ BOOSTS & TICKETS")
	for _, key in Config.ProductOrder do
		local product = Config.Products[key]
		order += 1
		local buy = row(shopScroll, order, product.Name, product.Description)
		buy.Text = "R$ " .. product.Price
		buy.Activated:Connect(function()
			promptPurchase(product, false)
		end)
	end

	-- Lobby buttons
	local side = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(150, 190),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local killersButton = button({ Size = UDim2.fromOffset(150, 52), Text = "🔪 KILLERS", LayoutOrder = 1, Parent = side }, C.red)
	local wardrobeButton = button({ Size = UDim2.fromOffset(150, 52), Text = "🎭 WARDROBE", LayoutOrder = 2, Parent = side }, C.purple)
	local shopButton = button({ Size = UDim2.fromOffset(150, 52), Text = "🛒 SHOP", LayoutOrder = 3, Parent = side }, C.gold)
	killersButton.Activated:Connect(function()
		togglePanel("Killers")
	end)
	wardrobeButton.Activated:Connect(function()
		togglePanel("Wardrobe")
	end)
	shopButton.Activated:Connect(function()
		togglePanel("Shop")
	end)

	------------------------------------------------------------------ live updates
	local rosterRows = {}
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		local t = now()
		local role = player:GetAttribute("Role") or "Lobby"
		local phase = workspace:GetAttribute("Phase") or "Waiting"
		local inMatch = phase == "Match"

		-- Skill check needle + timeout
		if active then
			local pos = (os.clock() - active.Start) / SKILL_DURATION
			needle.Position = UDim2.new(math.clamp(pos, 0, 1), -2, 0, -4)
			if pos > 1 then
				finishSkill("miss")
			end
		end

		-- Heartbeat & vignette for survivors
		local danger = 0
		if role == "Survivor" and inMatch then
			local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			for _, other in Players:GetPlayers() do
				if other:GetAttribute("Role") == "Killer" and not other:GetAttribute("Vanished") then
					local root = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
					if root and myRoot then
						danger = math.clamp(1 - (root.Position - myRoot.Position).Magnitude / 60, 0, 1)
					end
				end
			end
			for _, bot in CollectionService:GetTagged("KillerBot") do
				local root = bot:FindFirstChild("HumanoidRootPart")
				if root and myRoot then
					danger = math.max(danger, math.clamp(1 - (root.Position - myRoot.Position).Magnitude / 60, 0, 1))
				end
			end
		end
		heart.Visible = danger > 0
		if danger > 0 then
			local beat = math.abs(math.sin(os.clock() * (3 + danger * 7)))
			heart.Size = UDim2.fromOffset(44 + beat * 30 * danger, 44 + beat * 30 * danger)
		end
		for _, edge in edges do
			edge.BackgroundTransparency = 1 - danger * 0.7
		end

		elapsed += dt
		if elapsed < 0.1 then
			return
		end
		elapsed = 0

		wallet.Text = "🎟️ "
			.. Format.Abbrev(player:GetAttribute("Tickets") or 0)
			.. "    🔪 Killer Chance: "
			.. (player:GetAttribute("KillerChance") or 1)
		side.Visible = role == "Lobby" or role == "Escaped"
		if not side.Visible then
			for _, panel in panels do
				panel.Visible = false
			end
		end

		-- Top bar
		local remaining = Format.Time((workspace:GetAttribute("PhaseEndsAt") or t) - t)
		if inMatch then
			local killerType = workspace:GetAttribute("KillerType")
			titleLabel.Text = if killerType then string.upper(Config.Killers[killerType].Name) else "THE HUNT"
			subLabel.Text = "Fair closes in " .. remaining
			local collapse = workspace:GetAttribute("CollapseEndsAt")
			if workspace:GetAttribute("GatesPowered") and collapse then
				objectiveLabel.Text = "⚡ GATES POWERED · collapse in " .. Format.Time(collapse - t)
			else
				objectiveLabel.Text = "🎃 Pumpkins lit: "
					.. (workspace:GetAttribute("PumpkinsLit") or 0)
					.. " / "
					.. Config.Pumpkins.Needed
			end
		elseif phase == "Intermission" then
			titleLabel.Text = "NIGHTMARE FAIR"
			subLabel.Text = "The hunt begins in " .. remaining
			objectiveLabel.Text = "Higher Killer Chance = better odds to be the killer"
		elseif phase == "Results" then
			local killerWon = workspace:GetAttribute("ResultKillerWon")
			titleLabel.Text = if killerWon then "THE KILLER WINS" else "SURVIVORS WIN"
			subLabel.Text = (workspace:GetAttribute("ResultEscaped") or 0)
				.. " escaped · "
				.. (workspace:GetAttribute("ResultEliminated") or 0)
				.. " taken"
			objectiveLabel.Text = "Back to the lobby in " .. remaining
		else
			titleLabel.Text = "NIGHTMARE FAIR"
			subLabel.Text = "Waiting for players (" .. Config.MinPlayers .. " needed)..."
			objectiveLabel.Text = ""
		end

		-- Roster
		roster.Visible = inMatch
		local seen = {}
		if inMatch then
			for _, other in Players:GetPlayers() do
				local otherRole = other:GetAttribute("Role")
				if otherRole == "Survivor" or otherRole == "Ghost" or otherRole == "Escaped" then
					seen[other] = true
					local label = rosterRows[other]
					if not label then
						label = text({
							Name = other.Name,
							Size = UDim2.new(1, 0, 0, 24),
							TextXAlignment = Enum.TextXAlignment.Right,
							Parent = roster,
						})
						rosterRows[other] = label
					end
					local icon
					if otherRole == "Ghost" then
						icon = "👻"
					elseif otherRole == "Escaped" then
						icon = "🏃"
					else
						icon = HEALTH_ICON[other:GetAttribute("Health") or "Healthy"] or "❤️"
						local cageEnds = other:GetAttribute("CageEndsAt")
						if cageEnds then
							icon ..= " " .. math.max(0, math.floor(cageEnds - t)) .. "s"
						end
					end
					label.Text = other.DisplayName .. "  " .. icon
				end
			end
		end
		for other, label in rosterRows do
			if not seen[other] then
				label:Destroy()
				rosterRows[other] = nil
			end
		end

		-- Work bar
		local working = role == "Survivor" and player:GetAttribute("WorkingOn") ~= nil
		workFrame.Visible = working
		if working then
			workFill.Size = UDim2.fromScale(player:GetAttribute("WorkProgress") or 0, 1)
		elseif active then
			finishSkill("miss")
		end

		-- Status overlays
		local health = player:GetAttribute("Health")
		local statusText, subText, showCage = nil, nil, false
		if inMatch and role == "Survivor" then
			if player:GetAttribute("Hiding") then
				statusText, subText = "HIDING", "Hold still... The killer can search lockers. Press E to leave."
			elseif health == "Downed" then
				statusText, subText = "YOU'RE DOWN", "Crawl away! A teammate can help you up."
			elseif health == "Carried" then
				statusText = "YOU'RE BEING CARRIED"
				subText = "Wiggling free in "
					.. math.max(0, math.ceil((player:GetAttribute("WiggleEndsAt") or t) - t))
					.. "s... (pallet stuns drop you too)"
			elseif health == "Caged" then
				local count = player:GetAttribute("CageCount") or 1
				statusText = "CAUGHT IN A CROW CAGE"
				subText = "The crows come in "
					.. math.max(0, math.ceil((player:GetAttribute("CageEndsAt") or t) - t))
					.. "s · cage "
					.. count
					.. " of 3"
				showCage = true
			elseif (player:GetAttribute("TrappedUntil") or 0) > t then
				statusText, subText = "TRAPPED!", "Stuck in a bear trap..."
			end
		elseif inMatch and role == "Killer" then
			local frozen = (workspace:GetAttribute("PhaseEndsAt") or 0) - Config.MatchTime + 10 - t
			if frozen > 0 then
				statusText, subText = "YOU ARE THE KILLER", "The survivors are hiding. You can move in " .. math.ceil(frozen) .. "s"
			elseif (player:GetAttribute("StunnedUntil") or 0) > t then
				statusText = "STUNNED!"
			end
		elseif inMatch and role == "Ghost" then
			statusText, subText = "YOU ARE A GHOST", "Find the 🔔 Ghost Bells and ring them to reveal the killer to your friends."
		elseif role == "Escaped" and inMatch then
			statusText, subText = "YOU ESCAPED", "Waiting for the match to finish..."
		end
		status.Visible = statusText ~= nil
		statusSub.Visible = subText ~= nil
		status.Text = statusText or ""
		statusSub.Text = subText or ""
		status.TextColor3 = if role == "Ghost"
			then Color3.fromRGB(170, 220, 255)
			elseif role == "Escaped" then Color3.fromRGB(120, 255, 150)
			else C.red
		cageButtons.Visible = showCage
		useBreakOut.Visible = (player:GetAttribute("BreakOuts") or 0) > 0
		useBreakOut.Text = "🗝️ USE BREAK OUT (" .. (player:GetAttribute("BreakOuts") or 0) .. ")"

		-- Killer power
		power.Visible = inMatch and role == "Killer"
		if power.Visible then
			local killerType = player:GetAttribute("KillerType") or "Ringmaster"
			local info = Config.Killers[killerType]
			local abilityWait = (player:GetAttribute("AbilityReadyAt") or 0) - t
			powerLabel.Text = "[Q] "
				.. info.Ability
				.. (if abilityWait > 0 then "  ·  " .. math.ceil(abilityWait) .. "s" else "  ·  READY")
			powerLabel.TextColor3 = if abilityWait > 0 then C.dim else info.Color
			attackLabel.Text = if player:GetAttribute("Vanished")
				then "👻 Invisible (click to reveal)"
				else "[Click] Attack  ·  Pick up downed survivors and cage them"
		end
	end)
end

return HUD
