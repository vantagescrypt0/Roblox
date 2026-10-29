--!strict
-- The rewards for the skill challenges (Challenges.luau): each skill has a pet and an armor
-- set per tier, one tier for each resource it gathers (tier I from its first, II from the
-- next...), and every resource has a trophy.
--   Pet      follows you around and gives more XP in its skill (+5% a tier)
--   Armor    a set you wear: a better chance of a double drop in its skill (+3% a tier)
--   Trophy   a golden trophy block to show off on your island
-- You wear one pet and one armor set at a time (GearService). Items.luau makes them all
-- items and Blocks.luau the trophy blocks.

local Challenges = require(script.Parent.Challenges)

export type Pet = { Item: string, Name: string, Skill: string, Tier: number, XPBonus: number, Kind: string }
export type Armor = { Item: string, Name: string, Skill: string, Tier: number, DropBonus: number }
export type Trophy = { Item: string, Block: string, Name: string, Resource: string, Tier: number }

local PET_XP_PER_TIER = 0.05
local ARMOR_DROP_PER_TIER = 0.03
-- Which animal each skill's pets are
local PET_KINDS: { [string]: string } = { Farming = "Chicken", Woodcutting = "Beaver", Mining = "Mole" }

local pets: { [string]: Pet } = {}
local armors: { [string]: Armor } = {}
local trophies: { [string]: Trophy } = {}
local petList: { Pet } = {}
local armorList: { Armor } = {}
local trophyList: { Trophy } = {}
-- The item each challenge milestone gives, by milestone id
local rewards: { [string]: string } = {}

for _, resource in Challenges.List do
	local skill, tier = resource.Skill, resource.Tier
	for _, milestone in resource.Milestones do
		if milestone.Reward == "Pet" then
			local pet: Pet = {
				Item = `{skill}Pet{tier}`,
				Name = milestone.Name,
				Skill = skill,
				Tier = tier,
				XPBonus = PET_XP_PER_TIER * tier,
				Kind = PET_KINDS[skill] or "Chicken",
			}
			pets[pet.Item] = pet
			table.insert(petList, pet)
			rewards[milestone.Id] = pet.Item
		elseif milestone.Reward == "Armor" then
			local armor: Armor = {
				Item = `{skill}Armor{tier}`,
				Name = milestone.Name,
				Skill = skill,
				Tier = tier,
				DropBonus = ARMOR_DROP_PER_TIER * tier,
			}
			armors[armor.Item] = armor
			table.insert(armorList, armor)
			rewards[milestone.Id] = armor.Item
		else
			local trophy: Trophy = {
				Item = `{resource.Id}Trophy`,
				Block = `{resource.Id}Trophy`,
				Name = milestone.Name,
				Resource = resource.Id,
				Tier = tier,
			}
			trophies[trophy.Item] = trophy
			table.insert(trophyList, trophy)
			rewards[milestone.Id] = trophy.Item
		end
	end
end

return table.freeze({
	Pets = table.freeze(pets),
	Armors = table.freeze(armors),
	Trophies = table.freeze(trophies),
	PetList = table.freeze(petList),
	ArmorList = table.freeze(armorList),
	TrophyList = table.freeze(trophyList),
	-- milestone id -> the item it gives
	Rewards = table.freeze(rewards),
})
