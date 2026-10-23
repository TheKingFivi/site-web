-- Central game configuration. Tweak numbers here to balance the game.
-- IMPORTANT: replace every `Id = 0` with your real Game Pass / Developer Product IDs
-- (Creator Dashboard -> your experience -> Monetization). See GUIDE.md.

local Config = {}

Config.GameName = "Moonlight Critter Heist"
Config.DataStoreName = "CritterHeist_v1"
Config.AutoSaveInterval = 90

-- In Studio, pretend the player owns every game pass (handy for testing).
Config.StudioGrantAllPasses = false

Config.StartingCash = 100
Config.SellRatio = 0.5 -- selling a critter refunds 50% of its price

Config.Slots = {
	Base = 8,
	PerRebirth = 1,
	ExtraSlotsPass = 4,
	Max = 20, -- each plot has 20 pedestals
}

Config.Rebirth = {
	BaseCost = 1_000_000,
	CostMultiplier = 3,
	IncomeBonus = 0.5, -- +50% income per rebirth
}

Config.Lock = {
	Duration = 45,
	Cooldown = 90,
}

Config.MoonRaid = {
	Interval = 480, -- seconds of daytime between raids
	Duration = 120, -- raid length
}

Config.Steal = {
	HoldTime = 1.5,
	FastHoldTime = 0.6,
	NormalSpeed = 16,
	CarrySpeed = 12,
	FastCarrySpeed = 18,
	CatchDistance = 7,
	MaxCarryTime = 90,
}

Config.Conveyor = {
	SpawnInterval = 2.5,
	WalkSpeed = 7,
	StartX = -200,
	EndX = 200,
	RoadTop = 0.4,
}

Config.ServerLuck = {
	Multiplier = 3,
	Duration = 15 * 60,
}

Config.RaidShieldDuration = 10 * 60

Config.FriendBoost = {
	PerFriend = 0.1, -- +10% income per friend in the server
	Max = 0.5,
}

Config.OfflineEarnings = {
	MaxHours = 2,
	Rate = 0.25, -- earn 25% of normal income while offline
}

Config.Daily = {
	Cooldown = 20 * 3600,
	StreakReset = 48 * 3600,
	Rewards = { 500, 1_000, 2_500, 5_000, 10_000, 25_000, 100_000 }, -- multiplied by (1 + rebirths)
}

Config.Multipliers = {
	VIP = 1.25,
	DoubleCash = 2,
}

-- Game passes: one-time purchases, owned forever.
Config.GamePasses = {
	VIP = {
		Id = 0,
		Name = "👑 VIP",
		Description = "+25% income forever, golden [VIP] chat tag.",
		Price = 199,
	},
	DoubleCash = {
		Id = 0,
		Name = "💸 2x Cash",
		Description = "Double ALL critter income, forever.",
		Price = 299,
	},
	ExtraSlots = {
		Id = 0,
		Name = "🧱 +4 Base Slots",
		Description = "Hold 4 more critters in your base.",
		Price = 149,
	},
	FastThief = {
		Id = 0,
		Name = "🥷 Fast Thief",
		Description = "Steal 2.5x faster and run faster while carrying.",
		Price = 99,
	},
	AutoCollect = {
		Id = 0,
		Name = "🤖 Auto Collect",
		Description = "Income goes straight to your wallet, even while robbing others.",
		Price = 129,
	},
}
Config.PassOrder = { "DoubleCash", "VIP", "ExtraSlots", "AutoCollect", "FastThief" }

-- Developer products: can be bought again and again.
Config.Products = {
	CashSmall = {
		Id = 0,
		Name = "💰 Cash Pouch",
		Description = "5 minutes of income (min $5K x rebirth level).",
		Price = 25,
	},
	CashMedium = {
		Id = 0,
		Name = "💰 Cash Sack",
		Description = "30 minutes of income (min $50K x rebirth level).",
		Price = 99,
	},
	CashLarge = {
		Id = 0,
		Name = "💰 Cash Vault",
		Description = "3 hours of income (min $500K x rebirth level).",
		Price = 349,
	},
	ServerLuck = {
		Id = 0,
		Name = "🍀 Server Luck x3",
		Description = "15 minutes of 3x rare critters for EVERYONE in the server.",
		Price = 149,
	},
	RaidShield = {
		Id = 0,
		Name = "🛡️ Raid Shield",
		Description = "10 minutes of protection that even works during Moon Raids.",
		Price = 49,
	},
	MythicEgg = {
		Id = 0,
		Name = "🥚 Mythic Egg",
		Description = "Instantly get a random Mythic critter (10% Secret!).",
		Price = 399,
	},
}
Config.ProductOrder = { "CashSmall", "CashMedium", "CashLarge", "ServerLuck", "RaidShield", "MythicEgg" }

-- Cash packs: { minimum base amount, seconds of current income }
Config.CashPacks = {
	CashSmall = { 5_000, 5 * 60 },
	CashMedium = { 50_000, 30 * 60 },
	CashLarge = { 500_000, 3 * 3600 },
}

return Config
