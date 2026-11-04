--!strict
-- Over the hotbar, the way Minecraft does it (your call, 2026-11-03): ten hearts on the left, your armour
-- above them while you wear any, and in the Warzone ten drumsticks of hunger on the right, emptying from
-- the left. Half an icon counts. A hit makes the hearts blink, low health makes them shake and poison
-- turns them green. The icons are our own drawings (art/scripts/vitals_icons.py). The server decides all
-- of it; this shows it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Combat = require(ReplicatedStorage.Shared.Combat)
local Config = require(ReplicatedStorage.Shared.Config)
local Places = require(ReplicatedStorage.Shared.Places)
local Hotbar = require(script.Parent.Hotbar)

local ICON = 24
local STEP = 25 -- from one icon to the next
local RAISE = 6 -- above the hotbar
local ROW_GAP = 2
local CHECK_EVERY = 0.05
local BLINK_TIME = 0.6
local BLINK_EVERY = 0.1
local SHAKE_BELOW = 0.2 -- a share of your health
local SHAKE = 2 -- pixels

-- The sheet's cells, in the order the drawing script makes them
local CELL_SIZE = 44
local Cell = table.freeze({
	HeartFull = 0,
	HeartHalf = 1,
	HeartEmpty = 2,
	HeartBlink = 3,
	PoisonFull = 4,
	PoisonHalf = 5,
	FoodFull = 6,
	FoodHalf = 7,
	FoodEmpty = 8,
	ArmourFull = 9,
	ArmourHalf = 10,
	ArmourEmpty = 11,
})

local VitalsHud = {}

local player = Players.LocalPlayer
local armourRow: Frame
local armourIcons: { ImageLabel } = {}
local shownArmour = -1

local function setCell(icon: ImageLabel, cell: number)
	icon.ImageRectOffset = Vector2.new(cell * CELL_SIZE, 0)
end

local function makeRow(parent: Instance, name: string, fromRight: boolean, y: number): (Frame, { ImageLabel })
	local row = Instance.new("Frame")
	row.Name = name
	row.BackgroundTransparency = 1
	row.AnchorPoint = Vector2.new(if fromRight then 1 else 0, 1)
	row.Position = UDim2.new(if fromRight then 1 else 0, 0, 0, y)
	row.Size = UDim2.fromOffset(STEP * 10, ICON)
	row.Parent = parent
	local icons = {}
	for index = 1, 10 do
		local icon = Instance.new("ImageLabel")
		icon.BackgroundTransparency = 1
		icon.Size = UDim2.fromOffset(ICON, ICON)
		-- The hunger row counts from its right end
		icon.Position = UDim2.fromOffset(if fromRight then STEP * (10 - index) else STEP * (index - 1), 0)
		icon.Image = Config.VitalsSheet
		icon.ImageRectSize = Vector2.new(CELL_SIZE, CELL_SIZE)
		icon.ResampleMode = Enum.ResamplerMode.Pixelated
		icon.Parent = row
		icons[index] = icon
	end
	return row, icons
end

-- Fills a row from a count of halves, 0 to 20
local function fill(icons: { ImageLabel }, halves: number, full: number, half: number, empty: number)
	for index, icon in icons do
		local here = halves - (index - 1) * 2
		setCell(icon, if here >= 2 then full elseif here == 1 then half else empty)
	end
end

function VitalsHud.SetState(state: any)
	if not armourRow or not state then
		return
	end
	local points = Combat.Armor(state.Equipped)
	if points ~= shownArmour then
		shownArmour = points
		armourRow.Visible = points > 0
		fill(armourIcons, math.round(points), Cell.ArmourFull, Cell.ArmourHalf, Cell.ArmourEmpty)
	end
end

function VitalsHud.Start()
	local bar = Hotbar.Bar()
	local _, hearts = makeRow(bar, "Hearts", false, -RAISE)
	armourRow, armourIcons = makeRow(bar, "Armour", false, -RAISE - ICON - ROW_GAP)
	armourRow.Visible = false
	local foods: { ImageLabel }? = nil
	if Places.Current() == "Warzone" then
		local _, row = makeRow(bar, "Hunger", true, -RAISE)
		foods = row
	end

	local lastHealth, lastHalves, lastFood = -1, -1, -1
	local wasPoisoned = false
	local blinkUntil = 0
	local wasBlinking = false
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < CHECK_EVERY then
			return
		end
		elapsed = 0
		local now = os.clock()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local share = 1
		if humanoid then
			local hp, max = humanoid.Health, humanoid.MaxHealth
			share = if max > 0 then hp / max else 0
			if hp < lastHealth then
				blinkUntil = now + BLINK_TIME
			end
			lastHealth = hp
		end

		local until_ = player:GetAttribute("PoisonUntil")
		local poisoned = type(until_) == "number" and until_ > workspace:GetServerTimeNow()
		local blinking = now < blinkUntil
		local halves = math.ceil(share * 20)
		if halves ~= lastHalves or poisoned ~= wasPoisoned or blinking or wasBlinking then
			lastHalves, wasPoisoned, wasBlinking = halves, poisoned, blinking
			local lit = blinking and (blinkUntil - now) % (BLINK_EVERY * 2) > BLINK_EVERY
			fill(
				hearts,
				halves,
				if poisoned then Cell.PoisonFull else Cell.HeartFull,
				if poisoned then Cell.PoisonHalf else Cell.HeartHalf,
				if lit then Cell.HeartBlink else Cell.HeartEmpty
			)
		end

		-- Near death they shake
		local shaking = share > 0 and share <= SHAKE_BELOW
		for index, icon in hearts do
			local y = if shaking then math.random(-SHAKE, SHAKE) else 0
			if icon.Position.Y.Offset ~= y then
				icon.Position = UDim2.fromOffset(STEP * (index - 1), y)
			end
		end

		local row = foods
		if row then
			local value = player:GetAttribute("Hunger")
			local food = if type(value) == "number" then value else 100
			if food ~= lastFood then
				lastFood = food
				fill(row, math.ceil(food / 5), Cell.FoodFull, Cell.FoodHalf, Cell.FoodEmpty)
			end
		end
	end)
end

return VitalsHud
