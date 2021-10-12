local api = vim.api
local log = require("prosesitter/log")
local res = require("prosesitter/on_event/marks/process_results")
local shared = require("prosesitter/shared")

local M = {}
local ns_placeholders = nil

local function remove_row_marks(buf, row, mark_ns)
	local marks = api.nvim_buf_get_extmarks(buf, mark_ns, { row, 0 }, { row, -1 }, {})
	for _, mark in ipairs(marks) do
		api.nvim_buf_del_extmark(buf, mark_ns, mark[1])
	end
end

local function set_extmark(buf_id, mark_ns, row, col, opt)
	local ok, val = pcall(api.nvim_buf_set_extmark, buf_id, mark_ns, row, col, opt)
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

local function remove_old_marks(areas, mark_ns)
	for _, area in ipairs(areas) do
		local mark = api.nvim_buf_get_extmark_by_id(area.buf_id, ns_placeholders, area.row_id, { details = true })
		local row = mark[1]
		if row ~= nil then
			remove_row_marks(area.buf_id, row, mark_ns)
		end
	end
end

local function mark_results(results, areas, mark_ns)
	remove_old_marks(areas, mark_ns)
	for hl in res.hl_iter(results, areas) do
		local mark = api.nvim_buf_get_extmark_by_id(hl.buf_id, ns_placeholders, hl.row_id, { details = true })
		if mark[1] == nil then goto continue end

		local row = mark[1]
		local col_offset = mark[2]

		local opt = {
			end_col = col_offset + hl.end_col - 1,
			hl_group = hl.group,
		}
		local ok, mark_id = set_extmark(hl.buf_id, mark_ns, row, col_offset + hl.start_col - 2, opt)
		if not ok then goto continue end

		shared.mark_to_meta:add(mark_id, hl.hover_txt)
		::continue::
	end
end

local ns_vale = nil
function M.mark_vale_results(results, areas)
	mark_results(results, areas, ns_vale)
end

local ns_langtool = nil
function M.mark_langtool_results(results, areas)
	mark_results(results, areas, ns_langtool)
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
	ns_vale = shared.ns_vale
	ns_langtool = shared.ns_langtool
	ns_placeholders = shared.ns_placeholders
end

-- works unless lines > 999999 chars
local function offset(mark)
	return mark[1][2] * 999999 + mark[1][3]
end

function M.get_closest_mark(start, stop)
	local vale = api.nvim_buf_get_extmarks(0, shared.ns_vale, start, stop, { limit = 1 })
	local langtool = api.nvim_buf_get_extmarks(0, shared.ns_langtool, start, stop, { limit = 1 })

	if #vale == 0 then
		return langtool
	elseif #langtool == 0 then
		return vale
	else
		if offset(vale) < offset(langtool) then
			return vale
		else
			return langtool
		end
	end
end

function M.get_marks(buf)
	local marks = api.nvim_buf_get_extmarks(buf, shared.ns_vale, 0, -1, { details = true })
	local langtool = api.nvim_buf_get_extmarks(buf, shared.ns_langtool, 0, -1, { details = true })

	for _, mark in ipairs(langtool) do
		marks[#marks+1] = mark
	end

	return marks
end

return M
