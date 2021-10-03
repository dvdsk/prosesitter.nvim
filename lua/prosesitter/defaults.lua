local M = {}

M.query_by_ext = {
	rs = "[(line_comment)+ (block_comment) (string_literal)] @capture",
	py = "[(string) (comment)+ ] @capture",
	lua = "[(comment)+ ] @capture",
	c = "[(string_literal) (comment) ] @capture",
	h = "[(string_literal) (comment) ] @capture",
	cpp = "[(string_literal) (comment) ] @capture",
	hpp = "[(string_literal) (comment) ] @capture",
	tex = "[(text)+] @capture"
}

M.vale_cfg_ini = [==[
# StylesPath = added by lua code during install
MinAlertLevel = suggestion
[*]
# styles that should have all their rules enabled
BasedOnStyles = proselint, write-good, Vale
]==]

return M
