-- Moon Raids: every few minutes night falls, base locks stop working,
-- Moonlit mutations and Secret critters appear. This is the game's signature event.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local EventService = {}

local DAY = { ClockTime = 14, Brightness = 2, OutdoorAmbient = Color3.fromRGB(128, 128, 128) }
local NIGHT = { ClockTime = 0, Brightness = 1, OutdoorAmbient = Color3.fromRGB(70, 80, 130) }

local function setLighting(goal)
	TweenService:Create(Lighting, TweenInfo.new(5, Enum.EasingStyle.Sine), goal):Play()
end

local function now()
	return workspace:GetServerTimeNow()
end

function EventService.Init()
	for key, value in DAY do
		Lighting[key] = value
	end
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.3
	atmosphere.Parent = Lighting

	workspace:SetAttribute("MoonRaid", false)
	workspace:SetAttribute("LuckUntil", 0)

	task.spawn(function()
		while true do
			workspace:SetAttribute("MoonRaid", false)
			workspace:SetAttribute("NextRaidAt", now() + Config.MoonRaid.Interval)
			setLighting(DAY)
			task.wait(Config.MoonRaid.Interval)

			workspace:SetAttribute("RaidEndsAt", now() + Config.MoonRaid.Duration)
			workspace:SetAttribute("MoonRaid", true)
			setLighting(NIGHT)
			Remotes.announce("🌙 MOON RAID! Base locks are OFF and SECRET critters can appear!", Color3.fromRGB(160, 180, 255))
			task.wait(Config.MoonRaid.Duration)
			Remotes.announce("☀️ The Moon Raid is over. Locks work again!", Color3.fromRGB(255, 230, 140))
		end
	end)
end

return EventService
