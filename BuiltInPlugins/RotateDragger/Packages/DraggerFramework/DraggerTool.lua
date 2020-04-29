--[[
	TODO: provide a high level description of DraggerTool and its properties.
]]

-- Services
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local StudioService = game:GetService("StudioService")

local Framework = script.Parent
local Library = Framework.Parent.Parent
local plugin = Library.Parent
local Roact = require(Library.Packages.Roact)

-- Flags
local getFFlagClearHoverBoxOnDelete = require(Framework.Flags.getFFlagClearHoverBoxOnDelete)
local getFFlagTrackAttachmentBounds = require(Framework.Flags.getFFlagTrackAttachmentBounds)
local getFFlagTrackMouseDownState = require(Framework.Flags.getFFlagTrackMouseDownState)
local getFFlagLuaDraggerIconBandaid = require(Framework.Flags.getFFlagLuaDraggerIconBandaid)

-- Components
local SelectionDot = require(Framework.Components.SelectionDot)

-- Utilities
local Math = require(Framework.Utility.Math)
local SelectionWrapper = require(Framework.Utility.SelectionWrapper)
local ViewChangeDetector = require(Framework.Utility.ViewChangeDetector)
local BoundsChangedTracker = require(Framework.Utility.BoundsChangedTracker)
local Analytics = require(Framework.Utility.Analytics)
local DerivedWorldState = require(Framework.Implementation.DerivedWorldState)
local HoverTracker = require(Framework.Implementation.HoverTracker)

-- States
local DraggerStateType = require(Framework.Implementation.DraggerStateType)
local DraggerStates = Framework.Implementation.DraggerStates
local DraggerState = {
	[DraggerStateType.Ready] = require(DraggerStates.Ready),
	[DraggerStateType.PendingDraggingParts] = require(DraggerStates.PendingDraggingParts),
	[DraggerStateType.DraggingHandle] = require(DraggerStates.DraggingHandle),
	[DraggerStateType.DraggingParts] = require(DraggerStates.DraggingParts),
	[DraggerStateType.DragSelecting] = require(DraggerStates.DragSelecting),
}

-- Constants
local DRAGGER_UPDATE_BIND_NAME = "DraggerToolViewUpdate"

local DraggerTool = Roact.PureComponent:extend("DraggerTool")

DraggerTool.defaultProps = {
	AllowDragSelect = true,
	AllowFreeformDrag = true,
	ShowSelectionDot = false,
	UseCollisionsTransparency = true,
}

local function areJointsEnabled()
    return Library.Parent:GetJoinMode() ~= Enum.JointCreationMode.None
end

local function isAltKeyDown()
	return UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)
end
local function isCtrlKeyDown()
	return UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
end
local function isShiftKeyDown()
	return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
end

function DraggerTool:init()
	self:setState({
		mainState = DraggerStateType.Ready,
		stateObject = DraggerState[DraggerStateType.Ready].new(),
	})

	self._isMounted = false
	if getFFlagTrackMouseDownState() then
		self._isMouseDown = false
	end

	self._derivedWorldState = DerivedWorldState.new()
	if getFFlagClearHoverBoxOnDelete() then
		local function onHoverExternallyChanged()
			self:_processViewChanged()
		end
		self._hoverTracker =
			HoverTracker.new(self.props.ToolImplementation, onHoverExternallyChanged)
	else
		self._hoverTracker = HoverTracker.new(self.props.ToolImplementation)
	end

	self._boundsChangedTracker = BoundsChangedTracker.new(function(part)
		self:_processPartBoundsChanged(part)
	end)

	self:_updateSelectionInfo()

	-- We also have to fire off an initial update, since the only update we do
	-- is in willUpdate, which isn't called during mounting.
	if self.props.ToolImplementation and self.props.ToolImplementation.update then
		self.props.ToolImplementation:update(self.state, self._derivedWorldState)
	end
end

