local log = require("prosesitter/log")
local api = vim.api

M = {}

local org_cursor = nil
local function hide_cursor()
	org_cursor = vim.opt.guicursor
	vim.cmd("hi Cursor blend=100")
	vim.opt.guicursor = { "a:Cursor/lCursor" }
end

local function restore_cursor()
	vim.opt.guicursor = org_cursor
end

local function map_keys(buf)
	local opt = { nowait = true, noremap = true, silent = true }
	local close_popup = [[:lua require("prosesitter/actions/hover_menu"):callback("c")<CR>]]
	local chars = "abcdefghijklmnopqrstuvwxyz:,."
	for i = 1, #chars do
		local key = chars:sub(i, i)
		api.nvim_buf_set_keymap(buf, "n", key, close_popup, opt)
		api.nvim_buf_set_keymap(buf, "n", key:upper(), close_popup, opt)
	end

	local special_keys = { "<Right>", "<Left>", "<Up>", "<Down>", "<leader>", "Esc" }
	for _, key in ipairs(special_keys) do
		api.nvim_buf_set_keymap(buf, "n", key, close_popup, opt)
	end

	for i = 1, 10 do
		local cmd = [[:lua require("prosesitter/actions/hover_menu"):callback(]] .. i .. [[)<CR>]]
		api.nvim_buf_set_keymap(buf, "n", tostring(i), cmd, opt)
	end
end

function M:close_popup()
	api.nvim_win_close(self.win, true)
	self.win = false
	restore_cursor()
end

function M:callback(order)
	self:close_popup()
	if order == "c" then
		return
	end

	if #self.suggestions > 0 then
		local replacement = self.suggestions[order]
		local range = {
			["start"] = {
				line = self.row - 1,
				character = self.issue.start_col - 2,
			},
			["end"] = {
				line = self.row - 1,
				character = self.issue.end_col - 1,
			},
		}
		local replace_span = {
			range = range,
			newText = replacement,
		}
		vim.lsp.util.apply_text_edits({ replace_span }, 0)
	end
end

local function best_issue(issues)
	local issue
	local suggestions
	for _, v in ipairs(issues) do
		issue = v
		suggestions = issue:suggestion_lists()
		if suggestions ~= nil then
			return issue, suggestions
		end
	end
	return issue, {}
end

local function format(issue, suggestions)
	local lines = {}
	lines[#lines + 1] = issue.msg
	lines[#lines + 1] = "[" .. issue.severity .. "]" .. " " .. issue.full_source
	for i, sug in ipairs(suggestions) do
		lines[#lines + 1] = i .. ": " .. sug
	end
	return lines
end

local function max_width(lines)
	local max = 0
	for _, line in ipairs(lines) do
		if #line > max then
			max = #line
		end
	end
	return max
end

-- open hover window if lint error on current pos
-- else return false
function M:popup(issues)
	local issue, suggestions = best_issue(issues)
	local lines = format(issue, suggestions)

	local buf = api.nvim_create_buf(false, true)
	api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	api.nvim_buf_set_option(buf, "filetype", "whid")
	api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	api.nvim_buf_set_option(buf, "modifiable", false)
	hide_cursor()
	-- https://dev.to/2nit/how-to-write-neovim-plugins-in-lua-5cca

	local opt = {
		style = "minimal",
		relative = "cursor",
		width = max_width(lines) + 1,
		height = #lines,
		row = 1,
		col = 0,
	}

	self.suggestions = suggestions
	self.issue = issue
	self.row = api.nvim_win_get_cursor(0)[1]
	self.win = api.nvim_open_win(buf, true, opt)
	map_keys() -- make any key close the window
end

return M
