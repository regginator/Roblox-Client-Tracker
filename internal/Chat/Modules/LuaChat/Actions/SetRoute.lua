local CoreGui = game:GetService("CoreGui")

local Modules = CoreGui.RobloxGui.Modules
local Common = Modules.Common
local LuaChat = Modules.LuaChat

local ActionType = require(LuaChat.ActionType)
local Action = require(Common.Action)

return Action(ActionType.SetRoute, function(intent, parameters, popToIntent)
	return {
		intent = intent,
		parameters = parameters or {},
		popToIntent = popToIntent,
	}
end)