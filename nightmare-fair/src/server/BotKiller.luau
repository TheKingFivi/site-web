-- The AI killer: plays The Ringmaster when only one person is in the server, so a solo player can always play.
-- It hunts the nearest survivor it can see, investigates noises (failed skill checks, lit pumpkins),
-- downs survivors, carries them to Crow Cages, and can be stunned with pallets.
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local KillerService = require(script.Parent.KillerService)
local Match = require(script.Parent.Match)
local SurvivorService = require(script.Parent.SurvivorService)

local BotKiller = {}

local SPEED = 16.5 -- a little faster than survivors (16), slower than a real killer (18)
local CARRY_SPEED = 14
local SIGHT = 75
local rng = Random.new()

local bot = nil -- { Model, Humanoid, Root, ... }

local function now()
	return Match.Now()
end

local function flat(v: Vector3)
	return Vector3.new(v.X, 0, v.Z)
end

local function buildBody(spawnCFrame: CFrame)
	local description = Instance.new("HumanoidDescription")
	description.HeadColor = Color3.fromRGB(230, 225, 215)
	description.TorsoColor = Color3.fromRGB(30, 10, 18)
	description.LeftArmColor = Color3.fromRGB(30, 10, 18)
	description.RightArmColor = Color3.fromRGB(30, 10, 18)
	description.LeftLegColor = Color3.fromRGB(20, 15, 20)
	description.RightLegColor = Color3.fromRGB(20, 15, 20)
	local model = Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	model.Name = "The Ringmaster"
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.WalkSpeed = SPEED
	humanoid.BreakJointsOnDeath = false
	model:PivotTo(spawnCFrame)
	model.Parent = workspace
	Match.SetCollisionGroup(model, "Players")
	local root = model:FindFirstChild("HumanoidRootPart")
	root:SetNetworkOwner(nil) -- the server drives it
	KillerService.Dress(model, "Ringmaster")
	CollectionService:AddTag(model, "KillerBot")
	return model, humanoid, root
end

local function canSee(from: Vector3, to: Vector3, ignore)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	return workspace:Raycast(from, to - from, params) == nil
end

local function pickTarget()
	local best, bestScore = nil, math.huge
	for _, survivor in Match.Survivors() do
		local root = Match.Root(survivor)
		if root and Match.IsStandingSurvivor(survivor) then
			local distance = (root.Position - bot.Root.Position).Magnitude
			local visible = distance < 25
				or (distance < SIGHT and canSee(bot.Root.Position + Vector3.new(0, 2, 0), root.Position, { bot.Model, survivor.Character }))
			if visible and distance < bestScore then
				best, bestScore = survivor, distance
			end
		end
	end
	return best
end

local function downedSurvivor()
	local best, bestDistance = nil, math.huge
	for _, survivor in Match.Survivors() do
		local root = Match.Root(survivor)
		if root and Match.Health(survivor) == "Downed" then
			local distance = (root.Position - bot.Root.Position).Magnitude
			if distance < bestDistance then
				best, bestDistance = survivor, distance
			end
		end
	end
	return best
end

local function nearestFreeCage()
	local best, bestDistance = nil, math.huge
	for _, cage in Match.Map.Cages do
		if not cage.Occupant then
			local distance = (cage.Position - bot.Root.Position).Magnitude
			if distance < bestDistance then
				best, bestDistance = cage, distance
			end
		end
	end
	return best
end

-- Walks toward a goal using pathfinding (recomputed every half second), or straight when close.
local function moveTo(goal: Vector3)
	local t = os.clock()
	if (flat(goal) - flat(bot.Root.Position)).Magnitude < 14 then
		bot.Humanoid:MoveTo(goal)
		bot.Path = nil
		return
	end
	if not bot.Path or t - bot.PathTime > 0.5 or (bot.PathGoal - goal).Magnitude > 8 then
		bot.PathTime = t
		bot.PathGoal = goal
		local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
		local ok = pcall(function()
			path:ComputeAsync(bot.Root.Position, goal)
		end)
		if ok and path.Status == Enum.PathStatus.Success then
			bot.Path = path:GetWaypoints()
			bot.PathIndex = 2
		else
			bot.Path = nil
		end
	end
	if bot.Path and bot.Path[bot.PathIndex] then
		local waypoint = bot.Path[bot.PathIndex]
		if (flat(waypoint.Position) - flat(bot.Root.Position)).Magnitude < 3 then
			bot.PathIndex += 1
			waypoint = bot.Path[bot.PathIndex] or waypoint
		end
		if waypoint.Action == Enum.PathWaypointAction.Jump then
			bot.Humanoid.Jump = true
		end
		bot.Humanoid:MoveTo(waypoint.Position)
	else
		bot.Humanoid:MoveTo(goal)
	end
end

