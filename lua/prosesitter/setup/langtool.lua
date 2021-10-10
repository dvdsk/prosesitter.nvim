local defaults = require("prosesitter/defaults")
local util = require("prosesitter/util")
local M = {}


function M.binairy()
	vim.fn.mkdir(util.plugin_path, "p")
	local install_script = [=====[
		set -e 
		  
		tmp="/tmp/prosesitter"
		mkdir -p $tmp
		mkdir -p languagetool

		url="https://languagetool.org/download/LanguageTool-stable.zip"
		curl --location --output "$tmp/langtool.zip" $url 
		unzip "$tmp/langtool.zip" -d languagetool 
		# get languagetool-server.jar and its dependencies out of the version specific
		# folder into one we can depend on
		mv languagetool/*/* languagetool 
	]=====]

	local ok_msg = "[prosesitter] installed vale with default styles"
	local err_msg= "[prosesitter] could not setup vale styles"
	util.shell_in_new_window(install_script, ok_msg, err_msg)
end

function M.default_cfg()
	local exists = 1
	if vim.fn.filereadable(util.plugin_path .. "/vale_cfg.ini") ~= exists then
		local file = io.open(util.plugin_path .. "/vale_cfg.ini", "w")
		if file == nil then
			print("fatal error: could not open/create fresh vale config")
		end

		local cfg = "StylesPath = "..util.plugin_path.."/styles \n"..defaults.vale_cfg_ini
		file:write(cfg)
		file:flush()
		file:close()
	end
end

return M
