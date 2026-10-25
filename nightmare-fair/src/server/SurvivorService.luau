-- Survivors: health states, healing, being carried, Crow Cages, rescues, elimination, escape and ghosts.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local Match = require(script.Parent.Match)

local SurvivorService = {}
SurvivorService.OnCarryChanged = nil -- set by KillerService: function(killer)

local carried = {} -- [survivor] = { Killer, Weld, EndsAt, Saved }
local caged = {} -- [survivor] = cage
local boostToken = {}

local function now()
	return Match.Now()
end

-- The carrier is either the killer Player or the AI killer (a table with a Root part).
local function isPlayer(carrier): boolean
	return typeof(carrier) == "Instance" and carrier:IsA("Player")
end

local function carrierRoot(carrier): BasePart?
	if isPlayer(carrier) then
		return Match.Root(carrier)
	end
	return carrier and carrier.Root
end

local function prompt(player: Player, name: string)
	local root = Match.Root(player)
	return root and root:FindFirstChild(name)
end

local function refreshPrompts(player: Player)
	local health = Match.Health(player)
	local isSurvivor = Match.Role(player) == "Survivor"
	local heal = prompt(player, "HealPrompt")
	if heal then
		heal.Enabled = isSurvivor and (health == "Injured" or health == "Downed")
		heal.ActionText = if health == "Downed" then "Help up" else "Heal"
	end
	local pickup = prompt(player, "PickupPrompt")
	if pickup then
		pickup.Enabled = isSurvivor and health == "Downed"
	end
end

local function baseSpeed(player: Player): number
	local health = Match.Health(player)
	if health == "Downed" then
		return Config.Speeds.Crawl
	elseif health == "Injured" then
		return Config.Speeds.Injured
	end
	return Config.Speeds.Survivor
end

function SurvivorService.SetHealth(player: Player, health: string?)
	player:SetAttribute("Health", health)
	refreshPrompts(player)
	if health == "Healthy" or health == "Injured" or health == "Downed" then
		if not player:GetAttribute("TrappedUntil") or now() > player:GetAttribute("TrappedUntil") then
			Match.SetSpeed(player, baseSpeed(player))
		end
	end
end

-- Called when a character spawns into the match as a survivor.
function SurvivorService.Setup(player: Player)
	local root = Match.Root(player)
	if not root then
		return
	end
	for _, name in { "HealPrompt", "PickupPrompt" } do
		local old = root:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	local heal = Match.Prompt(root, "HealPrompt", "Survivor", "Heal", player.DisplayName, Config.Heal.HoldTime, 7)
	heal:SetAttribute("OwnerId", player.UserId)
	heal.Triggered:Connect(function(healer)
		if healer == player or not Match.IsStandingSurvivor(healer) then
			return
		end
		local health = Match.Health(player)
		if health == "Downed" then
			SurvivorService.SetHealth(player, "Injured")
		elseif health == "Injured" then
			SurvivorService.SetHealth(player, "Healthy")
		else
			return
		end
		local earned = DataService.AddTickets(healer, Config.Rewards.Heal, true)
		Remotes.notify(healer, "💉 You helped " .. player.DisplayName .. "! +" .. earned .. " 🎟️", "success")
		Remotes.notify(player, "💉 " .. healer.DisplayName .. " patched you up.", "success")
	end)

	local pickup = Match.Prompt(root, "PickupPrompt", "Killer", "Pick up", player.DisplayName, 0.4, 7)
	pickup:SetAttribute("OwnerId", player.UserId)
	pickup.Triggered:Connect(function(killer)
		if killer == Match.Killer and Match.Health(player) == "Downed" then
			SurvivorService.Pickup(killer, player)
		end
	end)

	local character = player.Character
	if character then
		Match.SetCollisionGroup(character, "Players")
	end
	SurvivorService.SetHealth(player, Match.Health(player) or "Healthy")
end

