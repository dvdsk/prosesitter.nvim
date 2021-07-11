local log = require("prosesitter/log")
local api = vim.api

M = {}
M.mark_to_meta = nil

function M:add_meta(id, meta)
	self.mark_to_meta[id] = meta
end

function M:setup()
	self.mark_to_meta = {}
end

-- open hover window if lint error on current pos
-- else return false
function popup()
	local row, col = api.nvim_win_get_cursor(0)
	local es = api.nvim_buf_get_extmarks(bufnr, M.ns, {row,col-1}, {row,col+1}, {limit=1})
	local id = es[1][1]

	local meta = M.self.to_meta[id]
	local opt = { relative='cursor', }
	api.nvim_open_win(0, false, opt) --	TODO see if there is dep for this
	

end
