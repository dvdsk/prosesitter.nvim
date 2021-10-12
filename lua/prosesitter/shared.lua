local log = require("prosesitter/log")

local M = {}
M.langtool_running = false
M.buf_query = {}
M.cfg = "should be set in prosesitter.setup"

MarkToMeta = { m = {} }
function MarkToMeta:add(id, meta)
	local buf = vim.api.nvim_get_current_buf()
	if self.m[buf] == nil then
		self.m[buf] = {}
	end
	self.m[buf][id] = meta
end

function MarkToMeta:by_id(id)
	local buf = vim.api.nvim_get_current_buf()
	return self.m[buf][id]
end

function MarkToMeta:by_buf_id(buf, id)
	return self.m[buf][id]
end

function MarkToMeta:buffers()
	local list = {}
	for buf, _ in pairs(self.m) do
		list[#list + 1] = buf
	end
	return list
end

M.mark_to_meta = MarkToMeta

M.ns_vale = vim.api.nvim_create_namespace("prosesitter_vale")
M.ns_langtool = vim.api.nvim_create_namespace("prosesitter_langtool")
M.ns_placeholders = vim.api.nvim_create_namespace("prosesitter_placeholders")

return M
