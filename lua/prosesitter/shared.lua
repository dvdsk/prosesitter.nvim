local log = require("prosesitter/log")
local defaults = require("prosesitter/defaults")
local install = require("prosesitter/install")
local plugin_path = vim.fn.stdpath("data") .. "/prosesitter"

local M = {}

M.buf_query = {}
local Cfg = {
	vale_to_hl = { error = "SpellBad", warning = "SpellRare", suggestion = "SpellCap" },
	vale_bin = false,
	vale_cfg = plugin_path .. "/vale_cfg.ini",
	default_cmds = true,
	auto_enable = true,
	disabled_ext = {}, -- empty so nothing disabled
	queries = defaults.queries,
	lint_target = defaults.lint_target,
}
M.cfg = Cfg

MarkToMeta = { m = {} }
function MarkToMeta:add(id, meta)
	local buf = vim.api.nvim_get_current_buf()
	if self.m[buf] == nil then
		self.m[buf] = {}
	end
	self.m[buf][id] = meta
end

function MarkToMeta:by_id(id)
	local buf = vim.api.nvim_get_current_buf()
	return self.m[buf][id]
end

function MarkToMeta:by_buf_id(buf, id)
	return self.m[buf][id]
end

function MarkToMeta:buffers()
	local list = {}
	for buf, _ in pairs(self.m) do
		list[#list + 1] = buf
	end
	return list
end

M.mark_to_meta = MarkToMeta
M.ns_placeholders = nil

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

	for _, lang in ipairs(user_cfg.disabled_ext) do
		self.disabled_ext[lang] = true
	end
end

function M:setup(user_cfg)
	self.cfg:adjust_cfg(user_cfg)

	if not self:vale_installed() then
		local do_setup = vim.fn.input("Vale is not installed, install vale? y/n: ")
		if do_setup == "y" then
			install.binairy_and_styles()
			install.default_cfg()
		else
			print("please setup vale manually and adjust your config")
			return false
		end
	end

	M.ns_vale = vim.api.nvim_create_namespace("prosesitter_vale")
	M.ns_langtool = vim.api.nvim_create_namespace("prosesitter_langtool")
	M.ns_placeholders = vim.api.nvim_create_namespace("prosesitter_placeholders")
	for _, hl in pairs(self.cfg.vale_to_hl) do
		hl = vim.api.nvim_get_hl_id_by_name(hl)
	end
	return true
end

function M:vale_installed()
	local ok = 1
	-- check any user set vale bin path
	if self.cfg.vale_bin ~= false then
		if vim.fn.filereadable(self.cfg.vale_bin) == ok then
			return true
		end
	end

	if vim.fn.exepath("vale") ~= "" then
		self.cfg.vale_bin = "vale"
		return true
	end

	local plugin_installed_vale_path = plugin_path .. "/vale"
	if vim.fn.filereadable(plugin_installed_vale_path) == ok then
		self.cfg.vale_bin = plugin_installed_vale_path
		return true
	end

	return false
end

function M.add_cmds()
	for name, fname in pairs(defaults.cmds) do
		vim.cmd(":command " .. name .. ' lua require("prosesitter").' .. fname .. "()<CR>")
	end
end

return M
