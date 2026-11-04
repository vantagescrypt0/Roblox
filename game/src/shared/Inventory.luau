--!strict
-- The inventory's rules (your call, 2026-11-02: 36 slots with stacks, like Minecraft). The first
-- 9 slots are the hotbar. Most things stack to 64; tools, worn gear and buckets don't stack
-- (Claude's numbers). Worn gear stays off the hotbar. The server runs these on the player's
-- data.Slots; the client runs Move and QuickMove too, so moving things feels instant.

local Items = require(script.Parent.Items)
local Tools = require(script.Parent.Tools)

export type Stack = { Item: string, Count: number }

local SIZE = 36
local HOTBAR = 9
local STACK = 64

local Inventory = { Size = SIZE, Hotbar = HOTBAR, ChestSize = 27, ChestOffset = 100 }

local function isGear(itemId: string): boolean
	local item = Items[itemId]
	return item ~= nil and item.Equip ~= nil
end

function Inventory.MaxStack(itemId: string): number
	if Tools.ByItem[itemId] or isGear(itemId) or string.find(itemId, "Bucket", 1, true) then
		return 1
	end
	return STACK
end

function Inventory.Empty(): { Stack }
	local slots = {}
	for index = 1, SIZE do
		slots[index] = { Item = "", Count = 0 }
	end
	return slots
end

-- Any number of empty slots, for a chest
function Inventory.EmptyOf(size: number): { Stack }
	local slots = {}
	for index = 1, size do
		slots[index] = { Item = "", Count = 0 }
	end
	return slots
end

-- How many more of an item fit
function Inventory.RoomFor(slots: { Stack }, itemId: string): number
	local max = Inventory.MaxStack(itemId)
	local first = if isGear(itemId) then HOTBAR + 1 else 1
	local room = 0
	for index = first, SIZE do
		local stack = slots[index]
		if stack.Count <= 0 then
			room += max
		elseif stack.Item == itemId then
			room += max - stack.Count
		end
	end
	return room
end

-- Adds to stacks already there, then to the first empty slots (the hotbar first, except for worn
-- gear). Returns how many didn't fit.
function Inventory.Insert(slots: { Stack }, itemId: string, amount: number): number
	local max = Inventory.MaxStack(itemId)
	local first = if isGear(itemId) then HOTBAR + 1 else 1
	local left = amount
	for index = first, SIZE do
		local stack = slots[index]
		if left > 0 and stack.Count > 0 and stack.Item == itemId and stack.Count < max then
			local moved = math.min(left, max - stack.Count)
			stack.Count += moved
			left -= moved
		end
	end
	for index = first, SIZE do
		local stack = slots[index]
		if left > 0 and stack.Count <= 0 then
			local moved = math.min(left, max)
			stack.Item = itemId
			stack.Count = moved
			left -= moved
		end
	end
	return left
end

-- Takes up to `amount` of an item, from the slot `prefer` if it has some, then from the last slots
-- first so the hotbar stays full. Returns how many it took.
function Inventory.Take(slots: { Stack }, itemId: string, amount: number, prefer: number?): number
	local taken = 0
	local function from(stack: Stack)
		if taken < amount and stack.Count > 0 and stack.Item == itemId then
			local moved = math.min(amount - taken, stack.Count)
			stack.Count -= moved
			taken += moved
			if stack.Count <= 0 then
				stack.Item = ""
				stack.Count = 0
			end
		end
	end
	if prefer and slots[prefer] then
		from(slots[prefer])
	end
	for index = SIZE, 1, -1 do
		from(slots[index])
	end
	return taken
end

-- Moves `amount` from one slot to another: onto an empty slot or the same item, up to a full stack.
-- A whole stack moved onto a different item swaps with it. Returns whether anything moved.
function Inventory.Move(slots: { Stack }, from: number, to: number, amount: number?): boolean
	local a, b = slots[from], slots[to]
	if not a or not b or from == to or a.Count <= 0 then
		return false
	end
	local count = math.clamp(amount or a.Count, 1, a.Count)
	if to <= HOTBAR and isGear(a.Item) then
		return false
	end
	if b.Count <= 0 or b.Item == a.Item then
		local room = Inventory.MaxStack(a.Item) - math.max(b.Count, 0)
		local moved = math.min(count, room)
		if moved <= 0 then
			return false
		end
		b.Item = a.Item
		b.Count = math.max(b.Count, 0) + moved
		a.Count -= moved
		if a.Count <= 0 then
			a.Item = ""
			a.Count = 0
		end
		return true
	end
	if count < a.Count or (from <= HOTBAR and isGear(b.Item)) then
		return false
	end
	a.Item, b.Item = b.Item, a.Item
	a.Count, b.Count = b.Count, a.Count
	return true
end

-- Shift-click: sends a stack between the hotbar and the rest of the inventory
function Inventory.QuickMove(slots: { Stack }, from: number): boolean
	local stack = slots[from]
	if not stack or stack.Count <= 0 then
		return false
	end
	local first = if from <= HOTBAR then HOTBAR + 1 else 1
	local last = if from <= HOTBAR then SIZE else HOTBAR
	local moved = false
	for pass = 1, 2 do
		for index = first, last do
			local target = slots[index]
			local fits = if pass == 1 then target.Count > 0 and target.Item == stack.Item else target.Count <= 0
			if stack.Count > 0 and fits and Inventory.Move(slots, from, index) then
				moved = true
			end
		end
	end
	return moved
end

-- Moves between two lists of slots, a chest and your inventory (`bag`): the same rules as Move, with
-- worn gear kept off your hotbar. Returns whether anything moved.
function Inventory.Across(
	from: { Stack },
	i: number,
	to: { Stack },
	j: number,
	amount: number?,
	bag: { Stack }
): boolean
	local a, b = from[i], to[j]
	if not a or not b or a.Count <= 0 or (from == to and i == j) then
		return false
	end
	local count = math.clamp(amount or a.Count, 1, a.Count)
	local function barred(list: { Stack }, index: number, itemId: string): boolean
		return list == bag and index <= HOTBAR and isGear(itemId)
	end
	if barred(to, j, a.Item) then
		return false
	end
	if b.Count <= 0 or b.Item == a.Item then
		local moved = math.min(count, Inventory.MaxStack(a.Item) - math.max(b.Count, 0))
		if moved <= 0 then
			return false
		end
		b.Item = a.Item
		b.Count = math.max(b.Count, 0) + moved
		a.Count -= moved
		if a.Count <= 0 then
			a.Item = ""
			a.Count = 0
		end
		return true
	end
	if count < a.Count or barred(from, i, b.Item) then
		return false
	end
	a.Item, b.Item = b.Item, a.Item
	a.Count, b.Count = b.Count, a.Count
	return true
end

-- Shift-click in a chest: sends a stack across as far as it fits, onto what's the same first. Into your
-- inventory it starts from the end of the hotbar, as Minecraft does. Returns whether anything moved.
function Inventory.Send(from: { Stack }, i: number, to: { Stack }, bag: { Stack }): boolean
	local stack = from[i]
	if not stack or stack.Count <= 0 then
		return false
	end
	local itemId = stack.Item
	local first, last, step = 1, #to, 1
	if to == bag then
		first, last, step = HOTBAR, 1, -1
	end
	local moved = false
	local function pass(a: number, z: number, wantSame: boolean)
		for index = a, z, step do
			local target = to[index]
			local fits = if wantSame then target.Count > 0 and target.Item == itemId else target.Count <= 0
			if stack.Count > 0 and stack.Item == itemId and fits then
				moved = Inventory.Across(from, i, to, index, nil, bag) or moved
			end
		end
	end
	for _, wantSame in { true, false } do
		pass(first, last, wantSame)
		if to == bag then
			-- Then the rest of the inventory, from its last slot
			pass(SIZE, HOTBAR + 1, wantSame)
		end
	end
	return moved
end

-- Takes an item out of every slot
function Inventory.Clear(slots: { Stack }, itemId: string)
	for _, stack in slots do
		if stack.Item == itemId then
			stack.Item = ""
			stack.Count = 0
		end
	end
end

return Inventory
