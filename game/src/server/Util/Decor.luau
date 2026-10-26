--!strict
-- Scenery that isn't whole blocks: lanterns, fences, benches, flowers and tall grass,
-- water, fountain jets, chimney smoke, banners, mine rails and carts, awnings. Wooden
-- and stone pieces are resized copies of the block art (ReplicatedStorage.Blocks), so
-- they keep the pixel look. Nothing here can be clicked or mined: everything is
-- anchored, and it goes in a folder outside the block world so it never gets in the way
-- of aiming at blocks.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)

local SIZE = Blocks.Size
local IRON = Color3.fromRGB(46, 42, 40)
local GLOW = Color3.fromRGB(255, 214, 128)

local Decor = {}

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = true
	p.CanQuery = false
	p.Parent = parent
	return p
end
Decor.Part = part

-- A resized copy of a block's art (posts, rails, planks, slabs...)
function Decor.Piece(parent: Instance, blockType: string, size: Vector3, cframe: CFrame): BasePart
	local folder = ReplicatedStorage:FindFirstChild("Blocks")
	local template = folder and folder:FindFirstChild(blockType)
	local piece: BasePart
	if template and template:IsA("BasePart") then
		piece = template:Clone()
		-- The mesh carries its own rotation: size it in its own axes
		local rotation = template.CFrame.Rotation
		local localSize = rotation:VectorToObjectSpace(size)
		piece.Size = Vector3.new(math.abs(localSize.X), math.abs(localSize.Y), math.abs(localSize.Z))
		piece.CFrame = cframe * rotation
	else
		piece = part(parent, blockType, size, cframe, Color3.fromRGB(150, 120, 80))
	end
	piece.Name = blockType .. "Piece"
	piece.Anchored = true
	piece.CanQuery = false
	piece.Parent = parent
	return piece
end

local function light(parent: Instance, range: number, brightness: number)
	local pointLight = Instance.new("PointLight")
	pointLight.Color = Color3.fromRGB(255, 206, 140)
	pointLight.Range = range
	pointLight.Brightness = brightness
	pointLight.Shadows = true
	pointLight.Parent = parent
end

-- An iron lantern standing on `bottom` (or hanging from a short chain above it)
function Decor.Lantern(parent: Instance, bottom: Vector3, hanging: boolean?, range: number?): BasePart
	local base = CFrame.new(bottom)
	part(parent, "LanternBase", Vector3.new(1.2, 0.25, 1.2), base * CFrame.new(0, 0.125, 0), IRON, Enum.Material.Metal)
	local glass =
		part(parent, "Lantern", Vector3.new(0.85, 1, 0.85), base * CFrame.new(0, 0.75, 0), GLOW, Enum.Material.Neon)
	part(parent, "LanternCap", Vector3.new(1.3, 0.3, 1.3), base * CFrame.new(0, 1.4, 0), IRON, Enum.Material.Metal)
	part(parent, "LanternTop", Vector3.new(0.5, 0.3, 0.5), base * CFrame.new(0, 1.7, 0), IRON, Enum.Material.Metal)
	if hanging then
		part(parent, "Chain", Vector3.new(0.15, 1.2, 0.15), base * CFrame.new(0, 2.45, 0), IRON, Enum.Material.Metal)
	end
	light(glass, range or 18, 1.2)
	return glass
end

-- A lantern on a bracket sticking out of a wall: `at` is a point on the wall's face,
-- `out` points away from the wall
function Decor.WallLantern(parent: Instance, at: Vector3, out: Vector3)
	local frame = CFrame.lookAt(at, at + out)
	part(parent, "Bracket", Vector3.new(0.25, 0.25, 1.4), frame * CFrame.new(0, 0.4, -0.7), IRON, Enum.Material.Metal)
	Decor.Lantern(parent, (frame * CFrame.new(0, -1.2, -1.3)).Position, true, 16)
end

