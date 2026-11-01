--!strict
-- Water and lava (on islands; LiquidService runs them). A bucket pours a source block; the
-- liquid flows from it like Minecraft's: down while it can fall, otherwise out to the sides,
-- one level lower each block, until it runs out (water after 7 blocks, lava after 3, and
-- lava spreads slower). Where flowing lava meets water it turns to stone, so a lava source
-- beside water is a stone generator: mine the stone and it forms again.
-- Only sources are saved; the flowing blocks are worked out again when the island loads.
--
-- Block types (Blocks.luau gets one for each):
--   "Water", "Lava"                  sources (an empty Bucket scoops them back up)
--   "Water1".."Water7", "Lava1"..    flowing, by level: the higher, the farther from the
--                                    source and the lower it's drawn
--   "FallingWater", "FallingLava"    pouring straight down

export type Kind = {
	Id: string, -- "Water" or "Lava", also its source block
	Name: string,
	Spread: number, -- how many blocks it flows out to the sides
	StepTime: number, -- seconds it takes to flow one block further
	Falling: string, -- its falling block
	Bucket: string, -- the item an empty Bucket gives for its source
}

-- What one liquid block is
export type Cell = {
	Kind: Kind,
	Level: number, -- 0 for a source or falling block, 1..Spread flowing
	Source: boolean,
	Falling: boolean,
}

local Kinds: { [string]: Kind } = {
	Water = {
		Id = "Water",
		Name = "Water",
		Spread = 7,
		StepTime = 0.25,
		Falling = "FallingWater",
		Bucket = "WaterBucket",
	},
	Lava = {
		Id = "Lava",
		Name = "Lava",
		Spread = 3,
		StepTime = 1,
		Falling = "FallingLava",
		Bucket = "LavaBucket",
	},
}

local byBlock: { [string]: Cell } = {}
local flowBlocks: { [string]: { string } } = {}
for _, kind in Kinds do
	byBlock[kind.Id] = { Kind = kind, Level = 0, Source = true, Falling = false }
	byBlock[kind.Falling] = { Kind = kind, Level = 0, Source = false, Falling = true }
	local names = {}
	for level = 1, kind.Spread do
		local name = `{kind.Id}{level}`
		names[level] = name
		byBlock[name] = { Kind = kind, Level = level, Source = false, Falling = false }
	end
	flowBlocks[kind.Id] = names
end

local Liquids = {}

Liquids.Kinds = table.freeze(Kinds)
-- Liquid block type -> what it is (nil for any other block)
Liquids.ByBlock = table.freeze(byBlock)

-- The flowing block of `kind` at `level` (1..Spread)
function Liquids.Flow(kind: Kind, level: number): string
	return flowBlocks[kind.Id][level]
end

-- How tall a liquid block is drawn, as a share of a block: sources and falling blocks
-- nearly fill it, flowing ones get lower the farther they've spread
function Liquids.Height(cell: Cell): number
	if cell.Level == 0 then
		return 0.9
	end
	return 0.9 * (1 - cell.Level / (cell.Kind.Spread + 1))
end

return table.freeze(Liquids)
