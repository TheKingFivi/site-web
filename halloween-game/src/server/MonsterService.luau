-- The Hollow: a pumpkin-headed scarecrow that hunts anyone outside the bonfire's light.
-- It is moved directly (anchored) along PathfindingService paths, which keeps it reliable.
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local World = require(script.Parent.World)

local MonsterService = {}
MonsterService.OnCatch = nil -- set by PlayerService: function(player)

local HEIGHT = 4.6 -- pivot height above the ground
local monsters = {}
local forcedTargets = {} -- [Player] = until (server time)
local rng = Random.new()

local function now()
	return workspace:GetServerTimeNow()
end

local function flat(v: Vector3)
	return Vector3.new(v.X, 0, v.Z)
end

local function newPart(props, parent)
	local part = Instance.new("Part")
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.Anchored = false
	part.Massless = true
	for key, value in props do
		part[key] = value
	end
	part.Parent = parent
	return part
end

local function buildModel(isBloodMoon: boolean)
	local model = Instance.new("Model")
	model.Name = "The Hollow"
	local root = newPart({ Name = "Root", Size = Vector3.new(2, 2, 1), Transparency = 1, Anchored = true }, model)
	model.PrimaryPart = root

	local function attach(part: BasePart, offset: CFrame)
		part.CFrame = root.CFrame * offset
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = part
		weld.Parent = part
		return part
	end

	local cloth = if isBloodMoon then Color3.fromRGB(70, 20, 25) else Color3.fromRGB(70, 55, 40)
	attach(
		newPart({ Name = "Torso", Size = Vector3.new(2.6, 3.4, 1.2), Color = cloth, Material = Enum.Material.Fabric }, model),
		CFrame.new(0, 0.6, 0)
	)
	for _, x in { -1, 1 } do
		attach(
			newPart(
				{ Name = "Leg", Size = Vector3.new(0.7, 3.4, 0.7), Color = Color3.fromRGB(50, 40, 30), Material = Enum.Material.Fabric },
				model
			),
			CFrame.new(x * 0.6, -2.8, 0)
		)
		attach(
			newPart({ Name = "Arm", Size = Vector3.new(0.6, 4.6, 0.6), Color = cloth, Material = Enum.Material.Fabric }, model),
			CFrame.new(x * 1.8, 0.2, -0.8) * CFrame.Angles(math.rad(-60), 0, x * math.rad(8))
		)
		for f = -1, 1 do
			attach(
				newPart({ Name = "Claw", Size = Vector3.new(0.15, 1.2, 0.15), Color = Color3.fromRGB(220, 210, 180) }, model),
				CFrame.new(x * 1.8 + f * 0.2, -1.1, -2.9) * CFrame.Angles(math.rad(-80), 0, 0)
			)
		end
		-- Straw sticking out
		attach(
			newPart({ Name = "Straw", Size = Vector3.new(0.1, 1.2, 0.1), Color = Color3.fromRGB(230, 200, 90) }, model),
			CFrame.new(x * 1.4, 2.2, 0) * CFrame.Angles(0, 0, x * 0.8)
		)
	end
	local head = attach(
		newPart({
			Name = "Head",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(3, 3, 3),
			Color = if isBloodMoon then Color3.fromRGB(150, 30, 20) else Color3.fromRGB(230, 110, 20),
		}, model),
		CFrame.new(0, 3.7, 0)
	)
	attach(newPart({ Name = "Stem", Size = Vector3.new(0.4, 0.8, 0.4), Color = Color3.fromRGB(60, 90, 30) }, model), CFrame.new(0, 5.4, 0))
	attach(
		newPart({ Name = "Hat", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 5, 5), Color = Color3.fromRGB(25, 20, 25) }, model),
		CFrame.new(0, 5.1, 0) * CFrame.Angles(0, 0, math.rad(90))
	)
	attach(
		newPart({ Name = "HatTop", Size = Vector3.new(2, 2.4, 2), Color = Color3.fromRGB(25, 20, 25) }, model),
		CFrame.new(0, 6.3, 0) * CFrame.Angles(0.2, 0, 0.15)
	)

	local eyeColor = if isBloodMoon then Color3.fromRGB(255, 30, 30) else Color3.fromRGB(255, 230, 60)
	local eyes = {}
	for _, x in { -0.6, 0.6 } do
		table.insert(
			eyes,
			attach(
				newPart({ Name = "Eye", Size = Vector3.new(0.7, 0.5, 0.2), Color = eyeColor, Material = Enum.Material.Neon }, model),
				CFrame.new(x, 4.05, -1.4)
			)
		)
	end
	attach(
		newPart({ Name = "Mouth", Size = Vector3.new(1.6, 0.35, 0.2), Color = eyeColor, Material = Enum.Material.Neon }, model),
		CFrame.new(0, 3.2, -1.38)
	)

	local light = Instance.new("PointLight")
	light.Color = eyeColor
	light.Range = 10
	light.Brightness = 2
	light.Parent = head

	return model, root, eyes
