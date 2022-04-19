--[[
	The toolbox itself

	Props (many of these come from the store):
		number initialWidth = 0
		number initialSelectedBackgroundIndex = 1
		string initialSelectedCategoryName = ""
		string initialSearchTerm = ""
		number initialSelectedSortIndex = 1

		Backgrounds backgrounds
		Suggestions suggestions
		Sorts sorts

		callback updatePageInfo()
		callback tryOpenAssetConfig, invoke assetConfig page with an assetId.
]]
local MemStorageService = game:GetService("MemStorageService")

local Plugin = script.Parent.Parent.Parent

local FFlagToolboxAssetCategorization4 = game:GetFastFlag("ToolboxAssetCategorization4")
local FFlagToolboxRefactorSearchOptions = game:GetFastFlag("ToolboxRefactorSearchOptions")
local FFlagToolboxAssetStyleUpdate2 = game:GetFastFlag("ToolboxAssetStyleUpdate2")

local Packages = Plugin.Packages
local Cryo = require(Packages.Cryo)
local Roact = require(Packages.Roact)
local RoactRodux = require(Packages.RoactRodux)
local Framework = require(Packages.Framework)

local disableMarketplaceAndRecents = require(Plugin.Core.Util.ToolboxUtilities).disableMarketplaceAndRecents
local showRobloxCreatedAssets = require(Plugin.Core.Util.ToolboxUtilities).showRobloxCreatedAssets

local SharedPluginConstants = require(Plugin.SharedPluginConstants)

local Util = Plugin.Core.Util
local Constants = require(Util.Constants)
local ContextGetter = require(Util.ContextGetter)
local PageInfoHelper = require(Util.PageInfoHelper)
local getModal = ContextGetter.getModal
local getTabs = require(Util.getTabs)
local Analytics = require(Util.Analytics.Analytics)

local Types = Plugin.Core.Types
local Sort = require(Types.Sort)
local Category = require(Types.Category)
local RequestReason = require(Types.RequestReason)

local getNetwork = ContextGetter.getNetwork

local Components = Plugin.Core.Components
local TabSet = require(Components.TabSet)
local Footer = require(Components.Footer.Footer)
local Header = require(Components.Header)
local MainView = require(Components.MainView.MainView)
local SoundPreviewComponent = require(Components.SoundPreviewComponent)
local HomeWrapper = if FFlagToolboxAssetCategorization4 then require(Components.Home.HomeWrapper) else nil
local SearchOptions = require(Plugin.Core.Components.SearchOptions.SearchOptions)

local Requests = Plugin.Core.Networking.Requests
local UpdatePageInfoAndSendRequest = require(Requests.UpdatePageInfoAndSendRequest)
local ChangeMarketplaceTab = require(Requests.ChangeMarketplaceTab)
local GetToolboxManageableGroupsRequest = require(Requests.GetToolboxManageableGroupsRequest)
local GetRolesRequest = require(Requests.GetRolesRequest)
local GetRolesDebugRequest = require(Requests.GetRolesDebugRequest)
local GetRobuxBalance = require(Requests.GetRobuxBalance)

local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext
local Settings = require(Plugin.Core.ContextServices.Settings)
local IXPContext = require(Plugin.Core.ContextServices.IXPContext)

local HomeTypes = require(Plugin.Core.Types.HomeTypes)

local FFlagDebugToolboxGetRolesRequest = game:GetFastFlag("DebugToolboxGetRolesRequest")
local FFlagToolboxAssetGridRefactor = game:GetFastFlag("ToolboxAssetGridRefactor6")

local Background = require(Plugin.Core.Types.Background)

local Toolbox = Roact.PureComponent:extend("Toolbox")

if FFlagToolboxAssetGridRefactor then
	Toolbox.defaultProps = {
		Size = UDim2.new(1, 0, 1, 0),
	}
end

