-- Loads/saves player data with retries, session locking and autosave.
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Cosmetics = require(Shared.Cosmetics)

local DataService = {}

local SESSION_TIMEOUT = 300 -- a lock older than this is considered stale
local profiles = {} -- [Player] = { Data = table, CanSave = boolean }

local store
pcall(function()
	store = DataStoreService:GetDataStore(Config.DataStoreName)
end)

local function defaultData()
	return {
		Tickets = 0,
		KillerChance = Config.KillerChance.Start,
		Unlocked = { Ringmaster = true },
		PreferredKiller = "Ringmaster",
		Escapes = 0,
		Eliminations = 0,
		KillerWins = 0,
		PumpkinsLit = 0,
		Rescues = 0,
		BreakOuts = 0,
		Owned = {},
		Equipped = {},
		StarterBought = false,
		ReceiptIds = {},
	}
end

local function reconcile(data)
	for key, value in defaultData() do
		if data[key] == nil then
			data[key] = value
		end
	end
	data.Unlocked.Ringmaster = true
	return data
end

local function keyFor(player: Player)
	return "Player_" .. player.UserId
end

local function setupLeaderstats(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, name in { "Tickets", "Escapes", "Kills" } do
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
	player:SetAttribute("Tickets", data.Tickets)
	player:SetAttribute("KillerChance", data.KillerChance)
	player:SetAttribute("PreferredKiller", data.PreferredKiller)
	player:SetAttribute("BreakOuts", data.BreakOuts)
	player:SetAttribute("StarterBought", data.StarterBought)
	for _, item in Cosmetics.Items do
		player:SetAttribute("Owned_" .. item.Id, data.Owned[item.Id] == true)
	end
	player:SetAttribute("Equip_Hat", data.Equipped.Hat)
	player:SetAttribute("Equip_Trail", data.Equipped.Trail)
	for _, killer in Config.KillerOrder do
		player:SetAttribute("Skin_" .. killer, data.Equipped["Skin_" .. killer])
	end
	for _, killer in Config.KillerOrder do
		local passKey = Config.Killers[killer].PassKey
		local unlocked = data.Unlocked[killer] == true or (passKey ~= nil and player:GetAttribute("Pass_" .. passKey) == true)
		player:SetAttribute("Unlocked_" .. killer, unlocked)
	end
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Tickets.Value = data.Tickets
		stats.Escapes.Value = data.Escapes
		stats.Kills.Value = data.Eliminations
	end
end

function DataService.TicketMultiplier(player: Player): number
	local mult = 1
	if player:GetAttribute("Pass_DoubleTickets") then
		mult *= Config.Multipliers.DoubleTickets
	end
	if player:GetAttribute("Pass_VIP") then
		mult *= Config.Multipliers.VIP
	end
	return mult
end

-- Gives tickets. `boosted` applies pass multipliers (use it for gameplay rewards, not purchases).
function DataService.AddTickets(player: Player, amount: number, boosted: boolean?): number
	local data = DataService.Get(player)
	if not data then
		return 0
	end
	if boosted then
		amount *= DataService.TicketMultiplier(player)
	end
	amount = math.floor(amount)
	data.Tickets += amount
	DataService.Sync(player)
	return amount
end

function DataService.SpendTickets(player: Player, amount: number): boolean
	local data = DataService.Get(player)
	if not data or data.Tickets < amount then
		return false
	end
	data.Tickets -= amount
	DataService.Sync(player)
	return true
end

-- Adds to a saved stat counter (Escapes, Eliminations, ...).
function DataService.Increment(player: Player, key: string, amount: number?)
	local data = DataService.Get(player)
	if data and type(data[key]) == "number" then
		data[key] += amount or 1
		DataService.Sync(player)
	end
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
