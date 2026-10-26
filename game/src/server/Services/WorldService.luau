--!strict
-- The shared resource worlds (Places: Mining, Woodcutting, Farming). Each is its own
-- place, reached through its portal in Town, with resources everyone on the server shares:
--   Mining       a quarry of rocky outcrops and a cliff face: stone, coal ore and iron ore
--   Woodcutting  a forest of oaks
--   Farming      fields of wild wheat, carrots and potatoes, already growing
-- Everything you can gather here is a node: mine a rock, chop a log or harvest a crop and
-- it grows back in the same spot after a while (Blocks.NodeRespawn, Crops.GrowTime), so a
-- world never runs out. The ground can't be broken and nobody can build here.
-- Gathering works like on your island: BlockService does the breaking (tools, double
-- drops, Mining and Woodcutting XP, saplings from leaves) and FarmService the harvesting
-- (Farming XP, hoe bonus, spare seeds), with the same level gates (iron ore needs a Stone
-- pickaxe, carrots Farming 5, potatoes Farming 10).
-- Only today's resources grow here. Rarer ores, trees and crops will be found elsewhere.
-- Arrive at the south end; the portals there lead back to Town or home.
--
-- Grid: x runs west to east, z south to north; y = 0 is the ground, things stand on y = 1.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Crops = require(ReplicatedStorage.Shared.Crops)
local Places = require(ReplicatedStorage.Shared.Places)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local Portal = require(script.Parent.Parent.Util.Portal)
local Signs = require(script.Parent.Parent.Util.Signs)
local Spawning = require(script.Parent.Parent.Util.Spawning)
local Trees = require(script.Parent.Parent.Util.Trees)
local BlockService = require(script.Parent.BlockService)
local FarmService = require(script.Parent.FarmService)
local ProgressionService = require(script.Parent.ProgressionService)
local StateService = require(script.Parent.StateService)
local TravelService = require(script.Parent.TravelService)

local CENTER = Vector3.new(0, 200, 0) -- top of the ground in the middle
local SIZE = Blocks.Size
local FALL_LIMIT = 120
local RADIUS: { [string]: number } = { Mining = 28, Woodcutting = 28, Farming = 24 }
local TITLES: { [string]: string } = {
	Mining = "MINING WORLD",
	Woodcutting = "WOODCUTTING WORLD",
	Farming = "FARMING WORLD",
}
local GROWING_NOTICE = 2 -- seconds between "still growing" messages per player

type Node = { X: number, Y: number, Z: number, Block: string, RespawnAt: number? }
-- A wild crop in the Farming World: ripe from ReadyAt on (os.clock time)
type Field = {
	Crop: Crops.Crop,
	ReadyAt: number,
	Model: Model,
	Base: CFrame,
	Stage: string?,
	Visual: Model?,
}

local WorldService = {}

local world: BlockWorld.World
local radius = 24
local southZ = 0 -- z of the arrival portals
local nodes: { [string]: Node } = {}
local depleted: { [Node]: boolean } = {}
local fields: { [string]: Field } = {} -- by farmland cell key
local growing: { [Field]: boolean } = {}
local lastNotice: { [Player]: number } = {}
local lastClick: { [Player]: number } = {}
local key = BlockWorld.key

-- Ground and nodes ---------------------------------------------------------------

local function set(x: number, y: number, z: number, blockType: string)
	BlockWorld.setRaw(world, x, y, z, blockType)
	world.Protected[key(x, y, z)] = true
end

local function node(x: number, y: number, z: number, blockType: string)
	local k = key(x, y, z)
	if world.Cells[k] then
		return
	end
	BlockWorld.setRaw(world, x, y, z, blockType)
	nodes[k] = { X = x, Y = y, Z = z, Block = blockType }
end

-- A wobbly round edge, the same every time
local edgeNoise: { number } = {}
do
	local noise = Random.new(5151)
	for i = 0, 15 do
		edgeNoise[i] = noise:NextNumber(-1.2, 1.2)
	end
end

