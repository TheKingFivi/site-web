-- Cosmetics: builds hats/masks and trails on characters, sells them for tickets,
-- opens Mystery Crates and grants Robux bundles.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cosmetics = require(Shared.Cosmetics)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local Match = require(script.Parent.Match)

local CosmeticService = {}

local rng = Random.new()
local rgb = Color3.fromRGB

local function newPart(props)
	local part = Instance.new("Part")
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	for key, value in props do
		part[key] = value
	end
	return part
end

local function attach(folder: Instance, to: BasePart, props, offset: CFrame)
	local part = newPart(props)
	part.CFrame = to.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = to
	weld.Part1 = part
	weld.Parent = part
	part.Parent = folder
	return part
end

local function glow(part: BasePart, color: Color3, range: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = 1.2
	light.Parent = part
end

-- Each builder gets (folder, head, torso)
local HATS = {
	CatEars = function(f, head)
		for _, x in { -0.45, 0.45 } do
			attach(
				f,
				head,
				{ Size = Vector3.new(0.45, 0.6, 0.2), Color = rgb(20, 20, 25) },
				CFrame.new(x, 0.75, 0) * CFrame.Angles(0, 0, x * -0.6)
			)
			attach(
				f,
				head,
				{ Size = Vector3.new(0.25, 0.35, 0.21), Color = rgb(255, 150, 180) },
				CFrame.new(x, 0.72, -0.02) * CFrame.Angles(0, 0, x * -0.6)
			)
		end
	end,
	TopHat = function(f, head)
		attach(
			f,
			head,
			{ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.15, 2.1, 2.1), Color = rgb(15, 15, 20) },
			CFrame.new(0, 0.65, 0) * CFrame.Angles(0, 0, math.rad(90))
		)
		attach(
			f,
			head,
			{ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 1.3, 1.3), Color = rgb(15, 15, 20) },
			CFrame.new(0, 1.35, 0) * CFrame.Angles(0, 0, math.rad(90))
		)
		attach(
			f,
			head,
			{ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.25, 1.35, 1.35), Color = rgb(140, 20, 30) },
			CFrame.new(0, 0.85, 0) * CFrame.Angles(0, 0, math.rad(90))
		)
	end,
	CandleHat = function(f, head)
		attach(
			f,
			head,
			{ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 1.4, 1.4), Color = rgb(90, 70, 50) },
			CFrame.new(0, 0.65, 0) * CFrame.Angles(0, 0, math.rad(90))
		)
		attach(f, head, { Size = Vector3.new(0.4, 1, 0.4), Color = rgb(240, 230, 200) }, CFrame.new(0, 1.2, 0))
		local flame = attach(
			f,
			head,
			{ Shape = Enum.PartType.Ball, Size = Vector3.new(0.35, 0.5, 0.35), Color = rgb(255, 180, 60), Material = Enum.Material.Neon },
			CFrame.new(0, 1.9, 0)
		)
		glow(flame, rgb(255, 170, 70), 12)
	end,
	DevilHorns = function(f, head)
		for _, x in { -0.45, 0.45 } do
			attach(
				f,
				head,
				{ Size = Vector3.new(0.25, 0.7, 0.25), Color = rgb(200, 20, 30), Material = Enum.Material.Neon },
				CFrame.new(x, 0.8, -0.1) * CFrame.Angles(0, 0, x * -0.7)
			)
		end
	end,
	WitchHat = function(f, head)
		attach(
			f,
			head,
			{ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.15, 2.8, 2.8), Color = rgb(40, 20, 60) },
			CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90))
		)
		for i, s in { 1.4, 1.05, 0.7, 0.4 } do
			attach(
				f,
				head,
				{ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.55, s, s), Color = rgb(40, 20, 60) },
				CFrame.new(0.05 * i, 0.6 + i * 0.5, 0.05 * i) * CFrame.Angles(0, 0, math.rad(90))
			)
		end
		attach(
			f,
			head,
			{
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.2, 1.45, 1.45),
				Color = rgb(150, 255, 90),
				Material = Enum.Material.Neon,
			},
			CFrame.new(0, 0.9, 0) * CFrame.Angles(0, 0, math.rad(90))
		)
	end,
	SkullMask = function(f, head)
		local mask = attach(
			f,
			head,
			{ Shape = Enum.PartType.Ball, Size = Vector3.new(1.3, 1.45, 1.1), Color = rgb(240, 235, 220) },
			CFrame.new(0, 0.05, -0.25)
		)
		for _, x in { -0.27, 0.27 } do
			attach(
				f,
				mask,
				{ Shape = Enum.PartType.Ball, Size = Vector3.new(0.35, 0.35, 0.2), Color = rgb(10, 10, 10) },
				CFrame.new(x, 0.12, -0.5)
			)
		end
		attach(f, mask, { Size = Vector3.new(0.6, 0.12, 0.1), Color = rgb(10, 10, 10) }, CFrame.new(0, -0.38, -0.52))
	end,
	PumpkinHead = function(f, head)
		local pumpkin =
			attach(f, head, { Shape = Enum.PartType.Ball, Size = Vector3.new(2, 1.8, 2), Color = rgb(240, 120, 20) }, CFrame.new(0, 0.1, 0))
		for _, x in { -0.35, 0.35 } do
			attach(
				f,
				pumpkin,
				{ Size = Vector3.new(0.3, 0.3, 0.1), Color = rgb(255, 220, 90), Material = Enum.Material.Neon },
				CFrame.new(x, 0.2, -0.95)
			)
		end
		attach(
			f,
			pumpkin,
			{ Size = Vector3.new(0.9, 0.2, 0.1), Color = rgb(255, 220, 90), Material = Enum.Material.Neon },
			CFrame.new(0, -0.3, -0.92)
		)
		attach(f, pumpkin, { Size = Vector3.new(0.25, 0.5, 0.25), Color = rgb(60, 90, 30) }, CFrame.new(0, 1.05, 0))
		glow(pumpkin, rgb(255, 150, 40), 10)
	end,
	BatWings = function(f, _, torso)
		for _, x in { -1, 1 } do
			attach(
				f,
				torso,
				{ Size = Vector3.new(2.6, 1.6, 0.1), Color = rgb(25, 15, 30) },
				CFrame.new(x * 1.5, 0.5, 0.7) * CFrame.Angles(0, x * -0.5, x * 0.35)
			)
		end
	end,
	Halo = function(f, head)
		local ring = attach(
			f,
			head,
			{
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.15, 1.6, 1.6),
				Color = rgb(255, 240, 150),
				Material = Enum.Material.Neon,
			},
			CFrame.new(0, 1.4, 0) * CFrame.Angles(0, 0, math.rad(90))
		)
		glow(ring, rgb(255, 240, 160), 10)
	end,
	Crown = function(f, head)
		attach(
			f,
			head,
			{ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.45, 1.3, 1.3), Color = rgb(255, 200, 50), Material = Enum.Material.Foil },
			CFrame.new(0, 0.75, 0) * CFrame.Angles(0, 0, math.rad(90))
		)
		for i = 0, 5 do
			local a = i / 6 * math.pi * 2
			attach(
				f,
				head,
				{ Size = Vector3.new(0.2, 0.45, 0.2), Color = rgb(255, 200, 50), Material = Enum.Material.Foil },
				CFrame.new(math.cos(a) * 0.55, 1.1, math.sin(a) * 0.55)
			)
		end
		local gem = attach(
			f,
			head,
			{ Shape = Enum.PartType.Ball, Size = Vector3.one * 0.3, Color = rgb(255, 30, 60), Material = Enum.Material.Neon },
			CFrame.new(0, 0.8, -0.65)
		)
		glow(gem, rgb(255, 60, 80), 8)
	end,
}

