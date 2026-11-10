--!strict
-- Item icons. Normally a pre-rendered picture cut from an icon sheet (Config.ItemIconSheets,
-- cells listed in ItemArt.luau, rendered by art/scripts/items3d.py; cell numbers run on from
-- one sheet to the next, PerSheet to a sheet). The shield and generated swords show their model,
-- and armour shows its own meshes put together as worn, in its tier's colours. Without one, block items show a
-- live 3D block, items with a model show that model, and anything else its emoji.
-- A block type that isn't an item (e.g. "CraftingTable") also works.
-- Swords and the Slaying World's items show models the server loads as it starts (Util/HeldModel,
-- Util/MonsterModels). An icon made before its model has arrived shows the plain picture, then swaps to the
-- model the moment it's there.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArmorArt = require(ReplicatedStorage.Shared.ArmorArt)
local Config = require(ReplicatedStorage.Shared.Config)
local Gear = require(ReplicatedStorage.Shared.Gear)
local ItemArt = require(ReplicatedStorage.Shared.ItemArt)
local Items = require(ReplicatedStorage.Shared.Items)
local MonsterArt = require(ReplicatedStorage.Shared.MonsterArt)
local Monsters = require(ReplicatedStorage.Shared.Monsters)
local Slivers = require(ReplicatedStorage.Shared.Slivers)
local SwordArt = require(ReplicatedStorage.Shared.SwordArt)

local ItemIcon = {}

-- Which generated model stands for each Slaying item: its monster for a spawner, its drop for a sliver, and the
-- drop's own (only those MonsterModels makes)
local MonsterIcons: { [string]: string } = {}
for _, monster in Monsters.List do
	MonsterIcons[monster.Spawner] = monster.Model
	MonsterIcons[monster.Drop] = monster.Drop
	local sliver = Slivers.ByOre[monster.Drop]
	if sliver then
		MonsterIcons[sliver.Item] = monster.Drop
	end
end
for name in MonsterArt do
	if Items[name] and not MonsterIcons[name] then
		MonsterIcons[name] = name
	end
end
for itemId, model in MonsterIcons do
	if not MonsterArt[model] then
		MonsterIcons[itemId] = nil
	end
end

