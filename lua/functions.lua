local api = vim.api
local SpellCheck = {pos = "unset", suggestions}

-- local function rebind()
-- 	local map = vim.api.nvim_set_keymap()
-- 	rebind = {1,2,3,4,5,6,8,9,0,q}
-- 	for key in rebind do 
-- 		map('n', key, jump, {noremap = true, silent =true}
-- 	end
-- end

-- function SpellCheck:back(key)
-- 	vim.fn.winrestview(self.pos)
-- 	self.pos = "unset"
-- end

function open_split()
	vim.cmd('10split')
	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_win_set_buf(win, buf)
	return buf
end

local function update_view(buf, suggestions)

	list = {}
	local keys = "1234567890abcdefghijklmnopqrstuvwxyz"
	for i=0,math.floor(#suggestions/3)-1 do
		list[i+1] = ""
		for j=3*i,3*i+2 do
			local key = keys:sub(j+1,j+1)
			list[i+1] = list[i+1]..'\t\t'..key..': '..suggestions[j+1]
		end
	end

	-- print remainder
	local i = math.floor(#suggestions/3)
	list[i+1] = ""
	for j=3*i,#suggestions-1 do
		local key = keys:sub(j+1,j+1)
		list[i+1] = list[i+1]..'\t\t'..key..': '..suggestions[j+1]
	end

	print(vim.inspect(list))
	api.nvim_buf_set_option(buf, 'modifiable', true)
	api.nvim_buf_set_lines(buf, 0, -1, false, list)
	api.nvim_buf_set_option(buf, 'modifiable', false)
end

-- TODO:
-- 		highlight curent word
-- 		jump back after pick
function SpellCheck:go()
	-- if self.pos == "unset" then
		self.pos = vim.fn.winsaveview()
		vim.api.nvim_command("set spell")
		-- vim.api.nvim_input("]s")
		local word = vim.fn.expand("<cword>")
		self.suggestions = vim.fn.spellsuggest(word)

		local buf = open_split()
		update_view(buf, self.suggestions)
		-- vim.api.nvim_input("z=")
	-- else 
	-- 	vim.fn.winrestview(self.pos)
	-- 	self.pos = "unset"
	-- end
end

_G.SpellCheck = SpellCheck
