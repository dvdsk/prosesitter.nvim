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

function M:is_empty()
	log.error("not implemented")
	return empty
end

-- returns placeholder ext-marks array sorted by
-- buffer then row number
local large_numb = math.huge/4
function M:marks_sorted_by_row()
	local unsorted = {}
	log.info(vim.inspect(self.marks))
	for _, mark in ipairs(self.marks) do
		local row, _ = api.nvim_buf_get_extmark_by_id(mark.buf, ns, mark.id, {})
		unsorted[#unsorted + 1] = { buf = mark.buf, row = row, id = mark.id }
	end
	table.sort(unsorted, function(a, b) -- ascending sort
		return a.buf * large_numb + a.row < b.buf * large_numb + b.row
	end)
	return unsorted -- is now sorted
end

function M:build()
	local req = { text = {}, areas = {} }
	local marks = self:marks_sorted_by_row()

	local col = 0
	for _, mark in ipairs(marks) do
		local line_txt = api.nvim_buf_get_lines(mark.buf, mark.row, mark.row, true)[1]
		local line_meta = self.meta_by_mark[mark.id]
		if line_meta == nil then
			req.text[#req.text + 1] = line_txt
			col = col + #line_txt + 1
		else
			for _, meta in ipairs() do
				local area = {
					col = col, -- column in text passed to linter
					row_col = meta.start_col, -- column in buffer
					row_id = mark.id, -- extmark at the start of the row
					buf_id = meta.buf,
				}
				req.areas[#req.areas + 1] = area
				req.text[#req.text + 1] = line_txt:sub(meta.start_col, meta.end_col)
				col = col + meta.end_col - meta.start_col
			end
		end
	end

	return req
end

function M:ensure_placeholders(buf, start_l, end_l)
	local marks = api.nvim_buf_get_extmarks(buf, ns, { start_l, 0 }, { end_l + 1, 0 }, {})
	local j = 1
	for i = start_l, end_l do
		-- second element of mark is the row
		if marks[j][2] == i + 1 then -- i uses zero based indexing
			j = j + 1
		else
			local id = api.nvim_buf_set_extmark(buf, ns, i, 0, {})
			self.marks[#self.marks + 1] = { id = id, buf = buf }
		end
	end
end

-- nodes should be arriving in order, therefore line_meta is correctly sorted
function M:note_hl(buf, row, start_col, end_col)
	local marks = api.nvim_buf_get_extmarks(buf, ns, { row, 0 }, { row, 0 }, {})
	local line_meta = self.meta_by_mark[marks[1]]
	line_meta[#line_meta + 1] = { buf = buf, start_col = start_col, end_col = end_col }
end

function M:on_lines(buf, nodes, start_l, end_l)
	self:ensure_placeholders(buf, start_l, end_l)

	for _, node in pairs(nodes) do
		local start_row, start_col, end_row, end_col = node:range()

		if start_row == end_row then
			self:note_hl(buf, start_row, start_col, end_col)
		else
			for row = start_row, end_row - 1 do
				self:note_hl(buf, row, start_col, 0)
				start_col = 0 -- only relevent for first line of comment
			end
			self:note_hl(buf, end_row, 0, end_col)
		end
	end

	log.error("unimplemented")
end

function M.setup(shared)
	ns = shared.ns_placeholders
end

return M
