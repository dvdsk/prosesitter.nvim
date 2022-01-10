-- used to share state between other modules
local log = require("prosesitter/log")

local M = {}
M.langtool_running = false
M.buf = {}

M.lintreq = {}

function M:attached()
	local buf = nil
	local iter = function()
		buf = next(self.buf, buf)
		if buf ~= nil then
			return buf
		else
			return nil
		end
	end
	return iter, buf
end

function M:list_attached()
	local list = {}
	for buf, _ in pairs(self.buf) do
		list[#list+1] = buf
	end
	return list
end

M.cfg = "should be set in prosesitter.setup"
M.issues = "should be set in prosesitter.setup"

M.ns_marks = vim.api.nvim_create_namespace("prosesitter_highlights")
M.ns_placeholders = vim.api.nvim_create_namespace("prosesitter_placeholders")

return M
