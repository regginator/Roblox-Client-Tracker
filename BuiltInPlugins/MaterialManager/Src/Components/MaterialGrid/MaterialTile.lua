local Plugin = script.Parent.Parent.Parent.Parent
local _Types = require(Plugin.Src.Types)
local Roact = require(Plugin.Packages.Roact)
local RoactRodux = require(Plugin.Packages.RoactRodux)
local Framework = require(Plugin.Packages.Framework)

local ContextServices = Framework.ContextServices
local withContext = ContextServices.withContext
local Analytics = ContextServices.Analytics
local Localization = ContextServices.Localization

local Stylizer = Framework.Style.Stylizer

local prioritize = Framework.Util.prioritize

local UI = Framework.UI
local Button = UI.Button
local Container = UI.Container
local Image = UI.Decoration.Image
local Pane = UI.Pane
local TextLabel = UI.Decoration.TextLabel
local Tooltip = UI.Tooltip

local Components = Plugin.Src.Components
local MaterialPreview = require(Components.MaterialPreview)
local StatusIcon = require(Components.StatusIcon)

local Util = Plugin.Src.Util
local getFullMaterialType = require(Util.getFullMaterialType)
local MaterialController = require(Util.MaterialController)

-- TODO: cleaning up for the FFLagMaterialVariantTempIdCompatibility - remove all texture maps from that file
local getFFlagMaterialVariantTempIdCompatibility = require(Plugin.Src.Flags.getFFlagMaterialVariantTempIdCompatibility)
local getFFlagDevFrameworkInfiniteScrollingGridBottomPadding = require(Plugin.Src.Flags.getFFlagDevFrameworkInfiniteScrollingGridBottomPadding)

export type Props = {
	Item : _Types.Material,
	LayoutOrder : number?,
	OnClick : (material : _Types.Material) -> (),
	Padding : number?,
	SetUpdate : ((item : _Types.Material, layoutOrder : number?, property : string) -> ()),
	Size : UDim2?,
}

type _Props = Props & {
	Analytics : any,
	Localization : any,
	Material : _Types.Material,
	MaterialController : any,
	Stylizer : any,
}

type _Style = {
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

local MaterialTile = Roact.PureComponent:extend("MaterialTile")

function MaterialTile:init()
	self.onClick = function()
		local props : _Props = self.props

		props.OnClick(props.Item)
	end
end

function MaterialTile:willUnmount()
	if self.changedConnection then
		self.changedConnection:Disconnect()
		self.changedConnection = nil
	end

	if self.overrideStatusChangedConnection then
		self.overrideStatusChangedConnection:Disconnect()
		self.overrideStatusChangedConnection = nil
	end
end

function MaterialTile:didMount()
	local props : _Props = self.props

	self.changedConnection = props.MaterialController:getMaterialChangedSignal():Connect(function(materialVariant)
		local props : _Props = self.props

		if materialVariant == props.Item.MaterialVariant then
			self:setState({})
		end
	end)

	self.overrideStatusChangedConnection = props.MaterialController:getOverrideStatusChangedSignal():Connect(function(materialType)
		local props : _Props = self.props

		if props.Item.IsBuiltin and materialType == props.Item.MaterialVariant.BaseMaterial then
			self:setState({})
		end
	end)
end

function MaterialTile:render()
	local props : _Props = self.props
	local style : _Style = props.Stylizer.MaterialTile
	local localization = props.Localization

	local item = props.Item
	local materialVariant = item.MaterialVariant

	local colorMap = materialVariant.ColorMap
	local metalnessMap = materialVariant.MetalnessMap
	local name = if item.IsBuiltin then localization:getText("Materials", materialVariant.Name) else materialVariant.Name
	local normalMap = materialVariant.NormalMap
	local roughnessMap = materialVariant.RoughnessMap
	local fullMaterialType = getFullMaterialType(item, localization)

	local padding = prioritize(props.Padding, style.Padding)
	local size = prioritize(props.Size, style.Size)
	local spacing = style.Spacing
	local textSize = style.TextSize

	return Roact.createElement(Button, {
		LayoutOrder = props.LayoutOrder,
		OnClick = self.onClick,
		Style = if props.Material == item
			then "RoundActive"
			else "Round",
		Size = size,
	}, {
		Content = Roact.createElement(Pane, {
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			Layout = Enum.FillDirection.Vertical,
			Padding = padding * 2,
			Spacing = padding,
			Size = size,
		}, {
			MaterialPreview = getFFlagMaterialVariantTempIdCompatibility() and Roact.createElement(MaterialPreview, {
				LayoutOrder = 1,
				Material = materialVariant.BaseMaterial,
				MaterialVariant = if not item.IsBuiltin then materialVariant.Name else nil,
				Size = if getFFlagDevFrameworkInfiniteScrollingGridBottomPadding() then
					UDim2.fromOffset(160, 140)
					else
					UDim2.new(size.X.Scale, size.X.Offset - (2 * padding), size.Y.Scale,  size.Y.Offset - (2 * padding) - spacing - textSize),
				Static = true,
			}) or Roact.createElement(MaterialPreview, {
				ColorMap = colorMap,
				LayoutOrder = 1,
				Material = materialVariant.BaseMaterial,
				MaterialVariant = if not item.IsBuiltin then materialVariant.Name else nil,
				MetalnessMap = metalnessMap,
				NormalMap = normalMap,
				RoughnessMap = roughnessMap,
				Size = if getFFlagDevFrameworkInfiniteScrollingGridBottomPadding() then
					UDim2.fromOffset(160, 140)
					else
					UDim2.new(size.X.Scale, size.X.Offset - (2 * padding), size.Y.Scale,  size.Y.Offset - (2 * padding) - spacing - textSize),
				Static = true,
			}),
			NameLabel = Roact.createElement(Pane, {
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				Layout = Enum.FillDirection.Vertical,
				LayoutOrder = 2,
				Size = style.TextLabelSize,
			}, {
				Name = Roact.createElement(TextLabel, {
					FitMaxWidth = style.MaxWidth,
					Size = UDim2.fromScale(1, 1),
					Text = name,
					TextSize = textSize,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextWrapped = false,
				})
			})
		}),
		MaterialVariantIcon = if not item.IsBuiltin then
			Roact.createElement(Container, {
				LayoutOrder = 2,
				Position = style.MaterialVariantIconPosition,
				Size = style.IconSize,
				ZIndex = 2,
			}, {
				Image = Roact.createElement(Image, {
					Style = style.MaterialVariant,
				}),
				Tooltip = Roact.createElement(Tooltip, {
					Text = fullMaterialType,
				})
			})
			else nil,
		StatusIcon = if item.IsBuiltin then
			Roact.createElement(StatusIcon, {
				LayoutOrder = 3,
				Material = item,
				Position = style.StatusIconPosition,
				Size = style.IconSize,
				ZIndex = 2,
			})
			else nil
	})
end

MaterialTile = withContext({
	Analytics = Analytics,
	Localization = Localization,
	MaterialController = MaterialController,
	Stylizer = Stylizer,
})(MaterialTile)

return RoactRodux.connect(
	function(state, props)
		return {
			Material = state.MaterialBrowserReducer.Material,
		}
	end
)(MaterialTile)