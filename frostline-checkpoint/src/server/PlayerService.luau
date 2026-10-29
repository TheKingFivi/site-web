-- Name tags, skins, daily rewards, locker hiding, and lobby prompts.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local SkinLook = require(script.Parent.SkinLook)

local PlayerService = {}

-- "Shift 5" tag with the player's headshot, like a badge over their head.
local function nameTag(player: Player, char: Model)
	local head = char:WaitForChild("Head", 10) :: BasePart?
	if not head then
		return
	end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "ShiftTag"
	gui.Size = UDim2.fromScale(5, 1.7) -- studs: shrinks with distance like a real sign
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.MaxDistance = 70
	gui.LightInfluence = 0
	gui.Parent = head
	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.fromScale(0.21, 0.62)
	avatar.BackgroundColor3 = Color3.new(1, 1, 1)
	avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
	avatar.Parent = gui
	local square = Instance.new("UIAspectRatioConstraint")
	square.Parent = avatar
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = avatar
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Parent = avatar
	local shift = Instance.new("TextLabel")
	shift.Name = "Shift"
	shift.Position = UDim2.fromScale(0.24, 0)
	shift.Size = UDim2.fromScale(0.76, 0.62)
	shift.BackgroundTransparency = 1
	shift.Font = Enum.Font.FredokaOne
	shift.TextScaled = true
	shift.TextXAlignment = Enum.TextXAlignment.Left
	shift.TextColor3 = Color3.new(1, 1, 1)
	shift.TextStrokeTransparency = 0.2
	shift.Parent = gui
	local name = Instance.new("TextLabel")
	name.Position = UDim2.fromScale(0, 0.66)
	name.Size = UDim2.fromScale(1, 0.31)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextScaled = true
	name.TextColor3 = Color3.fromRGB(230, 230, 230)
	name.TextStrokeTransparency = 0.3
	name.Text = player.DisplayName
	name.Parent = gui
	local function update()
		shift.Text = "Shift " .. (player:GetAttribute("NextShift") or 1)
		if player:GetAttribute("Pass_VIP") then
			name.Text = "👑 " .. player.DisplayName
			name.TextColor3 = Color3.fromRGB(255, 210, 80)
		end
	end
	update()
	player:GetAttributeChangedSignal("NextShift"):Connect(update)
	player:GetAttributeChangedSignal("Pass_VIP"):Connect(update)
end

-- Lockers: hold E to hide; the monster can't see you inside.
local occupied = {} -- [locker Model] = Player
local hiddenIn = {} -- [Player] = { Locker, Return CFrame }

local function unhide(player: Player)
	local info = hiddenIn[player]
	if not info then
		return
	end
	hiddenIn[player] = nil
	occupied[info.Locker] = nil
	player:SetAttribute("Hidden", nil)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		hrp.Anchored = false
		char:PivotTo(info.Return)
	end
	Remotes.Sfx:FireClient(player, "Locker")
end
PlayerService.Unhide = unhide

local function hide(player: Player, locker: Model)
	if hiddenIn[player] then
		unhide(player)
		return
	end
	if occupied[locker] then
		Remotes.notify(player, "Someone is already hiding in there!", "warn")
		return
	end
	local body = locker.PrimaryPart
	local point = body and body:FindFirstChild("HidePoint") :: Attachment?
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not point or not hrp or player:GetAttribute("KnockedOut") then
		return
	end
	occupied[locker] = player
	hiddenIn[player] = { Locker = locker, Return = body.CFrame * CFrame.new(0, -0.6, -3.2) }
	hrp.Anchored = true
	char:PivotTo(point.WorldCFrame)
	player:SetAttribute("Hidden", true)
	Remotes.Sfx:FireClient(player, "Locker")
end

