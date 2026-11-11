--!strict
-- Opening Loot Crates (LootCrates.luau). Hold one and right-click (or tap) anywhere: the crate lands there, in any
-- place, and your screen shows its 6 slots to spin (client/CrateOpening). The crate is used up and its 6 things go
-- straight into your Bag the moment it lands, so closing the window early (or leaving) never loses anything. When
-- you're done the crate goes, with confetti everyone nearby sees. Your design (2026-11-10).

local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local CrateArt = require(ReplicatedStorage.Shared.CrateArt)
local LootCrates = require(ReplicatedStorage.Shared.LootCrates)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local AwardService = require(script.Parent.AwardService)
local InventoryService = require(script.Parent.InventoryService)
local StateService = require(script.Parent.StateService)

local COOLDOWN = 0.6
local REACH = Blocks.Reach + 6 -- a little slack for lag
local SCALE = 1.5 -- the crate's meshes are made for the opening scene; a bit bigger stands out in the world
local LID_RISE = 1.3 -- the lid sits this far above the body's floor, before SCALE
local DROP = 5 -- it falls this far as it lands
local LIFETIME = 300 -- seconds before a crate nobody finished goes by itself

type Open = { Id: string, Model: Model, Body: BasePart, Lid: BasePart, At: Vector3, Good: boolean }

local CrateService = {}

local lastPlace: { [Player]: number } = {}
local open: { [Player]: Open } = {}
local rng = Random.new()
local folder: Folder
local nextId = 0

-- The opening meshes, loaded up front and kept where every screen can copy them
local function loadModels()
	local models = Instance.new("Folder")
	models.Name = "CrateModels"
	for name, art in CrateArt.Parts do
		task.spawn(function()
			local ok, part = pcall(function()
				return AssetService:CreateMeshPartAsync(art.Mesh)
			end)
			if not ok then
				warn(`[CrateService] {name} didn't load: {part}`)
				return
			end
			part.Name = name
			part.Size = art.Size
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			if art.Textured then
				part.TextureID = CrateArt.Texture
			end
			part.Parent = models
		end)
	end
	models.Parent = ReplicatedStorage
end

local function copyOf(name: string): BasePart?
	local models = ReplicatedStorage:FindFirstChild("CrateModels")
	local part = models and models:FindFirstChild(name)
	if not part or not part:IsA("BasePart") then
		return nil
	end
	local copy = part:Clone()
	copy.Size = part.Size * SCALE
	return copy
end

-- Where each mesh sits for a crate standing at `floor`
local function bodyAt(floor: CFrame): CFrame
	return floor * CFrame.new(CrateArt.Parts.Body.Offset * SCALE)
end

local function lidAt(floor: CFrame): CFrame
	return floor * CFrame.new(0, LID_RISE * SCALE, 0) * CFrame.new(CrateArt.Parts.Lid.Offset * SCALE)
end

-- Takes the crate away: the lid pops up, then it's gone and everyone near sees confetti
local function finish(player: Player)
	local crate = open[player]
	if not crate then
		return
	end
	open[player] = nil
	local up = crate.Lid.CFrame * CFrame.new(0, 2.2, 0) * CFrame.Angles(math.rad(-50), 0, math.rad(12))
	TweenService
		:Create(crate.Lid, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = up })
		:Play()
	task.delay(0.24, function()
		Remotes.CratePopped:FireAllClients(crate.At + Vector3.new(0, 1.2 * SCALE, 0), crate.Good)
		crate.Model:Destroy()
	end)
end

local function validPosition(player: Player, at: any): Vector3?
	if typeof(at) ~= "Vector3" then
		return nil
	end
	local position = at :: Vector3
	if position.X ~= position.X or position.Y ~= position.Y or position.Z ~= position.Z then
		return nil
	end
	if math.abs(position.X) > 1e6 or math.abs(position.Y) > 1e6 or math.abs(position.Z) > 1e6 then
		return nil
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") or (root.Position - position).Magnitude > REACH then
		return nil
	end
	return position
end

local function onPlace(player: Player, at: any)
	local now = os.clock()
	if now - (lastPlace[player] or 0) < COOLDOWN then
		return
	end
	lastPlace[player] = now
	local position = validPosition(player, at)
	if not position then
		return
	end
	local body, lid = copyOf("Body"), copyOf("Lid")
	if not body or not lid then
		StateService.Notify(player, "The crate is still loading. Try again in a moment", "bad")
		return
	end
	if not InventoryService.Remove(player, LootCrates.Item, 1) then
		body:Destroy()
		lid:Destroy()
		return
	end
	-- One crate down at a time: an old one you walked away from goes first
	finish(player)

	local results = {}
	local good = false
	for _ = 1, LootCrates.Slots do
		local prize = LootCrates.Roll(rng:NextNumber(), rng:NextNumber())
		local result = { Item = prize.Item, Count = rng:NextInteger(prize.Min, prize.Max), Good = prize.Good }
		InventoryService.Add(player, result.Item, result.Count) -- what doesn't fit arrives by letter
		table.insert(results, result)
		good = good or prize.Good
	end
	AwardService.Give(player, "FirstCrate")

	-- It faces you, and drops in with a bounce
	nextId += 1
	local id = `{player.UserId}-{nextId}`
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local toward = if root then (root.Position - position) * Vector3.new(1, 0, 1) else Vector3.zAxis
	local facing = if toward.Magnitude > 0.01 then toward.Unit else Vector3.zAxis
	local floor = CFrame.lookAt(position, position - facing)
	local model = Instance.new("Model")
	model.Name = `Crate_{player.UserId}`
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model:SetAttribute("Owner", player.UserId)
	body.Parent = model
	lid.Parent = model
	model.PrimaryPart = body
	local lift = CFrame.new(0, DROP, 0)
	body.CFrame = lift * bodyAt(floor)
	lid.CFrame = lift * lidAt(floor)
	model.Parent = folder
	local fall = TweenInfo.new(0.45, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
	TweenService:Create(body, fall, { CFrame = bodyAt(floor) }):Play()
	TweenService:Create(lid, fall, { CFrame = lidAt(floor) }):Play()

	open[player] = { Id = id, Model = model, Body = body, Lid = lid, At = position, Good = good }
	Remotes.CrateOpened:FireClient(player, id, results)
	task.delay(LIFETIME, function()
		local crate = open[player]
		if crate and crate.Id == id then
			finish(player)
		end
	end)
end

-- Your window closed: the crate goes. Closed before every slot was spun, you're told what you got.
local function onDone(player: Player, id: any, skipped: any)
	local crate = open[player]
	if not crate or crate.Id ~= id then
		return
	end
	finish(player)
	if skipped == true then
		StateService.Notify(player, "Your crate's 6 things are in your Bag", "level")
	end
end

function CrateService.Start()
	loadModels()
	folder = Instance.new("Folder")
	folder.Name = "Crates"
	folder.Parent = Workspace
	Remotes.PlaceCrate.OnServerEvent:Connect(onPlace)
	Remotes.CrateDone.OnServerEvent:Connect(onDone)
	Players.PlayerRemoving:Connect(function(player)
		finish(player)
		lastPlace[player] = nil
	end)
end

return CrateService
