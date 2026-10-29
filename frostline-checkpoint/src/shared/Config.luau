-- Frostline Checkpoint: central configuration. Tweak numbers here to balance the game.
-- IMPORTANT: replace every `Id = 0` with your real Game Pass / Developer Product / Sound IDs. See GUIDE.md.

local Config = {}

Config.GameName = "Frostline Checkpoint"
Config.DataStoreName = "FrostlineCheckpoint_v1"
Config.AutoSaveInterval = 90
Config.StudioGrantAllPasses = false

Config.Shift = {
	BasePassengers = 5,
	PassengersPerShift = 1,
	MaxPassengers = 12,
	MaxStrikes = 3, -- wrong calls before you're fired (the shift restarts)
	PayCorrect = 15,
	PayPerfectBonus = 60,
	AnomalyChance = 0.3, -- chance each passenger is not human (rises a little every shift)
	AnomalyChancePerShift = 0.02,
	RuleBreakerChance = 0.25, -- humans whose papers break today's rules
}

Config.LightsOut = {
	Duration = 120, -- seconds to restore power before the station is lost
	BreakerHold = 3,
	MonsterSpeed = 17,
	CatchDistance = 4.5,
	KnockoutTime = 8,
	TaserCooldown = 10,
	TaserRange = 18,
	TaserStun = 3.5,
}

-- Tools unlock one per shift, like learning the job.
Config.Tools = {
	{ Key = "Passport", Name = "Passport", Shift = 1 },
	{ Key = "Ticket", Name = "Ticket", Shift = 1 },
	{ Key = "XRay", Name = "X-Ray", Shift = 2 },
	{ Key = "Skeleton", Name = "Body Scan", Shift = 3 },
	{ Key = "Camera", Name = "Cameras", Shift = 4 },
	{ Key = "Thermal", Name = "Thermal", Shift = 5 },
	{ Key = "Interview", Name = "Lie Detector", Shift = 6, Room = true }, -- interrogation room
	{ Key = "Fingerprint", Name = "Fingerprints", Shift = 7, Room = true },
	{ Key = "Eyes", Name = "Eye Exam", Shift = 8, Room = true },
	{ Key = "Brain", Name = "Brain Scan", Shift = 9, Room = true },
}

Config.Countries = { "Varnia", "Kessia", "Oskarland", "Lunmark", "Teyra", "Nordhal" }
Config.Destinations = { "Varn Central", "Kessia Port", "Lunmark", "Teyra Falls" }

Config.Party = {
	MaxSize = 4,
	Countdown = 15, -- seconds a party pad waits for more players before the shift starts
	Pads = 4, -- party pads in the lobby (one station each)
}

-- Rank shown on your card and name tag, by the shift you've reached.
Config.Ranks = {
	{ Shift = 1, Name = "Trainee" },
	{ Shift = 3, Name = "Officer" },
	{ Shift = 5, Name = "Senior Officer" },
	{ Shift = 8, Name = "Inspector" },
	{ Shift = 12, Name = "Chief Inspector" },
	{ Shift = 20, Name = "Legend of the Line" },
}

-- Stress ("CRACK UP" meter). Mistakes, monsters and creepy answers raise it. At 100% your view warps
-- until you drink coffee in the break room.
Config.Stress = { WrongCall = 25, CreepyAnswer = 6, Caught = 40, Coffee = -60, PerfectCall = -4 }

Config.CandyPerShift = 12 -- Halloween currency, earned every finished shift
Config.CandyPerfectBonus = 10

-- Daily reward streak (day 7 repeats).
Config.DailyRewards = {
	{ Cash = 25 },
	{ Candy = 15 },
	{ Cash = 75 },
	{ Candy = 30 },
	{ Cash = 150 },
	{ Candy = 50 },
	{ Cash = 300, Candy = 100 },
}

