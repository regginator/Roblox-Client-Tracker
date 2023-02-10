local FriendsLanding = script:FindFirstAncestor("FriendsLanding")
local dependencies = require(FriendsLanding.dependencies)
local Roact = dependencies.Roact
local llama = dependencies.llama
local ProfileQRCode = dependencies.ProfileQRCode

return function(props)
	return Roact.createElement(
		ProfileQRCode.ProfileQRCodeEntryPoint,
		llama.Dictionary.join(props, {
			onClose = function()
				props.navigation.goBack()
			end,
		})
	)
end