local function attack(target: Player)
	local t = now()
	if t < bot.AttackReadyAt then
		return
	end
	bot.AttackReadyAt = t + Config.Attack.Cooldown + 0.3
	Remotes.Swing:FireAllClients(bot.Model)
	local result = SurvivorService.Hit(target)
	if result then
		bot.SlowedUntil = t + Config.Speeds.KillerAfterHitTime
	end
end

local function stun(seconds: number)
	bot.StunnedUntil = now() + seconds
	local survivor = SurvivorService.CarriedBy(bot)
	if survivor then
		SurvivorService.Drop(survivor, "Injured")
		Remotes.notify(survivor, "You fell free! RUN!", "success")
	end
end

local function think()
	if not bot or not bot.Model.Parent then
		return
	end
	local t = now()
	local humanoid = bot.Humanoid

	if t < bot.FrozenUntil or t < bot.StunnedUntil then
		humanoid.WalkSpeed = 0
		humanoid:MoveTo(bot.Root.Position)
		return
	end

	local carrying = SurvivorService.CarriedBy(bot)
	humanoid.WalkSpeed = if carrying then CARRY_SPEED elseif t < bot.SlowedUntil then Config.Speeds.KillerAfterHit else SPEED

	-- 1. Carrying someone: take them to the nearest empty cage
	if carrying then
		local cage = nearestFreeCage()
		if cage then
			if (cage.Position - bot.Root.Position).Magnitude < 7 then
				SurvivorService.CageSurvivor(bot, cage)
				bot.WanderGoal = nil
			else
				moveTo(cage.Position)
			end
		end
		return
	end

	-- 2. Someone is downed: go pick them up
	local downed = downedSurvivor()
	if downed then
		local root = Match.Root(downed)
		if root then
			if (root.Position - bot.Root.Position).Magnitude < 6 then
				SurvivorService.Pickup(bot, downed)
			else
				moveTo(root.Position)
			end
			return
		end
	end

	-- 3. Chase a survivor it can see
	local target = pickTarget()
	if target then
		bot.LastSeen = Match.Root(target).Position
		local root = Match.Root(target)
		if (root.Position - bot.Root.Position).Magnitude < Config.Attack.Range - 1.5 then
			attack(target)
		end
		moveTo(root.Position)
		return
	end

	-- 4. Investigate the last sighting or noise, then patrol between unlit pumpkins
	local goal = bot.LastSeen or bot.Noise
	if goal and (flat(goal) - flat(bot.Root.Position)).Magnitude < 6 then
		bot.LastSeen, bot.Noise = nil, nil
		goal = nil
	end
	if not goal then
		if not bot.WanderGoal or (flat(bot.WanderGoal) - flat(bot.Root.Position)).Magnitude < 8 then
			local options = {}
			for _, pumpkin in Match.Map.Pumpkins do
				if not pumpkin.Lit then
					table.insert(options, pumpkin.Position)
				end
			end
			for _, gate in Match.Map.Gates do
				if workspace:GetAttribute("GatesPowered") then
					table.insert(options, gate.Switch.Position)
				end
			end
			bot.WanderGoal = if #options > 0 then options[rng:NextInteger(1, #options)] else Match.Map.KillerSpawn.Position
		end
		goal = bot.WanderGoal
	end
	moveTo(goal)
end

function BotKiller.Start()
	BotKiller.Stop()
	local model, humanoid, root = buildBody(Match.Map.KillerSpawn)
	bot = {
		Model = model,
		Humanoid = humanoid,
		Root = root,
		AttackReadyAt = 0,
		SlowedUntil = 0,
		StunnedUntil = 0,
		FrozenUntil = now() + 10,
		PathTime = 0,
		PathGoal = Vector3.zero,
	}
	Match.BotModel = model
end

function BotKiller.Stop()
	if bot then
		local survivor = SurvivorService.CarriedBy(bot)
		if survivor then
			SurvivorService.Drop(survivor)
		end
		bot.Model:Destroy()
		bot = nil
	end
	Match.BotModel = nil
end

function BotKiller.IsActive(): boolean
	return bot ~= nil
end

function BotKiller.Init()
	KillerService.OnPalletDropped = function(position: Vector3, survivor: Player)
		if bot and (bot.Root.Position - position).Magnitude < Config.Pallet.StunRadius then
			stun(Config.Pallet.StunTime)
			local earned = DataService.AddTickets(survivor, Config.Rewards.PalletStun, true)
			Remotes.notify(survivor, "💥 PALLET STUN! +" .. earned .. " 🎟️", "success")
		end
	end
	Match.OnNoise = function(position: Vector3)
		if bot then
			bot.Noise = position
		end
	end
	task.spawn(function()
		while true do
			task.wait(0.15)
			if bot and Match.Active then
				local ok, err = pcall(think)
				if not ok then
					warn("[BotKiller] think error:", err)
				end
			end
		end
	end)
end

return BotKiller
