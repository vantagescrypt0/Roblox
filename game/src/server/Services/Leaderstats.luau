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

local function onChanged(player: Player, data: DataService.Data)
	local folder = player:FindFirstChild("leaderstats")
	if not folder then
		return
	end
	local level = folder:FindFirstChild("Level")
	local coins = folder:FindFirstChild("Coins")
	if level and level:IsA("IntValue") then
		level.Value = data.Level
	end
	if coins and coins:IsA("IntValue") then
		coins.Value = data.Coins
	end
end

function Leaderstats.Start()
	DataService.OnDataLoaded(onDataLoaded)
	DataService.OnChanged(onChanged)
end

return Leaderstats
