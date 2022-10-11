--[[
	Main frame containing Preview components

	Required Props:
		UDim2 Size: size of the frame
		table UserAddedAssets: the table of assets added by the user
		callback UpdateUserAddedAssets: function called when user added assets are changed

	Optional Props:
		Stylizer Stylizer: A Stylizer ContextItem, which is provided via withContext.
		number LayoutOrder: render order of component in layout
]]

local Plugin = script.Parent.Parent.Parent
local Roact = require(Plugin.Packages.Roact)
local RoactRodux = require(Plugin.Packages.RoactRodux)
local Cryo = require(Plugin.Packages.Cryo)
local AvatarToolsShared = require(Plugin.Packages.AvatarToolsShared)

local FFlagEnablePreviewDockWidget = require(Plugin.Src.Flags.GetFFlagEnablePreviewDockWidget)()

local AccessoryAndBodyToolSharedUtil = AvatarToolsShared.Util.AccessoryAndBodyToolShared
local PreviewConstantsInterface = AccessoryAndBodyToolSharedUtil.PreviewConstantsInterface

local Components = AvatarToolsShared.Components
local AnimationPlaybackSlider = Components.AnimationPlaybackSlider
local PreviewDockWidget = Components.PreviewDockWidget
local PreviewCategoryList = Components.PreviewCategoryList

local Framework = require(Plugin.Packages.Framework)
local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext
local Util = Framework.Util
local LayoutOrderIterator = Util.LayoutOrderIterator
local Typecheck = Util.Typecheck

local UI = Framework.UI
local Pane = UI.Pane

local PreviewTabsRibbon = require(Plugin.Src.Components.Preview.PreviewTabsRibbon)
local Grid = require(Plugin.Src.Components.Preview.Grid)
local PreviewTopBarWrapper = require(Plugin.Src.Components.Preview.PreviewTopBarWrapper)

local SetSelectedTab = require(Plugin.Src.Actions.SelectPreviewTab)
local SetCategoryFilter = require(Plugin.Src.Actions.SetCategoryFilter)
local SetSliderPlayhead = require(Plugin.Src.Actions.SetSliderPlayhead)
local SetIsPlaying = require(Plugin.Src.Actions.SetIsPlaying)
local SetPlayhead = require(Plugin.Src.Actions.SetPlayhead)
local SetTrackLength = require(Plugin.Src.Actions.SetTrackLength)
local PreviewingInfo = AccessoryAndBodyToolSharedUtil.PreviewingInfo

local PreviewFrame = Roact.PureComponent:extend("PreviewFrame")
Typecheck.wrap(PreviewFrame, script)

function PreviewFrame:init()
	self.state = {
		gridHeightOffset = 0,
	}

	self.previewFrameRef = Roact.createRef()

	self.onCategoryChanged = function(tabKey, categoryFilter)
		categoryFilter = if categoryFilter then categoryFilter else ""
		tabKey = if tabKey then tabKey else ""
		self.props.SetSelectedTab(tabKey)
		self.props.SetCategoryFilter(categoryFilter)
	end

	self.onAbsoluteSizeChanged = function(rbx)
		local props = self.props
		local theme = props.Stylizer
		local topBarHeight = rbx.PreviewTopBar.AbsoluteSize.Y
		self:setState({
			gridHeightOffset = topBarHeight + (2 * theme.MainPadding) + theme.SliderHeight
		})
	end
end

function PreviewFrame:render()
	local props = self.props
	local state = self.state

	local size = props.Size
	local layoutOrder = props.LayoutOrder
	local theme = props.Stylizer
	local userAddedAssets = props.UserAddedAssets
	local selectedTab = props.SelectedTab
	local isPlaying = props.IsPlaying
	local playhead = props.Playhead
	local trackLength = props.TrackLength
	local setIsPlaying = props.SetIsPlaying
	local setSliderPlayhead = props.SetSliderPlayhead

	local gridHeightOffset = state.gridHeightOffset

	local orderIterator = LayoutOrderIterator.new()

	-- Slider in SelectionControls does not drag if it is below a scrolling frame. Workaround
	-- is to set ZIndex to something higher.
	local zIndex = 1
	if self.previewFrameRef.current then
		zIndex = self.previewFrameRef.current.GridContainer.Grid.ZIndex + 1
	end

	return Roact.createElement("Frame", {
		BackgroundColor3 = theme.BackgroundColor,
		BorderSizePixel = 0,
		Size = size,
		LayoutOrder = layoutOrder,

		[Roact.Ref] = self.previewFrameRef,
		[Roact.Change.AbsoluteSize] = self.onAbsoluteSizeChanged,
	}, {
		UIListLayout = Roact.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, theme.MainPadding),
		}),
		PreviewTopBar = Roact.createElement(PreviewTopBarWrapper, {
			LayoutOrder = orderIterator:getNextOrder(),
		}),
		GridContainer = Roact.createElement(Pane, {
			Size = UDim2.new(1, 0, 1, -gridHeightOffset),
			Layout = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			LayoutOrder = orderIterator:getNextOrder(),
		}, {
			CategoryList = Roact.createElement(PreviewCategoryList, {
				LayoutOrder = orderIterator:getNextOrder(),
				OnCategoryChanged = self.onCategoryChanged,
			}),
			Grid = Roact.createElement(Grid, {
				layoutOrder = orderIterator:getNextOrder(),
				UpdateUserAddedAssets = props.UpdateUserAddedAssets,
				UserAddedAssets = userAddedAssets
			}),
		}),
		AnimPlaybackSliderContainer = PreviewConstantsInterface.shouldTabShowPlaybackSlider(selectedTab) and Roact.createElement(Pane, {
			Size = UDim2.new(1, -theme.MainPadding, 0, theme.SliderHeight),
			LayoutOrder = orderIterator:getNextOrder(),
		},{
			AnimPlaybackSlider =  Roact.createElement(AnimationPlaybackSlider, {
				IsPlaying = isPlaying,
				Playhead = playhead,
				OnSliderPlayheadChanged = setSliderPlayhead,
				OnPlayPauseClicked = setIsPlaying,
				Size = UDim2.new(1, 0, 0, theme.SliderHeight),
				TrackLength = trackLength,
			}),
		}),
	})
end

PreviewFrame = withContext({
	Stylizer = ContextServices.Stylizer,
})(PreviewFrame)

local function mapStateToProps(state, props)
	local previewStatus = state.previewStatus
	local animation = state.animation

	return {
		SelectedTab = previewStatus.selectedTab,
		AnimationId = PreviewingInfo.getPreviewingAnimationId(state),
		IsPlaying = animation.IsPlaying,
		Playhead = animation.Playhead,
		TrackLength = animation.TrackLength,
		SliderPlayhead = animation.SliderPlayhead,
	}
end

local function mapDispatchToProps(dispatch)
	return {
		SetSelectedTab = function(tab)
			dispatch(SetSelectedTab(tab))
		end,
		SetCategoryFilter = function(filter)
			dispatch(SetCategoryFilter(filter))
		end,
		SetIsPlaying = function(isPlaying)
			dispatch(SetIsPlaying(isPlaying))
		end,
		SetSliderPlayhead = function(sliderPlayhead)
			dispatch(SetSliderPlayhead(sliderPlayhead))
		end,
		SetPlayhead = function(playhead)
			dispatch(SetPlayhead(playhead))
		end,
		SetTrackLength = function(track)
			dispatch(SetTrackLength(track))
		end,
	}
end

return RoactRodux.connect(mapStateToProps, mapDispatchToProps)(PreviewFrame)
