--!strict
-- The Bag: a real inventory in the Night Glass look (Figma file "Skycore UI"; your pick,
-- 2026-11-03). Your 36 slots (Inventory.luau) with the hotbar along the bottom, your character
-- among the armour, shield and pet slots, a 2x2 grid for little crafts, and a card about the
-- item under your mouse.
--
-- Click a stack to pick it up and click again to put it down; right-click takes or leaves half or
-- one, and shift-click sends it straight across (or wears it). Worn things go in their slots.
-- What's in your hand and in the crafting grid never leaves your inventory on the server: it's
-- only drawn that way, so closing the Bag puts it all back and nothing can be lost or duplicated.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Foods = require(ReplicatedStorage.Shared.Foods)
local Gear = require(ReplicatedStorage.Shared.Gear)
local Inventory = require(ReplicatedStorage.Shared.Inventory)
local Items = require(ReplicatedStorage.Shared.Items)
local KitPowers = require(ReplicatedStorage.Shared.KitPowers)
local Recipes = require(ReplicatedStorage.Shared.Recipes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Rig = require(ReplicatedStorage.Shared.Rig)
local Tools = require(ReplicatedStorage.Shared.Tools)
local Hotbar = require(script.Parent.Parent.Hotbar)
local CrateWindow = require(script.Parent.CrateWindow)
local Glass = require(script.Parent.Parent.UI.Glass)
local ItemIcon = require(script.Parent.Parent.UI.ItemIcon)
local Theme = require(script.Parent.Parent.UI.Theme)
local Window = require(script.Parent.Parent.UI.Window)

local C = Glass.Color

local WINDOW = Vector2.new(1040, 566)
local SLOT = 69
local GAP = 6
local COLUMNS = 9
local CRAFT_SLOT = 52
local RIGHT = 320 -- where the right-hand side starts
local ITEMS_Y = 160
local HOTBAR_Y = 408

local STAGE = Vector2.new(300, 478)
local EQUIP_SLOT = 62
local EQUIP_GAP = 8
-- The slots, in columns down each side of the character
local EQUIP_SLOTS = {
	{ Slot = "Helmet", Name = "Helmet", Column = 0, Row = 0, From = "skill challenges give these" },
	{ Slot = "Chest", Name = "Chestplate", Column = 0, Row = 1, From = "skill challenges give these" },
	{ Slot = "Legs", Name = "Leggings", Column = 0, Row = 2, From = "skill challenges give these" },
	{ Slot = "Boots", Name = "Boots", Column = 0, Row = 3, From = "skill challenges give these" },
	{ Slot = "Shield", Name = "Shield", Column = 1, Row = 0, From = "craft one at the Anvil" },
	{ Slot = "Pet", Name = "Pet", Column = 1, Row = 1, From = "skill challenges give these" },
}

-- How the character stands in the preview
local PREVIEW_FOV = 30
local PREVIEW_HEIGHT_SHARE = 0.6 -- how much of the stage's height the character takes, at most
local PREVIEW_WIDTH_SHARE = 0.62 -- and of its width
local PREVIEW_BODY_WIDTH = 4.2 -- studs across the shoulders
local PREVIEW_LOWER = 1.2 -- studs below the middle of the stage
local PREVIEW_SWAY = math.rad(38)
local PREVIEW_SWAY_SPEED = 0.6
-- With a shield on, the view stays round its face: from straight ahead it's nearly edge-on
local SHIELD_TURN = math.rad(-25)
local SHIELD_SWAY = math.rad(20)

local BagWindow = {}

type Carried = { Item: string, Count: number, From: number | "Cell" }
type How = "left" | "right" | "shift"

local window: Window.Window
local state: any = nil
local slots: { Glass.Slot } = {}
local cellSlots: { Glass.Slot } = {}
local resultSlot: Glass.Slot
local equipSlots: { [string]: Glass.Slot } = {}
local ghosts: { [string]: ImageLabel } = {}
local coinsText: TextLabel
local bonuses: TextLabel
local preview: ViewportFrame
local previewFocus = Vector3.zero
local previewHeight = 6
local previewTurn = 0
local previewSway = PREVIEW_SWAY
-- Redoes the hint for the equipment slot you're pointing at, so it follows when that slot changes
local describePointedSlot: (() -> ())? = nil
local shownEquipped = ""

local infoPicture: Frame
local infoName: TextLabel
local infoKind: TextLabel
local infoText: TextLabel
local infoItem = ""

local carried: Carried? = nil
local floating: Frame
local floatingIcon: Frame
local floatingCount: TextLabel
local floatingItem = ""
local cells: { [number]: Inventory.Stack? } = {}
local prefer: { [string]: number } = {} -- which slot an item in the grid was picked up from
local hoverEquip: string? = nil -- the slot of the gear under the mouse

local handRecipes: { Recipes.Recipe } = {}
for _, recipe in Recipes.ById do
	if recipe.Hand then
		table.insert(handRecipes, recipe)
	end
end

local function percent(ratio: number): string
	return string.format("%g", math.round(ratio * 10000) / 100)
end

-- What the card says about an item: what kind of thing it is, and a line about it
local function describe(itemId: string): (string, string)
	local item = Items[itemId]
	local sells = if item.SellPrice > 0 then ` Sells for {Theme.formatNumber(item.SellPrice)} coins.` else ""
	local tool = Tools.ByItem[itemId]
	local pet, armor = Gear.Pets[itemId], Gear.Armors[itemId]
	local special = KitPowers.Swords[itemId]
	if special then
		return `Sword · {special.Name}`, `Right-click while holding it: {special.Text}`
	elseif tool then
		return `Tool · {tool.Kind}`, `{tool.TierName} tier. Put it on your hotbar and hold it to use it.`
	elseif pet then
		return `Pet · {pet.Skill}`, `+{percent(pet.XPBonus)}% {pet.Skill} XP while it follows you.`
	elseif armor and armor.Class then
		local bonus = KitPowers.Sets[armor.Skill]
		return `Armour · {armor.Skill} Kit`, `Protects like diamond. All four worn, {bonus.Name}: {bonus.Text}`
	elseif armor then
		return `Armour · {armor.Skill}`, `+{percent(armor.DropBonus)}% chance of double {armor.Skill} drops.`
	elseif item.Equip == "Shield" then
		return "Shield", "Hold right-click in the Warzone to block hits from the front."
	elseif item.Crate then
		return "Loot crate", "Shift-click it to open it."
	elseif Foods[itemId] then
		return "Food", `Fills {Foods[itemId]} hunger in the Warzone.{sells}`
	elseif itemId == "Chest" then
		return "Storage", "Place it on your island and right-click it: 27 slots to keep what you can't carry."
	elseif item.Block then
		return "Block", `Place it on your island.{sells}`
	end
	return "Material", `Used for crafting.{sells}`
end

local function setInfo(itemId: string)
	if itemId == infoItem or not Items[itemId] then
		return
	end
	infoItem = itemId
	for _, child in infoPicture:GetChildren() do
		child:Destroy()
	end
	ItemIcon.create(infoPicture, itemId, UDim2.fromScale(1, 1))
	infoName.Text = Items[itemId].Name
	infoText.Position = UDim2.fromOffset(118, 68)
	infoText.Size = UDim2.new(1, -132, 0, 54)
	local kind, text = describe(itemId)
	infoKind.Text = kind
	infoText.Text = text
end

local function hint(text: string)
	infoItem = ""
	for _, child in infoPicture:GetChildren() do
		child:Destroy()
	end
	infoName.Text = ""
	infoKind.Text = ""
	infoText.Text = text
	-- With no picture, the words get the card to themselves
	infoText.Position = UDim2.fromOffset(18, 46)
	infoText.Size = UDim2.new(1, -36, 0, 54)
end

local function worn(slot: string): string?
	local itemId = state and state.Equipped[slot]
	return if itemId and itemId ~= "" and (state.Items[itemId] or 0) > 0 then itemId else nil
end

-- What everything worn adds up to, for the line under the character
local function bonusText(): string
	local drops, xp, parts = {}, {}, {}
	for _, entry in EQUIP_SLOTS do
		local itemId = worn(entry.Slot)
		local armor = itemId and Gear.Armors[itemId]
		local pet = itemId and Gear.Pets[itemId]
		if armor and armor.DropBonus > 0 then
			drops[armor.Skill] = (drops[armor.Skill] or 0) + armor.DropBonus
		elseif pet then
			xp[pet.Skill] = pet.XPBonus
		end
	end
	for skill, bonus in drops do
		table.insert(parts, `+{percent(bonus)}% double {skill} drops`)
	end
	for skill, bonus in xp do
		table.insert(parts, `+{percent(bonus)}% {skill} XP`)
	end
	table.sort(parts)
	return table.concat(parts, " · ")
end

-- The hand holding a shield is moved by an IKControl, which doesn't run in a viewport, so the
-- copy takes that arm's pose from you
local function shieldArmPose(character: Model): { [string]: CFrame }?
	local chest = character:FindFirstChild("UpperTorso")
	if not chest or not chest:IsA("BasePart") or not character:FindFirstChild("Shield") then
		return nil
	end
	local pose = {}
	for _, name in { "LeftUpperArm", "LeftLowerArm", "LeftHand" } do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			pose[name] = chest.CFrame:ToObjectSpace(part.CFrame)
		end
	end
	return pose
end

-- Puts a still copy of your character in the middle of the slots
local function buildPreview()
	local old = preview:FindFirstChildOfClass("Model")
	if old then
		old:Destroy()
	end
	local character = Players.LocalPlayer.Character
	if not character then
		return
	end
	local archivable = character.Archivable
	character.Archivable = true
	local copy = character:Clone()
	character.Archivable = archivable
	if not copy then
		return
	end
	for _, child in copy:GetChildren() do
		-- The pet floats about under the character and has a slot of its own; hands stay empty here
		if child:IsA("Model") or child:IsA("Tool") or child.Name == "Held" then
			child:Destroy()
		end
	end
	for _, descendant in copy:GetDescendants() do
		if
			descendant:IsA("LuaSourceContainer")
			or descendant:IsA("Sound")
			or descendant:IsA("ForceField")
			or descendant:IsA("IKControl")
		then
			descendant:Destroy()
		elseif descendant:IsA("Humanoid") then
			descendant.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	end
	local root = copy:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		copy:Destroy()
		return
	end
	-- There's no physics in a viewport, so the copy stands straight and still
	Rig.Settle(copy, root, shieldArmPose(character))
	copy.PrimaryPart = root
	local box, size = copy:GetBoundingBox()
	previewFocus = box.Position
	previewHeight = size.Y
	local shielded = copy:FindFirstChild("Shield") ~= nil
	previewTurn = if shielded then SHIELD_TURN else 0
	previewSway = if shielded then SHIELD_SWAY else PREVIEW_SWAY
	copy.Parent = preview
end

-- The inventory as it should look: minus what's in your hand and in the crafting grid
local function shownSlots(): { Inventory.Stack }
	local shown: { Inventory.Stack } = {}
	for index = 1, Inventory.Size do
		local stack = state.Slots[index]
		shown[index] = { Item = if stack then stack.Item else "", Count = if stack then stack.Count else 0 }
	end
	local held = carried
	if held and held.From ~= "Cell" then
		local from = shown[held.From :: number]
		from.Count = math.max(from.Count - held.Count, 0)
	end
	local reserved: { [string]: number } = {}
	for index = 1, 4 do
		local cell = cells[index]
		if cell then
			reserved[cell.Item] = (reserved[cell.Item] or 0) + cell.Count
		end
	end
	if held and held.From == "Cell" then
		reserved[held.Item] = (reserved[held.Item] or 0) + held.Count
	end
	for itemId, amount in reserved do
		local left = amount - Inventory.Take(shown, itemId, amount, prefer[itemId])
		-- Used up elsewhere while it sat in the grid
		for index = 4, 1, -1 do
			local cell = cells[index]
			if left > 0 and cell and cell.Item == itemId then
				local cut = math.min(left, cell.Count)
				cell.Count -= cut
				left -= cut
				if cell.Count <= 0 then
					cells[index] = nil
				end
			end
		end
	end
	return shown
end

-- The recipe the grid spells out: each filled square counts as one of its item
local function matchRecipe(): Recipes.Recipe?
	local counts: { [string]: number } = {}
	local filled = 0
	for index = 1, 4 do
		local cell = cells[index]
		if cell then
			counts[cell.Item] = (counts[cell.Item] or 0) + 1
			filled += 1
		end
	end
	if filled == 0 then
		return nil
	end
	for _, recipe in handRecipes do
		local needed = 0
		local same = true
		for itemId, count in recipe.Inputs do
			needed += count
			same = same and counts[itemId] == count
		end
		if same and needed == filled then
			return recipe
		end
	end
	return nil
end

local function renderCarried()
	local held = carried
	-- Something else used it up while it was in your hand
	if held and held.From ~= "Cell" then
		local stack = state.Slots[held.From :: number]
		if not stack or stack.Item ~= held.Item or stack.Count < held.Count then
			carried = nil
			held = nil
		end
	end
	local item = if held then held.Item else ""
	if item ~= floatingItem then
		floatingItem = item
		for _, child in floatingIcon:GetChildren() do
			child:Destroy()
		end
		if item ~= "" then
			ItemIcon.create(floatingIcon, item, UDim2.fromScale(0.9, 0.9))
		end
	end
	floating.Visible = held ~= nil
	floatingCount.Text = if held and held.Count > 1 then tostring(held.Count) else ""
end

local function renderEquipment()
	local held = carried
	local gearInHand = if held then Items[held.Item].Equip else nil
	for _, entry in EQUIP_SLOTS do
		local slot = equipSlots[entry.Slot]
		local itemId = worn(entry.Slot)
		Glass.setSlot(slot, itemId or "", if itemId then 1 else 0)
		ghosts[entry.Slot].Visible = itemId == nil
		local armor = itemId and Gear.Armors[itemId]
		if gearInHand == entry.Slot or hoverEquip == entry.Slot then
			Glass.setSelected(slot, true)
		elseif itemId then
			Glass.setSelected(slot, true, if armor then Gear.TierColors[armor.Tier] else C.Gold)
		else
			Glass.setSelected(slot, false)
		end
	end
	local text = bonusText()
	bonuses.Text = text
	bonuses.Visible = text ~= ""
end

local function render()
	if not state then
		return
	end
	renderCarried()
	local shown = shownSlots()
	for index, slot in slots do
		Glass.setSlot(slot, shown[index].Item, shown[index].Count)
		if index <= Inventory.Hotbar then
			Glass.setSelected(slot, index == Hotbar.Selected())
		end
	end
	for index, slot in cellSlots do
		local cell = cells[index]
		Glass.setSlot(slot, if cell then cell.Item else "", if cell then cell.Count else 0)
	end
	local recipe = matchRecipe()
	Glass.setSlot(resultSlot, if recipe then recipe.Output else "", if recipe then recipe.Amount else 0)
	renderEquipment()
	coinsText.Text = Theme.formatNumber(state.Coins)
end

local function howClicked(): How
	local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
	return if shift then "shift" else "left"
end

-- Moves items now on this screen, and tells the server
local function move(from: number, to: number, amount: number): boolean
	if Inventory.Move(state.Slots, from, to, amount) then
		Remotes.MoveStack:FireServer(from, to, amount)
		return true
	end
	return false
end

local function onSlot(index: number, how: How)
	if not state then
		return
	end
	local stack = shownSlots()[index]
	local held = carried
	if not held then
		if stack.Count <= 0 then
			return
		end
		if how == "shift" then
			local item = Items[stack.Item]
			if item.Equip then
				Remotes.Equip:FireServer(stack.Item)
			elseif item.Crate then
				CrateWindow.Open()
			elseif Inventory.QuickMove(state.Slots, index) then
				Remotes.QuickMove:FireServer(index)
			end
		else
			local count = if how == "right" then math.ceil(stack.Count / 2) else stack.Count
			carried = { Item = stack.Item, Count = count, From = index }
			prefer[stack.Item] = index
		end
	elseif held.From == "Cell" then
		-- Out of the grid: it was never out of the inventory, so it simply shows there again
		carried = nil
	elseif held.From == index then
		if how == "right" then
			held.Count -= 1
			if held.Count <= 0 then
				carried = nil
			end
		else
			carried = nil
		end
	else
		local from = held.From :: number
		local amount = if how == "right" then 1 else held.Count
		if move(from, index, amount) then
			held.Count -= amount
			if held.Count <= 0 then
				carried = nil
			end
		elseif Items[held.Item].Equip and index <= Inventory.Hotbar then
			hint("Worn things don't go on the hotbar.")
		end
	end
	render()
end

local function onCell(index: number, how: How)
	local held = carried
	local cell = cells[index]
	if held then
		if cell and cell.Item ~= held.Item then
			return
		end
		local have = if cell then cell.Count else 0
		local amount = math.min(if how == "right" then 1 else held.Count, Inventory.MaxStack(held.Item) - have)
		if amount <= 0 then
			return
		end
		cells[index] = { Item = held.Item, Count = have + amount }
		held.Count -= amount
		if held.Count <= 0 then
			carried = nil
		end
	elseif cell then
		carried = { Item = cell.Item, Count = cell.Count, From = "Cell" }
		cells[index] = nil
	end
	render()
end

local function onResult(how: How)
	local recipe = matchRecipe()
	if not recipe or carried then
		return
	end
	local times = 1
	if how == "shift" then
		times = math.huge
		for index = 1, 4 do
			local cell = cells[index]
			if cell then
				times = math.min(times, cell.Count)
			end
		end
	end
	for _ = 1, times do
		Remotes.Craft:FireServer(recipe.Id)
		for index = 1, 4 do
			local cell = cells[index]
			if cell then
				cell.Count -= 1
				if cell.Count <= 0 then
					cells[index] = nil
				end
			end
		end
	end
	render()
end

local function onEquipSlot(entry: typeof(EQUIP_SLOTS[1]))
	local held = carried
	if held then
		if Items[held.Item].Equip == entry.Slot then
			Remotes.Equip:FireServer(held.Item)
			carried = nil
		else
			hint(`That doesn't go in the {entry.Name} slot.`)
		end
	else
		local itemId = worn(entry.Slot)
		if itemId then
			Remotes.Equip:FireServer(itemId)
		else
			-- An empty slot puts on the first thing you have that fits
			local found: string? = nil
			for index = 1, Inventory.Size do
				local stack = state.Slots[index]
				if not found and stack and stack.Count > 0 and Items[stack.Item].Equip == entry.Slot then
					found = stack.Item
				end
			end
			if found then
				Remotes.Equip:FireServer(found)
			else
				hint(
					`{entry.Name}: nothing to put on yet. {string.upper(string.sub(entry.From, 1, 1))}{string.sub(
						entry.From,
						2
					)}.`
				)
			end
		end
	end
	render()
end

local function equippedKey(): string
	local parts = {}
	for _, entry in EQUIP_SLOTS do
		table.insert(parts, state and state.Equipped[entry.Slot] or "")
	end
	return table.concat(parts, "|")
end

local function buildEquipment(body: Frame)
	local stage = Glass.stage(body, UDim2.fromOffset(STAGE.X, STAGE.Y))
	stage.Name = "Stage"
	local title = Glass.text(stage, "Equipment", 17, Glass.Font.Bold)
	title.Position = UDim2.fromOffset(14, 10)
	title.Size = UDim2.fromOffset(200, 22)
	title.ZIndex = 2

	Glass.glow(stage, C.Accent, UDim2.fromOffset(300, 300), UDim2.fromOffset(STAGE.X / 2, 310), 0.72)
	preview = Theme.make("ViewportFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(175, 175, 180),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(0.3, -0.7, 0.7),
		Parent = stage,
	})

	for _, entry in EQUIP_SLOTS do
		local x = if entry.Column == 0 then 10 else STAGE.X - 10 - EQUIP_SLOT
		local slot = Glass.slot(stage, EQUIP_SLOT, UDim2.fromOffset(x, 40 + entry.Row * (EQUIP_SLOT + EQUIP_GAP)))
		slot.Button.ZIndex = 2
		slot.Button.Name = `Equip{entry.Slot}`
		ghosts[entry.Slot] = Theme.make("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.74, 0.74),
			BackgroundTransparency = 1,
			Image = Config.SlotIcons[entry.Slot],
			ImageTransparency = 0.74,
			ScaleType = Enum.ScaleType.Fit,
			Parent = slot.Button,
		})
		local function describeSlot()
			local itemId = worn(entry.Slot)
			if itemId then
				setInfo(itemId)
			else
				hint(`{entry.Name}: nothing on. Drop one here, or click to put on the first you have.`)
			end
		end
		slot.Button.MouseEnter:Connect(function()
			describePointedSlot = describeSlot
			describeSlot()
		end)
		slot.Button.MouseLeave:Connect(function()
			describePointedSlot = nil
		end)
		slot.Button.Activated:Connect(function()
			onEquipSlot(entry)
		end)
		equipSlots[entry.Slot] = slot
	end

	bonuses = Glass.text(stage, "", 13, Glass.Font.Body, C.Muted)
	bonuses.AnchorPoint = Vector2.new(0.5, 1)
	bonuses.Position = UDim2.new(0.5, 0, 1, -8)
	bonuses.Size = UDim2.new(1, -20, 0, 34)
	bonuses.TextWrapped = true
	bonuses.TextTruncate = Enum.TextTruncate.None
	bonuses.TextXAlignment = Enum.TextXAlignment.Center
	bonuses.TextYAlignment = Enum.TextYAlignment.Bottom
	bonuses.ZIndex = 2
