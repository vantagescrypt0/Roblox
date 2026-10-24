--!strict
-- Our portal: a carved runestone archway (Runestone blocks) around a glowing teal and
-- gold energy field. Used for the island's portal to Town and the Town's way home.
--
--        [R][R][R]          y = 6   crown
--     [R][R]   [R][R]       y = 5   shoulders (the middle stays open)
--     [R]  field  [R]       y = 1..4, opening 3 blocks wide
--
-- x is relative to the arch's middle (cx); everything sits on a ground row at y = 0.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local BlockWorld = require(script.Parent.BlockWorld)

local SIZE = Blocks.Size
local FIELD = Color3.fromRGB(64, 214, 196)
local FRAME: { { number } } = {
	{ -2, 1 },
	{ -2, 2 },
	{ -2, 3 },
	{ -2, 4 },
	{ -2, 5 },
	{ 2, 1 },
	{ 2, 2 },
	{ 2, 3 },
	{ 2, 4 },
	{ 2, 5 },
	{ -1, 5 },
	{ 1, 5 },
	{ -1, 6 },
	{ 0, 6 },
	{ 1, 6 },
}

local Portal = {}

-- Writes the arch into `cells` and protects it, its opening and the ground in front of
-- and behind it, so players can't break or bury it
function Portal.addCells(cells: { [string]: string }, protected: { [string]: boolean }, cx: number, z: number)
	for _, c in FRAME do
		cells[BlockWorld.key(cx + c[1], c[2], z)] = "Runestone"
	end
	for x = cx - 2, cx + 2 do
		for y = 1, 6 do
			protected[BlockWorld.key(x, y, z)] = true
		end
		for dz = -1, 1 do
			protected[BlockWorld.key(x, 0, z + dz)] = true
		end
	end
end

local function sheet(world: BlockWorld.World, name: string, size: Vector3, position: Vector3): BasePart
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(position)
	part.Material = Enum.Material.Neon
	part.Color = FIELD
	part.Transparency = 0.3
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Parent = world.Model
	return part
end

-- The glowing field inside the arch. Returns the main part (prompts and touches go on it).
function Portal.makeField(world: BlockWorld.World, cx: number, z: number): BasePart
	local field =
		sheet(world, "PortalSurface", Vector3.new(3 * SIZE, 4 * SIZE, 0.4), BlockWorld.position(world, cx, 2.5, z))
	sheet(world, "PortalSurfaceTop", Vector3.new(SIZE, SIZE, 0.4), BlockWorld.position(world, cx, 5, z))

	local light = Instance.new("PointLight")
	light.Color = FIELD
	light.Range = 16
	light.Brightness = 1.8
	light.Parent = field

	-- Teal motes drifting up, with a few gold sparks
	for _, look in
		{
			{ Color = FIELD, Rate = 16, Size = 0.4 },
			{ Color = Color3.fromRGB(255, 214, 120), Rate = 6, Size = 0.28 },
		}
	do
		local particles = Instance.new("ParticleEmitter")
		particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		particles.Color = ColorSequence.new(look.Color)
		particles.LightEmission = 1
		particles.Size =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, look.Size), NumberSequenceKeypoint.new(1, 0) })
		particles.Lifetime = NumberRange.new(1.2, 2)
		particles.Rate = look.Rate
		particles.Speed = NumberRange.new(0.6, 1.4)
		particles.Acceleration = Vector3.new(0, 1.2, 0)
		particles.SpreadAngle = Vector2.new(60, 60)
		particles.Parent = field
	end
	return field
end

return Portal
