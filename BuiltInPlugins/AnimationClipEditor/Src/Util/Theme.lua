local Plugin = script.Parent.Parent.Parent
local Cryo = require(Plugin.Packages.Cryo)
local Framework = require(Plugin.Packages.Framework)
local Util = Framework.Util
local THEME_REFACTOR = Util.RefactorFlags.THEME_REFACTOR
local StyleModifier = Util.StyleModifier
local StyleTable = Util.StyleTable
local Style = Framework.Style
local StudioTheme = Style.Themes.StudioTheme
local StyleKey = Style.StyleKey
local Colors = Style.Colors
local UI = Framework.UI
local Decoration = UI.Decoration
local LightTheme = Style.Themes.LightTheme
local DarkTheme = Style.Themes.DarkTheme

-- Add new entries to both themes
local overridedLightTheme = Cryo.Dictionary.join(LightTheme, {
	[StyleKey.DialogButtonTextDisabled] = Color3.fromRGB(184, 184, 184),
	-- Track
	[StyleKey.TrackShadedBackgroundColor] = Color3.fromRGB(243, 243, 243),
	[StyleKey.TrackTitleBackgroundColor] = Color3.fromRGB(227, 227, 227),
	[StyleKey.TrackPrimaryBackgroundColor] = Color3.fromRGB(243, 243, 243),
	[StyleKey.TrackButtonColor] = Color3.fromRGB(136, 136, 136),
	[StyleKey.TrackHoveredButtonColor] = Colors.Blue,
	[StyleKey.TrackAddButtonColor] = Colors.Gray_Light,
	[StyleKey.TrackHoveredAddButtonColor] = Colors.Blue,
	[StyleKey.TrackPlusIconColor] = Color3.fromRGB(82, 82, 82),
	-- Timeline
	[StyleKey.TimelineDimmedColor] = Colors.Gray_Light,
	[StyleKey.TimelineBackgroundColor] = Color3.fromRGB(243, 243, 243),
	-- Keyframe
	[StyleKey.KeyframePrimaryClusterColor] = Color3.fromRGB(136, 136, 136),
	-- EventMarker
	[StyleKey.EventMarkerImageColor] = Color3.fromRGB(184, 184, 184),
	[StyleKey.EventMarkerBorderColor] = Color3.fromRGB(136, 136, 136),
	-- ScrollBar
	[StyleKey.ScrollBarControl] = Colors.White,
	[StyleKey.ScrollBarHover] = Color3.fromRGB(231, 240, 250),
	[StyleKey.ScrollBarPressed] = Color3.fromRGB(224, 224, 224),
	-- StartScreen
	[StyleKey.StartScreenDarkTextColor] = Colors.White,
	-- IK
	[StyleKey.IKHeaderColor] = Color3.fromRGB(243, 243, 243),
	[StyleKey.IKHeaderBorder] = Color3.fromRGB(243, 243, 243),
	-- Keyframes
	[StyleKey.KeyframePrimaryBackgroundColor] = Colors.White,
	[StyleKey.KeyframePrimaryBackgroundColorSelected] = Colors.White,
	[StyleKey.KeyframeErrorBackgroundColor] = Color3.fromRGB(255, 161, 161),
	[StyleKey.KeyframeErrorBorderColor] = Color3.fromRGB(168, 132, 132),
	[StyleKey.KeyframeErrorBackgroundColorSelected] = Color3.fromRGB(255, 161, 161),
	[StyleKey.KeyframeErrorBorderColorSelected] = Colors.Red,
	[StyleKey.KeyframePrimaryErrorBackgroundColor] = Color3.fromRGB(255, 161, 161),
	[StyleKey.KeyframePrimaryErrorBorderColor] = Color3.fromRGB(168, 132, 132),
	[StyleKey.KeyframePrimaryErrorBackgroundColorSelected] = Color3.fromRGB(255, 161, 161),
	[StyleKey.KeyframePrimaryErrorBorderColorSelected] = Colors.Red,
	-- Curves
	[StyleKey.CurveX] = Color3.fromRGB(255, 0, 0),
	[StyleKey.CurveY] = Color3.fromRGB(0, 255, 0),
	[StyleKey.CurveZ] = Color3.fromRGB(0, 0, 255),
})

