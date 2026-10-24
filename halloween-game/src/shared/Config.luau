-- Central game configuration. Tweak numbers here to balance the game.
-- IMPORTANT: replace every `Id = 0` with your real Game Pass / Developer Product IDs
-- (Creator Dashboard -> your experience -> Monetization). See GUIDE.md.

local Config = {}

Config.GameName = "Survive The Hollow"
Config.DataStoreName = "SurviveTheHollow_v1"
Config.AutoSaveInterval = 90

-- In Studio, pretend the player owns every game pass (handy for testing).
Config.StudioGrantAllPasses = false

Config.Nights = 5
Config.BloodMoonNight = 5 -- two monsters on this night
Config.IntermissionTime = 20
Config.DawnTime = 20
Config.EndScreenTime = 10
Config.NightLength = { 120, 140, 160, 180, 200 }

Config.Monster = {
	BaseSpeed = 13,
	SpeedPerNight = 1.5,
	EnragedMultiplier = 1.3, -- when the bonfire is out
	HauntedMultiplier = 1.2, -- while chasing a haunted / tricked player
	KillRange = 4.5,
	RepathInterval = 0.4,
	StunNeeded = 1.2, -- seconds of lantern light needed to scare it
	StunTime = 4,
	FleeSpeed = 22,
	PauseAfterHit = 2,
}

Config.Bonfire = {
	MaxFuel = 120,
	StartFuel = 90,
	DawnRefuel = 30,
	LogFuel = 25,
	DrainPerSec = 1,
	MinRadius = 8,
	RadiusPerFuel = 0.16,
}

Config.Flashlight = {
	BaseRange = 30,
	RangePerLevel = 6,
	ConeDegrees = 22,
	BaseBattery = 40,
	BatteryPerLevel = 15,
	DrainPerSec = 1,
	RechargePerSecInLight = 4,
}

Config.Movement = {
	WalkSpeed = 16,
	SprintSpeed = 24,
	BaseStamina = 4,
	StaminaPerLevel = 1.2,
	StaminaRegenPerSec = 1,
	CarryMultiplier = 0.75,
	DownedSpeed = 3,
}

Config.Downed = {
	BleedOut = 30,
	ReviveHold = 3,
	ReviveReward = 15,
}

Config.Rewards = {
	NightSurvived = { 20, 40, 60, 90, 130 },
	Escape = 500,
	ScareMonster = 5,
	LogDelivered = 10,
	CandyPickup = { 3, 8 },
}

Config.Pickups = {
	Candy = 45,
	Batteries = 10,
	Logs = 14,
	RespawnTime = 25,
}

Config.Doors = {
	Cooldown = 45,
	TrickChance = 0.15,
	TrickChaseTime = 10,
}

Config.Multipliers = {
	VIP = 1.5,
	DoubleCandy = 2,
}

-- Upgrades bought with Candy (the free currency). Costs per level.
Config.Upgrades = {
	Lantern = { Name = "🔦 Lantern Range", Description = "Your light reaches farther.", Costs = { 100, 250, 600, 1500, 4000 } },
	Battery = { Name = "🔋 Battery Size", Description = "Your lantern lasts longer.", Costs = { 100, 250, 600, 1500, 4000 } },
	Stamina = { Name = "👟 Stamina", Description = "Sprint for longer.", Costs = { 80, 200, 500, 1200, 3000 } },
}
Config.UpgradeOrder = { "Lantern", "Battery", "Stamina" }

-- Game passes: one-time purchases, owned forever.
Config.GamePasses = {
	DoubleCandy = { Id = 0, Name = "🍬 2x Candy", Description = "Double all candy you earn, forever.", Price = 299 },
	VIP = { Id = 0, Name = "👑 VIP", Description = "+50% candy and a gold [VIP] chat tag.", Price = 199 },
	InfiniteBattery = { Id = 0, Name = "🔦 Infinite Battery", Description = "Your lantern never runs out.", Price = 249 },
	SecondWind = { Id = 0, Name = "💖 Second Wind", Description = "Get back up for free once every night.", Price = 199 },
	MonsterRadar = { Id = 0, Name = "📡 Monster Radar", Description = "Always see where The Hollow is and how close.", Price = 149 },
}
Config.PassOrder = { "InfiniteBattery", "SecondWind", "DoubleCandy", "MonsterRadar", "VIP" }

-- Developer products: can be bought again and again.
Config.Products = {
	SelfRevive = { Id = 0, Name = "💖 Revive", Description = "Get back up right now. Saved for later if you're fine.", Price = 25 },
	BonfireRefill = { Id = 0, Name = "🔥 Refill Bonfire", Description = "Instantly fill the bonfire for the whole team.", Price = 19 },
	ServerDaylight = {
		Id = 0,
		Name = "☀️ Daylight",
		Description = "30 seconds of sunlight. The Hollow hides, everyone is safe.",
		Price = 99,
	},
	HauntPlayer = {
		Id = 0,
		Name = "👻 Haunt a Player",
		Description = "Send The Hollow after a player of your choice for 20s.",
		Price = 49,
	},
	CandySmall = { Id = 0, Name = "🍬 Candy Bag", Description = "300 candy.", Price = 25 },
	CandyLarge = { Id = 0, Name = "🍬 Candy Bucket", Description = "1,500 candy.", Price = 99 },
	CandyHuge = { Id = 0, Name = "🍬 Candy Cauldron", Description = "6,000 candy.", Price = 299 },
}
Config.ProductOrder = { "SelfRevive", "BonfireRefill", "ServerDaylight", "HauntPlayer", "CandySmall", "CandyLarge", "CandyHuge" }

Config.CandyPacks = { CandySmall = 300, CandyLarge = 1500, CandyHuge = 6000 }
Config.DaylightDuration = 30
Config.HauntDuration = 20

return Config
