local PackageIndex = script.Parent._Index

local package = PackageIndex["roblox_otter"]["otter"]

if package.ClassName == "ModuleScript" then
	return require(package)
end

return package
