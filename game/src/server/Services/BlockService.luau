--!strict
-- Breaking and placing blocks. On island servers that's your own island; in a resource
-- world it's the shared world (WorldService hands BlockService an Area for it, and
-- nobody can build there). The client times "hold to break" (Mining.luau: block
-- toughness vs the tool you're holding); the server checks the block is in reach, not
-- protected, that you aren't breaking faster than your tool allows, whether it drops
-- (stone needs a pickaxe), and wears the tool down.
-- Mining a resource node (a boulder or ore on your island, anything in a world) doesn't
-- leave a saved hole: the node grows back, and nobody can build in its spot meanwhile.
-- Chopping the last log of one of your island's trees fells it (IslandService): its
-- leaves fall and you get saplings for them, always at least one.
-- Mining natural stone and ore trains Mining, chopping natural trees trains Woodcutting,
-- and those skills give a growing chance of a double drop. Blocks you placed give no XP
-- and no bonus, so placing and re-mining can't farm XP or copy items.

local Players = game:GetService("Players")
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
-- Chance that a natural leaf block drops a sapling (TreeService plants it); a felled
-- tree's falling leaves roll it too
local SAPLING_CHANCE = 0.08
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

-- Where a player breaks blocks
export type Area = {
	World: BlockWorld.World,
	-- Is this block part of the area as it was made (gives XP and double drops)? Asked
	-- before the block is broken.
	Natural: (x: number, y: number, z: number, blockType: string) -> boolean,
	-- After it's broken: nodes start growing back, other changes are saved. Returns how
	-- many leaves fell if this felled a tree.
	Broken: (x: number, y: number, z: number) -> number?,
}

local BlockService = {}

local lastBreak: { [Player]: number } = {}
local lastPlace: { [Player]: number } = {}
local rng = Random.new()

-- The player's own island, on island servers
local function islandArea(player: Player): Area?
	local island = IslandService.GetIsland(player)
	if not island then
		return nil
	end
	return {
		World = island.World,
		Natural = function(x, y, z, blockType)
			return IslandService.IsNatural(player, x, y, z, blockType)
		end,
		Broken = function(x, y, z)
			return IslandService.Broken(player, x, y, z)
		end,
	}
end

local areaFor: (Player) -> Area? = islandArea

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

-- Saplings for a felled tree: a roll for each leaf that fell, and always at least one
local function treeFell(player: Player, leaves: number)
	local saplings = 0
	for _ = 1, leaves do
		if rng:NextNumber() < SAPLING_CHANCE then
			saplings += 1
		end
	end
	saplings = math.max(saplings, 1)
	InventoryService.Add(player, "Sapling", saplings)
	StateService.Notify(
		player,
		`Timber! The tree fell. +{saplings} Sapling{if saplings > 1 then "s" else ""} to replant`,
		"good"
	)
end

local function onBreak(player: Player, x: unknown, y: unknown, z: unknown)
	if not isCell(x, y, z) then
		return
	end
	local cx, cy, cz = x :: number, y :: number, z :: number
	local area = areaFor(player)
	if not area then
		return
	end
	local world = area.World
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

	local natural = area.Natural(cx, cy, cz, blockType)
	BlockWorld.set(world, cx, cy, cz, nil)
	local fellLeaves = area.Broken(cx, cy, cz)

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
	if natural and blockType == "Leaves" and rng:NextNumber() < SAPLING_CHANCE then
		InventoryService.Add(player, "Sapling", 1)
		StateService.Notify(player, "Found a Sapling! Plant it on grass or dirt", "good")
	end
	if fellLeaves then
		treeFell(player, fellLeaves)
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
	if BlockWorld.occupied(world, cx, cy, cz) then
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

-- Starts breaking and placing on islands. A resource world passes `worldArea` instead:
-- breaking happens there, and placing is off.
function BlockService.Start(worldArea: ((Player) -> Area?)?)
	Remotes.BreakBlock.OnServerEvent:Connect(onBreak)
	if worldArea then
		areaFor = worldArea
	else
		Remotes.PlaceBlock.OnServerEvent:Connect(onPlace)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastBreak[player] = nil
		lastPlace[player] = nil
	end)
end

return BlockService
