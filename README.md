# prosesitter

Prosesitter uses treesitter and vale to bring true syntax aware prose linting to neovim

## What is Prosesitter?
prosesitter.nvim is a text linting tool that adds grammar, spell and style checking to your comments and strings. It uses [language tool](https://github.com/languagetool-org/languagetool) and [vale](https://github.com/errata-ai/vale) as backends to check what you write for problems. Style issues can vary using the passive voice, weasle words ('very' unique) to using noninclusive terms. You  set your own style or use an existing one. Prosesitter will offer to setup a self contained install of language tool and vale including some defaults styles from the vales [style libary](https://github.com/errata-ai/styles). 

[![asciicast](https://asciinema.org/a/2AEBoLsLD2W6mNYjh0mMXUVWG.svg)](https://asciinema.org/a/2AEBoLsLD2W6mNYjh0mMXUVWG?speed=2)

### Features
 - Low performance impact; backends are called asynchronously and only when needed with only the text that changed.
 - Portable; written in lua and depends only on the backends, offers to install them if not found.
 - Configurable; specify exactly what you want to lint for which language, switch between prose style without reloading.
 - Can supports any language with a treesitter parser; (you might need to add your own query if I have not yet added one [adding queries](adding_queries.md)). Out of the box support for: latex, bash, lua, python, rust, c, and c++.
 - Telescope integration.

### Requirements
 - neovim > 0.5
 - treesitter set up
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

or pass a (partial)configuration; setting up your own vale binary, vale config and or adding extra treesitter queries (see [adding queries](adding_queries.md))
```lua
require("telescope").load_extension("prosesitter") -- Optionally, depends on telescope.nvim
require("prosesitter"):setup({
	vale_bin = vim.fn.stdpath("data") .. "/prosesitter/vale",
	vale_cfg = vim.fn.stdpath("data") .. "/prosesitter/vale_cfg.ini",
	-- override default behaviour for a languag
	ext = {
		py = {
			queries = {
				strings = "[(string) ] @capture",
				comments = "[(comment)+ ] @capture",
			},
			lint_target = "both",
			disabled = false,
		},
		tex = {
			lint_target = "strings",
			disabled = false,
		},
		sh = {
			lint_target = "comments",
		},
	},
	-- highlight groups to use for lint errors, warnings and suggestions
	severity_to_hl = { error = "SpellBad", warning = "SpellRare", suggestion = "SpellCap" },
	auto_enable = true, -- do not start linting files on open (default = true)
	default_cmds = false, -- do not add commands (default = true)
})
```

### Usage
You can map/use either lua functions or commands, the following functions are availible:

 - `next`/`prev`: jump to the next/prev linting issue from the current cursor pos and show the error in a popup window
 - `popup`: show a popup window if there is a linting issue on the current cursor pos
 - `disable`: disables linting on change removing all added highlights 
 - `enable`: re-enable linting on change and lint all open (supported) buffers
 - `switch_vale_cfg`: switches to a different vale config, updates all highlights to reflect the change. Not availible as command, takes as argument the path to the vale config to use

 The functions `next`, `prev` and `popup` return a bool that is true if they could jump/open a popup window. Use this (for example) to create a single keymap for prosesitters popup and your lsps show documentation function.

The commands:
 - `PsNext`
 - `PsPrev`
 - `PsPopup`
 - `PsEnable`
 - `PsDisable`

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
In no paticular order I would like to add the following features:

 - ability to hide a specific error
 - support for more queries (PR's are welcome!)
 - allow easy switching between linting comments, strings and comments and strings
 - making linting strings more practical by filtering out urls and paths
 - function to try and automatically fix an issue

### Trouble shooting
 - Do you have a treesitter parser installed for the file you want to prose lint? Try installing one with `TSInstall` \<tab to autocomplete\>.
 - If the treesitter parser is crashing it can help to update it to the latest version with `TSInstall update`

### Related work
If you like this plugin you might also be intrested in:

 - [spellsitter](https://github.com/lewis6991/spellsitter.nvim), the inspiration for this plugin and a great alternative if you are just looking for spellchecking comments
 - [ale](https://github.com/dense-analysis/ale) a asynchronous linting plugin that leaves syntax handling to the linters. Supports the default syntax vale supports (Markdown, AsciiDoc, reStructuredText, HTML, XML).
 - [vim-language](https://github.com/Konfekt/vim-langtool) collects all grammer mistakes into the quickfix list
 - [vim-grammarous](https://github.com/rhysd/vim-grammarous) grammar checker automatically downloads and sets up LanguageTool.
