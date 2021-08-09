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

function M:update(marks, buf, row, start_col, end_col)
	-- remove all but first mark on the current line, change that first mark
	-- into a placeholder mark
	local id = marks[1][1] -- there can be a max of 1 placeholder per line
	local opt = { id = id, end_col = 0 }
	api.nvim_buf_set_extmark(buf, M.ns, row, 0, opt) -- update placeholder
	local full_new_line = api.nvim_buf_get_lines(buf, row, row + 1, true)[1]
	local new_line = string.sub(full_new_line, start_col, end_col)
	local idx = self.meta_by_mark[id].text_idx
	self.text[idx] = new_line
end

function M:add_node(buf, node)
	local start_row, start_col, end_row, end_col = node:range()
	if start_row == end_row then
		self:add_line(buf, start_row, start_col, end_col)
	else
		for row = start_row, end_row - 1 do
			self:add_line(buf, row, start_col, 0)
			start_col = 0 -- only relevant for first line of block node
		end
		self:add_line(buf, end_row, 0, end_col)
	end
end

-- only single lines are added... issue if line breaks connect scentences
function M:add_line(buf, row, start_col, end_col)
	-- TODO do we want start_col till end coll?
	-- what happens if a comment is moved further from the line start?
	local marks = api.nvim_buf_get_extmarks(buf, ns, { row, 0 }, { row, 0 }, {})
	if #marks > 0 then
		self:update(marks, buf, row, start_col, end_col)
		return
	end

	local opt = { end_col = 0 }
	local ok, placeholder_id = pcall(api.nvim_buf_set_extmark, buf, ns, row, 0, opt)
	if ok == false then
		log.info("could not add placeholder: ", buf, ns, row, start_col, end_col)
	end
	local full_line = api.nvim_buf_get_lines(buf, row, row + 1, true)
	local line = string.sub(full_line[1], start_col, end_col)
	self.text[#self.text + 1] = line

	local meta = { buf = buf, id = placeholder_id, row_col = start_col }
	self.meta_by_mark[placeholder_id] = meta
	self.meta_by_idx[#self.text] = meta
end

function M:is_empty()
	local empty = next(self.text) == nil
	return empty
end

-- for some unknown reason table.concat hangs infinitly. Since we usually do not have
-- that many strings in table this is an okay alternative
local function to_string(table)
	-- local array = {}
	local text = ""
	for _, v in pairs(table) do
		text = text .. v .. " "
		-- array[#array+1] = v
	end
	-- local text = table.concat(array, "\n", 1, 2)
	return text
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
