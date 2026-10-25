-- The round loop: lobby -> pick a killer -> 7-minute match -> results -> back to the lobby.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local BotKiller = require(script.Parent.BotKiller)
local CosmeticService = require(script.Parent.CosmeticService)
local DataService = require(script.Parent.DataService)
local KillerService = require(script.Parent.KillerService)
local Match = require(script.Parent.Match)
local ObjectiveService = require(script.Parent.ObjectiveService)
local SurvivorService = require(script.Parent.SurvivorService)

local RoundService = {}

local rng = Random.new()

local function now()
	return Match.Now()
end

local function setPhase(phase: string, duration: number)
	workspace:SetAttribute("Phase", phase)
	workspace:SetAttribute("PhaseEndsAt", now() + duration)
end

local function loadedPlayers()
	local list = {}
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("Loaded") then
			table.insert(list, player)
		end
	end
	return list
end

local function pickKiller(players)
	local total = 0
	for _, player in players do
		total += math.max(1, player:GetAttribute("KillerChance") or 1)
	end
	local roll = rng:NextNumber() * total
	for _, player in players do
		roll -= math.max(1, player:GetAttribute("KillerChance") or 1)
		if roll <= 0 then
			return player
		end
	end
	return players[#players]
end

local function killerTypeFor(player: Player): string
	local preferred = player:GetAttribute("PreferredKiller")
	if preferred and Config.Killers[preferred] and player:GetAttribute("Unlocked_" .. preferred) then
		return preferred
	end
	return "Ringmaster"
end

local function shuffle(list)
	for i = #list, 2, -1 do
		local j = rng:NextInteger(1, i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

local function placeAsSurvivor(player: Player, spawnCFrame: CFrame)
	player:SetAttribute("Role", "Survivor")
	player:SetAttribute("CageCount", 0)
	player:SetAttribute("TrappedUntil", nil)
	player:SetAttribute("WorkingOn", nil)
	player:SetAttribute("Health", "Healthy")
	local character = player.Character
	if character then
		character:PivotTo(spawnCFrame)
	end
	SurvivorService.Setup(player)
end

local function placeAsKiller(player: Player)
	local character = player.Character
	if character then
		character:PivotTo(Match.Map.KillerSpawn)
	end
	KillerService.Setup(player, Match.KillerType)
	CosmeticService.Apply(player) -- killers keep their trail but not survivor hats
end

local function startMatch(players)
	-- Alone in the server? The AI Ringmaster hunts you instead of a real player.
	local solo = #players == 1
	local killer = if solo then nil else pickKiller(players)
	Match.Killer = killer
	Match.KillerType = if killer then killerTypeFor(killer) else "Ringmaster"
	Match.Active = true
	KillerService.Reset()
	ObjectiveService.Reset()

	-- Killer chance: the killer resets, everyone else goes up
	for _, player in players do
		local data = DataService.Get(player)
		if data then
			if player == killer then
				data.KillerChance = Config.KillerChance.Start
			else
				data.KillerChance += Config.KillerChance.PerRound + (if player:GetAttribute("Pass_VIP") then 1 else 0)
			end
			DataService.Sync(player)
		end
	end

	local spawns = shuffle(table.clone(Match.Map.SurvivorSpawns))
	local index = 0
	for _, player in players do
		if player == killer then
			placeAsKiller(player)
		else
			index += 1
			placeAsSurvivor(player, spawns[(index - 1) % #spawns + 1])
		end
	end
	workspace:SetAttribute("KillerType", Match.KillerType)
	workspace:SetAttribute("SurvivorCount", if killer then #players - 1 else #players)
	setPhase("Match", Config.MatchTime)
	if not killer then
		workspace:SetAttribute("KillerName", "AI")
		BotKiller.Start()
		Remotes.announce(
			"🤖 Solo hunt: the AI Ringmaster is coming for you! When more players join, one of them becomes the killer.",
			Config.Killers.Ringmaster.Color
		)
		return
	end
	workspace:SetAttribute("KillerName", killer.DisplayName)
	KillerService.Freeze(10)
	Remotes.announce(
		"🔪 "
			.. killer.DisplayName
			.. " is "
			.. Config.Killers[Match.KillerType].Name
			.. "! Survivors: light "
			.. Config.Pumpkins.Needed
			.. " Ritual Pumpkins and escape!",
		Config.Killers[Match.KillerType].Color
	)
	Remotes.notify(killer, "You're the KILLER. You can move in 10 seconds. Click to attack, Q for your power.", "info")
end

local function eliminateRemaining(reason: string)
	for _, survivor in Match.Survivors() do
		SurvivorService.Eliminate(survivor, reason)
	end
end

local function runMatch(): string
	while true do
		task.wait(0.5)
		local killer = Match.Killer
		if not BotKiller.IsActive() and (not killer or not killer.Parent or Match.Role(killer) ~= "Killer") then
			return "KillerLeft"
		end
		if #Match.Survivors() == 0 then
			return "Done"
		end
		local collapse = workspace:GetAttribute("CollapseEndsAt")
		if collapse and now() > collapse then
			eliminateRemaining("the fair collapsed")
			return "Done"
		end
		if now() > workspace:GetAttribute("PhaseEndsAt") then
			eliminateRemaining("the fair closed")
			return "Done"
		end
	end
end

local function endMatch(result: string)
	Match.Active = false
	BotKiller.Stop()
	local escaped, eliminated, total = 0, 0, 0
	for _, player in Players:GetPlayers() do
		local role = Match.Role(player)
		if role == "Escaped" then
			escaped += 1
			total += 1
		elseif role == "Ghost" then
			eliminated += 1
			total += 1
		end
	end
	local killer = Match.Killer
	local killerWon = result ~= "KillerLeft" and total > 0 and eliminated >= math.ceil(total / 2)
	if killer and killer.Parent then
		DataService.AddTickets(killer, Config.Rewards.Participation, true)
		if killerWon then
			DataService.Increment(killer, "KillerWins")
			local earned = DataService.AddTickets(killer, Config.Rewards.KillerWin, true)
			Remotes.notify(killer, "🏆 The fair is yours! +" .. earned .. " 🎟️", "success")
		end
	end
	workspace:SetAttribute("ResultEscaped", escaped)
	workspace:SetAttribute("ResultEliminated", eliminated)
	workspace:SetAttribute("ResultKillerWon", killerWon)
	setPhase("Results", Config.ResultsTime)
	if result == "KillerLeft" then
		Remotes.announce("The killer fled the fair. Survivors win!", Color3.fromRGB(120, 255, 150))
	elseif killerWon then
		Remotes.announce("☠️ THE KILLER WINS: " .. eliminated .. " taken, " .. escaped .. " escaped.", Color3.fromRGB(255, 60, 60))
	else
		Remotes.announce("🏃 SURVIVORS WIN: " .. escaped .. " escaped, " .. eliminated .. " taken.", Color3.fromRGB(120, 255, 150))
	end
	task.wait(Config.ResultsTime)

	SurvivorService.ResetAll()
	KillerService.Reset()
	ObjectiveService.Reset()
	Match.Killer = nil
	Match.KillerType = nil
	workspace:SetAttribute("KillerName", nil)
	workspace:SetAttribute("KillerType", nil)
	for _, player in Players:GetPlayers() do
		player:SetAttribute("Role", "Lobby")
		player:SetAttribute("Health", nil)
		player:SetAttribute("WorkingOn", nil)
		player:SetAttribute("CageEndsAt", nil)
		player:SetAttribute("TrappedUntil", nil)
		player:SetAttribute("Vanished", nil)
		if player:GetAttribute("Loaded") then
			player:LoadCharacter()
		end
	end
end

local function roundLoop()
	while true do
		workspace:SetAttribute("Phase", "Lobby")
		while #loadedPlayers() < Config.MinPlayers do
			setPhase("Waiting", 0)
			task.wait(1)
		end
		setPhase("Intermission", Config.IntermissionTime)
		local cancelled = false
		local endsAt = now() + Config.IntermissionTime
		while now() < endsAt do
			task.wait(0.5)
			if #loadedPlayers() < Config.MinPlayers then
				cancelled = true
				break
			end
		end
		if not cancelled then
			startMatch(loadedPlayers())
			endMatch(runMatch())
		end
	end
end

-- If someone respawns mid-match (reset, fell off the map), put them back where they belong.
function RoundService.OnCharacterAdded(player: Player, character: Model)
	if not Match.Active then
		return
	end
	character:WaitForChild("HumanoidRootPart", 5)
	task.wait(0.2)
	local role = Match.Role(player)
	if role == "Killer" and player == Match.Killer then
		placeAsKiller(player)
	elseif role == "Survivor" then
		character:PivotTo(Match.Map.SurvivorSpawns[1])
		SurvivorService.Setup(player)
		SurvivorService.Eliminate(player, "fell")
	elseif role == "Ghost" then
		character:PivotTo(Match.Map.SurvivorSpawns[rng:NextInteger(1, #Match.Map.SurvivorSpawns)])
		SurvivorService.MakeGhost(player)
	end
end

-- Moonlit and readable, DBD-style: you can see the map, but the distance fades into fog,
-- and warm carnival lights pop against the cold blue night.
local function setupLighting()
	Lighting.ClockTime = 0.2
	Lighting.GeographicLatitude = 35
	Lighting.Brightness = 2.4
	Lighting.ExposureCompensation = 0.35
	Lighting.Ambient = Color3.fromRGB(78, 76, 96)
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 124, 152)
	Lighting.ColorShift_Top = Color3.fromRGB(150, 165, 210)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.6
	Lighting.ShadowSoftness = 0.35
	Lighting.GlobalShadows = true

	local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
	sky.MoonAngularSize = 18
	sky.StarCount = 4000
	sky.SunAngularSize = 0
	sky.Parent = Lighting

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.12
	atmosphere.Color = Color3.fromRGB(122, 118, 150)
	atmosphere.Decay = Color3.fromRGB(62, 54, 84)
	atmosphere.Haze = 1.6
	atmosphere.Glare = 0
	atmosphere.Parent = Lighting

	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Intensity = 0.55
	bloom.Size = 28
	bloom.Threshold = 1.1
	bloom.Parent = Lighting

	local grade = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
	grade.Brightness = 0.03
	grade.Contrast = 0.14
	grade.Saturation = -0.22
	grade.TintColor = Color3.fromRGB(222, 226, 245)
	grade.Parent = Lighting

	local rays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if rays then
		rays:Destroy()
	end
end

function RoundService.Init()
	setupLighting()
	task.spawn(function()
		while true do
			local ok, err = pcall(roundLoop)
			if not ok then
				warn("[RoundService] round loop crashed, restarting:", err)
				Match.Active = false
				task.wait(2)
			end
		end
	end)
end

return RoundService
