--!strict
-- Studio-only test helpers, used from the Studio command bar (Server view):
--   game.ServerStorage.Dev:Invoke("Level", 10)              set player level
--   game.ServerStorage.Dev:Invoke("Skill", "Combat", 5)     set a skill level
--   game.ServerStorage.Dev:Invoke("Give", "Wood", 20)       give items
-- Acts on the first player in the server. Does nothing in live servers.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local DataService = require(script.Parent.DataService)
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
}

function DevService.Start()
	if not RunService:IsStudio() then
		return
	end
	local bindable = Instance.new("BindableFunction")
	bindable.Name = "Dev"
	bindable.OnInvoke = function(command: string, ...: any)
		local player = Players:GetPlayers()[1]
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
