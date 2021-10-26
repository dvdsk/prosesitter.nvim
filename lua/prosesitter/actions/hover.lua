local log = require("prosesitter/log")
local state = require("prosesitter/state")
local marks = require("prosesitter/linter/marks/marks")
local api = vim.api

M = {}
-- [1].value
local function format(issues)
	local lines = {}
	for _, issue in ipairs(issues) do
		lines[#lines+1] = issue.msg
		lines[#lines+1] = "["..issue.severity.."]".." "..issue.full_source

		local suggestion = issue:suggestion_text()
		if suggestion ~= nil then
			lines[#lines+1] = suggestion
		end
	end
	return lines
end

M.format = format

-- open hover window if lint error on current pos else return
function M.popup()
	local row, col = unpack(api.nvim_win_get_cursor(0))
	local start = { row - 1, col } -- row needs to be zero indexed for get_extmarks
	local stop = { row - 1, 0 } -- search entire line, TODO handle multi line extmarks
	local mark = marks.get_closest(start, stop)

	if mark == nil then
		return false
	end

	local id = mark[1]
	local issues = state.issues:for_id(id)

	local text = format(issues)
	vim.lsp.util.open_floating_preview(text, "markdown", {})
end

return M
