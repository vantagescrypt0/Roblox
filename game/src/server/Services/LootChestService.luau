--!strict
-- The Warzone's chests (your rules, 2026-11-02): all the same, spread out at random with no hotspots,
-- shared slots, and once one's emptied it vanishes and a new one appears somewhere else. Each stands on
-- open ground on one of the islands, never in the citadel. What they hold is in WarzoneLoot.luau; how
-- many there are and how soon a new one comes are Claude's picks, here.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Inventory = require(ReplicatedStorage.Shared.Inventory)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local WarzoneLoot = require(ReplicatedStorage.Shared.WarzoneLoot)
local Warzone = require(script.Parent.Parent.Worlds.Warzone)
local ChestService = require(script.Parent.ChestService)

local SIZE = Blocks.Size
local LIVE_CHESTS = 24
local PER_ISLAND = 1
local PER_BIG_ISLAND = 3 -- the four landmarks are far bigger
local BIG_RADIUS = 40
local NEW_ONE_AFTER = 20 -- seconds after one's emptied
local TRIES = 40
local ROOF_CHECK = 60 -- blocks above the island's ground the search for open air starts
local GROUND_SLACK = 10 -- blocks above or below its base that still count as the island's ground

local LootChestService = {}

local rng = Random.new()
local folder: Folder
local count = 0
local chests: { [string]: ChestService.Chest } = {}
local onIsland: { [string]: number } = {}

local function refill(slots: { Inventory.Stack })
	local stacks = rng:NextInteger(WarzoneLoot.MinStacks, WarzoneLoot.MaxStacks)
	local free = {}
	for index = 1, #slots do
		free[index] = index
	end
	for _ = 1, stacks do
		local entry = WarzoneLoot.Roll(rng:NextNumber())
		local slot = table.remove(free, rng:NextInteger(1, #free)) :: number
		slots[slot] = { Item = entry.Item, Count = rng:NextInteger(entry.Min, entry.Max) }
	end
end

-- Somewhere on this island with open air above and nothing in the way
local function findSpot(island: Warzone.IslandSpot, world: Instance): CFrame?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { world }
	local baseY = Warzone.CellHeight(island.Base)
	for _ = 1, TRIES do
		local angle = rng:NextNumber() * 2 * math.pi
		local distance = math.sqrt(rng:NextNumber()) * island.Radius * 0.85 * SIZE
		local x = island.X * SIZE + math.cos(angle) * distance
		local z = island.Z * SIZE + math.sin(angle) * distance
		local top = Vector3.new(x, baseY + ROOF_CHECK * SIZE, z)
		local hit = workspace:Raycast(top, Vector3.new(0, -(ROOF_CHECK + GROUND_SLACK * 2) * SIZE, 0), params)
		if hit and math.abs(hit.Position.Y - baseY) <= GROUND_SLACK * SIZE and hit.Normal.Y > 0.9 then
			local clear = #workspace:GetPartBoundsInBox(
				CFrame.new(hit.Position + Vector3.new(0, SIZE, 0)),
				Vector3.new(SIZE, SIZE * 1.6, SIZE)
			) == 0
			if clear then
				local turn = math.floor(rng:NextNumber() * 4) * math.pi / 2
				return CFrame.new(hit.Position + Vector3.new(0, SIZE / 2, 0)) * CFrame.Angles(0, turn, 0)
			end
		end
	end
	return nil
end

local spawnOne: () -> ()

local function goneAfter(chest: ChestService.Chest, island: string)
	for _, stack in chest.Slots do
		if stack.Count > 0 then
			return
		end
	end
	ChestService.CloseAll(chest)
	chests[chest.Id] = nil
	onIsland[island] = (onIsland[island] or 1) - 1
	if chest.Part then
		chest.Part:Destroy()
	end
	task.delay(NEW_ONE_AFTER, spawnOne)
end

function spawnOne()
	local template = ReplicatedStorage:WaitForChild("Blocks"):FindFirstChild("LootChest")
	local world = workspace:FindFirstChild("World")
	if not template or not template:IsA("BasePart") or not world then
		warn("[LootChests] nothing to spawn from")
		return
	end
	local list = Warzone.IslandSpots()
	for _ = 1, TRIES do
		local island = list[rng:NextInteger(1, #list)]
		local cap = if island.Radius >= BIG_RADIUS then PER_BIG_ISLAND else PER_ISLAND
		if (onIsland[island.Id] or 0) < cap then
			local spot = findSpot(island, world)
			if spot then
				count += 1
				local id = `loot{count}`
				local part = template:Clone()
				part.Name = "LootChest"
				part:PivotTo(spot)
				part:SetAttribute("ChestId", id)
				part.Parent = folder
				local slots = Inventory.EmptyOf(Inventory.ChestSize)
				refill(slots)
				local chest: ChestService.Chest = {
					Id = id,
					Title = "Warzone Chest",
					Slots = slots,
					Part = part,
					Position = spot.Position,
					Viewers = {},
					OnChanged = function(self: ChestService.Chest)
						goneAfter(self, island.Id)
					end,
				}
				chests[id] = chest
				onIsland[island.Id] = (onIsland[island.Id] or 0) + 1
				return
			end
		end
	end
	warn("[LootChests] no free spot found")
end

local function onOpen(player: Player, id: unknown)
	local chest = if type(id) == "string" then chests[id] else nil
	if not chest or player:GetAttribute("InWarzone") ~= true then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") and (root.Position - chest.Position).Magnitude <= Blocks.Reach + 3 then
		ChestService.Open(player, chest)
	end
end

function LootChestService.Start()
	folder = Instance.new("Folder")
	folder.Name = "LootChests"
	folder.Parent = workspace
	Remotes.OpenLootChest.OnServerEvent:Connect(onOpen)
	for _ = 1, LIVE_CHESTS do
		spawnOne()
	end
	local live = 0
	for _ in chests do
		live += 1
	end
	print(`[LootChests] {live} chests out`)
end

return LootChestService
