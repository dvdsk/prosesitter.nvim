local log = require("prosesitter/log")
local shared = require("prosesitter/shared")
local on_event = require("prosesitter/on_event/on_event")
local api = vim.api

local M = {}
M.hover = require("prosesitter/hover") -- exposed for keybindings

local attached = {}
local function on_win(_, _, bufnr)
	if not attached[bufnr] then
		attached[bufnr] = true
		on_event.on_win(nil, nil, bufnr)
	end
end

function M:setup()
	shared:setup()
	on_event.setup(shared)
	self.hover.setup(shared)

	api.nvim_set_decoration_provider(shared.ns_placeholders, {
		on_win = on_win,
	})
end

_G.ProseSitter = M
return M
