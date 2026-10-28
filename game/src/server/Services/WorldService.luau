--!strict
-- The shared resource worlds (Places: Mining, Woodcutting, Farming). Each is its own
-- place, reached through its portal in Town, with resources everyone on the server shares.
-- Each world is a group of floating islands joined by bridges, built by its own module in
-- server/Worlds:
--   Mining       a quarry camp and a great mountain with a cavern full of ore (Worlds/Mining)
--   Woodcutting  oak woods, a birch grove, snowy pines and cherry blossom hills (Worlds/Woodcutting)
--   Farming      wheat plains, veggie gardens, a pumpkin hollow and a melon oasis (Worlds/Farming)
-- Each zone island has its own resource, gated by a skill level (BlockService, Crops).
-- This service gives them the tools (Worlds/Context) and runs what they make:
--   nodes   resource blocks (ore, logs, leaves): mine one and it grows back in the same
--           spot after a while (Blocks.NodeRespawn, the rarer the slower), so a world never
--           runs out. A mined ore turns pale (Empty Ore) until it fills back in, so the
--           cave never gets holes, and a node only breaks with the tool that collects it
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

-- SouthZ: where the arrival portals stand (x = 0); the builder puts an island under them
type Builder = { SouthZ: number, Seed: number, Haze: number, Caves: boolean?, Build: (ctx: Context.Context) -> () }
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
	-- A tall gateway on the square's north side, its sign well above everyone's heads
	Signs.Gateway(decor, ctx.Set, function(x, y, z)
		return BlockWorld.position(world, x, y, z)
	end, 0, southZ + 9, -Vector3.zAxis, TITLES[kind] or string.upper(kind), 7)
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
	southZ = builder.SouthZ
	local started = os.clock()
	local ctx = Context.new(world, decor, builder.Seed, southZ)
	-- The arrival square stays flat
	ctx.Flatten(-10, southZ - 2, 10, southZ + 10, true)
	builder.Build(ctx)
	buildArrival(ctx, kind)
	for k, spot in ctx.Nodes do
		nodes[k] = { X = spot.X, Y = spot.Y, Z = spot.Z, Block = spot.Block }
	end
	for k, spot in ctx.Fields do
		fields[k] = {
			Crop = Crops.ById[spot.Crop],
			ReadyAt = 0,
			Model = world.Model,
			Base = CFrame.new(ctx.Top(spot.X, spot.Y, spot.Z)),
			Stage = nil,
			Visual = nil,
		}
	end
	BlockWorld.drawAll(world, true)
	portalFields()
	for _, field in fields do
		FarmService.ShowCrop(field, field.Crop, 1)
	end
	print(
		`[World] {kind}: built in {string.format("%.1f", os.clock() - started)}s,`,
		`{BlockWorld.partCount(world)} block parts, {#decor:GetDescendants()} decor instances`
	)
end

-- Gathering ----------------------------------------------------------------------

-- Breaking blocks here (for BlockService): only nodes can be broken, and they grow back
local area: BlockService.Area
local function makeArea(): BlockService.Area
	return {
		World = world,
		Public = true,
		Natural = function(x, y, z)
			return nodes[key(x, y, z)] ~= nil
		end,
		Remains = function(x, y, z)
			local mined = nodes[key(x, y, z)]
			return if mined and Blocks.Types[mined.Block].Ore then "EmptyOre" else nil
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
			-- An empty ore fills back in; an empty spot grows back once nobody stands in it
			local cell = BlockWorld.get(world, mined.X, mined.Y, mined.Z)
			if cell == "EmptyOre" or (cell == nil and not BlockWorld.occupied(world, mined.X, mined.Y, mined.Z)) then
				depleted[mined] = nil
				mined.RespawnAt = nil
				BlockWorld.set(world, mined.X, mined.Y, mined.Z, mined.Block)
			elseif cell ~= nil then
				depleted[mined] = nil
				mined.RespawnAt = nil
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