-- A small flower: a stem and a bloom, standing on `top` (the top of a block)
function Decor.Flower(parent: Instance, top: Vector3, color: Color3)
	local base = CFrame.new(top)
	part(parent, "Stem", Vector3.new(0.18, 0.9, 0.18), base * CFrame.new(0, 0.45, 0), Color3.fromRGB(66, 132, 52))
	part(parent, "Bloom", Vector3.new(0.5, 0.4, 0.5), base * CFrame.new(0, 1.05, 0), color)
	part(parent, "Centre", Vector3.new(0.22, 0.22, 0.22), base * CFrame.new(0, 1.3, 0), Color3.fromRGB(250, 226, 110))
end

-- A tuft of tall grass: three thin blades
function Decor.Grass(parent: Instance, top: Vector3, rng: Random)
	for i = 1, 3 do
		local height = rng:NextNumber(0.8, 1.5)
		local offset = Vector3.new(rng:NextNumber(-0.7, 0.7), height / 2, rng:NextNumber(-0.7, 0.7))
		part(
			parent,
			"Blade",
			Vector3.new(0.14, height, 0.14),
			CFrame.new(top + offset) * CFrame.Angles(rng:NextNumber(-0.25, 0.25), i, rng:NextNumber(-0.25, 0.25)),
			Color3.fromRGB(78, 150, 58):Lerp(Color3.fromRGB(110, 176, 70), rng:NextNumber())
		).CastShadow =
			false
	end
end

-- A mushroom (red with white spots, or plain brown)
function Decor.Mushroom(parent: Instance, top: Vector3, red: boolean)
	local base = CFrame.new(top)
	part(
		parent,
		"MushroomStem",
		Vector3.new(0.3, 0.6, 0.3),
		base * CFrame.new(0, 0.3, 0),
		Color3.fromRGB(236, 228, 210)
	)
	local cap = red and Color3.fromRGB(200, 48, 40) or Color3.fromRGB(150, 108, 72)
	part(parent, "MushroomCap", Vector3.new(0.8, 0.35, 0.8), base * CFrame.new(0, 0.75, 0), cap)
	if red then
		part(parent, "Spot", Vector3.new(0.2, 0.05, 0.2), base * CFrame.new(0.2, 0.95, 0.1), Color3.new(1, 1, 1))
		part(parent, "Spot", Vector3.new(0.18, 0.05, 0.18), base * CFrame.new(-0.2, 0.95, -0.15), Color3.new(1, 1, 1))
	end
end

