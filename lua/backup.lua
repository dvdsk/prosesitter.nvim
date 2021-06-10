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

-- function split()
-- 	vim.cmd('vsplit')
-- 	local win = vim.api.nvim_get_current_win()
-- 	local buf = vim.api.nvim_create_buf(true, true)
-- 	vim.api.nvim_win_set_buf(win, buf)
-- end

local function open_window()
  buf = api.nvim_create_buf(false, true) -- create new emtpy buffer
  api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  -- get dimensions
  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")

  -- calculate our floating window size
  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)

  -- and its starting position
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  -- set some options
  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col
  }

  -- and finally create it with buffer attached
  win = api.nvim_open_win(buf, true, opts)
  return buf
end

local function update_view(buf, suggestions)
	api.nvim_buf_set_lines(buf, 0, -1, false, suggestions)
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
		print(vim.inspect(self.suggestions))

		buf = open_window()
		update_view(buf, self.suggestions)
		-- vim.api.nvim_input("z=")
	-- else 
	-- 	vim.fn.winrestview(self.pos)
	-- 	self.pos = "unset"
	-- end
end

_G.SpellCheck = SpellCheck
