-- Client entry point.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Audio = require(script.Parent.Audio)
local Controls = require(script.Parent.Controls)
local Effects = require(script.Parent.Effects)
local HUD = require(script.Parent.HUD)

Audio.Start()
Effects.Start()
Controls.Start()
HUD.Start(Audio)

-- Rainbow trail cosmetic
RunService.RenderStepped:Connect(function()
	local hue = (os.clock() * 0.3) % 1
	for _, trail in CollectionService:GetTagged("RainbowTrail") do
		trail.Color = ColorSequence.new(Color3.fromHSV(hue, 0.9, 1), Color3.fromHSV((hue + 0.3) % 1, 0.9, 1))
	end
end)
