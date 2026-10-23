-- Stealing: hold the prompt on someone else's critter, carry it home before the owner tags you.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Critters = require(Shared.Critters)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local PlotService = require(script.Parent.PlotService)
local CritterFactory = require(script.Parent.CritterFactory)

local StealService = {}

local carries = {} -- [thief] = carry info

local function setSpeed(player: Player, speed: number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = speed
	end
end

local function cleanup(thief: Player, carry)
	carries[thief] = nil
	for _, connection in carry.Connections do
		connection:Disconnect()
	end
	if carry.Model then
		carry.Model:Destroy()
	end
	thief:SetAttribute("Carrying", nil)
	setSpeed(thief, Config.Steal.NormalSpeed)
	PlotService.SetReserved(carry.ThiefPlot, carry.TargetSlot, false)
end

local function giveOrRefund(player: Player, entry, slotIndex: number?)
	if PlotService.AddCritter(player, entry.Id, entry.Mutation, slotIndex) then
		return
	end
	DataService.AddCash(player, Critters.Price(entry.Id, entry.Mutation))
end

local function succeed(thief: Player, carry)
	cleanup(thief, carry)
	local entry = carry.Entry
	local name = Critters.DisplayName(entry.Id, entry.Mutation)
	giveOrRefund(thief, entry, carry.TargetSlot)
	local data = DataService.Get(thief)
	if data then
		data.Steals += 1
		DataService.Sync(thief)
	end
	Remotes.notify(thief, "🥷 You stole " .. name .. "!", "success")
	if carry.Owner.Parent then
		Remotes.notify(carry.Owner, thief.DisplayName .. " stole your " .. name .. "! Steal it back!", "error")
	end
	local rarity = Critters.RarityOf(entry.Id)
	if rarity.Order >= 5 then
		Remotes.announce("🥷 " .. thief.DisplayName .. " stole " .. carry.Owner.DisplayName .. "'s " .. name .. "!", rarity.Color)
	end
end

local function fail(thief: Player, carry, reason: string)
	cleanup(thief, carry)
	local entry = carry.Entry
	local name = Critters.DisplayName(entry.Id, entry.Mutation)
	local owner = carry.Owner
	if owner.Parent and PlotService.GetPlot(owner) == carry.Plot then
		giveOrRefund(owner, entry, carry.FromSlot)
		if reason == "caught" then
			Remotes.notify(owner, "🛡️ You caught " .. thief.DisplayName .. " and got your " .. name .. " back!", "success")
		else
			Remotes.notify(owner, "Your " .. name .. " came back home.", "info")
		end
	elseif thief.Parent then
		-- Owner is gone: the thief keeps the loot.
		giveOrRefund(thief, entry)
		return
	end
	if thief.Parent then
		local messages = {
			caught = "😱 " .. owner.DisplayName .. " caught you! The critter ran home.",
			died = "💀 You dropped the critter!",
			timeout = "⌛ Too slow! The critter ran home.",
		}
		Remotes.notify(thief, messages[reason] or "The critter ran home.", "error")
	end
end

function StealService.TrySteal(thief: Player, plot, slotIndex: number)
	local owner = plot.Owner
	if not owner or owner == thief then
		return
	end
	if carries[thief] then
		Remotes.notify(thief, "You're already carrying a critter! Run home!", "error")
		return
	end
	if PlotService.IsProtected(plot) then
		Remotes.notify(thief, "🔒 This base is locked!", "error")
		return
	end
	local thiefPlot = PlotService.GetPlot(thief)
	local slot = plot.Slots[slotIndex]
	if not thiefPlot or not slot or not slot.Critter then
		return
	end
	local character = thief.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then
		return
	end
	local target = PlotService.FindFreeSlot(thief)
	if not target then
		Remotes.notify(thief, "Your base is full! Make room before stealing.", "error")
		return
	end

	PlotService.SetReserved(thiefPlot, target, true)
	local entry = PlotService.RemoveCritter(plot, slotIndex)
	local def = Critters.ById[entry.Id]

	local model = CritterFactory.Build(entry.Id, entry.Mutation, {})
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.Massless = true
		end
	end
	model:PivotTo(root.CFrame * CFrame.new(0, 2.5 + def.Size * 0.6, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = model.PrimaryPart
	weld.Parent = model.PrimaryPart
	model.Parent = character

	local fast = thief:GetAttribute("Pass_FastThief")
	humanoid.WalkSpeed = if fast then Config.Steal.FastCarrySpeed else Config.Steal.CarrySpeed

	local carry = {
		Owner = owner,
		Plot = plot,
		FromSlot = slotIndex,
		Entry = entry,
		Model = model,
		ThiefPlot = thiefPlot,
		TargetSlot = target,
		StartedAt = os.clock(),
		Connections = {},
	}
	carries[thief] = carry
	table.insert(
		carry.Connections,
		humanoid.Died:Connect(function()
			if carries[thief] == carry then
				fail(thief, carry, "died")
			end
		end)
	)

	local name = Critters.DisplayName(entry.Id, entry.Mutation)
	thief:SetAttribute("Carrying", name)
	Remotes.notify(thief, "Run back to your base with " .. name .. "!", "info")
	Remotes.notify(owner, "⚠️ " .. thief.DisplayName .. " is stealing your " .. name .. "! Tag them to get it back!", "error")
end

function StealService.OnPlayerRemoving(player: Player)
	local own = carries[player]
	if own then
		fail(player, own, "left")
	end
	for thief, carry in carries do
		if carry.Owner == player then
			succeed(thief, carry)
		end
	end
end

function StealService.IsCarrying(player: Player): boolean
	return carries[player] ~= nil
end

local function monitor()
	for thief, carry in carries do
		local character = thief.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root or not thief.Parent then
			fail(thief, carry, "died")
		elseif PlotService.IsInside(carry.ThiefPlot, root.Position) then
			succeed(thief, carry)
		else
			local ownerCharacter = carry.Owner.Character
			local ownerRoot = ownerCharacter and ownerCharacter:FindFirstChild("HumanoidRootPart")
			if ownerRoot and (ownerRoot.Position - root.Position).Magnitude < Config.Steal.CatchDistance then
				fail(thief, carry, "caught")
			elseif os.clock() - carry.StartedAt > Config.Steal.MaxCarryTime then
				fail(thief, carry, "timeout")
			end
		end
	end
end

function StealService.Init()
	PlotService.StealHandler = StealService.TrySteal
	task.spawn(function()
		while true do
			task.wait(0.15)
			local ok, err = pcall(monitor)
			if not ok then
				warn("[StealService] monitor error:", err)
			end
		end
	end)
end

return StealService
