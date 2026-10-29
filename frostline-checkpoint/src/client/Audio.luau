-- Sounds: one-shots, 3D sounds, music layers and the heartbeat.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Audio = {}

local loops = {}

local function make(name: string, parent: Instance?): Sound?
	local info = Config.Sounds[name]
	if not info or info.Id == 0 then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = "rbxassetid://" .. info.Id
	sound.Volume = info.Volume
	sound.Parent = parent or SoundService
	return sound
end

-- Play once. With a position, the sound comes from that spot in the world.
function Audio.Play(name: string, position: Vector3?, pitch: number?)
	if position then
		local holder = Instance.new("Part")
		holder.Anchored = true
		holder.CanCollide = false
		holder.CanQuery = false
		holder.Transparency = 1
		holder.Size = Vector3.one
		holder.Position = position
		holder.Parent = workspace
		local sound = make(name, holder)
		if not sound then
			holder:Destroy()
			return
		end
		sound.RollOffMaxDistance = 140
		sound.PlaybackSpeed = pitch or 1
		sound:Play()
		sound.Ended:Once(function()
			holder:Destroy()
		end)
		task.delay(30, function()
			if holder.Parent then
				holder:Destroy()
			end
		end)
		return
	end
	local sound = make(name)
	if sound then
		sound.PlaybackSpeed = pitch or 1
		sound:Play()
		sound.Ended:Once(function()
			sound:Destroy()
		end)
	end
end

-- Looping layer (music, ambience, heartbeat). Volume 0 stops it.
function Audio.Loop(name: string, volume: number?)
	local sound = loops[name]
	if not sound then
		sound = make(name)
		if not sound then
			return nil
		end
		sound.Looped = true
		loops[name] = sound
	end
	local base = Config.Sounds[name].Volume
	local target = base * (volume or 1)
	if target <= 0.001 then
		sound:Stop()
	else
		sound.Volume = target
		if not sound.IsPlaying then
			sound:Play()
		end
	end
	return sound
end

-- 3D loop attached to a part (monster growl / breathing).
function Audio.Attach(name: string, part: BasePart): Sound?
	local sound = make(name, part)
	if sound then
		sound.Looped = true
		sound.RollOffMaxDistance = 90
		sound.RollOffMinDistance = 6
		sound:Play()
	end
	return sound
end

return Audio
