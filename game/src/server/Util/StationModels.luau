--!strict
-- The crafting stations that aren't block-shaped, built in code when a server starts and
-- put in ReplicatedStorage.Blocks next to the block meshes (like the trophies), so islands
-- draw them like any block and icons show them. Each is an invisible block-sized part (what
-- you aim at and stand on) with its pieces welded to it:
--   Anvil      an oak stump, a dark iron anvil with its horn, a hammer resting on top
--   GemBench   a plank workbench with a stone grinding wheel and gems waiting to be cut

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)

local SIZE = Blocks.Size
local IRON = Color3.fromRGB(62, 64, 72)
local IRON_FACE = Color3.fromRGB(104, 106, 116)
local HANDLE = Color3.fromRGB(150, 110, 64)
local WHEEL = Color3.fromRGB(150, 146, 138)
local AMETHYST = Color3.fromRGB(168, 96, 230)
local SAPPHIRE = Color3.fromRGB(60, 110, 235)

local StationModels = {}

-- A Weld keeps its offset from the root even when a copy is moved before it's in the world
local function weld(root: BasePart, part: BasePart)
	local joint = Instance.new("Weld")
	joint.Part0 = root
	joint.Part1 = part
	joint.C0 = root.CFrame:ToObjectSpace(part.CFrame)
	joint.Parent = part
end

local function settle(root: BasePart, part: BasePart, name: string)
	part.Name = name
	part.Anchored = false
	part.Massless = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Parent = root
	weld(root, part)
end

local function piece(
	root: BasePart,
	name: string,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	material: Enum.Material?,
	kind: string?
): BasePart
	local part: BasePart = if kind == "Wedge" then Instance.new("WedgePart") else Instance.new("Part")
	part.Size = size
	part.CFrame = root.CFrame * offset
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	settle(root, part, name)
	return part
end

-- A resized copy of a block's art (the stump keeps the oak log's bark), or a plain part
local function blockPiece(root: BasePart, name: string, blockType: string, size: Vector3, offset: CFrame)
	local folder = ReplicatedStorage:FindFirstChild("Blocks")
	local template = folder and folder:FindFirstChild(blockType)
	if not template or not template:IsA("BasePart") then
		piece(root, name, size, offset, HANDLE)
		return
	end
	local copy = template:Clone()
	for _, child in copy:GetChildren() do
		if not child:IsA("SpecialMesh") and not child:IsA("SurfaceAppearance") then
			child:Destroy()
		end
	end
	-- The mesh carries its own rotation: size it in its own axes
	local rotation = template.CFrame.Rotation
	local localSize = rotation:VectorToObjectSpace(size)
	copy.Size = Vector3.new(math.abs(localSize.X), math.abs(localSize.Y), math.abs(localSize.Z))
	copy.CFrame = root.CFrame * offset * rotation
	settle(root, copy, name)
end

local function rootPart(name: string): Part
	local root = Instance.new("Part")
	root.Name = name
	root.Size = Vector3.one * SIZE
	root.CFrame = CFrame.new()
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = true
	return root
end

local function anvil(): Part
	local root = rootPart("Anvil")
	-- An oak stump on the cell's floor, the anvil standing on it
	blockPiece(root, "Stump", "Wood", Vector3.new(2.3, 1.1, 2.3), CFrame.new(0, -0.95, 0))
	piece(root, "Foot", Vector3.new(1.9, 0.35, 1.3), CFrame.new(0, -0.22, 0), IRON, Enum.Material.Metal)
	piece(root, "Waist", Vector3.new(0.9, 0.5, 0.65), CFrame.new(0, 0.2, 0), IRON, Enum.Material.Metal)
	piece(root, "Body", Vector3.new(1.9, 0.5, 1.0), CFrame.new(0, 0.7, 0), IRON, Enum.Material.Metal)
	piece(root, "Face", Vector3.new(1.86, 0.08, 0.96), CFrame.new(0, 0.97, 0), IRON_FACE, Enum.Material.Metal)
	-- The horn: a wedge off one end, thick at the body, thin at the tip
	piece(
		root,
		"Horn",
		Vector3.new(0.8, 0.5, 0.55),
		CFrame.new(1.22, 0.7, 0) * CFrame.Angles(0, -math.pi / 2, 0),
		IRON,
		Enum.Material.Metal,
		"Wedge"
	)
	-- A hammer resting across the face
	piece(
		root,
		"HammerHandle",
		Vector3.new(0.14, 0.14, 1.1),
		CFrame.new(-0.35, 1.08, 0.05) * CFrame.Angles(0, math.rad(25), 0),
		HANDLE
	)
	piece(
		root,
		"HammerHead",
		Vector3.new(0.42, 0.26, 0.26),
		CFrame.new(-0.35, 1.08, 0.05) * CFrame.Angles(0, math.rad(25), 0) * CFrame.new(0, 0.02, -0.5),
		IRON_FACE,
		Enum.Material.Metal
	)
	return root
end

local function gemBench(): Part
	local root = rootPart("GemBench")
	-- A plank top on four oak legs
	blockPiece(root, "Top", "Planks", Vector3.new(2.9, 0.35, 2.0), CFrame.new(0, 0.025, 0))
	for _, x in { -1.2, 1.2 } do
		for _, z in { -0.75, 0.75 } do
			blockPiece(root, "Leg", "Wood", Vector3.new(0.35, 1.35, 0.35), CFrame.new(x, -0.825, z))
		end
	end
	-- The grinding wheel standing in a frame at one end (a cylinder's axis is its X)
	local wheel =
		piece(root, "Wheel", Vector3.new(0.3, 1.1, 1.1), CFrame.new(0.85, 0.85, 0), WHEEL, Enum.Material.Slate) :: Part
	wheel.Shape = Enum.PartType.Cylinder
	piece(root, "Axle", Vector3.new(0.6, 0.12, 0.12), CFrame.new(0.85, 0.85, 0), IRON, Enum.Material.Metal)
	for _, x in { 0.6, 1.1 } do
		piece(root, "Frame", Vector3.new(0.1, 0.8, 0.12), CFrame.new(x, 0.6, 0), HANDLE)
	end
	-- Gems waiting to be cut, and one already cut
	piece(
		root,
		"Gem",
		Vector3.new(0.35, 0.35, 0.35),
		CFrame.new(-0.7, 0.47, -0.35) * CFrame.Angles(0.4, 0.6, 0.2),
		AMETHYST,
		Enum.Material.Glass
	).Transparency =
		0.15
	piece(
		root,
		"Gem",
		Vector3.new(0.3, 0.3, 0.3),
		CFrame.new(-0.25, 0.45, 0.4) * CFrame.Angles(0.7, 0.2, 0.5),
		SAPPHIRE,
		Enum.Material.Glass
	).Transparency =
		0.15
	piece(
		root,
		"CutGem",
		Vector3.new(0.3, 0.18, 0.3),
		CFrame.new(-0.95, 0.38, 0.45) * CFrame.Angles(0, math.rad(45), 0),
		AMETHYST,
		Enum.Material.Neon
	)
	return root
end

-- Puts each station's look in ReplicatedStorage.Blocks (once per server)
function StationModels.Make()
	local blocks = ReplicatedStorage:FindFirstChild("Blocks")
	if not blocks then
		return
	end
	local builders: { [string]: () -> Part } = { Anvil = anvil, GemBench = gemBench }
	for name, build in builders do
		if not blocks:FindFirstChild(name) then
			build().Parent = blocks
		end
	end
end

return StationModels
