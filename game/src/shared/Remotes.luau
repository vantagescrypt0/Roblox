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
	"OpenShop", -- server -> client: show a shopkeeper's window (shop id, see Shops.luau)
	"Sell", -- client -> server: sell to a shop (shop id, item id, amount or "all"); item "*" sells everything it buys
	"Buy", -- client -> server: buy from a shop (shop id, item id, amount)
	"Expand", -- client -> server: buy the next island tier
	"IslandRebuilt", -- server -> client: your island was upgraded to this level (for effects)
	"BreakBlock", -- client -> server: break the block at grid x, y, z (your island, or the world you're in)
	"PlaceBlock", -- client -> server: place an item's block at grid x, y, z
	"SetHotbar", -- client -> server: put an item (or "") in hotbar slot 1-5
	"SelectSlot", -- client -> server: hotbar slot 1-5 is now selected
	"Travel", -- server -> client: you're being moved to another place (Places.Kind, for the fade)
	"FarmClick", -- client -> server: clicked the farmland at grid x, y, z (plant or harvest)
	"Till", -- client -> server: hoe the grass or dirt block at grid x, y, z into farmland
	"PlantSapling", -- client -> server: plant a sapling on the grass or dirt block at grid x, y, z
	"Uproot", -- client -> server: dig up the growing sapling at grid x, y, z
	"Scoop", -- client -> server: scoop up the water or lava source at grid x, y, z with the empty Bucket you hold
	"TradeRequest", -- client -> server: ask another player in Town to trade (player)
	"TradeInvite", -- server -> client: a player wants to trade with you (player), or nil to withdraw
	"TradeRespond", -- client -> server: answer an invite (player, accepted)
	"TradeOffer", -- client -> server: put this many of an item in your side of the trade (item id, count)
	"TradeAccept", -- client -> server: accept or un-accept the trade as you see it (accepted, version)
	"TradeCancel", -- client -> server: close the trade
	"TradeUpdate", -- server -> client: what the trade window shows, or nil when the trade closes
	"ClaimMail", -- client -> server: claim a letter in your Inbox (its id, or "*" for all of them)
	"Equip", -- client -> server: wear a pet or armor set (item id), or take it off if worn
	"TrackBoard", -- client -> server: show this Challenges board group in the quest tracker (Boards.luau id)
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
	OpenShop = folder:WaitForChild("OpenShop") :: RemoteEvent,
	Sell = folder:WaitForChild("Sell") :: RemoteEvent,
	Buy = folder:WaitForChild("Buy") :: RemoteEvent,
	Expand = folder:WaitForChild("Expand") :: RemoteEvent,
	IslandRebuilt = folder:WaitForChild("IslandRebuilt") :: RemoteEvent,
	BreakBlock = folder:WaitForChild("BreakBlock") :: RemoteEvent,
	PlaceBlock = folder:WaitForChild("PlaceBlock") :: RemoteEvent,
	SetHotbar = folder:WaitForChild("SetHotbar") :: RemoteEvent,
	SelectSlot = folder:WaitForChild("SelectSlot") :: RemoteEvent,
	Travel = folder:WaitForChild("Travel") :: RemoteEvent,
	FarmClick = folder:WaitForChild("FarmClick") :: RemoteEvent,
	Till = folder:WaitForChild("Till") :: RemoteEvent,
	PlantSapling = folder:WaitForChild("PlantSapling") :: RemoteEvent,
	Uproot = folder:WaitForChild("Uproot") :: RemoteEvent,
	Scoop = folder:WaitForChild("Scoop") :: RemoteEvent,
	TradeRequest = folder:WaitForChild("TradeRequest") :: RemoteEvent,
	TradeInvite = folder:WaitForChild("TradeInvite") :: RemoteEvent,
	TradeRespond = folder:WaitForChild("TradeRespond") :: RemoteEvent,
	TradeOffer = folder:WaitForChild("TradeOffer") :: RemoteEvent,
	TradeAccept = folder:WaitForChild("TradeAccept") :: RemoteEvent,
	TradeCancel = folder:WaitForChild("TradeCancel") :: RemoteEvent,
	TradeUpdate = folder:WaitForChild("TradeUpdate") :: RemoteEvent,
	ClaimMail = folder:WaitForChild("ClaimMail") :: RemoteEvent,
	Equip = folder:WaitForChild("Equip") :: RemoteEvent,
	TrackBoard = folder:WaitForChild("TrackBoard") :: RemoteEvent,
}
