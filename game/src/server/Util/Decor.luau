--!strict
-- Scenery that isn't whole blocks: lanterns, fences, benches, flowers and tall grass,
-- water, fountain jets, chimney smoke, banners, mine rails and carts, awnings. The pieces the
-- Builder sells are the same meshes it sells (Util/DecorModels, art/scripts/decor.py). Nothing
-- here can be clicked or mined: everything is anchored, and it goes in a folder outside the
-- block world so it never gets in the way of aiming at blocks.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local DecorModels = require(script.Parent.DecorModels)

local SIZE = Blocks.Size

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

-- An iron lantern standing on `bottom` (or hanging from a short chain above it)
function Decor.Lantern(parent: Instance, bottom: Vector3, hanging: boolean?, range: number?): BasePart
	local frame = CFrame.new(bottom)
	local lantern = DecorModels.Place(parent, "Lantern", frame, { Light = { Range = range or 18, Brightness = 1.2 } })
	if hanging then
		DecorModels.Place(parent, "LanternChain", frame)
	end
	return lantern
end

-- A wooden lamp post: a square post on a stone foot carrying a lantern box (a glowing
-- pane in a dark wooden frame under a little roof). `ground` is the top of the block it
-- stands on; `height` is the post's, in studs.
function Decor.LampPost(parent: Instance, ground: Vector3, height: number?, range: number?): BasePart
	local h = height or 8
	-- The model's post is 8 studs, with 3.65 of foot and head: a shorter post makes a smaller lamp
	local scale = (h + 3.65) / 11.65
	return DecorModels.Place(parent, "LampPost", CFrame.new(ground), {
		Scale = Vector3.one * scale,
		Collide = true,
		Light = { Range = range or 22, Brightness = 1.3 },
	})
end

-- A lantern on a bracket sticking out of a wall: `at` is a point on the wall's face,
-- `out` points away from the wall
function Decor.WallLantern(parent: Instance, at: Vector3, out: Vector3)
	DecorModels.Place(parent, "WallLantern", CFrame.lookAt(at, at + out), { Light = { Range = 16, Brightness = 1.2 } })
end

-- A small flower: a stem and a bloom, standing on `top` (the top of a block)
function Decor.Flower(parent: Instance, top: Vector3, color: Color3)
	DecorModels.Place(parent, "Flower", CFrame.new(top), { Tint = color })
end

-- A tuft of tall grass: three thin blades
function Decor.Grass(parent: Instance, top: Vector3, rng: Random)
	local frame = CFrame.new(top) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	DecorModels.Place(parent, "TallGrass", frame, { Scale = Vector3.one * rng:NextNumber(0.8, 1.1) })
end

-- A mushroom (red with white spots, or plain brown)
function Decor.Mushroom(parent: Instance, top: Vector3, red: boolean)
	DecorModels.Place(parent, if red then "MushroomRed" else "MushroomBrown", CFrame.new(top))
end

-- A window box of flowers: `at` is the middle of its bottom, against the wall, `out`
-- points away from the wall
function Decor.FlowerBox(parent: Instance, at: Vector3, out: Vector3, width: number)
	local frame = CFrame.lookAt(at, at + out)
	-- One box to about every block, side by side
	local count = math.max(1, math.round(width / 2.6))
	local each = width / count
	for i = 1, count do
		DecorModels.Place(parent, "FlowerBox", frame * CFrame.new(-width / 2 + each * (i - 0.5), 0, 0), {
			Scale = Vector3.new(each / 2.6, 1, 1),
		})
	end
end

-- A wooden bench whose seat faces `facing`, standing on `top`
function Decor.Bench(parent: Instance, top: Vector3, facing: Vector3, length: number?)
	DecorModels.Place(parent, "Bench", CFrame.lookAt(top, top + facing), {
		Scale = Vector3.new((length or 4) / 3, 1, 1),
		Collide = true,
	})
end

-- A wooden fence along the ground from `a` to `b` (block tops): a post every block and two rails
function Decor.Fence(parent: Instance, a: Vector3, b: Vector3, wood: string?)
	local span = b - a
	local length = span.Magnitude
	local posts = math.max(1, math.round(length / SIZE))
	-- A bridge's fence in the bridge's own wood is cut from that wood's block art
	if wood and wood ~= "Planks" then
		for i = 0, posts do
			local at = a + span * (i / posts)
			Decor.Piece(parent, wood, Vector3.new(0.6, 2.6, 0.6), CFrame.new(at + Vector3.new(0, 1.3, 0)))
		end
		if length > 0.1 then
			local middle = CFrame.lookAt((a + b) / 2, b)
			for _, height in { 1, 2 } do
				Decor.Piece(parent, wood, Vector3.new(0.3, 0.35, length), middle * CFrame.new(0, height, 0))
			end
		end
		return
	end
	for i = 0, posts do
		DecorModels.Place(parent, "Fence", CFrame.new(a + span * (i / posts)), { Collide = true })
	end
	if length > 0.1 then
		-- The rail model is half a block long
		local each = length / posts
		local frame = CFrame.lookAt(a, b)
		for i = 0, posts - 1 do
			DecorModels.Place(parent, "FenceRail", frame * CFrame.new(0, 0, -each * i), {
				Scale = Vector3.new(1, 1, each / 1.5),
				Collide = true,
			})
		end
	end
