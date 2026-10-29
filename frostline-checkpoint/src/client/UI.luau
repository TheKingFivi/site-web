-- UI building helpers and the game's visual style.
local TweenService = game:GetService("TweenService")

local UI = {}

UI.Colors = {
	Navy = Color3.fromRGB(20, 32, 72),
	NavyDark = Color3.fromRGB(12, 20, 48),
	Paper = Color3.fromRGB(236, 238, 244),
	PaperDark = Color3.fromRGB(214, 218, 230),
	Ink = Color3.fromRGB(16, 22, 48),
	Green = Color3.fromRGB(34, 168, 60),
	GreenDark = Color3.fromRGB(20, 110, 36),
	Red = Color3.fromRGB(205, 30, 30),
	Yellow = Color3.fromRGB(255, 214, 60),
	Cyan = Color3.fromRGB(60, 220, 255),
	Pink = Color3.fromRGB(236, 150, 236),
	Black = Color3.fromRGB(10, 10, 12),
	White = Color3.new(1, 1, 1),
	Cash = Color3.fromRGB(110, 230, 90),
	Candy = Color3.fromRGB(255, 190, 60),
}

-- Hand-drawn look like the screenshots: Kalam for titles, Patrick Hand for body text.
UI.Title = Font.new("rbxasset://fonts/families/Kalam.json", Enum.FontWeight.Bold)
UI.Hand = Font.new("rbxasset://fonts/families/PatrickHand.json")
UI.Bold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
UI.Mono = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Bold)

function UI.new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className)
	if props then
		local parent = props.Parent
		for key, value in props do
			if key ~= "Parent" then
				(inst :: any)[key] = value
			end
		end
		if children then
			for _, child in children do
				child.Parent = inst
			end
		end
		if parent then
			inst.Parent = parent
		end
	end
	return inst
end

function UI.corner(parent: Instance, radius: number?): UICorner
	return UI.new("UICorner", { CornerRadius = UDim.new(0, radius or 12), Parent = parent })
end

function UI.stroke(parent: Instance, thickness: number?, color: Color3?, mode: Enum.ApplyStrokeMode?): UIStroke
	return UI.new("UIStroke", {
		Thickness = thickness or 3,
		Color = color or UI.Colors.Ink,
		ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function UI.pad(parent: Instance, px: number)
	return UI.new("UIPadding", {
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		Parent = parent,
	})
end

function UI.list(parent: Instance, padding: number?, horizontal: boolean?, align: Enum.HorizontalAlignment?): UIListLayout
	return UI.new("UIListLayout", {
		Padding = UDim.new(0, padding or 6),
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical,
		HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

-- Text with a dark outline (the cartoony HUD look).
function UI.text(parent: Instance, text: string, props: { [string]: any }?): TextLabel
	local label = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		FontFace = UI.Title,
		TextColor3 = UI.Colors.White,
		TextScaled = true,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})
	if props then
		for key, value in props do
			(label :: any)[key] = value
		end
	end
	return label
end

function UI.outlined(label: TextLabel, thickness: number?)
	UI.new(
		"UIStroke",
		{ Thickness = thickness or 2.5, Color = UI.Colors.Black, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Parent = label }
	)
	return label
end

function UI.button(parent: Instance, text: string, color: Color3, onClick: () -> (), props: { [string]: any }?): TextButton
	local button = UI.new("TextButton", {
		BackgroundColor3 = color,
		Text = text,
		FontFace = UI.Title,
		TextColor3 = UI.Colors.White,
		TextScaled = true,
		AutoButtonColor = true,
		Parent = parent,
	})
	UI.corner(button, 10)
	UI.stroke(button, 3, color:Lerp(Color3.new(), 0.45))
	UI.new("UIPadding", {
		PaddingTop = UDim.new(0.12, 0),
		PaddingBottom = UDim.new(0.12, 0),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = button,
	})
	if props then
		for key, value in props do
			(button :: any)[key] = value
		end
	end
	button.MouseButton1Click:Connect(onClick)
	-- Little press animation
	local scale = UI.new("UIScale", { Parent = button })
	button.MouseButton1Down:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.06), { Scale = 0.94 }):Play()
	end)
	button.MouseButton1Up:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.1), { Scale = 1 }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.1), { Scale = 1 }):Play()
	end)
	return button
end

function UI.tween(inst: Instance, time: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween
	local tween = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

-- Pop-in animation for panels.
function UI.pop(frame: GuiObject)
	local scale = frame:FindFirstChildOfClass("UIScale") or UI.new("UIScale", { Parent = frame })
	scale.Scale = 0.7
	UI.tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
end

-- A modal window like the "CREATE PARTY" panel: navy header, subtitle, title, red X.
function UI.modal(parent: Instance, subtitle: string, title: string, icon: string, size: UDim2, onClose: () -> ()): (Frame, Frame)
	local frame = UI.new("Frame", {
		Size = size,
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = UI.Colors.Paper,
		Parent = parent,
	})
	UI.corner(frame, 14)
	UI.stroke(frame, 4, UI.Colors.NavyDark)
	UI.new(
		"UISizeConstraint",
		{ MaxSize = Vector2.new(size.X.Offset > 0 and size.X.Offset or 1000, size.Y.Offset > 0 and size.Y.Offset or 700), Parent = frame }
	)
	local header = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 82), BackgroundColor3 = UI.Colors.Navy, Parent = frame })
	UI.corner(header, 14)
	UI.new("Frame", {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 1, -16),
		BackgroundColor3 = UI.Colors.Navy,
		BorderSizePixel = 0,
		Parent = header,
	})
	UI.new("UIGradient", {
		Color = ColorSequence.new(UI.Colors.Navy, UI.Colors.NavyDark),
		Rotation = 90,
		Parent = header,
	})
	UI.text(header, icon, { Size = UDim2.fromOffset(64, 64), Position = UDim2.fromOffset(12, 9), FontFace = UI.Bold })
	UI.text(header, subtitle, {
		Size = UDim2.new(1, -170, 0, 24),
		Position = UDim2.fromOffset(86, 8),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(170, 190, 240),
	})
	UI.text(
		header,
		title,
		{ Size = UDim2.new(1, -170, 0, 44), Position = UDim2.fromOffset(84, 30), TextXAlignment = Enum.TextXAlignment.Left }
	)
	local close = UI.button(header, "X", UI.Colors.Red, onClose, {
		Size = UDim2.fromOffset(64, 64),
		Position = UDim2.new(1, -74, 0, 9),
		FontFace = UI.Bold,
	})
	local _ = close
	local body = UI.new("Frame", {
		Size = UDim2.new(1, 0, 1, -82),
		Position = UDim2.fromOffset(0, 82),
		BackgroundTransparency = 1,
		Parent = frame,
	})
	UI.pad(body, 16)
	UI.pop(frame)
	return frame, body
end

return UI
