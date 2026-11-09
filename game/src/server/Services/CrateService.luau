--!strict
-- Opening Loot Crates (LootCrates.luau). A crate is used up and its 6 things go straight into
-- your Bag; your screen is told what they were and shows it (client/CrateOpening). Works in every place.

local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CrateArt = require(ReplicatedStorage.Shared.CrateArt)
local LootCrates = require(ReplicatedStorage.Shared.LootCrates)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local AwardService = require(script.Parent.AwardService)
local InventoryService = require(script.Parent.InventoryService)

local COOLDOWN = 0.5

local CrateService = {}

local lastOpen: { [Player]: number } = {}
local rng = Random.new()

local function onOpen(player: Player)
	local now = os.clock()
	if now - (lastOpen[player] or 0) < COOLDOWN then
		return
	end
	lastOpen[player] = now
	if not InventoryService.Remove(player, LootCrates.Item, 1) then
		return
	end
	local results = {}
	for _ = 1, LootCrates.Slots do
		local prize = LootCrates.Roll(rng:NextNumber(), rng:NextNumber())
		local result = { Item = prize.Item, Count = rng:NextInteger(prize.Min, prize.Max), Good = prize.Good }
		InventoryService.Add(player, result.Item, result.Count) -- what doesn't fit arrives by letter
		table.insert(results, result)
	end
	Remotes.CrateOpened:FireClient(player, results)
	AwardService.Give(player, "FirstCrate")
end

-- The opening scene's meshes, loaded up front and kept where every screen can copy them
local function loadModels()
	local folder = Instance.new("Folder")
	folder.Name = "CrateModels"
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
			part.Parent = folder
		end)
	end
	folder.Parent = ReplicatedStorage
end

function CrateService.Start()
	loadModels()
	Remotes.OpenCrate.OnServerEvent:Connect(onOpen)
	Players.PlayerRemoving:Connect(function(player)
		lastOpen[player] = nil
	end)
end

return CrateService
