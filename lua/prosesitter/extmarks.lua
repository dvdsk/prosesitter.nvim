local api = vim.api
local log = require("prosesitter/log")

local M = {}
M.ns = nil



-- remove extmarks between line start and stop
function M.remove_line_extmarks(bufnr, start, stop)
  local es = api.nvim_buf_get_extmarks(bufnr, M.ns, {start,0}, {stop,-1}, {})
  for _, e in ipairs(es) do
    api.nvim_buf_del_extmark(bufnr, M.ns, e[1])
  end
end

function M.underline(bufnr, id, start_col, end_col, hl)
	local row, _ = api.nvim_buf_get_extmark_by_id(bufnr, M.ns, id, {details = true})

	local opt = {
		end_col = end_col,
		hl_group = hl,
		id = id,
	}
	local ok, _ = pcall(api.nvim_buf_set_extmark, bufnr, M.ns, row, start_col, opt)
	if not ok then
		log.error("Failed to add extmark, lnum="..vim.inspect(row).." pos="..start_col)
	end
end

return M
