local api = vim.api
local SpellCheck = { pos = "unset", suggestions, buf, win }

local keys = "1234567890abcdefghijklmnopqrstuvwxyz"
local function bind_opt(buf, suggestions)
	local opt = { noremap = true, silent = true, nowait = true }
	for i = 1, #keys do
		local key = keys:sub(i, i)
		local cmd = "<Cmd>lua _G.SpellCheck:replace(" .. i .. ")<CR>"
		api.nvim_buf_set_keymap(buf, "n", key, cmd, opt)
	end

	local cmd = "<Cmd>lua _G.SpellCheck:quit()<CR>"
	api.nvim_buf_set_keymap(buf, "n", "q", cmd, opt)
	api.nvim_buf_set_keymap(buf, "n", "<Esc>", cmd, opt)
end

-- assumes cursor is at the beginning of org
local function replace(org, new)
	-- vim.cmd("s/\\<" .. org .. "\\>/" .. new .. "/g")
	print("org: "..org)
	print("new: "..new)
	vim.cmd("s/" .. org .. "/" .. new .. "/g")
	-- vim.fn.substitute(org, new, "", 1)
end

function SpellCheck:quit()
	api.nvim_win_close(self.win, true)
	vim.fn.winrestview(self.pos)
end

function SpellCheck:replace(i)
	api.nvim_win_close(self.win, true)
	local good = self.suggestions[i]
	local bad = vim.fn.spellbadword()[1]
	replace(bad, good)
	vim.fn.winrestview(self.pos)
end

function SpellCheck:open_split()
	vim.cmd("10split")
	self.win = api.nvim_get_current_win()
	self.buf = api.nvim_create_buf(false, true)
	api.nvim_buf_set_option(self.buf, "bufhidden", "wipe")

	vim.api.nvim_win_set_buf(self.win, self.buf)
	return self.buf
end

local function col_fmt_str(cols)
	local available = api.nvim_get_option("columns")
	local border = available / 10
	local width = math.ceil((available - 2 * border) / cols)
	local fmt_border = "%" .. border .. "s "
	local fmt_str = fmt_border .. "%-" .. width .. "s"
	for _ = 1, cols - 1 do
		fmt_str = fmt_str .. "%-" .. width .. "s"
	end

	return fmt_str
end

local function write_table(list, cols)
	local table = {}
	local fmt_str = col_fmt_str(cols)

	local entries = {}
	for i = 1, #list do
		local key = keys:sub(i, i)
		local idx = (i - 1) % cols + 1
		entries[idx] = key .. ": " .. list[i]

		if i % cols == 0 then
			table[i / cols] = string.format(fmt_str, " ", unpack(entries))
		end
	end

	-- write remainder
	local fmt_str = col_fmt_str(#entries)
	local idx = math.ceil(#list / cols)
	table[idx] = string.format(fmt_str, " ", unpack(entries))

	return table
end

local function update_view(buf, suggestions)
	local table = write_table(suggestions, 3)

	api.nvim_buf_set_option(buf, "modifiable", true)
	api.nvim_buf_set_lines(buf, 0, -1, false, table)
	api.nvim_buf_set_option(buf, "modifiable", false)
end

-- TODO:
-- 		highlight curent word
-- 		jump back after pick
function SpellCheck:correct()
	-- vim.api.nvim_command("set spell")
	self.pos = vim.fn.winsaveview()
	vim.cmd("[s") -- jump to misspelled

	local word = vim.fn.expand("<cword>")
	self.suggestions = vim.fn.spellsuggest(word)

	local buf = self:open_split()
	update_view(buf, self.suggestions)
	bind_opt(buf, self.suggestions)
end

_G.SpellCheck = SpellCheck