-- The killer landed a hit. Returns the new health state.
function SurvivorService.Hit(player: Player): string?
	local health = Match.Health(player)
	player:SetAttribute("WorkingOn", nil)
	if health == "Healthy" then
		SurvivorService.SetHealth(player, "Injured")
		-- Burst of speed so the survivor can get away
		boostToken[player] = (boostToken[player] or 0) + 1
		local token = boostToken[player]
		Match.SetSpeed(player, Config.Speeds.HitBoost)
		task.delay(Config.Speeds.HitBoostTime, function()
			if boostToken[player] == token and Match.Health(player) == "Injured" then
				Match.SetSpeed(player, baseSpeed(player))
			end
		end)
		Remotes.Scare:FireClient(player, "hit")
		return "Injured"
	elseif health == "Injured" then
		SurvivorService.SetHealth(player, "Downed")
		Remotes.Scare:FireClient(player, "down")
		for _, other in Match.Survivors() do
			if other ~= player then
				Remotes.notify(other, "🆘 " .. player.DisplayName .. " is down!", "error")
			end
		end
		return "Downed"
	end
	return nil
end

local function setCarryPhysics(player: Player, on: boolean, saved)
	local character = player.Character
	if not character then
		return saved
	end
	saved = saved or {}
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			if on then
				saved[part] = { part.Massless, part.CanCollide }
				part.Massless = true
				part.CanCollide = false
			elseif saved[part] then
				part.Massless = saved[part][1]
				part.CanCollide = saved[part][2]
			end
		end
	end
	local humanoid = Match.Humanoid(player)
	if humanoid then
		humanoid.PlatformStand = on
	end
	return saved
end

function SurvivorService.CarriedBy(killer: Player): Player?
	for survivor, info in carried do
		if info.Killer == killer then
			return survivor
		end
	end
	return nil
end

function SurvivorService.Pickup(killer: Player, survivor: Player)
	if SurvivorService.CarriedBy(killer) then
		return
	end
	local killerRoot, root = carrierRoot(killer), Match.Root(survivor)
	if not killerRoot or not root or (killerRoot.Position - root.Position).Magnitude > 10 then
		return
	end
	SurvivorService.SetHealth(survivor, "Carried")
	local saved = setCarryPhysics(survivor, true)
	root.CFrame = killerRoot.CFrame * CFrame.new(1.3, 1.6, 0.4) * CFrame.Angles(0, 0, math.rad(90))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = killerRoot
	weld.Part1 = root
	weld.Parent = killerRoot
	carried[survivor] = { Killer = killer, Weld = weld, EndsAt = now() + Config.Cage.WiggleTime, Saved = saved }
	survivor:SetAttribute("WiggleEndsAt", now() + Config.Cage.WiggleTime)
	Remotes.notify(survivor, "😱 You're being carried! You'll wiggle free in " .. Config.Cage.WiggleTime .. "s...", "error")
	if isPlayer(killer) then
		Remotes.notify(killer, "Bring them to a 🐦‍⬛ Crow Cage!", "info")
	end
	if SurvivorService.OnCarryChanged then
		SurvivorService.OnCarryChanged(killer)
	end
end

-- Drops a carried survivor. newHealth is usually "Injured" (wiggled free / killer stunned).
function SurvivorService.Drop(survivor: Player, newHealth: string?)
	local info = carried[survivor]
	if not info then
		return
	end
	carried[survivor] = nil
	info.Weld:Destroy()
	setCarryPhysics(survivor, false, info.Saved)
	survivor:SetAttribute("WiggleEndsAt", nil)
	local root, killerRoot = Match.Root(survivor), carrierRoot(info.Killer)
	if root then
		if killerRoot then
			root.CFrame = killerRoot.CFrame * CFrame.new(0, 0, 3)
		end
		pcall(root.SetNetworkOwner, root, survivor)
	end
	if newHealth then
		SurvivorService.SetHealth(survivor, newHealth)
	end
	if SurvivorService.OnCarryChanged then
		SurvivorService.OnCarryChanged(info.Killer)
	end
end

local function cageFor(survivor: Player)
	return caged[survivor]
end

