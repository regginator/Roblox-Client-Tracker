local ContactImporter = script.Parent
local Packages = ContactImporter.Parent

local dependencies = require(ContactImporter.dependencies)
local Roact = dependencies.Roact
local llama = dependencies.llama
local UIBlox = dependencies.UIBlox
local UIBloxUniversalAppConfig = require(Packages.Dev.RobloxAppUIBloxConfig)

--- This has to be here to prevent tests from failing (if we put it in the devDependencies)
local mockLocale = require(Packages.Dev.SocialTestHelpers).StoryHelpers.mockLocale

-- Make sure to initialize in story book in case this storybook is called first
UIBlox.init(UIBloxUniversalAppConfig)

local AppStyleProvider = UIBlox.App.Style.AppStyleProvider

Roact.setGlobalConfig({
	propValidation = true,
	elementTracing = true,
})

local styleTable = {
	Default = {
		themeName = "Light",
		fontName = "Gotham",
	},
	Light = {
		themeName = "Light",
		fontName = "Gotham",
	},
	Dark = {
		themeName = "Dark",
		fontName = "Gotham",
	},
}

local globalControls = {
	language = "en-us",
}

return {
	name = "ContactImporter",
	storyRoot = ContactImporter,
	roact = Roact,
	mapDefinition = function(story)
		local newControls = llama.Dictionary.join(globalControls, story.controls or {})
		return llama.Dictionary.join(story, { controls = newControls })
	end,
	mapStory = function(story)
		return function(storyProps)
			return Roact.createElement(AppStyleProvider, {
				style = storyProps and styleTable[storyProps.theme] or styleTable.Default,
			}, {
				Child = mockLocale(story, storyProps),
			})
		end
	end,
}