local function edgeRadius(x: number, z: number): number
	local t = (math.atan2(z, x) / (2 * math.pi) + 0.5) * 16
	local i0 = math.floor(t) % 16
	local f = t - math.floor(t)
	return radius + edgeNoise[i0] * (1 - f) + edgeNoise[(i0 + 1) % 16] * f
end

local function inside(x: number, z: number, margin: number): boolean
	return math.sqrt(x * x + z * z) <= edgeRadius(x, z) - margin
end

-- The arrival area at the south end, where nothing grows
local function nearArrival(x: number, z: number, margin: number): boolean
	return z < southZ + 9 + margin and math.abs(x) < 9 + margin
end

-- The floating island itself. `top` picks each ground block's type.
local function buildGround(top: (x: number, z: number) -> string)
	for x = -radius - 2, radius + 2 do
		for z = -radius - 2, radius + 2 do
			local distance = math.sqrt(x * x + z * z)
			local edge = edgeRadius(x, z)
			if distance <= edge then
				local t = distance / edge
				local depth = 2 + math.floor((1 - t) ^ 0.8 * 9) + ((x * 7 + z * 13) % 3 == 0 and 1 or 0)
				set(x, 0, z, top(x, z))
				for y = -1, -depth, -1 do
					set(x, y, z, if y >= -2 then "Dirt" else "Stone")
				end
			end
		end
	end
end

-- Mining World: outcrops of stone with coal and iron in them, and a cliff face along the
-- north edge (more iron the deeper in)
local function oreAt(rng: Random, y: number): string
	local roll = rng:NextNumber()
	if roll < 0.07 + y * 0.015 then
		return "IronOre"
	elseif roll < 0.25 then
		return "CoalOre"
	end
	return "Stone"
end

local function buildMining(rng: Random)
	buildGround(function(x, z)
		return if inside(x, z, 4) then "Cobblestone" else "Grass"
	end)
	local placed: { Vector2 } = {}
	for _ = 1, 400 do
		if #placed >= 24 then
			break
		end
		local x, z = rng:NextInteger(-radius + 5, radius - 5), rng:NextInteger(-radius + 5, radius - 10)
		local spot = Vector2.new(x, z)
		local clear = inside(x, z, 4) and not nearArrival(x, z, 2)
		for _, other in placed do
			if (other - spot).Magnitude < 6 then
				clear = false
			end
		end
		if clear then
			table.insert(placed, spot)
			local size = rng:NextNumber(1.3, 2.7)
			local height = rng:NextInteger(2, 4)
			for dx = -3, 3 do
				for dz = -3, 3 do
					local d = math.sqrt(dx * dx + dz * dz)
					if d <= size then
						local column = math.max(1, math.round(height * (1 - (d / size) ^ 2 * 0.7)))
						for y = 1, column do
							node(x + dx, y, z + dz, oreAt(rng, y))
						end
					end
				end
			end
		end
	end
	-- The cliff face
	for x = -radius, radius do
		for z = radius - 7, radius do
			if inside(x, z, 0) and not inside(x, z, 6) then
				local height = 3 + math.floor((math.sin(x * 0.45) + 1) * 1.5) + (if (x * 5) % 3 == 0 then 1 else 0)
				for y = 1, height do
					node(x, y, z, oreAt(rng, y))
				end
			end
		end
	end
end

-- Woodcutting World: oaks on a loose grid, each nudged a little
local function buildWoodcutting(rng: Random)
	buildGround(function()
		return "Grass"
	end)
	for gx = -radius + 4, radius - 4, 7 do
		for gz = -radius + 4, radius - 4, 7 do
			local x, z = gx + rng:NextInteger(-1, 1), gz + rng:NextInteger(-1, 1)
			if inside(x, z, 4) and not nearArrival(x, z, 3) then
				Trees.Oak(x, 0, z, rng:NextInteger(4, 6), node)
			end
		end
	end
end

