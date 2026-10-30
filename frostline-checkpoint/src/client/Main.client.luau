-- Frostline Checkpoint client entry point.
local HUD = require(script.Parent.HUD)
local Inspect = require(script.Parent.Inspect)
local Effects = require(script.Parent.Effects)

HUD.Init()
Inspect.Init(HUD.Gui)
Inspect.Toast = HUD.Toast
Effects.Init()

-- The RULES button opens the rulebook from the latest shift state
HUD.OnRules = function()
	local state = HUD.State()
	if state.Shift then
		Inspect.Open("Rulebook", { Lines = state.Shift.Rules, Shift = state.Shift.Shift })
	end
end
