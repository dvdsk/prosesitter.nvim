local async = require("prosesitter/on_event/check/async_cmd")
local lintreq = require("prosesitter/on_event/lintreq")
local log = require("prosesitter/log")
local M = {}

M.schedualled = false
M.lintreq = nil
local vale_cfg_path = nil
local callback = nil
local job = nil

local function do_check()
	M.schedualled = false
	local req = M.lintreq:build()

	local function on_exit(results)
		callback(results, req.areas)
	end

	local args = { "--config", vale_cfg_path, "--no-exit", "--ignore-syntax", "--ext=.md", "--output=JSON" }
	async.dispatch_with_stdin(req.text, "vale", args, on_exit)
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

function M:setup(shared, _callback)
	vale_cfg_path = shared.cfg.vale_cfg_path
	lintreq.setup(shared)
	self.lintreq = lintreq.new()
	callback = _callback
end

function M:get_lintreq()
	return self.lintreq
end

function M:disable()
	self.lintreq = lintreq:new() -- reset lint req
	self.cancelled_schedualled() -- stop any running async jobs
end

return M
