local api = vim.api
local log = require("prosesitter/log")
local M = {}

local function get_lines(buf, node)
	local start_row, start_col, end_row, end_col = node:range()
	local text = api.nvim_buf_get_lines(buf, start_row, end_row + 1, true)
	text[#text] = string.sub(text[#text], 1, end_col)
	text[1] = string.sub(text[1], start_col + 1)
	return text, start_row, start_col
end

-- matches urls domains and paths
local url_path_pattern = "%S+[./]+%S+"

-- how to get space handling in here....
-- must be able to handle multi line node text
-- want to preserve native line ends
local function default_fn(buf, node, req)
	local text, row, col = get_lines(buf, node)
	req:add_range(buf, text, row, col + 1)
end

local fn_by_ext = {
	tex = function(buf, node, req)
		local text, row, col = get_lines(buf, node)
		local i = 1
		while i <= #text do
			if i > 1 then -- ugly
				col = 1
			end

			local line = text[i]
			local start, stop = string.find(line, url_path_pattern)
			if start ~= nil then
				local before = string.sub(line, 1, start - 1)
				if #before > 0 then
					req:add(before, before, row - 1 + i, col)
				end
				local after = string.sub(line, stop + 1)
				if #after > 0 then
					text[i] = after
					i = i - 1
				end
			else
				req:add(buf, line, row - 1 + i, col + 1)
			end
			i = i + 1
		end
	end,
}

function M.get_fn(extension)
	if fn_by_ext[extension] ~= nil then
		return fn_by_ext[extension]
	else
		return default_fn
	end
end

return M