local overridedDarkTheme = Cryo.Dictionary.join(DarkTheme, {
	[StyleKey.DialogButtonTextDisabled] = Color3.fromRGB(92, 92, 92),
	-- Track
	[StyleKey.TrackShadedBackgroundColor] = Color3.fromRGB(54, 54, 54),
	[StyleKey.TrackTitleBackgroundColor] = Color3.fromRGB(54, 54, 54),
	[StyleKey.TrackPrimaryBackgroundColor] = Color3.fromRGB(37, 37, 37),
	[StyleKey.TrackButtonColor] = Colors.Gray_Light,
	[StyleKey.TrackHoveredButtonColor] = Colors.White,
	[StyleKey.TrackAddButtonColor] = Colors.Gray,
	[StyleKey.TrackHoveredAddButtonColor] = Colors.lighter(Colors.Gray, 0.26),
	[StyleKey.TrackPlusIconColor] = Colors.Gray_Light,
	-- Timeline
	[StyleKey.TimelineDimmedColor] = Color3.fromRGB(102, 102, 102),
	[StyleKey.TimelineBackgroundColor] = Color3.fromRGB(56, 56, 56),
	-- Keyframe
	[StyleKey.KeyframePrimaryClusterColor] = Color3.fromRGB(170, 170, 170),
	-- EventMarker
	[StyleKey.EventMarkerImageColor] = Colors.Gray_Light,
	[StyleKey.EventMarkerBorderColor] = Colors.White,
	-- ScrollBar
	[StyleKey.ScrollBarControl] = Color3.fromRGB(64, 64, 64),
	[StyleKey.ScrollBarHover] = Color3.fromRGB(80, 80, 80),
	[StyleKey.ScrollBarPressed] = Color3.fromRGB(80, 80, 80),
	-- StartScreen
	[StyleKey.StartScreenDarkTextColor] = Colors.Gray_Light,
	-- IK
	[StyleKey.IKHeaderColor] = Colors.Slate,
	[StyleKey.IKHeaderBorder] = Color3.fromRGB(26, 26, 26),
	-- Keyframes
	[StyleKey.KeyframePrimaryBackgroundColor] = Colors.Gray_Light,
	[StyleKey.KeyframePrimaryBackgroundColorSelected] = Colors.Gray_Light,
	[StyleKey.KeyframeErrorBackgroundColor] = Colors.lighter(Colors.Black, 0.4),
	[StyleKey.KeyframeErrorBorderColor] = Color3.fromRGB(255, 68, 68),
	[StyleKey.KeyframeErrorBackgroundColorSelected] = Color3.fromRGB(170, 170, 170),
	[StyleKey.KeyframeErrorBorderColorSelected] = Color3.fromRGB(255, 68, 68),
	[StyleKey.KeyframePrimaryErrorBackgroundColor] = Colors.Gray_Light,
	[StyleKey.KeyframePrimaryErrorBorderColor] = Color3.fromRGB(255, 68, 68),
	[StyleKey.KeyframePrimaryErrorBackgroundColorSelected] = Colors.Gray_Light,
	[StyleKey.KeyframePrimaryErrorBorderColorSelected] = Color3.fromRGB(255, 68, 68),
	-- Curves
	[StyleKey.CurveX] = Color3.fromRGB(255, 127, 127),
	[StyleKey.CurveY] = Color3.fromRGB(127, 255, 127),
	[StyleKey.CurveZ] = Color3.fromRGB(127, 127, 255),
})

local playbackTheme = {
	autokeyOn = "",
	autokeyOff = "",
	skipBackward = "rbxasset://textures/AnimationEditor/button_control_previous.png",
	skipForward = "rbxasset://textures/AnimationEditor/button_control_next.png",
	play = "rbxasset://textures/AnimationEditor/button_control_play.png",
	pause = "rbxasset://textures/AnimationEditor/button_pause_white@2x.png",
	loop = "rbxasset://textures/AnimationEditor/button_loop.png",
	reverse = "rbxasset://textures/AnimationEditor/button_control_reverseplay.png",
	goToFirstFrame = "rbxasset://textures/AnimationEditor/button_control_firstframe.png",
	goToLastFrame = "rbxasset://textures/AnimationEditor/button_control_lastframe.png",
	selectClipDropdownIcon = "rbxasset://textures/AnimationEditor/btn_expand.png",
	iconColor = StyleKey.MainText,
	iconHighlightColor = StyleKey.DialogMainButtonText,
	timeInputBackground = StyleKey.InputFieldBackground,
	borderColor = StyleKey.Border,
	inputBorderColor = StyleKey.InputFieldBorder,
}

