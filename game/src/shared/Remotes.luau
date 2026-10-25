--!strict
-- Network events between server and client. The server creates them; clients wait for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	"State", -- server -> client: full HUD snapshot
	"Notify", -- server -> client: short pop-up message
	"Ready", -- client -> server: HUD is ready, send the current state
	"OpenCrafting", -- server -> client: show the crafting window
	"Craft", -- client -> server: craft a recipe (recipe id)
	"OpenMarket", -- server -> client: show the market window
	"Sell", -- client -> server: sell an item (item id, amount or "all"); "*" sells all crops
	"BuySeed", -- client -> server: buy seeds (seed item id, amount)
	"Expand", -- client -> server: buy the next island tier
	"IslandRebuilt", -- server -> client: your island just grew (for effects)
	"BreakBlock", -- client -> server: break the block at grid x, y, z on your island
	"PlaceBlock", -- client -> server: place an item's block at grid x, y, z
	"SetHotbar", -- client -> server: put an item (or "") in hotbar slot 1-5
	"SelectSlot", -- client -> server: hotbar slot 1-5 is now selected
	"Travel", -- server -> client: you're being moved to "Town" or "Island" (for the fade)
	"FarmClick", -- client -> server: clicked the farmland at grid x, y, z (plant or harvest)
	"Till", -- client -> server: hoe the grass or dirt block at grid x, y, z into farmland
	"TradeRequest", -- client -> server: ask another player in Town to trade (player)
	"TradeInvite", -- server -> client: a player wants to trade with you (player), or nil to withdraw
	"TradeRespond", -- client -> server: answer an invite (player, accepted)
	"TradeOffer", -- client -> server: put this many of an item in your side of the trade (item id, count)
	"TradeAccept", -- client -> server: accept or un-accept the trade as you see it (accepted, version)
	"TradeCancel", -- client -> server: close the trade
	"TradeUpdate", -- server -> client: what the trade window shows, or nil when the trade closes
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
	BreakBlock = folder:WaitForChild("BreakBlock") :: RemoteEvent,
	PlaceBlock = folder:WaitForChild("PlaceBlock") :: RemoteEvent,
	SetHotbar = folder:WaitForChild("SetHotbar") :: RemoteEvent,
	SelectSlot = folder:WaitForChild("SelectSlot") :: RemoteEvent,
	Travel = folder:WaitForChild("Travel") :: RemoteEvent,
	FarmClick = folder:WaitForChild("FarmClick") :: RemoteEvent,
	Till = folder:WaitForChild("Till") :: RemoteEvent,
	TradeRequest = folder:WaitForChild("TradeRequest") :: RemoteEvent,
	TradeInvite = folder:WaitForChild("TradeInvite") :: RemoteEvent,
	TradeRespond = folder:WaitForChild("TradeRespond") :: RemoteEvent,
	TradeOffer = folder:WaitForChild("TradeOffer") :: RemoteEvent,
	TradeAccept = folder:WaitForChild("TradeAccept") :: RemoteEvent,
	TradeCancel = folder:WaitForChild("TradeCancel") :: RemoteEvent,
	TradeUpdate = folder:WaitForChild("TradeUpdate") :: RemoteEvent,
}
