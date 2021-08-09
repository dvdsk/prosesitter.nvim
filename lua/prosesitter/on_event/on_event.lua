local log = require("prosesitter/log")
local marks = require("prosesitter/on_event/marks")
local check = require("prosesitter/on_event/check/check")

local get_parser = vim.treesitter.get_parser
local api = vim.api
local M = {}

local function postprocess(results, lintreq)
	for buf, id, start_c, end_c, hl_group, hover_txt in check.hl_iter(results, lintreq) do
		marks.underline(buf, id, start_c, end_c, hl_group, hover_txt)
	end
end

local function node_in_range(A, B, node)
	local a, _, b, _ = node:range()
	if a <= B and b >= A then -- TODO sharpen bounds
		return true
	else
		return false
	end
end

local function key(node)
	local row_start, col_start, row_end, col_end = node:range()
	local keystr = { row_start, col_start, row_end, col_end }
	return table.concat(keystr, "\0")
end

local prose_queries = {}
local function get_nodes(bufnr, cfg, start_l, end_l)
	local parser = get_parser(bufnr)
	local lang = parser:lang()
	local prose_query = prose_queries[lang]
	local nodes = {}

	parser:for_each_tree(function(tstree, _)
		local root_node = tstree:root()
		if not node_in_range(start_l, end_l, root_node) then
			return -- return in this callback skips to checking the next tree
		end

		for _, node in prose_query:iter_captures(root_node, bufnr, start_l, end_l + 1) do
			if node_in_range(start_l, end_l, node) then
				nodes[key(node)] = node
			end
		end
	end)
	return nodes
end

local cfg_by_buf = nil
local query = require("vim.treesitter.query")
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
		prose_queries[lang] = query.parse_query(lang, cfg_by_buf[bufnr].query)
	end

	api.nvim_buf_attach(bufnr, false, { on_lines = M.on_lines })

	parser:parse()
	local info = vim.fn.getbufinfo(bufnr)
	local last_line = info[1].linecount
	M.on_lines(nil, bufnr, nil, 0, last_line, last_line, 9999, nil, nil)
end

local lintreq = nil
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

	local nodes = get_nodes(buf, cfg, first_changed, last_changed - 1)
	for _, node in pairs(nodes) do
		lintreq:add_node(buf, node)
	end

	if not check.schedualled then
		check.schedual()
	end
end

function M.setup(shared)
	cfg_by_buf = shared.cfg.by_buf
	check:setup(shared, postprocess)
	lintreq = check:get_lintreq()
	marks.setup(shared)
end

function M.disable()
	check:disable()
end

return M
