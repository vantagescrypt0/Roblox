--!strict
-- Visiting other players' islands (Menu > Visit, client/Windows/VisitWindow). The list shows everyone on this
-- island server and your friends on other island servers. A visitor can walk around and look, and can't break,
-- place, open or take anything: BlockService and the client only ever work on your own island.
-- An island is only loaded while its owner is on the server, so you can't visit someone who's offline.
-- Each island says who may come: Everyone, Friends or Nobody (data.Island.VisitRule).
-- Guestbook: visitors sign the book of the island they're standing on (one entry each: signing again replaces it),
-- the newest MAX_BOOK are kept in the owner's save, and the words are checked by Roblox's filter before they're kept.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local TextService = game:GetService("TextService")

local Places = require(ReplicatedStorage.Shared.Places)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Metrics = require(script.Parent.Parent.Util.Metrics)
local Move = require(script.Parent.Parent.Util.Move)
local Policy = require(script.Parent.Parent.Util.Policy)
local DataService = require(script.Parent.DataService)
local AwardService = require(script.Parent.AwardService)
local IslandService = require(script.Parent.IslandService)
local StateService = require(script.Parent.StateService)
local TravelService = require(script.Parent.TravelService)

local MAX_BOOK = 50
local MAX_WORDS = 80
local GO_COOLDOWN = 1.5
local SIGN_COOLDOWN = 15
local ASK_COOLDOWN = 0.5
local ARRIVE_WAIT = 20 -- seconds to wait for a character after teleporting in to visit
local RULES = { Everyone = true, Friends = true, Nobody = true }

local VisitService = {}

local lastGo: { [Player]: number } = {}
local lastSign: { [Player]: number } = {}
local lastAsk: { [Player]: number } = {}

local function mayVisit(visitor: Player, owner: Player, ownerData: DataService.Data): boolean
	local rule = ownerData.Island.VisitRule
	if rule == "Nobody" then
		return false
	elseif rule == "Friends" then
		local ok, friends = pcall(function()
			return visitor:IsFriendsWith(owner.UserId)
		end)
		return ok and friends
	end
	return true
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- Whose island this player is standing on
local function hostOf(player: Player): Player?
	local root = rootOf(player)
	return if root then IslandService.OwnerAt(root.Position) else nil
end

-- Someone else's island they're on, if they're on one
local function visitedBy(player: Player): Player?
	local host = hostOf(player)
	return if host ~= player then host else nil
end

local function sendState(player: Player)
	local data = DataService.GetData(player)
	if not data then
		return
	end
	local host = visitedBy(player)
	local rows = {}
	for _, other in Players:GetPlayers() do
		local otherData = if other ~= player then DataService.GetData(other) else nil
		if otherData and IslandService.GetIsland(other) then
			table.insert(rows, {
				UserId = other.UserId,
				Name = other.DisplayName,
				Level = otherData.Level,
				Tier = otherData.Island.Tier,
				Open = mayVisit(player, other, otherData),
				Here = other == host,
			})
		end
	end
	table.sort(rows, function(a, b)
		return a.Name < b.Name
	end)
	-- The book of the island they're on: their own when they're at home
	local hostData = if host then DataService.GetData(host) else nil
	-- Yields the first time it's asked for a player
	local sharing = Policy.ContentSharingAllowed(player)
	Remotes.VisitState:FireClient(player, {
		Rows = rows,
		Rule = data.Island.VisitRule,
		HostName = if host then host.DisplayName else nil,
		Book = if sharing then (hostData or data).Island.Guestbook else {},
		Sharing = sharing,
	})
end

local function goHome(player: Player)
	local island = IslandService.GetIsland(player)
	if island then
		pcall(function()
			player:RequestStreamAroundAsync(island.Spawn.Position)
		end)
		IslandService.SendHome(player)
		sendState(player)
	end
end

local function arrive(visitor: Player, owner: Player)
	local island = IslandService.GetIsland(owner)
	local character = visitor.Character
	if not island or not character then
		return
	end
	pcall(function()
		visitor:RequestStreamAroundAsync(island.Spawn.Position)
	end)
	Move.To(character, island.Spawn.CFrame + Vector3.new(0, 4, 0))
	Metrics.Event(visitor, "IslandVisited")
	AwardService.Give(visitor, "Visitor")
	StateService.Notify(visitor, `Welcome to {owner.DisplayName}'s island`, "info")
	StateService.Notify(owner, `{visitor.DisplayName} is visiting your island`, "info")
	sendState(visitor)
end

-- Someone who isn't on this server: only friends can be followed to another server
local function followFriend(player: Player, userId: number)
	local isFriend, friends = pcall(function()
		return player:IsFriendsWith(userId)
	end)
	if not isFriend or not friends then
		StateService.Notify(player, "That island isn't on this server any more", "bad")
		return
	end
	if RunService:IsStudio() then
		StateService.Notify(player, "Visiting another server only works in the published game", "bad")
		return
	end
	local ok, _current, _problem, placeId, jobId = pcall(function()
		return TeleportService:GetPlayerPlaceInstanceAsync(userId)
	end)
	if ok and placeId == Places.Ids.Island and type(jobId) == "string" and jobId ~= "" then
		TravelService.ToIslandServer(player, jobId, userId)
	else
		StateService.Notify(player, "They've left their island", "bad")
	end
