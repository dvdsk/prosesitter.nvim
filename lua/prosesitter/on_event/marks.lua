local api = vim.api
local log = require("prosesitter/log")

local M = {}
local ns_marks = nil
local ns_placeholders = nil

-- remove extmarks between line start and stop
function M.remove_line_extmarks(bufnr, start, stop)
	-- remove permanent extmarks
	local es = api.nvim_buf_get_extmarks(bufnr, ns_marks, {start,0}, {stop,-1}, {})
	for _, e in ipairs(es) do
	api.nvim_buf_del_extmark(bufnr, M.ns, e[1])
	end
	-- remove placeholder marks (max one per line)
	local placeholders = api.nvim_buf_get_extmarks(bufnr, ns_placeholders, {start,0}, {stop,-1}, {})
	api.nvim_buf_del_extmark(bufnr, ns_placeholders, placeholders[1][1])

end

function M.underline(bufnr, id, start_col, end_col, hl)
	log.info(vim.inspect(ns_placeholders))
	local mark = api.nvim_buf_get_extmark_by_id(bufnr, ns_placeholders, id, {details = false})
	-- TODO cleanup placeholders
	local row = mark[1]

	local opt = {
		end_col = end_col,
		hl_group = hl,
	}
	local ok, _ = pcall(api.nvim_buf_set_extmark, bufnr, ns_marks, row, start_col-1, opt)
	if not ok then
		log.error("Failed to add extmark, lnum="..vim.inspect(row).." pos="..start_col)
	end
end

function M.setup(shared)
	ns_marks = shared.ns_marks
	ns_placeholders = shared.ns_placeholders -- seperate namespace for placeholder marks
end

return M
