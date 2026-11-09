--!strict
-- How long a block takes to break with what you're holding (Minecraft's rules):
--   right tool:            Hardness x 1.5 / tool Efficiency
--   no/wrong tool:         Hardness x 1.5           (if the block doesn't need a tool)
--   block needs a tool:    Hardness x 5, and it drops nothing
-- Used by the client (crack progress) and the server (anti-cheat timing).

local Blocks = require(script.Parent.Blocks)
local Tools = require(script.Parent.Tools)

local Mining = {}

-- Can this block be broken here? `onIsland` is a player's own island
function Mining.CanBreak(blockType: string, onIsland: boolean): boolean
	local block = Blocks.Types[blockType]
	return block ~= nil and (block.Breakable or (onIsland and block.BreaksOnIsland == true))
end

-- Returns break time in seconds and whether the block will drop its item
function Mining.BreakTime(blockType: string, heldItem: string?, onIsland: boolean?): (number, boolean)
	local block = Blocks.Types[blockType]
	if not block or not Mining.CanBreak(blockType, onIsland == true) then
		return math.huge, false
	end
	local tool = if heldItem then Tools.ByItem[heldItem] else nil
	local rightTool = tool ~= nil and block.Tool ~= nil and tool.Kind == block.Tool
	local speed = if rightTool and tool then tool.Efficiency else 1
	local canHarvest = not block.RequiresTool or (rightTool and tool ~= nil and tool.Tier >= (block.MinTier or 1))
	local factor = if canHarvest then 1.5 else 5
	return math.max(block.Hardness * factor / speed, 0.05), canHarvest
end

-- Does breaking this block with this item wear the tool down?
function Mining.UsesTool(blockType: string, heldItem: string?): boolean
	local block = Blocks.Types[blockType]
	local tool = if heldItem then Tools.ByItem[heldItem] else nil
	return block ~= nil and tool ~= nil and block.Hardness > 0
end

return Mining
