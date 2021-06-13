-- local on_line = require("prosesitter/underline").on_line

local shared = require("functions/prosesitter/shared")
local underline = require("functions/prosesitter/underline")
local hover = require("functions/prosesitter/hover")
local api = vim.api

local M = {}

function M.test()
	local prose = "When using the `write-good` style, this sentence will generate a warning by default "
		.. "(extremely is a weasel word!). However, if we format `extremely` as inline code, "
		.. "we will no longer receive a warning:"
	for p_start, p_end in shared.prose_check_iter(prose) do
		print("start col: " .. p_start .. ", end col: " .. p_end)
	end
end

function M.setup()
	shared:setup()

	api.nvim_set_decoration_provider(shared.ns, {
		on_win = M.on_win,
		-- on_line = M.on_line,
	})
	local opt = { noremap = true, silent = true, nowait = true }
	local cmd = "<Cmd>lua _G.ProseCheck:test()<CR>"
	vim.api.nvim_set_keymap("n", ",", cmd, opt)
end

_G.ProseCheck = M
return M
