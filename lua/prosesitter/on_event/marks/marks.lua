local api = vim.api
local log = require("prosesitter/log")
local res = require("prosesitter/on_event/marks/process_results")

local M = {}
local ns_marks = nil
local ns_placeholders = nil
local mark_to_hover = nil

local function remove_marks(buf, row)
	local marks = api.nvim_buf_get_extmarks(buf, ns_marks, { row, 0 }, { row, -1 }, {})
	for _, mark in ipairs(marks) do
		api.nvim_buf_del_extmark(buf, ns_marks, mark[1])
	end
end

function M.mark_results(results, areas)
	local last_clear_row = -1
	for hl in res.hl_iter(results, areas) do
		local mark = api.nvim_buf_get_extmark_by_id(hl.buf_id, ns_placeholders, hl.row_id, { details = true })
		local row = mark[1]
		local col_offset = mark[2]

		if row > last_clear_row then
			remove_marks(hl.buf_id, row)
			last_clear_row = row
		end

		local opt = {
			end_col = col_offset + hl.end_col - 1,
			hl_group = hl.group,
		}
		local mark_id = api.nvim_buf_set_extmark(hl.buf_id, ns_marks, row, col_offset + hl.start_col - 2, opt)
		mark_to_hover[mark_id] = hl.hover_txt
	end
end

function M.setup(shared)
	mark_to_hover = shared.mark_to_hover
	ns_marks = shared.ns_marks
	ns_placeholders = shared.ns_placeholders
	res.setup(shared.cfg)
end

return M
