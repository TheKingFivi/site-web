-- Small helpers for building the world out of parts.
local CollectionService = game:GetService("CollectionService")

local Build = {}

export type Props = { [string]: any }

-- Build.part(parent, size, cframe, color, material, props?)
function Build.part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, props: Props?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props then
		for key, value in props do
			(p :: any)[key] = value
		end
	end
	p.Parent = parent
	return p
end

function Build.wedge(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): WedgePart
	local p = Instance.new("WedgePart")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

function Build.cyl(parent: Instance, length: number, diameter: number, cf: CFrame, color: Color3, material: Enum.Material?): Part
	-- Cylinders run along their X axis.
	local p = Build.part(parent, Vector3.new(length, diameter, diameter), cf, color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

function Build.ball(parent: Instance, diameter: number, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Build.part(parent, Vector3.new(diameter, diameter, diameter), cf, color, material)
	p.Shape = Enum.PartType.Ball
	return p
end

function Build.model(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

-- Text on a face of a part.
function Build.label(part: BasePart, face: Enum.NormalId, text: string, color: Color3?, font: Enum.Font?, background: Color3?): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.2
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = if background then 0 else 1
	label.BackgroundColor3 = background or Color3.new()
	label.Text = text
	label.TextScaled = true
	label.Font = font or Enum.Font.GothamBlack
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.Parent = gui
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.04, 0)
	pad.PaddingRight = UDim.new(0.04, 0)
	pad.PaddingTop = UDim.new(0.08, 0)
	pad.PaddingBottom = UDim.new(0.08, 0)
	pad.Parent = label
	return label
end

function Build.pointLight(part: BasePart, color: Color3, range: number, brightness: number, shadows: boolean?): PointLight
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Shadows = shadows == true
	light.Parent = part
	return light
end

function Build.spotLight(part: BasePart, face: Enum.NormalId, color: Color3, range: number, brightness: number, angle: number): SpotLight
	local light = Instance.new("SpotLight")
	light.Face = face
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Angle = angle
	light.Shadows = true
	light.Parent = part
	return light
end

-- A ProximityPrompt. `only` limits it to one player (other clients hide it).
function Build.prompt(parent: Instance, action: string, object: string?, hold: number?, distance: number?): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = object or ""
	prompt.HoldDuration = hold or 0
	prompt.MaxActivationDistance = distance or 8
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.Parent = parent
	CollectionService:AddTag(prompt, "GamePrompt")
	return prompt
end

-- Fluorescent ceiling panel with a light that can be switched off in a blackout.
function Build.ceilingLight(parent: Instance, cf: CFrame, range: number?): Part
	local panel = Build.part(parent, Vector3.new(4, 0.3, 1.6), cf, Color3.fromRGB(235, 240, 255), Enum.Material.Neon)
	local light = Instance.new("SurfaceLight")
	light.Face = Enum.NormalId.Bottom
	light.Range = range or 22
	light.Brightness = 1.6
	light.Angle = 120
	light.Color = Color3.fromRGB(232, 240, 255)
	light.Shadows = true
	light.Parent = panel
	CollectionService:AddTag(panel, "PowerLight")
	return panel
end

-- Wall slab between two points on the floor (y = floor height).
function Build.wall(
	parent: Instance,
	a: Vector3,
	b: Vector3,
	height: number,
	thickness: number,
	color: Color3,
	material: Enum.Material?
): Part
	local mid = (a + b) / 2
	local length = (b - a).Magnitude
	local cf = CFrame.lookAt(mid, b) * CFrame.Angles(0, math.pi / 2, 0)
	return Build.part(parent, Vector3.new(length, height, thickness), cf + Vector3.new(0, height / 2, 0), color, material)
end

return Build