local LATE_WAIT = 120 -- seconds an icon keeps waiting for its model to arrive
-- A sword lies corner to corner, its tip at the top right (the camera looks along +Z, so +X is the picture's left)
local SWORD_TIP = Vector3.new(-1, 1, 0)
-- Lying corner to corner, a sword's box is mostly empty at the sides of the blade: it can fill more of the picture
local SWORD_FILL = 0.86

local ICON_CELLS = ItemArt.Icons :: { [string]: number }

-- Isometric view from above-front-right
local BLOCK_CAMERA = CFrame.lookAt(Vector3.new(1, 0.82, 1).Unit * 10.5, Vector3.zero)
local FIELD_OF_VIEW = 30
-- Item models are seen from the front, turned a little so their pixel depth shows
local MODEL_TURN = CFrame.Angles(math.rad(-8), math.rad(22), 0)
-- Armour is seen from the front, turned a little so its sides and shoulders show; boots further, so their toes do
local ARMOR_TURN = CFrame.Angles(math.rad(8), math.rad(-25), 0)
local BOOTS_TURN = CFrame.Angles(math.rad(10), math.rad(-55), 0)

local function viewport(parent: Instance, size: UDim2): ViewportFrame
	local frame = Instance.new("ViewportFrame")
	frame.Size = size
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.BackgroundTransparency = 1
	frame.Ambient = Color3.fromRGB(170, 170, 170)
	frame.LightColor = Color3.new(1, 1, 1)
	frame.LightDirection = Vector3.new(-0.6, -1, -0.4)
	frame.Parent = parent
	return frame
end

local function addCamera(frame: ViewportFrame, cframe: CFrame)
	local camera = Instance.new("Camera")
	camera.FieldOfView = FIELD_OF_VIEW
	camera.CFrame = cframe
	camera.Parent = frame
	frame.CurrentCamera = camera
end

-- World-axis half extents of a part (correct for rotated parts)
local function halfExtents(part: BasePart): Vector3
	local cf, half = part.CFrame, part.Size / 2
	local x, y, z = cf.XVector, cf.YVector, cf.ZVector
	return Vector3.new(
		math.abs(x.X) * half.X + math.abs(y.X) * half.Y + math.abs(z.X) * half.Z,
		math.abs(x.Y) * half.X + math.abs(y.Y) * half.Y + math.abs(z.Y) * half.Z,
		math.abs(x.Z) * half.X + math.abs(y.Z) * half.Y + math.abs(z.Z) * half.Z
	)
end

-- A model seen from the front, centered, turned toward the camera and filling the icon. `turn` replaces the usual
-- turn (a sword's tilt), and `fill` how much of its box must fit (below 1, a little of the box's corners may go).
local function modelIcon(parent: Instance, model: BasePart, size: UDim2, turn: CFrame?, fill: number?): ViewportFrame
	local frame = viewport(parent, size)
	-- Light from the camera side (upper left), so the faces we see are lit
	frame.Ambient = Color3.fromRGB(200, 200, 200)
	frame.LightDirection = Vector3.new(-0.5, -0.7, 1)
	local clone = model:Clone()
	-- Keep the mesh's own rotation
	clone.CFrame = turn or MODEL_TURN:Inverse() * model.CFrame.Rotation
	clone.Parent = frame
	local extents = halfExtents(clone)
	local radius = math.max(extents.X, extents.Y) * (fill or 1.08)
	local distance = radius / math.tan(math.rad(FIELD_OF_VIEW / 2)) + extents.Z
	addCamera(frame, CFrame.lookAt(Vector3.new(0, 0, -distance), Vector3.zero))
	return frame
end

-- An armour item as it looks worn: every mesh of its slot (a chestplate is the coat, shoulders, sleeves and
-- forearms), placed as on the avatar it was modelled for, in its tier's colour sheet
local function armorIcon(parent: Instance, armor: Gear.Armor, size: UDim2): ViewportFrame
	local frame = viewport(parent, size)
	frame.Ambient = Color3.fromRGB(200, 200, 200)
	frame.LightDirection = Vector3.new(-0.5, -0.7, 1)
	-- Combat has no coat of its own yet: it wears Mining's, as on a body (Util/ArmorModels.luau)
	local set = ArmorArt.Sets[armor.Skill] or ArmorArt.Sets.Mining
	local palette = ArmorArt.Palettes[math.clamp(armor.Tier, 1, #ArmorArt.Palettes)]
	local turn = if armor.Slot == "Boots" then BOOTS_TURN else ARMOR_TURN
	local low, high = Vector3.one * math.huge, -Vector3.one * math.huge
	local pieces: { string } = ArmorArt.SlotPieces[armor.Slot] or {}
	for _, name in pieces do
		local art = set[name]
		if art then
			local part = Instance.new("Part")
			part.Anchored = true
			part.Size = Vector3.new(art.Size.X, art.Size.Z, art.Size.Y)
			part.CFrame = turn * CFrame.new(ArmorArt.BodyAt[name] + art.Centre) * ArmorArt.MeshTurn
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.FileMesh
			mesh.MeshId = art.Mesh
			mesh.TextureId = palette
			mesh.Scale = Vector3.one / ArmorArt.MeshScale
			mesh.Parent = part
			part.Parent = frame
			local extents = halfExtents(part)
			low = low:Min(part.Position - extents)
			high = high:Max(part.Position + extents)
		end
	end
	if low.X > high.X then
		return frame
	end
	local centre, extents = (low + high) / 2, (high - low) / 2
	-- A turned mesh's box is bigger than the mesh, so this fills the picture without cutting anything off
	local radius = math.max(extents.X, extents.Y) * 0.9
	local distance = radius / math.tan(math.rad(FIELD_OF_VIEW / 2)) + extents.Z
	addCamera(frame, CFrame.lookAt(centre - Vector3.new(0, 0, distance), centre))
	return frame
end

-- The plain picture: the icon sheet's, or an item's pixel-art model, a block, or its emoji
local function picture(parent: Instance, itemId: string, size: UDim2): GuiObject
	local item = Items[itemId]

	-- Pre-rendered picture from the icon sheet
	local cell = ICON_CELLS[itemId]
	local sheet = if cell then Config.ItemIconSheets[cell // ItemArt.PerSheet + 1] else nil
	if cell and sheet then
		local cellSize = ItemArt.CellSize
		local here = cell % ItemArt.PerSheet
		local image = Instance.new("ImageLabel")
		image.Size = size
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Position = UDim2.fromScale(0.5, 0.5)
		image.BackgroundTransparency = 1
		image.Image = sheet
		image.ImageRectSize = Vector2.new(cellSize, cellSize)
		image.ImageRectOffset = Vector2.new((here % ItemArt.Columns) * cellSize, (here // ItemArt.Columns) * cellSize)
		image.ScaleType = Enum.ScaleType.Fit
		image.Parent = parent
		return image
	end

	-- Tools and crops: their pixel-art model, filling the icon
	local models = ReplicatedStorage:FindFirstChild("ItemModels")
	local model = item and item.Model and models and models:FindFirstChild(item.Model)
	if model and model:IsA("BasePart") then
		return modelIcon(parent, model, size)
	end

	-- Blocks: a small isometric cube (for a block item, or a block type by name, such as
	-- the Crafting Table)
	local blocks = ReplicatedStorage:FindFirstChild("Blocks")
	local blockName = if item then item.Block else itemId
	local template = blockName and blocks and blocks:FindFirstChild(blockName)
	if template and template:IsA("BasePart") then
		local frame = viewport(parent, size)
		local block = template:Clone()
		block.CFrame = template.CFrame.Rotation
		block.Parent = frame
		addCamera(frame, BLOCK_CAMERA)
		return frame
	end

	local label = Instance.new("TextLabel")
	label.Size = size
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.BackgroundTransparency = 1
	label.Text = if item then item.Icon else "?"
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = parent
	return label
end

-- A model the server loads as it starts: shown now if it's there, otherwise the plain picture until it comes
type Draw = (parent: Instance, model: BasePart, size: UDim2) -> GuiObject

local function lateModel(
	parent: Instance,
	itemId: string,
	size: UDim2,
	folderName: string,
	name: string,
	draw: Draw
): GuiObject
	local folder = ReplicatedStorage:FindFirstChild(folderName)
	local model = folder and folder:FindFirstChild(name)
	if model and model:IsA("BasePart") then
		return draw(parent, model, size)
	end
	local holder = Instance.new("Frame")
	holder.Size = size
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.BackgroundTransparency = 1
	holder.Parent = parent
	local standIn = picture(holder, itemId, UDim2.fromScale(1, 1))
	task.spawn(function()
		local arrivedFolder = folder or ReplicatedStorage:WaitForChild(folderName, LATE_WAIT)
		local arrived = arrivedFolder and arrivedFolder:WaitForChild(name, LATE_WAIT)
		if arrived and arrived:IsA("BasePart") and holder.Parent then
			standIn:Destroy()
			draw(holder, arrived, UDim2.fromScale(1, 1))
		end
	end)
	return holder
end

function ItemIcon.create(parent: Instance, itemId: string, size: UDim2): GuiObject
	local shields = ReplicatedStorage:FindFirstChild("ShieldModels")
	local shield = shields and shields:FindFirstChild(itemId)
	if shield and shield:IsA("BasePart") then
		return modelIcon(parent, shield, size)
	end

	local armor = Gear.Armors[itemId]
	if armor then
		return armorIcon(parent, armor, size)
	end

	-- The generated swords, kits' too, tilted corner to corner
	local art = SwordArt.List[itemId]
	if art then
		return lateModel(parent, itemId, size, "SwordModels", itemId, function(holder, model, area)
			local base = MODEL_TURN:Inverse() * model.CFrame.Rotation
			local tip = base:VectorToWorldSpace(art.Up)
			local roll = math.atan2(SWORD_TIP.Y, SWORD_TIP.X) - math.atan2(tip.Y, tip.X)
			return modelIcon(holder, model, area, CFrame.Angles(0, 0, roll) * base, SWORD_FILL)
		end)
	end

	-- Drops, slivers and spawners from the Slaying World: their generated mesh
	local monster = MonsterIcons[itemId]
	if monster then
		return lateModel(parent, itemId, size, "MonsterModels", monster, modelIcon)
	end

	return picture(parent, itemId, size)
end

return ItemIcon
