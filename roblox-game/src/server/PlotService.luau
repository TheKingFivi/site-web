-- Player bases: owning plots, placing critters, income, collecting, selling and locking.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Critters = require(Shared.Critters)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local CritterFactory = require(script.Parent.CritterFactory)
local MapBuilder = require(script.Parent.MapBuilder)

local PlotService = {}
PlotService.Plots = {}
PlotService.StealHandler = nil -- set by StealService: function(thief, plot, slotIndex)

local plotByPlayer = {}

local function now()
	return workspace:GetServerTimeNow()
end

local function playerFromHit(hit: BasePart)
	local character = hit:FindFirstAncestorOfClass("Model")
	return character and Players:GetPlayerFromCharacter(character)
end

function PlotService.GetPlot(player: Player)
	return plotByPlayer[player]
end

function PlotService.GetCapacity(player: Player): number
	local data = DataService.Get(player)
	local rebirths = if data then data.Rebirths else 0
	local extra = if player:GetAttribute("Pass_ExtraSlots") then Config.Slots.ExtraSlotsPass else 0
	return math.min(Config.Slots.Max, Config.Slots.Base + rebirths * Config.Slots.PerRebirth + extra)
end

function PlotService.GetMultiplier(player: Player): number
	local data = DataService.Get(player)
	local mult = 1 + (if data then data.Rebirths * Config.Rebirth.IncomeBonus else 0)
	if player:GetAttribute("Pass_DoubleCash") then
		mult *= Config.Multipliers.DoubleCash
	end
	if player:GetAttribute("Pass_VIP") then
		mult *= Config.Multipliers.VIP
	end
	mult *= 1 + (player:GetAttribute("FriendBoost") or 0)
	return mult
end

function PlotService.GetIncomePerSec(player: Player): number
	local plot = plotByPlayer[player]
	if not plot then
		return 0
	end
	local total = 0
	for _, slot in plot.Slots do
		if slot.Critter then
			total += Critters.Income(slot.Critter.Id, slot.Critter.Mutation)
		end
	end
	return total * PlotService.GetMultiplier(player)
end

function PlotService.IsProtected(plot): boolean
	local t = now()
	if t < plot.ShieldUntil then
		return true
	end
	return t < plot.LockedUntil and not workspace:GetAttribute("MoonRaid")
end

function PlotService.IsInside(plot, position: Vector3): boolean
	local offset = position - plot.Front
	local depth = offset:Dot(plot.Inward)
	local lateral = offset:Dot(plot.Right)
	return depth >= 1 and depth <= plot.Depth and math.abs(lateral) <= plot.Width / 2 and offset.Y < 30
end

function PlotService.FindFreeSlot(player: Player): number?
	local plot = plotByPlayer[player]
	if not plot then
		return nil
	end
	for i = 1, PlotService.GetCapacity(player) do
		local slot = plot.Slots[i]
		if not slot.Critter and not slot.Reserved then
			return i
		end
	end
	return nil
end

function PlotService.SetReserved(plot, slotIndex: number, reserved: boolean)
	local slot = plot.Slots[slotIndex]
	if slot then
		slot.Reserved = reserved
	end
end

function PlotService.RefreshPedestals(plot)
	if not plot then
		return
	end
	local capacity = if plot.Owner then PlotService.GetCapacity(plot.Owner) else Config.Slots.Max
	for i, slot in plot.Slots do
		local unlocked = i <= capacity
		slot.Pedestal.Color = if unlocked then plot.Color else Color3.fromRGB(60, 60, 70)
		slot.Label.Text = if slot.Critter then "" elseif unlocked then "Empty" else "🔒"
	end
end

