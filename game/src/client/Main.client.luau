--!strict
-- Client entry point.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Hud = require(script.Parent.Hud)

Hud.Start()

Remotes.State.OnClientEvent:Connect(Hud.Render)
Remotes.Notify.OnClientEvent:Connect(Hud.Toast)
Remotes.Ready:FireServer()
