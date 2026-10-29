-- One shift at one station for one party: lanes, passengers, tools, interrogation, verdicts,
-- and the blackout when something gets through.
local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Passengers = require(Shared.Passengers)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local NPC = require(script.Parent.NPC)
local PlayerService = require(script.Parent.PlayerService)
local SkinLook = require(script.Parent.SkinLook)

local Run = {}
Run.__index = Run

Run.ByPlayer = {} :: { [Player]: any }

local STEPS = 6
local GREETINGS = {
	"Evening, officer.",
	"I need to get on this train before midnight.",
	"Cold night, isn't it?",
	"Here are my papers.",
	"Please be quick, my kids are waiting.",
	"Is the train on time?",
	"Long queue tonight...",
}
local CREEPY_GREETINGS = {
	"Hello... officer.",
	"I am a normal traveller. Normal.",
	"Let me through. Please. Let me through.",
	"Your face looks so warm.",
	"I have papers. Papers papers papers.",
}

local function stamp(prompt: ProximityPrompt, players: { Player }?)
	if players then
		local ids = {}
		for _, p in players do
			table.insert(ids, tostring(p.UserId))
		end
		prompt:SetAttribute("ForUsers", "," .. table.concat(ids, ",") .. ",")
	else
		prompt:SetAttribute("ForUsers", nil)
	end
end

local function canUse(prompt: ProximityPrompt, player: Player): boolean
	local list = prompt:GetAttribute("ForUsers")
	return list == nil or string.find(list, "," .. player.UserId .. ",", 1, true) ~= nil
end

local function character(player: Player): (Model?, Humanoid?, BasePart?)
	local char = player.Character
	if not char then
		return nil, nil, nil
	end
	return char, char:FindFirstChildOfClass("Humanoid"), char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function teleport(player: Player, cf: CFrame)
	local char = player.Character
	if char then
		char:PivotTo(cf)
	end
end

function Run.AddStress(player: Player, amount: number)
	local stress = math.clamp((player:GetAttribute("Stress") or 0) + amount, 0, 100)
	player:SetAttribute("Stress", stress)
end

local function giveTaser(player: Player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack or backpack:FindFirstChild("Taser") then
		return
	end
	local tool = Instance.new("Tool")
	tool.Name = "Taser"
	tool.ToolTip = "Stun monsters (and coworkers)"
	tool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.4, 0.8, 1.4)
	handle.Color = Color3.fromRGB(250, 210, 40)
	handle.Parent = tool
	local tip = Instance.new("Part")
	tip.Size = Vector3.new(0.3, 0.3, 0.3)
	tip.Color = Color3.fromRGB(80, 200, 255)
	tip.Material = Enum.Material.Neon
	tip.CanCollide = false
	tip.Massless = true
	tip.CFrame = handle.CFrame * CFrame.new(0, 0.1, -0.8)
	local w = Instance.new("WeldConstraint")
	w.Part0 = handle
	w.Part1 = tip
	w.Parent = tip
	tip.Parent = tool
	tool.Parent = backpack
end

local function removeTaser(player: Player)
	for _, container in { player:FindFirstChildOfClass("Backpack"), player.Character } do
		local tool = container and container:FindFirstChild("Taser")
		if tool then
			tool:Destroy()
		end
	end
end

function Run.new(station, members: { Player }, shift: number, onEnd: (any) -> ())
	local self = setmetatable({}, Run)
	self.Station = station
	self.Shift = shift
	self.Rules = Passengers.Rules(shift)
	self.Members = table.clone(members)
	self.Lanes = {}
	self.Connections = {}
	self.Escaped = {} -- anomalies that boarded the train
	self.Monsters = {}
	self.Ended = false
	self.Blackout = false
	self.OnEnd = onEnd
	self.Folder = Instance.new("Folder")
	self.Folder.Name = "RunNPCs"
	self.Folder.Parent = station.Model
	self.PassengersPerLane =
		math.min(Config.Shift.BasePassengers + (shift - 1) * Config.Shift.PassengersPerShift, Config.Shift.MaxPassengers)
	return self
end

function Run:Connect(signal: RBXScriptSignal, fn)
	table.insert(self.Connections, signal:Connect(fn))
end

function Run:Objective(lane, step: number, title: string, text: string)
	Remotes.Objective:FireClient(lane.Player, { Title = title, Text = text, Step = step, Steps = STEPS })
end

function Run:SendState(lane)
	local maxStrikes = Config.Shift.MaxStrikes + (if lane.Player:GetAttribute("Pass_ExtraStrike") then 1 else 0)
	Remotes.ShiftState:FireClient(lane.Player, {
		Shift = self.Shift,
		Lane = lane.Index,
		Strikes = lane.Strikes,
		MaxStrikes = maxStrikes,
		Remaining = lane.Remaining,
		Total = self.PassengersPerLane,
		Correct = lane.Correct,
		Rules = self.Rules.Lines,
		RadarLeft = lane.RadarLeft,
	})
	local left = string.format("%02d", lane.Remaining)
	lane.Markers.SignLabel.Text = "LANE " .. lane.Index .. "  ·  " .. left .. " CHECK-INS LEFT"
end

