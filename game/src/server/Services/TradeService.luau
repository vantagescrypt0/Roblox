--!strict
-- Player trading in Town. Walk up to another player and use their Trade prompt (made on
-- the client, see TradeWindow) to ask; if they say yes, you both get the trade window.
--
--   1. Each side puts items in. The server keeps both offers and checks every change
--      against what you actually own; the client only ever asks.
--   2. Both press Accept. An Accept counts only for the version of the trade that player
--      was looking at, and any change un-accepts both sides, so nothing can be swapped
--      in at the last second.
--   3. A 3-second countdown, then the server swaps everything in one go. Nothing in the
--      swap waits, so no other code can run halfway through: it all happens or none of it.
--
-- Values come from Economy.luau (worn tools count at their worn value) so the window can
-- warn about lopsided trades. Items only, no coins (see the vault note "Economy &
-- Values"). Both players need player level Leveling.TradeLevel. Every trade is saved in
-- both players' data (Data.Trades) and printed to the server log.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(ReplicatedStorage.Shared.Economy)
local Items = require(ReplicatedStorage.Shared.Items)
local Leveling = require(ReplicatedStorage.Shared.Leveling)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Tools = require(ReplicatedStorage.Shared.Tools)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local StateService = require(script.Parent.StateService)

local INVITE_TIME = 20 -- seconds an invite stays open
local INVITE_COOLDOWN = 3 -- seconds between invites from the same player
local DECLINED_COOLDOWN = 20 -- after a "no thanks", seconds before you can ask them again
local MAX_DISTANCE = 24 -- studs: how close you must be to ask (and to say yes)
local COUNTDOWN = 3
local MAX_KINDS = 12 -- different items per side
local LOG_SIZE = 30 -- trades kept in each player's data

type Offer = { [string]: number }
type Session = {
	Players: { Player },
	Offers: { [Player]: Offer },
	Accepted: { [Player]: boolean },
	Version: number,
	CountdownToken: number?, -- set while the countdown runs
	CountdownEnds: number,
}
type Invite = { Target: Player, Expires: number }

local TradeService = {}

local sessions: { [Player]: Session } = {}
local invites: { [Player]: Invite } = {} -- who you've asked (one at a time)
local lastInvite: { [Player]: number } = {}
local declined: { [Player]: { [Player]: number } } = {} -- target -> who they said no to -> when
local countdownCounter = 0

local function partnerOf(session: Session, player: Player): Player
	return if session.Players[1] == player then session.Players[2] else session.Players[1]
end

local function asPlayer(value: unknown): Player?
	if typeof(value) == "Instance" and (value :: Instance):IsA("Player") then
		return value :: Player
	end
	return nil
end

local function distance(a: Player, b: Player): number
	local rootA = a.Character and a.Character:FindFirstChild("HumanoidRootPart")
	local rootB = b.Character and b.Character:FindFirstChild("HumanoidRootPart")
	if not rootA or not rootB or not rootA:IsA("BasePart") or not rootB:IsA("BasePart") then
		return math.huge
	end
	return (rootA.Position - rootB.Position).Magnitude
end

-- The part-used tool only goes along when you trade every one you have; otherwise you
-- keep it and give fresh ones. Returns item id -> its wear for the worn tools included.
local function wornIn(data: DataService.Data, offer: Offer): { [string]: number }
	local worn = {}
	for itemId, count in offer do
		local wear = data.Wear[itemId]
		if wear and wear > 0 and count >= (data.Items[itemId] or 0) then
			worn[itemId] = wear
		end
	end
	return worn
end

-- One side of the trade as the window shows it: a row per item with what it's worth
local function describe(session: Session, player: Player)
	local offer = session.Offers[player]
	local data = DataService.GetData(player)
	local worn = if data then wornIn(data, offer) else {}
	local rows = {}
	local total = 0
	for itemId, count in offer do
		local value = Economy.Value(itemId) * count
		local wear = worn[itemId]
		local usesLeft = nil
		if wear then
			value += Economy.Value(itemId, wear) - Economy.Value(itemId)
			usesLeft = Tools.ByItem[itemId].Durability - wear
		end
		total += value
		table.insert(rows, { Id = itemId, Count = count, Value = value, UsesLeft = usesLeft })
	end
	return { Items = rows, Value = total, Accepted = session.Accepted[player] }
end

-- Sends both players (or just `only`) what their trade window should show
local function sendViews(session: Session, only: Player?)
	local sides = {}
	for _, player in session.Players do
		sides[player] = describe(session, player)
	end
	for _, player in session.Players do
		if only and player ~= only then
			continue
		end
		local partner = partnerOf(session, player)
		Remotes.TradeUpdate:FireClient(player, {
			Partner = partner.DisplayName,
			Version = session.Version,
			Countdown = if session.CountdownToken then math.max(0, session.CountdownEnds - os.clock()) else nil,
			Mine = sides[player],
			Theirs = sides[partner],
		})
	end
end

-- Any change to the trade un-accepts both sides and stops the countdown
local function changed(session: Session)
	session.Version += 1
	session.CountdownToken = nil
	for _, player in session.Players do
		session.Accepted[player] = false
	end
	sendViews(session)
end

local function close(session: Session, messages: { [Player]: string }, kind: string)
	session.CountdownToken = nil
	for _, player in session.Players do
		if sessions[player] == session then
			sessions[player] = nil
		end
		if player.Parent == Players then
			Remotes.TradeUpdate:FireClient(player, nil)
			if messages[player] then
				StateService.Notify(player, messages[player], kind)
			end
		end
	end
end

-- Takes back your open invite (the other player's invite card disappears)
local function withdraw(sender: Player)
	local invite = invites[sender]
	if not invite then
		return
	end
	invites[sender] = nil
	if invite.Target.Parent == Players then
		Remotes.TradeInvite:FireClient(invite.Target, sender, false)
	end
end

local function startSession(a: Player, b: Player)
	withdraw(a)
	withdraw(b)
	local session: Session = {
		Players = { a, b },
		Offers = { [a] = {}, [b] = {} },
		Accepted = { [a] = false, [b] = false },
		Version = 1,
		CountdownToken = nil,
		CountdownEnds = 0,
	}
	sessions[a] = session
	sessions[b] = session
	sendViews(session)
end

-- How many of an item are in an offer (0 takes it out)
local function setCount(offer: Offer, itemId: string, count: number)
	if count > 0 then
		offer[itemId] = count
	else
		offer[itemId] = nil
	end
end

local function owns(player: Player, offer: Offer): boolean
	for itemId, count in offer do
		if InventoryService.Count(player, itemId) < count then
			return false
		end
	end
	return true
end

local function give(to: Player, offer: Offer, worn: { [string]: number })
	for itemId, count in offer do
		local wear = worn[itemId]
		if wear then
			InventoryService.Add(to, itemId, count - 1)
			InventoryService.AddWorn(to, itemId, wear)
		else
			InventoryService.Add(to, itemId, count)
		end
	end
end

local function logTrade(player: Player, partner: Player, gave: Offer, got: Offer)
	local data = DataService.GetData(player)
	if not data then
		return
	end
	table.insert(data.Trades, {
		At = os.time(),
		With = partner.UserId,
		WithName = partner.Name,
		Gave = table.clone(gave),
		Got = table.clone(got),
	})
	while #data.Trades > LOG_SIZE do
		table.remove(data.Trades, 1)
	end
end

local function summary(offer: Offer): string
	local parts = {}
	for itemId, count in offer do
		table.insert(parts, `{count} {itemId}`)
	end
	return if #parts > 0 then table.concat(parts, ", ") else "nothing"
end

-- The swap itself. Nothing in here waits, so it can't be interrupted halfway.
local function execute(session: Session)
	local a, b = session.Players[1], session.Players[2]
	local offerA, offerB = session.Offers[a], session.Offers[b]
	local dataA, dataB = DataService.GetData(a), DataService.GetData(b)
	if not dataA or not dataB or not owns(a, offerA) or not owns(b, offerB) then
		-- Offers are trimmed whenever someone's items change, so this shouldn't happen
		changed(session)
		for _, player in session.Players do
			StateService.Notify(player, "The trade changed. Check it and accept again", "bad")
		end
		return
	end

	local wornA, wornB = wornIn(dataA, offerA), wornIn(dataB, offerB)
	if not InventoryService.RemoveMany(a, offerA) then
		changed(session)
		return
	end
	if not InventoryService.RemoveMany(b, offerB) then
		give(a, offerA, wornA) -- put A's things back
		changed(session)
		return
	end
	give(b, offerA, wornA)
	give(a, offerB, wornB)

	logTrade(a, b, offerA, offerB)
	logTrade(b, a, offerB, offerA)
	print(`[Trade] {a.Name} ({a.UserId}) gave {summary(offerA)}; {b.Name} ({b.UserId}) gave {summary(offerB)}`)
	close(session, { [a] = "Trade complete!", [b] = "Trade complete!" }, "good")
end

local function startCountdown(session: Session)
	countdownCounter += 1
	local token = countdownCounter
	session.CountdownToken = token
	session.CountdownEnds = os.clock() + COUNTDOWN
	sendViews(session)
	task.delay(COUNTDOWN, function()
		if session.CountdownToken == token and sessions[session.Players[1]] == session then
			execute(session)
		end
	end)
end

-- Both players are a high enough level to trade? Tells `player` if not.
local function levelsOk(player: Player, other: Player): boolean
	local mine, theirs = DataService.GetData(player), DataService.GetData(other)
	if not mine or not theirs then
		return false
	end
	if mine.Level < Leveling.TradeLevel then
		StateService.Notify(
			player,
			`Trading unlocks at level {Leveling.TradeLevel}. You're level {mine.Level}, keep going!`,
			"bad"
		)
		return false
	elseif theirs.Level < Leveling.TradeLevel then
		StateService.Notify(player, `{other.DisplayName} can trade once they reach level {Leveling.TradeLevel}`, "bad")
		return false
	end
	return true
end

local function onRequest(player: Player, target: unknown)
	local other = asPlayer(target)
	if not other or other == player or other.Parent ~= Players or sessions[player] then
		return
	end
	if not levelsOk(player, other) then
		return
	end
	if sessions[other] then
		StateService.Notify(player, `{other.DisplayName} is already trading`, "bad")
		return
	end
	if distance(player, other) > MAX_DISTANCE then
		StateService.Notify(player, `Walk closer to {other.DisplayName} to trade`, "bad")
		return
	end

	-- They already asked you: that's a yes from both
	local theirs = invites[other]
	if theirs and theirs.Target == player and os.clock() < theirs.Expires then
		startSession(other, player)
		return
	end

	local now = os.clock()
	if now - (lastInvite[player] or 0) < INVITE_COOLDOWN then
		return
	end
	local saidNo = declined[other] and declined[other][player]
	if saidNo and now - saidNo < DECLINED_COOLDOWN then
		StateService.Notify(player, `{other.DisplayName} said no thanks. Try again in a bit`, "bad")
		return
	end
	lastInvite[player] = now
	withdraw(player)
	local invite = { Target = other, Expires = now + INVITE_TIME }
	invites[player] = invite
	Remotes.TradeInvite:FireClient(other, player, true)
	StateService.Notify(player, `Asked {other.DisplayName} to trade`, "info")

	task.delay(INVITE_TIME, function()
		if invites[player] == invite then
			withdraw(player)
			StateService.Notify(player, `{other.DisplayName} didn't answer`, "info")
		end
	end)
end

local function onRespond(player: Player, sender: unknown, accepted: unknown)
	local from = asPlayer(sender)
	local invite = from and invites[from]
	if not from or not invite or invite.Target ~= player or os.clock() > invite.Expires then
		return
	end
	if accepted ~= true then
		invites[from] = nil
		declined[player] = declined[player] or {}
		declined[player][from] = os.clock()
		StateService.Notify(from, `{player.DisplayName} said no thanks`, "info")
		return
	end
	if sessions[player] or sessions[from] then
		withdraw(from)
		StateService.Notify(player, `{from.DisplayName} is busy right now`, "bad")
		return
	end
	if not levelsOk(player, from) then
		withdraw(from)
		return
	end
	if distance(player, from) > MAX_DISTANCE * 1.5 then
		-- Keep the invite open: walk over and say yes again
		StateService.Notify(player, `Walk closer to {from.DisplayName} to trade`, "bad")
		Remotes.TradeInvite:FireClient(player, from, true)
		return
	end
	startSession(from, player)
end

local function onOffer(player: Player, itemId: unknown, count: unknown)
	local session = sessions[player]
	if not session or type(itemId) ~= "string" or not Items[itemId] then
		return
	end
	if type(count) ~= "number" or count ~= count then
		return
	end
	local offer = session.Offers[player]
	local amount = math.clamp(math.floor(count), 0, InventoryService.Count(player, itemId))
	if (offer[itemId] or 0) == amount then
		sendViews(session, player) -- nothing to change; resend so their window is in step
		return
	end
	if amount > 0 and not offer[itemId] then
		local kinds = 0
		for _ in offer do
			kinds += 1
		end
		if kinds >= MAX_KINDS then
			StateService.Notify(player, `Up to {MAX_KINDS} different items per trade`, "bad")
			sendViews(session, player)
			return
		end
	end
	setCount(offer, itemId, amount)
	changed(session)
end

local function onAccept(player: Player, accepted: unknown, version: unknown)
	local session = sessions[player]
	if not session or type(accepted) ~= "boolean" then
		return
	end
	if version ~= session.Version then
		-- They were looking at an older version of the trade; show them the new one
		sendViews(session, player)
		return
	end
	if
		accepted
		and next(session.Offers[session.Players[1]]) == nil
		and next(session.Offers[session.Players[2]]) == nil
	then
		return
	end
	if session.Accepted[player] == accepted then
		return
	end
	session.Accepted[player] = accepted
	if accepted and session.Accepted[partnerOf(session, player)] then
		startCountdown(session)
	else
		session.CountdownToken = nil
		sendViews(session)
	end
end

local function onCancel(player: Player)
	local session = sessions[player]
	if session then
		close(session, { [partnerOf(session, player)] = `{player.DisplayName} closed the trade` }, "info")
	else
		-- Already over (e.g. the other player left first): still confirm, so the window closes
		Remotes.TradeUpdate:FireClient(player, nil)
	end
end

-- Your items changed while trading (e.g. you sold some): the offer shrinks to what you
-- still have, and both sides have to accept again
local function onDataChanged(player: Player, data: DataService.Data)
	local session = sessions[player]
	if not session then
		return
	end
	local offer = session.Offers[player]
	local trimmed = false
	for itemId, count in offer do
		local have = data.Items[itemId] or 0
		if have < count then
			setCount(offer, itemId, have)
			trimmed = true
		end
	end
	if trimmed then
		changed(session)
		StateService.Notify(player, "Your items changed, so the trade was updated", "info")
	end
end

local function onPlayerRemoving(player: Player)
	local session = sessions[player]
	if session then
		close(session, { [partnerOf(session, player)] = `{player.DisplayName} left` }, "info")
	end
	withdraw(player)
	for sender, invite in invites do
		if invite.Target == player then
			invites[sender] = nil
		end
	end
	lastInvite[player] = nil
	declined[player] = nil
	for _, list in declined do
		list[player] = nil
	end
end

function TradeService.Start()
	Remotes.TradeRequest.OnServerEvent:Connect(onRequest)
	Remotes.TradeRespond.OnServerEvent:Connect(onRespond)
	Remotes.TradeOffer.OnServerEvent:Connect(onOffer)
	Remotes.TradeAccept.OnServerEvent:Connect(onAccept)
	Remotes.TradeCancel.OnServerEvent:Connect(onCancel)
	DataService.OnChanged(onDataChanged)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
end

return TradeService