local dropdownTheme = {
	itemColor = StyleKey.Item,
	hoveredItemColor = StyleKey.ItemHovered,
	textColor = StyleKey.MainText,
	itemHeight = 22,
	textSize = 15,
}

local trackTheme = {
	backgroundColor = StyleKey.MainBackground,
	shadedBackgroundColor = StyleKey.TrackShadedBackgroundColor,
	titleBackgroundColor = StyleKey.TrackTitleBackgroundColor,
	selectedBackgroundColor = StyleKey.ItemSelected,
	primaryBackgroundColor = StyleKey.TrackPrimaryBackgroundColor,

	textColor = StyleKey.MainText,
	primaryTextColor = StyleKey.BrightText,
	selectedTextColor = StyleKey.MainTextSelected,
	textSize = 15,

	arrow = {
		collapsed = "rbxasset://textures/StudioToolbox/ArrowCollapsed.png",
		expanded = "rbxasset://textures/StudioToolbox/ArrowExpanded.png",
	},
	contextMenu = "rbxasset://textures/AnimationEditor/icon_showmore.png",
	addButtonBackground = "rbxasset://textures/AnimationEditor/Circle.png",
	addEventBackground = "rbxasset://textures/AnimationEditor/addEvent_inner.png",
	addEventBorder = "rbxasset://textures/AnimationEditor/addEvent_border.png",
	plusIcon = "rbxasset://textures/AnimationEditor/icon_add.png",

	buttonColor = StyleKey.TrackButtonColor,
	hoveredButtonColor = StyleKey.TrackHoveredButtonColor,
	addButtonColor = StyleKey.TrackAddButtonColor,
	hoveredAddButtonColor = StyleKey.TrackHoveredAddButtonColor,
	plusIconColor = StyleKey.TrackPlusIconColor,
	hoveredPlusIconColor = StyleKey.DialogMainButtonText,
}

local scaleControlsTheme = {
	mainColor = StyleKey.DialogMainButton,
	textColor = StyleKey.DialogMainButtonText,
	textSize = 15,
}

local textBoxTheme = {
	textSize = 16,
	textColor = StyleKey.MainText,
	backgroundColor = StyleKey.InputFieldBackground,
	errorBorder = StyleKey.ErrorText,
	focusedBorder = StyleKey.DialogMainButton,
	defaultBorder = StyleKey.Border,
}

local settingsButtonTheme = {
	image = "rbxasset://textures/AnimationEditor/btn_manage.png",
	imageColor = StyleKey.MainText
}

local keyframeTheme = {
	clusterColor = StyleKey.DialogButtonTextDisabled,
	primaryClusterColor = StyleKey.KeyframePrimaryClusterColor,
}

local checkBoxTheme = {
	backgroundColor = Color3.fromRGB(182, 182, 182),
	titleColor = StyleKey.MainText,

	-- Previously this used Arial
	-- The whole plugin should use SourceSans
	-- But currently uses Legacy
	-- For now, keep this consistent and fix later with the rest of the plugin
	font = Enum.Font.Legacy,
	textSize = 8,

	backgroundImage = "rbxasset://textures/GameSettings/UncheckedBox.png",
	selectedImage = "rbxasset://textures/GameSettings/CheckedBoxLight.png",
}

-- Rest of the values come from UILibrary createTheme.lua and StudioStyle.lua
local roundFrameTheme = {
	slice = Rect.new(3, 3, 13, 13),
	backgroundImage = "rbxasset://textures/StudioToolbox/RoundedBackground.png",
	borderImage = "rbxasset://textures/StudioToolbox/RoundedBorder.png",
}

local textButtonTheme = {
	font = Enum.Font.SourceSans,
}

local buttonTheme = {
	-- Defining a new button style that uses images
	MediaControl = {
		Background = Decoration.Box,
		BackgroundStyle = {
			Color = StyleKey.MainBackground,
			BorderColor =  StyleKey.Border,
			BorderSize = 1,
		},
		[StyleModifier.Hover] = {
			BackgroundStyle = {
				Color = StyleKey.ButtonHover,
				BorderColor = StyleKey.Border,
				BorderSize = 1,
			},
		},
	},

	ActiveControl = {
		Background = Decoration.Box,
		BackgroundStyle = {
			Color = StyleKey.DialogMainButton,
			BorderColor =  StyleKey.DialogMainButton,
			BorderSize = 1,
		},
		[StyleModifier.Hover] = {
			BackgroundStyle = {
				Color = StyleKey.DialogMainButtonHover,
				BorderColor = StyleKey.DialogMainButtonHover,
				BorderSize = 1,
			},
		},
	},

	IKDefault = {
		Background = Decoration.RoundBox,
	},

	IKActive = {
		Background = Decoration.RoundBox,
	}
}

