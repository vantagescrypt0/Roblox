--!strict
-- Item icons. Normally a pre-rendered picture cut from an icon sheet (Config.ItemIconSheets,
-- cells listed in ItemArt.luau, rendered by art/scripts/items3d.py; cell numbers run on from
-- one sheet to the next, PerSheet to a sheet). The shield and generated swords show their model
-- and armor pieces their slot's picture in their tier's colour. Without one, block items show a live 3D
-- block, items with a model show that model, and anything else its emoji.
-- A block type that isn't an item (e.g. "CraftingTable") also works.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Gear = require(ReplicatedStorage.Shared.Gear)
local ItemArt = require(ReplicatedStorage.Shared.ItemArt)
local Items = require(ReplicatedStorage.Shared.Items)
local Monsters = require(ReplicatedStorage.Shared.Monsters)
local Slivers = require(ReplicatedStorage.Shared.Slivers)

local ItemIcon = {}

-- Which generated model stands for each Slaying item: its monster for a spawner, its drop for a sliver
local MonsterIcons: { [string]: string } = {}
for _, monster in Monsters.List do
	MonsterIcons[monster.Spawner] = monster.Model
	local sliver = Slivers.ByOre[monster.Drop]
	if sliver then
		MonsterIcons[sliver.Item] = monster.Drop
	end
end

local ICON_CELLS = ItemArt.Icons :: { [string]: number }

-- Isometric view from above-front-right
local BLOCK_CAMERA = CFrame.lookAt(Vector3.new(1, 0.82, 1).Unit * 10.5, Vector3.zero)
local FIELD_OF_VIEW = 30
-- Item models are seen from the front, turned a little so their pixel depth shows
local MODEL_TURN = CFrame.Angles(math.rad(-8), math.rad(22), 0)

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

-- A model seen from the front, centered, turned toward the camera and filling the icon
local function modelIcon(parent: Instance, model: BasePart, size: UDim2): ViewportFrame
	local frame = viewport(parent, size)
	-- Light from the camera side (upper left), so the faces we see are lit
	frame.Ambient = Color3.fromRGB(200, 200, 200)
	frame.LightDirection = Vector3.new(-0.5, -0.7, 1)
	local clone = model:Clone()
	-- Keep the mesh's own rotation
	clone.CFrame = MODEL_TURN:Inverse() * model.CFrame.Rotation
	clone.Parent = frame
	local extents = halfExtents(clone)
	local radius = math.max(extents.X, extents.Y) * 1.08
	local distance = radius / math.tan(math.rad(FIELD_OF_VIEW / 2)) + extents.Z
	addCamera(frame, CFrame.lookAt(Vector3.new(0, 0, -distance), Vector3.zero))
	return frame
end

function ItemIcon.create(parent: Instance, itemId: string, size: UDim2): GuiObject
	local item = Items[itemId]

	local shields = ReplicatedStorage:FindFirstChild("ShieldModels")
	local shield = shields and shields:FindFirstChild(itemId)
	if shield and shield:IsA("BasePart") then
		return modelIcon(parent, shield, size)
	end

	local swords = ReplicatedStorage:FindFirstChild("SwordModels")
	local sword = swords and swords:FindFirstChild(itemId)
	if sword and sword:IsA("BasePart") then
		return modelIcon(parent, sword, size)
	end

	local armor = Gear.Armors[itemId]
	local slotIcon = armor and Config.SlotIcons[armor.Slot]
	if armor and slotIcon then
		local image = Instance.new("ImageLabel")
		image.Size = size
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Position = UDim2.fromScale(0.5, 0.5)
		image.BackgroundTransparency = 1
		image.Image = slotIcon
		image.ImageColor3 = Gear.TierColors[armor.Tier]
		image.ScaleType = Enum.ScaleType.Fit
		image.Parent = parent
		return image
	end

	-- Drops, slivers and spawners from the Slaying World: their generated mesh
	local monsterModels = ReplicatedStorage:FindFirstChild("MonsterModels")
	local monsterModel = monsterModels and monsterModels:FindFirstChild(MonsterIcons[itemId] or itemId)
	if monsterModel and monsterModel:IsA("BasePart") then
		return modelIcon(parent, monsterModel, size)
	end

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

return ItemIcon
