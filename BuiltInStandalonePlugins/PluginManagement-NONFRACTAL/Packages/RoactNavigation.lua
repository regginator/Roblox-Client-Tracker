local PackageIndex = script.Parent._Index

local package = PackageIndex["roblox_roact-navigation"]["roact-navigation"]

if package.ClassName == "ModuleScript" then
	return require(package)
end

return package