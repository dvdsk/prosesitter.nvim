local util = require("prosesitter/util")
local M = {}



function M.setup_binairy()
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
	util:shell_in_new_window(install_script, ok_msg, err_msg)
end

return M
