--!strict
-- Item icons, like Minecraft's inventory: block items show a little 3D block, tools and
-- crops show their pixel-art model (ReplicatedStorage.ItemModels), anything else shows
-- its emoji.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)

local ItemIcon = {}

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

function ItemIcon.create(parent: Instance, itemId: string, size: UDim2): GuiObject
	local item = Items[itemId]

	-- Tools and crops: their pixel-art model, filling the icon
	local models = ReplicatedStorage:FindFirstChild("ItemModels")
	local model = item and item.Model and models and models:FindFirstChild(item.Model)
	if model and model:IsA("BasePart") then
		local frame = viewport(parent, size)
		-- Light from the camera side (upper left), so the pixel faces we see are lit
		frame.Ambient = Color3.fromRGB(200, 200, 200)
		frame.LightDirection = Vector3.new(-0.5, -0.7, 1)
		local clone = model:Clone()
		-- Keep the mesh's own rotation, centered and turned toward the camera
		clone.CFrame = MODEL_TURN:Inverse() * model.CFrame.Rotation
		clone.Parent = frame
		local extents = halfExtents(clone)
		local radius = math.max(extents.X, extents.Y) * 1.08
		local distance = radius / math.tan(math.rad(FIELD_OF_VIEW / 2)) + extents.Z
		addCamera(frame, CFrame.lookAt(Vector3.new(0, 0, -distance), Vector3.zero))
		return frame
	end

	-- Blocks: a small isometric cube
	local blocks = ReplicatedStorage:FindFirstChild("Blocks")
	local template = item and item.Block and blocks and blocks:FindFirstChild(item.Block)
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
