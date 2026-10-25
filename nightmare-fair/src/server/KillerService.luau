-- The killer: costume, attacks, the three killer powers, pallets and stuns.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Cosmetics = require(Shared.Cosmetics)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local Match = require(script.Parent.Match)
local SurvivorService = require(script.Parent.SurvivorService)

local KillerService = {}
KillerService.OnPalletDropped = nil -- set by BotKiller: function(position, survivor)
KillerService.Dress = nil -- assigned below

local state = {
	StunnedUntil = 0,
	FrozenUntil = 0,
	SlowedUntil = 0,
	ChargeUntil = 0,
	VanishUntil = 0,
	ChargeHit = false,
	Traps = {},
	Saved = {},
}

local function now()
	return Match.Now()
end

local function isKiller(player: Player)
	return player == Match.Killer and Match.Role(player) == "Killer"
end

-- Costumes ---------------------------------------------------------------

local function weld(part: BasePart, to: BasePart, offset: CFrame, parent: Instance)
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CFrame = to.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = part
	w.Parent = part
	part.Parent = parent
	return part
end

local function newPart(props)
	local part = Instance.new("Part")
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		part[key] = value
	end
	return part
end

-- Dresses a killer body. `player` (optional) is whose equipped skin to use; the AI killer has none.
local function dressKiller(character: Model?, killerType: string, player: Player?)
	local head = character and character:FindFirstChild("Head")
	local hand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"))
	if not head or not hand then
		return
	end
	local old = character:FindFirstChild("KillerCostume")
	if old then
		old:Destroy()
	end
	local costume = Instance.new("Folder")
	costume.Name = "KillerCostume"
	costume.Parent = character

	local info = Config.Killers[killerType]
	if killerType == "Ringmaster" then
		local mask = weld(
			newPart({ Name = "Mask", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.6, 1.3), Color = Color3.fromRGB(240, 235, 230) }),
			head,
			CFrame.new(0, 0.05, -0.2),
			costume
		)
		weld(
			newPart({
				Name = "Smile",
				Size = Vector3.new(0.9, 0.15, 0.1),
				Color = Color3.fromRGB(200, 20, 30),
				Material = Enum.Material.Neon,
			}),
			mask,
			CFrame.new(0, -0.35, -0.62),
			costume
		)
		weld(
			newPart({
				Name = "HatBrim",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.2, 2.4, 2.4),
				Color = Color3.fromRGB(20, 15, 20),
			}),
			head,
			CFrame.new(0, 0.75, 0) * CFrame.Angles(0, 0, math.rad(90)),
			costume
		)
		weld(
			newPart({ Name = "Hat", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.8, 1.5, 1.5), Color = Color3.fromRGB(20, 15, 20) }),
			head,
			CFrame.new(0, 1.7, 0) * CFrame.Angles(0, 0, math.rad(90)),
			costume
		)
		weld(
			newPart({ Name = "HatBand", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 1.55, 1.55), Color = info.Color }),
			head,
			CFrame.new(0, 1.05, 0) * CFrame.Angles(0, 0, math.rad(90)),
			costume
		)
		weld(
			newPart({ Name = "Whip", Size = Vector3.new(0.25, 0.25, 4.5), Color = Color3.fromRGB(60, 35, 25) }),
			hand,
			CFrame.new(0, -0.6, -2),
			costume
		)
	elseif killerType == "Butcher" then
		local mask = weld(
			newPart({
				Name = "Sack",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(1.6, 1.8, 1.6),
				Color = Color3.fromRGB(150, 115, 75),
				Material = Enum.Material.Fabric,
			}),
			head,
			CFrame.new(0, 0.1, 0),
			costume
		)
		for _, x in { -0.28, 0.28 } do
			weld(
				newPart({
					Name = "EyeHole",
					Size = Vector3.new(0.22, 0.22, 0.1),
					Color = Color3.fromRGB(255, 50, 30),
					Material = Enum.Material.Neon,
				}),
				mask,
				CFrame.new(x, 0.15, -0.78),
				costume
			)
		end
		weld(
			newPart({ Name = "Stitch", Size = Vector3.new(0.8, 0.08, 0.1), Color = Color3.fromRGB(40, 25, 20) }),
			mask,
			CFrame.new(0, -0.35, -0.78),
			costume
		)
		weld(
			newPart({ Name = "Handle", Size = Vector3.new(0.3, 1.2, 0.3), Color = Color3.fromRGB(60, 35, 25) }),
			hand,
			CFrame.new(0, -1, -0.3),
			costume
		)
		weld(
			newPart({
				Name = "Cleaver",
				Size = Vector3.new(0.12, 1.4, 2.2),
				Color = Color3.fromRGB(180, 180, 190),
				Material = Enum.Material.Metal,
				Reflectance = 0.2,
			}),
			hand,
			CFrame.new(0, -1.9, -0.9),
			costume
		)
	else
		local mask = weld(
			newPart({
				Name = "Porcelain",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(1.35, 1.6, 1.2),
				Color = Color3.fromRGB(245, 245, 255),
				Material = Enum.Material.Glass,
			}),
			head,
			CFrame.new(0, 0.05, -0.25),
			costume
		)
		for _, x in { -0.28, 0.28 } do
			weld(
				newPart({ Name = "Eye", Size = Vector3.new(0.25, 0.12, 0.1), Color = info.Color, Material = Enum.Material.Neon }),
				mask,
				CFrame.new(x, 0.15, -0.6),
				costume
			)
		end
		weld(
			newPart({
				Name = "Hood",
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(2, 2.2, 2),
				Color = Color3.fromRGB(20, 20, 30),
				Material = Enum.Material.Fabric,
			}),
			head,
			CFrame.new(0, 0.25, 0.35),
			costume
		)
		weld(
			newPart({ Name = "Shaft", Size = Vector3.new(0.25, 6, 0.25), Color = Color3.fromRGB(40, 40, 50) }),
			hand,
			CFrame.new(0, 1.5, -0.3),
			costume
		)
		weld(
			newPart({ Name = "Blade", Size = Vector3.new(0.12, 0.8, 3), Color = info.Color, Material = Enum.Material.Neon }),
			hand,
			CFrame.new(0, 4.3, -1.6),
			costume
		)
	end
	-- Equipped killer skin recolors the mask and glowing accents
	local skinId = player and player:GetAttribute("Skin_" .. killerType)
	local skin = skinId and player:GetAttribute("Owned_" .. skinId) and Cosmetics.ById[skinId]
	local accent = if skin then skin.Accent else info.Color
	if skin then
		for _, part in costume:GetChildren() do
			if part.Name == "Mask" or part.Name == "Sack" or part.Name == "Porcelain" then
				part.Color = skin.Mask
				part.Material = skin.Material
			elseif
				part.Name == "HatBand"
				or part.Name == "Smile"
				or part.Name == "EyeHole"
				or part.Name == "Eye"
				or part.Name == "Blade"
			then
				part.Color = accent
			end
		end
	end
	local eyesLight = Instance.new("PointLight")
	eyesLight.Color = accent
	eyesLight.Range = 10
	eyesLight.Brightness = 1.5
	eyesLight.Parent = head

	local reveal = Instance.new("Highlight")
	reveal.Name = "RevealHighlight"
	reveal.FillColor = Color3.fromRGB(255, 40, 40)
	reveal.OutlineColor = Color3.fromRGB(255, 120, 120)
	reveal.FillTransparency = 0.5
	reveal.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	reveal.Enabled = false
	reveal.Parent = character
