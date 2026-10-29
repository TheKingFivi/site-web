-- Frostline Checkpoint server entry point.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local LobbyBuilder = require(script.Parent.LobbyBuilder)
local MonetizationService = require(script.Parent.MonetizationService)
local NPC = require(script.Parent.NPC)
local PartyService = require(script.Parent.PartyService)
local PlayerService = require(script.Parent.PlayerService)
local Run = require(script.Parent.Run)

-- Moonlit winter night: dark sky, but bright enough to see everything
Lighting.ClockTime = 1.5
Lighting.Brightness = 2
Lighting.Ambient = Color3.fromRGB(70, 78, 100)
Lighting.OutdoorAmbient = Color3.fromRGB(110, 120, 150)
Lighting.EnvironmentDiffuseScale = 0.6
Lighting.EnvironmentSpecularScale = 0.6
Lighting.ExposureCompensation = 0.3
Lighting.GlobalShadows = true
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmosphere.Density = 0.32
atmosphere.Offset = 0.1
atmosphere.Color = Color3.fromRGB(150, 165, 200)
atmosphere.Decay = Color3.fromRGB(60, 70, 100)
atmosphere.Glare = 0
atmosphere.Haze = 1.4
atmosphere.Parent = Lighting
local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
bloom.Intensity = 0.6
bloom.Size = 30
bloom.Threshold = 1.4
bloom.Parent = Lighting
local grade = Lighting:FindFirstChild("Grade") or Instance.new("ColorCorrectionEffect")
grade.Name = "Grade"
grade.Contrast = 0.08
grade.Saturation = 0.05
grade.TintColor = Color3.fromRGB(240, 244, 255)
grade.Parent = Lighting

StarterPlayer.CameraMaxZoomDistance = 40
StarterPlayer.CharacterWalkSpeed = 16

local lobby = LobbyBuilder.Build(workspace)

-- Supervisor model for the "NEXT OBJECTIVE" portrait
local portraits = Instance.new("Folder")
portraits.Name = "Portraits"
portraits.Parent = ReplicatedStorage
NPC.Supervisor(portraits)

DataService.Init()
MonetizationService.Init()
PlayerService.Init(lobby)
PartyService.Init(lobby)

local function onPlayer(player: Player)
	DataService.Load(player)
	if not player.Parent then
		return
	end
	MonetizationService.LoadPasses(player)
	player:SetAttribute("StoredHints", (DataService.Get(player) or {}).StoredHints or 0)
	player:GetAttributeChangedSignal("KnockedOut"):Connect(function()
		if player:GetAttribute("KnockedOut") then
			task.delay(1.5, function()
				local run = Run.ForPlayer(player)
				if run and run.Blackout and player:GetAttribute("KnockedOut") and MonetizationService.AutoRevive(player) then
					run:WakeUp(player)
					Remotes.notify(player, "⚡ Wake Up used! RUN!", "success")
				end
			end)
		end
	end)
	if player:GetAttribute("DailyReady") then
		task.delay(4, function()
			Remotes.OpenMenu:FireClient(player, "Rewards")
		end)
	end
end
Players.PlayerAdded:Connect(onPlayer)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayer, player)
end
Players.PlayerRemoving:Connect(function(player)
	DataService.Release(player)
end)

-- Lie detector questions (interrogation room)
Remotes.Ask.OnServerInvoke = function(player, index)
	local _, lane = Run.ForPlayer(player)
	local current = lane and lane.Current
	if not current or current.Stage ~= "Room" or type(index) ~= "number" then
		return nil
	end
	local entry = current.Record.Interview[index]
	if not entry then
		return nil
	end
	NPC.Say(current.Model, entry.A)
	if entry.Spike then
		Run.AddStress(player, Config.Stress.CreepyAnswer)
	end
	return { Answer = entry.A, Spike = entry.Spike }
end

-- APPROVE / DENY from the on-screen buttons
Remotes.Decide.OnServerInvoke = function(player, approve)
	local run, lane = Run.ForPlayer(player)
	if run and lane and type(approve) == "boolean" then
		run:Decide(lane, approve)
		return true
	end
	return false
end

Remotes.Taser.OnServerEvent:Connect(function(player, aim)
	local run = Run.ForPlayer(player)
	if run then
		run:Taser(player, aim)
	end
end)

print("[Frostline] Server ready.")