local function wireLocker(locker: Instance)
	if not locker:IsA("Model") then
		return
	end
	local body = locker.PrimaryPart or locker:WaitForChild("Body", 5)
	local prompt = body and body:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.ActionText = "Hide / Leave"
		prompt.Triggered:Connect(function(player)
			if hiddenIn[player] and hiddenIn[player].Locker ~= locker then
				return
			end
			hide(player, locker)
		end)
	end
end

local function findSkin(key)
	for _, skin in Config.Skins do
		if skin.Key == key then
			return skin
		end
	end
	return nil
end

function PlayerService.Init(lobby)
	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(char)
			task.spawn(nameTag, player, char)
			local info = hiddenIn[player]
			if info then
				occupied[info.Locker] = nil
			end
			hiddenIn[player] = nil
			player:SetAttribute("Hidden", nil)
		end)
		if player.Character then
			task.spawn(nameTag, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		unhide(player)
	end)

	for _, locker in CollectionService:GetTagged("HideLocker") do
		task.spawn(wireLocker, locker)
	end
	CollectionService:GetInstanceAddedSignal("HideLocker"):Connect(function(locker)
		task.spawn(wireLocker, locker)
	end)

	-- Lobby prompts open menus
	lobby.ShopPrompt.Triggered:Connect(function(player)
		Remotes.OpenMenu:FireClient(player, "Shop")
	end)
	lobby.DailyPrompt.Triggered:Connect(function(player)
		Remotes.OpenMenu:FireClient(player, "Rewards")
	end)
	for _, prompt in CollectionService:GetTagged("GamePrompt") do
		local key = prompt:GetAttribute("Skin")
		if key then
			prompt.Triggered:Connect(function(player)
				Remotes.OpenMenu:FireClient(player, "Skins", key)
			end)
		end
	end

	Remotes.BuySkin.OnServerInvoke = function(player, key)
		local data = DataService.Get(player)
		local skin = findSkin(key)
		if not data or not skin then
			return false, "Unknown skin."
		end
		if data.OwnedSkins[key] then
			return false, "You already own it."
		end
		if not DataService.Spend(player, skin.Currency, skin.Price) then
			return false, "Not enough " .. (if skin.Currency == "Candy" then "🍬 Candy" else "💵 Cash") .. "."
		end
		data.OwnedSkins[key] = true
		data.Skin = key
		DataService.Sync(player)
		return true, "Unlocked " .. skin.Name .. "! It's equipped for your next shift."
	end

	Remotes.EquipSkin.OnServerInvoke = function(player, key)
		local data = DataService.Get(player)
		if not data or not findSkin(key) or not data.OwnedSkins[key] then
			return false, "You don't own that skin."
		end
		data.Skin = key
		DataService.Sync(player)
		if player:GetAttribute("InShift") and player.Character then
			SkinLook.Apply(player.Character, key)
		end
		return true, "Equipped!"
	end

	Remotes.ClaimDaily.OnServerInvoke = function(player)
		local data = DataService.Get(player)
		if not data then
			return false, "Data not loaded yet."
		end
		local today = os.time() // 86400
		if data.DailyLast >= today then
			return false, "Come back tomorrow!"
		end
		data.DailyStreak = if data.DailyLast == today - 1 then data.DailyStreak + 1 else 1
		data.DailyLast = today
		local day = (data.DailyStreak - 1) % #Config.DailyRewards + 1
		local reward = Config.DailyRewards[day]
		local vip = if player:GetAttribute("Pass_VIP") then 2 else 1
		local parts = {}
		if reward.Cash then
			DataService.AddCash(player, reward.Cash * vip, false)
			table.insert(parts, "$" .. reward.Cash * vip)
		end
		if reward.Candy then
			DataService.AddCandy(player, reward.Candy * vip, false)
			table.insert(parts, reward.Candy * vip .. " 🍬")
		end
		DataService.Sync(player)
		return true, "Day " .. data.DailyStreak .. " reward: " .. table.concat(parts, " + ")
	end
end

return PlayerService
