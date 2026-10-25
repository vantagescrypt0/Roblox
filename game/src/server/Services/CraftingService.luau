--!strict
-- Crafting at the crafting table and smelting in a furnace. Clicking either block opens
-- the crafting window on the client (showing that station's recipes); crafting is checked
-- and done entirely on the server, which makes sure the right station is close by and
-- that you have the skill levels the recipe needs. Every craft gives Crafting XP.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Recipes = require(ReplicatedStorage.Shared.Recipes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Skills = require(ReplicatedStorage.Shared.Skills)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local IslandService = require(script.Parent.IslandService)
local ProgressionService = require(script.Parent.ProgressionService)
local QuestService = require(script.Parent.QuestService)
local StateService = require(script.Parent.StateService)

-- How close you must be to the station to craft (a bit more than block reach)
local MAX_CRAFT_DISTANCE = 24
local STATION_NAMES = { CraftingTable = "crafting table", Furnace = "furnace" }

local CraftingService = {}

-- Is a block of this type on the player's island within crafting distance?
local function nearStation(player: Player, position: Vector3, blockType: string): boolean
	local island = IslandService.GetIsland(player)
	if not island then
		return false
	end
	local world = island.World
	for cellKey, cellType in world.Cells do
		if cellType == blockType then
			local x, y, z = BlockWorld.unkey(cellKey)
			if (BlockWorld.position(world, x, y, z) - position).Magnitude <= MAX_CRAFT_DISTANCE then
				return true
			end
		end
	end
	return false
end

local function craft(player: Player, recipeId: unknown)
	if type(recipeId) ~= "string" then
		return
	end
	local recipe = Recipes.ById[recipeId]
	local data = DataService.GetData(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not recipe or not data or not root or not root:IsA("BasePart") then
		return
	end
	if not nearStation(player, root.Position, recipe.Station) then
		StateService.Notify(player, `Get closer to your {STATION_NAMES[recipe.Station]}`, "bad")
		return
	end
	local function levelOf(skillId: string): number
		return ProgressionService.GetSkillLevel(player, skillId)
	end
	local _, skilled = Skills.Check(recipe.Requires, levelOf)
	if not skilled then
		StateService.Notify(player, `Needs {Skills.Describe(recipe.Requires, levelOf)}`, "bad")
		return
	end
	if not InventoryService.RemoveMany(player, recipe.Inputs) then
		StateService.Notify(player, "Not enough materials", "bad")
		return
	end
	InventoryService.Add(player, recipe.Output, recipe.Amount)
	local verb = if recipe.Station == "Furnace" then "Smelted" else "Crafted"
	StateService.Notify(player, `{verb} {Items[recipe.Output].Name}!`, "good")
	ProgressionService.AddSkillXP(player, "Crafting", recipe.CraftingXP)
	QuestService.Record(player, "Craft")
	QuestService.Record(player, `Craft:{recipe.Id}`)
end

function CraftingService.Start()
	Remotes.Craft.OnServerEvent:Connect(craft)
end

return CraftingService
