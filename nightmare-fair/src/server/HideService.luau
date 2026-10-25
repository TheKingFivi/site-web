-- Lockers & wardrobes, DBD-style: survivors hide inside (first-person view through the vents),
-- the killer can search them. Finding someone grabs them straight out onto the killer's shoulder.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local KillerService = require(script.Parent.KillerService)
local Match = require(script.Parent.Match)
local SurvivorService = require(script.Parent.SurvivorService)

local HideService = {}

local occupantOf = {} -- [locker] = Player
local lockerOf = {} -- [Player] = locker

local function now()
	return Match.Now()
end

local function swingDoor(locker)
	TweenService:Create(locker.Door, TweenInfo.new(0.15), { CFrame = locker.DoorOpen }):Play()
	task.delay(0.45, function()
		TweenService:Create(locker.Door, TweenInfo.new(0.2), { CFrame = locker.DoorClosed }):Play()
	end)
end

local function refreshPrompts(locker)
	local occupant = occupantOf[locker]
	locker.HidePrompt.Enabled = occupant == nil
	locker.LeavePrompt.Enabled = occupant ~= nil
	locker.LeavePrompt:SetAttribute("OnlyUserId", if occupant then occupant.UserId else nil)
end

function HideService.IsHiding(player: Player): boolean
	return lockerOf[player] ~= nil
end

function HideService.Hide(player: Player, locker)
	if occupantOf[locker] or lockerOf[player] or not Match.Active or not Match.IsStandingSurvivor(player) then
		return
	end
	if (player:GetAttribute("TrappedUntil") or 0) > now() then
		return
	end
	local root = Match.Root(player)
	if not root then
		return
	end
	player:SetAttribute("WorkingOn", nil)
	occupantOf[locker] = player
	lockerOf[player] = locker
	swingDoor(locker)
	root.CFrame = locker.Inside
	root.Anchored = true
	player:SetAttribute("Hiding", true)
	refreshPrompts(locker)
end

function HideService.Leave(player: Player)
	local locker = lockerOf[player]
	if not locker then
		return
	end
	lockerOf[player] = nil
	occupantOf[locker] = nil
	player:SetAttribute("Hiding", nil)
	local root = Match.Root(player)
	if root then
		root.Anchored = false
		root.CFrame = locker.Outside
	end
	swingDoor(locker)
	refreshPrompts(locker)
end

-- The killer (a Player, or the AI killer table) opens a locker. Returns true if someone was inside.
function HideService.Search(searcher, locker): boolean
	swingDoor(locker)
	Remotes.Sfx:FireAllClients("Pallet", locker.Position)
	local found = occupantOf[locker]
	if not found then
		return false
	end
	HideService.Leave(found)
	SurvivorService.SetHealth(found, "Downed")
	SurvivorService.Pickup(searcher, found)
	Remotes.Scare:FireClient(found, "down")
	Remotes.notify(found, "😱 The killer found you in the locker!", "error")
	if typeof(searcher) == "Instance" then
		Remotes.notify(searcher, "Found one! Take them to a Crow Cage.", "success")
	end
	return true
end

function HideService.OccupiedNear(position: Vector3, radius: number)
	local list = {}
	for _, locker in Match.Map.Lockers do
		if (locker.Position - position).Magnitude < radius then
			table.insert(list, locker)
		end
	end
	table.sort(list, function(a, b)
		return (a.Position - position).Magnitude < (b.Position - position).Magnitude
	end)
	return list
end

function HideService.Reset()
	for player in lockerOf do
		HideService.Leave(player)
	end
end

function HideService.Init()
	for _, locker in Match.Map.Lockers do
		locker.HidePrompt = Match.Prompt(locker.Door, "HidePrompt", "Survivor", "Hide", "Locker", 0.4, 7)
		locker.LeavePrompt = Match.Prompt(locker.Door, "LeavePrompt", "Survivor", "Leave", "Locker", 0, 7)
		local search = Match.Prompt(locker.Door, "SearchPrompt", "Killer", "Search", "Locker", 0.8, 8)
		locker.HidePrompt.Triggered:Connect(function(player)
			HideService.Hide(player, locker)
		end)
		locker.LeavePrompt.Triggered:Connect(function(player)
			if occupantOf[locker] == player then
				HideService.Leave(player)
			end
		end)
		search.Triggered:Connect(function(killer)
			if killer == Match.Killer and Match.Active and not SurvivorService.CarriedBy(killer) then
				if not HideService.Search(killer, locker) then
					KillerService.SlowFor(1.4)
					Remotes.notify(killer, "Empty...", "info")
				end
			end
		end)
		refreshPrompts(locker)
	end
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		local locker = lockerOf[player]
		if locker then
			lockerOf[player] = nil
			occupantOf[locker] = nil
			refreshPrompts(locker)
		end
	end)
end

return HideService
