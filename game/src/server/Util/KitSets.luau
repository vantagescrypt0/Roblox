--!strict
-- Which armour kit someone is wearing all four pieces of (KitPowers.luau), if any.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gear = require(ReplicatedStorage.Shared.Gear)
local DataService = require(script.Parent.Parent.Services.DataService)

local KitSets = {}

function KitSets.Wearing(player: Player): string?
	local data = DataService.GetData(player)
	if not data then
		return nil
	end
	local worn = data.Equipped :: any
	local set: string? = nil
	for _, slot in Gear.ArmorSlots do
		local armor = Gear.Armors[worn[slot]]
		if not armor or armor.Class ~= "Kit" or (set and armor.Skill ~= set) then
			return nil
		end
		set = armor.Skill
	end
	return set
end

return KitSets
