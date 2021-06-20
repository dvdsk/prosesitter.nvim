
-- notes
--
-- schedule_wrap
-- 
--
--

local log = require("prosesitter/log")
local shared = require("prosesitter/shared")
local underline = require("prosesitter/underline")
local hover = require("prosesitter/hover")
local api = vim.api

local M = {}

-- TODO on buf load parse trough all comments and add extmarks

local function on_lines(lines, buf, ct, first_l, last_l, llu, bc, dc, du)
	local line_removed = first_l < last_l
	if line_removed then -- TODO multiple lines removed
		log.info("lines removed from: "..last_l.." to: "..first_l)
		-- marks:update_lnums_added(last_l)
		-- return
	end

	-- local line_added = todo!
	-- if line_added then --- TODO multiple lines added
	-- 	-- marks:update_lnums_removed()


	     -- update lnum to extmark_id to account for line number changes
	-- else
	-- 		parse line for comments
	-- 		scheduale check if comments found
	-- 			check needs to remove any existing ext marks before adding new ones
	-- 			(use https://github.com/mfussenegger/nvim-dap/blob/
	-- 			 5ca2d535b1ec1dfcd11ed370d8e932bd49394b8d/lua/dap/repl.lua#L242 )
	-- end
	log.info("first_l: "..first_l.." last_l: "..last_l.." last updated: "..llu,bc,dc,du, ct)
end

-- TODO find better place to do this
local attached = {}
local function on_win(_, _, bufnr)
	if not attached[bufnr] then
		attached[bufnr] = true
		log.info("bufnr: "..bufnr)
		api.nvim_buf_attach(bufnr, false, {
			on_lines = on_lines,
		})
	end
	-- log.info("hi")
end

function M.setup()
	local ns = shared:setup()
	underline.ns = ns

	api.nvim_set_decoration_provider(ns, {
		on_win = on_win
		-- on_win = underline.on_win,
		-- on_line = underline.on_line,
	})
	local opt = { noremap = true, silent = true, nowait = true }
	local cmd = "<Cmd>lua _G.ProseCheck:test()<CR>"
	vim.api.nvim_set_keymap("n", ",", cmd, opt)
end

_G.ProseCheck = M
return M
