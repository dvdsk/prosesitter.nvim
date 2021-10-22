local async = require("prosesitter/linter/check/async_cmd")
local marks = require("prosesitter/linter/marks/marks")
local state = require("prosesitter/state")
local vale = require("prosesitter/backend/vale")
local langtool = require("prosesitter/backend/langtool")
local log = require("prosesitter/log")
local M = {}

M.schedualled_bufs = {}
local jobs = {}

local function check_buf(buf)
	local lintreq = state.lintreq[buf]
	if lintreq:is_empty() then
		return
	end

	local req = lintreq:build()

	if state.langtool_running then
		local function post_langtool(json)
			local results = langtool.add_spans(json)
			marks.mark_results(results, req.areas, "langtool", langtool.to_meta)
		end

		local args = langtool:curl_args()
		async.dispatch_with_stdin(req.text, "curl", args, post_langtool)
	end

	if state.cfg.vale_bin ~= nil then
		local function post_vale(json)
			local results = vim.fn.json_decode(json)["stdin.md"]
			marks.mark_results(results, req.areas, "vale", vale.to_meta)
		end
		local vale_args = { "--config", state.cfg.vale_cfg, "--no-exit", "--ignore-syntax", "--ext=.md", "--output=JSON" }
		async.dispatch_with_stdin(req.text, state.cfg.vale_bin, vale_args, post_vale)
	end
end

function M:cancelled_schedualled()
	for buf, job in pairs(jobs) do
		job:stop()
		self.schedualled[buf] = nil
	end
end

function M:schedualled(buf)
	return self.schedualled_bufs[buf] ~= nil
end

function M:schedual(buf)
	local check = function()
		check_buf(buf)
		self.schedualled_bufs[buf] = nil
	end
	jobs[buf] = vim.defer_fn(check, state.cfg.timeout)
	self.schedualled_bufs[buf] = true
end

function M:disable()
	self.cancelled_schedualled() -- stop any running async jobs
end

return M
