-- Every critter in the game, their rarities, and mutations.
local Critters = {}

local rgb = Color3.fromRGB

Critters.Rarities = {
	Common = { Order = 1, Weight = 55, Color = rgb(210, 210, 210) },
	Uncommon = { Order = 2, Weight = 26, Color = rgb(90, 220, 90) },
	Rare = { Order = 3, Weight = 12, Color = rgb(70, 150, 255) },
	Epic = { Order = 4, Weight = 5, Color = rgb(185, 95, 255) },
	Legendary = { Order = 5, Weight = 1.6, Color = rgb(255, 190, 40) },
	Mythic = { Order = 6, Weight = 0.4, Color = rgb(255, 60, 90) },
	-- Secret critters ONLY appear during Moon Raids.
	Secret = { Order = 7, Weight = 0, RaidWeight = 0.25, Color = rgb(0, 255, 230) },
}
Critters.RarityList = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" }

Critters.Mutations = {
	None = { Multiplier = 1, Chance = 0 },
	Gold = { Multiplier = 2, Chance = 0.04, Color = rgb(255, 205, 50), Material = Enum.Material.Foil },
	Diamond = { Multiplier = 5, Chance = 0.01, Color = rgb(120, 230, 255), Material = Enum.Material.Glass },
	Moonlit = { Multiplier = 3, Chance = 0, RaidChance = 0.25, Color = rgb(170, 190, 255), Material = Enum.Material.Neon },
	Rainbow = { Multiplier = 10, Chance = 0.002, RaidChance = 0.004, Material = Enum.Material.Neon },
}
-- Rolled in this order; first hit wins.
Critters.MutationOrder = { "Rainbow", "Diamond", "Moonlit", "Gold" }

Critters.List = {
	-- Common
	{ Id = "Puddlepup", Rarity = "Common", Price = 25, Income = 1, Size = 2.6, Color = rgb(120, 170, 230), Accent = rgb(70, 110, 180) },
	{ Id = "Snorbit", Rarity = "Common", Price = 60, Income = 2, Size = 2.7, Color = rgb(240, 170, 120), Accent = rgb(200, 110, 70) },
	{ Id = "Mossbean", Rarity = "Common", Price = 120, Income = 4, Size = 2.8, Color = rgb(110, 170, 90), Accent = rgb(70, 120, 50) },
	{ Id = "Pebblet", Rarity = "Common", Price = 200, Income = 6, Size = 2.9, Color = rgb(150, 150, 160), Accent = rgb(100, 100, 110) },
	-- Uncommon
	{ Id = "Zapling", Rarity = "Uncommon", Price = 500, Income = 12, Size = 3.1, Color = rgb(255, 240, 90), Accent = rgb(230, 170, 20) },
	{
		Id = "Fizzlewhisk",
		Rarity = "Uncommon",
		Price = 900,
		Income = 20,
		Size = 3.2,
		Color = rgb(250, 140, 200),
		Accent = rgb(200, 80, 150),
	},
	{ Id = "Toastlet", Rarity = "Uncommon", Price = 1_500, Income = 32, Size = 3.3, Color = rgb(215, 160, 90), Accent = rgb(140, 90, 40) },
	-- Rare
	{ Id = "Glimmerfin", Rarity = "Rare", Price = 4_000, Income = 75, Size = 3.5, Color = rgb(80, 210, 220), Accent = rgb(30, 140, 170) },
	{ Id = "Grumbleroot", Rarity = "Rare", Price = 8_000, Income = 140, Size = 3.6, Color = rgb(130, 90, 60), Accent = rgb(80, 160, 60) },
	{
		Id = "Cloudmunch",
		Rarity = "Rare",
		Price = 15_000,
		Income = 250,
		Size = 3.8,
		Color = rgb(245, 245, 255),
		Accent = rgb(170, 190, 230),
	},
	-- Epic
	{ Id = "Blazetail", Rarity = "Epic", Price = 45_000, Income = 650, Size = 4.1, Color = rgb(255, 110, 40), Accent = rgb(255, 210, 60) },
	{
		Id = "Frostnibble",
		Rarity = "Epic",
		Price = 90_000,
		Income = 1_200,
		Size = 4.2,
		Color = rgb(180, 230, 255),
		Accent = rgb(90, 160, 230),
	},
	{
		Id = "Thundermoo",
		Rarity = "Epic",
		Price = 160_000,
		Income = 2_000,
		Size = 4.4,
		Color = rgb(110, 90, 200),
		Accent = rgb(255, 230, 80),
	},
	-- Legendary
	{
		Id = "Starwhale",
		Rarity = "Legendary",
		Price = 500_000,
		Income = 5_500,
		Size = 4.8,
		Color = rgb(40, 60, 140),
		Accent = rgb(255, 240, 150),
	},
	{
		Id = "Chronoquack",
		Rarity = "Legendary",
		Price = 1_200_000,
		Income = 12_000,
		Size = 5.0,
		Color = rgb(250, 220, 100),
		Accent = rgb(120, 80, 30),
	},
	{
		Id = "Voidpuff",
		Rarity = "Legendary",
		Price = 2_500_000,
		Income = 23_000,
		Size = 5.2,
		Color = rgb(30, 20, 50),
		Accent = rgb(190, 80, 255),
	},
	-- Mythic
	{
		Id = "Lunaroth",
		Rarity = "Mythic",
		Price = 8_000_000,
		Income = 65_000,
		Size = 5.8,
		Color = rgb(200, 210, 255),
		Accent = rgb(120, 130, 220),
	},
	{
		Id = "Solflare",
		Rarity = "Mythic",
		Price = 20_000_000,
		Income = 150_000,
		Size = 6.0,
		Color = rgb(255, 150, 30),
		Accent = rgb(255, 60, 30),
	},
	-- Secret (Moon Raid only)
	{
		Id = "MoonEmperor",
		Name = "Moon Emperor Bonk",
		Rarity = "Secret",
		Price = 100_000_000,
		Income = 700_000,
		Size = 6.8,
		Color = rgb(235, 235, 255),
		Accent = rgb(255, 215, 0),
	},
	{
		Id = "CosmicJellyking",
		Name = "Cosmic Jellyking",
		Rarity = "Secret",
		Price = 250_000_000,
		Income = 1_600_000,
		Size = 7.2,
		Color = rgb(255, 120, 230),
		Accent = rgb(90, 255, 240),
	},
}

