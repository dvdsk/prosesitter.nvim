local defaults = require("prosesitter/defaults")
local M = {}

local plugin_path = vim.fn.stdpath("data") .. "/prosesitter"

local function shell_in_new_window(bash_script, wd, ok_msg_, err_msg)
	local function on_exit(_, code)
		if code ~= 0 then
			error(err_msg)
		end
	end

	vim.cmd("new")
	local shell = vim.o.shell
	vim.o.shell = "/usr/bin/env bash"
	vim.fn.termopen(bash_script, { cwd = plugin_path, on_exit = on_exit })
	vim.o.shell = shell
	vim.cmd("startinsert")
end

function M.binairy_and_styles()
	vim.fn.mkdir(plugin_path, "p")
	local install_script = [=====[
		set -e 

		styles="Microsoft Google write-good proselint Joblint alex"
		tmp="/tmp/prosesitter"
		mkdir -p $tmp
		mkdir -p styles

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
	shell_in_new_window(install_script, plugin_path, ok_msg, err_msg)
end

function M.default_cfg()
	local exists = 1
	if vim.fn.filereadable(plugin_path .. "/vale_cfg.ini") ~= exists then
		local file = io.open(plugin_path .. "/vale_cfg.ini", "w")
		if file == nil then
			print("fatal error: could not open/create fresh vale config")
		end

		local cfg = "StylesPath = "..plugin_path.."/styles \n"..defaults.vale_cfg_ini
		file:write(cfg)
		file:flush()
		file:close()
	end
end

return M
