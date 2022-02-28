-- local lintreq = require("prosesitter/linter/lintreq")
-- local state = require("prosesitter/state")

-- local function fill(buf)
--     local content = {
--   [[    hi]],
--   [[     hello how are you]],
--     }
--     vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
-- end

-- local buf
-- local function setup()
--     buf = vim.api.nvim_create_buf(false, false)
-- end

-- setup()
-- describe("lintreq", function()
--     after_each(function()
--         vim.api.nvim_buf_delete(buf, { force = true })
--         buf = vim.api.nvim_create_buf(false, false)
--     end)

--     it("basic", function()
--         local lr = lintreq.new()
--         fill(buf)
--         lr:add(buf, "hi", 0, 4)
--         lr:add(buf, "hello how are you", 1, 5 + 1)
--         local req = lr:build()
--         assert.are.equal(req.text, "hi hello how are you")
--     end)

--     it("overwrite part of lintreq", function()
--         local lr = lintreq.new()
--         fill(buf)

--         lr:add(buf, "hi", 0, 4)
--         lr:add(buf, "hello how are you", 1, 5 + 1)

--         vim.api.nvim_buf_set_lines(buf, 1, 2, false, { "     hello you are you" })
--         vim.api.nvim_buf_del_extmark(buf, state.ns_placeholders, 2)
--         vim.api.nvim_buf_set_extmark(buf, state.ns_placeholders, 1, 0, { end_col = 0, id = 2 })
--         lr:add(buf, "you", 1, #"     hello")

--         local req = lr:build()
--         assert.are.equal("hi hello you are you", req.text)
--     end)

--     -- it("add out of order", function()
--     --     local lr = lintreq.new()
--     --     fill(buf)
--     --     lr:add(buf, "how are you", 1, #"hello " + 5 + 1)
--     --     lr:add(buf, "hi", 0, 4)
--     --     lr:add(buf, "hello ", 1, #"     ")
--     --     local req = lr:build()
--     --     assert.are.equal("hi hello how are you", req.text)
--     --     print(req.text)
--     -- end)
-- end)
