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
		log.info("bufnr: " .. bufnr)
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
