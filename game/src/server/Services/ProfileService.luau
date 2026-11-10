--!strict
-- Player profiles (your call, 2026-11-10): left-click (tap) another player anywhere but the Warzone and their
-- profile opens (client/Windows/ProfileWindow). The server answers with a snapshot of their save: level, coins,
-- skills, what they wear (armour, shield, pet) and hold, their boosts, island, kits, trades and season, and a title
-- from their best skill. Nothing private: no inbox, no trade details, no anti-cheat record.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Boosts = require(ReplicatedStorage.Shared.Boosts)
local Gear = require(ReplicatedStorage.Shared.Gear)
local Leveling = require(ReplicatedStorage.Shared.Leveling)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Skills = require(ReplicatedStorage.Shared.Skills)
local DataService = require(script.Parent.DataService)

local ASK_COOLDOWN = 0.4

-- A title from your best skill's level: "Expert Miner" and so on
local RANKS = {
	{ Level = 99, Name = "Grandmaster" },
	{ Level = 75, Name = "Master" },
	{ Level = 50, Name = "Expert" },
	{ Level = 25, Name = "Adept" },
	{ Level = 10, Name = "Apprentice" },
	{ Level = 1, Name = "Novice" },
}
local WHO: { [string]: string } = {
	Farming = "Farmer",
	Mining = "Miner",
	Woodcutting = "Lumberjack",
	Crafting = "Crafter",
	Combat = "Slayer",
}

local ProfileService = {}

local lastAsk: { [Player]: number } = {}

local function held(player: Player): string?
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	local item = tool and tool:GetAttribute("Held")
	return if type(item) == "string" then item else nil
end

local function title(best: string, level: number): string
	for _, rank in RANKS do
		if level >= rank.Level then
			return `{rank.Name} {WHO[best] or best}`
		end
	end
	return "Newcomer"
end

local function snapshot(target: Player, data: DataService.Data)
	local skills = {}
	local total, best, bestLevel = 0, "Farming", 0
	for _, skill in Skills.List do
		local saved = (data.Skills :: any)[skill.Id]
		local level = if saved then saved.Level else 1
		local xp = if saved then saved.XP else 0
		total += level
		if level > bestLevel then
			best, bestLevel = skill.Id, level
		end
		table.insert(skills, {
			Id = skill.Id,
			Name = skill.Name,
			Icon = skill.Icon,
			Level = level,
			Progress = if level >= Leveling.MaxSkillLevel then 1 else xp / Leveling.SkillXPToNext(level),
		})
	end
	local kits = 0
	for _ in data.KitClaims do
		kits += 1
	end
	local equipped = {}
	for _, slot in Gear.ArmorSlots do
		equipped[slot] = (data.Equipped :: any)[slot]
	end
	equipped.Shield = data.Equipped.Shield
	equipped.Pet = data.Equipped.Pet
	return {
		UserId = target.UserId,
		Name = target.Name,
		DisplayName = target.DisplayName,
		Title = title(best, bestLevel),
		Level = data.Level,
		MaxLevel = Leveling.MaxPlayerLevel,
		Progress = if data.Level >= Leveling.MaxPlayerLevel then 1 else data.XP / Leveling.PlayerXPToNext(data.Level),
		Coins = data.Coins,
		Season = data.Season,
		Skills = skills,
		SkillTotal = total,
		Equipped = equipped,
		Held = held(target),
		Boosts = {
			Warzone = Boosts.Level(data, "Warzone"),
			Player = Boosts.Level(data, "Player"),
			Island = Boosts.Level(data, "Island"),
			Most = Boosts.PerTree,
		},
		IslandTier = data.Island.Tier,
		Trades = #data.Trades,
		Kits = kits,
		TradeLevel = Leveling.TradeLevel,
	}
end

local function onOpen(player: Player, target: unknown)
	if typeof(target) ~= "Instance" or not (target :: Instance):IsA("Player") then
		return
	end
	local other = target :: Player
	local now = os.clock()
	if other.Parent ~= Players or now - (lastAsk[player] or 0) < ASK_COOLDOWN then
		return
	end
	lastAsk[player] = now
	local data = DataService.GetData(other)
	if data then
		Remotes.ProfileShow:FireClient(player, snapshot(other, data))
	end
end

function ProfileService.Start()
	Remotes.ProfileOpen.OnServerEvent:Connect(onOpen)
	Players.PlayerRemoving:Connect(function(player)
		lastAsk[player] = nil
	end)
end

return ProfileService
