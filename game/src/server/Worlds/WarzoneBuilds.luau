--!strict
-- The Warzone's hero builds: one big thing on every island, so you always know where you
-- are. All our own designs, in the spirit of the Skybounds Warzones ([[Vaeron Warzones]]).
-- Each build gets a Frame at the middle of its island, facing the citadel, with h = 0 at the
-- ground. Everything is cover: legs to duck behind, halls to run through, roofs to jump on.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Decor = require(script.Parent.Parent.Util.Decor)
local Shapes = require(script.Parent.Shapes)

local SIZE = Blocks.Size
local CYAN = Color3.fromRGB(110, 226, 255)
local RED = Color3.fromRGB(255, 70, 60)
local MAGENTA = Color3.fromRGB(226, 90, 255)
local AMBER = Color3.fromRGB(255, 170, 70)

export type Hero = (f: Shapes.Frame, radius: number) -> ()

local Builds: { [string]: Hero } = {}

-- Small pieces --------------------------------------------------------------------------

local function v3(u: number, h: number, v: number): Vector3
	return Vector3.new(u, h, v)
end

-- A glowing ball of light at a cell
local function beacon(f: Shapes.Frame, u: number, h: number, v: number, size: number, color: Color3, range: number?)
	local ball = Shapes.Glow(f.Ctx, Vector3.new(size, size, size), CFrame.new(f.Pos(u, h, v)), color)
	ball.Shape = Enum.PartType.Ball
	if range then
		Shapes.Light(ball, color, range, 2)
	end
end

-- A strip of light up the face of something: from cell a to cell b
local function strip(f: Shapes.Frame, a: Vector3, b: Vector3, width: number, color: Color3)
	local pa, pb = f.Pos(a.X, a.Y, a.Z), f.Pos(b.X, b.Y, b.Z)
	local length = (pb - pa).Magnitude + SIZE
	Shapes.Glow(f.Ctx, Vector3.new(width, width, length), CFrame.lookAt((pa + pb) / 2, pb), color)
end

-- A traffic cone: orange with a white band
local function trafficCone(f: Shapes.Frame, u: number, v: number, height: number, r: number)
	f.Box(u - math.ceil(r), 1, v - math.ceil(r), u + math.ceil(r), 1, v + math.ceil(r), "HullDark")
	f.Cone(u, v, 2, height, r, 0.5, function(_, h)
		local t = h / height
		return if t > 0.45 and t < 0.68 then "HullWhite" else "HullOrange"
	end)
end

-- A tyre lying down, stacked `count` high
local function tyres(f: Shapes.Frame, u: number, v: number, r: number, count: number)
	for i = 0, count - 1 do
		f.Tyre(u, 2 + i * 3, v, r, 1.4, "Rubber", true)
	end
end

