-- Game passes, developer products, killer unlocks and the lobby killer picker.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local CosmeticService = require(script.Parent.CosmeticService)
local SurvivorService = require(script.Parent.SurvivorService)

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

local function breakOut(player: Player): boolean
	if SurvivorService.IsCaged(player) and SurvivorService.FreeFromCage(player) then
		Remotes.announce("🗝️ " .. player.DisplayName .. " broke out of a Crow Cage!", Color3.fromRGB(255, 210, 90))
		return true
	end
	return false
end

local productHandlers = {
	KillerChance = function(player: Player, data)
		data.KillerChance += Config.KillerChancePack
		DataService.Sync(player)
		Remotes.notify(
			player,
			"🔪 +" .. Config.KillerChancePack .. " Killer Chance! You now have " .. data.KillerChance .. ".",
			"success"
		)
	end,
	SelfRescue = function(player: Player, data)
		if not breakOut(player) then
			data.BreakOuts += 1
			DataService.Sync(player)
			Remotes.notify(player, "🗝️ Break Out saved! Use it next time you're caged.", "success")
		end
	end,
	TicketsSmall = function(player: Player)
		local amount = DataService.AddTickets(player, Config.TicketPacks.TicketsSmall, false)
		Remotes.notify(player, "🎟️ +" .. amount .. " tickets! Thanks for your support!", "success")
	end,
	TicketsLarge = function(player: Player)
		local amount = DataService.AddTickets(player, Config.TicketPacks.TicketsLarge, false)
		Remotes.notify(player, "🎟️ +" .. amount .. " tickets! Thanks for your support!", "success")
	end,
	TicketsHuge = function(player: Player)
		local amount = DataService.AddTickets(player, Config.TicketPacks.TicketsHuge, false)
		Remotes.notify(player, "🎟️ +" .. amount .. " tickets! Thanks for your support!", "success")
	end,
}
for _, key in { "PackStarter", "PackHalloween", "PackKiller", "PackLegendary" } do
	productHandlers[key] = function(player: Player)
		CosmeticService.GrantBundle(player, key)
	end
end

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

	Remotes.SelectKiller.OnServerInvoke = function(player, killer)
		local data = DataService.Get(player)
		if not data or type(killer) ~= "string" or not Config.Killers[killer] then
			return false, "Unknown killer."
		end
		if not player:GetAttribute("Unlocked_" .. killer) then
			return false, "Unlock " .. Config.Killers[killer].Name .. " first."
		end
		data.PreferredKiller = killer
		DataService.Sync(player)
		return true, "You'll play as " .. Config.Killers[killer].Name .. " when you're the killer."
	end

	Remotes.BuyKiller.OnServerInvoke = function(player, killer)
		local data = DataService.Get(player)
		local info = type(killer) == "string" and Config.Killers[killer]
		if not data or not info then
			return false, "Unknown killer."
		end
		if player:GetAttribute("Unlocked_" .. killer) then
			return false, "Already unlocked!"
		end
		if not DataService.SpendTickets(player, info.Price) then
			return false, "You need " .. info.Price .. " 🎟️"
		end
		data.Unlocked[killer] = true
		data.PreferredKiller = killer
		DataService.Sync(player)
		return true, "🔓 " .. info.Name .. " unlocked!"
	end

	Remotes.UseSelfRescue.OnServerInvoke = function(player)
		local data = DataService.Get(player)
		if not data or data.BreakOuts <= 0 then
			return false, "You have no Break Outs."
		end
		if not breakOut(player) then
			return false, "You're not in a cage."
		end
		data.BreakOuts -= 1
		DataService.Sync(player)
		return true, "🗝️ You broke out! RUN!"
	end
end

return MonetizationService
