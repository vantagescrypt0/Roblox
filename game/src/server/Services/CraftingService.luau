--!strict
-- The crafting table block on your island. Right-clicking it (tapping on mobile) opens
-- the crafting window on the client; crafting is checked and done entirely on the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Recipes = require(ReplicatedStorage.Shared.Recipes)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local IslandService = require(script.Parent.IslandService)
local QuestService = require(script.Parent.QuestService)
local StateService = require(script.Parent.StateService)

-- How close you must be to your crafting table to craft (a bit more than block reach)
local MAX_CRAFT_DISTANCE = 24

local CraftingService = {}

local workbenches: { [Player]: BasePart } = {}

local function craft(player: Player, recipeId: unknown)
	if type(recipeId) ~= "string" then
		return
	end
	local recipe = Recipes.ById[recipeId]
	local data = DataService.GetData(player)
	local bench = workbenches[player]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not recipe or not data or not bench or not root or not root:IsA("BasePart") then
		return
	end
	if (root.Position - bench.Position).Magnitude > MAX_CRAFT_DISTANCE then
		StateService.Notify(player, "Get closer to your crafting table", "bad")
		return
	end
	if data.Level < recipe.PlayerLevel then
		StateService.Notify(player, `Needs level {recipe.PlayerLevel}`, "bad")
		return
	end
	if not InventoryService.RemoveMany(player, recipe.Inputs) then
		StateService.Notify(player, "Not enough materials", "bad")
		return
	end
	InventoryService.Add(player, recipe.Output, recipe.Amount)
	StateService.Notify(player, `Crafted {Items[recipe.Output].Name}!`, "good")
	QuestService.Record(player, "Craft")
	QuestService.Record(player, `Craft:{recipe.Id}`)
end

local function onIslandCreated(player: Player, island: IslandService.Island)
	local cell = island.CraftingTable
	local bench = BlockWorld.part(island.World, cell.X, cell.Y, cell.Z)
	if not bench then
		return
	end
	workbenches[player] = bench
	bench.Destroying:Connect(function()
		if workbenches[player] == bench then
			workbenches[player] = nil
		end
	end)
end

function CraftingService.Start()
	IslandService.OnIslandCreated(onIslandCreated)
	Remotes.Craft.OnServerEvent:Connect(craft)
end

return CraftingService
