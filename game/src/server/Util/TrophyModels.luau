--!strict
-- The trophy blocks' look (Gear.luau), built in code when a server starts and put in
-- ReplicatedStorage.Blocks next to the block meshes, so islands draw them like any block and
-- the client shows them in icons. Each is an invisible block-sized part (what you aim at
-- and stand on) carrying a stone plinth, a golden cup, a nameplate and a little copy of what
-- it's for, all welded to it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Gear = require(ReplicatedStorage.Shared.Gear)
local Items = require(ReplicatedStorage.Shared.Items)

local SIZE = Blocks.Size
local GOLD = Color3.fromRGB(240, 192, 64)
local GOLD_DARK = Color3.fromRGB(196, 146, 36)
local STONE = Color3.fromRGB(176, 172, 164)

local TrophyModels = {}

-- A Weld keeps its offset from the root even when a copy of the trophy is moved before it's
-- in the world (a WeldConstraint would leave the pieces behind)
local function weld(root: BasePart, part: BasePart)
	local joint = Instance.new("Weld")
	joint.Part0 = root
	joint.Part1 = part
	joint.C0 = root.CFrame:ToObjectSpace(part.CFrame)
	joint.Parent = part
end

local function piece(
	root: BasePart,
	name: string,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	material: Enum.Material?
)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = root.CFrame * offset
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Parent = root
	weld(root, part)
	return part
end

-- A little copy of the thing the trophy is for, on the cup: its item's model, or its block
local function emblem(root: BasePart, trophy: Gear.Trophy)
	local blocks = ReplicatedStorage:FindFirstChild("Blocks")
	local models = ReplicatedStorage:FindFirstChild("ItemModels")
	local item = Items[trophy.Resource]
	local source: Instance? = if item and item.Model and models then models:FindFirstChild(item.Model) else nil
	if not source and blocks then
		source = blocks:FindFirstChild(trophy.Resource)
	end
	if not source or not source:IsA("BasePart") then
		piece(root, "Emblem", Vector3.one * 0.9, CFrame.new(0, 1.15, 0), GOLD, Enum.Material.Foil)
		return
	end
	local copy = source:Clone()
	for _, child in copy:GetChildren() do
		if not child:IsA("SpecialMesh") and not child:IsA("SurfaceAppearance") then
			child:Destroy()
		end
	end
	-- Shrink it to about a block's third, keeping its proportions
	local longest = math.max(copy.Size.X, copy.Size.Y, copy.Size.Z)
	copy.Size = copy.Size * (1.1 / longest)
	copy.CFrame = root.CFrame * CFrame.new(0, 1.2, 0) * source.CFrame.Rotation
	copy.Anchored = false
	copy.Massless = true
	copy.CanCollide = false
	copy.CanQuery = false
	copy.CanTouch = false
	copy.Name = "Emblem"
	copy.Parent = root
	weld(root, copy)
end

local function build(trophy: Gear.Trophy): Part
	local root = Instance.new("Part")
	root.Name = trophy.Block
	root.Size = Vector3.one * SIZE
	root.CFrame = CFrame.new()
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = true
	-- Stone plinth, gold band, the cup on a stem, two handles
	piece(root, "Plinth", Vector3.new(2.6, 0.7, 2.6), CFrame.new(0, -1.15, 0), STONE, Enum.Material.Slate)
	piece(root, "Band", Vector3.new(2.2, 0.25, 2.2), CFrame.new(0, -0.68, 0), GOLD_DARK, Enum.Material.Foil)
	piece(root, "Foot", Vector3.new(1.3, 0.25, 1.3), CFrame.new(0, -0.43, 0), GOLD, Enum.Material.Foil)
	piece(root, "Stem", Vector3.new(0.4, 0.6, 0.4), CFrame.new(0, -0.05, 0), GOLD, Enum.Material.Foil)
	local cup = piece(
		root,
		"Cup",
		Vector3.new(0.9, 1.5, 1.5),
		CFrame.new(0, 0.55, 0) * CFrame.Angles(0, 0, math.pi / 2),
		GOLD,
		Enum.Material.Foil
	)
	cup.Shape = Enum.PartType.Cylinder
	for _, side in { -1, 1 } do
		piece(
			root,
			"Handle",
			Vector3.new(0.25, 0.7, 0.25),
			CFrame.new(side * 0.9, 0.6, 0),
			GOLD_DARK,
			Enum.Material.Foil
		)
	end
	emblem(root, trophy)
	-- The nameplate on the plinth's front, readable from every side
	local plate =
		piece(root, "Plate", Vector3.new(2.62, 0.5, 2.62), CFrame.new(0, -1.15, 0), STONE, Enum.Material.Slate)
	plate.Transparency = 1
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.CanvasSize = Vector2.new(260, 50)
		gui.LightInfluence = 0
		gui.Parent = plate
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = string.upper(trophy.Name)
		label.TextScaled = true
		label.FontFace = Font.fromEnum(Enum.Font.Arcade)
		label.TextColor3 = GOLD
		label.Parent = gui
	end
	return root
end

-- Puts every trophy's look in ReplicatedStorage.Blocks (once per server)
function TrophyModels.Make()
	local blocks = ReplicatedStorage:FindFirstChild("Blocks")
	if not blocks then
		return
	end
	for _, trophy in Gear.TrophyList do
		if not blocks:FindFirstChild(trophy.Block) then
			build(trophy).Parent = blocks
		end
	end
end

return TrophyModels
