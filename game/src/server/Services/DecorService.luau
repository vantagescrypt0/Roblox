--!strict
-- Decorations on a player's island (Decorations.luau). They place, break and save as blocks
-- (BlockService), so this only adds what blocks don't do: which way they face, fences that join up
-- with what's next to them, signs with words on, and coming off when what holds them up is broken.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local Blocks = require(ReplicatedStorage.Shared.Blocks)
local Decorations = require(ReplicatedStorage.Shared.Decorations)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local BlockWorld = require(script.Parent.Parent.Util.BlockWorld)
local DecorModels = require(script.Parent.Parent.Util.DecorModels)
local Signs = require(script.Parent.Parent.Util.Signs)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local IslandService = require(script.Parent.IslandService)
local StateService = require(script.Parent.StateService)

local SIZE = Blocks.Size
local MAX_SIGN = 48
local SIGN_COOLDOWN = 0.5
local INK = Color3.fromRGB(46, 28, 16)
-- The tallest decoration, in cells: how far down to look for one reaching up into a cell
local MAX_TALL = 6
local SIDES = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
-- Where the words go on each kind of sign, around the model's origin
local SIGN_FACES: { [string]: { At: CFrame, Size: Vector3 } } = {
	SignPost = { At = CFrame.new(0, 4.2, -0.2), Size = Vector3.new(4.1, 2.4, 0.05) },
	WallSign = { At = CFrame.new(0, 0, -0.36), Size = Vector3.new(2.7, 1.8, 0.05) },
}

local DecorService = {}

local owners: { [BlockWorld.World]: Player } = {}
-- What each sign shows: its words after Roblox's filter (only this ever goes on a sign)
local shown: { [BlockWorld.World]: { [string]: string } } = {}
local lastEdit: { [Player]: number } = {}

local function decorAt(world: BlockWorld.World, x: number, y: number, z: number): Decorations.Decoration?
	local blockType = BlockWorld.get(world, x, y, z)
	return if blockType then Decorations.ByBlock[blockType] else nil
end

-- A block something can stand on or hang from
local function holds(world: BlockWorld.World, x: number, y: number, z: number): boolean
	local blockType = BlockWorld.get(world, x, y, z)
	local def = blockType and Blocks.Types[blockType]
	return def ~= nil and not def.Decor and not def.Liquid
end

