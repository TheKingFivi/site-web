-- Real 3D killer looks built from Roblox Marketplace items (set in Config.KillerLooks),
-- plus default Roblox R15 animations for the AI killer.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local KillerLook = {}

local SLOTS = {
	Hat = "HatAccessory",
	Face = "FaceAccessory",
	Back = "BackAccessory",
	Front = "FrontAccessory",
	Neck = "NeckAccessory",
	Shoulder = "ShouldersAccessory",
	Waist = "WaistAccessory",
}

-- Roblox's own default R15 animations (usable by every game).
KillerLook.DefaultAnimations = {
	Run = 507767714,
	Walk = 507777826,
	Idle = 507766388,
}

function KillerLook.Has(killerType: string): boolean
	local look = Config.KillerLooks[killerType]
	if not look then
		return false
	end
	for key in SLOTS do
		if look[key] and look[key] ~= "" then
			return true
		end
	end
	return (look.Shirt or 0) ~= 0 or (look.Pants or 0) ~= 0 or (look.FaceDecal or 0) ~= 0
end

-- Fills a HumanoidDescription with the killer's Marketplace items.
function KillerLook.Fill(description: HumanoidDescription, killerType: string)
	local look = Config.KillerLooks[killerType]
	if not look then
		return description
	end
	for key, property in SLOTS do
		description[property] = look[key] or ""
	end
	if (look.Shirt or 0) ~= 0 then
		description.Shirt = look.Shirt
	end
	if (look.Pants or 0) ~= 0 then
		description.Pants = look.Pants
	end
	if (look.FaceDecal or 0) ~= 0 then
		description.Face = look.FaceDecal
	end
	local animations = look.Animations or {}
	if (animations.Run or 0) ~= 0 then
		description.RunAnimation = animations.Run
	end
	if (animations.Walk or 0) ~= 0 then
		description.WalkAnimation = animations.Walk
	end
	if (animations.Idle or 0) ~= 0 then
		description.IdleAnimation = animations.Idle
	end
	return description
end

-- Puts the Marketplace look on a player who is the killer this round. Returns true if a look was applied.
function KillerLook.ApplyToPlayer(player: Player, killerType: string): boolean
	if not KillerLook.Has(killerType) then
		return false
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end
	local ok, err = pcall(function()
		local description = humanoid:GetAppliedDescription()
		humanoid:ApplyDescription(KillerLook.Fill(description, killerType))
	end)
	if not ok then
		warn("[KillerLook] Could not apply look for " .. killerType .. ": " .. tostring(err))
	end
	return ok
end

-- The animation IDs the AI killer uses (Roblox's default R15 run/walk/idle).
-- Marketplace animation packs only apply to player killers, through their HumanoidDescription.
function KillerLook.AnimationsForBot()
	return KillerLook.DefaultAnimations
end

return KillerLook