end

local function buildCrafting(body: Frame)
	local title = Glass.text(body, "Crafting", 16, Glass.Font.Bold)
	title.Position = UDim2.fromOffset(RIGHT, -2)
	title.Size = UDim2.fromOffset(200, 20)
	for index = 1, 4 do
		local column, row = (index - 1) % 2, (index - 1) // 2
		local slot = Glass.slot(
			body,
			CRAFT_SLOT,
			UDim2.fromOffset(RIGHT + column * (CRAFT_SLOT + GAP), 22 + row * (CRAFT_SLOT + GAP))
		)
		slot.Button.Name = `Cell{index}`
		slot.Button.Activated:Connect(function()
			onCell(index, howClicked())
		end)
		slot.Button.MouseButton2Click:Connect(function()
			onCell(index, "right")
		end)
		slot.Button.MouseEnter:Connect(function()
			local cell = cells[index]
			if cell then
				setInfo(cell.Item)
			else
				hint("Little crafts: one input to a square, like 1 Wood for Planks or 2 Planks for Sticks.")
			end
		end)
		cellSlots[index] = slot
	end
	local arrow = Glass.text(body, ">", 26, Glass.Font.Bold, C.Muted)
	arrow.Position = UDim2.fromOffset(RIGHT + CRAFT_SLOT * 2 + GAP + 9, 58)
	arrow.Size = UDim2.fromOffset(24, 34)
	arrow.TextXAlignment = Enum.TextXAlignment.Center
	resultSlot = Glass.slot(body, 66, UDim2.fromOffset(RIGHT + CRAFT_SLOT * 2 + GAP + 42, 43))
	resultSlot.Button.Name = "CraftResult"
	resultSlot.Button.Activated:Connect(function()
		onResult(howClicked())
	end)
	resultSlot.Button.MouseEnter:Connect(function()
		if resultSlot.Item ~= "" then
			setInfo(resultSlot.Item)
		end
	end)
