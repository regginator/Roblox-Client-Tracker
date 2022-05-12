local PluginRoot = script.Parent.Parent.Parent.Parent
local Roact = require(PluginRoot.Packages.Roact)
local RoactRodux = require(PluginRoot.Packages.RoactRodux)
local Framework = require(PluginRoot.Packages.Framework)

local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext
local Analytics = ContextServices.Analytics
local Localization = ContextServices.Localization
local Plugin = ContextServices.Plugin

local StudioUI = Framework.StudioUI
local showContextMenu = StudioUI.showContextMenu

local Dash = Framework.Dash
local map = Dash.map
local join = Dash.join

local UI = Framework.UI
local TreeTable = UI.TreeTable
local Stylizer = Framework.Style.Stylizer
local Util = Framework.Util
local deepCopy = Util.deepCopy

local Models = PluginRoot.Src.Models
local TableTab = require(Models.Watch.TableTab)
local WatchRow = require(Models.Watch.WatchRow)
local StepStateBundle = require(Models.StepStateBundle)

local WatchHelperFunctions = require(PluginRoot.Src.Util.WatchHelperFunctions)

local Actions = PluginRoot.Src.Actions
local SetVariableExpanded = require(Actions.Watch.SetVariableExpanded)
local SetExpressionExpanded = require(Actions.Watch.SetExpressionExpanded)
local ChangeExpression = require(Actions.Watch.ChangeExpression)
local AddExpression = require(Actions.Watch.AddExpression)
local RemoveExpression = require(Actions.Watch.RemoveExpression)
local SetWatchSortState = require(Actions.Watch.SetWatchSortState)

local LazyLoadVariableChildren = require(PluginRoot.Src.Thunks.Watch.LazyLoadVariableChildren)
local ExecuteExpressionForAllFrames = require(PluginRoot.Src.Thunks.Watch.ExecuteExpressionForAllFrames)

local UtilFolder = PluginRoot.Src.Util
local MakePluginActions = require(UtilFolder.MakePluginActions)
local Constants = require(UtilFolder.Constants)

local FFlagDevFrameworkTableColumnResize = game:GetFastFlag("DevFrameworkTableColumnResize")
local FFlagDevFrameworkTableHeaderTooltip = game:GetFastFlag("DevFrameworkTableHeaderTooltip")
local hasTableColumnResizeFFlags = FFlagDevFrameworkTableColumnResize

local DisplayTable = Roact.PureComponent:extend("DisplayTable")

local VariableKeys = {
	[1] = "nameColumn",
	[2] = "scopeColumn",
	[3] = "valueColumn",
	[4] = "dataTypeColumn",
}

local WatchKeys = {
	[1] = "expressionColumn",
	[2] = "valueColumn",
	[3] = "dataTypeColumn",
}

type PathMapping = {
	[string] : WatchRow.WatchRow
}

