--!strict
-- Chests: the traditional chest screen (client/Windows/ChestWindow), whoever's chest it is, and the
-- storage chests you place on your island (your rules, 2026-11-02: the 36 slots are all you carry, so
-- store the rest in real chests). A chest holds 27 slots. Several people can have one open (Warzone
-- chests are shared), so every move is checked here and everyone looking gets the new contents.
-- Breaking a storage chest gives you what's in it, and what doesn't fit goes to your Inbox, so nothing
-- is lost.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Inventory = require(ReplicatedStorage.Shared.Inventory)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local IslandService = require(script.Parent.IslandService)

local CHECK_EVERY = 0.5
local FAR = Blocks.Reach + 6 -- studs: walk this far away and a chest closes

export type Chest = {
	Id: string,
	Title: string,
	Slots: { Inventory.Stack },
	Part: BasePart?,
	Position: Vector3,
	Viewers: { [Player]: boolean },
	-- After its contents change (a storage chest saves, an emptied Warzone chest goes away)
	OnChanged: ((chest: Chest) -> ())?,
	-- Warzone chests: whether this player can open it now, and the first time each player does
	CanOpen: ((player: Player) -> boolean)?,
	OnFirstOpen: ((player: Player) -> ())?,
	-- A Warzone chest or Skydrop: which loot table filled it ("Chest", "Skydrop", "Legendary"; WarzoneLoot)
	Loot: string?,
}

local ChestService = {}

local openChest: { [Player]: Chest } = {}
local storage: { [string]: Chest } = {} -- by owner and cell

local function isIndex(index: unknown, last: number): boolean
	return type(index) == "number" and index == math.floor(index) and index >= 1 and index <= last
end

