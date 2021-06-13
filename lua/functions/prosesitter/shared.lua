local M = {}
M.cfg = { captures = { "comment" } } -- module global config and namespace
M.ns = nil

function M.prose_check_iter(text)
	local result = vim.fn.system('vale --config .vale.ini --output=JSON --ext=".md"', text)
	local problems = vim.fn.json_decode(result)["stdin.md"]
	local i = 0

	return function() -- lua iterator
		while i <= #problems do
			i = i + 1
			print(vim.inspect(problems[i]))
			return unpack(problems[i]["Span"])
		end
	end
end

function M:setup()
	self.ns = vim.api.nvim_create_namespace("prosesitter")
end



return M
