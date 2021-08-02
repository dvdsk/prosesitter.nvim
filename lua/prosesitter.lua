local log = require("prosesitter/log")
local shared = require("prosesitter/shared")
local on_event = require("prosesitter/on_event/on_event")
local api = vim.api
local buf_cfg = shared.cfg.by_buf

local M = {}
M.hover = require("prosesitter/hover") -- exposed for keybindings

local denylist_req = nil  -- get value during setup
local allowlist_req = nil
function M.attach()
	local bufnr = api.nvim_get_current_buf()
	if buf_cfg[bufnr] == nil then
		local extension = vim.fn.expand('%:e')
		local cfg = shared.cfg.by_ext[extension]
		if cfg == nil then
			cfg = shared.cfg.default
		end

		if cfg.mode == "allow" then
			cfg.lint_req = allowlist_req
		elseif cfg.mode == "deny" then
			cfg.lint_req = denylist_req
		else
			print("need to specify wheather mode is 'allow' or 'deny'")
		end

		buf_cfg[bufnr] = cfg
		on_event.on_win(bufnr)
	end
end

function M:setup()
	shared:setup()
	on_event.setup(shared)
	allowlist_req = on_event.get_allowlist_req()
	denylist_req = on_event.get_denylist_req()
	self.hover.setup(shared)
	vim.cmd("augroup prosesitter")
	vim.cmd("autocmd prosesitter BufEnter * lua _G.ProseSitter.attach()")
end

function M.disable()
	-- make future events cause the event handler to stop
	on_event.disable()

	-- disable and remove all extmarks
	for buf, _ in ipairs(buf_cfg) do
		api.nvim_buf_clear_namespace(buf, shared.ns_placeholders, 0, -1)
		api.nvim_buf_clear_namespace(buf, shared.ns_marks, 0, -1)
	end

	vim.cmd('autocmd! prosesitter') -- remove autocmd
	buf_cfg = {}
end

function M.enable()
	vim.cmd("autocmd prosesitter BufEnter * lua _G.ProseSitter.attach()")
	M.attach()
end

local es = nil
function M.test1()
	local start = 3
	local stop = 3
	es = api.nvim_buf_get_extmarks(0, shared.ns_marks, { start, 0 }, { stop, -1 }, {})
	log.info(vim.inspect(es))
end

function M.test2()
	for _, e in ipairs(es) do
		local m = api.nvim_buf_get_extmark_by_id(0, shared.ns_marks, e[1], {})
		log.info(vim.inspect(m))
	end
end

function M.showhl()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	row = row -1
	col = col -1
	local parser = vim.treesitter.get_parser(0)
	local lang = parser:lang()

	local query = require("vim.treesitter.query")
	local hl = query.get_query(lang, "highlights")
	local hl_group = nil

	parser:for_each_tree(function(tstree, _)
		local root = tstree:root()
		for id, node in hl:iter_captures(root, 0) do
			local start_row, start_col, end_row, end_col = node:range()
			if start_row > row or end_row < row then goto continue end
			if start_col > col or end_col < col then goto continue end
			log.info(hl_group)
			hl_group = hl.captures[id]
			::continue::
		end
	end)

	if hl_group ~= nil then
		print("cursor now on treesitter highlight: '"..hl_group.."'")
	else
		print("no highlight group under cursor")
	end
end

_G.ProseSitter = M
return M
