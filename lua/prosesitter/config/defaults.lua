local log = require("prosesitter/log")
local M = {}

local c_and_cpp_query = {
	strings = "(string_literal) @capture",
	comments = "(comment) @capture",
}

M.queries = {
	rust = {
		strings = "(string_literal) @capture",
		comments = "(line_comment)+ (block_comment) @capture",
	},
	python = {
		strings = "((string) @capture (#offset! @capture 0 1 0 -1))",
		comments = "(comment)+ @capture",
	},
	lua = {
		strings = "(string) @capture",
		comments = "(comment)+ @capture",
	},
	cpp = c_and_cpp_query,
	c = c_and_cpp_query,
	latex = {
		strings = "(text) @capture",
		comments = "(comment) @capture",
	},
	sh = {
		strings = "(string) @capture",
		comments = "(comment) @capture",
	},
	markdown = {
		strings = "(paragraph) @capture",
	},
}

function M:filetype()
	local filetype = {}
	for extension, _ in pairs(self.queries) do
		-- comments may use whitespace to line out tables etc so be default we ignore it
		filetype[extension] = { lint_targets = { "comments" }, langtool_ignore = "WHITESPACE_RULE" }
	end

	filetype.markdown.lint_targets = { "strings" }
	filetype.python.lint_targets = { "comments" }
	filetype.latex.lint_targets = { "strings" }
	filetype.latex.langtool_ignore = "WHITESPACE_RULE,COMMA_PARENTHESIS_WHITESPACE"

	return filetype
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
