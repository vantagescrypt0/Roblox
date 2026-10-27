--!strict
-- Wooden signs, lettered in a blocky pixel font (Press Start 2P, to match the block art).
-- Every sign reads from one side only. Styles:
--   Board     a neat plank with cream letters: the Town's shops, the portals, each world's
--             arrival gateway (Gateway)
--   Rustic    rough planks nailed a little crooked onto a post, letters burnt in: zone
--             signs and the odd field sign
--   Hanging   a rough board hung on two chains under a beam: the mine's entrance
--   Arrows    a post with pointed boards that point the way: path junctions
-- Rustic, Hanging and Arrows take a wood colour (Signs.Woods) so each zone's signs match
-- its trees.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Decor = require(script.Parent.Decor)
local Props = require(script.Parent.Props)

local SIZE = Blocks.Size
local PIXEL_FONT = Font.new("rbxasset://fonts/families/PressStart2P.json")
local CREAM = Color3.fromRGB(251, 238, 211)
local BURNT = Color3.fromRGB(46, 28, 16)
local CARVED = Color3.fromRGB(232, 204, 148) -- letters cut into dark wood
local IRON = Color3.fromRGB(46, 42, 40)

local Signs = {}

Signs.Woods = table.freeze({
	Oak = Color3.fromRGB(156, 120, 74),
	Birch = Color3.fromRGB(214, 200, 168),
	Spruce = Color3.fromRGB(110, 78, 48),
	Cherry = Color3.fromRGB(160, 92, 86),
	Dark = Color3.fromRGB(78, 54, 34),
	Sand = Color3.fromRGB(196, 160, 104),
})

-- Writes `text` on the face of `part` that points toward `front`. Without `ink` the
-- letters are cream with a dark outline; with it they're that colour, burnt or carved in.
function Signs.Label(part: BasePart, text: string, front: Vector3, ink: Color3?)
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
	label.TextColor3 = ink or CREAM
	label.Text = text
	label.Parent = gui
	if not ink then
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(46, 28, 15)
		stroke.Thickness = 4
		stroke.Parent = label
	end
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

-- The longest line's length in characters
local function longest(text: string): number
	local most = 0
	for _, line in string.split(text, "\n") do
		most = math.max(most, #line)
	end
	return most
end

-- Dark wood gets carved light letters, light wood burnt dark ones
local function inkFor(wood: Color3): Color3
	local _, _, value = wood:ToHSV()
	return if value < 0.45 then CARVED else BURNT
end

local function plank(parent: Instance, size: Vector3, cframe: CFrame, color: Color3): Part
	local p = Decor.Part(parent, "SignPlank", size, cframe, color, Enum.Material.WoodPlanks)
	p.CanCollide = false
	return p
end

-- A rough board: a few planks one above another, each a little off and a slightly
-- different shade, with nail heads, and a clear face in front carrying the letters.
-- `centre` faces its readers along -Z.
local function roughBoard(
	parent: Instance,
	centre: CFrame,
	width: number,
	height: number,
	wood: Color3,
	text: string,
	rng: Random
): Part
	local rows = math.max(2, #string.split(text, "\n") + 1)
	local rowHeight = height / rows
	for i = 1, rows do
		local y = -height / 2 + rowHeight * (i - 0.5)
		local tilt = CFrame.new(rng:NextNumber(-0.25, 0.25), y, 0)
			* CFrame.Angles(0, 0, math.rad(rng:NextNumber(-2.5, 2.5)))
		local shade = wood:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, 0.14))
		plank(parent, Vector3.new(width + rng:NextNumber(-0.3, 0.4), rowHeight - 0.05, 0.3), centre * tilt, shade)
	end
	for _, side in { -1, 1 } do
		for _, y in { -height / 2 + 0.3, height / 2 - 0.3 } do
			Decor.Part(
				parent,
				"Nail",
				Vector3.new(0.14, 0.14, 0.06),
				centre * CFrame.new(side * (width / 2 - 0.35), y, -0.17),
				IRON,
				Enum.Material.Metal
			).CanCollide =
				false
		end
	end
	local face = Decor.Part(
		parent,
		"SignFace",
		Vector3.new(width - 0.4, height - 0.1, 0.05),
		centre * CFrame.new(0, 0, -0.2),
		wood
	)
	face.Transparency = 1
	face.CanCollide = false
	Signs.Label(face, text, centre.LookVector, inkFor(wood))
	return face
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
-- top and the sign hanging under it (well above everyone's heads, facing the people
-- arriving), with a lantern on each end of the beam. (x, z) is the middle of the gateway;
-- its opening is `width` blocks wide, across `front` (+-x or +-z). `set` places a block;
-- `cell` gives a block's centre.
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
	return Signs.Board(parent, "GatewaySign", text, under, front, width)
