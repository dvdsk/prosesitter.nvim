local async = require("prosesitter/on_event/check/async_cmd")
local lintreq = require("prosesitter/on_event/lintreq")
local log = require("prosesitter/log")
local M = {}

M.schedualled = false
M.lintreq = nil
local callback = nil
local job = nil

local function do_check()
	M.schedualled = false
	local req = M.lintreq:build()

	local function on_exit(results)
		for hl in M.hl_iter(results, req.areas) do
			callback(hl)
		end
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
	local timeout_ms = 800
	job = vim.defer_fn(do_check, timeout_ms)
end

local function next_problem_span(problems, i)
	local next_problem = problems[i + 1]
	if next_problem == nil then
		return ""
	else
		return next_problem.Span
	end
end

local function next_col(self, j)
	local next_area = self[j + 1]
	if next_area == nil then
		return math.huge
	else
		return next_area.col
	end
end

local function start_col(problem, areas, j)
	local lint_col, _ = unpack(problem["Span"])
	while lint_col > areas:next_col(j) do
		j = j + 1
	end
	local hl_start = lint_col - areas[j].col + areas[j].row_col
	return hl_start, j
end

local function end_col(problem, areas, k)
	local _, lint_end_col = unpack(problem["Span"])
	while lint_end_col > areas:next_col(k) do
		k = k + 1
	end
	local hl_end = lint_end_col - areas[k].col + areas[k].row_col
	return hl_end
end

local function skip_to_next_problem(problems, i)
	while problems[i].Span == next_problem_span(problems, i) do
		if problems[i]["Message"] ~= problems[i + 1]["Message"] then
			problems[i + 1]["Message"] = problems[i + 1]["Message"] .. "\n" .. problems[i]["Message"]
		end
		i = i + 1
	end
	return i
end

local cfg = nil
function M.hl_iter(results, areas)
	local problems = vim.fn.json_decode(results)["stdin.md"]
	if problems == nil then
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

		i = skip_to_next_problem(problems, i)

		local hl = {}
		hl.start_col, j = start_col(problems[i], areas, j)
		hl.end_col = end_col(problems[i], areas, j)
		hl.buf_id = areas[j].buf_id
		hl.row_id = areas[j].row_id

		local severity = problems[i].Severity
		hl.group = cfg.vale_to_hl[severity]
		hl.hover_txt = problems[i]["Message"]

		return hl
	end
end

function M:setup(shared, _callback)
	lintreq.setup(shared)
	self.lintreq = lintreq.new()
	callback = _callback
	cfg = shared.cfg
end

function M:get_lintreq()
	return self.lintreq
end

function M:disable()
	self.lintreq = lintreq:new() -- reset lint req
	self.cancelled_schedualled() -- stop any running async jobs
end

return M
