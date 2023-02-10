local Loading = script.Parent
local App = Loading.Parent
local UIBlox = App.Parent
local Packages = UIBlox.Parent

local Roact = require(Packages.Roact)
local t = require(Packages.t)
local Cryo = require(Packages.Cryo)

local ShimmerPanel = require(Loading.ShimmerPanel)
local DebugProps = require(Loading.Enum.DebugProps)
local LoadingStrategy = require(Loading.Enum.LoadingStrategy)
local withStyle = require(UIBlox.Core.Style.withStyle)

local Images = require(UIBlox.App.ImageSet.Images)
local ImageSetComponent = require(UIBlox.Core.ImageSet.ImageSetComponent)

local ContentProviderContext = require(UIBlox.App.Context.ContentProvider)

local devOnly = require(UIBlox.Utility.devOnly)

local LOAD_FAILED_RETRY_COUNT = 3
local RETRY_TIME_MULTIPLIER = 1.5
local DEFAULT_IMAGE_AWAIT_TIMEOUT_IN_SECONDS = 30

local decal = Instance.new("Decal")
local inf = math.huge
local loadedImagesByUri = {}

local LoadingState = {
	InProgress = "InProgress",
	Failed = "Failed",
	Loaded = "Loaded",
}

local function shouldLoadImage(image)
	return image ~= nil and loadedImagesByUri[image] == nil
end

local LoadableImage = Roact.PureComponent:extend("LoadableImage")

local validateProps = devOnly(t.strictInterface({
	-- The anchor point of the final and loading image
	AnchorPoint = t.optional(t.Vector2),
	-- The background color of the final image. Defaults to placeholder background color.
	BackgroundColor3 = t.optional(t.Color3),
	-- The background transparency of the final image. Defaults to placeholder transparency.
	BackgroundTransparency = t.optional(t.number),
	-- The corner radius of the image, shimmer, and failed image's rounded corners.
	cornerRadius = t.optional(t.UDim),
	-- The final image
	Image = t.optional(t.union(t.string, t.table)),
	-- Coloration for final image when loaded
	ImageColor3 = t.optional(t.Color3),
	-- The transparency of the final and loading image
	ImageTransparency = t.optional(t.number),
	-- The image rect offset of the final and loading image
	ImageRectOffset = t.optional(t.union(t.Vector2, t.table)),
	-- The image rect size of the final and loading image
	ImageRectSize = t.optional(t.union(t.Vector2, t.table)),
	-- The layout order of the final and loading image
	LayoutOrder = t.optional(t.integer),
	-- The loading image which shows if useShimmerAnimationWhileLoading is false
	loadingImage = t.optional(t.union(t.string, t.table)),
	-- The timing when image starts loading (Eager = on component, Default = leave up to game engine to decide)
	loadingStrategy = t.optional(LoadingStrategy.isEnumValue),
	-- The maximum time in seconds to wait for the image to load by game engine before it's considered an error.
	loadingTimeout = t.optional(t.numberPositive),
	-- A render function to run while loading (overrides useShimmerAnimationWhileLoading and loadingImage)
	renderOnLoading = t.optional(t.callback),
	-- A render function to run when loading fails
	renderOnFailed = t.optional(t.callback),
	-- The max size of all images shown
	MaxSize = t.optional(t.Vector2),
	-- The min size of all images shown
	MinSize = t.optional(t.Vector2),
	-- The function to call when loading is complete
	onLoaded = t.optional(t.callback),
	-- The position point of the loading image
	Position = t.optional(t.UDim2),
	-- The scale type of the final and loading image
	ScaleType = t.optional(t.enum(Enum.ScaleType)),
	-- The size point of the loading image
	Size = t.UDim2,
	-- Whether or not to show a static image or the shimmer animation while loading
	useShimmerAnimationWhileLoading = t.optional(t.boolean),
	-- Whether to show failed state when failed
	showFailedStateWhenLoadingFailed = t.optional(t.boolean),
	-- The ZIndex of the loading and final images
	ZIndex = t.optional(t.integer),

	contentProvider = t.union(t.instanceOf("ContentProvider"), t.table),

	[DebugProps.forceLoading] = t.optional(t.boolean),
	[DebugProps.forceFailed] = t.optional(t.boolean),
}))

LoadableImage.defaultProps = {
	BackgroundTransparency = 0,
	cornerRadius = UDim.new(0, 0),
	MaxSize = Vector2.new(inf, inf),
	MinSize = Vector2.new(0, 0),
	useShimmerAnimationWhileLoading = false,
	showFailedStateWhenLoadingFailed = false,
	loadingStrategy = LoadingStrategy.Eager,
	loadingTimeout = DEFAULT_IMAGE_AWAIT_TIMEOUT_IN_SECONDS,
}

