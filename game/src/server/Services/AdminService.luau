--!strict
-- Admin tools (your calls, 2026-11-10): a panel only Config.Admins can open (F2; client/Windows/AdminWindow) and the
-- chat commands /kick, /ban, /unban and /flags. In Studio anyone is an admin, to test them. Every request is checked
-- here: from anyone else it does nothing. Everything acts on this server only, except bans, which Roblox applies to
-- the whole game.
--   Players   who's here, with their anti-cheat record (AntiCheatService); kick, ban (for some days or for good), unban
--   Give/set  items, coins (given or taken), player level and skill levels. In the live game these are real saves.
--   Move      go to someone, bring them to you, or watch them (spectate)
--   Server    an announcement to everyone here, or shut this server down (everyone's saved as they leave)
-- Answers go to the admin's chat and the panel's status line (AdminReply). Each action is also written to the log.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local TextService = game:GetService("TextService")

local Config = require(ReplicatedStorage.Shared.Config)
local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Skills = require(ReplicatedStorage.Shared.Skills)
local Move = require(script.Parent.Parent.Util.Move)
local AntiCheatService = require(script.Parent.AntiCheatService)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)

local AdminService = {}

local MAX_LEVEL = 50 -- player level (Skills.luau)
local MAX_SKILL = 99
local MAX_GIVE = 9999 -- items at once
local MAX_COINS = 100000000
local MAX_TEXT = 200 -- characters in a reason or an announcement
local NEAR = 4 -- studs from someone you go to or bring
local SHUTDOWN = "Skycore is restarting for an update. Rejoin in a moment!"

export type Row = {
	UserId: number,
	Name: string,
	DisplayName: string,
	Level: number,
	Coins: number,
	Strikes: number,
	Catches: number,
	Kicks: number,
	Last: string,
	LastAt: number,
}

local shuttingDown = false
local watching: { [Player]: Player } = {} -- admin -> who they're spectating

local function isAdmin(player: Player): boolean
	return Config.Admins[player.UserId] == true or RunService:IsStudio()
end

local function reply(admin: Player, text: string)
	Remotes.AdminReply:FireClient(admin, text)
end

local function count(n: number, one: string, many: string): string
	return `{n} {if n == 1 then one else many}`
end

local function ago(seconds: number): string
	if seconds < 120 then
		return `{seconds}s ago`
	elseif seconds < 7200 then
		return `{seconds // 60} min ago`
	elseif seconds < 172800 then
		return `{seconds // 3600} h ago`
	end
	return `{seconds // 86400} days ago`
end

-- Text someone typed, made safe to show other players. Nil if Roblox's filter can't be reached.
local function filtered(text: string, from: Player): string?
	local ok, result = pcall(function()
		return TextService:FilterStringAsync(text, from.UserId):GetNonChatStringForBroadcastAsync()
	end)
	return if ok and type(result) == "string" then result else nil
end

local function asText(value: unknown): string
	return if type(value) == "string" then string.sub(value, 1, MAX_TEXT) else ""
end

local function asWhole(value: unknown): number?
	local number = if type(value) == "number" then value elseif type(value) == "string" then tonumber(value) else nil
	if not number or number ~= number or math.abs(number) == math.huge then
		return nil
	end
	return math.floor(number)
end

