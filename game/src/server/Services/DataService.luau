--!strict
-- Loads and saves each player's data with ProfileStore (session-locked, so the same
-- save can't be open on two servers at once).
-- Studio playtests use their own store, so testing (and Dev "Give"/"Level" commands)
-- never touches anyone's real save.
-- Messages (ProfileStore's MessageAsync) reach a player's save from any server, even while
-- they're offline: they're handed over (OnMessage) once their data is open somewhere.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Inventory = require(ReplicatedStorage.Shared.Inventory)
local ItemOrder = require(ReplicatedStorage.Shared.ItemOrder)
local Items = require(ReplicatedStorage.Shared.Items)
local Seasons = require(ReplicatedStorage.Shared.Seasons)
local ProfileStore = require(script.Parent.Parent.Packages.ProfileStore)

local STORE_NAME = if RunService:IsStudio() then "PlayerData_Studio_v1" else "PlayerData_v1"

-- A letter in the Inbox (InboxService); its items and coins arrive when it's claimed
export type Letter = {
	Id: number,
	From: string,
	Text: string,
	Items: { [string]: number },
	Coins: number,
	At: number, -- os.time() it arrived
}

local SAVE_NOW_WAIT = 20 -- seconds SaveNow waits for Roblox before giving up

local TEMPLATE = {
	Coins = 0,
	Level = 1,
	XP = 0,
	-- The season this save is on (Seasons.luau; SeasonService resets it for a new one)
	Season = 1,
	Settings = { Music = 1, Effects = 1 },
	KitClaims = {} :: { [string]: number }, -- kit id -> os.time() of its last claim (KitService)
	Receipts = {} :: { [string]: number }, -- Robux purchases already paid out: purchase id -> when (KitService)
	Island = {
		Tier = 1,
		-- Blocks the player changed: "x,y,z" -> block type, or "Air" where they broke one
		Blocks = {} :: { [string]: string },
		-- Trees the player planted, by the cell they stand on, until they're felled (see IslandService)
		Trees = {} :: { [string]: { PlantedAt: number, Height: number, Kind: string? } },
		-- The island's own trees the player has felled (they don't grow back), by the cell they stood on
		Felled = {} :: { [string]: boolean },
		-- Nodes the player placed (rewards like a Coal Node): cell -> the block that grows back
		Nodes = {} :: { [string]: string },
		-- Storage chests: cell -> which way it faces and what's in it (ChestService)
		Chests = {} :: { [string]: { Turn: number, Items: { { Slot: number, Item: string, Count: number } } } },
		-- Decorations: cell -> which way it faces (quarter turns), and what a sign says (DecorService)
		Turns = {} :: { [string]: number },
		Signs = {} :: { [string]: string },
		-- Who can visit (Everyone, Friends, Nobody) and what visitors wrote, newest first (VisitService)
		VisitRule = "Everyone",
		Guestbook = {} :: { { UserId: number, Name: string, Text: string, At: number } },
	},
	-- item id -> count: what's in Slots plus what's worn (InventoryService keeps them in step)
	Items = {} :: { [string]: number },
	-- The 36 inventory slots, the first 9 the hotbar (Inventory.luau). Filled in as the save loads.
	Slots = {} :: { Inventory.Stack },
	-- See Skills.luau; new skills reach old saves through Reconcile
	Skills = {
		Farming = { Level = 1, XP = 0 },
		Mining = { Level = 1, XP = 0 },
		Woodcutting = { Level = 1, XP = 0 },
		Crafting = { Level = 1, XP = 0 },
		Combat = { Level = 1, XP = 0 },
	},
	Farm = {
		-- plot number (as a string) -> what's planted there
		Plots = {} :: { [string]: { Crop: string, PlantedAt: number } },
	},
	Flags = {
		StarterKit = false,
		-- The starter hoe: in the starter kit, or mailed once to players from before it was
		StarterHoe = false,
		-- A Water Bucket and a Lava Bucket: the same, for players from before them
		StarterBuckets = false,
		-- Old islands' ready-made farm patch has become the player's own farmland (IslandService)
		OwnFarmland = false,
		-- The beginner chain got a "Craft Twine" step; saves past that point skip it (QuestService)
		TwineStep = false,
		-- Armor sets have become four pieces each (GearService)
		ArmorPieces = false,
		-- Items moved into the 36 slots
		Slots = false,
	},
	-- Mail waiting to be claimed, oldest first (InboxService). Count is how many letters
	-- the player has ever had (each letter's id).
	Inbox = {
		Count = 0,
		Mail = {} :: { Letter },
	},
	-- Skill challenges (Challenges.luau): how many of each resource you've gathered this
	-- season and the milestones reached. They reset each season with the skills.
	Challenges = {
		Counts = {} :: { [string]: number },
		Reached = {} :: { [string]: boolean },
	},
	-- The pet, armor pieces and shield the player wears (item ids, "" = none; see Gear.luau)
	Equipped = {
		Pet = "",
		Helmet = "",
		Chest = "",
		Legs = "",
		Boots = "",
		Shield = "",
	},
	-- Beginner quest chain: which quest you're on and how far along it is
	Quest = {
		Index = 1,
		Progress = 0,
	},
	-- The Challenges board's other groups (Boards.luau), by group id: the Ids of the
	-- challenges finished, and progress on the current one (Current is its Id, so progress
	-- never carries over to a different challenge)
	Boards = {} :: { [string]: { Done: { [string]: boolean }, Current: string, Progress: number } },
	-- The group the quest tracker shows
	Tracked = "Beginner",
	-- Active: in the Warzone right now. (The bag is left from the prototype, and unused.)
	Raid = {
		Active = false,
		Bag = {} :: { [string]: number },
	},
	-- You quit the Warzone: until this time (os.time) rejoining sends you back to that server
	-- and spot, with your hunger as it was (WarzoneService, TravelService)
	Rejoin = {
		JobId = "",
		Until = 0,
		X = 0,
		Y = 0,
		Z = 0,
		Hunger = 100,
	},
	-- You left a body in the Warzone: until this time (os.time) jumping back in takes you to that
	-- server, so you can go after it (BodyService, TravelService)
	Body = {
		JobId = "",
		Until = 0,
	},
	-- Your last trades with other players, newest last, so scams and duplication bugs can
	-- be looked into
	Trades = {} :: { { At: number, With: number, WithName: string, Gave: { [string]: number }, Got: { [string]: number } } },
}

export type Data = typeof(TEMPLATE)
export type IslandData = typeof(TEMPLATE.Island)
type PlayerCallback = (player: Player, data: Data) -> ()
type MessageHandler = (player: Player, data: Data, message: { [string]: any }) -> ()

local DataService = {}

local store = ProfileStore.New(STORE_NAME, TEMPLATE)
local profiles: { [Player]: any } = {}
local leavingCallbacks: { PlayerCallback } = {}
local loadingCallbacks: { PlayerCallback } = {}
local loadedCallbacks: { PlayerCallback } = {}
local changedCallbacks: { PlayerCallback } = {}
local messageHandlers: { [string]: MessageHandler } = {}
local pendingChanges: { [Player]: boolean } = {}

-- Saves from before the 36 slots: what was on the hotbar stays where it was, the rest fills up in
-- the Bag's old order, and what doesn't fit waits in a letter to claim when there's room
local function moveToSlots(data: Data)
	if data.Flags.Slots then
		return
	end
	data.Flags.Slots = true
	local hotbar = (data :: any).Hotbar or {}
	(data :: any).Hotbar = nil

	local left = table.clone(data.Items)
	for _, worn in data.Equipped :: { [string]: string } do
		if worn ~= "" and (left[worn] or 0) > 0 then
			left[worn] -= 1
		end
	end

	local slots = Inventory.Empty()
	for index, itemId in hotbar do
		local item = Items[itemId]
		if item and not item.Equip and (left[itemId] or 0) > 0 and slots[index] then
			local count = math.min(left[itemId], Inventory.MaxStack(itemId))
			slots[index] = { Item = itemId, Count = count }
			left[itemId] -= count
		end
	end
	local waiting: { [string]: number } = {}
	for _, itemId in ItemOrder do
		if (left[itemId] or 0) > 0 then
			local over = Inventory.Insert(slots, itemId, left[itemId])
			if over > 0 then
				waiting[itemId] = over
				data.Items[itemId] -= over
			end
		end
	end
	data.Slots = slots

	if next(waiting) then
		data.Inbox.Count += 1
		table.insert(data.Inbox.Mail, {
			Id = data.Inbox.Count,
			From = "Skycore",
			Text = "Your Bag now holds 36 stacks. These didn't fit, so they're waiting here. Make room, then claim them.",
			Items = waiting,
			Coins = 0,
			At = os.time(),
		})
	end
end

local function profileKey(userId: number): string
	return `Player_{userId}`
end

-- Runs the callback on each player's data as it loads, before any OnDataLoaded callback
-- sees it. It mustn't yield.
function DataService.OnLoading(callback: PlayerCallback)
	table.insert(loadingCallbacks, callback)
end

-- Runs the callback for every player whose data is loaded, now and in the future.
function DataService.OnDataLoaded(callback: PlayerCallback)
	table.insert(loadedCallbacks, callback)
	for player, profile in profiles do
		task.spawn(callback, player, profile.Data)
	end
end

-- Runs the callback (at most once per frame per player) after data changes.
function DataService.OnChanged(callback: PlayerCallback)
	table.insert(changedCallbacks, callback)
end

function DataService.GetData(player: Player): Data?
	local profile = profiles[player]
	return if profile then profile.Data else nil
end

-- Handles messages of one kind (message.Kind) sent with SendMessage, once the player's data
-- is open on this server
function DataService.OnMessage(kind: string, handler: MessageHandler)
	messageHandlers[kind] = handler
end

-- Sends a message (a table with a Kind) to a player's save, online anywhere or offline.
-- Yields; returns false if it couldn't be sent.
function DataService.SendMessage(userId: number, message: { [string]: any }): boolean
	local ok, sent = pcall(function()
		return store:MessageAsync(profileKey(userId), message)
	end)
	if not ok then
		warn(`[DataService] message to {userId} failed: {sent}`)
	end
	return ok and sent == true
end

-- Call after changing a player's data so the HUD and leaderboard update.
-- Saves now and waits for it, for what can't be lost (a Robux purchase). False if it wasn't saved in time.
function DataService.SaveNow(player: Player): boolean
	local profile = profiles[player]
	if not profile or not profile:IsActive() then
		return false
	end
	local saved = false
	local connection = profile.OnAfterSave:Connect(function()
		saved = true
	end)
	profile:Save()
	local deadline = os.clock() + SAVE_NOW_WAIT
	while not saved and os.clock() < deadline and profile:IsActive() do
		task.wait(0.2)
	end
	connection:Disconnect()
	return saved
end

function DataService.MarkChanged(player: Player)
	if pendingChanges[player] then
		return
	end
	pendingChanges[player] = true
	task.defer(function()
		pendingChanges[player] = nil
		local data = DataService.GetData(player)
		if not data then
			return
		end
		for _, callback in changedCallbacks do
			task.spawn(callback, player, data)
		end
	end)
end

local function onPlayerAdded(player: Player)
	local profile = store:StartSessionAsync(profileKey(player.UserId), {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		player:Kick("Your data couldn't be loaded. Please rejoin.")
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		player:Kick("Your data was opened on another server. Please rejoin.")
	end)

	if player.Parent ~= Players then
		profile:EndSession()
		return
	end

	local data = profile.Data
	if not data.Flags.StarterKit then
		data.Flags.StarterKit = true
		data.Flags.StarterHoe = true
		data.Flags.StarterBuckets = true
		data.Flags.OwnFarmland = true
		data.Flags.TwineStep = true
		data.Flags.ArmorPieces = true
		data.Items.WheatSeeds = (data.Items.WheatSeeds or 0) + 6
		data.Items.WoodenHoe = (data.Items.WoodenHoe or 0) + 1
		data.Items.WaterBucket = (data.Items.WaterBucket or 0) + 1
		data.Items.LavaBucket = (data.Items.LavaBucket or 0) + 1
		(data :: any).Hotbar = { "WheatSeeds", "WoodenHoe" }
		-- New players start on the current season (no reset for them)
		data.Season = Seasons.At(os.time())
	end
	if data.Raid.Active then
		data.Raid.Active = false
		data.Raid.Bag = {}
	end

	for _, callback in loadingCallbacks do
		callback(player, data)
	end
	moveToSlots(data)

	profiles[player] = profile
	for _, callback in loadedCallbacks do
		task.spawn(callback, player, data)
	end

	-- Messages waiting for this save, now and while the player stays on this server
	profile:MessageHandler(function(message: any, processed: () -> ())
		if profiles[player] ~= profile then
			return
		end
		local handler = if type(message) == "table" then messageHandlers[message.Kind] else nil
		if handler then
			handler(player, profile.Data, message)
		else
			warn(`[DataService] no handler for message kind {type(message) == "table" and message.Kind}`)
		end
		processed()
	end)
end

-- Runs just before a player's save closes, as they leave, so it can still be changed
function DataService.OnLeaving(callback: PlayerCallback)
	table.insert(leavingCallbacks, callback)
end

function DataService.Start()
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)

	Players.PlayerRemoving:Connect(function(player)
		pendingChanges[player] = nil
		local profile = profiles[player]
		if profile then
			for _, callback in leavingCallbacks do
				callback(player, profile.Data)
			end
			profile:EndSession()
		end
	end)
end

return DataService
