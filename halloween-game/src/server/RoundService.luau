-- The round loop: intermission -> 5 nights (with dawn breaks) -> escape or game over.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local MonsterService = require(script.Parent.MonsterService)
local PlayerService = require(script.Parent.PlayerService)
local World = require(script.Parent.World)

local RoundService = {}

local pendingHaunts = {} -- players to sic the monster on when the next night starts

local atmosphere, colorCorrection

local LOOKS = {
	Day = {
		Lighting = { ClockTime = 7, Brightness = 1.2, Ambient = Color3.fromRGB(90, 85, 95), OutdoorAmbient = Color3.fromRGB(120, 110, 120) },
		Atmosphere = { Density = 0.35, Color = Color3.fromRGB(190, 170, 180), Decay = Color3.fromRGB(120, 100, 110), Haze = 1 },
		Tint = Color3.new(1, 1, 1),
	},
	Night = {
		Lighting = { ClockTime = 0, Brightness = 0.2, Ambient = Color3.fromRGB(20, 20, 30), OutdoorAmbient = Color3.fromRGB(35, 35, 55) },
		Atmosphere = { Density = 0.55, Color = Color3.fromRGB(50, 55, 80), Decay = Color3.fromRGB(20, 20, 35), Haze = 2.5 },
		Tint = Color3.fromRGB(220, 225, 255),
	},
	BloodMoon = {
		Lighting = { ClockTime = 0, Brightness = 0.3, Ambient = Color3.fromRGB(40, 10, 10), OutdoorAmbient = Color3.fromRGB(80, 20, 20) },
		Atmosphere = { Density = 0.55, Color = Color3.fromRGB(120, 30, 30), Decay = Color3.fromRGB(60, 10, 10), Haze = 2.5 },
		Tint = Color3.fromRGB(255, 190, 190),
	},
}

local currentLook

local function setLook(name: string)
	if currentLook == name then
		return
	end
	currentLook = name
	local look = LOOKS[name]
	local info = TweenInfo.new(4, Enum.EasingStyle.Sine)
	TweenService:Create(Lighting, info, look.Lighting):Play()
	TweenService:Create(atmosphere, info, look.Atmosphere):Play()
	TweenService:Create(colorCorrection, info, { TintColor = look.Tint }):Play()
end

local function now()
	return workspace:GetServerTimeNow()
end

local function setPhase(phase: string, duration: number, night: number?)
	workspace:SetAttribute("Phase", phase)
	workspace:SetAttribute("PhaseEndsAt", now() + duration)
	if night then
		workspace:SetAttribute("Night", night)
	end
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

local function everyoneDown(): boolean
	local players = loadedPlayers()
	if #players == 0 then
		return false
	end
	for _, player in players do
		if PlayerService.IsActive(player) then
			return false
		end
	end
	return true
end

function RoundService.QueueHaunt(target: Player)
	table.insert(pendingHaunts, target)
end

local function runNight(night: number): string
	local isBloodMoon = night == Config.BloodMoonNight
	PlayerService.ResetNight()
	PlayerService.ReviveAll()
	setPhase("Night", Config.NightLength[night], night)
	setLook(if isBloodMoon then "BloodMoon" else "Night")
	if isBloodMoon then
		Remotes.announce("🩸 BLOOD MOON! Night " .. night .. ": TWO of them are hunting...", Color3.fromRGB(255, 70, 70))
	else
		Remotes.announce(
			"🌑 Night " .. night .. " of " .. Config.Nights .. ". Stay in the light. Keep the fire burning.",
			Color3.fromRGB(255, 170, 80)
		)
	end

	task.wait(3)
	MonsterService.Spawn(isBloodMoon, night)
	if isBloodMoon then
		MonsterService.Spawn(true, night)
	end
	for _, target in pendingHaunts do
		if target.Parent then
			MonsterService.ForceTarget(target, Config.HauntDuration)
			Remotes.Jumpscare:FireClient(target)
		end
	end
	table.clear(pendingHaunts)

	local endsAt = workspace:GetAttribute("PhaseEndsAt")
	local last = os.clock()
	local allDownSince = nil
	while now() < endsAt do
		task.wait(0.25)
		local dt = os.clock() - last
		last = os.clock()
		if #loadedPlayers() == 0 then
			return "Empty"
		end
		if World.IsDaylight() then
			setLook("Day")
		else
			setLook(if isBloodMoon then "BloodMoon" else "Night")
			local before = World.Fuel
			World.AddFuel(-Config.Bonfire.DrainPerSec * dt)
			if before > 0 and World.Fuel <= 0 then
				Remotes.announce("🔥 THE BONFIRE WENT OUT! The Hollow is enraged. Bring logs!", Color3.fromRGB(255, 80, 60))
			end
		end
		-- Give downed players a few seconds to use a revive before the night is lost.
		if everyoneDown() then
			allDownSince = allDownSince or os.clock()
			if os.clock() - allDownSince > 8 then
				return "Lost"
			end
		else
			allDownSince = nil
		end
	end
	return "Survived"
