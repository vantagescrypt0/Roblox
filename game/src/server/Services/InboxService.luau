--!strict
-- The Inbox: mail a player receives, kept in their save until they claim it in the Inbox
-- window. A letter says who it's from and a line of text, and can carry items and coins
-- that arrive when it's claimed: starter kits and gifts from the game now; later things
-- from traders, rewards and auction sales. Mail to a player who isn't on this server goes
-- through their save's messages (DataService.SendMessage), so it reaches them on whichever
-- server they're on, or the next time they join.
--
--   InboxService.Send(userId, { From = "Builder", Text = "Thanks!", Items = { Stone = 8 }, Coins = 50 })
--
-- Players from before the starter hoe (or the starter buckets) were in the starter kit get
-- theirs by mail, once.
--
-- What doesn't fit in your Bag waits here too (InventoryService.Add), and claiming takes as much
-- as there's room for, leaving the rest in the letter.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local StateService = require(script.Parent.StateService)

-- A full inbox opens its oldest letter by itself, so a save can't grow without end
local MAX_MAIL = 100
local CLAIM_COOLDOWN = 0.2
local BAG_LETTER = "Your Bag"

-- What a sender writes (InboxService.Send)
export type Mail = { From: string, Text: string, Items: { [string]: number }?, Coins: number? }

local InboxService = {}

local lastClaim: { [Player]: number } = {}

-- Only real items in whole positive amounts, whole coins, short text
local function clean(mail: any): Mail
	local items: { [string]: number } = {}
	if type(mail.Items) == "table" then
		for itemId, count in mail.Items do
			if type(itemId) == "string" and Items[itemId] and type(count) == "number" and count >= 1 then
				items[itemId] = math.floor(count)
			end
		end
	end
	return {
		From = string.sub(tostring(mail.From or "Skycore"), 1, 40),
		Text = string.sub(tostring(mail.Text or ""), 1, 200),
		Items = items,
		Coins = if type(mail.Coins) == "number" then math.max(0, math.floor(mail.Coins)) else 0,
	}
end

-- Gives letters' items and coins to the player (they're already out of the inbox), with
-- one message for all of them
local function open(player: Player, letters: { DataService.Letter })
	local items: { [string]: number } = {}
	local coins = 0
	for _, letter in letters do
		for itemId, count in letter.Items do
			items[itemId] = (items[itemId] or 0) + count
		end
		coins += letter.Coins
	end
	local got = {}
	for itemId, count in items do
		if Items[itemId] then
			InventoryService.Add(player, itemId, count)
			table.insert(got, `+{count} {Items[itemId].Name}`)
		end
	end
	if coins > 0 then
		InventoryService.AddCoins(player, coins)
		table.insert(got, `+{coins} {if coins == 1 then "coin" else "coins"}`)
	end
	DataService.MarkChanged(player)
	if #got > 0 then
		StateService.Notify(player, table.concat(got, ", "), "good")
	end
end

-- Puts a letter in the inbox of a player on this server
local function deliver(player: Player, data: DataService.Data, mail: any)
	local letter = clean(mail)
	data.Inbox.Count += 1
	table.insert(data.Inbox.Mail, {
		Id = data.Inbox.Count,
		From = letter.From,
		Text = letter.Text,
		Items = letter.Items or {},
		Coins = letter.Coins or 0,
		At = os.time(),
	})
	local overflow = {}
	while #data.Inbox.Mail > MAX_MAIL do
		table.insert(overflow, table.remove(data.Inbox.Mail, 1) :: DataService.Letter)
	end
	if #overflow > 0 then
		open(player, overflow)
	end
	DataService.MarkChanged(player)
	StateService.Notify(player, `New mail from {letter.From}! Open your Inbox`, "info")
end

-- Sends a letter to a player wherever they are, or for the next time they join. Yields
-- when they aren't on this server; returns false if it couldn't be sent.
function InboxService.Send(userId: number, mail: Mail): boolean
	local player = Players:GetPlayerByUserId(userId)
	local data = player and DataService.GetData(player)
	if player and data then
		deliver(player, data, mail)
		return true
	end
	return DataService.SendMessage(userId, { Kind = "Mail", Mail = clean(mail) })
end

-- Claiming from the Inbox window: one letter by its id, or "*" for all of them
local function onClaim(player: Player, id: unknown)
	local now = os.clock()
	if now - (lastClaim[player] or 0) < CLAIM_COOLDOWN then
		return
	end
	lastClaim[player] = now
	local data = DataService.GetData(player)
	if not data then
		return
	end
	local got: { [string]: number } = {}
	local coins = 0
	local stillWaiting = false
	for index = #data.Inbox.Mail, 1, -1 do
		local letter = data.Inbox.Mail[index]
		if id == "*" or letter.Id == id then
			for itemId, count in letter.Items do
				local give = if Items[itemId] then math.min(count, InventoryService.RoomFor(player, itemId)) else count
				if give > 0 and Items[itemId] then
					InventoryService.Add(player, itemId, give)
					got[itemId] = (got[itemId] or 0) + give
				end
				letter.Items[itemId] = (if count > give then count - give else nil) :: any
			end
			coins += letter.Coins
			letter.Coins = 0
			if next(letter.Items) then
				stillWaiting = true
			else
				table.remove(data.Inbox.Mail, index)
			end
		end
	end
	local lines = {}
	for itemId, count in got do
		table.insert(lines, `+{count} {Items[itemId].Name}`)
	end
	if coins > 0 then
		InventoryService.AddCoins(player, coins)
		table.insert(lines, `+{coins} {if coins == 1 then "coin" else "coins"}`)
	end
	DataService.MarkChanged(player)
	if #lines > 0 then
		StateService.Notify(player, table.concat(lines, ", "), "good")
	end
	if stillWaiting then
		StateService.Notify(player, "Your Bag is full: the rest is still in your Inbox", "bad")
	end
end

-- What didn't fit in the Bag: one letter that keeps growing until it's claimed
local function onOverflow(player: Player, itemId: string, amount: number)
	local data = DataService.GetData(player)
	if not data then
		return
	end
	local last = data.Inbox.Mail[#data.Inbox.Mail]
	if last and last.From == BAG_LETTER then
		last.Items[itemId] = (last.Items[itemId] or 0) + amount
		DataService.MarkChanged(player)
	else
		deliver(player, data, {
			From = BAG_LETTER,
			Text = "Your Bag was full, so this is waiting here. Make room, then claim it.",
			Items = { [itemId] = amount },
		})
	end
end

function InboxService.Start()
	InventoryService.OnOverflow(onOverflow)
	DataService.OnMessage("Mail", function(player, data, message)
		if type(message.Mail) == "table" then
			deliver(player, data, message.Mail)
		end
	end)
	DataService.OnDataLoaded(function(player, data)
		if not data.Flags.StarterHoe then
			data.Flags.StarterHoe = true
			deliver(player, data, {
				From = "Skycore",
				Text = "Crops need a hoe to harvest now, so here's one to start you off. Pumpkins and melons need an axe.",
				Items = { WoodenHoe = 1 },
			})
		end
		if not data.Flags.StarterBuckets then
			data.Flags.StarterBuckets = true
			deliver(player, data, {
				From = "Skycore",
				Text = "Water and lava are here! Pour them on your island. Where they meet, stone forms: mine it and it forms again. Don't touch the lava!",
				Items = { WaterBucket = 1, LavaBucket = 1 },
			})
		end
	end)
	Remotes.ClaimMail.OnServerEvent:Connect(onClaim)
	Players.PlayerRemoving:Connect(function(player)
		lastClaim[player] = nil
	end)
end

return InboxService
