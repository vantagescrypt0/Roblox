--!strict
-- Block types (Minecraft-style). Each one has a cube mesh in ReplicatedStorage.Blocks
-- with the same name (made in art/scripts/blocks.py). Blocks are 3 studs.

export type Block = {
	Name: string,
	Drop: string?, -- item you get when you break it (nil = nothing)
	BreakTime: number, -- seconds of holding to break it by hand
	Breakable: boolean,
	SeeThrough: boolean?, -- blocks behind it still get drawn (leaves)
}

local Blocks: { [string]: Block } = {
	Grass = { Name = "Grass Block", Drop = "Grass", BreakTime = 0.45, Breakable = true },
	Dirt = { Name = "Dirt", Drop = "Dirt", BreakTime = 0.45, Breakable = true },
	Stone = { Name = "Stone", Drop = "Stone", BreakTime = 1.4, Breakable = true },
	Cobblestone = { Name = "Cobblestone", Drop = "Stone", BreakTime = 1.4, Breakable = true },
	Wood = { Name = "Wood", Drop = "Wood", BreakTime = 0.9, Breakable = true },
	Planks = { Name = "Planks", Drop = "Planks", BreakTime = 0.7, Breakable = true },
	Leaves = { Name = "Leaves", Drop = nil, BreakTime = 0.15, Breakable = true, SeeThrough = true },
	RedWool = { Name = "Red Wool", Drop = nil, BreakTime = 0.3, Breakable = true },
	WhiteWool = { Name = "White Wool", Drop = nil, BreakTime = 0.3, Breakable = true },
	-- Special blocks the game places; players can't break them
	CraftingTable = { Name = "Crafting Table", Drop = nil, BreakTime = 1, Breakable = false },
	Farmland = { Name = "Farmland", Drop = nil, BreakTime = 1, Breakable = false },
	Obsidian = { Name = "Obsidian", Drop = nil, BreakTime = 1, Breakable = false },
}

local Size = 3

return table.freeze({
	Size = Size,
	-- How far away (studs) you can break or place blocks
	Reach = 20,
	Types = table.freeze(Blocks),
})
