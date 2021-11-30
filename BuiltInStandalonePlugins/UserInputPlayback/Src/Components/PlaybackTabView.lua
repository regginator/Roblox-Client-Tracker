--[[
	PlaybackTabView: Contains a FileSelector UI group.
]]

local Plugin = script.Parent.Parent.Parent
local Roact = require(Plugin.Packages.Roact)
local Framework = require(Plugin.Packages.Framework)
local ContextServices = Framework.ContextServices

local UI = Framework.UI
local Pane = UI.Pane

local FileSelectorUIGroup = require(Plugin.Src.Components.FileSelectorUIGroup)
local PlaybackInfoUIGroup = require(Plugin.Src.Components.PlaybackInfoUIGroup)
local FilterSettingsUIGroup = require(Plugin.Src.Components.FilterSettingsUIGroup)

local PlaybackTabView = Roact.PureComponent:extend("PlaybackTabView")

function PlaybackTabView:render()
	local props = self.props
	local style = props.Stylizer

	return Roact.createElement(Pane, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Padding = style.PaddingPx,
		Layout = Enum.FillDirection.Vertical,
		Spacing = UDim.new(0, style.PaddingPx),
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
	}, {
		FileSelector = Roact.createElement(FileSelectorUIGroup, {
			LayoutOrder = 1,
		}),
		PlaybackInfoGroup = Roact.createElement(PlaybackInfoUIGroup, {
			LayoutOrder = 2,
		}),
		FilterSettings = Roact.createElement(FilterSettingsUIGroup, {
			LayoutOrder = 3,
			RoduxStoreContext = "playbackTabFilter",
		}),
	})
end

PlaybackTabView = ContextServices.withContext({
	Stylizer = ContextServices.Stylizer,
})(PlaybackTabView)

return PlaybackTabView