end

local function validTarget(player: Player)
	if player:GetAttribute("Downed") or player:GetAttribute("Dead") then
		return nil
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then
		return nil
	end
	return root
end

local function pickTarget(monster)
	local t = now()
	-- Haunted / tricked players are chased first, wherever they are.
	for player, untilTime in forcedTargets do
		if t > untilTime or not player.Parent then
			forcedTargets[player] = nil
		else
			local root = validTarget(player)
			if root and not World.IsSafe(root.Position) then
				return player, root, true
			end
		end
	end
	local best, bestRoot, bestDistance = nil, nil, math.huge
	for _, player in Players:GetPlayers() do
		local root = validTarget(player)
		if root and not World.IsSafe(root.Position) then
			local distance = (flat(root.Position) - monster.Position).Magnitude
			if distance < bestDistance then
				best, bestRoot, bestDistance = player, root, distance
			end
		end
	end
	return best, bestRoot, false
end

local function computePath(monster, goal: Vector3)
	if monster.Computing then
		return
	end
	monster.Computing = true
	task.spawn(function()
		local path = PathfindingService:CreatePath({ AgentRadius = 2.5, AgentHeight = 9, AgentCanJump = false })
		local ok = pcall(function()
			path:ComputeAsync(monster.Position + Vector3.new(0, 2, 0), goal + Vector3.new(0, 2, 0))
		end)
		if ok and path.Status == Enum.PathStatus.Success then
			local points = {}
			for _, waypoint in path:GetWaypoints() do
				table.insert(points, flat(waypoint.Position))
			end
			monster.Waypoints = points
			monster.WaypointIndex = 2
		else
			monster.Waypoints = nil
		end
		monster.LastPath = os.clock()
		monster.Computing = false
	end)
end

local function setEyes(monster, color: Color3)
	for _, eye in monster.Eyes do
		eye.Color = color
	end
end

local function step(monster, dt: number)
	local t = now()
	local speed = monster.Speed
	if World.Fuel <= 0 then
		speed *= Config.Monster.EnragedMultiplier
	end

	local goal
	if World.IsDaylight() then
		-- Hide at the edge of the map in daylight
		goal = monster.Home
		speed = Config.Monster.FleeSpeed
		monster.Target = nil
	elseif t < monster.StunnedUntil then
		local away = monster.Position.Magnitude > 1 and monster.Position.Unit or Vector3.new(1, 0, 0)
		goal = monster.Position + away * 20
		speed = Config.Monster.FleeSpeed
	elseif t < monster.PausedUntil then
		return
	else
		if monster.StunnedUntil > 0 and t >= monster.StunnedUntil then
			monster.StunnedUntil = 0
			setEyes(monster, monster.EyeColor)
		end
		local player, targetRoot, forced = pickTarget(monster)
		monster.Target = player
		if targetRoot then
			if forced then
				speed *= Config.Monster.HauntedMultiplier
			end
			local targetPos = flat(targetRoot.Position)
			if (targetPos - monster.Position).Magnitude < 14 then
				goal = targetPos
				monster.Waypoints = nil
			else
				if os.clock() - monster.LastPath > Config.Monster.RepathInterval then
					computePath(monster, targetPos)
				end
				if monster.Waypoints and monster.Waypoints[monster.WaypointIndex] then
					goal = monster.Waypoints[monster.WaypointIndex]
				else
					goal = targetPos
				end
			end
		else
			-- Nobody to hunt: prowl around the edge of the light
			if not monster.WanderGoal or (monster.WanderGoal - monster.Position).Magnitude < 3 then
				local angle = rng:NextNumber(0, math.pi * 2)
				local radius = World.SafeRadius() + rng:NextNumber(8, 25)
				monster.WanderGoal = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
			end
			goal = monster.WanderGoal
			speed *= 0.6
		end
	end

	local offset = goal - monster.Position
	local distance = offset.Magnitude
	if distance > 0.05 then
		local direction = offset.Unit
		local move = math.min(distance, speed * dt)
		local nextPos = monster.Position + direction * move
		-- The light keeps it out
		local safe = World.SafeRadius()
		if safe > 0 and nextPos.Magnitude < safe + 1.5 then
			nextPos = (if nextPos.Magnitude > 0.1 then nextPos.Unit else Vector3.new(1, 0, 0)) * (safe + 1.5)
		end
		-- Stay inside the map
		if nextPos.Magnitude > World.MapRadius - 4 then
			nextPos = nextPos.Unit * (World.MapRadius - 4)
		end
		monster.Position = nextPos
		monster.Facing = direction
		if monster.Waypoints and goal == monster.Waypoints[monster.WaypointIndex] and (goal - nextPos).Magnitude < 1.5 then
			monster.WaypointIndex += 1
		end
	end
	local pivot = monster.Position + Vector3.new(0, HEIGHT, 0)
	local bob = math.sin(os.clock() * 8) * 0.15
	monster.Model:PivotTo(CFrame.lookAt(pivot + Vector3.new(0, bob, 0), pivot + monster.Facing))

	-- Catching players
	if World.IsDaylight() or t < monster.StunnedUntil then
		return
	end
	for _, player in Players:GetPlayers() do
		local root = validTarget(player)
		if root and not World.IsSafe(root.Position) then
			if
				(flat(root.Position) - monster.Position).Magnitude < Config.Monster.KillRange
				and math.abs(root.Position.Y - pivot.Y) < 8
			then
				monster.PausedUntil = t + Config.Monster.PauseAfterHit
				forcedTargets[player] = nil
				if MonsterService.OnCatch then
					MonsterService.OnCatch(player)
				end
			end
		end
	end