end

local function buildInfo(body: Frame)
	local x = RIGHT + 246
	local card =
		Glass.inset(body, UDim2.fromOffset(COLUMNS * SLOT + (COLUMNS - 1) * GAP - 246, 132), UDim2.fromOffset(x, 0))
	infoPicture = Theme.make("Frame", {
		Position = UDim2.fromOffset(16, 22),
		Size = UDim2.fromOffset(88, 88),
		BackgroundTransparency = 1,
		Parent = card,
	})
	infoName = Glass.text(card, "", 21, Glass.Font.Bold)
	infoName.Position = UDim2.fromOffset(118, 18)
	infoName.Size = UDim2.new(1, -132, 0, 26)
	infoKind = Glass.text(card, "", 14, Glass.Font.Body, C.Accent)
	infoKind.Position = UDim2.fromOffset(118, 46)
	infoKind.Size = UDim2.new(1, -132, 0, 18)
	infoText = Glass.text(card, "", 14, Glass.Font.Body, C.Muted)
	infoText.Position = UDim2.fromOffset(118, 68)
	infoText.Size = UDim2.new(1, -132, 0, 54)
	infoText.TextWrapped = true
	infoText.TextTruncate = Enum.TextTruncate.None
	infoText.TextYAlignment = Enum.TextYAlignment.Top
