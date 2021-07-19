local api = vim.api
local log = require("prosesitter/log")

local M = {}
local ns_marks = nil
local ns_placeholders = nil
local mark_to_hover = nil

-- remove extmarks between line start and stop
function M.remove_line(bufnr, start, stop)
	-- remove permanent extmarks
	local es = api.nvim_buf_get_extmarks(bufnr, ns_marks, {start,0}, {stop-1,0}, {})
	for _, e in ipairs(es) do
		api.nvim_buf_del_extmark(bufnr, ns_marks, e[1])
	end
	-- remove placeholder marks (max one per line)
	local placeholders = api.nvim_buf_get_extmarks(bufnr, ns_placeholders, {start,0}, {stop,-1}, {})
	api.nvim_buf_del_extmark(bufnr, ns_placeholders, placeholders[1][1])
end

function M.underline(bufnr, id, start_col, end_col, hl, hover_txt)
	local mark = api.nvim_buf_get_extmark_by_id(bufnr, ns_placeholders, id, {details = false})
	-- TODO cleanup placeholders
	local row = mark[1]

	local opt = {
		end_col = end_col,
		hl_group = hl,
	}
	local ok, mark_id = pcall(api.nvim_buf_set_extmark, bufnr, ns_marks, row, start_col-1, opt)
	mark_to_hover[mark_id] = hover_txt
	if not ok then
		log.error("Failed to add extmark, lnum="..vim.inspect(row).." pos="..start_col.." text="..hover_txt)
	end
end

function M.setup(shared)
	mark_to_hover = shared.mark_to_hover
	ns_marks = shared.ns_marks
	ns_placeholders = shared.ns_placeholders -- seperate namespace for placeholder marks
end

return M
