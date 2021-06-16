local log = require("functions/prosesitter/log")
local M = {}
M.cfg = {
	captures = { "comment" },
	vale_to_hl = { error = "SpellBad", warning = "SpellRare", suggestion = "SpellCap" },
}
M.ns = nil


-- iterator that returns a span and highlight group
function M.hl_iter(results, pieces)
	local problems = vim.fn.json_decode(results)["stdin.md"]
	if problems == nil then
		return
	end

	local i = 0
	return function() -- lua iterator
		while i < #problems do
			i = i + 1
			local severity = problems[i].Severity
			local hl = M.cfg.vale_to_hl[severity]
			local line = problems[i].Line -- relative line numb in chunk send to vale

			local offset = pieces[line].start_col
			local startc, endc = unpack(problems[i]["Span"])
			local lnum = pieces[line].lnum -- get original line numb back
			return lnum, startc+offset, endc+offset, hl
		end
	end
end

local Proses = {}
Proses.__index = Proses -- failed table lookups on the instances should fallback to the class table, to get methods
function Proses.new()
	local self = setmetatable({}, Proses)
	-- local time_str = vim.fn.reltime()
	-- self.last_update = vim.fn.reltimefloat(time_str)
	self.text = ""
	self.piece = {}
	return self
end

function Proses:add(text, start_col, lnum)
	if self.piece[lnum] == nil then
		self.text = self.text..text
		self.piece[lnum] = {len= #text, start_col= start_col}
	end
end

function Proses:reset()
	log.info(vim.inspect(self))
	local text = self.text
	local pieces = self.pieces
	self = {}
	return text, pieces
end

function M:setup()
	self.ns = vim.api.nvim_create_namespace("prosesitter")
	for _, hl in pairs(self.cfg.vale_to_hl) do
		hl = vim.api.nvim_get_hl_id_by_name(hl)
	end
end

M.Proses = Proses
return M