-- Someone in this server, by name or display name, whole or the start of it
local function findPlayer(text: string): Player?
	local wanted = string.lower(text)
	local partly: Player? = nil
	for _, player in Players:GetPlayers() do
		local name, shown = string.lower(player.Name), string.lower(player.DisplayName)
		if name == wanted or shown == wanted then
			return player
		end
		if not partly and (string.sub(name, 1, #wanted) == wanted or string.sub(shown, 1, #wanted) == wanted) then
			partly = player
		end
	end
	return partly
end

-- Anyone at all: someone here, a user id, or a username
local function userIdOf(text: string): (number?, string)
	local here = findPlayer(text)
	if here then
		return here.UserId, here.Name
	end
	local number = tonumber(text)
	if number then
		return number, text
	end
	local ok, id = pcall(Players.GetUserIdFromNameAsync, Players, text)
	if ok and type(id) == "number" then
		return id, text
	end
	return nil, text
end

local function playerFrom(value: unknown): Player?
	return if type(value) == "number" then Players:GetPlayerByUserId(value) else nil
end

local function rootOf(player: Player): BasePart?
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- One player's anti-cheat record, as a line
local function flagLine(player: Player): string?
	local data = DataService.GetData(player)
	local strikes = AntiCheatService.Strikes(player)
	local catches = if data then data.AntiCheat.Flags else 0
	if catches == 0 and strikes < 0.05 then
		return nil
	end
	local line = `{player.Name}: {math.floor(strikes * 10) / 10} strikes now, {count(catches, "catch", "catches")} ever`
	if data then
		line ..= `, {count(data.AntiCheat.Kicks, "kick", "kicks")}`
		if data.AntiCheat.Last ~= "" then
			line ..= `, last: {data.AntiCheat.Last} ({ago(os.time() - data.AntiCheat.LastAt)})`
		end
	end
	return line
end

-- What admins can do ---------------------------------------------------------------------------------------------

local function kick(admin: Player, target: Player, reason: string): string
	local said = if reason ~= "" then filtered(reason, admin) else nil
	target:Kick(if said then `An admin removed you: {said}` else "An admin removed you from this server.")
	return `Kicked {target.Name}.`
end

local function ban(admin: Player, userId: number, name: string, days: number?, reason: string): string
	local said = if reason ~= "" then filtered(reason, admin) else nil
	Players:BanAsync({
		UserIds = { userId },
		ApplyToUniverse = true,
		Duration = if days and days > 0 then days * 86400 else -1,
		DisplayReason = said or "Breaking Skycore's rules",
		PrivateReason = `Banned by {admin.Name} ({admin.UserId})`,
		ExcludeAltAccounts = false,
	})
	return `Banned {name} ({userId}) {if days and days > 0 then `for {count(days, "day", "days")}` else "for good"}.`
end

local function unban(userId: number, name: string): string
	Players:UnbanAsync({ UserIds = { userId }, ApplyToUniverse = true })
	return `Unbanned {name} ({userId}).`
end

local function stopWatching(admin: Player)
	watching[admin] = nil
	admin.ReplicationFocus = nil
end

local function rows(): { Row }
	local list: { Row } = {}
	for _, player in Players:GetPlayers() do
		local data = DataService.GetData(player)
		table.insert(list, {
			UserId = player.UserId,
			Name = player.Name,
			DisplayName = player.DisplayName,
			Level = if data then data.Level else 0,
			Coins = if data then data.Coins else 0,
			Strikes = math.floor(AntiCheatService.Strikes(player) * 10) / 10,
			Catches = if data then data.AntiCheat.Flags else 0,
			Kicks = if data then data.AntiCheat.Kicks else 0,
			Last = if data then data.AntiCheat.Last else "",
			LastAt = if data then data.AntiCheat.LastAt else 0,
		})
	end
	table.sort(list, function(a, b)
		return string.lower(a.Name) < string.lower(b.Name)
	end)
	return list
end

-- Panel actions: each gets the admin and what the panel sent, and answers with a line (or nil for no answer)
local ACTIONS: { [string]: (admin: Player, ...unknown) -> string? } = {
	List = function(admin)
		local target = watching[admin]
		Remotes.AdminState:FireClient(admin, rows(), if target then target.UserId else 0)
		return nil
	end,

	Kick = function(admin, who, reason)
		local target = playerFrom(who)
		if not target then
			return "They've left the server."
		end
		return kick(admin, target, asText(reason))
	end,
	Ban = function(admin, who, days, reason)
		local userId = asWhole(who)
		if not userId then
			return "Pick someone to ban."
		end
		local here = Players:GetPlayerByUserId(userId)
		return ban(admin, userId, if here then here.Name else tostring(userId), asWhole(days), asText(reason))
	end,
	Unban = function(_admin, who)
		local text = asText(who)
		if text == "" then
			return "Type a username or user id to unban."
		end
		local userId, name = userIdOf(text)
		if not userId then
			return `No player called {text}.`
		end
		return unban(userId, name)
	end,

	Give = function(_admin, who, itemId, amount)
		local target = playerFrom(who)
		local item = if type(itemId) == "string" then Items[itemId] else nil
		local n = asWhole(amount)
		if not target then
			return "They've left the server."
		elseif not item then
			return "Pick an item first."
		elseif not n or n < 1 then
			return "Type how many to give."
		end
		n = math.min(n, MAX_GIVE)
		InventoryService.Add(target, itemId :: string, n)
		return `Gave {target.Name} {n} {item.Name}.`
	end,
	Coins = function(_admin, who, amount)
		local target = playerFrom(who)
		local data = target and DataService.GetData(target)
		local n = asWhole(amount)
		if not target or not data then
			return "They've left the server."
		elseif not n or n == 0 then
			return "Type how many coins: a minus takes them away."
		end
		n = math.clamp(n, -MAX_COINS, MAX_COINS)
		if n > 0 then
			InventoryService.AddCoins(target, n)
			return `Gave {target.Name} {n} coins.`
		end
		local taken = math.min(-n, data.Coins)
		if taken > 0 then
			InventoryService.SpendCoins(target, taken)
		end
		return `Took {taken} coins from {target.Name}.`
	end,
	Level = function(_admin, who, level)
		local target = playerFrom(who)
		local data = target and DataService.GetData(target)
		local n = asWhole(level)
		if not target or not data then
			return "They've left the server."
		elseif not n then
			return "Type a level."
		end
		n = math.clamp(n, 1, MAX_LEVEL)
		data.Level = n
		data.XP = 0
		DataService.MarkChanged(target)
		return `{target.Name} is now level {n}.`
	end,
	Skill = function(_admin, who, skillId, level)
		local target = playerFrom(who)
		local data = target and DataService.GetData(target)
		local skill = if type(skillId) == "string" then Skills.ById[skillId] else nil
		local entry = if data and skill then (data.Skills :: any)[skill.Id] else nil
		local n = asWhole(level)
		if not target or not data then
			return "They've left the server."
		elseif not skill or not entry then
			return "Pick a skill first."
		elseif not n then
			return "Type a level."
		end
		n = math.clamp(n, 1, MAX_SKILL)
		entry.Level = n
		entry.XP = 0
		DataService.MarkChanged(target)
		return `{target.Name}'s {skill.Name} is now {n}.`
	end,

	GoTo = function(admin, who)
		local target = playerFrom(who)
		local to = target and rootOf(target)
		if not target or not to or not admin.Character then
			return "They're not in the world right now."
		end
		pcall(admin.RequestStreamAroundAsync, admin, to.Position)
		stopWatching(admin)
		Move.To(admin.Character, to.CFrame * CFrame.new(0, 0, NEAR))
		return `Went to {target.Name}.`
	end,
	Bring = function(admin, who)
		local target = playerFrom(who)
		local here = rootOf(admin)
		if not target or not target.Character or not here then
			return "They're not in the world right now."
		end
		pcall(target.RequestStreamAroundAsync, target, here.Position)
		Move.To(target.Character, here.CFrame * CFrame.new(0, 0, -NEAR) * CFrame.Angles(0, math.pi, 0))
		return `Brought {target.Name} to you.`
	end,
	-- Watch someone: their surroundings load for you, and your camera follows them (the panel does the camera)
	Spectate = function(admin, who)
		local target = playerFrom(who)
		local root = target and rootOf(target)
		if not target or target == admin or not root then
			stopWatching(admin)
			return nil
		end
		watching[admin] = target
		admin.ReplicationFocus = root
		return `Watching {target.Name}. Press Stop watching in the panel to come back.`
	end,

	Announce = function(admin, text)
		local words = asText(text)
		if words == "" then
			return "Type something to announce."
		end
		local said = filtered(words, admin)
		if not said then
			return "Roblox's text filter didn't answer, so nothing was sent. Try again."
		end
		Remotes.Announce:FireAllClients(said)
		return `Announced to {count(#Players:GetPlayers(), "player", "players")}.`
	end,
	Shutdown = function()
		shuttingDown = true
		for _, player in Players:GetPlayers() do
			player:Kick(SHUTDOWN)
		end
		return nil
	end,
}

-- Chat commands: /kick, /ban, /unban, /flags (answers in the admin's chat; hidden from everyone's command list)
local COMMANDS: { [string]: (admin: Player, words: { string }) -> string } = {
	kick = function(admin, words)
		local target = words[1] and findPlayer(words[1])
		if not target then
			return "Usage: /kick <player> [reason]. Nobody here by that name."
		end
		return kick(admin, target, table.concat(words, " ", 2))
	end,
	ban = function(admin, words)
		if not words[1] then
			return "Usage: /ban <player> [days] [reason]. No days means for good."
		end
		local userId, name = userIdOf(words[1])
		if not userId then
			return `No player called {words[1]}.`
		end
		local days = tonumber(words[2])
		return ban(
			admin,
			userId,
			name,
			if days then math.floor(days) else nil,
			table.concat(words, " ", if days then 3 else 2)
		)
	end,
	unban = function(_admin, words)
		if not words[1] then
			return "Usage: /unban <player or user id>"
		end
		local userId, name = userIdOf(words[1])
		if not userId then
			return `No player called {words[1]}.`
		end
		return unban(userId, name)
	end,
	flags = function(_admin, words)
		if words[1] then
			local target = findPlayer(words[1])
			if not target then
				return `Nobody here called {words[1]}.`
			end
			return flagLine(target) or `{target.Name} has never been caught.`
		end
		local lines = {}
		for _, player in Players:GetPlayers() do
			local line = flagLine(player)
			if line then
				table.insert(lines, line)
			end
		end
		return if #lines > 0 then table.concat(lines, "\n") else "Nobody in this server has been caught."
	end,
}

local function addCommands()
	local holder = TextChatService:FindFirstChild("TextChatCommands") or TextChatService
	for name, run in COMMANDS do
		local command = Instance.new("TextChatCommand")
		command.Name = `Admin{name}`
		command.PrimaryAlias = `/{name}`
		pcall(function()
			-- Not offered to everyone in the chat's command list
			(command :: any).AutocompleteVisible = false
		end)
		command.Triggered:Connect(function(source: TextSource, text: string)
			local admin = Players:GetPlayerByUserId(source.UserId)
			if not admin or not isAdmin(admin) then
				return
			end
			local words = {}
			for word in string.gmatch(text, "%S+") do
				table.insert(words, word)
			end
			table.remove(words, 1)
			warn(`[Admin] {admin.Name}: {text}`)
			local ok, answer = pcall(run, admin, words)
			reply(admin, if ok then answer else `That didn't work: {answer}`)
		end)
		command.Parent = holder
	end
end

function AdminService.Start()
	Remotes.AdminAction.OnServerEvent:Connect(function(admin: Player, action: unknown, ...: unknown)
		if not isAdmin(admin) or type(action) ~= "string" then
			return
		end
		local run = ACTIONS[action]
		if not run then
			return
		end
		if action ~= "List" then
			local shown = {}
			for _, value in { ... } do
				table.insert(shown, tostring(value))
			end
			warn(`[Admin] {admin.Name}: {action} {table.concat(shown, " ")}`)
		end
		local ok, answer = pcall(run, admin, ...)
		if not ok then
			reply(admin, `That didn't work: {answer}`)
		elseif answer then
			reply(admin, answer)
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		if shuttingDown then
			player:Kick(SHUTDOWN)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		watching[player] = nil
		for admin, target in watching do
			if target == player then
				stopWatching(admin)
			end
		end
	end)

	addCommands()
end

return AdminService
