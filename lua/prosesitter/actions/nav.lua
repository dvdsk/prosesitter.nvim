local log = require("prosesitter/log")
local shared = require("prosesitter/shared")
local marks = require("prosesitter/on_event/marks/marks")

local api = vim.api
M = {}

local function format(issues)
	return { "todo" }
end

local function goto_mark(start, stop)
	local mark = marks.get_closest_mark(start, stop)
	if mark == nil then
		return false
	end

	log.info(vim.inspect(mark))
	local id = mark[1][1]
	local row = mark[1][2]
	local col = mark[1][3]

	vim.api.nvim_win_set_cursor(0, { row+1, col })

	local issues = shared.issues:by_id(id)
	local cb = function()
		vim.lsp.util.open_floating_preview(format(issues), "markdown", {})
	end
	vim.schedule(cb)
end

function M.next()
	local row, col = unpack(api.nvim_win_get_cursor(0))
	local start = { row - 1, col + 1 } -- row needs to be zero indexed for get_extmarks
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
