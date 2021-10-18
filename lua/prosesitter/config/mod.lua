local vale = require("prosesitter/backend/vale")
local langtool = require("prosesitter/backend/langtool")
local defaults = require("prosesitter/config/defaults")
local util = require("prosesitter/util")
local log = require("prosesitter/log")

local function overlay_table(overlay, default)
	for ext, _ in pairs(overlay) do
		default[ext] = overlay[ext]
	end
	return default
end

local function add_merged_queries(queries)
	for _, q in pairs(queries) do
		if q.strings ~= nil and q.comments ~= nil then
			q.both = defaults.merge_queries(q)
		end
	end
end

local Cfg = {
	timeout = 500,
	severity_to_hl = { error = "SpellBad", warning = "SpellRare", suggestion = "SpellCap" },
	vale_cfg = util.plugin_path .. "/vale_cfg.ini",
	vale_bin = false,
	langtool_bin = false,
	langtool_port = 34287, -- just a random port thats probably free
	langtool_cfg = util.plugin_path .. "/langtool.cfg",
	default_cmds = true,
	auto_enable = true,
	disabled_ext = {}, -- empty so nothing disabled
	queries = defaults.queries,
	lint_target = defaults.lint_target,
}

function Cfg:adjust_cfg(user_cfg)
	if user_cfg == nil then
		return
	end

	for key, _ in pairs(user_cfg) do
		self[key] = user_cfg[key]
	end

	if user_cfg.queries ~= nil then
		add_merged_queries(user_cfg.queries)
		self.queries = overlay_table(user_cfg.queries, defaults.queries)
	end

	if user_cfg.lint_target ~= nil then
		self.lint_target = overlay_table(user_cfg.lint_target, defaults.lint_target)
	end

	if user_cfg.disabled ~= nil then
		self.disabled = overlay_table(user_cfg.disabled, self.disabled)
	end

	if user_cfg.disabled_ext ~= nil then
		for _, lang in ipairs(user_cfg.disabled_ext) do
			self.disabled_ext[lang] = true
		end
	end
end

function M:setup(user_cfg)
	Cfg:adjust_cfg(user_cfg)

	-- for now vale is not optional
	Cfg.vale_bin = util:resolve_path(Cfg.vale_bin, "vale")
	if Cfg.vale_bin == nil then
		local do_setup = vim.fn.input("vale is not installed, install vale? y/n: ")
		if do_setup == "y" then
			vale.setup_binairy_and_styles()
			vale.setup_cfg()
		else
			print("please setup vale manually and adjust your config")
			return nil
		end
	end

	-- for now langtool is not optional
	Cfg.langtool_bin = util:resolve_path(Cfg.langtool_bin, "languagetool/languagetool-server.jar")
	if Cfg.langtool_bin == nil then
		local do_setup = vim.fn.input("Language tool not installed, install language tool? y/n: ")
		if do_setup == "y" then
			langtool.setup_binairy()
			langtool.setup_cfg()
		else
			print("please set up language tool manually and adjust your config")
			return nil
		end
	end
	return Cfg
end

function M.add_cmds()
	for name, fname in pairs(defaults.cmds) do
		vim.cmd(":command " .. name .. ' lua require("prosesitter").' .. fname .. "()<CR>")
	end
end

return M
