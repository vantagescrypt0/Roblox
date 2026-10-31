--!strict
-- Water and lava on islands (Liquids.luau). A source is an ordinary saved block, poured from
-- a bucket. Whenever a block on the island changes, this works out again where every source
-- flows and draws the flowing blocks, spreading a block at a time (water every 0.25 s, lava
-- every second). Flowing blocks are never saved: they're worked out again when the island
-- loads. Wherever flowing water would touch lava, or flowing lava would touch water, that
-- cell turns to stone instead (saved like a placed block). Mine the stone and the flow comes
-- back and turns to stone again: a stone generator.
-- Lava burns whoever stands in it. Also builds the liquids' look (LiquidModels) on every
-- server, for icons.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Liquids = require(ReplicatedStorage.Shared.Liquids)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local LiquidModels = require(script.Parent.Parent.Util.LiquidModels)
local IslandService = require(script.Parent.IslandService)

-- How far liquid may flow from the island's middle (blocks), and the lowest and highest
-- cells it may fill (a waterfall off the edge stops a little below the island)
local REACH, BOTTOM, TOP = 40, -45, 60
local SIDES = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
local NEIGHBOURS = { { 1, 0, 0 }, { -1, 0, 0 }, { 0, 1, 0 }, { 0, -1, 0 }, { 0, 0, 1 }, { 0, 0, -1 } }
-- Seconds at least before stone forms where water and lava meet
local STONE_TIME = 1
-- Lava: damage per burn, seconds between burns, seconds between checks
local LAVA_DAMAGE, BURN_EVERY, CHECK_EVERY = 6, 0.5, 0.2

local key, unkey = BlockWorld.key, BlockWorld.unkey

type State = {
	Player: Player,
	Island: IslandService.Island,
	-- Source cells on the island
	Sources: { [string]: boolean },
	-- The flowing blocks drawn now: cell -> block type
	Flows: { [string]: string },
	-- Goes up with every new plan, so an older one stops filling
	Version: number,
	Queued: boolean,
}

-- Where everything should flow: the flowing block for each cell and the seconds until it
-- fills (0 for cells already wet), and the cells where lava turns to stone
type Plan = {
	Flows: { [string]: string },
	Delays: { [string]: number },
	Stone: { [string]: number },
}

local LiquidService = {}

local states: { [Player]: State } = {}
local lastBurn: { [Player]: number } = {}
-- True while this service changes cells itself, so those changes don't plan again
local applying = false

local function plan(state: State): Plan
	local island = state.Island
	local world = island.World
	local cells = world.Cells
	local flows: { [string]: string } = {}
	local levels: { [string]: number } = {}
	local delays: { [string]: number } = {}
	local stone: { [string]: number } = {}

	-- Can liquid go here? An empty cell, or one only flowing liquid is in (worked out again
	-- now); never a protected cell (farmland, crops, a growing sapling) or a resource node
	local function free(x: number, y: number, z: number): boolean
		if math.abs(x) > REACH or math.abs(z) > REACH or y < BOTTOM or y > TOP then
			return false
		end
		local k = key(x, y, z)
		if world.Protected[k] or island.Nodes[k] then
			return false
		end
		local blockType = cells[k]
		local cell = blockType and Liquids.ByBlock[blockType]
		return blockType == nil or (cell ~= nil and not cell.Source)
	end

	-- "Water" or "Lava" if that liquid is in the cell: a source, or planned to flow there
	local function liquidAt(k: string): string?
		local flow = flows[k]
		if flow then
			return Liquids.ByBlock[flow].Kind.Id
		end
		local blockType = cells[k]
		local cell = blockType and Liquids.ByBlock[blockType]
		return if cell and cell.Source then cell.Kind.Id else nil
	end

	local function touches(x: number, y: number, z: number, liquid: string): boolean
		for _, d in NEIGHBOURS do
			if liquidAt(key(x + d[1], y + d[2], z + d[3])) == liquid then
				return true
			end
		end
		return false
	end

	local function spread(kind: Liquids.Kind)
		local other = if kind.Id == "Water" then "Lava" else "Water"
		local queue: { { number } } = {}
		for k in state.Sources do
			if cells[k] == kind.Id then
				local x, y, z = unkey(k)
				table.insert(queue, { x, y, z, 0, 0 })
			end
		end

		-- Is the cell this liquid already (so it fills at once)?
		local function wet(k: string): boolean
			local blockType = cells[k]
			local cell = blockType and Liquids.ByBlock[blockType]
			return cell ~= nil and cell.Kind == kind
		end

		-- Flows into a cell at `level` (0 when falling), `delay` seconds from now
		local function enter(x: number, y: number, z: number, level: number, falling: boolean, delay: number)
			local k = key(x, y, z)
			if touches(x, y, z, other) then
				-- It would touch the other liquid: stone forms here instead
				local at = math.max(delay, STONE_TIME)
				if stone[k] == nil or at < stone[k] then
					stone[k] = at
				end
				return
			end
			local best = levels[k]
			if best and best <= level then
				return
			end
			levels[k] = level
			flows[k] = if falling then kind.Falling else Liquids.Flow(kind, level)
			delays[k] = if wet(k) then 0 else delay
			table.insert(queue, { x, y, z, level, delays[k] })
		end

		local head = 1
		while head <= #queue do
			local entry = queue[head]
			head += 1
			local x, y, z, level, delay = entry[1], entry[2], entry[3], entry[4], entry[5]
			local best = levels[key(x, y, z)]
			if best and best < level then
				continue -- this cell was reached better since
			end
			local step = delay + kind.StepTime
			if free(x, y - 1, z) and liquidAt(key(x, y - 1, z)) ~= other then
				-- Nothing underneath: it pours straight down, and doesn't spread
				enter(x, y - 1, z, 0, true, step)
			elseif level < kind.Spread then
				for _, d in SIDES do
					local nx, nz = x + d[1], z + d[2]
					if free(nx, y, nz) and liquidAt(key(nx, y, nz)) ~= other then
						enter(nx, y, nz, level + 1, false, step)
					end
				end
			end
		end
	end

	-- Water first (it stops beside lava sources), then lava round the water
	spread(Liquids.Kinds.Water)
	spread(Liquids.Kinds.Lava)
	return { Flows = flows, Delays = delays, Stone = stone }
