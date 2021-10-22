local api = vim.api
local log = require("prosesitter/log")
local M = {}

-- how to get space handling in here....
-- must be able to handle multi line node text
-- want to preserve native line ends
local function default_fn(buf, node, req)
	local start_row, start_col, end_row, end_col = node:range()
	local text = api.nvim_buf_get_lines(buf, start_row, end_row+1, true)
	text[#text] = string.sub(text[#text], 1, end_col)
	text[1] = string.sub(text[1], start_col+1)

	-- Space to do something with text

	-- can call this multiple times
	req:add_range(buf, text, start_row, start_col + 1)
end

local fn_by_ext = {}
function M.get_fn(extension)
	if fn_by_ext[extension] ~= nil then
		return fn_by_ext[extension]
	else
		return default_fn
	end
end

return M
