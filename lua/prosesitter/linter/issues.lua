local state = require("prosesitter/state")
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

Issue = {}
Issue.__index = Issue
function Issue.new()
	local self = setmetatable({}, Issue)
	return self
end

function Issue:suggestion_text()
	if #self.replacements > 0 then
		log.info(vim.inspect(self.replacements))
		return "replace with: "..self.replacements[1].value
	end
end

function Issue:suggestion_lists()
	if #self.replacements == 0 then
		return nil
	end

	local list = {}
	for _, repl in ipairs(self.replacements) do
		list[#list+1] = repl.value
	end
	return list
end

M.Issue = Issue

-- meta is a dict containing all kind of properties
-- m = buffer/linter/id/meta
-- then issues is a list of:
--
-- msg, severity, type, full_source, action
--
IssueList = { m = {} }
function IssueList:attach(buf)
	self.m[buf] = { vale = {}, langtool = {} }
end

function IssueList:clear_meta_for(linter, buf, id)
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

function IssueList:set(buf, linter, id, issues)
	self.m[buf][linter][id] = issues
end

function IssueList:for_id(id)
	local buf = vim.api.nvim_get_current_buf()
	return self:for_buf_id(buf, id)
end

-- returns a list of issues given a mark id
function IssueList:for_buf_id(buf, id)
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

function IssueList:all_issues()
	local issues = {}
	for buf in state:attached() do
		issues[#issues + 1] = self:for_buf(buf)
	end
	return issues
end

M.IssueList = IssueList
return M