end

KillerService.Dress = dressKiller

-- Phantom invisibility ---------------------------------------------------

local function setVanished(player: Player, vanished: boolean)
	local character = player.Character
	if not character then
		return
	end
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			if vanished then
				state.Saved[d] = d.Transparency
				d.Transparency = 1
			elseif state.Saved[d] ~= nil then
				d.Transparency = state.Saved[d]
			end
		elseif d:IsA("PointLight") then
			d.Enabled = not vanished
		end
	end
	if not vanished then
		table.clear(state.Saved)
	end
	player:SetAttribute("Vanished", vanished or nil)
end

-- Core actions ------------------------------------------------------------

function KillerService.Stun(seconds: number, reason: string)
	local killer = Match.Killer
	if not killer then
		return
	end
	state.StunnedUntil = math.max(state.StunnedUntil, now() + seconds)
	state.ChargeUntil = 0
	if state.VanishUntil > now() then
		state.VanishUntil = 0
		setVanished(killer, false)
	end
	local survivor = SurvivorService.CarriedBy(killer)
	if survivor then
		SurvivorService.Drop(survivor, "Injured")
		Remotes.notify(survivor, "You fell free! RUN!", "success")
	end
	Remotes.notify(killer, "💫 Stunned by " .. reason .. "!", "error")
