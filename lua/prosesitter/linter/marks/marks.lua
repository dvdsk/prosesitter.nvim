local api = vim.api
local log = require("prosesitter/log")
local res = require("prosesitter/linter/marks/process_results")
local state = require("prosesitter/state")

local M = {}
local ns_placeholders = state.ns_placeholders
local ns_marks =state.ns_marks

local function clear_mark_for(buf, mark, linter)
	local id = mark[1]
	local outdated = state.issues:remove(linter, buf, id)
	if outdated == nil then
		return
	end

	local linked = state.issues:linked_issue(linter, buf, id)
	if linked == nil then
		api.nvim_buf_del_extmark(buf, ns_marks, id)
		return
	end

	-- return if the mark is still valid for the other linter
	if mark[4].hl_group == outdated:hl_group() then
		return
	end

	-- color of the mark needs to be adjusted
	local row = mark[2]
	local col = mark[3]
	local opt = { id= id, end_col = mark[4].end_col, hl_group = linked:hl_group() }
	api.nvim_buf_set_extmark(buf, ns_marks, row, col, opt)
end

local function remove_row_marks(buf, row, linter)
	local marks = api.nvim_buf_get_extmarks(buf, ns_marks, { row, 0 }, { row, -1 }, {details = true})
	for _, mark in ipairs(marks) do
		clear_mark_for(buf, mark, linter)
	end
end

local function remove_old_marks(areas, linter)
	local cleared =	{}
	for _, area in ipairs(areas) do
		local mark = api.nvim_buf_get_extmark_by_id(area.buf_id, ns_placeholders, area.row_id, { details = true })
		local row = mark[1]
		if row ~= nil then
			if cleared[row] == nil then
				remove_row_marks(area.buf_id, row, linter)
			end
			cleared[row] = true
		end
	end
end

local function check_existing_mark(buf, row, start_col, end_col)
	local marks = api.nvim_buf_get_extmarks(buf, ns_marks,
		{ row, start_col }, { row, end_col },
		{details = true})

	for _, mark in ipairs(marks) do
		if end_col == mark[4].end_col then
			return mark
		end
	end
end

local function ensure_marked(linter, issue_list, buf, row, start_col, end_col)
	local mark = check_existing_mark(buf, row, start_col, end_col)
	if mark == nil then
		local opt = { end_col = end_col, hl_group = issue_list:hl_group()}
		local ok, id = pcall(api.nvim_buf_set_extmark, buf, ns_marks, row, start_col, opt)
		if not ok then return end
		log.debug("added mark, id,linter,buf:",id,linter,buf)
		state.issues:set(buf, linter, id, issue_list)
		return
	end

	-- as there is already an extmark there **has tot be a linked issue**
	-- this because we cleared any of the current linters marks previously
	-- and mark pos, length is unique
	local linked_id = mark[1]
	local linked = state.issues:linked_issue(linter, buf, linked_id)

	if linked:severity() > issue_list:severity() then
		state.issues:set(buf, linter, linked_id, issue_list)
	else
		local opt = { id = linked_id, end_col = end_col, hl_group = issue_list:hl_group()}
		api.nvim_buf_set_extmark(buf, ns_marks, row, start_col, opt)
		state.issues:set(buf, linter, linked_id, issue_list)
	end
end

function M.mark_results(results, areas, linter, to_issue)
	remove_old_marks(areas, linter)
	for hl, issue_list in res.mark_iter(results, areas, to_issue) do
		local mark, _ = api.nvim_buf_get_extmark_by_id(hl.buf_id, ns_placeholders, hl.row_id, { details = true })
		if mark[1] == nil then goto continue end

		local row = mark[1]
		local col_offset = mark[2]

		local start_col = col_offset + hl.start_col - 2
		local end_col = col_offset + hl.end_col - 1
		ensure_marked(linter, issue_list, hl.buf_id, row, start_col, end_col)
		::continue::
	end
end

function M.remove_placeholders(buf, start_row, up_to_row)
	-- log.info("removing placeholders row: "..start_row.." up to: "..up_to_row)
	local start = {start_row, 0}
	local up_to = {up_to_row, -1}
	local marks = api.nvim_buf_get_extmarks(buf, ns_placeholders, start, up_to, {})
	for _, mark in ipairs(marks) do
		api.nvim_buf_del_extmark(buf, ns_placeholders, mark[1])
	end
end

function M.get_closest(start, stop)
	local marks = api.nvim_buf_get_extmarks(0, ns_marks, start, stop, {})
	-- local marks = api.nvim_buf_get_extmarks(0, ns_marks, start, stop, { limit = 1 })
	return marks[1]
end

function M.get_marks(buf)
	local marks = api.nvim_buf_get_extmarks(buf, ns_marks, 0, -1, { details = true })
	return marks
end

return M
