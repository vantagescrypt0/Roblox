--!strict
-- The decorations the Builder sells: the same pieces Town and the worlds are dressed with
-- (Util/Decor), made in art/scripts/decor.py. Each one is a block type too (Blocks.luau), so it
-- places, breaks and saves like a block, but it's drawn as its model (ReplicatedStorage.DecorModels)
-- and it's see-through to the blocks round it.
--   Mount   Floor: stands on a solid block, facing whoever placed it
--           Wall: on the side of a solid block, facing out
--           Water: floats on water
--   Anchor  where the model's origin goes, from the middle of the cell, before it's turned
--   Tall    how many cells it reaches up: nothing can be placed in those
--   Solid   players bump into it
-- It stands on or hangs from what's next to it: break that and it comes back to your Bag.

local DecorArt = require(script.Parent.DecorArt)

export type Mount = "Floor" | "Wall" | "Water"

export type Decoration = {
	Block: string,
	Item: string,
	Name: string,
	Icon: string,
	Price: number,
	Model: string,
	Mount: Mount,
	Anchor: Vector3,
	Tall: number,
	Solid: boolean,
	Tint: Color3?,
	Tool: string?,
	Hardness: number,
	Light: { Range: number, Brightness: number }?,
}

type Options = {
	Block: string?,
	Item: string?,
	Model: string?,
	Anchor: Vector3?,
	Solid: boolean?,
	Tint: Color3?,
	Tool: string?,
	Light: { Range: number, Brightness: number }?,
}

local BLOCK_SIZE = 3
-- A source of water fills 0.9 of its block (Liquids.luau), so a lily pad sits that far down in
-- the cell over it
local WATER_GAP = BLOCK_SIZE * 0.1

local byBlock: { [string]: Decoration } = {}
local byItem: { [string]: Decoration } = {}
local items: { string } = {}

local function add(id: string, name: string, icon: string, price: number, mount: Mount, options: Options?)
	local given: Options = options or {}
	local block = given.Block or id
	local item = given.Item or id
	local model = given.Model or block
	local art = DecorArt[model]
	local tall = 1
	if mount == "Floor" and art then
		tall = math.max(1, math.ceil((art.Center.Y + art.Size.Y / 2) / BLOCK_SIZE - 0.05))
	end
	local default = if mount == "Wall"
		then Vector3.new(0, 0, BLOCK_SIZE / 2)
		elseif mount == "Water" then Vector3.new(0, -BLOCK_SIZE / 2 - WATER_GAP, 0)
		else Vector3.new(0, -BLOCK_SIZE / 2, 0)
	local decoration: Decoration = {
		Block = block,
		Item = item,
		Name = name,
		Icon = icon,
		Price = price,
		Model = model,
		Mount = mount,
		Anchor = given.Anchor or default,
		Tall = tall,
		Solid = given.Solid == true,
		Tint = given.Tint,
		Tool = given.Tool,
		-- Quick to take back up, with or without a tool
		Hardness = if given.Tool then 0.5 else 0,
		Light = given.Light,
	}
	byBlock[block] = decoration
	if not byItem[item] then
		byItem[item] = decoration
		table.insert(items, item)
	end
end

local RED = Color3.fromRGB(196, 52, 46)
local BLUE = Color3.fromRGB(58, 104, 196)
local GREEN = Color3.fromRGB(72, 148, 64)
local YELLOW = Color3.fromRGB(232, 190, 64)

-- Lights
add(
	"LampPost",
	"Lamp Post",
	"🏮",
	25,
	"Floor",
	{ Solid = true, Tool = "Axe", Light = { Range = 22, Brightness = 1.3 } }
)
add("Lantern", "Lantern", "🏮", 12, "Floor", { Tool = "Pickaxe", Light = { Range = 18, Brightness = 1.2 } })
add("WallLantern", "Wall Lantern", "🏮", 15, "Wall", {
	Anchor = Vector3.new(0, 0.6, BLOCK_SIZE / 2),
	Tool = "Pickaxe",
	Light = { Range = 16, Brightness = 1.2 },
})
add(
	"StoneLantern",
	"Stone Lantern",
	"🏮",
	20,
	"Floor",
	{ Solid = true, Tool = "Pickaxe", Light = { Range = 16, Brightness = 1 } }
)
add(
	"JackOLantern",
	"Jack-o'-Lantern",
	"🎃",
	15,
	"Floor",
	{ Solid = true, Tool = "Axe", Light = { Range = 12, Brightness = 1 } }
)

-- Seats, fences, signs and cloth
add("Bench", "Bench", "🪑", 12, "Floor", { Solid = true, Tool = "Axe" })
add("Fence", "Fence", "🪵", 4, "Floor", { Solid = true, Tool = "Axe" })
add("Sign", "Sign", "🪧", 8, "Floor", { Block = "SignPost", Solid = true, Tool = "Axe" })
add("WallSign", "Sign", "🪧", 8, "Wall", { Item = "Sign", Tool = "Axe" })
for _, banner in
	{
		{ "BannerRed", "Red Banner", RED },
		{ "BannerBlue", "Blue Banner", BLUE },
		{ "BannerGreen", "Green Banner", GREEN },
		{ "BannerYellow", "Yellow Banner", YELLOW },
	}
do
	add(banner[1], banner[2], "🚩", 10, "Wall", {
		Model = "Banner",
		Anchor = Vector3.new(0, 1.2, BLOCK_SIZE / 2 - 0.15),
		Tint = banner[3],
		Tool = "Axe",
	})
end
add("Awning", "Awning", "⛱️", 10, "Wall", { Anchor = Vector3.new(0, 1.4, BLOCK_SIZE / 2), Tool = "Axe" })

-- Plants
for _, flower in
	{
		{ "FlowerRed", "Red Flower", RED },
		{ "FlowerYellow", "Yellow Flower", YELLOW },
		{ "FlowerBlue", "Blue Flower", BLUE },
		{ "FlowerWhite", "White Flower", Color3.fromRGB(244, 240, 228) },
		{ "FlowerPink", "Pink Flower", Color3.fromRGB(240, 136, 180) },
	}
do
	add(flower[1], flower[2], "🌸", 3, "Floor", { Model = "Flower", Tint = flower[3] })
end
add("TallGrass", "Tall Grass", "🌿", 2, "Floor")
add("MushroomRed", "Red Mushroom", "🍄", 4, "Floor")
add("MushroomBrown", "Brown Mushroom", "🍄", 4, "Floor")
add("FlowerBox", "Flower Box", "🌼", 8, "Wall", { Anchor = Vector3.new(0, -1, BLOCK_SIZE / 2), Tool = "Axe" })
add("LilyPad", "Lily Pad", "🪷", 4, "Water")
add("Cactus", "Cactus", "🌵", 12, "Floor", { Model = "Cactus2", Solid = true })
add("PalmTree", "Palm Tree", "🌴", 30, "Floor", { Solid = true, Tool = "Axe" })

-- Mine and farm
add("Minecart", "Minecart", "🛒", 30, "Floor", { Solid = true, Tool = "Pickaxe" })
add("Rails", "Rails", "🛤️", 5, "Floor", { Tool = "Pickaxe" })

return table.freeze({
	ByBlock = table.freeze(byBlock),
	ByItem = table.freeze(byItem),
	-- Item ids, in the order the Builder lists them
	Items = table.freeze(items),
})
