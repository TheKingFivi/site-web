-- Game passes and developer products (safe, idempotent receipts).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local Run = require(script.Parent.Run)

local MonetizationService = {}

local MAX_RECEIPTS = 100

function MonetizationService.LoadPasses(player: Player)
	for key, pass in Config.GamePasses do
		local owned = false
		if pass.Id ~= 0 then
			local ok, result = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
			owned = ok and result == true
		end
		if RunService:IsStudio() and Config.StudioGrantAllPasses then
			owned = true
		end
		player:SetAttribute("Pass_" .. key, owned)
	end
	DataService.Sync(player)
end

-- Tells the player whether the passenger in front of them is human.
function MonetizationService.Hint(player: Player): (boolean, string)
	local _, lane = Run.ForPlayer(player)
	local current = lane and lane.Current
	if not current or not current.Record then
		return false, "No passenger at your desk right now."
	end
	if current.Record.Anomaly then
		return true, "🔍 Your gut screams: this passenger is NOT HUMAN."
	end
	return true, "🔍 This passenger is human." .. (if current.Record.Violation then " (But check their papers...)" else "")
end

local productHandlers = {
	Hint = function(player: Player)
		local ok, text = MonetizationService.Hint(player)
		if not ok then
			-- No passenger: save it as a stored hint
			local data = DataService.Get(player)
			if data then
				data.StoredHints = (data.StoredHints or 0) + 1
				player:SetAttribute("StoredHints", data.StoredHints)
			end
			Remotes.notify(player, "🔍 Hint saved! Use it from the shop during a shift.", "success")
			return
		end
		Remotes.notify(player, text, "info")
	end,
	Revive = function(player: Player)
		local run = Run.ForPlayer(player)
		if run and player:GetAttribute("KnockedOut") then
			run:WakeUp(player)
			Remotes.notify(player, "⚡ You're back up! RUN!", "success")
		else
			local data = DataService.Get(player)
			if data then
				data.StoredRevives = (data.StoredRevives or 0) + 1
			end
			Remotes.notify(player, "⚡ Wake Up saved for later. It triggers automatically when you're caught.", "success")
		end
	end,
	PowerSurge = function(player: Player)
		local run = Run.ForPlayer(player)
		if not (run and run:SurgeBreaker(player)) then
			DataService.AddCash(player, 250, false)
			Remotes.notify(player, "No blackout right now, so here's $250 instead.", "info")
		end
	end,
	CashSmall = function(player: Player)
		local amount = DataService.AddCash(player, Config.CashPacks.CashSmall, false)
		Remotes.notify(player, "💵 +$" .. amount .. "! Thanks for your support!", "success")
	end,
	CashLarge = function(player: Player)
		local amount = DataService.AddCash(player, Config.CashPacks.CashLarge, false)
		Remotes.notify(player, "💵 +$" .. amount .. "! Thanks for your support!", "success")
	end,
	CandySmall = function(player: Player)
		local amount = DataService.AddCandy(player, Config.CandyPacks.CandySmall, false)
		Remotes.notify(player, "🍬 +" .. amount .. " Candy! Happy Halloween!", "success")
	end,
	CandyLarge = function(player: Player)
		local amount = DataService.AddCandy(player, Config.CandyPacks.CandyLarge, false)
		Remotes.notify(player, "🍬 +" .. amount .. " Candy! Happy Halloween!", "success")
	end,
}

local handlerById = {}
for key, product in Config.Products do
	if product.Id ~= 0 and productHandlers[key] then
		handlerById[product.Id] = productHandlers[key]
	end
end

local function processReceipt(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = DataService.Get(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if data.ReceiptIds[info.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local handler = handlerById[info.ProductId]
	if not handler then
		warn("[Monetization] No handler for product", info.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ok, err = pcall(handler, player, data)
	if not ok then
		warn("[Monetization] Handler error:", err)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	data.ReceiptIds[info.PurchaseId] = os.time()
	local count, oldestId, oldestTime = 0, nil, math.huge
	for id, time in data.ReceiptIds do
		count += 1
		if time < oldestTime then
			oldestId, oldestTime = id, time
		end
	end
	if count > MAX_RECEIPTS and oldestId then
		data.ReceiptIds[oldestId] = nil
	end

	if not DataService.Save(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService.Init()
	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for key, pass in Config.GamePasses do
			if pass.Id ~= 0 and pass.Id == passId then
				player:SetAttribute("Pass_" .. key, true)
				DataService.Sync(player)
				Remotes.notify(player, "Thanks for buying " .. pass.Name .. "!", "success")
			end
		end
	end)

	Remotes.UseHint.OnServerInvoke = function(player)
		local data = DataService.Get(player)
		if not data or (data.StoredHints or 0) <= 0 then
			return false, "You have no saved hints."
		end
		local ok, text = MonetizationService.Hint(player)
		if ok then
			data.StoredHints -= 1
			player:SetAttribute("StoredHints", data.StoredHints)
		end
		return ok, text
	end

	-- Anomaly Radar pass: points at the tool that will expose this passenger.
	Remotes.UseRadar.OnServerInvoke = function(player)
		local run, lane = Run.ForPlayer(player)
		if not run or not lane then
			return false, "Only during a shift."
		end
		if not player:GetAttribute("Pass_AnomalyRadar") then
			return false, "You need the 📡 Anomaly Radar pass."
		end
		if lane.RadarLeft <= 0 then
			return false, "No radar charges left this shift."
		end
		local record = lane.Current and lane.Current.Record
		if not record then
			return false, "No passenger at your desk."
		end
		lane.RadarLeft -= 1
		run:SendState(lane)
		local Passengers = require(Shared.Passengers)
		if record.Anomaly then
			for _, tell in Passengers.Anomalies[record.Anomaly].Tells do
				if Passengers.ToolUnlocked(run.Shift, tell) then
					return true, "📡 Radar: check the " .. tell .. " carefully."
				end
			end
		end
		if record.Violation then
			return true, "📡 Radar: something on their papers or bag breaks tonight's rules."
		end
		return true, "📡 Radar: nothing unusual detected."
	end
end

-- Spend a saved Wake Up automatically when knocked out.
function MonetizationService.AutoRevive(player: Player): boolean
	local data = DataService.Get(player)
	if data and (data.StoredRevives or 0) > 0 then
		data.StoredRevives -= 1
		return true
	end
	return false
end

return MonetizationService
