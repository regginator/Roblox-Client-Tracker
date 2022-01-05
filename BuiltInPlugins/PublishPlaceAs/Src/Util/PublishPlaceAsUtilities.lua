local FStringDevPublishChinaRequirementsLink = game:GetFastString("DevPublishChinaRequirementsLink")

local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local PublishPlaceAsPolicy = game:GetService("PluginPolicyService"):getPluginPolicy("PublishPlaceAs")

local Plugin = script.Parent.Parent.Parent

local Cryo = require(Plugin.Packages.Cryo)

local KeyProvider = require(Plugin.Src.Util.KeyProvider)

local contextKey = KeyProvider.getContextKeyName()
local pluginKey = KeyProvider.getPluginKeyName()
local publishPlaceAsKey = KeyProvider.getPublishPlaceAsKeyName()
local regionKey = KeyProvider.getRegionKeyName()
local statusKey = KeyProvider.getStatusKeyName()

local PublishPlaceAsUtilities =  {}

function PublishPlaceAsUtilities.shouldShowDevPublishLocations()
	return PublishPlaceAsPolicy["ShowOptInLocations"]
end

function PublishPlaceAsUtilities.getIsOptInChina(optInRegions)
    --[[
        Endpoint returns optInLocations in the following format:
            [
                {
                    "region": "China",
                    "status": "Approved"
                },
            ]
    ]]
    
    if optInRegions == nil then
        return false
    end

    for _,optInRegion in pairs(optInRegions) do
        local region = optInRegion[regionKey]
        local status = optInRegion[statusKey]
        if region == "China" and status == "Approved" then
            return true
        end
    end
    return false
end

function PublishPlaceAsUtilities.getOptInLocationsRequirementsLink(location)
	return FStringDevPublishChinaRequirementsLink
end

function PublishPlaceAsUtilities.getPlayerAppDownloadLink(location)
	return PublishPlaceAsPolicy["PlayerAppDownloadLink"][location]
end

local function getDevPublishKibanaPoints(plugin, context)
	return {
		[pluginKey] = plugin,
		[contextKey] = context,
	}
end

function PublishPlaceAsUtilities.sendAnalyticsToKibana(seriesName, throttlingPercentage, context, values)
	local points = getDevPublishKibanaPoints(publishPlaceAsKey, context)
	points = Cryo.Dictionary.join(points, values)
	RbxAnalyticsService:reportInfluxSeries(seriesName, points, throttlingPercentage)
end

return PublishPlaceAsUtilities
