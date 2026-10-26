--!strict
-- What WorldService hands each world's builder (Worlds/Mining, Woodcutting, Farming): the
-- block world and tools to fill it. Everything a builder sets is protected scenery
-- except nodes and fields, the resources players gather (they grow back).
--
-- Grid: x runs west to east, z south to north; y = 0 is the ground's usual height.

local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)

export type Context = {
	World: BlockWorld.World,
	Decor: Folder, -- scenery parts (outside the block world, so they never block aiming)
	Rng: Random, -- seeded per world: the same world every time
	Radius: number, -- the island's rough radius in blocks
	SouthZ: number, -- z of the arrival portals at the south end

	-- The island: `column(x, z)` gives the top block and its height for each column
	Ground: (column: (x: number, z: number) -> (string, number)) -> (),
	-- Is (x, z) at least `margin` blocks in from the island's edge?
	Inside: (x: number, z: number, margin: number) -> boolean,
	-- Is (x, z) within `margin` of the arrival square (kept flat and clear)?
	NearArrival: (x: number, z: number, margin: number) -> boolean,
	-- The ground's height at (x, z), as built
	HeightAt: (x: number, z: number) -> number,

	Set: (x: number, y: number, z: number, block: string?) -> (),
	SetFree: (x: number, y: number, z: number, block: string) -> (),
	-- A resource block that grows back after it's mined (skipped if the cell is taken)
	Node: (x: number, y: number, z: number, block: string) -> (),
	-- A wild crop growing on a farmland block at (x, y, z)
	Field: (x: number, y: number, z: number, crop: string) -> (),
	-- Top face of a block, where things stand
	Top: (x: number, y: number, z: number) -> Vector3,
	-- Same number every time for a cell, 0..1
	Hash: (x: number, y: number, z: number) -> number,
}

return {}
