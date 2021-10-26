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

local function collect_current_span(i, problems, issues, to_issue, hl)
	issues[1] = to_issue(problems[i], hl.start_col, hl.end_col)
	while spans_match(problems[i].Span, next_problem_span(problems, i)) do
		issues[#issues+1] = to_issue(problems[i], hl.start_col, hl.end_col)
		i = i + 1
	end
	return i
end

-- returns hl: start_col, end_col, buf_id, row_id, meta
-- from meta the hl group can be deduced
function M.mark_iter(problems, areas, to_issue)
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

		local hl = {}
		hl.start_col, j = start_col(problems[i], areas, j)
		hl.end_col = end_col(problems[i], areas, j)
		hl.buf_id = areas[j].buf_id
		hl.row_id = areas[j].row_id

		local issues = {}
		i = collect_current_span(i, problems, issues, to_issue, hl)

		return hl, issues
	end
end

return M
