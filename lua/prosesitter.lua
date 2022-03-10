local log = require("prosesitter/log")
local on_event = require("prosesitter/linter/on_event")
local state = require("prosesitter/state")
local config = require("prosesitter/config/mod")
local langtool = require("prosesitter/backend/langtool")
local issues = require("prosesitter/linter/issues")
local lintreq = require("prosesitter/linter/lintreq")
local prep = require("prosesitter/preprocessing/preprocessing")

local api = vim.api
local M = {}

M.next = require("prosesitter/actions/nav").next
M.prev = require("prosesitter/actions/nav").prev
M.popup = require("prosesitter/actions/hover").popup

function M.attach()
	local bufnr = api.nvim_get_current_buf()
	if state.buf[bufnr] ~= nil then
		return false, "buffer ("..bufnr..") already attached"
	end

	local filetype = vim.bo[bufnr].filetype
	local file_cfg = state.cfg.filetype[filetype]
	if file_cfg == nil then
		return false, "can not handle filetype: \""..filetype.."\""
	end

	if file_cfg.disabled ~= nil and file_cfg.disabled == true then
		return false, "handling filetype: \""..filetype.."\" files has been disabled"
	end

	local lint_targets = file_cfg.lint_targets
	local query = config.build_query(lint_targets, filetype)

	local prepfunc = prep.get_fn(filetype)
	state.buf[bufnr] = {
		langtool_ignore = file_cfg.langtool_ignore,
		lintreq = lintreq.new(),
		preprosessing = prepfunc,
		query = query,
	}

	state.issues:attach(bufnr)
	return on_event.attach(bufnr)
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
	state.buf = {}
end

function M.enable()
	vim.cmd("augroup prosesitter")
	vim.cmd("autocmd prosesitter BufEnter * lua require('prosesitter').attach()")
	return M.attach()
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

	if cfg.langtool_bin ~= false then
		langtool.start_server(on_event, cfg)
	end

	if cfg.default_cmds then
		config.add_cmds()
	end

	state.cfg = cfg
	state.issues = issues.IssueIndex
	if cfg.auto_enable then
		M.enable()
	end
end

return M
