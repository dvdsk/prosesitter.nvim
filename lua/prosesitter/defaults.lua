local python_query = [[
	[(string) (comment)+ ] @capture
]]
local rust_query = [[
	[(line_comment)+ (block_comment) (string_literal)] @capture
]]

local M = {}
M.query_by_ext = { rs = {query = rust_query}, py = {query = python_query} }
M.vale_cfg_ini = [[
StylesPath = styles
Vocab = Blog
[*.md]
BasedOnStyles = Vale, write-good
]]

return M
