--[[ Upright Transition ]]--
local baseTransition = require(script.Parent.Parent.Parent:WaitForChild("BaseStateMachine"):WaitForChild("BaseTransitionModule"))

local Upright = baseTransition:extend()
Upright.name = script.Name
Upright.destinationName = "Running"
Upright.sourceName = "GettingUp"
Upright.priority = 3
Upright.upAngle = 0.90

function Upright:Test(stateMachine)
	local rootPart = stateMachine.context.humanoid.Parent.PrimaryPart
	if rootPart then
		local upVec = rootPart.CFrame.upVector		
		return upVec.y > Upright.upAngle
	else
		return true
	end	
end

return Upright