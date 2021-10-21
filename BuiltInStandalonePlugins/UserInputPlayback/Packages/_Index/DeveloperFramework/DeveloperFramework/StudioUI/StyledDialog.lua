--[[
	A version of StudioUI/Dialog that utilizes the current theme and
	DevFramework's Buttons.

	Required Props:
		table Buttons: A list of tables that hold information about how to style buttons.
		Vector2 MinContentSize: A width and height used if the calculated size is smaller.
		callback OnClose: A function which is fired when the X button attached
			to the widget.
		callback OnButtonPressed: A function which is called when any of the buttons
			are pressed.
		string Title: The title text displayed at the top of the widget.

	Optional Props:
		Enum.AutomaticSize AutomaticSize: The AutomaticSize of the component.
		boolean Enabled: Whether the widget is currently visible.
		Vector2 MinSize: The minimum size of the widget, in pixels.
			If the widget is not resizable, this property is not required.
		boolean Modal: Whether the widget blocks input to other windows.
		boolean Resizable: Whether the widget can be resized.
		Style Style: a predefined kind of dialog to use.
		Enum.ZIndexBehavior ZIndexBehavior: The ZIndexBehavior of the widget.
		Stylizer Stylizer: A Stylizer ContextItem, which is provided via withContext.
		Theme Theme: A Theme ContextItem, which is provided via withContext.
		Enum.HorizontalAlignment ButtonHorizontalAlignment: Where to align the buttons horizontally (Left, Center, or Right)

	Style Values:
		Color3 BackgroundColor3: Background color of the dialog.
]]

local FFlagDeveloperFrameworkWithContext = game:GetFastFlag("DeveloperFrameworkWithContext")
local FFlagDevFrameworkStyledDialogFullBleed = game:GetFastFlag("DevFrameworkStyledDialogFullBleed")
local FFlagDevFrameworkStyledDialogStyleModifier = game:GetFastFlag("DevFrameworkStyledDialogStyleModifier")

local Framework = script.Parent.Parent
local ContextServices = require(Framework.ContextServices)
local withContext = ContextServices.withContext
local Roact = require(Framework.Parent.Roact)

local Padding = require(Framework.Style.Padding)

local Util = require(Framework.Util)
local THEME_REFACTOR = Util.RefactorFlags.THEME_REFACTOR

local Button =  require(Framework.UI.Button)
local Container = require(Framework.UI.Container)
local Pane =  require(Framework.UI.Pane)
local Dialog = require(Framework.StudioUI.Dialog)
local prioritize = Util.prioritize
local Typecheck = Util.Typecheck

local BUTTON_HEIGHT = 32
local BUTTON_WIDTH = 120
local BUTTON_PADDING = 24 -- Remove with FFlagDevFrameworkCustomStyledDialogPadding
local BUTTON_EDGE_PADDING = 70 -- Remove with FFlagDevFrameworkCustomStyledDialogPadding
local CONTENT_PADDING = 24 -- Remove with FFlagDevFrameworkCustomStyledDialogPadding

local StyledDialog = Roact.PureComponent:extend("StyledDialog")

StyledDialog.defaultProps = {
	Enabled = true,
}

function StyledDialog:init()
	if FFlagDevFrameworkStyledDialogFullBleed then
		self.getComputedSizes = function(style)
			local buttons = self.props.Buttons

			local buttonContainerSize
			if buttons and #buttons then
				local buttonPadding = Padding(style.ButtonPadding)
				local spacing = style.ButtonSpacing
				local width = (#buttons * BUTTON_WIDTH) + (spacing * (#buttons - 1)) + buttonPadding.Horizontal
				local height = BUTTON_HEIGHT + buttonPadding.Vertical
				buttonContainerSize = Vector2.new(width, height)
			else
				buttonContainerSize = Vector2.new(0, 0)
			end

			local contentSize = self.props.MinContentSize
			local contentPadding = Padding(style.ContentPadding)
			local width = math.max(contentSize.X + contentPadding.Horizontal, buttonContainerSize.X)
			local height = contentSize.Y + contentPadding.Vertical + buttonContainerSize.Y
			local windowSize = Vector2.new(width, height)

			return windowSize, buttonContainerSize
		end
	else
		self.getWindowSize = function()
			local contentSize = self.props.MinContentSize
			local buttons = self.props.Buttons

			local size

			if buttons and #buttons >= 1 then
				local minContentWidth = (2 * CONTENT_PADDING) + contentSize.X
				local totalButtonWidth = (#buttons * BUTTON_WIDTH) + (CONTENT_PADDING * (#buttons - 1)) + (2 * BUTTON_EDGE_PADDING)
				local minContentHeight = (3 * CONTENT_PADDING) + BUTTON_HEIGHT + contentSize.Y
				size = Vector2.new(math.max(minContentWidth, totalButtonWidth), minContentHeight)
			end

			return size or Vector2.new(0,0)
		end
	end

	self.getButtons = function(styleTable)
		local onButtonPressed = self.props.OnButtonPressed
		local buttons = self.props.Buttons
		local defaultButtons = styleTable.Buttons or {}

		local buttonHorizontalAlignment = prioritize(self.props.ButtonHorizontalAlignment, styleTable.ButtonHorizontalAlignment)

		local buttonsElements = {}
		if not FFlagDevFrameworkStyledDialogFullBleed then
			if buttons then
				buttonsElements["Layout"] = Roact.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = buttonHorizontalAlignment,
					Padding = UDim.new(0, BUTTON_PADDING),
					SortOrder = Enum.SortOrder.LayoutOrder,
				})
			end
		end
		for i, buttonProps in ipairs(buttons) do
			assert(buttonProps.Key ~= nil, string.format("Dialog buttons must have keys. Missing at index : %d", i))

			local buttonStyle = defaultButtons[i] or {}
			local key = buttonProps.Key
			local styleName = prioritize(buttonProps.Style, buttonStyle.Style, "Round")
			local text = buttonProps.Text
			local styleModifier = nil
			
			if FFlagDevFrameworkStyledDialogStyleModifier then
				styleModifier = buttonProps.StyleModifier
			end

			buttonsElements[tostring(i)] = Roact.createElement(Button, {
				LayoutOrder = i,
				OnClick = function()
					onButtonPressed(key)
				end,
				Size = UDim2.fromOffset(BUTTON_WIDTH, BUTTON_HEIGHT),
				Style = styleName,
				StyleModifier = styleModifier,
				Text = text,
			})
		end
		return buttonsElements
	end
