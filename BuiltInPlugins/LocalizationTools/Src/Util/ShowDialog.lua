local Plugin = script.Parent.Parent.Parent
local Roact = require(Plugin.Packages.Roact)
local Framework = require(Plugin.Packages.Framework)
local ContextServices = Framework.ContextServices
local Promise = Framework.Util.Promise
local PluginTheme = require(Plugin.Src.Resources.PluginTheme)


local THEME_REFACTOR = Framework.Util.RefactorFlags.THEME_REFACTOR
local DIALOG_SIZE = Vector2.new(300, 370)

return function(plugin, localization, theme, mouse)
	return function(title, renderContent)
		
		return Promise.new(function(resolve, _)
			spawn(function()
				local dialogHandle
				local dialog = plugin:CreateQWidgetPluginGui(title, {
					Size = THEME_REFACTOR and DIALOG_SIZE or theme:get("Plugin").DialogSize,
					Modal = true,
				})
				dialog.Enabled = true
				dialog.Title = title

				local function ok()
					Roact.unmount(dialogHandle)
					dialog:Destroy()
					resolve(true)
				end

				local function cancel()
					Roact.unmount(dialogHandle)
					dialog:Destroy()
					resolve(false)
				end

				dialog:GetPropertyChangedSignal("Enabled"):connect(function()
					cancel()
				end)
				
				local providedTheme
				if THEME_REFACTOR then
					providedTheme = PluginTheme()
				else
					providedTheme = theme
				end
				
				local dialogContent = ContextServices.provide({
					localization,
					providedTheme,
					mouse,
				}, {
					Content = renderContent(ok, cancel)
				})

				dialogHandle = Roact.mount(dialogContent, dialog)
			end)
		end)
	end
end