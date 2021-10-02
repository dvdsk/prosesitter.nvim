local log = require("prosesitter/log")
local on_event = require("prosesitter/on_event/on_event")
local api = vim.api

local M = {}
M.shared = require("prosesitter/shared")

local buf_cfg = M.shared.cfg.by_buf
function M.attach()
	local bufnr = api.nvim_get_current_buf()
	if buf_cfg[bufnr] == nil then
		local extension = vim.fn.expand("%:e")
		local cfg = M.shared.cfg.by_ext[extension]
		if cfg == nil then
			return
		end

		buf_cfg[bufnr] = cfg
		on_event.attach(bufnr)
	end
end

function M:setup(user_cfg)
	local ok = self.shared:setup(user_cfg)
	if not ok then
		print("setup unsuccesful; exiting")
		return
	end

	on_event.setup(self.shared)
	vim.cmd("augroup prosesitter")
	vim.cmd("autocmd prosesitter BufEnter * lua require('prosesitter').attach()")
end

function M.disable()
	-- make future events cause the event handler to stop
	on_event.disable()

	-- disable and remove all extmarks
	for buf, _ in ipairs(buf_cfg) do
		api.nvim_buf_clear_namespace(buf, M.shared.ns_placeholders, 0, -1)
		api.nvim_buf_clear_namespace(buf, M.shared.ns_marks, 0, -1)
	end

	vim.cmd("autocmd! prosesitter") -- remove autocmd
	buf_cfg = {}
end

function M.enable()
	vim.cmd("autocmd prosesitter BufEnter * lua _G.ProseSitter.attach()")
	M.attach()
end

function M.switch_vale_cfg(path)
	M.shared.cfg.vale_cfg = path

	M.disable()
	M.enable()
end

return M