function CosmeticService.Apply(player: Player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local torso = character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not head or not torso or not root then
		return
	end
	local old = character:FindFirstChild("Cosmetics")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Cosmetics"
	folder.Parent = character

	local hat = player:GetAttribute("Equip_Hat")
	if hat and HATS[hat] and Match.Role(player) ~= "Killer" then
		HATS[hat](folder, head, torso)
	end
	local trailId = player:GetAttribute("Equip_Trail")
	local item = trailId and Cosmetics.ById[trailId]
	if item then
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 0.8, 0.5)
		a0.Parent = root
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -1.2, 0.5)
		a1.Parent = root
		local trail = Instance.new("Trail")
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Lifetime = 0.6
		trail.LightEmission = 0.8
		trail.Color = ColorSequence.new(item.Colors[1], item.Colors[2])
		trail.Transparency = NumberSequence.new(0.2, 1)
		trail.Parent = folder
		if item.Rainbow then
			CollectionService:AddTag(trail, "RainbowTrail")
		end
		for _, attachment in { a0, a1 } do
			attachment.Name = "TrailAttachment"
		end
	end
end

function CosmeticService.Grant(player: Player, id: string): boolean
	local data = DataService.Get(player)
	if not data or not Cosmetics.ById[id] then
		return false
	end
	local isNew = not data.Owned[id]
	data.Owned[id] = true
	return isNew
