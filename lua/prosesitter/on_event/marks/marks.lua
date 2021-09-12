local api = vim.api
local log = require("prosesitter/log")
local res = require("prosesitter/on_event/marks/process_results")

local M = {}
local ns_marks = nil
local ns_placeholders = nil
local mark_to_hover = nil

local function remove_row_marks(buf, row)
	local marks = api.nvim_buf_get_extmarks(buf, ns_marks, { row, 0 }, { row, -1 }, {})
	for _, mark in ipairs(marks) do
		api.nvim_buf_del_extmark(buf, ns_marks, mark[1])
	end
end

local function nvim_buf_set_extmark_traced(buf_id, row, col, opt)
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

local function remove_marks(areas)
	for _, area in ipairs(areas) do
		local mark = api.nvim_buf_get_extmark_by_id(area.buf_id, ns_placeholders, area.row_id, { details = true })
		local row = mark[1]
		if row ~= nil then
			remove_row_marks(area.buf_id, row)
		end
	end
end

function M.mark_results(results, areas)
	remove_marks(areas)

	for hl in res.hl_iter(results, areas) do
		local mark = api.nvim_buf_get_extmark_by_id(hl.buf_id, ns_placeholders, hl.row_id, { details = true })
		if mark[1] == nil then goto continue end

		local row = mark[1]
		local col_offset = mark[2]

		local opt = {
			end_col = col_offset + hl.end_col - 1,
			hl_group = hl.group,
		}
		local ok, mark_id = nvim_buf_set_extmark_traced(hl.buf_id, row, col_offset + hl.start_col - 2, opt)
		if not ok then goto continue end

		mark_to_hover[mark_id] = hl.hover_txt
		::continue::
	end
end

function M.remove_placeholders(buf, start_row, up_to_row)
	local start = {start_row, 0}
	local up_to = {up_to_row, -1}
	local marks = api.nvim_buf_get_extmarks(buf, ns_placeholders, start, up_to, {})
	for _, mark in ipairs(marks) do
		log.info(vim.inspect(mark))
		api.nvim_buf_del_extmark(buf, ns_placeholders, mark[1])
	end
end

function M.setup(shared)
	mark_to_hover = shared.mark_to_hover
	ns_marks = shared.ns_marks
	ns_placeholders = shared.ns_placeholders
	res.setup(shared.cfg)
end

return M
