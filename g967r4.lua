local g967r4 = {}

local f = string.format

local separator = package.config:sub(1,1)
local is_windows = separator == "\\"
local extension = is_windows and ".exe" or ""

local lfs = require("lfs")

local addon_json =
[[
{
	"title"		:	"%s",
	"type"		:	"ServerContent",
	"tags"		:	[ "roleplay", "realism" ],
	"ignore"	:
	[
		"*.psd",
		"*.vcproj",
		"*.svn*",
		".gitignore",
		"*.gma"
	]
}
]]

local config_content =
[=[
return {
	gmad_path = [[%s]],
	icon = [[%s]]
}
]=]

local function get_file_name(file)
      return file:match("^.+/(.+)$")
end

local function copy_folder(source, destination)
	local cmd = is_windows and f("xcopy /e /v %s %s", source, destination)
						   or f("cp -a %s %s", source, destination)
	os.execute(cmd)
end

local function delete_folder(folder)
	local cmd = is_windows and f('rd /s /q "%s"', folder)
						   or f('rm -rf "%s"', folder)
	os.execute(cmd)
end

local function generate_addon_descriptor(folder)
	local name = get_file_name(folder) or folder

	local file = io.open(folder .. "/addon.json", "w")
		file:write(f(addon_json, name))
	file:close()
end

function g967r4.upload_gma(folder, gmad_path, icon_path)
	os.execute(f('%s create -folder "%s" -out "%s%saddon.gma"', gmad_path, folder, folder, separator))

	local gmpublish_path = gmad_path:gsub("gmad" .. extension, "gmpublish" .. extension)
	print("Icon", icon_path)

	os.execute(f('%s create -addon "%s%saddon.gma" -icon "%s"', gmpublish_path, folder, separator, icon_path))

	return true
end

function g967r4.generate_content(folder, gmad_path, icon_path)
	if not lfs.attributes(folder) then error("Specified folder is not exists.") end

	local filename = get_file_name(folder) or folder
	local content_folder = filename .. "-content"

	if lfs.attributes(content_folder) then delete_folder(content_folder) end

	lfs.mkdir(content_folder)
	copy_folder(folder, content_folder)

	if lfs.attributes(content_folder .. separator .. "lua") then delete_folder(content_folder .. separator .. "lua") end
	if not lfs.attributes(content_folder .. separator .. "addon.json") then generate_addon_descriptor(content_folder) end

	g967r4.upload_gma(content_folder, gmad_path, icon_path)

	return true
end

function g967r4.generate(folder, gmad_path, icon_path)
	local config = pcall(require, "g967r4-config")

	if not config and not gmad_path then error("GMAD path is unknown. Specify it as second arg.") end
	if not config and not icon_path then error("Icon path is not specified. Specify full path.") end

	if config then config = require("g967r4-config") end

	if (gmad_path) and (not config) then
		local file = io.open("g967r4-config.lua", "w")
			file:write(f(config_content, gmad_path, icon_path))
		file:close()

		-- We don't want to re-require, right?
		config = {gmad_path = gmad_path, icon = icon_path}
	end

	if not config.gmad_path then error("GMAD path was not founded in config.") end
	if not config.icon then error("Icon path was not founded in config.") end

	if not lfs.attributes(config.gmad_path) then error("Specified GMAD file is not exists.") end

	print(config.icon)
	g967r4.generate_content(folder, config.gmad_path, config.icon)
end

if not arg[1] then error("Addon folder not specified.") end
g967r4.generate(arg[1], arg[2], arg[3])