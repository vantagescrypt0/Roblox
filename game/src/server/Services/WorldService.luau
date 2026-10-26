--!strict
-- The shared resource worlds (Places: Mining, Woodcutting, Farming). Each is its own
-- place, reached through its portal in Town, with resources everyone on the server shares.
-- Each world's scenery is built by its own module in server/Worlds:
--   Mining       a quarry camp and a mountain with a mine in it (Worlds/Mining)
--   Woodcutting  a forest on rolling hills with a river and a lumber camp (Worlds/Woodcutting)
--   Farming      a farmstead with fields of wild crops, a barn and a windmill (Worlds/Farming)
-- This service gives them the tools (Worlds/Context) and runs what they make:
--   nodes   resource blocks (rock, ore, logs, leaves): mine one and it grows back in the
--           same spot after a while (Blocks.NodeRespawn), so a world never runs out
--   fields  wild crops on farmland: click a ripe one to harvest it, it regrows
--           (Crops.GrowTime) for everyone
-- Everything else is scenery nobody can break, and nobody can build here. Gathering works
-- like on your island: BlockService does the breaking (tools, double drops, Mining and
-- Woodcutting XP, saplings from leaves) and FarmService the harvesting (Farming XP, hoe
-- bonus, spare seeds), with the same level gates (iron ore needs a Stone pickaxe, carrots
-- Farming 5, potatoes Farming 10).
-- Only today's resources grow here. Rarer ores, trees and crops will be found elsewhere.
-- Players arrive in a paved square at the south end; its portals lead back to Town or home.
--
-- Grid: x runs west to east, z south to north; y = 0 is the ground's usual height.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Crops = require(ReplicatedStorage.Shared.Crops)
local Places = require(ReplicatedStorage.Shared.Places)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Ambience = require(script.Parent.Parent.Util.Ambience)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local Decor = require(script.Parent.Parent.Util.Decor)
local Portal = require(script.Parent.Parent.Util.Portal)
local Signs = require(script.Parent.Parent.Util.Signs)
local Spawning = require(script.Parent.Parent.Util.Spawning)
local Context = require(script.Parent.Parent.Worlds.Context)
local BlockService = require(script.Parent.BlockService)
local FarmService = require(script.Parent.FarmService)
local ProgressionService = require(script.Parent.ProgressionService)
local StateService = require(script.Parent.StateService)
local TravelService = require(script.Parent.TravelService)

local CENTER = Vector3.new(0, 200, 0) -- top of the ground in the middle
local SIZE = Blocks.Size
local FALL_LIMIT = 140
local GROWING_NOTICE = 2 -- seconds between "still growing" messages per player
local TITLES: { [string]: string } = {
	Mining = "MINING WORLD",
	Woodcutting = "WOODCUTTING WORLD",
	Farming = "FARMING WORLD",
}

type Builder = { Radius: number, Haze: number, Caves: boolean?, Build: (ctx: Context.Context) -> () }
local BUILDERS: { [string]: Builder } = {
	Mining = require(script.Parent.Parent.Worlds.Mining) :: any,
	Woodcutting = require(script.Parent.Parent.Worlds.Woodcutting) :: any,
	Farming = require(script.Parent.Parent.Worlds.Farming) :: any,
}

type Node = { X: number, Y: number, Z: number, Block: string, RespawnAt: number? }
-- A wild crop: ripe from ReadyAt on (os.clock time)
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
local decor: Folder
local southZ = 0
local nodes: { [string]: Node } = {}
local depleted: { [Node]: boolean } = {}
local fields: { [string]: Field } = {} -- by farmland cell key
local growing: { [Field]: boolean } = {}
local lastNotice: { [Player]: number } = {}
local lastClick: { [Player]: number } = {}
local key = BlockWorld.key

-- Building tools ---------------------------------------------------------------------