local function placeModel(plot, slotIndex: number, critter)
	local slot = plot.Slots[slotIndex]
	local def = Critters.ById[critter.Id]
	local model, labels = CritterFactory.Build(critter.Id, critter.Mutation, { Accum = true })
	local top = slot.Pedestal.Position + Vector3.new(0, slot.Pedestal.Size.X / 2, 0)
	local pos = top + Vector3.new(0, CritterFactory.GroundOffset(def), 0)
	model:PivotTo(CFrame.lookAt(pos, pos - plot.Inward))

	local name = Critters.DisplayName(critter.Id, critter.Mutation)
	local ownerId = plot.Owner.UserId

	local steal = Instance.new("ProximityPrompt")
	steal.Name = "StealPrompt"
	steal.ActionText = "Steal"
	steal.ObjectText = name
	steal.HoldDuration = Config.Steal.HoldTime
	steal.MaxActivationDistance = 9
	steal.RequiresLineOfSight = false
	steal:SetAttribute("OwnerId", ownerId)
	CollectionService:AddTag(steal, "CritterPrompt")
	steal.Triggered:Connect(function(player)
		if PlotService.StealHandler and plot.Slots[slotIndex].Critter == critter then
			PlotService.StealHandler(player, plot, slotIndex)
		end
	end)
	steal.Parent = model.PrimaryPart

	local sellValue = math.floor(Critters.Price(critter.Id, critter.Mutation) * Config.SellRatio)
	local sell = Instance.new("ProximityPrompt")
	sell.Name = "SellPrompt"
	sell.ActionText = "Sell " .. Format.Cash(sellValue)
	sell.ObjectText = name
	sell.KeyboardKeyCode = Enum.KeyCode.F
	sell.GamepadKeyCode = Enum.KeyCode.ButtonY
	sell.HoldDuration = 1
	sell.MaxActivationDistance = 9
	sell.RequiresLineOfSight = false
	sell:SetAttribute("OwnerId", ownerId)
	CollectionService:AddTag(sell, "CritterPrompt")
	sell.Triggered:Connect(function(player)
		if player == plot.Owner and plot.Slots[slotIndex].Critter == critter then
			PlotService.RemoveCritter(plot, slotIndex)
			DataService.AddCash(player, sellValue)
			Remotes.notify(player, "Sold " .. name .. " for " .. Format.Cash(sellValue), "success")
		end
	end)
	sell.Parent = model.PrimaryPart

	model.Parent = plot.Model
	return model, labels
end

-- Puts a critter in a player's base. Returns the slot index, or nil if there's no room.
function PlotService.AddCritter(player: Player, id: string, mutation: string?, slotIndex: number?): number?
	local plot = plotByPlayer[player]
	local data = DataService.Get(player)
	if not plot or not data or not Critters.ById[id] then
		return nil
	end
	if slotIndex then
		local slot = plot.Slots[slotIndex]
		if not slot or slot.Critter or slot.Reserved or slotIndex > PlotService.GetCapacity(player) then
			slotIndex = nil
		end
	end
	slotIndex = slotIndex or PlotService.FindFreeSlot(player)
	if not slotIndex then
		return nil
	end
	local critter = { Id = id, Mutation = mutation or "None", Accum = 0 }
	local slot = plot.Slots[slotIndex]
	slot.Critter = critter
	critter.Model, critter.Labels = placeModel(plot, slotIndex, critter)
	data.Critters[tostring(slotIndex)] = { Id = critter.Id, Mutation = critter.Mutation }
	slot.Label.Text = ""
	return slotIndex
end

-- Removes a critter from a plot (pays out its uncollected cash to the owner).
function PlotService.RemoveCritter(plot, slotIndex: number, skipPayout: boolean?)
	local slot = plot.Slots[slotIndex]
	local critter = slot and slot.Critter
	if not critter then
		return nil
	end
	slot.Critter = nil
	if critter.Model then
		critter.Model:Destroy()
	end
	local owner = plot.Owner
	if owner then
		local data = DataService.Get(owner)
		if data then
			data.Critters[tostring(slotIndex)] = nil
		end
		if not skipPayout and critter.Accum > 0 then
			DataService.AddCash(owner, critter.Accum)
		end
	end
	PlotService.RefreshPedestals(plot)
	return { Id = critter.Id, Mutation = critter.Mutation }
