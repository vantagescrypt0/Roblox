--!strict
-- Tree shapes, shared by islands, the Woodcutting World, the Farming World and Town. Each
-- stands a trunk of logs on the cell (x, baseY, z) and calls `put` for every block; `put`
-- decides whether the cell is free and what to do with it (a node that grows back,
-- scenery, ...).
--   Oak      a trunk, two wide layers of leaves near the top and a small cap
--   BigOak   a taller trunk under a round crown about seven blocks across
--   Birch    a slim white trunk with a narrow crown
--   Spruce   a tall trunk under a cone of dark needles, wide at the bottom, to a point
--   Cherry   a short trunk that forks, under a wide, flat, drooping crown of blossom
--   Maple    a stout trunk under a big round crown in reds and oranges
--   Redwood  a giant: a bare trunk two or three blocks across, boughs only near the top
--   Mangrove a trunk up on arching roots, under a wide, low crown with roots hanging from it
--   Starwood a slim pale trunk with glowing round crowns on its branches
-- Oak and BigOak take other logs and leaves too (autumn trees in the Farming World).

local Trees = {}

type Put = (x: number, y: number, z: number, block: string) -> ()

function Trees.Oak(x: number, baseY: number, z: number, height: number, put: Put, log: string?, leaves: string?)
	local wood, leaf = log or "Wood", leaves or "Leaves"
	for y = 1, height do
		put(x, baseY + y, z, wood)
	end
	-- Two wide layers, then a small cap
	for ly = height - 1, height do
		for dx = -2, 2 do
			for dz = -2, 2 do
				local corner = math.abs(dx) == 2 and math.abs(dz) == 2
				if not corner and not (dx == 0 and dz == 0) then
					put(x + dx, baseY + ly, z + dz, leaf)
				end
			end
		end
	end
	for dx = -1, 1 do
		for dz = -1, 1 do
			if math.abs(dx) + math.abs(dz) < 2 or ((dx + dz + height) % 2 == 0) then
				put(x + dx, baseY + height + 1, z + dz, leaf)
			end
		end
	end
	put(x, baseY + height + 2, z, leaf)
	for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
		put(x + d[1], baseY + height + 2, z + d[2], leaf)
	end
end

function Trees.BigOak(x: number, baseY: number, z: number, height: number, put: Put, log: string?, leaves: string?)
	local wood, leaf = log or "Wood", leaves or "Leaves"
	for y = 1, height do
		put(x, baseY + y, z, wood)
	end
	local crown = baseY + height
	for dy = -2, 3 do
		for dx = -3, 3 do
			for dz = -3, 3 do
				local d = dx * dx + dz * dz + (dy * 1.3) ^ 2
				-- Ragged edge: the outermost ring is patchy
				local edge = d > 7.5 and (dx * 3 + dz * 5 + dy * 7) % 3 == 0
				if d <= 11 and not edge and not (dx == 0 and dz == 0 and dy <= 0) then
					put(x + dx, crown + dy, z + dz, leaf)
				end
			end
		end
	end
end

function Trees.Birch(x: number, baseY: number, z: number, height: number, put: Put)
	for y = 1, height do
		put(x, baseY + y, z, "BirchWood")
	end
	for ly = height - 2, height + 1 do
		local wide = ly == height - 1 or ly == height
		for dx = -2, 2 do
			for dz = -2, 2 do
				local ring = math.max(math.abs(dx), math.abs(dz))
				local corner = math.abs(dx) == 2 and math.abs(dz) == 2
				local inLayer = if wide then not corner else ring <= 1 and math.abs(dx) + math.abs(dz) < 2 + (ly % 2)
				if inLayer and not (dx == 0 and dz == 0 and ly <= height) then
					put(x + dx, baseY + ly, z + dz, "BirchLeaves")
				end
			end
		end
	end
	put(x, baseY + height + 2, z, "BirchLeaves")
end

