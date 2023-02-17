--!nonstrict
local FriendsLanding = script:FindFirstAncestor("FriendsLanding")
local dependencies = require(FriendsLanding.dependencies)
local Roact = dependencies.Roact
local RoactNavigation = dependencies.RoactNavigation
local FriendsLandingScreen = require(FriendsLanding.Components.FriendsLandingScreen)
local AddFriendsScreen = require(FriendsLanding.Components.AddFriends.AddFriendsScreen)
local FriendsLandingScreenNavigationOptions = require(FriendsLanding.Components.FriendsLandingScreen.NavigationOptions)
local FriendsLandingContext = require(FriendsLanding.FriendsLandingContext)
local EnumScreens = require(FriendsLanding.EnumScreens)
local PlayerSearchWrapper = require(FriendsLanding.Navigator.PlayerSearchWrapper)
local HeaderBarCenterView = require(FriendsLanding.Components.HeaderBarCenterView)
local HeaderBarRightView = require(FriendsLanding.Components.HeaderBarRightView)
local GatewayComponent = require(FriendsLanding.Navigator.GatewayComponent)
local llama = dependencies.llama

local getFFlagAddFriendsFixSocialTabSearchbar = require(FriendsLanding.Flags.getFFlagAddFriendsFixSocialTabSearchbar)
local getFFlagAddFriendsSearchbarIXPEnabled = dependencies.getFFlagAddFriendsSearchbarIXPEnabled

local MainStackNavigator = RoactNavigation.createRobloxStackNavigator({
	{
		[EnumScreens.Gateway] = {
			screen = GatewayComponent,
			navigationOptions = {
				headerText = {},
			},
		},
	},
	{
		[EnumScreens.FriendsLanding] = {
			screen = FriendsLandingScreen,
			navigationOptions = FriendsLandingScreenNavigationOptions,
		},
	},
	{
		[EnumScreens.AddFriends] = {
			screen = AddFriendsScreen,
			navigationOptions = function(navProps)
				return {
					headerText = {
						raw = "Feature.Chat.Label.AddFriends",
					},
					renderCenter = if getFFlagAddFriendsFixSocialTabSearchbar()
						then function()
							return Roact.createElement(HeaderBarCenterView, navProps)
						end
						elseif getFFlagAddFriendsSearchbarIXPEnabled() then function()
							return FriendsLandingContext.with(function(context)
								return Roact.createElement(
									HeaderBarCenterView,
									llama.Dictionary.join(navProps, {
										shouldRenderSearchbarButtonInWideMode = if context.addFriendsPageSearchbarEnabled
											then true
											else nil,
									})
								)
							end)
						end
						else function()
							return Roact.createElement(HeaderBarCenterView, navProps)
						end,
					renderRight = if getFFlagAddFriendsSearchbarIXPEnabled()
						then function()
							return FriendsLandingContext.with(function(context)
								if context.addFriendsPageSearchbarEnabled then
									return false
								else
									return Roact.createElement(HeaderBarRightView, navProps)
								end
							end)
						end
						else function()
							return Roact.createElement(HeaderBarRightView, navProps)
						end,
					useSecondaryHeader = if getFFlagAddFriendsSearchbarIXPEnabled()
						then function()
							return FriendsLandingContext.with(function(context)
								if context.addFriendsPageSearchbarEnabled then
									return true
								else
									return nil
								end
							end)
						end
						else function()
							return nil
						end,
					shouldRenderSearchbarButtonInWideMode = if getFFlagAddFriendsSearchbarIXPEnabled()
						then function()
							return FriendsLandingContext.with(function(context)
								if context.addFriendsPageSearchbarEnabled then
									return true
								else
									return nil
								end
							end)
						end
						else function()
							return nil
						end,
				}
			end,
		},
	},
	{
		[EnumScreens.SearchFriends] = {
			screen = function(navProps)
				return Roact.createElement(PlayerSearchWrapper, {
					navigation = navProps.navigation,
				})
			end,
			navigationOptions = function(navProps)
				return {
					headerText = {
						raw = if getFFlagAddFriendsSearchbarIXPEnabled()
							then "Feature.AddFriends.Label.InputPlaceholder.SearchForPeople"
							else "Feature.Friends.Label.SearchFriends",
					},
					tabBarVisible = false,
					renderCenter = function()
						return Roact.createElement(HeaderBarCenterView, navProps)
					end,
					renderRight = function()
						return Roact.createElement(HeaderBarRightView, navProps)
					end,
					useSecondaryHeader = if getFFlagAddFriendsSearchbarIXPEnabled()
						then function()
							return FriendsLandingContext.with(function(context)
								if context.addFriendsPageSearchbarEnabled then
									return true
								else
									return nil
								end
							end)
						end
						else function()
							return nil
						end,
				}
			end,
		},
	},
})

return MainStackNavigator
