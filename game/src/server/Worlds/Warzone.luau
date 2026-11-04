--!strict
-- The Warzone map, the Robot / sci-fi one: a net of floating islands round a safe citadel,
-- built for PvP ([[Warzone Rebuild Plan]], the look from [[Vaeron Warzones]]). Our own builds.
--   The citadel      the safe zone in the middle, where you arrive: a ring plaza with a glowing
--                    moat, a white wall with four gates, gardens, four towers and a very tall
--                    tower with the Sky Core shining in its neck
--   The inner ring   nine islands joined to it by four white causeways
--   The outer ring   thirteen more, further out
--   The landmarks    North, East, South and West, each a huge build with its name floating
--                    over it, so you always know where you are
-- Islands are joined three ways: white causeways from the gates, dark catwalks with glowing
-- edges on the main routes, and strings of stepping stones you hop along everywhere else.
-- Nothing here can be broken or built on.
--
-- Grid: north is -z and east is +x, a true compass (unlike the other worlds' files). y = 0 is
-- the citadel's ground.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local Decor = require(script.Parent.Parent.Util.Decor)
local Common = require(script.Parent.Common)
local Context = require(script.Parent.Context)
local Shapes = require(script.Parent.Shapes)
local Builds = require(script.Parent.WarzoneBuilds)

local SIZE = Blocks.Size
local CYAN = Color3.fromRGB(110, 226, 255)
local RED = Color3.fromRGB(255, 70, 60)
local key = BlockWorld.key

local WALL_IN, WALL_OUT = 43, 46
local PLAZA = 58
local GATE_HALF = 4
local TREE_SHARE = 1.2 -- each island plants this many times its listed trees, for cover

local Warzone = {}

Warzone.SouthZ = 0
Warzone.Seed = 77
-- The safe zone: no PvP within this many blocks of the middle
Warzone.SafeRadius = PLAZA
Warzone.OriginY = 200 -- where WarzoneService puts the ground of block height 0, in studs
-- Where you arrive: inside the south gate, facing the tower
Warzone.Arrival = { X = 0, Y = 0, Z = 38 }

-- The ground under an island's hero
type Ground = {
	Top: string,
	Alt: string,
	Path: string,
	Soil: string,
	Rock: { string },
	Hills: number,
	Natural: boolean,
}

local GROUNDS: { [string]: Ground } = {
	Grass = {
		Top = "Grass",
		Alt = "CoarseDirt",
		Path = "Gravel",
		Soil = "Dirt",
		Rock = { "Stone", "Terracotta", "Stone", "RedTerracotta" },
		Hills = 4,
		Natural = true,
	},
	Meadow = {
		Top = "Grass",
		Alt = "FlowerGrass",
		Path = "Path",
		Soil = "Dirt",
		Rock = { "Sandstone", "Terracotta", "Sandstone" },
		Hills = 5,
		Natural = true,
	},
	Rust = {
		Top = "RustGround",
		Alt = "CoarseDirt",
		Path = "Gravel",
		Soil = "RedTerracotta",
		Rock = { "Terracotta", "RedTerracotta", "Sandstone", "RedTerracotta" },
		Hills = 3,
		Natural = false,
	},
	Sand = {
		Top = "Sand",
		Alt = "Sand",
		Path = "Sand",
		Soil = "Sand",
		Rock = { "Sandstone", "Terracotta", "Sandstone" },
		Hills = 3,
		Natural = true,
	},
	Snow = {
		Top = "Snow",
		Alt = "SnowyGrass",
		Path = "Gravel",
		Soil = "Dirt",
		Rock = { "Stone", "SmoothStone", "Stone" },
		Hills = 5,
		Natural = true,
	},
	Dark = {
		Top = "CoarseDirt",
		Alt = "Gravel",
		Path = "Gravel",
		Soil = "Dirt",
		Rock = { "DarkStone", "Stone", "DarkStone" },
		Hills = 4,
		Natural = false,
	},
	Plate = {
		Top = "HullGrey",
		Alt = "HullGrey",
		Path = "HullDark",
		Soil = "HullDark",
		Rock = { "Stone", "DarkStone", "Stone" },
		Hills = 0,
		Natural = false,
	},
	Jungle = {
		Top = "Grass",
		Alt = "MossyCobblestone",
		Path = "Gravel",
		Soil = "Dirt",
		Rock = { "Stone", "Terracotta", "Stone" },
		Hills = 3,
		Natural = true,
	},
}

type Spec = {
	Id: string,
	Name: string,
	Angle: number, -- degrees clockwise from north
	Dist: number,
	R: number,
	Base: number,
	Ground: string,
	Hero: string,
	-- Trees over the rest of the island
	Pines: number?,
	SnowPines: number?,
	Oaks: number?,
	-- A landmark's name floats over it
	Word: string?,
	WordY: number?,
	Grass: number?,
}

local SPECS: { Spec } = {
	-- The landmarks
	{
		Id = "robot",
		Name = "Robot Stand",
		Angle = 0,
		Dist = 298,
		R = 54,
		Base = 6,
		Ground = "Rust",
		Hero = "GiantRobot",
		Pines = 8,
		Word = "NORTH",
		WordY = 68,
	},
	{
		Id = "reactor",
		Name = "Reactor",
		Angle = 90,
		Dist = 310,
		R = 54,
		Base = 0,
		Ground = "Dark",
		Hero = "Reactor",
		Oaks = 5,
		Word = "EAST",
		WordY = 42,
	},
	{
		Id = "rocket",
		Name = "Launch Pad",
		Angle = 180,
		Dist = 298,
		R = 54,
		Base = 4,
		Ground = "Meadow",
		Hero = "Rocket",
		Pines = 10,
		Oaks = 4,
		Word = "SOUTH",
		WordY = 64,
	},
	{
		Id = "ship",
		Name = "Crash Site",
		Angle = 270,
		Dist = 298,
		R = 54,
		Base = -2,
		Ground = "Rust",
		Hero = "CrashedShip",
		Oaks = 2,
		Word = "WEST",
		WordY = 38,
	},
	-- The inner ring
	{
		Id = "comms",
		Name = "Comms Tower",
		Angle = 0,
		Dist = 135,
		R = 30,
		Base = 3,
		Ground = "Grass",
		Hero = "CommsTower",
		Pines = 5,
		Oaks = 2,
	},
	{
		Id = "dome",
		Name = "Glass Garden",
		Angle = 45,
		Dist = 159,
		R = 32,
		Base = -4,
		Ground = "Meadow",
		Hero = "GlassDome",
		Oaks = 3,
	},
	{
		Id = "monorail",
		Name = "Monorail Station",
		Angle = 90,
		Dist = 135,
		R = 30,
		Base = 2,
		Ground = "Plate",
		Hero = "Monorail",
	},
	{
		Id = "ufo",
		Name = "Saucer Field",
		Angle = 125,
		Dist = 161,
		R = 28,
		Base = 8,
		Ground = "Meadow",
		Hero = "Ufo",
		Pines = 4,
	},
	{
		Id = "pod",
		Name = "Pod Crater",
		Angle = 153,
		Dist = 171,
		R = 23,
		Base = 0,
		Ground = "Dark",
		Hero = "EscapePod",
		Pines = 3,
	},
	{
		Id = "hangar",
		Name = "Hangar",
		Angle = 180,
		Dist = 137,
		R = 32,
		Base = -2,
		Ground = "Plate",
		Hero = "Hangar",
	},
	{
		Id = "crystal",
		Name = "Crystal Cliffs",
		Angle = 225,
		Dist = 159,
		R = 34,
		Base = 5,
		Ground = "Dark",
		Hero = "CrystalCliffs",
	},
	{
		Id = "mech",
		Name = "Old Head",
		Angle = 270,
		Dist = 135,
		R = 30,
		Base = 1,
		Ground = "Jungle",
		Hero = "MechHead",
		Oaks = 6,
		Pines = 2,
	},
	{
		Id = "radar",
		Name = "Radar Hill",
		Angle = 315,
		Dist = 161,
		R = 30,
		Base = 9,
		Ground = "Grass",
		Hero = "RadarDish",
		Pines = 6,
	},
	-- The outer ring
	{
		Id = "turbines",
		Name = "Wind Hill",
		Angle = 18,
		Dist = 227,
		R = 24,
		Base = 11,
		Ground = "Meadow",
		Hero = "Turbines",
		Oaks = 2,
	},
	{
		Id = "bunker",
		Name = "The Bunker",
		Angle = 42,
		Dist = 250,
		R = 24,
		Base = -6,
		Ground = "Dark",
		Hero = "Bunker",
		Pines = 4,
	},
	{
		Id = "solar",
		Name = "Solar Farm",
		Angle = 68,
		Dist = 226,
		R = 26,
		Base = 6,
		Ground = "Grass",
		Hero = "SolarFarm",
		Pines = 2,
	},
	{
		Id = "observatory",
		Name = "Observatory",
		Angle = 90,
		Dist = 216,
		R = 21,
		Base = 3,
		Ground = "Grass",
		Hero = "Observatory",
		Pines = 3,
	},
	{
		Id = "pipes",
		Name = "Pipe Works",
		Angle = 112,
		Dist = 226,
		R = 24,
		Base = -10,
		Ground = "Rust",
		Hero = "PipeWorks",
	},
	{
		Id = "drill",
		Name = "Drill Rig",
		Angle = 136,
		Dist = 250,
		R = 26,
		Base = 2,
		Ground = "Rust",
		Hero = "DrillRig",
		Pines = 2,
	},
	{
		Id = "snow",
		Name = "Snow Lab",
		Angle = 160,
		Dist = 234,
		R = 24,
		Base = 12,
		Ground = "Snow",
		Hero = "SnowLab",
		SnowPines = 8,
	},
	{
		Id = "cargo",
		Name = "Cargo Yard",
		Angle = 200,
		Dist = 226,
		R = 26,
		Base = -8,
		Ground = "Rust",
		Hero = "CargoStacks",
	},
	{
		Id = "walker",
		Name = "Walker Post",
		Angle = 224,
		Dist = 250,
		R = 26,
		Base = 3,
		Ground = "Grass",
		Hero = "WalkerMech",
		Pines = 5,
	},
	{
		Id = "beach",
		Name = "Wreck Beach",
		Angle = 250,
		Dist = 226,
		R = 24,
		Base = -12,
		Ground = "Sand",
		Hero = "BeachWreck",
	},
	{
		Id = "dog",
		Name = "Good Boy Hill",
		Angle = 290,
		Dist = 226,
		R = 24,
		Base = 7,
		Ground = "Meadow",
		Hero = "RobotDog",
		Oaks = 3,
	},
	{
		Id = "ruin",
		Name = "Jungle Temple",
		Angle = 316,
		Dist = 250,
		R = 26,
		Base = -3,
		Ground = "Jungle",
		Hero = "JungleRuin",
		Oaks = 6,
	},
	{
		Id = "pylons",
		Name = "Data Pylons",
		Angle = 340,
		Dist = 226,
		R = 24,
		Base = 14,
		Ground = "Plate",
		Hero = "DataPylons",
	},
}

-- How the islands join: { from, to, kind }. "citadel" is the plaza.
type LinkKind = "Causeway" | "Catwalk" | "Wide" | "Stones"
local LINKS: { { string } } = {
	{ "citadel", "comms", "Causeway" },
	{ "citadel", "monorail", "Causeway" },
	{ "citadel", "hangar", "Causeway" },
	{ "citadel", "mech", "Causeway" },
	-- Round the inner ring
	{ "comms", "dome", "Stones" },
	{ "dome", "monorail", "Catwalk" },
	{ "monorail", "ufo", "Stones" },
	{ "ufo", "pod", "Stones" },
	{ "pod", "hangar", "Catwalk" },
	{ "hangar", "crystal", "Stones" },
	{ "crystal", "mech", "Catwalk" },
	{ "mech", "radar", "Stones" },
	{ "radar", "comms", "Catwalk" },
	-- Out to the landmarks
	{ "comms", "robot", "Wide" },
	{ "monorail", "observatory", "Catwalk" },
	{ "observatory", "reactor", "Wide" },
	{ "hangar", "rocket", "Wide" },
	{ "mech", "ship", "Wide" },
	-- Inner ring to outer ring
	{ "dome", "turbines", "Stones" },
	{ "dome", "bunker", "Catwalk" },
	{ "dome", "solar", "Stones" },
	{ "ufo", "pipes", "Stones" },
	{ "ufo", "drill", "Catwalk" },
	{ "pod", "snow", "Stones" },
	{ "crystal", "cargo", "Stones" },
	{ "crystal", "walker", "Catwalk" },
	{ "crystal", "beach", "Stones" },
	{ "radar", "dog", "Stones" },
	{ "radar", "ruin", "Catwalk" },
	{ "radar", "pylons", "Stones" },
	-- Round the outer ring
	{ "robot", "turbines", "Catwalk" },
	{ "turbines", "bunker", "Stones" },
	{ "bunker", "solar", "Stones" },
	{ "solar", "observatory", "Stones" },
	{ "solar", "reactor", "Stones" },
	{ "observatory", "pipes", "Stones" },
	{ "reactor", "pipes", "Stones" },
	{ "pipes", "drill", "Catwalk" },
	{ "drill", "snow", "Stones" },
	{ "snow", "rocket", "Catwalk" },
	{ "rocket", "cargo", "Stones" },
	{ "cargo", "walker", "Stones" },
	{ "walker", "beach", "Stones" },
	{ "beach", "ship", "Catwalk" },
	{ "ship", "dog", "Stones" },
	{ "dog", "ruin", "Stones" },
	{ "ruin", "pylons", "Stones" },
	{ "pylons", "robot", "Catwalk" },
}

-- The letters of the landmarks' names
local LETTERS: { [string]: { string } } = {
	N = { "X...X", "XX..X", "XX..X", "X.X.X", "X..XX", "X..XX", "X...X" },
	O = { ".XXX.", "X...X", "X...X", "X...X", "X...X", "X...X", ".XXX." },
	R = { "XXXX.", "X...X", "X...X", "XXXX.", "X.X..", "X..X.", "X...X" },
	T = { "XXXXX", "..X..", "..X..", "..X..", "..X..", "..X..", "..X.." },
	H = { "X...X", "X...X", "X...X", "XXXXX", "X...X", "X...X", "X...X" },
	S = { ".XXXX", "X....", "X....", ".XXX.", "....X", "....X", "XXXX." },
	U = { "X...X", "X...X", "X...X", "X...X", "X...X", "X...X", ".XXX." },
	E = { "XXXXX", "X....", "X....", "XXXX.", "X....", "X....", "XXXXX" },
	A = { ".XXX.", "X...X", "X...X", "XXXXX", "X...X", "X...X", "X...X" },
	W = { "X...X", "X...X", "X...X", "X.X.X", "X.X.X", "XX.XX", "X...X" },
}

type Placed = {
	Spec: Spec,
	X: number,
	Z: number,
	Island: Context.Island?,
	Lanes: { Vector3 },
}

-- Lanes: the clear, flat ways in from a link's landing to the hero
local function onLane(place: Placed, x: number, z: number, width: number): boolean
	local rel = Vector3.new(x - place.X, 0, z - place.Z)
	for _, dir in place.Lanes do
		local along = rel:Dot(dir)
		if along > 0 and (rel - dir * along).Magnitude <= width then
			return true
		end
	end
	return false
end

-- The citadel -----------------------------------------------------------------------------

local function isGate(x: number, z: number): boolean
	return math.abs(x) <= GATE_HALF or math.abs(z) <= GATE_HALF
end

local function buildPlaza(ctx: Context.Context)
	local twoPi = 2 * math.pi
	for x = -PLAZA - 1, PLAZA + 1 do
		for z = -PLAZA - 1, PLAZA + 1 do
			local d = math.sqrt(x * x + z * z)
			if d <= WALL_IN + 0.5 and not ctx.IslandAt(x, z) then
				-- Rock wherever the island's ragged rim stops short of the wall
				ctx.Set(x, 0, z, "Grass")
				ctx.Set(x, -1, z, "Dirt")
				ctx.Set(x, -2, z, "Dirt")
				ctx.Set(x, -3, z, "Stone")
			elseif d > WALL_IN + 0.5 and d <= PLAZA + 0.5 then
				local angle = math.atan2(z, x)
				local spoke = math.abs(math.sin(angle * 6)) * d < 1.6
				local top = "HullDark"
				if d > PLAZA - 1 or (d > 47 and spoke) then
					top = "HullWhite"
				elseif d > 49 and d <= 54 then
					top = "HullGlow"
				end
				ctx.Set(x, -2, z, top)
				ctx.Set(x, -3, z, "HullGrey")
				-- Stepping in underneath, into the rock
				if d <= PLAZA - 3 then
					ctx.Set(x, -4, z, "HullGrey")
				end
				if d <= PLAZA - 7 then
					ctx.Set(x, -5, z, "HullDark")
				end
				if d <= PLAZA - 11 then
					ctx.Set(x, -6, z, "HullDark")
					ctx.Set(x, -7, z, "Stone")
				end
				-- A low white rim, open at the gates
				if d > PLAZA - 1 and not isGate(x, z) then
					ctx.Set(x, -1, z, "HullWhite")
				end
			end
		end
	end
	-- Real light in the moat
	local segments = 48
	for i = 0, segments - 1 do
		local a = i / segments * twoPi
		local at = ctx.Top(0, -2, 0)
			+ Vector3.new(math.cos(a), 0, math.sin(a)) * (51.5 * SIZE)
			+ Vector3.new(0, 0.12, 0)
		Shapes.Glow(
			ctx,
			Vector3.new(SIZE * 4.2, 0.2, 2 * math.pi * 51.5 * SIZE / segments * 0.7),
			CFrame.lookAt(at, at + Vector3.new(-math.sin(a), 0, math.cos(a))),
			CYAN
		)
	end
end

local function buildWall(ctx: Context.Context)
	for x = -WALL_OUT - 1, WALL_OUT + 1 do
		for z = -WALL_OUT - 1, WALL_OUT + 1 do
			local d = math.sqrt(x * x + z * z)
			if d > WALL_IN and d <= WALL_OUT then
				local gate = isGate(x, z)
				for y = -1, 7 do
					if not gate or y >= 6 then
						ctx.Set(x, y, z, if y == 3 or y == 4 then "HullOrange" else "HullWhite")
					end
				end
				if gate then
					-- The floor through a gate, a step up from the plaza
					ctx.Set(x, -1, z, "SmoothStone")
				elseif d > WALL_OUT - 1 and (x + z + 400) % 4 < 2 then
					ctx.Set(x, 8, z, "HullWhite")
				end
			end
		end
	end
	-- Gatehouses: an arch with a flanking tower either side
	for _, c in { { 0, 1 }, { 1, 0 }, { 0, -1 }, { -1, 0 } } do
		local fx, fz = c[1], c[2]
		local out = Vector3.new(fx, 0, fz)
		local gate = Shapes.Frame(ctx, 0, 0, 0, fx, fz)
		gate.Box(-GATE_HALF - 2, 6, WALL_IN, GATE_HALF + 2, 10, WALL_OUT + 1, "HullWhite")
		gate.Box(-GATE_HALF - 2, 8, WALL_OUT + 2, GATE_HALF + 2, 10, WALL_OUT + 2, "HullOrange")
		gate.Box(-GATE_HALF + 1, 9, WALL_OUT + 3, GATE_HALF - 1, 9, WALL_OUT + 3, "HullGlow")
		for _, s in { -1, 1 } do
			gate.Cyl(s * 9, WALL_OUT - 0.5, -1, 14, 3, function(_, h)
				return if h == 3 or h == 4 or h == 11 then "HullOrange" else "HullWhite"
			end)
			gate.Dome(s * 9, 15, WALL_OUT - 0.5, 3, 2.5, 3, "HullGrey")
		end
		-- A slope up through the gate
		local a = gate.Pos(0, -2.5 + 1, WALL_OUT + 1.5)
		local b = gate.Pos(0, 0.5, WALL_IN - 2)
		Shapes.Ramp(ctx, a, b, (GATE_HALF * 2 + 1) * SIZE)
		local lamp = Shapes.Glow(
			ctx,
			Vector3.new(SIZE * 5, 1, 1),
			CFrame.lookAt(gate.Pos(0, 9, WALL_OUT + 3.6), gate.Pos(0, 9, WALL_OUT + 3.6) + out),
			CYAN
		)
		Shapes.Light(lamp, CYAN, 40, 1.5)
	end
end

-- A tall corner tower with a glowing cap
local function buildTower(f: Shapes.Frame, u: number, v: number)
	local out = math.atan2(v, u)
	f.Cone(u, v, 1, 7, 8, 5.5, "HullGrey", 1.6)
	f.Cyl(u, v, 8, 36, 5.5, function(cu, h, cv)
		local a = math.atan2(cv - v, cu - u) - out
		a = math.atan2(math.sin(a), math.cos(a))
		if h == 15 or h == 16 or h == 30 or h == 31 then
			return "HullOrange"
		end
		if math.abs(a) < 0.32 then
			return "HullOrange"
		end
		if math.abs(math.abs(a) - 1.57) < 0.3 and h % 7 >= 3 and h % 7 <= 5 then
			return "HullDark"
		end
		return "HullWhite"
	end, 3.8)
	f.Cyl(u, v, 37, 38, 7, "HullOrange")
	f.Ring(u, v, 39, 7, 1, "HullWhite")
	f.Dome(u, 39, v, 5.5, 5, 5.5, "HullWhite", 1.4)
	f.Line(Vector3.new(u, 45, v), Vector3.new(u, 49, v), 0, "HullDark")
end

local function buildCentralTower(ctx: Context.Context, f: Shapes.Frame)
	-- The great stepped foot, with fins and four dark doors
	f.Cone(0, 0, 1, 11, 16, 10, "HullGrey", 2)
	for i = 0, 7 do
		local a = i * math.pi / 4 + math.pi / 8
		local du, dv = math.cos(a), math.sin(a)
		f.Line(Vector3.new(du * 16.5, 1, dv * 16.5), Vector3.new(du * 10.5, 12, dv * 10.5), 0.6, "HullOrange")
	end
	for _, c in { { 0, 15 }, { 0, -15 }, { 15, 0 }, { -15, 0 } } do
		local alongU = c[2] == 0
		local u1, u2 = (if alongU then c[1] else -2), (if alongU then c[1] + math.sign(c[1]) * -2 else 2)
		local v1, v2 = (if alongU then -2 else c[2]), (if alongU then 2 else c[2] + math.sign(c[2]) * -2)
		f.Box(u1, 1, v1, u2, 4, v2, "HullDark")
	end
	-- The drum
	f.Cyl(0, 0, 12, 28, 10, function(u, h, v)
		if h == 17 or h == 18 then
			return "HullOrange"
		end
		local a = math.atan2(v, u)
		if h >= 22 and h <= 25 and (a * 8 / math.pi) % 2 < 0.9 then
			return "HullDark"
		end
		return "HullWhite"
	end, 7.5)
	f.Cyl(0, 0, 29, 30, 13, "HullDark")
	f.Ring(0, 0, 31, 13, 1.1, "HullGlow")
	-- The neck, the struts and the Sky Core shining between them
	f.Cyl(0, 0, 31, 46, 2.5, "HullGrey")
	for _, c in { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } } do
		f.Line(Vector3.new(c[1] * 8, 31, c[2] * 8), Vector3.new(c[1] * 8, 47, c[2] * 8), 1, "HullWhite")
	end
	f.Tyre(0, 39, 0, 9, 0.7, "HullOrange", true)
	local core = Shapes.Glow(ctx, Vector3.new(SIZE * 10, SIZE * 10, SIZE * 10), CFrame.new(f.Pos(0, 39, 0)), CYAN)
	core.Shape = Enum.PartType.Ball
	Shapes.Light(core, CYAN, 60, 4)
	-- The head: floors of white and glass, a stepped roof, a mast
	f.Box(-11, 47, -11, 11, 48, 11, "HullDark")
	f.Box(-8, 49, -8, 8, 72, 8, function(u, h, v)
		local face = math.abs(u) == 8 or math.abs(v) == 8
		if not face then
			return nil
		end
		local band = (h - 49) % 6
		if band == 0 then
			return "HullOrange"
		end
		if band >= 2 and band <= 4 and (u + v) % 4 ~= 0 then
			return "Glass"
		end
		return "HullWhite"
	end)
	f.Box(-9, 73, -9, 9, 74, 9, "HullOrange")
	f.Box(-6, 75, -6, 6, 77, 6, "HullWhite")
	f.Box(-3, 78, -3, 3, 80, 3, "HullDark")
	f.Line(Vector3.new(0, 81, 0), Vector3.new(0, 90, 0), 0, "HullGrey")
	local top = Shapes.Glow(ctx, Vector3.new(SIZE, SIZE, SIZE), CFrame.new(f.Pos(0, 91, 0)), RED)
	top.Shape = Enum.PartType.Ball
	Shapes.Light(top, RED, 60, 3)
