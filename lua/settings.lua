local o = vim.o -- global options
local wo = vim.wo
local bo = vim.bo
local g = vim.g
local cmd = vim.cmd

-- global options
o.shortmess = "" -- usefull for debug handlers/autocommands
o.ignorecase = true --ignore case in search
o.smartcase = true --except when I put a capital in the query
o.incsearch = true --highlight all matches:
o.hlsearch = false --do not keep highlighting search after move
o.mouse = 'nic' --enable mouse support except for selecting text
-- o.nohlsearch = true --do not keep highlighting search after move
o.spell = false 
o.spelllang = 'en_gb'
o.spellsuggest = "10" --don't take up the entire screen
o.hidden = true --allow to hide an unsaved buffer
o.splitbelow = true --new split goes bottom
o.splitright = true --new split goes right
o.tabstop= 4
o.softtabstop= 0 
o.shiftwidth = 4
o.smartindent = true
o.foldmethod = "syntax"
o.foldenable = true
o.foldlevel = 1
o.foldlevelstart = 99

-- gui related
wo.number = true
wo.relativenumber = true
o.laststatus = 2
o.termguicolors = true

-- undo
local undodir = vim.fn.system("echo $HOME/.vimdid")
o.undodir = undodir --permanent undo
o.undofile = true --permanent undo
vim.fn.system("mkdir -p "..o.undodir) -- ensure the folder exists


-- comments shoulb be italic
vim.api.nvim_exec([[
	highlight Comment cterm=italic gui=italic
	]], false)
