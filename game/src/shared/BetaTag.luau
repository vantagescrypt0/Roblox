--!strict
-- The Beta Tester tag (players asked for one; the user had Claude pick the cap and the look, 2026-11-11). The first
-- Config.BetaTags players to join get a numbered tag, theirs for good: server/Services/BetaService hands out the
-- numbers. It shows as a "BETA #37" pill over their head (client/BetaTagController), "[BETA]" before their name in
-- chat, and a chip on their profile.

local Players = game:GetService("Players")

local BetaTag = {}

BetaTag.Attribute = "Beta" -- on the Player, set by the server: their number
BetaTag.Color = Color3.fromRGB(176, 140, 255)
BetaTag.Hex = "#B08CFF"

-- Their Beta Tester number, or nil if they don't have one
function BetaTag.Of(player: Player?): number?
	if not player or player.Parent ~= Players then
		return nil
	end
	local number = player:GetAttribute(BetaTag.Attribute)
	return if type(number) == "number" and number > 0 then number else nil
end

return table.freeze(BetaTag)
