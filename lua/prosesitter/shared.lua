-- used to share state between other modules
local log = require("prosesitter/log")

local M = {}
M.langtool_running = false
M.buf_query = {}

M.cfg = "should be set in prosesitter.setup"
M.issues = "should be set in prosesitter.setup"

M.ns_marks = vim.api.nvim_create_namespace("prosesitter_highlights")
M.ns_placeholders = vim.api.nvim_create_namespace("prosesitter_placeholders")

return M
