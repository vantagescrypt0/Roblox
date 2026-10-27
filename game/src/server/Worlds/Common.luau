--!strict
-- Pieces every world uses: the zone gateways at the bridge ends, paths, lamp posts,
-- planting a forest, and the tall grass and flowers scattered over open ground.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local Decor = require(script.Parent.Parent.Util.Decor)
local Signs = require(script.Parent.Parent.Util.Signs)
local Context = require(script.Parent.Context)

local SIZE = Blocks.Size

local Common = {}

-- Ground a path, a lamp or a flower can go on
local SOFT: { [string]: boolean } = {
	Grass = true,
	FlowerGrass = true,
	SnowyGrass = true,
	Snow = true,
	Sand = true,
	Dirt = true,
	CoarseDirt = true,
}
Common.Soft = SOFT

-- A worn patch of path under a signpost (so no crop or flower grows in it)
local function trample(ctx: Context.Context, x: number, z: number)
	local h = ctx.HeightAt(x, z)
	if SOFT[ctx.World.Cells[BlockWorld.key(x, h, z)] or ""] then
		ctx.Set(x, h, z, "Path")
	end
end

-- A rough zone sign beside the path where a zone begins, with the zone's name and what it
-- needs, e.g. ("BIRCH GROVE", "WOODCUTTING 10"), in the zone's wood (Signs.Woods);
-- `front` faces people walking in. On the ground at (x, z), or on the block at height
-- `groundY` (inside a cave).
function Common.ZoneSign(
	ctx: Context.Context,
	x: number,
	z: number,
	front: Vector3,
	name: string,
	need: string?,
	wood: Color3?,
	groundY: number?
)
	local text = if need then `{name}\n{need}` else name
	Signs.Rustic(ctx.Decor, ctx.Top(x, groundY or ctx.HeightAt(x, z), z), front, text, wood)
	if not groundY then
		trample(ctx, x, z)
	end
end

-- A signpost on the ground at (x, z) pointing the way to places ({ Text, Toward }), read
-- by people coming from `reader`'s side. On the block at height `groundY` inside a cave.
function Common.Arrows(
	ctx: Context.Context,
	x: number,
	z: number,
	reader: Vector3,
	arrows: { { Text: string, Toward: Vector3 } },
	wood: Color3?,
	groundY: number?
)
	Signs.Arrows(ctx.Decor, ctx.Top(x, groundY or ctx.HeightAt(x, z), z), reader, arrows, wood)
	if not groundY then
		trample(ctx, x, z)
	end
end

-- A cobbled stone path's mix of blocks
Common.StonePath = table.freeze({ "Cobblestone", "Gravel", "Gravel", "StoneBricks", "Path" })