end

function PlotService.ClearCritters(player: Player)
	local plot = plotByPlayer[player]
	if not plot then
		return
	end
	for i in plot.Slots do
		PlotService.RemoveCritter(plot, i, true)
	end
end

function PlotService.AssignPlot(player: Player)
	for _, plot in PlotService.Plots do
		if not plot.Owner then
			plot.Owner = player
			plot.LockedUntil = 0
			plot.LockCooldownUntil = 0
			plot.ShieldUntil = 0
			plotByPlayer[player] = plot
			plot.Model:SetAttribute("OwnerId", player.UserId)
			plot.SignLabel.Text = player.DisplayName .. "'s Base"
			player:SetAttribute("PlotIndex", plot.Index)
			player:SetAttribute("LockReadyAt", 0)
			player:SetAttribute("ShieldUntil", 0)
			PlotService.RefreshPedestals(plot)
			return plot
		end
	end
	return nil
end

-- Re-creates the critters saved in the player's data.
function PlotService.LoadCritters(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local saved = data.Critters
	data.Critters = {}
	local overflow = {}
	for key, entry in saved do
		local index = tonumber(key)
		if not (index and Critters.ById[entry.Id] and PlotService.AddCritter(player, entry.Id, entry.Mutation, index)) then
			table.insert(overflow, entry)
		end
	end
	for _, entry in overflow do
		if Critters.ById[entry.Id] and not PlotService.AddCritter(player, entry.Id, entry.Mutation) then
			-- No room (shouldn't happen) - refund instead of deleting it.
			DataService.AddCash(player, Critters.Price(entry.Id, entry.Mutation))
		end
	end
end

-- Frees the plot without touching saved data (used when a player leaves).
function PlotService.ReleasePlot(player: Player)
	local plot = plotByPlayer[player]
	if not plot then
		return
	end
	for _, slot in plot.Slots do
		if slot.Critter and slot.Critter.Model then
			slot.Critter.Model:Destroy()
		end
		slot.Critter = nil
		slot.Reserved = false
	end
	plot.Owner = nil
	plot.LockedUntil = 0
	plot.ShieldUntil = 0
	plot.Model:SetAttribute("OwnerId", nil)
	plot.SignLabel.Text = "Empty Plot"
	plotByPlayer[player] = nil
	PlotService.RefreshPedestals(plot)
end

function PlotService.SpawnAtPlot(player: Player, character: Model)
	local plot = plotByPlayer[player]
	if not plot then
		return
	end
	character:WaitForChild("HumanoidRootPart", 5)
	task.wait(0.1)
	if character.Parent and plotByPlayer[player] == plot then
		character:PivotTo(plot.SpawnCFrame)
	end
end

function PlotService.Collect(player: Player)
	local plot = plotByPlayer[player]
	if not plot then
		return
	end
	local total = 0
	for _, slot in plot.Slots do
		local critter = slot.Critter
		if critter and critter.Accum > 0 then
			total += critter.Accum
			critter.Accum = 0
			critter.Labels.Accum.Text = "💰 $0"
		end
	end
	if total >= 1 then
		DataService.AddCash(player, total)
		Remotes.notify(player, "+" .. Format.Cash(total) .. " collected!", "success")
	end
end

function PlotService.Lock(player: Player): (boolean, string)
	local plot = plotByPlayer[player]
	if not plot then
		return false, "You don't have a base yet."
	end
	local t = now()
	if workspace:GetAttribute("MoonRaid") then
		return false, "🌙 Locks don't work during a Moon Raid! (A Raid Shield does.)"
	end
	if t < plot.LockCooldownUntil then
		return false, "Lock recharging: " .. Format.Time(plot.LockCooldownUntil - t)
	end
	plot.LockedUntil = t + Config.Lock.Duration
	plot.LockCooldownUntil = t + Config.Lock.Cooldown
	player:SetAttribute("LockReadyAt", plot.LockCooldownUntil)
	player:SetAttribute("LockedUntil", plot.LockedUntil)
	return true, "🔒 Base locked for " .. Config.Lock.Duration .. " seconds!"
end

function PlotService.Shield(player: Player, seconds: number)
	local plot = plotByPlayer[player]
	if not plot then
		return
	end
	plot.ShieldUntil = math.max(now(), plot.ShieldUntil) + seconds
	player:SetAttribute("ShieldUntil", plot.ShieldUntil)
end

local function knockBack(plot, character: Model)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local outside = Vector3.new(root.Position.X, plot.Front.Y + 4, plot.Front.Z) - plot.Inward * 6
	root.CFrame = CFrame.new(outside)
	root.AssemblyLinearVelocity = -plot.Inward * 60 + Vector3.new(0, 30, 0)
end

local function incomeTick()
	for _, plot in PlotService.Plots do
		local owner = plot.Owner
		if owner then
			local mult = PlotService.GetMultiplier(owner)
			local auto = owner:GetAttribute("Pass_AutoCollect")
			local perSec, direct = 0, 0
			for _, slot in plot.Slots do
				local critter = slot.Critter
				if critter then
					local income = Critters.Income(critter.Id, critter.Mutation) * mult
					perSec += income
					if auto then
						direct += income
					else
						critter.Accum += income
						critter.Labels.Accum.Text = "💰 " .. Format.Cash(critter.Accum)
					end
				end
			end
			if direct > 0 then
				DataService.AddCash(owner, direct)
			end
			owner:SetAttribute("IncomePerSec", perSec)
			owner:SetAttribute("Multiplier", mult)
		end
		local protected = PlotService.IsProtected(plot)
		plot.Laser.Transparency = if protected then 0.35 else 1
		plot.Model:SetAttribute("Protected", protected)
		if protected then
			local shielded = now() < plot.ShieldUntil
			plot.LockLabel.Text = if shielded then "🛡️ SHIELDED" else "🔒 LOCKED " .. Format.Time(plot.LockedUntil - now())
		else
			plot.LockLabel.Text = "🔒 LOCK BASE"
		end
	end
end

function PlotService.Init()
	for _, plot in MapBuilder.Build() do
		plot.Owner = nil
		plot.LockedUntil = 0
		plot.LockCooldownUntil = 0
		plot.ShieldUntil = 0
		plot.Slots = {}
		for i, pedestal in plot.Pedestals do
			plot.Slots[i] = { Pedestal = pedestal.Part, Label = pedestal.Label, Critter = nil, Reserved = false }
		end
		table.insert(PlotService.Plots, plot)

		plot.CollectPad.Touched:Connect(function(hit)
			local player = playerFromHit(hit)
			if player and player == plot.Owner then
				PlotService.Collect(player)
			end
		end)

		local lockDebounce = {}
		plot.LockButton.Touched:Connect(function(hit)
			local player = playerFromHit(hit)
			if player and player == plot.Owner and not lockDebounce[player] then
				lockDebounce[player] = true
				local _, message = PlotService.Lock(player)
				Remotes.notify(player, message, "info")
				task.delay(2, function()
					lockDebounce[player] = nil
				end)
			end
		end)

		plot.Laser.Touched:Connect(function(hit)
			local player = playerFromHit(hit)
			if player and player ~= plot.Owner and PlotService.IsProtected(plot) and player.Character then
				knockBack(plot, player.Character)
			end
		end)
	end

	Remotes.LockBase.OnServerInvoke = function(player)
		return PlotService.Lock(player)
	end

	task.spawn(function()
		while true do
			task.wait(1)
			local ok, err = pcall(incomeTick)
			if not ok then
				warn("[PlotService] income tick error:", err)
			end
		end
	end)
end

return PlotService
