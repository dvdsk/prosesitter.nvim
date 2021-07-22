local async = require("prosesitter/on_event/check/async_cmd")
local lint_allowlist = require("prosesitter/on_event/lint_allow")
local lint_denylist = require("prosesitter/on_event/lint_deny")
local log = require("prosesitter/log")
local M = {}

M.schedualled = false
M.allowlist_req = nil
M.denylist_req = nil
local callback = nil
local job = nil

local function do_check()
	M.schedualled = false
	-- we need to build from allow list and deny list here
	-- need to merge two requests here
	local req = M.allowlist_req:build()
	-- TODO deny list request build and merge
	local function on_exit(results)
		callback(results, req.meta_array)
	end

	local args = { "--config", ".vale.ini", "--no-exit", "--ignore-syntax", "--ext=.md", "--output=JSON" }
	async.dispatch_with_stdin(req.text, "vale", args, on_exit)
end

function M.cancelled_schedualled()
	if job ~= nil then
		job:stop()
		M.schedualled = false
	end
end

function M.schedual()
	local timeout_ms = 500
	job = vim.defer_fn(do_check, timeout_ms)
end

local function closest_smaller(target, array)
	local prev
	for i=1,#array do
		if array[i].col > target then
			break
		end
		prev = array[i]
	end
	return prev
end

local cfg = nil
-- iterator that returns a span and highlight group
function M.hl_iter(results, meta_array)
	local problems = vim.fn.json_decode(results)["stdin.md"]
	if problems == nil then
		-- TODO cleanup remove placeholders
		return function() return nil end -- caller needs a function, see lua iterators
	end

	local i = 0
	return function() -- lua iterator
		i = i + 1
		if i > #problems then
			return nil
		end
		local severity = problems[i].Severity
		local hl = cfg.vale_to_hl[severity]

		-- get the metadata for the line that was written to the flattend
		-- input for vale. Then calculate the the column positions in the buffer
		-- and get the placeholder extmark for recovering the line number later
		local flatcol_start, flatcol_end = unpack(problems[i]["Span"])
		local hover_txt = problems[i]["Message"]

		local meta = closest_smaller(flatcol_start, meta_array)
		local rel_start = flatcol_start - meta.col
		local rel_end = flatcol_end - meta.col

		return meta.buf, meta.id, rel_start, rel_end, hl, hover_txt
	end
end

function M:setup(shared, _callback)
	lint_allowlist.setup(shared)
	lint_denylist.setup(shared)
	self.allowlist_req = lint_allowlist.new()
	self.denylist_req = lint_denylist.new()
	callback = _callback
	cfg = shared.cfg
end

function M:disable()
	self.allowlist_req = lint_allowlist:new() -- reset lint req
	self.denylist_req = lint_denylist:new() -- reset lint req
	self.cancelled_schedualled() -- stop any running async jobs
end

return M
