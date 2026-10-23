-- Client entry point: UI, prompt visibility, rainbow effects and VIP chat tags.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local HUD = require(script.Parent.HUD)

local player = Players.LocalPlayer

HUD.Start()

-- Only show "Steal" on other people's critters and "Sell" on your own.
local function setupPrompt(prompt: ProximityPrompt)
	local isMine = prompt:GetAttribute("OwnerId") == player.UserId
	if prompt.Name == "StealPrompt" then
		prompt.Enabled = not isMine
		prompt.HoldDuration = if player:GetAttribute("Pass_FastThief") then Config.Steal.FastHoldTime else Config.Steal.HoldTime
	elseif prompt.Name == "SellPrompt" then
		prompt.Enabled = isMine
	end
end
CollectionService:GetInstanceAddedSignal("CritterPrompt"):Connect(setupPrompt)
for _, prompt in CollectionService:GetTagged("CritterPrompt") do
	setupPrompt(prompt)
end
player:GetAttributeChangedSignal("Pass_FastThief"):Connect(function()
	for _, prompt in CollectionService:GetTagged("CritterPrompt") do
		setupPrompt(prompt)
	end
end)

-- Rainbow mutation animation
RunService.RenderStepped:Connect(function()
	local color = Color3.fromHSV((os.clock() * 0.25) % 1, 0.8, 1)
	for _, part in CollectionService:GetTagged("Rainbow") do
		part.Color = color
	end
	for _, label in CollectionService:GetTagged("RainbowText") do
		label.TextColor3 = color
	end
end)

-- [VIP] chat tag
TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local properties = Instance.new("TextChatMessageProperties")
	local source = message.TextSource
	local speaker = source and Players:GetPlayerByUserId(source.UserId)
	if speaker and speaker:GetAttribute("Pass_VIP") then
		properties.PrefixText = "<font color='#FFD23C'>[VIP]</font> " .. message.PrefixText
	end
	return properties
end
