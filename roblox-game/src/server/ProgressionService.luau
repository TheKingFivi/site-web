-- Rebirths, daily rewards, offline earnings and friend boosts.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local StealService = require(script.Parent.StealService)

local ProgressionService = {}

local friendsOf = {} -- [Player] = { [userId] = true }

function ProgressionService.RebirthCost(rebirths: number): number
	return Config.Rebirth.BaseCost * Config.Rebirth.CostMultiplier ^ rebirths
end

function ProgressionService.Sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("RebirthCost", ProgressionService.RebirthCost(data.Rebirths))
	player:SetAttribute("DailyReadyAt", data.LastDaily + Config.Daily.Cooldown)
	player:SetAttribute("DailyStreak", data.DailyStreak)
	player:SetAttribute("Capacity", PlotService.GetCapacity(player))
end

local function rebirth(player: Player)
	local data = DataService.Get(player)
	if not data then
		return false, "Data not loaded yet."
	end
	if StealService.IsCarrying(player) then
		return false, "Finish your heist first!"
	end
	local cost = ProgressionService.RebirthCost(data.Rebirths)
	if data.Cash < cost then
		return false, "You need " .. Format.Cash(cost) .. " to rebirth."
	end
	PlotService.ClearCritters(player)
	data.Rebirths += 1
	DataService.SetCash(player, Config.StartingCash)
	PlotService.RefreshPedestals(PlotService.GetPlot(player))
	ProgressionService.Sync(player)
	Remotes.announce("♻️ " .. player.DisplayName .. " reached Rebirth " .. data.Rebirths .. "!", Color3.fromRGB(255, 160, 255))
	return true,
		"Rebirth " .. data.Rebirths .. "! Income is now x" .. (1 + data.Rebirths * Config.Rebirth.IncomeBonus) .. " and you got +1 slot."
end

local function claimDaily(player: Player)
	local data = DataService.Get(player)
	if not data then
		return false, "Data not loaded yet."
	end
	local t = os.time()
	local readyAt = data.LastDaily + Config.Daily.Cooldown
	if t < readyAt then
		return false, "Next reward in " .. Format.Time(readyAt - t)
	end
	local streak = if t - data.LastDaily > Config.Daily.StreakReset then 1 else data.DailyStreak % #Config.Daily.Rewards + 1
	local reward = Config.Daily.Rewards[streak] * (1 + data.Rebirths)
	data.DailyStreak = streak
	data.LastDaily = t
	DataService.AddCash(player, reward)
	ProgressionService.Sync(player)
	return true, "🎁 Day " .. streak .. " reward: " .. Format.Cash(reward) .. "! Come back tomorrow."
end

function ProgressionService.GiveOfflineEarnings(player: Player)
	local data = DataService.Get(player)
	if not data or data.LastOnline <= 0 then
		return
	end
	local seconds = math.min(os.time() - data.LastOnline, Config.OfflineEarnings.MaxHours * 3600)
	if seconds < 60 then
		return
	end
	local earned = PlotService.GetIncomePerSec(player) * seconds * Config.OfflineEarnings.Rate
	if earned >= 1 then
		DataService.AddCash(player, earned)
		task.delay(4, function()
			if player.Parent then
				Remotes.notify(player, "😴 Your critters earned " .. Format.Cash(earned) .. " while you were away!", "success")
			end
		end)
	end
end

local function updateFriendBoosts()
	for _, player in Players:GetPlayers() do
		local count = 0
		local friends = friendsOf[player]
		if friends then
			for _, other in Players:GetPlayers() do
				if other ~= player and friends[other.UserId] then
					count += 1
				end
			end
		end
		player:SetAttribute("FriendBoost", math.min(count * Config.FriendBoost.PerFriend, Config.FriendBoost.Max))
	end
end

function ProgressionService.OnPlayerAdded(player: Player)
	friendsOf[player] = friendsOf[player] or {}
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local ok, isFriend = pcall(player.IsFriendsWith, player, other.UserId)
			if ok and isFriend then
				friendsOf[player][other.UserId] = true
				friendsOf[other] = friendsOf[other] or {}
				friendsOf[other][player.UserId] = true
			end
		end
	end
	updateFriendBoosts()
end

function ProgressionService.OnPlayerRemoving(player: Player)
	friendsOf[player] = nil
	task.defer(updateFriendBoosts)
end

function ProgressionService.Init()
	Remotes.Rebirth.OnServerInvoke = rebirth
	Remotes.ClaimDaily.OnServerInvoke = claimDaily
end

return ProgressionService
