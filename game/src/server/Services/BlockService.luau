--!strict
-- Breaking and placing blocks on your own island. The client times "hold to break";
-- the server checks the island is yours, the block is in reach, not protected, and that
-- you aren't breaking faster than the block allows.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local InventoryService = require(script.Parent.InventoryService)
local IslandService = require(script.Parent.IslandService)
local ProgressionService = require(script.Parent.ProgressionService)
local QuestService = require(script.Parent.QuestService)

local PLACE_COOLDOWN = 0.12
-- Building area around the island (in blocks)
local MAX_HEIGHT, MAX_DEPTH, EXTRA_RADIUS = 40, 40, 12

local BlockService = {}

local lastBreak: { [Player]: number } = {}
local lastPlace: { [Player]: number } = {}

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
	local now = os.clock()
	if now - (lastBreak[player] or 0) < def.BreakTime * 0.6 then
		return
	end
	lastBreak[player] = now

	BlockWorld.set(world, cx, cy, cz, nil)
	IslandService.RecordChange(player, cx, cy, cz, nil)
	if def.Drop then
		InventoryService.Add(player, def.Drop, 1)
	end
	if blockType == "Wood" then
		ProgressionService.AddPlayerXP(player, 2)
		QuestService.Record(player, "Chop")
	elseif blockType == "Stone" or blockType == "Cobblestone" then
		ProgressionService.AddPlayerXP(player, 2)
		QuestService.Record(player, "Mine")
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
	if world.Cells[cellKey] or world.Protected[cellKey] then
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
