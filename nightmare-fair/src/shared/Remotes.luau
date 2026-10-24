-- Creates the remotes on the server and waits for them on the client.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EVENTS = {
	"Notify",
	"Announce",
	"Attack", -- killer swings
	"Ability", -- killer uses power
	"SkillCheck", -- server -> client: start a skill check; client -> server: result
	"Scare", -- server -> client: jumpscare flash
	"Swing", -- server -> all: play a swing effect
	"Ping", -- server -> killer: show a noise marker at a position
}
local FUNCTIONS = { "SelectKiller", "BuyKiller", "UseSelfRescue", "BuyCosmetic", "Equip", "OpenCrate" }

local Remotes = {}

if RunService:IsServer() then
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	for _, name in EVENTS do
		local remote = folder:FindFirstChild(name) or Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		Remotes[name] = remote
	end
	for _, name in FUNCTIONS do
		local remote = folder:FindFirstChild(name) or Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = folder
		Remotes[name] = remote
	end
else
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	for _, name in EVENTS do
		Remotes[name] = folder:WaitForChild(name)
	end
	for _, name in FUNCTIONS do
		Remotes[name] = folder:WaitForChild(name)
	end
end

function Remotes.notify(player: Player, text: string, kind: string?)
	Remotes.Notify:FireClient(player, text, kind or "info")
end

function Remotes.announce(text: string, color: Color3?)
	Remotes.Announce:FireAllClients(text, if color then color:ToHex() else nil)
end

return Remotes