end

-- A flat sheet of water, `size` wide and deep, its surface at `surface` (tagged "Water", so
-- the client's SwimController swims in it where it's deep enough)
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
	CollectionService:AddTag(water, "Water")
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
	DecorModels.Place(parent, "Banner", CFrame.lookAt(top, top + facing), {
		Scale = Vector3.new(1, (height or 5) / 5, 1),
		Tint = color,
	})
end

-- Mine rails on the floor from `a` to `b` (block tops, in a straight line)
function Decor.Rails(parent: Instance, a: Vector3, b: Vector3)
	local span = b - a
	local length = span.Magnitude
	if length < 0.1 then
		return
	end
	local frame = CFrame.lookAt(a, b)
	local pieces = math.max(1, math.floor(length / SIZE))
	local each = length / pieces
	for i = 1, pieces do
		DecorModels.Place(parent, "Rails", frame * CFrame.new(0, 0, -(i - 0.5) * each), {
			Scale = Vector3.new(1, 1, each / SIZE),
		})
	end
end

-- A mine cart on `top`, pointing along `facing`, optionally heaped with ore
function Decor.Minecart(parent: Instance, top: Vector3, facing: Vector3, ore: string?)
	local frame = CFrame.lookAt(top, top + facing)
	DecorModels.Place(parent, "Minecart", frame, { Collide = true })
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
	local frame = CFrame.lookAt(top, top + out)
	local count = math.max(2, math.round(width / 0.9))
	local stripe = width / count
	for i = 1, count do
		DecorModels.Place(parent, "AwningStripe", frame * CFrame.new(-width / 2 + stripe * (i - 0.5), 0, 0), {
			Scale = Vector3.new(stripe / 0.9, 1, 1),
			Tint = stripes[(i - 1) % #stripes + 1],
			Material = Enum.Material.Fabric,
		})
	end
end

local function emitter(holder: BasePart, props: { [string]: any }): ParticleEmitter
	local particles = Instance.new("ParticleEmitter")
	for name, value in props do
		(particles :: any)[name] = value
	end
	particles.Parent = holder
	return particles
end

local function holder(parent: Instance, name: string, size: Vector3, cframe: CFrame): Part
	local p = part(parent, name, size, cframe, Color3.new(1, 1, 1))
	p.Transparency = 1
	p.CanCollide = false
	p.CastShadow = false
	return p
end

-- Water pouring over an island's edge: `lip` is the middle of the edge at the water's
-- surface, `out` points out over the edge. It falls `drop` studs, thinning into mist.
function Decor.Waterfall(parent: Instance, lip: Vector3, out: Vector3, width: number, drop: number)
	local frame = CFrame.lookAt(lip, lip + out)
	local color = Color3.fromRGB(96, 160, 226)
	local curve = part(
		parent,
		"Waterfall",
		Vector3.new(width, 0.6, 2.6),
		frame * CFrame.new(0, -0.5, -1) * CFrame.Angles(math.rad(-35), 0, 0),
		color,
		Enum.Material.Glass
	)
	curve.Transparency = 0.25
	curve.CanCollide = false
	local y, length = -1.2, drop / 3
	for i, fade in { 0.25, 0.45, 0.7 } do
		local sheet = part(
			parent,
			"Waterfall",
			Vector3.new(width - i * 0.4, length, 0.7),
			frame * CFrame.new(0, y - length / 2, -2.2 - i * 0.25),
			color,
			Enum.Material.Glass
		)
		sheet.Transparency = fade
		sheet.CanCollide = false
		sheet.CastShadow = false
		y -= length
	end
	-- White foam where it tips over, spray down the fall, mist at the bottom
	local top = holder(parent, "Foam", Vector3.new(width, 0.4, 0.4), frame * CFrame.new(0, -1, -2.1))
	emitter(top, {
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Color = ColorSequence.new(Color3.fromRGB(235, 245, 255)),
		Transparency = NumberSequence.new(0.3, 1),
		Size = NumberSequence.new(0.8, 1.6),
		Lifetime = NumberRange.new(0.8, 1.4),
		Rate = 30,
		Speed = NumberRange.new(2, 4),
		SpreadAngle = Vector2.new(25, 25),
		EmissionDirection = Enum.NormalId.Bottom,
		Acceleration = Vector3.new(0, -12, 0),
	})
	local bottom = holder(parent, "Mist", Vector3.new(width, 1, 1), frame * CFrame.new(0, -drop * 0.7, -2.6))
	emitter(bottom, {
		Texture = "rbxasset://textures/particles/smoke_main.dds",
		Color = ColorSequence.new(Color3.fromRGB(220, 235, 250)),
		Transparency = NumberSequence.new(0.6, 1),
		Size = NumberSequence.new(4, 9),
		Lifetime = NumberRange.new(3, 5),
		Rate = 6,
		Speed = NumberRange.new(1, 3),
		SpreadAngle = Vector2.new(60, 60),
		Acceleration = Vector3.new(0, -1, 0),
	})
end

-- Things drifting down over an area: snow, cherry petals or autumn leaves. `centre` is
-- the middle of the area, high up; `size` its width and depth in studs.
function Decor.Falling(parent: Instance, centre: Vector3, size: Vector2, kind: "Snow" | "Petals" | "Leaves")
	local area = holder(parent, kind, Vector3.new(size.X, 1, size.Y), CFrame.new(centre))
	local colors = {
		Snow = ColorSequence.new(Color3.fromRGB(250, 252, 255)),
		Petals = ColorSequence.new(Color3.fromRGB(250, 186, 214), Color3.fromRGB(240, 150, 190)),
		Leaves = ColorSequence.new(Color3.fromRGB(230, 120, 40), Color3.fromRGB(196, 70, 36)),
	}
	emitter(area, {
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Color = colors[kind],
		LightEmission = if kind == "Snow" then 0.3 else 0,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.1, 0.1),
			NumberSequenceKeypoint.new(0.85, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Size = NumberSequence.new(if kind == "Snow" then 0.35 else 0.45),
		Lifetime = NumberRange.new(9, 13),
		Rate = math.clamp(size.X * size.Y / 400, 10, 60),
		Speed = NumberRange.new(3, 5),
		EmissionDirection = Enum.NormalId.Bottom,
		Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
		Acceleration = Vector3.new(0.8, -0.4, 0.4),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-60, 60),
	})
