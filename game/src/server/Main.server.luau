--!strict
-- Server entry point. Starts each service once, depending on which place this server is
-- running (Places.luau):
--   Island   everyone's islands: blocks, farming, crafting, island expansion
--   Town     the hub: shopkeepers, player trading and the portals to the worlds
--   Mining / Woodcutting / Farming   a shared resource world (WorldService), where
--            BlockService breaks blocks in the world instead of on islands
-- The Warzone (WarzoneService, MobService) is built but switched off until PvE arrives.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Places = require(ReplicatedStorage.Shared.Places)
local Services = script.Parent.Services

local BlockService = require(Services.BlockService)
local CombatService = require(Services.CombatService)
local CraftingService = require(Services.CraftingService)
local DataService = require(Services.DataService)
local DevService = require(Services.DevService)
local FarmService = require(Services.FarmService)
local GearService = require(Services.GearService)
local HotbarService = require(Services.HotbarService)
local InboxService = require(Services.InboxService)
local IslandService = require(Services.IslandService)
local Leaderstats = require(Services.Leaderstats)
local QuestService = require(Services.QuestService)
local SeasonService = require(Services.SeasonService)
local ShopService = require(Services.ShopService)
local StateService = require(Services.StateService)
local TownService = require(Services.TownService)
local TradeService = require(Services.TradeService)
local TravelService = require(Services.TravelService)
local TreeService = require(Services.TreeService)
local WorldService = require(Services.WorldService)

local kind = Places.Current()
StateService.Start()
if kind == "Town" then
	TownService.Start()
	ShopService.Start()
	TradeService.Start()
elseif Places.IsWorld(kind) then
	WorldService.Start()
	BlockService.Start(WorldService.AreaFor)
else
	IslandService.Start()
	BlockService.Start()
	FarmService.Start()
	CraftingService.Start()
	TreeService.Start()
end
TravelService.Start()
GearService.Start()
CombatService.Start()
HotbarService.Start()
InboxService.Start()
QuestService.Start()
SeasonService.Start()
Leaderstats.Start()
DevService.Start()
-- Last, so every service is listening before player data loads
DataService.Start()
