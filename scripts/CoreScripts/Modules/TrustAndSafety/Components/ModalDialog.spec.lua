return function()
	local CorePackages = game:GetService("CorePackages")

	local AppDarkTheme = require(CorePackages.AppTempCommon.LuaApp.Style.Themes.DarkTheme)
	local AppFont = require(CorePackages.AppTempCommon.LuaApp.Style.Fonts.Gotham)
	local Roact = require(CorePackages.Roact)
	local RoactRodux = require(CorePackages.RoactRodux)
	local Rodux = require(CorePackages.Rodux)
	local UIBlox = require(CorePackages.UIBlox)

	local ModalDialog = require(script.Parent.ModalDialog)

	local appStyle = {
		Theme = AppDarkTheme,
		Font = AppFont,
	}

	it("empty dialog should create and destroy without errors", function()
		local element = Roact.createElement(UIBlox.Core.Style.Provider, {
			style = appStyle,
		}, {
			ModalDialog = Roact.createElement(ModalDialog, {
				visible = true,
				titleText = "Title",
				titleBar = nil,
				contents = nil,
				actionButtons = nil,
				onDismiss = function() end,
			}),
		})

		local instance = Roact.mount(element)
		Roact.unmount(instance)
	end)
end
