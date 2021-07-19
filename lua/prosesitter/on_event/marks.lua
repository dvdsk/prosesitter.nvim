local api = vim.api
local log = require("prosesitter/log")

local M = {}
local ns_marks = nil
local ns_placeholders = nil
local mark_to_hover = nil

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