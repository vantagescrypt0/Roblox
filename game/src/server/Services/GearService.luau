--!strict
-- Pets and armor sets (Gear.luau), the skill challenges' rewards. A player wears one pet and
-- one armor set at a time (data.Equipped), picked in the Bag (the Equip remote). The pet
-- floats beside its owner (PetModels; a pet you don't own any more is put away) and gives
-- more XP in its skill; the armor is drawn on the character (ArmorModels) and gives a better
-- chance of a double drop in its skill. Also builds the trophy blocks' look (TrophyModels)
-- when a server starts. Runs in every place.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gear = require(ReplicatedStorage.Shared.Gear)
local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ArmorModels = require(script.Parent.Parent.Util.ArmorModels)
local PetModels = require(script.Parent.Parent.Util.PetModels)
local TrophyModels = require(script.Parent.Parent.Util.TrophyModels)
local DataService = require(script.Parent.DataService)
local StateService = require(script.Parent.StateService)

-- Where the pet floats: to the right of and a little behind its owner
local PET_OFFSET = CFrame.new(3, 0.5, 2.5)

local GearService = {}

local shown: { [Player]: { Pet: string, Armor: string, Character: Model? } } = {}
local petModels: { [Player]: Model } = {}

-- Extra skill XP (0.05 = +5%) from the pet a player wears, for `skill`
function GearService.XPBonus(player: Player, skill: string): number
	local data = DataService.GetData(player)
	local pet = data and Gear.Pets[data.Equipped.Pet]
	return if pet and pet.Skill == skill then pet.XPBonus else 0
end

-- Extra chance of a double drop (0.03 = +3%) from the armor a player wears, for `skill`
function GearService.DropBonus(player: Player, skill: string): number
	local data = DataService.GetData(player)
	local armor = data and Gear.Armors[data.Equipped.Armor]
	return if armor and armor.Skill == skill then armor.DropBonus else 0
end

local function removePet(player: Player)
	local model = petModels[player]
	if model then
		model:Destroy()
		petModels[player] = nil
	end
end

-- Floats the pet beside the character: physics constraints pull it along, owned by the
-- player so it moves smoothly on their screen
local function spawnPet(player: Player, character: Model, itemId: string)
	local pet = Gear.Pets[itemId]
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not pet or not rootPart or not rootPart:IsA("BasePart") then
		return
	end
	local model = PetModels.Build(pet.Kind, pet.Tier, rootPart.CFrame * PET_OFFSET)
	local root = model.PrimaryPart :: BasePart
	local target = Instance.new("Attachment")
	target.Name = "PetTarget"
	target.CFrame = PET_OFFSET
	target.Parent = rootPart
	local own = Instance.new("Attachment")
	own.Parent = root
	local position = Instance.new("AlignPosition")
	position.Attachment0 = own
	position.Attachment1 = target
	position.MaxForce = 1e6
	position.Responsiveness = 18
	position.Parent = root
	local orientation = Instance.new("AlignOrientation")
	orientation.Attachment0 = own
	orientation.Attachment1 = target
	orientation.MaxTorque = 1e6
	orientation.Responsiveness = 14
	orientation.Parent = root
	model.Name = `{player.Name}'s {pet.Name}`
	model.Parent = character
	pcall(function()
		root:SetNetworkOwner(player)
	end)
	model.Destroying:Connect(function()
		target:Destroy()
	end)
	petModels[player] = model
end

-- Makes what the character shows match what the player wears
local function refresh(player: Player)
	local data = DataService.GetData(player)
	local character = player.Character
	if not data or not character then
		return
	end
	local last = shown[player]
	local pet, armor = data.Equipped.Pet, data.Equipped.Armor
	if last and last.Pet == pet and last.Armor == armor and last.Character == character then
		return
	end
	shown[player] = { Pet = pet, Armor = armor, Character = character }

	removePet(player)
	local oldArmor = character:FindFirstChild("Armor")
	if oldArmor then
		oldArmor:Destroy()
	end
	if pet ~= "" then
		spawnPet(player, character, pet)
	end
	local set = Gear.Armors[armor]
	if set then
		ArmorModels.Apply(character, set.Skill, set.Tier)
	end
end

-- Wears a pet or armor set, or takes it off if it's already worn
local function onEquip(player: Player, itemId: unknown)
	if type(itemId) ~= "string" then
		return
	end
	local data = DataService.GetData(player)
	local item = Items[itemId]
	if not data or not item or not item.Equip or (data.Items[itemId] or 0) <= 0 then
		return
	end
	local slot = if item.Equip == "Pet" then "Pet" else "Armor"
	local equipped = data.Equipped :: { [string]: string }
	if equipped[slot] == itemId then
		equipped[slot] = ""
		StateService.Notify(player, `Put away: {item.Name}`, "info")
	else
		equipped[slot] = itemId
		local pet, armor = Gear.Pets[itemId], Gear.Armors[itemId]
		local bonus = if pet
			then `+{math.round(pet.XPBonus * 100)}% {pet.Skill} XP`
			elseif armor then `+{math.round(armor.DropBonus * 100)}% double {armor.Skill} drops`
			else ""
		StateService.Notify(player, `Wearing {item.Name}: {bonus}`, "good")
	end
	DataService.MarkChanged(player)
	refresh(player)
end

-- A pet or armor set the player no longer has (traded away) comes off
local function checkOwned(player: Player, data: DataService.Data)
	local equipped = data.Equipped :: { [string]: string }
	local changed = false
	for slot, itemId in equipped do
		if itemId ~= "" and (data.Items[itemId] or 0) <= 0 then
			equipped[slot] = ""
			changed = true
		end
	end
	if changed then
		DataService.MarkChanged(player)
	end
	refresh(player)
end

function GearService.Start()
	TrophyModels.Make()
	Remotes.Equip.OnServerEvent:Connect(onEquip)
	DataService.OnChanged(checkOwned)
	DataService.OnDataLoaded(function(player, data)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart", 10)
			-- Let the avatar finish loading its body parts before the armor goes on
			task.wait(0.5)
			if player.Character == character then
				shown[player] = nil
				refresh(player)
			end
		end)
		if player.Character then
			checkOwned(player, data)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		removePet(player)
		shown[player] = nil
	end)
end

return GearService
