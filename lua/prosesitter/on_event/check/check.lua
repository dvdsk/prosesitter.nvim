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
	local allowlist_req = M.allowlist_req:build()
	-- local denylist_req = M.denylist_req:build()
	local areas = allowlist_req.areas -- TODO merge etc
	local text = allowlist_req.text

	local function on_exit(results)
		callback(results, areas)
	end

	local args = { "--config", ".vale.ini", "--no-exit", "--ignore-syntax", "--ext=.md", "--output=JSON" }
	async.dispatch_with_stdin(text, "vale", args, on_exit)
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

local function next_col(self, j)
	local next_area = self[j + 1]
	if next_area == nil then
		return math.huge
	else
		return next_area.col
	end
end

local cfg = nil
-- iterator that returns a span and highlight group
-- TODO rewrite to take into account gaps in text that should be highlighted
function M.hl_iter(results, areas)
	local problems = vim.fn.json_decode(results)["stdin.md"]
	if problems == nil then
		-- TODO cleanup remove placeholders
		return function()
			return nil
		end -- caller needs a function, see lua iterators
	end

	local i = 0
	local j = 1
	areas.next_col = next_col
	return function() -- lua iterator
		i = i + 1
		if i > #problems then
			return nil
		end

		local lint_col, lint_end_col = unpack(problems[i]["Span"])
		while lint_col > areas:next_col(j) do
			j = j + 1
		end
		local hl_start = lint_col - areas[j].col + areas[j].row_col

		while lint_end_col > areas:next_col(j) do
			j = j + 1
		end
		local hl_end = lint_end_col - areas[j].col + areas[j].row_col

		local severity = problems[i].Severity
		local hl_group = cfg.vale_to_hl[severity]
		local hover_txt = problems[i]["Message"]

		return areas[j].buf_id, areas[j].row_id, hl_start, hl_end, hl_group, hover_txt
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
