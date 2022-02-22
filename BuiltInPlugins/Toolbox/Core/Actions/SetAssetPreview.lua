local Plugin = script.Parent.Parent.Parent

local Packages = Plugin.Packages
local Util = require(Packages.Framework).Util
local Action = Util.Action

return Action(script.Name, function(isPreviewing, previewAssetId)
	return {
		isPreviewing = isPreviewing,
		previewAssetId = previewAssetId,
	}
end)
