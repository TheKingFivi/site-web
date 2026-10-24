-- Shared world state: the map, the bonfire's fuel and the safe zone around it.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local MapBuilder = require(script.Parent.MapBuilder)

local World = {}
World.Fuel = Config.Bonfire.StartFuel

function World.Init()
	local map = MapBuilder.Build()
	World.Bonfire = map.Bonfire
	World.Houses = map.Houses
	World.MapRadius = map.Radius
	World.SetFuel(Config.Bonfire.StartFuel)
end

function World.RandomSpot(minRadius: number?): Vector3
	return MapBuilder.RandomSpot(World.Houses, minRadius)
end

function World.SafeRadius(): number
	if World.Fuel <= 0 then
		return 0
	end
	return Config.Bonfire.MinRadius + World.Fuel * Config.Bonfire.RadiusPerFuel
end

function World.IsSafe(position: Vector3): boolean
	local flat = Vector3.new(position.X, 0, position.Z)
	return flat.Magnitude < World.SafeRadius()
end

function World.IsDaylight(): boolean
	return workspace:GetServerTimeNow() < (workspace:GetAttribute("DaylightUntil") or 0)
end

function World.SetFuel(fuel: number)
	World.Fuel = math.clamp(fuel, 0, Config.Bonfire.MaxFuel)
	workspace:SetAttribute("BonfireFuel", World.Fuel)
	workspace:SetAttribute("BonfireMax", Config.Bonfire.MaxFuel)

	local radius = World.SafeRadius()
	local bonfire = World.Bonfire
	local lit = World.Fuel > 0
	bonfire.Fire.Enabled = lit
	bonfire.Fire.Size = 4 + World.Fuel / Config.Bonfire.MaxFuel * 10
	bonfire.Light.Enabled = lit
	bonfire.Light.Range = math.min(60, radius * 1.6 + 6)
	bonfire.Zone.Transparency = if lit then 0.85 else 1
	TweenService:Create(bonfire.Zone, TweenInfo.new(0.5), { Size = Vector3.new(0.2, radius * 2, radius * 2) }):Play()
end

function World.AddFuel(amount: number)
	World.SetFuel(World.Fuel + amount)
end

return World
