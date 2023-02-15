local getFFlagAddFriendsNewEmptyStateAndBanners = require(script.Parent.getFFlagAddFriendsNewEmptyStateAndBanners)

game:DefineFastFlag("AddFriendsQRCodeAnalytics", false)

return function()
	return getFFlagAddFriendsNewEmptyStateAndBanners() and game:GetFastFlag("AddFriendsQRCodeAnalytics")
end
