if not game:GetFastFlag("ImprovePluginSpeed_AlignmentTool") then
	return
end

require(script.Parent.defineLuaFlags)

local Plugin = script.Parent.Parent

local PluginLoaderBuilder = require(Plugin.PluginLoader.PluginLoaderBuilder)
local TranslationDevelopmentTable = Plugin.Src.Resources.Localization.TranslationDevelopmentTable
local TranslationReferenceTable = Plugin.Src.Resources.Localization.TranslationReferenceTable

local FFlagDebugRbxQtitanRibbonAndDockingEnabled = game:GetFastFlag("DebugRbxQtitanRibbonAndDockingEnabled")

local args : PluginLoaderBuilder.Args = {
	plugin = plugin,
	pluginName = "AlignmentTool",
	translationResourceTable = TranslationReferenceTable,
	fallbackResourceTable = TranslationDevelopmentTable,
	overrideLocaleId = nil,
	localizationNamespace = nil,
	getToolbarName = function()
		return "Alignment"
	end,
	buttonInfo = {
		getName = function()
			return "AlignTool"
		end,
		getDescription = function()
			return ""
		end,
		icon = "",
		text = nil,
		clickableWhenViewportHidden = true
	},
	dockWidgetInfo = {
		dockWidgetPluginGuiInfo = DockWidgetPluginGuiInfo.new(
			Enum.InitialDockState.Left, --initialDockState,
			not FFlagDebugRbxQtitanRibbonAndDockingEnabled, --initialEnabled,
			false, --initialEnabledShouldOverrideRestore,
			300, --size.X,
			250, --size.Y,
			175, --minSize.X,
			250 --minSize.Y
		),
		getDockTitle =  function(getLocalizedText, namespace, pluginName)
			return getLocalizedText(namespace, pluginName, "Plugin", "WindowTitle")
		end,
		zIndexBehavior = Enum.ZIndexBehavior.Sibling,
	},
}

local pluginLoaderContext : PluginLoaderBuilder.PluginLoaderContext = PluginLoaderBuilder.build(args)
local success = pluginLoaderContext.pluginLoader:waitForUserInteraction()
if not success then
	-- Plugin destroyed
	return
end

local main = require(script.Parent.main)
main(plugin, pluginLoaderContext)
