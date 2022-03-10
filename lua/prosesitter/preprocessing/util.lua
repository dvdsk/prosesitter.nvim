local M = {}
local api = vim.api

local function get_lines(buf, start_row, start_col, end_row, end_col )
	local text = api.nvim_buf_get_lines(buf, start_row, end_row + 1, true)
	text[#text] = string.sub(text[#text], 1, end_col)
	text[1] = string.sub(text[1], start_col + 1)
	return text, start_row, start_col
end

-- matches urls domains and paths
M.url_path_pattern = "%S+[./]+%S+"

function M.add_if_not_pattern(req, pattern, buf, text, row, col)
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
					col = col + stop
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

function M.range(node, meta)
	if meta.content ~= nil then
		return unpack(meta.content[1])
	else
		return node:range()
	end
end

-- how to get space handling in here....
-- must be able to handle multi line node text
-- want to preserve native line ends
function M.default_fn(buf, node, meta, req)
	local text, row, col = get_lines(buf, M.range(node, meta))
	M.add_if_not_pattern(req, url_path_pattern, buf, text, row, col)
end

return M
