-- Client entry point: controls, UI, revive prompt visibility and VIP chat tags.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local Controls = require(script.Parent.Controls)
local HUD = require(script.Parent.HUD)

local player = Players.LocalPlayer

Controls.Start()
HUD.Start(Controls)

-- You can't revive yourself: hide your own revive prompt.
local function setupPrompt(prompt: ProximityPrompt)
	if prompt:GetAttribute("OwnerId") == player.UserId then
		prompt.MaxActivationDistance = 0
	end
end
CollectionService:GetInstanceAddedSignal("RevivePrompt"):Connect(setupPrompt)
for _, prompt in CollectionService:GetTagged("RevivePrompt") do
	setupPrompt(prompt)
end

-- [VIP] chat tag
TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local properties = Instance.new("TextChatMessageProperties")
	local source = message.TextSource
	local speaker = source and Players:GetPlayerByUserId(source.UserId)
	if speaker and speaker:GetAttribute("Pass_VIP") then
		properties.PrefixText = "<font color='#FFB43C'>[VIP]</font> " .. message.PrefixText
	end
	return properties
end