end

-- Works out the flows again and changes the island to match: dried-up cells go at once,
-- new ones fill as the flow reaches them (`instant`: all at once, as an island loads)
local function apply(state: State, instant: boolean?)
	if states[state.Player] ~= state then
		return
	end
	local world = state.Island.World
	for k in state.Sources do
		local blockType = world.Cells[k]
		local cell = blockType and Liquids.ByBlock[blockType]
		if not cell or not cell.Source then
			state.Sources[k] = nil
		end
	end
	local target = plan(state)
	state.Version += 1
	local version = state.Version

	applying = true
	for k, blockType in state.Flows do
		if target.Flows[k] ~= blockType then
			state.Flows[k] = nil
			if world.Cells[k] == blockType then
				local x, y, z = unkey(k)
				BlockWorld.set(world, x, y, z, nil)
			end
		end
	end
	applying = false

	local steps: { { Key: string, Block: string, At: number } } = {}
	for k, blockType in target.Flows do
		if state.Flows[k] ~= blockType then
			table.insert(steps, { Key = k, Block = blockType, At = target.Delays[k] })
		end
	end
	for k, at in target.Stone do
		table.insert(steps, { Key = k, Block = "Stone", At = at })
	end
	if #steps == 0 then
		return
	end
	table.sort(steps, function(a, b)
		return a.At < b.At
	end)

	local function fill()
		local started = os.clock()
		for _, step in steps do
			local wait = if instant then 0 else step.At - (os.clock() - started)
			if wait > 0 then
				task.wait(wait)
			end
			if states[state.Player] ~= state or state.Version ~= version then
				return
			end
			local current = world.Cells[step.Key]
			local cell = current and Liquids.ByBlock[current]
			if current == nil or (cell and not cell.Source) then
				local x, y, z = unkey(step.Key)
				if step.Block == "Stone" then
					-- Lava met water. A real block: saved, and the flows are worked out again
					state.Flows[step.Key] = nil
					BlockWorld.set(world, x, y, z, "Stone")
					IslandService.RecordChange(state.Player, x, y, z, "Stone")
				else
					applying = true
					BlockWorld.set(world, x, y, z, step.Block)
					applying = false
					state.Flows[step.Key] = step.Block
				end
			end
		end
	end
	if instant then
		fill()
	else
		task.spawn(fill)
	end
end

-- Plans again once this frame's changes are all in
local function queue(state: State)
	if state.Queued then
		return
	end
	state.Queued = true
	task.defer(function()
		state.Queued = false
		apply(state)
	end)
end

local function onChanged(state: State, x: number, y: number, z: number)
	if applying then
		return
	end
	local k = key(x, y, z)
	local blockType = state.Island.World.Cells[k]
	local cell = blockType and Liquids.ByBlock[blockType]
	if cell and cell.Source then
		state.Sources[k] = true
	end
	if next(state.Sources) or next(state.Flows) then
		queue(state)
	end
end

local function onIsland(player: Player, island: IslandService.Island)
	local state: State = {
		Player = player,
		Island = island,
		Sources = {},
		Flows = {},
		Version = 0,
		Queued = false,
	}
	for k, blockType in island.World.Cells do
		local cell = Liquids.ByBlock[blockType]
		if cell and cell.Source then
			state.Sources[k] = true
		end
	end
	states[player] = state
	island.World.Changed = function(x, y, z)
		onChanged(state, x, y, z)
	end
	if next(state.Sources) then
		apply(state, true)
	end
end

local function burn(player: Player, humanoid: Humanoid, root: BasePart)
	local now = os.clock()
	if now - (lastBurn[player] or 0) < BURN_EVERY then
		return
	end
	lastBurn[player] = now
	humanoid:TakeDamage(LAVA_DAMAGE)
	if not root:FindFirstChild("LavaFire") then
		local fire = Instance.new("Fire")
		fire.Name = "LavaFire"
		fire.Size = 4
		fire.Heat = 6
		fire.Parent = root
		task.delay(1.2, function()
			fire:Destroy()
		end)
	end
end

-- Anyone standing in lava (body or feet) burns
local function checkLava()
	for player, state in states do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			local world = state.Island.World
			for _, drop in { 0, 2.8 } do
				local x, y, z = BlockWorld.cellAt(world, root.Position - Vector3.new(0, drop, 0))
				local blockType = world.Cells[key(x, y, z)]
				local def = blockType and Blocks.Types[blockType]
				if def and def.Liquid == "Lava" then
					burn(player, humanoid, root)
					break
				end
			end
		end
	end
end

function LiquidService.Start()
	LiquidModels.Make()
	IslandService.OnIslandCreated(onIsland)
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
		lastBurn[player] = nil
	end)
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= CHECK_EVERY then
			elapsed = 0
			checkLava()
		end
	end)
end

return LiquidService
