-- Shared state for the current match, plus small helpers every service uses.
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local Match = {}

Match.Active = false
Match.Killer = nil :: Player?
Match.KillerType = nil :: string?
Match.Map = nil -- result of MapBuilder.Build()
Match.BotModel = nil :: Model? -- the AI killer's body, in solo games
Match.OnNoise = nil -- set by BotKiller: function(position) for noises the AI should investigate

function Match.Now(): number
	return workspace:GetServerTimeNow()
end

function Match.Role(player: Player): string
	return player:GetAttribute("Role") or "Lobby"
end

function Match.Health(player: Player): string?
	return player:GetAttribute("Health")
end

function Match.Root(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

function Match.Humanoid(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

-- A survivor who is still in the fight (not downed, carried, caged, eliminated or escaped).
function Match.IsStandingSurvivor(player: Player): boolean
	if Match.Role(player) ~= "Survivor" then
		return false
	end
	local health = Match.Health(player)
	return health == "Healthy" or health == "Injured"
end

function Match.Survivors(): { Player }
	local list = {}
	for _, player in Players:GetPlayers() do
		if Match.Role(player) == "Survivor" then
			table.insert(list, player)
		end
	end
	return list
end

function Match.PlayerFromHit(hit: BasePart): Player?
	local model = hit:FindFirstAncestorOfClass("Model")
	while model do
		local player = Players:GetPlayerFromCharacter(model)
		if player then
			return player
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return nil
end

function Match.SetSpeed(player: Player, speed: number)
	local humanoid = Match.Humanoid(player)
	if humanoid then
		humanoid.WalkSpeed = speed
	end
end

-- A proximity prompt that only players with the given role can see (the client hides the rest).
function Match.Prompt(parent: Instance, name: string, forRole: string, action: string, objectText: string?, hold: number?, range: number?)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = name
	prompt.ActionText = action
	prompt.ObjectText = objectText or ""
	prompt.HoldDuration = hold or 0
	prompt.MaxActivationDistance = range or 8
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("For", forRole)
	prompt:SetAttribute("Range", range or 8)
	CollectionService:AddTag(prompt, "RolePrompt")
	prompt.Parent = parent
	return prompt
end

-- Collision groups: ghosts walk through living players.
function Match.SetupCollisionGroups()
	for _, group in { "Players", "Ghosts" } do
		pcall(function()
			PhysicsService:RegisterCollisionGroup(group)
		end)
	end
	PhysicsService:CollisionGroupSetCollidable("Ghosts", "Players", false)
	PhysicsService:CollisionGroupSetCollidable("Ghosts", "Ghosts", false)
end

function Match.SetCollisionGroup(character: Model, group: string)
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = group
		end
	end
end

return Match
