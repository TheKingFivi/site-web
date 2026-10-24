-- Entry point: starts every service and handles players joining/leaving.
local Players = game:GetService("Players")

local Server = script.Parent
local DataService = require(Server.DataService)
local World = require(Server.World)
local MonsterService = require(Server.MonsterService)
local PlayerService = require(Server.PlayerService)
local PickupService = require(Server.PickupService)
local RoundService = require(Server.RoundService)
local MonetizationService = require(Server.MonetizationService)

DataService.Init()
World.Init()
MonsterService.Init()
PlayerService.Init()
PickupService.Init()
MonetizationService.Init()
RoundService.Init()

local function onPlayerAdded(player: Player)
	PlayerService.OnPlayerAdded(player)
	local data = DataService.Load(player)
	if not data then
		return
	end
	MonetizationService.LoadPasses(player)
	player:SetAttribute("Loaded", true)
	PlayerService.Spawn(player)
end

local function onPlayerRemoving(player: Player)
	PickupService.DropLog(player)
	PlayerService.OnPlayerRemoving(player)
	DataService.Release(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
