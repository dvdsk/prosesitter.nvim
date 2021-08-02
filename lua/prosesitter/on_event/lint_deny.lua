local log = require("prosesitter/log")
local api = vim.api
local ns = nil

local M = {}
M.__index = M -- failed table lookups on the instances should fallback to the class table, to get methods
function M.new()
	local self = setmetatable({}, M)
	self.meta_by_mark = {}
	self.marks = {}
	return self
end

function M:reset()
	self.meta_by_mark = {}
	self.marks = {}
end

function M:is_empty()
	log.error("not implemented")
	return false
end

-- returns placeholder ext-marks array sorted by
-- buffer then row number
local large_numb = 2 ^ 20 -- about 1 million
function M:marks_sorted_by_row()
	local unsorted = {}
	for mark_id, mark_buf in pairs(self.marks) do
		-- need to get the row again in case text was inserted above it
		local row = api.nvim_buf_get_extmark_by_id(mark_buf, ns, mark_id, {})[1]
		unsorted[#unsorted + 1] = { buf = mark_buf, row = row, id = mark_id }
	end
	table.sort(unsorted, function(a, b) -- ascending sort
		return a.buf * large_numb + a.row < b.buf * large_numb + b.row
	end)
	return unsorted -- is now sorted
end

-- TODO refactor: too long!
function M:build()
	local req = { text = {}, areas = {} }
	local marks = self:marks_sorted_by_row()

	local col = 0
	for _, line in ipairs(marks) do
		local line_txt = api.nvim_buf_get_lines(line.buf, line.row, line.row+1, false)[1]
		local forbidden = self.meta_by_mark[line.id]
		if forbidden == nil then
			if #line_txt > 0 then
				req.text[#req.text+1] = line_txt
				req.areas[#req.areas+1] = {
					col = col,
					row_col = 0,
					row_id = line.id,
					buf_id = line.buf,
				}
				col = col + #line_txt + 1
			end
			goto continue1
		end

		local current_end = 1
		for _, forbidden_area in ipairs(forbidden) do
			local next_start = forbidden_area.start_col
			if next_start - current_end > 0 then
				req.text[#req.text+1] = line_txt:sub(current_end, next_start)
				req.areas[#req.areas+1] = {
					col = col,
					row_col = current_end,
					row_id = line.id,
					buf_id = line.buf,
				}
				col = col + next_start - current_end + 2
			end
			current_end = forbidden_area.end_col + 1
		end

		if current_end ~= #line_txt then
			req.text[#req.text+1] = line_txt:sub(current_end, -1)
			req.areas[#req.areas+1] = {
				col = col,
				row_col = current_end,
				row_id = line.id,
				buf_id = line.buf,
			}
			col = col + #line_txt - current_end + 2
		end

		::continue1::
	end
	self:reset()
	return req
end

function M:add_marks(buf)
	-- not an array, row can be zero
	for _, id in pairs(self.marks_by_row) do
		self.marks[id] = buf
	end
end

function M:ensure_placeholders(buf, start_l, end_l)
	self.marks_by_row = {}
	local j = 1
	local existing_marks = api.nvim_buf_get_extmarks(buf, ns, { start_l, 0 }, { end_l, -1 }, {})
	for row = start_l, end_l do
		-- check for existing extmark to reuse
		local existing = existing_marks[j]
		if existing == nil then
			local id = api.nvim_buf_set_extmark(buf, ns, row, 0, {})
			self.marks_by_row[row] = id
		else
			local id = existing[1]
			-- existing marks and for loop have same order
			self.marks_by_row[row] = id
		end
	end
end

-- nodes should be arriving in order, therefore line_meta is correctly sorted
function M:note_hl(buf, row, start_col, end_col)
	local mark_id = self.marks_by_row[row]
	local line_meta = self.meta_by_mark[mark_id]
	local meta = { buf = buf, start_col = start_col, end_col = end_col }
	if line_meta == nil then
		self.meta_by_mark[mark_id] = { meta }
	else
		-- there can be multiple forbidden (hl) zones per line
		line_meta[#line_meta + 1] = meta
	end
end

function M:on_lines(buf, nodes, start_l, end_l)
	self:ensure_placeholders(buf, start_l, end_l)

	for _, node in pairs(nodes) do
		local start_row, start_col, end_row, end_col = node:range()
		if start_row > end_l or end_row < start_l then
			goto continue
		end

		start_row = math.max(start_row, start_l)
		end_row = math.min(end_row, end_l)

		if start_row == end_row then
			self:note_hl(buf, start_row, start_col, end_col)
		else
			for row = start_row, end_row - 1 do
				self:note_hl(buf, row, start_col, 0)
				start_col = 0 -- only relevent for first line of comment
			end
			self:note_hl(buf, end_row, 0, end_col)
		end
		::continue::
	end

	self:add_marks(buf)
end

function M.setup(shared)
	ns = shared.ns_placeholders
end

return M
