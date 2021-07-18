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

local org_cursor = nil
local function hide_cursor()
	org_cursor = vim.opt.guicursor
	vim.cmd('hi Cursor blend=100')
	vim.opt.guicursor = {'a:Cursor/lCursor'}
end

local function restore_cursor()
	vim.opt.guicursor = org_cursor
end

local function map_keys(buf)
	local opt = { nowait = true, noremap = true, silent = true }
	local cmd = ":lua _G.ProseSitter.hover:close_popup()<CR>"
	local chars = "abcdefghijklmnopqrstuvwxyz"
	for i=1,#chars do
		local key = chars:sub(i, i)
		api.nvim_buf_set_keymap(buf, 'n', key, cmd, opt)
		api.nvim_buf_set_keymap(buf, 'n', key:upper(), cmd, opt)
	end

	local special_keys = {'<Right>','<Left>','<Up>','<Down>','<leader>', 'Esc'}
	for _, key in ipairs(special_keys) do
		api.nvim_buf_set_keymap(buf, 'n', key, cmd, opt)
	end
end

local win = nil
function M.close_popup()
	api.nvim_win_close(win, true)
	win = false
	restore_cursor()
end

-- open hover window if lint error on current pos
-- else return false
function M.popup()
	local row, col = unpack(api.nvim_win_get_cursor(0))
	local start = { row - 1, col } -- row needs to be zero indexed for get_extmarks
	local stop = { row - 1, 0 } -- search entire line, TODO handle multi line extmarks
	local es = api.nvim_buf_get_extmarks(0, shared.ns_marks, start, stop, { limit = 1 })
	if #es == 0 then return end

	local id = es[1][1]
	local text = shared.mark_to_hover[id]

	local buf = api.nvim_create_buf(false, true)
	api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	api.nvim_buf_set_option(buf, "filetype", "whid")
	api.nvim_buf_set_lines(buf, 0, -1, false, { text })
	api.nvim_buf_set_option(buf, "modifiable", false)
	hide_cursor()
	-- https://dev.to/2nit/how-to-write-neovim-plugins-in-lua-5cca

	local opt = {
		style = "minimal",
		relative = "cursor",
		width = math.min(40, #text),
		height = 2,
		row = 1,
		col = 0,
	}

	win = api.nvim_open_win(buf, true, opt)
	map_keys() -- make any key close the window
end

return M
