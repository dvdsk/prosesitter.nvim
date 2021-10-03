local log = require("prosesitter/log")
local on_event = require("prosesitter/on_event/on_event")
local shared = require("prosesitter/shared")

local api = vim.api
local M = {}

M.next = require("prosesitter/actions/nav").next
M.prev = require("prosesitter/actions/nav").prev
M.popup = require("prosesitter/actions/hover").popup
M.enable = require("prosesitter/actions/config").enable
M.disable = require("prosesitter/actions/config").disable
M.switch_vale_cfg = require("prosesitter/actions/config").switch_vale_cfg

local buf_cfg = shared.cfg.by_buf
function M.attach()
	local bufnr = api.nvim_get_current_buf()
	if buf_cfg[bufnr] == nil then
		local extension = vim.fn.expand("%:e")
		local cfg = shared.cfg.by_ext[extension]
		if cfg == nil then
			return
		end

		buf_cfg[bufnr] = cfg
		on_event.attach(bufnr)
	end
end

function M:setup(user_cfg)
	local ok = shared:setup(user_cfg)
	if not ok then
		print("setup unsuccesful; exiting")
		return
	end

	on_event.setup(self.shared)
	vim.cmd("augroup prosesitter")
	vim.cmd("autocmd prosesitter BufEnter * lua require('prosesitter').attach()")
end


return M
