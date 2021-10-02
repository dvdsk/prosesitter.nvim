local api = vim.api

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local action_state = require("telescope.actions.state")
local action_set = require("telescope.actions.set")
local log = require("prosesitter/log")
local M = {}

local function make_entries(shared)
	local entries = {}
	local buffer_marks = api.nvim_buf_get_extmarks(0, shared.ns_marks, 0, -1, { details = true })
	local curr_buf = vim.fn.bufnr("%")
	for _, mark in ipairs(buffer_marks) do
		local id = mark[1]
		entries[#entries + 1] = {
			text = shared.mark_to_hover[id],
			row = mark[2] + 1,
			start_col = mark[3],
			end_col = mark[4].end_col,
			id = mark[1],
			buf = curr_buf,
		}
	end
	return entries
end

local function buf_path(bufnr)
	local info = vim.fn.getbufinfo(bufnr)
	return info[1].name
end

local function fill_finder(shared)
	return finders.new_table({
		results = make_entries(shared),
		entry_maker = function(entry)
			return {
				value = entry,
				display = entry.text,
				ordinal = entry.text,
				path = buf_path(entry.buf),
				lnum = entry.row,
				start = entry.start_col,
				finish = entry.end_col,
			}
		end,
	})
end

function M.find(shared)
	local opts = {}
	pickers.new(opts, {
		prompt_title = "ProseSitter Lints",
		finder = fill_finder(shared),
		sorter = conf.generic_sorter(opts),
		previewer = conf.qflist_previewer(opts),
		attach_mappings = function()
			action_set.select:enhance({
				post = function()
					local selection = action_state.get_selected_entry()
					vim.api.nvim_win_set_cursor(0, { selection.lnum, selection.start + 1 })
					local cb = function()
						vim.lsp.util.open_floating_preview({ selection.display }, "markdown", {})
					end
					vim.schedule(cb)
				end,
			})
			return true
		end,
	}):find()
end

return M
