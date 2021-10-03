local log = require("prosesitter/log")
local M = {}

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

local function spans_match(a, b)
	return a[1] == b[1] and a[2] == b[2]
end

local severity_as_int = {
	error = 4,
	warning = 3,
}

local function merge_severity(a, b)
	if severity_as_int[a.Severity] > severity_as_int[b.Severity] then
		return a.Severity
	else
		return b.Severity
	end
end

local function merge_message(a, b)
	if a.Message ~= b.Message then
		return a.Message .. "\n" .. b.Message
	else
		return a.Message
	end
end

local function skip_to_next_problem(problems, i)
	while spans_match(problems[i].Span, next_problem_span(problems, i)) do
		problems[i + 1].Message = merge_message(problems[i], problems[i + 1])
		problems[i + 1].Severity = merge_severity(problems[i], problems[i + 1])
		i = i + 1
	end
	return i
end

local cfg = nil
function M.hl_iter(results, areas)
	-- to_print = results
	-- vim.defer_fn(print_res, 100)
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

function M.setup(_cfg)
	cfg = _cfg
end

return M
