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
	local opt = { id = id, end_col= end_col }
	api.nvim_buf_set_extmark(buf, M.ns, row, start_col, opt) -- update placeholder
	local full_new_line = api.nvim_buf_get_lines(buf, row, row+1, true)[1]
	local new_line = string.sub(full_new_line, start_col, end_col)
	local idx = self.meta_by_mark[id].text_idx
	self.text[idx] = new_line
end

-- only single lines are added... issue if line breaks connect scentences
function M:add(buf, row, start_col, end_col)
	-- TODO do we want start_col till end coll? 
	-- what happens if a comment is moved further from the line start?
	local marks = api.nvim_buf_get_extmarks(buf, ns, {row, start_col}, {row, end_col}, {})
	if #marks > 0 then
		self:update(marks, buf, row, start_col, end_col)
		return
	end

	local opt = { end_col= end_col }
	local ok, placeholder_id = pcall(api.nvim_buf_set_extmark, buf, ns, row, start_col, opt)
	if ok == false then
		log.info("could not add placeholder: ",buf, ns, row, start_col, end_col)
	end
	local full_line = api.nvim_buf_get_lines(buf, row, row+1, true)
	local line = string.sub(full_line[1], start_col, end_col)
	self.text[#self.text+1] = line

	local meta = {buf=buf, text_idx=#self.text, id=placeholder_id}
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
		text=text..v.." "
		-- array[#array+1] = v
	end
	-- local text = table.concat(array, "\n", 1, 2)
	return text
end

function M:build()
	local req = {}
	req.text = to_string(self.text)
	req.meta_array = {}

	local col = 0
	for i=1,#self.text do
		local meta = self.meta_by_idx[i]
		meta.col = col
		req.meta_array[#req.meta_array+1] = meta
		col = col + #self.text[i] + 1 -- plus one for the line end
	end

	return req
end

function M:on_lines(buf, nodes)
	for _, node in pairs(nodes) do
		local start_row, start_col, end_row, end_col = node:range()

		if start_row == end_row then
			self:add(buf, start_row, start_col, end_col)
		else
			for row = start_row, end_row - 1 do
				self:add(buf, row, start_col, 0)
				start_col = 0 -- only relevent for first line of comment
			end
			self:add(buf, end_row, 0, end_col)
		end
	end
end

function M.setup(shared)
	ns = shared.ns_placeholders
end

return M
