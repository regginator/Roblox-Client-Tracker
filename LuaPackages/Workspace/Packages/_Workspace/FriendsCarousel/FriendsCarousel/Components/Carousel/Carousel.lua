local FriendsCarousel = script.Parent.Parent.Parent
local dependencies = require(FriendsCarousel.dependencies)
local Roact = dependencies.Roact
local llama = dependencies.llama
local t = dependencies.t
local memoize = dependencies.memoize
local withLocalization = dependencies.withLocalization

local mapStateToProps = require(script.Parent.carouselMapStateToProps)
local mapDispatchToProps = require(script.Parent.carouselMapDispatchToProps)

local UserModel = dependencies.RoduxUsers.Models.User
local PresenceModel = dependencies.RoduxPresence.Models.Presence
local RecommendationModel = dependencies.RoduxFriends.Models.Recommendation

local FindFriendsTile = require(FriendsCarousel.Components.FindFriendsTile)
local FindFriendsHint = require(FriendsCarousel.Components.FindFriendsHint)
local CarouselUserTile = require(FriendsCarousel.Components.CarouselUserTile)
local LoadingTile = require(FriendsCarousel.Components.LoadingTile)

local LocalTypes = require(FriendsCarousel.Common.LocalTypes)
local TextKeys = require(FriendsCarousel.Common.TextKeys)
local UIVariants = require(FriendsCarousel.Common.UIVariants)

local getFFlagFriendsCarouselRemoveVariant = dependencies.getFFlagFriendsCarouselRemoveVariant
local getFFlagFriendsCarouselPassCIBadge = require(FriendsCarousel.Flags.getFFlagFriendsCarouselPassCIBadge)

-- Note: Type information is not retained on lua tables, so the only way to get
-- React _types_ is to require a module that re-exports them
local React = require(game:GetService("CorePackages").Packages.React)

local Carousel = Roact.Component:extend("Carousel")

local TILE_SIZE_SQUARE: number = 100
local TILE_SIZE_CIRCULAR: number = 96

local CARD_PADDING: number = 10

export type Props = {
	carousel: React.ComponentType<any>,
	carouselProps: any,

	-- remove with getFFlagFriendsCarouselRemoveVariant
	friendsCarouselExperimentVariant: string?,

	showToast: (toastMessageKey: string) -> (),
	onSuccessfulRender: () -> ()?,

	userSeen: (user: LocalTypes.User, additionalData: { absolutePosition: number }) -> (),
	onFindFriendsTileActivated: () -> (),
	onUserTileActivated: (
		user: LocalTypes.User,
		isInGame: boolean,
		additionalData: LocalTypes.ContextualMenuData
	) -> (),

	showNewBadge: boolean?,
}

type InternalProps = Props & mapStateToProps.Props & mapDispatchToProps.Props

export type CarouselTilePassedProps = {
	tileInfoHeight: number,
	absoluteIndex: number,
	layoutOrder: number,
	setPeopleListFrozen: (boolean) -> (),
} & { user: LocalTypes.LoadingUser | LocalTypes.User }

Carousel.validateProps = t.strictInterface({
	carousel = t.interface({
		render = t.callback,
	}),
	carouselProps = t.table,
	friendsAndRecList = t.array(
		t.union(
			RecommendationModel.isValid,
			PresenceModel.isValid,
			UserModel.isValid,
			t.interface({
				isLoading = t.boolean,
			})
		)
	),
	friendCount = t.number,
	fetchingStatus = t.string,
	friendRequestCount = t.number,
	onFindFriendsTileActivated = t.callback,
	showToast = t.callback,
	onUserTileActivated = t.callback,
	userSeen = t.callback,
	onSuccessfulRender = t.optional(t.callback),
	friendsCarouselExperimentVariant = if getFFlagFriendsCarouselRemoveVariant() then nil else t.string,
	showNewBadge = t.optional(t.boolean),
})

Carousel.defaultProps = {
	friendsCarouselExperimentVariant = if getFFlagFriendsCarouselRemoveVariant()
		then nil
		else UIVariants.CIRCULAR_TILES,
}

