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
--   game.ServerStorage.Dev:Invoke("Fill", Vector3.new(2, -3, 2), Vector3.new(4, -1, 4), "Water")
--                                                           fill a box of island cells (or "Air")
--   game.ServerStorage.Dev:Invoke("Hunger", 20)             set your hunger (Warzone)
--   game.ServerStorage.Dev:Invoke("TestQuit", 8)            quit the Warzone and rejoin it 8 s later (Warzone)
--   game.ServerStorage.Dev:Invoke("Kill")                   die on the spot; your body drops (Warzone)
--   game.ServerStorage.Dev:Invoke("Tag")                    tag yourself for a fight (Warzone)
--   game.ServerStorage.Dev:Invoke("QuitTime", 3, 1)         quitters have 3 s, plus 1 s of grace (Warzone)
--   game.ServerStorage.Dev:Invoke("BodyTime", 20)           bodies last 20 s (Warzone)
--   game.ServerStorage.Dev:Invoke("TestBlock", position)    would your shield stop a hit from
--                                                           there? Prints the answer (Warzone)
--   game.ServerStorage.Dev:Invoke("Board", "Warzone")       where you are on a Challenges board. Add a
--                                                           challenge's Id to jump to it
--   game.ServerStorage.Dev:Invoke("Skydrop")                a regular Skydrop falls now (Warzone)
--   game.ServerStorage.Dev:Invoke("Legendary", 5)           a Legendary falls now, with 5 cracks left in its
--                                                           bar; leave the number off for the full bar (Warzone)
--   game.ServerStorage.Dev:Invoke("Dummy")                  a dummy to hit, just in front of you; hits
--                                                           on it print what they did
--   game.ServerStorage.Dev:Invoke("Kit", true, true, false, 0)  kits and crates as if on sale, owned, not
--                                                           restricted, last claimed 0 s ago (add a kit's Id)
--   game.ServerStorage.Dev:Invoke("KitReceipt", "abc")      Roblox telling us crate purchase "abc" was paid for
--   game.ServerStorage.Dev:Invoke("As", "Player2")          later commands act on Player2
-- Acts on the first player in the server unless "As" picked another (for local tests with
-- several players). Does nothing in live servers.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Boards = require(ReplicatedStorage.Shared.Boards)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local BodyService = require(script.Parent.BodyService)
local ChallengeService = require(script.Parent.ChallengeService)
local DataService = require(script.Parent.DataService)
local InboxService = require(script.Parent.InboxService)
local InventoryService = require(script.Parent.InventoryService)
local IslandService = require(script.Parent.IslandService)
local KitService = require(script.Parent.KitService)
local SkydropService = require(script.Parent.SkydropService)
local WarzoneService = require(script.Parent.WarzoneService)

local DevService = {}

local commands: { [string]: (player: Player, data: DataService.Data, ...any) -> ...any } = {
	Kit = function(_player, data, onSale, owned, restricted, claimedAgo, kitId)
		data.KitClaims[kitId or "CrateKeeper"] = if claimedAgo then os.time() - claimedAgo else nil
		KitService.SetTest({ OnSale = onSale == true, Owned = owned == true, Restricted = restricted == true })
	end,
	KitReceipt = function(player, _data, purchaseId)
		return tostring(KitService.TestReceipt(player, purchaseId))
	end,
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
	Hunger = function(player, _data, amount)
		WarzoneService.SetHunger(player, amount)
	end,
	TestQuit = function(player, _data, away)
		WarzoneService.TestQuit(player, away)
	end,
	-- What you have, as text
	Carried = function(_player, data)
		local slots = {}
		for index, stack in data.Slots do
			if stack.Count > 0 then
				table.insert(slots, `{index}:{stack.Item}x{stack.Count}`)
			end
		end
		local totals = {}
		for itemId, total in data.Items do
			table.insert(totals, `{itemId}x{total}`)
		end
		table.sort(totals)
		local worn = {}
		for slot, itemId in data.Equipped :: { [string]: string } do
			if itemId ~= "" then
				table.insert(worn, `{slot}={itemId}`)
			end
		end
		return `slots[{table.concat(slots, " ")}] totals[{table.concat(totals, " ")}] worn[{table.concat(worn, " ")}]`
			.. ` rejoin={data.Rejoin.Until} body={data.Body.Until} mail={#data.Inbox.Mail} coins={data.Coins}`
	end,
	-- Die on the spot (Warzone: your body drops)
	Kill = function(player)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end,
	-- Tag yourself, as if a fight had just started (Warzone)
	Tag = function(player)
		WarzoneService.Tag(player)
	end,
	-- How long a quitter has to come back and how long a body lasts, in seconds, for testing
	QuitTime = function(_player, _data, seconds, grace)
		WarzoneService.SetRejoinTime(seconds, grace or 0)
	end,
	BodyTime = function(_player, _data, seconds)
		BodyService.SetLifetime(seconds)
	end,
	TestBlock = function(player, _data, from)
		print("[Dev] blocked:", WarzoneService.Blocks(player, from))
	end,
	-- Where you are on a Challenges board, and if you name a challenge, jump to it
	Board = function(_player, data, boardId, jumpTo)
		local board = Boards.ById[boardId]
		local entry = data.Boards[boardId]
		if not entry then
			entry = { Done = {}, Current = "", Progress = 0 }
			data.Boards[boardId] = entry
		end
		if jumpTo then
			entry.Done = {}
			entry.Progress = 0
			for _, challenge in board.Challenges do
				if challenge.Id == jumpTo then
					break
				end
				entry.Done[challenge.Id :: string] = true
			end
		end
		local current = board.Challenges[Boards.CurrentIndex(board, entry.Done)]
		return if current then `{current.Id}: {entry.Progress} of {current.Target}` else "all done"
	end,
	Skydrop = function()
		return if SkydropService.Drop("Skydrop") then "falling" else "didn't drop"
	end,
	Legendary = function(_player, _data, cracks)
		return if SkydropService.Drop("Legendary", cracks) then "falling" else "didn't drop"
	end,
	-- Print your last trades to the Output
	Trades = function(_player, data)
		for _, trade in data.Trades do
			print(trade.At, trade.WithName, "gave", trade.Gave, "got", trade.Got)
		end
	end,
	-- Something to practise on: CombatService treats it like a player with no armour
	Dummy = function(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local dummy = Players:CreateHumanoidModelFromDescription(
				Instance.new("HumanoidDescription"),
				Enum.HumanoidRigType.R15
			)
			dummy.Name = "Dummy"
			dummy:SetAttribute("Dummy", true)
			dummy:PivotTo(root.CFrame * CFrame.new(0, 0, -6) * CFrame.Angles(0, math.pi, 0))
			dummy.Parent = workspace
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
	-- Fill a box of cells on your island with a block (saved like placed blocks), or with
	-- nothing for "Air", e.g. ("Fill", Vector3.new(2, -3, 2), Vector3.new(4, -1, 4), "Air")
	Fill = function(player, _data, from, to, blockType)
		local island = IslandService.GetIsland(player)
		if not island then
			return
		end
		local block = if blockType == "Air" then nil else blockType
		local low, high = (from :: Vector3):Min(to), (from :: Vector3):Max(to)
		for x = low.X, high.X do
			for y = low.Y, high.Y do
				for z = low.Z, high.Z do
					BlockWorld.set(island.World, x, y, z, block)
					IslandService.RecordChange(player, x, y, z, block)
				end
			end
		end
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
		return run(player, data, ...) or "ok"
	end
	bindable.Parent = ServerStorage
end

return DevService