-- A window box of flowers: `at` is the middle of its bottom, against the wall, `out`
-- points away from the wall
function Decor.FlowerBox(parent: Instance, at: Vector3, out: Vector3, width: number, colors: { Color3 })
	local frame = CFrame.lookAt(at, at + out)
	Decor.Piece(parent, "DarkPlanks", Vector3.new(width, 0.7, 0.9), frame * CFrame.new(0, 0.35, -0.45))
	local count = math.max(2, math.floor(width / 0.9))
	for i = 1, count do
		local x = -width / 2 + (i - 0.5) * width / count
		local base = frame * CFrame.new(x, 0.7, -0.45)
		part(parent, "Leaf", Vector3.new(0.5, 0.35, 0.5), base * CFrame.new(0, 0.17, 0), Color3.fromRGB(70, 140, 56))
		part(parent, "Bloom", Vector3.new(0.4, 0.35, 0.4), base * CFrame.new(0, 0.5, 0), colors[(i - 1) % #colors + 1])
	end
end

-- A wooden bench whose seat faces `facing`, standing on `top`
function Decor.Bench(parent: Instance, top: Vector3, facing: Vector3, length: number?)
	local width = length or 4
	local frame = CFrame.lookAt(top, top + facing)
	Decor.Piece(parent, "DarkPlanks", Vector3.new(width, 0.35, 1.3), frame * CFrame.new(0, 1.3, 0))
	Decor.Piece(parent, "DarkPlanks", Vector3.new(width, 1, 0.3), frame * CFrame.new(0, 2.1, 0.55))
	for _, x in { -width / 2 + 0.3, width / 2 - 0.3 } do
		part(parent, "BenchLeg", Vector3.new(0.3, 1.15, 1.1), frame * CFrame.new(x, 0.58, 0), IRON, Enum.Material.Metal)
	end
end

-- A wooden fence along the ground from `a` to `b` (block tops): a post every block and two rails
function Decor.Fence(parent: Instance, a: Vector3, b: Vector3, wood: string?)
	local block = wood or "Planks"
	local span = b - a
	local length = span.Magnitude
	local posts = math.max(1, math.round(length / SIZE))
	for i = 0, posts do
		local at = a + span * (i / posts)
		Decor.Piece(parent, block, Vector3.new(0.6, 2.6, 0.6), CFrame.new(at + Vector3.new(0, 1.3, 0)))
	end
	if length > 0.1 then
		local middle = CFrame.lookAt((a + b) / 2, b)
		for _, height in { 1, 2 } do
			Decor.Piece(parent, block, Vector3.new(0.3, 0.35, length), middle * CFrame.new(0, height, 0))
		end
	end
end

-- A flat sheet of water, `size` wide and deep, its surface at `surface`
function Decor.Water(parent: Instance, surface: Vector3, size: Vector2, depth: number?): Part
	local d = depth or 1.5
	local water = part(
		parent,
		"Water",
		Vector3.new(size.X, d, size.Y),
		CFrame.new(surface - Vector3.new(0, d / 2, 0)),
		Color3.fromRGB(56, 128, 206),
		Enum.Material.Glass
	)
	water.Transparency = 0.35
	water.Reflectance = 0.12
	water.CanCollide = false
	water.CastShadow = false
	return water
end

-- A fountain jet: water spraying up from `at`
function Decor.Jet(parent: Instance, at: Vector3, height: number?)
	local holder = part(parent, "Jet", Vector3.new(0.4, 0.4, 0.4), CFrame.new(at), Color3.new(1, 1, 1))
	holder.Transparency = 1
	holder.CanCollide = false
	local spray = Instance.new("ParticleEmitter")
	spray.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	spray.Color = ColorSequence.new(Color3.fromRGB(180, 220, 255))
	spray.LightEmission = 0.4
	spray.Transparency = NumberSequence.new(0.2, 1)
	spray.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.2) })
	spray.Lifetime = NumberRange.new(1, 1.3)
	spray.Rate = 60
	spray.Speed = NumberRange.new(height or 9, (height or 9) + 2)
	spray.SpreadAngle = Vector2.new(8, 8)
	spray.Acceleration = Vector3.new(0, -18, 0)
	spray.Parent = holder
end

-- Chimney smoke rising from `at`
function Decor.Smoke(parent: Instance, at: Vector3)
	local holder = part(parent, "Smoke", Vector3.new(0.4, 0.4, 0.4), CFrame.new(at), Color3.new(1, 1, 1))
	holder.Transparency = 1
	holder.CanCollide = false
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = "rbxasset://textures/particles/smoke_main.dds"
	smoke.Color = ColorSequence.new(Color3.fromRGB(200, 200, 200))
	smoke.Transparency = NumberSequence.new(0.4, 1)
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 4) })
	smoke.Lifetime = NumberRange.new(3, 5)
	smoke.Rate = 4
	smoke.Speed = NumberRange.new(2, 3)
	smoke.Acceleration = Vector3.new(0.6, 0.4, 0)
	smoke.Parent = holder
end

-- A cloth banner hanging from a pole: `top` is the top of the pole, `facing` the side the
-- cloth shows to
function Decor.Banner(parent: Instance, top: Vector3, facing: Vector3, color: Color3, height: number?)
	local h = height or 5
	local frame = CFrame.lookAt(top, top + facing)
	part(parent, "BannerBar", Vector3.new(2.6, 0.25, 0.25), frame, IRON, Enum.Material.Metal)
	local cloth = part(
		parent,
		"Banner",
		Vector3.new(2.2, h, 0.15),
		frame * CFrame.new(0, -h / 2 - 0.1, 0),
		color,
		Enum.Material.Fabric
	)
	cloth.CastShadow = true
	-- A pointed tail
	part(
		parent,
		"BannerTail",
		Vector3.new(1.5, 1.5, 0.14),
		frame * CFrame.new(0, -h - 0.1, 0) * CFrame.Angles(0, 0, math.rad(45)),
		color,
		Enum.Material.Fabric
	)
	part(
		parent,
		"BannerTrim",
		Vector3.new(2.2, 0.3, 0.17),
		frame * CFrame.new(0, -0.5, 0),
		Color3.fromRGB(240, 210, 110),
		Enum.Material.Fabric
	)
