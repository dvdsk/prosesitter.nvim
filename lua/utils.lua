local M = {}
local cmd = vim.cmd

function M.create_augroup(autocmds, name)
    cmd('augroup ' .. name)
    cmd('autocmd!')
    for _, autocmd in ipairs(autocmds) do
        cmd('autocmd ' .. table.concat(autocmd, ' '))
    end
    cmd('augroup END')
end

function M.tcode(str)
	return vim.api.nvim_replace_termcodes(str, true, true, true)
end

-- TODO FIXME 
function M.update()
	local buf = nvim_get_current_buf()
	local mod = nvim_buf_get_var("modified")
	local name = nvim_buf_get_var("name")
	if mod then 
		if name == "%" then
			vim.api.nvim_command("browse confirm write")
		else 
			vim.api.nvim_command("confirm write")
		end
	end
end


return M
