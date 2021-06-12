vim.cmd("packadd paq-nvim")
local paq = require("paq-nvim").paq
paq({ "savq/paq-nvim", opt = true })

-- Dependencies
paq("nvim-lua/plenary.nvim") -- telescope, gitsigns
paq("nvim-lua/popup.nvim") -- telescope

-- themes
paq("folke/tokyonight.nvim")
paq("shaunsingh/solarized.nvim")

-- Looks
paq("machakann/vim-highlightedyank")
paq("lewis6991/gitsigns.nvim")
paq("hoob3rt/lualine.nvim")
paq("kyazdani42/nvim-web-devicons")
paq("mhinz/vim-startify")

-- GUI Tools
paq("kyazdani42/nvim-tree.lua")
paq("simnalamburt/vim-mundo")
paq("nvim-telescope/telescope.nvim")
paq("oberblastmeister/termwrapper.nvim")
paq("folke/which-key.nvim")

-- Text Tools
-- paq 'svermeulen/vim-macrobatics'
paq("vim-scripts/Align")
paq("b3nj5m1n/kommentary")
paq("conradirwin/vim-bracketed-paste")
paq("lewis6991/spellsitter.nvim")
-- paq 'airblade/vim-rooter' -- has issues with rust workspaces

-- Nouns, Verbs, textobjects
paq("tpope/vim-surround")
paq("tpope/vim-repeat")
paq("kana/vim-textobj-user")
paq("kana/vim-textobj-indent")

-- TreeSitter
paq({ "nvim-treesitter/nvim-treesitter", run = treesitter_languages })
paq("nvim-treesitter/nvim-treesitter-textobjects")

-- LSP
paq("neovim/nvim-lspconfig")
paq("glepnir/lspsaga.nvim") -- extend lsp ui

-- Completions
paq("hrsh7th/nvim-compe")
paq("hrsh7th/vim-vsnip")
-- paq 'L3MON4D3/LuaSnip' -- switch to in future
paq("rafamadriz/friendly-snippets")

require("settings")
require("maps")
require("maps_plugins")

-- these files mirrors those above in the package section
-- and contain configurations
require("theme")
require("looks")
require("gui_tools")
require("text_tools")
require("treesitter")

require("comp")
require("lsp")

local saga = require("lspsaga")
saga.init_lsp_saga()
