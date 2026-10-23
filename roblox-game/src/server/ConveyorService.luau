-- Critter Road: critters walk down the road and players buy them before they leave.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Critters = require(Shared.Critters)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local CritterFactory = require(script.Parent.CritterFactory)

local ConveyorService = {}

local rng = Random.new()

local function currentLuck(): number
	if workspace:GetServerTimeNow() < (workspace:GetAttribute("LuckUntil") or 0) then
		return Config.ServerLuck.Multiplier
	end
	return 1
end

function ConveyorService.Spawn(forcedId: string?, forcedMutation: string?)
	local isRaid = workspace:GetAttribute("MoonRaid") == true
	local id = forcedId or Critters.Roll(currentLuck(), isRaid, rng)
	local mutation = forcedMutation or Critters.RollMutation(isRaid, rng)
	local def = Critters.ById[id]
	local rarity = Critters.Rarities[def.Rarity]
	local price = Critters.Price(id, mutation)
	local name = Critters.DisplayName(id, mutation)

	local model = CritterFactory.Build(id, mutation, { Price = price })
	local y = Config.Conveyor.RoadTop + CritterFactory.GroundOffset(def)
	local startPos = Vector3.new(Config.Conveyor.StartX, y, 0)
	local endPos = Vector3.new(Config.Conveyor.EndX, y, 0)
	local direction = (endPos - startPos).Unit
	model:PivotTo(CFrame.lookAt(startPos, startPos + direction))

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy " .. Format.Cash(price)
	prompt.ObjectText = name
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart

	model.Parent = workspace:WaitForChild("RoadCritters")

	local duration = (endPos - startPos).Magnitude / Config.Conveyor.WalkSpeed
	local tween = TweenService:Create(model.PrimaryPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		CFrame = CFrame.lookAt(endPos, endPos + direction),
	})
	local sold = false
	tween.Completed:Connect(function()
		if not sold then
			model:Destroy()
		end
	end)

	prompt.Triggered:Connect(function(player)
		if sold then
			return
		end
		if not PlotService.GetPlot(player) then
			return
		end
		if not PlotService.FindFreeSlot(player) then
			Remotes.notify(player, "Your base is full! Sell a critter, rebirth, or get +4 Slots.", "error")
			return
		end
		if not DataService.SpendCash(player, price) then
			Remotes.notify(player, "Not enough cash for " .. name .. " (" .. Format.Cash(price) .. ")", "error")
			return
		end
		sold = true
		tween:Cancel()
		model:Destroy()
		PlotService.AddCritter(player, id, mutation)
		Remotes.notify(player, "You bought " .. name .. "! It's in your base.", "success")
		if rarity.Order >= 5 then
			Remotes.announce("💎 " .. player.DisplayName .. " bought a " .. def.Rarity .. " " .. name .. "!", rarity.Color)
		end
	end)

	tween:Play()

	if rarity.Order >= 5 then
		Remotes.announce("✨ A " .. def.Rarity:upper() .. " " .. name .. " is walking down Critter Road!", rarity.Color)
	end
end

function ConveyorService.Init()
	task.spawn(function()
		while true do
			local ok, err = pcall(ConveyorService.Spawn)
			if not ok then
				warn("[ConveyorService] spawn error:", err)
			end
			task.wait(Config.Conveyor.SpawnInterval)
		end
	end)
end

return ConveyorService
