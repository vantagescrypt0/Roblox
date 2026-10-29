--!strict
-- Loads and saves each player's data with ProfileStore (session-locked, so the same
-- save can't be open on two servers at once).
-- Studio playtests use their own store, so testing (and Dev "Give"/"Level" commands)
-- never touches anyone's real save.
-- Messages (ProfileStore's MessageAsync) reach a player's save from any server, even while
-- they're offline: they're handed over (OnMessage) once their data is open somewhere.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

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

local TEMPLATE = {
	Coins = 0,
	Level = 1,
	XP = 0,
	Season = 1,
	Island = {
		Tier = 1,
		-- Blocks the player changed: "x,y,z" -> block type, or "Air" where they broke one
		Blocks = {} :: { [string]: string },
		-- Trees the player planted, by the cell they stand on, until they're felled (see IslandService)
		Trees = {} :: { [string]: { PlantedAt: number, Height: number } },
		-- The island's own trees the player has felled (they don't grow back), by the cell they stood on
		Felled = {} :: { [string]: boolean },
		-- Nodes the player placed (rewards like a Coal Node): cell -> the block that grows back
		Nodes = {} :: { [string]: string },
	},
	-- item id -> count
	Items = {} :: { [string]: number },
	-- The 5 hotbar slots: item ids ("" = empty)
	Hotbar = { "", "", "", "", "" },
	-- Tool wear: item id -> uses on the tool you're currently using up
	Wear = {} :: { [string]: number },
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
	-- The pet and armor set the player wears (item ids, "" = none; see Gear.luau)
	Equipped = {
		Pet = "",
		Armor = "",
	},
	-- Beginner quest chain: which quest you're on and how far along it is
	Quest = {
		Index = 1,
		Progress = 0,
	},
	-- Warzone run in progress. The bag only becomes yours when you extract; leaving
	-- the game mid-raid loses it.
	Raid = {
		Active = false,
		Bag = {} :: { [string]: number },
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
local loadedCallbacks: { PlayerCallback } = {}
local changedCallbacks: { PlayerCallback } = {}
local messageHandlers: { [string]: MessageHandler } = {}
local pendingChanges: { [Player]: boolean } = {}

local function profileKey(userId: number): string
	return `Player_{userId}`
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
		data.Items.WheatSeeds = (data.Items.WheatSeeds or 0) + 6
		data.Items.WoodenHoe = (data.Items.WoodenHoe or 0) + 1
		data.Hotbar[1] = "WheatSeeds"
		data.Hotbar[2] = "WoodenHoe"
	end
	if data.Raid.Active then
		data.Raid.Active = false
		data.Raid.Bag = {}
	end

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

function DataService.Start()
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)

	Players.PlayerRemoving:Connect(function(player)
		pendingChanges[player] = nil
		local profile = profiles[player]
		if profile then
			profile:EndSession()
		end
	end)
end

return DataService
