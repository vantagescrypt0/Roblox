--!strict
-- Studio-only test helpers, used from the Studio command bar (Server view):
--   game.ServerStorage.Dev:Invoke("Level", 10)              set player level
--   game.ServerStorage.Dev:Invoke("Skill", "Combat", 5)     set a skill level
--   game.ServerStorage.Dev:Invoke("Give", "Wood", 20)       give items
--   game.ServerStorage.Dev:Invoke("Coins", 500)             give coins
--   game.ServerStorage.Dev:Invoke("Use", "IronPickaxe", 100) wear a tool down
--   game.ServerStorage.Dev:Invoke("Trades")                 print your last trades
--   game.ServerStorage.Dev:Invoke("Mail", { From = "Builder", Text = "Hi", Items = { Stone = 8 }, Coins = 50 })
--                                                           send yourself a letter (Inbox)
--   game.ServerStorage.Dev:Invoke("MailByMessage", { ... })  the same, the way it reaches
--                                                           a player on another server
--   game.ServerStorage.Dev:Invoke("Count", "Wheat", 500)    count gathered resources (skill challenges)
--   game.ServerStorage.Dev:Invoke("Season")                 act as if your season just ended
--                                                           (SeasonService resets you within a second)
--   game.ServerStorage.Dev:Invoke("Season", "Kick")         the same, but kicked at once, so you're
--                                                           reset as your save loads when you rejoin
--   game.ServerStorage.Dev:Invoke("As", "Player2")          later commands act on Player2
-- Acts on the first player in the server unless "As" picked another (for local tests with
-- several players). Does nothing in live servers.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local ChallengeService = require(script.Parent.ChallengeService)
local DataService = require(script.Parent.DataService)
local InboxService = require(script.Parent.InboxService)
local InventoryService = require(script.Parent.InventoryService)

local DevService = {}

local commands: { [string]: (player: Player, data: DataService.Data, ...any) -> () } = {
	Level = function(player, data, level)
		data.Level = level
		data.XP = 0
		DataService.MarkChanged(player)
	end,
	Skill = function(player, data, skill, level)
		local entry = (data.Skills :: any)[skill]
		if entry then
			entry.Level = level
			entry.XP = 0
			DataService.MarkChanged(player)
		end
	end,
	Give = function(player, _data, item, amount)
		InventoryService.Add(player, item, amount)
	end,
	Coins = function(player, _data, amount)
		InventoryService.AddCoins(player, amount)
	end,
	-- Wear a tool down, e.g. ("Use", "IronPickaxe", 100)
	Use = function(player, _data, item, uses)
		InventoryService.UseTool(player, item, uses)
	end,
	-- Print your last trades to the Output
	Trades = function(_player, data)
		for _, trade in data.Trades do
			print(trade.At, trade.WithName, "gave", trade.Gave, "got", trade.Got)
		end
	end,
	-- Send yourself a letter
	Mail = function(player, _data, mail)
		print("[Dev] mail sent:", InboxService.Send(player.UserId, mail))
	end,
	-- Count resources as gathered, e.g. ("Count", "Wheat", 500) reaches Wheat's pet milestone
	Count = function(player, _data, resourceId, amount)
		ChallengeService.Count(player, resourceId, amount)
	end,
	-- Put your save back a season, as if the season ended while you're here (or, with
	-- "Kick", while you were away)
	Season = function(player, data, kick)
		data.Season -= 1
		if kick == "Kick" then
			player:Kick("Season test: rejoin")
		end
	end,
	-- Send it through your save's messages, as if you were on another server
	MailByMessage = function(player, _data, mail)
		print("[Dev] message sent:", DataService.SendMessage(player.UserId, { Kind = "Mail", Mail = mail }))
	end,
}

function DevService.Start()
	if not RunService:IsStudio() then
		return
	end
	local bindable = Instance.new("BindableFunction")
	bindable.Name = "Dev"
	local target: string? = nil
	bindable.OnInvoke = function(command: string, ...: any)
		if command == "As" then
			target = ...
			return "ok"
		end
		local player = if target then Players:FindFirstChild(target) :: Player? else Players:GetPlayers()[1]
		local data = player and DataService.GetData(player)
		local run = commands[command]
		if not player or not data or not run then
			return "no player or unknown command"
		end
		run(player, data, ...)
		return "ok"
	end
	bindable.Parent = ServerStorage
end

return DevService
