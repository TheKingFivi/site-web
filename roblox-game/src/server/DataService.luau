-- Loads/saves player data with retries, session locking and autosave.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Format)

local DataService = {}

local SESSION_TIMEOUT = 300 -- a lock older than this is considered stale
local profiles = {} -- [Player] = { Data = table, CanSave = boolean }

local store
pcall(function()
	store = DataStoreService:GetDataStore(Config.DataStoreName)
end)

local function defaultData()
	return {
		Cash = Config.StartingCash,
		Critters = {}, -- ["slotIndex"] = { Id = string, Mutation = string }
		Rebirths = 0,
		Steals = 0,
		TotalEarned = 0,
		DailyStreak = 0,
		LastDaily = 0,
		LastOnline = 0,
		ReceiptIds = {},
	}
end

local function reconcile(data)
	for key, value in defaultData() do
		if data[key] == nil then
			data[key] = value
		end
	end
	return data
end

local function keyFor(player: Player)
	return "Player_" .. player.UserId
end

local function setupLeaderstats(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Parent = stats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = stats
	local steals = Instance.new("IntValue")
	steals.Name = "Steals"
	steals.Parent = stats
	stats.Parent = player
end

function DataService.Load(player: Player)
	local data, canSave = nil, false
	if store then
		for attempt = 1, 8 do
			local lockedElsewhere = false
			local ok, err = pcall(function()
				data = store:UpdateAsync(keyFor(player), function(old)
					old = old or defaultData()
					local session = old.Session
					if session and session.Job ~= game.JobId and os.time() - session.Time < SESSION_TIMEOUT and attempt < 8 then
						lockedElsewhere = true
						return nil -- cancel the write, another server still owns this data
					end
					old.Session = { Job = game.JobId, Time = os.time() }
					return old
				end)
			end)
			if ok and not lockedElsewhere and data then
				canSave = true
				break
			end
			if not ok then
				warn("[DataService] Load failed for", player.Name, err)
			end
			if not player.Parent then
				return nil
			end
			task.wait(if lockedElsewhere then 5 else attempt)
		end
	end

	if not canSave then
		warn("[DataService] Could not load data for " .. player.Name .. "; progress will NOT be saved this session.")
		data = nil
	end
	data = reconcile(if type(data) == "table" then data else defaultData())

	if not player.Parent then
		-- Player left while loading: release the session lock we just took.
		if canSave then
			pcall(function()
				store:UpdateAsync(keyFor(player), function(old)
					if old then
						old.Session = nil
					end
					return old
				end)
			end)
		end
		return nil
	end

	profiles[player] = { Data = data, CanSave = canSave }
	setupLeaderstats(player)
	DataService.Sync(player)
	return data
end

function DataService.Get(player: Player)
	local profile = profiles[player]
	return if profile then profile.Data else nil
end

function DataService.Save(player: Player, release: boolean?): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	if not profile.CanSave then
		-- In Studio without API access we can't save; treat as success so purchases still work.
		return RunService:IsStudio()
	end
	local data = profile.Data
	data.Session = if release then nil else { Job = game.JobId, Time = os.time() }
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			store:UpdateAsync(keyFor(player), function()
				return data
			end)
		end)
		if ok then
			return true
		end
		warn("[DataService] Save failed for", player.Name, err)
		task.wait(attempt)
	end
	return false
end

function DataService.Release(player: Player)
	if profiles[player] then
		DataService.Save(player, true)
		profiles[player] = nil
	end
end

function DataService.Sync(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	player:SetAttribute("Cash", data.Cash)
	player:SetAttribute("Rebirths", data.Rebirths)
	player:SetAttribute("Steals", data.Steals)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Cash.Value = Format.Cash(data.Cash)
		stats.Rebirths.Value = data.Rebirths
		stats.Steals.Value = data.Steals
	end
end

function DataService.AddCash(player: Player, amount: number)
	local data = DataService.Get(player)
	if not data or amount ~= amount then
		return
	end
	data.Cash += amount
	if amount > 0 then
		data.TotalEarned += amount
	end
	DataService.Sync(player)
end

function DataService.SetCash(player: Player, amount: number)
	local data = DataService.Get(player)
	if data then
		data.Cash = amount
		DataService.Sync(player)
	end
end

function DataService.SpendCash(player: Player, amount: number): boolean
	local data = DataService.Get(player)
	if not data or data.Cash < amount then
		return false
	end
	data.Cash -= amount
	DataService.Sync(player)
	return true
end

function DataService.Init()
	task.spawn(function()
		while true do
			task.wait(Config.AutoSaveInterval)
			for player in profiles do
				task.spawn(DataService.Save, player)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				local data = DataService.Get(player)
				if data then
					data.LastOnline = os.time()
				end
				DataService.Save(player, true)
				pending -= 1
			end)
		end
		local started = os.clock()
		while pending > 0 and os.clock() - started < 25 do
			task.wait(0.1)
		end
	end)
end

return DataService
