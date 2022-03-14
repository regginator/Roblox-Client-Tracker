local Modules = game:getService("CoreGui").RobloxGui.Modules
local CorePackages = game:GetService("CorePackages")
local HttpService = game:GetService("HttpService")
local Url = require(CorePackages.AppTempCommon.LuaApp.Http.Url)
local ArgCheck = require(CorePackages.ArgCheck)

local GetFFlagSendIsOptedInThroughUpsellParameter = require(Modules.Flags.GetFFlagSendIsOptedInThroughUpsellParameter)

--[[
	Documentation of endpoint:
	https://voice.roblox.com/docs#!/Voice/post_v1_settings_user_opt_in

	Updates whether a user is opted in or out of voice chat. If the user specifically opts in
	to voice chat using the enable voice chat upsell modal, isOptedInThroughUpsell must be set to true.
	Otherwise, isOptedInThroughUpsell isn't required.
]]

return function(requestImpl, isUserOptIn, isOptedInThroughUpsell)
	ArgCheck.isType(isUserOptIn, "boolean", "UserOptIn request expects isUserOptIn to be a boolean")

	local url = string.format("%sv1/settings/user-opt-in/", Url.VOICE_URL)
	local body
	if GetFFlagSendIsOptedInThroughUpsellParameter() and isOptedInThroughUpsell ~= nil then
		ArgCheck.isType(isOptedInThroughUpsell, "boolean", "UserOptIn request expects isOptedInThroughUpsell to be a boolean")
		body = HttpService:JSONEncode({
			isUserOptIn = isUserOptIn,
			isOptedInThroughUpsell = isOptedInThroughUpsell,
		})
	else
		body = HttpService:JSONEncode({
			isUserOptIn = isUserOptIn,
		})
	end
	return requestImpl(url, "POST", { postBody = body })
end
