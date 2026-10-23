-- Entry point: starts every service and handles players joining/leaving.
local Players = game:GetService("Players")

local Server = script.Parent
local DataService = require(Server.DataService)
local PlotService = require(Server.PlotService)
local ConveyorService = require(Server.ConveyorService)
local StealService = require(Server.StealService)
local EventService = require(Server.EventService)
local MonetizationService = require(Server.MonetizationService)
local ProgressionService = require(Server.ProgressionService)

DataService.Init()
PlotService.Init()
EventService.Init()
ConveyorService.Init()
StealService.Init()
MonetizationService.Init()
ProgressionService.Init()

local function onPlayerAdded(player: Player)
	local data = DataService.Load(player)
	if not data then
		return
	end
	MonetizationService.LoadPasses(player)
	local plot = PlotService.AssignPlot(player)
	if not plot then
		player:Kick("This server is full, please join another one!")
		return
	end
	PlotService.LoadCritters(player)
	ProgressionService.OnPlayerAdded(player)
	ProgressionService.Sync(player)
	ProgressionService.GiveOfflineEarnings(player)

	player.CharacterAdded:Connect(function(character)
		PlotService.SpawnAtPlot(player, character)
	end)
	if player.Character then
		task.spawn(PlotService.SpawnAtPlot, player, player.Character)
	end
	player:GetAttributeChangedSignal("Rebirths"):Connect(function()
		ProgressionService.Sync(player)
	end)
	player:GetAttributeChangedSignal("Pass_ExtraSlots"):Connect(function()
		ProgressionService.Sync(player)
	end)
end

local function onPlayerRemoving(player: Player)
	StealService.OnPlayerRemoving(player)
	ProgressionService.OnPlayerRemoving(player)
	local data = DataService.Get(player)
	if data then
		data.LastOnline = os.time()
	end
	PlotService.ReleasePlot(player)
	DataService.Release(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
