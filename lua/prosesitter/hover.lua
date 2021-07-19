local log = require("prosesitter/log")
local api = vim.api

local shared = nil
M = {}

function M.add_meta(id, meta)
	shared.mark_to_hover[id] = meta
end

function M.setup(_shared)
	shared = _shared
end

-- open hover window if lint error on current pos else return
function M.popup()
	local row, col = unpack(api.nvim_win_get_cursor(0))
	local start = { row - 1, col } -- row needs to be zero indexed for get_extmarks
	local stop = { row - 1, 0 } -- search entire line, TODO handle multi line extmarks
	local es = api.nvim_buf_get_extmarks(0, shared.ns_marks, start, stop, { limit = 1 })
	if #es == 0 then
		return
	end

	local id = es[1][1]
	local text = shared.mark_to_hover[id]

	vim.lsp.util.open_floating_preview({text}, "markdown", {})
end

return M
