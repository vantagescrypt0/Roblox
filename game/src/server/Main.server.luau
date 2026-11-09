--!strict
-- Server entry point. Starts each service once, depending on which place this server is
-- running (Places.luau):
--   Island   everyone's islands: blocks, farming, crafting, island expansion
--   Town     the hub: shopkeepers, player trading and the portals to the worlds
--   Mining / Woodcutting / Farming   a shared resource world (WorldService), where
--            BlockService breaks blocks in the world instead of on islands
--   Warzone  PvP across floating islands (WarzoneService, Worlds/Warzone)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Places = require(ReplicatedStorage.Shared.Places)
local StationModels = require(script.Parent.Util.StationModels)
local Services = script.Parent.Services

local AwardService = require(Services.AwardService)
local BlockService = require(Services.BlockService)
local BodyService = require(Services.BodyService)
local ChestService = require(Services.ChestService)
local CombatService = require(Services.CombatService)
local CrateService = require(Services.CrateService)
local CraftingService = require(Services.CraftingService)
local DataService = require(Services.DataService)
local DecorService = require(Services.DecorService)
local DevService = require(Services.DevService)
local FarmService = require(Services.FarmService)
local GearService = require(Services.GearService)
local HotbarService = require(Services.HotbarService)
local InboxService = require(Services.InboxService)
local IslandService = require(Services.IslandService)
local KitService = require(Services.KitService)
local Leaderstats = require(Services.Leaderstats)
local LiquidService = require(Services.LiquidService)
local LootChestService = require(Services.LootChestService)
local QuestService = require(Services.QuestService)
local SeasonService = require(Services.SeasonService)
local ShopService = require(Services.ShopService)
local SprintService = require(Services.SprintService)
local StateService = require(Services.StateService)
local TownService = require(Services.TownService)
local TradeService = require(Services.TradeService)
local TravelService = require(Services.TravelService)
local TreeService = require(Services.TreeService)
local SkydropService = require(Services.SkydropService)
local SpawnerService = require(Services.SpawnerService)
local VisitService = require(Services.VisitService)
local WarzoneService = require(Services.WarzoneService)
local WorldService = require(Services.WorldService)

local kind = Places.Current()
-- The Anvil's, Gem Bench's and chests' looks, in every place (islands draw them, icons show them)
StationModels.Make()
StateService.Start()
if kind == "Town" then
	TownService.Start()
	ShopService.Start()
	TradeService.Start()
elseif Places.IsWorld(kind) then
	WorldService.Start()
	BlockService.Start(WorldService.AreaFor)
elseif kind == "Warzone" then
	WarzoneService.Start()
	LootChestService.Start()
	SkydropService.Start()
	BodyService.StartWarzone()
else
	IslandService.Start()
	DecorService.Start()
	VisitService.Start()
	ChestService.StartIsland()
	BlockService.Start()
	FarmService.Start()
	CraftingService.Start()
	TreeService.Start()
	SpawnerService.Start()
end
TravelService.Start()
ChestService.Start()
GearService.Start()
LiquidService.Start()
CombatService.Start()
SprintService.Start()
HotbarService.Start()
InboxService.Start()
BodyService.Start()
CrateService.Start()
KitService.Start()
AwardService.Start()
QuestService.Start()
SeasonService.Start()
Leaderstats.Start()
DevService.Start()
-- Last, so every service is listening before player data loads
DataService.Start()
