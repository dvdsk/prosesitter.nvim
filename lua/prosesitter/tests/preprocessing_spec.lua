local defaults = require "prosesitter.config.defaults"
local q = require "vim.treesitter.query"
local prep = require "prosesitter.preprocessing.preprocessing"
local util = require "prosesitter.preprocessing.util"
local lintreq = require "prosesitter.linter.lintreq"
local test_util = require("prosesitter.tests.test_util")

local function fill_buf(buf, path)
	local lines = test_util.lines("preprocessing/"..path)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

FakeReq = { list = {} }
function FakeReq:add(_, row, start_col, end_col)
    self.list[#self.list + 1] = { text = text, row = row, start_col = start_col, end_col = end_col }
end

local buf = vim.api.nvim_create_buf(false, false)
describe("preprocessing", function()
    after_each(function()
        vim.api.nvim_buf_delete(buf, { force = true })
        buf = vim.api.nvim_create_buf(false, false)
    end)

	it("minimal", function()
		fill_buf(buf, "minimal.md")
		vim.bo[buf].filetype = "markdown"

        local ok, parser = pcall(vim.treesitter.get_parser, buf)
        assert(ok, "failed to get parser")
		parser:parse()

        local query_str = defaults.queries.markdown.strings
        local query = q.parse_query(parser:lang(), query_str)

        local tree = parser:trees()[1]
        local root = tree:root()

		local lr = lintreq.new()
		local prepfn = prep.get_fn("markdown")
        for _, node, meta in query:iter_captures(root, buf, 0, -1) do
			prepfn(buf, node, meta, lr)
        end
		assert.are_same(0, lr.meta_by_mark[1][1].col_start, "first line should start at col 0")
        local req = lr:build()
		assert.are.same("1nd paragraph. Italic, bold, and code 2nd paragraph italics or bold ", req.text)
	end)

	it("basic emphasis", function()
		fill_buf(buf, "emphasis.md")
		vim.bo[buf].filetype = "markdown"
        local ok, parser = pcall(vim.treesitter.get_parser, buf)
        assert(ok, "failed to get parser")

        local query_str = defaults.queries.markdown.strings
        local query = q.parse_query(parser:lang(), query_str)

        local tree = parser:trees()[1]
        local root = tree:root()

		local lr = lintreq.new()
		local prepfn = prep.get_fn("markdown")
        for _, node, meta in query:iter_captures(root, buf, 0, -1) do
			prepfn(buf, node, meta, lr)
        end
        local req = lr:build()
		assert.are.same("1nd paragraph. Italic, bold and code 2nd paragraph italics or bold ", req.text)
	end)

	it("paragraphs", function()
		fill_buf(buf, "paragraphs.md")
		vim.bo[buf].filetype = "markdown"
        local ok, parser = pcall(vim.treesitter.get_parser, buf)
        assert(ok, "failed to get parser")

        local query_str = defaults.queries.markdown.strings
        local query = q.parse_query(parser:lang(), query_str)

        local tree = parser:trees()[1]
        local root = tree:root()

		local lr = lintreq.new()
		local prepfn = prep.get_fn("markdown")
        for _, node, meta in query:iter_captures(root, buf, 0, -1) do
			prepfn(buf, node, meta, lr)
        end
        local req = lr:build()
		assert.are.same("chapter Italics Paragraphs are separated by a blank line. 2nd paragraph. Italic, bold, and code. Itemized lists alternatively italics or bold look like:", req.text)
	end)

	it("inline links", function()
		fill_buf(buf, "links.md")
		vim.bo[buf].filetype = "markdown"
        local ok, parser = pcall(vim.treesitter.get_parser, buf)
        assert(ok, "failed to get parser")

        local query_str = defaults.queries.markdown.strings
        local query = q.parse_query(parser:lang(), query_str)

        local tree = parser:trees()[1]
        local root = tree:root()

		local lr = lintreq.new()
		local prepfn = prep.get_fn("markdown")
        for _, node, meta in query:iter_captures(root, buf, 0, -1) do
			prepfn(buf, node, meta, lr)
        end
        local req = lr:build()
		assert.are.same("Queries are language specific strings that tell the treesitter parser how to find the prose in code. They look like this: For prosesitter to be able to automatically merge string only and comment lint targets we need the outer square brackets even if there is only a single pattern cought by a query. To see how queries match text see the Treesitter documentation. around the query You can easily create new ones using Treesitter Playground with its query editor. To add one or more queries to prosesitter make a table of extensions and the query that should be used and add that table to your config during setup under the key code. If a query already exists for a file extension your new query will replace it. language tool rules: https://community.languagetool.org/rule/list?lang=en ", req.text)
	end)
end)
