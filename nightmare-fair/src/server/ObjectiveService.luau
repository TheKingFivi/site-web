-- Survivor objectives: light Ritual Pumpkins (with skill checks), power and open the exit gates, escape.
-- Ghosts ring bells to reveal the killer.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local KillerService = require(script.Parent.KillerService)
local Match = require(script.Parent.Match)
local SurvivorService = require(script.Parent.SurvivorService)

local ObjectiveService = {}

local rng = Random.new()
local nextCheck = {} -- [Player] = time of the next skill check
local pending = {} -- [Player] = { Id, Deadline, Pumpkin }
local checkCounter = 0

local DARK_FACE = Color3.fromRGB(30, 20, 15)
local LIT_FACE = Color3.fromRGB(255, 220, 90)

local function now()
	return Match.Now()
end

local function litCount(): number
	local count = 0
	for _, pumpkin in Match.Map.Pumpkins do
		if pumpkin.Lit then
			count += 1
		end
	end
	return count
end

local function setPumpkinVisual(pumpkin)
	local fraction = pumpkin.Progress
	pumpkin.Label.Text = if pumpkin.Lit then "🎃 LIT" else "🎃 " .. math.floor(fraction * 100) .. "%"
	pumpkin.Light.Brightness = if pumpkin.Lit then 3 else fraction * 1.2
	pumpkin.Pumpkin.Color = Color3.fromRGB(150, 75, 25):Lerp(Color3.fromRGB(255, 130, 20), if pumpkin.Lit then 1 else fraction)
	for _, part in pumpkin.Face do
		part.Color = if pumpkin.Lit then LIT_FACE else DARK_FACE
		part.Material = if pumpkin.Lit then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end
end

local function powerGates()
	workspace:SetAttribute("GatesPowered", true)
	workspace:SetAttribute("CollapseEndsAt", now() + Config.EndGameCollapse)
	for _, gate in Match.Map.Gates do
		gate.Lamp.Color = Color3.fromRGB(255, 200, 40)
		gate.Light.Color = Color3.fromRGB(255, 200, 40)
		gate.Prompt.Enabled = true
	end
	for _, pumpkin in Match.Map.Pumpkins do
		pumpkin.Prompt.Enabled = false
	end
	Remotes.announce(
		"⚡ The exit gates have power! Open them and ESCAPE! The fair collapses in " .. Config.EndGameCollapse .. "s.",
		Color3.fromRGB(255, 210, 60)
	)
end

local function lightPumpkin(pumpkin, workers)
	pumpkin.Lit = true
	pumpkin.Progress = 1
	pumpkin.Prompt.Enabled = false
	setPumpkinVisual(pumpkin)
	for _, worker in workers do
		worker:SetAttribute("WorkingOn", nil)
		DataService.Increment(worker, "PumpkinsLit")
		local earned = DataService.AddTickets(worker, Config.Rewards.PumpkinLit, true)
		Remotes.notify(worker, "🎃 Pumpkin lit! +" .. earned .. " 🎟️", "success")
	end
	local count = litCount()
	workspace:SetAttribute("PumpkinsLit", math.min(count, Config.Pumpkins.Needed))
	if Match.Killer then
		Remotes.Ping:FireClient(Match.Killer, pumpkin.Position, "pumpkin")
	end
	if count >= Config.Pumpkins.Needed and not workspace:GetAttribute("GatesPowered") then
		powerGates()
	else
		Remotes.announce("🎃 A Ritual Pumpkin is lit! " .. count .. " / " .. Config.Pumpkins.Needed, Color3.fromRGB(255, 160, 50))
	end
end