function Toolbox:handleInitialSettings()
	local networkInterface = getNetwork(self)
	if not self.props.Settings then
		return
	end
	local settings = self.props.Settings:get("Plugin")
	local initialSettings = settings:loadInitialSettings()

	local initialSelectedSortIndex
	local initialSearchTerm
	local initialSelectedBackgroundIndex = Background.getBackgroundForStudioTheme()
	-- We should reset the categoryName and sortIndex since release of tabs.
	initialSelectedSortIndex = 1
	initialSearchTerm = ""

	local pageInfoCategories = Category.getTabForCategoryName(initialSettings.categoryName)

	local newPageInfo = {
		categories = pageInfoCategories,
		categoryName = initialSettings.categoryName,
		creator = initialSettings.creator,
		searchTerm = initialSearchTerm,
		sortIndex = initialSelectedSortIndex,
		targetPage = 1,
		selectedBackgroundIndex = initialSelectedBackgroundIndex,
		requestReason = RequestReason.InitLoad,
	}

	local shouldGetGroups = pageInfoCategories == Category.INVENTORY or pageInfoCategories == Category.CREATIONS
	if shouldGetGroups then
		self.props.getToolboxManageableGroups(networkInterface, settings, newPageInfo)
	end

	-- TODO: we don't need to do this if we are showing the home view experiment

	-- Set the initial page info for the toolbox
	-- This will trigger a web request to load the first round of assets
	self.props.updatePageInfo(networkInterface, settings, newPageInfo)
end

function Toolbox:init(props)
	self.state = {
		toolboxWidth = math.max(props.initialWidth or 0, Constants.TOOLBOX_MIN_WIDTH),
		showSearchOptions = false,
		-- Keep track of the timestamp an asset was last inserted
		-- Allows us to track an analytic if a search is made and no asset is chosen
		mostRecentAssetInsertTime = not FFlagToolboxAssetGridRefactor and 0 or nil,
	}

	self.toolboxRef = Roact.createRef()

	-- If flag is on, use function that gets ref, else use old with rbx param
	self.onAbsoluteSizeChange = function()
		local toolboxWidth = math.max(self.toolboxRef.current.AbsoluteSize.x, Constants.TOOLBOX_MIN_WIDTH)
		if self.state.toolboxWidth ~= toolboxWidth then
			self:setState({
				toolboxWidth = toolboxWidth,
			})
		end
	end

	self:handleInitialSettings()

	self.toggleSearchOptions = function()
		local showSearchOptions = self.state.showSearchOptions

		if not showSearchOptions then
			Analytics.onSearchOptionsOpened()
		end

		if FFlagToolboxRefactorSearchOptions then
			getModal(self).onSearchOptionsToggled(not showSearchOptions)
		end

		self:setState({
			showSearchOptions = not showSearchOptions,
		})
	end

	local networkInterface = getNetwork(self)

	local function determineCategoryNameOnTabChange(tabName, newCategories)
		if Category.CREATIONS_KEY == tabName then
			for _, category in ipairs(newCategories) do
				local isSelectable = category and (nil == category.selectable or category.selectable) -- nil for selectable defalts to selectable true
				if isSelectable then
					return category.name
				end
			end
		end
		return newCategories[1].name
	end

	local function getCreatorOverrideIfNeeded(tabName)
		if showRobloxCreatedAssets() then
			if tabName == Category.MARKETPLACE_KEY then
				return Category.CREATOR_ROBLOX
			end
		end

		return nil
	end

	self.changeMarketplaceTab = function(tabName, optionsOverrides)
		-- Change tab will always set categoryName to the first category in the new tab.
		local newCategories = Category.getCategories(tabName, self.props.roles)
		local options = Cryo.Dictionary.join({
			categoryName = determineCategoryNameOnTabChange(tabName, newCategories),
			creator = getCreatorOverrideIfNeeded(tabName),
			searchTerm = "",
			sortIndex = 1,
			groupIndex = 0,
		}, optionsOverrides or {})
		local mySettings = self.props.Settings:get("Plugin")
		self.props.changeMarketplaceTab(networkInterface, tabName, newCategories, mySettings, options)

		local currentCategory = PageInfoHelper.getCategory(self.props.categoryName)

		local newCategory = PageInfoHelper.getCategory(options.categoryName)

		Analytics.onCategorySelected(currentCategory, newCategory)
	end

	if not FFlagToolboxAssetGridRefactor then
		self.updateMostRecentAssetTime = function()
			self:setState({
				mostRecentAssetInsertTime = tick(),
			})
		end
	end
