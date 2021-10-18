-- used to share state between other modules
local log = require("prosesitter/log")

local M = {}
M.langtool_running = false
M.buf_query = {}
M.parsers = {} -- table of parsers keyed by bufnr

function M:attached_bufs()
	local function attached_it(t, buf)
		buf = buf+1
		local v = self.parsers[buf]
		if v ~= nil then
			return buf
		else 
			return nil
		end
	end
	return attached_it
end

M.cfg = "should be set in prosesitter.setup"
M.issues = "should be set in prosesitter.setup"

M.ns_marks = vim.api.nvim_create_namespace("prosesitter_highlights")
M.ns_placeholders = vim.api.nvim_create_namespace("prosesitter_placeholders")

return M