local eventMarker = {
	imageColor = StyleKey.EventMarkerImageColor,
	borderColor = StyleKey.EventMarkerBorderColor,
	selectionBorderColor = StyleKey.DialogMainButton,
	mainImage = "rbxasset://textures/AnimationEditor/eventMarker_inner.png",
	borderImage = "rbxasset://textures/AnimationEditor/eventMarker_border.png",
	selectionBorderImage = "rbxasset://textures/AnimationEditor/eventMarker_border_selected.png",
	textSize = 15,
}

local scrollBarTheme = {
	controlImage = "rbxasset://textures/AnimationEditor/button_zoom.png",
	arrowImage = "rbxasset://textures/AnimationEditor/img_triangle.png",
	imageColor = StyleKey.MainText,
	controlColor = StyleKey.ScrollBarControl,
	hoverColor = StyleKey.ScrollBarHover,
	pressedColor = StyleKey.ScrollBarPressed,
	backgroundColor = StyleKey.ScrollBarBackground,
	borderColor = StyleKey.InputFieldBorder,
	borderSize = 1,
}

local timelineTheme = {
	lineColor = StyleKey.DimmedText,
	textColor = StyleKey.DimmedText,
	dimmedColor = StyleKey.TimelineDimmedColor,
	barColor = StyleKey.MainBackground,
	backgroundColor = StyleKey.TimelineBackgroundColor,
	lowerTransparency = 0.85,
	lowerBrightTransparency = 0.7,
	textSize = 15,
}

local dialogTheme = {
	textSize = 16,
	subTextSize = 15,
	headerFont = Enum.Font.SourceSansSemibold,
	textColor = StyleKey.MainText,
	subTextColor = StyleKey.DimmedText,
	errorTextColor = StyleKey.ErrorText,
	deleteImage = "rbxasset://textures/AnimationEditor/icon_close.png",
	addImage = "rbxasset://textures/AnimationEditor/icon_add.png",
	errorImage = "rbxasset://textures/AnimationEditor/icon_error.png",
}

local toastTheme = {
	textSize = 16,
	textColor = StyleKey.MainText,
	shadowTransparency = 0.75,
	shadowColor = Color3.new(),
	shadowSize = 35,
}

local startScreenTheme = {
	textSize = 16,
	textColor = StyleKey.MainText,
	darkTextColor = StyleKey.StartScreenDarkTextColor,
}

local gridTheme = {
	lineColor = BrickColor.new(Color3.new(1, 1, 1)),
}

local ikTheme = {
	textColor = StyleKey.MainText,
	primaryTextColor = StyleKey.MainTextSelected,
	textSize = 15,
	lineColor = StyleKey.DimmedText,
	ikLineColor = Color3.fromRGB(182, 80, 203),
	transparency = 0.6,
	leafNodeImage = "rbxasset://textures/AnimationEditor/icon_hierarchy_end_white.png",
	expandImage = "rbxasset://textures/AnimationEditor/button_expand.png",
	collapseImage = "rbxasset://textures/AnimationEditor/button_collapse.png",
	pinImage = "rbxasset://textures/AnimationEditor/Pin.png",
	iconColor = StyleKey.DimmedText,
	iconHighlightColor = StyleKey.BrightText,
	selected = StyleKey.ItemSelected,
	headerColor = StyleKey.IKHeaderColor,
	headerBorder = StyleKey.IKHeaderBorder,
	pinHover = StyleKey.DialogMainButtonHover,
}