-- Skins: shown on pedestals in the lobby. Currency is "Cash" or "Candy".
-- Every skin is built from parts so it works without uploads. Optional: add Marketplace accessory IDs.
Config.Skins = {
	{
		Key = "Standard",
		Name = "Standard Issue",
		Price = 0,
		Currency = "Cash",
		Coat = Color3.fromRGB(40, 52, 78),
		Trim = Color3.fromRGB(220, 180, 70),
		Hat = "Cap",
	},
	{
		Key = "Night",
		Name = "Night Watch",
		Price = 400,
		Currency = "Cash",
		Coat = Color3.fromRGB(22, 24, 30),
		Trim = Color3.fromRGB(90, 200, 255),
		Hat = "Cap",
	},
	{
		Key = "Arctic",
		Name = "Arctic Patrol",
		Price = 900,
		Currency = "Cash",
		Coat = Color3.fromRGB(210, 220, 230),
		Trim = Color3.fromRGB(60, 120, 200),
		Hat = "Ushanka",
	},
	{
		Key = "Crimson",
		Name = "Crimson Chief",
		Price = 2000,
		Currency = "Cash",
		Coat = Color3.fromRGB(120, 20, 26),
		Trim = Color3.fromRGB(240, 200, 90),
		Hat = "Peaked",
	},
	{
		Key = "Gold",
		Name = "Golden Inspector",
		Price = 6000,
		Currency = "Cash",
		Coat = Color3.fromRGB(196, 158, 60),
		Trim = Color3.fromRGB(255, 255, 255),
		Hat = "Peaked",
	},
	-- Halloween (Candy)
	{
		Key = "Plague",
		Name = "Plague Doctor",
		Price = 300,
		Currency = "Candy",
		Coat = Color3.fromRGB(30, 30, 32),
		Trim = Color3.fromRGB(120, 100, 70),
		Hat = "PlagueMask",
		Halloween = true,
	},
	{
		Key = "Pumpkin",
		Name = "Pumpkin Conductor",
		Price = 300,
		Currency = "Candy",
		Coat = Color3.fromRGB(60, 30, 70),
		Trim = Color3.fromRGB(255, 130, 20),
		Hat = "Pumpkin",
		Halloween = true,
	},
	{
		Key = "Witch",
		Name = "Witch Medic",
		Price = 500,
		Currency = "Candy",
		Coat = Color3.fromRGB(70, 20, 80),
		Trim = Color3.fromRGB(120, 230, 90),
		Hat = "Witch",
		Halloween = true,
	},
	{
		Key = "Count",
		Name = "Inspector Dracul",
		Price = 800,
		Currency = "Candy",
		Coat = Color3.fromRGB(16, 12, 14),
		Trim = Color3.fromRGB(170, 10, 20),
		Hat = "Fangs",
		Halloween = true,
	},
	{
		Key = "Wraith",
		Name = "Frost Wraith",
		Price = 1500,
		Currency = "Candy",
		Coat = Color3.fromRGB(180, 230, 255),
		Trim = Color3.fromRGB(40, 160, 255),
		Hat = "Hood",
		Halloween = true,
	},
}

Config.GamePasses = {
	DoublePay = { Id = 0, Name = "💰 2x Pay", Description = "Double all pay, forever.", Price = 249 },
	AnomalyRadar = { Id = 0, Name = "📡 Anomaly Radar", Description = "3 times per shift, highlight one suspicious detail.", Price = 299 },
	ExtraStrike = { Id = 0, Name = "🛡️ Second Chance", Description = "One extra mistake allowed every shift.", Price = 199 },
	VIP = { Id = 0, Name = "👑 VIP", Description = "+25% pay & candy, gold name tag, +1 daily reward.", Price = 249 },
}
Config.PassOrder = { "AnomalyRadar", "DoublePay", "ExtraStrike", "VIP" }