function DraggerTool:didMount()
	self._isMounted = true
	local mouse = self.props.Mouse

	self._mouseDownConnection = mouse.Button1Down:Connect(function()
		self:_processMouseDown()
	end)
	self._mouseUpConnection = mouse.Button1Up:Connect(function()
		self:_processMouseUp()
	end)
	self._keyDownConnection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if input.UserInputType == Enum.UserInputType.Keyboard then
			self:_processKeyDown(input.KeyCode)
		end
	end)

	SelectionWrapper:init()
	self._boundsChangedTracker:install()

	self._selectionChangedConnection = SelectionWrapper.SelectionChangedByStudio:Connect(function()
		self:_processSelectionChanged()
	end)

	self._dragEnterConnection = mouse.DragEnter:Connect(function(instances)
		if #instances > 0 then
			self:_beginToolboxInitiatedFreeformSelectionDrag()
		end
	end)

	local viewChange = ViewChangeDetector.new(mouse)
	local lastUseLocalSpace = StudioService.UseLocalSpace
	RunService:BindToRenderStep(DRAGGER_UPDATE_BIND_NAME, Enum.RenderPriority.First.Value, function()
		if not self._isMounted then
			return
		end

		local shouldUpdateView = false
		local shouldUpdateSelection = false

		if viewChange:poll() then
			shouldUpdateView = true
		end

		if StudioService.UseLocalSpace ~= lastUseLocalSpace then
			-- Can't use a changed event for this, since Changed doesn't fire
			-- for changes to UseLocalSpace.
			shouldUpdateSelection = true
		end

		if RunService:IsRunning() then
			-- Must do a view update every frame in run mode to catch stuff
			-- moving under our mouse.
			shouldUpdateView = true

			-- If there's a physically simulated part in the selection then we
			-- have to update the whole selection every frame.
			local isDragging =
				self.state.mainState == DraggerStateType.DraggingHandle or
				self.state.mainState == DraggerStateType.DraggingParts
			if not isDragging then
				if self._derivedWorldState:doesSelectionHavePhysics() then
					shouldUpdateSelection = true
				end
			end
		end

		if shouldUpdateSelection then
			self:_processSelectionChanged()
		end
		if shouldUpdateView then
			self:_processViewChanged()
		end

		lastUseLocalSpace = StudioService.UseLocalSpace
	end)

	self:_analyticsSessionBegin()
end

function DraggerTool:willUnmount()
	self._isMounted = false

	if getFFlagTrackMouseDownState() then
		if self._isMouseDown then
			self:_processMouseUp()
		end
	end

	self._mouseDownConnection:Disconnect()
	self._mouseDownConnection = nil

	self._mouseUpConnection:Disconnect()
	self._mouseUpConnection = nil

	self._keyDownConnection:Disconnect()
	self._keyDownConnection = nil

	self._dragEnterConnection:Disconnect()
	self._dragEnterConnection = nil

	self._selectionChangedConnection:Disconnect()
	self._selectionChangedConnection = nil
	SelectionWrapper:destroy()
	self._boundsChangedTracker:uninstall()

	if getFFlagClearHoverBoxOnDelete() then
		self._hoverTracker:clearHover()
	end

	RunService:UnbindFromRenderStep(DRAGGER_UPDATE_BIND_NAME)

	self:_analyticsSendSession()
end

function DraggerTool:willUpdate(nextProps, nextState)
	if nextState.mainState == DraggerStateType.Ready or nextState.mainState == DraggerStateType.DraggingHandle then
		if nextProps.ToolImplementation and nextProps.ToolImplementation.update then
			nextProps.ToolImplementation:update(nextState, self._derivedWorldState)
		end
	end
end

