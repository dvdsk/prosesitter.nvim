local log = require("prosesitter/log")
local shared = require("prosesitter/shared")
local on_event = require("prosesitter/on_event/on_event")
local api = vim.api
local disabled = false -- weather the plugin has been disabled

local M = {}
M.hover = require("prosesitter/hover") -- exposed for keybindings

local attached = {}
local function on_win(_, _, bufnr)
	if disabled then return true end  -- stop calling on lines if the plugin was just disabled

	if not attached[bufnr] then
		attached[bufnr] = true
		on_event.on_win(nil, nil, bufnr)
	end
end

function M:setup()
	shared:setup()
	on_event.setup(shared)
	self.hover.setup(shared)

	-- TODO replace with https://neovim.io/doc/user/api.html nvim_subscribe
	api.nvim_set_decoration_provider(shared.ns_placeholders, {
		on_win = on_win,
	})
end

function M.disable()
	-- make future events cause the event handler to stop
	disabled = true
	on_event.disable()

	-- disable and remove all extmarks
	for buf, _ in ipairs(attached) do
		api.nvim_buf_clear_namespace(buf, shared.ns_placeholders, 0, -1)
		api.nvim_buf_clear_namespace(buf, shared.ns_marks, 0, -1)
	end
	attached = {}
end

function M.enable()
	disabled = false
	on_event.enable()

	api.nvim_set_decoration_provider(shared.ns_placeholders, {
		on_win = on_win,
	})
end

local es = nil
function M.test1()
	local start = 3
	local stop = 3
	es = api.nvim_buf_get_extmarks(0, shared.ns_marks, {start,0}, {stop,-1}, {})
	log.info(vim.inspect(es))
end

function M.test2()
	for _, e in ipairs(es) do
		local m = api.nvim_buf_get_extmark_by_id(0, shared.ns_marks, e[1], {})
		log.info(vim.inspect(m))
	end
end

_G.ProseSitter = M
return M
