-- local on_event = require("prosesitter/linter/on_event")
local state = require("prosesitter/state")
local langtool = require("prosesitter/backend/langtool")
local Path = require("plenary.path")
local util = require("prosesitter/util")

local M = {}

M.setup = function()
	require("prosesitter"):setup({
		vale_bin = vim.loop.cwd() .. "/test_data/vale",
		vale_cfg = vim.loop.cwd() .. "/test_data/vale_cfg.ini",
		langtool_bin = false, -- started manually before tests are called
		langtool_cfg = vim.loop.cwd() .. "/test_data/langtool.cfg",

		auto_enable = false,
		default_cmds = false,
		timeout = 0,

		filetype = {
			python = {
				lint_targets = { "comments", "docstrings", "strings" },
			},
			rust = {
				lint_targets = { "comments", "strings" },
			},
		},
	})

	state.langtool_running = true
	langtool.url = "http://localhost:34287/v2/check"
end

-- only call after deleting buffer
M.reset = function()
	-- remove any buffer specific state
	state.buf = {}
end

function M.read_file(file)
	return Path:new("lua", "prosesitter", "tests", file):read()
end

function M.lines(file)
	local text = M.read_file(file)
	return util.split_string(text, "\n")
end

return M
