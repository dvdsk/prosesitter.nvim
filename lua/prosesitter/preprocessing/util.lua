local M = {}
local api = vim.api

-- start_row and end_row zero based
local function get_lines(buf, start_row, start_col, end_row, end_col )
	local text = api.nvim_buf_get_lines(buf, start_row, end_row+1, false)
	text[#text] = string.sub(text[#text], 1, end_col)
	text[1] = string.sub(text[1], start_col + 1)
	return text
end

-- matches urls domains and paths
M.url_path_pattern = "%S+[./]+%S+"

-- column is zero based
function M.add_if_not_pattern(req, pattern, buf, line, row, col)
	while true do
		local start, stop = string.find(line, pattern)
		if start ~= nil then
			if start > 1 then
				local before = string.sub(line, 1, start - 1) -- TODO remove and replace col + #before
				req:add(buf, row, col, col + #before)
			end
			if stop < #line then
				line = string.sub(line, stop + 1)
				col = col + stop
			else
				break
			end
		else
			req:add(buf, row, col, col + #line)
			break
		end
	end
end

-- returns range, end exclusive. A newline means the range is up to the start
-- of the next line at column 0
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
	local start_row, start_col, end_row, end_col = M.range(node, meta)
	local text = get_lines(buf, start_row, start_col, end_row, end_col)
	local col = start_col
	for n, line in ipairs(text) do
		local row = start_row + n -1
		M.add_if_not_pattern(req, M.url_path_pattern, buf, line, row, col)
		req:add_append_text(buf, row, " ")
		col = 0
	end
end

return M
