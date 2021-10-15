local M = {}

local c_and_cpp_query = {
	strings = "[(string_literal) ] @capture",
	comments = "[(comment) ] @capture",
}

M.queries = {
	rs = {
		strings = "[(string_literal)] @capture",
		comments = "[(line_comment)+ (block_comment)] @capture",
	},
	py = {
		strings = "[(string) ] @capture",
		comments = "[(comment)+ ] @capture",
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
		strings = "[(text)+] @capture",
		comments = "[(comment)] @capture",
	},
	sh = {
		strings = "[(string)] @capture",
		comments = "[(comment)] @capture",
	},
}

function M.merge_queries(queries)
	local q1 = string.match(queries.strings, "%[(.-)%]")
	local q2 = string.match(queries.comments, "%[(.-)%]")
	return "[" .. q1 .. " " .. q2 .. "] @capture"
end

for _, queries in pairs(M.queries) do
	if queries["both"] == nil then
		queries["both"] = M.merge_queries(queries)
	end
end

M.lint_target = {}
for key, _ in pairs(M.queries) do
	M.lint_target[key] = "both"
end

-- override some options to not have both enabled
M.lint_target.sh = "comments" -- doesnt really make sens to check bash strings (mostly paths/cmds)

function M.all_disabled(queries, disabled)
	local table = {}
	for key, _ in pairs(queries) do
		table[key] = disabled
	end
	return table
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
