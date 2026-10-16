--!strict
-- Network events between server and client. The server creates them; clients wait for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	"State", -- server -> client: full HUD snapshot
	"Notify", -- server -> client: short pop-up message
	"Ready", -- client -> server: HUD is ready, send the current state
}

local folder: Instance
if RunService:IsServer() then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in NAMES do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild("Remotes")
end

return {
	State = folder:WaitForChild("State") :: RemoteEvent,
	Notify = folder:WaitForChild("Notify") :: RemoteEvent,
	Ready = folder:WaitForChild("Ready") :: RemoteEvent,
}
