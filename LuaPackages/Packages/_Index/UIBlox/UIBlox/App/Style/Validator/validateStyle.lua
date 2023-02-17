local Validator = script.Parent
local Style = Validator.Parent
local App = Style.Parent
local UIBlox = App.Parent
local Packages = UIBlox.Parent

local t = require(Packages.t)

local validateFont = require(Validator.validateFont)

local UIBloxConfig = require(UIBlox.UIBloxConfig)
local validateTheme = if UIBloxConfig.useNewThemeColorPalettes
	then require(Validator.validateThemeNew)
	else require(Validator.validateTheme)

local StylePalette = t.strictInterface({
	Theme = validateTheme,
	Font = validateFont,
	Dimensions = t.optional(t.strictInterface({
		IconSizeMap = t.table,
	})),
})

return StylePalette
