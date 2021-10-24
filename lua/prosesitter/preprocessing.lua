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

local function add_if_not_pattern(req, pattern, buf, text, row, col)
	for n, line in ipairs(text) do
		while true do
			local start, stop = string.find(line, pattern)
			if start ~= nil then
				if start > 1 then
					local before = string.sub(line, 1, start - 1)
					req:add(buf, before, row - 1 + n, col)
				end
				if stop < #line then
					line = string.sub(line, stop + 1)
				else
					break
				end
			else
				req:add(buf, line, row - 1 + n, col + 1)
				break
			end
		end
		col = 0
	end
end

local function is_latex_math(node)
	local parent = node:parent()
	return parent:type() == "inline_formula"
end

local fn_by_ext = {
	tex = function(buf, node, req)
		if is_latex_math(node) then
			return
		end

		local text, row, col = get_lines(buf, node)
		add_if_not_pattern(req, url_path_pattern, buf, text, row, col)
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
