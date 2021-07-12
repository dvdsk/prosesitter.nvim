local api = vim.api
local log = require("prosesitter/log")

local M = {}
M.placeholder_ns = nil
M.ns = nil

-- remove extmarks between line start and stop
function M.remove_line_extmarks(bufnr, start, stop)
	-- remove permanent extmarks
	local es = api.nvim_buf_get_extmarks(bufnr, M.ns, {start,0}, {stop,-1}, {})
	for _, e in ipairs(es) do
	api.nvim_buf_del_extmark(bufnr, M.ns, e[1])
	end
	-- remove placeholder marks (max one per line)
	local placeholders = api.nvim_buf_get_extmarks(bufnr, M.placeholder_ns, {start,0}, {stop,-1}, {})
	api.nvim_buf_del_extmark(bufnr, M.placeholder_ns, placeholders[1][1])

end

function M.underline(bufnr, id, start_col, end_col, hl)
	local mark = api.nvim_buf_get_extmark_by_id(bufnr, M.placeholder_ns, id, {details = false})
	-- TODO cleanup placeholders
	local row = mark[1]

	local opt = {
		end_col = end_col,
		hl_group = hl,
	}
	local ok, _ = pcall(api.nvim_buf_set_extmark, bufnr, M.ns, row, start_col-1, opt)
	if not ok then
		log.error("Failed to add extmark, lnum="..vim.inspect(row).." pos="..start_col)
	end
end

return M
