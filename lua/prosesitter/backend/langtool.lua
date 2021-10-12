local util = require("prosesitter/util")
local log = require("prosesitter/log")
local shared = require("prosesitter/shared")
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


local function mark_rdy_if_responding(on_event)
	local on_exit = function(text)
		if not shared.langtool_running then
			if text ~= nil then
				if string.starts(text, '{"software":{"name":"LanguageTool"') then
					shared.langtool_running = true
					log.info("Language tool started")
					for buf, _ in pairs(shared.buf_query) do
						on_event:lint_everything(buf)
					end
					-- TODO check all attached buffers
				end
			end
		end
	end

	local async = require("prosesitter/on_event/check/async_cmd")
	local do_check = function()
		if not M.langtool_running then
			local curl_args = { "--no-progress-meter", "--data", "@-", "http://localhost:8081/v2/check" }
			async.dispatch_with_stdin("language=en-US&text=hi", "curl", curl_args, on_exit)
		end
	end

	for timeout = 0, 15, 1 do
		vim.defer_fn(do_check, timeout*1000)
	end
end

function M.start_server(on_event, path)
	local on_exit = function()
		M.langtool_running = false
	end

	local res = vim.fn.jobstart({
		"java",
		"-cp",
		path,
		"org.languagetool.server.HTTPServer",
		"--port",
		"8081",
	}, {
		on_exit = on_exit,
	})

	if res > 0 then
		mark_rdy_if_responding(on_event)
	else
		error("could not start language server using path: " .. path)
	end
end

return M
