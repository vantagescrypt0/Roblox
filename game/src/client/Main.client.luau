--!strict
-- Client entry point.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CraftingMenu = require(script.Parent.CraftingMenu)
local Hud = require(script.Parent.Hud)
local QuestTracker = require(script.Parent.QuestTracker)

Hud.Start()
CraftingMenu.Start()
QuestTracker.Start()

Remotes.State.OnClientEvent:Connect(function(state)
	Hud.Render(state)
	CraftingMenu.SetState(state)
	QuestTracker.Render(state)
end)
Remotes.Notify.OnClientEvent:Connect(Hud.Toast)
Remotes.OpenCrafting.OnClientEvent:Connect(CraftingMenu.Open)
Remotes.Ready:FireServer()
