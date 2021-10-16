local async = require("prosesitter/on_event/check/async_cmd")
local lintreq = require("prosesitter/on_event/lintreq")
local marks = require("prosesitter/on_event/marks/marks")
local shared = require("prosesitter/shared")
local vale = require("prosesitter/backend/vale")
local langtool = require("prosesitter/backend/langtool")
local log = require("prosesitter/log")
local M = {}

M.schedualled = false
M.lintreq = "should be set in check.setup"
local job = "should be set in check.setup"

local cfg = "should be set in check.setup"
local function do_check()
	M.schedualled = false
	local req = M.lintreq:build()

	if shared.langtool_running then
		local function post_langtool(json)
			log.info(json)
			-- local results = langtool.add_spans(json)
			-- marks.mark_results(results, req.areas, "langtool", langtool.to_meta)
		end

		log.info("starting check on: ", req.text)
		local curl_args = {
			"--no-progress-meter",
			"--data-urlencode",
			"language=en-US",
			"--data-urlencode",
			"disabledCategories=STYLE",
			"--data-urlencode",
			"disabledRules=WHITESPACE_RULE",
			"--data-urlencode",
			"text@-",
			langtool.url,
		}
		async.dispatch_with_stdin(langtool.query(req.text), "curl", curl_args, post_langtool)
	end

	-- if cfg.vale_bin ~= nil then
	-- 	local function post_vale(json)
	-- 		local results = vim.fn.json_decode(json)["stdin.md"]
	-- 		marks.mark_results(results, req.areas, "vale", vale.to_meta)
	-- 	end
	-- 	local vale_args = { "--config", cfg.vale_cfg, "--no-exit", "--ignore-syntax", "--ext=.md", "--output=JSON" }
	-- 	async.dispatch_with_stdin(req.text, cfg.vale_bin, vale_args, post_vale)
	-- end
end

function M.cancelled_schedualled()
	if job ~= nil then
		job:stop()
		M.schedualled = false
	end
end

function M.schedual()
	local timeout_ms = 500 -- was 800
	job = vim.defer_fn(do_check, timeout_ms)
end

function M:setup()
	cfg = shared.cfg
	lintreq.setup(shared)
	self.lintreq = lintreq.new()
end

function M:get_lintreq()
	return self.lintreq
end

function M:disable()
	self.lintreq:reset()
	self.cancelled_schedualled() -- stop any running async jobs
end

return M
