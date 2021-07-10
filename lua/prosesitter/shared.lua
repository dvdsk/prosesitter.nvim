local api = vim.api
local log = require("prosesitter/log")
local M = {}
M.cfg = {
	captures = { "comment" },
	vale_to_hl = { error = "SpellBad", warning = "SpellRare", suggestion = "SpellCap" },
}
M.ns = nil

local function closest_smaller(target, table)
	local prev_k, prev_v
	for k,v in pairs(table) do
		if k > target then
			break
		end
		prev_k = k
		prev_v = v
	end
	return prev_k, prev_v
end

-- iterator that returns a span and highlight group
function M.hl_iter(results, meta_by_flatcol)
	local problems = vim.fn.json_decode(results)["stdin.md"]
	if problems == nil then
		-- TODO cleanup remove placeholders
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

		-- get the metadata for the line that was written to the flattend
		-- input for vale. Then calculate the the column positions in the buffer
		-- and get the placeholder extmark for recovering the line number later
		local flatcol_start, flatcol_end = unpack(problems[i]["Span"])
		-- log.info("problem: "..problems[i]["Message"]) TODO probably want to store in lookup db (key: bufnr+mark_id)
		local col_start, meta = closest_smaller(flatcol_start, meta_by_flatcol)
		local rel_start = flatcol_start - col_start
		local rel_end = flatcol_end - col_start

		return meta.buf, meta.id, rel_start, rel_end, hl
	end
end

local LintReqBuilder = {}
LintReqBuilder.__index = LintReqBuilder -- failed table lookups on the instances should fallback to the class table, to get methods
function LintReqBuilder.new()
	local self = setmetatable({}, LintReqBuilder)
	self.text = {}
	self.meta_by_mark = {}
	self.meta_by_idx = {}
	return self
end

function LintReqBuilder:update(marks, buf, row, start_col, end_col)
	-- remove all but first mark on the current line, change that first mark
	-- into a placeholder mark
	local id = marks[1][1] -- there can be a max of 1 placeholder per line
	local opt = { id = id, end_col= end_col }
	api.nvim_buf_set_extmark(buf, M.ns, row, start_col, opt) -- update placeholder
	local full_new_line = api.nvim_buf_get_lines(buf, row, row+1, true)[1]
	local new_line = string.sub(full_new_line, start_col, end_col)
	local idx = self.meta_by_mark[id].text_idx
	self.text[idx] = new_line
end

-- only single lines are added... issue if line breaks connect scentences
function LintReqBuilder:add(buf, row, start_col, end_col)
	local marks = api.nvim_buf_get_extmarks(buf, M.ns, {row, start_col}, {row, end_col}, {})
	if #marks > 0 then
		self:update(marks, buf, row, start_col, end_col)
		return
	end

	local opt = { end_col= end_col }
	local placeholder_id = api.nvim_buf_set_extmark(buf, M.ns, row, start_col, opt)
	local full_line = api.nvim_buf_get_lines(buf, row, row+1, true)
	local line = string.sub(full_line[1], start_col, end_col)
	self.text[#self.text+1] = line

	local meta = {buf=buf, text_idx=#self.text, id=placeholder_id}
	self.meta_by_mark[placeholder_id] = meta
	self.meta_by_idx[#self.text] = meta
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
		text=text..v.." "
		-- array[#array+1] = v
	end
	-- local text = table.concat(array, "\n", 1, 2)
	return text
end

function LintReqBuilder:build()
	local req = {}
	req.text = to_string(self.text)
	req.meta_by_flatcol = {}

	local col = 0
	for i=1,#self.text do
		req.meta_by_flatcol[col] = self.meta_by_idx[i]
		col = col + #self.text[i] + 1 -- plus one for the line end
	end

	return req
end

function M:setup()
	M.ns = vim.api.nvim_create_namespace("prosesitter")
	for _, hl in pairs(self.cfg.vale_to_hl) do
		hl = vim.api.nvim_get_hl_id_by_name(hl)
	end
	return M.ns
end

M.LintReqBuilder = LintReqBuilder
return M
