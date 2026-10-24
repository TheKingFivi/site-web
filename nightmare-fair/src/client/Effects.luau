-- World effects: spinning rides, role-based prompt visibility, killer swing trails,
-- noise pings for the killer, and the [VIP] chat tag.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local player = Players.LocalPlayer

local Effects = {}

-- Spinning rides (Ferris wheel, carousel): rotated locally every frame
local spinners = {}
local function addSpinner(model: Model)
	spinners[model] = model:GetPivot()
end

-- Prompts: only show the ones meant for your role, and never your own heal/pickup prompt
local function refreshPrompt(prompt: ProximityPrompt)
	local forRole = prompt:GetAttribute("For")
	local ownerId = prompt:GetAttribute("OwnerId")
	local role = player:GetAttribute("Role")
	local visible = forRole == role and ownerId ~= player.UserId
	prompt.MaxActivationDistance = if visible then (prompt:GetAttribute("Range") or 8) else 0
end

local function refreshAllPrompts()
	for _, prompt in CollectionService:GetTagged("RolePrompt") do
		refreshPrompt(prompt)
	end
end

local function showPing(position: Vector3, kind: string?)
	local marker = Instance.new("Part")
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker.Transparency = 1
	marker.Position = position + Vector3.new(0, 6, 0)
	marker.Parent = workspace
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(60, 60)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Text = if kind == "rescue" then "🐦‍⬛" elseif kind == "pumpkin" then "🎃" elseif kind == "trap" then "🪤" else "💥"
	label.Parent = gui
	gui.Parent = marker
	TweenService:Create(label, TweenInfo.new(4), { TextTransparency = 1 }):Play()
	task.delay(4, function()
		marker:Destroy()
	end)
end

local function swingEffect(userId: number)
	local killer = Players:GetPlayerByUserId(userId)
	local root = killer and killer.Character and killer.Character:FindFirstChild("HumanoidRootPart")
	if not root or killer:GetAttribute("Vanished") then
		return
	end
	local slash = Instance.new("Part")
	slash.Anchored = true
	slash.CanCollide = false
	slash.CanQuery = false
	slash.CanTouch = false
	slash.Size = Vector3.new(6, 0.2, 3)
	slash.Material = Enum.Material.Neon
	slash.Color = Color3.fromRGB(255, 60, 60)
	slash.Transparency = 0.3
	slash.CFrame = root.CFrame * CFrame.new(0, 0.5, -3.5) * CFrame.Angles(0, 0, math.rad(-30))
	slash.Parent = workspace
	TweenService:Create(slash, TweenInfo.new(0.25), { Transparency = 1, CFrame = slash.CFrame * CFrame.Angles(0, 0, math.rad(60)) }):Play()
	task.delay(0.3, function()
		slash:Destroy()
	end)
end

function Effects.Start()
	CollectionService:GetInstanceAddedSignal("Spin"):Connect(addSpinner)
	for _, model in CollectionService:GetTagged("Spin") do
		addSpinner(model)
	end
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for model, origin in spinners do
			if model.Parent then
				local speed = model:GetAttribute("SpinSpeed") or 0.2
				local axis = model:GetAttribute("SpinAxis")
				local rotation = if axis == "Z" then CFrame.Angles(0, 0, t * speed) else CFrame.Angles(0, t * speed, 0)
				model:PivotTo(origin * rotation)
			else
				spinners[model] = nil
			end
		end
	end)

	CollectionService:GetInstanceAddedSignal("RolePrompt"):Connect(refreshPrompt)
	player:GetAttributeChangedSignal("Role"):Connect(refreshAllPrompts)
	refreshAllPrompts()

	Remotes.Ping.OnClientEvent:Connect(showPing)
	Remotes.Swing.OnClientEvent:Connect(swingEffect)

	TextChatService.OnIncomingMessage = function(message: TextChatMessage)
		local properties = Instance.new("TextChatMessageProperties")
		local source = message.TextSource
		local speaker = source and Players:GetPlayerByUserId(source.UserId)
		if speaker and speaker:GetAttribute("Pass_VIP") then
			properties.PrefixText = "<font color='#FFC83C'>[VIP]</font> " .. message.PrefixText
		end
		return properties
	end
end

return Effects