end

local function onGo(player: Player, userId: unknown)
	if type(userId) ~= "number" then
		return
	end
	local now = os.clock()
	if now - (lastGo[player] or 0) < GO_COOLDOWN then
		return
	end
	lastGo[player] = now
	if userId == 0 or userId == player.UserId then
		goHome(player)
		return
	end
	local owner = Players:GetPlayerByUserId(userId)
	local ownerData = if owner then DataService.GetData(owner) else nil
	if not owner or not ownerData or not IslandService.GetIsland(owner) then
		followFriend(player, userId)
	elseif mayVisit(player, owner, ownerData) then
		arrive(player, owner)
	else
		StateService.Notify(player, `{owner.DisplayName}'s island isn't open to you right now`, "bad")
	end
end

-- Sends anyone who may no longer be there back to their own island
local function clearVisitors(owner: Player, ownerData: DataService.Data)
	for _, other in Players:GetPlayers() do
		if other ~= owner and hostOf(other) == owner and not mayVisit(other, owner, ownerData) then
			StateService.Notify(other, `{owner.DisplayName} closed their island, so you're back home`, "info")
			goHome(other)
		end
	end
end

local function onRule(player: Player, rule: unknown)
	local data = DataService.GetData(player)
	if not data or type(rule) ~= "string" or not RULES[rule] then
		return
	end
	data.Island.VisitRule = rule
	DataService.MarkChanged(player)
	clearVisitors(player, data)
	sendState(player)
end

local function onSign(player: Player, text: unknown)
	if type(text) ~= "string" then
		return
	end
	if not Policy.ContentSharingAllowed(player) then
		StateService.Notify(player, "Your account settings don't allow signing guestbooks", "bad")
		return
	end
	local words = string.match(string.sub(text, 1, MAX_WORDS), "^%s*(.-)%s*$") or ""
	local host = visitedBy(player)
	if not host then
		StateService.Notify(player, "Visit someone's island to sign their guestbook", "bad")
		return
	end
	local now = os.clock()
	if words == "" or now - (lastSign[player] or 0) < SIGN_COOLDOWN then
		return
	end
	lastSign[player] = now
	local checked = words
	if not RunService:IsStudio() then
		local ok, result = pcall(function()
			return TextService:FilterStringAsync(words, player.UserId):GetNonChatStringForBroadcastAsync()
		end)
		if not ok then
			lastSign[player] = nil
			StateService.Notify(player, "Couldn't check that message. Try again in a moment", "bad")
			return
		end
		checked = result
	end
	-- They could have left while the filter ran
	local hostData = DataService.GetData(host)
	if not hostData or player.Parent ~= Players then
		return
	end
	local book = hostData.Island.Guestbook
	for i = #book, 1, -1 do
		if book[i].UserId == player.UserId then
			table.remove(book, i)
		end
	end
	table.insert(book, 1, { UserId = player.UserId, Name = player.DisplayName, Text = checked, At = os.time() })
	while #book > MAX_BOOK do
		table.remove(book)
	end
	DataService.MarkChanged(host)
	Metrics.Event(player, "GuestbookSigned")
	AwardService.Give(player, "GuestbookSigned")
	StateService.Notify(host, `{player.DisplayName} signed your guestbook!`, "good")
	StateService.Notify(player, "You signed the guestbook", "good")
	sendState(player)
	sendState(host)
end

local function onAsk(player: Player)
	local now = os.clock()
	if now - (lastAsk[player] or 0) >= ASK_COOLDOWN then
		lastAsk[player] = now
		sendState(player)
	end
end

-- Came from another server to visit someone: take them to that island
local function checkArrival(player: Player)
	local join = player:GetJoinData()
	local teleportData = join and join.TeleportData
	local userId = if type(teleportData) == "table" then (teleportData :: any).Visit else nil
	if type(userId) ~= "number" then
		return
	end
	local waited = 0
	while not player.Character and player.Parent == Players and waited < ARRIVE_WAIT do
		waited += task.wait(0.25)
	end
	local owner = Players:GetPlayerByUserId(userId)
	local ownerData = if owner then DataService.GetData(owner) else nil
	if owner and ownerData and IslandService.GetIsland(owner) and mayVisit(player, owner, ownerData) then
		arrive(player, owner)
	else
		StateService.Notify(player, "That island isn't open right now, so here's yours", "info")
	end
end

function VisitService.Start()
	Remotes.VisitOpen.OnServerEvent:Connect(onAsk)
	Remotes.VisitGo.OnServerEvent:Connect(onGo)
	Remotes.VisitRule.OnServerEvent:Connect(onRule)
	Remotes.GuestbookSign.OnServerEvent:Connect(onSign)
	IslandService.OnIslandCreated(function(player)
		checkArrival(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastGo[player] = nil
		lastSign[player] = nil
		lastAsk[player] = nil
	end)
	-- Tells each screen whose island they're on, for the "Go home" bar
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 1 then
			return
		end
		elapsed = 0
		for _, player in Players:GetPlayers() do
			local host = visitedBy(player)
			player:SetAttribute("VisitingName", if host then host.DisplayName else "")
		end
	end)
end

return VisitService
