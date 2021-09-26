local M = {}
local log = require("prosesitter/log")
local loop = vim.loop

local uv = loop
local handle

local function on_stderr(err, data)
	assert(not err, err)
	if data then
		print("stderr chunk", data)
	end
end

-- right now specialized for bufferd output
function M.dispatch_with_stdin(input, cmd, args, user_callback)
	local stdin = uv.new_pipe(false)
	local stdout = uv.new_pipe(false)
	local stderr = uv.new_pipe(false)

	local output
	handle, _ = uv.spawn(cmd, {
		args = args,
		stdio = { stdin, stdout, stderr },
	}, vim.schedule_wrap(function(_, _) -- on exit
		user_callback(output)
	end))

	uv.read_start(stdout, vim.schedule_wrap(function(err, data)
		assert(not err, err)
		if data then
			output = data
		elseif err then
			log.error("stdout err:", err)
		end
	end))

	uv.read_start(stderr, on_stderr)
	uv.write(stdin, input)
	uv.shutdown(stdin)
end

return M
