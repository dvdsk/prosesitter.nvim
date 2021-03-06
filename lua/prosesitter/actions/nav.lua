local log = require("prosesitter/log")
local state = require("prosesitter/state")
local marks = require("prosesitter/linter/marks/marks")
local menu = require("prosesitter/actions/hover_menu")

local api = vim.api
M = {}

local function goto_mark(start, stop)
	local mark = marks.get_closest(start, stop)
	if mark == nil then
		return false
	end

	local row = mark[2]
	local col = mark[3]
	vim.api.nvim_win_set_cursor(0, { row+1, col })

	local id = mark[1]
	local issues = state.issues:for_id(id)
	local cb = function()
		menu:popup(issues)
	end
	vim.schedule(cb)
end

function M.next()
	local row, col = unpack(api.nvim_win_get_cursor(0))
	local start = { row - 1, col + 1 } -- row needs to be zero indexed for get_extmarks
	local stop = { -1, -1 } -- search till the end of the file
	return goto_mark(start, stop)
end

function M.prev()
	local row, col = unpack(api.nvim_win_get_cursor(0))
	local start = { row - 1, col - 1} -- row needs to be zero indexed for get_extmarks
	local stop = { 0, 0 } -- search till the start of the file
	return goto_mark(start, stop)
end

return M
