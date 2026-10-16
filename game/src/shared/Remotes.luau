--!strict
-- Network events between server and client. The server creates them; clients wait for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	"State", -- server -> client: full HUD snapshot
	"Notify", -- server -> client: short pop-up message
	"Ready", -- client -> server: HUD is ready, send the current state
	"OpenCrafting", -- server -> client: show the workbench window
	"Craft", -- client -> server: craft a recipe (recipe id)
	"OpenMarket", -- server -> client: show the market window
	"Sell", -- client -> server: sell an item (item id, amount or "all"); "*" sells all crops
	"BuySeed", -- client -> server: buy seeds (seed item id, amount)
	"Expand", -- client -> server: buy the next island tier
	"IslandRebuilt", -- server -> client: your island just grew (for effects)
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
	OpenCrafting = folder:WaitForChild("OpenCrafting") :: RemoteEvent,
	Craft = folder:WaitForChild("Craft") :: RemoteEvent,
	OpenMarket = folder:WaitForChild("OpenMarket") :: RemoteEvent,
	Sell = folder:WaitForChild("Sell") :: RemoteEvent,
	BuySeed = folder:WaitForChild("BuySeed") :: RemoteEvent,
	Expand = folder:WaitForChild("Expand") :: RemoteEvent,
	IslandRebuilt = folder:WaitForChild("IslandRebuilt") :: RemoteEvent,
}
