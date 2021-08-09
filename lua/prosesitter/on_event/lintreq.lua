local log = require("prosesitter/log")
local api = vim.api
local ns = nil

local M = {}
M.__index = M -- failed table lookups on the instances should fallback to the class table, to get methods
function M.new()
	local self = setmetatable({}, M)
	self.text = {}
	self.meta_by_mark = {}
	self.meta_by_idx = {}
	return self
end

function M:add_node(buf, node)
	local start_row, start_col, end_row, end_col = node:range()
	if start_row == end_row then
		self:add_line(buf, start_row, start_col+1, end_col)
	else
		for row = start_row, end_row do
			self:add_line(buf, row, start_col, -1)
			start_col = 1 -- only relevant for first line of block node
		end
		self:add_line(buf, end_row, 1, end_col)
	end
end

function M:update(id, new_line, start_col)
	local meta = self.meta_by_mark[id]
	meta.row_col = start_col
	self.text[meta.idx] = new_line
end

function M:add_line(buf, row, start_col, end_col)
	local full_line = api.nvim_buf_get_lines(buf, row, row + 1, true)
	local line = string.sub(full_line[1], start_col, end_col)

	local id = nil
	local marks = api.nvim_buf_get_extmarks(buf, ns, { row, 0 }, { row, 0 }, {})
	if #marks > 0 then
		id = marks[1][1] -- there can be a max of 1 placeholder per line
		if self.meta_by_mark[id] ~= nil then
			self:update(id, line, start_col)
			return
		end
	else
		id = api.nvim_buf_set_extmark(buf, ns, row, 0, { end_col = 0 })
	end

	local meta = { buf = buf, id = id, row_col = start_col, idx = #self.text + 1 }
	self.meta_by_mark[id] = meta
	self.meta_by_idx[#self.text + 1] = meta
	self.text[#self.text + 1] = line
end

function M:is_empty()
	local empty = next(self.text) == nil
	return empty
end

-- returns a request with members:
function M:build()
	local req = {}
	req.text = table.concat(self.text, " ")
	req.areas = {}

	local col = 0
	for i = 1, #self.text do
		local meta = self.meta_by_idx[i]
		local area = {
			col = col, -- column in text passed to linter
			row_col = meta.row_col, -- column in buffer
			row_id = meta.id, -- extmark at the start of the row
			buf_id = meta.buf,
		}
		req.areas[#req.areas + 1] = area
		col = col + #self.text[i] + 1 -- plus one for the line end
	end

	return req
end

function M.setup(shared)
	ns = shared.ns_placeholders
end

return M
