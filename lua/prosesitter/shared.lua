local M = {}

local latex = {
	captures = {
		"type",
		"include",
		"punctuation.bracket",
		"punctuation.delimiter",
		-- "functions.macro",
		"function.macro",
		"text.environment.name",
		"text.environment",
		"_name",
		"parameter",
	},
	mode = "hl_deny",
}

local rust = {
	mode = "query",
}

M.cfg = {
	by_buf = {},
	by_ext = { tex = latex, rs = rust },
	default = { captures = { "comment" }, mode = "hl_allow" },
	vale_to_hl = { error = "SpellBad", warning = "SpellRare", suggestion = "SpellCap" },
}

M.mark_to_hover = {}
M.ns_placeholders = nil
M.ns_marks = nil

function M:setup()
	M.ns_marks = vim.api.nvim_create_namespace("prosesitter_marks")
	M.ns_placeholders = vim.api.nvim_create_namespace("prosesitter_placeholders")
	for _, hl in pairs(self.cfg.vale_to_hl) do
		hl = vim.api.nvim_get_hl_id_by_name(hl)
	end
end

return M
