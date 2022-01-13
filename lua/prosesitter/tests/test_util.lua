local on_event = require("prosesitter/linter/on_event")
local state = require("prosesitter/state")
local api = vim.api

local M = {}

M.setup = function()
	require("prosesitter"):setup({
		vale_bin = vim.loop.cwd() .. "/test_data/vale",
		vale_cfg = vim.loop.cwd() .. "/test_data/vale_cfg.ini",
		langtool_bin = vim.loop.cwd() .. "/test_data/languagetool/languagetool-server.jar",
		langtool_cfg = vim.loop.cwd() .. "/test_data/langtool.cfg",

		auto_enable = false,
		default_cmds = false,
	})
end

M.reset = function()
	-- disable and remove all extmarks
	for buf in state:attached() do
		api.nvim_buf_clear_namespace(buf, state.ns_placeholders, 0, -1)
		api.nvim_buf_clear_namespace(buf, state.ns_marks, 0, -1)
	end

	-- remove any buffer specific state
	state.buf = {}
end

return M
