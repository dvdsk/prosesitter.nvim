local log = require("prosesitter/log")
local M = {}

local c_and_cpp_query = {
	strings = "[(string_literal) ] @capture",
	comments = "[(comment) ] @capture",
}

local default_queries = {
	rs = {
		strings = "[(string_literal)] @capture",
		comments = "[(line_comment)+ (block_comment)] @capture",
	},
	py = {
		strings = "((string) @capture (#offset! @capture 0 1 0 -1))", -- may not be invalid range (will be skipped)
		comments = "",
		-- comments = "[(comment)+ ] @capture",
		both = ""
	},
	lua = {
		strings = "[(string) ] @capture",
		comments = "[(comment)+ ] @capture",
	},
	c = c_and_cpp_query,
	h = c_and_cpp_query,
	cpp = c_and_cpp_query,
	hpp = c_and_cpp_query,
	tex = {
		strings = "[(text)] @capture",
		comments = "[(comment)] @capture",
	},
	sh = {
		strings = "[(string)] @capture",
		comments = "[(comment)] @capture",
	},
}

function M.merge_queries(to_merge)
	local q1 = string.match(to_merge.strings, "%[(.-)%]")
	local q2 = string.match(to_merge.comments, "%[(.-)%]")
	return "[" .. q1 .. " " .. q2 .. "] @capture"
end

function M:ext()
	local ext = {}
	for extension, queries in pairs(default_queries) do
		if queries["both"] == nil then
			queries.both = self.merge_queries(queries)
		end
		ext[extension] = { queries = queries, lint_target = "both", langtool_ig="" }
	end

	-- override some options to not have both enabled
	ext.sh.lint_target = "comments" -- doesnt really make sens to check bash strings (mostly paths/cmds)
	ext.tex.langtool_ig = "WHITESPACE_RULE,COMMA_PARENTHESIS_WHITESPACE"
	-- comments may use whitespace to line out tables etc
	ext.py.langtool_ig = "WHITESPACE_RULE"
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
