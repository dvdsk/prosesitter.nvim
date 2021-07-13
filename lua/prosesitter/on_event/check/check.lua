local async = require("prosesitter/on_event/check/async_cmd")
local lintreq = require("prosesitter/on_event/lintreq")
local log = require("prosesitter/log")
local M = {}

M.schedualled = false
M.lint_req = nil
local callback = nil
local job = nil
local cfg = nil

local function do_check()
	M.schedualled = false
	local req = M.lint_req:build()
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
	local timeout_ms = 2000
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
		-- log.info("problem: "..problems[i]["Message"]) -- TODO probably want to store in lookup db (key: bufnr+mark_id)
		local meta = closest_smaller(flatcol_start, meta_array)
		local rel_start = flatcol_start - meta.col
		local rel_end = flatcol_end - meta.col

		return meta.buf, meta.id, rel_start, rel_end, hl
	end
end

function M:setup(shared, _callback)
	lintreq.setup(shared)
	self.lint_req = lintreq.new()
	callback = _callback
	cfg = shared.cfg
end

return M
