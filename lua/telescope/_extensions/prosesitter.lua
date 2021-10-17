local api = vim.api

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local action_state = require("telescope.actions.state")
local action_set = require("telescope.actions.set")
local state = require("prosesitter/shared")
local marks = require("prosesitter/linter/marks/marks")
local log = require("prosesitter/log")

local function format(issue)
	return "["..issue.severity.."] "..issue.msg
end

local function add_buffer_entries(entries, buf)
	local buffer_marks = marks.get_marks(buf)
	for _, mark in ipairs(buffer_marks) do
		local id = mark[1]
		local issues = state.issues:for_buf_id(buf, id)
		for _, issue in ipairs(issues) do
			entries[#entries + 1] = {
				text = format(issue),
				row = mark[2] + 1,
				start_col = mark[3],
				end_col = mark[4].end_col,
				id = mark[1],
				buf = buf,
			}
		end
	end
end

local function make_entries(buffers)
	local entries = {}
	for _, buf in ipairs(buffers) do
		add_buffer_entries(entries, buf)
	end
	return entries
end

local function buf_path(bufnr)
	local info = vim.fn.getbufinfo(bufnr)
	return info[1].name
end

local function fill_finder(buffers)
	return finders.new_table({
		results = make_entries(buffers),
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

local function pick_lint(opts, buffers)
	pickers.new(opts, {
		prompt_title = "ProseSitter Lints",
		finder = fill_finder(buffers),
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

return require("telescope").register_extension({
	exports = {
		buf = function(opts)
			local curr_buf = api.nvim_get_current_buf()
			pick_lint(opts, {curr_buf})
		end,
		all = function(opts)
			local buffers = state:attached_buffers()
			pick_lint(opts, buffers)
		end,
	}
})
