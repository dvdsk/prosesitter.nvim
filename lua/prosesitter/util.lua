local log = require("prosesitter/log")

M = {}

M.plugin_path = vim.fn.stdpath("data") .. "/prosesitter"

function M:shell_in_new_window(bash_script, ok_msg, err_msg)
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
	vim.fn.termopen(bash_script, { cwd = self.plugin_path, on_exit = on_exit })
	vim.o.shell = shell
	vim.cmd("startinsert")
end

function M:resolve_path(cfg_bin, exe_name)
	log.info(cfg_bin, exe_name)
	local ok = 1
	-- check any user set vale bin path
	if cfg_bin ~= false then
		if vim.fn.filereadable(cfg_bin) == ok then
			return cfg_bin
		end
	end

	if vim.fn.exepath(exe_name) ~= "" then
		return exe_name
	end

	local plugin_installed_path = self.plugin_path .. "/"..exe_name
	log.info(plugin_installed_path)
	if vim.fn.filereadable(plugin_installed_path) == ok then
		log.info("yo")
		return plugin_installed_path
	end

	return nil
end

return M