function LoadableImage:init()
	self.state = {
		loadingState = loadedImagesByUri[self.props.Image] and LoadingState.Loaded or LoadingState.InProgress,
	}
	self.imageRef = Roact.createRef()
	self._isMounted = false
	self._hasStartedLoading = false

	self.isLoadingComplete = function(image)
		if image == Roact.None or image == nil then
			return false
		else
			return self.state.loadingState ~= LoadingState.InProgress
		end
	end

	self.defaultRenderOnFail = function(theme, sizeConstraint)
		local cornerRadius = self.props.cornerRadius

		local failedImage = Images["icons/status/imageunavailable"]
		local failedImageSize = failedImage.ImageRectSize / Images.ImagesResolutionScale

		return Roact.createElement("Frame", {
			AnchorPoint = self.props.AnchorPoint,
			BorderSizePixel = 0,
			BackgroundColor3 = theme.PlaceHolder.Color,
			BackgroundTransparency = theme.PlaceHolder.Transparency,
			LayoutOrder = self.props.LayoutOrder,
			Position = self.props.Position,
			Size = self.props.Size,
			ZIndex = self.props.ZIndex,
		}, {
			EmptyIcon = Roact.createElement(ImageSetComponent.Label, {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = failedImage,
				ImageColor3 = theme.UIDefault.Color,
				ImageTransparency = theme.UIDefault.Transparency,
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, failedImageSize.X, 0, failedImageSize.Y),
			}, {
				UICorner = cornerRadius ~= UDim.new(0, 0) and Roact.createElement("UICorner", {
					CornerRadius = cornerRadius,
				}) or nil,
			}),
			UISizeConstraint = sizeConstraint,
			UICorner = cornerRadius ~= UDim.new(0, 0) and Roact.createElement("UICorner", {
				CornerRadius = cornerRadius,
			}) or nil,
		})
	end

	self.renderShimmer = function(theme, sizeConstraint)
		return Roact.createElement("Frame", {
			AnchorPoint = self.props.AnchorPoint,
			BorderSizePixel = 0,
			BackgroundColor3 = theme.PlaceHolder.Color,
			BackgroundTransparency = theme.PlaceHolder.Transparency,
			LayoutOrder = self.props.LayoutOrder,
			Position = self.props.Position,
			Size = self.props.Size,
			ZIndex = self.props.ZIndex,
		}, {
			Shimmer = Roact.createElement(ShimmerPanel, {
				Size = UDim2.new(1, 0, 1, 0),
				cornerRadius = self.props.cornerRadius,
			}),
			UISizeConstraint = sizeConstraint,
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = self.props.cornerRadius,
			}) or nil,
		})
	end
end

function LoadableImage:render()
	assert(validateProps(self.props))

	local anchorPoint = self.props.AnchorPoint
	local layoutOrder = self.props.LayoutOrder
	local size = self.props.Size
	local position = self.props.Position
	local backgroundColor3 = self.props.BackgroundColor3
	local backgroundTransparency = self.props.BackgroundTransparency
	local cornerRadius = self.props.cornerRadius
	local scaleType = self.props.ScaleType
	local zIndex = self.props.ZIndex
	local image = self.props.Image
	local imageTransparency = self.props.ImageTransparency
	local imageRectOffset = self.props.ImageRectOffset
	local imageRectSize = self.props.ImageRectSize
	local imageColor3 = self.props.ImageColor3
	local maxSize = self.props.MaxSize
	local minSize = self.props.MinSize
	local renderOnLoading = self.props.renderOnLoading
	local renderOnFailed = self.props.renderOnFailed
	local loadingImage = self.props.loadingImage
	local loadingStrategy = self.props.loadingStrategy
	local useShimmerAnimationWhileLoading = self.props.useShimmerAnimationWhileLoading
	local showFailedStateWhenLoadingFailed = self.props.showFailedStateWhenLoadingFailed
	local loadingComplete = self.isLoadingComplete(image)
	local loadingFailed = loadingComplete and self.state.loadingState == LoadingState.Failed
	local hasUISizeConstraint = false

	if self.props[DebugProps.forceLoading] then
		loadingComplete = false
	end
	if self.props[DebugProps.forceFailed] then
		loadingFailed = true
	end

	if maxSize.X ~= inf or maxSize.Y ~= inf or minSize.X ~= 0 or minSize.Y ~= 0 then
		hasUISizeConstraint = true
	end

	local sizeConstraint = hasUISizeConstraint
		and Roact.createElement("UISizeConstraint", {
			MaxSize = maxSize,
			MinSize = minSize,
		})

	return withStyle(function(stylePalette)
		local theme = stylePalette.Theme

		if loadingFailed and renderOnFailed then
			return renderOnFailed()
		elseif loadingFailed and showFailedStateWhenLoadingFailed then
			return self.defaultRenderOnFail(theme, sizeConstraint)
		elseif not loadingComplete and renderOnLoading and loadingStrategy ~= LoadingStrategy.Default then
			return renderOnLoading()
		elseif
			not loadingComplete
			and useShimmerAnimationWhileLoading
			and loadingStrategy ~= LoadingStrategy.Default
		then
			return self.renderShimmer(theme, sizeConstraint)
		else
			-- Default strategy requires the Image property to be populated in order for the engine to fetch it
			local shouldDisplayImage = loadingComplete or loadingStrategy == LoadingStrategy.Default
			return Roact.createElement(ImageSetComponent.Label, {
				AnchorPoint = anchorPoint,
				BackgroundColor3 = backgroundColor3 or theme.PlaceHolder.Color,
				BackgroundTransparency = backgroundTransparency or theme.PlaceHolder.Transparency,
				BorderSizePixel = 0,
				Image = shouldDisplayImage and image or loadingImage,
				ImageTransparency = imageTransparency,
				ImageRectOffset = imageRectOffset,
				ImageRectSize = imageRectSize,
				ImageColor3 = shouldDisplayImage and imageColor3 or nil,
				LayoutOrder = layoutOrder,
				Position = position,
				ScaleType = scaleType,
				Size = size,
				ZIndex = zIndex,
				[Roact.Ref] = self.imageRef,
			}, {
				UISizeConstraint = sizeConstraint,
				UICorner = cornerRadius ~= UDim.new(0, 0) and Roact.createElement("UICorner", {
					CornerRadius = cornerRadius,
				}) or nil,
				OnLoading = if not loadingComplete
						and renderOnLoading
						and loadingStrategy == LoadingStrategy.Default
					then renderOnLoading()
					else nil,
				Shimmer = if not loadingComplete
						and useShimmerAnimationWhileLoading
						and loadingStrategy == LoadingStrategy.Default
					then self.renderShimmer(theme, sizeConstraint)
					else nil,
			})
		end
	end)