end

function CosmeticService.GrantBundle(player: Player, key: string)
	local bundle = Cosmetics.Bundles[key]
	local data = DataService.Get(player)
	if not bundle or not data then
		return
	end
	if bundle.OneTime and data.StarterBought then
		-- Already bought once: give the tickets value of the items instead so nothing is wasted
		DataService.AddTickets(player, bundle.Tickets * 2, false)
		Remotes.notify(player, "You already own the Starter Pack, so you got " .. bundle.Tickets * 2 .. " 🎟️ instead!", "info")
		return
	end
	for _, id in bundle.Items do
		CosmeticService.Grant(player, id)
	end
	if bundle.OneTime then
		data.StarterBought = true
	end
	data.Tickets += bundle.Tickets or 0
	data.KillerChance += bundle.KillerChance or 0
	DataService.Sync(player)
	Remotes.notify(player, bundle.Name .. " unlocked! Check your Wardrobe.", "success")
end

local function equip(player: Player, id: string?)
	local data = DataService.Get(player)
	if not data then
		return false, "Not loaded yet."
	end
	local item = type(id) == "string" and Cosmetics.ById[id]
	if not item then
		return false, "Unknown item."
	end
	if not data.Owned[id] then
		return false, "You don't own that yet."
	end
	local slot = if item.Type == "Skin" then "Skin_" .. item.Killer else item.Type
	if data.Equipped[slot] == id then
		data.Equipped[slot] = nil -- clicking an equipped item takes it off
	else
		data.Equipped[slot] = id
	end
	DataService.Sync(player)
	if Match.Role(player) ~= "Killer" then
		CosmeticService.Apply(player)
	end
	return true, if data.Equipped[slot] then item.Name .. " equipped!" else item.Name .. " removed."
end

local function buy(player: Player, id: string?)
	local item = type(id) == "string" and Cosmetics.ById[id]
	local data = DataService.Get(player)
	if not item or not data then
		return false, "Unknown item."
	end
	if data.Owned[id] then
		return false, "You already own it."
	end
	if not item.Price then
		return false, "This item only comes in bundles and crates."
	end
	if not DataService.SpendTickets(player, item.Price) then
		return false, "You need " .. item.Price .. " 🎟️"
	end
	CosmeticService.Grant(player, id)
	DataService.Sync(player)
	equip(player, id)
	return true, "Bought " .. item.Name .. "!"
end

local function openCrate(player: Player)
	local data = DataService.Get(player)
	if not data then
		return false, "Not loaded yet."
	end
	if not DataService.SpendTickets(player, Cosmetics.Crate.Price) then
		return false, "You need " .. Cosmetics.Crate.Price .. " 🎟️"
	end
	local id = Cosmetics.RollCrate(rng)
	local item = Cosmetics.ById[id]
	local isNew = CosmeticService.Grant(player, id)
	if not isNew then
		data.Tickets += Cosmetics.Crate.DuplicateRefund
	end
	DataService.Sync(player)
	if item.Rarity == "Legendary" then
		Remotes.announce("✨ " .. player.DisplayName .. " unboxed a LEGENDARY " .. item.Name .. "!", Cosmetics.Rarities.Legendary.Color)
	end
	return true,
		if isNew
			then "You got: " .. item.Name .. " (" .. item.Rarity .. ")!"
			else "Duplicate " .. item.Name .. ": +" .. Cosmetics.Crate.DuplicateRefund .. " 🎟️ back",
		id
end

function CosmeticService.Init()
	Remotes.Equip.OnServerInvoke = equip
	Remotes.BuyCosmetic.OnServerInvoke = buy
	Remotes.OpenCrate.OnServerInvoke = openCrate
end

return CosmeticService