end

function KillerService.Freeze(seconds: number)
	state.FrozenUntil = now() + seconds
end

local function landHit(killer: Player, victim: Player)
	local result = SurvivorService.Hit(victim)
	if not result then
		return
	end
	state.SlowedUntil = now() + Config.Speeds.KillerAfterHitTime
	local reward = if result == "Downed" then Config.Rewards.KillerDown else Config.Rewards.KillerHit
	local earned = DataService.AddTickets(killer, reward, true)
	Remotes.notify(
		killer,
		(if result == "Downed" then "🩸 Downed " else "🔪 Hit ") .. victim.DisplayName .. "! +" .. earned .. " 🎟️",
		"success"
	)
end

local function attack(killer: Player)
	if not isKiller(killer) or not Match.Active then
		return
	end
	local t = now()
	if t < (killer:GetAttribute("AttackReadyAt") or 0) or t < state.StunnedUntil or t < state.FrozenUntil then
		return
	end
	if SurvivorService.CarriedBy(killer) then
		return
	end
	if state.VanishUntil > t then
		-- Attacking ends the vanish (reveal first, then you can swing)
		state.VanishUntil = 0
		setVanished(killer, false)
		killer:SetAttribute("AttackReadyAt", t + 0.4)
		return
	end
	killer:SetAttribute("AttackReadyAt", t + Config.Attack.Cooldown)
	local root = Match.Root(killer)
	if not root then
		return
	end
	Remotes.Swing:FireAllClients(killer.UserId)

	local best, bestDistance = nil, math.huge
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	for _, survivor in Match.Survivors() do
		local health = Match.Health(survivor)
		local sroot = Match.Root(survivor)
		if sroot and (health == "Healthy" or health == "Injured") then
			local offset = sroot.Position - root.Position
			local flat = Vector3.new(offset.X, 0, offset.Z)
			local distance = flat.Magnitude
			if
				distance < Config.Attack.Range
				and math.abs(offset.Y) < 6
				and (distance < 2 or flat.Unit:Dot(root.CFrame.LookVector) > Config.Attack.ArcDot)
			then
				params.FilterDescendantsInstances = { killer.Character, survivor.Character }
				if not workspace:Raycast(root.Position, offset, params) and distance < bestDistance then
					best, bestDistance = survivor, distance
				end
			end
		end
	end
	if best then
		landHit(killer, best)
	else
		state.SlowedUntil = now() + 0.6 -- a whiff is punished a little
	end
end

