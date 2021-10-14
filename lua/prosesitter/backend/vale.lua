local defaults = require("prosesitter/defaults")
local util = require("prosesitter/util")
local M = {}

function M.setup_binairy_and_styles()
	vim.fn.mkdir(util.plugin_path, "p")
	local install_script = [=====[
		set -e 

		function latest_version() {
			local release=$(curl -L -s -H 'Accept: application/json' $1/releases/latest)
			local version=$(echo $release | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
			echo $version
		}

		function os_str() {
			local os_str
			if [[ "$OSTYPE" == "linux-gnu"* ]]; then
				echo Linux
			elif [[ "$OSTYPE" == "darwin"* ]]; then
				echo macOS
			else 
				echo "Error: Os other then linux and macOS not supported by install script"
				exit -1
			fi
		}

		# setup vale binary
		latest_version=$(latest_version https://github.com/errata-ai/vale)
		fname="vale_${latest_version:1}_$(os_str)_64-bit.tar.gz"
		url="https://github.com/errata-ai/vale/releases/download/$latest_version/$fname"
		curl --location $url | tar --gzip --extract --directory . vale

		# setup styles
		for style in $styles; do
			release=$(latest_version https://github.com/errata-ai/$style)
			version=$(echo $release | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
			url="https://github.com/errata-ai/$style/releases/download/$version/$style.zip"

			curl --location --output "$tmp/$style.zip" $url 
			unzip "$tmp/$style.zip" -d styles 
		done
	]=====]

	local ok_msg = "[prosesitter] installed vale with default styles"
	local err_msg= "[prosesitter] could not setup vale styles"
	util:shell_in_new_window(install_script, ok_msg, err_msg)
end

function M.setup_default_cfg()
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

function M.to_meta(problem)
	local issue = {}
	issue.msg = problem.Message
	issue.severity = problem.Severity
	issue.full_source = "TODO"
	issue.action = "TODO"
	return issue
end

return M