function SurvivorService.Eliminate(survivor: Player, reason: string?)
	if Match.Role(survivor) ~= "Survivor" then
		return
	end
	SurvivorService.Drop(survivor)
	local cage = cageFor(survivor)
	if cage then
		caged[survivor] = nil
		cage.Occupant = nil
		cage.RescuePrompt.Enabled = false
		cage.Light.Color = Color3.fromRGB(255, 40, 40)
	end
	survivor:SetAttribute("WorkingOn", nil)
	survivor:SetAttribute("CageEndsAt", nil)
	SurvivorService.SetHealth(survivor, nil)
	survivor:SetAttribute("Role", "Ghost")
	DataService.AddTickets(survivor, Config.Rewards.Participation, true)

	local killer = Match.Killer
	if killer and killer.Parent then
		local earned = DataService.AddTickets(killer, Config.Rewards.KillerElimination, true)
		DataService.Increment(killer, "Eliminations")
		Remotes.notify(killer, "☠️ " .. survivor.DisplayName .. " was taken by the crows! +" .. earned .. " 🎟️", "success")
	end
	Remotes.announce(
		"🐦‍⬛ " .. survivor.DisplayName .. " was taken by the crows" .. (if reason then " (" .. reason .. ")" else "") .. ".",
		Color3.fromRGB(255, 80, 80)
	)
	SurvivorService.MakeGhost(survivor)
end

function SurvivorService.MakeGhost(player: Player)
	local character = player.Character
	local root = Match.Root(player)
	if not character or not root then
		return
	end
	root.Anchored = false
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Transparency = math.max(part.Transparency, 0.6)
		elseif part:IsA("Decal") then
			part.Transparency = 0.6
		end
	end
	Match.SetCollisionGroup(character, "Ghosts")
	local glow = Instance.new("Highlight")
	glow.Name = "GhostGlow"
	glow.FillColor = Color3.fromRGB(150, 200, 255)
	glow.FillTransparency = 0.6
	glow.OutlineTransparency = 1
	glow.DepthMode = Enum.HighlightDepthMode.Occluded
	glow.Parent = character
	Match.SetSpeed(player, Config.Speeds.Ghost)
	for _, name in { "HealPrompt", "PickupPrompt" } do
		local p = root:FindFirstChild(name)
		if p then
			p.Enabled = false
		end
	end
	Remotes.notify(player, "👻 You're a ghost now. Ring the 🔔 Ghost Bells to reveal the killer to your friends!", "info")
end

function SurvivorService.Escape(survivor: Player)
	if not Match.IsStandingSurvivor(survivor) then
		return
	end
	survivor:SetAttribute("WorkingOn", nil)
	SurvivorService.SetHealth(survivor, nil)
	survivor:SetAttribute("Role", "Escaped")
	DataService.Increment(survivor, "Escapes")
	local earned = DataService.AddTickets(survivor, Config.Rewards.Escape, true)
	Remotes.notify(survivor, "🏃 YOU ESCAPED THE FAIR! +" .. earned .. " 🎟️", "success")
	Remotes.announce("🏃 " .. survivor.DisplayName .. " escaped!", Color3.fromRGB(120, 255, 150))
	local character = survivor.Character
	if character and Match.Map then
		character:PivotTo(Match.Map.LobbySpawn)
	end
end

function SurvivorService.CageSurvivor(killer: Player, cage)
	local survivor = SurvivorService.CarriedBy(killer)
	if not survivor or cage.Occupant then
		return
	end
	SurvivorService.Drop(survivor)
	local root = Match.Root(survivor)
	if not root then
		return
	end
	local count = (survivor:GetAttribute("CageCount") or 0) + 1
	survivor:SetAttribute("CageCount", count)
	cage.Occupant = survivor
	caged[survivor] = cage
	root.CFrame = cage.Inside
	root.Anchored = true
	SurvivorService.SetHealth(survivor, "Caged")
	cage.Light.Color = Color3.fromRGB(255, 200, 60)

	if isPlayer(killer) then
		local earned = DataService.AddTickets(killer, Config.Rewards.KillerCage, true)
		Remotes.notify(killer, "🐦‍⬛ Caged " .. survivor.DisplayName .. "! +" .. earned .. " 🎟️", "success")
	end
	if count > #Config.Cage.Stages then
		SurvivorService.Eliminate(survivor, "caged 3 times")
		return
	end
	survivor:SetAttribute("CageEndsAt", now() + Config.Cage.Stages[count])
	cage.RescuePrompt.Enabled = true
	Remotes.Scare:FireClient(survivor, "cage")
	for _, other in Match.Survivors() do
		if other ~= survivor then
			Remotes.notify(other, "🐦‍⬛ " .. survivor.DisplayName .. " is in a Crow Cage! Rescue them!", "error")
			Remotes.Ping:FireClient(other, cage.Position, "rescue")
		end
	end