end

function Toolbox:didMount()
	if self.toolboxRef.current then
		self.toolboxRef.current:GetPropertyChangedSignal("AbsoluteSize"):connect(self.onAbsoluteSizeChange)
	end

	self:handleInitialSettings()

	self.props.setRoles(getNetwork(self))

	self.props.getRobuxBalance(getNetwork(self))

	self._showPluginsConnection = self.props.pluginLoaderContext
			and self.props.pluginLoaderContext.signals["MemStorageService." .. SharedPluginConstants.SHOW_TOOLBOX_PLUGINS_EVENT]:Connect(
				function()
					local categoryName = Category.WHITELISTED_PLUGINS.name

					self.changeMarketplaceTab(Category.MARKETPLACE_KEY, {
						categoryName = categoryName,
					})

					Analytics.openedFromPluginManagement()
				end
			)
		or nil
end

function Toolbox:willUnmount()
	if self._showPluginsConnection then
		self._showPluginsConnection:Disconnect()
		self._showPluginsConnection = nil
	end
end

function Toolbox:render()
	local props = self.props
	local state = self.state

	local toolboxWidth = state.toolboxWidth
	local showSearchOptions = state.showSearchOptions

	local backgrounds = props.backgrounds
	local creator = props.creator
	local searchTerm = props.searchTerm
	local suggestions = props.suggestions or {}
	local categoryName = props.categoryName
	local currentTabKey = Category.getTabKeyForCategoryName(categoryName)

	local tryOpenAssetConfig = props.tryOpenAssetConfig
	local pluginGui = props.pluginGui

	local size = self.props.Size
	local toolboxTheme = self.props.Stylizer
	local localizedContent = props.Localization
	local locale = props.Localization.locale
	local ixp = props.IXP

	local onAbsoluteSizeChange = self.onAbsoluteSizeChange

	local tabHeight = Constants.TAB_WIDGET_HEIGHT
	local headerOffset = tabHeight

	local inHomeViewExperiment = false
	local selectedAssetType = if FFlagToolboxAssetCategorization4
		then Category.getEngineAssetType(Category.getCategoryByName(categoryName).assetType)
		else nil
	if
		FFlagToolboxAssetCategorization4
		and currentTabKey == Category.MARKETPLACE_KEY
		and table.find(HomeTypes.ENABLED_ASSET_TYPES, selectedAssetType) ~= nil
		and not ixp:isError()
		and (not creator or creator == "")
		and searchTerm == ""
	then
		if not ixp:isReady() then
			-- IXP state has not loaded yet, avoid a flash of (potentially) the wrong content
			return nil
		end
		local ixpVariables = ixp:getVariables()["MarketplaceHomeView"]
		if ixpVariables then
			inHomeViewExperiment = ixpVariables["HomeViewEnabled"]
		end
	end

	return Roact.createElement("Frame", {
		Position = UDim2.new(0, 0, 0, 0),
		Size = FFlagToolboxAssetGridRefactor and size or UDim2.new(1, 0, 1, 0),

		BorderSizePixel = 0,
		BackgroundColor3 = toolboxTheme.backgroundColor,

		[Roact.Ref] = self.toolboxRef,
		[Roact.Change.AbsoluteSize] = onAbsoluteSizeChange,
		[Roact.Event.MouseEnter] = props.onMouseEnter,
	}, {
		Tabs = Roact.createElement(TabSet, {
			Size = UDim2.new(1, 0, 0, Constants.TAB_WIDGET_HEIGHT),
			Tabs = getTabs(localizedContent),
			CurrentTab = currentTabKey,
			onTabSelected = self.changeMarketplaceTab,
		}),

		Header = Roact.createElement(Header, {
			Position = UDim2.new(0, 0, 0, headerOffset),
			maxWidth = toolboxWidth,
			onSearchOptionsToggled = self.toggleSearchOptions,
			pluginGui = pluginGui,
			mostRecentAssetInsertTime = not FFlagToolboxAssetGridRefactor and self.state.mostRecentAssetInsertTime
				or nil,
		}),

		MainView = if inHomeViewExperiment
			then Roact.createElement(HomeWrapper, {
				AssetType = selectedAssetType,
				CategoryName = categoryName,
				Locale = locale,
				Position = UDim2.new(0, 0, 0, headerOffset + Constants.HEADER_HEIGHT + 1),
				Size = UDim2.new(
					1,
					0,
					1,
					-(
							Constants.HEADER_HEIGHT
							+ (FFlagToolboxAssetStyleUpdate2 and 0 or Constants.FOOTER_HEIGHT)
							+ headerOffset
							+ 2
						)
				),
				SortName = Sort.getDefaultSortNameForCategory(categoryName),
				TryOpenAssetConfig = tryOpenAssetConfig,
			})
			else Roact.createElement(MainView, {
				Position = UDim2.new(0, 0, 0, headerOffset + Constants.HEADER_HEIGHT + 1),
				Size = UDim2.new(
					1,
					0,
					1,
					-(
							Constants.HEADER_HEIGHT
							+ (FFlagToolboxAssetStyleUpdate2 and 0 or Constants.FOOTER_HEIGHT)
							+ headerOffset
							+ 2
						)
				),

				maxWidth = toolboxWidth,
				suggestions = suggestions,
				showSearchOptions = if not FFlagToolboxRefactorSearchOptions then showSearchOptions else nil,
				onSearchOptionsToggled = if not FFlagToolboxRefactorSearchOptions
					then self.toggleSearchOptions
					else nil,
				tryOpenAssetConfig = tryOpenAssetConfig,
				mostRecentAssetInsertTime = not FFlagToolboxAssetGridRefactor and self.state.mostRecentAssetInsertTime
					or nil,
				onAssetInsertionSuccesful = not FFlagToolboxAssetGridRefactor and self.updateMostRecentAssetTime or nil,
			}),

		SearchOptions = if FFlagToolboxRefactorSearchOptions and showSearchOptions
			then Roact.createElement(SearchOptions, {
				onSearchOptionsToggled = self.toggleSearchOptions,
			})
			else nil,

		Footer = if not FFlagToolboxAssetStyleUpdate2
			then Roact.createElement(Footer, {
				backgrounds = backgrounds,
			})
			else nil,

		AudioPreview = Roact.createElement(SoundPreviewComponent),
	})
