local util = require "prosesitter.preprocessing.util"

M = {}

local split = {}
function split:new(buf, node, meta, req)
	self.row_s, self.col_s, self.row_end, self.col_end = util.range(node, meta)
	self.req = req
	self.buf = buf
end

function split:add(row_start, col_start, row_end, col_end)
	if row_start ~= row_end then
		self.req:add_rows(self.buf, row_start, row_end, col_start, col_end)
	elseif col_start ~= col_end then
		self.req:add_row(self.buf, row_start, col_start, col_end)
	end
end

function split:add_trimmed(trim, child)
	local row_start, col_start, row_end, col_end = child:range()
	self:add(self.row_s, self.col_s, row_start, col_start)
	self:add(row_start, col_start+trim, row_end, col_end-trim)
	self.row_s = row_end
	self.col_s = col_end
end

function split:add_code(child)
	local row_start, col_start, row_end, col_end = child:range()
	self:add(self.row_s, self.col_s, row_start, col_start)
	self.row_s = row_end
	self.col_s = col_end
	self.req:add_append_text(self.buf, self.row_s, "code")
end

function split:add_link(child)
	local c_row_start, c_col_start, c_row_end, c_col_end = child:range()
	self:add(self.row_s, self.col_s, c_row_start, c_col_start)
	local text_child = child:named_child(0)
	local row_start, col_start, row_end, col_end = text_child:range()
	self:add(row_start, col_start, row_end, col_end)
	self.row_s = c_row_end
	self.col_s = c_col_end
end

-- assumes a single line
local function markdown_split_paragraph(buf, node, meta, req)
	split:new(buf, node, meta, req)
	for child in node:iter_children() do
		if child:type() == "emphasis" then
			split:add_trimmed(1, child)
		elseif child:type() == "strong_emphasis" then
			split:add_trimmed(2, child)
		elseif child:type() == "code_span" then
			split:add_code(child)
		elseif child:type() == "inline_link" then
			split:add_link(child)
		end
	end

	if split.col_end > split.col_s then
		split:add(split.row_s, split.col_s, split.row_end, split.col_end)
		req:add_append_text(buf, split.row_s, " ")
	end
end

local function prep(buf, node, meta, req)
	if node:parent():type() == "block_quote" then
		return
	end

	if node:named_child_count() > 0 then
		markdown_split_paragraph(buf, node, meta, req)
	else
		local start_row, start_col, end_row, end_col = util.range(node, meta)
		req:add_rows(buf, start_row, end_row, start_col, end_col)
		req:add_append_text(buf, end_row, " ")
	end
end

return prep
