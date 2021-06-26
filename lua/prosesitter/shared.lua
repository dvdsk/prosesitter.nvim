local api = vim.api
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
		return function() return nil end -- caller needs a function, see lua iterators
	end

	local i = 0
	return function() -- lua iterator
		i = i + 1
		if i > #problems then
			return nil
		end
		local severity = problems[i].Severity
		local hl = M.cfg.vale_to_hl[severity]
		local line = problems[i].Line -- relative line numb in chunk send to vale

		local offset = pieces[line].start_col
		local startc, endc = unpack(problems[i]["Span"])
		local lnum = pieces[line].org_lnum -- get original line numb back
		-- subtract one to get to 0 based coll
		return lnum, startc + offset - 1, endc + offset, hl
	end
end

local LintReqBuilder = {}
LintReqBuilder.__index = LintReqBuilder -- failed table lookups on the instances should fallback to the class table, to get methods
function LintReqBuilder.new()
	local self = setmetatable({}, LintReqBuilder)
	self.text = {}
	self.meta_by_id = {}
	return self
end

function LintReqBuilder:update(marks, buf, row, start_col, end_col)
	local id = marks[1]
	local opt = { id = id, end_col= end_col }
	api.nvim_buf_set_extmark(buf, M.ns, row, start_col, opt) -- update placeholder
	local new_line = api.nvim_buf_get_lines(buf, row, row, true).sub(start_col, end_col)
	local idx = self.meta_by_id[id].text_idx
	self.text[idx] = new_line
end

-- only single lines are added... issue if line breaks connect scentences
function LintReqBuilder:add(buf, row, start_col, end_col)
	local marks = api.nvim_buf_get_extmarks(buf, M.ns, (row, start_col), (row, end_col))
	if #marks > 0 then
		self.update(marks, buf, row, start_col, end_col)
		return
	end

	local opt = { id = 0, end_col= end_col }
	local placeholder_id = api.nvim_buf_set_extmark(buf, M.ns, row, start_col, opt)
	local line = api.nvim_buf_get_lines(buf, row, row, true).sub(start_col, end_col)
	self.text[#self.text+1] = line

	local meta = {buf=buf, text_idx=#self.text}
	self.meta_by_id[placeholder_id] = meta
end

function LintReqBuilder:is_empty()
	local empty = next(self.text) == nil
	return empty
end

-- for some unknown reason table.concat hangs infinitly. Since we usually do not have
-- that many strings in table this is an okay alternative
local function to_string(table)
	-- local array = {}
	local text = ""
	for _, v in pairs(table) do
		text=text..v.."\n"
		-- array[#array+1] = v
	end
	-- local text = table.concat(array, "\n", 1, 2)
	return text
end

function LintReqBuilder:build() -- TODO FIXME
	local text = to_string(self.text_by_id)
	local pieces = {}
	for lnum, start_col in pairs(self.start_col) do -- works if text and start_col order matches
		pieces[#pieces+1] = { org_lnum = lnum, start_col = start_col }
	end
	self.text_by_id = {}
	self.start_col = {}
	return text, pieces
end

function M:setup()
	M.ns = vim.api.nvim_create_namespace("prosesitter")
	for _, hl in pairs(self.cfg.vale_to_hl) do
		hl = vim.api.nvim_get_hl_id_by_name(hl)
	end
	return M.ns
end

M.Proses = LintReqBuilder
return M
