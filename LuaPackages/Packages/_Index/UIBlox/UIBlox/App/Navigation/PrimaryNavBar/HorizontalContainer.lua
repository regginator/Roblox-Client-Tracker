local Navigation = script.Parent.Parent
local App = Navigation.Parent
local UIBlox = App.Parent
local Packages = UIBlox.Parent

-- Packages
local Roact = require(Packages.Roact)
local LuauPolyfill = require(Packages.LuauPolyfill)
local Object = LuauPolyfill.Object

-- UIBlox Core
local useStyle = require(UIBlox.Core.Style.useStyle)
local ControlState = require(UIBlox.Core.Control.Enum.ControlState)

-- Constants
local Constants = require(script.Parent.Constants)

-- Types
local Types = require(script.Parent.Types)
type Props = Types.HorizontalContainerProps

return function(extraProps: Props, children: { [any]: Instance })
	local style = useStyle()
	return Roact.createElement("Frame", {
		Size = if extraProps.size then extraProps.size else UDim2.new(1, 0, 1, 0),
		AutomaticSize = extraProps.automaticSize,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
	}, {
		RoundedBackgroundWithTopAlignedToContent = if extraProps.showRoundedBackground
			then Roact.createElement("Frame", {
				Size = extraProps.roundedBackgroundHeight and UDim2.new(1, 0, 0, extraProps.roundedBackgroundHeight)
					or UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = Constants.ICON_TAB_SELECTED_TRANSPARENCY,
				BackgroundColor3 = extraProps.backgroundColor3 or style.Theme.BackgroundUIDefault.Color,
				Position = UDim2.fromOffset(
					0,
					if extraProps.padding and extraProps.padding.top then extraProps.padding.top else 0
				),
				ZIndex = 1,
			}, {
				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, extraProps.roundCornerRadius),
				}),
			})
			else nil,
		Overlay = if extraProps.showOverlay
			then Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = style.Theme.BackgroundUIDefault.Color,
				BackgroundTransparency = Constants.ICON_TAB_PRESSED_TRANSPARENCY,
				ZIndex = 3,
			}, {
				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, extraProps.roundCornerRadius),
				}),
			})
			else nil,
		Content = Roact.createElement(
			"Frame",
			{
				Size = if extraProps.size then extraProps.size else UDim2.new(1, 0, 1, 0),
				AutomaticSize = extraProps.automaticSize,
				BackgroundTransparency = 1,
				LayoutOrder = 2,
				ZIndex = 2,
			},
			Object.assign({}, {
				Layout = Roact.createElement(
					"UIListLayout",
					Object.assign({}, {
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, extraProps.spacing or 0),
					})
				),
				Padding = if extraProps.padding
					then Roact.createElement("UIPadding", {
						PaddingLeft = UDim.new(0, extraProps.padding.left or 0),
						PaddingRight = UDim.new(0, extraProps.padding.right or 0),
						PaddingTop = UDim.new(0, extraProps.padding.top or 0),
						PaddingBottom = UDim.new(0, extraProps.padding.bottom or 0),
					})
					else nil,
			}, children)
		),
	})
end
