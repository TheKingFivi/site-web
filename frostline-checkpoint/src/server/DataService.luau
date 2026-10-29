-- Loads/saves player data with retries, session locking and autosave.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local DataService = {}

local SESSION_TIMEOUT = 300 -- a lock older than this is considered stale
local profiles = {} -- [Player] = { Data = table, CanSave = boolean }

local store
pcall(function()
	store = DataStoreService:GetDataStore(Config.DataStoreName)
end)

local function defaultData()
	return {
		Cash = 0,
		NextShift = 1, -- the night you're on
		BestShift = 0,
		PerfectShifts = 0,
		Correct = 0,
		Candy = 0,
		Skin = "Standard",
		OwnedSkins = { Standard = true },
		DailyStreak = 0,
		DailyLast = 0, -- day number (os.time() // 86400) of the last claim
		ReceiptIds = {},
	}
end

local function reconcile(data)
	for key, value in defaultData() do
		if data[key] == nil then
			data[key] = value
		end
	end
	data.OwnedSkins.Standard = true
	return data
end

local function keyFor(player: Player)
	return "Player_" .. player.UserId
end

local function setupLeaderstats(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, name in { "Shift", "Cash", "Perfect" } do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Parent = stats
	end
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
	player:SetAttribute("NextShift", data.NextShift)
	player:SetAttribute("Candy", data.Candy)
	player:SetAttribute("Skin", data.Skin)
	player:SetAttribute("DailyStreak", data.DailyStreak)
	player:SetAttribute("DailyReady", data.DailyLast < os.time() // 86400)
	for _, skin in Config.Skins do
		player:SetAttribute("OwnedSkin_" .. skin.Key, data.OwnedSkins[skin.Key] == true)
	end
	local rank = Config.Ranks[1].Name
	for _, r in Config.Ranks do
		if data.NextShift >= r.Shift then
			rank = r.Name
		end
	end
	player:SetAttribute("Rank", rank)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Shift.Value = data.NextShift
		stats.Cash.Value = data.Cash
		stats.Perfect.Value = data.PerfectShifts
	end
end

function DataService.PayMultiplier(player: Player): number
	local mult = 1
	if player:GetAttribute("Pass_DoublePay") then
		mult *= Config.Multipliers.DoublePay
	end
	if player:GetAttribute("Pass_VIP") then
		mult *= Config.Multipliers.VIP
	end
	return mult
end

-- Gives cash. `boosted` applies pass multipliers (gameplay pay, not purchases).
function DataService.AddCash(player: Player, amount: number, boosted: boolean?): number
	local data = DataService.Get(player)
	if not data then
		return 0
	end
	if boosted then
		amount *= DataService.PayMultiplier(player)
	end
	amount = math.floor(amount)
	data.Cash += amount
	DataService.Sync(player)
	return amount
end

function DataService.AddCandy(player: Player, amount: number, boosted: boolean?): number
	local data = DataService.Get(player)
	if not data then
		return 0
	end
	if boosted and player:GetAttribute("Pass_VIP") then
		amount *= Config.Multipliers.VIP
	end
	amount = math.floor(amount)
	data.Candy += amount
	DataService.Sync(player)
	return amount
end

function DataService.Spend(player: Player, currency: string, amount: number): boolean
	local data = DataService.Get(player)
	if not data or (data[currency] or 0) < amount then
		return false
	end
	data[currency] -= amount
	DataService.Sync(player)
	return true
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
