--!strict
-- The rewards for the skill challenges (Challenges.luau): each skill has a pet and an armor
-- set per tier, one tier for each resource it gathers (tier I from its first, II from the
-- next...), and every resource has a trophy.
--   Pet      follows you around and gives more XP in its skill (+5% a tier)
--   Armor    four pieces (helmet, chestplate, leggings, boots; your call, 2026-11-02). Each is
--            worn on its own, and the whole set gives a better chance of a double drop in its
--            skill (+3% a tier)
--   Trophy   a golden trophy block to show off on your island
-- You wear one pet and one piece per armor slot at a time (GearService). Items.luau makes them
-- all items and Blocks.luau the trophy blocks.

local Challenges = require(script.Parent.Challenges)

export type Pet = { Item: string, Name: string, Skill: string, Tier: number, XPBonus: number, Kind: string }
export type Armor = { Item: string, Name: string, Skill: string, Tier: number, Slot: string, DropBonus: number }
export type Trophy = { Item: string, Block: string, Name: string, Resource: string, Tier: number }

local PET_XP_PER_TIER = 0.05
local ARMOR_DROP_PER_TIER = 0.03
local ARMOR_PIECES = {
	{ Slot = "Helmet", Word = "Helmet" },
	{ Slot = "Chest", Word = "Chestplate" },
	{ Slot = "Legs", Word = "Leggings" },
	{ Slot = "Boots", Word = "Boots" },
}
local ARMOR_SLOTS = { "Helmet", "Chest", "Legs", "Boots" }
-- Armor's colour by tier: bronze, silver, gold, emerald, diamond, then the deep cave's amethyst,
-- ruby and starlight, then Farming's far crops
local TIER_COLORS = {
	Color3.fromRGB(205, 127, 50),
	Color3.fromRGB(196, 200, 208),
	Color3.fromRGB(242, 193, 78),
	Color3.fromRGB(80, 200, 120),
	Color3.fromRGB(120, 222, 244),
	Color3.fromRGB(168, 96, 230),
	Color3.fromRGB(220, 40, 60),
	Color3.fromRGB(255, 236, 170),
	Color3.fromRGB(236, 70, 160),
	Color3.fromRGB(150, 240, 220),
}
-- Which animal each skill's pets are
local PET_KINDS: { [string]: string } = { Farming = "Chicken", Woodcutting = "Beaver", Mining = "Mole" }

local pets: { [string]: Pet } = {}
local armors: { [string]: Armor } = {}
local trophies: { [string]: Trophy } = {}
local petList: { Pet } = {}
local armorList: { Armor } = {}
local trophyList: { Trophy } = {}
-- The items each challenge milestone gives, by milestone id
local rewards: { [string]: { string } } = {}
-- Saves from before the pieces hold a whole set as one item: its id -> its four pieces
local oldSets: { [string]: { string } } = {}

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
			rewards[milestone.Id] = { pet.Item }
		elseif milestone.Reward == "Armor" then
			local set = {}
			for _, piece in ARMOR_PIECES do
				local armor: Armor = {
					Item = `{skill}{piece.Word}{tier}`,
					Name = (string.gsub(milestone.Name, "Armor", piece.Word)),
					Skill = skill,
					Tier = tier,
					Slot = piece.Slot,
					DropBonus = ARMOR_DROP_PER_TIER * tier / #ARMOR_PIECES,
				}
				armors[armor.Item] = armor
				table.insert(armorList, armor)
				table.insert(set, armor.Item)
			end
			rewards[milestone.Id] = set
			oldSets[`{skill}Armor{tier}`] = set
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
			rewards[milestone.Id] = { trophy.Item }
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
	-- milestone id -> the items it gives
	Rewards = table.freeze(rewards),
	OldArmorSets = table.freeze(oldSets),
	ArmorSlots = table.freeze(ARMOR_SLOTS),
	TierColors = table.freeze(TIER_COLORS),
})