local function placeTrap(killer: Player, info)
	local root = Match.Root(killer)
	if not root then
		return false
	end
	local ground = root.Position - Vector3.new(0, 2.9, 0)
	local trap = Instance.new("Model")
	trap.Name = "BearTrap"
	local base = newPart({
		Name = "Base",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 3.2, 3.2),
		CFrame = CFrame.new(ground) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(60, 55, 55),
		Material = Enum.Material.CorrodedMetal,
		Anchored = true,
		CanCollide = false,
	})
	base.Parent = trap
	for _, side in { -1, 1 } do
		local jaw = newPart({
			Name = "Jaw",
			Size = Vector3.new(3, 0.6, 0.2),
			CFrame = CFrame.new(ground + Vector3.new(0, 0.4, side * 1.2)) * CFrame.Angles(math.rad(side * 40), 0, 0),
			Color = Color3.fromRGB(120, 115, 110),
			Material = Enum.Material.Metal,
			Anchored = true,
			CanCollide = false,
			CanTouch = false,
		})
		jaw.Parent = trap
	end
	trap.Parent = workspace
	table.insert(state.Traps, trap)
	if #state.Traps > info.MaxTraps then
		table.remove(state.Traps, 1):Destroy()
	end
	local sprung = false
	base.Touched:Connect(function(hit)
		local survivor = Match.PlayerFromHit(hit)
		if sprung or not survivor or not Match.IsStandingSurvivor(survivor) then
			return
		end
		sprung = true
		local index = table.find(state.Traps, trap)
		if index then
			table.remove(state.Traps, index)
		end
		trap:Destroy()
		local untilTime = now() + info.TrapTime
		survivor:SetAttribute("TrappedUntil", untilTime)
		survivor:SetAttribute("WorkingOn", nil)
		Match.SetSpeed(survivor, 0)
		Remotes.Scare:FireClient(survivor, "trap")
		Remotes.notify(survivor, "🪤 You stepped in a bear trap!", "error")
		if Match.Killer then
			Remotes.notify(Match.Killer, "🪤 " .. survivor.DisplayName .. " is caught in a trap!", "success")
			local sroot = Match.Root(survivor)
			if sroot then
				Remotes.Ping:FireClient(Match.Killer, sroot.Position, "trap")
			end
		end
		task.delay(info.TrapTime, function()
			if survivor:GetAttribute("TrappedUntil") == untilTime then
				survivor:SetAttribute("TrappedUntil", nil)
				if Match.IsStandingSurvivor(survivor) then
					SurvivorService.SetHealth(survivor, Match.Health(survivor))
				end
			end
		end)
	end)
	return true
end

local function useAbility(killer: Player)
	if not isKiller(killer) or not Match.Active then
		return
	end
	local t = now()
	if t < (killer:GetAttribute("AbilityReadyAt") or 0) or t < state.StunnedUntil or t < state.FrozenUntil then
		return
	end
	local killerType = Match.KillerType
	local info = Config.Killers[killerType]
	local used = false
	if killerType == "Ringmaster" then
		used = placeTrap(killer, info)
	elseif killerType == "Butcher" then
		if not SurvivorService.CarriedBy(killer) then
			state.ChargeUntil = t + info.ChargeTime
			state.ChargeHit = false
			used = true
		end
	elseif killerType == "Phantom" then
		if not SurvivorService.CarriedBy(killer) then
			state.VanishUntil = t + info.VanishTime
			setVanished(killer, true)
			used = true
		end
	end
	if used then
		killer:SetAttribute("AbilityReadyAt", t + info.Cooldown)
	end
end

-- Pallets -----------------------------------------------------------------

local function setupPallets()
	for _, spot in Match.Map.Pallets do
		spot.State = "Standing"
		local pallet = spot.Pallet
		spot.SlatOffsets = {}
		for _, slat in spot.Model:GetChildren() do
			if slat.Name == "Slat" then
				spot.SlatOffsets[slat] = spot.Standing:ToObjectSpace(slat.CFrame)
			end
		end
		spot.DropPrompt = Match.Prompt(pallet, "DropPrompt", "Survivor", "Drop pallet", "", 0, 9)
		spot.BreakPrompt = Match.Prompt(pallet, "BreakPrompt", "Killer", "Break pallet", "", Config.Pallet.BreakTime, 9)
		spot.BreakPrompt.Enabled = false
		spot.DropPrompt.Triggered:Connect(function(survivor)
			if spot.State ~= "Standing" or not Match.IsStandingSurvivor(survivor) then
				return
			end
			spot.State = "Dropped"
			spot.DropPrompt.Enabled = false
			spot.BreakPrompt.Enabled = true
			TweenService:Create(pallet, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = spot.Dropped })
				:Play()
			for slat, offset in spot.SlatOffsets do
				TweenService:Create(slat, TweenInfo.new(0.25), { CFrame = spot.Dropped * offset }):Play()
			end
			task.delay(0.2, function()
				pallet.CanCollide = true
			end)
			local killerRoot = Match.Killer and Match.Root(Match.Killer)
			if killerRoot and (killerRoot.Position - spot.Dropped.Position).Magnitude < Config.Pallet.StunRadius then
				KillerService.Stun(Config.Pallet.StunTime, "a pallet")
				local earned = DataService.AddTickets(survivor, Config.Rewards.PalletStun, true)
				Remotes.notify(survivor, "💥 PALLET STUN! +" .. earned .. " 🎟️", "success")
			elseif KillerService.OnPalletDropped then
				KillerService.OnPalletDropped(spot.Dropped.Position, survivor)
			end
		end)
		spot.BreakPrompt.Triggered:Connect(function(killer)
			if spot.State ~= "Dropped" or not isKiller(killer) then
				return
			end
			spot.State = "Broken"
			spot.BreakPrompt.Enabled = false
			pallet.CanCollide = false
			pallet.Transparency = 1
			for _, slat in spot.Model:GetChildren() do
				if slat.Name == "Slat" then
					slat.Transparency = 1
				end
			end
		end)
	end
