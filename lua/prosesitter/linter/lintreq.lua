local log = require("prosesitter/log")
local util = require("prosesitter/util")
local state = require("prosesitter/state")
local api = vim.api
local ns = state.ns_placeholders

local M = {}
M.__index = M -- failed table lookups on the instances should fallback to the class table, to get methods
function M.new()
    local self = setmetatable({}, M)
    -- key: placeholder_id,
    -- value: array with holes of tables of:
	-- 		buf,
	-- 		placeholder_id,
	-- 		col_start [zero based],
	-- 		col_end [zero based],
	-- sentinel value "deleted" is used to indicate
	-- holes (removed values)
    self.meta_by_mark = {}
    return self
end

-- given overlapping entries returns a single entry encompassing
-- the entire range
local function update(new, existing)
    if existing.col_start < new.col_start then
        new.col_start = existing.col_start
    end
    if existing.col_end > new.col_end then
        new.col_end = existing.col_end
    end
end

function M:append_or_update(buf, id, start_col, end_col)
    local meta_list = self.meta_by_mark[id]

    local new = {
  buf = buf,
  id = id,
  col_start = start_col,
  col_end = end_col,
    }
    -- expand new if it overlaps with an existing range
    -- remove the existing range
    for i, meta in util.hpairs(meta_list) do
        if meta.append_text == nil and util.overlap(new, meta) then
            meta_list[i] = "deleted" -- sentinel value
            update(new, meta)
        end
    end

    meta_list[#meta_list+1] = new
end

-- add text starting (including) start_col up till (excluding) end_col
-- col is zero indexed. Row is zero indexed
function M:add_row(buf, row, start_col, end_col)
    local id = nil
    local marks = api.nvim_buf_get_extmarks(buf, ns, { row, 0 }, { row, 0 }, {})
    if #marks > 0 then
        id = marks[1][1] -- there can be a max of 1 placeholder per line
        assert(self.meta_by_mark[id] ~= nil, "should be a metadata entry for placeholder")
        self:append_or_update(buf, id, start_col, end_col)
        return
    else
        id = api.nvim_buf_set_extmark(buf, ns, row, 0, { end_col = 0 })
    end

    local meta = { buf = buf, id = id, col_start = start_col,
                   col_end = end_col }
    self.meta_by_mark[id] = { meta }
end

-- add multiple rows of text starting at (including) start_col up till (excluding) end_col
-- col is zero indexed. Row is zero indexed
function M:add_rows(buf, start_row, end_row, start_col, end_col)
	assert(end_col ~= nil)
	for i = start_row, end_row-1, 1 do
		self:add_row(buf, i, start_col, 99999)
		start_col = 0
	end
	self:add_row(buf, end_row, start_col, end_col)
end

-- add a string to the text send to the spell/grammer checker. Any feedback from the
-- spell/grammer checker will be ignored. Usefull for adding spaces between lines or
-- for adding placeholders in text containing paths and urls.
function M:add_append_text(buf, row, text)
    local marks = api.nvim_buf_get_extmarks(buf, ns, { row, 0 }, { row, 0 }, {})
    if #marks > 0 then
        local id = marks[1][1] -- there can be a max of 1 placeholder per line
		local meta_list = self.meta_by_mark[id]
		meta_list[#meta_list+1] = { append_text = text}
	end
end

function M:clear_lines(buf, start, stop)
    local marks = api.nvim_buf_get_extmarks(buf, ns, { start, 0 }, { stop, 0 }, {})
    for i = #marks, 1, -1 do
        local mark = marks[i]
        local id = mark[1]
        local deleted = self.meta_by_mark[id]
        if deleted ~= nil then
            self.meta_by_mark[id] = {}
        end
    end
end

function M:is_empty()
    return #self.meta_by_mark == 0
end

-- TODO PERF hide check under debug flag
function M:assert_no_duplicate()
    local meta_seen = {}
    for mark, meta_list in pairs(self.meta_by_mark) do
		for _, meta in util.hpairs(meta_list) do
			if meta.append_text ~= nil then
				goto continue
			end

			local hash = table.concat({ mark, meta.buf, meta.id, meta.col_end, meta.col_start }, ",")
			if meta_seen[hash] ~= nil then
				local err = "lintreq contains overlapping/duplicate entries, (meta: "
					.. vim.inspect(meta_seen[hash]) .. ") and  (meta: " .. vim.inspect(meta) .. ")"
					.. "\n lintreq dump: "..vim.inspect(self)
				assert(false, err)
			end
			meta_seen[hash] = meta
			::continue::
		end
    end
end

-- TODO PERF hide check under debug flag
function M:assert_meta_lists_sorted()
	-- verify meta lists is sorted by column
	for mark, meta_list in pairs(self.meta_by_mark) do
		local col = 0
		for _, meta in util.hpairs(meta_list) do
			if meta.append_text ~= nil then
				goto continue
			end

			if meta.col_start < col then
				assert(false, "meta_list is for mark: "..mark.."not sorted: "..meta_list)
			end
			col = meta.col_start
			::continue::
		end
	end

end

-- returns a request with members:
function M:build()
	self:assert_no_duplicate()
	self:assert_meta_lists_sorted()

    local req = {}
    req.areas = {}
	req.text = {}

	local col = 0
	for mark, meta_list in pairs(self.meta_by_mark) do
		local buf = util.harray_get_first(meta_list).buf
		local row = api.nvim_buf_get_extmark_by_id(buf, state.ns_placeholders, mark, {})[1]
		local line = api.nvim_buf_get_lines(buf, row, row + 1, true)[1]

		for _, meta in util.hpairs(meta_list) do
			if meta.append_text then
				req.text[#req.text+1] = meta.append_text
				col = col + #meta.append_text
			else
				req.areas[#req.areas+1] = {
					col = col,
					row_col = meta.col_start,
					row_id = meta.id,
					buf_id = meta.buf,
				}

				req.text[#req.text+1] = string.sub(line, meta.col_start+1, meta.col_end)
				local length = meta.col_end - meta.col_start
				col = col + length -- why? why is this not before the req.areas?
			end
		end
	end

    self:reset()
	req.text = table.concat(req.text, "")
    return req
end

function M:reset()
    self.meta_by_mark = {}
end

return M
