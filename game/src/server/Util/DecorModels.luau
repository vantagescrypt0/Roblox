--!strict
-- Puts decoration models (art/scripts/decor.py, in ReplicatedStorage.DecorModels) in the world. A
-- model is one mesh with any others as its children, each sitting where it belongs around the
-- model's origin at the middle of the world, so it goes wherever `frame` says with its pieces
-- still together.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DecorArt = require(ReplicatedStorage.Shared.DecorArt)

export type Options = {
	Scale: Vector3?, -- along the model's own axes, moving its pieces to match
	Tint: Color3?, -- the colour of its cloth or petals
	Material: Enum.Material?, -- of a model that's only a coloured shape
	Collide: boolean?,
	Query: boolean?, -- can be aimed at
	Light: { Range: number, Brightness: number }?,
}

local DecorModels = {}

local LIGHT = Color3.fromRGB(255, 206, 140)
local GLOW = Color3.fromRGB(255, 214, 128)

local standIns: { [string]: BasePart } = {}

-- Only for testing a build that hasn't got the meshes: a plain box of the right size
local function standIn(name: string): BasePart
	local known = standIns[name]
	if known then
		return known
	end
	warn(`[DecorModels] no mesh for {name}: using a plain box`)
	local function box(artName: string): Part
		local art = DecorArt[artName]
		local p = Instance.new("Part")
		p.Size = if art then art.Size else Vector3.one
		p.CFrame = CFrame.new(if art then art.Center else Vector3.zero)
		p.Color = Color3.fromRGB(150, 130, 110)
		return p
	end
	local root = box(name)
	root.Name = name
	for artName in DecorArt do
		local childName = string.match(artName, `^{name}__(%w+)$`)
		if childName then
			local child = box(artName)
			child.Name = childName
			child.Parent = root
		end
	end
	standIns[name] = root
	return root
end

function DecorModels.Get(name: string): BasePart
	local folder = ReplicatedStorage:FindFirstChild("DecorModels")
	local template = folder and folder:FindFirstChild(name)
	return if template and template:IsA("BasePart") then template else standIn(name)
end

-- A warm light in a lit piece
function DecorModels.Light(part: BasePart, range: number, brightness: number)
	local light = Instance.new("PointLight")
	light.Color = LIGHT
	light.Range = range
	light.Brightness = brightness
	light.Shadows = true
	light.Parent = part
end

-- Where a piece goes and how big it is, scaled along the model's own axes
local function fit(part: BasePart, template: BasePart, frame: CFrame, scale: Vector3?)
	local at = template.CFrame
	if scale then
		local inMesh = at.Rotation:VectorToObjectSpace(scale)
		part.Size = template.Size * Vector3.new(math.abs(inMesh.X), math.abs(inMesh.Y), math.abs(inMesh.Z))
		at = CFrame.new(at.Position * scale) * at.Rotation
	end
	part.CFrame = frame * at
end

-- Puts a copy of the model where `frame` says, and returns its main part. Its children are
-- named by what they are: "Glow" is lit, "Tint" takes the Tint.
function DecorModels.Place(parent: Instance, name: string, frame: CFrame, options: Options?): BasePart
	local given: Options = options or {}
	local template = DecorModels.Get(name)
	local root = template:Clone()
	root.Name = name
	root.Anchored = true
	root.CanCollide = given.Collide == true
	root.CanQuery = given.Query == true
	root.CanTouch = false
	fit(root, template, frame, given.Scale)
	if given.Tint then
		-- A model that's only a coloured shape has no children to take the colour
		root.Color = given.Tint
	end
	if given.Material then
		root.Material = given.Material
	end
	for _, child in root:GetChildren() do
		if child:IsA("BasePart") then
			local source = template:FindFirstChild(child.Name)
			if source and source:IsA("BasePart") then
				fit(child, source, frame, given.Scale)
			end
			child.Anchored = true
			child.CanCollide = false
			child.CanQuery = false
			child.CanTouch = false
			if child.Name == "Tint" and given.Tint then
				child.Color = given.Tint
			elseif child.Name == "Glow" then
				child.Color = GLOW
				child.Material = Enum.Material.Neon
				if given.Light then
					DecorModels.Light(child, given.Light.Range, given.Light.Brightness)
				end
			end
		end
	end
	root.Parent = parent
	return root
end

return DecorModels
