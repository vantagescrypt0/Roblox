--!strict
-- Solid shapes in blocks, for builds that aren't boxes: rings, cones, domes, thick lines,
-- tyres and big trees. A Frame is a build's own axes, so one design can face any way:
--   u  runs across the front
--   h  is height; the ground row is h = 0
--   v  runs toward the way it faces
-- Everything a Frame sets is protected scenery. Solid shapes store every cell, but only the
-- ones touching air are ever drawn (BlockWorld).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local Decor = require(script.Parent.Parent.Util.Decor)
local Context = require(script.Parent.Context)

local SIZE = Blocks.Size

-- A block type, or a function picking one per cell (nil leaves the cell alone)
export type Paint = string | (u: number, h: number, v: number) -> string?

export type Frame = {
	Ctx: Context.Context,
	Facing: Vector3,
	Cell: (u: number, h: number, v: number) -> (number, number, number),
	-- World position of a cell's center (fractions allowed)
	Pos: (u: number, h: number, v: number) -> Vector3,
	-- A world direction from a local one
	Dir: (du: number, dh: number, dv: number) -> Vector3,
	Set: (u: number, h: number, v: number, paint: Paint?) -> (),
	Free: (u: number, h: number, v: number, paint: Paint) -> (),
	Box: (u1: number, h1: number, v1: number, u2: number, h2: number, v2: number, paint: Paint?) -> (),
	-- A standing cylinder (from radius `inner` out, if given)
	Cyl: (u: number, v: number, h1: number, h2: number, r: number, paint: Paint, inner: number?) -> (),
	-- A standing cylinder whose radius goes from r1 at h1 to r2 at h2. With `shell`, only
	-- that many blocks of its outside.
	Cone: (u: number, v: number, h1: number, h2: number, r1: number, r2: number, paint: Paint, shell: number?) -> (),
	-- A ball or egg. With `shell`, only that many blocks of its outside.
	Ball: (u: number, h: number, v: number, ru: number, rh: number, rv: number, paint: Paint, shell: number?) -> (),
	-- The top half of a ball, its flat side at h
	Dome: (u: number, h: number, v: number, ru: number, rh: number, rv: number, paint: Paint, shell: number?) -> (),
	-- A line from a to b, `r` blocks out from its middle (0 = one block thick)
	Line: (a: Vector3, b: Vector3, r: number, paint: Paint) -> (),
	-- A flat ring lying down (a band round a tower, a platform's rim)
	Ring: (u: number, v: number, h: number, r: number, width: number, paint: Paint) -> (),
	-- A tube bent into a ring round the u axis (a tyre on its side is `lying`)
	Tyre: (u: number, h: number, v: number, r: number, tube: number, paint: Paint, lying: boolean?) -> (),
}

local Shapes = {}

local function pick(paint: Paint?, u: number, h: number, v: number): string?
	if type(paint) == "function" then
		return paint(u, h, v)
	end
	return paint :: string?
end

-- A build at (ox, oy, oz), facing `fx, fz` (an axis)
function Shapes.Frame(ctx: Context.Context, ox: number, oy: number, oz: number, fx: number, fz: number): Frame
	local frame = {} :: Frame
	frame.Ctx = ctx
	frame.Facing = Vector3.new(fx, 0, fz)

	local function cell(u: number, h: number, v: number): (number, number, number)
		return math.round(ox + u * fz + v * fx), math.round(oy + h), math.round(oz - u * fx + v * fz)
	end
	frame.Cell = cell

	function frame.Pos(u, h, v)
		return BlockWorld.position(ctx.World, ox + u * fz + v * fx, oy + h, oz - u * fx + v * fz)
	end
	function frame.Dir(du, dh, dv)
		return Vector3.new(du * fz + dv * fx, dh, -du * fx + dv * fz)
	end
	function frame.Set(u, h, v, paint)
		local x, y, z = cell(u, h, v)
		ctx.Set(x, y, z, pick(paint, u, h, v))
	end
	function frame.Free(u, h, v, paint)
		local x, y, z = cell(u, h, v)
		local chosen = pick(paint, u, h, v)
		if chosen then
			ctx.SetFree(x, y, z, chosen)
		end
	end
	function frame.Box(u1, h1, v1, u2, h2, v2, paint)
		for u = math.min(u1, u2), math.max(u1, u2) do
			for v = math.min(v1, v2), math.max(v1, v2) do
				for h = math.min(h1, h2), math.max(h1, h2) do
					frame.Set(u, h, v, paint)
				end
			end
		end
	end
	function frame.Cyl(u0, v0, h1, h2, r, paint, inner)
		local reach = math.ceil(r)
		for du = -reach, reach do
			for dv = -reach, reach do
				local d = math.sqrt(du * du + dv * dv)
				if d <= r + 0.3 and (not inner or d > inner + 0.3) then
					for h = math.min(h1, h2), math.max(h1, h2) do
						frame.Set(u0 + du, h, v0 + dv, paint)
					end
				end
			end
		end
	end
	function frame.Cone(u0, v0, h1, h2, r1, r2, paint, shell)
		local span = math.max(h2 - h1, 1)
		for h = h1, h2 do
			local r = r1 + (r2 - r1) * (h - h1) / span
			local reach = math.ceil(r)
			for du = -reach, reach do
				for dv = -reach, reach do
					local d = math.sqrt(du * du + dv * dv)
					if d <= r + 0.3 and (not shell or d > r - shell) then
						frame.Set(u0 + du, h, v0 + dv, paint)
					end
				end
			end
		end
	end
	function frame.Ball(u0, h0, v0, ru, rh, rv, paint, shell)
		for du = -math.ceil(ru), math.ceil(ru) do
			for dv = -math.ceil(rv), math.ceil(rv) do
				for dh = -math.ceil(rh), math.ceil(rh) do
					local d = math.sqrt((du / ru) ^ 2 + (dh / rh) ^ 2 + (dv / rv) ^ 2)
					if d <= 1.02 and (not shell or d > 1 - shell / math.min(ru, rh, rv)) then
						frame.Set(u0 + du, h0 + dh, v0 + dv, paint)
					end
				end
			end
		end
	end
	function frame.Dome(u0, h0, v0, ru, rh, rv, paint, shell)
		for du = -math.ceil(ru), math.ceil(ru) do
			for dv = -math.ceil(rv), math.ceil(rv) do
				for dh = 0, math.ceil(rh) do
					local d = math.sqrt((du / ru) ^ 2 + (dh / rh) ^ 2 + (dv / rv) ^ 2)
					if d <= 1.02 and (not shell or d > 1 - shell / math.min(ru, rh, rv)) then
						frame.Set(u0 + du, h0 + dh, v0 + dv, paint)
					end
				end
			end
		end
	end
	function frame.Line(a, b, r, paint)
		local steps = math.max(1, math.ceil((b - a).Magnitude * 2))
		local reach = math.ceil(r)
		local last: { [string]: boolean } = {}
		for i = 0, steps do
			local p = a:Lerp(b, i / steps)
			for du = -reach, reach do
				for dh = -reach, reach do
					for dv = -reach, reach do
						if r == 0 or du * du + dh * dh + dv * dv <= r * r + 0.3 then
							local u, h, v = math.round(p.X) + du, math.round(p.Y) + dh, math.round(p.Z) + dv
							local k = BlockWorld.key(u, h, v)
							if not last[k] then
								last[k] = true
								frame.Set(u, h, v, paint)
							end
						end
					end
				end
			end
		end
	end
	function frame.Ring(u0, v0, h, r, width, paint)
		frame.Cyl(u0, v0, h, h, r, paint, r - width)
	end
	function frame.Tyre(u0, h0, v0, r, tube, paint, lying)
		local reach = math.ceil(r + tube)
		local depth = math.ceil(tube)
		for a = -reach, reach do
			for b = -reach, reach do
				local ring = math.sqrt(a * a + b * b) - r
				for c = -depth, depth do
					if ring * ring + c * c <= tube * tube + 0.3 then
						if lying then
							frame.Set(u0 + a, h0 + c, v0 + b, paint)
						else
							frame.Set(u0 + c, h0 + b, v0 + a, paint)
						end
					end
				end
			end
		end
	end
	return frame
end

-- Glow ----------------------------------------------------------------------------------

-- A strip of light: thin, nothing walks into it, it never blocks aiming
function Shapes.Glow(ctx: Context.Context, size: Vector3, cframe: CFrame, color: Color3): Part
	local strip = Decor.Part(ctx.Decor, "Glow", size, cframe, color, Enum.Material.Neon)
	strip.CanCollide = false
	strip.CastShadow = false
	return strip
end

-- A real light on a part
function Shapes.Light(part: BasePart, color: Color3, range: number, brightness: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Shadows = false
	light.Parent = part
end

-- An invisible smooth slope from a to b, `width` studs across, so a stepped walkway walks
-- like a ramp (a and b are the walkway's top surface at both ends)
function Shapes.Ramp(ctx: Context.Context, a: Vector3, b: Vector3, width: number)
	local THICK = 1
	local length = (b - a).Magnitude
	if length < 1 or math.abs(b.Y - a.Y) < 0.01 then
		return
	end
	local middle = (a + b) / 2
	local slope = CFrame.lookAt(middle, b) * CFrame.new(0, -THICK / 2 + 0.75, 0)
	local ramp = Decor.Part(ctx.Decor, "Ramp", Vector3.new(width, THICK, length + SIZE), slope, Color3.new(1, 1, 1))
	ramp.Transparency = 1
	ramp.CastShadow = false
end

-- Trees ---------------------------------------------------------------------------------

-- A tall pine on the ground at (x, y, z): tiers of needles getting smaller to a point,
-- hollow inside. `snow`: the tiers' tops are white.
function Shapes.Pine(ctx: Context.Context, x: number, y: number, z: number, height: number, snow: boolean?)
	local trunk = if height >= 18 then 1 else 0
	for h = 1, height - 2 do
		for dx = 0, trunk do
			for dz = 0, trunk do
				ctx.SetFree(x + dx, y + h, z + dz, "SpruceWood")
			end
		end
	end
	local widest = height * 0.27
	local from = math.floor(height * 0.28)
	for h = from, height + 1 do
		local t = (h - from) / (height + 1 - from)
		-- A saw edge: each tier flares out, then pulls in
		local tier = (h - from) % 3
		local r = (widest * (1 - t) + 0.4) * (0.72 + tier * 0.14)
		local reach = math.ceil(r)
		for dx = -reach, reach do
			for dz = -reach, reach do
				local d = math.sqrt(dx * dx + dz * dz)
				if d <= r and d > r - 1.3 then
					local top = snow and tier == 2 and ctx.Hash(x + dx, y + h, z + dz) < 0.7
					ctx.SetFree(x + dx, y + h, z + dz, if top then "Snow" else "SpruceLeaves")
				end
			end
		end
	end
end

-- A palm: a trunk curving away from upright under a crown of drooping fronds
function Shapes.Palm(ctx: Context.Context, x: number, y: number, z: number, height: number)
	local angle = ctx.Hash(x, y, z) * 2 * math.pi
	local dx, dz = math.cos(angle), math.sin(angle)
	local function trunk(h: number): (number, number)
		local bend = (h / height) ^ 2 * height * 0.35
		return math.round(x + dx * bend), math.round(z + dz * bend)
	end
	for h = 1, height do
		local tx, tz = trunk(h)
		ctx.SetFree(tx, y + h, tz, if h % 3 == 0 then "DarkPlanks" else "Wood")
	end
	local tx, tz = trunk(height)
	local top = y + height
	ctx.SetFree(tx, top + 1, tz, "Leaves")
	for i = 0, 7 do
		local a = i * math.pi / 4 + 0.2
		for r = 1, 7 do
			local fx, fz = math.round(tx + math.cos(a) * r), math.round(tz + math.sin(a) * r)
			local fy = top + 1 - math.floor((r - 2) ^ 2 * 0.2)
			ctx.SetFree(fx, fy, fz, "Leaves")
			if r >= 5 then
				ctx.SetFree(fx, fy - 1, fz, "Leaves")
			end
		end
	end
end

-- A big broad tree: a thick trunk, limbs and lumpy hollow balls of leaves
function Shapes.BigTree(
	ctx: Context.Context,
	x: number,
	y: number,
	z: number,
	height: number,
	spread: number,
	log: string?,
	leaves: string?
)
	local wood, leaf = log or "Wood", leaves or "Leaves"
	for h = 1, height do
		ctx.SetFree(x, y + h, z, wood)
		if height >= 9 and h <= height // 2 then
			ctx.SetFree(x + 1, y + h, z, wood)
			ctx.SetFree(x, y + h, z + 1, wood)
			ctx.SetFree(x + 1, y + h, z + 1, wood)
		end
	end
	local crown = {}
	table.insert(crown, { 0, height + 1, 0, spread })
	local arms = 3 + math.floor(ctx.Hash(x, y, z) * 2)
	for i = 1, arms do
		local angle = (i + ctx.Hash(x, i, z)) / arms * 2 * math.pi
		local out = spread * 0.85
		local dx, dz = math.round(math.cos(angle) * out), math.round(math.sin(angle) * out)
		local up = height - 1 + math.floor(ctx.Hash(z, i, x) * 2)
		table.insert(crown, { dx, up, dz, spread * 0.68 })
		for s = 1, 4 do
			ctx.SetFree(
				x + math.round(dx * s / 5),
				y + height - 2 + math.floor(s / 2),
				z + math.round(dz * s / 5),
				wood
			)
		end
	end
	for _, blob in crown do
		local bx, by, bz, r = x + blob[1], y + blob[2], z + blob[3], blob[4]
		local reach = math.ceil(r)
		local tall = math.ceil(r * 0.75)
		for dx = -reach, reach do
			for dz = -reach, reach do
				for dy = -tall, tall do
					local d = math.sqrt((dx / r) ^ 2 + (dy / (r * 0.75)) ^ 2 + (dz / r) ^ 2)
					local lump = ctx.Hash(bx + dx, by + dy, bz + dz) * 0.22
					if d <= 1.02 - lump and d > 0.6 then
						ctx.SetFree(bx + dx, by + dy, bz + dz, leaf)
					end
				end
			end
		end
	end
end

return Shapes
