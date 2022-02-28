-- Test setup adapted from refactoring.nvim ( refactoring.nvim/lua/refactoring/tests/refactor_spec.lua )

local Path = require("plenary.path")
local scandir = require("plenary.scandir")

local ps = require("prosesitter")
local util = require("prosesitter/util")
local test_util = require("prosesitter/tests/test_util")
local on_event = require("prosesitter/linter/on_event")
local state = require("prosesitter/state")

local cwd = vim.loop.cwd()
vim.cmd("set rtp+=" .. cwd)

local function remove_cwd(file)
	return file:sub(#cwd + 2 + #"lua/refactoring/tests/")
end

local function for_each_file(cb)
	local files = scandir.scan_dir(Path:new(cwd, "lua", "prosesitter", "tests"):absolute())
	for _, file in pairs(files) do
		file = remove_cwd(file)
		if string.match(file, "code") then
			cb(file)
		end
	end
end

local function read_file(file)
	return Path:new("lua", "prosesitter", "tests", file):read()
end

local function get_content(file)
	return util.split_string(read_file(file), "\n")
end

local function get_marks(file)
	local extension = file:match("^.+%.(.+)$")
	local dir = file:match("^(.+/).+$")
	local path = dir .. extension .. ".json"
	local json = read_file(path)
	return vim.fn.json_decode(json)
end

local extension_to_filetype = {
	["lua"] = "lua",
	["py"] = "python",
	["rs"] = "rust",
	["c"] = "c",
	["cpp"] = "cpp",
	["tex"] = "latex",
}
local function filetype(file)
	local parts = util.split_string(file, "%.")
	local extension = parts[2]
	local res = extension_to_filetype[extension]
	assert(res ~= nil, "filetype not in extension_to_filetype")
	return res
end

test_util.setup()

describe("Static", function()
	after_each(function()
		test_util.reset()
	end)

	for_each_file(function(file)
		it(string.format(": %s", file), function()
			assert.truthy("Pass.")

			if file ~= "static/simple/code.py" then
				return
			end

			local bufnr = vim.api.nvim_create_buf(false, false)
			vim.api.nvim_win_set_buf(0, bufnr)
			vim.bo[bufnr].filetype = filetype(file)
			local content = get_content(file)
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, content)

			local ok, err = ps.attach()
			assert.message(err).is_true(ok)

			local function check()
				return #state.issues.m[bufnr].langtool > 1
			end

			ok, _ = vim.wait(2500, check, 500, false)
			assert(ok, "languagetool check did not complete or resulted in zero issues")

			local details = vim.api.nvim_buf_get_extmarks(bufnr, state.ns_marks, 0, -1, { details = true })

			local marks = {}
			for _, mark in ipairs(details) do
				local id = mark[1]
				local issues = state.issues:for_buf_id(bufnr, id)
				marks[#marks + 1] = {
					row = mark[2],
					col_start = mark[3],
					col_end = mark[4].end_col,
					severity = issues:severity(),
					sources = issues:sources(),
				}
			end

			local correct_marks = get_marks(file)
			assert.are.same(correct_marks, marks)

			vim.api.nvim_buf_delete(bufnr, { force = true })
		end)
	end)
end)
