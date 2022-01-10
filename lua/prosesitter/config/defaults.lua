local log = require("prosesitter/log")
local M = {}

local c_and_cpp_query = {
	strings = "(string_literal) @capture",
	comments = "(comment) @capture",
}

M.queries = {
	rs = {
		strings = "(string_literal) @capture",
		comments = "(line_comment)+ (block_comment) @capture",
	},
	py = {
		docstrings = "((expression_statement(string) @capture) (#offset! @capture 0 3 0 -3))",
		strings = "((string) @capture (#offset! @capture 0 1 0 -1))",
		comments = "(comment)+ @capture",
	},
	lua = {
		strings = "(string) @capture",
		comments = "(comment)+ @capture",
	},
	c = c_and_cpp_query,
	h = c_and_cpp_query,
	cpp = c_and_cpp_query,
	hpp = c_and_cpp_query,
	tex = {
		strings = "(text) @capture",
		comments = "(comment) @capture",
	},
	sh = {
		strings = "(string) @capture",
		comments = "(comment) @capture",
	},
}

function M:ext()
	local ext = {}
	for extension, _ in pairs(self.queries) do
		-- comments may use whitespace to line out tables etc so be default we ignore it
		ext[extension] = { lint_targets = { "comments" }, langtool_ig = "WHITESPACE_RULE" }
	end

	ext.py.lint_targets = { "comments", "docstrings" }
	ext.tex.lint_targets = { "strings" }
	ext.tex.langtool_ig = "WHITESPACE_RULE,COMMA_PARENTHESIS_WHITESPACE"

	return ext
end

M.vale_cfg_ini = [==[
# StylesPath = added by lua code during install
MinAlertLevel = suggestion
[*]
# styles that should have all their rules enabled
BasedOnStyles = proselint, write-good, Vale
]==]

M.langtool_cfg = [==[
maxCheckThreads=2
]==]

M.cmds = {
	PsNext = "next",
	PsPrev = "prev",
	PsPopup = "popup",
	PsEnable = "enable",
	PsDisable = "disable",
}

return M
