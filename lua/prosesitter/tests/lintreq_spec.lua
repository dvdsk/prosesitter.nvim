local lintreq = require("prosesitter/linter/lintreq")
local state = require("prosesitter/state")

local function fill(buf, lr)
    lr:add(buf, "hi", 0, 4)
    local test_str = "hello there"
    lr:add(buf, test_str, 1, 5)
    lr:add(buf, "how are you", 1, 5 + 1 + #test_str)

    local content = {
  [[    hi]],
  [[     hello how are you")]],
    }
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
end

local bufnr
local function setup()
    bufnr = vim.api.nvim_create_buf(false, false)
    state.ns = vim.api.nvim_create_namespace("test_lintreq")
end

setup()
describe("lintreq", function()
    it("add overlapping within same callback", function()
        local lr = lintreq.new()
        fill(bufnr, lr)
        lr:add(bufnr, "there", 1, 5 + 6)
    end)
end)
