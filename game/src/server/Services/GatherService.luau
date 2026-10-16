--!strict
-- Trees and rocks on your island that you can harvest for Wood and Stone.
-- A harvested node fades out and comes back after a short wait.

local Prompts = require(script.Parent.Parent.Util.Prompts)
local InventoryService = require(script.Parent.InventoryService)
local IslandService = require(script.Parent.IslandService)
local ProgressionService = require(script.Parent.ProgressionService)
local QuestService = require(script.Parent.QuestService)
local StateService = require(script.Parent.StateService)

type NodeKind = {
	Action: string,
	Object: string,
	Item: string,
	Min: number,
	Max: number,
	PlayerXP: number,
	Respawn: number,
	Hold: number,
}

local KINDS: { [string]: NodeKind } = {
	Tree = {
		Action = "Chop",
		Object = "Tree",
		Item = "Wood",
		Min = 2,
		Max = 3,
		PlayerXP = 4,
		Respawn = 25,
		Hold = 0.8,
	},
	Rock = {
		Action = "Mine",
		Object = "Rock",
		Item = "Stone",
		Min = 1,
		Max = 2,
		PlayerXP = 4,
		Respawn = 20,
		Hold = 1,
	},
}

local GatherService = {}

local rng = Random.new()

local function setFaded(parts: { BasePart }, faded: boolean)
	for _, part in parts do
		if part:GetAttribute("Collides") == nil then
			part:SetAttribute("Collides", part.CanCollide)
		end
		part.Transparency = if faded then 0.75 else 0
		part.CanCollide = not faded and part:GetAttribute("Collides") == true
	end
end

local function setupNode(player: Player, kind: NodeKind, promptPart: BasePart, parts: { BasePart })
	local prompt = Prompts.Create(promptPart, { Action = kind.Action, Object = kind.Object, Hold = kind.Hold })
	Prompts.OnTriggeredBy(prompt, player, function()
		if not prompt.Enabled then
			return
		end
		prompt.Enabled = false
		setFaded(parts, true)

		local amount = rng:NextInteger(kind.Min, kind.Max)
		InventoryService.Add(player, kind.Item, amount)
		ProgressionService.AddPlayerXP(player, kind.PlayerXP)
		StateService.Notify(player, `+{amount} {kind.Item}`, "good")
		QuestService.Record(player, kind.Action)

		task.delay(kind.Respawn, function()
			if promptPart.Parent then
				setFaded(parts, false)
				prompt.Enabled = true
			end
		end)
	end)
end

local function onIslandCreated(player: Player, island: IslandService.Island)
	local model = island.Model

	-- Trees come as TreeTrunk_N + TreeLeaves_N; rocks as Rock_N
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end
		local treeId = string.match(part.Name, "^TreeTrunk_(%d+)$")
		if treeId then
			local parts = { part }
			local leaves = model:FindFirstChild(`TreeLeaves_{treeId}`, true)
			if leaves and leaves:IsA("BasePart") then
				table.insert(parts, leaves)
			end
			setupNode(player, KINDS.Tree, part, parts)
		elseif string.match(part.Name, "^Rock") then
			setupNode(player, KINDS.Rock, part, { part })
		end
	end
end

function GatherService.Start()
	IslandService.OnIslandCreated(onIslandCreated)
end

return GatherService
