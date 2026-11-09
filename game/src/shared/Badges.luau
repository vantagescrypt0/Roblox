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
	Welcome = { Id = 0, Name = "Welcome to Skycore", Description = "Set foot on your island for the first time." },
	WarzoneUnlocked = { Id = 0, Name = "Warzone Ready", Description = "Reached level 10 and unlocked the Warzone." },
	WarzoneEntered = { Id = 0, Name = "Into the Pit", Description = "Jumped into the void and entered the Warzone." },
	Visitor = { Id = 0, Name = "Good Neighbour", Description = "Visited another player's island." },
	GuestbookSigned = { Id = 0, Name = "Left a Note", Description = "Signed someone's guestbook." },
	FirstKill = { Id = 0, Name = "Monster Slayer", Description = "Slew your first monster." },
	FirstCrate = { Id = 0, Name = "Crate Cracker", Description = "Opened your first Loot Crate." },
	Legendary = { Id = 0, Name = "Legendary Haul", Description = "Broke open a Legendary Skydrop." },
}

return table.freeze(Badges)
