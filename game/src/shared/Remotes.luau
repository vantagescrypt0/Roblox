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
	"PlaceBlock", -- client -> server: place an item's block at grid x, y, z, aimed at the block at x, y, z
	"SaveSettings", -- client -> server: music and sound effects volumes, 0 to 1
	"VisitOpen", -- client -> server: send me the Visit window's list and guestbook
	"VisitState", -- server -> client: that list, and the guestbook of the island you're on
	"VisitGo", -- client -> server: go to this player's island (user id; 0 = home)
	"VisitRule", -- client -> server: who can visit your island (Everyone, Friends, Nobody)
	"GuestbookSign", -- client -> server: sign the guestbook of the island you're on
	"OpenSign", -- both ways: client asks to open its sign at grid x, y, z; server opens it (and the words)
	"EditSign", -- client -> server: write these words on your sign at grid x, y, z
	"MoveStack", -- client -> server: move items between inventory slots (from, to, amount)
	"QuickMove", -- client -> server: send a stack between the hotbar and the rest (slot)
	"SelectSlot", -- client -> server: hotbar slot 1-9 is now selected
	"OpenChest", -- client -> server: open the storage chest at grid x, y, z on your island
	"OpenLootChest", -- client -> server: open this Warzone chest (its id)
	"MineSkydrop", -- client -> server: one finished crack on this sealed Legendary Skydrop (its id)
	"ChestOpened", -- server -> client: show the chest screen (id, title, slots, its part)
	"ChestUpdate", -- server -> client: what's in the chest now (id, slots)
	"ChestClosed", -- server -> client: that chest is shut for you (id)
	"ChestMove", -- client -> server: move items between the chest and you (from, to, amount; chest slots are over 100)
	"ChestQuick", -- client -> server: send a stack straight across (slot)
	"ChestClose", -- client -> server: you closed the chest screen
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
	"Equip", -- client -> server: wear a pet, armor piece or shield (item id), or take it off if worn
	"OpenCrate", -- client -> server: open one of your Loot Crates
	"CrateOpened", -- server -> client: what your crate gave (a list of item id, count, good)
	"KitOpen", -- client -> server: send me what's for sale
	"KitState", -- server -> client: each kit (on sale, owned, seconds until your next claim) and single crates
	"KitClaim", -- client -> server: claim this kit's reward (kit id)
	"KitBuy", -- client -> server: show me Roblox's purchase prompt for this kit (kit id)
	"KitBuyCrate", -- client -> server: show me Roblox's purchase prompt for one Loot Crate
	"BoostOpen", -- client -> server: send me my boost crystals
	"BoostState", -- server -> client: your crystals, how many are in each tree, whether you can reassign, on sale
	"BoostAdd", -- client -> server: put one of my free crystals into this tree (tree id)
	"BoostReset", -- client -> server: take all my crystals out of the trees (once a season)
	"BoostBuy", -- client -> server: show me Roblox's purchase prompt for one boost crystal
	"BoostUse", -- client -> server: redeem the Boost Crystal I'm holding (right-click)
	"BoostRedeemed", -- server -> client: "redeemed" or "reset", and how many crystals are free to place now
	"ProfileOpen", -- client -> server: show me this player's profile (Player)
	"ProfileShow", -- server -> client: a player's profile (ProfileService snapshot)
	"AuctionOpen", -- client -> server: send me what's for sale in the Auction House
	"AuctionState", -- server -> client: what's for sale, your own listings, the server's clock
	"AuctionList", -- client -> server: put this up for sale (item, count, "BuyNow"/"Auction", price, hours)
	"AuctionBuy", -- client -> server: buy this Buy Now listing (listing id)
	"AuctionBid", -- client -> server: bid on this auction (listing id, coins)
	"AuctionCancel", -- client -> server: take my listing off the market (listing id)
	"TrackBoard", -- client -> server: show this Challenges board group in the quest tracker (Boards.luau id)
	"LeaveWarzone", -- client -> server: holding the Warzone's Leave button (true), or let go (false)
	"Block", -- client -> server: holding your shield up (true), or let go (false)
	"Attack", -- client -> server: swung, at this character if one's under your aim (Model or nil)
	"Sprint", -- client -> server: sprinting (true), or stopped (false)
	"Knockback", -- server -> client: you were hit; your character gets this velocity
	"HitEffect", -- server -> clients: this character was hit (Model, "hit", "crit", "sweep" or "block")
	"KitPower", -- client -> server: right-clicked with a kit's sword, at this character if one's under the aim
	"KitFx", -- server -> clients: show a kit special going off (kind, where, and what it needs)
	"AdminReply", -- server -> client: the answer to an admin's command or panel action, shown in their chat
	"AdminAction", -- client -> server: an admin panel action (name, then its arguments; AdminService)
	"AdminState", -- server -> client: who's in the server, for the admin panel
	"Announce", -- server -> clients: an admin's announcement (already filtered)
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
	SaveSettings = folder:WaitForChild("SaveSettings") :: RemoteEvent,
	VisitOpen = folder:WaitForChild("VisitOpen") :: RemoteEvent,
	VisitState = folder:WaitForChild("VisitState") :: RemoteEvent,
	VisitGo = folder:WaitForChild("VisitGo") :: RemoteEvent,
	VisitRule = folder:WaitForChild("VisitRule") :: RemoteEvent,
	GuestbookSign = folder:WaitForChild("GuestbookSign") :: RemoteEvent,
	OpenSign = folder:WaitForChild("OpenSign") :: RemoteEvent,
	EditSign = folder:WaitForChild("EditSign") :: RemoteEvent,
	MoveStack = folder:WaitForChild("MoveStack") :: RemoteEvent,
	QuickMove = folder:WaitForChild("QuickMove") :: RemoteEvent,
	SelectSlot = folder:WaitForChild("SelectSlot") :: RemoteEvent,
	OpenChest = folder:WaitForChild("OpenChest") :: RemoteEvent,
	OpenLootChest = folder:WaitForChild("OpenLootChest") :: RemoteEvent,
	MineSkydrop = folder:WaitForChild("MineSkydrop") :: RemoteEvent,
	ChestOpened = folder:WaitForChild("ChestOpened") :: RemoteEvent,
	ChestUpdate = folder:WaitForChild("ChestUpdate") :: RemoteEvent,
	ChestClosed = folder:WaitForChild("ChestClosed") :: RemoteEvent,
	ChestMove = folder:WaitForChild("ChestMove") :: RemoteEvent,
	ChestQuick = folder:WaitForChild("ChestQuick") :: RemoteEvent,
	ChestClose = folder:WaitForChild("ChestClose") :: RemoteEvent,
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
	OpenCrate = folder:WaitForChild("OpenCrate") :: RemoteEvent,
	CrateOpened = folder:WaitForChild("CrateOpened") :: RemoteEvent,
	KitOpen = folder:WaitForChild("KitOpen") :: RemoteEvent,
	KitState = folder:WaitForChild("KitState") :: RemoteEvent,
	KitClaim = folder:WaitForChild("KitClaim") :: RemoteEvent,
	KitBuy = folder:WaitForChild("KitBuy") :: RemoteEvent,
	KitBuyCrate = folder:WaitForChild("KitBuyCrate") :: RemoteEvent,
	BoostOpen = folder:WaitForChild("BoostOpen") :: RemoteEvent,
	BoostState = folder:WaitForChild("BoostState") :: RemoteEvent,
	BoostAdd = folder:WaitForChild("BoostAdd") :: RemoteEvent,
	BoostReset = folder:WaitForChild("BoostReset") :: RemoteEvent,
	BoostBuy = folder:WaitForChild("BoostBuy") :: RemoteEvent,
	BoostUse = folder:WaitForChild("BoostUse") :: RemoteEvent,
	BoostRedeemed = folder:WaitForChild("BoostRedeemed") :: RemoteEvent,
	ProfileOpen = folder:WaitForChild("ProfileOpen") :: RemoteEvent,
	ProfileShow = folder:WaitForChild("ProfileShow") :: RemoteEvent,
	AuctionOpen = folder:WaitForChild("AuctionOpen") :: RemoteEvent,
	AuctionState = folder:WaitForChild("AuctionState") :: RemoteEvent,
	AuctionList = folder:WaitForChild("AuctionList") :: RemoteEvent,
	AuctionBuy = folder:WaitForChild("AuctionBuy") :: RemoteEvent,
	AuctionBid = folder:WaitForChild("AuctionBid") :: RemoteEvent,
	AuctionCancel = folder:WaitForChild("AuctionCancel") :: RemoteEvent,
	TrackBoard = folder:WaitForChild("TrackBoard") :: RemoteEvent,
	LeaveWarzone = folder:WaitForChild("LeaveWarzone") :: RemoteEvent,
	Block = folder:WaitForChild("Block") :: RemoteEvent,
	Attack = folder:WaitForChild("Attack") :: RemoteEvent,
	Sprint = folder:WaitForChild("Sprint") :: RemoteEvent,
	Knockback = folder:WaitForChild("Knockback") :: RemoteEvent,
	HitEffect = folder:WaitForChild("HitEffect") :: RemoteEvent,
	KitPower = folder:WaitForChild("KitPower") :: RemoteEvent,
	KitFx = folder:WaitForChild("KitFx") :: RemoteEvent,
	AdminReply = folder:WaitForChild("AdminReply") :: RemoteEvent,
	AdminAction = folder:WaitForChild("AdminAction") :: RemoteEvent,
	AdminState = folder:WaitForChild("AdminState") :: RemoteEvent,
	Announce = folder:WaitForChild("Announce") :: RemoteEvent,
}
