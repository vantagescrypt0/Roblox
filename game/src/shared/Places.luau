--!strict
-- The experience's places. Each runs on its own servers:
--   Island  the start place, where everyone's own island lives
--   Town    the shared plaza with the Market (and later the Warzone gate)
-- Which one a server is running comes from the PlaceKind attribute on Workspace, set in
-- each place's Rojo project file (default.project.json = Island, town.project.json = Town).

local Workspace = game:GetService("Workspace")

export type Kind = "Island" | "Town"

local Places = {}

-- Place ids in the published experience ("Sky Farm Prototype"); 0 = not published yet
Places.Ids = table.freeze({
	Island = 70908743282881,
	Town = 0,
})

function Places.Current(): Kind
	return if Workspace:GetAttribute("PlaceKind") == "Town" then "Town" else "Island"
end

return table.freeze(Places)