end

-- Mine rails on the floor from `a` to `b` (block tops, in a straight line)
function Decor.Rails(parent: Instance, a: Vector3, b: Vector3)
	local span = b - a
	local length = span.Magnitude
	if length < 0.1 then
		return
	end
	local frame = CFrame.lookAt(a, b)
	for i = 0, math.floor(length / 1.5) do
		Decor.Piece(parent, "DarkPlanks", Vector3.new(2.6, 0.2, 0.5), frame * CFrame.new(0, 0.1, -i * 1.5))
	end
	for _, x in { -0.8, 0.8 } do
		part(
			parent,
			"Rail",
			Vector3.new(0.2, 0.25, length),
			frame * CFrame.new(x, 0.32, -length / 2),
			Color3.fromRGB(120, 118, 116),
			Enum.Material.Metal
		)
	end
end

-- A mine cart on `top`, pointing along `facing`, optionally heaped with ore
function Decor.Minecart(parent: Instance, top: Vector3, facing: Vector3, ore: string?)
	local frame = CFrame.lookAt(top, top + facing)
	local body = Color3.fromRGB(92, 88, 86)
	part(parent, "CartFloor", Vector3.new(2, 0.3, 3), frame * CFrame.new(0, 0.9, 0), body, Enum.Material.Metal)
	for _, side in { -1, 1 } do
		part(
			parent,
			"CartSide",
			Vector3.new(0.25, 1.4, 3),
			frame * CFrame.new(side * 1, 1.6, 0),
			body,
			Enum.Material.Metal
		)
		part(
			parent,
			"CartEnd",
			Vector3.new(2, 1.4, 0.25),
			frame * CFrame.new(0, 1.6, side * 1.5),
			body,
			Enum.Material.Metal
		)
		for _, z in { -1, 1 } do
			part(
				parent,
				"Wheel",
				Vector3.new(0.3, 0.8, 0.8),
				frame * CFrame.new(side * 0.9, 0.45, z),
				IRON,
				Enum.Material.Metal
			)
		end
	end
	if ore then
		for i = 1, 3 do
			Decor.Piece(
				parent,
				ore,
				Vector3.one * 1.1,
				frame * CFrame.new((i - 2) * 0.55, 2.2, (i % 2) * 0.5 - 0.25) * CFrame.Angles(0, i, 0.3)
			)
		end
	end
end

-- A striped cloth awning over a doorway or window: `top` is where it meets the wall,
-- `out` points away from the wall
function Decor.Awning(parent: Instance, top: Vector3, out: Vector3, width: number, colors: { Color3 }?)
	local stripes = colors or { Color3.fromRGB(196, 58, 52), Color3.fromRGB(240, 234, 222) }
	local frame = CFrame.lookAt(top, top + out) * CFrame.Angles(math.rad(-28), 0, 0)
	local count = math.max(2, math.round(width / 0.9))
	local stripe = width / count
	for i = 1, count do
		local x = -width / 2 + stripe * (i - 0.5)
		local cloth = part(
			parent,
			"Awning",
			Vector3.new(stripe, 0.15, 2.4),
			frame * CFrame.new(x, 0, -1.2),
			stripes[(i - 1) % #stripes + 1],
			Enum.Material.Fabric
		)
		cloth.CastShadow = true
	end
end

-- Makes a model turn around its pivot's Z axis on every player's screen
-- (client/AmbientController), `speed` degrees per second
function Decor.Spin(model: Model, speed: number)
	model:SetAttribute("Spin", speed)
	CollectionService:AddTag(model, "Spin")
end

return Decor
