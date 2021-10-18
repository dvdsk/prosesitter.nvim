local log = require("prosesitter/log")
local on_event = require("prosesitter/linter/on_event")
local state = require("prosesitter/state")
local config = require("prosesitter/config/mod")
local langtool = require("prosesitter/backend/langtool")
local issues = require("prosesitter/linter/issues")

local api = vim.api
local M = {}

M.next = require("prosesitter/actions/nav").next
M.prev = require("prosesitter/actions/nav").prev
M.popup = require("prosesitter/actions/hover").popup

function M.attach()
	local bufnr = api.nvim_get_current_buf()
	if state.buf_query[bufnr] ~= nil then
		return
	end

	local extension = vim.fn.expand("%:e")
	if state.cfg.disabled_ext[extension] ~= nil then
		return
	end

	local queries = state.cfg.queries[extension]
	if queries == nil then
		return
	end

	local lint_target = state.cfg.lint_target[extension]
	local query = queries[lint_target]

	state.buf_query[bufnr] = query
	state.issues:attach(bufnr)
	on_event.attach(bufnr)
end

function M.disable()
	-- make future events cause the event handler to stop
	on_event.disable()

	-- disable and remove all extmarks
	for buf in state:attached() do
		api.nvim_buf_clear_namespace(buf, state.ns_placeholders, 0, -1)
		api.nvim_buf_clear_namespace(buf, state.ns_marks, 0, -1)
	end

	vim.cmd("autocmd! prosesitter") -- remove autocmd
	state.buf_query = {}
end

function M.enable()
	vim.cmd("autocmd prosesitter BufEnter * lua require('prosesitter').attach()")
	M.attach()
end

function M.switch_vale_cfg(path)
	state.cfg.vale_cfg = path

	M.disable()
	M.enable()
end

function M:setup(user_cfg)
	local cfg = config:setup(user_cfg)
	if cfg == nil then
		print("setup unsuccesful; exiting")
		return
	end

	if cfg.langtool_bin ~= nil then
		langtool.start_server(on_event, cfg)
	end

	if cfg.default_cmds then
		config.add_cmds()
	end

	state.cfg = cfg
	state.issues = issues.Issues
	on_event.setup(state)
	if cfg.auto_enable then
		vim.cmd("augroup prosesitter")
		vim.cmd("autocmd prosesitter BufEnter * lua require('prosesitter').attach()")
	end
end

return M
