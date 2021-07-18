local log = require("prosesitter/log")
local marks = require("prosesitter/on_event/marks")
local check = require("prosesitter/on_event/check/check")
local query = require("vim.treesitter.query")

local disabled = false -- weather the plugin has been disabled
local get_parser = vim.treesitter.get_parser
local api = vim.api
local cfg = nil
local M = {}

local function postprocess(results, meta_array)
	for buf, id, start_c, end_c, hl_group, hover_txt in check.hl_iter(results, meta_array) do
		marks.underline(buf, id, start_c, end_c, hl_group, hover_txt)
	end
end

local hl_queries = {}
local function comments(bufnr, start_l, end_l)
	local parser = get_parser(bufnr)
	local lang = parser:lang()
	local hl_query = hl_queries[lang]
	local nodes = {}

	parser:for_each_tree(function(tstree, _)
		local root_node = tstree:root()
		local root_start_row, _, root_end_row, _ = root_node:range()

		-- Only worry about trees within the line range
		if root_start_row > start_l or root_end_row < end_l then
			return
		end
		for id, node in hl_query:iter_captures(root_node, bufnr, start_l, end_l) do
			if vim.tbl_contains(cfg.captures, hl_query.captures[id]) then
				nodes[#nodes+1] = node
			end
		end
	end)
	return nodes
end

function M.on_lines(_, buf, _, first_changed, last_changed, last_updated, byte_count, _, _)
	if disabled then return true end  -- stop calling on lines if the plugin was just disabled

	local lines_removed = first_changed == last_updated
	if lines_removed then
		log.info("lines removed from: " .. first_changed .. " to: " .. last_changed)
		marks.remove_line(buf, first_changed, last_changed)
		return
	end

	for _, comment in pairs(comments(buf, first_changed, last_changed)) do
		local start_row, start_col, end_row, end_col = comment:range()

		if start_row == end_row then
			check.lint_req:add(buf, start_row, start_col, end_col) -- FIXME this is not running... why?
		else
			for row=start_row,end_row-1 do
				check.lint_req:add(buf, row, start_col, 0)
				start_col = 0 -- only relevent for first line of comment
			end
			check.lint_req:add(buf, end_row, 0, end_col)
		end
	end

	if not check.schedualled then
		check.schedual()
	end
end

function M.on_win(_, _, bufnr)
	if not api.nvim_buf_is_loaded(bufnr) or api.nvim_buf_get_option(bufnr, "buftype") ~= "" then
		return false
	end

	if vim.tbl_isempty(cfg.captures) then
		return false
	end

	local ok, parser = pcall(get_parser, bufnr)
	if not ok then
		return false
	end

	local lang = parser:lang()
	if not hl_queries[lang] then
		hl_queries[lang] = query.get_query(lang, "highlights")
	end

	api.nvim_buf_attach(bufnr, false, {
		on_lines = M.on_lines,
	})

	-- FIXME: shouldn't be required. Possibly related to:
	-- https://github.com/nvim-treesitter/nvim-treesitter/issues/1124
	parser:parse()
	local info = vim.fn.getbufinfo(bufnr)
	local last_line = info[1].linecount
	M.on_lines(nil, bufnr, nil, 0, last_line, last_line, 9999, nil, nil)
end

function M.setup(shared)
	check:setup(shared, postprocess)
	marks.setup(shared)

	cfg = shared.cfg
end

function M.enable()
	disabled = false
end

function M.disable()
	disabled = true
	check:disable()
end

return M
