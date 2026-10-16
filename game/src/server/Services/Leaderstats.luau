--!strict
-- Shows Level and Coins on the player list.

local DataService = require(script.Parent.DataService)

local Leaderstats = {}

local function onDataLoaded(player: Player, data: DataService.Data)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"

	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = data.Level
	level.Parent = folder

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = data.Coins
	coins.Parent = folder

	folder.Parent = player
end

function Leaderstats.Start()
	DataService.OnDataLoaded(onDataLoaded)
end

return Leaderstats