end

local function rewardNight(night: number)
	for _, player in loadedPlayers() do
		if not player:GetAttribute("Dead") then
			local data = DataService.Get(player)
			if data then
				data.NightsSurvived += 1
				data.BestNight = math.max(data.BestNight, night)
			end
			local earned = DataService.AddCandy(player, Config.Rewards.NightSurvived[night], true)
			Remotes.notify(player, "🌅 You survived night " .. night .. "! +" .. earned .. " 🍬", "success")
		end
	end
end

local function roundLoop()
	while true do
		-- Intermission
		MonsterService.DespawnAll()
		World.SetFuel(Config.Bonfire.StartFuel)
		workspace:SetAttribute("Night", 0)
		setLook("Day")
		while #loadedPlayers() == 0 do
			setPhase("Waiting", 0, 0)
			task.wait(1)
		end
		setPhase("Intermission", Config.IntermissionTime, 0)
		PlayerService.ReviveAll()
		task.wait(Config.IntermissionTime)

		local result = "Survived"
		local reached = 0
		for night = 1, Config.Nights do
			result = runNight(night)
			MonsterService.DespawnAll()
			if result ~= "Survived" then
				break
			end
			reached = night
			rewardNight(night)
			if night < Config.Nights then
				setPhase("Dawn", Config.DawnTime, night)
				setLook("Day")
				World.AddFuel(Config.Bonfire.DawnRefuel)
				PlayerService.ReviveAll()
				Remotes.announce(
					"🌅 Dawn. Rest, upgrade your gear, and gather logs. Night " .. (night + 1) .. " is coming.",
					Color3.fromRGB(255, 220, 150)
				)
				task.wait(Config.DawnTime)
			end
		end

		if result == "Survived" then
			setPhase("Victory", Config.EndScreenTime, Config.Nights)
			setLook("Day")
			local names = {}
			for _, player in loadedPlayers() do
				if not player:GetAttribute("Dead") then
					table.insert(names, player.DisplayName)
					local data = DataService.Get(player)
					if data then
						data.Escapes += 1
					end
					local earned = DataService.AddCandy(player, Config.Rewards.Escape, true)
					Remotes.notify(player, "🏆 YOU ESCAPED THE HOLLOW! +" .. earned .. " 🍬", "success")
				end
			end
			Remotes.announce("🏆 " .. #names .. " survivor(s) escaped The Hollow!", Color3.fromRGB(255, 215, 80))
		elseif result == "Lost" then
			setPhase("GameOver", Config.EndScreenTime, reached)
			Remotes.announce("💀 The Hollow got everyone on night " .. (reached + 1) .. ". Try again!", Color3.fromRGB(255, 70, 70))
		end
		if result ~= "Empty" then
			task.wait(Config.EndScreenTime)
		end
	end
end

function RoundService.Init()
	atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Parent = Lighting
	colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
	colorCorrection.Saturation = -0.2
	colorCorrection.Contrast = 0.1
	colorCorrection.Parent = Lighting
	Lighting.GlobalShadows = true
	workspace:SetAttribute("DaylightUntil", 0)

	task.spawn(function()
		while true do
			local ok, err = pcall(roundLoop)
			if not ok then
				warn("[RoundService] round loop crashed, restarting:", err)
				task.wait(2)
			end
		end
	end)
end

return RoundService
