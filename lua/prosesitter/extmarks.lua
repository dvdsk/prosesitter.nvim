local api = vim.api
local log = require("prosesitter/log")

local M = {}
M.ns = nil

-- remove extmarks between line start and stop
function M.remove_line_extmarks(bufnr, start, stop)
  local es = api.nvim_buf_get_extmarks(bufnr, ns, {start,0}, {stop,-1}, {})
  for _, e in ipairs(es) do
    api.nvim_buf_del_extmark(bufnr, ns, e[1])
  end
end

function M.add_extmark(bufnr, lnum, start_col, end_col, hl)
	-- TODO: This errors because of an out of bounds column when inserting
	-- newlines. Wrapping in pcall hides the issue.

	local opt = {
		end_line = lnum,
		end_col = end_col,
		hl_group = hl,
		-- ephemeral = true, -- only keep for one draw
	}
	local ok, _ = pcall(api.nvim_buf_set_extmark, bufnr, M.ns, lnum, start_col, opt)
	if not ok then
		log.error("Failed to add extmark, lnum="..vim.inspect(lnum).." pos="..start_col)
	end
end

return M
