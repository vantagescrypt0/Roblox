--!strict
-- Skill challenges, from the Skybounds skill menus (02 Research/References/Skybounds/menus).
-- Every crop, log and ore a skill gathers keeps a count of how many you've gathered this
-- season, and milestones along it unlock rewards: a tier of the skill's pet and of its armor
-- set (tier I from its first resource, II from the next...) and, at the top, the resource's
-- trophy. Counts and unlocks reset each season along with the skills.
--
-- A resource's Level and XP come from where they're set: Crops.luau for crops, Gathering.luau
-- for logs and ore. The milestone counts are guesses for a ~25-hour skill (Leveling.luau):
-- crops are quick to harvest, logs and ore slower.

local Crops = require(script.Parent.Crops)
local Gathering = require(script.Parent.Gathering)

export type Reward = "Pet" | "Armor" | "Trophy"

export type Milestone = {
	Id: string, -- unique, e.g. "Wheat:Pet"
	Count: number,
	Reward: Reward,
	Name: string, -- "Farming Pet I", "Wheat Trophy"
}

export type Resource = {
	Id: string, -- what's counted: the crop ("Wheat") or block ("Wood", "CoalOre") gathered
	Name: string,
	Icon: string, -- item or block whose picture shows it
	Skill: string,
	Level: number, -- the skill level it needs
	XP: number, -- base skill XP for gathering one
	Note: string?, -- anything else it needs ("Stone Pickaxe")
	Tier: number,
	Milestones: { Milestone },
}

local ROMAN = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII" }

local List: { Resource } = {}
local bySkill: { [string]: { Resource } } = {}
local byId: { [string]: Resource } = {}

-- `steps` are the counts for the pet, the armor set and the trophy
local function add(skill: string, id: string, name: string, icon: string, steps: { number }, note: string?)
	local crop = Crops.ById[id]
	local gather = Gathering[id]
	local level = if crop then crop.FarmingLevel elseif gather then gather.Level or 1 else 1
	local xp = if crop then crop.FarmingXP elseif gather then gather.XP else 0
	local list = bySkill[skill] or {}
	bySkill[skill] = list
	local tier = #list + 1
	local resource: Resource = {
		Id = id,
		Name = name,
		Icon = icon,
		Skill = skill,
		Level = level,
		XP = xp,
		Note = note,
		Tier = tier,
		Milestones = {
			{ Id = `{id}:Pet`, Count = steps[1], Reward = "Pet", Name = `{skill} Pet {ROMAN[tier]}` },
			{ Id = `{id}:Armor`, Count = steps[2], Reward = "Armor", Name = `{skill} Armor {ROMAN[tier]}` },
			{ Id = `{id}:Trophy`, Count = steps[3], Reward = "Trophy", Name = `{name} Trophy` },
		},
	}
	table.insert(list, resource)
	table.insert(List, resource)
	byId[id] = resource
end

-- Farming: crops, in the order they unlock (Glowberry joins when the Warzone opens)
add("Farming", "Wheat", "Wheat", "Wheat", { 500, 2500, 25000 })
add("Farming", "Carrot", "Carrot", "Carrot", { 750, 3500, 35000 })
add("Farming", "Potato", "Potato", "Potato", { 1000, 5000, 50000 })
add("Farming", "Pumpkin", "Pumpkin", "Pumpkin", { 1250, 6500, 65000 }, "Axe to harvest")
add("Farming", "Melon", "Melon", "Melon", { 1500, 7500, 75000 }, "Axe to harvest")
-- Woodcutting: logs (leaves don't count)
add("Woodcutting", "Wood", "Oak", "Wood", { 250, 1250, 12500 })
add("Woodcutting", "BirchWood", "Birch", "BirchWood", { 375, 1750, 17500 })
add("Woodcutting", "SpruceWood", "Spruce", "SpruceWood", { 500, 2500, 25000 })
add("Woodcutting", "CherryWood", "Cherry", "CherryWood", { 625, 3000, 30000 })
-- Mining: ore
add("Mining", "CoalOre", "Coal", "CoalOre", { 250, 1250, 12500 }, "Any pickaxe")
add("Mining", "IronOre", "Iron", "IronOre", { 375, 1750, 17500 }, "Stone Pickaxe or better")
add("Mining", "GoldOre", "Gold", "GoldOre", { 500, 2500, 25000 }, "Iron Pickaxe or better")

local Challenges = {
	List = table.freeze(List),
	BySkill = table.freeze(bySkill),
	ById = table.freeze(byId),
}

-- The next milestone a count of `count` hasn't reached yet (nil = all reached)
function Challenges.Next(resource: Resource, count: number): Milestone?
	for _, milestone in resource.Milestones do
		if count < milestone.Count then
			return milestone
		end
	end
	return nil
end

return table.freeze(Challenges)
