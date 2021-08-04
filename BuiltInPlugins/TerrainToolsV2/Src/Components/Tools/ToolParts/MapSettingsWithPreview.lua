--[[
	Wraps MapSettingsWithPreviewFragment inside a Panel called Map Settings
]]
local FFlagTerrainToolsV2WithContext = game:GetFastFlag("TerrainToolsV2WithContext")

local Plugin = script.Parent.Parent.Parent.Parent.Parent

local Framework = require(Plugin.Packages.Framework)
local Cryo = require(Plugin.Packages.Cryo)
local Roact = require(Plugin.Packages.Roact)

local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext
local ContextItems = require(Plugin.Src.ContextItems)

local ToolParts = script.Parent
local MapSettingsWithPreviewFragment = require(ToolParts.MapSettingsWithPreviewFragment)
local Panel = require(ToolParts.Panel)

local MapSettingsWithPreview = Roact.PureComponent:extend(script.Name)

function MapSettingsWithPreview:render()
	local localization = self.props.Localization:get()

	local layoutOrder = self.props.LayoutOrder
	local isSubsection = self.props.isSubsection

	local fragmentProps = Cryo.Dictionary.join(self.props, {
		LayoutOrder = Cryo.None,
		isSubsection = Cryo.None,

		InitialLayoutOrder = 1,
	})

	return Roact.createElement(Panel, {
		LayoutOrder = layoutOrder,
		isSubsection = isSubsection,
		Title = localization:getText("MapSettings", "MapSettings"),
		Padding = UDim.new(0, 12),
	}, {
		MapSettingsWithPreviewFragment = Roact.createElement(MapSettingsWithPreviewFragment, fragmentProps),
	})
end

if FFlagTerrainToolsV2WithContext then
	MapSettingsWithPreview = withContext({
		Localization = ContextItems.UILibraryLocalization,
	})(MapSettingsWithPreview)
else
	ContextServices.mapToProps(MapSettingsWithPreview, {
		Localization = ContextItems.UILibraryLocalization,
	})
end


return MapSettingsWithPreview
