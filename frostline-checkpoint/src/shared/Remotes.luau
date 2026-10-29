-- Creates the remotes on the server and waits for them on the client.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EVENTS = {
	"Notify", -- server -> client: toast
	"Announce", -- server -> all: big banner
	"Speech", -- server -> all: an NPC speech bubble (head, text)
	"Objective", -- server -> client: { Title, Text, Step, Steps } or nil
	"ShiftState", -- server -> client: shift HUD (shift, strikes, remaining, rules...) or nil when you leave
	"OpenTool", -- server -> client: open an inspection panel (key, data)
	"CloseTools", -- server -> client: close all panels
	"Verdict", -- server -> client: result of a decision
	"Results", -- server -> client: end-of-shift summary
	"Blackout", -- server -> client: lights-out state for your station
	"Scare", -- server -> client: jumpscare
	"Sfx", -- server -> client(s): sound effect (name, position?)
	"PartyPrompt", -- server -> client: open the Create Party panel for a pad
	"OpenMenu", -- server -> client: open Shop / Skins / Rewards
	"Taser", -- client -> server: fire the taser toward a position
}
local FUNCTIONS = { "CreateParty", "Ask", "ClaimDaily", "BuySkin", "EquipSkin", "UseHint", "UseRadar", "Decide" }

local Remotes = {}

if RunService:IsServer() then
	local folder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
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
