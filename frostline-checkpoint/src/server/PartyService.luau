-- Lobby party pads: step in, create a party (1-4, friends only), count down, start a shift.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local Run = require(script.Parent.Run)
local StationBuilder = require(script.Parent.StationBuilder)

local PartyService = {}

local pads = {}
local stations = {}
local lobbyMarkers
local friendCache = {} -- ["a:b"] = bool

local function isFriend(a: Player, b: Player): boolean
	if a == b then
		return true
	end
	local key = math.min(a.UserId, b.UserId) .. ":" .. math.max(a.UserId, b.UserId)
	if friendCache[key] == nil then
		local ok, result = pcall(a.IsFriendsWith, a, b.UserId)
		friendCache[key] = ok and result == true
	end
	return friendCache[key]
end

local function stationFor(index: number)
	if not stations[index] then
		local folder = workspace:FindFirstChild("Stations") or Instance.new("Folder")
		folder.Name = "Stations"
		folder.Parent = workspace
		stations[index] = StationBuilder.Build(folder, CFrame.new(1400 * index, 0, 0), "Station" .. index)
	end
	return stations[index]
end

local function onPad(pad, player: Player): boolean
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return false
	end
	local rel = hrp.Position - pad.Center
	return math.abs(rel.X) <= pad.Size.X / 2 and math.abs(rel.Z) <= pad.Size.Z / 2 and rel.Y < 12 and rel.Y > -4
end

local function refresh(pad)
	if pad.State == "InShift" then
		pad.Count.Text = "IN SHIFT"
		pad.Status.Text = "SHIFT " .. (pad.Shift or 1) .. " RUNNING"
	elseif pad.State == "Waiting" then
		pad.Count.Text = #pad.Members .. "/" .. pad.MaxSize
		pad.Status.Text = if pad.Countdown <= 0 then "LAUNCHING..." else "STARTING IN " .. pad.Countdown
		if pad.FriendsOnly then
			pad.Status.Text ..= "  ·  👥"
		end
	else
		pad.Count.Text = "0/" .. Config.Party.MaxSize
		pad.Status.Text = if pad.Pending then "CREATING PARTY..." else "STEP IN"
	end
end

local function reset(pad)
	pad.State = "Idle"
	pad.Members = {}
	pad.Leader = nil
	pad.Pending = nil
	pad.MaxSize = Config.Party.MaxSize
	pad.FriendsOnly = false
	pad.Countdown = 0
	refresh(pad)
end

local function launch(pad)
	pad.State = "InShift"
	local members = {}
	for _, p in pad.Members do
		if p.Parent and onPad(pad, p) then
			table.insert(members, p)
		end
	end
	if #members == 0 then
		reset(pad)
		return
	end
	local leaderData = DataService.Get(pad.Leader or members[1])
	local shift = if leaderData then leaderData.NextShift else 1
	pad.Shift = shift
	refresh(pad)
	for _, p in members do
		Remotes.Announce:FireClient(p, "SHIFT " .. shift, nil)
	end
	local station = stationFor(pad.Index)
	local run = Run.new(station, members, shift, function()
		reset(pad)
	end)
	run.OnReturn = function(player: Player)
		local char = player.Character
		if char and lobbyMarkers then
			char:PivotTo(lobbyMarkers.Spawn * CFrame.new(math.random(-6, 6), 0, math.random(-4, 4)))
		end
	end
	run:Start()
end

function PartyService.Init(markers)
	lobbyMarkers = markers
	for i, pad in markers.Pads do
		pad.Index = i
		pads[i] = pad
		reset(pad)
	end

	Remotes.CreateParty.OnServerInvoke = function(player, index, size, friendsOnly)
		local pad = pads[index]
		if not pad or type(size) ~= "number" or size ~= size or player:GetAttribute("InShift") then
			return false, "Can't create a party here."
		end
		if pad.State ~= "Idle" or (pad.Pending and pad.Pending ~= player) then
			return false, "Someone else is already creating a party here."
		end
		if not onPad(pad, player) then
			return false, "Step into the zone first."
		end
		size = math.clamp(math.floor(size), 1, Config.Party.MaxSize)
		pad.State = "Waiting"
		pad.Pending = nil
		pad.Leader = player
		pad.Members = { player }
		pad.MaxSize = size
		pad.FriendsOnly = friendsOnly == true
		pad.Countdown = if size == 1 then 3 else Config.Party.Countdown
		refresh(pad)
		return true, "Party created!"
	end

	task.spawn(function()
		local tick = 0
		while true do
			task.wait(0.25)
			tick += 1
			for _, pad in pads do
				if pad.State == "Idle" then
					-- Someone stepped in: they get to create the party
					if pad.Pending and (not pad.Pending.Parent or not onPad(pad, pad.Pending)) then
						pad.Pending = nil
						refresh(pad)
					end
					-- Still standing there without creating? Ask again every 12 seconds.
					if pad.Pending and os.clock() - (pad.PendingAt or 0) > 12 then
						pad.PendingAt = os.clock()
						Remotes.PartyPrompt:FireClient(pad.Pending, pad.Index)
					end
					if not pad.Pending then
						for _, player in Players:GetPlayers() do
							if not player:GetAttribute("InShift") and onPad(pad, player) then
								pad.Pending = player
								pad.PendingAt = os.clock()
								Remotes.PartyPrompt:FireClient(player, pad.Index)
								refresh(pad)
								break
							end
						end
					end
				elseif pad.State == "Waiting" then
					-- Drop players who left the zone
					for i = #pad.Members, 1, -1 do
						local member = pad.Members[i]
						if not member.Parent or not onPad(pad, member) then
							table.remove(pad.Members, i)
						end
					end
					if #pad.Members == 0 then
						reset(pad)
						continue
					end
					if not table.find(pad.Members, pad.Leader) then
						pad.Leader = pad.Members[1]
					end
					-- New players join
					for _, player in Players:GetPlayers() do
						if not table.find(pad.Members, player) and not player:GetAttribute("InShift") and onPad(pad, player) then
							if #pad.Members >= pad.MaxSize then
								if not player:GetAttribute("ToldFull") then
									player:SetAttribute("ToldFull", true)
									Remotes.notify(player, "This party is full. Try another zone!", "warn")
								end
							elseif pad.FriendsOnly and not isFriend(pad.Leader, player) then
								if not player:GetAttribute("ToldFull") then
									player:SetAttribute("ToldFull", true)
									Remotes.notify(player, "👥 Friends only party.", "warn")
								end
							else
								table.insert(pad.Members, player)
								Remotes.notify(player, "Joined " .. pad.Leader.DisplayName .. "'s party!", "success")
							end
						elseif player:GetAttribute("ToldFull") and not onPad(pad, player) then
							player:SetAttribute("ToldFull", nil)
						end
					end
					if #pad.Members >= pad.MaxSize then
						pad.Countdown = math.min(pad.Countdown, 3)
					end
					if tick % 4 == 0 then
						pad.Countdown -= 1
						if pad.Countdown <= 0 then
							refresh(pad)
							launch(pad)
							continue
						end
					end
					refresh(pad)
				end
			end
		end
	end)
end

return PartyService
