local api = vim.api
local SpellCheck = { pos = "unset", suggestions }

local keys = "1234567890abcdefghijklmnopqrstuvwxyz"
local function bind_opt(buf, suggestions)
	for i=1,#keys do
		local key = keys:sub(i, i)
		print()
		local opt = {noremap = true, silent =true}
		local cmd = '<Cmd>lua _G.SpellCheck:go('..suggestions[i]..')<CR>'
		api.nvim_buf_set_keymap(buf, 'n', key, cmd, opt)
	end
end

function SpellCheck:go(i)
	print("i: "..i)
end

local function open_split()
	vim.cmd("10split")
	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_win_set_buf(win, buf)
	return buf
end

local function col_fmt_str(cols)
	local available = api.nvim_get_option("columns");
	local border = available/10
	local width = math.ceil((available-2*border)/cols)
	local fmt_border = "%"..border.."s "
	local fmt_str = fmt_border.."%-"..width.."s"
	for _ = 1, cols-1 do
		fmt_str = fmt_str .. "%-"..width.."s"
	end

	return fmt_str
end

local function write_table(list, cols)
	local table = {}
	local fmt_str = col_fmt_str(cols)

	local entries = {}
	for i = 1, #list do
		local key = keys:sub(i, i)
		local idx = (i-1) % cols + 1
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
	self.pos = vim.fn.winsaveview()
	vim.api.nvim_command("set spell")
	local word = vim.fn.expand("<cword>")
	self.suggestions = vim.fn.spellsuggest(word)

	local buf = open_split()
	update_view(buf, self.suggestions)
	bind_opt(buf, self.suggestions)
end

_G.SpellCheck = SpellCheck
