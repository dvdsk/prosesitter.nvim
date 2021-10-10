local async = require("prosesitter/on_event/check/async_cmd")
local lintreq = require("prosesitter/on_event/lintreq")
local marks = require("prosesitter/on_event/marks/marks")
local log = require("prosesitter/log")
local shared = require("prosesitter/shared")
local M = {}

M.schedualled = false
M.lintreq = nil
local cfg = nil
local job = nil

local id_to_severity = {
	CAPITALIZATION = "error",
	COLLOCATIONS = "warning",
	CONFUSED_WORDS = "warning",
	COMPOUNDING = "warning",
	CREATIVE_WRITING = "suggestion", -- not active by default
	GRAMMAR = "error",
	MISC = "warning",
	NONSTANDARD_PHRASES = "warning",
	PLAIN_ENGLISH = "suggestion", -- not active by default
	TYPOS = "error",
	PUNCTUATION = "warning",
	REDUNDANCY = "suggestion",
	SEMANTICS = "warning",
	STYLE = "suggestion", -- disabled by us
	TEXT_ANALYSIS = "suggestion", -- not active by default
	TYPOGRAPHY = "warning",
	CASING = "error",
	WIKIPEDIA = "suggestion", --not active by default
}

local function to_vale_format(json)
	local result = vim.fn.json_decode(json)["matches"]
	local vale_dict = {}
	for _, res in ipairs(result) do
		local item = {}
		item.Span = { res.offset + 1, res.offset + res.length }
		item.Severity = id_to_severity[res.rule.category.id]
		item.Message = res.message
		vale_dict[#vale_dict + 1] = item
	end
	return vale_dict
end

local function langtool_query(text)
	-- Disable whitespace rule (whitespace repetition checking) as comments are often formatted
	-- using whitespace. Disable style checking as we use vale for that.
	return "language=en-US&disabledCategories=STYLE&disabledRules=WHITESPACE_RULE&text=" .. text
end
local function do_check()
	M.schedualled = false
	local req = M.lintreq:build()

	if shared.langtool_running then
		local function post_langtool(json)
			local results = to_vale_format(json)
			marks.mark_langtool_results(results, req.areas)
		end
		local curl_args = { "--no-progress-meter", "--data", "@-", "http://localhost:8081/v2/check" }
		async.dispatch_with_stdin(langtool_query(req.text), "curl", curl_args, post_langtool)
	end

	if cfg.vale_bin ~= nil then
		local function post_vale(json)
			local results = vim.fn.json_decode(json)["stdin.md"]
			marks.mark_vale_results(results, req.areas)
		end
		local vale_args = { "--config", cfg.vale_cfg, "--no-exit", "--ignore-syntax", "--ext=.md", "--output=JSON" }
		async.dispatch_with_stdin(req.text, cfg.vale_bin, vale_args, post_vale)
	end
end

function M.cancelled_schedualled()
	if job ~= nil then
		job:stop()
		M.schedualled = false
	end
end

function M.schedual()
	local timeout_ms = 500 -- was 800
	job = vim.defer_fn(do_check, timeout_ms)
end

function M:setup(shared)
	cfg = shared.cfg
	lintreq.setup(shared)
	self.lintreq = lintreq.new()
end

function M:get_lintreq()
	return self.lintreq
end

function M:disable()
	self.lintreq:reset()
	self.cancelled_schedualled() -- stop any running async jobs
end

return M
