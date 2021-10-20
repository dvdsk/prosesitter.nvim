local M = {}

local fn_by_ext = {}

local function default_fn(ranges, node)
	ranges[#ranges+1] = { node:range() }
end

function M.get_fn(extension)
	if fn_by_ext[extension] ~= nil then
		return fn_by_ext[extension]
	else
		return default_fn
	end
end

return M
