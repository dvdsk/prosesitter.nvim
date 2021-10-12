local log = require("prosesitter/log")
local on_event = require("prosesitter/on_event/on_event")
local shared = require("prosesitter/shared")
local config = require("prosesitter/config/mod")
local langtool = require("prosesitter/backend/langtool")

local api = vim.api
local M = {}

M.next = require("prosesitter/actions/nav").next
M.prev = require("prosesitter/actions/nav").prev
M.popup = require("prosesitter/actions/hover").popup

function M.attach()
	local bufnr = api.nvim_get_current_buf()
	if shared.buf_query[bufnr] ~= nil then
		return
	end

	local extension = vim.fn.expand("%:e")
	if shared.cfg.disabled_ext[extension] ~= nil then
		return
	end

	local queries = shared.cfg.queries[extension]
	if queries == nil then
		return
	end

	local lint_target = shared.cfg.lint_target[extension]
	local query = queries[lint_target]

	shared.buf_query[bufnr] = query
	on_event.attach(bufnr)
end

function M.disable()
	-- make future events cause the event handler to stop
	on_event.disable()

	-- disable and remove all extmarks
	for buf, _ in ipairs(shared.buf_query) do
		api.nvim_buf_clear_namespace(buf, shared.ns_placeholders, 0, -1)
		api.nvim_buf_clear_namespace(buf, shared.ns_vale, 0, -1)
		api.nvim_buf_clear_namespace(buf, shared.ns_langtool, 0, -1)
	end

	vim.cmd("autocmd! prosesitter") -- remove autocmd
	shared.buf_query = {}
end

function M.enable()
	vim.cmd("autocmd prosesitter BufEnter * lua require('prosesitter').attach()")
	M.attach()
end

function M.switch_vale_cfg(path)
	shared.cfg.vale_cfg = path

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
		langtool.start_server(on_event, cfg.langtool_bin)
	end

	if cfg.default_cmds then
		config.add_cmds()
	end

	shared.cfg = cfg
	on_event.setup(shared)
	if cfg.auto_enable then
		vim.cmd("augroup prosesitter")
		vim.cmd("autocmd prosesitter BufEnter * lua require('prosesitter').attach()")
	end

end

return M