end

local function buildSlots(body: Frame)
	local itemsTitle = Glass.text(body, "Items", 16, Glass.Font.Bold)
	itemsTitle.Position = UDim2.fromOffset(RIGHT, ITEMS_Y - 22)
	itemsTitle.Size = UDim2.fromOffset(200, 20)
	local hotbarTitle = Glass.text(body, "Hotbar", 16, Glass.Font.Bold)
	hotbarTitle.Position = UDim2.fromOffset(RIGHT, HOTBAR_Y - 22)
	hotbarTitle.Size = UDim2.fromOffset(200, 20)

	for index = 1, Inventory.Size do
		local column, y
		if index <= Inventory.Hotbar then
			column, y = index - 1, HOTBAR_Y
		else
			local here = index - Inventory.Hotbar - 1
			column, y = here % COLUMNS, ITEMS_Y + (here // COLUMNS) * (SLOT + GAP)
		end
		local slot = Glass.slot(body, SLOT, UDim2.fromOffset(RIGHT + column * (SLOT + GAP), y))
		slot.Button.Name = `Slot{index}`
		slot.Button.Activated:Connect(function()
			onSlot(index, howClicked())
		end)
		slot.Button.MouseButton2Click:Connect(function()
			onSlot(index, "right")
		end)
		slot.Button.MouseEnter:Connect(function()
			if slot.Item ~= "" then
				setInfo(slot.Item)
				hoverEquip = Items[slot.Item].Equip
			else
				hoverEquip = nil
			end
			if state then
				renderEquipment()
			end
		end)
		slot.Button.MouseLeave:Connect(function()
			hoverEquip = nil
			if state then
				renderEquipment()
			end
		end)
		slots[index] = slot
	end
end

function BagWindow.SetState(newState: any)
	state = newState
	if window.IsOpen then
		render()
		local key = equippedKey()
		if key ~= shownEquipped then
			shownEquipped = key
			if describePointedSlot then
				describePointedSlot()
			end
			-- The server dresses the character at the same moment; give that time to arrive
			task.delay(0.3, buildPreview)
		end
	end
end

function BagWindow.Toggle()
	Window.toggle(window)
end

function BagWindow.Start()
	window = Window.new("Inventory", "Inventory", WINDOW)
	local body = window.Body

	-- Coins, in the title's row
	local coin = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, -212, 0, 32),
		Size = UDim2.fromOffset(28, 28),
		BackgroundTransparency = 1,
		Parent = window.Root,
	})
	Theme.coin(coin)
	coinsText = Glass.text(window.Root, "0", 19, Glass.Font.Bold)
	coinsText.AnchorPoint = Vector2.new(0, 0.5)
	coinsText.Position = UDim2.new(1, -180, 0, 32)
	coinsText.Size = UDim2.fromOffset(110, 24)

	buildEquipment(body)
	buildCrafting(body)
	buildInfo(body)
	buildSlots(body)
	local howTo = if Theme.isPhone()
		then "Tap a stack to pick it up, then tap where it goes."
		else "Click a stack to pick it up. Right-click takes half. Shift-click sends it across."
	hint(howTo)

	-- What's in your hand follows the mouse
	floating = Theme.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(SLOT, SLOT),
		BackgroundTransparency = 1,
		ZIndex = 20,
		Visible = false,
		Parent = window.Gui,
	})
	floatingIcon = Theme.make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 20,
		Parent = floating,
	})
	floatingCount = Glass.worldText(floating, "", 17, Glass.Font.Bold)
	floatingCount.AnchorPoint = Vector2.new(1, 1)
	floatingCount.Position = UDim2.new(1, -4, 1, -2)
	floatingCount.Size = UDim2.new(1, 0, 0, 20)
	floatingCount.TextXAlignment = Enum.TextXAlignment.Right
	floatingCount.ZIndex = 21

	local camera = Instance.new("Camera")
	camera.FieldOfView = PREVIEW_FOV
	camera.Parent = preview
	preview.CurrentCamera = camera

	-- The character turns gently from side to side while the Bag is open
	local stepping: RBXScriptConnection? = nil
	window.OnOpen = function()
		hint(howTo)
		carried = nil
		cells = {}
		shownEquipped = equippedKey()
		buildPreview()
		render()
		local started = os.clock()
		stepping = RunService.RenderStepped:Connect(function()
			local frame = preview.AbsoluteSize
			local aspect = frame.X / math.max(frame.Y, 1)
			local studsTall =
				math.max(previewHeight / PREVIEW_HEIGHT_SHARE, PREVIEW_BODY_WIDTH / PREVIEW_WIDTH_SHARE / aspect)
			local distance = studsTall / 2 / math.tan(math.rad(PREVIEW_FOV / 2))
			local yaw = previewTurn + math.sin((os.clock() - started) * PREVIEW_SWAY_SPEED) * previewSway
			local focus = previewFocus + Vector3.new(0, PREVIEW_LOWER, 0)
			camera.CFrame = CFrame.lookAt(
				focus + Vector3.new(math.sin(yaw) * distance, distance * 0.05, -math.cos(yaw) * distance),
				focus
			)
			if carried then
				local mouse = UserInputService:GetMouseLocation()
				floating.Position = UDim2.fromOffset(mouse.X, mouse.Y)
			end
		end)
	end
	window.OnClose = function()
		if stepping then
			stepping:Disconnect()
			stepping = nil
		end
		-- All of it is still in your inventory: it just shows there again
		carried = nil
		cells = {}
		if state then
			render()
		end
	end

	-- The selected hotbar slot shows in here too
	Hotbar.OnChanged(function()
		if window.IsOpen and state then
			for index = 1, Inventory.Hotbar do
				Glass.setSelected(slots[index], index == Hotbar.Selected())
			end
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.B then
			Window.toggle(window)
		end
	end)
end

return BagWindow
