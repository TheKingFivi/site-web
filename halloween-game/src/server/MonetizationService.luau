-- Game passes and developer products (this is where the Robux come from).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local MonsterService = require(script.Parent.MonsterService)
local PlayerService = require(script.Parent.PlayerService)
local RoundService = require(script.Parent.RoundService)
local World = require(script.Parent.World)

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
end

local function candyPack(key: string)
	return function(player: Player)
		local amount = DataService.AddCandy(player, Config.CandyPacks[key], false)
		Remotes.notify(player, "🍬 +" .. amount .. " candy! Thanks for your support!", "success")
	end
end

local productHandlers = {
	CandySmall = candyPack("CandySmall"),
	CandyLarge = candyPack("CandyLarge"),
	CandyHuge = candyPack("CandyHuge"),

	SelfRevive = function(player: Player, data)
		if PlayerService.Revive(player) then
			Remotes.notify(player, "💖 You're back on your feet!", "success")
		else
			data.ReviveTokens += 1
			DataService.Sync(player)
			Remotes.notify(player, "💖 Revive saved! It's ready next time you go down.", "success")
		end
	end,

	BonfireRefill = function(player: Player)
		World.SetFuel(Config.Bonfire.MaxFuel)
		Remotes.announce("🔥 " .. player.DisplayName .. " refilled the bonfire for everyone!", Color3.fromRGB(255, 160, 60))
	end,

	ServerDaylight = function(player: Player)
		local t = workspace:GetServerTimeNow()
		local current = math.max(t, workspace:GetAttribute("DaylightUntil") or 0)
		workspace:SetAttribute("DaylightUntil", current + Config.DaylightDuration)
		Remotes.announce(
			"☀️ " .. player.DisplayName .. " summoned DAYLIGHT! The Hollow hides. Grab logs and candy!",
			Color3.fromRGB(255, 230, 120)
		)
	end,

	HauntPlayer = function(player: Player)
		local target = Players:GetPlayerByUserId(player:GetAttribute("HauntTarget") or 0)
		if not target or target == player then
			local others = {}
			for _, other in Players:GetPlayers() do
				if other ~= player then
					table.insert(others, other)
				end
			end
			target = others[math.random(1, math.max(1, #others))]
		end
		if not target or target == player then
			DataService.AddCandy(player, 400, false)
			Remotes.notify(player, "Nobody else is here to haunt, so you got 400 🍬 instead.", "info")
			return
		end
		Remotes.announce(
			"👻 " .. player.DisplayName .. " sent The Hollow after " .. target.DisplayName .. "!",
			Color3.fromRGB(200, 120, 255)
		)
		if workspace:GetAttribute("Phase") == "Night" and MonsterService.Count() > 0 then
			MonsterService.ForceTarget(target, Config.HauntDuration)
			Remotes.Jumpscare:FireClient(target)
		else
			RoundService.QueueHaunt(target)
			Remotes.notify(player, "👻 The haunt will start when the next night begins.", "info")
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
				Remotes.notify(player, "Thanks for buying " .. pass.Name .. "!", "success")
			end
		end
	end)
end

return MonetizationService
