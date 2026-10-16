--!strict
-- Swords. You hold the sword in your selected hotbar slot. Hits are worked out on the
-- server: mobs anywhere, other players only when both of you are in the Warzone.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Weapons = require(ReplicatedStorage.Shared.Weapons)
local MobService = require(script.Parent.MobService)
local WarzoneService = require(script.Parent.WarzoneService)

local CombatService = {}

local lastSwing: { [Player]: number } = {}

local function targetsInFront(character: Model, root: BasePart, range: number): { Model }
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local box = root.CFrame * CFrame.new(0, 0, -range / 2)
	local found: { Model } = {}
	local seen: { [Model]: boolean } = {}
	for _, hit in workspace:GetPartBoundsInBox(box, Vector3.new(5, 6, range), params) do
		local model = hit:FindFirstAncestorOfClass("Model")
		if model and not seen[model] and model:FindFirstChildOfClass("Humanoid") then
			seen[model] = true
			table.insert(found, model)
		end
	end
	return found
end

local function swing(player: Player, weapon: Weapons.Weapon)
	local now = os.clock()
	if now - (lastSwing[player] or 0) < weapon.Cooldown then
		return
	end
	lastSwing[player] = now

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return
	end

	for _, model in targetsInFront(character, root, weapon.Range) do
		if model:GetAttribute("Mob") then
			MobService.Damage(model, player, weapon.Damage)
		else
			local victim = Players:GetPlayerFromCharacter(model)
			local victimHumanoid = model:FindFirstChildOfClass("Humanoid")
			if victim and victimHumanoid and WarzoneService.IsInRaid(player) and WarzoneService.IsInRaid(victim) then
				victimHumanoid:SetAttribute("LastAttacker", player.UserId)
				victimHumanoid:TakeDamage(weapon.Damage)
			end
		end
	end
end

local function makeTool(player: Player, weapon: Weapons.Weapon): Tool
	local tool = Instance.new("Tool")
	tool.Name = Items[weapon.Item].Name
	tool.CanBeDropped = false
	tool:SetAttribute("Weapon", weapon.Item)
	-- Same grip as Roblox's classic sword
	tool.GripPos = Vector3.new(0, 0, -1.5)
	tool.GripForward = Vector3.new(-1, 0, 0)
	tool.GripRight = Vector3.new(0, 1, 0)
	tool.GripUp = Vector3.new(0, 0, 1)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.5, 0.3, 4)
	handle.Color = weapon.Color
	handle.Material = weapon.Material
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	tool.Activated:Connect(function()
		-- The default animation script plays a slash when it sees this value
		local anim = Instance.new("StringValue")
		anim.Name = "toolanim"
		anim.Value = "Slash"
		anim.Parent = tool
		swing(player, weapon)
	end)
	return tool
end

local function currentTool(player: Player): Tool?
	local containers: { Instance? } = { player.Character, player:FindFirstChildOfClass("Backpack") }
	for _, container in containers do
		if container then
			for _, child in container:GetChildren() do
				if child:IsA("Tool") and child:GetAttribute("Weapon") then
					return child
				end
			end
		end
	end
	return nil
end

-- Holds the given sword (from the selected hotbar slot), or nothing
function CombatService.Equip(player: Player, itemId: string?)
	local character = player.Character
	if not character then
		return
	end
	local tool = currentTool(player)
	if tool and itemId and tool:GetAttribute("Weapon") == itemId and tool.Parent == character then
		return
	end
	if tool then
		tool:Destroy()
	end
	local weapon = itemId and Weapons.ByItem[itemId]
	if weapon then
		makeTool(player, weapon).Parent = character
	end
end

function CombatService.Start()
	Players.PlayerRemoving:Connect(function(player)
		lastSwing[player] = nil
	end)
end

return CombatService
