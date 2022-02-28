local defaults = require "prosesitter.config.defaults"
local q = require "vim.treesitter.query"

local function fill_buffer(buf)
    local content = {
    [[    """]], -- indented python docstring
    [[        Multi line string with errors in them.]],
    [[        Has lines! Multiple even! Test.]],
    [[    """]],
    }
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
end

local buf = vim.api.nvim_create_buf(false, false)

describe("preprocessing", function()
    after_each(function()
        vim.api.nvim_buf_delete(buf, { force = true })
        buf = vim.api.nvim_create_buf(false, false)
    end)

    it("python docstring offset", function()
        fill_buffer(buf)
        vim.bo[buf].filetype = "python"
		local ok, parser = pcall(vim.treesitter.get_parser, buf)
		assert(ok, "failed to get parser")

		local query_str = defaults.queries.python.docstrings
		local query = q.parse_query(parser:lang(), query_str)

        local tree = parser:trees()[1]
		local root = tree:root()
		for _, _, meta in query:iter_captures(root, buf, 0, -1) do
			assert.are.same({0,7,3,4}, meta.content[1])
		end
    end)
end)
