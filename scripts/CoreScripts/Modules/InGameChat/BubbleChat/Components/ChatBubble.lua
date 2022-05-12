local CorePackages = game:GetService("CorePackages")
local TextService = game:GetService("TextService")
local TextChatService = game:GetService("TextChatService")

local Otter = require(CorePackages.Packages.Otter)
local Roact = require(CorePackages.Packages.Roact)
local RoactRodux = require(CorePackages.Packages.RoactRodux)
local t = require(CorePackages.Packages.t)
local Cryo = require(CorePackages.Packages.Cryo)

local root = script.Parent.Parent
local Types = require(root.Types)
local getSizeSpringFromSettings = require(root.Helpers.getSizeSpringFromSettings)
local getTransparencySpringFromSettings = require(root.Helpers.getTransparencySpringFromSettings)

local CoreGui = game:GetService("CoreGui")
local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local GetFFlagBubbleVoiceIndicator = require(RobloxGui.Modules.Flags.GetFFlagBubbleVoiceIndicator)
local FFlagEnableRichTextForBubbleChat = require(RobloxGui.Modules.Flags.FFlagEnableRichTextForBubbleChat)

local ChatBubble = Roact.PureComponent:extend("ChatBubble")

ChatBubble.validateProps = t.strictInterface({
	messageId = t.string,

	fadingOut = t.optional(t.boolean),
	onFadeOut = t.optional(t.callback),
	isMostRecent = t.optional(t.boolean),
	theme = t.optional(t.string),
	renderInsert = t.optional(t.callback),
	insertSize = t.optional(t.Vector2),
	chatSettings = Types.IChatSettings,

	-- RoactRodux
	text = t.string,
	timestamp = t.number,
})

ChatBubble.defaultProps = {
	theme = "Light",
	isMostRecent = true,
}

local function initMockSizingLabel()
	local SizingGui = Instance.new("ScreenGui")
	SizingGui.Enabled = false
	SizingGui.Name = "RichTextSizingLabel"
	local SizingLabel = Instance.new("TextLabel")
	SizingLabel.TextWrapped = true
	SizingLabel.RichText = true
	SizingLabel.Parent = SizingGui
	SizingGui.Parent = CoreGui
	return SizingLabel
end

function ChatBubble:init()
	self.width, self.updateWidth = Roact.createBinding(0)
	self.widthMotor = Otter.createSingleMotor(0)
	self.widthMotor:onStep(function(value)
		self.updateWidth(math.round(value))
	end)

	self.height, self.updateHeight = Roact.createBinding(0)
	self.heightMotor = Otter.createSingleMotor(0)
	self.heightMotor:onStep(function(value)
		self.updateHeight(math.round(value))
	end)

	self.transparency, self.updateTransparency = Roact.createBinding(1)
	self.transparencyMotor = Otter.createSingleMotor(1)
	self.transparencyMotor:onStep(self.updateTransparency)

	self.size = Roact.joinBindings({ self.width, self.height }):map(function(sizes)
		return UDim2.fromOffset(sizes[1], sizes[2])
	end)

	self.mockSizingLabel = initMockSizingLabel()

	self.isRichTextEnabled = if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService and FFlagEnableRichTextForBubbleChat then
		true
	else
		false
end

function ChatBubble:getBoundsFromSizingLabel(Text, TextSize, Font, Size)
	self.mockSizingLabel.Text = Text
	self.mockSizingLabel.TextSize = TextSize
	self.mockSizingLabel.Font = Font
	self.mockSizingLabel.Size = UDim2.fromOffset(Size.X, Size.Y)
	return self.mockSizingLabel.TextBounds
end

function ChatBubble:getTextBounds()
	local chatSettings = self.props.chatSettings
	local padding = Vector2.new(chatSettings.Padding * 4, chatSettings.Padding * 2)

	local bounds = Vector2.new(0, 0)
	if self.isRichTextEnabled then
		bounds = self:getBoundsFromSizingLabel(
			self.props.text,
			chatSettings.TextSize,
			chatSettings.Font,
			Vector2.new(chatSettings.MaxWidth, 10000)
		)
	else
		bounds = TextService:GetTextSize(
			self.props.text,
			chatSettings.TextSize,
			chatSettings.Font,
			Vector2.new(chatSettings.MaxWidth, 10000)
		)
	end

	return bounds + padding
end

