-- Everything about a player's body: lantern & battery, getting downed, reviving, dying, upgrades.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local MonsterService = require(script.Parent.MonsterService)
local World = require(script.Parent.World)

local PlayerService = {}
PlayerService.OnDowned = nil -- set by PickupService: function(player) drops a carried log

local lanterns = {} -- [Player] = { Attachment, Light }
local aims = {} -- [Player] = Vector3
local secondWindUsed = {} -- [Player] = true

local function now()
	return workspace:GetServerTimeNow()
end

local function getHumanoid(player: Player)
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid"), character and character:FindFirstChild("HumanoidRootPart")
end

function PlayerService.BatteryMax(player: Player): number
	return Config.Flashlight.BaseBattery + (player:GetAttribute("Up_Battery") or 0) * Config.Flashlight.BatteryPerLevel
end

function PlayerService.LanternRange(player: Player): number
	return Config.Flashlight.BaseRange + (player:GetAttribute("Up_Lantern") or 0) * Config.Flashlight.RangePerLevel
end

-- Returns the player's root part if they're alive and standing, else nil.
function PlayerService.IsActive(player: Player)
	if player:GetAttribute("Downed") or player:GetAttribute("Dead") then
		return nil
	end
	local humanoid, root = getHumanoid(player)
	if humanoid and humanoid.Health > 0 and root then
		return root
	end
	return nil
end

local function setFlashlight(player: Player, on: boolean)
	local lantern = lanterns[player]
	if lantern then
		lantern.Light.Enabled = on
	end
	player:SetAttribute("FlashlightOn", on)
end

local function refreshStats(player: Player)
	player:SetAttribute("BatteryMax", PlayerService.BatteryMax(player))
	player:SetAttribute("LanternRange", PlayerService.LanternRange(player))
	local lantern = lanterns[player]
	if lantern then
		lantern.Light.Range = PlayerService.LanternRange(player)
	end
end

local function setupCharacter(player: Player, character: Model)
	player:SetAttribute("Downed", false)
	player:SetAttribute("Dead", false)
	player:SetAttribute("CarryingLog", false)
	refreshStats(player)
	player:SetAttribute("Battery", PlayerService.BatteryMax(player))
	setFlashlight(player, false)

	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root then
		return
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "LanternAttachment"
	attachment.Position = Vector3.new(0.8, 1.2, -0.8)
	attachment.Parent = root
	local light = Instance.new("SpotLight")
	light.Brightness = 5
	light.Angle = 50
	light.Range = PlayerService.LanternRange(player)
	light.Color = Color3.fromRGB(255, 235, 190)
	light.Face = Enum.NormalId.Front
	light.Shadows = true
	light.Enabled = false
	light.Parent = attachment
	lanterns[player] = { Attachment = attachment, Light = light }

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RevivePrompt"
	prompt.ActionText = "Revive"
	prompt.ObjectText = player.DisplayName
	prompt.HoldDuration = Config.Downed.ReviveHold
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt:SetAttribute("OwnerId", player.UserId)
	CollectionService:AddTag(prompt, "RevivePrompt")
	prompt.Triggered:Connect(function(reviver)
		if reviver ~= player and PlayerService.IsActive(reviver) and player:GetAttribute("Downed") then
			PlayerService.StandUp(player)
			local earned = DataService.AddCandy(reviver, Config.Downed.ReviveReward, true)
			Remotes.notify(reviver, "💖 You revived " .. player.DisplayName .. "! +" .. earned .. " 🍬", "success")
			Remotes.notify(player, "💖 " .. reviver.DisplayName .. " revived you!", "success")
		end
	end)
	prompt.Parent = root

	humanoid.Died:Connect(function()
		if PlayerService.OnDowned then
			PlayerService.OnDowned(player)
		end
		setFlashlight(player, false)
		player:SetAttribute("Downed", false)
		player:SetAttribute("Dead", true)
		prompt.Enabled = false
	end)
end

function PlayerService.Down(player: Player)
	if not PlayerService.IsActive(player) then
		return
	end
	local humanoid, root = getHumanoid(player)
	player:SetAttribute("Downed", true)
	player:SetAttribute("DownedUntil", now() + Config.Downed.BleedOut)
	setFlashlight(player, false)
	if PlayerService.OnDowned then
		PlayerService.OnDowned(player)
	end
	humanoid.WalkSpeed = Config.Movement.DownedSpeed
	local prompt = root:FindFirstChild("RevivePrompt")
	if prompt then
		prompt.Enabled = true
	end
	Remotes.Jumpscare:FireClient(player)
	for _, other in Players:GetPlayers() do
		if other ~= player then
			Remotes.notify(other, "🆘 " .. player.DisplayName .. " is down! Revive them (hold E)!", "error")
		end
	end
end

function PlayerService.StandUp(player: Player)
	local humanoid, root = getHumanoid(player)
	player:SetAttribute("Downed", false)
	if humanoid then
		humanoid.Health = humanoid.MaxHealth
		humanoid.WalkSpeed = Config.Movement.WalkSpeed
	end
	local prompt = root and root:FindFirstChild("RevivePrompt")
	if prompt then
		prompt.Enabled = false
	end
end

function PlayerService.Die(player: Player)
	local humanoid = getHumanoid(player)
	player:SetAttribute("Downed", false)
	player:SetAttribute("Dead", true)
	if humanoid then
		humanoid.Health = 0
	end
end

-- Gets a downed or dead player back on their feet. Returns false if they didn't need it.
function PlayerService.Revive(player: Player): boolean
	if player:GetAttribute("Downed") then
		PlayerService.StandUp(player)
		return true
	end
	local humanoid = getHumanoid(player)
	if player:GetAttribute("Dead") or not humanoid or humanoid.Health <= 0 then
		player:LoadCharacter()
		return true
	end
	return false
