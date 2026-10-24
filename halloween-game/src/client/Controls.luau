-- Sprint (Shift), lantern (F), and aiming the lantern where the camera looks.
-- ContextActionService also adds on-screen buttons for phones and tablets.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local player = Players.LocalPlayer

local Controls = {}
Controls.Stamina = Config.Movement.BaseStamina
Controls.Sprinting = false

local wantSprint = false

function Controls.StaminaMax(): number
	return Config.Movement.BaseStamina + (player:GetAttribute("Up_Stamina") or 0) * Config.Movement.StaminaPerLevel
end

function Controls.ToggleLantern()
	Remotes.ToggleFlashlight:FireServer(not player:GetAttribute("FlashlightOn"))
end

function Controls.Start()
	ContextActionService:BindAction("Sprint", function(_, state)
		if state == Enum.UserInputState.Begin then
			wantSprint = true
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			wantSprint = false
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
	ContextActionService:SetTitle("Sprint", "RUN")
	ContextActionService:SetPosition("Sprint", UDim2.new(1, -170, 1, -150))

	ContextActionService:BindAction("Lantern", function(_, state)
		if state == Enum.UserInputState.Begin then
			Controls.ToggleLantern()
		end
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.F, Enum.KeyCode.ButtonR1)
	ContextActionService:SetTitle("Lantern", "LIGHT")
	ContextActionService:SetPosition("Lantern", UDim2.new(1, -170, 1, -90))

	local sendTimer = 0
	RunService.RenderStepped:Connect(function(dt)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end

		local max = Controls.StaminaMax()
		local moving = humanoid.MoveDirection.Magnitude > 0.1
		local downed = player:GetAttribute("Downed")
		Controls.Sprinting = wantSprint and moving and not downed and Controls.Stamina > 0
		if Controls.Sprinting then
			Controls.Stamina = math.max(0, Controls.Stamina - dt)
		else
			Controls.Stamina = math.min(max, Controls.Stamina + Config.Movement.StaminaRegenPerSec * dt)
		end

		local speed = if Controls.Sprinting then Config.Movement.SprintSpeed else Config.Movement.WalkSpeed
		if player:GetAttribute("CarryingLog") then
			speed *= Config.Movement.CarryMultiplier
		end
		if downed then
			speed = Config.Movement.DownedSpeed
		end
		humanoid.WalkSpeed = speed

		-- Point the lantern where the camera looks (smooth locally, synced to the server 10x/second)
		if player:GetAttribute("FlashlightOn") then
			local camera = workspace.CurrentCamera
			local root = character:FindFirstChild("HumanoidRootPart")
			local attachment = root and root:FindFirstChild("LanternAttachment")
			if camera and attachment then
				local direction = camera.CFrame.LookVector
				local origin = attachment.WorldPosition
				attachment.WorldCFrame = CFrame.lookAt(origin, origin + direction)
				sendTimer += dt
				if sendTimer >= 0.1 then
					sendTimer = 0
					Remotes.Aim:FireServer(direction)
				end
			end
		end
	end)
end

return Controls
