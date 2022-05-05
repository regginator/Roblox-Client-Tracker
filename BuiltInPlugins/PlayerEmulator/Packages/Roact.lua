--[[
	Package link auto-generated by manage_libraries and Rotriever
]]
local FFlagPlayerEmulatorDeduplicatePackages = game:GetFastFlag("PlayerEmulatorDeduplicatePackages")
if FFlagPlayerEmulatorDeduplicatePackages then
	local PackageIndex = script.Parent._Index
	local Package = require(PackageIndex["Roact"]["Roact"])
	return Package
else
	local PackageIndex = script.Parent._Old

	if game:GetFastFlag("PlayerEmulatorUseRoactv14") then
		return require(PackageIndex["roblox_roact"]["roact"])
	end

	return require(PackageIndex["Roact-c4d9a64d540b-41af74df7307"].packages["Roact"])
end
