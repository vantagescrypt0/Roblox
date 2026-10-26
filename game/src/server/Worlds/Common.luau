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
}
Common.Soft = SOFT

local function cellCentre(ctx: Context.Context): (number, number, number) -> Vector3
	return function(x, y, z)
		return BlockWorld.position(ctx.World, x, y, z)
	end
end

-- A tall gateway at ground level (y = 0) with the zone's name and what it needs, e.g.
-- ("BIRCH GROVE", "WOODCUTTING 10"); `front` faces people walking in
function Common.ZoneGate(ctx: Context.Context, x: number, z: number, front: Vector3, name: string, need: string?)
	local text = if need then `{name}\n{need}` else name
	Signs.Gateway(ctx.Decor, ctx.Set, cellCentre(ctx), x, z, front, text, 7)
end

-- A sign on a tall post standing on the ground at (x, z), or on the block at height
-- `groundY` (inside a cave)
function Common.Signpost(
	ctx: Context.Context,
	x: number,
	z: number,
	front: Vector3,
	text: string,
	width: number,
	groundY: number?
)
	Signs.Post(ctx.Decor, ctx.Set, cellCentre(ctx), x, groundY or ctx.HeightAt(x, z), z, front, text, width)
end

-- A path `width` blocks wide along a straight line in x or z: the ground's top block
-- becomes `block` (Path) wherever it's soft ground
function Common.Path(
	ctx: Context.Context,
	x1: number,
	z1: number,
	x2: number,
	z2: number,
	width: number,
	block: string?
)
	local half = math.floor(width / 2)
	for x = math.min(x1, x2) - (if z1 == z2 then 0 else half), math.max(x1, x2) + (if z1 == z2 then 0 else half) do
		for z = math.min(z1, z2) - (if z1 == z2 then half else 0), math.max(z1, z2) + (if z1 == z2 then half else 0) do
			local h = ctx.HeightAt(x, z)
			if SOFT[ctx.World.Cells[BlockWorld.key(x, h, z)] or ""] then
				ctx.Set(x, h, z, block or "Path")
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