function ChatBubble:renderOld()
	local bounds = self:getTextBounds()
	local chatSettings = self.props.chatSettings
	local backgroundImageSettings = chatSettings.BackgroundImage
	local backgroundGradientSettings = chatSettings.BackgroundGradient

	return Roact.createElement("Frame", {
		LayoutOrder = self.props.timestamp,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = self.size,
		Position = UDim2.fromScale(1, 0.5),
		Transparency = 1,
	}, {
		Layout = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, -1), --UICorner generates a 1 pixel gap (UISYS-625), this fixes it by moving the carrot up by 1 pixel
		}),

		Frame = Roact.createElement("ImageLabel", Cryo.Dictionary.join(backgroundImageSettings, {
			LayoutOrder = 1,
			BackgroundColor3 = chatSettings.BackgroundColor3,
			AnchorPoint = Vector2.new(0.5, 0),
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, 0, 0, 0),
			BackgroundTransparency = backgroundImageSettings.Image ~= "" and 1 or self.transparency,
			ClipsDescendants = true,
			ImageTransparency = self.transparency,
		}), {
			UICorner = chatSettings.CornerEnabled and Roact.createElement("UICorner", {
				CornerRadius = chatSettings.CornerRadius,
			}),

			Text = Roact.createElement("TextLabel", {
				Text = self.props.text,
				Size = UDim2.new(0, bounds.X, 0, bounds.Y),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundTransparency = 1,
				Font = chatSettings.Font,
				TextColor3 = chatSettings.TextColor3,
				TextSize = chatSettings.TextSize,
				TextTransparency = self.transparency,
				TextWrapped = true,
				AutoLocalize = false,
			}, {
				Padding = Roact.createElement("UIPadding", {
					PaddingTop = UDim.new(0, chatSettings.Padding),
					PaddingRight = UDim.new(0, chatSettings.Padding),
					PaddingBottom = UDim.new(0, chatSettings.Padding),
					PaddingLeft = UDim.new(0, chatSettings.Padding),
				})
			}),

			Gradient = backgroundGradientSettings.Enabled and Roact.createElement("UIGradient", backgroundGradientSettings)
		}),

		Carat = self.props.isMostRecent and chatSettings.TailVisible and Roact.createElement("ImageLabel", {
			LayoutOrder = 2,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(9, 6),
			Image = "rbxasset://textures/ui/InGameChat/Caret.png",
			ImageColor3 = chatSettings.BackgroundColor3,
			ImageTransparency = self.transparency,
		}),
	})
end

function ChatBubble:renderNew()
	local chatSettings = self.props.chatSettings
	local backgroundImageSettings = chatSettings.BackgroundImage
	local backgroundGradientSettings = chatSettings.BackgroundGradient

	local extraWidth = self.props.renderInsert and (self.props.insertSize.X + chatSettings.Padding) or 0

	return Roact.createElement("Frame", {
		LayoutOrder = self.props.timestamp,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = self.size,
		Position = UDim2.fromScale(1, 0.5),
		Transparency = 1,
	}, {
		Layout = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, -1), --UICorner generates a 1 pixel gap (UISYS-625), this fixes it by moving the carrot up by 1 pixel
		}),

		Frame = Roact.createElement("ImageLabel", Cryo.Dictionary.join(backgroundImageSettings, {
			LayoutOrder = 1,
			BackgroundColor3 = chatSettings.BackgroundColor3,
			AnchorPoint = Vector2.new(0.5, 0),
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, 0, 0, 0),
			BackgroundTransparency = backgroundImageSettings.Image ~= "" and 1 or self.transparency,
			ClipsDescendants = true,
			ImageTransparency = self.transparency,
		}), {
			UICorner = chatSettings.CornerEnabled and Roact.createElement("UICorner", {
				CornerRadius = chatSettings.CornerRadius,
			}),

			UIListLayout = Roact.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
				Padding = UDim.new(0, chatSettings.Padding),
			}),

			Padding = Roact.createElement("UIPadding", {
				PaddingTop = UDim.new(0, chatSettings.Padding),
				PaddingRight = UDim.new(0, chatSettings.Padding),
				PaddingBottom = UDim.new(0, chatSettings.Padding),
				PaddingLeft = UDim.new(0, chatSettings.Padding),
			}),

			Insert = self.props.renderInsert and self.props.renderInsert(),

			Text = Roact.createElement("TextLabel", {
				Text = self.props.text,
				Size = UDim2.new(1, -extraWidth, 1, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundTransparency = 1,
				Font = chatSettings.Font,
				TextColor3 = chatSettings.TextColor3,
				TextSize = chatSettings.TextSize,
				TextTransparency = self.transparency,
				TextWrapped = true,
				AutoLocalize = false,
				LayoutOrder = 2,
				RichText = self.isRichTextEnabled,
			}),

			Gradient = backgroundGradientSettings.Enabled and Roact.createElement("UIGradient", backgroundGradientSettings)
		}),

		Carat = self.props.isMostRecent and 	chatSettings.TailVisible and Roact.createElement("ImageLabel", {
			LayoutOrder = 2,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(9, 6),
			Image = "rbxasset://textures/ui/InGameChat/Caret.png",
			ImageColor3 = chatSettings.BackgroundColor3,
			ImageTransparency = self.transparency,
		}),
	})
