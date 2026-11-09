--!strict
-- Background music and nature sounds for each place: a calm playlist (APM Music from
-- Roblox's licensed library, so any experience may use it) that plays through and fades
-- between tracks, and a quiet ambience loop under it. Volumes live in the "Music" sound
-- group, so a settings menu can turn them down later.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Places = require(ReplicatedStorage.Shared.Places)

local MusicController = {}

local MUSIC_VOLUME = 0.22
local AMBIENCE_VOLUME = 0.12
local FADE = 2.5

-- APM tracks by place (asset id, name for whoever reads this)
local PLAYLISTS: { [string]: { number } } = {
	Island = {
		9046598930, -- Watching the Garden Grow (a)
		9038622067, -- Lakefront Days (Ukulele Version)
	},
	Town = {
		95631966166002, -- Village Jig
		1845197284, -- Village Day
	},
	Farming = {
		1839127780, -- Green Grassland
		9046601136, -- Watching the Garden Grow (b)
	},
	Woodcutting = {
		1836416985, -- Gone Fishing
		1836417198, -- Wandering
	},
	Mining = {
		1848354561, -- Quietness Sustained
		1848354536, -- Relaxed Scene
	},
	Warzone = {
		1848354561, -- Quietness Sustained
		1848354536, -- Relaxed Scene
	},
	Slaying = {
		1836416985, -- Gone Fishing
		1848354536, -- Relaxed Scene
	},
}

-- Pro Sound Effects loops under the music
local BIRDS = 9112748456 -- Birds Exterior Ambience 6
local CAVE = 9118747525 -- Rumble Ambience Interior Wind Turbo Shaft 1
local AMBIENCE: { [string]: number } = {
	Island = BIRDS,
	Town = BIRDS,
	Farming = BIRDS,
	Woodcutting = BIRDS,
	Mining = CAVE,
	Warzone = CAVE,
	Slaying = BIRDS,
}

local group = Instance.new("SoundGroup")
group.Name = "Music"
group.Volume = 1
group.Parent = SoundService

local function newSound(assetId: number, volume: number, looped: boolean): Sound
	local sound = Instance.new("Sound")
	sound.SoundId = `rbxassetid://{assetId}`
	sound.Volume = volume
	sound.Looped = looped
	sound.SoundGroup = group
	sound.Parent = SoundService
	return sound
end

local function fadeTo(sound: Sound, volume: number)
	TweenService:Create(sound, TweenInfo.new(FADE), { Volume = volume }):Play()
end

function MusicController.Start()
	local place = Places.Current()
	local ambience = AMBIENCE[place]
	if ambience then
		newSound(ambience, AMBIENCE_VOLUME, true):Play()
	end

	local playlist = PLAYLISTS[place] or PLAYLISTS.Island
	task.spawn(function()
		-- A little quiet first, then the tracks in a loop, starting at a random one
		task.wait(3)
		local index = math.random(1, #playlist)
		while true do
			local track = newSound(playlist[index], 0, false)
			track:Play()
			fadeTo(track, MUSIC_VOLUME)
			-- Wait for it to finish (a track that won't load is skipped after a while)
			local waited = 0
			while not track.IsLoaded and waited < 10 do
				waited += task.wait(0.5)
			end
			local length = if track.IsLoaded and track.TimeLength > 0 then track.TimeLength else 20
			task.wait(math.max(length - FADE, 1))
			fadeTo(track, 0)
			task.wait(FADE)
			track:Destroy()
			-- A pause between tracks
			task.wait(8)
			index = index % #playlist + 1
		end
	end)
end

return MusicController
