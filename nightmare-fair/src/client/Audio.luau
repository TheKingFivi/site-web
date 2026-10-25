-- Music and sound, DBD-style:
--   lobby: broken music-box waltz
--   match: wind + drone ambience
--   survivors: heartbeat that grows as the killer gets closer, chase music when it's on top of you
--   killer: chase music when a survivor is close
--   one-shot effects, positioned in 3D where they happen
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local player = Players.LocalPlayer

local Audio = {}

local loops = {}

local function soundId(key: string): string?
	local info = Config.Sounds[key]
	if info and info.Id ~= 0 then
		return "rbxassetid://" .. info.Id
	end
	return nil
end

local function makeLoop(key: string)
	local id = soundId(key)
	if not id then
		return
	end
	local sound = Instance.new("Sound")
	sound.Name = key
	sound.SoundId = id
	sound.Looped = true
	sound.Volume = 0
	sound.Parent = SoundService
	sound:Play()
	loops[key] = { Sound = sound, Target = 0, Max = Config.Sounds[key].Volume }
end

-- Plays a one-shot effect. With a position, it's heard in 3D from that spot.
function Audio.Play(key: string, position: Vector3?)
	local id = soundId(key)
	if not id then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = Config.Sounds[key].Volume
	if position then
		local anchor = Instance.new("Part")
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.Transparency = 1
		anchor.Size = Vector3.one
		anchor.Position = position
		anchor.Parent = workspace
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMinDistance = 15
		sound.RollOffMaxDistance = 220
		sound.Parent = anchor
		sound.Ended:Connect(function()
			anchor:Destroy()
		end)
	else
		sound.Parent = SoundService
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end
	sound:Play()
end

local function killerRoot(): BasePart?
	for _, other in Players:GetPlayers() do
		if other:GetAttribute("Role") == "Killer" and not other:GetAttribute("Vanished") then
			local character = other.Character
			return character and character:FindFirstChild("HumanoidRootPart")
		end
	end
	for _, bot in CollectionService:GetTagged("KillerBot") do
		return bot:FindFirstChild("HumanoidRootPart")
	end
	return nil
end

local function nearestSurvivorDistance(from: Vector3): number
	local best = math.huge
	for _, other in Players:GetPlayers() do
		if other ~= player and other:GetAttribute("Role") == "Survivor" then
			local character = other.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				best = math.min(best, (root.Position - from).Magnitude)
			end
		end
	end
	return best
end

local function setTarget(key: string, fraction: number)
	local loop = loops[key]
	if loop then
		loop.Target = loop.Max * math.clamp(fraction, 0, 1)
	end
end

function Audio.Start()
	for _, key in { "LobbyMusic", "Ambience", "TerrorRadius", "ChaseMusic" } do
		makeLoop(key)
	end

	Remotes.Sfx.OnClientEvent:Connect(function(key, position)
		Audio.Play(key, position)
	end)
	Remotes.SkillCheck.OnClientEvent:Connect(function()
		Audio.Play("SkillCheck")
	end)

	RunService.Heartbeat:Connect(function(dt)
		local role = player:GetAttribute("Role") or "Lobby"
		local inMatch = workspace:GetAttribute("Phase") == "Match"
		local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")

		local terror, chase = 0, 0
		if inMatch and myRoot then
			if role == "Survivor" then
				local root = killerRoot()
				if root then
					local distance = (root.Position - myRoot.Position).Magnitude
					terror = 1 - distance / Config.TerrorRadius
					chase = if distance < Config.ChaseRadius then 1 else 0
				end
			elseif role == "Killer" then
				chase = if nearestSurvivorDistance(myRoot.Position) < Config.ChaseRadius then 1 else 0
			end
		end
		local inLobby = not inMatch or role == "Lobby" or role == "Escaped"
		setTarget("LobbyMusic", if inLobby then 1 else 0)
		setTarget("Ambience", if inMatch and not inLobby then 1 - chase * 0.6 else 0)
		setTarget("TerrorRadius", terror * (1 - chase * 0.5))
		setTarget("ChaseMusic", chase)

		-- Smooth fades
		for _, loop in loops do
			local speed = if loop.Target > loop.Sound.Volume then 1.5 else 0.6
			local step = speed * dt
			loop.Sound.Volume += math.clamp(loop.Target - loop.Sound.Volume, -step, step)
		end
		local heartbeat = loops.TerrorRadius
		if heartbeat then
			-- The heartbeat speeds up as the killer closes in
			heartbeat.Sound.PlaybackSpeed = 1 + math.clamp(terror, 0, 1) * 0.35
		end
	end)
end

return Audio