function Run:Start()
	for i, player in self.Members do
		local markers = self.Station.Lanes[i]
		local room = self.Station.Interrogation[i]
		local lane = {
			Index = i,
			Player = player,
			Markers = markers,
			Room = room,
			Remaining = self.PassengersPerLane,
			Strikes = 0,
			Correct = 0,
			Wrong = 0,
			Pay = 0,
			Current = nil,
			Fired = false,
			Done = false,
			RadarLeft = if player:GetAttribute("Pass_AnomalyRadar") then 3 else 0,
			Log = {},
		}
		self.Lanes[i] = lane
		Run.ByPlayer[player] = self
		player:SetAttribute("InShift", true)
		player:SetAttribute("Lane", i)
		player:SetAttribute("Stress", player:GetAttribute("Stress") or 0)
		for _, prompt in markers.Prompts do
			stamp(prompt, { player })
			prompt.Enabled = false
		end
		for _, prompt in room.Prompts do
			stamp(prompt, { player })
			prompt.Enabled = false
		end
		markers.Prompts.Rulebook.Enabled = true
		local char = player.Character
		if char then
			SkinLook.Apply(char, player:GetAttribute("Skin") or "Standard")
			for _, p in char:GetDescendants() do
				if p:IsA("BasePart") then
					p.CollisionGroup = "Players"
				end
			end
		end
		pcall(player.RequestStreamAroundAsync, player, markers.OfficerSpawn.Position)
		player.CameraMode = Enum.CameraMode.LockFirstPerson -- work the desk in first person
		teleport(player, markers.OfficerSpawn)
		giveTaser(player)
		-- Respawned (reset / fell): put them back at work
		self:Connect(player.CharacterAdded, function(newChar)
			task.wait()
			if Run.ByPlayer[player] ~= self or self.Ended then
				return
			end
			player:SetAttribute("KnockedOut", nil)
			player:SetAttribute("Hidden", nil)
			newChar:PivotTo(if self.Blackout then self.Station.BreakRoomSpawn else markers.OfficerSpawn)
			SkinLook.Apply(newChar, player:GetAttribute("Skin") or "Standard")
			for _, p in newChar:GetDescendants() do
				if p:IsA("BasePart") then
					p.CollisionGroup = "Players"
				end
			end
			giveTaser(player)
		end)
		self:SendState(lane)
		self:Objective(lane, 1, "Check in the passenger", "Your first passenger is on the way. Meet them at the check-in desk.")
		self:WirePrompts(lane)
	end
	-- Breakers, lockers and coffee belong to the whole party
	for _, breaker in self.Station.Breakers do
		stamp(breaker.Prompt, self.Members)
		breaker.Prompt.Enabled = false
		self:Connect(breaker.Prompt.Triggered, function(player)
			self:FlipBreaker(player, breaker)
		end)
	end
	self:Connect(self.Station.Coffee.Triggered, function(player)
		if Run.ByPlayer[player] == self then
			Run.AddStress(player, Config.Stress.Coffee)
			Remotes.Sfx:FireClient(player, "Coffee")
			Remotes.notify(player, "☕ Hot coffee. You feel calmer.", "success")
		end
	end)
	-- Close any lanes past the party size
	for i = #self.Members + 1, #self.Station.Lanes do
		self.Station.Lanes[i].SignLabel.Text = "LANE " .. i .. "  ·  CLOSED"
	end
	for _, lane in self.Lanes do
		Remotes.Sfx:FireClient(lane.Player, "TrainHorn")
		task.delay(3, function()
			self:NextPassenger(lane)
		end)
	end
	self:Connect(Players.PlayerRemoving, function(player)
		for _, lane in self.Lanes do
			if lane.Player == player then
				lane.Fired = true
				lane.Done = true
				if lane.Current and lane.Current.Model then
					lane.Current.Model:Destroy()
				end
				lane.Current = nil
			end
		end
		Run.ByPlayer[player] = nil
		self:CheckAllDone()
	end)
end

function Run:LanePrompts(lane, enabled: boolean, room: boolean?)
	local unlocked = function(key)
		return Passengers.ToolUnlocked(self.Shift, key)
	end
	local prompts = lane.Markers.Prompts
	prompts.Approve.Enabled = enabled and not room
	prompts.Deny.Enabled = enabled and not room
	for _, key in { "XRay", "Skeleton", "Camera", "Thermal" } do
		prompts[key].Enabled = enabled and not room and unlocked(key)
	end
	prompts.Interrogate.Enabled = enabled and not room and unlocked("Interview")
	for _, key in { "Interview", "Fingerprint", "Eyes", "Brain" } do
		lane.Room.Prompts[key].Enabled = enabled and room == true and unlocked(key)
	end
	lane.Room.Prompts.Approve.Enabled = enabled and room == true
	lane.Room.Prompts.Deny.Enabled = enabled and room == true
end

