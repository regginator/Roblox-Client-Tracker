local Workspace = game.Workspace
local PublishService = game:GetService("PublishService")

local Plugin = script.Parent.Parent.Parent

local ModelUtil = require(Plugin.Src.Util.ModelUtil)
local ItemCharacteristics = require(Plugin.Src.Util.ItemCharacteristics)

return function(editingItem, sourceItem)
	return function(store)
		if not editingItem then
			return
		end

		local state = store:getState()
		local pointData = state.cageData.pointData

		local clone = editingItem:Clone()

		-- temporary bug workaround: LC item needs to be a child of a model in order for cage editing to happen
		local tempModel
		local isClothes = ItemCharacteristics.isClothes(editingItem)
		if isClothes then
			tempModel = Instance.new("Model", Workspace)
			tempModel.Name = sourceItem.Name
			clone.Parent = tempModel
			clone.Name = "Handle"
			ModelUtil:deformClothing(clone, pointData, Enum.CageType.Inner)
			ModelUtil:deformClothing(clone, pointData, Enum.CageType.Outer)
		else
			clone.Parent = Workspace
			ModelUtil:deformAvatar(clone, pointData, Enum.CageType.Outer)
		end

		if isClothes then
			local weld = clone:FindFirstChildWhichIsA("WeldConstraint")
			weld:Destroy()
		end

		local newIdsInner = {}
		local newIdsOuter = {}
		local deformerToPartMap = ModelUtil:getDeformerToPartMap(clone, not isClothes)
		if isClothes then
			for _, deformer in pairs(deformerToPartMap) do
				local id = PublishService:PublishCageMeshAsync(deformer, Enum.CageType.Inner)
				newIdsInner[deformer] = id
			end
		end
		for _, deformer in pairs(deformerToPartMap) do
			local id = PublishService:PublishCageMeshAsync(deformer, Enum.CageType.Outer)
			newIdsOuter[deformer] = id
		end

		for _, desc in ipairs(clone:GetDescendants()) do
			if newIdsInner[desc] then
				desc.ReferenceMeshId = newIdsInner[desc]
			end
			if newIdsOuter[desc] then
				desc.CageMeshId = newIdsOuter[desc]
			end
		end

		ModelUtil:cleanupDeformerNames(tempModel, sourceItem)

		-- parent completed item to accessory instance
		if isClothes then
			local accessory = Instance.new("Accessory", Workspace)
			clone.Parent = accessory
			accessory.Name = tempModel.Name
			tempModel:Destroy()
		end
	end
end