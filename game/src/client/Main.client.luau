--!strict
-- Client entry point: builds the UI and routes server messages to it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Places = require(ReplicatedStorage.Shared.Places)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local IslandTiers = require(ReplicatedStorage.Shared.IslandTiers)
local BlockController = require(script.Parent.BlockController)
local Hotbar = require(script.Parent.Hotbar)
local Hud = require(script.Parent.Hud)
local MerchantController = require(script.Parent.MerchantController)
local PromptUI = require(script.Parent.PromptUI)
local QuestTracker = require(script.Parent.QuestTracker)
local BagWindow = require(script.Parent.Windows.BagWindow)
local CraftingWindow = require(script.Parent.Windows.CraftingWindow)
local IslandWindow = require(script.Parent.Windows.IslandWindow)
local MarketWindow = require(script.Parent.Windows.MarketWindow)
local TradeWindow = require(script.Parent.Windows.TradeWindow)

-- Our own hotbar replaces Roblox's backpack bar
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

BagWindow.Start()
IslandWindow.Start()
MarketWindow.Start()
CraftingWindow.Start()
TradeWindow.Start()
QuestTracker.Start()
PromptUI.Start()
Hud.Start({
	OnBag = BagWindow.Toggle,
	OnIsland = function()
		if Places.Current() == "Town" then
			Hud.Toast("Your island is back through the portal", "info")
		else
			IslandWindow.Toggle()
		end
	end,
})
Hotbar.Start()
BlockController.Start({
	OpenCrafting = CraftingWindow.Open,
	OpenMarket = MarketWindow.Open,
})
MerchantController.Start()

Remotes.State.OnClientEvent:Connect(function(state)
	Hud.Render(state)
	Hotbar.SetState(state)
	QuestTracker.Render(state)
	BagWindow.SetState(state)
	IslandWindow.SetState(state)
	MarketWindow.SetState(state)
	CraftingWindow.SetState(state)
	TradeWindow.SetState(state)
end)
Remotes.Notify.OnClientEvent:Connect(Hud.Toast)
Remotes.OpenCrafting.OnClientEvent:Connect(CraftingWindow.Open)
Remotes.OpenMarket.OnClientEvent:Connect(MarketWindow.Open)
Remotes.Travel.OnClientEvent:Connect(Hud.Travel)
Remotes.IslandRebuilt.OnClientEvent:Connect(function(tier: number)
	IslandWindow.Close()
	local info = IslandTiers[tier]
	Hud.Celebrate("Island Expanded!", if info then info.Name else "", Color3.fromRGB(150, 214, 110))
end)
Remotes.Ready:FireServer()