local function makeContext(radius: number, seed: number): Context.Context
	local rng = Random.new(seed)
	local edgeNoise: { number } = {}
	for i = 0, 23 do
		edgeNoise[i] = rng:NextNumber(-1.5, 1.5)
	end
	local function edgeRadius(x: number, z: number): number
		local t = (math.atan2(z, x) / (2 * math.pi) + 0.5) * 24
		local i0 = math.floor(t) % 24
		local f = t - math.floor(t)
		return radius + edgeNoise[i0] * (1 - f) + edgeNoise[(i0 + 1) % 24] * f
	end
	local heights: { [string]: number } = {}

	local ctx = {} :: Context.Context
	ctx.World = world
	ctx.Decor = decor
	ctx.Rng = rng
	ctx.Radius = radius
	ctx.SouthZ = southZ

	function ctx.Set(x, y, z, block)
		local k = key(x, y, z)
		BlockWorld.setRaw(world, x, y, z, block)
		world.Protected[k] = true
		nodes[k] = nil
	end
	function ctx.SetFree(x, y, z, block)
		if not world.Cells[key(x, y, z)] then
			ctx.Set(x, y, z, block)
		end
	end
	function ctx.Node(x, y, z, block)
		local k = key(x, y, z)
		if world.Cells[k] then
			return
		end
		BlockWorld.setRaw(world, x, y, z, block)
		world.Protected[k] = nil
		nodes[k] = { X = x, Y = y, Z = z, Block = block }
	end
	function ctx.Field(x, y, z, cropId)
		ctx.Set(x, y, z, "Farmland")
		-- Crops need the space above free
		world.Protected[key(x, y + 1, z)] = true
		fields[key(x, y, z)] = {
			Crop = Crops.ById[cropId],
			ReadyAt = 0,
			Model = world.Model,
			Base = CFrame.new(BlockWorld.position(world, x, y, z) + Vector3.new(0, SIZE / 2, 0)),
			Stage = nil,
			Visual = nil,
		}
	end
	function ctx.Top(x, y, z)
		return BlockWorld.position(world, x, y, z) + Vector3.new(0, SIZE / 2, 0)
	end
	function ctx.Hash(x, y, z)
		return Random.new(x * 73856093 + y * 19349663 + z * 83492791 + seed):NextNumber()
	end
	function ctx.Inside(x, z, margin)
		return math.sqrt(x * x + z * z) <= edgeRadius(x, z) - margin
	end
	function ctx.NearArrival(x, z, margin)
		return z < southZ + 9 + margin and math.abs(x) < 9 + margin
	end
	function ctx.HeightAt(x, z)
		return heights[`{x},{z}`] or 0
	end
	function ctx.Ground(column)
		for x = -radius - 2, radius + 2 do
			for z = -radius - 2, radius + 2 do
				local distance = math.sqrt(x * x + z * z)
				local edge = edgeRadius(x, z)
				if distance <= edge then
					local block, height = column(x, z)
					heights[`{x},{z}`] = height
					ctx.Set(x, height, z, block)
					local t = distance / edge
					local depth = 2 + math.floor((1 - t) ^ 0.8 * 11) + (if (x * 7 + z * 13) % 3 == 0 then 1 else 0)
					for y = height - 1, -depth, -1 do
						ctx.Set(x, y, z, if y >= height - 2 then "Dirt" else "Stone")
					end
				end
			end
		end
	end
	return ctx
end

-- Arrival: a paved square at the south end with the portals home and to Town, lamps and
-- a welcome sign
local function buildArrival(ctx: Context.Context, kind: string)
	for x = -8, 8 do
		for z = southZ - 1, southZ + 8 do
			if world.Cells[key(x, 0, z)] then
				ctx.Set(x, 0, z, if math.abs(x) == 8 or z == southZ + 8 then "StoneBricks" else "SmoothStone")
				for y = 1, 6 do
					ctx.Set(x, y, z, nil)
				end
			end
		end
	end
	Portal.addCells(world.Cells, world.Protected, -4, southZ)
	Portal.addCells(world.Cells, world.Protected, 4, southZ)
	for _, x in { -2, 2 } do
		ctx.Set(x, 1, southZ + 9, "Wood")
		ctx.Set(x, 2, southZ + 9, "Wood")
	end
	-- Nailed to the front of the two posts, facing new arrivals
	Signs.Board(
		decor,
		"WelcomeSign",
		TITLES[kind] or string.upper(kind),
		BlockWorld.position(world, 0, 2.2, southZ + 9) - Vector3.new(0, 0, SIZE / 2 + 0.25),
		-Vector3.zAxis,
		6
	)
	for _, x in { -7, 7 } do
		for y = 1, 3 do
			ctx.Set(x, y, southZ + 6, "Wood")
		end
		Decor.Lantern(decor, ctx.Top(x, 3, southZ + 6), false, 20)
	end
end

local function portalFields()
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
			decor,
			`{portal.Sign}Sign`,
			portal.Sign,
			BlockWorld.position(world, portal.X, 6, southZ) + north * (SIZE / 2 + 0.25),
			north,
			2
		)
	end
end

local function build(kind: string)
	world = BlockWorld.new(CENTER - Vector3.new(0, SIZE / 2, 0), "World", workspace)
	world.Model:SetAttribute("Kind", kind)
	-- Scenery lives outside the block world so it never gets in the way of aiming
	decor = Instance.new("Folder")
	decor.Name = "WorldDecor"
	decor.Parent = workspace

	local builder = BUILDERS[kind]
	Ambience.Apply(builder.Haze, builder.Caves)
	southZ = -(builder.Radius - 3)
	local ctx = makeContext(builder.Radius, if kind == "Mining" then 11 elseif kind == "Woodcutting" then 22 else 33)
	builder.Build(ctx)
	buildArrival(ctx, kind)
	BlockWorld.drawAll(world)
	portalFields()
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