end

-- A stone lantern: a footing, a short pillar, a lit box and a wide cap, on `top`
function Decor.StoneLantern(parent: Instance, top: Vector3)
	DecorModels.Place(
		parent,
		"StoneLantern",
		CFrame.new(top),
		{ Collide = true, Light = { Range = 16, Brightness = 1 } }
	)
end

-- A lily pad on a water surface, maybe with a flower
function Decor.LilyPad(parent: Instance, surface: Vector3, flower: Color3?)
	DecorModels.Place(parent, "LilyPad", CFrame.new(surface))
	if flower then
		DecorModels.Place(parent, "LilyBloom", CFrame.new(surface), { Tint = flower })
	end
end

-- A palm tree on `top`: a ringed trunk curving up, a crown of drooping fronds, coconuts
function Decor.PalmTree(parent: Instance, top: Vector3, height: number, lean: number)
	DecorModels.Place(parent, "PalmTree", CFrame.new(top) * CFrame.Angles(0, lean, 0), {
		Scale = Vector3.one * (height / 12),
		Collide = true,
	})
end

-- A cactus on `top`: a ribbed green column, maybe with arms
function Decor.Cactus(parent: Instance, top: Vector3, height: number, arms: number)
	DecorModels.Place(parent, `Cactus{math.clamp(arms, 0, 2)}`, CFrame.new(top), {
		Scale = Vector3.new(1, height / 6, 1),
		Collide = true,
	})
end

-- A carved face glowing on a pumpkin block's side: `at` is the middle of that side,
-- `out` points away from it
function Decor.JackOLantern(parent: Instance, at: Vector3, out: Vector3)
	local face = DecorModels.Place(parent, "JackFace", CFrame.lookAt(at, at + out))
	face.Material = Enum.Material.Neon
	face.Color = Color3.fromRGB(255, 196, 70)
	DecorModels.Light(face, 12, 1)
end

-- Makes a model turn around its pivot's Z axis on every player's screen
-- (client/AmbientController), `speed` degrees per second. With streaming on, the model
-- arrives on a screen whole, and turns from where it rests ("SpinBase").
function Decor.Spin(model: Model, speed: number)
	model:SetAttribute("Spin", speed)
	model:SetAttribute("SpinBase", model:GetPivot())
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	CollectionService:AddTag(model, "Spin")
end

return Decor
