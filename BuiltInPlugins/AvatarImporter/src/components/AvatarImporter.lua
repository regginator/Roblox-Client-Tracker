--[[
	AvatarImporter - Wrapper component to display the current screen based on Rodux store
]]

local root = script.Parent.Parent.Parent

-- imports
local Roact = require(root.lib.Roact)
local RoactRodux = require(root.lib.RoactRodux)

local Constants = require(root.src.Constants)
local AvatarPrompt = require(root.src.components.AvatarPrompt)
local LoadingPrompt = require(root.src.components.LoadingPrompt)
local ErrorPrompt = require(root.src.components.ErrorPrompt)

local function showAvatarPrompt(currentScreen)
	return currentScreen == Constants.SCREENS.AVATAR
end

local function showLoadingPrompt(currentScreen)
	return currentScreen == Constants.SCREENS.LOADING
end

local function showErrorPrompt(currentScreen)
	return currentScreen == Constants.SCREENS.ERROR
end

-- component
local AvatarImporter = Roact.Component:extend("AvatarImporter")

function AvatarImporter:render()
	local screen = self.props.screen

	return Roact.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
	}, {
		AvatarPrompt = showAvatarPrompt(screen) and Roact.createElement(AvatarPrompt),
		LoadingPrompt = showLoadingPrompt(screen) and Roact.createElement(LoadingPrompt),
		ErrorPrompt = showErrorPrompt(screen) and Roact.createElement(ErrorPrompt),
	})
end

local function mapStateToProps(state)
	state = state or {}

	return {
		screen = state.plugin.screen,
	}
end

return RoactRodux.connect(mapStateToProps)(AvatarImporter)