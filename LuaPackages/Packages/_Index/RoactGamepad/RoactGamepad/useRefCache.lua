--!strict
--[[
	Hook that returns a ref cache (see createRefCache).

	The same ref cache instance is returned on every render.
]]
local Packages = script.Parent.Parent
local React = require(Packages.React)

local createRefCache = require(script.Parent.createRefCache)

local function useRefCache()
	local ref = React.useRef(nil)
	if ref.current == nil then
		ref.current = createRefCache()
	end
	return ref.current
end

return useRefCache
