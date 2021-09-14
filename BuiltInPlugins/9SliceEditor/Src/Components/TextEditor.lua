--[[
	Contains the TextInputs half of the 9SliceEditor
	Creates TextLabels for Offsets, Left, Right, Top, Bottom text
	Creates four TextOffset components for Left, Right, Top, Bottom

	Props:
		pixelDimensions (Vector2) -- dimensions of the image in pixels
		sliceRect -- current SliceCenter ordered in { X0, X1, Y0, Y1 } format
		setSliceRect -- callback to change sliceRect in SliceEditor
]]

local Plugin = script.Parent.Parent.Parent
local Roact = require(Plugin.Packages.Roact)
local Framework = require(Plugin.Packages.Framework)
local TextOffset = require(Plugin.Src.Components.TextOffset)
local Constants = require(Plugin.Src.Util.Constants)
local Orientation = require(Plugin.Src.Util.Orientation)

local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext
local Analytics = ContextServices.Analytics
local Localization = ContextServices.Localization

local UI = Framework.UI
local Pane = UI.Pane
local TextLabel = UI.Decoration.TextLabel

local TextEditor = Roact.PureComponent:extend("TextEditor")

local LEFT = Orientation.Left.rawValue()
local RIGHT = Orientation.Right.rawValue()
local TOP = Orientation.Top.rawValue()
local BOTTOM = Orientation.Bottom.rawValue()

function TextEditor:createLabel(orientation)
	-- helper function to create TextLabels for  Left, Right, Top, Bottom
	local localization = self.props.Localization
	local labelPosition, labelText

	if orientation == LEFT then
		labelPosition = Constants.LEFTLABEL_YPOSITION
		labelText = localization:getText("TextEditor", "Left")
	elseif orientation == RIGHT then
		labelPosition = Constants.RIGHTLABEL_YPOSITION
		labelText = localization:getText("TextEditor", "Right")
	elseif orientation == TOP then
		labelPosition = Constants.TOPLABEL_YPOSITION
		labelText = localization:getText("TextEditor", "Top")
	elseif orientation == BOTTOM then
		labelPosition = Constants.BOTTOMLABEL_YPOSITION
		labelText = localization:getText("TextEditor", "Bottom")
	end

	return Roact.createElement(TextLabel, {
		Position = UDim2.fromOffset(0, labelPosition),
		Text = labelText,
		TextSize = Constants.TEXTSIZE,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
end

function TextEditor:createOffset(orientation)
	-- helper function to create TextOffsets
	local props = self.props

	return Roact.createElement(TextOffset, {
		orientation = orientation,
		sliceRect = props.sliceRect,
		setSliceRect = props.setSliceRect,
		pixelDimensions = props.pixelDimensions,
	})
end

function TextEditor:render()
	-- Renders the TextEditor as a pane with labels for offsets and four text boxes
	local props = self.props
	local localization = props.Localization

	return Roact.createElement(Pane, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(Constants.TEXTEDITOR_XOFFSET, Constants.TEXTEDITOR_YOFFSET),
		Size = UDim2.fromOffset(Constants.TEXTEDITOR_XSIZE, Constants.TEXTEDITOR_YSIZE),
	}, {
		OffsetLabel = Roact.createElement(TextLabel, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0),
			Text = localization:getText("TextEditor", "Offsets"),
			TextSize = Constants.TEXTSIZE,
			TextXAlignment = Enum.TextXAlignment.Center,
		}),
		LeftInput = self:createOffset(LEFT),
		RightInput = self:createOffset(RIGHT),
		TopInput = self:createOffset(TOP),
		BottomInput = self:createOffset(BOTTOM),

		LeftText = self:createLabel(LEFT),
		RightText = self:createLabel(RIGHT),
		TopText = self:createLabel(TOP),
		BottomText = self:createLabel(BOTTOM),
	})
end

TextEditor = withContext({
	Analytics = Analytics,
	Localization = Localization,
	Stylizer = ContextServices.Stylizer,
})(TextEditor)

return TextEditor
