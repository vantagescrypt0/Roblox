--!strict
-- Pets and armor pieces (Gear.luau), the skill challenges' rewards, and the shield. A player
-- wears one pet, one armor piece per slot and one shield at a time (data.Equipped), picked in
-- the Bag (the Equip remote). The shield goes on the left arm (ShieldModel; WarzoneService
-- does the blocking). The pet floats beside its owner (PetModels; a pet you don't own any more is put away) and gives
-- more XP in its skill; each armor piece is drawn on the character (ArmorModels) and gives a
-- better chance of a double drop in its skill. Also builds the trophy blocks' look (TrophyModels)
-- when a server starts. Runs in every place.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gear = require(ReplicatedStorage.Shared.Gear)
local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ArmorModels = require(script.Parent.Parent.Util.ArmorModels)
local MonsterModels = require(script.Parent.Parent.Util.MonsterModels)
local PetModels = require(script.Parent.Parent.Util.PetModels)
local SpawnerModels = require(script.Parent.Parent.Util.SpawnerModels)
local ShieldModel = require(script.Parent.Parent.Util.ShieldModel)
local TrophyModels = require(script.Parent.Parent.Util.TrophyModels)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)

-- Where the pet floats: to the right of and a little behind its owner
local PET_OFFSET = CFrame.new(3, 0.5, 2.5)

local GearService = {}

local shown: { [Player]: { Pet: string, Armor: string, Shield: string, Character: Model? } } = {}
local petModels: { [Player]: Model } = {}

-- Extra skill XP (0.05 = +5%) from the pet a player wears, for `skill`
function GearService.XPBonus(player: Player, skill: string): number
	local data = DataService.GetData(player)
	local pet = data and Gear.Pets[data.Equipped.Pet]
	return if pet and pet.Skill == skill then pet.XPBonus else 0
end

-- Extra chance of a double drop (0.03 = +3%) from the armor a player wears, for `skill`: each
-- piece of that skill counts
function GearService.DropBonus(player: Player, skill: string): number
	local data = DataService.GetData(player)
	if not data then
		return 0
	end
	local equipped = data.Equipped :: { [string]: string }
	local bonus = 0
	for _, slot in Gear.ArmorSlots do
		local armor = Gear.Armors[equipped[slot]]
		if armor and armor.Skill == skill then
			bonus += armor.DropBonus
		end
	end
	return bonus
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
	local equipped = data.Equipped :: { [string]: string }
	local last = shown[player]
	local worn = {}
	for _, slot in Gear.ArmorSlots do
		table.insert(worn, equipped[slot] or "")
	end
	local armorKey = table.concat(worn, "|")
	local pet, shield = equipped.Pet, equipped.Shield
	local sameBody = last ~= nil and last.Character == character
	shown[player] = { Pet = pet, Armor = armorKey, Shield = shield, Character = character }

	if not sameBody or last.Pet ~= pet then
		removePet(player)
		if pet ~= "" then
			spawnPet(player, character, pet)
		end
	end
	if not sameBody or last.Armor ~= armorKey then
		local oldArmor = character:FindFirstChild("Armor")
		if oldArmor then
			oldArmor:Destroy()
		end
		local pieces = {}
		for _, itemId in worn do
			local armor = Gear.Armors[itemId]
			if armor then
				table.insert(pieces, { Slot = armor.Slot, Skill = armor.Skill, Tier = armor.Tier })
			end
		end
		ArmorModels.Apply(character, pieces)
	end
	if not sameBody or last.Shield ~= shield then
		local oldShield = character:FindFirstChild("Shield")
		if oldShield then
			oldShield:Destroy()
		end
		if shield ~= "" then
			ShieldModel.Apply(character)
		end
	end
end

-- Wears something in its slot, or takes it off if it's already worn. The Bag shows the result.
local function onEquip(player: Player, itemId: unknown)
	if type(itemId) ~= "string" then
		return
	end
	local data = DataService.GetData(player)
	local item = Items[itemId]
	if not data or not item or not item.Equip or (data.Items[itemId] or 0) <= 0 then
		return
	end
	local equipped = data.Equipped :: { [string]: string }
	local slot = item.Equip
	local worn = equipped[slot] or ""
	if worn == itemId then
		if not InventoryService.PutBackFromWearing(player, itemId) then
			InventoryService.NotifyFull(player)
			return
		end
		equipped[slot] = ""
	else
		if not InventoryService.TakeOutToWear(player, itemId) then
			return
		end
		-- What was on goes back where the new piece just came from
		if worn ~= "" then
			InventoryService.PutBackFromWearing(player, worn)
		end
		equipped[slot] = itemId
	end
	DataService.MarkChanged(player)
	refresh(player)
end

-- Saves from before armor came in pieces: each whole set becomes its four pieces, and what was
-- being worn stays worn
local function splitOldArmor(_player: Player, data: DataService.Data)
	if data.Flags.ArmorPieces then
		return
	end
	data.Flags.ArmorPieces = true
	local equipped = data.Equipped :: { [string]: any }
	for oldId, pieces in Gear.OldArmorSets do
		local count = data.Items[oldId]
		if count and count > 0 then
			for _, piece in pieces do
				data.Items[piece] = (data.Items[piece] or 0) + count
			end
			if equipped.Armor == oldId then
				for _, piece in pieces do
					equipped[Gear.Armors[piece].Slot] = piece
				end
			end
		end
		data.Items[oldId] = nil
	end
	equipped.Armor = nil
end

-- A pet or armor piece the player no longer has (traded away) comes off
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
	MonsterModels.Make()
	SpawnerModels.Make()
	Remotes.Equip.OnServerEvent:Connect(onEquip)
	DataService.OnLoading(splitOldArmor)
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
