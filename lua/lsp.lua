-- list of installable lang-servers
-- https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md
--
local M = {}
local lsp = require("lspconfig")

vim.lsp.set_log_level("debug")

local function lua_lsp(lsp, on_attach)
	local lsp_root = vim.fn.system("echo -n $HOME/.local/share/lua-language-server")
	local lsp_binary = lsp_root .. "/bin/Linux/lua-language-server"
	lsp.sumneko_lua.setup({
		on_attach = on_attach,
		cmd = { lsp_binary, "-E", lsp_root .. "/main.lua" },
		settings = {
			Lua = {
				runtime = {
					version = "LuaJIT",
					path = vim.split(package.path, ";"),
				},
				diagnostics = {
					globals = { "vim" }, -- Get the language server to recognize the `vim` global
				},
				workspace = {
					library = { -- Make the server aware of Neovim runtime files
						[vim.fn.expand("$VIMRUNTIME/lua")] = true,
						[vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
					},
				},
				telemetry = {
					enable = false,
				},
			},
		},
	})

	-- this autoformatter only works when the code is
	-- compiling fine... its the best we can do now
	-- this is not an issue of the formatter, it works fine
	-- from the terminal
	lsp.efm.setup({
		init_options = { documentFormatting = true },
		filetypes = { "lua" },
		settings = {
			rootMarkers = { ".git/" },
			languages = {
				lua = {
					{
						formatCommand = "stylua -",
						formatStdin = true,
					},
				},
			},
		},
	})
end

-- on attach is not used right now but could be used by other
-- plugins in the future
function M.setup(on_attach)
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	capabilities.textDocument.completion.completionItem.snippetSupport = true

	lsp.rust_analyzer.setup({
		on_attach = on_attach,
		capabilities = capabilities,
		settings = {
			["rust-analyzer"] = {
				assist = {
					importMergeBehavior = "last",
					importGranularity = "module",
					importPrefix = "by_self",
				},
				cargo = {
					loadOutDirsFromCheck = true,
				},
				procMacro = {
					enable = true,
				},
			},
		},
	})

	lsp.pylsp.setup({ on_attach = on_attach }) -- python
	lsp.texlab.setup({ on_attach = on_attach }) -- latex
	lsp.bashls.setup({ on_attach = on_attach }) -- bash
	lua_lsp(lsp, on_attach)
	lsp.clangd.setup({ -- c++ and c
		on_attach = on_attach,
		filetypes = { "c", "cpp", "cc" },
	})
end

M.setup()