end

local function buildCitadel(ctx: Context.Context)
	local function path(x: number, z: number): boolean
		local d = math.sqrt(x * x + z * z)
		return math.abs(x) <= 3 or math.abs(z) <= 3 or (d > 19 and d <= 23)
	end
	ctx.Island({
		Name = "Citadel",
		X = 0,
		Z = 0,
		Radius = 38,
		Column = function(x, z)
			local d = math.sqrt(x * x + z * z)
			if d > WALL_IN then
				return "HullDark", -2
			end
			if path(x, z) then
				return "SmoothStone", 0
			end
			return if ctx.Noise(x, z, 6, 11) > 0.26 then "FlowerGrass" else "Grass", 0
		end,
		Depth = 44,
		Step = 6,
		Rock = function(x, y, z)
			local band = math.floor((y + ctx.Noise(x, z, 8, 12) * 6) / 5)
			return if band % 2 == 0 then "Stone" else "Terracotta"
		end,
	})
	buildPlaza(ctx)
	local f = Shapes.Frame(ctx, 0, 0, 0, 0, 1)
	buildWall(ctx)
	for _, c in { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } } do
		buildTower(f, c[1] * 23, c[2] * 23)
	end
	-- The ring of glowing tube joining the towers, high up
	f.Ring(0, 0, 24, 33.5, 1.6, "HullGlow")
	f.Ring(0, 0, 25, 33.5, 1.6, "HullGrey")
	buildCentralTower(ctx, f)
	-- Gardens: big trees between the paths
	local rng = ctx.Rng
	local planted: { Vector2 } = {}
	local function free(x: number, z: number, gap: number): boolean
		local d = math.sqrt(x * x + z * z)
		if d < 18 or d > WALL_IN - 4 or path(x, z) or math.abs(x) <= 5 or math.abs(z) <= 5 then
			return false
		end
		-- Not against a tower
		if (math.abs(x) - 23) ^ 2 + (math.abs(z) - 23) ^ 2 < 100 then
			return false
		end
		for _, spot in planted do
			if (spot - Vector2.new(x, z)).Magnitude < gap then
				return false
			end
		end
		return true
	end
	for _ = 1, 400 do
		local x, z = rng:NextInteger(-40, 40), rng:NextInteger(-40, 40)
		if free(x, z, 8) and #planted < 18 then
			table.insert(planted, Vector2.new(x, z))
			if rng:NextNumber() < 0.42 then
				Shapes.Pine(ctx, x, 0, z, rng:NextInteger(11, 15))
			else
				Shapes.BigTree(ctx, x, 0, z, rng:NextInteger(6, 8), rng:NextNumber(3, 3.8))
			end
		end
	end
	-- Lamps along the paths from the gates
	for _, c in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
		for _, d in { 26, 36 } do
			for _, s in { -4, 4 } do
				local x = c[1] * d + (if c[1] == 0 then s else 0)
				local z = c[2] * d + (if c[2] == 0 then s else 0)
				Decor.LampPost(ctx.Decor, ctx.Top(x, 0, z), 7, 22)
			end
		end
	end