function DraggerTool:render()
	local mouse = self.props.Mouse
	local selection = SelectionWrapper:Get()

	local coreGuiContent = {}

	if not getFFlagLuaDraggerIconBandaid() then
		-- Default mouse behavior if stateObject doesn't override it
		if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			if #selection > 0 then
				mouse.Icon = "rbxasset://textures/advClosed-hand.png"
			else
				mouse.Icon = "rbxasset://textures/advCursor-openedHand.png"
			end
		else
			mouse.Icon = "rbxasset://textures/advCursor-openedHand.png"
		end
	end

	-- State specific rendering code
	coreGuiContent.StateSpecificUI = self.state.stateObject:render(self)

	-- All states: Render selection dot.
	local showSelectionDot = self.props.ShowSelectionDot and #selection > 0
	if showSelectionDot then
		local boundingBox = Math.regionFromParts(selection)
		coreGuiContent.SelectionDot = Roact.createElement(SelectionDot, {
			BackgroundColor3 = self.props.SelectionDotColor,
			Position = boundingBox.CFrame.Position,
			Size = self.props.SelectionDotSize,
		})
	end

	return Roact.createElement(Roact.Portal, {
		target = CoreGui
	}, coreGuiContent)
end

--[[
	Called by the main DraggerTool code, and the code in individual DraggerTool
	main states in order to transition to a new state.

	* otherState is the additional Roact component state to set other than the
	  mainState during the state transition.

	* The variable arguments are passed as arguments to the constructor of the
	  new state object which will be constructed and transitioned to.
]]
function DraggerTool:transitionToState(otherState, draggerStateType, ...)
	if getFFlagTrackMouseDownState() then
		if not self._isMounted then
			return
		end
	end

	otherState.mainState = draggerStateType
	otherState.stateObject = DraggerState[draggerStateType].new(self, ...)
	self:setState(otherState)
end

function DraggerTool:_scheduleRender()
	if self._isMounted then
		self:setState({}) -- Force a rerender
	end
end

function DraggerTool:_processSelectionChanged()
	self.state.stateObject:processSelectionChanged(self)
	self:_updateSelectionInfo()
end

function DraggerTool:_processKeyDown(keyCode)
	self.state.stateObject:processKeyDown(self, keyCode)
end

function DraggerTool:_processMouseDown()
	if getFFlagTrackMouseDownState() then
		assert(not self._isMouseDown)
		self._isMouseDown = true
	end
	self.state.stateObject:processMouseDown(self)
end

function DraggerTool:_processMouseUp()
	if getFFlagTrackMouseDownState() then
		-- This condition can be hit when the tool was selected while the mouse
		-- was being held down. In that case it's a spurious mouse up that we
		-- should ignore.
		if not self._isMouseDown then
			return
		end
		self._isMouseDown = false
	end
	self.state.stateObject:processMouseUp(self)
end

--[[
	Called when the camera or mouse position changes, i.e., the world position
	currently under the mouse cursor has changed.
]]
function DraggerTool:_processViewChanged()
	self._derivedWorldState:updateView()
	self._hoverTracker:update(self._derivedWorldState)

	self.state.stateObject:processViewChanged(self)

	-- Derived world state may have changed as a result of the view update, so
	-- we need to manually trigger a re-render here.
	if getFFlagTrackMouseDownState() then
		self:_scheduleRender()
	else
		self:setState({})
	end
end

--[[
	Called when the user sets the size or position of one of the parts we have
	selected, thus requiring an update to the bounding box.
]]
function DraggerTool:_processPartBoundsChanged(part)
	-- Unfortunately there's no simple way to incrementally update the bounding
	-- box selection, so we just recalculate it from scratch here by triggering
	-- a selection changed.
	self:_processSelectionChanged()
end

function DraggerTool:_updateSelectionInfo()
	self._derivedWorldState:updateSelectionInfo()
	self._hoverTracker:update(self._derivedWorldState)
	if getFFlagTrackAttachmentBounds() then
		local allAttachments = self._derivedWorldState:getAllSelectedAttachments()
		self._boundsChangedTracker:setAttachments(allAttachments)
	end
	self._boundsChangedTracker:setParts(self._derivedWorldState:getObjectsToTransform())

	if getFFlagTrackMouseDownState() then
		self:_scheduleRender()
	else
		self:setState({}) -- Force a re-render
	end
end

function DraggerTool:_beginToolboxInitiatedFreeformSelectionDrag()
	self:transitionToState({
		tiltRotate = CFrame.new(),
	}, DraggerStateType.DraggingParts, {
		mouseLocation = UserInputService:GetMouseLocation(),
		basisPoint = Vector3.new(), -- Just drag from the center of the object
		clickPoint = Vector3.new(),
	})