end

local function resetPallets()
	for _, spot in Match.Map.Pallets do
		spot.State = "Standing"
		spot.Pallet.CFrame = spot.Standing
		spot.Pallet.CanCollide = false
		spot.Pallet.Transparency = 0
		for slat, offset in spot.SlatOffsets do
			slat.CFrame = spot.Standing * offset
			slat.Transparency = 0
		end
		spot.DropPrompt.Enabled = true
		spot.BreakPrompt.Enabled = false
	end
end

-- Match lifecycle ---------------------------------------------------------

function KillerService.Setup(player: Player, killerType: string)
	player:SetAttribute("Role", "Killer")
	player:SetAttribute("KillerType", killerType)
	player:SetAttribute("AttackReadyAt", 0)
	player:SetAttribute("AbilityReadyAt", 0)
	local character = player.Character
	if character then
		Match.SetCollisionGroup(character, "Players")
	end
	dressKiller(player.Character, killerType, player)
end

function KillerService.Reveal(seconds: number)
	local killer = Match.Killer
	local character = if killer then killer.Character else Match.BotModel
	local highlight = character and character:FindFirstChild("RevealHighlight")
	if highlight then
		highlight.Enabled = true
		task.delay(seconds, function()
			if highlight.Parent then
				highlight.Enabled = false
			end
		end)
	end
end

function KillerService.Reset()
	for _, trap in state.Traps do
		trap:Destroy()
	end
	table.clear(state.Traps)
	if Match.Killer and state.VanishUntil > now() then
		setVanished(Match.Killer, false)
	end
	state.StunnedUntil, state.FrozenUntil, state.SlowedUntil, state.ChargeUntil, state.VanishUntil = 0, 0, 0, 0, 0
	if Match.Map then
		resetPallets()
	end
end

local function tick()
	local killer = Match.Killer
	if not killer or not Match.Active or not isKiller(killer) then
		return
	end
	local t = now()
	local info = Config.Killers[Match.KillerType]
	local speed = Config.Speeds.Killer
	if state.VanishUntil > 0 and t >= state.VanishUntil then
		state.VanishUntil = 0
		setVanished(killer, false)
	end
	if t < state.StunnedUntil or t < state.FrozenUntil then
		speed = 0
	elseif t < state.ChargeUntil then
		speed = info.ChargeSpeed
		local root = Match.Root(killer)
		if root and not state.ChargeHit then
			for _, survivor in Match.Survivors() do
				local sroot = Match.Root(survivor)
				if sroot and Match.IsStandingSurvivor(survivor) and (sroot.Position - root.Position).Magnitude < 5 then
					state.ChargeHit = true
					state.ChargeUntil = 0
					landHit(killer, survivor)
					break
				end
			end
		end
	elseif t < state.VanishUntil then
		speed = info.VanishSpeed
	elseif t < state.SlowedUntil then
		speed = Config.Speeds.KillerAfterHit
	elseif SurvivorService.CarriedBy(killer) then
		speed = Config.Speeds.KillerCarrying
	end
	Match.SetSpeed(killer, speed)
	killer:SetAttribute("StunnedUntil", state.StunnedUntil)
end

function KillerService.Init()
	setupPallets()
	Remotes.Attack.OnServerEvent:Connect(attack)
	Remotes.Ability.OnServerEvent:Connect(useAbility)
	task.spawn(function()
		while true do
			task.wait(0.1)
			local ok, err = pcall(tick)
			if not ok then
				warn("[KillerService] tick error:", err)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		if player == Match.Killer then
			KillerService.Reset()
		end
	end)
end

return KillerService