end

-- Walkways --------------------------------------------------------------------------------

-- A deck between two grid points, `half` blocks out from its middle. `paint` picks each
-- block from how far along it is and how far out.
local function deck(
	ctx: Context.Context,
	a: Vector3,
	b: Vector3,
	half: number,
	paint: (along: number, out: number, length: number) -> string,
	under: string
)
	local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local length = flat.Magnitude
	local dir = flat.Unit
	local side = Vector3.new(-dir.Z, 0, dir.X)
	local done: { [string]: boolean } = {}
	local s = 0
	while s <= length do
		local p = a:Lerp(b, s / length)
		local w = -half - 0.4
		while w <= half + 0.4 do
			local q = p + side * w
			local x, y, z = math.round(q.X), math.round(p.Y), math.round(q.Z)
			local k = key(x, y, z)
			if not done[k] then
				done[k] = true
				ctx.Set(x, y, z, paint(s, math.abs(w), length))
				ctx.SetFree(x, y - 1, z, under)
			end
			w += 0.4
		end
		s += 0.4
	end
	local function top(point: Vector3): Vector3
		return BlockWorld.position(ctx.World, point.X, point.Y, point.Z) + Vector3.new(0, SIZE / 2, 0)
	end
	Shapes.Ramp(ctx, top(a), top(b), (half * 2 + 1) * SIZE)
