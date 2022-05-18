
local Plugin = script.Parent.Parent.Parent
local _Types = require(Plugin.Src.Types)
local Roact = require(Plugin.Packages.Roact)
local RoactRodux = require(Plugin.Packages.RoactRodux)
local Framework = require(Plugin.Packages.Framework)

local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext
local Analytics = ContextServices.Analytics
local Localization = ContextServices.Localization

local Stylizer = Framework.Style.Stylizer

local UI = Framework.UI
local Pane = UI.Pane
local InfiniteScrollingGrid = UI.InfiniteScrollingGrid

local Actions = Plugin.Src.Actions
local SetMaterial = require(Actions.SetMaterial)

local Components = Plugin.Src.Components
local MaterialTile = require(Components.MaterialGrid.MaterialTile)

local Util = Plugin.Src.Util
local getMaterialPath = require(Util.getMaterialPath)
local ContainsPath = require(Util.ContainsPath)
local MaterialController = require(Util.MaterialController)

local getFFlagDevFrameworkInfiniteScrollingGridBottomPadding = require(Plugin.Src.Flags.getFFlagDevFrameworkInfiniteScrollingGridBottomPadding)

local MaterialGrid = Roact.PureComponent:extend("MaterialGrid")

export type Props = {
	LayoutOrder : number?,
	Size : UDim2?,
}

type _Props = Props & {
	Analytics : any,
	Localization : any,
	MaterialController : any,
	Path : _Types.Path,
	Stylizer : any,
	Search : string,
}

type _Style = {
	BackgroundColor : Color3,
	Padding : number,
}

type _MaterialTileStyle = {
	IconSize : UDim2,
	MaterialVariant : _Types.Image,
	MaterialVariantIconPosition : UDim2,
	MaxWidth : number,
	Padding : number,
	Size : UDim2,
	Spacing : number,
	StatusIconPosition : UDim2,
	TextLabelSize : UDim2,
	TextSize : number,
}
function MaterialGrid:init()
	self.onClick = function(item)
		self.props.dispatchSetMaterial(item)
	end

	self.renderTile = function (layoutOrder : number, item : _Types.Material)
		return Roact.createElement(MaterialTile, {
			Item = item,
			LayoutOrder = layoutOrder,
			OnClick = self.onClick,
			SetUpdate = function() end,
		})
	end

	self.setupMaterialConnections = function()
		local props : _Props = self.props

		self.materialAddedConnection = props.MaterialController:getMaterialAddedSignal():Connect(function(materialPath)
			if (ContainsPath(self.props.Path, materialPath)) then
				self:setState({
					materials = props.MaterialController:getMaterials(self.props.Path, self.props.Search)
				})
			end
		end)

		self.materialNameChangedConnection = props.MaterialController:getMaterialNameChangedSignal():Connect(function(materialVariant)
			if (ContainsPath(self.props.Path, getMaterialPath(materialVariant))) then
				self:setState({
					materials = props.MaterialController:getMaterials(self.props.Path, self.props.Search)
				})
			end
		end)

		self.materialRemovedConnection = props.MaterialController:getMaterialRemovedSignal():Connect(function(materialPath)
			if (ContainsPath(self.props.Path, materialPath)) then
				self:setState({
					materials = props.MaterialController:getMaterials(self.props.Path, self.props.Search)
				})
			end
		end)
	end


	self.state = {
		materials = {},
		lastSearchItem = nil,
		lastPath = nil,
	}
end

function MaterialGrid:willUnmount()
	if self.materialAddedConnection then
		self.materialAddedConnection:Disconnect()
		self.materialAddedConnection = nil
	end

	if self.materialNameChangedConnection then
		self.materialNameChangedConnection:Disconnect()
		self.materialNameChangedConnection = nil
	end

	if self.materialRemovedConnection then
		self.materialRemovedConnection:Disconnect()
		self.materialRemovedConnection = nil
	end
end

function MaterialGrid:didMount()
	local props : _Props = self.props

	if #self.state.materials == 0 then
		self:setState({
			materials = props.MaterialController:getMaterials(props.Path, props.Search)
		})
	end

	self.setupMaterialConnections()
end

function MaterialGrid:didUpdate(prevProps)
	local props : _Props = self.props

	if prevProps.Path ~= props.Path or prevProps.Search ~= props.Search then
		self:setState({
			materials = props.MaterialController:getMaterials(props.Path, props.Search)
		})
	end
end

function MaterialGrid:render()
	local props : _Props = self.props
	local style : _Style = props.Stylizer.MaterialGrid
	local materialTileStyle : _MaterialTileStyle = props.Stylizer.MaterialTile

	local layoutOrder = props.LayoutOrder
	local size = props.Size

	return Roact.createElement(Pane, {
		BackgroundColor = style.BackgroundColor,
		LayoutOrder = layoutOrder,
		Size = size
	}, {
		Grid = Roact.createElement(InfiniteScrollingGrid, {
			AbsoluteMax = #self.state.materials,
			CellPadding = if getFFlagDevFrameworkInfiniteScrollingGridBottomPadding() then
				UDim2.fromOffset(style.Padding, style.Padding)
				else
				UDim2.fromOffset(materialTileStyle.Padding, materialTileStyle.Padding),
			CellSize = materialTileStyle.Size,
			BufferedRows = 2,
			Items = self.state.materials,
			Loading = false,
			Padding = if getFFlagDevFrameworkInfiniteScrollingGridBottomPadding() then
				style.Padding
				else
				materialTileStyle.Padding,
			RenderItem = self.renderTile,
			Size = UDim2.fromScale(1, 1),
		})
	})
end

MaterialGrid = withContext({
	Analytics = Analytics,
	Localization = Localization,
	MaterialController = MaterialController,
	Stylizer = Stylizer,
})(MaterialGrid)

return RoactRodux.connect(
	function(state, props)
		return {
			Path = state.MaterialBrowserReducer.Path,
			Search = state.MaterialBrowserReducer.Search,
		}
	end,
	function(dispatch)
		return {
			dispatchSetMaterial = function(material)
				dispatch(SetMaterial(material))
			end,
		}
	end
)(MaterialGrid)
