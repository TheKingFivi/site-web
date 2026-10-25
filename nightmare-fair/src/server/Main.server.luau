-- Entry point: builds the fair, starts every service, handles players joining/leaving.
local Players = game:GetService("Players")

local Server = script.Parent
local BotKiller = require(Server.BotKiller)
local CosmeticService = require(Server.CosmeticService)
local DataService = require(Server.DataService)
local HideService = require(Server.HideService)
local MapBuilder = require(Server.MapBuilder)
local Match = require(Server.Match)
local SurvivorService = require(Server.SurvivorService)
local KillerService = require(Server.KillerService)
local ObjectiveService = require(Server.ObjectiveService)
local RoundService = require(Server.RoundService)
local MonetizationService = require(Server.MonetizationService)

Match.SetupCollisionGroups()
Match.Map = MapBuilder.Build()

DataService.Init()
SurvivorService.Init()
SurvivorService.SetupCages()
KillerService.Init()
ObjectiveService.Init()
HideService.Init()
MonetizationService.Init()
CosmeticService.Init()
BotKiller.Init()
RoundService.Init()

local function onPlayerAdded(player: Player)
	player:SetAttribute("Role", "Lobby")
	player.CharacterAdded:Connect(function(character)
		local role = Match.Role(player)
		if role ~= "Ghost" then
			task.defer(Match.SetCollisionGroup, character, "Players")
		end
		task.delay(0.5, CosmeticService.Apply, player)
		RoundService.OnCharacterAdded(player, character)
	end)
	local data = DataService.Load(player)
	if not data then
		return
	end
	MonetizationService.LoadPasses(player)
	player:SetAttribute("Loaded", true)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
	DataService.Release(player)
end)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