end

function SurvivorService.FreeFromCage(survivor: Player)
	local cage = caged[survivor]
	if not cage then
		return false
	end
	caged[survivor] = nil
	cage.Occupant = nil
	cage.RescuePrompt.Enabled = false
	cage.Light.Color = Color3.fromRGB(255, 40, 40)
	survivor:SetAttribute("CageEndsAt", nil)
	local root = Match.Root(survivor)
	if root then
		root.Anchored = false
		root.CFrame = cage.Door.CFrame * CFrame.new(3, 0, 0)
	end
	SurvivorService.SetHealth(survivor, "Injured")
	return true
end

function SurvivorService.IsCaged(survivor: Player): boolean
	return caged[survivor] ~= nil
end

function SurvivorService.SetupCages()
	for _, cage in Match.Map.Cages do
		cage.Occupant = nil
		local cagePrompt = Match.Prompt(cage.Door, "CagePrompt", "Killer", "Cage survivor", "Crow Cage", 0.6, 9)
		cagePrompt.Triggered:Connect(function(killer)
			if killer == Match.Killer then
				SurvivorService.CageSurvivor(killer, cage)
			end
		end)
		cage.RescuePrompt = Match.Prompt(cage.Door, "RescuePrompt", "Survivor", "Rescue", "Crow Cage", Config.Cage.RescueHold, 9)
		cage.RescuePrompt.Enabled = false
		cage.RescuePrompt.Triggered:Connect(function(rescuer)
			local survivor = cage.Occupant
			if not survivor or survivor == rescuer or not Match.IsStandingSurvivor(rescuer) then
				return
			end
			if SurvivorService.FreeFromCage(survivor) then
				DataService.Increment(rescuer, "Rescues")
				local earned = DataService.AddTickets(rescuer, Config.Rewards.Rescue, true)
				Remotes.notify(rescuer, "🗝️ You rescued " .. survivor.DisplayName .. "! +" .. earned .. " 🎟️", "success")
				Remotes.notify(survivor, "🗝️ " .. rescuer.DisplayName .. " got you out! RUN!", "success")
			end
		end)
	end
end

-- Clears all carry/cage state (between matches).
function SurvivorService.ResetAll()
	for survivor in carried do
		SurvivorService.Drop(survivor)
	end
	for survivor, cage in caged do
		cage.Occupant = nil
		cage.RescuePrompt.Enabled = false
		cage.Light.Color = Color3.fromRGB(255, 40, 40)
		local root = Match.Root(survivor)
		if root then
			root.Anchored = false
		end
	end
	table.clear(caged)
end

function SurvivorService.OnPlayerRemoving(player: Player)
	SurvivorService.Drop(player)
	local cage = caged[player]
	if cage then
		caged[player] = nil
		cage.Occupant = nil
		cage.RescuePrompt.Enabled = false
	end
	for survivor, info in carried do
		if info.Killer == player then
			SurvivorService.Drop(survivor, "Injured")
		end
	end
end

local function tick()
	local t = now()
	for survivor, info in carried do
		if t >= info.EndsAt then
			local killer = info.Killer
			SurvivorService.Drop(survivor, "Injured")
			Remotes.notify(survivor, "💪 You wiggled free!", "success")
			if isPlayer(killer) then
				Remotes.notify(killer, "They wiggled free!", "error")
			end
		end
	end
	for survivor in caged do
		local endsAt = survivor:GetAttribute("CageEndsAt")
		if endsAt and t >= endsAt then
			SurvivorService.Eliminate(survivor, "the crows came")
		end
	end
end

function SurvivorService.Init()
	task.spawn(function()
		while true do
			task.wait(0.2)
			local ok, err = pcall(tick)
			if not ok then
				warn("[SurvivorService] tick error:", err)
			end
		end
	end)
	Players.PlayerRemoving:Connect(SurvivorService.OnPlayerRemoving)
end

return SurvivorService
