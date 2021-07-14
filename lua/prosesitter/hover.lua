local log = require("prosesitter/log")
local api = vim.api

local shared = nil
local win = nil
M = {}

function M.add_meta(id, meta)
	shared.mark_to_hover[id] = meta
end

function M.setup(_shared)
	shared = _shared
end

-- open hover window if lint error on current pos
-- else return false
function M.popup()
	local row, col = unpack(api.nvim_win_get_cursor(0))
	local start = { row, col - 5 } -- TODO these bounds should be smarter
	local stop = { row, col + 5 }
	local es = api.nvim_buf_get_extmarks(0, shared.ns_marks, start, stop, { limit = 1 }) -- TODO improve this
	log.info(vim.inspect(es))
	local id = es[1][1]

	local text = shared.mark_to_hover[id]

	local buf = api.nvim_create_buf(false, true)
	api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	api.nvim_buf_set_lines(buf, 0, -1, false, { text })
	-- https://dev.to/2nit/how-to-write-neovim-plugins-in-lua-5cca

	local opt = {
		style = "minimal",
		relative = "cursor",
		width = 20,
		height = 2,
		row = 0,
		col = 0,
	}

	if win == nil then
		win = api.nvim_open_win(0, false, opt) --	TODO see if there is dep for this
	end

	-- TODO how to exit win
end

return M