-- Farming World: a field of each crop off a cobblestone path, each with a signpost at its
-- south-west corner saying what grows there, and a few oaks around the edge (scenery:
-- they can't be chopped here)
local FIELDS = {
	{ Crop = "Wheat", X1 = -15, X2 = -6, Z1 = -7, Z2 = 0, Sign = "WHEAT", Width = 2 },
	{ Crop = "Potato", X1 = 6, X2 = 13, Z1 = -7, Z2 = -1, Sign = "POTATOES · FARMING 10", Width = 5 },
	{ Crop = "Carrot", X1 = -5, X2 = 5, Z1 = 6, Z2 = 11, Sign = "CARROTS · FARMING 5", Width = 4 },
}
local FARM_TREES = { { -19, 8, 5 }, { 18, 9, 4 }, { -11, 16, 4 }, { 12, 16, 5 }, { 20, -6, 4 }, { -20, -11, 5 } }

local function buildFarming()
	buildGround(function(x, z)
		local main = math.abs(x) <= 1 and z <= 3
		local cross = z >= 2 and z <= 3 and math.abs(x) <= 15
		return if main or cross then "Cobblestone" else "Grass"
	end)
	for _, info in FIELDS do
		local crop = Crops.ById[info.Crop]
		for x = info.X1, info.X2 do
			for z = info.Z1, info.Z2 do
				set(x, 0, z, "Farmland")
				-- Crops need the space above free
				world.Protected[key(x, 1, z)] = true
				fields[key(x, 0, z)] = {
					Crop = crop,
					ReadyAt = 0,
					Model = world.Model,
					Base = CFrame.new(BlockWorld.position(world, x, 0, z) + Vector3.new(0, SIZE / 2, 0)),
					Stage = nil,
					Visual = nil,
				}
			end
		end
		-- The board sits on top of a one-log post
		local px, pz = info.X1 - 1, info.Z1 - 1
		set(px, 1, pz, "Wood")
		Signs.Board(
			world.Model,
			`{info.Crop}Sign`,
			info.Sign,
			BlockWorld.position(world, px, 1.93, pz),
			-Vector3.zAxis,
			info.Width
		)
	end
	for _, spot in FARM_TREES do
		Trees.Oak(spot[1], 0, spot[2], spot[3], function(x, y, z, block)
			if not BlockWorld.get(world, x, y, z) then
				set(x, y, z, block)
			end
		end)
	end
end

-- Arrival: portals to Town and home at the south end, a paved square and a welcome sign
local function buildArrival(kind: string)
	for x = -8, 8 do
		for z = southZ - 1, southZ + 8 do
			if BlockWorld.get(world, x, 0, z) then
				set(x, 0, z, "Cobblestone")
			end
		end
	end
	Portal.addCells(world.Cells, world.Protected, -4, southZ)
	Portal.addCells(world.Cells, world.Protected, 4, southZ)
	for _, x in { -2, 2 } do
		set(x, 1, southZ + 9, "Wood")
		set(x, 2, southZ + 9, "Wood")
	end
	-- Nailed to the front of the two posts, facing new arrivals
	Signs.Board(
		world.Model,
		"WelcomeSign",
		TITLES[kind] or string.upper(kind),
		BlockWorld.position(world, 0, 2.2, southZ + 9) - Vector3.new(0, 0, SIZE / 2 + 0.25),
		-Vector3.zAxis,
		6
	)
end

local function build(kind: string)
	world = BlockWorld.new(CENTER - Vector3.new(0, SIZE / 2, 0), "World", workspace)
	world.Model:SetAttribute("Kind", kind)
	radius = RADIUS[kind] or 24
	southZ = -(radius - 3)
	local rng = Random.new(if kind == "Mining" then 11 elseif kind == "Woodcutting" then 22 else 33)
	if kind == "Mining" then
		buildMining(rng)
	elseif kind == "Woodcutting" then
		buildWoodcutting(rng)
	else
		buildFarming()
	end
	buildArrival(kind)
	BlockWorld.drawAll(world)

	local north = Vector3.zAxis
	local portals: { { X: number, To: Places.Kind, Action: string, Sign: string } } = {
		{ X = -4, To = "Town", Action = "Back to Town", Sign = "TOWN" },
		{ X = 4, To = "Island", Action = "Go home", Sign = "HOME" },
	}
	for _, portal in portals do
		local field = Portal.makeField(world, portal.X, southZ)
		TravelService.AddPortal(field, portal.To, portal.Action, function()
			return true
		end)
		Signs.Board(
			world.Model,
			`{portal.Sign}Sign`,
			portal.Sign,
			BlockWorld.position(world, portal.X, 6, southZ) + north * (SIZE / 2 + 0.25),
			north,
			2
		)
	end
	for _, field in fields do
		FarmService.ShowCrop(field, field.Crop, 1)
	end
end

-- Gathering ----------------------------------------------------------------------

-- Breaking blocks here (for BlockService): only nodes can be broken, and they grow back
local area: BlockService.Area
local function makeArea(): BlockService.Area
	return {
		World = world,
		Natural = function(x, y, z)
			return nodes[key(x, y, z)] ~= nil
		end,
		Broken = function(x, y, z)
			local mined = nodes[key(x, y, z)]
			if mined then
				mined.RespawnAt = os.clock() + (Blocks.Types[mined.Block].NodeRespawn or 30)
				depleted[mined] = true
			end
			return nil
		end,
	}
end

function WorldService.AreaFor(_player: Player): BlockService.Area?
	return area
end

local function regrow()
	local now = os.clock()
	for mined in depleted do
		if now >= (mined.RespawnAt or 0) then
			if BlockWorld.get(world, mined.X, mined.Y, mined.Z) then
				depleted[mined] = nil
				mined.RespawnAt = nil
			elseif not BlockWorld.occupied(world, mined.X, mined.Y, mined.Z) then
				depleted[mined] = nil
				mined.RespawnAt = nil
				BlockWorld.set(world, mined.X, mined.Y, mined.Z, mined.Block)
			end
		end
	end
	for field in growing do
		local left = field.ReadyAt - now
		FarmService.ShowCrop(field, field.Crop, 1 - math.max(left, 0) / field.Crop.GrowTime)
		if left <= 0 then
			growing[field] = nil
		end
	end
end

local function notice(player: Player, text: string)
	local now = os.clock()
	if now - (lastNotice[player] or 0) >= GROWING_NOTICE then
		lastNotice[player] = now
		StateService.Notify(player, text, "info")
	end
end

-- Clicking a wild crop: harvest it if it's ripe and you have the Farming level
local function onFarmClick(player: Player, x: unknown, y: unknown, z: unknown)
	if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
		return
	end
	local now = os.clock()
	if now - (lastClick[player] or 0) < 0.15 then
		return
	end
	lastClick[player] = now
	local field = fields[key(x, y, z)]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not field or not root or not root:IsA("BasePart") then
		return
	end
	if (root.Position - field.Base.Position).Magnitude > Blocks.Reach + 3 then
		return
	end
	local crop = field.Crop
	if ProgressionService.GetSkillLevel(player, "Farming") < crop.FarmingLevel then
		notice(player, `{crop.Id} needs Farming level {crop.FarmingLevel}. Wheat grows for everyone!`)
		return
	elseif now < field.ReadyAt then
		notice(player, `This {crop.Id} is still growing`)
		return
	end
	field.ReadyAt = now + crop.GrowTime
	growing[field] = true
	FarmService.ShowCrop(field, crop, 0)
	FarmService.Harvest(player, crop)
end

function WorldService.Start()
	local kind = Places.Current()
	build(kind)
	area = makeArea()

	local spawnPoint = Spawning.MakeSpawn(CENTER + Vector3.new(0, 0, (southZ + 4) * SIZE), Vector3.zAxis, world.Model)
	Spawning.Start(spawnPoint, CENTER.Y - FALL_LIMIT)

	Remotes.FarmClick.OnServerEvent:Connect(onFarmClick)
	Players.PlayerRemoving:Connect(function(player)
		lastNotice[player] = nil
		lastClick[player] = nil
	end)
	local timer = 0
	RunService.Heartbeat:Connect(function(dt)
		timer += dt
		if timer >= 1 then
			timer = 0
			regrow()
		end
	end)
end

return WorldService
