--[[
	Reducer that combines the Settings and Status reducers.
]]

local Plugin = script.Parent.Parent.Parent
local Rodux = require(Plugin.Rodux)

local GameMetadata = require(Plugin.Src.Reducers.GameMetadata)
local GameOwnerMetadata = require(Plugin.Src.Reducers.GameOwnerMetadata)
local PageLoadState = require(Plugin.Src.Reducers.PageLoadState)
local PageSaveState = require(Plugin.Src.Reducers.PageSaveState)
local Settings = require(Plugin.Src.Reducers.Settings)
local Status = require(Plugin.Src.Reducers.Status)

local EditAsset = require(Plugin.Src.Reducers.EditAsset)

local CollaboratorSearch = require(Plugin.Src.Components.SettingsPages.PermissionsPage.Reducers.CollaboratorSearch)
local DevSubModeration = require(Plugin.Src.Components.SettingsPages.DeveloperSubscriptionsPage.Reducers.DevSubModeration)
local AutoTranslationMetaData = require(Plugin.Src.Components.SettingsPages.LocalizationPage.Reducers.AutoTranslationMetaData)
local MorpherEditorRoot = require(Plugin.Src.Components.SettingsPages.AvatarPage.Reducers.MorpherEditorRoot)

local FFlagStudioLocalizationInGameSettingsEnabled = game:GetFastFlag("StudioLocalizationInGameSettingsEnabled")
local FFlagStudioStandaloneGameMetadata = game:GetFastFlag("StudioStandaloneGameMetadata")

return Rodux.combineReducers({
	Settings = Settings,
	Status = Status,
	MorpherEditorRoot = MorpherEditorRoot,
	CollaboratorSearch = CollaboratorSearch,
	DevSubModeration = settings():GetFFlag("DeveloperSubscriptionsEnabled") and DevSubModeration or nil,
	AutoTranslationMetaData = FFlagStudioLocalizationInGameSettingsEnabled and AutoTranslationMetaData or nil,
	PageLoadState = PageLoadState,
	PageSaveState = PageSaveState,
	Metadata = FFlagStudioStandaloneGameMetadata and GameMetadata or nil,
    GameOwnerMetadata = GameOwnerMetadata,
	EditAsset = (game:GetFastFlag("GameSettingsPlaceSettings") or game:GetFastFlag("StudioAddMonetizationToGameSettings")) and EditAsset or nil,
})