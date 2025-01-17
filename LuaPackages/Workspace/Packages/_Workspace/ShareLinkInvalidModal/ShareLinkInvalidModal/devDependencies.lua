local Root = script.Parent
local Packages = Root.Parent

local LuaSocialLibrariesDeps = require(Packages.LuaSocialLibrariesDeps)
local JestGlobals = require(Packages.Dev.JestGlobals)

JestGlobals.expect.extend(LuaSocialLibrariesDeps.CollisionMatchers.Jest)

return {
	JestGlobals = JestGlobals,
	ReactRoblox = require(Packages.Dev.ReactRoblox),
	Mock = LuaSocialLibrariesDeps.Mock,
	UnitTestHelpers = require(Packages.Dev.LuaProfileDeps).UnitTestHelpers,
	Rhodium = require(Packages.Dev.Rhodium),
	RhodiumHelpers = function()
		return require(Packages.Dev.RhodiumHelpers)
	end,
	createTreeWithProviders = require(Packages.Dev.SocialTestHelpers).TestHelpers.createTreeWithProviders,
	DeferredLuaHelpers = require(Packages.Dev.TestUtils).DeferredLuaHelpers,
}