-- What each tool shows.
function Run:ToolData(lane, key: string)
	local current = lane.Current
	local p = current and current.Record
	if key == "Rulebook" then
		return { Lines = self.Rules.Lines, Shift = self.Shift }
	end
	if not p then
		return nil
	end
	if key == "Passport" then
		return {
			First = p.First,
			Last = p.Last,
			Country = p.Country,
			Birth = p.Birth,
			PassportNo = p.PassportNo,
			Expiry = string.format("%02d/%d", p.ExpiryMonth, p.ExpiryYear),
			Print = if Passengers.ToolUnlocked(self.Shift, "Fingerprint") then p.PrintedFingerprint else nil,
			Photo = p.Photo,
			Model = current.Model,
			Ticket = p.Ticket,
			Today = string.format("%02d/%d", Passengers.Today.Month, Passengers.Today.Year),
		}
	elseif key == "XRay" then
		local items = {}
		for _, itemKey in p.Bag do
			local item = Passengers.Items[itemKey]
			table.insert(items, { Icon = item.Icon, Name = item.Name, Category = item.Category })
		end
		return { Items = items, Forbidden = self.Rules.Forbidden }
	elseif key == "Skeleton" then
		return { Skeleton = p.Skeleton, Height = p.Look.Height }
	elseif key == "Camera" then
		return { Model = current.Model, TrueForm = p.TrueForm, Lane = lane.Index }
	elseif key == "Thermal" then
		return { Temperature = p.Temperature }
	elseif key == "Interview" then
		local qs = {}
		for i, entry in p.Interview do
			qs[i] = entry.Q
		end
		return { Questions = qs, Name = p.First }
	elseif key == "Fingerprint" then
		return { Scanned = p.Fingerprint, Printed = p.PrintedFingerprint }
	elseif key == "Eyes" then
		return { Eyes = p.Eyes }
	elseif key == "Brain" then
		return { Brain = p.Brain }
	end
	return nil
end

function Run:OpenTool(lane, key: string)
	local data = self:ToolData(lane, key)
	if data then
		Remotes.OpenTool:FireClient(lane.Player, key, data)
		Remotes.Sfx:FireClient(lane.Player, if key == "Rulebook" or key == "Passport" then "Paper" else "Scanner")
	end
end

function Run:WirePrompts(lane)
	local prompts = lane.Markers.Prompts
	local function guard(fn)
		return function(player)
			if player ~= lane.Player or self.Ended or lane.Done then
				return
			end
			fn(player)
		end
	end
	self:Connect(
		prompts.Rulebook.Triggered,
		guard(function()
			self:OpenTool(lane, "Rulebook")
		end)
	)
	self:Connect(
		prompts.TakeID.Triggered,
		guard(function()
			local current = lane.Current
			if not current or current.Stage ~= "Desk" then
				return
			end
			current.Stage = "Inspect"
			prompts.TakeID.Enabled = false
			lane.Markers.PassportProp.Transparency = 1
			NPC.Pose(current.Model, nil)
			self:LanePrompts(lane, true, false)
			self:OpenTool(lane, "Passport")
			self:Objective(
				lane,
				3,
				"Inspect the passenger",
				"Check the passport, ticket and tonight's rules (R). Use the monitors and tools on your desk."
			)
		end)
	)
	for _, key in { "XRay", "Skeleton", "Camera", "Thermal" } do
		self:Connect(
			prompts[key].Triggered,
			guard(function()
				if lane.Current and lane.Current.Stage == "Inspect" then
					self:OpenTool(lane, key)
				end
			end)
		)
	end
	self:Connect(
		prompts.Approve.Triggered,
		guard(function()
			self:Decide(lane, true)
		end)
	)
	self:Connect(
		prompts.Deny.Triggered,
		guard(function()
			self:Decide(lane, false)
		end)
	)
	self:Connect(
		prompts.Interrogate.Triggered,
		guard(function()
			self:SendToRoom(lane)
		end)
	)
	local room = lane.Room.Prompts
	for _, key in { "Interview", "Fingerprint", "Eyes", "Brain" } do
		self:Connect(
			room[key].Triggered,
			guard(function()
				if lane.Current and lane.Current.Stage == "Room" then
					self:OpenTool(lane, key)
					if key == "Brain" then
						lane.Room.BrainLabel.Text = "NEURO-SCAN\nRUNNING..."
						task.delay(1.5, function()
							if lane.Current and lane.Current.Record then
								lane.Room.BrainLabel.Text = "NEURO-SCAN\nCOMPLETE"
							end
						end)
					end
				end
			end)
		)
	end
	self:Connect(
		room.Approve.Triggered,
		guard(function()
			self:Decide(lane, true)
		end)
	)
	self:Connect(
		room.Deny.Triggered,
		guard(function()
			self:Decide(lane, false)
		end)
	)
end

-- Moves a bag model along the X-ray belt.
local function slideBag(bag: Model, from: CFrame, to: CFrame, duration: number)
	local start = os.clock()
	while bag.Parent and os.clock() - start < duration do
		local t = (os.clock() - start) / duration
		bag:PivotTo(from:Lerp(to, t) * CFrame.Angles(0, 0, math.pi / 2))
		task.wait()
	end
	if bag.Parent then
		bag:PivotTo(to * CFrame.Angles(0, 0, math.pi / 2))
	end
end

