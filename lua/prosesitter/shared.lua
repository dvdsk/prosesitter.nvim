local log = require("prosesitter/log")
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
			local lnum = pieces[line].org_lnum -- get original line numb back
			-- subtract one to get to 0 based coll
			return lnum, startc + offset - 1, endc + offset - 1, hl
		end
	end
end

local Proses = {}
Proses.__index = Proses -- failed table lookups on the instances should fallback to the class table, to get methods
function Proses.new()
	local self = setmetatable({}, Proses)
	self.start_col = {}
	self.text = {}
	return self
end

function Proses:add(text, lang, start_col, lnum)
	self.text[lnum+1] = text -- needs +1 for table.concat to work (arrays start at 1)
	self.start_col[lnum] = start_col
end

function Proses:is_empty()
	local empty = next(self.text) == nil
	return empty
end

function Proses:reset()
	local text = table.concat(self.text, "\n")
	local pieces = {}
	for lnum, start_col in pairs(self.start_col) do -- works if text and start_col order matches
		pieces[#pieces+1] = { org_lnum = lnum, start_col = start_col }
	end
	self.text = {}
	self.start_col = {}
	return text, pieces
end

function M:setup()
	local ns = vim.api.nvim_create_namespace("prosesitter")
	for _, hl in pairs(self.cfg.vale_to_hl) do
		hl = vim.api.nvim_get_hl_id_by_name(hl)
	end
	return ns
end

M.Proses = Proses
return M