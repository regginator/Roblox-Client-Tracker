local Framework = script.Parent.Parent

local isUsedAsPackage = require(Framework.Util.isUsedAsPackage)
if game:GetFastFlag("DevFrameworkUseSiblingPackages") and isUsedAsPackage() then
	return require(Framework.Parent["DeveloperTools"])
end

--[[
	Package link auto-generated by Rotriever
]]
local PackageIndex = script.Parent._Index

local package = PackageIndex["roblox_developer-tools-8bf32936-90266d90"]["developer-tools"]

if package.ClassName == "ModuleScript" then
	return require(package)
end

return package