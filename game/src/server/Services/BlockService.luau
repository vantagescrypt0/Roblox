--!strict
-- Breaking and placing blocks on your own island. The client times "hold to break"
-- (Mining.luau: block toughness vs the tool you're holding); the server checks the island
-- is yours, the block is in reach, not protected, that you aren't breaking faster than
-- your tool allows, whether it drops (stone needs a pickaxe), and wears the tool down.
-- Mining a resource node (tree, boulder, ore) doesn't leave a saved hole: the node grows
-- back (IslandService), and nobody can build in its spot meanwhile.
-- Mining the island's own stone and ore trains Mining, chopping its trees trains
-- Woodcutting, and those skills give a growing chance of a double drop. Blocks you placed
-- give no XP and no bonus, so placing and re-mining can't farm XP or copy items.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Items = require(ReplicatedStorage.Shared.Items)
local Leveling = require(ReplicatedStorage.Shared.Leveling)
local Mining = require(ReplicatedStorage.Shared.Mining)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local HotbarService = require(script.Parent.HotbarService)
local InventoryService = require(script.Parent.InventoryService)
local IslandService = require(script.Parent.IslandService)
local ProgressionService = require(script.Parent.ProgressionService)
local QuestService = require(script.Parent.QuestService)
local StateService = require(script.Parent.StateService)

local PLACE_COOLDOWN = 0.12
-- Building area around the island (in blocks)
local MAX_HEIGHT, MAX_DEPTH, EXTRA_RADIUS = 40, 40, 12

-- What gathering each natural block is worth: skill XP and player XP
local GATHER: { [string]: { Skill: string, XP: number, PlayerXP: number } } = {
	Stone = { Skill = "Mining", XP = 5, PlayerXP = 2 },
	Cobblestone = { Skill = "Mining", XP = 5, PlayerXP = 2 },
	CoalOre = { Skill = "Mining", XP = 12, PlayerXP = 4 },
	IronOre = { Skill = "Mining", XP = 20, PlayerXP = 6 },
	Wood = { Skill = "Woodcutting", XP = 6, PlayerXP = 2 },
}

-- Block types some item can place (so a block of that type might be player-made)
local placeable: { [string]: boolean } = {}
for _, item in Items do
	if item.Block then
		placeable[item.Block] = true
	end
end

local BlockService = {}

local lastBreak: { [Player]: number } = {}
local lastPlace: { [Player]: number } = {}
local rng = Random.new()

-- Is this block part of the island itself: a resource node, or an ore vein (a block type
-- no item can place, still as the island was made)?
local function isNatural(island: IslandService.Island, isNode: boolean, cellKey: string, blockType: string): boolean
	return isNode or (not placeable[blockType] and island.Base[cellKey] == blockType)
end

local function isCell(x: unknown, y: unknown, z: unknown): boolean
	for _, value in { x, y, z } do
		if type(value) ~= "number" or value ~= math.floor(value) or math.abs(value) > 500 then
			return false
		end
	end
	return true
end

local function inReach(player: Player, world: BlockWorld.World, x: number, y: number, z: number): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	return (root.Position - BlockWorld.position(world, x, y, z)).Magnitude <= Blocks.Reach + 3
end

local function onBreak(player: Player, x: unknown, y: unknown, z: unknown)
	if not isCell(x, y, z) then
		return
	end
	local cx, cy, cz = x :: number, y :: number, z :: number
	local island = IslandService.GetIsland(player)
	if not island then
		return
	end
	local world = island.World
	local blockType = BlockWorld.get(world, cx, cy, cz)
	local def = blockType and Blocks.Types[blockType]
	if not blockType or not def or not def.Breakable or world.Protected[BlockWorld.key(cx, cy, cz)] then
		return
	end
	if not inReach(player, world, cx, cy, cz) then
		return
	end
	-- How long this block takes with what they're holding (toughness vs tool power)
	local held = HotbarService.GetHeldItem(player)
	local breakTime, canHarvest = Mining.BreakTime(blockType, held)
	local now = os.clock()
	if now - (lastBreak[player] or 0) < breakTime * 0.6 then
		return
	end
	lastBreak[player] = now

	local isNode = IslandService.GetNode(player, cx, cy, cz) ~= nil
	local natural = isNatural(island, isNode, BlockWorld.key(cx, cy, cz), blockType)
	BlockWorld.set(world, cx, cy, cz, nil)
	if isNode then
		IslandService.DepleteNode(player, cx, cy, cz)
	else
		IslandService.RecordChange(player, cx, cy, cz, nil)
	end

	local gather = if natural and canHarvest then GATHER[blockType] else nil
	if def.Drop and canHarvest then
		local amount = 1
		if gather then
			local level = ProgressionService.GetSkillLevel(player, gather.Skill)
			if rng:NextNumber() < Leveling.BonusChance(level) then
				amount = 2
				StateService.Notify(player, `Double drop! +2 {Items[def.Drop].Name}`, "good")
			end
		end
		InventoryService.Add(player, def.Drop, amount)
	elseif not canHarvest then
		StateService.Notify(player, `You need a {def.Tool or "tool"} to collect {def.Name}`, "bad")
	end
	if held and Mining.UsesTool(blockType, held) and InventoryService.UseTool(player, held, 1) then
		StateService.Notify(player, `Your {Items[held].Name} broke!`, "bad")
	end
	if gather then
		ProgressionService.AddSkillXP(player, gather.Skill, gather.XP)
		ProgressionService.AddPlayerXP(player, gather.PlayerXP)
	end
	if canHarvest and blockType == "Wood" then
		QuestService.Record(player, "Chop")
	elseif canHarvest and (blockType == "Stone" or blockType == "Cobblestone") then
		QuestService.Record(player, "Mine")
	elseif canHarvest and (blockType == "CoalOre" or blockType == "IronOre") then
		QuestService.Record(player, "Mine")
		QuestService.Record(player, `Mine:{blockType}`)
	end
end

-- Is someone standing where the block would go?
local function blockedByCharacter(position: Vector3): boolean
	local size = Vector3.one * (Blocks.Size - 0.3)
	for _, part in workspace:GetPartBoundsInBox(CFrame.new(position), size) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and model:FindFirstChildOfClass("Humanoid") then
			return true
		end
	end
	return false
end

local function onPlace(player: Player, x: unknown, y: unknown, z: unknown, itemId: unknown)
	if not isCell(x, y, z) or type(itemId) ~= "string" then
		return
	end
	local cx, cy, cz = x :: number, y :: number, z :: number
	local item = Items[itemId]
	local island = IslandService.GetIsland(player)
	if not item or not item.Block or not island then
		return
	end
	local world = island.World
	local cellKey = BlockWorld.key(cx, cy, cz)
	if world.Cells[cellKey] or world.Protected[cellKey] or IslandService.GetNode(player, cx, cy, cz) then
		return
	end
	local limit = 13 + EXTRA_RADIUS
	if math.abs(cx) > limit or math.abs(cz) > limit or cy > MAX_HEIGHT or cy < -MAX_DEPTH then
		return
	end
	if not BlockWorld.hasNeighbour(world, cx, cy, cz) or not inReach(player, world, cx, cy, cz) then
		return
	end
	local now = os.clock()
	if now - (lastPlace[player] or 0) < PLACE_COOLDOWN then
		return
	end
	if blockedByCharacter(BlockWorld.position(world, cx, cy, cz)) then
		return
	end
	if not InventoryService.Remove(player, itemId, 1) then
		return
	end
	lastPlace[player] = now

	BlockWorld.set(world, cx, cy, cz, item.Block)
	IslandService.RecordChange(player, cx, cy, cz, item.Block)
	QuestService.Record(player, "Place")
end

function BlockService.Start()
	Remotes.BreakBlock.OnServerEvent:Connect(onBreak)
	Remotes.PlaceBlock.OnServerEvent:Connect(onPlace)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastBreak[player] = nil
		lastPlace[player] = nil
	end)
end

return BlockService