end

function StyledDialog:render()
	local theme = self.props.Theme
	local style
	if THEME_REFACTOR then
		style = self.props.Stylizer
	else
		style = theme:getStyle("Framework", self)
	end

	local automaticSize = self.props.AutomaticSize
	local backgroundColor = prioritize(self.props.BackgroundColor3, style.Background)
	local buttonHorizontalAlignment = prioritize(self.props.ButtonHorizontalAlignment, style.ButtonHorizontalAlignment)
	local isEnabled = self.props.Enabled
	local isModal = prioritize(self.props.Modal, style.Modal)
	local isResizable = prioritize(self.props.Resizable, style.Resizable)
	local onClose = self.props.OnClose
	local title = self.props.Title
	local zIndexBehavior = self.props.ZIndexBehavior

	local buttonContainer
	if not FFlagDevFrameworkStyledDialogFullBleed then
		buttonContainer = Roact.createElement(Container, {
			Position = UDim2.new(0, CONTENT_PADDING, 1, -(BUTTON_HEIGHT + CONTENT_PADDING)),
			Size = UDim2.new(1, -(CONTENT_PADDING * 2), 0, BUTTON_HEIGHT),
		}, self.getButtons(style))
	end

	local windowSize, buttonContainerSize
	if FFlagDevFrameworkStyledDialogFullBleed then
		windowSize, buttonContainerSize = self.getComputedSizes(style)
	end

	return Roact.createElement(Dialog, {
		Enabled = isEnabled,
		Modal = isModal,
		OnClose = onClose,
		Resizable = isResizable,
		Size = FFlagDevFrameworkStyledDialogFullBleed and windowSize or self.getWindowSize(style),
		Title = title,
		ZIndexBehavior = zIndexBehavior,
	}, {
		SolidBackground = FFlagDevFrameworkStyledDialogFullBleed and Roact.createElement(Pane, {
			BackgroundColor = backgroundColor,
			Layout = Enum.FillDirection.Vertical,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			Padding = style.ContentPadding,
		}, {
			Contents = Roact.createElement(Pane, {
				AutomaticSize = automaticSize,
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 1, -buttonContainerSize.Y),
			}, self.props[Roact.Children]),

			ButtonContainer = Roact.createElement(Pane, {
				HorizontalAlignment = buttonHorizontalAlignment,
				Layout = Enum.FillDirection.Horizontal,
				LayoutOrder = 2,
				Padding = style.ButtonPadding,
				Size = UDim2.new(1, 0, 0, buttonContainerSize.Y),
				Spacing = style.ButtonSpacing,
			}, self.getButtons(style))
		}) or Roact.createElement("Frame", {
			BackgroundColor3 = backgroundColor,
			Size = UDim2.new(1, 0, 1, 0),
		}, {
			Contents = Roact.createElement(Container, {
				AutomaticSize = automaticSize,
				Position = UDim2.new(0, CONTENT_PADDING, 0, CONTENT_PADDING),
				Size = UDim2.new(1, -(CONTENT_PADDING * 2), 1, -((CONTENT_PADDING * 3) + BUTTON_HEIGHT))
			}, self.props[Roact.Children]),

			ButtonContainer = buttonContainer,
		}),
	})
end
if FFlagDeveloperFrameworkWithContext then
	StyledDialog = withContext({
		Stylizer = THEME_REFACTOR and ContextServices.Stylizer or nil,
		Theme = (not THEME_REFACTOR) and ContextServices.Theme or nil,
	})(StyledDialog)
else
	ContextServices.mapToProps(StyledDialog, {
		Stylizer = THEME_REFACTOR and ContextServices.Stylizer or nil,
		Theme = (not THEME_REFACTOR) and ContextServices.Theme or nil,
	})
end


Typecheck.wrap(StyledDialog, script)

return StyledDialog