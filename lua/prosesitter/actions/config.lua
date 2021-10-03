local on_event = require("prosesitter/on_event/on_event")
local shared = require("prosesitter/shared")
local api = vim.api

local M = {}

local buf_cfg = shared.cfg.by_buf
function M.disable()
	-- make future events cause the event handler to stop
	on_event.disable()

	-- disable and remove all extmarks
	for buf, _ in ipairs(buf_cfg) do
		api.nvim_buf_clear_namespace(buf, shared.ns_placeholders, 0, -1)
		api.nvim_buf_clear_namespace(buf, shared.ns_marks, 0, -1)
	end

	vim.cmd("autocmd! prosesitter") -- remove autocmd
	buf_cfg = {}
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

return M
