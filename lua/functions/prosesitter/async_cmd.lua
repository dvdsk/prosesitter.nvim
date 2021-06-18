local M = {}
local log = require("functions/prosesitter/log")
local loop = vim.loop

local output = ""
local function on_stdout(err, data)
	if err then
		log.error(err)
	end
	-- log.info(vim.inspect(data))
	output = output .. data
end

local function on_stderr(err, data)
	if err then
		log.error(err)
	end
	log.error(data)
end

local handle
-- function M.dispatch_with_stdin(input, cmd, args, user_callback)
-- 	-- create file descriptors not used for inter process comm
-- 	local stdin = loop.new_pipe(true)
-- 	log.info("stdin: "..vim.inspect(stdin))
-- 	-- loop.write(stdin, input) -- queue input for cmd
-- 	-- loop.stream_set_blocking(stdin, true)
-- 	-- loop.write(stdin, "hello world", function() log.info("wrote data") end) -- queue input for cmd
-- 	-- loop.shutdown(stdin, function() log.info("shutting down") end) -- wait for data to write and close write end

-- 	local stdout = loop.new_pipe(true)
-- 	local stderr = loop.new_pipe(true)
-- 	loop.read_start(stdout, vim.schedule_wrap(on_stdout))
-- 	loop.read_start(stderr, vim.schedule_wrap(on_stderr))

-- 	local pid
-- 	log.info("spawn time")
-- 	handle, pid = loop.spawn(cmd, {
-- 		args = {},
-- 		stdio = { stdin, stdout, stderr },
-- 	}, vim.schedule_wrap(function(code, signal) -- callback once the cmd has completed
-- 		log.info("code: "..code.." signal: "..signal)
-- 		stdout:read_stop()
-- 		stderr:read_stop()
-- 		stdin:close()
-- 		stdout:close()
-- 		stderr:close()
-- 		handle:close()
-- 		user_callback(output)
-- 	end))

-- 	loop.write(stdin, "hllo world")--, vim.schedule_wrap(function() log.info("wrote data") end))
-- 	loop.shutdown(stdin)--, vim.schedule_wrap(function() log.info("shutting down") end)) -- wait for data to write and close write end
-- end

local uv = loop
function M.dispatch_with_stdin(input, cmd, args, user_callback)
	local stdin = uv.new_pipe(false)
	local stdout = uv.new_pipe(false)
	local stderr = uv.new_pipe(false)

	print("stdin", stdin)
	print("stdout", stdout)
	print("stderr", stderr)

	local handle, pid = uv.spawn("vale", {
	  stdio = {stdin, stdout, stderr}
	}, function(code, signal) -- on exit
	  print("exit code", code)
	  print("exit signal", signal)
	end)

	print("process opened", handle, pid)

	uv.read_start(stdout, vim.schedule_wrap(function(err, data)
	  assert(not err, err)
	  if data then
		log.info("stdout chunk", stdout, data)
	  else
		print("stdout end", stdout)
	  end
	end))

	uv.read_start(stderr, function(err, data)
	  assert(not err, err)
	  if data then
		print("stderr chunk", stderr, data)
	  else
		print("stderr end", stderr)
	  end
	end)

	uv.write(stdin, "Hllo World")

	uv.shutdown(stdin, function()
	  print("stdin shutdown", stdin)
	  uv.close(handle, function()
		print("process closed", handle, pid)
	  end)
	end)
end


return M