local function resolveSkillCheck(player: Player, result: string)
	local check = pending[player]
	if not check then
		return
	end
	pending[player] = nil
	local pumpkin = check.Pumpkin
	if pumpkin.Lit then
		return
	end
	if result == "great" then
		pumpkin.Progress = math.min(0.999, pumpkin.Progress + Config.Pumpkins.GreatBonus / Config.Pumpkins.WorkSeconds)
		DataService.AddTickets(player, Config.Rewards.GreatSkillCheck, true)
	elseif result == "miss" then
		pumpkin.Progress = math.max(0, pumpkin.Progress - Config.Pumpkins.MissPenalty / Config.Pumpkins.WorkSeconds)
		Remotes.notify(player, "💥 The pumpkin sputtered! The killer heard that...", "error")
		if Match.Killer then
			Remotes.Ping:FireClient(Match.Killer, pumpkin.Position, "noise")
			Remotes.notify(Match.Killer, "💥 A survivor botched a pumpkin!", "info")
		end
	end
	setPumpkinVisual(pumpkin)
end

local function tick(dt: number)
	if not Match.Active then
		return
	end
	local t = now()
	local workersByPumpkin = {}
	for _, survivor in Match.Survivors() do
		local index = survivor:GetAttribute("WorkingOn")
		if index then
			local pumpkin = Match.Map.Pumpkins[index]
			local root = Match.Root(survivor)
			local trapped = (survivor:GetAttribute("TrappedUntil") or 0) > t
			if
				not pumpkin
				or pumpkin.Lit
				or not root
				or trapped
				or not Match.IsStandingSurvivor(survivor)
				or (root.Position - pumpkin.Position).Magnitude > Config.Pumpkins.WorkRange + 3
			then
				survivor:SetAttribute("WorkingOn", nil)
				pending[survivor] = nil
			else
				workersByPumpkin[pumpkin] = workersByPumpkin[pumpkin] or {}
				table.insert(workersByPumpkin[pumpkin], survivor)
			end
		end
	end
	for pumpkin, workers in workersByPumpkin do
		local speed = 1 + Config.Pumpkins.CoopBonus * (#workers - 1)
		pumpkin.Progress = math.min(1, pumpkin.Progress + dt / Config.Pumpkins.WorkSeconds * speed)
		if pumpkin.Progress >= 1 then
			lightPumpkin(pumpkin, workers)
		else
			setPumpkinVisual(pumpkin)
			for _, worker in workers do
				worker:SetAttribute("WorkProgress", pumpkin.Progress)
				if not pending[worker] and t >= (nextCheck[worker] or 0) then
					checkCounter += 1
					pending[worker] = { Id = checkCounter, Deadline = t + 3, Pumpkin = pumpkin }
					nextCheck[worker] = t + rng:NextNumber(Config.Pumpkins.SkillCheckMin, Config.Pumpkins.SkillCheckMax)
					Remotes.SkillCheck:FireClient(worker, checkCounter)
				end
			end
		end
	end
	for player, check in pending do
		if t > check.Deadline then
			resolveSkillCheck(player, "miss")
		end
	end
end

local function setupPumpkins()
	for index, pumpkin in Match.Map.Pumpkins do
		pumpkin.Progress = 0
		pumpkin.Lit = false
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(120, 30)
		gui.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
		gui.MaxDistance = 45
		gui.LightInfluence = 0
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(255, 190, 90)
		label.Text = "🎃 0%"
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Parent = label
		label.Parent = gui
		gui.Parent = pumpkin.Pumpkin
		pumpkin.Label = label

		pumpkin.Prompt =
			Match.Prompt(pumpkin.Pumpkin, "WorkPrompt", "Survivor", "Light", "Ritual Pumpkin", 0, Config.Pumpkins.WorkRange + 2)
		pumpkin.Prompt.Triggered:Connect(function(player)
			if not Match.Active or pumpkin.Lit or not Match.IsStandingSurvivor(player) then
				return
			end
			if (player:GetAttribute("TrappedUntil") or 0) > now() then
				return
			end
			player:SetAttribute("WorkingOn", index)
			nextCheck[player] = now() + rng:NextNumber(2, Config.Pumpkins.SkillCheckMax)
		end)
		setPumpkinVisual(pumpkin)
	end
end

local function openGate(gate)
	gate.Open = true
	gate.Prompt.Enabled = false
	gate.Lamp.Color = Color3.fromRGB(60, 255, 90)
	gate.Light.Color = Color3.fromRGB(60, 255, 90)
	for _, door in gate.Doors do
		TweenService:Create(door.Part, TweenInfo.new(2, Enum.EasingStyle.Quad), { CFrame = door.Open }):Play()
		door.Part.CanCollide = false
	end
	Remotes.announce("🚪 An exit gate is OPEN! Get out!", Color3.fromRGB(90, 255, 120))
end

local function setupGates()
	for _, gate in Match.Map.Gates do
		gate.Open = false
		gate.Prompt = Match.Prompt(gate.Switch, "GatePrompt", "Survivor", "Open gate", "Exit Gate", Config.Gates.OpenTime, 9)
		gate.Prompt.Enabled = false
		gate.Prompt.Triggered:Connect(function(player)
			if workspace:GetAttribute("GatesPowered") and not gate.Open and Match.IsStandingSurvivor(player) then
				openGate(gate)
			end
		end)
		gate.Escape.Touched:Connect(function(hit)
			local player = Match.PlayerFromHit(hit)
			if player and gate.Open and Match.Active and Match.IsStandingSurvivor(player) then
				SurvivorService.Escape(player)
			end
		end)
	end
end

local function setupBells()
	for _, bell in Match.Map.Bells do
		bell.ReadyAt = 0
		local prompt = Match.Prompt(bell.Bell, "BellPrompt", "Ghost", "Ring bell", "Ghost Bell", 1, 10)
		prompt.Triggered:Connect(function(ghost)
			if not Match.Active or Match.Role(ghost) ~= "Ghost" or now() < bell.ReadyAt then
				if now() < bell.ReadyAt then
					Remotes.notify(ghost, "🔔 This bell is still ringing. Try another one!", "error")
				end
				return
			end
			bell.ReadyAt = now() + Config.Bells.Cooldown
			KillerService.Reveal(Config.Bells.RevealTime)
			TweenService:Create(
				bell.Bell,
				TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 6, true),
				{ Size = bell.Bell.Size * 1.3 }
			):Play()
			local earned = DataService.AddTickets(ghost, Config.Rewards.BellReveal, true)
			Remotes.notify(ghost, "🔔 The killer is revealed to everyone! +" .. earned .. " 🎟️", "success")
			for _, survivor in Match.Survivors() do
				Remotes.notify(survivor, "🔔 " .. ghost.DisplayName .. "'s ghost rang a bell: the killer is revealed!", "info")
			end
			if Match.Killer then
				Remotes.notify(Match.Killer, "🔔 A ghost rang a bell. Everyone can see you!", "error")
			end
		end)
	end
