local FriendsCarousel = script:FindFirstAncestor("FriendsCarousel")
local dependencies = require(FriendsCarousel.dependencies)
local RoduxPresence = dependencies.RoduxPresence
local EnumPresenceType = RoduxPresence.Enums.PresenceType
local RecommendationContextType = dependencies.RoduxFriends.Enums.RecommendationContextType
local LocalTypes = require(FriendsCarousel.Common.LocalTypes)

local getFFlagFriendsCarouselIncomingFriendRequest =
	require(FriendsCarousel.Flags.getFFlagFriendsCarouselIncomingFriendRequest)

local mockedUsers: { [string]: LocalTypes.User } = {
	friendOnline = {
		id = "2326285850",
		username = "username",
		displayName = "name",
		userId = "friendOnline",
		userPresenceType = EnumPresenceType.Online,
		isFriendWithUser = true,
		hasPendingFriendRequest = false,
		canSendFriendRequest = false,
	},
	friendOffline = {
		id = "2326285850",
		username = "username",
		displayName = "friendOffline displayName",
		userId = "friendOffline",
		userPresenceType = EnumPresenceType.Offline,
		isFriendWithUser = true,
		hasPendingFriendRequest = false,
		canSendFriendRequest = false,
	},
	friendInGame = {
		id = "2326285850",
		username = "username",
		displayName = "friendInGame displayName",
		userId = "friendInGame",
		lastOnline = "lastOnline",
		lastLocation = "last Location very long name name name",
		universeId = "universeId",
		rootPlaceId = "rootPlaceId",
		placeId = "placeId",
		gameId = "gameId",
		userPresenceType = EnumPresenceType.InGame,
		isFriendWithUser = true,
		hasPendingFriendRequest = false,
		canSendFriendRequest = false,
	},
	friendInGameWithoutLocation = {
		id = "2326285850",
		username = "username",
		displayName = "friendInGameWithoutLocation displayName",
		userId = "friendInGameWithoutLocation",
		lastOnline = "lastOnline",
		lastLocation = nil,
		universeId = "universeId",
		rootPlaceId = "rootPlaceId",
		placeId = "placeId",
		gameId = "gameId",
		userPresenceType = EnumPresenceType.InGame,
		isFriendWithUser = true,
		hasPendingFriendRequest = false,
		canSendFriendRequest = false,
	},
	friendInStudio = {
		id = "2326285850",
		username = "username",
		displayName = "friendInStudio displayName",
		userId = "friendInStudio",
		userPresenceType = EnumPresenceType.InStudio,
		isFriendWithUser = true,
		hasPendingFriendRequest = false,
		canSendFriendRequest = false,
		lastLocation = "In Studio location",
	},
	recommendationMutual = {
		id = "2326285850",
		username = "username",
		displayName = "recommendationMutual displayName",
		mutualFriendsList = { "1", "2", "3", "4" },
		contextType = RecommendationContextType.MutualFriends,
		rank = 1,
		isFriendWithUser = false,
		hasPendingFriendRequest = false,
		canSendFriendRequest = true,
	},
	recommendationMutualSingle = {
		id = "2326285850",
		username = "username",
		displayName = "recommendationMutual displayName",
		mutualFriendsList = { "1" },
		contextType = RecommendationContextType.MutualFriends,
		rank = 1,
		isFriendWithUser = false,
		hasPendingFriendRequest = false,
		canSendFriendRequest = true,
	},
	recommendationMutualNone = {
		id = "2326285850",
		username = "username",
		displayName = "recommendationMutualNone displayName",
		mutualFriendsList = {},
		contextType = RecommendationContextType.MutualFriends,
		rank = 1,
		isFriendWithUser = false,
		hasPendingFriendRequest = false,
		canSendFriendRequest = true,
	},
	recommendationNone = {
		id = "2326285850",
		username = "username2",
		displayName = "recommendationNone displayName",
		mutualFriendsList = {},
		contextType = RecommendationContextType.None,
		rank = 1,
		isFriendWithUser = false,
		hasPendingFriendRequest = false,
		canSendFriendRequest = true,
	},
	requestPending = {
		id = "2326285850",
		username = "username",
		displayName = "requestPending displayName",
		mutualFriendsList = { "1" },
		contextType = RecommendationContextType.MutualFriends,
		rank = 0,
		isFriendWithUser = false,
		hasPendingFriendRequest = true,
		canSendFriendRequest = false,
	},
	recommendationFrequent = {
		id = "2326285850",
		username = "username",
		displayName = "recommendationFrequent displayName",
		mutualFriendsList = {},
		contextType = RecommendationContextType.Frequents,
		rank = 1,
		isFriendWithUser = false,
		hasPendingFriendRequest = false,
		canSendFriendRequest = true,
	},
} :: any

if getFFlagFriendsCarouselIncomingFriendRequest() then
	mockedUsers.recommendationIncomingFriendRequest = {
		id = "2326285850",
		username = "username",
		displayName = "recommendationIncomingFriendRequest displayName",
		mutualFriendsList = { "1" },
		contextType = RecommendationContextType.MutualFriends,
		rank = 1,
		isFriendWithUser = false,
		hasPendingFriendRequest = false,
		canSendFriendRequest = false,
		hasIncomingFriendRequest = true,
	}
end

return mockedUsers
