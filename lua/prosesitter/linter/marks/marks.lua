local api = vim.api
local log = require("prosesitter/log")
local res = require("prosesitter/linter/marks/process_results")
local state = require("prosesitter/state")
local issues = require("prosesitter/linter/issues")

local M = {}
local ns_placeholders = "will be set in setup"
local ns_marks = "will be set in setup"

local function remove_row_marks(buf, row, linter)
	local marks = api.nvim_buf_get_extmarks(buf, ns_marks, { row, 0 }, { row, -1 }, {})
	for _, mark in ipairs(marks) do
		local id = mark[1]
		if state.issues:clear_meta_for(linter, buf, id) then
			api.nvim_buf_del_extmark(buf, ns_marks, mark[1])
		end
	end
end

local function set_extmark(buf_id, row, col, opt)
	local ok, val = pcall(api.nvim_buf_set_extmark, buf_id, ns_marks, row, col, opt)
	-- if not ok then
	-- 	log.fatal(
	-- 		"could not place extmark"
	-- 			.. "\nbuf_id: "
	-- 			.. vim.inspect(buf_id)
	-- 			.. "\nrow: "
	-- 			.. vim.inspect(row)
	-- 			.. "\ncol_start: "
	-- 			.. vim.inspect(col)
	-- 			.. "\ncol_end: "
	-- 			.. vim.inspect(opt.end_col)
	-- 	)
	-- end
	return ok, val
end

local function remove_old_marks(areas, linter)
	for _, area in ipairs(areas) do
		local mark = api.nvim_buf_get_extmark_by_id(area.buf_id, ns_placeholders, area.row_id, { details = true })
		local row = mark[1]
		if row ~= nil then
			remove_row_marks(area.buf_id, row, linter)
		end
	end
end

function M.mark_results(results, areas, linter, to_meta)
	remove_old_marks(areas, linter)
	for hl, lints in res.mark_iter(results, areas, to_meta) do
		local mark, _ = api.nvim_buf_get_extmark_by_id(hl.buf_id, ns_placeholders, hl.row_id, { details = true })
		if mark[1] == nil then goto continue end

		local row = mark[1]
		local col_offset = mark[2]

		local opt = {
			end_col = col_offset + hl.end_col - 1,
			hl_group = issues.hl_group(lints),
		}
		local ok, id = set_extmark(hl.buf_id, row, col_offset + hl.start_col - 2, opt)
		if not ok then goto continue end

		state.issues:set(hl.buf_id, linter, id, lints)
		::continue::
	end
end

function M.remove_placeholders(buf, start_row, up_to_row)
	local start = {start_row, 0}
	local up_to = {up_to_row, -1}
	local marks = api.nvim_buf_get_extmarks(buf, ns_placeholders, start, up_to, {})
	for _, mark in ipairs(marks) do
		api.nvim_buf_del_extmark(buf, ns_placeholders, mark[1])
	end
end

function M.setup()
	ns_marks = state.ns_marks
	ns_placeholders = state.ns_placeholders
end

-- works unless lines > 999999 chars
-- local function offset(mark)
-- 	return mark[1][2] * 999999 + mark[1][3]
-- end

function M.get_closest_mark(start, stop)
	local marks = api.nvim_buf_get_extmarks(0, ns_marks, start, stop, { limit = 1 })
	return marks[1]
end

function M.get_marks(buf)
	local marks = api.nvim_buf_get_extmarks(buf, ns_marks, 0, -1, { details = true })
	return marks
end

return M
