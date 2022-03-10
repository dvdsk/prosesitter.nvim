local defaults = require "prosesitter.config.defaults"
local q = require "vim.treesitter.query"
local prep = require "prosesitter.preprocessing.preprocessing"
local lintreq = require "prosesitter.linter.lintreq"

local function emphasis_buffer(buf)
    local content = {
    [[1nd paragraph. *Italic*, **bold**, and `monospace` ]],
    [[    ]],
    [[2nd paragraph _italics_ or __bold__ ]],
    [[    ]],
    }
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
end

local function docstring_buffer(buf)
    local content = {
    [[    """]], -- indented python docstring
    [[        Multi line string with errors in them.]],
    [[        Has lines! Multiple even! Test.]],
    [[    """]],
    }
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
end

FakeReq = { list = {} }
function FakeReq:add(_, text, row, start_col)
    self.list[#self.list + 1] = { text = text, row = row, start_col = start_col }
end

local buf = vim.api.nvim_create_buf(false, false)

describe("preprocessing", function()
    after_each(function()
        vim.api.nvim_buf_delete(buf, { force = true })
        buf = vim.api.nvim_create_buf(false, false)
    end)

	it("markdown emphasis stripping", function()
		emphasis_buffer(buf)
		vim.bo[buf].filetype = "markdown"
        local ok, parser = pcall(vim.treesitter.get_parser, buf)
        assert(ok, "failed to get parser")

        local query_str = defaults.queries.markdown.strings
        local query = q.parse_query(parser:lang(), query_str)

        local tree = parser:trees()[1]
        local root = tree:root()

		local req = lintreq.new()
		local prepfn = prep.get_fn("markdown")
        for _, node, meta in query:iter_captures(root, buf, 0, -1) do
			prepfn(buf, node, meta, req)
        end
		local text = table.concat(req.text, "")
		print(text)
	end)

    -- it("python docstring offset range", function()
    --     docstring_buffer(buf)
    --     vim.bo[buf].filetype = "python"
    --     local ok, parser = pcall(vim.treesitter.get_parser, buf)
    --     assert(ok, "failed to get parser")

    --     local query_str = defaults.queries.python.docstrings
    --     local query = q.parse_query(parser:lang(), query_str)

    --     local tree = parser:trees()[1]
    --     local root = tree:root()

    --     for _, node, meta in query:iter_captures(root, buf, 0, -1) do
    --         assert.are.same({ 0, 7, 3, 4 }, { prep.range(node, meta) })
    --     end
    -- end)

   --  it("python docstring offset preprocessing", function()
   --      docstring_buffer(buf)
   --      vim.bo[buf].filetype = "python"
   --      local ok, parser = pcall(vim.treesitter.get_parser, buf)
   --      assert(ok, "failed to get parser")

   --      local query_str = defaults.queries.python.docstrings
   --      local query = q.parse_query(parser:lang(), query_str)

   --      local tree = parser:trees()[1]
   --      local root = tree:root()

   --      local add_node = prep.get_fn("python")
   --      for _, node, meta in query:iter_captures(root, buf, 0, -1) do
   --          add_node(buf, node, meta, FakeReq)
   --      end

   --      assert.are.same({ {
   -- row = 0,
   -- start_col = 8,
   -- text = ""
   --                        }, {
   -- row = 1,
   -- start_col = 1,
   -- text = "        Multi line string with errors in them."
   --                        }, {
   -- row = 2,
   -- start_col = 1,
   -- text = "        Has lines! Multiple even! Test."
   --                        }, {
   -- row = 3,
   -- start_col = 1,
   -- text = "    "
   --                        } }, FakeReq.list)
   --  end)
end)
