local lintreq = require("prosesitter/linter/lintreq")
local state = require("prosesitter/state")

local buf = vim.api.nvim_create_buf(false, false)

local function fill_single_line(buf)
    local content = {
  [[each word a lintreq]],
    }
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
end

-- DISABLED as not currently working, needs to be implemented still
-- describe("lintreq spacing", function()
-- 	it("single row", function()
-- 		fill_single_line(buf)
-- 		local lr = lintreq.new()
-- 		lr:add(buf, "each ", 0, 0)
-- 		lr:add(buf, "word ", 0, 6)
-- 		lr:add(buf, "a lintreq ", 0, 12)
--         local req = lr:build()
--         assert.are.equal("each word a lintreq", req.text)
-- 	end)
-- end)

local function fill()
    local content = {
  [[    hi]],
  [[     hello how are you]],
    }
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
end

describe("lintreq duplication", function()
    after_each(function()
        vim.api.nvim_buf_delete(buf, { force = true })
        buf = vim.api.nvim_create_buf(false, false)
    end)

    it("basic", function()
        local lr = lintreq.new()
        fill()
        lr:add(buf, "hi", 0, 4)
        lr:add(buf, "hello how are you", 1, 5 + 1)
        local req = lr:build()
        assert.are.equal(req.text, "hi hello how are you")
    end)

    it("overwrite part of lintreq", function()
        local lr = lintreq.new()
        fill()

        lr:add(buf, "hi", 0, 4)
        lr:add(buf, "hello how are you", 1, 5 + 1)

        vim.api.nvim_buf_set_lines(buf, 1, 2, false, { "     hello you are you" })
        vim.api.nvim_buf_del_extmark(buf, state.ns_placeholders, 2)
        vim.api.nvim_buf_set_extmark(buf, state.ns_placeholders, 1, 0, { end_col = 0, id = 2 })
        lr:add(buf, "you", 1, #"     hello")

        local req = lr:build()
        assert.are.equal("hi hello you are you", req.text)
    end)
end)
