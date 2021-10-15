local util = require("prosesitter/util")
local log = require("prosesitter/log")
local shared = require("prosesitter/shared")
local defaults = require("prosesitter/config/defaults")
local M = {}

M.url = "set in start_server function"

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

	local ok_msg = "[prosesitter] installed language tool"
	local err_msg = "[prosesitter] could not setup language tool"
	util:shell_in_new_window(install_script, ok_msg, err_msg)
end

function M.setup_cfg()
	local exists = 1
	if vim.fn.filereadable(util.plugin_path .. "/langtool.cfg") ~= exists then
		local file = io.open(util.plugin_path .. "/langtool.cfg", "w")
		if file == nil then
			print("fatal error: could not open/create fresh LanguageTool config")
		end

		file:write(defaults.langtool_cfg)
		file:flush()
		file:close()
	end
end

local function mark_rdy_if_responding(on_event)
	local on_exit = function(text)
		if not shared.langtool_running then
			if text ~= nil then
				if string.starts(text, '{"software":{"name":"LanguageTool"') then
					shared.langtool_running = true
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
			local curl_args = { "--no-progress-meter", "--data", "@-", M.url }
			async.dispatch_with_stdin("language=en-US&text=hi", "curl", curl_args, on_exit)
		end
	end

	for timeout = 0, 15, 1 do
		vim.defer_fn(do_check, timeout * 1000)
	end
end

-- using depedency injection here (on_event) to break
-- dependency loop
function M.start_server(on_event, cfg)
	local on_exit = function()
		M.langtool_running = false
	end

	M.url = "http://localhost:" .. cfg.langtool_port .. "/v2/check"
	local res = vim.fn.jobstart({
		"java",
		"-cp",
		cfg.langtool_bin,
		"org.languagetool.server.HTTPServer",
		"--config",
		cfg.langtool_cfg,
		"--port",
		cfg.langtool_port,
	}, {
		on_exit = on_exit,
	})

	if res > 0 then
		mark_rdy_if_responding(on_event)
	else
		error("could not start language server using path: " .. cfg.langtool_bin)
		log.error("could not start language server using path: " .. cfg.langtool_bin)

	end
end

local id_to_severity = {
	CAPITALIZATION = "error",
	COLLOCATIONS = "warning",
	CONFUSED_WORDS = "warning",
	COMPOUNDING = "warning",
	CREATIVE_WRITING = "suggestion", -- not active by default
	GRAMMAR = "error",
	MISC = "warning",
	NONSTANDARD_PHRASES = "warning",
	PLAIN_ENGLISH = "suggestion", -- not active by default
	TYPOS = "error",
	PUNCTUATION = "warning",
	REDUNDANCY = "suggestion",
	SEMANTICS = "warning",
	STYLE = "suggestion", -- disabled by us
	TEXT_ANALYSIS = "suggestion", -- not active by default
	TYPOGRAPHY = "warning",
	CASING = "error",
	WIKIPEDIA = "suggestion", --not active by default
}

function M.to_meta(problem)
	local issue = {}
	issue.msg = problem.message
	issue.severity = id_to_severity[problem.rule.category.id]
	issue.full_source = "TODO"
	issue.action = "TODO"
	return issue
end

function M.add_spans(json)
	local problems = vim.fn.json_decode(json)["matches"]
	for _, res in ipairs(problems) do
		res.Span = { res.offset + 1, res.offset + res.length }
	end
	return problems
end

return M
