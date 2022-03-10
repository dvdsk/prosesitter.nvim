local api = vim.api
local log = require("prosesitter/log")
local util = require("prosesitter.preprocessing.util")

local M = {}

local fn_by_ftype = {
	tex = function(buf, node, meta, req)
		if node:parent():type() == "inline_formula" then
			return
		end
		util.default_fn(buf, node, meta, req)
	end,
	markdown = require("lua.prosesitter.preprocessing.markdown")
}

function M.get_fn(filetype)
	if fn_by_ftype[filetype] ~= nil then
		return fn_by_ftype[filetype]
	else
		return util.default_fn
	end
end

return M
