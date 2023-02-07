local VirtualEvents = script:FindFirstAncestor("VirtualEvents")

local Cryo = require(VirtualEvents.Parent.Cryo)
local React = require(VirtualEvents.Parent.React)
local UIBlox = require(VirtualEvents.Parent.UIBlox)
local useDispatch = require(VirtualEvents.Parent.RoactUtils).Hooks.RoactRodux.useDispatch
local getEventTimerStatus = require(VirtualEvents.Common.getEventTimerStatus)
local findFirstImageInMedia = require(VirtualEvents.Common.findFirstImageInMedia)
local getGalleryItems = require(VirtualEvents.Common.getGalleryItems)
local useVirtualEventMedia = require(VirtualEvents.Hooks.useVirtualEventMedia)
local useExperienceDetails = require(VirtualEvents.Hooks.useExperienceDetails)
local useActionBarProps = require(VirtualEvents.Hooks.useActionBarProps)
local EventTimer = require(VirtualEvents.Components.EventTimer)
local EventDescription = require(VirtualEvents.Components.EventDescription)
local EventHostedBy = require(VirtualEvents.Components.EventHostedBy)
local Attendance = require(VirtualEvents.Components.Attendance)
local network = require(VirtualEvents.network)
local types = require(VirtualEvents.types)
local getFFlagHorizontalMediaOnEventDetailsPage =
	require(VirtualEvents.Parent.SharedFlags).getFFlagHorizontalMediaOnEventDetailsPage

local DetailsPageTemplate = UIBlox.App.Template.DetailsPage.DetailsPageTemplate
local ContentPositionEnum = UIBlox.App.Template.DetailsPage.Enum.ContentPosition
local MediaGalleryPreview = UIBlox.App.Container.MediaGalleryPreview
local MediaGalleryHorizontal = UIBlox.App.Container.MediaGalleryHorizontal
local ListTable = UIBlox.App.Table.ListTable
local noop = function() end

local THUMBNAILS_COUNT = 5

-- These get used by EventDetailsPageLoader so it can pass down all the same props
export type BaseProps = {
	currentTime: DateTime,
	onClose: (() -> ())?,
	onJoinEvent: (() -> ())?,
	onRsvpChanged: ((newRsvpStatus: types.RsvpStatus) -> ())?,
	onExperienceTileActivated: (() -> ())?,
	onHostActivated: ((host: types.Host) -> ())?,
	onShare: (() -> ())?,
}

export type Props = BaseProps & {
	virtualEvent: types.VirtualEvent,
}

local defaultProps = {
	onClose = noop,
	onJoinEvent = noop,
	onShare = noop,
}

type InternalProps = typeof(defaultProps) & Props

