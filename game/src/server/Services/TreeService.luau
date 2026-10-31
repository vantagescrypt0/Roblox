--!strict
-- Planting trees on your island. Leaves sometimes drop a Sapling, felling a tree always
-- gives at least one (BlockService), and the Lumberjack in Town sells them. Hold one and
-- right-click (or tap) grass or dirt with room above it to plant it. It grows into a tree
-- after a few minutes (IslandService); chop it down for its wood and it's gone, so plant
-- the saplings it gives you. How many planted trees you can have at once grows with
-- Woodcutting (Leveling.PlantedTrees). Click a growing sapling to dig it up and get it back.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Leveling = require(ReplicatedStorage.Shared.Leveling)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local HotbarService = require(script.Parent.HotbarService)
local InventoryService = require(script.Parent.InventoryService)
local IslandService = require(script.Parent.IslandService)
local ProgressionService = require(script.Parent.ProgressionService)
local QuestService = require(script.Parent.QuestService)
local StateService = require(script.Parent.StateService)

local COOLDOWN = 0.25

local TreeService = {}

local lastUse: { [Player]: number } = {}

-- A clicked cell on the player's own island, in reach and not clicked too often
local function checkCell(player: Player, x: unknown, y: unknown, z: unknown): (boolean, number, number, number)
	if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
		return false, 0, 0, 0
	end
	if x ~= math.floor(x) or y ~= math.floor(y) or z ~= math.floor(z) then
		return false, 0, 0, 0
	end
	local now = os.clock()
	if now - (lastUse[player] or 0) < COOLDOWN then
		return false, 0, 0, 0
	end
	lastUse[player] = now
	local island = IslandService.GetIsland(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not island or not root or not root:IsA("BasePart") then
		return false, 0, 0, 0
	end
	if (root.Position - BlockWorld.position(island.World, x, y, z)).Magnitude > Blocks.Reach + 3 then
		return false, 0, 0, 0
	end
	return true, x, y, z
end

local function onPlant(player: Player, x: unknown, y: unknown, z: unknown)
	local ok, cx, cy, cz = checkCell(player, x, y, z)
	if not ok or HotbarService.GetHeldItem(player) ~= "Sapling" then
		return
	end
	local level = ProgressionService.GetSkillLevel(player, "Woodcutting")
	local limit = Leveling.PlantedTrees(level)
	if IslandService.PlantedCount(player) >= limit then
		StateService.Notify(
			player,
			`Woodcutting level {level} lets you have {limit} planted trees at once. Fell one, or level up for more!`,
			"bad"
		)
		return
	end
	local planted, reason = IslandService.PlantSapling(player, cx, cy, cz)
	if not planted then
		if reason then
			StateService.Notify(player, reason, "bad")
		end
		return
	end
	InventoryService.Remove(player, "Sapling", 1)
	StateService.Notify(player, "Planted! It grows into a tree in a few minutes", "good")
	QuestService.Record(player, "PlantSapling")
end

local function onUproot(player: Player, x: unknown, y: unknown, z: unknown)
	local ok, cx, cy, cz = checkCell(player, x, y, z)
	if ok and IslandService.Uproot(player, cx, cy, cz) then
		InventoryService.Add(player, "Sapling", 1)
		StateService.Notify(player, "Dug it up. You got the sapling back", "info")
	end
end

function TreeService.Start()
	Remotes.PlantSapling.OnServerEvent:Connect(onPlant)
	Remotes.Uproot.OnServerEvent:Connect(onUproot)
	Players.PlayerRemoving:Connect(function(player)
		lastUse[player] = nil
	end)
end

return TreeService
