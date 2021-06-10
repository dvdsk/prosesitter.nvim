local ts = require 'nvim-treesitter.configs'

ts.setup {
	highlight = { enable = true },
	indent = { enable = true },
}

-- TODO For now this does not run on update .. :(
function treesitter_languages()
	vim.api.nvim_command([[
		:TSUpdate
		:TSInstall rust python yaml toml c lua
	]])
	print("installed treesitter languages")
end

vim.wo.foldmethod = "expr"
vim.wo.foldexpr = "nvim_treesitter#foldexpr()"

local select = {
  enable = true,
  keymaps = {
	-- You can use the capture groups defined in textobjects.scm
	["af"] = "@function.outer",
	["if"] = "@function.inner",
	["ac"] = "@class.outer",
	["ic"] = "@class.inner",
  },
}

local swap = {
  enable = true,
  swap_next = {
	["h"] = "@parameter.inner",
  },
  swap_previous = {
	["H"] = "@parameter.inner",
  },
}

require'nvim-treesitter.configs'.setup {
  textobjects = {
    select = select,
	swap = swap,
  },
}
