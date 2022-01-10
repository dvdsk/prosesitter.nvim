local util = require("prosesitter/util")
local log = require("prosesitter/log")
local state = require("prosesitter/state")
local defaults = require("prosesitter/config/defaults")
local Issue = require("prosesitter/linter/issues").Issue
local M = {}

M.url = "set in start_server function"

function M.setup_binairy()
	vim.fn.mkdir(util.plugin_path, "p")
	local install_script = [=====[
		set -e 
		GREEN='\033[0;32m'
		NC='\033[0m' # No Color
		  
		tmp="/tmp/prosesitter"
		mkdir -p $tmp
		mkdir -p languagetool

		url="https://languagetool.org/download/LanguageTool-stable.zip"
		printf "${GREEN}downloading languagetool${NC}\n"
		curl --location --output "$tmp/langtool.zip" $url 

		unzip -q "$tmp/langtool.zip" -d languagetool
		# get languagetool-server.jar and its dependencies out of the version specific
		# folder into one we can depend on
		mv languagetool/*/* languagetool 
		printf "${GREEN}done installing languagetool, restart nvim for changes to take effect${NC}\n"
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
		if not state.langtool_running then
			if text ~= nil then
				if string.starts(text, '{"software":{"name":"LanguageTool"') then
					state.langtool_running = true
					for buf in state:attached() do
						on_event:lint_everything(buf)
					end
				end
			end
		end
	end

	local async = require("prosesitter/linter/check/async_cmd")
	local do_check = function()
		if not M.langtool_running then
			local args = M:curl_args("")
			async.dispatch_with_stdin("hi", "curl", args, on_exit)
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

function M.to_issue(problem, start_col, end_col)
	local issue = Issue.new()
	issue.msg = problem.message
	issue.severity = id_to_severity[problem.rule.category.id]
	issue.full_source = problem.rule.category.name..": "..problem.rule.id
	issue.replacements = problem.replacements
	issue.start_col = start_col
	issue.end_col = end_col
	return issue
end

function M:curl_args(disabled_rules)
	return {
		"--no-progress-meter",
		"--data-urlencode",
		"language=en-US",
		"--data-urlencode",
		"disabledCategories=STYLE",
		"--data-urlencode",
		"disabledRules="..disabled_rules,
		"--data-urlencode",
		"text@-",
		self.url,
	}
end

function M.add_spans(json)
	local problems = vim.fn.json_decode(json)["matches"]
	for _, res in ipairs(problems) do
		res.Span = { res.offset + 1, res.offset + res.length }
	end
	return problems
end

return M
