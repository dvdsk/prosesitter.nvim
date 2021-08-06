local log = require("prosesitter/log")
local api = vim.api
local query = require("vim.treesitter.query")
local get_parser = vim.treesitter.get_parser

local cfg_by_buf = nil
local check = nil
local M = {}

local prose_queries = {}
local function get_nodes(bufnr, cfg, start_l, end_l)
	local parser = get_parser(bufnr)
	local lang = parser:lang()
	local prose_query = prose_queries[lang]
	local nodes = {}

	parser:for_each_tree(function(tstree, _)
		local root_node = tstree:root()
		local root_start_row, _, root_end_row, _ = root_node:range()

		-- Only worry about trees within the line range
		if root_start_row > start_l or root_end_row < end_l then
			return
		end
		for _, node in prose_query:iter_captures(root_node, bufnr, start_l, end_l) do
			nodes[#nodes + 1] = node
		end
	end)
	return nodes
end

function M.attach(bufnr)
	if not api.nvim_buf_is_loaded(bufnr) or api.nvim_buf_get_option(bufnr, "buftype") ~= "" then
		return false
	end

	local ok, parser = pcall(get_parser, bufnr)
	if not ok then
		return false
	end

	local lang = parser:lang()
	if not prose_queries[lang] then
		prose_queries[lang] = query.get_query(lang, "proselinter")
	end

	parser:parse()
	local info = vim.fn.getbufinfo(bufnr)
	local last_line = info[1].linecount
	M.on_lines(nil, bufnr, nil, 0, last_line, last_line, 9999, nil, nil)
end

function M.on_lines(_, buf, _, first_changed, last_changed, last_updated, _, _, _)
	 -- stop calling on lines if the plugin was just disabled
	local cfg = cfg_by_buf[buf]
	if cfg == nil then
		return true
	end

	-- do not clean up extmarks, they are still needed in case of undo
	local lines_removed = first_changed == last_updated
	if lines_removed then
		return
	end

	local nodes = get_nodes(buf, cfg, first_changed, last_changed-1)
	cfg.lint_req:on_lines(buf, nodes, first_changed, last_changed-1)

	if not check.schedualled then
		check.schedual()
	end
end

function M.setup(shared, _check)
	cfg_by_buf = shared.cfg.by_buf
	check = _check
end

return M