end

-- A rough sign nailed to a leaning post standing on `ground` (the top of a block), its
-- board above head height, readable from `front`
function Signs.Rustic(parent: Instance, ground: Vector3, front: Vector3, text: string, wood: Color3?): Part
	local color = wood or Signs.Woods.Oak
	local rng = Random.new(math.floor(ground.X * 7 + ground.Z * 13))
	local lines = #string.split(text, "\n")
	local width = math.clamp(longest(text) * 0.8 + 2, 5, 13)
	local height = 1.45 * lines + 0.8
	local lean =
		CFrame.Angles(math.rad(rng:NextNumber(-4, 4)), math.rad(rng:NextNumber(-8, 8)), math.rad(rng:NextNumber(-5, 5)))
	local base = CFrame.lookAt(ground, ground + front) * lean
	plank(parent, Vector3.new(0.6, 7.5, 0.6), base * CFrame.new(0, 3.5, 0.45), color:Lerp(Color3.new(0, 0, 0), 0.3))
	return roughBoard(parent, base * CFrame.new(0, 6.2 + height / 2, 0), width, height, color, text, rng)
end

-- A rough board hanging on two chains below `under` (the underside of a beam), readable
-- from `front`. `scale` makes it bigger for a wide opening
function Signs.Hanging(
	parent: Instance,
	under: Vector3,
	front: Vector3,
	text: string,
	wood: Color3?,
	scale: number?
): Part
	local color = wood or Signs.Woods.Dark
	local rng = Random.new(math.floor(under.X * 5 + under.Z * 11))
	local s = scale or 1
	local width = math.clamp(longest(text) * 0.75 + 2, 4, 12) * s
	local height = 1.5 * s
	local drop = 1.2
	local top = CFrame.lookAt(under, under + front)
	for _, side in { -1, 1 } do
		Decor.Part(
			parent,
			"Chain",
			Vector3.new(0.12, drop, 0.12),
			top * CFrame.new(side * (width / 2 - 0.6), -drop / 2, 0),
			IRON,
			Enum.Material.Metal
		).CanCollide =
			false
	end
	local swing = CFrame.Angles(0, 0, math.rad(rng:NextNumber(-3, 3)))
	return roughBoard(parent, top * CFrame.new(0, -drop - height / 2, 0) * swing, width, height, color, text, rng)
end

-- A signpost on `ground` (the top of a block) with a pointed board for each place, pointing
-- toward it ({ Text, Toward }). `reader` points from the post toward where people read it
-- from; each board's letters face that way. Boards pointing straight at or away from
-- readers are turned a little, so they don't show their edge.
function Signs.Arrows(
	parent: Instance,
	ground: Vector3,
	reader: Vector3,
	arrows: { { Text: string, Toward: Vector3 } },
	wood: Color3?
)
	local color = wood or Signs.Woods.Oak
	local rng = Random.new(math.floor(ground.X * 3 + ground.Z * 17))
	local flatReader = (reader * Vector3.new(1, 0, 1)).Unit
	local postHeight = 7.6 + #arrows * 1.9
	plank(
		parent,
		Vector3.new(0.6, postHeight, 0.6),
		CFrame.new(ground + Vector3.new(0, postHeight / 2, 0)) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 90)), 0),
		color:Lerp(Color3.new(0, 0, 0), 0.3)
	)
	for i, arrow in arrows do
		local dir = (arrow.Toward * Vector3.new(1, 0, 1)).Unit
		if math.abs(dir:Dot(flatReader)) > 0.8 then
			dir = (CFrame.Angles(0, math.rad(40), 0)):VectorToWorldSpace(dir)
		end
		local length = math.clamp(#arrow.Text * 0.85 + 2.6, 6, 15)
		local height = postHeight - 1.1 - (i - 1) * 1.9
		local centre = ground + Vector3.new(0, height, 0) + dir * (length / 2 + 0.2)
		local frame = CFrame.lookAt(centre, centre + dir)
			* CFrame.Angles(0, 0, math.rad(rng:NextNumber(-3, 3)))
			* CFrame.Angles(math.rad(rng:NextNumber(-2, 2)), 0, 0)
		local shade = color:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, 0.12))
		local board = plank(parent, Vector3.new(0.3, 1.6, length), frame, shade)
		-- A diamond at the far end, half of it sticking out: the arrow's point
		plank(
			parent,
			Vector3.new(0.3, 1.13, 1.13),
			frame * CFrame.new(0, 0, -length / 2) * CFrame.Angles(math.rad(45), 0, 0),
			shade
		)
		local side = if frame.RightVector:Dot(flatReader) >= 0 then frame.RightVector else -frame.RightVector
		Signs.Label(board, arrow.Text, side, inkFor(color))
	end
end

return Signs
