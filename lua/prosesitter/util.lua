M = {}

M.plugin_path = vim.fn.stdpath("data") .. "/prosesitter"

function M.shell_in_new_window(bash_script, ok_msg, err_msg)
	local function on_exit(_, code)
		if code ~= 0 then
			error(err_msg)
		else
			print(ok_msg)
		end
	end

	vim.cmd("new")
	local shell = vim.o.shell
	vim.o.shell = "/usr/bin/env bash"
	vim.fn.termopen(bash_script, { cwd = M.plugin_path, on_exit = on_exit })
	vim.o.shell = shell
	vim.cmd("startinsert")
end

function M:installed(cfg_bin, exe_name)
	local ok = 1
	-- check any user set vale bin path
	if cfg_bin ~= false then
		if vim.fn.filereadable(cfg_bin) == ok then
			return true
		end
	end

	if vim.fn.exepath(exe_name) ~= "" then
		cfg_bin = exe_name
		return true
	end

	local plugin_installed_path = self.plugin_path .. "/"..exe_name
	if vim.fn.filereadable(plugin_installed_path) == ok then
		cfg_bin = plugin_installed_path
		return true
	end

	return false
end

return M
