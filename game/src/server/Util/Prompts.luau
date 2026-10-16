--!strict
-- ProximityPrompts work with keyboard, gamepad and touch, so they're our interaction system.
-- They use the Custom style; the client draws them (client/PromptUI.luau).

local Prompts = {}

export type PromptOptions = {
	Action: string,
	Object: string?,
	Hold: number?,
	Key: Enum.KeyCode?,
	Distance: number?,
}

function Prompts.Create(parent: Instance, options: PromptOptions): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = options.Action
	prompt.ObjectText = options.Object or ""
	prompt.HoldDuration = options.Hold or 0
	prompt.KeyboardKeyCode = options.Key or Enum.KeyCode.E
	prompt.MaxActivationDistance = options.Distance or 10
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.Parent = parent
	return prompt
end

-- Connects a handler that only runs for the given owner.
function Prompts.OnTriggeredBy(prompt: ProximityPrompt, owner: Player, handler: () -> ())
	return prompt.Triggered:Connect(function(who)
		if who == owner then
			handler()
		end
	end)
end

return Prompts
