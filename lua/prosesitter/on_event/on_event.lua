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
		if root_start_row > end_l or root_end_row < start_l then
			return
		end
		for _, node in prose_query:iter_captures(root_node, bufnr, start_l, end_l) do
			nodes[#nodes + 1] = node
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

	local nodes = get_nodes(buf, cfg, first_changed, last_changed - 1)
	M.process_nodes(buf, nodes)

	-- if not check.schedualled then
	-- 	check.schedual()
	-- end
end

-- TODO add to lintreq here, take care to allow multi line comments
function M.process_nodes(buf, nodes)
	for _, node in ipairs(nodes) do
		local start_row, start_col, end_row, end_col = node:range()
		log.info(start_row, start_col, end_row, end_col)
	end
end

function M.setup(shared)
	cfg_by_buf = shared.cfg.by_buf
	check:setup(shared, postprocess)
	marks.setup(shared)
end

function M.disable()
	check:disable()
end

return M
