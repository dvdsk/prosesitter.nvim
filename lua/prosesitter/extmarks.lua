local function add_extmark(bufnr, lnum, start_col, end_col, hl)
	-- TODO: This errors because of an out of bounds column when inserting
	-- newlines. Wrapping in pcall hides the issue.

	local opt = {
		end_line = lnum,
		end_col = end_col,
		hl_group = hl,
		-- ephemeral = true, -- only keep for one draw
	}
	local ok, _ = pcall(api.nvim_buf_set_extmark, bufnr, M.ns, lnum, start_col, opt)
	if not ok then
		log.error("Failed to add extmark, lnum="..vim.inspect(lnum).." pos="..start_col)
	end
end
