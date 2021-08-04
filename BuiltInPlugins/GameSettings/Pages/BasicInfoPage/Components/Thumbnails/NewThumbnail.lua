--[[
	Represents the widget for adding a new Thumbnail to a ThumbnailSet.

	Props:
		int LayoutOrder = The order in which this widget will appear in the set.
		function OnClick = A callback for when this button is clicked.
]]
local FFlagGameSettingsWithContext = game:GetFastFlag("GameSettingsWithContext")

local BORDER = "rbxasset://textures/GameSettings/DottedBorder.png"
local PLUS = "rbxasset://textures/GameSettings/CenterPlus.png"

local Plugin = script.Parent.Parent.Parent.Parent.Parent
local Roact = require(Plugin.Roact)

local ContextServices = require(Plugin.Framework.ContextServices)
local withContext = ContextServices.withContext

local NewThumbnail = Roact.PureComponent:extend("NewThumbnail")

function NewThumbnail:init()
	self.mouseEnter = function()
		self:mouseHoverChanged(true)
	end

	self.mouseLeave = function()
		self:mouseHoverChanged(false)
	end
end

function NewThumbnail:mouseHoverChanged(hovering)
	local props = self.props

	-- TODO: change to use HoverArea from Developer Framework
	if hovering then
		props.Mouse:__pushCursor("PointingHand")
	else
		props.Mouse:__resetCursor()
	end
end

function NewThumbnail:render()
	local props = self.props
	local theme = props.Theme:get("Plugin")

	return Roact.createElement("ImageButton", {
		BorderSizePixel = 0,
		BackgroundColor3 = theme.newThumbnail.background,
		ImageColor3 = theme.newThumbnail.border,
		LayoutOrder = self.props.LayoutOrder or 1,
		Image = BORDER,

		[Roact.Event.MouseEnter] = self.mouseEnter,
		[Roact.Event.MouseLeave] = self.mouseLeave,

		[Roact.Event.Activated] = self.props.OnClick,
	}, {
		Plus = Roact.createElement("ImageLabel", {
			BackgroundTransparency = 1,
			ImageColor3 = theme.newThumbnail.plus,
			ImageTransparency = 0.4,
			Size = UDim2.new(1, 0, 1, 0),
			Image = PLUS,
			ZIndex = 2,
		})
	})
end

if FFlagGameSettingsWithContext then
	NewThumbnail = withContext({
		Theme = ContextServices.Theme,
		Mouse = ContextServices.Mouse,
	})(NewThumbnail)
else
	ContextServices.mapToProps(NewThumbnail, {
		Theme = ContextServices.Theme,
		Mouse = ContextServices.Mouse,
	})
end


return NewThumbnail