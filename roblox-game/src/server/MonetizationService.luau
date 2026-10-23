-- Game passes and developer products (this is where the Robux come from).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Critters = require(Shared.Critters)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)

local MonetizationService = {}

local MAX_RECEIPTS = 100

local function onPassGranted(player: Player, key: string)
	if key == "ExtraSlots" then
		PlotService.RefreshPedestals(PlotService.GetPlot(player))
	end
end

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
end

local function cashPack(key: string)
	return function(player: Player, data)
		local pack = Config.CashPacks[key]
		local amount = math.max(pack[1] * (1 + data.Rebirths), PlotService.GetIncomePerSec(player) * pack[2])
		DataService.AddCash(player, amount)
		Remotes.notify(player, "💰 +" .. Format.Cash(amount) .. "! Thanks for your support!", "success")
	end
end

local productHandlers = {
	CashSmall = cashPack("CashSmall"),
	CashMedium = cashPack("CashMedium"),
	CashLarge = cashPack("CashLarge"),

	ServerLuck = function(player: Player)
		local t = workspace:GetServerTimeNow()
		local current = math.max(t, workspace:GetAttribute("LuckUntil") or 0)
		workspace:SetAttribute("LuckUntil", current + Config.ServerLuck.Duration)
		Remotes.announce(
			"🍀 " .. player.DisplayName .. " activated SERVER LUCK x" .. Config.ServerLuck.Multiplier .. " for everyone! Say thanks!",
			Color3.fromRGB(110, 255, 120)
		)
	end,

	RaidShield = function(player: Player)
		PlotService.Shield(player, Config.RaidShieldDuration)
		Remotes.notify(player, "🛡️ Raid Shield active for " .. Format.Time(Config.RaidShieldDuration) .. "!", "success")
	end,

	MythicEgg = function(player: Player)
		local rng = Random.new()
		local pool = if rng:NextNumber() < 0.1 then Critters.ByRarity.Secret else Critters.ByRarity.Mythic
		local def = pool[rng:NextInteger(1, #pool)]
		if PlotService.AddCritter(player, def.Id, "None") then
			Remotes.announce(
				"🥚 " .. player.DisplayName .. " hatched a " .. def.Rarity:upper() .. " " .. def.Name .. "!",
				Critters.Rarities[def.Rarity].Color
			)
		else
			DataService.AddCash(player, def.Price)
			Remotes.notify(player, "Your base was full, so you got " .. Format.Cash(def.Price) .. " instead!", "info")
		end
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
		-- Granted in memory (the receipt id prevents a double grant); Roblox will retry the save later.
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
				onPassGranted(player, key)
				Remotes.notify(player, "Thanks for buying " .. pass.Name .. "!", "success")
			end
		end
	end)
end

return MonetizationService
