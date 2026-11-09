--!strict
-- Tunable numbers shared by server and client.

local Config = {}

Config.Island = table.freeze({
	-- Y position of each island's grass surface
	Height = 200,
	-- Distance between island centers (studs): room for the biggest build border
	-- (IslandTiers) on both neighbours, plus a gap
	Spacing = 2400,
	PlotsPerRow = 6,
	Radius = 20,
	-- Model in ServerStorage.Assets; a greybox island is built if it's missing
	TemplateName = "StarterIsland",
	-- Fall this far below your island and you're put back on it
	FallLimit = 120,
})

-- Uploaded copies of the icon sheets, art/textures/item_icons.png then item_icons_2.png and on
-- (64 icons to a sheet, see ItemArt.luau). An icon whose sheet isn't listed falls back to a
-- live 3D preview. Uploaded with Studio's MCP upload_image (see art/README.md); every
-- re-render of the sheets needs a new upload, since cells move.
-- The Bag's equipment slot pictures (art/scripts/slot_icons.ps1); armor pieces use them as their
-- item icons too, tinted by tier
Config.SlotIcons = table.freeze({
	Helmet = "rbxassetid://125219234840382",
	Chest = "rbxassetid://86188456567729",
	Legs = "rbxassetid://98708952373456",
	Boots = "rbxassetid://95410567961432",
	Shield = "rbxassetid://91212786041472",
	Pet = "rbxassetid://112965300672337",
})

-- The hearts, hunger and armour over the hotbar (art/scripts/vitals_icons.py)
Config.VitalsSheet = "rbxassetid://95020115199214"

-- A soft round light, white so it can be tinted (art/scripts/slot_icons.ps1)
Config.GlowImage = "rbxassetid://72340108615521"

Config.ItemIconSheets = table.freeze({
	"rbxassetid://93743291124490",
	"rbxassetid://138476835803414",
	"rbxassetid://95151359504155",
})

-- Who can fly (double-tap Space, see client/FlightController): user ids. Only the game's
-- owner for now (koiopio).
Config.Flyers = table.freeze({
	[545120355] = true,
})
Config.FlySpeed = 70 -- studs per second, across
Config.FlyClimb = 45 -- studs per second, up and down

return table.freeze(Config)
