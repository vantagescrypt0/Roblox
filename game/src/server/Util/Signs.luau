--!strict
-- Wooden sign boards with cream lettering in Fondamento (the UI's title font), for the
-- Town's stalls and portals and the worlds' welcome signs.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Props = require(script.Parent.Props)

local SIZE = Blocks.Size

local Signs = {}

-- Writes `text` on the face of `part` that points toward `front`
function Signs.Label(part: BasePart, text: string, front: Vector3)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Props.FaceToward(part, front)
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.FontFace = Font.fromEnum(Enum.Font.Fondamento)
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(251, 238, 211)
	label.Text = text
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(46, 28, 15)
	stroke.Thickness = 3
	stroke.Parent = label
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.12, 0)
	padding.PaddingBottom = UDim.new(0.12, 0)
	padding.Parent = label
end

-- A plank sign `width` blocks wide, centered at `position`, readable from `front`
function Signs.Board(
	parent: Instance,
	name: string,
	text: string,
	position: Vector3,
	front: Vector3,
	width: number
): Part
	local sign = Instance.new("Part")
	sign.Name = name
	sign.Size = Vector3.new(width * SIZE, SIZE * 0.85, 0.4)
	sign.CFrame = CFrame.lookAt(position, position + front)
	sign.Color = Color3.fromRGB(162, 130, 78)
	sign.Material = Enum.Material.WoodPlanks
	sign.Anchored = true
	sign.Parent = parent
	Signs.Label(sign, text, front)
	return sign
end

return Signs
