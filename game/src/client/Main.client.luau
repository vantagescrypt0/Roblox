--!strict
-- Client entry point: builds the UI and routes server messages to it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")

local ANNOUNCE_SECONDS = 6 -- an admin's announcement stays on screen this long

local Places = require(ReplicatedStorage.Shared.Places)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local IslandTiers = require(ReplicatedStorage.Shared.IslandTiers)
local MusicController = require(script.Parent.MusicController)
local AmbientController = require(script.Parent.AmbientController)
local BlockController = require(script.Parent.BlockController)
local CombatController = require(script.Parent.CombatController)
local FirstPersonController = require(script.Parent.FirstPersonController)
local FlightController = require(script.Parent.FlightController)
local SprintController = require(script.Parent.SprintController)
local SwimController = require(script.Parent.SwimController)
local HeldController = require(script.Parent.HeldController)
local Hotbar = require(script.Parent.Hotbar)
local Hud = require(script.Parent.Hud)
local MobController = require(script.Parent.MobController)
local NpcController = require(script.Parent.NpcController)
local PromptUI = require(script.Parent.PromptUI)
local QuestTracker = require(script.Parent.QuestTracker)
local AdminWindow = require(script.Parent.Windows.AdminWindow)
local BagWindow = require(script.Parent.Windows.BagWindow)
local ChallengesWindow = require(script.Parent.Windows.ChallengesWindow)
local ChestWindow = require(script.Parent.Windows.ChestWindow)
local SignWindow = require(script.Parent.Windows.SignWindow)
local SettingsWindow = require(script.Parent.Windows.SettingsWindow)
local VisitWindow = require(script.Parent.Windows.VisitWindow)
local CraftingWindow = require(script.Parent.Windows.CraftingWindow)
local CrateOpening = require(script.Parent.CrateOpening)
local CrateWindow = require(script.Parent.Windows.CrateWindow)
local InboxWindow = require(script.Parent.Windows.InboxWindow)
local IslandWindow = require(script.Parent.Windows.IslandWindow)
local KitPowerController = require(script.Parent.KitPowerController)
local KitsWindow = require(script.Parent.Windows.KitsWindow)
local ShopWindow = require(script.Parent.Windows.ShopWindow)
local SkillsWindow = require(script.Parent.Windows.SkillsWindow)
local TradeWindow = require(script.Parent.Windows.TradeWindow)
local VitalsHud = require(script.Parent.VitalsHud)
local SkydropController = require(script.Parent.SkydropController)
local WarzoneHud = require(script.Parent.WarzoneHud)
local Sfx = require(script.Parent.UI.Sfx)

-- Our own hotbar and health bar replace Roblox's
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

Sfx.preload()
MusicController.Start()
BagWindow.Start()
AdminWindow.Start()
IslandWindow.Start()
ShopWindow.Start()
CraftingWindow.Start()
TradeWindow.Start()
SkillsWindow.Start()
InboxWindow.Start()
CrateWindow.Start()
KitsWindow.Start()
CrateOpening.Start(CrateWindow.Count, KitsWindow.CrateOnSale, KitsWindow.OpenCrate)
ChestWindow.Start()
SignWindow.Start()
VisitWindow.Start()
SettingsWindow.Start()
ChallengesWindow.Start()
QuestTracker.Start(ChallengesWindow.OpenTracked)
PromptUI.Start()
Hud.Start({
	OnBag = BagWindow.Toggle,
	OnSkills = SkillsWindow.Toggle,
	OnChallenges = ChallengesWindow.Toggle,
	OnInbox = InboxWindow.Toggle,
	OnSettings = SettingsWindow.Toggle,
	OnKits = KitsWindow.Toggle,
	OnVisit = function()
		if Places.Current() ~= "Island" then
			Hud.Toast("Visit islands from your own island", "info")
		else
			VisitWindow.Toggle()
		end
	end,
	OnIsland = function()
		if Places.Current() ~= "Island" then
			Hud.Toast("Your island is back through the portal", "info")
		else
			IslandWindow.Toggle()
		end
	end,
})
Hotbar.Start()
VitalsHud.Start()
WarzoneHud.Start()
task.spawn(SkydropController.Start)
BlockController.Start({
	OpenCrafting = CraftingWindow.Open,
	OpenShop = ShopWindow.Open,
})
NpcController.Start()
MobController.Start()
AmbientController.Start()
FlightController.Start()
SwimController.Start()
HeldController.Start()
KitPowerController.Start()
CombatController.Start()
SprintController.Start()
FirstPersonController.Start()

Remotes.KitState.OnClientEvent:Connect(function(state)
	-- Only in the Menu for someone who owns a kit or can buy something
	Hud.ShowKits(KitsWindow.SetState(state))
end)

Remotes.State.OnClientEvent:Connect(function(state)
	Hud.Render(state)
	SettingsWindow.SetState(state)
	Hotbar.SetState(state)
	VitalsHud.SetState(state)
	QuestTracker.Render(state)
	BagWindow.SetState(state)
	IslandWindow.SetState(state)
	ShopWindow.SetState(state)
	CraftingWindow.SetState(state)
	TradeWindow.SetState(state)
	SkillsWindow.SetState(state)
	InboxWindow.SetState(state)
	CrateWindow.SetState(state)
	ChestWindow.SetState(state)
	ChallengesWindow.SetState(state)
end)
Remotes.Notify.OnClientEvent:Connect(Hud.Toast)
Remotes.OpenCrafting.OnClientEvent:Connect(CraftingWindow.Open)
Remotes.OpenShop.OnClientEvent:Connect(ShopWindow.Open)
Remotes.Travel.OnClientEvent:Connect(Hud.Travel)
Remotes.IslandRebuilt.OnClientEvent:Connect(function(tier: number)
	IslandWindow.Close()
	local info = IslandTiers[tier]
	local across = if info then info.Border * 2 + 1 else 0
	Hud.Celebrate("Island Upgraded!", `Build up to {across} x {across} blocks`, Color3.fromRGB(150, 214, 110))
end)
-- A line in your own chat, from the game
local function systemMessage(text: string)
	local channels = TextChatService:FindFirstChild("TextChannels")
	local system = channels and channels:FindFirstChild("RBXSystem")
	if system and system:IsA("TextChannel") then
		for _, line in string.split(text, "\n") do
			-- Chat reads < and > as formatting, and "/kick <player>" would break it
			local plain = string.gsub(string.gsub(string.gsub(line, "&", "&amp;"), "<", "&lt;"), ">", "&gt;")
			system:DisplaySystemMessage(plain)
		end
	end
end
-- The answer to an admin's command or panel action, in their own chat only (server/Services/AdminService)
Remotes.AdminReply.OnClientEvent:Connect(systemMessage)
-- An admin's announcement to everyone in the server: across the screen, and kept in chat
Remotes.Announce.OnClientEvent:Connect(function(text: string)
	Hud.Celebrate("Announcement", text, nil, ANNOUNCE_SECONDS)
	systemMessage(`[Announcement] {text}`)
end)
Remotes.Ready:FireServer()
