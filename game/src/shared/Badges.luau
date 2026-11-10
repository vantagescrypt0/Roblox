--!strict
-- Roblox badges for the moments worth remembering (the list is Claude's pick). Id is the badge on
-- Roblox: 0 means it hasn't been made there yet, and AwardService skips it, so making one is just
-- filling in its number here.

export type Badge = { Id: number, Name: string, Description: string }
export type Key =
	"Welcome"
	| "WarzoneUnlocked"
	| "WarzoneEntered"
	| "Visitor"
	| "GuestbookSigned"
	| "FirstKill"
	| "FirstCrate"
	| "Legendary"

local Badges: { [Key]: Badge } = {
	-- Pictures: art/scripts/badge_icons.ps1. Roblox allows five new badges a day for free, so the last three wait a day.
	Welcome = {
		Id = 2753379181900505,
		Name = "Welcome to Skycore",
		Description = "Set foot on your island for the first time.",
	},
	WarzoneUnlocked = {
		Id = 3458230270559094,
		Name = "Warzone Ready",
		Description = "Reached level 10 and unlocked the Warzone.",
	},
	WarzoneEntered = {
		Id = 3630634130358574,
		Name = "Into the Pit",
		Description = "Jumped into the void and entered the Warzone.",
	},
	Visitor = { Id = 0, Name = "Good Neighbour", Description = "Visited another player's island." },
	GuestbookSigned = { Id = 0, Name = "Left a Note", Description = "Signed someone's guestbook." },
	FirstKill = { Id = 1645320913913704, Name = "Monster Slayer", Description = "Slew your first monster." },
	-- Roblox's text filter turned down "Crate Cracker"
	FirstCrate = { Id = 3757061369283009, Name = "Crate Opener", Description = "Opened your first Loot Crate." },
	Legendary = { Id = 0, Name = "Legendary Haul", Description = "Broke open a Legendary Skydrop." },
}

return table.freeze(Badges)
