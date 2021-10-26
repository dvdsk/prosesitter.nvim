local log = require("prosesitter/log")
local util = require("prosesitter/util")
local state = require("prosesitter/state")
local api = vim.api
local ns = state.ns_placeholders

local M = {}
M.__index = M -- failed table lookups on the instances should fallback to the class table, to get methods
function M.new()
	local self = setmetatable({}, M)
	-- an array
	self.text = {}
	-- key: placeholder_id,
	-- value: arrays of tables of buf, id(same as key), row_col, idx
	self.meta_by_mark = {}
	-- key: index of corrosponding text in self.text (idx)
	-- value: table of buf, id, row_col, idx(same as key)
	self.meta_by_idx = {}
	return self
end

-- text can be empty list
-- needs to be passed 1 based start_col
function M:add_range(buf, lines, start_row, start_col)
	for i, text in ipairs(lines) do
		local row = start_row - 1 + i
		self:add(buf, text, row, start_col)
		start_col = 1
	end
end

function M:append(buf, id, text, start_col)
	-- if start col matches meta_list[1] then clear?
	local meta_list = self.meta_by_mark[id]
	local meta = {
		buf = buf,
		id = id,
		row_col = start_col,
		idx = #self.text + 1,
	}
	meta_list[#meta_list + 1] = meta
	self.meta_by_idx[#self.text + 1] = meta
	self.text[#self.text + 1] = text
end

function M:add(buf, text, row, start_col)
	local id = nil
	local marks = api.nvim_buf_get_extmarks(buf, ns, { row, 0 }, { row, 0 }, {})
	assert(#marks < 2, "there should never be more then one placeholder on a line")
	if #marks > 0 then
		id = marks[1][1] -- there can be a max of 1 placeholder per line
		if self.meta_by_mark[id] ~= nil then
			self:append(buf, id, text, start_col)
			return
		end
	else
		id = api.nvim_buf_set_extmark(buf, ns, row, 0, { end_col = 0 })
	end

	local meta = { buf = buf, id = id, row_col = start_col, idx = #self.text + 1 }
	self.meta_by_mark[id] = { meta }
	self.meta_by_idx[#self.text + 1] = meta
	self.text[#self.text + 1] = text
end

local function delete_by_idx(deleted_meta, array, map)
	for i = #deleted_meta, 1, -1 do
		local idx = deleted_meta[i].idx
		table.remove(array, idx)
		table.remove(map, idx)
	end
end

function M:clear_lines(buf, start, stop)
	local marks = api.nvim_buf_get_extmarks(buf, ns, { start, 0 }, { stop, 0 }, {})
	for _, mark in ipairs(marks) do
		local id = mark[1]
		local deleted = self.meta_by_mark[id]
		if deleted ~= nil then
			self.meta_by_mark[id] = {}
			delete_by_idx(deleted, self.text, self.meta_by_idx)
		end
	end
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

	self:reset()
	return req
end

function M:reset()
	self.text = {}
	self.meta_by_mark = {}
	self.meta_by_idx = {}
end

return M
