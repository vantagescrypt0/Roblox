--!strict
-- Wooden sign boards with cream lettering in a blocky pixel font (Press Start 2P, to
-- match the block art), for the Town's shops and portals and the worlds' gateways and
-- zone signs.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Decor = require(script.Parent.Decor)
local Props = require(script.Parent.Props)

local SIZE = Blocks.Size
local PIXEL_FONT = Font.new("rbxasset://fonts/families/PressStart2P.json")

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
	label.FontFace = PIXEL_FONT
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(251, 238, 211)
	label.Text = text
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(46, 28, 15)
	stroke.Thickness = 4
	stroke.Parent = label
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0.2, 0)
	padding.PaddingBottom = UDim.new(0.2, 0)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = label
end

-- How tall a board is for its text: taller for two lines
local function boardHeight(text: string): number
	local lines = #string.split(text, "\n")
	return if lines > 1 then SIZE * 0.6 * lines else SIZE * 0.85
end

-- A plank sign `width` blocks wide, centered at `position`, readable from `front`. Text
-- can have two lines ("BIRCH GROVE\nWOODCUTTING 10").
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
	sign.Size = Vector3.new(width * SIZE, boardHeight(text), 0.4)
	sign.CFrame = CFrame.lookAt(position, position + front)
	sign.Color = Color3.fromRGB(162, 130, 78)
	sign.Material = Enum.Material.WoodPlanks
	sign.Anchored = true
	sign.Parent = parent
	Signs.Label(sign, text, front)
	return sign
end

-- A tall gateway people walk through: two log posts five blocks high, a beam across the
-- top and the sign hanging under it (readable from both sides, well above everyone's
-- heads), with a lantern on each end of the beam. (x, z) is the middle of the gateway;
-- its opening is `width` blocks wide, across `front` (+-x or +-z), the way the sign faces
-- people arriving. `set` places a block; `cell` gives a block's centre.
function Signs.Gateway(
	parent: Instance,
	set: (x: number, y: number, z: number, block: string) -> (),
	cell: (x: number, y: number, z: number) -> Vector3,
	x: number,
	z: number,
	front: Vector3,
	text: string,
	width: number
): Part
	local ax, az = math.round(-front.Z), math.round(front.X)
	local half = math.floor(width / 2) + 1
	for _, s in { -half, half } do
		for y = 1, 5 do
			set(x + ax * s, y, z + az * s, "Wood")
		end
		Decor.Lantern(parent, cell(x + ax * s, 6, z + az * s) + Vector3.new(0, SIZE / 2, 0), false, 20)
	end
	for s = -half, half do
		set(x + ax * s, 6, z + az * s, "DarkPlanks")
	end
	-- Hung just under the beam
	local under = cell(x, 5, z) + Vector3.new(0, SIZE / 2 - boardHeight(text) / 2 - 0.05, 0)
	local sign = Signs.Board(parent, "GatewaySign", text, under, front, width)
	Signs.Label(sign, text, -front)
	return sign
end

-- A sign on a tall post beside a path or field gate: the post stands on the cell
-- (x, y, z) and the board sits on top of it, well above head height
function Signs.Post(
	parent: Instance,
	set: (x: number, y: number, z: number, block: string) -> (),
	cell: (x: number, y: number, z: number) -> Vector3,
	x: number,
	y: number,
	z: number,
	front: Vector3,
	text: string,
	width: number
): Part
	for dy = 1, 4 do
		set(x, y + dy, z, "Wood")
	end
	local height = boardHeight(text)
	local at = cell(x, y + 4, z) + Vector3.new(0, SIZE / 2 + height / 2, 0)
	local sign = Signs.Board(parent, "PostSign", text, at, front, width)
	Signs.Label(sign, text, -front)
	return sign
end

return Signs