function Run:NextPassenger(lane)
	if self.Ended or lane.Done or self.Blackout then
		return
	end
	if lane.Remaining <= 0 then
		lane.Done = true
		self:LanePrompts(lane, false)
		self:Objective(lane, STEPS, "Lane clear!", "Great work. Wait for the others to finish their lanes.")
		self:CheckAllDone()
		return
	end
	local seed = math.floor((os.clock() * 1000) % 1e6) + lane.Index * 7919 + lane.Remaining * 104729
	local record = Passengers.Generate(self.Shift, seed, self.Rules)
	local points = lane.Markers.Points
	local model = NPC.Passenger(record, self.Station.Outside * CFrame.new(math.random(-4, 4), 0, 0), self.Folder)
	local current = { Record = record, Model = model, Stage = "Walking", Location = "Desk" }
	lane.Current = current
	self:Objective(lane, 1, "Check in the passenger", "Your next passenger is on the way. Meet them at the check-in desk.")
	lane.Markers.XRayLabel.Text = "X-RAY\nWAITING"
	lane.Markers.ScanLabel.Text = "BODY SCAN\nWAITING"
	task.spawn(function()
		local alive = function()
			return lane.Current == current and model.Parent ~= nil and not self.Ended
		end
		NPC.WalkTo(model, self.Station.HallDoorIn.Position)
		NPC.WalkTo(model, points.Entry.Position)
		NPC.WalkTo(model, points.Queue.Position)
		if not alive() then
			return
		end
		-- Bag on the X-ray belt
		NPC.WalkTo(model, points.Bag.Position)
		NPC.Face(model, lane.Markers.BagStart.Position)
		NPC.Pose(model, "PlaceBag")
		task.wait(0.6)
		if not alive() then
			return
		end
		local bag = NPC.DropBag(model, lane.Markers.BagStart)
		current.Bag = bag
		NPC.Pose(model, nil)
		if bag then
			task.spawn(function()
				slideBag(bag, lane.Markers.BagStart, lane.Markers.BagEnd, 6)
				if lane.Current == current then
					lane.Markers.XRayLabel.Text = if Passengers.ToolUnlocked(self.Shift, "XRay")
						then "X-RAY\nREADY ✓"
						else "X-RAY\nLOCKED"
				end
			end)
		end
		-- Body scanner
		NPC.WalkTo(model, points.ScanWait.Position)
		NPC.WalkTo(model, points.Scan.Position)
		NPC.Face(model, points.Counter.Position)
		NPC.Pose(model, "ArmsUp")
		Remotes.Sfx:FireClient(lane.Player, "Scanner", points.Scan.Position)
		local light = lane.Markers.ScanLight
		for _ = 1, 4 do
			light.Color = Color3.fromRGB(255, 255, 255)
			task.wait(0.25)
			light.Color = Color3.fromRGB(90, 200, 255)
			task.wait(0.25)
		end
		NPC.Pose(model, nil)
		if not alive() then
			return
		end
		lane.Markers.ScanLabel.Text = if Passengers.ToolUnlocked(self.Shift, "Skeleton")
			then "BODY SCAN\nREADY ✓"
			else "BODY SCAN\nLOCKED"
		-- To the counter
		NPC.WalkTo(model, points.Counter.Position)
		NPC.Face(model, points.Counter.Position - Vector3.new(0, 0, 10))
		local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			NPC.Face(model, hrp.Position + (lane.Markers.OfficerSpawn.Position - hrp.Position) * Vector3.new(1, 0, 1))
		end
		if not alive() then
			return
		end
		NPC.Pose(model, "HandOver")
		lane.Markers.PassportProp.Transparency = 0
		current.Stage = "Desk"
		lane.Markers.Prompts.TakeID.Enabled = true
		local rng = Random.new(record.Seed + 1)
		local line = if record.Anomaly and rng:NextNumber() < 0.45
			then CREEPY_GREETINGS[rng:NextInteger(1, #CREEPY_GREETINGS)]
			else GREETINGS[rng:NextInteger(1, #GREETINGS)]
		NPC.Say(model, line)
		Remotes.Sfx:FireClient(lane.Player, "Bell")
		self:Objective(lane, 2, "Check in the passenger", "Grab their ID card off the tray.")
	end)
end

local function aisle(lane)
	return lane.Markers.Points.Back.Position + Vector3.new(0, 0, 7)
end

local function walk(model: Model, points: { Vector3 }, still: () -> boolean)
	for _, point in points do
		if not still() then
			return false
		end
		NPC.WalkTo(model, point, 25)
	end
	return still()
end

-- Waypoints out of the desk area or the interrogation room, ending in the main hall aisle.
function Run:PathToHall(lane, location: string): { Vector3 }
	local points = lane.Markers.Points
	if location == "Room" then
		local room = lane.Room
		local doorZ = room.Door.Position.Z
		local corridorX = self.Station.WingCorridorTop.Position.X
		return {
			Vector3.new(room.Door.Position.X - 7, 0, doorZ),
			room.Door.Position,
			Vector3.new(corridorX, 0, doorZ),
			self.Station.WingCorridorTop.Position,
			self.Station.WingHallDoor.Position,
			self.Station.WingHallDoor.Position + Vector3.new(3, 0, 3),
		}
	end
	return { points.Scan.Position, points.Back.Position, aisle(lane) }
end

-- Walk the passenger to this lane's interrogation room.
function Run:SendToRoom(lane)
	local current = lane.Current
	if not current or current.Stage ~= "Inspect" then
		return
	end
	current.Stage = "ToRoom"
	self:LanePrompts(lane, false)
	lane.Markers.Prompts.Rulebook.Enabled = true
	Remotes.CloseTools:FireClient(lane.Player)
	NPC.Say(current.Model, "W-what? Why me?")
	self:Objective(
		lane,
		4,
		"Interrogation",
		"Go to INTERROGATION ROOM " .. lane.Index .. " (back corridor, west wing). Your suspect is being escorted."
	)
	lane.Player:SetAttribute("Waypoint", lane.Room.OfficerSpot.Position)
	local model = current.Model
	local room = lane.Room
	task.spawn(function()
		local path = self:PathToHall(lane, "Desk")
		local wingDoor = self.Station.WingHallDoor.Position
		for _, point in
			{
				wingDoor + Vector3.new(3, 0, 3),
				wingDoor,
				self.Station.WingCorridorTop.Position,
				Vector3.new(self.Station.WingCorridorTop.Position.X, 0, room.Door.Position.Z),
				room.Door.Position,
				room.Door.Position - Vector3.new(7, 0, 0),
				room.Seat.Position,
			}
		do
			table.insert(path, point)
		end
		if not walk(model, path, function()
			return lane.Current == current
		end) then
			return
		end
		current.Location = "Room"
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid and room.SeatPart then
			room.SeatPart:Sit(humanoid)
		end
		current.Stage = "Room"
		self:LanePrompts(lane, true, true)
		NPC.Say(model, "...")
		self:Objective(
			lane,
			4,
			"Interrogation",
			"Question them. Lie detector, fingerprints, eye exam and brain scan are on the table. Then stamp."
		)
	end)
end

function Run:Decide(lane, approve: boolean)
	local current = lane.Current
	if not current or (current.Stage ~= "Inspect" and current.Stage ~= "Room") then
		return
	end
	local player = lane.Player
	current.Stage = "Leaving"
	self:LanePrompts(lane, false)
	lane.Markers.Prompts.Rulebook.Enabled = true
	player:SetAttribute("Waypoint", nil)
	Remotes.CloseTools:FireClient(player)
	Remotes.Sfx:FireClient(player, "Stamp")
	local record = current.Record
	local shouldApprove, reason = Passengers.Judge(record, self.Rules)
	local correct = approve == shouldApprove
	lane.Remaining -= 1
	table.insert(
		lane.Log,
		{ Name = record.First .. " " .. record.Last, Approved = approve, Correct = correct, Reason = reason, Anomaly = record.Anomaly }
	)
	if correct then
		lane.Correct += 1
		Run.AddStress(player, Config.Stress.PerfectCall)
		Remotes.Verdict:FireClient(
			player,
			{ Correct = true, Approved = approve, Text = if approve then "Approved ✓" else "Denied ✓ " .. reason }
		)
		Remotes.Sfx:FireClient(player, "Correct")
	elseif approve and record.Anomaly then
		-- Something boarded the train. Nobody tells you... yet.
		lane.Wrong += 1
		table.insert(self.Escaped, record)
		Remotes.Verdict:FireClient(player, { Correct = true, Approved = true, Text = "Approved ✓", Uneasy = true })
		Remotes.Sfx:FireClient(player, "Whispers")
	else
		lane.Wrong += 1
		lane.Strikes += 1
		Run.AddStress(player, Config.Stress.WrongCall)
		Remotes.Verdict:FireClient(player, { Correct = false, Approved = approve, Text = "WRONG ✗  " .. reason })
		Remotes.Sfx:FireClient(player, "Buzzer")
	end
	self:SendState(lane)
	-- Passenger leaves
	local model = current.Model
	local points = lane.Markers.Points
	if approve then
		NPC.Say(model, if record.Anomaly then "Thank you... officer." else "Thank you! Have a good night.")
	else
		NPC.Say(model, if record.Anomaly then "You will regret this." else "What?! This is ridiculous!")
	end
	task.spawn(function()
		local bag = current.Bag
		if bag then
			bag:Destroy()
		end
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Sit then
			humanoid.Sit = false
			humanoid.Jump = true
			task.wait(0.5)
		end
		local path = self:PathToHall(lane, current.Location)
		if approve then
			for _, point in { self.Station.HallSide.Position, self.Station.PlatformDoor.Position, self.Station.TrainDoor.Position } do
				table.insert(path, point)
			end
		else
			local entry = if current.Location == "Room"
				then self.Station.WingHallDoor.Position + Vector3.new(7, 0, 17)
				else points.Entry.Position
			for _, point in { entry, self.Station.HallDoorIn.Position, self.Station.Outside.Position } do
				table.insert(path, point)
			end
		end
		walk(model, path, function()
			return model.Parent ~= nil and not self.Ended
		end)
		model:Destroy()
	end)
	lane.Current = nil
	local maxStrikes = Config.Shift.MaxStrikes + (if player:GetAttribute("Pass_ExtraStrike") then 1 else 0)
	if lane.Strikes >= maxStrikes then
		lane.Fired = true
		lane.Done = true
		self:LanePrompts(lane, false)
		Remotes.Announce:FireClient(player, "YOU'RE FIRED", Color3.fromRGB(220, 40, 40):ToHex())
		self:Objective(lane, STEPS, "Fired", "Too many mistakes. Clocking you out...")
		task.delay(3, function()
			self:FinishPlayer(lane, false, "fired")
			self:CheckAllDone()
		end)
		return
	end
	self:Objective(lane, 5, if correct then "Good call" else "Mistake", "Next passenger coming up...")
	task.delay(2.5, function()
		self:NextPassenger(lane)
	end)
end

function Run:CheckAllDone()
	if self.Ended or self.Blackout then
		return
	end
	for _, lane in self.Lanes do
		if not lane.Done then
			return
		end
	end
	local active = false
	for _, lane in self.Lanes do
		if not lane.Fired and lane.Player.Parent then
			active = true
		end
	end
	if not active then
		self:End(false)
	elseif #self.Escaped > 0 then
		task.delay(4, function()
			self:StartBlackout()
		end)
	else
		self:End(true)
	end
end

function Run:ActivePlayers(): { Player }
	local list = {}
	for _, lane in self.Lanes do
		if not lane.Fired and lane.Player.Parent and Run.ByPlayer[lane.Player] == self then
			table.insert(list, lane.Player)
		end
	end
	return list
end

-- POWER FAILURE: lights die, the things that boarded the train come back for you.
function Run:SetPower(on: boolean)
	local model = self.Station.Model
	for _, part in CollectionService:GetTagged("PowerLight") do
		if part:IsDescendantOf(model) then
			part.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
			for _, light in part:GetChildren() do
				if light:IsA("Light") then
					light.Enabled = on
				end
			end
		end
	end
	for _, part in CollectionService:GetTagged("PowerScreen") do
		if part:IsDescendantOf(model) then
			part.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
			part.Color = if on then part:GetAttribute("OnColor") or part.Color else Color3.fromRGB(10, 10, 12)
			for _, gui in part:GetChildren() do
				if gui:IsA("SurfaceGui") then
					gui.Enabled = on
				end
			end
		end
	end
	for _, part in CollectionService:GetTagged("EmergencyLight") do
		if part:IsDescendantOf(model) then
			local light = part:FindFirstChild("Emergency") :: PointLight?
			if light then
				light.Brightness = if on then 0 else 1.6
			end
			part.Material = if on then Enum.Material.SmoothPlastic else Enum.Material.Neon
			part.Color = if on then Color3.fromRGB(90, 0, 0) else Color3.fromRGB(255, 30, 20)
		end
	end
end

function Run:StartBlackout()
	if self.Ended or self.Blackout then
		return
	end
	self.Blackout = true
	self.BreakersOn = 0
	local players = self:ActivePlayers()
	for _, part in CollectionService:GetTagged("PowerScreen") do
		if part:IsDescendantOf(self.Station.Model) and not part:GetAttribute("OnColor") then
			part:SetAttribute("OnColor", part.Color)
		end
	end
	self:SetPower(false)
	self.Deadline = os.time() + Config.LightsOut.Duration
	for _, player in players do
		Remotes.Sfx:FireClient(player, "PowerDown")
		Remotes.Blackout:FireClient(
			player,
			{ Active = true, Deadline = self.Deadline, Breakers = 0, Total = #self.Station.Breakers, Count = #self.Escaped }
		)
		Remotes.CloseTools:FireClient(player)
		Remotes.Objective:FireClient(player, {
			Title = "RESTORE THE POWER",
			Text = #self.Escaped .. " of the passengers you approved were NOT human. Flip all 3 breakers. Hide in lockers. Tase it.",
			Step = STEPS,
			Steps = STEPS,
		})
	end
	for _, breaker in self.Station.Breakers do
		breaker.Prompt.Enabled = true
		breaker.Light.Color = Color3.fromRGB(255, 40, 40)
		breaker.Lever.CFrame = breaker.Base * CFrame.new(0, 4.6, -0.6) * CFrame.Angles(math.rad(40), 0, 0)
	end
	-- The things come out of the train
	local count = math.min(3, #self.Escaped)
	task.delay(4, function()
		for i = 1, count do
			if self.Ended or not self.Blackout then
				return
			end
			local monster = NPC.Monster(self.Station.MonsterSpawn * CFrame.new(0, 0, (i - 1) * 4), self.Folder)
			table.insert(self.Monsters, monster)
			for _, player in self:ActivePlayers() do
				Remotes.Sfx:FireClient(player, "MonsterScreech", self.Station.MonsterSpawn.Position)
			end
			task.spawn(function()
				self:MonsterBrain(monster)
			end)
			task.wait(6)
		end
	end)
	task.spawn(function()
		while self.Blackout and not self.Ended do
			task.wait(1)
			if os.time() >= self.Deadline then
				self:EndBlackout(false)
				return
			end
			local active = self:ActivePlayers()
			if #active == 0 then
				self:EndBlackout(false)
				return
			end
			local standing = 0
			for _, player in active do
				if not player:GetAttribute("KnockedOut") then
					standing += 1
				end
			end
			-- Everyone down for longer than a knockout = the station is lost
			if standing == 0 then
				self.AllDownAt = self.AllDownAt or os.clock()
				if os.clock() - self.AllDownAt > Config.LightsOut.KnockoutTime + 2 then
					self:EndBlackout(false)
					return
				end
			else
				self.AllDownAt = nil
			end
		end
	end)
end

function Run:FlipBreaker(player: Player, breaker)
	if not self.Blackout or self.Ended or not breaker.Prompt.Enabled or Run.ByPlayer[player] ~= self then
		return
	end
	breaker.Prompt.Enabled = false
	breaker.Light.Color = Color3.fromRGB(40, 255, 80)
	breaker.Lever.CFrame = breaker.Base * CFrame.new(0, 5.4, -0.6) * CFrame.Angles(math.rad(-40), 0, 0)
	self.BreakersOn += 1
	for _, p in self:ActivePlayers() do
		Remotes.Sfx:FireClient(p, "Breaker")
		Remotes.Blackout:FireClient(
			p,
			{ Active = true, Deadline = self.Deadline, Breakers = self.BreakersOn, Total = #self.Station.Breakers }
		)
		Remotes.notify(
			p,
			"⚡ "
				.. player.DisplayName
				.. " restored breaker "
				.. breaker.Name
				.. " ("
				.. self.BreakersOn
				.. "/"
				.. #self.Station.Breakers
				.. ")",
			"success"
		)
	end
	if self.BreakersOn >= #self.Station.Breakers then
		self:EndBlackout(true)
	end
end

-- Used by the Power Surge product.
function Run:SurgeBreaker(player: Player): boolean
	if not self.Blackout then
		return false
	end
	for _, breaker in self.Station.Breakers do
		if breaker.Prompt.Enabled then
			self:FlipBreaker(player, breaker)
			return true
		end
	end
	return false
end

function Run:EndBlackout(won: boolean)
	if not self.Blackout then
		return
	end
	self.Blackout = false
	for _, breaker in self.Station.Breakers do
		breaker.Prompt.Enabled = false
	end
	for _, monster in self.Monsters do
		monster:Destroy()
	end
	self.Monsters = {}
	if won then
		self:SetPower(true)
	end
	for _, player in self:ActivePlayers() do
		Remotes.Blackout:FireClient(player, { Active = false, Won = won })
		player:SetAttribute("KnockedOut", nil)
		local _, humanoid = character(player)
		if humanoid then
			humanoid.PlatformStand = false
			humanoid.WalkSpeed = 16
		end
	end
	task.delay(if won then 2 else 3, function()
		self:End(won)
	end)
end

function Run:Knockout(player: Player, monster: Model)
	if player:GetAttribute("KnockedOut") then
		return
	end
	player:SetAttribute("KnockedOut", true)
	Run.AddStress(player, Config.Stress.Caught)
	Remotes.Scare:FireClient(player, monster)
	local _, humanoid = character(player)
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.PlatformStand = true
	end
	task.delay(Config.LightsOut.KnockoutTime, function()
		self:WakeUp(player)
	end)
end

function Run:WakeUp(player: Player)
	if not player:GetAttribute("KnockedOut") then
		return
	end
	player:SetAttribute("KnockedOut", nil)
	local _, humanoid = character(player)
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.WalkSpeed = 16
	end
	if self.Blackout then
		teleport(player, self.Station.BreakRoomSpawn)
		Remotes.notify(player, "You wake up in the break room. Your head is pounding.", "warn")
	end
end

-- Chase AI: pathfind to the nearest visible officer, catch them, ignore anyone hiding in a locker.
function Run:MonsterBrain(monster: Model)
	local humanoid = monster:FindFirstChildOfClass("Humanoid")
	local root = monster:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root then
		return
	end
	local wanderPoints = { self.Station.BreakRoomSpawn.Position }
	for _, lane in self.Station.Lanes do
		table.insert(wanderPoints, lane.OfficerSpawn.Position)
		table.insert(wanderPoints, lane.Points.Queue.Position)
	end
	for _, breaker in self.Station.Breakers do
		table.insert(wanderPoints, (breaker.Base * CFrame.new(0, 0, -4)).Position)
	end
	local rng = Random.new()
	while monster.Parent and self.Blackout and not self.Ended do
		if (monster:GetAttribute("StunnedUntil") or 0) > os.clock() then
			humanoid:MoveTo(root.Position)
			task.wait(0.2)
			continue
		end
		-- Pick a target
		local target, best = nil, math.huge
		for _, player in self:ActivePlayers() do
			local _, _, hrp = character(player)
			if hrp and not player:GetAttribute("Hidden") and not player:GetAttribute("KnockedOut") then
				local d = (hrp.Position - root.Position).Magnitude
				if d < best then
					target, best = hrp, d
				end
			end
		end
		local goal = if target then target.Position else wanderPoints[rng:NextInteger(1, #wanderPoints)]
		humanoid.WalkSpeed = if target and best < 40 then Config.LightsOut.MonsterSpeed else Config.LightsOut.MonsterSpeed * 0.6
		local path = PathfindingService:CreatePath({ AgentRadius = 2.5, AgentHeight = 8, AgentCanJump = false })
		local ok = pcall(function()
			path:ComputeAsync(root.Position, goal)
		end)
		local waypoints = if ok and path.Status == Enum.PathStatus.Success then path:GetWaypoints() else {}
		local function tryCatch()
			for _, player in self:ActivePlayers() do
				local _, _, hrp = character(player)
				if
					hrp
					and not player:GetAttribute("Hidden")
					and not player:GetAttribute("KnockedOut")
					and (hrp.Position - root.Position).Magnitude < Config.LightsOut.CatchDistance * 1.45
				then
					self:Knockout(player, monster)
				end
			end
		end
		if #waypoints == 0 then
			humanoid:MoveTo(goal)
			for _ = 1, 4 do
				task.wait(0.1)
				tryCatch()
			end
		else
			local started = os.clock()
			for i = 2, math.min(#waypoints, 7) do
				if not monster.Parent or not self.Blackout then
					return
				end
				if (monster:GetAttribute("StunnedUntil") or 0) > os.clock() then
					break
				end
				humanoid:MoveTo(waypoints[i].Position)
				local reached = false
				local conn = humanoid.MoveToFinished:Once(function()
					reached = true
				end)
				local t0 = os.clock()
				while not reached and os.clock() - t0 < 1 do
					task.wait(0.1)
					tryCatch()
				end
				conn:Disconnect()
				-- Re-plan often when chasing
				if target and os.clock() - started > 1.2 then
					break
				end
			end
		end
	end
end

-- A player's taser shot.
function Run:Taser(player: Player, aim: Vector3)
	local _, _, hrp = character(player)
	if not hrp or typeof(aim) ~= "Vector3" then
		return
	end
	local last = player:GetAttribute("TaserAt") or 0
	if os.clock() - last < Config.LightsOut.TaserCooldown then
		return
	end
	player:SetAttribute("TaserAt", os.clock())
	local origin = hrp.Position + Vector3.new(0, 1.5, 0)
	local direction = (aim - origin)
	if direction.Magnitude < 0.1 then
		return
	end
	direction = direction.Unit * Config.LightsOut.TaserRange
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	local hit = workspace:Spherecast(origin, 1.2, direction, params)
	local endPos = if hit then hit.Position else origin + direction
	for _, p in self.Members do
		Remotes.Sfx:FireClient(p, "Taser", endPos, origin)
	end
	if not hit then
		return
	end
	local model = hit.Instance:FindFirstAncestorOfClass("Model")
	while model and model.Parent and model.Parent:IsA("Model") do
		model = model.Parent :: Model
	end
	if not model then
		return
	end
	if model:GetAttribute("Monster") then
		model:SetAttribute("StunnedUntil", os.clock() + Config.LightsOut.TaserStun)
		Remotes.notify(player, "⚡ Stunned it! RUN!", "success")
	else
		local victim = Players:GetPlayerFromCharacter(model)
		if victim and victim ~= player then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.PlatformStand = true
				task.delay(2, function()
					if not victim:GetAttribute("KnockedOut") then
						humanoid.PlatformStand = false
					end
				end)
			end
			Remotes.notify(victim, "⚡ " .. player.DisplayName .. " tased you!", "warn")
		end
	end
end

-- Pays one player and sends them back to the lobby.
function Run:FinishPlayer(lane, survived: boolean, why: string?)
	if lane.Finished then
		return
	end
	lane.Finished = true
	local player = lane.Player
	if not player.Parent then
		return
	end
	local perfect = survived and lane.Wrong == 0 and lane.Correct > 0
	local pay = lane.Correct * Config.Shift.PayCorrect + (if perfect then Config.Shift.PayPerfectBonus else 0)
	if not survived then
		pay = math.floor(pay / 2)
	end
	local cashGiven = DataService.AddCash(player, pay, true)
	local candyGiven = 0
	local data = DataService.Get(player)
	if survived and data then
		candyGiven = DataService.AddCandy(player, Config.CandyPerShift + (if perfect then Config.CandyPerfectBonus else 0), true)
		data.NextShift = math.max(data.NextShift, self.Shift + 1)
		data.BestShift = math.max(data.BestShift, self.Shift)
		data.Correct += lane.Correct
		if perfect then
			data.PerfectShifts += 1
		end
		DataService.Sync(player)
	end
	Remotes.Results:FireClient(player, {
		Shift = self.Shift,
		Survived = survived,
		Why = why,
		Correct = lane.Correct,
		Wrong = lane.Wrong,
		Perfect = perfect,
		Cash = cashGiven,
		Candy = candyGiven,
		Escaped = #self.Escaped,
		Log = lane.Log,
		NextShift = if data then data.NextShift else self.Shift,
	})
	Remotes.ShiftState:FireClient(player, nil)
	Remotes.Objective:FireClient(player, nil)
	Remotes.Blackout:FireClient(player, { Active = false })
	Run.ByPlayer[player] = nil
	PlayerService.Unhide(player)
	player.CameraMode = Enum.CameraMode.Classic
	player:SetAttribute("Stress", 0)
	player:SetAttribute("InShift", nil)
	player:SetAttribute("Lane", nil)
	player:SetAttribute("Hidden", nil)
	player:SetAttribute("KnockedOut", nil)
	player:SetAttribute("Waypoint", nil)
	removeTaser(player)
	local char, humanoid = character(player)
	if char then
		SkinLook.Clear(char)
	end
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.WalkSpeed = 16
	end
	if self.OnReturn then
		self.OnReturn(player)
	end
end

function Run:End(survived: boolean)
	if self.Ended then
		return
	end
	self.Ended = true
	self.Blackout = false
	for _, lane in self.Lanes do
		self:FinishPlayer(lane, survived and not lane.Fired, if lane.Fired then "fired" elseif survived then nil else "blackout")
	end
	-- Reset the station for the next party
	for _, conn in self.Connections do
		conn:Disconnect()
	end
	self:SetPower(true)
	for _, lane in self.Station.Lanes do
		for _, prompt in lane.Prompts do
			prompt.Enabled = false
		end
		lane.PassportProp.Transparency = 1
		lane.SignLabel.Text = "LANE " .. lane.Index .. "  ·  CLOSED"
		lane.XRayLabel.Text = "X-RAY\nWAITING"
		lane.ScanLabel.Text = "BODY SCAN\nWAITING"
		lane.ScanLight.Color = Color3.fromRGB(90, 200, 255)
	end
	for _, room in self.Station.Interrogation do
		for _, prompt in room.Prompts do
			prompt.Enabled = false
		end
		room.BrainLabel.Text = "NEURO-SCAN\nIDLE"
	end
	for _, breaker in self.Station.Breakers do
		breaker.Prompt.Enabled = false
		breaker.Light.Color = Color3.fromRGB(255, 40, 40)
		breaker.Lever.CFrame = breaker.Base * CFrame.new(0, 4.6, -0.6) * CFrame.Angles(math.rad(40), 0, 0)
	end
	self.Folder:Destroy()
	if self.OnEnd then
		self.OnEnd(self)
	end
end

-- Remote helpers used by Main
function Run.ForPlayer(player: Player)
	local run = Run.ByPlayer[player]
	if not run then
		return nil, nil
	end
	for _, lane in run.Lanes do
		if lane.Player == player then
			return run, lane
		end
	end
	return run, nil
end

function Run.CanUse(prompt: ProximityPrompt, player: Player): boolean
	return canUse(prompt, player)
end

return Run
