-- Generates tonight's rules and every passenger: their documents, luggage, skeleton, temperature,
-- fingerprints, eyes, interview answers, appearance, and (for anomalies) the hidden tells.
-- Shared by the server (which decides what's correct) and the client (which draws the inspection tools).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Passengers = {}

Passengers.Today = { Month = 12, Year = 2026 }

local FIRST = {
	"Anya",
	"Boris",
	"Clara",
	"Dmitri",
	"Elsa",
	"Felix",
	"Greta",
	"Hugo",
	"Ida",
	"Jonas",
	"Katya",
	"Lev",
	"Mila",
	"Niko",
	"Olga",
	"Pavel",
	"Rosa",
	"Stefan",
	"Tilda",
	"Viktor",
	"Wren",
	"Yuri",
	"Zora",
	"Emil",
}
local LAST = {
	"Varga",
	"Holm",
	"Petrov",
	"Lind",
	"Novak",
	"Berg",
	"Kask",
	"Morrow",
	"Strand",
	"Volk",
	"Eklund",
	"Frost",
	"Hale",
	"Ivers",
	"Janek",
	"Korsa",
	"Lunde",
	"Marek",
	"Orlov",
	"Rask",
	"Sorel",
	"Tamm",
}

-- Luggage. Each item has an X-ray icon and a category used by tonight's rules.
Passengers.Items = {
	Clothes = { Icon = "👕", Name = "Folded clothes", Category = "Normal" },
	Book = { Icon = "📕", Name = "Book", Category = "Normal" },
	Shoes = { Icon = "👞", Name = "Shoes", Category = "Normal" },
	Camera = { Icon = "📷", Name = "Camera", Category = "Normal" },
	Laptop = { Icon = "💻", Name = "Laptop", Category = "Normal" },
	Toothbrush = { Icon = "🪥", Name = "Toothbrush", Category = "Normal" },
	Headphones = { Icon = "🎧", Name = "Headphones", Category = "Normal" },
	Teddy = { Icon = "🧸", Name = "Teddy bear", Category = "Normal" },
	Umbrella = { Icon = "☂️", Name = "Umbrella", Category = "Normal" },
	Gnome = { Icon = "🍄", Name = "Garden gnome", Category = "Normal" }, -- odd, but allowed
	Bottle = { Icon = "🍾", Name = "Sealed bottle", Category = "Liquids" },
	Perfume = { Icon = "🧴", Name = "Large perfume", Category = "Liquids" },
	Scissors = { Icon = "✂️", Name = "Scissors", Category = "Sharp" },
	Razor = { Icon = "🪒", Name = "Straight razor", Category = "Sharp" },
	Cat = { Icon = "🐈", Name = "Cat", Category = "Animals" },
	Bird = { Icon = "🐦", Name = "Bird", Category = "Animals" },
	Fireworks = { Icon = "🎆", Name = "Fireworks", Category = "Explosives" },
	-- Things only anomalies carry
	Teeth = { Icon = "🦷", Name = "Jar of teeth", Category = "Anomalous" },
	Ice = { Icon = "🧊", Name = "Ice that doesn't melt", Category = "Anomalous" },
	Heart = { Icon = "🫀", Name = "A beating heart", Category = "Anomalous" },
	Eye = { Icon = "👁️", Name = "Something watching", Category = "Anomalous" },
}
local NORMAL_ITEMS = { "Clothes", "Book", "Shoes", "Camera", "Laptop", "Toothbrush", "Headphones", "Teddy", "Umbrella", "Gnome" }
local CATEGORY_ITEMS = {
	Liquids = { "Bottle", "Perfume" },
	Sharp = { "Scissors", "Razor" },
	Animals = { "Cat", "Bird" },
	Explosives = { "Fireworks" },
}
local FORBIDDEN_ROTATION = { "Explosives", "Sharp", "Liquids", "Animals" }

-- Anomaly types: which tools can reveal them (at least one must be unlocked for it to appear).
Passengers.Anomalies = {
	Mimic = { Name = "Mimic", Tells = { "Passport", "Camera", "Interview", "Brain" } }, -- wrong photo, true face on camera
	Echo = { Name = "Echo", Tells = { "Ticket", "Camera", "Interview", "Brain" } }, -- name slightly wrong, repeats your words
	Stretcher = { Name = "Stretcher", Tells = { "XRay", "Skeleton", "Camera", "Brain" } }, -- too tall, long arms, teeth in bag
	Hollow = { Name = "Hollow", Tells = { "Skeleton", "Thermal", "Camera", "Fingerprint", "Brain" } }, -- no bones, no prints
	Frost = { Name = "Frost", Tells = { "Thermal", "XRay", "Camera", "Eyes", "Brain" } }, -- freezing cold, glowing eyes
}

local SKIN = {
	Color3.fromRGB(255, 220, 190),
	Color3.fromRGB(234, 192, 150),
	Color3.fromRGB(198, 145, 105),
	Color3.fromRGB(150, 100, 70),
	Color3.fromRGB(105, 70, 50),
	Color3.fromRGB(245, 205, 170),
}
local CLOTHES = {
	Color3.fromRGB(176, 40, 44),
	Color3.fromRGB(40, 90, 60),
	Color3.fromRGB(46, 70, 150),
	Color3.fromRGB(230, 200, 70),
	Color3.fromRGB(235, 235, 235),
	Color3.fromRGB(60, 60, 66),
	Color3.fromRGB(120, 80, 150),
	Color3.fromRGB(196, 120, 60),
}
local PANTS = { Color3.fromRGB(34, 40, 60), Color3.fromRGB(70, 60, 50), Color3.fromRGB(40, 40, 44), Color3.fromRGB(90, 96, 110) }
local HAIR_COLORS = {
	Color3.fromRGB(30, 22, 18),
	Color3.fromRGB(90, 56, 30),
	Color3.fromRGB(200, 160, 90),
	Color3.fromRGB(150, 60, 30),
	Color3.fromRGB(180, 180, 180),
}
local HAIR_STYLES = { "Short", "Long", "Bun", "Pigtails", "Spiky", "Bald", "Cap" }
local FINGERPRINTS = { "Whorl", "Loop", "Arch", "Double Loop", "Tented Arch", "Spiral" }

local function pick(rng: Random, list)
	return list[rng:NextInteger(1, #list)]
end

local function toolUnlocked(shift: number, key: string): boolean
	for _, tool in Config.Tools do
		if tool.Key == key then
			return shift >= tool.Shift
		end
	end
	return false
end
Passengers.ToolUnlocked = toolUnlocked

local function misspell(name: string, rng: Random): string
	local i = rng:NextInteger(2, #name)
	local swaps = { a = "e", e = "a", i = "y", o = "u", u = "o", n = "m", r = "l", l = "r", s = "z", k = "c" }
	local ch = string.sub(name, i, i)
	local new = swaps[string.lower(ch)] or "x"
	return string.sub(name, 1, i - 1) .. new .. string.sub(name, i + 1)
end

-- Tonight's rules. Each rule has text (shown in the rulebook) and data the checks use.
function Passengers.Rules(shift: number)
	local rng = Random.new(shift * 7919)
	local rules = {
		Destination = Config.Destinations[(shift - 1) % #Config.Destinations + 1],
		Night = shift,
		Forbidden = {},
		BannedCountry = nil,
		FeverDeny = shift >= 5,
		Lines = {},
	}
	table.insert(
		rules.Lines,
		"Passports must not be expired (today is " .. string.format("%02d/%d", Passengers.Today.Month, Passengers.Today.Year) .. ")."
	)
	table.insert(rules.Lines, "The photo must match the passenger, and the ticket name must match the passport exactly.")
	table.insert(rules.Lines, "Tonight's train goes to " .. rules.Destination .. ". Tickets must say NIGHT " .. shift .. ".")
	if shift >= 2 then
		local count = math.min(1 + math.floor((shift - 2) / 2), #FORBIDDEN_ROTATION)
		for i = 1, count do
			table.insert(rules.Forbidden, FORBIDDEN_ROTATION[(shift + i - 2) % #FORBIDDEN_ROTATION + 1])
		end
		table.insert(rules.Lines, "Forbidden in luggage tonight: " .. table.concat(rules.Forbidden, ", ") .. ".")
	end
	if shift >= 3 then
		table.insert(rules.Lines, "A human body has 1 skull, 2 arms, 2 legs and a full rib cage.")
	end
	if shift >= 4 then
		table.insert(rules.Lines, "Cameras see what your eyes miss. Compare them with the person in front of you.")
	end
	if rules.FeverDeny then
		table.insert(rules.Lines, "Humans are 36-37.5 °C. Deny fevers (38 °C or more). Much colder is NOT human.")
	end
	if shift >= 6 then
		table.insert(rules.Lines, "Interview: answers must match their documents. Watch the lie detector.")
	end
	if shift >= 7 then
		table.insert(rules.Lines, "Fingerprints must match the pattern printed in the passport.")
		rules.BannedCountry = pick(rng, Config.Countries)
		table.insert(rules.Lines, "No citizens of " .. rules.BannedCountry .. " may travel tonight.")
	end
	if shift >= 6 then
		table.insert(rules.Lines, "Suspicious? Press the red INTERROGATION phone and question them in the back room.")
	end
	if shift >= 8 then
		table.insert(rules.Lines, "Eye exam: human eyes have round pupils that react to light.")
	end
	if shift >= 9 then
		table.insert(rules.Lines, "Brain scan: a human brain shows two active halves. Flat, mirrored or static = NOT human.")
	end
	table.insert(rules.Lines, "Some passengers are NOT human. Never let them board.")
	return rules
end

-- Creates one passenger. The record is plain data so it can be sent to every client.
function Passengers.Generate(shift: number, seed: number, rules)
	local rng = Random.new(seed)
	local first, last = pick(rng, FIRST), pick(rng, LAST)
	local p = {
		Seed = seed,
		First = first,
		Last = last,
		Country = pick(rng, Config.Countries),
		Birth = string.format("%02d/%02d/%d", rng:NextInteger(1, 28), rng:NextInteger(1, 12), rng:NextInteger(1950, 2006)),
		PassportNo = string.upper(string.sub(first, 1, 1) .. string.sub(last, 1, 1)) .. "-" .. rng:NextInteger(10000, 99999),
		ExpiryMonth = rng:NextInteger(1, 12),
		ExpiryYear = rng:NextInteger(2027, 2031),
		Ticket = { Name = first .. " " .. last, Destination = rules.Destination, Night = shift },
		Bag = {},
		Skeleton = { Skull = 1, Arms = 2, Legs = 2, Ribs = "Normal", LongArms = false },
		Temperature = math.floor(rng:NextNumber(36.2, 37.3) * 10) / 10,
		Eyes = "Normal",
		Brain = "Normal", -- Normal | Flat (no activity) | Mirror | Static
		Fingerprint = pick(rng, FINGERPRINTS),
		Look = {
			Skin = rng:NextInteger(1, #SKIN),
			Shirt = rng:NextInteger(1, #CLOTHES),
			Pants = rng:NextInteger(1, #PANTS),
			Hair = pick(rng, HAIR_STYLES),
			HairColor = rng:NextInteger(1, #HAIR_COLORS),
			Height = rng:NextNumber(0.92, 1.06),
		},
		Photo = nil, -- nil = matches; otherwise how the passport photo differs
		TrueForm = false, -- shows its real face on camera
		Anomaly = nil,
		Violation = nil, -- the rule a human breaks (deny them, but they're harmless)
		Interview = {},
	}
	p.PrintedFingerprint = p.Fingerprint
	-- Luggage: 3-5 normal things
	for _ = 1, rng:NextInteger(3, 5) do
		table.insert(p.Bag, pick(rng, NORMAL_ITEMS))
	end

	-- Is this one human?
	local anomalyChance = Config.Shift.AnomalyChance + Config.Shift.AnomalyChancePerShift * (shift - 1)
	if rng:NextNumber() < anomalyChance then
		local options = {}
		for key, info in Passengers.Anomalies do
			for _, tell in info.Tells do
				if toolUnlocked(shift, tell) then
					table.insert(options, key)
					break
				end
			end
		end
		table.sort(options)
		if #options > 0 then
			p.Anomaly = pick(rng, options)
		end
	end

	local a = p.Anomaly
	if a then
		p.TrueForm = true
		p.Brain = if a == "Hollow" then "Flat" elseif a == "Mimic" or a == "Echo" then "Mirror" else "Static"
		if a == "Mimic" then
			p.Photo = pick(rng, { "BlackEyes", "WrongHair", "WideSmile" })
		elseif a == "Echo" then
			if rng:NextNumber() < 0.5 then
				p.Ticket.Name = misspell(first, rng) .. " " .. last
			else
				p.Ticket.Name = first .. " " .. misspell(last, rng)
			end
		elseif a == "Stretcher" then
			p.Look.Height = 1.18
			p.Skeleton.LongArms = true
			table.insert(p.Bag, "Teeth")
		elseif a == "Hollow" then
			p.Skeleton = { Skull = 0, Arms = 0, Legs = 0, Ribs = "None", LongArms = false }
			p.Temperature = math.floor(rng:NextNumber(24, 29) * 10) / 10
			p.Fingerprint = "None"
		elseif a == "Frost" then
			p.Temperature = math.floor(rng:NextNumber(2, 11) * 10) / 10
			table.insert(p.Bag, "Ice")
			p.Eyes = "Glowing"
		end
		-- Extra creepiness that later tools can catch for any anomaly
		if rng:NextNumber() < 0.4 then
			p.Skeleton.Ribs = if p.Skeleton.Ribs == "None" then "None" else "Extra"
		end
		if a ~= "Frost" and rng:NextNumber() < 0.5 then
			p.Eyes = pick(rng, { "NoPupils", "Slit" })
		end
		if a ~= "Hollow" and rng:NextNumber() < 0.5 then
			p.Fingerprint = pick(rng, FINGERPRINTS)
			if p.Fingerprint == p.PrintedFingerprint then
				p.Fingerprint = "Smudged"
			end
		end
	elseif rng:NextNumber() < Config.Shift.RuleBreakerChance then
		-- A human with a problem: deny them, but they're no threat
		local problems = { "Expired", "WrongDestination", "WrongNight", "NameTypo" }
		if #rules.Forbidden > 0 then
			table.insert(problems, "Contraband")
		end
		if rules.FeverDeny then
			table.insert(problems, "Fever")
		end
		if rules.BannedCountry then
			table.insert(problems, "BannedCountry")
		end
		if shift >= 7 then
			table.insert(problems, "WrongPrint")
		end
		local problem = pick(rng, problems)
		p.Violation = problem
		if problem == "Expired" then
			p.ExpiryYear = Passengers.Today.Year - rng:NextInteger(0, 2)
			p.ExpiryMonth = if p.ExpiryYear == Passengers.Today.Year
				then rng:NextInteger(1, Passengers.Today.Month - 1)
				else rng:NextInteger(1, 12)
		elseif problem == "WrongDestination" then
			local others = {}
			for _, d in Config.Destinations do
				if d ~= rules.Destination then
					table.insert(others, d)
				end
			end
			p.Ticket.Destination = pick(rng, others)
		elseif problem == "WrongNight" then
			p.Ticket.Night = shift + pick(rng, { -1, 1, 2 })
		elseif problem == "NameTypo" then
			p.Ticket.Name = first .. " " .. misspell(last, rng)
		elseif problem == "Contraband" then
			local category = pick(rng, rules.Forbidden)
			table.insert(p.Bag, pick(rng, CATEGORY_ITEMS[category]))
		elseif problem == "Fever" then
			p.Temperature = math.floor(rng:NextNumber(38.1, 39.6) * 10) / 10
		elseif problem == "BannedCountry" then
			p.Country = rules.BannedCountry
		elseif problem == "WrongPrint" then
			repeat
				p.Fingerprint = pick(rng, FINGERPRINTS)
			until p.Fingerprint ~= p.PrintedFingerprint
		end
	end
	-- Humans sometimes carry allowed-but-odd things, so the X-ray isn't a giveaway
	if rng:NextNumber() < 0.3 then
		local allowed = {}
		for category, items in CATEGORY_ITEMS do
			if not table.find(rules.Forbidden, category) then
				for _, item in items do
					table.insert(allowed, item)
				end
			end
		end
		table.sort(allowed)
		if #allowed > 0 and not p.Violation then
			table.insert(p.Bag, pick(rng, allowed))
		end
	end

	-- Interview answers (Q: destination, birthday, purpose)
	local purposes =
		{ "Visiting my sister.", "Work. I fix trains.", "Going home.", "A funeral, sadly.", "Holiday, finally.", "Moving to the city." }
	p.Interview = {
		{ Q = "Where are you travelling to?", A = p.Ticket.Destination .. ".", Spike = false },
		{ Q = "What is your date of birth?", A = p.Birth .. ".", Spike = false },
		{ Q = "Why are you travelling tonight?", A = pick(rng, purposes), Spike = false },
	}
	if a == "Echo" then
		p.Interview[1].A = "Where are you travelling to?"
		p.Interview[3].A = "Why are you... travelling... tonight?"
		p.Interview[1].Spike, p.Interview[3].Spike = true, true
	elseif a then
		local creepy =
			{ "Somewhere warm. Somewhere with people.", "I don't remember being born.", "The train is hungry.", "To see you again." }
		local i = rng:NextInteger(1, 3)
		p.Interview[i].A = pick(rng, creepy)
		p.Interview[i].Spike = true
	end
	return p
end

-- What the right call is, and why. Returns (shouldApprove, reasonText).
function Passengers.Judge(p, _rules)
	if p.Anomaly then
		return false, "It wasn't human (" .. Passengers.Anomalies[p.Anomaly].Name .. ")."
	end
	local reasons = {
		Expired = "Their passport was expired.",
		WrongDestination = "Their ticket was for the wrong destination.",
		WrongNight = "Their ticket was for another night.",
		NameTypo = "The ticket name didn't match the passport.",
		Contraband = "They carried forbidden items.",
		Fever = "They had a fever.",
		BannedCountry = "Their country is banned tonight.",
		WrongPrint = "Their fingerprints didn't match the passport.",
	}
	if p.Violation then
		return false, reasons[p.Violation]
	end
	return true, "They were a normal, honest traveller."
end

Passengers.SkinColors = SKIN
Passengers.ShirtColors = CLOTHES
Passengers.PantsColors = PANTS
Passengers.HairColors = HAIR_COLORS
Passengers.Fingerprints = FINGERPRINTS

return Passengers
