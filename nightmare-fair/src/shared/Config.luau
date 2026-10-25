-- Central game configuration. Tweak numbers here to balance the game.
-- IMPORTANT: replace every `Id = 0` with your real Game Pass / Developer Product IDs
-- (Creator Dashboard -> your experience -> Monetization). See GUIDE.md.

local Config = {}

Config.GameName = "Nightmare Fair"
Config.DataStoreName = "NightmareFair_v1"
Config.AutoSaveInterval = 90

-- In Studio, pretend the player owns every game pass (handy for testing).
Config.StudioGrantAllPasses = false

Config.MinPlayers = 1 -- alone? the AI killer hunts you
Config.IntermissionTime = 25
Config.MatchTime = 420 -- 7 minutes
Config.EndGameCollapse = 120 -- after the gates are powered
Config.ResultsTime = 10

Config.Speeds = {
	Survivor = 16,
	Injured = 16,
	HitBoost = 24, -- the burst of speed right after being hit
	HitBoostTime = 2,
	Crawl = 3,
	Killer = 18,
	KillerAfterHit = 8, -- killer wipes the blade after a hit
	KillerAfterHitTime = 1.6,
	KillerCarrying = 15,
	Ghost = 20,
}

Config.Attack = {
	Range = 7.5,
	Cooldown = 1.4,
	ArcDot = 0.35, -- how wide the swing is (lower = wider)
}

Config.Pumpkins = {
	Total = 7,
	Needed = 5,
	WorkSeconds = 70, -- for one survivor working alone
	CoopBonus = 0.8, -- each extra helper adds 80% speed
	WorkRange = 7,
	SkillCheckMin = 5,
	SkillCheckMax = 11,
	GreatBonus = 2, -- seconds of progress added for a GREAT skill check
	MissPenalty = 6, -- seconds of progress lost on a miss
}

Config.Gates = {
	OpenTime = 8,
}

Config.Heal = {
	HoldTime = 6,
}

Config.Cage = {
	Stages = { 60, 40 }, -- seconds before elimination on the 1st and 2nd caging; 3rd caging eliminates
	RescueHold = 1.5,
	WiggleTime = 16, -- a carried survivor breaks free after this long
}

Config.Pallet = {
	StunRadius = 6,
	StunTime = 2.2,
	BreakTime = 2.2,
}

Config.Bells = {
	RevealTime = 6,
	Cooldown = 30,
}

-- Killers: id -> settings. "Price" is in tickets; PassKey means it's unlocked by a game pass instead.
Config.Killers = {
	Ringmaster = {
		Name = "The Ringmaster",
		Description = "Sets bear traps. Survivors who step in are stuck and revealed.",
		Ability = "Bear Trap",
		Cooldown = 8,
		MaxTraps = 4,
		TrapTime = 4,
		Price = 0,
		Color = Color3.fromRGB(200, 30, 50),
	},
	Butcher = {
		Name = "The Butcher",
		Description = "Charges forward at high speed and injures whoever he slams into.",
		Ability = "Charge",
		Cooldown = 14,
		ChargeTime = 1.2,
		ChargeSpeed = 34,
		Price = 750,
		Color = Color3.fromRGB(150, 110, 70),
	},
	Phantom = {
		Name = "The Phantom",
		Description = "Vanishes for 6 seconds and moves faster while unseen. Can't attack while invisible.",
		Ability = "Vanish",
		Cooldown = 24,
		VanishTime = 6,
		VanishSpeed = 23,
		Price = 2500,
		PassKey = "Phantom",
		Color = Color3.fromRGB(120, 200, 255),
	},
}
Config.Killers.Banshee = {
	Name = "The Banshee",
	Description = "Floats above the ground and blinks through the air to appear right next to you.",
	Ability = "Blink",
	Cooldown = 7,
	BlinkDistance = 24,
	BlinkFatigue = 1.3,
	Price = 1500,
	Color = Color3.fromRGB(170, 225, 255),
}
Config.KillerOrder = { "Ringmaster", "Banshee", "Butcher", "Phantom" }

Config.Rewards = {
	PumpkinLit = 20,
	GreatSkillCheck = 2,
	Heal = 10,
	Rescue = 25,
	PalletStun = 10,
	Escape = 120,
	Survived = 40, -- per minute alive, given at the end (divided by 60 per second)
	BellReveal = 5,
	KillerHit = 5,
	KillerDown = 10,
	KillerCage = 20,
	KillerElimination = 40,
	KillerWin = 120, -- 3+ eliminations
	Participation = 15,
}

Config.KillerChance = {
	PerRound = 1,
	Start = 1,
}

Config.Multipliers = {
	VIP = 1.25,
	DoubleTickets = 2,
}

Config.GamePasses = {
	Phantom = { Id = 0, Name = "👻 The Phantom", Description = "Unlock the invisible killer forever.", Price = 399 },
	DoubleTickets = { Id = 0, Name = "🎟️ 2x Tickets", Description = "Double all tickets you earn.", Price = 299 },
	VIP = { Id = 0, Name = "👑 VIP", Description = "+25% tickets, +1 extra Killer Chance every round, gold chat tag.", Price = 249 },
}
Config.PassOrder = { "Phantom", "DoubleTickets", "VIP" }