end

function PlayerService.Spawn(player: Player)
	player:LoadCharacter()
end

-- Start of a night / dawn: everyone gets back up.
function PlayerService.ReviveAll()
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("Loaded") then
			PlayerService.Revive(player)
		end
	end
end

function PlayerService.ResetNight()
	table.clear(secondWindUsed)
end

local function useRevive(player: Player, kind: string)
	if not (player:GetAttribute("Downed") or player:GetAttribute("Dead")) then
		return false, "You're not down!"
	end
	if kind == "SecondWind" then
		if not player:GetAttribute("Pass_SecondWind") then
			return false, "You need the Second Wind pass."
		end
		if secondWindUsed[player] then
			return false, "Second Wind already used tonight."
		end
		secondWindUsed[player] = true
	elseif kind == "Token" then
		local data = DataService.Get(player)
		if not data or data.ReviveTokens <= 0 then
			return false, "You have no revive tokens."
		end
		data.ReviveTokens -= 1
		DataService.Sync(player)
	else
		return false, "Unknown revive."
	end
	PlayerService.Revive(player)
	return true, "💖 You're back on your feet!"
end

local function buyUpgrade(player: Player, key: string)
	local upgrade = Config.Upgrades[key]
	local data = DataService.Get(player)
	if type(key) ~= "string" or not upgrade or not data then
		return false, "Unknown upgrade."
	end
	local level = data.Upgrades[key] or 0
	local cost = upgrade.Costs[level + 1]
	if not cost then
		return false, "Already maxed!"
	end
	if not DataService.SpendCandy(player, cost) then
		return false, "You need " .. cost .. " 🍬"
	end
	data.Upgrades[key] = level + 1
	DataService.Sync(player)
	refreshStats(player)
	return true, upgrade.Name .. " is now level " .. (level + 1) .. "!"
end

local function tick(dt: number)
	local t = now()
	for _, player in Players:GetPlayers() do
		local root = PlayerService.IsActive(player)
		if root then
			local battery = player:GetAttribute("Battery") or 0
			local max = PlayerService.BatteryMax(player)
			if player:GetAttribute("FlashlightOn") then
				if not player:GetAttribute("Pass_InfiniteBattery") then
					battery -= Config.Flashlight.DrainPerSec * dt
					if battery <= 0 then
						battery = 0
						setFlashlight(player, false)
						Remotes.notify(player, "🔦 Your lantern died! Recharge it by the bonfire.", "error")
					end
				end
				local lantern = lanterns[player]
				local aim = aims[player]
				if lantern and aim and player:GetAttribute("FlashlightOn") then
					local scared =
						MonsterService.ApplyLight(player, lantern.Attachment.WorldPosition, aim, PlayerService.LanternRange(player), dt)
					if scared then
						local earned = DataService.AddCandy(player, Config.Rewards.ScareMonster, true)
						Remotes.notify(player, "😤 You scared The Hollow away! +" .. earned .. " 🍬", "success")
					end
				end
			elseif World.IsSafe(root.Position) then
				battery = math.min(max, battery + Config.Flashlight.RechargePerSecInLight * dt)
			end
			player:SetAttribute("Battery", math.floor(battery * 10) / 10)
		elseif player:GetAttribute("Downed") and t > (player:GetAttribute("DownedUntil") or 0) then
			PlayerService.Die(player)
			Remotes.notify(player, "💀 You didn't make it. You'll be back at dawn.", "error")
		end
	end
end

function PlayerService.OnPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
	player:GetAttributeChangedSignal("Up_Lantern"):Connect(function()
		refreshStats(player)
	end)
	player:GetAttributeChangedSignal("Up_Battery"):Connect(function()
		refreshStats(player)
	end)
end

function PlayerService.OnPlayerRemoving(player: Player)
	lanterns[player] = nil
	aims[player] = nil
	secondWindUsed[player] = nil
end

function PlayerService.Init()
	Players.CharacterAutoLoads = false

	Remotes.ToggleFlashlight.OnServerEvent:Connect(function(player, on)
		if
			on == true
			and PlayerService.IsActive(player)
			and ((player:GetAttribute("Battery") or 0) > 0 or player:GetAttribute("Pass_InfiniteBattery"))
		then
			setFlashlight(player, true)
		else
			setFlashlight(player, false)
		end
	end)

	Remotes.Aim.OnServerEvent:Connect(function(player, direction)
		if typeof(direction) ~= "Vector3" or direction.Magnitude < 0.5 or direction.Magnitude > 1.5 then
			return
		end
		direction = direction.Unit
		aims[player] = direction
		local lantern = lanterns[player]
		if lantern and lantern.Attachment.Parent then
			local origin = lantern.Attachment.WorldPosition
			lantern.Attachment.WorldCFrame = CFrame.lookAt(origin, origin + direction)
		end
	end)

	Remotes.SetHauntTarget.OnServerEvent:Connect(function(player, userId)
		if type(userId) == "number" then
			player:SetAttribute("HauntTarget", userId)
		end
	end)

	Remotes.UseRevive.OnServerInvoke = useRevive
	Remotes.BuyUpgrade.OnServerInvoke = buyUpgrade

	MonsterService.OnCatch = PlayerService.Down

	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(0.1)
			local current = os.clock()
			local ok, err = pcall(tick, current - last)
			last = current
			if not ok then
				warn("[PlayerService] tick error:", err)
			end
		end
	end)
end

return PlayerService
