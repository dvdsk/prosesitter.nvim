local log = require("prosesitter/log")
local api = vim.api
local ns = nil

local M = {}
M.__index = M -- failed table lookups on the instances should fallback to the class table, to get methods
function M.new()
	local self = setmetatable({}, M)
	self.meta_by_mark = {}
	return self
end


function M:is_empty()
	log.error("not implemented")
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

function M:build()
	local text = {}
	local req = {}
	req.meta_array = {}

	local marks = sorted_marks()
	for _, line_id in ipairs(marks) do
		local line_txt = get_line(line_id)
		local line_meta = self.meta_by_mark[line_id]
		if line_meta == nil then
			text[#text+1] = line_txt
		end

		for _, meta in ipairs() do
			text[#text+1] = line_txt:sub(meta.start_col, meta.end_col)
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
			self.marks[#self.marks + 1] = api.nvim_buf_set_extmark(buf, ns, i, 0, {})
		end
	end
end

-- nodes should be arriving in order, therefore line_meta is correctly sorted
function M:note_hl(buf, row, start_col, end_col)
	local marks = api.nvim_buf_get_extmarks(buf, ns, { row, 0 }, { row, 0 }, {})
	local line_meta = self.meta_by_mark[marks[1]]
	line_meta[#line_meta+1] = { start_col = start_col, end_col = end_col }
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