-- A path `width` blocks wide along a straight line in x or z: the ground's top block
-- becomes `block` (Path, or a mix like Common.StonePath) wherever it's soft ground
function Common.Path(
	ctx: Context.Context,
	x1: number,
	z1: number,
	x2: number,
	z2: number,
	width: number,
	block: (string | { string })?
)
	local half = math.floor(width / 2)
	for x = math.min(x1, x2) - (if z1 == z2 then 0 else half), math.max(x1, x2) + (if z1 == z2 then 0 else half) do
		for z = math.min(z1, z2) - (if z1 == z2 then half else 0), math.max(z1, z2) + (if z1 == z2 then half else 0) do
			local h = ctx.HeightAt(x, z)
			if SOFT[ctx.World.Cells[BlockWorld.key(x, h, z)] or ""] then
				local chosen = "Path"
				if type(block) == "table" then
					chosen = block[math.floor(ctx.Hash(x, 77, z) * #block) + 1]
				elseif type(block) == "string" then
					chosen = block
				end
				ctx.Set(x, h, z, chosen)
			end
		end
	end
end

-- A boulder of `blocks` (picked at random) on the ground at (x, z), about `size` across
function Common.Boulder(ctx: Context.Context, x: number, z: number, size: number, blocks: { string })
	local r = size / 2
	local h0 = ctx.HeightAt(x, z)
	for dx = -math.ceil(r), math.ceil(r) do
		for dz = -math.ceil(r), math.ceil(r) do
			local d = math.sqrt(dx * dx + dz * dz)
			if d <= r + 0.3 and ctx.IslandAt(x + dx, z + dz) then
				local tall = math.max(1, math.round((1 - d / (r + 1)) * size * 0.8 + ctx.Hash(x + dx, 5, z + dz)))
				for y = 1, tall do
					local pick = blocks[math.floor(ctx.Hash(x + dx, y, z + dz) * #blocks) + 1]
					ctx.SetFree(x + dx, h0 + y, z + dz, pick)
				end
			end
		end
	end
end

-- A giant red mushroom on the ground at (x, z): a pale stem `height` blocks tall under a
-- wide round cap with a lip hanging down at its edge
function Common.GiantMushroom(ctx: Context.Context, x: number, z: number, height: number, capRadius: number)
	local h0 = ctx.HeightAt(x, z)
	for y = 1, height do
		ctx.SetFree(x, h0 + y, z, "MushroomStem")
	end
	local top = h0 + height + 1
	for dx = -capRadius, capRadius do
		for dz = -capRadius, capRadius do
			local d = math.sqrt(dx * dx + dz * dz)
			if d <= capRadius + 0.3 then
				ctx.SetFree(x + dx, top, z + dz, "MushroomCap")
				if d > capRadius - 0.8 then
					ctx.SetFree(x + dx, top - 1, z + dz, "MushroomCap")
				end
			end
			if d <= capRadius - 1.2 then
				ctx.SetFree(x + dx, top + 1, z + dz, "MushroomCap")
			end
		end
	end
end

-- Vines hanging down cliff faces on an island: wherever the ground drops two blocks or
-- more to a neighbour, now and then (`chance`)
function Common.CliffVines(
	ctx: Context.Context,
	island: Context.Island,
	chance: number,
	skip: ((x: number, z: number) -> boolean)?
)
	local r = math.ceil(island.Radius * 1.25)
	local green = Color3.fromRGB(72, 132, 52)
	for x = island.X - r, island.X + r do
		for z = island.Z - r, island.Z + r do
			if ctx.IslandAt(x, z) == island and not (skip and skip(x, z)) then
				local h = ctx.HeightAt(x, z)
				for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
					local nx, nz = x + d[1], z + d[2]
					local drop = h - ctx.HeightAt(nx, nz)
					if drop >= 2 and ctx.IslandAt(nx, nz) and ctx.Hash(x * 3 + d[1], 31, z * 3 + d[2]) < chance then
						local out = Vector3.new(d[1], 0, d[2])
						local length = SIZE * (drop - 0.3) * (0.5 + ctx.Hash(x, 32, z) * 0.5)
						local at = ctx.Top(x, h, z) + out * (SIZE / 2 + 0.08)
						local vine = Decor.Part(
							ctx.Decor,
							"Vine",
							Vector3.new(SIZE * 0.8, length, 0.12),
							CFrame.lookAt(at, at + out) * CFrame.new(0, -length / 2, 0),
							green:Lerp(Color3.fromRGB(96, 156, 64), ctx.Hash(z, 33, x)),
							Enum.Material.LeafyGrass
						)
						vine.CanCollide = false
						vine.CastShadow = false
					end
				end
			end
		end
	end
end

-- A lamp post: two logs and a lantern, on the ground at (x, z)
function Common.Lamp(ctx: Context.Context, x: number, z: number)
	local h = ctx.HeightAt(x, z)
	ctx.Set(x, h + 1, z, "Wood")
	ctx.Set(x, h + 2, z, "Wood")
	Decor.Lantern(ctx.Decor, ctx.Top(x, h + 2, z), false, 18)
end

-- Plants trees about `spacing` apart over an island, `margin` in from its rim, skipping
-- spots `avoid` says no to. `plant(x, groundY, z)` grows one.
function Common.Forest(
	ctx: Context.Context,
	island: Context.Island,
	spacing: number,
	margin: number,
	avoid: (x: number, z: number) -> boolean,
	plant: (x: number, y: number, z: number) -> ()
)
	local rng = ctx.Rng
	local placed: { Vector2 } = {}
	local r = island.Radius + 6
	for gx = island.X - r, island.X + r, spacing do
		for gz = island.Z - r, island.Z + r, spacing do
			local x = gx + rng:NextInteger(-1, 1)
			local z = gz + rng:NextInteger(-1, 1)
			local spot = Vector2.new(x, z)
			local ok = ctx.IslandAt(x, z) == island and ctx.Inside(x, z, margin) and not avoid(x, z)
			if ok then
				for _, other in placed do
					if (other - spot).Magnitude < spacing - 1 then
						ok = false
						break
					end
				end
			end
			if ok then
				table.insert(placed, spot)
				plant(x, ctx.HeightAt(x, z), z)
			end
		end
	end
end

-- Tall grass and flowers on open grassy ground over an island
function Common.Scatter(
	ctx: Context.Context,
	island: Context.Island,
	grass: number,
	flowers: number,
	colors: { Color3 }
)
	local rng = ctx.Rng
	local r = math.ceil(island.Radius * 1.25)
	for x = island.X - r, island.X + r do
		for z = island.Z - r, island.Z + r do
			if ctx.IslandAt(x, z) == island then
				local h = ctx.HeightAt(x, z)
				local ground = ctx.World.Cells[BlockWorld.key(x, h, z)]
				if
					(ground == "Grass" or ground == "FlowerGrass" or ground == "SnowyGrass")
					and not ctx.World.Cells[BlockWorld.key(x, h + 1, z)]
				then
					local roll = rng:NextNumber()
					if roll < grass then
						Decor.Grass(ctx.Decor, ctx.Top(x, h, z), rng)
					elseif roll < grass + flowers and #colors > 0 then
						Decor.Flower(ctx.Decor, ctx.Top(x, h, z), colors[rng:NextInteger(1, #colors)])
					end
				end
			end
		end
	end
end

-- A round pond: water over a sandy (or `bed`) floor, `radius` blocks, with a shore of
-- `shore` round it. Returns the water part.
function Common.Pond(ctx: Context.Context, cx: number, cz: number, radius: number, shore: string?, bed: string?): Part
	for x = cx - math.ceil(radius) - 2, cx + math.ceil(radius) + 2 do
		for z = cz - math.ceil(radius) - 2, cz + math.ceil(radius) + 2 do
			local d = math.sqrt((x - cx) ^ 2 + (z - cz) ^ 2)
			if d <= radius - 0.6 then
				ctx.Set(x, 0, z, nil)
				ctx.Set(x, -1, z, bed or "Sand")
				for y = 1, 3 do
					ctx.Set(x, y, z, nil)
				end
			elseif d <= radius + 0.8 and ctx.Inside(x, z, 0) then
				ctx.Set(x, 0, z, shore or "Sand")
			end
		end
	end
	local size = (math.floor(radius - 0.6) * 2 + 1) * SIZE
	return Decor.Water(
		ctx.Decor,
		ctx.Top(cx, -1, cz) + Vector3.new(0, SIZE * 0.75, 0),
		Vector2.new(size, size),
		SIZE * 0.8
	)
end

return Common
