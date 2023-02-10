--!nonstrict
local Style = script:FindFirstAncestor("Style")
local Packages = Style.Parent
local CorePackages = game:GetService("CorePackages")
local ArgCheck = require(CorePackages.Workspace.Packages.ArgCheck)
local Logging = require(CorePackages.Logging)
local UIBlox = require(CorePackages.UIBlox)

local Logger = require(Style.Logger)

local GetFFlagLuaAppWorkspaceUseLumberyakLogger =
	require(Packages.SharedFlags).GetFFlagLuaAppWorkspaceUseLumberyakLogger

return function(fontName, defaultFont, fontMap)
	-- TODO: We should move this up once we address APPFDN-1784
	local validateFont = UIBlox.Style.Validator.validateFont

	local mappedFont
	if fontName ~= nil and #fontName > 0 then
		mappedFont = fontMap[string.lower(fontName)]
	end

	if mappedFont == nil then
		mappedFont = fontMap[defaultFont]

		if GetFFlagLuaAppWorkspaceUseLumberyakLogger() then
			Logger:warning(string.format("Unrecognized font name: `%s`", tostring(fontName)))
		else
			Logging.warn(string.format("Unrecognized font name: `%s`", tostring(fontName)))
		end
	end

	ArgCheck.assert(validateFont(mappedFont))
	return mappedFont
end
