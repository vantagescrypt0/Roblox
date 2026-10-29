--!strict
-- Lets long builds (the worlds, Town) pause for a frame now and then, so a big world never
-- trips the server's script timeout and the server keeps running while it builds. Wrap the
-- build in Pace.Begin() / Pace.Finish() and call Pace.Step() inside long loops; it only
-- yields during a build, and only when a tenth of a second has gone by. (Outside a build,
-- e.g. an island redrawn while players play, it never yields.)

local Pace = {}

local building = false
local last = os.clock()

function Pace.Begin()
	building = true
	last = os.clock()
end

function Pace.Finish()
	building = false
end

function Pace.Step()
	if building and os.clock() - last > 0.1 then
		task.wait()
		last = os.clock()
	end
end

return Pace