function Trees.Spruce(x: number, baseY: number, z: number, height: number, put: Put)
	for y = 1, height do
		put(x, baseY + y, z, "SpruceWood")
	end
	-- Slim rings of needles from a few blocks up, wide and narrow in turn, to a point
	local RINGS = { 0, 1, 1, 2, 1, 2, 2, 1, 2, 2 } -- ring size by layers down from the top
	for ly = 3, height + 1 do
		local ring = RINGS[math.min(height + 2 - ly, #RINGS)]
		for dx = -ring, ring do
			for dz = -ring, ring do
				local corner = ring == 2 and math.abs(dx) == 2 and math.abs(dz) == 2
				local plus = ring == 1 and ly % 2 == 0 and math.abs(dx) + math.abs(dz) > 1
				if not corner and not plus and not (dx == 0 and dz == 0 and ly <= height) then
					put(x + dx, baseY + ly, z + dz, "SpruceLeaves")
				end
			end
		end
	end
	put(x, baseY + height + 2, z, "SpruceLeaves")
end

function Trees.Cherry(x: number, baseY: number, z: number, height: number, put: Put)
	for y = 1, height do
		put(x, baseY + y, z, "CherryWood")
	end
	-- Two branches leaning out from the top of the trunk, each under its own canopy
	local crowns = { { x, z } }
	for _, d in { { 1, 1 }, { -1, -1 } } do
		local bx, bz = x + d[1], z + d[2]
		put(bx, baseY + height + 1, bz, "CherryWood")
		put(bx + d[1], baseY + height + 2, bz + d[2], "CherryWood")
		table.insert(crowns, { bx + d[1], bz + d[2] })
	end
	for _, c in crowns do
		local cx, cz = c[1], c[2]
		for dy = 0, 2 do
			local r = if dy == 1 then 3 else 2
			for dx = -r, r do
				for dz = -r, r do
					local d = dx * dx + dz * dz
					if
						d <= r * r - (if dy == 1 then 2 else 0) and (d < r * r - 2 or (dx * 5 + dz * 3 + dy) % 3 ~= 0)
					then
						put(cx + dx, baseY + height + 1 + dy, cz + dz, "CherryLeaves")
					end
				end
			end
		end
		-- Blossom drooping from the rim
		for _, d in { { 3, 0 }, { -3, 0 }, { 0, 3 }, { 0, -3 } } do
			put(cx + d[1], baseY + height, cz + d[2], "CherryLeaves")
		end
	end
end

function Trees.Maple(x: number, baseY: number, z: number, height: number, put: Put)
	for y = 1, height do
		put(x, baseY + y, z, "MapleWood")
	end
	-- Limbs reaching out into the crown
	for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
		put(x + d[1], baseY + height, z + d[2], "MapleWood")
	end
	local crown = baseY + height + 1
	for dy = -2, 3 do
		for dx = -4, 4 do
			for dz = -4, 4 do
				local d = dx * dx + dz * dz + (dy * 1.4) ^ 2
				-- Ragged edge: the outermost ring is patchy
				local edge = d > 12 and (dx * 3 + dz * 5 + dy * 7) % 3 == 0
				if d <= 17 and not edge then
					-- Red, with patches of orange a few blocks across
					local patch = (math.floor((x + dx) / 3) * 7 + math.floor((z + dz) / 3) * 5 + math.floor(dy / 2)) % 3
					put(x + dx, crown + dy, z + dz, if patch == 0 then "AutumnLeaves" else "MapleLeaves")
				end
			end
		end
	end
end

-- `width` is how many blocks across the trunk is (2, or 3 for the oldest trees)
function Trees.Redwood(x: number, baseY: number, z: number, height: number, put: Put, width: number?)
	local across = width or 2
	for y = 1, height do
		for dx = 0, across - 1 do
			for dz = 0, across - 1 do
				put(x + dx, baseY + y, z + dz, "Redwood")
			end
		end
	end
	-- Roots flaring out at the foot
	for i = 0, across - 1 do
		put(x - 1, baseY + 1, z + i, "Redwood")
		put(x + across, baseY + 1, z + i, "Redwood")
		put(x + i, baseY + 1, z - 1, "Redwood")
		put(x + i, baseY + 1, z + across, "Redwood")
	end
	-- Rings of boughs from about two thirds of the way up, narrowing to a point
	local cx, cz = x + (across - 1) / 2, z + (across - 1) / 2
	local first = math.floor(height * 0.66)
	local top = height + 3
	for ly = first, top, 2 do
		local r = 1.5 + 3.5 * (1 - (ly - first) / (top - first))
		local reach = math.ceil(r)
		for dx = -reach, reach + across - 1 do
			for dz = -reach, reach + across - 1 do
				local bx, bz = x + dx, z + dz
				local d = math.sqrt((bx - cx) ^ 2 + (bz - cz) ^ 2)
				-- Ragged, so each ring reads as boughs and not a plate
				if d <= r and (d < r - 1.5 or (bx * 3 + bz * 5 + ly) % 3 ~= 0) then
					put(bx, baseY + ly, bz, "RedwoodLeaves")
				end
			end
		end
	end
	put(x, baseY + top + 1, z, "RedwoodLeaves")
end

function Trees.Mangrove(x: number, baseY: number, z: number, height: number, put: Put)
	-- The trunk starts above the water, on roots that arch out and down from it
	local lift = 3
	for y = lift + 1, height do
		put(x, baseY + y, z, "MangroveWood")
	end
	for _, d in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
		put(x + d[1], baseY + lift + 1, z + d[2], "MangroveWood")
		put(x + d[1] * 2, baseY + lift, z + d[2] * 2, "MangroveWood")
		put(x + d[1] * 3, baseY + lift - 1, z + d[2] * 3, "MangroveWood")
		put(x + d[1] * 3, baseY + 1, z + d[2] * 3, "MangroveWood")
	end
	-- A wide, low crown
	local crown = baseY + height + 1
	for dy = -1, 2 do
		local r = if dy == 2 then 2.6 elseif dy == 1 then 3.8 else 4.4
		local reach = math.ceil(r)
		for dx = -reach, reach do
			for dz = -reach, reach do
				local d = math.sqrt(dx * dx + dz * dz)
				if d <= r and (d < r - 1 or (dx * 3 + dz * 5 + dy) % 3 ~= 0) and not (d < 1 and dy < 1) then
					put(x + dx, crown + dy, z + dz, "MangroveLeaves")
				end
			end
		end
	end
	-- Roots hanging from the crown, down to the water
	for _, d in { { 3, 2 }, { -3, -2 } } do
		for y = 1, height do
			put(x + d[1], baseY + y, z + d[2], "MangroveWood")
		end
	end
end

function Trees.Starwood(x: number, baseY: number, z: number, height: number, put: Put)
	for y = 1, height do
		put(x, baseY + y, z, "Starwood")
	end
	local function orb(cx: number, cy: number, cz: number, r: number)
		local reach = math.ceil(r)
		for dx = -reach, reach do
			for dy = -reach, reach do
				for dz = -reach, reach do
					if dx * dx + dy * dy + dz * dz <= r * r then
						put(cx + dx, cy + dy, cz + dz, "StarwoodLeaves")
					end
				end
			end
		end
	end
	-- The tree's top, and two branches each carrying a smaller crown; which way they lean
	-- changes from tree to tree
	local turn = (x * 3 + z * 5) % 2
	local dirs: { { number } } = if turn == 0 then { { 1, 0 }, { -1, 0 } } else { { 0, 1 }, { 0, -1 } }
	local mid = baseY + math.floor(height * 0.65)
	for i, d in dirs do
		local up = mid + i
		put(x + d[1], up, z + d[2], "Starwood")
		put(x + d[1] * 2, up + 1, z + d[2] * 2, "Starwood")
		put(x + d[1] * 3, up + 1, z + d[2] * 3, "Starwood")
		orb(x + d[1] * 4, up + 2, z + d[2] * 4, 2)
	end
	orb(x, baseY + height + 2, z, 3)
end

return Trees