Critters.ById = {}
Critters.ByRarity = {}
for _, def in Critters.List do
	def.Name = def.Name or def.Id
	Critters.ById[def.Id] = def
	Critters.ByRarity[def.Rarity] = Critters.ByRarity[def.Rarity] or {}
	table.insert(Critters.ByRarity[def.Rarity], def)
end

function Critters.RarityOf(id: string)
	return Critters.Rarities[Critters.ById[id].Rarity]
end

-- Picks a random critter id. `luck` multiplies the weight of Rare and above.
function Critters.Roll(luck: number, isRaid: boolean, rng: Random): string
	local weights = {}
	local total = 0
	for _, name in Critters.RarityList do
		local rarity = Critters.Rarities[name]
		local w = if isRaid then (rarity.RaidWeight or rarity.Weight) else rarity.Weight
		if rarity.Order >= 3 then
			w *= luck
		end
		weights[name] = w
		total += w
	end
	local roll = rng:NextNumber() * total
	local picked = "Common"
	for _, name in Critters.RarityList do
		if weights[name] > 0 then
			roll -= weights[name]
			if roll <= 0 then
				picked = name
				break
			end
		end
	end
	local pool = Critters.ByRarity[picked]
	return pool[rng:NextInteger(1, #pool)].Id
end

function Critters.RollMutation(isRaid: boolean, rng: Random): string
	for _, name in Critters.MutationOrder do
		local m = Critters.Mutations[name]
		local chance = if isRaid then (m.RaidChance or m.Chance) else m.Chance
		if rng:NextNumber() < chance then
			return name
		end
	end
	return "None"
end

function Critters.MutationMultiplier(mutation: string?): number
	local m = Critters.Mutations[mutation or "None"]
	return if m then m.Multiplier else 1
end

function Critters.Income(id: string, mutation: string?): number
	return Critters.ById[id].Income * Critters.MutationMultiplier(mutation)
end

-- Mutated critters cost more, but less than the income boost they give: they're a deal.
function Critters.Price(id: string, mutation: string?): number
	local m = Critters.MutationMultiplier(mutation)
	return math.floor(Critters.ById[id].Price * (1 + (m - 1) * 0.5))
end

function Critters.DisplayName(id: string, mutation: string?): string
	local name = Critters.ById[id].Name
	if mutation and mutation ~= "None" then
		return mutation .. " " .. name
	end
	return name
end

return Critters