end

function DraggerTool:_analyticsSessionBegin()
	self._selectedAtTime = tick()
	self._sessionAnalytics = {
		freeformDrags = 0,
		handleDrags = 0,
		clickSelects = 0,
		dragSelects = 0,
		dragTilts = 0,
		dragRotates = 0,
		toolName = self.props.AnalyticsName,
	}
	Analytics:sendEvent("toolSelected", {
		toolName = self.props.AnalyticsName,
	})
	Analytics:reportCounter("studioLua"..self.props.AnalyticsName.."DraggerSelected")
end

function DraggerTool:_analyticsSendSession()
	local totalTime = tick() - self._selectedAtTime
	self._sessionAnalytics.duration = totalTime
	Analytics:sendEvent("toolSession", self._sessionAnalytics)
end

function DraggerTool:_analyticsSendClick(clickedInstance, didChangeSelection)
	Analytics:sendEvent("clickedObject", {
		altPressed = isAltKeyDown(),
		ctrlPressed = isCtrlKeyDown(),
		shiftPressed = isShiftKeyDown(),
		clickedAttachment = clickedInstance and clickedInstance:IsA("Attachment"),
		clickedConstraint = clickedInstance and
			(clickedInstance:IsA("Constraint") or clickedInstance:IsA("WeldConstraint")),
		didAlterSelection = didChangeSelection,
	})
	if didChangeSelection then
		self._sessionAnalytics.clickSelects = self._sessionAnalytics.clickSelects + 1
	end
end

function DraggerTool:_analyticsRecordFreeformDragBegin(timeToStartDrag)
	self._sessionAnalytics.freeformDrags = self._sessionAnalytics.freeformDrags + 1
	self._dragAnalytics = {
		dragTilts = 0,
		dragRotates = 0,
		partCount = #self._derivedWorldState:getObjectsToTransform(),
		timeToStartDrag = timeToStartDrag,
	}
	self._dragStartLocation = nil
	Analytics:reportStats("studioLuaDraggerDragTime", timeToStartDrag)
end

function DraggerTool:_analyticsRecordFreeformDragUpdate(dragTarget)
	if dragTarget then
		self._dragAnalytics.dragTargetType = dragTarget.dragTargetType
		if self._dragStartLocation then
			self._dragAnalytics.dragDistance =
				(dragTarget.mainCFrame.Position - self._dragStartLocation).Magnitude
		else
			self._dragAnalytics.dragDistance = 0
			self._dragStartLocation = dragTarget.mainCFrame.Position
		end
		self._dragAnalytics.distanceToCamera =
			(Workspace.CurrentCamera.CFrame.Position - dragTarget.mainCFrame.Position).Magnitude
	else
		self._dragAnalytics.dragTargetType = "Failed"
	end
end

function DraggerTool:_analyticsSendFreeformDragged()
	self._dragAnalytics.gridSize = StudioService.GridSize
	self._dragAnalytics.toolName = self.props.AnalyticsName
	self._dragAnalytics.joinSurfaces = areJointsEnabled()
	self._dragAnalytics.useConstraints = StudioService.DraggerSolveConstraints
	Analytics:sendEvent("freeformDragged", self._dragAnalytics)
end

function DraggerTool:_analyticsSendHandleDragged()
	Analytics:sendEvent("handleDragged", {
		toolName = self.props.AnalyticsName,
		useLocalSpace = StudioService.UseLocalSpace,
		joinSurfaces = areJointsEnabled(),
		useConstraints = StudioService.DraggerSolveConstraints,
		haveCollisions = plugin.CollisionEnabled,
	})
end

function DraggerTool:_analyticsSendBoxSelect()
	Analytics:sendEvent("boxSelected", {
		toolName = self.props.AnalyticsName,
		objectCount = #SelectionWrapper:Get(),
	})
end

function DraggerTool:_analyticsSendFaceInstanceSelected()
	Analytics:sendEvent("faceInstanceSelected", {
		toolName = self.props.AnalyticsName,
	})
end

return DraggerTool
