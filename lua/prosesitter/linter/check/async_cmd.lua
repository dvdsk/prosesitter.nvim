local M = {}
local log = require("prosesitter/log")
local loop = vim.loop

local uv = loop

local function on_stderr(err, data)
	assert(not err, err)
	-- if data then
	-- 	log.error(data)
	-- end
end

-- right now specialized for bufferd output
function M.dispatch_with_stdin(input, cmd, args, user_callback)
	local stdin = uv.new_pipe(false)
	local stdout = uv.new_pipe(false)
	local stderr = uv.new_pipe(false)

	local output = {}
	local _, _ = uv.spawn(cmd, {
		args = args,
		stdio = { stdin, stdout, stderr },
	}, vim.schedule_wrap(function(_, _) -- on exit
		local string = table.concat(output, "")
		user_callback(string)
	end))

	uv.read_start(stdout, function(err, data)
		assert(not err, err)
		if data then
			output[# output+1] = data
		end
	end)

	uv.read_start(stderr, on_stderr)
	uv.write(stdin, input)
	uv.shutdown(stdin)
end

return M
