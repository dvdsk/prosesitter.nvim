local python_query = [[
	[(string) (comment)+ ] @capture
]]
local rust_query = [[
	[(line_comment)+ (block_comment) (string_literal)] @capture
]]

local M = {}
M.query_by_ext = { rs = rust_query, py = python_query }
M.vale_cfg_ini = [==[
# StylesPath = added by lua code during install
MinAlertLevel = suggestion
[*]
# styles that should have all their rules enabled
BasedOnStyles = proselint, write-good, Vale
]==]

return M
