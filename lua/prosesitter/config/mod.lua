local vale = require("prosesitter/backend/vale")
local langtool = require("prosesitter/backend/langtool")
local defaults = require("prosesitter/config/defaults")
local util = require("prosesitter/util")
local log = require("prosesitter/log")

local function layer_on_top(foreground, background)
	if background == nil then
		return foreground
	end

	for key, _ in pairs(foreground) do
		background[key] = foreground[key]
	end
	return background
end

local Cfg = {
	timeout = 500,
	severity_to_hl = { error = "SpellBad", warning = "SpellRare", suggestion = "SpellCap" },
	vale_bin = nil,
	vale_cfg = util.plugin_path .. "/vale_cfg.ini",
	langtool_bin = nil,
	langtool_port = 34287, -- just a random port thats probably free
	langtool_cfg = util.plugin_path .. "/langtool.cfg",
	default_cmds = true,
	auto_enable = true,
	-- keyed by file_extention a subtable of queries,
	-- disabled and of lint target
	filetype = nil,
}

local queries = defaults.queries
local newline = string.char(10)
function M.build_query(lint_targets, filetype)
	local list = {}
	for _, target in ipairs(lint_targets) do
		if queries[filetype][target] ~= nil then
			list[#list + 1] = queries[filetype][target]
		end
	end
	return table.concat(list, newline)
end

function Cfg:adjust_cfg(user_cfg)
	if user_cfg == nil then
		return
	end

	for key, _ in pairs(user_cfg) do
		self[key] = user_cfg[key]
	end

	self.filetype = defaults:filetype()
	if user_cfg.filetype ~= nil then
		for type, conf in pairs(user_cfg.filetype) do
			if conf.queries ~= nil then
				queries[type] = layer_on_top(conf.queries, queries[type])
			end
			if conf.ig_langtool_rules == nil then
				conf.ig_langtool_rules = ""
			end
			self.filetype[type] = layer_on_top(conf, self.filetype[type])
		end
	end
end

function M:setup(user_cfg)
	Cfg:adjust_cfg(user_cfg)

	local setup_vale = false
	Cfg.vale_bin = util:resolve_path(Cfg.vale_bin, "vale")
	if Cfg.vale_bin == nil then
		local do_setup = vim.fn.input("vale is not installed, install vale? y/n: ")
		if do_setup == "y" then
			setup_vale = true
		else
			print("please set 'vale_bin = false' in prosesitter plugin")
		end
	end

	local setup_langtool = false
	Cfg.langtool_bin = util:resolve_path(Cfg.langtool_bin, "languagetool/languagetool-server.jar")
	if Cfg.langtool_bin == nil then
		local do_setup = vim.fn.input("Language tool not installed, install language tool? y/n: ")
		if do_setup == "y" then
			setup_langtool = true
		else
			print("please set 'langtool_bin = false' in prosesitter plugin")
		end
	end

	if setup_langtool then
		langtool.setup_binairy()
		langtool.setup_cfg()
	end
	if setup_vale then
		vale.setup_binairy_and_styles()
		vale.setup_cfg()
	end

	return Cfg
end

function M.add_cmds()
	for name, fname in pairs(defaults.cmds) do
		vim.cmd(":command " .. name .. ' lua require("prosesitter").' .. fname .. "()<CR>")
	end
end

return M
