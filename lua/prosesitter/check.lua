local async = require("prosesitter/async_cmd")
local log = require("prosesitter/log")
local M = {}

M.callback = nil
M.schedualled = false
M.lint_req = nil
M.job = nil

function M.now()
	local req = M.lint_req:build()
	local function on_exit(results)
		M.callback(results, req.meta_by_flatcol)
	end

	local args = { "--config", ".vale.ini", "--no-exit", "--ignore-syntax", "--ext=.md", "--output=JSON" }
	async.dispatch_with_stdin(req.text, "vale", args, on_exit)
end

function M.cancelled_schedualled()
	if M.job ~= nil then
		M.job.stop()
		M.schedualled = false
	end
end

function M.schedual()
	local timeout_ms = 2000
	M.job = vim.defer_fn(M.now(), timeout_ms)
	M.schedualled = true
end

return M