function Carousel:init()
	self.renderFindFriendsTile = function(): any
		local props: InternalProps = self.props
		local tileUIProperties = self.getTileUIProperties()

		if getFFlagFriendsCarouselPassCIBadge() then
			return withLocalization({
				newTextBadge = TextKeys.NewText,
			})(function(localized)
				return Roact.createElement(FindFriendsTile, {
					friendsCarouselExperimentVariant = if getFFlagFriendsCarouselRemoveVariant()
						then nil
						else props.friendsCarouselExperimentVariant,
					onActivated = props.onFindFriendsTileActivated,
					badgeValue = if getFFlagFriendsCarouselPassCIBadge() and props.showNewBadge
						then localized.newTextBadge
						else props.friendRequestCount,
					tileSize = tileUIProperties.tileHeight,
					onDidMount = props.onSuccessfulRender,
				})
			end)
		else
			return Roact.createElement(FindFriendsTile, {
				friendsCarouselExperimentVariant = if getFFlagFriendsCarouselRemoveVariant()
					then nil
					else props.friendsCarouselExperimentVariant,
				onActivated = props.onFindFriendsTileActivated,
				badgeValue = props.friendRequestCount,
				tileSize = tileUIProperties.tileHeight,
				onDidMount = props.onSuccessfulRender,
			})
		end
	end

	self.renderFindFriendsHint = function(passedProps: FindFriendsHint.Props)
		local tileUIProperties = self.getTileUIProperties()

		return Roact.createElement(FindFriendsHint, {
			layoutOrder = passedProps.layoutOrder,
			tileHeight = tileUIProperties.tileHeight,
		})
	end

	self.renderUserTile = function(passedProps: CarouselTilePassedProps)
		local props: InternalProps = self.props
		local tileUIProperties = self.getTileUIProperties()

		local user: LocalTypes.LoadingUser = passedProps.user :: any
		if user.isLoading then
			local loadingTilePassedProps: LoadingTile.Props = {
				friendsCarouselExperimentVariant = if getFFlagFriendsCarouselRemoveVariant()
					then nil
					else props.friendsCarouselExperimentVariant,
				layoutOrder = passedProps.layoutOrder,
				tileSize = tileUIProperties.tileHeight,
				tileInfoHeight = passedProps.tileInfoHeight,
			} :: any

			return Roact.createElement(LoadingTile, loadingTilePassedProps)
		end

		local userTilePassedProps: CarouselUserTile.Props = llama.Dictionary.join(passedProps, {
			friendsCarouselExperimentVariant = if getFFlagFriendsCarouselRemoveVariant()
				then nil
				else props.friendsCarouselExperimentVariant,
			tileSize = tileUIProperties.tileHeight,
			contextualInfoLines = tileUIProperties.maxContextualLines,
			tileInfoHeight = passedProps.tileInfoHeight,
			onActivated = props.onUserTileActivated,
			showToast = props.showToast,
			userSeen = props.userSeen,
		}) :: any

		return Roact.createElement(CarouselUserTile, userTilePassedProps)
	end

	self.getTileUIProperties = memoize(function()
		local props: InternalProps = self.props

		if getFFlagFriendsCarouselRemoveVariant() then
			return { tileHeight = TILE_SIZE_CIRCULAR }
		end

		return {
			tileHeight = if props.friendsCarouselExperimentVariant == UIVariants.SQUARE_TILES
				then TILE_SIZE_SQUARE
				else TILE_SIZE_CIRCULAR,
		}
	end)
end

function Carousel:render()
	local props: InternalProps = self.props
	local tileUIProperties = self.getTileUIProperties()

	return Roact.createElement(
		props.carousel,
		llama.Dictionary.join(props.carouselProps, {
			friendCount = props.friendCount,
			friends = props.friendsAndRecList,

			renderFindFriendsTile = self.renderFindFriendsTile,
			renderFindFriendsHint = self.renderFindFriendsHint,
			renderUserTile = self.renderUserTile,

			friendThumbnailSize = tileUIProperties.tileHeight,
			cardPadding = CARD_PADDING,
		})
	)
end

return Carousel
