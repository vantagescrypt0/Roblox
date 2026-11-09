--!strict
-- Sound effects. Sfx.play("Click") plays a sound flat (UI); Sfx.play("StoneHit", position)
-- plays it at a spot in the world, quieter further away. Each name can have a few takes,
-- picked at random with a slight pitch change, so repeated hits don't sound the same.
--
-- Every sound is from Roblox's own uploads or the licensed libraries in the Creator Store
-- (Pro Sound Effects for effects, APM Music in MusicController), which any experience may
-- use. Never use sounds ripped from other games.

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Blocks = require(ReplicatedStorage.Shared.Blocks)

type Def = {
	Ids: { number },
	Volume: number,
	Pitch: { number }?, -- random playback speed range
	Gap: number?, -- seconds before the same sound can play again
}

local DEFS: { [string]: Def } = {
	-- Interface (Roblox's UI pack)
	Click = { Ids = { 15675059323 }, Volume = 0.5 }, -- Roblox_UI_Bright_Click
	Open = { Ids = { 15675024286 }, Volume = 0.35 }, -- Roblox_UI_Whoosh_01
	Close = { Ids = { 15675012262 }, Volume = 0.3 }, -- Roblox_UI_Whoosh_04
	Pop = { Ids = { 15675055424 }, Volume = 0.35, Pitch = { 0.95, 1.1 }, Gap = 0.08 }, -- Roblox_UI_Cute_Pop
	Error = { Ids = { 15675062723 }, Volume = 0.35, Gap = 0.4 }, -- Roblox_UI_Whistle_Low
	Coins = { Ids = { 127645268874265 }, Volume = 0.5, Gap = 0.15 }, -- CoinTransfer_01
	Chime = { Ids = { 17208361335 }, Volume = 0.5 }, -- Roblox GUI - Notification High
	Mail = { Ids = { 17208372272 }, Volume = 0.45 }, -- Roblox GUI - Notification Low
	Stinger = { Ids = { 15675043410 }, Volume = 0.6 }, -- Roblox_UI_Tonal_Stinger
	Sparkle = { Ids = { 9126073001 }, Volume = 0.35 }, -- Synth Sparkle Tone Bell Ding
	Travel = { Ids = { 15675046931 }, Volume = 0.5 }, -- Roblox_UI_Sweep
	-- Gathering and building (Pro Sound Effects)
	StoneHit = { Ids = { 9125869504, 9125869495, 9125869138 }, Volume = 0.3, Pitch = { 0.95, 1.12 }, Gap = 0.1 },
	StoneBreak = { Ids = { 9125869797 }, Volume = 0.4, Pitch = { 0.95, 1.08 } },
	WoodHit = {
		Ids = { 9120808574, 9120811299, 9120808557, 9120807255 },
		Volume = 0.35,
		Pitch = { 0.95, 1.1 },
		Gap = 0.1,
	},
	WoodBreak = { Ids = { 9120813044 }, Volume = 0.4, Pitch = { 0.95, 1.08 } },
	DirtHit = { Ids = { 9114083260, 9114083746 }, Volume = 0.3, Pitch = { 0.95, 1.12 }, Gap = 0.1 },
	Leaves = { Ids = { 9114518386, 9114518233, 9114517229 }, Volume = 0.3, Pitch = { 0.95, 1.15 }, Gap = 0.1 },
	Place = { Ids = { 9120880067 }, Volume = 0.35, Pitch = { 0.9, 1.15 }, Gap = 0.05 }, -- Wood Grab Muted Thuds
	Harvest = { Ids = { 9114518070 }, Volume = 0.35, Pitch = { 0.95, 1.15 }, Gap = 0.08 }, -- Foliage Movement
	Craft = { Ids = { 9113447467 }, Volume = 0.4, Pitch = { 0.95, 1.08 }, Gap = 0.1 }, -- Blacksmith Anvil Hammer Hits
	Smelt = { Ids = { 9114442751 }, Volume = 0.4, Pitch = { 0.95, 1.08 }, Gap = 0.1 }, -- Fire Whoosh
	Pour = { Ids = { 9120576882 }, Volume = 0.4, Gap = 0.2 }, -- Water Pour Plastic Bucket
	Splash = { Ids = { 9125703162, 9125702803 }, Volume = 0.35, Gap = 0.1 }, -- Mud Puddle Splash
	Sizzle = { Ids = { 9119165650 }, Volume = 0.35, Pitch = { 0.9, 1.1 }, Gap = 0.3 }, -- Sizzle Short
	TreeFall = { Ids = { 9120258937 }, Volume = 0.55 }, -- Tree Branches Breaking Snapping Cracking
	Swing = { Ids = { 15675012262 }, Volume = 0.35, Pitch = { 1.1, 1.3 }, Gap = 0.1 }, -- Roblox_UI_Whoosh_04
	Hit = { Ids = { 9119330371 }, Volume = 0.6, Pitch = { 0.95, 1.1 }, Gap = 0.05 }, -- Soccer Ball Tackle 4
	Crit = { Ids = { 9118270242 }, Volume = 0.5, Pitch = { 1, 1.1 }, Gap = 0.05 }, -- Robot Impact Hollow Metal Hits
}

-- How hitting and breaking a block sounds, by the tool that breaks it
local HITS: { [string]: string } = { Pickaxe = "StoneHit", Axe = "WoodHit", Shovel = "DirtHit" }
local BREAKS: { [string]: string } = { Pickaxe = "StoneBreak", Axe = "WoodBreak", Shovel = "DirtHit" }

local Sfx = {}

local rng = Random.new()
local lastPlayed: { [string]: number } = {}

local effects = Instance.new("SoundGroup")
effects.Name = "Effects"
effects.Volume = 1
effects.Parent = SoundService
Sfx.Effects = effects

local function id(n: number): string
	return `rbxassetid://{n}`
end

-- `pitch` plays it at exactly that speed, for sounds that climb
function Sfx.play(name: string, position: Vector3?, exactPitch: number?)
	local def = DEFS[name]
	if not def then
		return
	end
	local now = os.clock()
	if now - (lastPlayed[name] or 0) < (def.Gap or 0.03) then
		return
	end
	lastPlayed[name] = now

	local sound = Instance.new("Sound")
	sound.SoundId = id(def.Ids[rng:NextInteger(1, #def.Ids)])
	sound.Volume = def.Volume
	local pitch = def.Pitch
	sound.PlaybackSpeed = exactPitch or if pitch then rng:NextNumber(pitch[1], pitch[2]) else 1
	sound.SoundGroup = effects
	local holder: Instance = sound
	if position then
		-- At a spot in the world: an attachment there holds the sound
		local spot = Instance.new("Attachment")
		spot.WorldPosition = position
		sound.RollOffMinDistance = 12
		sound.RollOffMaxDistance = 140
		sound.Parent = spot
		spot.Parent = workspace.Terrain
		holder = spot
	else
		sound.Parent = SoundService
	end
	sound.Ended:Once(function()
		holder:Destroy()
	end)
	sound:Play()
	-- In case it never loads (Ended never fires)
	task.delay(12, function()
		if holder.Parent then
			holder:Destroy()
		end
	end)
end

-- A block being hit (or broken, if `broke`): stone, wood, dirt or leaves by its material
function Sfx.block(blockName: string, broke: boolean, position: Vector3)
	local name
	if string.find(blockName, "Leaves") then
		name = "Leaves"
	else
		local def = Blocks.Types[blockName]
		local tool = if def then def.Tool or "" else ""
		name = if broke then BREAKS[tool] or "StoneBreak" else HITS[tool] or "StoneHit"
	end
	Sfx.play(name, position)
end

-- Loads every effect up front, so the first click doesn't play late
function Sfx.preload()
	task.spawn(function()
		local list = {}
		for _, def in DEFS do
			for _, n in def.Ids do
				local sound = Instance.new("Sound")
				sound.SoundId = id(n)
				table.insert(list, sound)
			end
		end
		pcall(function()
			ContentProvider:PreloadAsync(list)
		end)
	end)
end

return Sfx
