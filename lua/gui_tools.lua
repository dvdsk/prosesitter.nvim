require"termwrapper".setup {
    -- these are all of the defaults
    open_autoinsert = true, -- autoinsert when opening
    toggle_autoinsert = true, -- autoinsert when toggling
    autoclose = true, -- autoclose, (no [Process exited 0])
    winenter_autoinsert = false, -- autoinsert when entering the window
    default_window_command = "belowright 13split", -- the default window command to run when none is specified,
                                                   -- opens a window in the bottom
    open_new_toggle = true, -- open a new terminal if the toggle target does not exist
    log = 1, -- 1 = warning, 2 = info, 3 = debug
}

require('telescope').setup{
  defaults = {
    vimgrep_arguments = {
      'rg',
      '--color=never',
      '--no-heading',
      '--with-filename',
      '--line-number',
      '--column',
      '--smart-case'
    },
    prompt_position = "bottom",
    prompt_prefix = "> ",
    selection_caret = "> ",
    entry_prefix = "  ",
    initial_mode = "insert",
    selection_strategy = "reset",
    sorting_strategy = "descending",
    layout_strategy = "horizontal",
    layout_defaults = {
      horizontal = {
        mirror = false,
      },
      vertical = {
        mirror = false,
      },
    },
    file_sorter =  require'telescope.sorters'.get_fuzzy_file,
    file_ignore_patterns = {},
    generic_sorter =  require'telescope.sorters'.get_generic_fuzzy_sorter,
    shorten_path = true,
    winblend = 0,
    width = 0.75,
    preview_cutoff = 120,
    results_height = 1,
    results_width = 0.8,
    border = {},
    borderchars = { '─', '│', '─', '│', '╭', '╮', '╯', '╰' },
    color_devicons = true,
    use_less = true,
    set_env = { ['COLORTERM'] = 'truecolor' }, -- default = nil,
    file_previewer = require'telescope.previewers'.vim_buffer_cat.new,
    grep_previewer = require'telescope.previewers'.vim_buffer_vimgrep.new,
    qflist_previewer = require'telescope.previewers'.vim_buffer_qflist.new,

    -- Developer configurations: Not meant for general override
    buffer_previewer_maker = require'telescope.previewers'.buffer_previewer_maker
  }
}

require("which-key").setup {
	plugins = { 
		registers = true,
		spelling = { 
			enabled = true,
			suggestions = 20,
		}
	}
}