-- These are used to draw the dopesheet keyframes
-- TODO: Rename and/or move to keyframeTheme
local keyframe = {
	Default = {
		backgroundColor = StyleKey.DialogButtonTextDisabled,
		borderColor = StyleKey.DimmedText,

		selected = {
			backgroundColor = StyleKey.DialogButtonTextDisabled,
			borderColor = StyleKey.DialogMainButton,
		},
	},

	Primary = {
		backgroundColor = StyleKey.KeyframePrimaryBackgroundColor,
		borderColor = StyleKey.Border,

		selected = {
			backgroundColor = StyleKey.KeyframePrimaryBackgroundColorSelected,
			borderColor = Colors.Blue,
		},
	},

	Error = {
		backgroundColor = StyleKey.KeyframeErrorBackgroundColor,
		borderColor = StyleKey.KeyframeErrorBorderColor,

		selected = {
			backgroundColor = StyleKey.KeyframeErrorBackgroundColorSelected,
			borderColor = StyleKey.KeyframeErrorBorderColorSelected,
		},
	},

	PrimaryError = {
		backgroundColor = StyleKey.KeyframePrimaryErrorBackgroundColor,
		borderColor = StyleKey.KeyframePrimaryErrorBorderColor,

		selected = {
			backgroundColor = StyleKey.KeyframePrimaryErrorBackgroundColorSelected,
			borderColor = StyleKey.KeyframePrimaryErrorBorderColorSelected,
		},
	},

	Bounce = {
		backgroundColor = Color3.fromRGB(155, 198, 204),
		borderColor = Color3.fromRGB(56, 56, 56),

		selected = {
			backgroundColor = Color3.fromRGB(155, 198, 204),
			borderColor = StyleKey.DialogMainButton,
		},
	},

	Constant = {
		backgroundColor = Color3.fromRGB(156, 147, 226),
		borderColor = Color3.fromRGB(56, 56, 56),

		selected = {
			backgroundColor = Color3.fromRGB(156, 147, 226),
			borderColor = StyleKey.DialogMainButton,
		},
	},

	Cubic = {
		backgroundColor = Color3.fromRGB(254, 189, 81),
		borderColor = Color3.fromRGB(56, 56, 56),

		selected = {
			backgroundColor = Color3.fromRGB(254, 189, 81),
			borderColor = StyleKey.DialogMainButton,
		},
	},

	Elastic = {
		backgroundColor = Color3.fromRGB(137, 187, 77),
		borderColor = Color3.fromRGB(56, 56, 56),

		selected = {
			backgroundColor = Color3.fromRGB(137, 187, 77),
			borderColor = StyleKey.DialogMainButton,
		},
	},
}

local curveTheme = {
	Default = StyleKey.MainText,
	X = StyleKey.CurveX,
	Y = StyleKey.CurveY,
	Z = StyleKey.CurveZ,
	XAxis = StyleKey.BrightText,
}

local scrubberTheme = {
	backgroundColor = StyleKey.DialogMainButton,
	image = "rbxasset://textures/AnimationEditor/img_scrubberhead.png",
}

local PluginTheme = {
	font = Enum.Font.SourceSans,
	backgroundColor = StyleKey.MainBackground,
	borderColor = StyleKey.Border,

	playbackTheme = playbackTheme,
	dropdownTheme = dropdownTheme,
	trackTheme = trackTheme,
	keyframeTheme = keyframeTheme,
	eventMarker = eventMarker,
	selectionBox = StyleKey.DialogMainButton,
	zoomBarTheme = scrollBarTheme,
	scrollBarTheme = scrollBarTheme,
	timelineTheme = timelineTheme,
	scaleControlsTheme = scaleControlsTheme,
	textBox = textBoxTheme,
	settingsButtonTheme = settingsButtonTheme,
	dialogTheme = dialogTheme,
	toastTheme = toastTheme,
	startScreenTheme = startScreenTheme,
	gridTheme = gridTheme,
	ikTheme = ikTheme,
	checkBox =checkBoxTheme,
	roundFrame = roundFrameTheme,
	button = buttonTheme,
	keyframe = keyframe,
	scrubberTheme = scrubberTheme,
	curveTheme = curveTheme,
}

local UILibraryOverrides = {
	radioButton = {
		font = PluginTheme.font,
		textColor = StyleKey.MainText,
		textSize = 15,
		buttonHeight = 20,
		radioButtonBackground = "rbxasset://textures/GameSettings/RadioButton.png",
		radioButtonSelected = "rbxasset://textures/ui/LuaApp/icons/ic-blue-dot.png",
		contentPadding = 16,
		buttonPadding = 6,
	},
}

if THEME_REFACTOR then
	return function(createMock: boolean?)
		local styleRoot
		if createMock then
			styleRoot = StudioTheme.mock(overridedDarkTheme)
		else
			styleRoot = StudioTheme.new(overridedDarkTheme, overridedLightTheme)
		end

		return styleRoot:extend({
			PluginTheme = PluginTheme,
			UILibraryOverrides = UILibraryOverrides,
		})
	end
else
	return require(script.Parent.Theme_deprecated)
end