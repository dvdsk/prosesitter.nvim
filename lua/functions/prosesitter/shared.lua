local M = {}
M.cfg = {
	captures = { "comment" },
	vale_to_hl = { error = "SpellBad", warning = "SpellRare", suggestion = "SpellCap" },
}
M.ns = nil

-- local result = vim.fn.system(
-- 	"vale"
-- 		.. " --config .vale.ini" -- TODO remove config path in favor of lua check for system config
-- 		.. " --output=JSON"
-- 		.. " --ignore-syntax"
-- 		.. " --ext='.md'",
-- 	text
-- )

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
function Proses:new()
	self.prose = ""
	self.piece = {}
end

function Proses:add(prose, start_col, lnum)
	self.prose = self.prose..prose
	self.piece[lnum] = {len= #prose, start_col= start_col}
end

function M:setup()
	self.ns = vim.api.nvim_create_namespace("prosesitter")
	for _, hl in pairs(self.cfg.vale_to_hl) do
		hl = vim.api.nvim_get_hl_id_by_name(hl)
	end
end

M.Proses = Proses
return M
