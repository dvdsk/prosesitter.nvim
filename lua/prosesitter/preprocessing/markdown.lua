local util = require "prosesitter.preprocessing.util"

M = {}

-- assumes a single line
local function markdown_split_paragraph(buf, node, meta, req)
	local add = function(row_start, col_start, row_end, col_end)
		if row_start ~= row_end then
			req:add_rows(buf, row_start, row_end, col_start, col_end)
		elseif col_start ~= col_end then
			req:add_row(buf, row_start, col_start, col_end)
		end
	end

	local curr_row_s, curr_col_s, par_row_end, par_col_end = util.range(node, meta)
	local add_trimmed = function(trim, child)
		local child_row_start, child_col_start, child_row_end, child_col_end = child:range()
		add(curr_row_s, curr_col_s, child_row_start, child_col_start)
		add(child_row_start, child_col_start+trim, child_row_end, child_col_end-trim)
		curr_row_s = child_row_end
		curr_col_s = child_col_end
	end

	for child in node:iter_children() do
		if child:type() == "emphasis" then
			add_trimmed(1, child)
		elseif child:type() == "strong_emphasis" then
			add_trimmed(2, child)
		elseif child:type() == "code_span" then
			local child_row_start, child_col_start, child_row_end, child_col_end = child:range()
			add(curr_row_s, curr_col_s, child_row_start, child_col_start)
			curr_row_s = child_row_end
			curr_col_s = child_col_end
			req:add_append_text(buf, curr_row_s, "code")
		elseif child:type() == "inline_link" then
			local child_row_start, child_col_start, child_row_end, child_col_end = child:range()
			add(curr_row_s, curr_col_s, child_row_start, child_col_start)
			local text_child = child:named_child(0)
			local row_start, col_start, row_end, col_end = text_child:range()
			add(row_start, col_start, row_end, col_end)
			curr_row_s = child_row_end
			curr_col_s = child_col_end
		end
	end

	if par_col_end > curr_col_s then
		add(curr_row_s, curr_col_s, par_row_end, par_col_end)
		req:add_append_text(buf, curr_row_s, " ")
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
