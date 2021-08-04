local Framework = script.Parent.Parent.Parent
local Roact = require(Framework.Parent.Roact)
local UI = require(Framework.UI)
local TextInput = UI.TextInput

local FFlagAllowTextInputTextXAlignment = game:GetFastFlag("AllowTextInputTextXAlignment")
local FFlagAllowInputObjOnFocusLost = game:GetFastFlag("AllowInputObjOnFocusLost")

return {
	stories = {
		{	name = "RoundedBorder",
			story = Roact.createElement(TextInput, {
				Size = UDim2.new(0, 150, 0, 20),
				Style = "RoundedBorder",
				PlaceholderText = "Placeholder",
				TextXAlignment = FFlagAllowTextInputTextXAlignment and Enum.TextXAlignment.Center or nil,
				OnTextChanged = function(text)
					print("TextInput - OnTextChanged: ", text)
				end,
				OnFocusGained = function()
					print("TextInput - OnFocusGained")
				end,
				OnFocusLost = function(enterPressed, rbx)
					print("TextInput - OnFocusLost", enterPressed)
					if FFlagAllowInputObjOnFocusLost then
						print("TextInput - OnFocusLost original text", rbx.Text)
						rbx.Text = "OnFocusLost Changed"
					end
				end
			}),
		},
		{
			name = "FilledRoundedBorder",
			story = Roact.createElement(TextInput, {
				Size = UDim2.new(0, 150, 0, 20),
				Style = "FilledRoundedBorder",
				PlaceholderText = "Placeholder",
				OnTextChanged = function(text)
					print("TextInput - OnTextChanged: ", text)
				end,
				OnFocusGained = function()
					print("TextInput - OnFocusGained")
				end,
				OnFocusLost = function(enterPressed)
					print("TextInput - OnFocusLost", enterPressed)
				end
			}),
		},
		{
			name = "FilledRoundedRedBorder",
			story = Roact.createElement(TextInput, {
				Size = UDim2.new(0, 150, 0, 20),
				Style = "FilledRoundedRedBorder",
				PlaceholderText = "Placeholder",
				OnTextChanged = function(text)
					print("TextInput - OnTextChanged: ", text)
				end,
				OnFocusGained = function()
					print("TextInput - OnFocusGained")
				end,
				OnFocusLost = function(enterPressed)
					print("TextInput - OnFocusLost", enterPressed)
				end
			}),
		},
	}
}