end

local function causeway(ctx: Context.Context, a: Vector3, b: Vector3)
	deck(ctx, a, b, 3, function(along, out)
		if out >= 3 then
			return "HullOrange"
		end
		if out < 0.7 and along % 8 < 4 then
			return "HullGlow"
		end
		return "HullWhite"
	end, "HullGrey")
end

local function wide(ctx: Context.Context, a: Vector3, b: Vector3)
	deck(ctx, a, b, 2, function(along, out)
		if out >= 2 then
			return "HullOrange"
		end
		return if along % 12 < 1.2 then "HullDark" else "HullWhite"
	end, "HullDark")
end

local function catwalk(ctx: Context.Context, a: Vector3, b: Vector3)
	deck(ctx, a, b, 1, function(along, out)
		if out < 0.7 and along % 6 < 2 then
			return "HullGrey"
		end
		return "HullDark"
	end, "HullGrey")
	-- A line of light down each edge
	local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local side = Vector3.new(-flat.Z, 0, flat.X).Unit
	for _, s in { -1, 1 } do
		local from = BlockWorld.position(ctx.World, a.X, a.Y, a.Z)
			+ side * (s * SIZE * 1.5)
			+ Vector3.new(0, SIZE / 2, 0)
		local to = BlockWorld.position(ctx.World, b.X, b.Y, b.Z) + side * (s * SIZE * 1.5) + Vector3.new(0, SIZE / 2, 0)
		Shapes.Glow(
			ctx,
			Vector3.new(0.35, 0.35, (to - from).Magnitude),
			CFrame.lookAt((from + to) / 2 + Vector3.new(0, 0.2, 0), to + Vector3.new(0, 0.2, 0)),
			CYAN
		)
	end