-- Still water, not a flow (a flow's height keeps changing)
local function isWater(world: BlockWorld.World, x: number, y: number, z: number): boolean
	return BlockWorld.get(world, x, y, z) == "Water"
end

-- The quarter turn that points a model's front (-Z) along this direction
local function turnToward(dx: number, dz: number): number
	return math.round(math.atan2(-dx, -dz) / (math.pi / 2)) % 4
end

-- Fences -------------------------------------------------------------------------------

-- Fences join other fences, and solid blocks like Minecraft's do
local function fenceJoins(world: BlockWorld.World, x: number, y: number, z: number): boolean
	local blockType = BlockWorld.get(world, x, y, z)
	if blockType == "Fence" then
		return true
	end
	local def = blockType and Blocks.Types[blockType]
	return def ~= nil and not def.Decor and not def.Liquid and not def.SeeThrough
end

local function drawRails(world: BlockWorld.World, x: number, y: number, z: number)
	local post = BlockWorld.part(world, x, y, z)
	if not post or post.Name ~= "Fence" then
		return
	end
	for _, child in post:GetChildren() do
		if child.Name == "FenceRail" then
			child:Destroy()
		end
	end
	local floor = BlockWorld.position(world, x, y, z) - Vector3.new(0, SIZE / 2, 0)
	for _, side in SIDES do
		if fenceJoins(world, x + side[1], y, z + side[2]) then
			local toward = Vector3.new(side[1], 0, side[2])
			DecorModels.Place(post, "FenceRail", CFrame.lookAt(floor, floor + toward), { Collide = true })
		end
	end
end

-- Signs --------------------------------------------------------------------------------

local function drawWords(world: BlockWorld.World, x: number, y: number, z: number)
	local key = BlockWorld.key(x, y, z)
	local part = BlockWorld.part(world, x, y, z)
	local face = part and SIGN_FACES[part.Name]
	if not part or not face then
		return
	end
	local old = part:FindFirstChild("SignFace")
	if old then
		old:Destroy()
	end
	local words = shown[world] and shown[world][key]
	local decor = Decorations.ByBlock[part.Name]
	if not words or words == "" or not decor then
		return
	end
	local turns = world.Turns[key] or 0
	local frame = CFrame.new(BlockWorld.position(world, x, y, z))
		* CFrame.Angles(0, turns * math.pi / 2, 0)
		* CFrame.new(decor.Anchor)
		* face.At
	local holder = Instance.new("Part")
	holder.Name = "SignFace"
	holder.Size = face.Size
	holder.CFrame = frame
	holder.Transparency = 1
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.CastShadow = false
	holder.Parent = part
	Signs.Label(holder, words, frame.LookVector, INK)
end

-- Runs words through Roblox's filter. Yields. Words that can't be checked don't show.
local function filtered(text: string, userId: number): string
	if RunService:IsStudio() then
		return text
	end
	local ok, result = pcall(function()
		return TextService:FilterStringAsync(text, userId):GetNonChatStringForBroadcastAsync()
	end)
	return if ok then result else ""
end

local function setWords(player: Player, world: BlockWorld.World, x: number, y: number, z: number, text: string)
	local checked = filtered(text, player.UserId)
	-- It could have been broken while the filter ran
	if owners[world] ~= player or not SIGN_FACES[BlockWorld.get(world, x, y, z) or ""] then
		return
	end
	shown[world][BlockWorld.key(x, y, z)] = checked
	drawWords(world, x, y, z)
end

local function onEditSign(player: Player, x: unknown, y: unknown, z: unknown, text: unknown)
	if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" or type(text) ~= "string" then
		return
	end
	local island = IslandService.GetIsland(player)
	local data = DataService.GetData(player)
	local now = os.clock()
	if not island or not data or now - (lastEdit[player] or 0) < SIGN_COOLDOWN then
		return
	end
	local world = island.World
	if not SIGN_FACES[BlockWorld.get(world, x, y, z) or ""] then
		return
	end
	lastEdit[player] = now
	local words = string.sub(text, 1, MAX_SIGN)
	data.Island.Signs[BlockWorld.key(x, y, z)] = if words == "" then nil else words
	DataService.MarkChanged(player)
	setWords(player, world, x, y, z, words)
end

-- Right-clicking one of your own signs opens it, with the words you wrote
local function onOpenSign(player: Player, x: unknown, y: unknown, z: unknown)
	if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
		return
	end
	local island = IslandService.GetIsland(player)
	local data = DataService.GetData(player)
	if island and data and SIGN_FACES[BlockWorld.get(island.World, x, y, z) or ""] then
		Remotes.OpenSign:FireClient(player, x, y, z, data.Island.Signs[BlockWorld.key(x, y, z)] or "")
	end
end

-- Placing -------------------------------------------------------------------------------

-- Does a decoration below reach up into this cell?
function DecorService.InTall(world: BlockWorld.World, x: number, y: number, z: number): boolean
	for down = 1, MAX_TALL do
		local decor = decorAt(world, x, y - down, z)
		if decor and decor.Tall > down then
			return true
		end
	end
	return false
end

-- Works out how this item goes in this cell, aimed at the block next to it: its block and turn,
-- or nil if it can't go there (having said why)
function DecorService.Plan(
	player: Player,
	world: BlockWorld.World,
	itemId: string,
	x: number,
	y: number,
	z: number,
	aimX: unknown,
	aimY: unknown,
	aimZ: unknown
): (string?, number?)
	local decor = Decorations.ByItem[itemId]
	if not decor or type(aimX) ~= "number" or type(aimY) ~= "number" or type(aimZ) ~= "number" then
		return nil
	end
	local dx, dy, dz = x - aimX, y - aimY, z - aimZ
	if math.abs(dx) + math.abs(dy) + math.abs(dz) ~= 1 then
		return nil
	end
	-- A sign goes on a post on top of a block, or flat on the side of one
	if itemId == "Sign" and dy == 0 then
		decor = Decorations.ByBlock.WallSign
	end
	if decor.Mount == "Wall" then
		if dy ~= 0 or not holds(world, aimX, aimY, aimZ) then
			StateService.Notify(player, `{decor.Name} goes on the side of a block`, "bad")
			return nil
		end
		return decor.Block, turnToward(dx, dz)
	end
	if decor.Mount == "Water" then
		if not isWater(world, x, y - 1, z) then
			StateService.Notify(player, `{decor.Name} goes on water`, "bad")
			return nil
		end
	elseif not holds(world, x, y - 1, z) then
		StateService.Notify(player, `{decor.Name} goes on top of a block`, "bad")
		return nil
	end
	for up = 1, decor.Tall - 1 do
		if BlockWorld.get(world, x, y + up, z) then
			StateService.Notify(player, `There isn't room for a {decor.Name} there`, "bad")
			return nil
		end
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local turn = 0
	if root and root:IsA("BasePart") then
		local toYou = root.Position - BlockWorld.position(world, x, y, z)
		turn = turnToward(toYou.X, toYou.Z)
	end
	return decor.Block, turn
end

-- Before a decoration's block goes in: which way it faces, now and whenever the island's built
function DecorService.SetTurn(player: Player, world: BlockWorld.World, x: number, y: number, z: number, turn: number)
	local data = DataService.GetData(player)
	local key = BlockWorld.key(x, y, z)
	world.Turns[key] = turn
	if data then
		data.Island.Turns[key] = turn
	end
end

-- After a decoration has come off: forget what only it needed
function DecorService.Removed(player: Player, world: BlockWorld.World, x: number, y: number, z: number)
	local data = DataService.GetData(player)
	local key = BlockWorld.key(x, y, z)
	world.Turns[key] = nil
	if shown[world] then
		shown[world][key] = nil
	end
	if data then
		data.Island.Turns[key] = nil
		data.Island.Signs[key] = nil
	end
end

-- Holding on ----------------------------------------------------------------------------

local function isHeld(world: BlockWorld.World, x: number, y: number, z: number, decor: Decorations.Decoration): boolean
	if decor.Mount == "Water" then
		return isWater(world, x, y - 1, z)
	elseif decor.Mount == "Floor" then
		return holds(world, x, y - 1, z)
	end
	-- The block behind it: a turned model's back (+Z) points this way
	local angle = (world.Turns[BlockWorld.key(x, y, z)] or 0) * math.pi / 2
	return holds(world, x + math.round(math.sin(angle)), y, z + math.round(math.cos(angle)))
end

-- Takes a decoration off and gives it back to the island's owner
local function popOff(world: BlockWorld.World, x: number, y: number, z: number, decor: Decorations.Decoration)
	local owner = owners[world]
	BlockWorld.set(world, x, y, z, nil)
	if owner then
		IslandService.RecordChange(owner, x, y, z, nil)
		DecorService.Removed(owner, world, x, y, z)
		InventoryService.AddGathered(owner, decor.Item, 1)
	end
end

local function checkHeld(world: BlockWorld.World, x: number, y: number, z: number)
	local decor = decorAt(world, x, y, z)
	if decor and not isHeld(world, x, y, z, decor) then
		popOff(world, x, y, z, decor)
	end
end

-- Whenever a cell on the island changes
local function onChanged(world: BlockWorld.World, x: number, y: number, z: number)
	checkHeld(world, x, y + 1, z)
	for _, side in SIDES do
		local nx, nz = x + side[1], z + side[2]
		checkHeld(world, nx, y, nz)
		if BlockWorld.get(world, nx, y, nz) == "Fence" then
			drawRails(world, nx, y, nz)
		end
	end
end

-- Whenever a decoration's part is drawn (again)
local function onDrawn(world: BlockWorld.World, x: number, y: number, z: number, part: BasePart)
	if part.Name == "Fence" then
		drawRails(world, x, y, z)
	elseif SIGN_FACES[part.Name] then
		drawWords(world, x, y, z)
	end
end

local function attach(player: Player, island: IslandService.Island)
	local world = island.World
	local data = DataService.GetData(player)
	owners[world] = player
	shown[world] = {}
	world.Drawn = function(x, y, z, part)
		onDrawn(world, x, y, z, part)
	end
	world.DecorChanged = function(x, y, z)
		onChanged(world, x, y, z)
	end
	-- The island's already drawn by now
	for key, blockType in world.Cells do
		if blockType == "Fence" then
			drawRails(world, BlockWorld.unkey(key))
		end
	end
	if data then
		for key, words in data.Island.Signs do
			local x, y, z = BlockWorld.unkey(key)
			task.spawn(setWords, player, world, x, y, z, words)
		end
	end
end

function DecorService.Start()
	IslandService.OnIslandCreated(attach)
	Remotes.EditSign.OnServerEvent:Connect(onEditSign)
	Remotes.OpenSign.OnServerEvent:Connect(onOpenSign)
	Players.PlayerRemoving:Connect(function(player)
		lastEdit[player] = nil
		for world, owner in owners do
			if owner == player then
				owners[world] = nil
				shown[world] = nil
			end
		end
	end)
end

return DecorService
