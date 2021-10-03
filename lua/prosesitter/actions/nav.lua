local log = require("prosesitter/log")
local shared = require("prosesitter/shared")
local api = vim.api
M = {}

local function goto_mark(start, stop)
	log.info(shared.ns_marks)
	local es = api.nvim_buf_get_extmarks(0, shared.ns_marks, start, stop, { limit = 1 })
	if #es == 0 then
		return false
	end

	local mark_id = es[1][1]
	local mark_row = es[1][2]
	local mark_col = es[1][3]

	vim.api.nvim_win_set_cursor(0, { mark_row, mark_col })

	local text = shared.mark_to_meta:by_id(mark_id)
	vim.lsp.util.open_floating_preview({ text }, "markdown", {})
end

function M.next()
	local row, col = unpack(api.nvim_win_get_cursor(0))
	local start = { row - 1, col } -- row needs to be zero indexed for get_extmarks
	local stop = { -1, -1 } -- search till the end of the file
	goto_mark(start, stop)
end

function M.prev()
	local row, col = unpack(api.nvim_win_get_cursor(0))
	local start = { row - 1, col } -- row needs to be zero indexed for get_extmarks
	local stop = { 0, 0 } -- search till the end of the file
	goto_mark(start, stop)
end

return M
