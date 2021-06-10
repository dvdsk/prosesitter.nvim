-- list of installable lang-servers
-- https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md
--
local M = {}
local lsp = require 'lspconfig'

vim.lsp.set_log_level("debug")

-- on attach is not used right now but could be used by other
-- plugins in the future
function M.setup(on_attach)
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	capabilities.textDocument.completion.completionItem.snippetSupport = true

	lsp.rust_analyzer.setup({
		on_attach=on_attach,
		capabilities = capabilities,
		settings = {
			["rust-analyzer"] = {
				assist = {
					importMergeBehavior = "last",
					importGranularity = "module",
					importPrefix = "by_self",
				},
				cargo = {
					loadOutDirsFromCheck = true
				},
				procMacro = {
					enable = true
				},
			}
		}
	})

	lsp.pylsp.setup{ on_attach=on_attach }   -- python
	lsp.texlab.setup{ on_attach=on_attach } -- latex
	lsp.bashls.setup{ on_attach=on_attach } -- bash
	lsp.clangd.setup({  -- c++ and c
		on_attach=on_attach,
		filetypes={ "c", "cpp", "cc" },
	})
end

M.setup()