end

function MonsterService.Spawn(isBloodMoon: boolean, nightIndex: number)
	local model, root, eyes = buildModel(isBloodMoon)
	local angle = rng:NextNumber(0, math.pi * 2)
	local home = Vector3.new(math.cos(angle), 0, math.sin(angle)) * (World.MapRadius - 15)
	local monster = {
		Model = model,
		Root = root,
		Eyes = eyes,
		EyeColor = eyes[1].Color,
		Home = home,
		Position = home,
		Facing = -home.Unit,
		Speed = Config.Monster.BaseSpeed + Config.Monster.SpeedPerNight * (nightIndex - 1),
		StunMeter = 0,
		StunnedUntil = 0,
		PausedUntil = 0,
		LastPath = 0,
		Computing = false,
	}
	model:PivotTo(CFrame.lookAt(home + Vector3.new(0, HEIGHT, 0), Vector3.new(0, HEIGHT, 0)))
	model.Parent = workspace:WaitForChild("Monsters")
	table.insert(monsters, monster)
	return monster
end

function MonsterService.DespawnAll()
	for _, monster in monsters do
		monster.Model:Destroy()
	end
	table.clear(monsters)
	table.clear(forcedTargets)
end

function MonsterService.ForceTarget(player: Player, seconds: number)
	forcedTargets[player] = math.max(forcedTargets[player] or 0, now()) + seconds
end

function MonsterService.Count(): number
	return #monsters
end

-- Called by PlayerService while a player's lantern is on. Returns true if this light scared a monster away.
function MonsterService.ApplyLight(player: Player, origin: Vector3, direction: Vector3, range: number, dt: number): boolean
	local scared = false
	local cosCone = math.cos(math.rad(Config.Flashlight.ConeDegrees))
	for _, monster in monsters do
		if now() >= monster.StunnedUntil then
			local center = monster.Position + Vector3.new(0, HEIGHT + 1, 0)
			local toMonster = center - origin
			local distance = toMonster.Magnitude
			local lit = false
			if distance < range and distance > 0.1 and toMonster.Unit:Dot(direction) > cosCone then
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = { player.Character, monster.Model, workspace:WaitForChild("Pickups") }
				lit = workspace:Raycast(origin, toMonster, params) == nil
			end
			if lit then
				monster.StunMeter += dt
				if monster.StunMeter >= Config.Monster.StunNeeded then
					monster.StunMeter = 0
					monster.StunnedUntil = now() + Config.Monster.StunTime
					monster.Waypoints = nil
					setEyes(monster, Color3.new(1, 1, 1))
					scared = true
				end
			end
		end
	end
	return scared
end

function MonsterService.Init()
	RunService.Heartbeat:Connect(function(dt)
		for _, monster in monsters do
			monster.StunMeter = math.max(0, monster.StunMeter - dt * 0.25)
			local ok, err = pcall(step, monster, dt)
			if not ok then
				warn("[MonsterService] step error:", err)
			end
		end
	end)
end

return MonsterService