-- A heap of scrap
local function scrap(f: Shapes.Frame, u: number, v: number, size: number)
	local ctx = f.Ctx
	local kinds = { "HullGrey", "HullDark", "HullWhite", "RustGround", "HullOrange", "Rubber" }
	for du = -size, size do
		for dv = -size, size do
			local d = math.sqrt(du * du + dv * dv)
			if d <= size then
				local tall = math.ceil((1 - d / (size + 1)) * size * 0.9 + ctx.Hash(u + du, 7, v + dv) * 1.5)
				for h = 1, tall do
					f.Free(u + du, h, v + dv, kinds[math.floor(ctx.Hash(u + du, h, v + dv) * #kinds) + 1])
				end
			end
		end
	end
end

-- A lattice mast: four legs leaning in from (w1) at h1 to (w2) at h2, zigzag braces between
local function lattice(
	f: Shapes.Frame,
	u: number,
	v: number,
	h1: number,
	h2: number,
	w1: number,
	w2: number,
	paint: string,
	brace: string
)
	local corners = { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }
	for _, c in corners do
		f.Line(v3(u + c[1] * w1, h1, v + c[2] * w1), v3(u + c[1] * w2, h2, v + c[2] * w2), 0, paint)
	end
	local levels = math.max(1, math.floor((h2 - h1) / 5))
	for level = 0, levels - 1 do
		local t1, t2 = level / levels, (level + 1) / levels
		local a, b = h1 + (h2 - h1) * t1, h1 + (h2 - h1) * t2
		local wa, wb = w1 + (w2 - w1) * t1, w1 + (w2 - w1) * t2
		for i = 1, 4 do
			local c1, c2 = corners[i], corners[i % 4 + 1]
			local flip = level % 2 == 0
			local from = if flip then c1 else c2
			local to = if flip then c2 else c1
			f.Line(v3(u + from[1] * wa, a, v + from[2] * wa), v3(u + to[1] * wb, b, v + to[2] * wb), 0, brace)
		end
	end
end

-- A pool: water with a bed, cut into the ground around (u, v)
local function pool(f: Shapes.Frame, u: number, v: number, r: number, shore: string?, bed: string?)
	local reach = math.ceil(r) + 2
	for du = -reach, reach do
		for dv = -reach, reach do
			local d = math.sqrt(du * du + dv * dv)
			if d <= r - 0.6 then
				f.Set(u + du, 0, v + dv, nil)
				f.Set(u + du, -1, v + dv, bed or "Sand")
			elseif d <= r + 0.8 and shore then
				f.Set(u + du, 0, v + dv, shore)
			end
		end
	end
	local across = (math.floor(r - 0.6) * 2 + 1) * SIZE
	Decor.Water(f.Ctx.Decor, f.Pos(u, 0, v) + Vector3.new(0, SIZE * 0.3, 0), Vector2.new(across, across), SIZE * 0.8)
end

-- Steps up to a height, with a smooth slope over them: from (u, 1, v) rising toward +v
local function stairs(f: Shapes.Frame, u1: number, u2: number, v: number, height: number, paint: string, along: number?)
	local dir = along or 1
	for i = 0, height - 1 do
		f.Box(u1, 1, v + i * dir, u2, height - i, v + i * dir, paint)
	end
	local top = height + 0.5
	Shapes.Ramp(
		f.Ctx,
		f.Pos((u1 + u2) / 2, top, v - 0.5 * dir),
		f.Pos((u1 + u2) / 2, 0.5, v + height * dir + 0.5 * dir),
		(math.abs(u2 - u1) + 1) * SIZE
	)
end

-- A shipping container: a box with ribs and a dark door end
local function container(f: Shapes.Frame, u: number, h: number, v: number, alongU: boolean, paint: string)
	local a, b = 2, 5
	local u1, u2 = u - (if alongU then b else a), u + (if alongU then b else a)
	local v1, v2 = v - (if alongU then a else b), v + (if alongU then a else b)
	f.Box(u1, h, v1, u2, h + 3, v2, function(cu, ch, cv)
		local along = if alongU then cu else cv
		if along == (if alongU then u1 else v1) then
			return "HullDark"
		end
		return if ch == h + 3 or along % 2 == 0 then paint else "HullGrey"
	end)
end

-- A wind turbine's three blades, turning (the tower is built by the caller)
local function rotor(f: Shapes.Frame, hub: Vector3, facing: Vector3, length: number, speed: number)
	local ctx = f.Ctx
	local model = Instance.new("Model")
	model.Name = "Rotor"
	local frame = CFrame.lookAt(hub, hub + facing)
	Decor.Part(model, "Hub", Vector3.new(4, 4, 5), frame, Color3.fromRGB(226, 228, 232), Enum.Material.Metal)
	for i = 0, 2 do
		local spin = frame * CFrame.Angles(0, 0, i * 2 * math.pi / 3)
		local blade = Decor.Part(
			model,
			"Blade",
			Vector3.new(2.6, length, 0.5),
			spin * CFrame.new(0, length / 2, 0),
			Color3.fromRGB(240, 241, 244),
			Enum.Material.SmoothPlastic
		)
		blade.CanCollide = false
		local tip = Decor.Part(
			model,
			"BladeTip",
			Vector3.new(2.7, length * 0.14, 0.55),
			spin * CFrame.new(0, length * 0.93, 0),
			Color3.fromRGB(214, 106, 40),
			Enum.Material.SmoothPlastic
		)
		tip.CanCollide = false
	end
	model.WorldPivot = frame
	model.Parent = ctx.Decor
	Decor.Spin(model, speed)
end

-- The landmarks -------------------------------------------------------------------------

-- North: a giant robot waving hello, hazard stage round its feet
function Builds.GiantRobot(f: Shapes.Frame)
	f.Cyl(0, 0, 0, 0, 23, "HullDark")
	f.Ring(0, 0, 0, 24, 2, "Hazard")
	for _, s in { -1, 1 } do
		-- Boots
		f.Box(s * 2, 1, -6, s * 10, 2, 8, "HullDark")
		f.Box(s * 2, 1, 8, s * 10, 1, 10, "HullOrange")
		-- Shin, with a plate down the front
		f.Box(s * 3, 3, -4, s * 9, 11, 4, "HullWhite")
		f.Box(s * 4, 5, 5, s * 8, 10, 5, "HullOrange")
		f.Box(s * 4, 3, -5, s * 8, 9, -5, "HullGrey")
		-- Knee
		f.Box(s * 2, 12, -5, s * 10, 14, 5, "HullOrange")
		-- Thigh
		f.Box(s * 3, 15, -4, s * 9, 20, 4, "HullGrey")
	end
	-- Hips and waist
	f.Box(-11, 21, -5, 11, 24, 5, "HullDark")
	f.Box(-7, 25, -4, 7, 26, 4, "HullGrey")
	-- The body widens to the shoulders
	for h = 27, 38 do
		local w = math.round(9 + (h - 27) * 0.42)
		f.Box(-w, h, -6, w, h, 6, function(u, _, v)
			if v == 6 and math.abs(u) >= w - 1 then
				return "HullOrange"
			end
			return "HullWhite"
		end)
	end
	-- Chest: a dark frame round a glowing core
	f.Box(-6, 29, 7, 6, 36, 7, "HullDark")
	f.Box(-3, 31, 8, 3, 34, 8, "HullGlow")
	beacon(f, 0, 32.5, 8.5, SIZE * 4, CYAN, 60)
	-- Shoulders
	for _, s in { -1, 1 } do
		f.Box(s * 14, 35, -6, s * 21, 41, 6, "HullOrange")
		f.Box(s * 15, 37, 7, s * 20, 39, 7, "HullWhite")
	end
	-- Arm down, with a big fist
	f.Line(v3(-18, 35, 0), v3(-20, 23, 2), 2.5, "HullWhite")
	f.Box(-23, 20, -2, -17, 24, 6, "HullOrange")
	f.Line(v3(-20, 20, 2), v3(-19, 11, 7), 2.5, "HullGrey")
	f.Box(-23, 5, 4, -15, 11, 11, "HullDark")
	-- Arm up, waving
	f.Line(v3(18, 38, 0), v3(27, 46, 1), 2.5, "HullWhite")
	f.Box(24, 43, -3, 30, 49, 5, "HullOrange")
	f.Line(v3(27, 48, 1), v3(28, 54, 2), 2.5, "HullGrey")
	f.Box(24, 54, -2, 32, 59, 5, "HullDark")
	for i = 0, 2 do
		f.Box(24 + i * 3, 60, 0, 25 + i * 3, 62, 2, "HullGrey")
	end
	-- Head
	f.Box(-4, 39, -3, 4, 40, 3, "HullDark")
	f.Box(-8, 41, -7, 8, 50, 7, "HullWhite")
	f.Box(-9, 44, -4, -9, 48, 4, "HullOrange")
	f.Box(9, 44, -4, 9, 48, 4, "HullOrange")
	f.Box(-7, 45, 8, 7, 48, 8, "HullDark")
	f.Box(-5, 46, 9, -2, 47, 9, "HullGlow")
	f.Box(2, 46, 9, 5, 47, 9, "HullGlow")
	strip(f, v3(-5, 46.5, 9.4), v3(-2, 46.5, 9.4), 2.4, CYAN)
	strip(f, v3(2, 46.5, 9.4), v3(5, 46.5, 9.4), 2.4, CYAN)
	f.Box(-4, 42, 8, 4, 43, 8, "HullGrey")
	f.Line(v3(0, 51, 0), v3(0, 57, 0), 0, "HullDark")
	beacon(f, 0, 58, 0, SIZE * 1.6, RED, 40)
	-- Bits and pieces round its feet
	trafficCone(f, -19, 15, 8, 2.5)
	trafficCone(f, 17, 16, 6, 2)
	f.Box(14, 1, -16, 20, 5, -10, "Crate")
	f.Box(15, 6, -15, 18, 8, -12, "Crate")
end

-- East: three cooling towers round a glowing reactor dome, joined by fat pipes
function Builds.Reactor(f: Shapes.Frame)
	f.Cyl(0, 0, 0, 0, 24, "HullGrey")
	f.Ring(0, 0, 0, 25, 2, "Hazard")
	for i = 0, 2 do
		local angle = i * 2 * math.pi / 3 + math.pi / 6
		local u, v = math.round(math.cos(angle) * 16), math.round(math.sin(angle) * 16)
		local function paint(_: number, h: number): string?
			return if h >= 24 and h <= 26 then "HullOrange" else "HullWhite"
		end
		-- Waisted, like a real cooling tower
		f.Cone(u, v, 1, 16, 8, 5.5, paint, 1.5)
		f.Cone(u, v, 17, 30, 5.5, 7, paint, 1.5)
		f.Line(v3(0, 4, 0), v3(u, 4, v), 1.5, "HullOrange")
		local top = f.Pos(u, 30, v)
		Decor.Smoke(f.Ctx.Decor, top)
		Decor.Smoke(f.Ctx.Decor, top + Vector3.new(4, 0, 3))
		f.Box(u - 2, 1, v - 2, u + 2, 3, v + 2, "HullDark")
	end
	f.Cyl(0, 0, 1, 4, 8, "HullDark")
	f.Dome(0, 5, 0, 7, 8, 7, function(u, h, v)
		local a = math.atan2(v, u)
		return if (a * 8 / math.pi) % 2 < 0.45 or h % 4 == 0 then "HullWhite" else "HullGrey"
	end, 1.5)
	f.Ring(0, 0, 5, 8, 1.2, "HullGlow")
	beacon(f, 0, 14, 0, SIZE * 4.5, CYAN, 70)
	f.Line(v3(0, 13, 0), v3(0, 22, 0), 0, "HullDark")
	beacon(f, 0, 23, 0, SIZE * 1.3, RED, 30)
	-- Warning light on stands
	for _, c in { { -21, 0 }, { 21, 0 }, { 0, -21 }, { 0, 21 } } do
		f.Box(c[1], 1, c[2], c[1], 4, c[2], "HullDark")
		beacon(f, c[1], 5, c[2], SIZE * 0.9, AMBER, 22)
	end
end

-- South: a rocket on its launch pad, with a gantry you could hide behind
function Builds.Rocket(f: Shapes.Frame)
	f.Cyl(0, 0, 0, 2, 16, "HullDark")
	f.Ring(0, 0, 2, 16, 2, "Hazard")
	f.Ring(0, 0, 2, 11, 1, "HullGlow")
	-- Steps up onto the pad on the citadel side
	stairs(f, -5, 5, 17, 2, "HullGrey")
	local function body(_: number, h: number, v: number): string?
		if (h >= 13 and h <= 14) or (h >= 31 and h <= 32) then
			return "HullOrange"
		end
		if h >= 37 and h <= 39 and v >= 4 then
			return "Glass"
		end
		return "HullWhite"
	end
	f.Cyl(0, 0, 4, 42, 5.5, body)
	f.Cone(0, 0, 43, 55, 5.5, 0.4, function(_, h)
		return if h >= 51 then "HullGrey" else "HullOrange"
	end)
	-- Fins and the engine bell
	for _, c in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
		f.Line(v3(c[1] * 5, 18, c[2] * 5), v3(c[1] * 12, 4, c[2] * 12), 1, "HullOrange")
		f.Line(v3(c[1] * 8, 7, c[2] * 8), v3(c[1] * 12, 4, c[2] * 12), 1, "HullDark")
	end
	-- Two strap-on boosters
	for _, s in { -1, 1 } do
		f.Cyl(s * 8, 0, 4, 24, 2.3, "HullGrey")
		f.Cone(s * 8, 0, 25, 29, 2.3, 0.4, "HullOrange")
	end
	beacon(f, 0, 3, 0, SIZE * 3.2, AMBER, 40)
	-- The gantry
	f.Box(-22, 0, -7, -14, 0, 1, "HullDark")
	lattice(f, -18, -3, 1, 48, 3.5, 2.5, "HullDark", "HullGrey")
	for h = 12, 44, 8 do
		f.Box(-21, h, -6, -15, h, 0, "HullGrey")
	end
	f.Box(-15, 38, -3, -6, 38, -1, "HullOrange")
	f.Box(-22, 49, -7, -14, 50, 1, "HullWhite")
	f.Line(v3(-18, 51, -3), v3(-18, 58, -3), 0, "HullDark")
	beacon(f, -18, 59, -3, SIZE * 1.4, RED, 40)
end

-- West: a starship that came down hard, nose in the ground, in a yard of scrap, tyres and
-- traffic cones
function Builds.CrashedShip(f: Shapes.Frame)
	local ctx = f.Ctx
	local nose, tail = -25, 25
	for u = nose, tail do
		-- Its middle climbs from the buried nose to the raised tail
		local t = (u - nose) / (tail - nose)
		local center = -1 + t * 15
		local r = 9 * math.sqrt(math.max(0.08, 1 - (1 - t * 1.15) ^ 2)) * (if t > 0.8 then 1.1 - (t - 0.8) * 1.5 else 1)
		-- A torn gap in the hull shows the ribs
		local torn = u >= 4 and u <= 11
		local reach = math.ceil(r)
		for dh = -reach, reach do
			for dv = -reach, reach do
				local d = math.sqrt(dh * dh + (dv * 0.85) ^ 2)
				if d <= r and d > r - 1.6 then
					local h = math.round(center + dh)
					local keep = not torn or u % 3 == 0 or dh < -2 or ctx.Hash(u, h, dv) < 0.12
					if keep and h >= 1 then
						local burnt = ctx.Noise(u, h + dv, 6, 91) > 0.18
						local paint = if burnt
							then "HullDark"
							elseif dh < -2 then "HullGrey"
							elseif math.abs(dh - 3) <= 1 then "HullOrange"
							else "HullWhite"
						f.Set(u, h, dv, paint)
					end
				end
			end
		end
	end
	-- The wings, one snapped short
	f.Box(10, 6, 9, 22, 7, 22, "HullGrey")
	f.Box(18, 8, 9, 22, 9, 16, "HullOrange")
	f.Line(v3(14, 9, -9), v3(18, 2, -17), 1.5, "HullGrey")
	-- The tail fin and three engines still glowing
	f.Line(v3(21, 20, 0), v3(27, 30, 0), 1.5, "HullWhite")
	for _, c in { { 12, 0 }, { 16, -5 }, { 16, 5 } } do
		f.Line(v3(25, c[1], c[2]), v3(29, c[1] + 1, c[2]), 2, "HullDark")
		f.Cyl(30, c[2], c[1] + 1, c[1] + 1, 0.2, "HullGlow")
		beacon(f, 30, c[1] + 1, c[2], SIZE * 2, AMBER, 26)
	end
	Decor.Smoke(ctx.Decor, f.Pos(4, 12, 0))
	Decor.Smoke(ctx.Decor, f.Pos(8, 10, 3))
	Decor.Smoke(ctx.Decor, f.Pos(28, 16, 0))
	-- The ridge the nose ploughed up
	for du = -6, 6 do
		for dv = -7, 7 do
			if du * du + dv * dv * 0.8 <= 40 then
				f.Free(-28 + du, 1, dv, "RustGround")
				if du * du + dv * dv <= 16 then
					f.Free(-28 + du, 2, dv, "Gravel")
				end
			end
		end
	end
	-- The yard
	tyres(f, -16, 19, 5, 3)
	tyres(f, -3, 22, 4, 2)
	f.Tyre(-22, 7, -14, 6, 1.8, "Rubber")
	trafficCone(f, 5, 24, 10, 3)
	trafficCone(f, 12, -22, 8, 2.5)
	trafficCone(f, -8, -22, 7, 2.5)
	scrap(f, -19, 3, 4)
	scrap(f, 1, -19, 5)
	scrap(f, 24, -14, 4)
	-- Fuel tanks
	for i, u in { -12, -3 } do
		f.Cyl(u, -14 + i, 1, 7, 4, function(_, h)
			return if h == 5 then "HullOrange" else "HullWhite"
		end)
		f.Dome(u, 8, -14 + i, 4, 2, 4, "HullWhite")
	end
end

-- The inner ring ------------------------------------------------------------------------

function Builds.CommsTower(f: Shapes.Frame)
	f.Cyl(0, 0, 0, 0, 9, "SmoothStone")
	f.Ring(0, 0, 0, 10, 1, "Hazard")
	lattice(f, 0, 0, 1, 38, 6, 1, "HullDark", "HullGrey")
	f.Cyl(0, 0, 21, 21, 5, "HullOrange")
	f.Ring(0, 0, 22, 5, 1, "HullWhite")
	f.Cyl(0, 0, 31, 32, 3, "HullWhite")
	for _, s in { -1, 1 } do
		-- A round aerial either side
		f.Dome(s * 4, 26, 0, 3, 2, 3, "HullWhite", 1)
		f.Line(v3(s * 4, 26, 0), v3(s * 2, 26, 0), 0, "HullDark")
	end
	f.Line(v3(0, 39, 0), v3(0, 46, 0), 0, "HullDark")
	beacon(f, 0, 47, 0, SIZE * 1.3, RED, 40)
	-- The hut at its foot
	f.Box(-3, 1, -9, 3, 5, -5, "HullWhite")
	f.Box(-4, 6, -10, 4, 6, -4, "HullOrange")
	f.Box(-1, 1, -4, 1, 3, -4, "HullDark")
end

-- A glass dome you can walk into, a little garden inside
function Builds.GlassDome(f: Shapes.Frame)
	local ctx = f.Ctx
	f.Cyl(0, 0, 0, 0, 16, "SmoothStone")
	f.Ring(0, 0, 0, 17, 1, "HullWhite")
	f.Cyl(0, 0, 0, 0, 11, "Grass")
	f.Dome(0, 1, 0, 15, 14, 15, function(u, h, v)
		-- Four doors, one each way
		if h <= 5 and (math.abs(u) <= 2 or math.abs(v) <= 2) then
			return nil
		end
		local a = math.atan2(v, u)
		return if (a * 8 / math.pi) % 2 < 0.25 or h % 4 == 1 then "HullWhite" else "Glass"
	end, 1)
	for _, c in { { 2, 0 }, { -2, 0 } } do
		f.Box(c[1] + math.sign(c[1]), 1, -16, c[1] + math.sign(c[1]), 5, -14, "HullOrange")
		f.Box(c[1] + math.sign(c[1]), 1, 14, c[1] + math.sign(c[1]), 5, 16, "HullOrange")
		f.Box(-16, 1, c[1] + math.sign(c[1]), -14, 5, c[1] + math.sign(c[1]), "HullOrange")
		f.Box(14, 1, c[1] + math.sign(c[1]), 16, 5, c[1] + math.sign(c[1]), "HullOrange")
	end
	pool(f, 4, -4, 3.5, "Sand", "Sand")
	for _, c in { { -6, 4, 7 }, { 5, 6, 6 }, { -5, -6, 5 } } do
		local x, y, z = f.Cell(c[1], 0, c[2])
		Shapes.BigTree(ctx, x, y, z, c[3], 2.8, "CherryWood", "CherryLeaves")
	end
	beacon(f, 0, 13, 0, SIZE * 1.5, CYAN, 50)
end

-- A monorail running across the island, a train stopped at its station
function Builds.Monorail(f: Shapes.Frame, radius: number)
	local reach = radius + 5
	f.Box(-reach, 9, -1, reach, 10, 1, "HullWhite")
	f.Box(-reach, 11, 0, reach, 11, 0, "HullDark")
	for u = -radius + 2, radius - 2, 12 do
		f.Box(u - 1, 1, -1, u + 1, 8, 1, "HullGrey")
		f.Box(u - 3, 8, -2, u + 3, 8, 2, "HullDark")
	end
	-- The broken ends of the line
	for _, s in { -1, 1 } do
		f.Box(s * (reach + 1), 9, -1, s * (reach + 1), 9, 0, "HullDark")
		f.Line(v3(s * reach, 9, 1), v3(s * (reach + 4), 7, 1), 0, "HullOrange")
	end
	-- The station: a platform, a roof on thin legs, steps up from the citadel side
	f.Box(-13, 1, 3, 13, 6, 8, function(_, h, v)
		return if h == 6 then (if v == 3 then "Hazard" else "HullDark") else "HullGrey"
	end)
	stairs(f, -3, 3, 9, 6, "HullGrey")
	for _, u in { -12, -4, 4, 12 } do
		f.Box(u, 7, 7, u, 12, 7, "HullDark")
	end
	f.Box(-14, 13, 1, 14, 13, 8, "HullWhite")
	f.Box(-14, 14, 2, 14, 14, 7, "HullOrange")
	strip(f, v3(-12, 12.45, 5), v3(12, 12.45, 5), 0.6, CYAN)
	-- The train, on top of the beam
	f.Box(-11, 12, -3, 11, 17, 3, function(_, h, v)
		if h == 15 or h == 16 then
			return if math.abs(v) == 3 then "Glass" else "HullGrey"
		end
		return if h == 13 then "HullOrange" else "HullWhite"
	end)
	f.Box(-13, 12, -2, -12, 15, 2, "HullOrange")
	f.Box(12, 12, -2, 13, 15, 2, "HullOrange")
end

-- A flying saucer hanging over a crop circle, its beam on
function Builds.Ufo(f: Shapes.Frame)
	f.Ring(0, 0, 0, 13, 2, "CoarseDirt")
	f.Ring(0, 0, 0, 8, 1, "CoarseDirt")
	f.Cyl(0, 0, 0, 0, 3, "CoarseDirt")
	local lift = 16
	f.Cyl(0, 0, lift, lift, 6, "HullDark")
	f.Cyl(0, 0, lift + 1, lift + 1, 10, "HullGrey")
	f.Cyl(0, 0, lift + 2, lift + 2, 13, function(u, _, v)
		local a = math.atan2(v, u)
		local spot = (a * 12 / math.pi) % 2 < 0.5
		return if math.sqrt(u * u + v * v) > 12 and spot then "HullGlow" else "HullWhite"
	end)
	f.Cyl(0, 0, lift + 3, lift + 3, 11, "HullWhite")
	f.Cyl(0, 0, lift + 4, lift + 4, 8, "HullOrange")
	f.Dome(0, lift + 5, 0, 6, 6, 6, "Glass", 1)
	beacon(f, 0, lift + 7, 0, SIZE * 2, CYAN, 40)
	-- The beam
	local beam = Shapes.Glow(
		f.Ctx,
		Vector3.new(SIZE * lift, SIZE * 10, SIZE * 10),
		CFrame.new(f.Pos(0, lift / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		CYAN
	)
	beam.Shape = Enum.PartType.Cylinder
	beam.Transparency = 0.82
end

-- An open hangar you can run straight through, a fighter parked inside
function Builds.Hangar(f: Shapes.Frame)
	local r, half = 12, 13
	f.Box(-r - 1, 0, -half - 1, r + 1, 0, half + 1, function(u, _, v)
		return if math.abs(u) == r + 1 or math.abs(v) == half + 1 then "Hazard" else "HullGrey"
	end)
	for v = -half, half do
		local rib = (v + half) % 6 == 0
		for u = -r, r do
			for h = 1, r do
				local d = math.sqrt(u * u + h * h)
				if d <= r and d > r - (if rib then 2.2 else 1.3) then
					f.Set(u, h, v, if rib then "HullOrange" else "HullWhite")
				end
			end
		end
	end
	strip(f, v3(0, r - 1.4, -half), v3(0, r - 1.4, half), 0.6, CYAN)
	-- The fighter
	f.Line(v3(0, 4, -7), v3(0, 4, 7), 1.5, "HullWhite")
	f.Line(v3(0, 4, 8), v3(0, 4, 10), 0.5, "HullOrange")
	f.Box(-1, 5, 3, 1, 6, 6, "Glass")
	f.Box(-8, 3, -5, 8, 3, 2, "HullGrey")
	f.Box(-8, 4, -2, -7, 4, 2, "HullOrange")
	f.Box(7, 4, -2, 8, 4, 2, "HullOrange")
	f.Box(0, 5, -7, 0, 9, -3, "HullOrange")
	for _, c in { { -3, 3 }, { 3, 3 }, { 0, -5 } } do
		f.Box(c[1], 1, c[2], c[1], 2, c[2], "HullDark")
	end
	beacon(f, 0, 4, -8.5, SIZE, AMBER, 12)
	-- Crates down one side, for cover
	f.Box(-10, 1, 6, -8, 3, 9, "Crate")
	f.Box(8, 1, -11, 10, 2, -7, "Crate")
	f.Box(-10, 1, -10, -8, 2, -8, "Barrel")
end

-- Sharp cliffs of dark rock split by purple crystal
function Builds.CrystalCliffs(f: Shapes.Frame)
	local ctx = f.Ctx
	local function rock(u: number, h: number, v: number): string?
		local patch = ctx.Noise(u + h * 0.6, v - h * 0.6, 6, 61)
		return if patch > 0.18 then "Stone" elseif patch < -0.26 then "Obsidian" else "DarkStone"
	end
	local cliffs = { { -12, -6, 26, 6 }, { 11, -9, 32, 7 }, { 1, 8, 20, 5 }, { -9, 12, 16, 4 }, { 13, 10, 13, 4 } }
	for _, c in cliffs do
		f.Cone(c[1], c[2], 1, c[3], c[4], 1.4, rock)
	end
	-- Shards leaning out of the rock
	local rng = ctx.Rng
	for i = 1, 16 do
		local c = cliffs[(i - 1) % #cliffs + 1]
		local angle = rng:NextNumber(0, 2 * math.pi)
		local from = rng:NextInteger(2, math.max(3, c[3] - 8))
		local out = rng:NextNumber(4, 9)
		local base = v3(c[1] + math.cos(angle) * 2, from, c[2] + math.sin(angle) * 2)
		local tip = v3(c[1] + math.cos(angle) * out, from + rng:NextNumber(5, 11), c[2] + math.sin(angle) * out)
		f.Line(base, base:Lerp(tip, 0.6), 1.2, "PurpleCrystal")
		f.Line(base:Lerp(tip, 0.6), tip, 0.4, "PurpleCrystal")
	end
	-- Crystal trees
	for _, c in { { -2, -14, 7 }, { 5, 3, 6 }, { -15, 6, 6 } } do
		local x, y, z = f.Cell(c[1], 0, c[2])
		Shapes.BigTree(ctx, x, y, z, c[3], 3, "DarkPlanks", "PurpleCrystal")
	end
	beacon(f, 11, 33, -9, SIZE * 1.6, MAGENTA, 50)
	beacon(f, -12, 27, -6, SIZE * 1.3, MAGENTA, 40)
	beacon(f, 1, 21, 8, SIZE * 1.1, MAGENTA, 30)
end

-- The head of a huge old robot, half buried, moss all over it
function Builds.MechHead(f: Shapes.Frame)
	local ctx = f.Ctx
	local function plate(u: number, h: number, v: number): string?
		local moss = ctx.Noise(u + v, h, 5, 83) + (h - 6) * 0.035
		if moss > 0.28 then
			return "MossyCobblestone"
		elseif moss > 0.12 then
			return "MossyStoneBricks"
		end
		return if ctx.Hash(u, h, v) < 0.14 then "HullDark" else "HullGrey"
	end
	f.Box(-10, -1, -9, 10, 13, 9, plate)
	-- Visor, with one eye still working
	f.Box(-9, 6, 10, 9, 10, 10, "HullDark")
	f.Box(-7, 7, 11, -3, 9, 11, "RedWool")
	beacon(f, -5, 8, 11.6, SIZE * 2.4, RED, 40)
	f.Box(3, 7, 11, 7, 9, 11, "CrackedStoneBricks")
	-- Jaw and teeth
	f.Box(-8, 1, 10, 8, 3, 12, "HullGrey")
	for u = -7, 7, 3 do
		f.Box(u, 4, 11, u + 1, 5, 11, "HullWhite")
	end
	-- Ears and a bent aerial
	f.Box(-13, 3, -4, -11, 11, 4, "HullOrange")
	f.Box(11, 3, -4, 13, 11, 4, "RustGround")
	f.Line(v3(5, 14, -2), v3(8, 21, -2), 0.5, "HullDark")
	f.Line(v3(8, 21, -2), v3(14, 23, -2), 0.5, "HullDark")
	-- Bushes growing on top
	for _, c in { { -5, -3, 3.4 }, { 4, 3, 2.6 }, { 6, -5, 2.6 }, { -3, 5, 2 } } do
		f.Ball(c[1], 14, c[2], c[3], c[3] * 0.65, c[3], "Leaves", 1.3)
	end
end

-- A big radar dish tipped toward the sky
function Builds.RadarDish(f: Shapes.Frame)
	f.Cyl(0, 0, 0, 0, 8, "SmoothStone")
	f.Ring(0, 0, 0, 9, 1, "Hazard")
	f.Cyl(0, 0, 1, 3, 6, "HullDark")
	f.Cyl(0, 0, 4, 12, 3, "HullGrey")
	f.Ring(0, 0, 8, 4, 1, "HullOrange")
	local tilt = math.rad(50)
	local center = v3(0, 18, 0)
	local axis = v3(0, math.sin(tilt), math.cos(tilt))
	local side = v3(1, 0, 0)
	local up = v3(0, math.cos(tilt), -math.sin(tilt))
	local r = 14
	local a = -r
	while a <= r do
		local b = -r
		while b <= r do
			local d = math.sqrt(a * a + b * b)
			if d <= r then
				local depth = d * d / (4 * 9)
				local p = center + side * a + up * b + axis * depth
				local paint = if d > r - 1.3
					then "HullOrange"
					elseif math.abs(a) < 0.6 or math.abs(b) < 0.6 then "HullGrey"
					else "HullWhite"
				f.Set(math.round(p.X), math.round(p.Y), math.round(p.Z), paint)
			end
			b += 0.5
		end
		a += 0.5
	end
	-- The horn on its three struts
	local horn = center + axis * 11
	for i = 0, 2 do
		local angle = i * 2 * math.pi / 3
		f.Line(center + side * (math.cos(angle) * 8) + up * (math.sin(angle) * 8) + axis * 2, horn, 0, "HullDark")
	end
	f.Ball(horn.X, horn.Y, horn.Z, 2, 2, 2, "HullOrange")
	f.Line(v3(0, 12, 0), center, 1.5, "HullDark")
	beacon(f, horn.X, horn.Y + 1, horn.Z, SIZE, RED, 30)
	-- A hut
	f.Box(-13, 1, -5, -8, 5, 3, "HullWhite")
	f.Box(-14, 6, -6, -7, 6, 4, "HullOrange")
end

-- An escape pod in the crater it made, its parachute dragged across the ground
function Builds.EscapePod(f: Shapes.Frame)
	local ctx = f.Ctx
	f.Ball(0, 0, 1, 6, 6, 8, function(u, h, v)
		if h <= -2 then
			return nil
		end
		if v >= 6 and h >= 1 and math.abs(u) <= 2 then
			return "Glass"
		end
		if math.abs(v - 1) <= 1 then
			return "HullOrange"
		end
		return if ctx.Noise(u, h + v, 4, 73) > 0.22 then "HullDark" else "HullWhite"
	end)
	f.Cyl(0, -7, 0, 2, 2, "HullDark")
	beacon(f, 0, 2, -8, SIZE * 1.2, AMBER, 18)
	Decor.Smoke(ctx.Decor, f.Pos(0, 6, -3))
	Decor.Smoke(ctx.Decor, f.Pos(2, 5, 2))
	-- The chute: red and white panels over the crater's rim
	for u = -7, 3 do
		for v = -14, -9 do
			local rise = if ctx.Hash(u, 5, v) < 0.25 then 2 else 1
			f.Set(u, rise, v, if (u + 20) % 4 < 2 then "RedWool" else "WhiteWool")
		end
	end
	for _, u in { -6, -2, 2 } do
		f.Line(v3(u, 2, -9), v3(0, 3, -7), 0, "WhiteWool")
	end
end

-- The outer ring ------------------------------------------------------------------------

-- Three wind turbines turning over a green hill
function Builds.Turbines(f: Shapes.Frame)
	local spots = { { 0, -6, 34 }, { -10, 6, 26 }, { 10, 7, 22 } }
	for i, c in spots do
		local top = c[3]
		f.Box(c[1] - 2, 0, c[2] - 2, c[1] + 2, 1, c[2] + 2, "HullGrey")
		f.Cone(c[1], c[2], 2, top, 2, 0.8, function(_, h)
			return if h % 12 == 0 then "HullOrange" else "HullWhite"
		end)
		f.Box(c[1] - 1, top + 1, c[2] - 3, c[1] + 1, top + 2, c[2] + 1, "HullGrey")
		local hub = f.Pos(c[1], top + 1.5, c[2] + 2.5)
		rotor(f, hub, f.Facing, if i == 1 then 30 else 24, 40 + i * 15)
	end
end

-- A squat concrete bunker to fight through, a twin gun on its roof
function Builds.Bunker(f: Shapes.Frame)
	local ctx = f.Ctx
	local function wall(u: number, h: number, v: number): string?
		local roll = ctx.Hash(u, h, v)
		return if roll < 0.2 then "CrackedStoneBricks" elseif roll < 0.3 then "MossyStoneBricks" else "StoneBricks"
	end
	f.Box(-12, 1, -9, 12, 6, 9, wall)
	f.Box(-13, 7, -10, 13, 7, 10, "SmoothStone")
	f.Box(-10, 8, -8, 10, 8, 8, "SmoothStone")
	-- Hollow, with doors at both ends and firing slits along the front
	f.Box(-10, 1, -7, 10, 5, 7, nil)
	f.Box(-2, 1, 8, 2, 4, 9, nil)
	f.Box(-2, 1, -9, 2, 4, -8, nil)
	f.Box(-12, 1, -2, -11, 4, 2, nil)
	f.Box(11, 1, -2, 12, 4, 2, nil)
	f.Box(-3, 1, 9, -3, 5, 9, "Hazard")
	f.Box(3, 1, 9, 3, 5, 9, "Hazard")
	for _, u in { -8, 7 } do
		f.Box(u, 4, 8, u + 1, 4, 9, nil)
	end
	-- The gun
	f.Cyl(0, 0, 9, 10, 4, "HullDark")
	f.Box(-3, 11, -3, 3, 13, 3, "HullGrey")
	f.Box(-1, 12, 4, -1, 12, 12, "HullDark")
	f.Box(1, 12, 4, 1, 12, 12, "HullDark")
	f.Line(v3(-8, 9, -6), v3(-8, 16, -6), 0, "HullDark")
	beacon(f, -8, 17, -6, SIZE * 0.8, RED, 20)
	-- Sandbags
	for _, c in { { -14, 12, -8, 12 }, { 8, 13, 15, 13 } } do
		f.Box(c[1], 1, c[2], c[3], 2, c[4], "SmoothStone")
	end
end

-- Rows of tilted solar panels and a little control hut
function Builds.SolarFarm(f: Shapes.Frame)
	local ctx = f.Ctx
	f.Box(-3, 1, -3, 3, 6, 3, "HullWhite")
	f.Box(-4, 7, -4, 4, 7, 4, "HullOrange")
	f.Line(v3(0, 8, 0), v3(0, 16, 0), 0, "HullDark")
	beacon(f, 0, 17, 0, SIZE, CYAN, 26)
	local navy = Color3.fromRGB(26, 44, 92)
	local tilt = math.rad(35)
	for _, row in { -12, -6, 6, 12 } do
		for _, u in { -10, 0, 10 } do
			if not (row == -6 and u == 0) and not (row == 6 and u == 0) then
				for _, s in { -3, 3 } do
					f.Box(u + s, 1, row, u + s, 3, row, "HullDark")
				end
				local at = CFrame.lookAt(f.Pos(u, 3.6, row), f.Pos(u, 3.6, row) + f.Dir(0, 0, 1))
					* CFrame.Angles(-tilt, 0, 0)
				local panel = Decor.Part(
					ctx.Decor,
					"SolarPanel",
					Vector3.new(SIZE * 8, 0.5, SIZE * 4),
					at,
					navy,
					Enum.Material.Glass
				)
				panel.Reflectance = 0.25
				for i = -1, 1 do
					Shapes.Glow(
						ctx,
						Vector3.new(SIZE * 8, 0.1, 0.25),
						at * CFrame.new(0, 0.3, i * SIZE * 1.3),
						Color3.fromRGB(120, 180, 255)
					)
				end
				Decor.Part(
					ctx.Decor,
					"PanelFrame",
					Vector3.new(SIZE * 8.3, 0.4, SIZE * 4.3),
					at * CFrame.new(0, -0.3, 0),
					Color3.fromRGB(226, 228, 232),
					Enum.Material.Metal
				)
			end
		end
	end
end

-- A tangle of fat pipes, tanks and catwalks with steam leaking out
function Builds.PipeWorks(f: Shapes.Frame)
	local ctx = f.Ctx
	local tanks = { { -9, -6, 13, 5 }, { 9, -7, 16, 6 }, { -2, 9, 9, 4 } }
	for _, c in tanks do
		f.Cyl(c[1], c[2], 1, c[3], c[4], function(_, h)
			return if h % 5 == 0 then "HullOrange" else "HullWhite"
		end)
		f.Dome(c[1], c[3] + 1, c[2], c[4], 2, c[4], "HullGrey")
		Decor.Smoke(ctx.Decor, f.Pos(c[1], c[3] + 3, c[2]))
	end
	f.Line(v3(-9, 7, -6), v3(9, 7, -7), 1.6, "HullOrange")
	f.Line(v3(-2, 5, 9), v3(9, 5, -7), 1.6, "HullGrey")
	f.Line(v3(-2, 4, 9), v3(-9, 4, -6), 1.6, "HullOrange")
	f.Line(v3(9, 12, -7), v3(14, 12, 3), 1.2, "HullGrey")
	f.Line(v3(14, 12, 3), v3(14, 1, 3), 1.2, "HullGrey")
	-- Flanges every few blocks
	for u = -6, 6, 4 do
		f.Cyl(u, -6, 7, 7, 0.2, "HullDark")
		f.Box(u, 5, -8, u, 9, -5, "HullDark")
	end
	-- A catwalk over it all, with steps up
	f.Box(-14, 9, 1, 6, 9, 4, "HullDark")
	for _, c in { { -14, 1 }, { 6, 1 }, { -14, 4 }, { 6, 4 } } do
		f.Box(c[1], 1, c[2], c[1], 8, c[2], "HullGrey")
	end
	stairs(f, -13, -11, 5, 8, "HullGrey")
	Decor.Smoke(ctx.Decor, f.Pos(0, 8, -6))
	beacon(f, 14, 14, 3, SIZE, AMBER, 20)
end

-- A drill rig: its derrick stands over the island and the bit pokes out underneath
function Builds.DrillRig(f: Shapes.Frame, radius: number)
	local ctx = f.Ctx
	f.Box(-11, 1, -11, 11, 2, 11, function(u, _, v)
		return if math.abs(u) == 11 or math.abs(v) == 11 then "Hazard" else "HullDark"
	end)
	stairs(f, -2, 2, 12, 2, "HullGrey")
	lattice(f, 0, 0, 3, 38, 9, 2, "HullOrange", "HullDark")
	f.Box(-3, 39, -3, 3, 40, 3, "HullWhite")
	beacon(f, 0, 41, 0, SIZE * 1.1, RED, 36)
	-- The shaft, right through the island and out of the rock
	local bottom = -math.floor(radius * 1.25)
	f.Cyl(0, 0, bottom, 36, 2, function(_, h)
		return if h % 4 == 0 then "HullOrange" else "HullGrey"
	end)
	f.Cone(0, 0, bottom - 7, bottom - 1, 0.4, 3.5, function(_, h)
		return if h % 2 == 0 then "HullOrange" else "HullDark"
	end)
	-- Winch house and a heap of spoil
	f.Box(5, 3, -9, 10, 7, -4, "HullWhite")
	f.Box(5, 8, -9, 10, 8, -4, "HullOrange")
	for du = -5, 5 do
		for dv = -5, 5 do
			local d = math.sqrt(du * du + dv * dv)
			if d <= 5 then
				for h = 3, 3 + math.floor((5 - d) * 0.9) do
					f.Free(-7 + du, h, -6 + dv, if ctx.Hash(du, h, dv) < 0.6 then "Gravel" else "CoarseDirt")
				end
			end
		end
	end
end

-- A research base on a snowy island
function Builds.SnowLab(f: Shapes.Frame)
	local ctx = f.Ctx
	f.Cyl(-6, -2, 1, 2, 8, "HullDark")
	f.Dome(-6, 3, -2, 7, 7, 7, function(u, h, v)
		local a = math.atan2(v + 2, u + 6)
		return if (a * 8 / math.pi) % 2 < 0.3 or h % 4 == 0 then "HullGrey" else "HullWhite"
	end, 1.5)
	f.Cyl(8, 2, 1, 1, 5, "HullDark")
	f.Dome(8, 2, 2, 5, 5, 5, "HullWhite", 1.3)
	-- The corridor between them
	f.Box(-1, 1, -1, 5, 4, 3, "HullWhite")
	f.Box(-1, 5, -1, 5, 5, 3, "HullOrange")
	f.Box(-1, 2, 3, 5, 3, 3, "Glass")
	-- A snowed-in aerial and a frozen pond
	f.Line(v3(-6, 10, -2), v3(-6, 18, -2), 0, "HullDark")
	beacon(f, -6, 19, -2, SIZE, RED, 24)
	f.Dome(8, 8, 2, 2, 1, 2, "HullOrange")
	for du = -6, 6 do
		for dv = -5, 5 do
			if du * du + dv * dv * 1.3 <= 32 then
				f.Set(-1 + du, 0, 11 + dv, "Ice")
				f.Set(-1 + du, -1, 11 + dv, "Stone")
			end
		end
	end
	local centre = f.Pos(0, 20, 0)
	Decor.Falling(ctx.Decor, centre, Vector2.new(SIZE * 36, SIZE * 36), "Snow")
end

-- A yard of shipping containers: a maze with a crane over it
function Builds.CargoStacks(f: Shapes.Frame, radius: number)
	local paints = { "HullOrange", "HullWhite", "RedWool", "HullDark", "HullGrey", "Terracotta" }
	local ctx = f.Ctx
	local reach = radius - 8
	f.Box(-reach - 1, 0, -reach - 1, reach + 1, 0, reach + 1, "HullGrey")
	for row = -1, 1 do
		for col = -1, 1 do
			if not (row == 0 and col == 0) then
				local alongU = (row + col) % 2 == 0
				local u, v = col * 13, row * 10
				local levels = 1 + math.floor(ctx.Hash(u, 3, v) * 3)
				for level = 0, levels - 1 do
					local paint = paints[math.floor(ctx.Hash(u, level, v) * #paints) + 1]
					container(f, u, 1 + level * 4, v, alongU, paint)
				end
			end
		end
	end
	-- The gantry crane straddling the yard
	for _, c in { { -17, -12 }, { -17, 12 }, { 17, -12 }, { 17, 12 } } do
		f.Box(c[1] - 1, 1, c[2] - 1, c[1] + 1, 20, c[2] + 1, "HullOrange")
	end
	f.Box(-18, 21, -13, 18, 22, -11, "HullOrange")
	f.Box(-18, 21, 11, 18, 22, 13, "HullOrange")
	f.Box(-3, 23, -13, 3, 24, 13, "HullWhite")
	f.Box(-1, 15, -1, 1, 22, 1, "HullDark")
	container(f, 0, 11, 0, true, "HullOrange")
	beacon(f, 0, 25, 0, SIZE, AMBER, 26)
end

-- A four-legged walker mech, standing guard
function Builds.WalkerMech(f: Shapes.Frame)
	for _, s in { -1, 1 } do
		for _, t in { -1, 1 } do
			local hip = v3(s * 8, 19, t * 7)
			local knee = v3(s * 16, 15, t * 13)
			local foot = v3(s * 14, 2, t * 12)
			f.Line(hip, knee, 1.6, "HullGrey")
			f.Line(knee, foot, 1.6, "HullWhite")
			f.Ball(knee.X, knee.Y, knee.Z, 2.4, 2.4, 2.4, "HullOrange")
			f.Box(s * 14 - 3, 1, t * 12 - 3, s * 14 + 3, 1, t * 12 + 3, "HullDark")
		end
	end
	f.Box(-9, 17, -8, 9, 24, 9, function(u, h, v)
		if h == 20 and (math.abs(u) == 9 or math.abs(v) >= 8) then
			return "HullOrange"
		end
		return if h >= 23 then "HullGrey" else "HullWhite"
	end)
	f.Box(-5, 25, -5, 5, 28, 6, "HullGrey")
	f.Box(-4, 26, 7, 4, 27, 7, "Glass")
	f.Box(-6, 20, 10, 6, 22, 10, "HullDark")
	f.Box(-3, 21, 11, -2, 21, 11, "HullGlow")
	f.Box(2, 21, 11, 3, 21, 11, "HullGlow")
	-- Guns under the chin and a mast
	for _, s in { -1, 1 } do
		f.Box(s * 6, 18, 10, s * 6, 18, 19, "HullDark")
		f.Box(s * 7, 18, 10, s * 7, 18, 16, "HullDark")
	end
	f.Line(v3(3, 29, -3), v3(3, 35, -3), 0, "HullDark")
	beacon(f, 3, 36, -3, SIZE * 0.9, RED, 24)
	beacon(f, 0, 21, 11.5, SIZE * 1.4, CYAN, 26)
end

-- A beach round a lagoon, a hover barge wrecked on the sand, palm trees leaning over it
function Builds.BeachWreck(f: Shapes.Frame)
	local ctx = f.Ctx
	pool(f, 4, 5, 8, "Sand", "Sand")
	-- The barge: a pointed hull run up the sand, nose in the air, open on top
	local length = 13
	for u = -length, length do
		local half = math.round(5.5 * math.sqrt(math.max(0, 1 - (u / (length + 1)) ^ 4)))
		local lift = math.round((u + length) / (2 * length) * 6)
		for v = -half, half do
			for h = 0, 4 do
				local wall = math.abs(v) == half or math.abs(u) == length
				if (wall or h == 0) and ctx.Hash(u, h + 11, v) > 0.05 then
					local paint = if h == 4
						then "HullOrange"
						elseif h == 0 then "HullDark"
						elseif u % 5 == 0 then "HullGrey"
						else "HullWhite"
					f.Set(u - 3, lift + h, v - 10, paint)
				end
			end
		end
	end
	-- Its wheelhouse and a mast with a torn flag
	f.Box(-13, 5, -13, -7, 8, -7, "HullWhite")
	f.Box(-12, 7, -7, -8, 7, -7, "Glass")
	f.Box(-14, 9, -14, -6, 9, -6, "HullOrange")
	f.Line(v3(-3, 5, -10), v3(0, 17, -10), 0.5, "HullDark")
	f.Box(1, 13, -10, 7, 16, -10, function(u, h)
		return if ctx.Hash(u, h, 3) < 0.25 then nil else "RedWool"
	end)
	-- Cargo washed up along the shore
	f.Box(9, 1, -6, 11, 3, -4, "Crate")
	f.Box(12, 1, -6, 13, 2, -5, "Crate")
	f.Box(-12, 1, 3, -10, 2, 5, "Barrel")
	f.Box(-8, 1, 9, -7, 2, 10, "Crate")
	for _, c in { { -12, 10, 15 }, { 14, -7, 13 }, { -9, -3, 12 }, { 13, 11, 16 }, { 6, -13, 12 } } do
		local x, y, z = f.Cell(c[1], 0, c[2])
		Shapes.Palm(ctx, x, y, z, c[3])
	end
end

-- A giant robot dog, tail up
function Builds.RobotDog(f: Shapes.Frame)
	-- Legs
	for _, s in { -1, 1 } do
		for _, t in { -1, 1 } do
			f.Line(v3(s * 5, 11, t * 5), v3(s * 6, 2, t * 6), 1.8, "HullWhite")
			f.Box(s * 6 - 2, 1, t * 6 - 2, s * 6 + 2, 1, t * 6 + 3, "HullDark")
			f.Ball(s * 6, 7, t * 5.5, 2.3, 2.3, 2.3, "HullOrange")
		end
	end
	-- Body and collar
	f.Box(-6, 10, -8, 6, 18, 8, function(_, h, v)
		if math.abs(v) >= 7 then
			return "HullGrey"
		end
		return if h == 14 then "HullOrange" else "HullWhite"
	end)
	f.Line(v3(0, 17, 7), v3(0, 22, 10), 3, "HullGrey")
	f.Box(-5, 19, 7, 5, 20, 11, "HullOrange")
	beacon(f, 0, 19, 11.5, SIZE * 1.2, CYAN, 24)
	-- Head, snout, ears
	f.Box(-5, 21, 8, 5, 30, 17, "HullWhite")
	f.Box(-3, 21, 18, 3, 25, 23, "HullGrey")
	f.Box(-2, 25, 23, 2, 26, 23, "HullDark")
	f.Box(-4, 26, 18, -2, 28, 18, "HullGlow")
	f.Box(2, 26, 18, 4, 28, 18, "HullGlow")
	f.Box(-7, 23, 10, -6, 31, 14, "HullOrange")
	f.Box(6, 23, 10, 7, 31, 14, "HullOrange")
	-- Tail
	f.Line(v3(0, 17, -9), v3(0, 23, -13), 1, "HullGrey")
	f.Line(v3(0, 23, -13), v3(0, 29, -12), 0.6, "HullOrange")
	-- A ball to fetch
	f.Ball(-11, 3, 11, 2.6, 2.6, 2.6, "HullOrange")
end

-- A stepped jungle temple with something very old glowing on top
function Builds.JungleRuin(f: Shapes.Frame)
	local ctx = f.Ctx
	local function stone(u: number, h: number, v: number): string?
		local roll = ctx.Hash(u, h, v)
		if roll < 0.35 then
			return "MossyStoneBricks"
		end
		return if roll < 0.5 then "CrackedStoneBricks" else "StoneBricks"
	end
	for i = 0, 4 do
		local w = 13 - i * 2
		f.Box(-w, 1 + i * 2, -w, w, 2 + i * 2, w, stone)
	end
	-- The stair up the front
	for i = 0, 9 do
		f.Box(-2, 1 + i, 13 - i, 2, 1 + i, 14 - i, "Cobblestone")
	end
	Shapes.Ramp(ctx, f.Pos(0, 10.5, 4.5), f.Pos(0, 0.5, 14.5), SIZE * 5)
	-- The shrine: four pillars, a roof and the core
	for _, c in { { -3, -3 }, { 3, -3 }, { 3, 3 }, { -3, 3 } } do
		f.Box(c[1], 11, c[2], c[1], 15, c[2], "MossyStoneBricks")
	end
	f.Box(-4, 16, -4, 4, 16, 4, stone)
	f.Box(-2, 17, -2, 2, 17, 2, stone)
	f.Box(-1, 11, -1, 1, 11, 1, "HullDark")
	beacon(f, 0, 13.5, 0, SIZE * 2, CYAN, 50)
	-- Water running off the back
	local lip = f.Pos(0, 2.5, -14)
	Decor.Waterfall(ctx.Decor, lip, f.Dir(0, 0, -1), SIZE * 3, SIZE * 4)
end

-- Tall black data pylons round a glowing globe
function Builds.DataPylons(f: Shapes.Frame)
	f.Cyl(0, 0, 0, 0, 14, "HullWhite")
	f.Ring(0, 0, 0, 15, 2, "HullDark")
	f.Ring(0, 0, 0, 9, 1, "HullGlow")
	for i = 0, 4 do
		local angle = i * 2 * math.pi / 5 + math.pi / 10
		local u, v = math.round(math.cos(angle) * 11), math.round(math.sin(angle) * 11)
		local top = 18 + (i % 3) * 5
		f.Box(u - 1, 1, v - 1, u + 1, top, v + 1, "HullDark")
		f.Box(u - 2, 1, v - 2, u + 2, 2, v + 2, "HullGrey")
		local out = f.Dir(math.sign(math.cos(angle)), 0, 0)
		local bottom = f.Pos(u, 3, v) + out * (SIZE * 1.55)
		local up = f.Pos(u, top, v) + out * (SIZE * 1.55)
		Shapes.Glow(f.Ctx, Vector3.new(0.7, (up - bottom).Magnitude, 0.7), CFrame.new((bottom + up) / 2), CYAN)
		local cube = Shapes.Glow(
			f.Ctx,
			Vector3.new(SIZE, SIZE, SIZE),
			CFrame.new(f.Pos(u, top + 3, v)) * CFrame.Angles(0.6, 0.6, 0.6),
			CYAN
		)
		Shapes.Light(cube, CYAN, 24, 1.5)
		f.Line(v3(u, 1, v), v3(0, 1, 0), 0, "HullDark")
	end
	f.Cyl(0, 0, 1, 5, 1, "HullGrey")
	f.Ball(0, 10, 0, 4.5, 4.5, 4.5, function(u, h, v)
		local a = math.atan2(v, u)
		return if (a * 6 / math.pi) % 2 < 0.5 or (h - 10) % 3 == 0 then "HullGlow" else nil
	end, 1)
	beacon(f, 0, 10, 0, SIZE * 2.2, CYAN, 40)
end

-- A white observatory on a stepped base, its telescope out of the slit
function Builds.Observatory(f: Shapes.Frame)
	f.Cyl(0, 0, 1, 2, 13, "StoneBricks")
	f.Cyl(0, 0, 3, 4, 11, "SmoothStone")
	f.Cyl(0, 0, 5, 11, 9, function(u, h, v)
		local a = math.atan2(v, u)
		if h >= 7 and h <= 9 and (a * 8 / math.pi) % 2 < 0.5 then
			return "Glass"
		end
		return if h == 11 then "HullOrange" else "HullWhite"
	end, 6.5)
	f.Dome(0, 12, 0, 9, 9, 9, function(u, h, v)
		-- The slit
		if math.abs(u) <= 2 and v >= 0 and h >= 13 then
			return nil
		end
		local a = math.atan2(v, u)
		return if (a * 8 / math.pi) % 2 < 0.2 then "HullGrey" else "HullWhite"
	end, 1.5)
	f.Line(v3(0, 13, -1), v3(0, 26, 11), 2, function(_, h)
		return if h == 18 or h == 24 then "HullOrange" else "HullDark"
	end)
	f.Cyl(0, 0, 5, 12, 2, "HullGrey")
	beacon(f, 0, 27, 12, SIZE, CYAN, 26)
	-- Steps up the front, a door in the wall
	stairs(f, -2, 2, 12, 4, "StoneBricks")
	f.Box(-1, 5, 7, 1, 7, 9, nil)
end

return Builds
