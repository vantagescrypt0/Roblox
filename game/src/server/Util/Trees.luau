--!strict
-- The oak tree shape, shared by islands, the Woodcutting World and Town: a trunk of
-- `height` logs standing on the cell (x, baseY, z), two wide layers of leaves near the
-- top and a small cap. `put` is called for every block; it decides whether the cell is
-- free and what to do with it.

local Trees = {}

function Trees.Oak(
	x: number,
	baseY: number,
	z: number,
	height: number,
	put: (x: number, y: number, z: number, block: string) -> ()
)
	for y = 1, height do
		put(x, baseY + y, z, "Wood")
	end
	-- Two wide layers, then a small cap
	for ly = height - 1, height do
		for dx = -2, 2 do
			for dz = -2, 2 do
				local corner = math.abs(dx) == 2 and math.abs(dz) == 2
				if not corner and not (dx == 0 and dz == 0) then
					put(x + dx, baseY + ly, z + dz, "Leaves")
				end
			end
		end
	end
	for dx = -1, 1 do
		for dz = -1, 1 do
			if math.abs(dx) + math.abs(dz) < 2 or ((dx + dz + height) % 2 == 0) then
				put(x + dx, baseY + height + 1, z + dz, "Leaves")
			end
		end
	end
	put(x, baseY + height + 2, z, "Leaves")
	for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
		put(x + d[1], baseY + height + 2, z + d[2], "Leaves")
	end
end

return Trees