Config.Products = {
	KillerChance = { Id = 0, Name = "🔪 +5 Killer Chance", Description = "Much better odds of being the killer next round.", Price = 49 },
	SelfRescue = {
		Id = 0,
		Name = "🗝️ Break Out",
		Description = "Escape the Crow Cage yourself (use it when you're caged).",
		Price = 35,
	},
	TicketsSmall = { Id = 0, Name = "🎟️ 500 Tickets", Description = "Unlock killers faster.", Price = 25 },
	TicketsLarge = { Id = 0, Name = "🎟️ 3,000 Tickets", Description = "Unlock killers faster.", Price = 99 },
	TicketsHuge = { Id = 0, Name = "🎟️ 12,000 Tickets", Description = "Best ticket value.", Price = 299 },
	-- Bundles (contents are in Cosmetics.Bundles)
	PackStarter = {
		Id = 0,
		Name = "🎁 Starter Pack",
		Description = "Top Hat, Candy Corn Trail, 1,500 tickets, +3 Killer Chance.",
		Price = 49,
	},
	PackHalloween = {
		Id = 0,
		Name = "🎃 Halloween Pack",
		Description = "Pumpkin Head, Witch Hat, Hellfire Trail, 2,000 tickets.",
		Price = 199,
	},
	PackKiller = {
		Id = 0,
		Name = "🔪 Killer Pack",
		Description = "Golden Ringmaster, Inferno Butcher, Toxic Trail, +10 Killer Chance.",
		Price = 249,
	},
	PackLegendary = {
		Id = 0,
		Name = "👑 Legendary Pack",
		Description = "Crown, Halo, Bat Wings, Rainbow Trail, Void Phantom, 5,000 tickets.",
		Price = 499,
	},
}
Config.ProductOrder = { "KillerChance", "SelfRescue", "TicketsSmall", "TicketsLarge", "TicketsHuge" }
Config.TicketPacks = { TicketsSmall = 500, TicketsLarge = 3000, TicketsHuge = 12000 }
Config.KillerChancePack = 5

-- Music & sound effects. The files are in the audio/ folder of the project:
-- upload each one in the Creator Hub (Development Items -> Audio), then paste its ID here.
Config.Sounds = {
	LobbyMusic = { Id = 0, Volume = 0.45, File = "lobby_music.ogg" },
	Ambience = { Id = 0, Volume = 0.5, File = "ambience.ogg" },
	TerrorRadius = { Id = 0, Volume = 0.9, File = "terror_heartbeat.ogg" },
	ChaseMusic = { Id = 0, Volume = 0.7, File = "chase_music.ogg" },
	SkillCheck = { Id = 0, Volume = 0.6, File = "sfx_skillcheck.ogg" },
	Great = { Id = 0, Volume = 0.6, File = "sfx_great.ogg" },
	PumpkinLit = { Id = 0, Volume = 0.7, File = "sfx_pumpkin_lit.ogg" },
	Hit = { Id = 0, Volume = 0.9, File = "sfx_hit.ogg" },
	Pallet = { Id = 0, Volume = 1, File = "sfx_pallet.ogg" },
	CageScream = { Id = 0, Volume = 0.9, File = "sfx_cage_scream.ogg" },
	GateAlarm = { Id = 0, Volume = 0.6, File = "sfx_gate_alarm.ogg" },
	Blink = { Id = 0, Volume = 0.9, File = "sfx_blink.ogg" },
}
Config.TerrorRadius = 45 -- studs: the heartbeat starts here
Config.ChaseRadius = 22 -- studs: chase music kicks in here

-- Real 3D looks for the killers from the Roblox Marketplace (roblox.com/catalog).
-- Open an item, copy the number from its web address, and paste it below.
-- Several accessories in one slot: separate with commas, e.g. "123,456".
-- Leave everything empty to keep the built-in costume.
-- Animations: Marketplace animation items (e.g. a zombie run) for player killers; the AI uses Roblox's defaults.
Config.KillerLooks = {
	Ringmaster = {
		Hat = "",
		Face = "",
		Back = "",
		Front = "",
		Neck = "",
		Shoulder = "",
		Waist = "",
		Shirt = 0,
		Pants = 0,
		FaceDecal = 0,
		Animations = { Run = 0, Walk = 0, Idle = 0 },
	},
	Butcher = {
		Hat = "",
		Face = "",
		Back = "",
		Front = "",
		Neck = "",
		Shoulder = "",
		Waist = "",
		Shirt = 0,
		Pants = 0,
		FaceDecal = 0,
		Animations = { Run = 0, Walk = 0, Idle = 0 },
	},
	Banshee = {
		Hat = "",
		Face = "",
		Back = "",
		Front = "",
		Neck = "",
		Shoulder = "",
		Waist = "",
		Shirt = 0,
		Pants = 0,
		FaceDecal = 0,
		Animations = { Run = 0, Walk = 0, Idle = 0 },
	},
	Phantom = {
		Hat = "",
		Face = "",
		Back = "",
		Front = "",
		Neck = "",
		Shoulder = "",
		Waist = "",
		Shirt = 0,
		Pants = 0,
		FaceDecal = 0,
		Animations = { Run = 0, Walk = 0, Idle = 0 },
	},
}

return Config