end

function ChatBubble:render()
	if GetFFlagBubbleVoiceIndicator() then
		return self:renderNew()
	else
		return self:renderOld()
	end
end

function ChatBubble:fadeOut()
	if not self.isFadingOut then
		self.isFadingOut = true

		self.transparencyMotor:onComplete(function()
			if self.props.onFadeOut then
				self.props.onFadeOut(self.props.messageId)
			end
		end)

		local transparencySpring = getTransparencySpringFromSettings(self.props.chatSettings)
		self.transparencyMotor:setGoal(transparencySpring(1))
	end
end

function ChatBubble:didUpdate(previousProps)
	if self.props.fadingOut then
		self:fadeOut()
	end
	-- Update the size of the bubble to accommodate changes to the text's size (for instance: when the text changes due
	-- to filtering, or when new customization settings are applied)
	if GetFFlagBubbleVoiceIndicator() then
		if previousProps.text ~= self.props.text
			or previousProps.chatSettings ~= self.props.chatSettings
			or previousProps.renderInsert ~= self.props.renderInsert
			or previousProps.insertSize ~= self.props.insertSize
		then
			local bounds = self:getTextBounds()
			local sizeSpring = getSizeSpringFromSettings(self.props.chatSettings)
			local padding = self.props.chatSettings.Padding

			local width = bounds.X
			local height = bounds.Y
			if self.props.renderInsert then
				width += self.props.insertSize.X + padding
				height = math.max(height, self.props.insertSize.Y + padding * 2)
			end
			self.heightMotor:setGoal(sizeSpring(height))
			self.widthMotor:setGoal(sizeSpring(width))
		end
	else
		if previousProps.text ~= self.props.text or previousProps.chatSettings ~= self.props.chatSettings then
			local bounds = self:getTextBounds()
			local sizeSpring = getSizeSpringFromSettings(self.props.chatSettings)
			self.heightMotor:setGoal(sizeSpring(bounds.Y))
			self.widthMotor:setGoal(sizeSpring(bounds.X))
		end
	end
end

function ChatBubble:didMount()
	self.isMounted = true

	local bounds = self:getTextBounds()
	local chatSettings = self.props.chatSettings
	local sizeSpring = getSizeSpringFromSettings(chatSettings)
	local transparencySpring = getTransparencySpringFromSettings(chatSettings)

	local width = bounds.X
	local height = bounds.Y
	if GetFFlagBubbleVoiceIndicator() then
		if self.props.renderInsert then
			width += self.props.insertSize.X + chatSettings.Padding
			height = math.max(height, self.props.insertSize.Y + chatSettings.Padding * 2)
		end
	end

	if self.props.isMostRecent then
		-- Chat bubble spawned for the first time
		self.heightMotor:setGoal(sizeSpring(height))
		self.widthMotor:setGoal(Otter.instant(width))
	else
		-- Transition between distant bubble and chat bubble
		self.heightMotor:setGoal(sizeSpring(height))
		self.widthMotor:setGoal(sizeSpring(width))
	end

	self.transparencyMotor:setGoal(transparencySpring(chatSettings.Transparency))
end

function ChatBubble:willUnmount()
	self.isMounted = false
	self.transparencyMotor:destroy()
	self.heightMotor:destroy()
	self.widthMotor:destroy()
end

local function mapStateToProps(state, props)
	local message = state.messages[props.messageId]
	return {
		-- We must listen for the message's text from the state rather than get it as a prop from the parent BubbleChatList
		-- because it can be updated (message done filtering) and that would not trigger a BubbleChatList re-render
		text = message and message.text or "",
		timestamp = message and message.timestamp or 0,
	}
end

return RoactRodux.connect(mapStateToProps)(ChatBubble)