-- A numbered place in either list: 1 to 36 is your inventory, over 100 the chest (a body holds more)
local function placeOf(index: unknown, chest: Chest): boolean
	return isIndex(index, Inventory.Size)
		or (type(index) == "number" and isIndex(index - Inventory.ChestOffset, #chest.Slots))
end

local function send(chest: Chest)
	for viewer in chest.Viewers do
		Remotes.ChestUpdate:FireClient(viewer, chest.Id, chest.Slots)
	end
end

local function changed(chest: Chest)
	send(chest)
	if chest.OnChanged then
		chest.OnChanged(chest)
	end
end

local function closeFor(player: Player, tell: boolean)
	local chest = openChest[player]
	if chest then
		openChest[player] = nil
		chest.Viewers[player] = nil
		if tell then
			Remotes.ChestClosed:FireClient(player, chest.Id)
		end
	end
end

-- Shows a chest on this player's screen
function ChestService.Open(player: Player, chest: Chest)
	closeFor(player, false)
	openChest[player] = chest
	chest.Viewers[player] = true
	Remotes.ChestOpened:FireClient(player, chest.Id, chest.Title, chest.Slots, chest.Part)
end

-- Shuts a chest on everyone's screen (it's gone)
function ChestService.CloseAll(chest: Chest)
	for viewer in chest.Viewers do
		closeFor(viewer, true)
	end
end

-- Shuts whatever chest this player has open (they died)
function ChestService.CloseFor(player: Player)
	closeFor(player, true)
end

-- Keeps what you carry in step with its totals as a stack leaves or arrives
local function recount(data: any, before: Inventory.Stack, after: Inventory.Stack)
	local items = data.Items :: { [string]: number }
	if before.Count > 0 then
		items[before.Item] = (items[before.Item] or 0) - before.Count
	end
	if after.Count > 0 then
		items[after.Item] = (items[after.Item] or 0) + after.Count
	end
end

local function copyOf(stack: Inventory.Stack?): Inventory.Stack
	return if stack then { Item = stack.Item, Count = stack.Count } else { Item = "", Count = 0 }
end

local function canReach(player: Player, chest: Chest): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and root:IsA("BasePart") and (root.Position - chest.Position).Magnitude <= FAR
end

local function onMove(player: Player, from: unknown, to: unknown, amount: unknown)
	local chest = openChest[player]
	local data = DataService.GetData(player)
	if not chest or not data or not placeOf(from, chest) or not placeOf(to, chest) or not isIndex(amount, 1e9) then
		return
	end
	if from == to or not canReach(player, chest) then
		return
	end
	local a, b = from :: number, to :: number
	local bag = data.Slots
	local fromChest, toChest = a > Inventory.ChestOffset, b > Inventory.ChestOffset
	if not fromChest and not toChest then
		return -- inside your inventory: that's the MoveStack remote
	end
	local i = if fromChest then a - Inventory.ChestOffset else a
	local j = if toChest then b - Inventory.ChestOffset else b
	local fromList = if fromChest then chest.Slots else bag
	local toList = if toChest then chest.Slots else bag
	local bagIndex = if fromChest then j else i
	local before = copyOf(bag[bagIndex])
	-- Moved within the chest, or between it and you, the same way
	if Inventory.Across(fromList, i, toList, j, amount :: number, bag) then
		if fromChest ~= toChest then
			recount(data, before, bag[bagIndex])
			DataService.MarkChanged(player)
		end
		changed(chest)
	end
end

local function onQuick(player: Player, from: unknown)
	local chest = openChest[player]
	local data = DataService.GetData(player)
	if not chest or not data or not placeOf(from, chest) or not canReach(player, chest) then
		return
	end
	local index = from :: number
	local bag = data.Slots
	local before: { Inventory.Stack } = {}
	for slot = 1, Inventory.Size do
		before[slot] = copyOf(bag[slot])
	end
	local moved = if index > Inventory.ChestOffset
		then Inventory.Send(chest.Slots, index - Inventory.ChestOffset, bag, bag)
		else Inventory.Send(bag, index, chest.Slots, bag)
	if moved then
		for slot = 1, Inventory.Size do
			local was, now = before[slot], bag[slot]
			if was.Item ~= now.Item or was.Count ~= now.Count then
				recount(data, was, now)
			end
		end
		DataService.MarkChanged(player)
		changed(chest)
	end
end

-- Storage chests ------------------------------------------------------------------------------

type Saved = { Turn: number, Items: { { Slot: number, Item: string, Count: number } } }

local function savedChests(data: any): { [string]: Saved }
	return data.Island.Chests
end

local function save(data: any, key: string, chest: Chest)
	local saved = savedChests(data)[key]
	if saved then
		local items = {}
		for slot, stack in chest.Slots do
			if stack.Count > 0 then
				table.insert(items, { Slot = slot, Item = stack.Item, Count = stack.Count })
			end
		end
		saved.Items = items
	end
end

local function storageChest(player: Player, data: any, world: BlockWorld.World, x: number, y: number, z: number): Chest
	local key = BlockWorld.key(x, y, z)
	local id = `{player.UserId}:{key}`
	local known = storage[id]
	if known then
		return known
	end
	local saved = savedChests(data)[key]
	local slots = Inventory.EmptyOf(Inventory.ChestSize)
	if saved then
		for _, entry in saved.Items do
			if slots[entry.Slot] then
				slots[entry.Slot] = { Item = entry.Item, Count = entry.Count }
			end
		end
	end
	local chest: Chest = {
		Id = id,
		Title = "Chest",
		Slots = slots,
		Part = world.Parts[key],
		Position = BlockWorld.position(world, x, y, z),
		Viewers = {},
		OnChanged = function(self: Chest)
			save(data, key, self)
			DataService.MarkChanged(player)
		end,
	}
	storage[id] = chest
	return chest
end

local function onOpenStorage(player: Player, x: unknown, y: unknown, z: unknown)
	if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
		return
	end
	local island = IslandService.GetIsland(player)
	local data = DataService.GetData(player)
	if not island or not data or BlockWorld.get(island.World, x, y, z) ~= "Chest" then
		return
	end
	local chest = storageChest(player, data, island.World, x, y, z)
	chest.Part = island.World.Parts[BlockWorld.key(x, y, z)]
	if canReach(player, chest) then
		ChestService.Open(player, chest)
	end
end

-- A storage chest going down: it turns to face you
function ChestService.Placed(player: Player, world: BlockWorld.World, x: number, y: number, z: number)
	local data = DataService.GetData(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not data then
		return
	end
	local turn = 0
	if root and root:IsA("BasePart") then
		local toYou = root.Position - BlockWorld.position(world, x, y, z)
		turn = math.round(math.atan2(toYou.X, toYou.Z) / (math.pi / 2)) % 4
	end
	savedChests(data)[BlockWorld.key(x, y, z)] = { Turn = turn, Items = {} }
	BlockWorld.setTurn(world, x, y, z, turn)
	DataService.MarkChanged(player)
end

-- A storage chest broken: what's in it comes to you, and the rest to your Inbox
function ChestService.Broken(player: Player, x: number, y: number, z: number)
	local data = DataService.GetData(player)
	if not data then
		return
	end
	local key = BlockWorld.key(x, y, z)
	local id = `{player.UserId}:{key}`
	local live = storage[id]
	local saved = savedChests(data)[key]
	if live then
		ChestService.CloseAll(live)
		for _, stack in live.Slots do
			if stack.Count > 0 then
				InventoryService.Add(player, stack.Item, stack.Count)
			end
		end
	elseif saved then
		for _, entry in saved.Items do
			InventoryService.Add(player, entry.Item, entry.Count)
		end
	end
	storage[id] = nil
	savedChests(data)[key] = nil
	-- Whatever goes in this spot next stands square again
	local island = IslandService.GetIsland(player)
	if island then
		island.World.Turns[key] = nil
	end
end

local function restoreTurns(player: Player, island: IslandService.Island)
	local data = DataService.GetData(player)
	if data then
		for key, saved in savedChests(data) do
			local x, y, z = BlockWorld.unkey(key)
			BlockWorld.setTurn(island.World, x, y, z, saved.Turn)
		end
	end
end

-- Running everywhere there are chests
function ChestService.Start()
	Remotes.ChestMove.OnServerEvent:Connect(onMove)
	Remotes.ChestQuick.OnServerEvent:Connect(onQuick)
	Remotes.ChestClose.OnServerEvent:Connect(function(player: Player)
		closeFor(player, false)
	end)
	task.spawn(function()
		while true do
			task.wait(CHECK_EVERY)
			for player, chest in openChest do
				if not canReach(player, chest) then
					closeFor(player, true)
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		closeFor(player, false)
		local prefix = `{player.UserId}:`
		for id in storage do
			if string.sub(id, 1, #prefix) == prefix then
				storage[id] = nil
			end
		end
	end)
end

-- On island servers: storage chests
function ChestService.StartIsland()
	Remotes.OpenChest.OnServerEvent:Connect(onOpenStorage)
	IslandService.OnIslandCreated(restoreTurns)
end

return ChestService
