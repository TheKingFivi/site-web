-- All on-screen UI, built from code: cash, timers, buttons, shop, rebirth panel, notifications.
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

local FONT = Enum.Font.FredokaOne
local COLORS = {
	panel = Color3.fromRGB(35, 30, 60),
	panelLight = Color3.fromRGB(55, 48, 92),
	accent = Color3.fromRGB(160, 110, 255),
	green = Color3.fromRGB(70, 210, 100),
	red = Color3.fromRGB(235, 70, 80),
	blue = Color3.fromRGB(70, 140, 255),
	gold = Color3.fromRGB(255, 200, 60),
	white = Color3.new(1, 1, 1),
}
local TOAST_COLORS = { success = COLORS.green, error = COLORS.red, info = COLORS.blue }

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
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

local function outline(thickness: number?)
	return new("UIStroke", { Thickness = thickness or 2, Color = Color3.new(0, 0, 0), Transparency = 0.2 })
end

local function borderStroke(color: Color3)
	return new("UIStroke", { Thickness = 3, Color = color, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function text(props)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = props.Font or FONT
	props.TextColor3 = props.TextColor3 or COLORS.white
	props.TextScaled = if props.TextScaled == nil then true else props.TextScaled
	return new("TextLabel", props, { outline() })
end

local function button(props, color: Color3)
	props.BackgroundColor3 = color
	props.Font = FONT
	props.TextColor3 = COLORS.white
	props.TextScaled = true
	props.AutoButtonColor = true
	return new("TextButton", props, {
		corner(10),
		outline(),
		new(
			"UIPadding",
			{ PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }
		),
		borderStroke(color:Lerp(Color3.new(0, 0, 0), 0.35)),
	})
end

local function now()
	return workspace:GetServerTimeNow()
end

function HUD.Start()
	local gui = new("ScreenGui", {
		Name = "CritterHeistHUD",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})

	-- Cash display
	local cashFrame = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(280, 66),
		BackgroundColor3 = COLORS.panel,
		BackgroundTransparency = 0.15,
		Parent = gui,
	}, { corner(14), borderStroke(COLORS.gold) })
	local cashLabel = text({
		Size = UDim2.new(1, -12, 0, 40),
		Position = UDim2.fromOffset(6, 2),
		Text = "$0",
		TextColor3 = COLORS.gold,
		Parent = cashFrame,
	})
	local incomeLabel = text({
		Size = UDim2.new(1, -12, 0, 20),
		Position = UDim2.fromOffset(6, 42),
		Text = "+$0/s",
		TextColor3 = Color3.fromRGB(140, 255, 150),
		Parent = cashFrame,
	})

	local eventLabel = text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 78),
		Size = UDim2.fromOffset(460, 26),
		Text = "",
		Parent = gui,
	})
	local luckLabel = text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 104),
		Size = UDim2.fromOffset(360, 22),
		Text = "",
		TextColor3 = Color3.fromRGB(120, 255, 130),
		Parent = gui,
	})

	local carryLabel = text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.fromOffset(520, 44),
		Text = "",
		TextColor3 = Color3.fromRGB(255, 120, 120),
		Visible = false,
		Parent = gui,
	})

	-- Big announcements
	local announceLabel = text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 132),
		Size = UDim2.new(0.8, 0, 0, 34),
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
		announceLabel.TextColor3 = if colorHex then Color3.fromHex(colorHex) else COLORS.white
		announceLabel.TextTransparency = 0
		announceStroke.Transparency = 0.2
		task.delay(5, function()
			if token == announceToken then
				TweenService:Create(announceLabel, TweenInfo.new(1), { TextTransparency = 1 }):Play()
				TweenService:Create(announceStroke, TweenInfo.new(1), { Transparency = 1 }):Play()
			end
		end)
	end

	-- Toast notifications
	local toastHolder = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -110),
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
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundColor3 = TOAST_COLORS[kind or "info"] or COLORS.blue,
			LayoutOrder = toastCount,
			Parent = toastHolder,
		}, { corner(10) })
		text({ Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4), Text = message, Parent = frame })
		task.delay(3.5, function()
			TweenService:Create(frame, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
			task.wait(0.4)
			frame:Destroy()
		end)
	end

	Remotes.Notify.OnClientEvent:Connect(toast)
	Remotes.Announce.OnClientEvent:Connect(announce)

	-- Panels
	local panels = {}
	local function makePanel(name: string, title: string, size: Vector2)
		local panel = new("Frame", {
			Name = name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.52),
			Size = UDim2.fromOffset(size.X, size.Y),
			BackgroundColor3 = COLORS.panel,
			Visible = false,
			Parent = gui,
		}, { corner(16), borderStroke(COLORS.accent) })
		text({
			Size = UDim2.new(1, -80, 0, 36),
			Position = UDim2.fromOffset(16, 8),
			Text = title,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = panel,
		})
		local close =
			button({ Size = UDim2.fromOffset(36, 36), Position = UDim2.new(1, -46, 0, 8), Text = "X", Parent = panel }, COLORS.red)
		close.Activated:Connect(function()
			panel.Visible = false
		end)
		panels[name] = panel
		return panel
	end
	local function togglePanel(name: string)
		for key, panel in panels do
			panel.Visible = key == name and not panel.Visible
		end
	end

	-- Shop
	local shop = makePanel("Shop", "🛒 SHOP", Vector2.new(480, 440))
	local scroll = new("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 54),
		Size = UDim2.new(1, -24, 1, -66),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		Parent = shop,
	}, { new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })

	local order = 0
	local function header(title: string)
		order += 1
		text({
			Size = UDim2.new(1, -10, 0, 26),
			Text = title,
			TextColor3 = COLORS.gold,
			LayoutOrder = order,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = scroll,
		})
	end
	local function shopItem(item, isPass: boolean, key: string)
		order += 1
		local row = new(
			"Frame",
			{ Size = UDim2.new(1, -10, 0, 70), BackgroundColor3 = COLORS.panelLight, LayoutOrder = order, Parent = scroll },
			{ corner(10) }
		)
		text({
			Size = UDim2.new(1, -140, 0, 28),
			Position = UDim2.fromOffset(10, 6),
			Text = item.Name,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		text({
			Size = UDim2.new(1, -140, 0, 30),
			Position = UDim2.fromOffset(10, 34),
			Text = item.Description,
			TextColor3 = Color3.fromRGB(210, 210, 230),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			Parent = row,
		})
		local buy = button(
			{
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(110, 44),
				Text = "R$ " .. item.Price,
				Parent = row,
			},
			COLORS.green
		)
		buy.Activated:Connect(function()
			if item.Id == 0 then
				toast("This item isn't set up yet (Id = 0 in Config).", "error")
				return
			end
			if isPass then
				MarketplaceService:PromptGamePassPurchase(player, item.Id)
			else
				MarketplaceService:PromptProductPurchase(player, item.Id)
			end
		end)
		if isPass then
			local function refresh()
				if player:GetAttribute("Pass_" .. key) then
					buy.Text = "OWNED"
					buy.BackgroundColor3 = Color3.fromRGB(90, 90, 110)
					buy.Active = false
				end
			end
			player:GetAttributeChangedSignal("Pass_" .. key):Connect(refresh)
			refresh()
		end
	end
	header("⭐ GAME PASSES (forever)")
	for _, key in Config.PassOrder do
		shopItem(Config.GamePasses[key], true, key)
	end
	header("⚡ BOOSTS & PACKS")
	for _, key in Config.ProductOrder do
		shopItem(Config.Products[key], false, key)
	end

	-- Rebirth panel
	local rebirthPanel = makePanel("Rebirth", "♻️ REBIRTH", Vector2.new(400, 270))
	local rebirthInfo = text({
		Position = UDim2.fromOffset(16, 52),
		Size = UDim2.new(1, -32, 0, 140),
		TextScaled = false,
		TextSize = 20,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = "",
		Parent = rebirthPanel,
	})
	local rebirthButton = button(
		{
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -14),
			Size = UDim2.fromOffset(220, 50),
			Text = "REBIRTH!",
			Parent = rebirthPanel,
		},
		COLORS.accent
	)
	rebirthButton.Activated:Connect(function()
		local ok, success, message = pcall(Remotes.Rebirth.InvokeServer, Remotes.Rebirth)
		if ok then
			toast(message, if success then "success" else "error")
			if success then
				rebirthPanel.Visible = false
			end
		end
	end)

	-- Side buttons
	local side = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(150, 250),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local shopButton = button({ Size = UDim2.fromOffset(150, 52), Text = "🛒 SHOP", LayoutOrder = 1, Parent = side }, COLORS.gold)
	local rebirthOpen = button({ Size = UDim2.fromOffset(150, 52), Text = "♻️ REBIRTH", LayoutOrder = 2, Parent = side }, COLORS.accent)
	local dailyButton = button({ Size = UDim2.fromOffset(150, 52), Text = "🎁 DAILY", LayoutOrder = 3, Parent = side }, COLORS.green)
	local lockButton = button({ Size = UDim2.fromOffset(150, 52), Text = "🔒 LOCK", LayoutOrder = 4, Parent = side }, COLORS.blue)

	shopButton.Activated:Connect(function()
		togglePanel("Shop")
	end)
	rebirthOpen.Activated:Connect(function()
		togglePanel("Rebirth")
	end)
	dailyButton.Activated:Connect(function()
		local ok, success, message = pcall(Remotes.ClaimDaily.InvokeServer, Remotes.ClaimDaily)
		if ok then
			toast(message, if success then "success" else "error")
		end
	end)
	lockButton.Activated:Connect(function()
		local ok, success, message = pcall(Remotes.LockBase.InvokeServer, Remotes.LockBase)
		if ok then
			toast(message, if success then "success" else "error")
		end
	end)

	-- Live updates
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.1 then
			return
		end
		elapsed = 0
		local t = now()

		cashLabel.Text = Format.Cash(player:GetAttribute("Cash") or 0)
		local mult = player:GetAttribute("Multiplier") or 1
		local incomeText = "+" .. Format.Cash(player:GetAttribute("IncomePerSec") or 0) .. "/s"
		if mult > 1.001 then
			incomeText ..= string.format("  (x%.2f)", mult)
		end
		incomeLabel.Text = incomeText

		if workspace:GetAttribute("MoonRaid") then
			eventLabel.Text = "🌙 MOON RAID! Locks are OFF — "
				.. Format.Time((workspace:GetAttribute("RaidEndsAt") or t) - t)
				.. " left"
			eventLabel.TextColor3 = Color3.fromRGB(170, 190, 255)
		else
			eventLabel.Text = "🌙 Moon Raid in " .. Format.Time((workspace:GetAttribute("NextRaidAt") or t) - t)
			eventLabel.TextColor3 = COLORS.white
		end

		local luckUntil = workspace:GetAttribute("LuckUntil") or 0
		luckLabel.Text = if t < luckUntil
			then "🍀 Server Luck x" .. Config.ServerLuck.Multiplier .. " — " .. Format.Time(luckUntil - t)
			else ""

		local carrying = player:GetAttribute("Carrying")
		carryLabel.Visible = carrying ~= nil
		if carrying then
			carryLabel.Text = "🏃 RUN HOME WITH " .. string.upper(carrying) .. "!"
		end

		local dailyReady = player:GetAttribute("DailyReadyAt") or 0
		local nowUnix = math.floor(t)
		dailyButton.Text = if nowUnix >= dailyReady then "🎁 DAILY!" else "🎁 " .. Format.Time(dailyReady - nowUnix)

		local shieldUntil = player:GetAttribute("ShieldUntil") or 0
		local lockedUntil = player:GetAttribute("LockedUntil") or 0
		local lockReady = player:GetAttribute("LockReadyAt") or 0
		if t < shieldUntil then
			lockButton.Text = "🛡️ " .. Format.Time(shieldUntil - t)
		elseif t < lockedUntil and not workspace:GetAttribute("MoonRaid") then
			lockButton.Text = "🔒 " .. Format.Time(lockedUntil - t)
		elseif t < lockReady then
			lockButton.Text = "⏳ " .. Format.Time(lockReady - t)
		else
			lockButton.Text = "🔒 LOCK"
		end

		if rebirthPanel.Visible then
			local rebirths = player:GetAttribute("Rebirths") or 0
			local cost = player:GetAttribute("RebirthCost") or 0
			rebirthInfo.Text = string.format(
				"Rebirths: %d\nCost: %s\n\n✅ Gain: x%.1f income and +1 base slot\n❌ Lose: your cash and critters",
				rebirths,
				Format.Cash(cost),
				1 + (rebirths + 1) * Config.Rebirth.IncomeBonus
			)
		end
	end)
end

return HUD
