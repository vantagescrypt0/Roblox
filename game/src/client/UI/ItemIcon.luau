--!strict
-- Item icons. Block items show a little 3D block (like Minecraft's inventory);
-- everything else shows its emoji.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)

local ItemIcon = {}

-- Isometric view from above-front-right
local CAMERA_CFRAME = CFrame.lookAt(Vector3.new(1, 0.82, 1).Unit * 10.5, Vector3.zero)

function ItemIcon.create(parent: Instance, itemId: string, size: UDim2): GuiObject
	local item = Items[itemId]
	local blocks = ReplicatedStorage:FindFirstChild("Blocks")
	local template = item and item.Block and blocks and blocks:FindFirstChild(item.Block)
	if template and template:IsA("BasePart") then
		local viewport = Instance.new("ViewportFrame")
		viewport.Size = size
		viewport.AnchorPoint = Vector2.new(0.5, 0.5)
		viewport.Position = UDim2.fromScale(0.5, 0.5)
		viewport.BackgroundTransparency = 1
		viewport.Ambient = Color3.fromRGB(170, 170, 170)
		viewport.LightColor = Color3.new(1, 1, 1)
		viewport.LightDirection = Vector3.new(-0.6, -1, -0.4)
		local block = template:Clone()
		block.CFrame = template.CFrame.Rotation
		block.Parent = viewport
		local camera = Instance.new("Camera")
		camera.FieldOfView = 30
		camera.CFrame = CAMERA_CFRAME
		camera.Parent = viewport
		viewport.CurrentCamera = camera
		viewport.Parent = parent
		return viewport
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
