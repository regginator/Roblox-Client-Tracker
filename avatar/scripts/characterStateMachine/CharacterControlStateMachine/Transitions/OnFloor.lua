--[[ OnFloor Transition ]]--
local baseTransition = require(script.Parent.Parent.Parent:WaitForChild("BaseStateMachine"):WaitForChild("BaseTransitionModule"))

local OnFloor = baseTransition:extend()
OnFloor.name = script.Name
OnFloor.destinationName = "Landed"
OnFloor.sourceName = "FreeFall"
OnFloor.priority = 3

function OnFloor:Test(stateMachine)
	local onFloor = stateMachine.context.humanoid.OnFloor -- TODO: Need to check for relative velocity to floor
	if onFloor then
		stateMachine.context.noFloorTimer = 0
	end
	return onFloor
end

return OnFloor