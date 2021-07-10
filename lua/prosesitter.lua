local log = require("prosesitter/log")
local shared = require("prosesitter/shared")
local underline = require("prosesitter/underline")
-- local hover = require("prosesitter/hover") -- TODO add hover support
local api = vim.api

local M = {}

local attached = {}
local function on_win(_, _, bufnr)
	if not attached[bufnr] then
		attached[bufnr] = true
		underline.on_win(nil, nil, bufnr)

		local info = vim.fn.getbufinfo(bufnr)
		local last_line = info[1].linecount
		underline.on_lines(nil, bufnr, nil, 0, last_line, last_line, 9999, nil, nil)
	end
end

function M.setup()
	-- local ns = shared:setup()
	local ns = shared:setup()
	underline.setup(ns)
	underline.ns = ns

	api.nvim_set_decoration_provider(ns, {
		on_win = on_win,
	})
	local opt = { noremap = true, silent = true, nowait = true }
	local cmd = "<Cmd>lua _G.ProseCheck:test()<CR>"
	vim.api.nvim_set_keymap("n", ",", cmd, opt)
end

_G.ProseCheck = M
return M
