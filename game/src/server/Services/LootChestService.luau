--!strict
-- The Warzone's chests (your rules, 2026-11-02): all the same, spread out at random with no hotspots,
-- shared slots, and once one's emptied it vanishes and a new one appears somewhere else. Each stands on
-- open ground on one of the islands, never in the citadel. What they hold is in WarzoneLoot.luau; how
-- many there are and how soon a new one comes are Claude's picks, here.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Boosts = require(ReplicatedStorage.Shared.Boosts)
local Inventory = require(ReplicatedStorage.Shared.Inventory)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local WarzoneLoot = require(ReplicatedStorage.Shared.WarzoneLoot)
local Warzone = require(script.Parent.Parent.Worlds.Warzone)
local ChestService = require(script.Parent.ChestService)
local DataService = require(script.Parent.DataService)
local QuestService = require(script.Parent.QuestService)
local StateService = require(script.Parent.StateService)

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
local openedBy: { [ChestService.Chest]: { [Player]: boolean } } = setmetatable({}, { __mode = "k" }) :: any

-- Fills a chest's slots with what this kind of chest holds, in random slots
function LootChestService.Refill(slots: { Inventory.Stack }, kind: WarzoneLoot.Kind)
	local least, most = WarzoneLoot.Stacks(kind)
	local stacks = rng:NextInteger(least, most)
	local free = {}
	for index = 1, #slots do
		free[index] = index
	end
	for _ = 1, stacks do
		local entry = WarzoneLoot.Roll(kind, rng:NextNumber())
		local slot = table.remove(free, rng:NextInteger(1, #free)) :: number
		slots[slot] = { Item = entry.Item, Count = rng:NextInteger(entry.Min, entry.Max) }
	end
end

-- Somewhere on this island with open air above and nothing in the way
function LootChestService.FindSpot(island: Warzone.IslandSpot): CFrame?
	local world = workspace:FindFirstChild("World")
	if not world then
		return nil
	end
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
	if not template or not template:IsA("BasePart") or not workspace:FindFirstChild("World") then
		warn("[LootChests] nothing to spawn from")
		return
	end
	local list = Warzone.IslandSpots()
	for _ = 1, TRIES do
		local island = list[rng:NextInteger(1, #list)]
		local cap = if island.Radius >= BIG_RADIUS then PER_BIG_ISLAND else PER_ISLAND
		if (onIsland[island.Id] or 0) < cap then
			local spot = LootChestService.FindSpot(island)
			if spot then
				count += 1
				local id = `loot{count}`
				local part = template:Clone()
				part.Name = "LootChest"
				part:PivotTo(spot)
				part:SetAttribute("ChestId", id)
				part.Parent = folder
				local slots = Inventory.EmptyOf(Inventory.ChestSize)
				LootChestService.Refill(slots, "Chest")
				local chest: ChestService.Chest = {
					Id = id,
					Title = "Warzone Chest",
					Loot = "Chest",
					Slots = slots,
					Part = part,
					Position = spot.Position,
					Viewers = {},
					OnChanged = function(self: ChestService.Chest)
						goneAfter(self, island.Id)
					end,
					OnFirstOpen = function(player: Player)
						QuestService.Record(player, "OpenChest")
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

-- The Warzone tree's fourth boost: the first time they open a chest or Skydrop, sometimes one more thing from its table
local function luckyFind(player: Player, chest: ChestService.Chest)
	if not chest.Loot or not Boosts.Has(DataService.GetData(player), "Warzone", 4) then
		return
	end
	local kind: WarzoneLoot.Kind = chest.Loot :: any
	if rng:NextNumber() >= Boosts.ExtraLootChance then
		return
	end
	for index, stack in chest.Slots do
		if stack.Count <= 0 then
			local entry = WarzoneLoot.Roll(kind, rng:NextNumber())
			chest.Slots[index] = { Item = entry.Item, Count = rng:NextInteger(entry.Min, entry.Max) }
			StateService.Notify(player, "Lucky find! One more thing in here (Warzone boost)", "good")
			return
		end
	end
end

local function onOpen(player: Player, id: unknown)
	local chest = if type(id) == "string" then chests[id] else nil
	if not chest or player:GetAttribute("InWarzone") ~= true then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	if not root or not root:IsA("BasePart") or (root.Position - chest.Position).Magnitude > Blocks.Reach + 3 then
		return
	end
	if chest.CanOpen and not chest.CanOpen(player) then
		return
	end
	local seen = openedBy[chest]
	if not seen then
		seen = {}
		openedBy[chest] = seen
	end
	if not seen[player] then
		seen[player] = true
		luckyFind(player, chest)
		if chest.OnFirstOpen then
			chest.OnFirstOpen(player)
		end
	end
	ChestService.Open(player, chest)
end

-- Something else that opens the same way: a body (BodyService) or a Skydrop (SkydropService)
function LootChestService.Add(chest: ChestService.Chest)
	chests[chest.Id] = chest
end

function LootChestService.Remove(id: string)
	chests[id] = nil
end

-- Where the chests are in the Workspace
function LootChestService.Folder(): Folder
	return folder
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