Config.Products = {
	Hint = { Id = 0, Name = "🔍 Hint", Description = "Reveal whether the current passenger is human.", Price = 15 },
	Revive = { Id = 0, Name = "⚡ Wake Up", Description = "Get back up instantly when the thing knocks you out.", Price = 25 },
	PowerSurge = { Id = 0, Name = "🔋 Power Surge", Description = "Instantly restore one breaker during a blackout.", Price = 49 },
	CashSmall = { Id = 0, Name = "💵 $500", Description = "Buy skins faster.", Price = 25 },
	CashLarge = { Id = 0, Name = "💵 $3,000", Description = "Buy skins faster.", Price = 99 },
	CandySmall = { Id = 0, Name = "🍬 300 Candy", Description = "Unlock a Halloween skin now!", Price = 49 },
	CandyLarge = { Id = 0, Name = "🍬 1,500 Candy", Description = "Best value: any Halloween skin.", Price = 199 },
}
Config.ProductOrder = { "Hint", "Revive", "PowerSurge", "CandySmall", "CandyLarge", "CashSmall", "CashLarge" }
Config.CashPacks = { CashSmall = 500, CashLarge = 3000 }
Config.CandyPacks = { CandySmall = 300, CandyLarge = 1500 }

Config.Multipliers = { DoublePay = 2, VIP = 1.25 }

-- Music & sounds (see GUIDE.md). Upload the files in audio/ and paste the IDs.
Config.Sounds = {
	-- Music & ambience
	Ambience = { Id = 0, Volume = 0.45 }, -- station hum + wind (loops during shifts)
	LobbyMusic = { Id = 0, Volume = 0.35 }, -- eerie music box in the lobby
	ChaseMusic = { Id = 0, Volume = 0.7 }, -- blackout chase music (loops)
	Heartbeat = { Id = 0, Volume = 0.8 }, -- louder the closer the monster is
	Whispers = { Id = 0, Volume = 0.5 }, -- when stress is high or you approve something wrong
	-- Monster
	MonsterScreech = { Id = 0, Volume = 1 },
	MonsterGrowl = { Id = 0, Volume = 0.9 }, -- 3D, loops on the monster
	MonsterBreath = { Id = 0, Volume = 0.8 }, -- 3D, heard near lockers
	MonsterSteps = { Id = 0, Volume = 0.8 },
	Jumpscare = { Id = 0, Volume = 1 }, -- the screamer when you're caught
	-- Station
	Stamp = { Id = 0, Volume = 0.8 },
	Correct = { Id = 0, Volume = 0.5 },
	Buzzer = { Id = 0, Volume = 0.45 },
	Bell = { Id = 0, Volume = 0.6 },
	Paper = { Id = 0, Volume = 0.6 },
	Scanner = { Id = 0, Volume = 0.5 },
	PowerDown = { Id = 0, Volume = 0.9 },
	Breaker = { Id = 0, Volume = 0.9 },
	Taser = { Id = 0, Volume = 0.5 },
	TrainHorn = { Id = 0, Volume = 0.6 },
	Coffee = { Id = 0, Volume = 0.8 }, -- pour + slurp
	Locker = { Id = 0, Volume = 0.7 },
}

-- Custom animations (made in the Roblox Animation Editor or Moon Animator, then uploaded).
-- Leave 0 to use Roblox's default walk/idle; fill these in to make the characters even more alive.
Config.Animations = {
	PassengerWalk = 0,
	PassengerIdle = 0,
	PassengerHandOver = 0, -- handing the passport over the counter
	PassengerPlaceBag = 0, -- putting the suitcase on the X-ray belt
	PassengerScanPose = 0, -- arms up in the body scanner
	MonsterRun = 0,
	MonsterIdle = 0,
	MonsterAttack = 0,
}

-- Real Marketplace items for passengers (roblox.com/catalog: copy the number from an item's web address).
-- Each passenger picks randomly from these lists. Empty lists = built-in hair and plain clothes.
Config.PassengerLooks = {
	Hair = {}, -- e.g. { "1234567", "7654321" }
	Shirts = {}, -- classic shirt IDs
	Pants = {}, -- classic pants IDs
	Faces = {}, -- face IDs
}

return Config
