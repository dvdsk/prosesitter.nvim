local state = require("prosesitter/shared")
local log = require("prosesitter/log")
local M = {}

local severity_as_int = {
	error = 4,
	warning = 3,
	suggestion = 2,
}

local function max_severity(issues)
	local max = 0
	local res = "should never be unset"
	for _, issue in pairs(issues) do
		local curr = severity_as_int[issue.severity]
		if curr > max then
			max = curr
			res = issue.severity
		end
	end
	return res
end

function M.hl_group(issues)
	local sev = max_severity(issues)
	return state.cfg.severity_to_hl[sev]
end

local function other(linter)
	if linter == "vale" then
		return "langtool"
	else
		return "vale"
	end
end

-- meta is a dict containing all kind of properties
-- m = buffer/linter/id/meta
-- then meta is a list of:
--
-- msg, severity, type, full_source, action
--
Issues = { m = {} }
function Issues:attach(buf)
	self.m[buf] = { vale = {}, langtool = {} }
end

function Issues:clear_meta_for(linter, buf, id)
	if self.m[buf][linter][id] ~= nil then
		self.m[buf][linter][id] = nil
	end
	-- should the highlight be removed?
	-- TODO could re-eval highlight severity
	if self.m[buf][other(linter)][id] == nil then
		return true
	else
		return false
	end
end

function Issues:set(linter, id, meta)
	local buf = vim.api.nvim_get_current_buf()
	self.m[buf][linter][id] = meta
end

function Issues:for_id(id)
	local buf = vim.api.nvim_get_current_buf()
	return self:for_buf_id(buf, id)
end

-- returns a list of issues given a mark id
function Issues:for_buf_id(buf, id)
	local issues = {}
	for _, issues_by_linter in pairs(self.m[buf]) do
		local issues_list = issues_by_linter[id]
		if issues_list ~= nil then
			for _, issue in pairs(issues_list) do
				issues[#issues + 1] = issue
			end
		end
	end
	return issues
end

function Issues:all_issues()
	local issues = {}
	for buf, _ in pairs(M.buf_query) do
		issues[#issues + 1] = self:for_buf(buf)
	end
	return issues
end

-- returns a list of individual issues, can return multiple
-- items for a single word
-- function Issues:all_issues_for_buf(buf)
-- 	local issues = {}
-- 	for source in { "vale", "langtool" } do
-- 		for meta in self.m[buf][source] do
-- 			issues[#issues + 1] = meta
-- 		end
-- 	end
-- 	return issues
-- end

M.Issues = Issues
return M
