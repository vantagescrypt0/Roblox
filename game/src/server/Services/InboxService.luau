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
-- Players from before the starter hoe was in the starter kit get theirs by mail, once.

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
		From = string.sub(tostring(mail.From or "Skyblox"), 1, 40),
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
	local taken: { DataService.Letter } = {}
	for index = #data.Inbox.Mail, 1, -1 do
		local letter = data.Inbox.Mail[index]
		if id == "*" or letter.Id == id then
			table.insert(taken, table.remove(data.Inbox.Mail, index) :: DataService.Letter)
		end
	end
	if #taken > 0 then
		open(player, taken)
	end
end

function InboxService.Start()
	DataService.OnMessage("Mail", function(player, data, message)
		if type(message.Mail) == "table" then
			deliver(player, data, message.Mail)
		end
	end)
	DataService.OnDataLoaded(function(player, data)
		if not data.Flags.StarterHoe then
			data.Flags.StarterHoe = true
			deliver(player, data, {
				From = "Skyblox",
				Text = "Crops need a hoe to harvest now, so here's one to start you off. Pumpkins and melons need an axe.",
				Items = { WoodenHoe = 1 },
			})
		end
	end)
	Remotes.ClaimMail.OnServerEvent:Connect(onClaim)
	Players.PlayerRemoving:Connect(function(player)
		lastClaim[player] = nil
	end)
end

return InboxService