end

-- A string of stepping stones sagging between two points, close enough to hop along
local function stones(ctx: Context.Context, a: Vector3, b: Vector3, palette: { string })
	local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local length = flat.Magnitude
	local count = math.max(2, math.floor(length / 3))
	local rise = math.abs(b.Y - a.Y) / count
	local sag = math.clamp((1.5 - rise) * count / 4, 0, 6)
	for i = 0, count do
		local t = i / count
		local p = a:Lerp(b, t)
		local y = math.round(p.Y - sag * 4 * t * (1 - t))
		local x, z = math.round(p.X), math.round(p.Z)
		local block = palette[i % #palette + 1]
		for dx = 0, 1 do
			for dz = 0, 1 do
				ctx.Set(x + dx, y, z + dz, block)
			end
		end
		-- A hanging bead under every other stone
		if i % 2 == 1 then
			ctx.Set(x, y - 1, z, block)
		end
	end
end

-- Words -----------------------------------------------------------------------------------

-- A word in huge floating letters at (x, y, z), its face toward the citadel. `pixel` blocks to
-- a dot of a letter.
local function word(ctx: Context.Context, text: string, x: number, y: number, z: number)
	local pixel = 2
	local width = 5 * pixel
	local gap = pixel
	local total = #text * width + (#text - 1) * gap
	local flat = Vector3.new(x, 0, z).Unit
	local fx, fz = math.round(flat.X), math.round(flat.Z)
	-- Reading from the citadel, looking outward: the viewer's right
	local rx, rz = -fz, fx
	for i = 1, #text do
		local glyph = LETTERS[string.sub(text, i, i)]
		local start = -total / 2 + (i - 1) * (width + gap)
		for row = 1, 7 do
			for col = 1, 5 do
				if string.sub(glyph[row], col, col) == "X" then
					for pu = 0, pixel - 1 do
						for ph = 0, pixel - 1 do
							local across = math.round(start + (col - 1) * pixel + pu)
							local up = y + (7 - row) * pixel + ph
							local cx, cz = x + rx * across, z + rz * across
							-- Bright face on the citadel side, a dark back
							ctx.Set(cx - fx, up, cz - fz, "HullOrange")
							ctx.Set(cx, up, cz, "HullOrange")
							ctx.Set(cx + fx, up, cz + fz, "HullDark")
						end
					end
				end
			end
		end
	end
end

-- Dressing --------------------------------------------------------------------------------

local function plantTrees(ctx: Context.Context, place: Placed, clear: number)
	local spec = place.Spec
	local island = place.Island
	if not island then
		return
	end
	local rng = ctx.Rng
	local planted: { Vector2 } = {}
	local function spot(gap: number): (number?, number?)
		for _ = 1, 60 do
			local a = rng:NextNumber(0, 2 * math.pi)
			local d = rng:NextNumber(clear, spec.R)
			local x, z = math.round(place.X + math.cos(a) * d), math.round(place.Z + math.sin(a) * d)
			local good = ctx.IslandAt(x, z) == island and ctx.Inside(x, z, 3) and not onLane(place, x, z, 4)
			if good then
				for _, other in planted do
					if (other - Vector2.new(x, z)).Magnitude < gap then
						good = false
						break
					end
				end
			end
			if good then
				table.insert(planted, Vector2.new(x, z))
				return x, z
			end
		end
		return nil, nil
	end
	for _ = 1, math.round((spec.Pines or 0) * TREE_SHARE) do
		local x, z = spot(5)
		if x and z then
			Shapes.Pine(ctx, x, ctx.HeightAt(x, z), z, rng:NextInteger(11, 20))
		end
	end
	for _ = 1, math.round((spec.SnowPines or 0) * TREE_SHARE) do
		local x, z = spot(5)
		if x and z then
			Shapes.Pine(ctx, x, ctx.HeightAt(x, z), z, rng:NextInteger(10, 17), true)
		end
	end
	for _ = 1, math.round((spec.Oaks or 0) * TREE_SHARE) do
		local x, z = spot(8)
		if x and z then
			Shapes.BigTree(ctx, x, ctx.HeightAt(x, z), z, rng:NextInteger(6, 9), rng:NextNumber(3, 4))
		end
	end
end

-- Cover on the open ground round a hero, so no island is a bare plain: boulders on natural
-- ground, heaps of scrap on the rusty and dark islands, crates and barrels on the rest
local function placeCover(ctx: Context.Context, place: Placed, clear: number, count: number)
	local island = place.Island
	if not island then
		return
	end
	local kind = place.Spec.Ground
	local rng = ctx.Rng
	local placed: { Vector2 } = {}
	for _ = 1, count * 30 do
		if #placed >= count then
			break
		end
		local a = rng:NextNumber(0, 2 * math.pi)
		local d = rng:NextNumber(clear, place.Spec.R)
		local x, z = math.round(place.X + math.cos(a) * d), math.round(place.Z + math.sin(a) * d)
		local good = ctx.IslandAt(x, z) == island and ctx.Inside(x, z, 4) and not onLane(place, x, z, 4)
		for _, other in placed do
			good = good and (other - Vector2.new(x, z)).Magnitude >= 9
		end
		if good then
			table.insert(placed, Vector2.new(x, z))
			local size = rng:NextInteger(4, 6)
			if kind == "Rust" or kind == "Dark" then
				Common.Boulder(ctx, x, z, size, { "HullGrey", "HullDark", "RustGround", "Rubber", "HullOrange" })
			elseif kind == "Snow" then
				Common.Boulder(ctx, x, z, size, { "Snow", "Stone", "Stone" })
			elseif kind == "Grass" or kind == "Meadow" or kind == "Jungle" then
				Common.Boulder(ctx, x, z, size, { "Stone", "Stone", "MossyCobblestone", "Cobblestone" })
			else
				-- A stack of crates with a barrel beside it
				local h = ctx.HeightAt(x, z)
				for dx = 0, 2 do
					for dz = 0, 2 do
						for dy = 1, 2 do
							ctx.SetFree(x + dx, h + dy, z + dz, "Crate")
						end
					end
				end
				ctx.SetFree(x + 1, h + 3, z + 1, "Crate")
				ctx.SetFree(x + 3, h + 1, z, "Barrel")
			end
		end
	end
end

local MEADOW = {
	Color3.fromRGB(222, 62, 52),
	Color3.fromRGB(242, 212, 64),
	Color3.fromRGB(240, 240, 240),
	Color3.fromRGB(150, 110, 220),
}

-- Little rocks floating in the gaps
local function islets(ctx: Context.Context, count: number)
	local rng = ctx.Rng
	local placed = 0
	for _ = 1, count * 12 do
		if placed >= count then
			break
		end
		local a = rng:NextNumber(0, 2 * math.pi)
		local d = rng:NextNumber(72, 375)
		local x, z = math.round(math.cos(a) * d), math.round(math.sin(a) * d)
		local r = rng:NextInteger(2, 5)
		local clear = true
		for dx = -14, 14, 4 do
			for dz = -14, 14, 4 do
				if ctx.IslandAt(x + dx, z + dz) then
					clear = false
				end
			end
		end
		if clear then
			placed += 1
			local y = rng:NextInteger(-22, 20)
			ctx.Islet(x, y, z, r, if rng:NextNumber() < 0.7 then "Grass" else "Sandstone")
			if r >= 4 and rng:NextNumber() < 0.7 then
				Shapes.Pine(ctx, x, y, z, rng:NextInteger(7, 11))
			end
		end
	end
end

-- Where the islands are, in blocks, for what's scattered on them later (LootChestService)
export type IslandSpot = { Id: string, X: number, Z: number, Radius: number, Base: number }

function Warzone.IslandSpots(): { IslandSpot }
	local list = {}
	for _, spec in SPECS do
		local a = math.rad(spec.Angle)
		table.insert(list, {
			Id = spec.Id,
			X = math.round(math.sin(a) * spec.Dist),
			Z = math.round(-math.cos(a) * spec.Dist),
			Radius = spec.R,
			Base = spec.Base,
		})
	end
	return list
end

-- The height in studs of the ground at this block height
function Warzone.CellHeight(base: number): number
	return Warzone.OriginY + base * 3
end

-- The map -----------------------------------------------------------------------------------

function Warzone.Build(ctx: Context.Context)
	local places: { [string]: Placed } = {}
	for _, spec in SPECS do
		local a = math.rad(spec.Angle)
		places[spec.Id] = {
			Spec = spec,
			X = math.round(math.sin(a) * spec.Dist),
			Z = math.round(-math.cos(a) * spec.Dist),
			Island = nil,
			Lanes = {},
		}
	end
	local function target(id: string): Vector3
		if id == "citadel" then
			return Vector3.zero
		end
		local place = places[id]
		return Vector3.new(place.X, 0, place.Z)
	end
	-- Which ways each island needs clear ground before it's built
	for _, link in LINKS do
		for i = 1, 2 do
			local place = places[link[i]]
			if place then
				local other = target(link[3 - i])
				table.insert(place.Lanes, (other - Vector3.new(place.X, 0, place.Z)).Unit)
			end
		end
	end

	buildCitadel(ctx)

	-- The islands' ground
	for _, spec in SPECS do
		local place = places[spec.Id]
		local ground = GROUNDS[spec.Ground]
		local core = if spec.Word then 38 else spec.R * 0.66
		local salt = spec.Angle + spec.Dist
		place.Island = ctx.Island({
			Name = spec.Name,
			X = place.X,
			Z = place.Z,
			Radius = spec.R,
			Base = spec.Base,
			Soil = ground.Soil,
			Depth = math.floor(math.min(spec.R * 0.78, 36)),
			Step = 8,
			Column = function(x, z)
				local dx, dz = x - place.X, z - place.Z
				local d = math.sqrt(dx * dx + dz * dz)
				if onLane(place, x, z, 2) and d > core * 0.6 then
					return ground.Path, 0
				end
				local top = if ctx.Noise(x, z, 12, salt) > 0.24 then ground.Alt else ground.Top
				-- Odd ground for two builds: a crater, a dip for the frozen pond
				if spec.Hero == "EscapePod" and d <= 12 then
					return "DarkStone", -math.round(4 * (1 - (d / 12) ^ 2))
				end
				if d <= core then
					return top, 0
				end
				local rise = (d - core) / math.max(spec.R - core, 1)
				local hill = math.round((ctx.Noise(x, z, 14, salt + 1) + 0.5) * ground.Hills * math.min(rise * 2, 1))
				return top, math.max(hill, 0)
			end,
			Rock = function(x, y, z)
				local band = math.floor((y + ctx.Noise(x, z, 18, salt + 2) * 4) / 8)
				return ground.Rock[band % #ground.Rock + 1]
			end,
		})
	end

	-- The walkways
	local function landing(id: string, toward: Vector3): Vector3
		if id == "citadel" then
			local dir = toward.Unit
			return Vector3.new(math.round(dir.X * (PLAZA - 1)), -2, math.round(dir.Z * (PLAZA - 1)))
		end
		local place = places[id]
		local from = Vector3.new(place.X, 0, place.Z)
		local dir = (toward - from).Unit
		for d = math.ceil(place.Spec.R * 1.4), 1, -1 do
			local p = from + dir * d
			local x, z = math.round(p.X), math.round(p.Z)
			if ctx.IslandAt(x, z) == place.Island and ctx.Inside(x, z, 0) then
				-- A little way in, so it meets the ground
				local inner = from + dir * (d - 1)
				return Vector3.new(math.round(inner.X), place.Spec.Base, math.round(inner.Z))
			end
		end
		return Vector3.new(place.X, place.Spec.Base, place.Z)
	end
	for _, link in LINKS do
		local ta, tb = target(link[1]), target(link[2])
		local a, b = landing(link[1], tb), landing(link[2], ta)
		local kind = link[3] :: LinkKind
		if kind == "Causeway" then
			causeway(ctx, a, b)
		elseif kind == "Wide" then
			wide(ctx, a, b)
		elseif kind == "Catwalk" then
			catwalk(ctx, a, b)
		else
			local natural = false
			local pa, pb = places[link[1]], places[link[2]]
			if pa and pb then
				natural = GROUNDS[pa.Spec.Ground].Natural and GROUNDS[pb.Spec.Ground].Natural
			end
			stones(
				ctx,
				a,
				b,
				if natural
					then { "Sandstone", "Terracotta", "SmoothStone" }
					else { "HullWhite", "HullOrange", "HullDark" }
			)
		end
	end

	-- The heroes, the trees and the names
	for _, spec in SPECS do
		local place = places[spec.Id]
		-- Each build faces the citadel, along whichever axis is nearest
		local fx, fz = 0, 0
		if math.abs(place.X) > math.abs(place.Z) then
			fx = -math.sign(place.X)
		else
			fz = -math.sign(place.Z)
		end
		local frame = Shapes.Frame(ctx, place.X, spec.Base, place.Z, fx, fz)
		Builds[spec.Hero](frame, spec.R)
		local clear = if spec.Word then 30 else spec.R * 0.5
		plantTrees(ctx, place, clear)
		placeCover(ctx, place, clear, if spec.Word then 12 elseif spec.Dist < 180 then 5 else 2)
		if spec.Word then
			word(ctx, spec.Word, place.X, spec.Base + (spec.WordY or 40), place.Z)
		end
		local ground = GROUNDS[spec.Ground]
		if place.Island and ground.Natural and spec.Ground ~= "Sand" then
			Common.Scatter(ctx, place.Island, 0.025, 0.012, MEADOW)
		end
		if place.Island and spec.Ground == "Jungle" then
			Common.CliffVines(ctx, place.Island, 0.5)
		end
	end

	islets(ctx, 32)
end

return Warzone
