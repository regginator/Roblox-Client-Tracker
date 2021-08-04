local Framework = script.Parent.Parent

local isUsedAsPackage = require(Framework.Util.isUsedAsPackage)
if game:GetFastFlag("DevFrameworkUseSiblingPackages") and isUsedAsPackage() then
	return require(Framework.Parent["Cryo"])
end

--[[
	Package link auto-generated by Rotriever
]]
local PackageIndex = script.Parent._Index

local package = PackageIndex["roblox_cryo"]["cryo"]

if package.ClassName == "ModuleScript" then
	return require(package)
end

return package