end

function LoadableImage:didUpdate(oldProps)
	if oldProps.Image ~= self.props.Image then
		self:_loadImage()
	end
end

function LoadableImage:didMount()
	self._isMounted = true

	self:_loadImage()
end

function LoadableImage:willUnmount()
	self._isMounted = false
end

function LoadableImage:_awaitImageLoaded()
	if self.imageRef then
		local image = self.imageRef:getValue()
		if image then
			image.Changed:Connect(function(prop)
				if prop == "IsNotOccluded" and image.IsNotOccluded and not self._hasStartedLoading then
					-- Image became visible for the first time
					self._hasStartedLoading = true
				end
			end)

			while not self._hasStartedLoading do
				task.wait()
			end

			local timeoutAt = os.clock() + self.props.loadingTimeout
			while not image.IsLoaded and os.clock() < timeoutAt do
				task.wait()
			end
			return image.IsLoaded
		end
	end
	return nil
end

function LoadableImage:_preloadAsyncImage()
	local image = self.props.Image
	local retryCount = 0
	local loadingFailed

	while loadedImagesByUri[image] == nil and retryCount <= LOAD_FAILED_RETRY_COUNT do
		if retryCount > 0 then
			wait(RETRY_TIME_MULTIPLIER * math.pow(2, retryCount - 1))
		end

		loadingFailed = false
		decal.Texture = image

		self.props.contentProvider:PreloadAsync({ decal }, function(contentId, assetFetchStatus)
			if contentId == image and assetFetchStatus == Enum.AssetFetchStatus.Failure then
				loadingFailed = true
			end
		end)

		-- Image load succeeded, no retry required
		if not loadingFailed then
			break
		end

		retryCount = retryCount + 1
	end

	return loadingFailed
end

function LoadableImage:_loadImage()
	local image = self.props.Image
	local loadingStrategy = self.props.loadingStrategy

	if shouldLoadImage(image) then
		self:setState({
			loadingState = LoadingState.InProgress,
		})
	else
		if loadedImagesByUri[image] then
			self:setState({
				loadingState = LoadingState.Loaded,
			})
		elseif loadedImagesByUri[image] == false then
			self:setState({
				loadingState = LoadingState.Failed,
			})
		end
		return
	end

	-- Synchronization/Batching work should be done in engine for performance improvements
	-- related ticket: CLIPLAYEREX-1764
	coroutine.wrap(function()
		local loadingFailed
		if loadingStrategy == LoadingStrategy.Eager then
			loadingFailed = self:_preloadAsyncImage()
		elseif loadingStrategy == LoadingStrategy.Default then
			loadingFailed = not self:_awaitImageLoaded()
		end

		if loadingFailed == nil then
			loadingFailed = not loadedImagesByUri[image]
		else
			loadedImagesByUri[image] = not loadingFailed
		end

		if self._isMounted and self.props.Image == image then
			self:setState({
				loadingState = loadingFailed and LoadingState.Failed or LoadingState.Loaded,
			})

			if self.props.onLoaded then
				self.props.onLoaded()
			end
		end
	end)()
end

function LoadableImage.isLoaded(image)
	if image == Roact.None or image == nil then
		return false
	else
		return loadedImagesByUri[image] == true
	end
end

return function(props)
	return Roact.createElement(ContentProviderContext.Consumer, {
		render = function(contentProvider)
			local propsWithContentProvider = Cryo.Dictionary.join(props, {
				contentProvider = contentProvider,
			})

			return Roact.createElement(LoadableImage, propsWithContentProvider)
		end,
	})
end