end

function ObjectiveService.Reset()
	table.clear(pending)
	table.clear(nextCheck)
	workspace:SetAttribute("PumpkinsLit", 0)
	workspace:SetAttribute("PumpkinsNeeded", Config.Pumpkins.Needed)
	workspace:SetAttribute("GatesPowered", false)
	workspace:SetAttribute("CollapseEndsAt", nil)
	for _, pumpkin in Match.Map.Pumpkins do
		pumpkin.Progress = 0
		pumpkin.Lit = false
		pumpkin.Prompt.Enabled = true
		setPumpkinVisual(pumpkin)
	end
	for _, gate in Match.Map.Gates do
		gate.Open = false
		gate.Prompt.Enabled = false
		gate.Lamp.Color = Color3.fromRGB(255, 40, 40)
		gate.Light.Color = Color3.fromRGB(255, 40, 40)
		for _, door in gate.Doors do
			door.Part.CFrame = door.Closed
			door.Part.CanCollide = true
		end
	end
	for _, bell in Match.Map.Bells do
		bell.ReadyAt = 0
	end
end

function ObjectiveService.Init()
	setupPumpkins()
	setupGates()
	setupBells()
	ObjectiveService.Reset()
	Remotes.SkillCheck.OnServerEvent:Connect(function(player, id, result)
		local check = pending[player]
		if check and check.Id == id and (result == "great" or result == "good" or result == "miss") then
			resolveSkillCheck(player, result)
		end
	end)
	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(0.1)
			local current = os.clock()
			local ok, err = pcall(tick, current - last)
			last = current
			if not ok then
				warn("[ObjectiveService] tick error:", err)
			end
		end
	end)
end

return ObjectiveService
