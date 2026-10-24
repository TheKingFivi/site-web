-- Candy, batteries and logs scattered in the dark, plus trick-or-treat doors on every house.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local MonsterService = require(script.Parent.MonsterService)
local PlayerService = require(script.Parent.PlayerService)
local World = require(script.Parent.World)

local PickupService = {}

local rng = Random.new()
local folder

local function playerFromHit(hit: BasePart)
	local character = hit:FindFirstAncestorOfClass("Model")
	return character and Players:GetPlayerFromCharacter(character)
end

local function newPart(props)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		part[key] = value
	end
	return part
end

local function glow(part: BasePart, color: Color3, range: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = 1
	light.Parent = part
end

local spawnPickup

local function give(kind: string, player: Player): boolean
	if kind == "Candy" then
		local amount = DataService.AddCandy(player, rng:NextInteger(Config.Rewards.CandyPickup[1], Config.Rewards.CandyPickup[2]), true)
		Remotes.notify(player, "+" .. amount .. " 🍬", "success")
		return true
	elseif kind == "Battery" then
		local max = PlayerService.BatteryMax(player)
		if (player:GetAttribute("Battery") or 0) >= max - 0.5 then
			return false
		end
		player:SetAttribute("Battery", max)
		Remotes.notify(player, "🔋 Lantern fully charged!", "success")
		return true
	elseif kind == "Log" then
		if player:GetAttribute("CarryingLog") then
			return false
		end
		PickupService.GiveLog(player)
		return true
	end
	return false
end

function spawnPickup(kind: string, position: Vector3?)
	position = position or World.RandomSpot(20)
	local part
	if kind == "Candy" then
		part = newPart({
			Name = "Candy",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.3, 1.3, 1.3),
			Color = Color3.fromRGB(255, 140, 30),
			Material = Enum.Material.Neon,
			Position = position + Vector3.new(0, 1, 0),
		})
		glow(part, Color3.fromRGB(255, 140, 30), 6)
	elseif kind == "Battery" then
		part = newPart({
			Name = "Battery",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.8, 0.9, 0.9),
			CFrame = CFrame.new(position + Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(90, 255, 120),
			Material = Enum.Material.Neon,
		})
		glow(part, Color3.fromRGB(90, 255, 120), 8)
	else
		part = newPart({
			Name = "Log",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(3.6, 1.1, 1.1),
			CFrame = CFrame.new(position + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0),
			Color = Color3.fromRGB(110, 70, 40),
			Material = Enum.Material.Wood,
		})
		glow(part, Color3.fromRGB(255, 200, 120), 5)
	end
	part:SetAttribute("Kind", kind)

	local taken = false
	part.Touched:Connect(function(hit)
		if taken then
			return
		end
		local player = playerFromHit(hit)
		if player and PlayerService.IsActive(player) and give(kind, player) then
			taken = true
			part:Destroy()
			task.delay(Config.Pickups.RespawnTime, spawnPickup, kind)
		end
	end)
	part.Parent = folder
	return part
end

function PickupService.GiveLog(player: Player)
	player:SetAttribute("CarryingLog", true)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		local log = Instance.new("Part")
		log.Name = "CarriedLog"
		log.Shape = Enum.PartType.Cylinder
		log.Size = Vector3.new(3.6, 1.1, 1.1)
		log.Color = Color3.fromRGB(110, 70, 40)
		log.Material = Enum.Material.Wood
		log.CanCollide = false
		log.CanTouch = false
		log.CanQuery = false
		log.Massless = true
		log.CFrame = root.CFrame * CFrame.new(0, 0.5, 1)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = log
		weld.Parent = log
		log.Parent = character
	end
	Remotes.notify(player, "🪵 Got a log! Bring it to the bonfire.", "info")
end

local function clearLog(player: Player)
	player:SetAttribute("CarryingLog", false)
	local character = player.Character
	local log = character and character:FindFirstChild("CarriedLog")
	if log then
		log:Destroy()
	end
end

-- Called when a player is downed or dies: the log falls where they stand.
function PickupService.DropLog(player: Player)
	if not player:GetAttribute("CarryingLog") then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	clearLog(player)
	if root then
		spawnPickup("Log", Vector3.new(root.Position.X, 0, root.Position.Z) + Vector3.new(2, 0, 0))
	else
		task.delay(Config.Pickups.RespawnTime, spawnPickup, "Log")
	end
end

local function checkDeliveries()
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("CarryingLog") then
			local root = PlayerService.IsActive(player)
			if root then
				local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
				if flat.Magnitude < math.max(World.SafeRadius(), 10) then
					clearLog(player)
					World.AddFuel(Config.Bonfire.LogFuel)
					local earned = DataService.AddCandy(player, Config.Rewards.LogDelivered, true)
					Remotes.notify(player, "🔥 The fire grows! +" .. earned .. " 🍬", "success")
					task.delay(Config.Pickups.RespawnTime, spawnPickup, "Log")
				end
			end
		end
	end
end

local function setupDoor(house)
	local door = house.Door
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "KnockPrompt"
	prompt.ActionText = "Knock"
	prompt.ObjectText = "🎃 Trick or Treat?"
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = door

	prompt.Triggered:Connect(function(player)
		if not prompt.Enabled or not PlayerService.IsActive(player) then
			return
		end
		prompt.Enabled = false
		task.delay(Config.Doors.Cooldown, function()
			prompt.Enabled = true
		end)

		local roll = rng:NextNumber()
		local isNight = workspace:GetAttribute("Phase") == "Night"
		if roll < Config.Doors.TrickChance and isNight then
			MonsterService.ForceTarget(player, Config.Doors.TrickChaseTime)
			Remotes.Jumpscare:FireClient(player)
			Remotes.notify(player, "🎃 TRICK! The Hollow heard you knocking... RUN!", "error")
		elseif roll < 0.35 then
			player:SetAttribute("Battery", PlayerService.BatteryMax(player))
			Remotes.notify(player, "🍭 TREAT! Someone handed you fresh batteries.", "success")
		elseif roll < 0.5 and not player:GetAttribute("CarryingLog") then
			PickupService.GiveLog(player)
		else
			local amount = DataService.AddCandy(player, rng:NextInteger(10, 30), true)
			Remotes.notify(player, "🍬 TREAT! +" .. amount .. " candy.", "success")
		end
	end)
end

function PickupService.Init()
	folder = workspace:WaitForChild("Pickups")
	for _ = 1, Config.Pickups.Candy do
		spawnPickup("Candy")
	end
	for _ = 1, Config.Pickups.Batteries do
		spawnPickup("Battery")
	end
	for _ = 1, Config.Pickups.Logs do
		spawnPickup("Log")
	end
	for _, house in World.Houses do
		setupDoor(house)
	end
	PlayerService.OnDowned = PickupService.DropLog

	task.spawn(function()
		while true do
			task.wait(0.2)
			local ok, err = pcall(checkDeliveries)
			if not ok then
				warn("[PickupService] delivery error:", err)
			end
		end
	end)
end

return PickupService