local function EventDetailsPage(props: Props)
	local joinedProps: InternalProps = Cryo.Dictionary.join(defaultProps, props)
	local dispatch = useDispatch()
	local media = useVirtualEventMedia(joinedProps.virtualEvent)
	local experienceDetails = useExperienceDetails(joinedProps.virtualEvent.universeId)
	local firstImage = if media then findFirstImageInMedia(media) else nil

	local galleryHeight, setGalleryHeight = React.useState(0)

	local galleryItems = React.useMemo(function()
		return getGalleryItems(media)
	end, { media })

	local eventStatus = (
		React.useMemo(function()
			return getEventTimerStatus(joinedProps.virtualEvent, joinedProps.currentTime)
		end, { joinedProps.virtualEvent, joinedProps.currentTime } :: { any })
	) :: any

	local onSizeChanged = React.useCallback(function(container: Frame)
		local containerWidth = container.AbsoluteSize.X
		local gallerySizes = MediaGalleryPreview:calcSizesFromWidth(containerWidth, THUMBNAILS_COUNT)
		local contentHeight = gallerySizes.contentSize.Y.Offset
		if contentHeight ~= galleryHeight then
			setGalleryHeight(contentHeight)
		end
	end, { galleryHeight })

	local onRsvpChanged = React.useCallback(function()
		local newRsvpStatus: types.RsvpStatus
		if joinedProps.virtualEvent.userRsvpStatus ~= "going" then
			newRsvpStatus = "going"
		else
			newRsvpStatus = "notGoing"
		end

		if joinedProps.onRsvpChanged then
			joinedProps.onRsvpChanged(newRsvpStatus)
		end

		dispatch(network.NetworkingVirtualEvents.UpdateMyRsvpStatus.API(joinedProps.virtualEvent.id, newRsvpStatus))
	end, { joinedProps.virtualEvent })

	local actionBarProps = useActionBarProps(joinedProps.virtualEvent, eventStatus, {
		onClose = joinedProps.onClose,
		onJoinEvent = joinedProps.onJoinEvent,
		onShare = joinedProps.onShare,
		onRsvpChanged = onRsvpChanged,
	})

	local shouldShowActionBar = React.useMemo(function()
		return actionBarProps.button or #actionBarProps.icons > 0
	end, { actionBarProps })

	local componentList = {
		Attendance = if eventStatus ~= "Elapsed"
			then {
				portraitLayoutOrder = 1,
				landscapePosition = ContentPositionEnum.Left,
				landscapeLayoutOrder = 1,
				renderComponent = function()
					return React.createElement(Attendance, {
						virtualEvent = joinedProps.virtualEvent,
						eventStatus = eventStatus,
					})
				end,
			}
			else nil,
		MediaGallery = {
			portraitLayoutOrder = 2,
			landscapePosition = ContentPositionEnum.Right,
			landscapeLayoutOrder = 1,
			renderComponent = function()
				if getFFlagHorizontalMediaOnEventDetailsPage() then
					return React.createElement(MediaGalleryHorizontal, {
						items = galleryItems,
					})
				else
					return React.createElement("Frame", {
						Size = UDim2.new(1, 0, 0, galleryHeight),
						BackgroundTransparency = 1,
						[React.Change.AbsoluteSize] = onSizeChanged,
					}, {
						Gallery = React.createElement(MediaGalleryPreview, {
							items = galleryItems,
							numberOfThumbnails = THUMBNAILS_COUNT,
						}),
					})
				end
			end,
		},
		Description = {
			portraitLayoutOrder = 3,
			landscapePosition = ContentPositionEnum.Left,
			landscapeLayoutOrder = 2,
			renderComponent = function()
				return React.createElement(EventDescription, {
					description = joinedProps.virtualEvent.description,
					experienceName = if experienceDetails then experienceDetails.name else nil,
					experienceThumbnail = firstImage,
					onExperienceTileActivated = joinedProps.onExperienceTileActivated,
				})
			end,
		},
		EventInfo = {
			portraitLayoutOrder = 4,
			landscapePosition = ContentPositionEnum.Right,
			landscapeLayoutOrder = 2,
			renderComponent = function()
				return React.createElement(ListTable, {
					cells = {
						React.createElement(EventHostedBy, {
							host = joinedProps.virtualEvent.host,
							onActivated = joinedProps.onHostActivated,
						}),
					},
				})
			end,
		},
	}

	return React.createElement(DetailsPageTemplate, {
		isMobile = true, -- TODO: EN-1467 Setup breakpoints for mobile and desktop
		titleText = joinedProps.virtualEvent.title,
		thumbnailImageUrl = firstImage,
		thumbnailAspectRatio = Vector2.new(16, 9),
		renderInfoContent = function()
			return React.createElement(EventTimer, {
				virtualEvent = joinedProps.virtualEvent,
				status = eventStatus,
				currentTime = joinedProps.currentTime,
			})
		end,
		actionBarProps = if shouldShowActionBar then actionBarProps else nil,
		componentList = if props.virtualEvent.eventStatus ~= "cancelled" then componentList else {},
		onClose = joinedProps.onClose,
	})
end

return EventDetailsPage
