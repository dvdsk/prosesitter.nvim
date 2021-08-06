local log = require("prosesitter/log")
local hl_linting = require("prosesitter/on_event/hl_linting/hl_linting")
local marks = require("prosesitter/on_event/marks")
local check = require("prosesitter/on_event/check/check")
local query_linting = require("prosesitter/on_event/query_linting")

local get_parser = vim.treesitter.get_parser
local api = vim.api
local M = {}

local function postprocess(results, lintreq)
	for buf, id, start_c, end_c, hl_group, hover_txt in check.hl_iter(results, lintreq) do
		marks.underline(buf, id, start_c, end_c, hl_group, hover_txt)
	end
end

function M.setup(shared)
	check:setup(shared, postprocess)
	marks.setup(shared)
	hl_linting.setup(shared, check)
	query_linting.setup(shared, check)
end

function M.attach_hl(bufnr)
	hl_linting.attach(bufnr)
end

function M.attach_query(bufnr)
	query_linting.attach(bufnr)
end

function M.get_allowlist_req()
	return check.hl_allow_req
end

function M.get_denylist_req()
	return check.hl_deny_req
end

function M.disable()
	check:disable()
end

return M
