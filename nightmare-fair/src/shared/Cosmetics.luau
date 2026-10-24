-- Every cosmetic in the game: survivor hats, trails and killer skins, plus Robux bundles and the Mystery Crate.
local Cosmetics = {}

local rgb = Color3.fromRGB

Cosmetics.Rarities = {
	Common = { Order = 1, Color = rgb(200, 200, 200) },
	Rare = { Order = 2, Color = rgb(80, 160, 255) },
	Epic = { Order = 3, Color = rgb(190, 90, 255) },
	Legendary = { Order = 4, Color = rgb(255, 190, 40) },
}

-- Price = tickets in the shop. nil means bundle / crate only.
Cosmetics.Items = {
	-- Hats & masks (survivors)
	{ Id = "CatEars", Type = "Hat", Name = "Black Cat Ears", Rarity = "Common", Price = 300 },
	{ Id = "TopHat", Type = "Hat", Name = "Midnight Top Hat", Rarity = "Common", Price = 400 },
	{ Id = "CandleHat", Type = "Hat", Name = "Candle Hat", Rarity = "Rare", Price = 900 },
	{ Id = "DevilHorns", Type = "Hat", Name = "Devil Horns", Rarity = "Rare", Price = 1200 },
	{ Id = "WitchHat", Type = "Hat", Name = "Witch Hat", Rarity = "Epic" },
	{ Id = "SkullMask", Type = "Hat", Name = "Skull Mask", Rarity = "Epic", Price = 2500 },
	{ Id = "PumpkinHead", Type = "Hat", Name = "Pumpkin Head", Rarity = "Epic" },
	{ Id = "BatWings", Type = "Hat", Name = "Bat Wings", Rarity = "Epic" },
	{ Id = "Halo", Type = "Hat", Name = "Survivor's Halo", Rarity = "Legendary" },
	{ Id = "Crown", Type = "Hat", Name = "Crown of the Fair", Rarity = "Legendary" },

	-- Trails (everyone)
	{
		Id = "TrailCandy",
		Type = "Trail",
		Name = "Candy Corn Trail",
		Rarity = "Common",
		Price = 350,
		Colors = { rgb(255, 240, 200), rgb(255, 150, 30) },
	},
	{
		Id = "TrailGhost",
		Type = "Trail",
		Name = "Ghostly Trail",
		Rarity = "Rare",
		Price = 1000,
		Colors = { rgb(180, 220, 255), rgb(255, 255, 255) },
	},
	{ Id = "TrailToxic", Type = "Trail", Name = "Toxic Trail", Rarity = "Rare", Colors = { rgb(120, 255, 60), rgb(30, 120, 20) } },
	{ Id = "TrailBlood", Type = "Trail", Name = "Blood Trail", Rarity = "Epic", Price = 2200, Colors = { rgb(200, 0, 20), rgb(60, 0, 0) } },
	{ Id = "TrailFire", Type = "Trail", Name = "Hellfire Trail", Rarity = "Epic", Colors = { rgb(255, 220, 60), rgb(255, 40, 0) } },
	{
		Id = "TrailRainbow",
		Type = "Trail",
		Name = "Rainbow Trail",
		Rarity = "Legendary",
		Colors = { rgb(255, 60, 60), rgb(60, 140, 255) },
		Rainbow = true,
	},

	-- Killer skins
	{
		Id = "RingmasterBloody",
		Type = "Skin",
		Killer = "Ringmaster",
		Name = "Bloody Ringmaster",
		Rarity = "Rare",
		Price = 1500,
		Mask = rgb(230, 210, 205),
		Accent = rgb(140, 0, 10),
		Material = Enum.Material.SmoothPlastic,
	},
	{
		Id = "RingmasterGolden",
		Type = "Skin",
		Killer = "Ringmaster",
		Name = "Golden Ringmaster",
		Rarity = "Legendary",
		Mask = rgb(255, 200, 60),
		Accent = rgb(255, 230, 120),
		Material = Enum.Material.Foil,
	},
	{
		Id = "ButcherToxic",
		Type = "Skin",
		Killer = "Butcher",
		Name = "Toxic Butcher",
		Rarity = "Rare",
		Price = 1500,
		Mask = rgb(90, 140, 60),
		Accent = rgb(140, 255, 60),
		Material = Enum.Material.Fabric,
	},
	{
		Id = "ButcherInferno",
		Type = "Skin",
		Killer = "Butcher",
		Name = "Inferno Butcher",
		Rarity = "Legendary",
		Mask = rgb(40, 20, 20),
		Accent = rgb(255, 90, 0),
		Material = Enum.Material.CrackedLava,
	},
	{
		Id = "PhantomCrimson",
		Type = "Skin",
		Killer = "Phantom",
		Name = "Crimson Phantom",
		Rarity = "Epic",
		Price = 3000,
		Mask = rgb(255, 230, 230),
		Accent = rgb(255, 30, 60),
		Material = Enum.Material.Glass,
	},
	{
		Id = "PhantomVoid",
		Type = "Skin",
		Killer = "Phantom",
		Name = "Void Phantom",
		Rarity = "Legendary",
		Mask = rgb(20, 20, 30),
		Accent = rgb(170, 90, 255),
		Material = Enum.Material.Neon,
	},
}

Cosmetics.ById = {}
for _, item in Cosmetics.Items do
	Cosmetics.ById[item.Id] = item
end

-- Robux bundles. The ProductKey matches Config.Products.
Cosmetics.Bundles = {
	PackStarter = {
		Name = "🎁 Starter Pack",
		Badge = "ONE TIME · BEST VALUE",
		Items = { "TopHat", "TrailCandy" },
		Tickets = 1500,
		KillerChance = 3,
		OneTime = true,
	},
	PackHalloween = {
		Name = "🎃 Halloween Pack",
		Badge = "LIMITED · HALLOWEEN",
		Items = { "PumpkinHead", "WitchHat", "TrailFire" },
		Tickets = 2000,
	},
	PackKiller = {
		Name = "🔪 Killer Pack",
		Badge = "FOR KILLER MAINS",
		Items = { "RingmasterGolden", "ButcherInferno", "TrailToxic" },
		Tickets = 1000,
		KillerChance = 10,
	},
	PackLegendary = {
		Name = "👑 Legendary Pack",
		Badge = "EVERYTHING RARE",
		Items = { "Crown", "Halo", "BatWings", "TrailRainbow", "PhantomVoid" },
		Tickets = 5000,
		KillerChance = 10,
	},
}
Cosmetics.BundleOrder = { "PackStarter", "PackHalloween", "PackKiller", "PackLegendary" }

-- Mystery Crate, bought with tickets. Odds are shown in the shop (required by Roblox for random items).
Cosmetics.Crate = {
	Price = 600,
	Odds = { Common = 55, Rare = 30, Epic = 12, Legendary = 3 },
	DuplicateRefund = 250, -- tickets back if you already own what you rolled
}

function Cosmetics.RollCrate(rng: Random): string
	local roll = rng:NextNumber() * 100
	local rarity = "Common"
	for _, name in { "Legendary", "Epic", "Rare", "Common" } do
		local chance = Cosmetics.Crate.Odds[name]
		if roll < chance then
			rarity = name
			break
		end
		roll -= chance
	end
	local pool = {}
	for _, item in Cosmetics.Items do
		if item.Rarity == rarity then
			table.insert(pool, item.Id)
		end
	end
	return pool[rng:NextInteger(1, #pool)]
end

return Cosmetics
