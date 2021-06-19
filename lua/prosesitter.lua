
-- notes
--
-- schedule_wrap
-- 
--
--

local log = require("prosesitter/log")
local shared = require("prosesitter/shared")
local underline = require("prosesitter/underline")
local hover = require("prosesitter/hover")
local api = vim.api

local M = {}

function M.test()
	-- local prose = "When usng the `write-good` style, this sentence will generate a warning by default "
	-- 	.. "(extremely is a weasel word!). However, if we format `extremely` as inline code, "
	-- 	.. "we will no longer receive a warning:"
	-- for p_start, p_end, hl in shared.hl_iter(prose) do
	-- 	print("start col: " .. p_start .. ", end col: " .. p_end .. ", highlight: " .. hl)
	-- end
	underline.test()
end

function M.setup()
	local ns = shared:setup()
	underline.ns = ns

	api.nvim_set_decoration_provider(ns, {
		on_win = underline.on_win,
		on_line = underline.on_line,
	})
	local opt = { noremap = true, silent = true, nowait = true }
	local cmd = "<Cmd>lua _G.ProseCheck:test()<CR>"
	vim.api.nvim_set_keymap("n", ",", cmd, opt)
end

_G.ProseCheck = M
return M