end

Toolbox = withContext({
	IXP = if FFlagToolboxAssetCategorization4 then IXPContext else nil,
	Stylizer = ContextServices.Stylizer,
	Localization = ContextServices.Localization,
	Settings = Settings,
})(Toolbox)

local function mapStateToProps(state, props)
	state = state or {}
	local pageInfo = state.pageInfo or {}

	return {
		categoryName = pageInfo.categoryName or Category.DEFAULT.name,
		creator = if FFlagToolboxAssetCategorization4 then pageInfo.creator else nil,
		roles = state.roles or {},
		searchTerm = if FFlagToolboxAssetCategorization4 then pageInfo.searchTerm or "" else nil,
		sorts = pageInfo.sorts or {},
	}
end

local function mapDispatchToProps(dispatch)
	return {
		setRoles = function(networkInterface)
			if FFlagDebugToolboxGetRolesRequest then
				dispatch(GetRolesDebugRequest(networkInterface))
			else
				dispatch(GetRolesRequest(networkInterface))
			end
		end,

		updatePageInfo = function(networkInterface, settings, newPageInfo)
			dispatch(UpdatePageInfoAndSendRequest(networkInterface, settings, newPageInfo))
		end,

		changeMarketplaceTab = function(networkInterface, tabName, newCategories, settings, options)
			dispatch(ChangeMarketplaceTab(networkInterface, tabName, newCategories, settings, options))
		end,

		getRobuxBalance = function(networkInterface)
			dispatch(GetRobuxBalance(networkInterface))
		end,

		getToolboxManageableGroups = function(networkInterface, settings, newPageInfo)
			dispatch(GetToolboxManageableGroupsRequest(networkInterface, settings, newPageInfo))
		end,
	}
end

return RoactRodux.connect(mapStateToProps, mapDispatchToProps)(Toolbox)
