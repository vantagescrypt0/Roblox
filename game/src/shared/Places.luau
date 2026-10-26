--!strict
-- The experience's places. Each runs on its own servers:
--   Island       the start place, where everyone's own island lives
--   Town         the shared hub: the shopkeepers, player trading and the world portals
--   Mining, Woodcutting, Farming
--                shared resource worlds (WorldService) with rocks, trees and crops that
--                grow back, reached through their portals in Town
--   Slaying      the PvE world (not built yet; its portal in Town is boarded up)
-- Which one a server is running comes from the PlaceKind attribute on Workspace, set in
-- each place's Rojo project file (default.project.json = Island, town.project.json = Town,
-- mining/woodcutting/farming.project.json = the worlds).

local Workspace = game:GetService("Workspace")

export type Kind = "Island" | "Town" | "Mining" | "Woodcutting" | "Farming" | "Slaying"

local Places = {}

-- Place ids in the published experience ("Sky Farm Prototype"); 0 = not published yet
Places.Ids = table.freeze({
	Island = 70908743282881,
	Town = 133194089069740,
	Mining = 0,
	Woodcutting = 0,
	Farming = 0,
	Slaying = 0,
})

-- How messages and the travel screen name each place ("Travelling to the Mining World...")
Places.Names = table.freeze({
	Island = "your island",
	Town = "Town",
	Mining = "the Mining World",
	Woodcutting = "the Woodcutting World",
	Farming = "the Farming World",
	Slaying = "the Slaying World",
})

-- The resource worlds WorldService can build
local WORLDS = { Mining = true, Woodcutting = true, Farming = true }

function Places.Current(): Kind
	local kind = Workspace:GetAttribute("PlaceKind")
	if type(kind) == "string" and (Places.Ids :: any)[kind] then
		return kind :: Kind
	end
	return "Island"
end

function Places.IsWorld(kind: string): boolean
	return WORLDS[kind] == true
end

return table.freeze(Places)