-- Local Functions
local function populateRootItems(roots : {string}, flattenedTreeCopy : PathMapping)
	if (#roots == 0) then
		return {}
	end
	
	local toReturn = {}
	for index, path in ipairs(roots) do
		local rootData = nil
		if (flattenedTreeCopy[path]) then
			rootData = deepCopy(flattenedTreeCopy[path])
			local childrenData = populateRootItems(rootData.childPaths, flattenedTreeCopy)
			rootData.children = childrenData
		else
			-- this can happen after an expression is added but before it is evaluated
			rootData = WatchRow.fromExpression(path)
			rootData.children = {}
		end
		table.insert(toReturn, rootData)
	end
	return toReturn
end

local function populateExpansionTable(rowItems, expansionTable, storeExpansionTable)
	if (#rowItems == 0) then
		return
	end
	
	for index, rowItem in ipairs(rowItems) do
		expansionTable[rowItem] = storeExpansionTable[rowItem.pathColumn]
		populateExpansionTable(rowItem.children, expansionTable, storeExpansionTable)
	end
end

local function applyFilters(rootItems, flattenedTreeCopy)
	local toReturn = {}
	for index, rowItem in ipairs(rootItems) do
		if not flattenedTreeCopy[rowItem.pathColumn] or (not flattenedTreeCopy[rowItem.pathColumn].textFilteredOut and not flattenedTreeCopy[rowItem.pathColumn].scopeFilteredOut) then
			table.insert(toReturn, rowItem)
		end
	end
	return toReturn
end

local function useListOfExpressionsAsSOT(listOfExpressions : {string}, rootsList : {string}, flattenedTreeCopy : PathMapping)
	-- if an expression has been evaluated, use it's debuggerVariableId
	-- if it has not been evaluated, use its name
	-- if it was evaluated but no longer in the list of variables, don't use it
	local toReturn = deepCopy(listOfExpressions)
	for index, expression in ipairs(listOfExpressions) do
		for _, debugVarId in ipairs(rootsList) do 
			if flattenedTreeCopy[debugVarId] == nil then
				warn('debug variable id not found in store when constructing DisplayTable')
				return
			end
			if expression == flattenedTreeCopy[debugVarId].expressionColumn then
				toReturn[index] = debugVarId
				break
			end
		end
	end
	return toReturn
end

function DisplayTable:init()
	self.getTreeChildren = function(item)
		return item.children or {}
	end
	
	self.getVariableTableColumns = function()
		local localization = self.props.Localization
		return {
			{
				Name = localization:getText("Watch", "NameColumn"),
				Key = VariableKeys[1],
				Tooltip = FFlagDevFrameworkTableHeaderTooltip and localization:getText("Watch", "NameColumnTooltip") or nil,
			}, {
				Name = localization:getText("Watch", "ScopeColumn"),
				Key = VariableKeys[2],
				Tooltip = FFlagDevFrameworkTableHeaderTooltip and localization:getText("Watch", "ScopeColumnTooltip") or nil,
			}, {
				Name = localization:getText("Watch", "ValueColumn"),
				Key = VariableKeys[3],
				Tooltip = FFlagDevFrameworkTableHeaderTooltip and localization:getText("Watch", "ValueColumnTooltip") or nil,
			}, {
				Name = localization:getText("Watch", "DataTypeColumn"),
				Key = VariableKeys[4],
				Tooltip = FFlagDevFrameworkTableHeaderTooltip and localization:getText("Watch", "DataTypeColumnTooltip") or nil,
			}, 
		}
	end
	
	self.getWatchTableColumns = function()
		local localization = self.props.Localization
		return {
			{
				Name = localization:getText("Watch", "ExpressionColumn"),
				Key = WatchKeys[1],
			}, {
				Name = localization:getText("Watch", "ValueColumn"),
				Key = WatchKeys[2],
				Tooltip = FFlagDevFrameworkTableHeaderTooltip and localization:getText("Watch", "ValueColumnTooltip") or nil,
			}, {
				Name = localization:getText("Watch", "DataTypeColumn"),
				Key = WatchKeys[3],
				Tooltip = FFlagDevFrameworkTableHeaderTooltip and localization:getText("Watch", "DataTypeColumnTooltip") or nil,
			}, 
		}
	end
	
	local variableInitialSizes = {}
	if hasTableColumnResizeFFlags then 
		local numColumns = 4
		for i = 1, numColumns do
			table.insert(variableInitialSizes, UDim.new(1/(numColumns), 0))
		end
	end
	
	local myWatchInitialSizes = {}
	if hasTableColumnResizeFFlags then 
		local numColumns = 3
		for i = 1, numColumns do
			table.insert(myWatchInitialSizes, UDim.new(1/(numColumns), 0))
		end
	end
	
	self.state = {
		VariableColumnSizes = hasTableColumnResizeFFlags and variableInitialSizes,
		MyWatchColumnSizes = hasTableColumnResizeFFlags and myWatchInitialSizes,
	}
	
	self.OnColumnSizesChange = function(newSizes : {UDim})
		if hasTableColumnResizeFFlags then
			local props = self.props
			local isVariablesTab = props.SelectedTab == TableTab.Variables
			if isVariablesTab then
				self:setState(function(state)
					return { 
						VariableColumnSizes = newSizes
					}
				end)
			else
				self:setState(function(state)
					return { 
						MyWatchColumnSizes = newSizes
					}
				end)
			end
		end
	end
	
	self.onExpansionChange = function(newExpansion)
		local props = self.props
		local currentStepStateBundle = props.CurrentStepStateBundle
		local debuggerConnectionManager = game:GetService("DebuggerConnectionManager")
		if not currentStepStateBundle then
			assert(false)
			return
		end
		local debuggerConnection = debuggerConnectionManager:GetConnectionById(currentStepStateBundle.debuggerStateToken.debuggerConnectionId)
		for row, expandedBool in pairs(newExpansion) do
			local isVariablesTab = props.SelectedTab == TableTab.Variables
			if expandedBool then
				self.props.OnLazyLoadChildren(row.pathColumn, currentStepStateBundle, isVariablesTab, debuggerConnection)
			end
			if isVariablesTab then
				self.props.OnVariableExpansionDispatch(row.pathColumn, expandedBool)
			else
				self.props.OnExpressionExpansionDispatch(row.pathColumn, expandedBool)
			end
		end
	end
	
	self.IsDuplicateWatchEntry = function(watchString)
		for _, entry in ipairs(self.props.RootItems) do
			if entry.expressionColumn == watchString then
				return true
			end
		end
		return false
	end

	self.OnFocusLost = function(enterPress, inputObj, row, col)
		local oldExpression = row.item.expressionColumn
		local newExpression = inputObj.Text

		local currentStepStateBundle = self.props.CurrentStepStateBundle
		local debuggerConnectionManager = game:GetService("DebuggerConnectionManager")

		if col == 1 then
			if self.IsDuplicateWatchEntry(newExpression) then
				if oldExpression == "" then
					-- if we have inputted a duplicate entry, clear the input row
					inputObj.Text = ""
				elseif oldExpression ~= newExpression then
					-- remove the changed entry if it is the same as a previous entry
					self.props.OnRemoveExpression(oldExpression)
				end
				return
			end
			
			if oldExpression == "" and newExpression ~= "" then
				self.props.OnAddExpression(newExpression)
				if (currentStepStateBundle ~= nil) then
					local dst = currentStepStateBundle.debuggerStateToken
					if dst then
						local debuggerConnection = debuggerConnectionManager:GetConnectionById(dst.debuggerConnectionId)
						self.props.OnExecuteExpressionForAllFrames(newExpression, debuggerConnection, dst, currentStepStateBundle.threadId)
					end
				end
			elseif newExpression == "" then
				self.props.OnRemoveExpression(oldExpression)
			elseif oldExpression ~= newExpression then
				self.props.OnChangeExpression(oldExpression, newExpression)
				if (currentStepStateBundle ~= nil) then
					local dst = currentStepStateBundle.debuggerStateToken
					if dst then
						local debuggerConnection = debuggerConnectionManager:GetConnectionById(dst.debuggerConnectionId)
						self.props.OnExecuteExpressionForAllFrames(newExpression, debuggerConnection, dst, currentStepStateBundle.threadId)
					end					
				end
			end
		end
	end

	self.onMenuActionSelected = function(actionId, extraParameters)
		local _row = extraParameters.row
		if actionId == Constants.WatchActionIds.AddExpression then
			print('todo RIDE-5141')
		elseif actionId == Constants.WatchActionIds.EditExpression then
			print('todo RIDE-5141')
		end
	end

	self.onRightClick = function(row)
		if self.props.SelectedTab == TableTab.Watches then
			local props = self.props
			local localization = props.Localization
			local plugin = props.Plugin:get()
			local actions = MakePluginActions.getWatchActions(localization)
			showContextMenu(plugin, "Watch", actions, self.onMenuActionSelected, {row = row})
		end
	end

	self.OnDoubleClick = function(row)
		if self.props.SelectedTab == TableTab.Watches then
			local DebuggerUIService = game:GetService("DebuggerUIService")
			DebuggerUIService:EditWatch(row.item.expressionColumn)
		end
	end
	
	self.OnSortChange = function(index, sortOrder)
		local props = self.props
		local defaultSortOrder = props.SortOrder or sortOrder
		props.OnSetWatchSortState((props.SortIndex == index) and sortOrder or defaultSortOrder, index)
	end
	
	self.childSort = function(leftItem, rightItem)
		local tableToSort = {leftItem, rightItem}
		local props = self.props
		local isVariablesTab = props.SelectedTab == TableTab.Variables
		
		if leftItem == rightItem then
			return false
		end
		
		WatchHelperFunctions.sortTableByColumnAndOrder(tableToSort, props.SortIndex, props.SortOrder, 
			(isVariablesTab and VariableKeys or WatchKeys), false)
		return tableToSort[1] == leftItem
	end
end

function DisplayTable:render()
	local props = self.props
	local style = props.Stylizer	
	
	local isVariablesTab = props.SelectedTab == TableTab.Variables
	
	local tableColumns = (isVariablesTab and self.getVariableTableColumns() or self.getWatchTableColumns())
	
	if hasTableColumnResizeFFlags then
		tableColumns = map(tableColumns, function(column, index: number)
			if isVariablesTab then
				return join(column, {
					Width = self.state.VariableColumnSizes[index]
				})
			else
				return join(column, {
					Width = self.state.MyWatchColumnSizes[index]
				})
			end
		end)
	end
	
	local textInputCols = not isVariablesTab and {[1] = true} or nil
	return Roact.createElement(TreeTable, {
		Scroll = true,  
		Size = UDim2.fromScale(1, 1),
		Columns = tableColumns,
		RootItems = props.RootItems,
		Stylizer = style,
		OnExpansionChange = self.onExpansionChange,
		GetChildren = self.getTreeChildren,
		Expansion = props.ExpansionTable,
		OnFocusLost = self.OnFocusLost,
		TextInputCols = textInputCols,
		RightClick = self.onRightClick,
		OnDoubleClick = self.OnDoubleClick,
		DisableTooltip = false,
		SortIndex = props.SortIndex,
		SortOrder = props.SortOrder,
		OnSortChange = self.OnSortChange,
		SortChildren = self.childSort,
		OnColumnSizesChange = if hasTableColumnResizeFFlags then self.OnColumnSizesChange else nil,
		UseDeficit = if hasTableColumnResizeFFlags then false else nil,
		UseScale = if hasTableColumnResizeFFlags then true else nil,
		ClampSize = if hasTableColumnResizeFFlags then true else nil,
	})
end

-- RoactRoduxConnection
DisplayTable = withContext({
	Analytics = Analytics,
	Localization = Localization,
	Stylizer = Stylizer,
	Plugin = Plugin,
})(DisplayTable)

DisplayTable = RoactRodux.connect(
	function(state, props)
		local common = state.Common
		local watch = state.Watch
		local tabState = watch.currentTab
		local isVariablesTab = (tabState == TableTab.Variables)

		local threadId = common.debuggerConnectionIdToCurrentThreadId[common.currentDebuggerConnectionId]
		local frameNumber = threadId and common.currentFrameMap[common.currentDebuggerConnectionId][threadId] or nil
		local token = common.debuggerConnectionIdToDST[common.currentDebuggerConnectionId]
		local watchVars = token and watch.stateTokenToRoots[token] or nil

		local roots = watchVars and watchVars[threadId] and watchVars[threadId][frameNumber]
		local treeKey = isVariablesTab and "Variables" or "Watches"
		local rootsList = roots and (roots[treeKey] and deepCopy(roots[treeKey]) or {}) or {}

		local watchTree = watch.stateTokenToFlattenedTree[token]
		local tree = watchTree and watchTree[threadId] and watchTree[threadId][frameNumber]
		local flattenedTreeCopy = tree and (tree[treeKey] and deepCopy(tree[treeKey]) or {}) or {}

		if not isVariablesTab then
			rootsList = useListOfExpressionsAsSOT(watch.listOfExpressions, rootsList, flattenedTreeCopy)
		end

		local rootItems = populateRootItems(rootsList, flattenedTreeCopy)
		rootItems = applyFilters(rootItems, flattenedTreeCopy)
		local expansionTable = {}
		local storeExpansionTable = isVariablesTab and watch.pathToExpansionState or watch.expressionToExpansionState
		populateExpansionTable(rootItems, expansionTable, storeExpansionTable)

		if not isVariablesTab then
			table.insert(rootItems, WatchRow.fromExpression(""))
		end

		local tableColumns = (isVariablesTab and VariableKeys or WatchKeys)

		WatchHelperFunctions.sortTableByColumnAndOrder(rootItems or {}, watch.columnIndex, watch.sortDirection, tableColumns, (not isVariablesTab))

		return {
			SelectedTab = tabState,
			RootItems = rootItems or {},
			ExpansionTable = expansionTable,
			CurrentStepStateBundle = StepStateBundle.ctor(token,threadId,frameNumber),
			SortIndex = watch.columnIndex,
			SortOrder = watch.sortDirection
		}
	end,
	
	function(dispatch)
		return {
			OnVariableExpansionDispatch = function(path, expanded)
				return dispatch(SetVariableExpanded(path, expanded))
			end,
			OnExpressionExpansionDispatch = function(path, expanded)
				return dispatch(SetExpressionExpanded(path, expanded))
			end,
			OnChangeExpression = function(oldName, newName)
				return dispatch(ChangeExpression(oldName, newName))
			end,
			OnAddExpression = function(newExpression)
				return dispatch(AddExpression(newExpression))
			end,
			OnLazyLoadChildren = function(path, stepStateBundle, isExpression, debuggerConnection)
				return dispatch(LazyLoadVariableChildren(path, stepStateBundle, isExpression, debuggerConnection))
			end,
			OnExecuteExpressionForAllFrames = function(expression, debuggerConnection, dst, threadId)
				return dispatch(ExecuteExpressionForAllFrames(expression, debuggerConnection, dst, threadId))
			end,
			OnRemoveExpression = function(oldExpression)
				return dispatch(RemoveExpression(oldExpression))
			end,
			OnSetWatchSortState = function(sortDirection, columnIndex)
				return dispatch(SetWatchSortState(sortDirection, columnIndex))
			end,
		}
	end
)(DisplayTable)

return DisplayTable
