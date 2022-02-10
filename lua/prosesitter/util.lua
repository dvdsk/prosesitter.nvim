local log = require("prosesitter/log")

M = {}

M.plugin_path = vim.fn.stdpath("data") .. "/prosesitter"

function M:shell_in_new_window(bash_script, ok_msg, err_msg)
	local ok = nil
	local function on_exit(_, code)
		print("done")
		if code ~= 0 then
			ok = true
			error(err_msg)
		else
			ok = false
			print(ok_msg)
		end
	end

	vim.cmd("new")
	local shell = vim.o.shell
	vim.o.shell = "/usr/bin/env bash"
	vim.fn.termopen(bash_script, { cwd = self.plugin_path, on_exit = on_exit })
	vim.o.shell = shell
	vim.cmd("startinsert")
	return ok
end

function M:resolve_path(cfg_bin, exe_name)
	local ok = 1
	-- check any user set bin path
	if cfg_bin ~= false then
		if vim.fn.filereadable(cfg_bin) == ok then
			return cfg_bin
		end
	end

	if vim.fn.exepath(exe_name) ~= "" then
		return exe_name
	end

	local plugin_installed_path = self.plugin_path .. "/"..exe_name
	if vim.fn.filereadable(plugin_installed_path) == ok then
		return plugin_installed_path
	end

	return nil
end

function string.starts(hay, needle)
	return string.sub(hay, 1, string.len(needle)) == needle
end

function M.array_remove(t, fnKeep)
    local j, n = 1, #t;

    for i=1,n do
        if (fnKeep(t, i, j)) then
            -- Move i's kept value to j's position, if it's not already there.
            if (i ~= j) then
                t[j] = t[i];
                t[i] = nil;
            end
            j = j + 1; -- Increment position of where we'll place the next kept value.
        else
            t[i] = nil;
        end
    end
    return t;
end

function M.array_concat(a,b)
	for _, v in ipairs(b) do
		a[#a+1] = v
	end
	return a
end

-- credits: refactoring.nvim
function M.split_string(inputstr, sep)
    local t = {}
    -- [[ lets not think about the edge case there... --]]
    while #inputstr > 0 do
        local start, stop = inputstr:find(sep)
        local str
        if not start then
            str = inputstr
            inputstr = ""
        else
            str = inputstr:sub(1, start - 1)
            inputstr = inputstr:sub(stop + 1)
        end
        table.insert(t, str)
    end
    return t
end

return M
