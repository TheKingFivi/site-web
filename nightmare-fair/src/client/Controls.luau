-- Killer input: click / ATTACK button to swing, Q / POWER button for the killer's power.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local player = Players.LocalPlayer

local Controls = {}

local bound = false

local function isKiller()
	return player:GetAttribute("Role") == "Killer"
end

function Controls.Attack()
	if isKiller() then
		Remotes.Attack:FireServer()
	end
end

function Controls.Ability()
	if isKiller() then
		Remotes.Ability:FireServer()
	end
end

local function refreshBindings()
	if isKiller() and not bound then
		bound = true
		ContextActionService:BindAction("KillerAttack", function(_, state)
			if state == Enum.UserInputState.Begin then
				Controls.Attack()
			end
			return Enum.ContextActionResult.Sink
		end, true, Enum.KeyCode.ButtonR2)
		ContextActionService:SetTitle("KillerAttack", "ATTACK")
		ContextActionService:SetPosition("KillerAttack", UDim2.new(1, -180, 1, -160))
		ContextActionService:BindAction("KillerAbility", function(_, state)
			if state == Enum.UserInputState.Begin then
				Controls.Ability()
			end
			return Enum.ContextActionResult.Sink
		end, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonL2)
		ContextActionService:SetTitle("KillerAbility", "POWER")
		ContextActionService:SetPosition("KillerAbility", UDim2.new(1, -250, 1, -100))
	elseif not isKiller() and bound then
		bound = false
		ContextActionService:UnbindAction("KillerAttack")
		ContextActionService:UnbindAction("KillerAbility")
	end
end

function Controls.Start()
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then
			Controls.Attack()
		end
	end)
	player:GetAttributeChangedSignal("Role"):Connect(refreshBindings)
	refreshBindings()
end

return Controls
