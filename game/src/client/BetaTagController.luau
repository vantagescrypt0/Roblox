--!strict
-- Beta Tester tags (shared/BetaTag.luau, server/Services/BetaService). A "BETA #37" pill floats over each tagged
-- player's name, and over your own head while you're not in first person. "[BETA]" goes before their name in chat.
-- And there's a celebration the moment you get yours.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local BetaTag = require(ReplicatedStorage.Shared.BetaTag)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local FirstPersonController = require(script.Parent.FirstPersonController)
local Hud = require(script.Parent.Hud)
local Theme = require(script.Parent.UI.Theme)

local C = Theme.Color
local localPlayer = Players.LocalPlayer

local NAME_ABOVE_HEAD = 1.5 -- studs over the top of the head: where Roblox draws a player's name (measured)
local LIFT = 25 -- pixels from the middle of their name up to the middle of the pill, the same at any distance
local PILL_HEIGHT = 22
local RANGE = 70 -- studs: further off, the pill goes
local CELEBRATE_SECONDS = 5

type Tag = { Board: BillboardGui, Head: BasePart? }

-- The board sits where their name is. Others' pills go a fixed number of pixels above it, so the two never
-- overlap however far off they are; yours (Roblox doesn't show you your own name) goes where your name would be.
local function anchor(board: BillboardGui, head: BasePart)
	board.Adornee = head
	board.StudsOffsetWorldSpace = Vector3.new(0, head.Size.Y / 2 + NAME_ABOVE_HEAD, 0)
end

local BetaTagController = {}

local tags: { [Player]: Tag } = {}

local function makeBoard(player: Player, number: number): BillboardGui
	local board = Theme.make("BillboardGui", {
		Name = `BetaTag_{player.UserId}`,
		Size = UDim2.fromOffset(160, (LIFT + PILL_HEIGHT // 2) * 2),
		MaxDistance = RANGE,
		LightInfluence = 0,
		ResetOnSpawn = false,
		Enabled = false,
	})
	local mine = player == localPlayer
	local pill = Theme.make("TextLabel", {
		AnchorPoint = Vector2.new(0.5, if mine then 0.5 else 0),
		Position = UDim2.fromScale(0.5, if mine then 0.5 else 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, PILL_HEIGHT),
		BackgroundColor3 = C.Well,
		BackgroundTransparency = 0.15,
		RichText = true,
		Text = `<font color="{BetaTag.Hex}">BETA</font> #{number}`,
		TextSize = 15,
		FontFace = Theme.Font.Bold,
		TextColor3 = C.Ink,
		Parent = board,
	})
	Theme.corner(pill, 11)
	Theme.stroke(pill, BetaTag.Color, 1.5, 0.1)
	Theme.padding(pill, 10, 10, 0, 0)
	board.Parent = localPlayer:WaitForChild("PlayerGui")
	return board
end

local function drop(player: Player)
	local tag = tags[player]
	if tag then
		tag.Board:Destroy()
		tags[player] = nil
	end
end

local function findHead(player: Player): BasePart?
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	return if head and head:IsA("BasePart") then head else nil
end

local function refresh(player: Player)
	local number = BetaTag.Of(player)
	drop(player)
	if not number then
		return
	end
	local board = makeBoard(player, number)
	local head = findHead(player)
	if head then
		anchor(board, head)
	end
	tags[player] = { Board = board, Head = head }
end

local function watch(player: Player)
	refresh(player)
	player:GetAttributeChangedSignal(BetaTag.Attribute):Connect(function()
		refresh(player)
	end)
	player.CharacterAdded:Connect(function(character)
		local head = character:WaitForChild("Head", 10)
		local tag = tags[player]
		if tag and head and head:IsA("BasePart") and player.Character == character then
			tag.Head = head
			anchor(tag.Board, head)
		end
	end)
end

-- Hidden when there's no head to show it over: gone, see-through (a hidden body in the Warzone), or yours in
-- first person
local function update()
	for player, tag in tags do
		local head = tag.Head
		local shown = head ~= nil
			and head.Parent ~= nil
			and head.Transparency < 0.95
			and head.LocalTransparencyModifier < 0.95
		if player == localPlayer and FirstPersonController.IsActive() then
			shown = false
		end
		if tag.Board.Enabled ~= shown then
			tag.Board.Enabled = shown
		end
	end
end

-- "[BETA]" before a tagged player's name in chat
local function onIncomingMessage(message: TextChatMessage): TextChatMessageProperties?
	local properties = Instance.new("TextChatMessageProperties")
	local source = message.TextSource
	if source and BetaTag.Of(Players:GetPlayerByUserId(source.UserId)) then
		properties.PrefixText = `<font color="{BetaTag.Hex}">[BETA]</font> {message.PrefixText}`
	end
	return properties
end

function BetaTagController.Start()
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(drop)
	RunService.Heartbeat:Connect(update)
	TextChatService.OnIncomingMessage = onIncomingMessage
	Remotes.BetaTagGiven.OnClientEvent:Connect(function(number: number, total: number)
		Hud.Celebrate(
			`Beta Tester #{number}`,
			`One of the first {Theme.formatNumber(total)} players. The BETA tag is yours for good.`,
			BetaTag.Color,
			CELEBRATE_SECONDS
		)
	end)
end

return BetaTagController
