--!strict
-- What every item is worth, in coins, for trading between players.
--
--   Gathered things (wood, stone, ores, crops, seeds, Warzone loot) have a hand-set Value
--   in Items.luau, priced by how long they take to get.
--   Crafted things are worth what went into them plus CRAFT_PREMIUM for the work, worked
--   out from Recipes.luau, so changing a recipe updates the value automatically.
--   Worn tools are worth less: value x the share of uses they have left.
--
-- The Merchant pays about half of value (Items.SellPrice), so trading with players is
-- always the better deal. See the vault note "Economy & Values".

local Items = require(script.Parent.Items)
local Recipes = require(script.Parent.Recipes)
local Tools = require(script.Parent.Tools)

local CRAFT_PREMIUM = 1.1

local Economy = {}

local values: { [string]: number } = {}

local recipeFor: { [string]: Recipes.Recipe } = {}
for _, recipe in Recipes.List do
	recipeFor[recipe.Output] = recipe
end

local function work(itemId: string, depth: number): number
	local known = values[itemId]
	if known then
		return known
	end
	local item = Items[itemId]
	local value = 0
	if item and item.Value then
		value = item.Value
	elseif recipeFor[itemId] and depth < 10 then
		local recipe = recipeFor[itemId]
		local inputs = 0
		for input, count in recipe.Inputs do
			inputs += work(input, depth + 1) * count
		end
		value = math.max(1, math.round(inputs * CRAFT_PREMIUM / recipe.Amount))
	end
	values[itemId] = value
	return value
end

for itemId in Items do
	work(itemId, 0)
end

-- What one of this item is worth. For tools, pass how worn it is (uses spent).
function Economy.Value(itemId: string, wear: number?): number
	local value = values[itemId] or 0
	local tool = Tools.ByItem[itemId]
	if tool and wear and wear > 0 then
		value = math.max(1, math.round(value * (1 - wear / tool.Durability)))
	end
	return value
end

-- Total worth of a bundle of items, e.g. one side of a trade
function Economy.Total(items: { [string]: number }): number
	local total = 0
	for itemId, count in items do
		total += Economy.Value(itemId) * count
	end
	return total
end

return table.freeze(Economy)
