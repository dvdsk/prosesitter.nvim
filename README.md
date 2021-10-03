# prosesitter

Prosesitter uses treesitter and vale to bring true syntax aware prose linting to neovim

## What is Prosesitter?
prosesitter.nvim is a text linting tool that adds spell and style checking to your comments and strings. It uses vale to check what you write for style problems. That could vary from not using the passive voice and weasle words ('very' unique) to outdated or noninclusive terms. You can set up your own style or copy an existing one. If you let prosesitter set up vale for you it will also setup some styles for you [from vales style libary](https://github.com/errata-ai/styles). 


GIF

### Features
 - Low performance impact; vale is called asynchronously and only when needed
 - Portable; written in lua and depends only on the vale binary. offers to install vale if not found
 - Configurable; switch between prose style without reloading, add your own queries specifying what to lint
 - Supports any language with a treesitter parser; though you might need to add your own query if I have not yet added one [adding queries](adding_queries.md). Out of the box support for: python, rust, latex, c, c++
 - Telescope integration

### Requirements
 - neovim > 0.5
 - (windows only) vale installed

### Installation

packer.nvim:
```
use {
	'dvdsk/prosesitter'
}
```
vim-plug:
```
plug 'dvdsk/prosesitter'
```

### Setup
```lua
require("telescope").load_extension("prosesitter") -- Optionally, depends on telescope.nvim
require("prosesitter"):setup()
```

or pass a (partial)configuration; setting up your own vale binary, vale config and or adding extra treesitter queries (see [adding queries](adding_queries.md)
```lua
require("telescope").load_extension("prosesitter") -- Optionally, depends on telescope.nvim
require("prosesitter"):setup({
	vale_bin = vim.fn.stdpath("data") .. "/prosesitter/vale",
	vale_cfg = vim.fn.stdpath("data") .. "/prosesitter/vale_cfg.ini",
	extra_queries = { py = "[(string)] @capture" },
	default_cmds = false,  -- do not add commands (default = true)
	enabled = false, -- do not start linting files on open (default = true)
})
```

### Usage
You can map/use either lua functions or commands, the following functions are availible:

 - next/prev: jump to the next/prev linting issue from the current cursor pos and show the error in a popup window
 - popup: show a popup window if there is a linting issue on the current cursor pos
 - disable: disables linting on change removing all added highlights 
 - enable: re-enable linting on change and lint all open (supported) buffers
 - switch\_vale\_cfg: switches to a different vale config, updates all highlights to reflect the change. Not availible as command, takes as argument the path to the vale config to use

 The functions next, prev and popup return a bool that is true if they could jump/open a popup window. Use this (for example) to create a single keymap for prosesitters popup and your lsps show documentation function.

The commands:
 - PsNext
 - PsPrev
 - PsPopup
 - PsEnable
 - PsDisable

#### example mapping:
Unfortunatly I have not yet found good keybindings to suggest as I have a rather excentric [config](https://github.com/dvdsk/new-linux-setup/tree/master/vim).

Setting up a simple keybinding
```lua
local opt = { noremap = true, silent = true, nowait = true }
vim.api.nvim_set_keymap("n", ",", "lua require('prosesitter').next()", opt)
```

A more complicated example:
```lua
-- if there was a linting error on the current cursor
-- position open a popup, otherwise show the lsp hover 
-- documentation
function Hover()
	if not require('prosesitter').popup() then
		vim.lsp.buf.hover()
	end
end

local cmd = ":lua Hover()<CR>"
local opt = { noremap = true, silent = true, nowait = true }
vim.api.nvim_set_keymap("n", ",", cmd, opt)
```

#### User command
You might not want to switch style too often, thus command can be more suitable then a keybind. You can set one up like this:
```lua
vim.cmd(':command EmailStyle lua require("prosesitter").switch_vale_cfg("~/Documents/vale_mail.ini")')
```

### Future work
 - support for more queries (PR's are welcome!)
 - allow easy switching between linting comments, strings and comments and strings
 - making linting strings more practical by filtering out urls and paths
 - languagetool support for grammer checking
 - ability to hide a specific error
 - function to try and automatically fix an issue

### Related work
If you like this plugin you might also be intrested in:

 - language tool
 - ale
 - [spellsitter](), the inspiration for this plugin and a great alternative if you are just looking for spellchecking comments

