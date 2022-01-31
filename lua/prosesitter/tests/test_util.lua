-- local on_event = require("prosesitter/linter/on_event")
local state = require("prosesitter/state")
local langtool = require("prosesitter/backend/langtool")

local M = {}

M.setup = function()
	require("prosesitter"):setup({
		vale_bin = vim.loop.cwd() .. "/test_data/vale",
		vale_cfg = vim.loop.cwd() .. "/test_data/vale_cfg.ini",
		langtool_bin = false, -- started manually before tests are called
		langtool_cfg = vim.loop.cwd() .. "/test_data/langtool.cfg",

		auto_enable = false,
		default_cmds = false,
	})

	state.langtool_running = true;
	langtool.url = "http://localhost:34287/v2/check"
end

-- only call after deleting buffer
M.reset = function()
	-- remove any buffer specific state
	state.buf = {}
end

return M
