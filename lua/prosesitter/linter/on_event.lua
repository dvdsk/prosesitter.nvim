local log = require("prosesitter/log")
local marks = require("prosesitter/linter/marks/marks")
local check = require("prosesitter/linter/check/check")
local state = require("prosesitter/state")

local api = vim.api
local M = {}

local function node_in_range(A, B, node)
	local a, _, b, _ = node:range()
	if a <= B and b >= A then -- TODO sharpen bounds
		return true
	else
		return false
	end
end

local BufMemory = {}
function BufMemory:reset()
	for i, _ in ipairs(self) do self[i] = nil end
end
function BufMemory:no_change(buf, start_row)
	local line =api.nvim_buf_get_lines(buf, start_row, start_row + 1, false)[1]

	if self[buf] == nil then
		self[buf] = line
		return false
	elseif self[buf] == line then
		return true
	else
		self[buf] = line
		return false
	end
end

local prose_queries = {}
local function add_nodes(bufnr, lintreq, start_l, end_l)
	local add_node = state.buf[bufnr].preprosessing
	local parser = state.buf[bufnr].parsers
	local lang = parser:lang()
	local prose_query = prose_queries[lang]

	parser:for_each_tree(function(tstree, _)
		local root_node = tstree:root()
		if not node_in_range(start_l, end_l, root_node) then
			return -- return in this callback skips to checking the next tree
		end

		for _, node, meta in prose_query:iter_captures(root_node, bufnr, start_l, end_l + 1) do
			if node_in_range(start_l, end_l, node) then
				add_node(bufnr, node, meta, lintreq)
			end
		end
	end)
end

local function delayed_on_bytes(...)
	local args = { ... }
	vim.defer_fn(function()
		M.on_bytes(unpack(args))
	end, 25)
end

function M:lint_everything(bufnr)
	BufMemory:reset()
	local info = vim.fn.getbufinfo(bufnr)
	local last_line = info[1].linecount
	self.on_bytes(bufnr, nil, 0, nil, nil, last_line, nil, nil, last_line, nil, nil)
end

local q = require("vim.treesitter.query")
function M.attach(bufnr)
	if not api.nvim_buf_is_loaded(bufnr) or api.nvim_buf_get_option(bufnr, "buftype") ~= "" then
		return false, "not a normal buffer"
	end

	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok then
		return false, "treesitter had no parser for this buffer"
	end

	local lang = parser:lang()
	if not prose_queries[lang] then
		prose_queries[lang] = q.parse_query(lang, state.buf[bufnr].query)
	end

	-- keep the parser to let vim know we need it
	state.buf[bufnr].parsers = parser
	parser:register_cbs({ on_bytes = delayed_on_bytes })
	M:lint_everything(bufnr)
	return true
end


function M.on_bytes(
	buf,
	_, --changed_tick,
	start_row,
	_, --start_col,
	_, --start_byte,
	old_row,
	_, --old_col,
	_, --old_byte,
	new_row,
	_, --new_col,
	_ --new_byte
)
	-- stop calling on lines if the plugin was just disabled
	local query = state.buf[buf].query
	if query == nil then
		return true
	end

	if BufMemory:no_change(buf, start_row) then
		return
	end

	-- on deletion it seems like new row is always '-0' while old_row is not '-0'
	-- 		(might be the number of rows deleted)
	-- do not clean up highlighting extmarks, they are still needed in case of undo
	local lines_removed = (new_row == -0 and old_row ~= -0)
	local change_start = start_row
	local change_end = start_row + old_row
	if lines_removed then
		marks.remove_placeholders(buf, change_start, change_end)
		return
	end

	local lintreq = state.buf[buf].lintreq
	lintreq:clear_lines(buf, change_start, change_end)
	add_nodes(buf, lintreq, change_start, change_end)

	if not check:schedualled() then
		check:schedual(buf)
	end
end

function M.disable()
	BufMemory:reset()
	check:disable()
end

return M
