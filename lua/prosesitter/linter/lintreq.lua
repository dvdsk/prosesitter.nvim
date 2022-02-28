local log = require("prosesitter/log")
local util = require("prosesitter/util")
local state = require("prosesitter/state")
local api = vim.api
local ns = state.ns_placeholders

local M = {}
M.__index = M -- failed table lookups on the instances should fallback to the class table, to get methods
function M.new()
    local self = setmetatable({}, M)
    -- an array
    self.text = {}
    -- key: placeholder_id,
    -- value: by idx tables of buf, id(same as key), row_col, idx
    self.meta_by_mark = {}
    -- key: index of corrosponding text in self.text (idx)
    -- value: table of buf, id, row_col, idx(same as key)
    self.meta_by_idx = {}
    return self
end

-- text can be empty list
-- needs to be passed 1 based start_col
function M:add_range(buf, lines, start_row, start_col)
    for i, text in ipairs(lines) do
        local row = start_row - 1 + i
        self:add(buf, text, row, start_col)
        start_col = 1
    end
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

function M:append_or_update(buf, id, text, start_col)
    local meta_list = self.meta_by_mark[id]

    local new = {
  buf = buf,
  id = id,
  col_start = start_col,
  col_end = start_col + #text,
  idx = #self.text + 1,
    }
    -- expand new if it overlaps with an existing range
    -- remove the existing range
    for idx, meta in pairs(meta_list) do
        if util.overlap(new, meta) then
            meta_list[idx] = nil
            self.meta_by_idx[idx] = nil
            self.text[idx] = nil

            update(new, meta)
            local row = api.nvim_buf_get_extmark_by_id(buf, ns, id, {})[1]
            text = api.nvim_buf_get_lines(buf, row, row + 1, true)
            text = text[1]
            text = string.sub(text, 1, new.col_end)
            text = string.sub(text, new.col_start)
        end
    end

    meta_list[new.idx] = new
    self.meta_by_idx[new.idx] = new
    self.text[new.idx] = text
end

function M:add(buf, text, row, start_col)
    local id = nil
    local marks = api.nvim_buf_get_extmarks(buf, ns, { row, 0 }, { row, 0 }, {})
    if #marks > 0 then
        id = marks[1][1] -- there can be a max of 1 placeholder per line
        assert(self.meta_by_mark[id] ~= nil, "should be a metadata entry for placeholder")
        self:append_or_update(buf, id, text, start_col)
        return
    else
        id = api.nvim_buf_set_extmark(buf, ns, row, 0, { end_col = 0 })
    end

	local idx = #self.text + 1
    local meta = { buf = buf, id = id, col_start = start_col,
                   col_end = start_col + #text, idx = idx }
    self.meta_by_mark[id] = {[idx] = meta}
    self.meta_by_idx[meta.idx] = meta
    self.text[meta.idx] = text
end

local function delete_by_idx(meta_by_mark, array, map)
    for idx, _ in pairs(meta_by_mark) do
        table.remove(array, idx)
        table.remove(map, idx)
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
            delete_by_idx(deleted, self.text, self.meta_by_idx)
        end
    end
end

function M:is_empty()
    local empty = next(self.text) == nil
    return empty
end

-- returns a request with members:
function M:build()
    local req = {}
    req.areas = {}

    -- TODO hide check under debug flag
    local meta_seen = {}
    for _, meta in pairs(self.meta_by_idx) do
        local hash = table.concat({ meta.buf, meta.id, meta.col_end, meta.col_start }, ",")
        if meta_seen[hash] ~= nil then
            local err = "lintreq contains overlapping/duplicate entries, (idx: "
                .. meta_seen[hash] .. ") and  (idx: " .. meta.idx .. ")"
				.. "\n lintreq dump: "..vim.inspect(self)
            assert(false, err)
        end
        meta_seen[hash] = meta.idx
    end

    local col = 0
	local text_list = {}
    for idx, text in pairs(self.text) do
        local meta = self.meta_by_idx[idx]
        local area = {
   col = col, -- column in text passed to linter
   row_col = meta.col_start, -- column in buffer
   row_id = meta.id, -- extmark at the start of the row
   buf_id = meta.buf,
        }
        req.areas[#req.areas + 1] = area
		text_list[#text_list+1] = text
        col = col + #text + 1 -- plus one for the line end
    end

    req.text = table.concat(text_list, " ")
    self:reset()
    return req
end

function M:reset()
    self.text = {}
    self.meta_by_mark = {}
    self.meta_by_idx = {}
end

return M
