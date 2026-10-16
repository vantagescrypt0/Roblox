--!strict
-- Whatever is in your selected hotbar slot shows in your hand: pixel-art tool and crop
-- models (ReplicatedStorage.ItemModels) or a small block. Swinging a tool hits what's in
-- front of you using that tool's Damage, Range and Cooldown (Tools.luau) and wears it
-- down. Hits are worked out on the server: mobs anywhere, other players only when both
-- of you are in the Warzone.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Items)
local Tools = require(ReplicatedStorage.Shared.Tools)
local InventoryService = require(script.Parent.InventoryService)
local MobService = require(script.Parent.MobService)
local StateService = require(script.Parent.StateService)
local WarzoneService = require(script.Parent.WarzoneService)

-- Where the hand holds a pixel-art item model (model space: handle at bottom-right,
-- head at top-left, flat in the XY plane), and the direction from handle to head.
local HOLD_POINT = Vector3.new(1.0, -1.0, 0)
local HANDLE_TO_HEAD = Vector3.new(-1, 1, 0).Unit
local BLOCK_IN_HAND = 1.1 -- studs

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

local function swing(player: Player, tool: Tools.Tool)
	local now = os.clock()
	if now - (lastSwing[player] or 0) < tool.Cooldown then
		return
	end
	lastSwing[player] = now

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
		return
	end

	local landed = false
	for _, model in targetsInFront(character, root, tool.Range) do
		if model:GetAttribute("Mob") then
			MobService.Damage(model, player, tool.Damage)
			landed = true
		else
			local victim = Players:GetPlayerFromCharacter(model)
			local victimHumanoid = model:FindFirstChildOfClass("Humanoid")
			if victim and victimHumanoid and WarzoneService.IsInRaid(player) and WarzoneService.IsInRaid(victim) then
				victimHumanoid:SetAttribute("LastAttacker", player.UserId)
				victimHumanoid:TakeDamage(tool.Damage)
				landed = true
			end
		end
	end
	-- Hitting something wears the tool: swords 1 use, other tools 2 (like Minecraft)
	if landed and InventoryService.UseTool(player, tool.Item, if tool.Kind == "Sword" then 1 else 2) then
		StateService.Notify(player, `Your {Items[tool.Item].Name} broke!`, "bad")
	end
end

-- Builds the Handle for an item: its pixel-art model, a small block, or a plain stick
local function makeHandle(itemId: string): (BasePart, CFrame)
	local item = Items[itemId]
	local models = ReplicatedStorage:FindFirstChild("ItemModels")
	local model = item and item.Model and models and models:FindFirstChild(item.Model)
	if model and model:IsA("BasePart") then
		local handle = model:Clone()
		-- Express the hold point and direction in the mesh's own space
		local rotation = model.CFrame.Rotation
		local up = rotation:VectorToObjectSpace(HANDLE_TO_HEAD)
		local back = rotation:VectorToObjectSpace(Vector3.zAxis)
		local right = up:Cross(back).Unit
		return handle, CFrame.fromMatrix(rotation:PointToObjectSpace(HOLD_POINT), right, up, back)
	end

	local blocks = ReplicatedStorage:FindFirstChild("Blocks")
	local block = item and item.Block and blocks and blocks:FindFirstChild(item.Block)
	if block and block:IsA("BasePart") then
		local handle = block:Clone()
		handle.Size = Vector3.one * BLOCK_IN_HAND
		return handle, CFrame.new(0, 0, 0.2)
	end

	local stick = Instance.new("Part")
	stick.Size = Vector3.new(0.3, 0.3, 2)
	stick.Color = Color3.fromRGB(104, 78, 46)
	return stick, CFrame.new(0, 0, -0.6)
end

local function makeTool(player: Player, itemId: string): Tool
	local tool = Instance.new("Tool")
	tool.Name = Items[itemId].Name
	tool.CanBeDropped = false
	tool:SetAttribute("Held", itemId)

	local handle, grip = makeHandle(itemId)
	handle.Name = "Handle"
	handle.Anchored = false
	handle.CanCollide = false
	handle.CanQuery = false
	handle.Massless = true
	handle.Parent = tool
	tool.Grip = grip

	local stats = Tools.ByItem[itemId]
	tool.Activated:Connect(function()
		-- The default animation script plays a slash when it sees this value
		local anim = Instance.new("StringValue")
		anim.Name = "toolanim"
		anim.Value = "Slash"
		anim.Parent = tool
		if stats then
			swing(player, stats)
		end
	end)
	return tool
end

local function currentTool(player: Player): Tool?
	local containers: { Instance? } = { player.Character, player:FindFirstChildOfClass("Backpack") }
	for _, container in containers do
		if container then
			for _, child in container:GetChildren() do
				if child:IsA("Tool") and child:GetAttribute("Held") then
					return child
				end
			end
		end
	end
	return nil
end

-- Shows the given item in the player's hand (from the selected hotbar slot), or nothing
function CombatService.Equip(player: Player, itemId: string?)
	local character = player.Character
	if not character then
		return
	end
	local tool = currentTool(player)
	if tool and itemId and tool:GetAttribute("Held") == itemId and tool.Parent == character then
		return
	end
	if tool then
		tool:Destroy()
	end
	if itemId and Items[itemId] then
		makeTool(player, itemId).Parent = character
	end
end

function CombatService.Start()
	Players.PlayerRemoving:Connect(function(player)
		lastSwing[player] = nil
	end)
end

return CombatService
